#!/usr/bin/env python3
"""Scan-Werkstatt: Fotos von Papier (auch gefaltete Briefe) → sauberes A4-PDF.

Start (Browser-Editor):
    python3 ~/.claude/skills/scan/scan_tool.py FOTO [FOTO …] -o Ausgabe.pdf
    → legt neben der Ausgabe einen Ordner scan_werkstatt/ an (Originale, Vorschauen,
      punkte.json, arbeit/) und öffnet http://localhost:8743/scan_tool.html

Ohne Browser (aus gespeicherter punkte.json):
    python3 scan_tool.py --werkstatt PFAD/scan_werkstatt --bauen

Geometrie: Pro Seite 0/1/2 Knicke → 4/6/8 Punkte (Blattecken + Knick-Endpunkte links/rechts).
Jedes Paneel zwischen zwei Knicklinien ist eben → eigene 4-Punkt-Perspektivkorrektur
(ImageMagick -distort Perspective) auf ein Band des Zielblatts; Bänder werden gestapelt.
Annahme: Lage der Knicke auf dem Zielblatt (mm, Default Drittel bzw. Hälfte) — editierbar.
Wölbung: jede Kante kann per Griff senkrecht gebogen werden (quadratische Bézier); Paneele werden als
feines Gitter (Homographie + Coons-Überlagerung der Randwölbungen) in einem PIL-MESH-Warp gerechnet.

Braucht ImageMagick (magick), img2pdf, pdftoppm und Pillow (PIL, für den Gitter-Warp).
"""
import argparse, http.server, json, math, os, shutil, socketserver, subprocess, sys, tempfile, webbrowser

HIER = os.path.dirname(os.path.abspath(__file__))
PORT = 8743
VORSCHAU_BREITE = 1800          # Browser-Arbeitsbild (längste Kante)
FORMATE_MM = {"A4": (210, 297), "A5": (148, 210), "DINlang": (99, 210), "Letter": (215.9, 279.4)}
DEFAULTS = {"knicke": 2, "falz_mm": [99, 198], "format": "A4", "look": "farbe",
            "aktiv": True, "punkte": None, "rundung": {}, "koppeln": True}


# ---------------------------------------------------------------- Werkstatt-Verwaltung

def lade_punkte(werkstatt):
    p = os.path.join(werkstatt, "punkte.json")
    if os.path.exists(p):
        with open(p) as f:
            return json.load(f)
    return {"seiten": []}


def speichere_punkte(werkstatt, daten):
    with open(os.path.join(werkstatt, "punkte.json"), "w") as f:
        json.dump(daten, f, indent=1, ensure_ascii=False)


def bildgroesse(pfad):
    aus = subprocess.run(["magick", "identify", "-format", "%w %h", pfad + "[0]"],
                         capture_output=True, text=True, check=True)
    return tuple(map(int, aus.stdout.split()))


def importiere(werkstatt, fotos, daten):
    """Kopiert Fotos als auto-orientierte, profilbereinigte PNGs nach originale/ + Vorschau."""
    for d in ("originale", "vorschau", "arbeit"):
        os.makedirs(os.path.join(werkstatt, d), exist_ok=True)
    vorhanden = {s["quelle"] for s in daten["seiten"]}
    for foto in fotos:
        foto = os.path.abspath(foto)
        if foto in vorhanden:
            continue
        nr = len(daten["seiten"]) + 1
        stamm = f"{nr:03d}_" + os.path.splitext(os.path.basename(foto))[0].replace(" ", "_")
        orig = os.path.join(werkstatt, "originale", stamm + ".png")
        vors = os.path.join(werkstatt, "vorschau", stamm + ".jpg")
        subprocess.run(["magick", foto + "[0]", "-auto-orient", "-strip", "-colorspace", "sRGB",
                        "-type", "TrueColor", "-alpha", "off", orig], check=True)
        subprocess.run(["magick", orig, "-resize", f"{VORSCHAU_BREITE}x{VORSCHAU_BREITE}>",
                        "-quality", "80", vors], check=True)
        w, h = bildgroesse(orig)
        seite = dict(DEFAULTS, id=stamm, quelle=foto, breite=w, hoehe=h)
        # Hochkant-Foto im Querformat? Knicke liegen bei Briefen quer zur langen Blattseite —
        # der Nutzer dreht im Editor; hier nur merken.
        daten["seiten"].append(seite)
    speichere_punkte(werkstatt, daten)


def drehe_seite(werkstatt, seite, grad):
    orig = os.path.join(werkstatt, "originale", seite["id"] + ".png")
    vors = os.path.join(werkstatt, "vorschau", seite["id"] + ".jpg")
    subprocess.run(["magick", orig, "-rotate", str(grad), orig], check=True)
    subprocess.run(["magick", orig, "-resize", f"{VORSCHAU_BREITE}x{VORSCHAU_BREITE}>",
                    "-quality", "80", vors], check=True)
    seite["breite"], seite["hoehe"] = bildgroesse(orig)
    seite["punkte"] = None


# ---------------------------------------------------------------- Ecken finden (Apple Vision, Stufe 1 „Magic Fit")

LOKAL = os.path.join(HIER, "_lokal")   # Binaries, Benchmark-Fotos, Caches — nicht versioniert (siehe skills/README.md)


def docdetect_binary():
    """Kompiliert docdetect.swift bei Bedarf (einmalig, ~10 s) → _lokal/bin/docdetect. Nur macOS (Apple Vision)."""
    if sys.platform != "darwin":
        raise RuntimeError("Auto-Erkennung (Apple Vision) gibt es nur auf macOS — Punkte von Hand setzen.")
    quelle = os.path.join(HIER, "docdetect.swift")
    binaer = os.path.join(LOKAL, "bin", "docdetect")
    if not os.path.exists(binaer) or os.path.getmtime(binaer) < os.path.getmtime(quelle):
        if not shutil.which("swiftc"):
            raise RuntimeError("swiftc fehlt (Xcode Command Line Tools: `xcode-select --install`) — Auto-Erkennung nicht verfügbar.")
        os.makedirs(os.path.dirname(binaer), exist_ok=True)
        subprocess.run(["swiftc", "-O", "-o", binaer, quelle], check=True, capture_output=True)
    return binaer


def finde_ecken(werkstatt, seite, mit_text=True):
    """Apple Vision: Dokument-Viereck {confidence, corners:[TL,TR,BR,BL]} (normiert, y nach unten) und — mit
    mit_text — Textzeilen-Quads (`lines`). Ergebnis wird je Seite in text/<id>.json gecacht (OCR ~0,4 s)."""
    orig = os.path.join(werkstatt, "originale", seite["id"] + ".png")
    cache = os.path.join(werkstatt, "text", seite["id"] + ".json")
    if mit_text and os.path.exists(cache) and os.path.getmtime(cache) >= os.path.getmtime(orig):
        with open(cache) as f:
            return json.load(f)
    try:
        aus = subprocess.run([docdetect_binary(), orig] + (["--text"] if mit_text else []),
                             capture_output=True, text=True, check=True)
    except (RuntimeError, subprocess.CalledProcessError) as e:
        return {"corners": None, "fehler": str(e) if isinstance(e, RuntimeError) else f"Vision-Fehler: {(e.stderr or '')[:200]}"}
    erg = json.loads(aus.stdout)
    if mit_text:
        os.makedirs(os.path.dirname(cache), exist_ok=True)
        with open(cache, "w") as f:
            json.dump(erg, f)
    return erg


def papiermaske(kanten, punkte, n):
    """Polygon (normiert, im Uhrzeigersinn) aus den gemessenen Randpunkten; Lücken (abgeschnitten/unmessbar)
    werden durch die Modellpunkte überbrückt. Alles außerhalb wird beim Bau weiß — wie ein Scannerdeckel."""
    TL, TR = punkte[0], punkte[1]; BL, BR = punkte[-2], punkte[-1]
    def sortiert(pts, A, B):   # entlang der Sehne A→B ordnen
        ax, ay = B[0] - A[0], B[1] - A[1]
        return sorted(pts, key=lambda p: (p[0] - A[0]) * ax + (p[1] - A[1]) * ay)
    def glatt(pts, achse, rand=0.004):
        """Gleitender Median (Fenster 7) quer zur Kante + Versatz nach innen (rand, normiert ≈ 1 mm):
        Messpunkte springen zwischen Papier- und Schattenkante — das Polygon soll sicher im Papier liegen."""
        if len(pts) < 7:
            return [list(p) for p in pts]
        out = []
        for i in range(len(pts)):
            fenster = pts[max(0, i - 3):i + 4]
            xs = sorted(p[0] for p in fenster); ys = sorted(p[1] for p in fenster)
            p = [pts[i][0], pts[i][1]]
            if achse == "x":   # linke/rechte Kante: x glätten
                p[0] = xs[len(xs) // 2]
            else:
                p[1] = ys[len(ys) // 2]
            out.append(p)
        dx, dy = {"O": (0, rand), "U": (0, -rand), "L": (rand, 0), "R": (-rand, 0)}[achse_key]
        return [[p[0] + dx, p[1] + dy] for p in out]
    achse_key = "O"; oben = glatt(sortiert(kanten.get("O", []), TL, TR), "y")
    achse_key = "R"; rechts = glatt(sortiert(kanten.get("R", []), TR, BR), "x")
    achse_key = "U"; unten = glatt(sortiert(kanten.get("U", []), BL, BR), "y")[::-1]
    achse_key = "L"; links = glatt(sortiert(kanten.get("L", []), TL, BL), "x")[::-1]
    poly = [list(TL)] + [list(p) for p in oben] + [list(TR)] + [list(p) for p in rechts] + [list(BR)] + \
           [list(p) for p in unten] + [list(BL)] + [list(p) for p in links]
    return poly


def auto_fit_seite(werkstatt, seite):
    """Magic Fit headless inkl. Knickzahl: erst 2 Knicke, Knicke ohne gefundene Falzlinie werden abgezogen
    (→ 1 oder 0) und der Fit wiederholt. Schreibt punkte/rundung/maske/knicke in die Seite."""
    seite["knicke"] = 2
    for _ in range(3):   # iterativ: Knickzahl senken, bis gefundene Falzlinien (Stärke ≥ 8) = angenommene Knicke
        seite["falz_mm"] = [99, 198] if seite["knicke"] == 2 else [148.5, 198]
        erg = magic_fit(werkstatt, seite)
        if not erg.get("ok"):
            seite["punkte"] = None; seite["auto"] = {"ok": False}; return seite
        gefunden = sum(1 for n in erg.get("naht", []) if n.get("durchlaeufe") and n["durchlaeufe"][0] and n["durchlaeufe"][0]["staerke"] >= 8)
        if gefunden >= seite["knicke"]:
            break
        seite["knicke"] = gefunden
    seite.update(punkte=erg["punkte"], rundung=erg["rundung"], maske=erg.get("maske"),
                 auto={"ok": True, "knicke": seite["knicke"], "vision": erg.get("confidence"),
                       "zeilen": (erg.get("inhalt") or {}).get("zeilen"), "unsicher": erg["info"].get("unsicher")})
    return seite


def magic_fit(werkstatt, seite, inhalt_an=True):
    """Gesamtablauf: Vision → Kantenmessung (Ecken, Knicke, Wölbung) → inhaltsbasierte Verfeinerung.
    → dict(ok, corners, falten, rundung, punkte, info, …) für Editor/Benchmark."""
    erg = finde_ecken(werkstatt, seite)
    if not erg.get("corners"):
        return {"ok": False, "meldung": erg.get("fehler") or "kein Blatt erkannt"}
    n = seite["knicke"]
    ecken, falten, info, rundung = verfeinere_ecken(werkstatt, seite, erg["corners"], n)
    TL, TR, BR, BL = ecken
    punkte = [TL, TR]
    for i in range(n):
        t = (i + 1) / (n + 1)
        f = falten[i] if falten[i] else [[TL[0] + (BL[0] - TL[0]) * t, TL[1] + (BL[1] - TL[1]) * t],
                                         [TR[0] + (BR[0] - TR[0]) * t, TR[1] + (BR[1] - TR[1]) * t]]
        punkte += f
    punkte += [BL, BR]
    out = {"ok": True, "vision": erg["corners"], "confidence": erg.get("confidence"), "corners": ecken,
           "falten": falten, "rundung": rundung, "punkte": punkte, "info": info,
           "maske": papiermaske(info["kanten"], punkte, n)}
    if inhalt_an:
        import inhalt
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = None
        out.update(punkte_1b=punkte, rundung_1b=rundung)
        if n:   # Falzpositionen über Naht-Stetigkeit des Inhalts nachführen
            img = Image.open(os.path.join(werkstatt, "originale", seite["id"] + ".png")).convert("L")
            sk = 1400 / max(img.size)
            img = img.resize((max(1, round(img.width * sk)), max(1, round(img.height * sk))), Image.BILINEAR)
            punkte, naht = inhalt.verfeinere_falten_linie(img, punkte, rundung, n, seite["falz_mm"], seite.get("format", "A4"),
                                                          seite["breite"], seite["hoehe"])
            out.update(punkte=punkte, naht=naht)
        if erg.get("lines"):
            fest = [f"L{k}" for k, c in enumerate(info.get("klassen", {}).get("links", [])) if c not in ("ok", "schwach+")] + \
                   [f"R{k}" for k, c in enumerate(info.get("klassen", {}).get("rechts", [])) if c not in ("ok", "schwach+")]
            P2, R2, bericht = inhalt.verfeinere(punkte, rundung, n, seite["falz_mm"], seite.get("format", "A4"),
                                                seite["breite"], seite["hoehe"], erg["lines"], info["kanten"], erg["corners"],
                                                fest=fest)
            out.update(punkte=P2, rundung=R2, inhalt=bericht)
    return out


# ---------------------------------------------------------------- Stufe 1b: Kanten im Foto nachmessen, Ecken extrapolieren

def _fit_gerade(punkte):
    """Robuste Total-Least-Squares-Gerade (PCA + MAD-Ausreißer, 3 Runden) → (zentrum, richtung) oder None."""
    pts = list(punkte)
    for _ in range(3):
        if len(pts) < 8:
            return None
        cx = sum(p[0] for p in pts) / len(pts); cy = sum(p[1] for p in pts) / len(pts)
        sxx = sum((p[0] - cx) ** 2 for p in pts); syy = sum((p[1] - cy) ** 2 for p in pts)
        sxy = sum((p[0] - cx) * (p[1] - cy) for p in pts)
        # Hauptachse der 2x2-Kovarianz
        theta = 0.5 * math.atan2(2 * sxy, sxx - syy)
        d = (math.cos(theta), math.sin(theta))
        res = [abs((p[0] - cx) * d[1] - (p[1] - cy) * d[0]) for p in pts]
        med = sorted(res)[len(res) // 2]
        mad = sorted(abs(r - med) for r in res)[len(res) // 2] or 1e-6
        neu = [p for p, r in zip(pts, res) if r <= med + 3 * 1.4826 * mad + 0.5]
        if len(neu) == len(pts):
            break
        pts = neu
    return ((cx, cy), d, len(pts))


def _schnitt(g1, g2):
    (p1, d1), (p2, d2) = g1[:2], g2[:2]
    det = d1[0] * d2[1] - d1[1] * d2[0]
    if abs(det) < 1e-9:
        return None
    t = ((p2[0] - p1[0]) * d2[1] - (p2[1] - p1[1]) * d2[0]) / det
    return (p1[0] + t * d1[0], p1[1] + t * d1[1])


def _ls_gerade(pts):
    """Least-Squares-Gerade (PCA) ohne Ausreißerbehandlung → (zentrum, richtung, residuum_summe) oder None."""
    if len(pts) < 4:
        return None
    cx = sum(p[0] for p in pts) / len(pts); cy = sum(p[1] for p in pts) / len(pts)
    sxx = sum((p[0] - cx) ** 2 for p in pts); syy = sum((p[1] - cy) ** 2 for p in pts)
    sxy = sum((p[0] - cx) * (p[1] - cy) for p in pts)
    theta = 0.5 * math.atan2(2 * sxy, sxx - syy); d = (math.cos(theta), math.sin(theta))
    res = sum(((p[0] - cx) * d[1] - (p[1] - cy) * d[0]) ** 2 for p in pts)
    return ((cx, cy), d, res)


def _stueckweise(links, rechts, n_knicke):
    """Gemeinsame Bruchstellen (t-Parameter entlang der Kante) für linke+rechte Kante per Rastersuche.
    links/rechts: Listen von (t, (x, y)). → (bruchstellen, segmente_links, segmente_rechts, gewinn)"""
    def fit_mit(bruch, pts):
        grenzen = [0] + list(bruch) + [1.01]; segs, res = [], 0
        for a, b in zip(grenzen, grenzen[1:]):
            seg = [p for t, p in pts if a <= t < b]
            g = _ls_gerade(seg)
            if g is None:
                return None, float("inf")
            segs.append((g[0], g[1], g[2], len(seg))); res += g[2]
        return segs, res
    eins = (_ls_gerade([p for _, p in links]) or (None, None, 0))[2] + (_ls_gerade([p for _, p in rechts]) or (None, None, 0))[2]
    if n_knicke == 0:
        sl, _ = fit_mit([], links); sr, _ = fit_mit([], rechts)
        return [], sl, sr, 0
    schritte = [0.12 + 0.02 * i for i in range(39)]  # 0.12 … 0.88
    kandidaten = ([(b,) for b in schritte] if n_knicke == 1
                  else [(b1, b2) for b1 in schritte for b2 in schritte if b2 - b1 >= 0.15])
    best = None
    for br in kandidaten:
        sl, rl = fit_mit(br, links); sr, rr = fit_mit(br, rechts)
        if sl is None or sr is None:
            continue
        if best is None or rl + rr < best[0]:
            best = (rl + rr, br, sl, sr)
    if best is None:
        return None
    gewinn = 1 - best[0] / eins if eins > 0 else 0
    return list(best[1]), best[2], best[3], gewinn


def saeubere_kante(pts, maxdim):
    """Kontinuitätsfilter für gemessene Kantenpunkte [(t,(x,y))]: ein Punkt muss an den vorigen anschließen
    (Sprung ≤ 3× typischer Abstand); nach einer Lücke (Kante lag außerhalb des Fotos) nur dann wieder
    akzeptieren, wenn er auf der Verlängerung der zuletzt gemessenen Kante liegt (≤ 3 % der Bildgröße)."""
    if len(pts) < 3:
        return pts
    pts = sorted(pts); akz = [pts[0]]; spacings = []
    for t, p in pts[1:]:
        tp, pp = akz[-1]; d = math.dist(p, pp)
        if t - tp < 0.03:
            typ = sorted(spacings)[len(spacings) // 2] if len(spacings) >= 5 else d
            if d <= 3 * typ + 0.01 * maxdim:
                akz.append((t, p)); spacings.append(d)
        else:  # Lücke
            basis = [q for _, q in akz[-12:]]
            g = _fit_gerade(basis) if len(basis) >= 8 else None
            if g is None:
                akz.append((t, p)); continue
            (cx, cy), (dx, dy), _ = g
            abstand = abs((p[0] - cx) * dy - (p[1] - cy) * dx)
            if abstand <= 0.03 * maxdim:
                akz.append((t, p)); spacings.append(d)
    return akz


def finde_knicke(img, ecken_px, ml, mr, n_knicke):
    """Knicklagen aus dem Richtungswechsel der gemessenen Seitenkanten (Hauptsignal, absolute Grad) plus
    schwachem Helligkeitsstufen-Signal des grob entzerrten Blatts; Prior „ungefähr Drittel".
    Auswertung auf gemeinsamem t-Raster, anschließend je Seite lokal nachjustiert.
    → (bruch: Liste [t_links, t_rechts] je Knick, diagnose)"""
    from PIL import Image
    TL, TR, BR, BL = ecken_px
    RW, RH = 300, 420
    rect = img.transform((RW, RH), Image.QUAD, (*TL, *BL, *BR, *TR), resample=Image.BILINEAR)
    px = rect.load()
    hq = homographie([(0, 0), (RW, 0), (RW, RH), (0, RH)], [TL, TR, BR, BL])

    def t_auf(p, A, B):
        ax, ay = B[0] - A[0], B[1] - A[1]; return ((p[0] - A[0]) * ax + (p[1] - A[1]) * ay) / (ax * ax + ay * ay)

    def stufen_signal(xa, xb, A, B, xr):
        """Helligkeitsstufe je Zeile (90. Perzentil, geglättet) → Funktion t ↦ Stufe (0..3, gedeckelt)."""
        prof = []
        for v in range(RH):
            z = sorted(px[x, v] for x in range(xa, xb)); prof.append(z[int(len(z) * 0.9)])
        gl = [sum(prof[max(0, i - 2):i + 3]) / len(prof[max(0, i - 2):i + 3]) for i in range(RH)]
        st = [abs(sum(gl[v + 4:v + 17]) / 13 - sum(gl[v - 16:v - 3]) / 13) if 16 <= v < RH - 16 else 0 for v in range(RH)]
        ts = [t_auf(anw(hq, xr, v), A, B) for v in range(RH)]
        def bei(t):
            v = min(range(RH), key=lambda v: abs(ts[v] - t)); return min(3.0, st[v] / 4.0)
        return bei

    def winkel_signal(pts, fenster=0.12):
        """t ↦ Richtungswechsel (Grad, gedeckelt 30) zwischen den Kantenpunkten vor und nach t;
        beide Fenster brauchen ≥ 6 Punkte und ≥ 0.05 Spannweite, sonst None (nicht messbar)."""
        def bei(t):
            a = [(tt, p) for tt, p in pts if t - fenster <= tt < t]; b = [(tt, p) for tt, p in pts if t <= tt < t + fenster]
            if len(a) < 8 or len(b) < 8 or a[-1][0] - a[0][0] < 0.7 * fenster or b[-1][0] - b[0][0] < 0.7 * fenster:
                return None
            ga, gb = _fit_gerade([p for _, p in a]), _fit_gerade([p for _, p in b])
            if ga is None or gb is None:
                return None
            return min(30.0, math.degrees(math.acos(min(1, abs(ga[1][0] * gb[1][0] + ga[1][1] * gb[1][1])))))
        return bei

    def knick_signal(pts):
        """Knick ≠ Wölbung: ein Knick zeigt denselben Winkel bei kleinem und großem Fenster, eine Wölbung
        wächst mit dem Fenster → Minimum beider Fenster."""
        klein, gross = winkel_signal(pts, 0.07), winkel_signal(pts, 0.13)
        def bei(t):
            a, b = klein(t), gross(t)
            if a is None and b is None:
                return None
            return min(x for x in (a, b) if x is not None)
        return bei

    wl, wr = knick_signal(ml), knick_signal(mr)
    sl_, sr_ = stufen_signal(int(RW * 0.06), int(RW * 0.5), TL, BL, 0), stufen_signal(int(RW * 0.5), int(RW * 0.94), TR, BR, RW)
    raster = [0.08 + 0.01 * i for i in range(85)]
    def score(t):
        w = [x for x in (wl(t), wr(t)) if x is not None]
        hell = (sl_(t) + sr_(t)) / 2
        if not w:                                          # Kanten dort nicht messbar (abgeschnitten): nur Helligkeit
            return hell
        return (sum(w) / len(w)) / 3.0 + 0.4 * hell        # 9° ≙ 3
    sc = [score(t) for t in raster]
    prior = lambda t, soll: -((t - soll) / 0.14) ** 2
    solls = [0.5] if n_knicke == 1 else [1 / 3, 2 / 3]
    kand = [i for i in range(len(raster)) if sc[i] >= max(sc[max(0, i - 6):i + 7]) and sc[i] > 0.5]
    if not kand:
        return None, {"grund": "keine Kandidaten"}
    paare = [(i,) for i in kand] if n_knicke == 1 else [(a, b) for a in kand for b in kand if raster[b] - raster[a] >= 0.18]
    if not paare:
        return None, {"grund": "kein Paar"}
    best = max(paare, key=lambda pr: sum(sc[i] + prior(raster[i], so) for i, so in zip(pr, solls)))
    bruch = []
    for i in best:   # je Seite lokal (±0.04) auf das Winkelmaximum nachjustieren
        t = raster[i]; out = []
        for w in (wl, wr):
            lokal = [(w(t + d), t + d) for d in (-0.04, -0.03, -0.02, -0.01, 0, 0.01, 0.02, 0.03, 0.04)]
            lokal = [(v, tt) for v, tt in lokal if v is not None]
            out.append(max(lokal)[1] if lokal else t)
        bruch.append(out)
    return bruch, {"t": [round(raster[i], 2) for i in best], "score": [round(sc[i], 1) for i in best]}


def schaetze_woelbung(pts, A, B, W, Hh):
    """Parabel-Wölbung einer Kante A→B aus gemessenen Punkten: senkrechter Abstand e zur Sehne, Modell
    e(u) = 4u(1-u)·D (u = Sehnenparameter) → D per Least Squares. Rückgabe normierter Griff-Vektor [dx, dy]
    (Editor-Konvention: Kurvenmitte = Sehnenmitte + D) oder [0, 0], wenn zu wenig/zu kurz gemessen."""
    ax, ay = B[0] - A[0], B[1] - A[1]; L2 = ax * ax + ay * ay
    if L2 <= 0 or len(pts) < 10:
        return [0.0, 0.0]
    L = math.sqrt(L2); nx, ny = -ay / L, ax / L
    num = den = 0.0; us = []
    for (x, y) in pts:
        u = ((x - A[0]) * ax + (y - A[1]) * ay) / L2
        if u < 0.02 or u > 0.98:
            continue
        e = (x - A[0]) * nx + (y - A[1]) * ny; b = 4 * u * (1 - u)
        num += e * b; den += b * b; us.append(u)
    if den <= 0 or len(us) < 10 or max(us) - min(us) < 0.4:
        return [0.0, 0.0]
    D = num / den
    return [D * nx / W, D * ny / Hh]


def _segmente(pts, bruch):
    grenzen = [0] + list(bruch) + [1.01]; segs = []
    for a, b in zip(grenzen, grenzen[1:]):
        seg = [p for t, p in pts if a <= t < b]
        g = _ls_gerade(seg)
        segs.append((g[0], g[1], g[2], len(seg)) if g else (None, None, 0, len(seg)))
    return segs


def _punkt_bei(g, A, B, t):
    """Punkt der Geraden g, der dem Kantenparameter t (auf der Sehne A→B) am nächsten liegt."""
    (cx, cy), (dx, dy) = g[:2]
    qx, qy = A[0] + t * (B[0] - A[0]), A[1] + t * (B[1] - A[1])
    u = (qx - cx) * dx + (qy - cy) * dy
    return (cx + u * dx, cy + u * dy)


def papierheit(rgb, ecken):
    """Kanal „Papierheit": Pixel auf die Farbachse Hintergrund→Papier projiziert (Papier hell ≈ 220, Hintergrund
    ≈ 35). Papierfarbe = Median innerhalb des (um 20 % geschrumpften) Vision-Vierecks, Hintergrundfarbe = Median
    außerhalb (um 12 % vergrößert). Auf rosa Bettwäsche o. ä. ist der Luminanz-Kontrast fast null, der
    Farbkontrast groß. Ist der Farbabstand klein (< 30), bleibt es bei Luminanz. → (Bild L, Info)"""
    W, H = rgb.size; px = rgb.load()
    TL, TR, BR, BL = ecken
    cx, cy = sum(p[0] for p in ecken) / 4, sum(p[1] for p in ecken) / 4
    def quad(f):  # Viereck um das Zentrum skaliert
        return [(cx + (p[0] - cx) * f, cy + (p[1] - cy) * f) for p in ecken]
    def innerhalb(q, x, y):
        sgn = 0
        for i in range(4):
            a, b = q[i], q[(i + 1) % 4]
            c = (b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0]); sgn += 1 if c >= 0 else -1
        return abs(sgn) == 4
    innen_q, aussen_q = quad(0.8), quad(1.12)
    innen, aussen = [], []
    for yi in range(0, H, max(1, H // 60)):
        for xi in range(0, W, max(1, W // 60)):
            xn, yn = xi / W, yi / H; c = px[xi, yi]
            if innerhalb(innen_q, xn, yn):
                innen.append(c)
            elif not innerhalb(aussen_q, xn, yn):
                aussen.append(c)
    if len(innen) < 20 or len(aussen) < 20:
        return rgb.convert("L"), {"kanal": "luminanz", "grund": "zu wenig Proben"}
    med = lambda L, i: sorted(c[i] for c in L)[len(L) // 2]
    pap = [med(innen, i) for i in range(3)]; hg = [med(aussen, i) for i in range(3)]
    d = [pap[i] - hg[i] for i in range(3)]; norm = math.sqrt(sum(v * v for v in d)) or 1
    lum = lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
    lum_abstand = abs(lum(pap) - lum(hg))
    # Luminanz bleibt Standard (erprobt), Farbachse nur, wenn sie deutlich mehr Kontrast bietet (rosa/farbige Unterlage)
    if norm < 30 or lum_abstand >= 60:   # Luminanz reicht (weiß auf dunkel/holz); Farbachse nur bei schwachem Helligkeitskontrast
        return rgb.convert("L"), {"kanal": "luminanz", "papier": pap, "hintergrund": hg, "abstand": round(norm), "lum": round(lum_abstand)}
    u = [v / norm for v in d]
    # L = a*R + b*G + c*B + off, so dass Hintergrund → 35 und Papier → 220
    skal = 185.0 / norm
    a, b, c = u[0] * skal, u[1] * skal, u[2] * skal
    off = 35 - (a * hg[0] + b * hg[1] + c * hg[2])
    return rgb.convert("L", (a, b, c, off)), {"kanal": "farbachse", "papier": pap, "hintergrund": hg, "abstand": round(norm)}


def verfeinere_ecken(werkstatt, seite, ecken, knicke):
    """Misst die Papierkanten im Foto nach (Stufenfilter senkrecht zur Vision-Kante), fittet Geraden und
    schneidet sie → Ecken auch außerhalb des Fotos. Seitenkanten: stückweise linear mit gemeinsamen
    Bruchstellen = Knick-Vorschlag. Gibt (ecken, falten, info) normiert zurück."""
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    orig = os.path.join(werkstatt, "originale", seite["id"] + ".png")
    rgb = Image.open(orig).convert("RGB")
    sk = 1400 / max(rgb.size)
    rgb = rgb.resize((max(1, round(rgb.width * sk)), max(1, round(rgb.height * sk))), Image.BILINEAR)
    img_lum = rgb.convert("L")
    img, kanal_info = papierheit(rgb, ecken)   # Kantenmessung auf dem Kanal mit dem besten Papier/Hintergrund-Kontrast
    W, Hh = img.size; px = img.load()
    R = max(8, round(0.05 * max(W, Hh))); w = max(3, round(0.006 * max(W, Hh))); rand = 0.006 * max(W, Hh)
    TL, TR, BR, BL = [(x * W, y * Hh) for x, y in ecken]
    zentrum = ((TL[0] + TR[0] + BR[0] + BL[0]) / 4, (TL[1] + TR[1] + BR[1] + BL[1]) / 4)

    def messe(A, B, n=150):
        """Kantenpunkte entlang A→B: pro Abtastung stärkste Helligkeitsstufe auf der Normalen → [(t, (x,y))]."""
        ex, ey = B[0] - A[0], B[1] - A[1]; L = math.hypot(ex, ey) or 1
        nx, ny = -ey / L, ex / L
        mx, my = (A[0] + B[0]) / 2 - zentrum[0], (A[1] + B[1]) / 2 - zentrum[1]
        if nx * mx + ny * my > 0:
            nx, ny = -nx, -ny
        treffer = []; am_rand.clear()
        for i in range(n):
            t = 0.02 + 0.96 * (i + 0.5) / n
            cx, cy = A[0] + t * ex, A[1] + t * ey
            prof = []
            for s_ in range(-R, R + 1):
                x, y = cx + s_ * nx, cy + s_ * ny
                prof.append(None if (x < 0 or y < 0 or x >= W - 1 or y >= Hh - 1) else px[int(x), int(y)])
            # Stufen entlang der Normalen (Innenseite = +); Papier-Referenzhelligkeit = Medianwert tief innen
            innen = [v for v in prof[len(prof) - 3 * w:] if v is not None]
            papier = sorted(innen)[len(innen) // 2] if innen else None
            kand = []
            for j in range(w, len(prof) - w):
                a, b = prof[j - w:j], prof[j:j + w]
                if None in a or None in b:
                    continue
                kand.append((abs(sum(b) - sum(a)) / w, j, sum(b) / w))
            if not kand:              # Suchfenster ragt über den Fotorand: Kante dort nicht messbar
                am_rand.append(t); continue
            top = max(c[0] for c in kand)
            # Mehrdeutigkeit (Papier – dunkler Spalt – helle Wand/zweites Blatt): innerste starke Stufe nehmen,
            # deren Innenseite papierhell ist; sonst die stärkste
            stark = [c for c in kand if c[0] >= 0.5 * top and (papier is None or c[2] >= 0.75 * papier)]
            best, bs, _ = max(stark, key=lambda c: c[1]) if stark else max(kand)
            x, y = cx + (bs - R) * nx, cy + (bs - R) * ny
            if x < rand or y < rand or x > W - rand or y > Hh - rand:
                am_rand.append(t); continue
            treffer.append((t, (x, y), best))
        if not treffer:
            return []
        med = sorted(c for *_, c in treffer)[len(treffer) // 2]
        return [(t, p) for t, p, c in treffer if c >= 0.5 * med and c >= 8]
    am_rand = []   # t-Werte, deren Treffer am Fotorand lagen (Kante dort abgeschnitten)

    info = {"fallback": [], "knicke_gefunden": 0, "bruch": None}
    def vision_gerade(A, B):
        L = math.dist(A, B) or 1
        return ((A[0], A[1]), ((B[0] - A[0]) / L, (B[1] - A[1]) / L), 0)

    def robust(name, pts, A, B):
        g = _fit_gerade(pts) if len(pts) >= 12 else None
        if g is None:
            info["fallback"].append(name); return vision_gerade(A, B)
        vg = vision_gerade(A, B)
        # Plausibilität: gefittete Gerade darf an beiden Enden der Vision-Kante höchstens 4 % abweichen
        def abstand(pt):
            return abs((pt[0] - g[0][0]) * g[1][1] - (pt[1] - g[0][1]) * g[1][0])
        if max(abstand(A), abstand(B)) > 0.04 * max(W, Hh):
            info["fallback"].append(name + ":abweichend"); return vg
        return (g[0], g[1], 0)

    mo, mu = messe(TL, TR), messe(BL, BR)
    oben = robust("oben", [p for _, p in mo], TL, TR)
    unten = robust("unten", [p for _, p in mu], BL, BR)
    ml = saeubere_kante(messe(TL, BL), max(W, Hh)); rand_l = list(am_rand)
    mr = saeubere_kante(messe(TR, BR), max(W, Hh)); rand_r = list(am_rand)
    falten = [None] * knicke
    bruch, diag = (finde_knicke(img_lum, (TL, TR, BR, BL), ml, mr, knicke) if knicke else (None, {}))
    info["knick_diag"] = diag; info["kanal"] = kanal_info
    if bruch:
        bruch_l, bruch_r = [b[0] for b in bruch], [b[1] for b in bruch]
        sl, sr = _segmente(ml, bruch_l), _segmente(mr, bruch_r)
        # Segmente ohne Geradenfit (zu wenige Punkte) bekommen Platzhalter aus der Vision-Kante
        sl = [g if g[0] else (vision_gerade(TL, BL)[0], vision_gerade(TL, BL)[1], 0, g[3]) for g in sl]
        sr = [g if g[0] else (vision_gerade(TR, BR)[0], vision_gerade(TR, BR)[1], 0, g[3]) for g in sr]
        info["bruch"] = bruch; info["knicke_gefunden"] = knicke
        def stabilisiere(segs, name, rand_ts, A, B, bruch):
            """Unzuverlässige Segmente übernehmen Richtung (und bei abgeschnittener Kante auch den Anker) vom
            nächsten zuverlässigen Segment derselben Kante. Unzuverlässig = abgeschnitten (mehr Abtastungen am
            Fotorand verworfen als Treffer), Schwerpunkt > 4 % von der Vision-Kante entfernt, oder < 20 Punkte."""
            grenzen = [0] + bruch + [1.01]; vg = vision_gerade(A, B); maxd = 0.09 * max(W, Hh)   # Knick-Ausbuchtung liegt legitim neben der Sehne
            klasse = []
            for i, g in enumerate(segs):
                n_rand = sum(1 for t in rand_ts if grenzen[i] <= t < grenzen[i + 1])
                abstand = abs((g[0][0] - vg[0][0]) * vg[1][1] - (g[0][1] - vg[0][1]) * vg[1][0])
                if n_rand > g[3]: klasse.append("abgeschnitten")
                elif abstand > maxd: klasse.append("abweichend")
                elif g[3] < 20: klasse.append("schwach")
                else: klasse.append("ok")
            info.setdefault("klassen", {})[name] = klasse
            stark = [i for i, k in enumerate(klasse) if k == "ok"]
            if not stark or len(stark) == len(segs):
                return segs
            out = list(segs)
            for i, g in enumerate(segs):
                if klasse[i] == "ok":
                    continue
                j = min(stark, key=lambda j: abs(j - i)); dn = segs[j][1]
                if klasse[i] == "schwach":   # Mischung nach Punktzahl — außer die eigene Richtung ist unplausibel (> 8° zum Nachbarn)
                    a = g[3] / 20
                    if g[1][0] * dn[0] + g[1][1] * dn[1] < 0: dn = (-dn[0], -dn[1])
                    winkel = math.degrees(math.acos(min(1, abs(g[1][0] * dn[0] + g[1][1] * dn[1]))))
                    if winkel > 8:
                        a = 0.0
                    dx, dy = a * g[1][0] + (1 - a) * dn[0], a * g[1][1] + (1 - a) * dn[1]; L = math.hypot(dx, dy) or 1
                    out[i] = (g[0], (dx / L, dy / L), g[2], g[3])
                else:                        # Nachbar-Richtung, Anker = Nachbar-Ende an der gemeinsamen Bruchstelle
                    anker = _punkt_bei(segs[j], A, B, grenzen[i + 1] if j > i else grenzen[i])
                    out[i] = (anker, dn, g[2], g[3])
                info.setdefault("unsicher", []).append(f"{name}{i}:{klasse[i]}")
            return out
        sl, sr = stabilisiere(sl, "links", rand_l, TL, BL, bruch_l), stabilisiere(sr, "rechts", rand_r, TR, BR, bruch_r)
        links0, linksN, rechts0, rechtsN = sl[0], sl[-1], sr[0], sr[-1]
        for k, (bl_, br_) in enumerate(bruch):   # Knickpunkt = Mittel der beiden Segment-Enden an der Bruchstelle
            pl = [_punkt_bei(sl[k], TL, BL, bl_), _punkt_bei(sl[k + 1], TL, BL, bl_)]
            pr = [_punkt_bei(sr[k], TR, BR, br_), _punkt_bei(sr[k + 1], TR, BR, br_)]
            falten[k] = [[(pl[0][0] + pl[1][0]) / 2 / W, (pl[0][1] + pl[1][1]) / 2 / Hh],
                         [(pr[0][0] + pr[1][0]) / 2 / W, (pr[0][1] + pr[1][1]) / 2 / Hh]]
    else:
        links0 = linksN = robust("links", [p for _, p in ml], TL, BL)
        rechts0 = rechtsN = robust("rechts", [p for _, p in mr], TR, BR)
    neu = [_schnitt(oben, links0) or TL, _schnitt(oben, rechts0) or TR,
           _schnitt(unten, rechtsN) or BR, _schnitt(unten, linksN) or BL]
    # Ecken neben unzuverlässigen Seitensegmenten: Visions Ecke als Schiedsrichter, wenn sie nicht am Bildrand klemmt
    kl_l0 = info.get("klassen", {}).get("links", ["ok"] * (knicke + 1)); kl_r0 = info.get("klassen", {}).get("rechts", ["ok"] * (knicke + 1))
    rand_px = 0.015 * max(W, Hh)
    def frei(p):
        return rand_px < p[0] < W - rand_px and rand_px < p[1] < Hh - rand_px
    for idx, (vis, kl) in enumerate(((TL, kl_l0[0]), (TR, kl_r0[0]), (BR, kl_r0[-1]), (BL, kl_l0[-1]))):
        if kl != "ok" and frei(vis) and math.dist(neu[idx], vis) > 0.02 * max(W, Hh):
            neu[idx] = vis; info.setdefault("ecke_vision", []).append(["TL", "TR", "BR", "BL"][idx])
    # Wölbung je Kante aus den Messpunkten (Stufe 3): Seitenkanten segmentweise, Außenkanten ganz
    ecken_n = [[x / W, y / Hh] for x, y in neu]
    modell = [neu[0], neu[1]]
    for f in falten:
        modell += [(f[0][0] * W, f[0][1] * Hh), (f[1][0] * W, f[1][1] * Hh)] if f else [None, None]
    modell += [neu[3], neu[2]]
    rundung = {}
    grenzen_l = [0] + [b[0] for b in (bruch or [])] + [1.01]
    grenzen_r = [0] + [b[1] for b in (bruch or [])] + [1.01]
    kl_l = info.get("klassen", {}).get("links", ["ok"] * (knicke + 1))
    kl_r = info.get("klassen", {}).get("rechts", ["ok"] * (knicke + 1))
    def vertrauenswuerdig(pts, grenzen, klassen, A, B):
        """Segmentpunkte behalten, wenn Segment „ok" — oder „schwach", aber nahe an Visions Kante (Median < 1,5 %)."""
        vg = vision_gerade(A, B); keep = set()
        for k in range(knicke + 1):
            seg = [(t, p) for t, p in pts if grenzen[k] <= t < grenzen[k + 1]]
            if not seg:
                continue
            if klassen[k] == "ok":
                keep.update(id(p) for _, p in seg); continue
            if klassen[k] == "schwach":
                d = sorted(abs((p[0] - vg[0][0]) * vg[1][1] - (p[1] - vg[0][1]) * vg[1][0]) for _, p in seg)
                if d[len(d) // 2] < 0.015 * max(W, Hh):
                    keep.update(id(p) for _, p in seg); klassen[k] = "schwach+"
        return [(t, p) for t, p in pts if id(p) in keep]
    ml_ok = vertrauenswuerdig(ml, grenzen_l, kl_l, TL, BL)
    mr_ok = vertrauenswuerdig(mr, grenzen_r, kl_r, TR, BR)
    info["verworfen"] = {"links": len(ml) - len(ml_ok), "rechts": len(mr) - len(mr_ok)}
    ml, mr = ml_ok, mr_ok   # unzuverlässige Segmente: weder Wölbung noch Randpunkte (Inhalt/Maske)
    for k in range(knicke + 1):
        A_, B_ = modell[2 * k], modell[2 * k + 2]
        if A_ and B_ and kl_l[k] in ("ok", "schwach+"):
            seg = [p for t, p in ml if grenzen_l[k] <= t < grenzen_l[k + 1]]
            rundung[f"L{k}"] = schaetze_woelbung(seg, A_, B_, W, Hh)
        A_, B_ = modell[2 * k + 1], modell[2 * k + 3]
        if A_ and B_ and kl_r[k] in ("ok", "schwach+"):
            seg = [p for t, p in mr if grenzen_r[k] <= t < grenzen_r[k + 1]]
            rundung[f"R{k}"] = schaetze_woelbung(seg, A_, B_, W, Hh)
    rundung["H0"] = schaetze_woelbung([p for _, p in mo], neu[0], neu[1], W, Hh)
    rundung[f"H{knicke + 1}"] = schaetze_woelbung([p for _, p in mu], neu[3], neu[2], W, Hh)
    rundung = {k: v for k, v in rundung.items() if abs(v[0]) + abs(v[1]) > 1e-4}
    info["kanten"] = {"L": [(p[0] / W, p[1] / Hh) for _, p in ml], "R": [(p[0] / W, p[1] / Hh) for _, p in mr],
                      "O": [(p[0] / W, p[1] / Hh) for _, p in mo], "U": [(p[0] / W, p[1] / Hh) for _, p in mu]}
    info["woelbung"] = {k: [round(v[0], 4), round(v[1], 4)] for k, v in rundung.items()}
    return ecken_n, falten, info, rundung


# ---------------------------------------------------------------- Geometrie + Bildbau

def zielmasse(seite, dpi):
    fmt = seite.get("format", "A4")
    if fmt == "auto":
        # Zielmaß aus den Bildkanten (wie das alte Eckpunkte-Tool): längste Horizontal-/Vertikalkante
        pts = seite["punkte"]; bw, bh = seite["breite"], seite["hoehe"]
        px = [(x * bw, y * bh) for x, y in pts]
        n = len(px) // 2
        breite = max(math.dist(px[2 * i], px[2 * i + 1]) for i in range(n))
        hoehe = sum(max(math.dist(px[2 * i], px[2 * i + 2]), math.dist(px[2 * i + 1], px[2 * i + 3]))
                    for i in range(n - 1))
        return round(breite), round(hoehe), None
    mm_b, mm_h = FORMATE_MM[fmt]
    return round(mm_b / 25.4 * dpi), round(mm_h / 25.4 * dpi), mm_h


def loese(A, b):
    """Gauß mit Pivot (kleine Systeme, kein numpy)."""
    n = len(b); A = [r[:] for r in A]; b = b[:]
    for i in range(n):
        p = max(range(i, n), key=lambda r: abs(A[r][i])); A[i], A[p] = A[p], A[i]; b[i], b[p] = b[p], b[i]
        for r in range(i + 1, n):
            f = A[r][i] / A[i][i]
            for k in range(i, n): A[r][k] -= f * A[i][k]
            b[r] -= f * b[i]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (b[i] - sum(A[i][k] * x[k] for k in range(i + 1, n))) / A[i][i]
    return x


def homographie(src, dst):
    A, b = [], []
    for (x, y), (u, v) in zip(src, dst):
        A.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); b.append(u)
        A.append([0, 0, 0, x, y, 1, -v * x, -v * y]); b.append(v)
    return loese(A, b)


def anw(h, x, y):
    w = h[6] * x + h[7] * y + 1
    return ((h[0] * x + h[1] * y + h[2]) / w, (h[3] * x + h[4] * y + h[5]) / w)


GITTER_NX, GITTER_NY = 12, 28   # Zellen je Paneel (Server); bilineare Zellen ≈ exakte Homographie bei dieser Feinheit


def gitter_mesh(seite, W, H, ys):
    """Baut die PIL-MESH-Liste: je Zelle (Zielrechteck, Quellviereck NW,SW,SE,NE in Originalpixeln).
    Zellecken = exakte Paneel-Homographie + Coons-Überlagerung der vier Randwölbungen (wie im Editor)."""
    pts = seite["punkte"]; bw, bh = seite["breite"], seite["hoehe"]
    rund = seite.get("rundung") or {}
    dev = lambda key: rund.get(key) or [0, 0]
    mesh = []
    for k in range(seite["knicke"] + 1):
        src = [(pts[2 * k][0] * bw, pts[2 * k][1] * bh), (pts[2 * k + 1][0] * bw, pts[2 * k + 1][1] * bh),
               (pts[2 * k + 3][0] * bw, pts[2 * k + 3][1] * bh), (pts[2 * k + 2][0] * bw, pts[2 * k + 2][1] * bh)]
        y0, y1 = ys[k], ys[k + 1]
        hk = homographie([(0, y0), (W, y0), (W, y1), (0, y1)], src)
        dL, dR, dT, dB = dev(f"L{k}"), dev(f"R{k}"), dev(f"H{k}"), dev(f"H{k + 1}")

        def quelle(x, y):
            u, v = x / W, (y - y0) / (y1 - y0)
            bx, by = anw(hk, x, y); bl, bu = 4 * v * (1 - v), 4 * u * (1 - u)
            dx = ((1 - u) * dL[0] + u * dR[0]) * bl + ((1 - v) * dT[0] + v * dB[0]) * bu
            dy = ((1 - u) * dL[1] + u * dR[1]) * bl + ((1 - v) * dT[1] + v * dB[1]) * bu
            return (bx + dx * bw, by + dy * bh)

        xs = [round(i * W / GITTER_NX) for i in range(GITTER_NX + 1)]
        yy = [y0 + round(j * (y1 - y0) / GITTER_NY) for j in range(GITTER_NY + 1)]
        for j in range(GITTER_NY):
            for i in range(GITTER_NX):
                xa, xb, ya, yb = xs[i], xs[i + 1], yy[j], yy[j + 1]
                if xb <= xa or yb <= ya:
                    continue
                nw, sw, se, ne = quelle(xa, ya), quelle(xa, yb), quelle(xb, yb), quelle(xb, ya)
                mesh.append(((xa, ya, xb, yb), (*nw, *sw, *se, *ne)))
    return mesh


def baue_seite(werkstatt, seite, dpi, tmp):
    """Entzerrt eine Seite (Gitter-Warp, PIL) und wendet den Look an (ImageMagick) → arbeit/<id>.jpg"""
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    orig = os.path.join(werkstatt, "originale", seite["id"] + ".png")
    ziel = os.path.join(werkstatt, "arbeit", seite["id"] + ".jpg")
    pts = seite["punkte"]; bw, bh = seite["breite"], seite["hoehe"]
    W, H, mm_h = zielmasse(seite, dpi)
    n_knicke = seite["knicke"]
    assert len(pts) == 4 + 2 * n_knicke, "Punktzahl passt nicht zur Knickzahl"
    if n_knicke == 0:
        ys = [0, H]
    else:
        falz = seite["falz_mm"][:n_knicke]
        if mm_h:
            ys = [0] + [round(f / mm_h * H) for f in falz] + [H]
        else:  # auto-Format: Knicke proportional zu den Bildkanten
            px = [(x * bw, y * bh) for x, y in pts]
            laengen = [max(math.dist(px[2 * i], px[2 * i + 2]), math.dist(px[2 * i + 1], px[2 * i + 3]))
                       for i in range(n_knicke + 1)]
            akk, ys = 0, [0]
            for l in laengen[:-1]:
                akk += l; ys.append(round(akk / sum(laengen) * H))
            ys.append(H)
    mesh = gitter_mesh(seite, W, H, ys)
    bild = Image.open(orig).convert("RGB")
    if seite.get("maske"):   # Papiermaske: außerhalb des gemessenen Randpolygons weiß
        from PIL import ImageDraw
        m = Image.new("L", bild.size, 0)
        ImageDraw.Draw(m).polygon([(x * bw, y * bh) for x, y in seite["maske"]], fill=255)
        bild = Image.composite(bild, Image.new("RGB", bild.size, (255, 255, 255)), m)
    roh_img = bild.transform((W, H), Image.MESH, mesh, resample=Image.BICUBIC, fillcolor=(255, 255, 255))
    roh = os.path.join(tmp, f"{seite['id']}_roh.png")
    roh_img.save(roh)
    # Look
    look = seite.get("look", "farbe")
    cmd = ["magick", roh]
    if look in ("farbe", "grau", "sw"):
        if look != "farbe":
            cmd += ["-colorspace", "Gray"]
        # Beleuchtung glätten: Bild durch stark weichgezeichnete Kopie teilen (Schatten/Vignette weg)
        cmd += ["(", "+clone", "-scale", "5%", "-blur", "0x3", "-resize", f"{W}x{H}!", ")",
                "-compose", "Divide_Dst", "-composite",
                "-contrast-stretch", "0.3%x0.3%"]
        if look == "sw":
            cmd += ["-lat", "30x30-3%", "-threshold", "50%"]
        elif look == "grau":
            cmd += ["-level", "8%,96%"]
        else:
            cmd += ["-level", "6%,97%", "-modulate", "100,85"]
    cmd += ["-colorspace", "Gray" if look in ("grau", "sw") else "sRGB",
            "-strip", "-density", str(dpi), "-quality", "88", ziel]
    subprocess.run(cmd, check=True)
    return ziel


def baue_pdf(werkstatt, daten, ausgabe, dpi):
    aktiv = [s for s in daten["seiten"] if s.get("aktiv", True) and s.get("punkte")]
    if not aktiv:
        return False, "Keine aktive Seite mit gesetzten Punkten."
    seiten = []
    with tempfile.TemporaryDirectory() as tmp:
        for s in aktiv:
            seiten.append(baue_seite(werkstatt, s, dpi, tmp))
    fmt = aktiv[0].get("format", "A4")
    cmd = ["img2pdf", *seiten, "-o", ausgabe]
    if fmt in FORMATE_MM:
        mm_b, mm_h = FORMATE_MM[fmt]
        cmd += ["--pagesize", f"{mm_b}mmx{mm_h}mm"]
    subprocess.run(cmd, check=True)
    # Selbsttest: rendert jede Seite einmal — Warnungen (ICC, jpx …) wären hier sichtbar
    test = subprocess.run(["pdftoppm", "-r", "20", "-png", ausgabe, os.path.join(werkstatt, ".selbsttest")],
                          capture_output=True, text=True)
    for f in os.listdir(werkstatt):
        if f.startswith(".selbsttest"):
            os.remove(os.path.join(werkstatt, f))
    mb = os.path.getsize(ausgabe) / 1e6
    warn = f" ⚠️ Render-Warnung: {test.stderr.strip()[:200]}" if test.stderr.strip() else ""
    return True, f"{len(seiten)} Seite(n) → {os.path.basename(ausgabe)} ({mb:.1f} MB){warn}"


# ---------------------------------------------------------------- Server

def mache_handler(werkstatt, ausgabe, dpi):
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=werkstatt, **kw)

        def do_GET(self):
            if self.path == "/scan_tool.html":
                with open(os.path.join(HIER, "scan_tool.html"), "rb") as f:
                    body = f.read()
                return self._antwort(body, "text/html; charset=utf-8")
            if self.path == "/daten":
                d = lade_punkte(werkstatt)
                d["ausgabe"] = os.path.basename(ausgabe); d["dpi"] = dpi
                return self._json(d)
            return super().do_GET()

        def do_POST(self):
            laenge = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(laenge)) if laenge else {}
            if self.path == "/speichern":
                speichere_punkte(werkstatt, {"seiten": body["seiten"]})
                return self._json({"ok": True, "meldung": "gespeichert"})
            if self.path in ("/bauen", "/fertig"):
                daten = {"seiten": body["seiten"]}
                speichere_punkte(werkstatt, daten)
                try:
                    ok, meldung = baue_pdf(werkstatt, daten, ausgabe, dpi)
                    if ok and self.path == "/bauen":
                        subprocess.Popen(["open", ausgabe])
                except subprocess.CalledProcessError as e:
                    ok, meldung = False, f"Fehler: {e}"
                if self.path == "/fertig" and ok:
                    with open(os.path.join(werkstatt, "fertig.json"), "w") as f:
                        json.dump({"ausgabe": ausgabe, "meldung": meldung,
                                   "seiten": [s["id"] for s in daten["seiten"] if s.get("aktiv", True)]}, f, indent=1)
                    self._json({"ok": True, "meldung": meldung + " — fertig, Server beendet sich."})
                    import threading
                    threading.Thread(target=self.server.shutdown, daemon=True).start()
                    return
                return self._json({"ok": ok, "meldung": meldung})
            if self.path == "/vorschau_voll":
                daten = {"seiten": body["seiten"]}
                seite = next(s for s in daten["seiten"] if s["id"] == body["id"])
                if not seite.get("punkte"):
                    return self._json({"ok": False, "meldung": "keine Punkte"})
                os.makedirs(os.path.join(werkstatt, "vorschau_voll"), exist_ok=True)
                try:
                    with tempfile.TemporaryDirectory() as tmp:
                        jpg = baue_seite(werkstatt, seite, 110, tmp)
                    ziel = os.path.join(werkstatt, "vorschau_voll", seite["id"] + ".jpg")
                    shutil.copy(jpg, ziel)
                    return self._json({"ok": True, "url": f"vorschau_voll/{seite['id']}.jpg?{os.path.getmtime(ziel)}"})
                except Exception as e:
                    return self._json({"ok": False, "meldung": f"Fehler: {e}"})
            if self.path == "/ecken":
                daten = {"seiten": body["seiten"]}
                seite = next(s for s in daten["seiten"] if s["id"] == body["id"])
                try:
                    erg = magic_fit(werkstatt, seite)
                    erg.get("info", {}).pop("kanten", None)
                    return self._json(erg)
                except Exception as e:
                    return self._json({"ok": False, "meldung": f"Magic Fit fehlgeschlagen: {e}"})
            if self.path == "/drehen":
                daten = {"seiten": body["seiten"]}
                seite = next(s for s in daten["seiten"] if s["id"] == body["id"])
                drehe_seite(werkstatt, seite, body["grad"])
                speichere_punkte(werkstatt, daten)
                return self._json({"ok": True, "seite": seite})
            self.send_error(404)

        def _json(self, obj):
            self._antwort(json.dumps(obj, ensure_ascii=False).encode(), "application/json")

        def _antwort(self, body, typ):
            self.send_response(200)
            self.send_header("Content-Type", typ)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *a):
            pass
    return Handler


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("fotos", nargs="*", help="Fotos/Bilder (jpg, png, heic, pdf-Seite …)")
    ap.add_argument("-o", "--ausgabe", help="Ziel-PDF (Default: Scan.pdf im aktuellen Ordner)")
    ap.add_argument("--werkstatt", help="Werkstatt-Ordner (Default: scan_werkstatt/ neben der Ausgabe)")
    ap.add_argument("--dpi", type=int, default=200)
    ap.add_argument("--port", type=int, default=PORT)
    ap.add_argument("--bauen", action="store_true", help="PDF direkt aus punkte.json bauen, kein Browser")
    ap.add_argument("--kein-browser", action="store_true")
    ap.add_argument("--auto", action="store_true", help="Magic Fit für alle Seiten ohne Punkte vorab ausführen (Knickzahl automatisch)")
    a = ap.parse_args()

    ausgabe = os.path.abspath(a.ausgabe or "Scan.pdf")
    werkstatt = os.path.abspath(a.werkstatt or os.path.join(os.path.dirname(ausgabe), "scan_werkstatt"))
    os.makedirs(werkstatt, exist_ok=True)
    daten = lade_punkte(werkstatt)
    if a.fotos:
        importiere(werkstatt, a.fotos, daten)
    if not daten["seiten"]:
        sys.exit("Keine Seiten — Fotos angeben.")
    if a.auto:
        for s_ in daten["seiten"]:
            if not s_.get("punkte"):
                auto_fit_seite(werkstatt, s_)
                print(f"  auto: {s_['id'][:40]}  Knicke {s_.get('knicke')}  {s_.get('auto')}")
        speichere_punkte(werkstatt, daten)
    if a.bauen:
        ok, meldung = baue_pdf(werkstatt, daten, ausgabe, a.dpi)
        print(meldung); sys.exit(0 if ok else 1)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", a.port), mache_handler(werkstatt, ausgabe, a.dpi)) as httpd:
        url = f"http://localhost:{a.port}/scan_tool.html"
        print(f"Scan-Werkstatt: {url}\n  Werkstatt: {werkstatt}\n  Ausgabe:   {ausgabe}\n  (Beenden: Ctrl+C)")
        if not a.kein_browser:
            webbrowser.open(url)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
    fertig = os.path.join(werkstatt, "fertig.json")
    if os.path.exists(fertig):
        with open(fertig) as f:
            print("FERTIG:", json.load(f)["meldung"], "→", ausgabe)


if __name__ == "__main__":
    main()
