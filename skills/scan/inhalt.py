#!/usr/bin/env python3
"""Inhaltsbasierte Verfeinerung („Magic Fit" Stufe B): Das Blattmodell (4/6/8 Punkte + Kanten-Wölbung) wird so
optimiert, dass (1) erkannte Textzeilen nach der Entzerrung waagerecht liegen, (2) die gemessenen Papierrand-
punkte auf den Blattkanten des Modells landen und (3) das Modell nahe am Startwert bleibt.

Mathematik: Vorwärtsabbildung F(u, v) = Zielblatt (0..1)² → Quellbild (normiert) ist dieselbe wie im
Gitter-Warp von scan_tool (Paneel-Homographie + Coons-Überlagerung der Randwölbungen). Die Umkehrung
F⁻¹ wird numerisch (Start: inverse Paneel-Homographie, dann Newton) berechnet. Optimiert wird mit einer
Mustersuche (koordinatenweise, adaptive Schrittweite) — keine Abhängigkeiten außer der Standardbibliothek.
"""
import math

FORMATE_MM = {"A4": (210, 297), "A5": (148, 210), "DINlang": (99, 210), "Letter": (215.9, 279.4)}


def _loese(A, b):
    n = len(b); A = [r[:] for r in A]; b = b[:]
    for i in range(n):
        p = max(range(i, n), key=lambda r: abs(A[r][i])); A[i], A[p] = A[p], A[i]; b[i], b[p] = b[p], b[i]
        if abs(A[i][i]) < 1e-12:
            return None
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
    return _loese(A, b)


def anw(h, x, y):
    w = h[6] * x + h[7] * y + 1
    return ((h[0] * x + h[1] * y + h[2]) / w, (h[3] * x + h[4] * y + h[5]) / w)


class Modell:
    """Blattmodell in normierten Bildkoordinaten; Zielblatt-Koordinaten (u, v) ∈ [0,1]²."""

    def __init__(self, punkte, rundung, knicke, falz_mm, format_mm, bw, bh):
        self.P = [list(p) for p in punkte]; self.R = {k: list(v) for k, v in (rundung or {}).items()}
        self.n = knicke; self.bw, self.bh = bw, bh
        mm_h = format_mm[1]
        self.ys = [0.0] + [f / mm_h for f in falz_mm[:knicke]] + [1.0]
        self.mm = format_mm
        self._bereit()

    def _bereit(self):
        self.H, self.Hinv = [], []
        for k in range(self.n + 1):
            P = self.P
            src = [P[2 * k], P[2 * k + 1], P[2 * k + 3], P[2 * k + 2]]
            dst = [(0, self.ys[k]), (1, self.ys[k]), (1, self.ys[k + 1]), (0, self.ys[k + 1])]
            self.H.append(homographie(dst, src)); self.Hinv.append(homographie(src, dst))

    def dev(self, key):
        return self.R.get(key, [0.0, 0.0])

    def vorw(self, u, v):
        """Zielblatt (u, v) → Quellbild (normiert)."""
        k = min(self.n, max(0, next((i for i in range(self.n + 1) if v < self.ys[i + 1]), self.n)))
        y0, y1 = self.ys[k], self.ys[k + 1]
        t = (v - y0) / (y1 - y0) if y1 > y0 else 0
        bx, by = anw(self.H[k], u, v)
        bl, bu = 4 * t * (1 - t), 4 * u * (1 - u)
        dL, dR, dT, dB = self.dev(f"L{k}"), self.dev(f"R{k}"), self.dev(f"H{k}"), self.dev(f"H{k + 1}")
        dx = ((1 - u) * dL[0] + u * dR[0]) * bl + ((1 - t) * dT[0] + t * dB[0]) * bu
        dy = ((1 - u) * dL[1] + u * dR[1]) * bl + ((1 - t) * dT[1] + t * dB[1]) * bu
        return (bx + dx, by + dy)

    def rueck(self, x, y):
        """Quellbild (normiert) → Zielblatt (u, v), numerisch (inverse Homographie + Newton)."""
        best = None
        for k in range(self.n + 1):
            if self.Hinv[k] is None:
                continue
            u, v = anw(self.Hinv[k], x, y)
            d = 0 if self.ys[k] <= v <= self.ys[k + 1] else min(abs(v - self.ys[k]), abs(v - self.ys[k + 1]))
            if best is None or d < best[0]:
                best = (d, u, v)
        if best is None:
            return (x, y)
        _, u, v = best
        eps = 1e-4
        for _ in range(6):
            fx, fy = self.vorw(u, v)
            ex, ey = (fx - x) * self.bw, (fy - y) * self.bh
            if abs(ex) + abs(ey) < 0.05:
                break
            ax, ay = self.vorw(u + eps, v); bx, by = self.vorw(u, v + eps)
            J = [[(ax - fx) * self.bw / eps, (bx - fx) * self.bw / eps],
                 [(ay - fy) * self.bh / eps, (by - fy) * self.bh / eps]]
            det = J[0][0] * J[1][1] - J[0][1] * J[1][0]
            if abs(det) < 1e-9:
                break
            du = (J[1][1] * ex - J[0][1] * ey) / det; dv = (-J[1][0] * ex + J[0][0] * ey) / det
            u -= du; v -= dv
        return (u, v)


def zeilen_aufbereiten(lines, ecken, bw, bh, min_breite=0.04):
    """Textzeilen (Vision-Quads, normiert) → [(links_mitte, rechts_mitte, gewicht)], nur Zeilen im Blatt und
    breit genug; Gewicht = Breite in Bildpixeln."""
    def innerhalb(p):  # grob: Punkt im Vision-Viereck (konvex) per Kreuzprodukt
        TL, TR, BR, BL = ecken; q = [TL, TR, BR, BL]
        s = 0
        for i in range(4):
            a, b = q[i], q[(i + 1) % 4]
            c = (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
            s += 1 if c >= 0 else -1
        return abs(s) == 4
    out = []
    for l in lines:
        tl, tr, br, bl = l["quad"]
        L = ((tl[0] + bl[0]) / 2, (tl[1] + bl[1]) / 2); Rm = ((tr[0] + br[0]) / 2, (tr[1] + br[1]) / 2)
        breite = math.hypot((Rm[0] - L[0]) * bw, (Rm[1] - L[1]) * bh) / max(bw, bh)
        if breite < min_breite or not (innerhalb(L) and innerhalb(Rm)):
            continue
        out.append((L, Rm, breite))
    return out


def zeilen_neigung(modell, zeilen):
    """Gewichtete mittlere |Neigung| (Grad) der Zeilen nach der Entzerrung — die Metrik „Zeilengeradheit"."""
    if not zeilen:
        return None
    sw = sg = 0.0
    for L, Rm, w in zeilen:
        u1, v1 = modell.rueck(*L); u2, v2 = modell.rueck(*Rm)
        dx, dy = (u2 - u1) * modell.mm[0], (v2 - v1) * modell.mm[1]
        if abs(dx) < 1e-6:
            continue
        sw += w * abs(math.degrees(math.atan2(dy, dx))); sg += w
    return sw / sg if sg else None


def verfeinere(punkte, rundung, knicke, falz_mm, fmt, bw, bh, lines, kanten, ecken_vision,
               max_runden=60, schritt0=0.012, log=None, nur_bewerten=False, fest=()):
    """Optimiert Punkte + Wölbung. kanten = {"L": [...], "R": [...], "O": [...], "U": [...]} gemessene
    Randpunkte (normiert). Rückgabe (punkte, rundung, bericht)."""
    fm = FORMATE_MM.get(fmt, FORMATE_MM["A4"])
    zeilen = zeilen_aufbereiten(lines, ecken_vision, bw, bh)
    # Randpunkte ausdünnen (max ~40 je Kante)
    kant = {}
    for key, pts in kanten.items():
        pts = list(pts); schritt = max(1, len(pts) // 40); kant[key] = pts[::schritt]
    start_P = [list(p) for p in punkte]
    # Parameter: alle Punktkoordinaten + Wölbungs-Skalare entlang der Kantennormalen
    keys = [f"L{k}" for k in range(knicke + 1)] + [f"R{k}" for k in range(knicke + 1)] + ["H0", f"H{knicke + 1}"]

    def kante_ab(key, P):
        if key[0] == "H":
            i = int(key[1:]); return P[2 * i], P[2 * i + 1]
        k = int(key[1:]); return (P[2 * k], P[2 * k + 2]) if key[0] == "L" else (P[2 * k + 1], P[2 * k + 3])

    def normale(key, P):
        A, B = kante_ab(key, P); ax, ay = (B[0] - A[0]) * bw, (B[1] - A[1]) * bh; L = math.hypot(ax, ay) or 1
        return (-ay / L, ax / L)

    def skalar(key, vec, P):
        n = normale(key, P); return vec[0] * bw * n[0] + vec[1] * bh * n[1]

    def vektor(key, s, P):
        n = normale(key, P); return [s * n[0] / bw, s * n[1] / bh]

    # Startwölbung: links/rechts je Drittel mitteln (Physik: gemeinsames Profil), entlang der Außennormalen
    def aussen_skalar(key, P, R):
        sk = skalar(key, (R or {}).get(key, [0, 0]), P)
        k = int(key[1:]); Z = [sum(P[2 * k + j][0] for j in range(4)) / 4, sum(P[2 * k + j][1] for j in range(4)) / 4]
        A, B = kante_ab(key, P); M = [(A[0] + B[0]) / 2, (A[1] + B[1]) / 2]; n = normale(key, P)
        vorz = 1 if (M[0] - Z[0]) * bw * n[0] + (M[1] - Z[1]) * bh * n[1] >= 0 else -1
        return sk * vorz, vorz   # Skalar nach außen, und Vorzeichen der Normalen relativ zu "außen"
    start_R = dict(rundung or {})
    for k in range(knicke + 1):
        (aL, vL), (aR, vR) = aussen_skalar(f"L{k}", punkte, rundung), aussen_skalar(f"R{k}", punkte, rundung)
        mittel = (aL + aR) / 2
        start_R[f"L{k}"] = vektor(f"L{k}", mittel * vL, punkte); start_R[f"R{k}"] = vektor(f"R{k}", mittel * vR, punkte)
    x = [c for p in punkte for c in p] + [skalar(k, start_R.get(k, [0, 0]), punkte) for k in keys]
    npk = len(punkte) * 2
    mm_px = 297.0 / max(bw, bh)   # px → mm (längere Bildkante ≙ Blatthöhe, grob)
    # Linksbündige Gruppen (im Startmodell): Zeilen, deren linker Rand in derselben Spalte liegt (±2,5 mm),
    # mindestens 3 Zeilen, die sich über ≥ 25 mm Höhe verteilen
    m_start = Modell(punkte, start_R, knicke, falz_mm, fm, bw, bh)
    links_u = [(m_start.rueck(*L), i) for i, (L, Rm, w) in enumerate(zeilen)]
    gruppen = []
    rest = sorted(links_u, key=lambda t: t[0][0])
    while rest:
        (u0, v0), i0 = rest[0]; grp = [(u, v, i) for (u, v), i in rest if abs(u - u0) * fm[0] <= 2.5]
        rest = [t for t in rest if t[1] not in {g[2] for g in grp}]
        vs = [g[1] for g in grp]
        if len(grp) >= 3 and (max(vs) - min(vs)) * fm[1] >= 25:
            gruppen.append([g[2] for g in grp])

    fest = set(fest)   # unzuverlässig gemessene Kanten: Wölbung nicht frei optimieren, sondern an die Gegenseite koppeln
    def bau(x):
        P = [[x[2 * i], x[2 * i + 1]] for i in range(len(punkte))]
        R = {k: vektor(k, x[npk + j], P) for j, k in enumerate(keys)}
        for k in fest:
            if k[0] in "LR":
                partner = ("R" if k[0] == "L" else "L") + k[1:]
                if partner in R and partner not in fest:
                    a, _ = aussen_skalar(partner, P, R); _, vz = aussen_skalar(k, P, {k: vektor(k, 1.0, P)})
                    R[k] = vektor(k, a * vz, P)
                else:
                    R[k] = [0.0, 0.0]
        return Modell(P, R, knicke, falz_mm, fm, bw, bh)

    def teile(x):
        m = bau(x)
        if any(h is None for h in m.H):
            return {"ungueltig": 1e9}
        T = {"zeilen": 0.0, "rand_L": 0.0, "rand_R": 0.0, "rand_O": 0.0, "rand_U": 0.0, "linksbuendig": 0.0, "kopplung": 0.0, "regul": 0.0}
        # (1) Zeilen waagerecht (Grad², robust gedeckelt)
        for L, Rm, w in zeilen:
            u1, v1 = m.rueck(*L); u2, v2 = m.rueck(*Rm)
            dx, dy = (u2 - u1) * fm[0], (v2 - v1) * fm[1]
            if abs(dx) < 1e-6:
                continue
            a = math.degrees(math.atan2(dy, dx)); T["zeilen"] += w * min(a * a, 25.0)
        # (2) Randpunkte auf den Kanten (mm², gedeckelt)
        for key, pts in kant.items():
            for (px, py) in pts:
                u, v = m.rueck(px, py)
                d = {"L": u * fm[0], "R": (u - 1) * fm[0], "O": v * fm[1], "U": (v - 1) * fm[1]}[key]
                T["rand_" + key] += 0.15 * min(d * d, 36.0)
        # (2b) Linksbündigkeit: linke Zeilenanfänge einer Gruppe stehen untereinander (mm², gedeckelt)
        for grp in gruppen:
            us = [m.rueck(*zeilen[i][0])[0] * fm[0] for i in grp]
            mu = sum(us) / len(us)
            for u_ in us:
                T["linksbuendig"] += 0.25 * min((u_ - mu) ** 2, 25.0)
        # (2c) Kopplung der Wölbung links ↔ rechts je Drittel (mm², weich): gemeinsames 3D-Profil
        P_ = [[x[2 * i], x[2 * i + 1]] for i in range(len(punkte))]
        for k in range(knicke + 1):
            jL, jR = keys.index(f"L{k}"), keys.index(f"R{k}")
            aL = x[npk + jL] * aussen_skalar(f"L{k}", P_, {f"L{k}": vektor(f"L{k}", 1.0, P_)})[1]
            aR = x[npk + jR] * aussen_skalar(f"R{k}", P_, {f"R{k}": vektor(f"R{k}", 1.0, P_)})[1]
            T["kopplung"] += 0.08 * ((aL - aR) * mm_px) ** 2   # weich: gemessene Kanten sollen gewinnen
        # (3) Regularisierung: Punkte nahe Startwert (mm²)
        for i, p in enumerate(start_P):
            T["regul"] += 0.02 * (((x[2 * i] - p[0]) * bw / max(bw, bh) * 297) ** 2 + ((x[2 * i + 1] - p[1]) * bh / max(bw, bh) * 297) ** 2)
        return T

    def kosten(x):
        return sum(teile(x).values())

    if nur_bewerten:   # Diagnose: Zielfunktions-Terme für genau dieses Modell (ohne Mittelung der Wölbung)
        x_roh = [c for p in punkte for c in p] + [skalar(k, (rundung or {}).get(k, [0, 0]), punkte) for k in keys]
        return teile(x_roh)

    J0 = kosten(x); bericht = {"start": J0, "zeilen": len(zeilen), "gruppen": [len(g) for g in gruppen]}
    m0 = bau(x); bericht["neigung_start"] = zeilen_neigung(m0, zeilen)
    schritte = [schritt0] * npk + [schritt0 * max(bw, bh) * 0.5] * len(keys)
    J = J0
    for runde in range(max_runden):
        verbessert = False
        for i in range(len(x)):
            if i >= npk and keys[i - npk] in fest:
                continue
            for richtung in (1, -1):
                xn = x[:]; xn[i] += richtung * schritte[i]
                Jn = kosten(xn)
                if Jn < J - 1e-6:
                    x, J, verbessert = xn, Jn, True
                    break
        if not verbessert:
            schritte = [s * 0.5 for s in schritte]
            if schritte[0] < 0.0006:
                break
        if log:
            log(f"Runde {runde}: J={J:.1f}")
    m = bau(x)
    bericht.update(ende=J, neigung_ende=zeilen_neigung(m, zeilen))
    return m.P, m.R, bericht


# ---------------------------------------------------------------- Naht-Stetigkeit (Falzposition)

def _strip_rendern(img_klein, modell, v_mitte, hoehe_v, breite_px, zeilen_px):
    """Rendert einen horizontalen Streifen des Zielblatts um v_mitte (±hoehe_v) aus dem verkleinerten Grau-
    bild per PIL-MESH (Zellen 12×zeilen) → PIL-Bild breite_px × zeilen_px."""
    from PIL import Image
    W, H = img_klein.size
    nx, ny = 12, max(4, zeilen_px // 4)
    v0, v1 = v_mitte - hoehe_v, v_mitte + hoehe_v
    mesh = []
    for j in range(ny):
        ya, yb = round(j * zeilen_px / ny), round((j + 1) * zeilen_px / ny)
        va, vb = v0 + (v1 - v0) * j / ny, v0 + (v1 - v0) * (j + 1) / ny
        for i in range(nx):
            xa, xb = round(i * breite_px / nx), round((i + 1) * breite_px / nx)
            ua, ub = i / nx, (i + 1) / nx
            nw = modell.vorw(ua, va); sw = modell.vorw(ua, vb); se = modell.vorw(ub, vb); ne = modell.vorw(ub, va)
            mesh.append(((xa, ya, xb, yb), (nw[0] * W, nw[1] * H, sw[0] * W, sw[1] * H, se[0] * W, se[1] * H, ne[0] * W, ne[1] * H)))
    return img_klein.transform((breite_px, zeilen_px), Image.MESH, mesh, resample=Image.BILINEAR, fillcolor=255)


def naht_unstetigkeit(img_klein, modell, v_naht, hoehe_v=0.035, breite_px=360, zeilen_px=48):
    """Maß für den Sprung des Inhalts an der Naht: mittlere |Differenz| der Zeilen knapp über/unter der Naht,
    normiert auf die typische Zeilendifferenz im Streifen (1.0 ≈ unauffällig, >1 = Sprung). Beleuchtungs-
    unterschied der Paneele wird durch Spaltenmittel-Abgleich je Hälfte herausgerechnet."""
    strip = _strip_rendern(img_klein, modell, v_naht, hoehe_v, breite_px, zeilen_px)
    px = strip.load(); m = zeilen_px // 2; rand = max(2, breite_px // 20)
    def zeile(y):
        return [px[x, y] for x in range(rand, breite_px - rand)]
    # Beleuchtung: obere und untere Hälfte auf gleiches Mittel bringen
    ob = [zeile(y) for y in range(m - 6, m - 1)]; un = [zeile(y) for y in range(m + 2, m + 7)]
    mo = sum(sum(z) for z in ob) / (len(ob) * len(ob[0])); mu = sum(sum(z) for z in un) / (len(un) * len(un[0]))
    offs = mu - mo
    def diff(a, b, korr=0.0):
        return sum(abs(x - y - korr) for x, y in zip(a, b)) / len(a)
    naht = diff(zeile(m - 2), zeile(m + 2), -offs)
    # lokale „natürliche" Zeilendifferenz direkt neben der Naht (nicht über die Naht hinweg)
    typ = [diff(zeile(y - 2), zeile(y + 2)) for y in (m - 7, m - 5, m + 5, m + 7)]
    typ_m = sum(typ) / len(typ)
    eps = 3.0   # Graustufen-Rauschen: Leerflächen → (0+ε)/(0+ε) = 1 (neutral), echter Sprung > 1, stetiger Inhalt < 1
    return (naht + eps) / (typ_m + eps)


def verfeinere_falten(img_klein, punkte, rundung, knicke, falz_mm, fmt, bw, bh, bereich=0.04, schritt=0.005, log=None):
    """Verschiebt je Falz die beiden Endpunkte entlang ihrer Kanten (Raster ±bereich), bis der Inhalt über die
    Naht hinweg am stetigsten ist. Rückgabe (punkte, bericht)."""
    fm = FORMATE_MM.get(fmt, FORMATE_MM["A4"])
    P = [list(p) for p in punkte]; bericht = []
    for k in range(knicke):
        iL, iR = 2 * (k + 1), 2 * (k + 1) + 1
        # Verschiebung d entlang der jeweiligen Kante (Richtung: Vorgänger- → Nachfolgerpunkt derselben Seite)
        startL, startR = list(P[iL]), list(P[iR])
        v_naht = falz_mm[k] / fm[1]
        schritte = [round(-bereich + schritt * i, 4) for i in range(int(2 * bereich / schritt) + 1)]
        best = None
        for dl in schritte:
            for dr in schritte:
                if abs(dl - dr) > 0.03:      # Falz läuft annähernd parallel zu den Nachbarn: links/rechts ähnlich
                    continue
                P[iL] = [startL[0] + dl * (P[iL + 2][0] - P[iL - 2][0]), startL[1] + dl * (P[iL + 2][1] - P[iL - 2][1])]
                P[iR] = [startR[0] + dr * (P[iR + 2][0] - P[iR - 2][0]), startR[1] + dr * (P[iR + 2][1] - P[iR - 2][1])]
                m = Modell(P, rundung, knicke, falz_mm, fm, bw, bh)
                if any(h is None for h in m.H):
                    continue
                u = naht_unstetigkeit(img_klein, m, v_naht) + 0.15 * ((dl * dl + dr * dr) / (bereich * bereich))
                if best is None or u < best[0]:
                    best = (u, dl, dr)
        if best:
            u, dl, dr = best
            P[iL] = [startL[0] + dl * (P[iL + 2][0] - P[iL - 2][0]), startL[1] + dl * (P[iL + 2][1] - P[iL - 2][1])]
            P[iR] = [startR[0] + dr * (P[iR + 2][0] - P[iR - 2][0]), startR[1] + dr * (P[iR + 2][1] - P[iR - 2][1])]
            bericht.append({"falz": k + 1, "dl": dl, "dr": dr, "unstetigkeit": round(u, 2)})
            if log:
                log(f"Falz {k + 1}: dl={dl:+.3f} dr={dr:+.3f} Unstetigkeit {u:.2f}")
        else:
            P[iL], P[iR] = startL, startR
    return P, bericht


# ---------------------------------------------------------------- Falzlinie im entzerrten Streifen suchen

def finde_falzlinie(img_klein, modell, v_naht, hoehe_v=0.13, breite_px=360, zeilen_px=208):
    """Sucht im entzerrten Streifen um die angenommene Naht die Falz als dünne Linie (Schatten/Glanz) quer über
    die Seite: Linienantwort r(x,y) = I(y) - Mittel(I(y-4), I(y+4)); Kandidat = Gerade von (0, yl) nach
    (W, yr); Antwort = Median über die Spalten (textrobust). Rückgabe (dv_links, dv_rechts, staerke) als
    Versatz der Naht in Zielblatt-v, oder None, wenn keine klare Linie."""
    strip = _strip_rendern(img_klein, modell, v_naht, hoehe_v, breite_px, zeilen_px)
    px = strip.load(); W, H = breite_px, zeilen_px
    # Linienantwort vorab (gemittelt über 3 Zeilen → Falz ist 2–4 px breit)
    def I(x, y):
        return px[x, max(0, min(H - 1, y))]
    r = [[0.0] * H for _ in range(W)]
    for x in range(W):
        for y in range(5, H - 5):
            mitte = (I(x, y - 1) + I(x, y) + I(x, y + 1)) / 3
            r[x][y] = mitte - (I(x, y - 5) + I(x, y + 5)) / 2
    # Nur die Papierränder (äußere 2–11 % der Breite): eine Falz läuft durch den Rand, gedruckte Linien/Text nicht
    xs = list(range(int(W * 0.02), int(W * 0.11), 2)) + list(range(int(W * 0.89), int(W * 0.98), 2))
    best = None; alle = []
    rng = range(6, H - 6)
    for yl in rng:
        for yr in rng:
            if abs(yr - yl) > H // 3:
                continue
            vals = sorted(r[x][int(round(yl + (yr - yl) * x / W))] for x in xs)
            med = vals[len(vals) // 2]
            # Distanz-Prior: weit von der angenommenen Naht entfernte Kandidaten müssen deutlich stärker sein
            abst = abs((yl + yr) / 2 - H / 2) / (H / 2)
            wert = abs(med) * (1 - 0.8 * abst)
            alle.append(wert)
            if best is None or wert > best[0]:
                best = (wert, yl, yr, med)
    if best is None:
        return None
    alle.sort(); rausch = alle[len(alle) // 2] or 0.5
    staerke = best[0] / rausch
    if best[0] < 1.5 or staerke < 2.5:
        return None
    m = H / 2
    dv_l = (best[1] - m) / H * 2 * hoehe_v; dv_r = (best[2] - m) / H * 2 * hoehe_v
    return dv_l, dv_r, round(staerke, 1), round(best[3], 1)


def verfeinere_falten_linie(img_klein, punkte, rundung, knicke, falz_mm, fmt, bw, bh, log=None):
    """Setzt je Falz die beiden Endpunkte auf die im entzerrten Streifen gefundene Falzlinie (zwei Durchläufe,
    weil sich der Streifen nach der ersten Korrektur verschiebt). Rückgabe (punkte, bericht)."""
    fm = FORMATE_MM.get(fmt, FORMATE_MM["A4"])
    P = [list(p) for p in punkte]; bericht = []
    for k in range(knicke):
        iL, iR = 2 * (k + 1), 2 * (k + 1) + 1; v_naht = falz_mm[k] / fm[1]
        eintrag = {"falz": k + 1, "durchlaeufe": []}
        for durchlauf in range(2):
            m = Modell(P, rundung, knicke, falz_mm, fm, bw, bh)
            if any(h is None for h in m.H):
                break
            erg = finde_falzlinie(img_klein, m, v_naht) if durchlauf == 0 else finde_falzlinie(img_klein, m, v_naht, hoehe_v=0.03, zeilen_px=64)
            if erg is None:
                eintrag["durchlaeufe"].append(None); break
            dv_l, dv_r, staerke, wert = erg
            neuL = m.vorw(0.0, v_naht + dv_l); neuR = m.vorw(1.0, v_naht + dv_r)
            P[iL] = [neuL[0], neuL[1]]; P[iR] = [neuR[0], neuR[1]]
            eintrag["durchlaeufe"].append({"dv_l": round(dv_l, 4), "dv_r": round(dv_r, 4), "staerke": staerke, "wert": wert})
            if abs(dv_l) < 0.003 and abs(dv_r) < 0.003:
                break
        bericht.append(eintrag)
        if log:
            log(str(eintrag))
    return P, bericht
