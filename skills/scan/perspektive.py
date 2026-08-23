#!/usr/bin/env python3
"""Experiment: Kamerapose + Scharniermodell für gefaltete Blätter.

Idee (Mats, 23.08.): Aus dem Bild-Viereck eines bekannten Rechtecks (A4-Drittel 210×99 mm) folgt bei fester
Brennweite die Kamerapose. Zwei verlässliche Drittel → Knickwinkel θ₁ aus der Konsistenz der Kameraposition.
Ein drittes, schlecht messbares Drittel hängt als starres Rechteck an der Falz: nur θ₂ unbekannt → aus der
einen messbaren Kante bestimmbar → Gegenkante/Ecken physikalisch vorhergesagt.

Koordinaten: Blattrahmen je Drittel: Ursprung TL, x nach rechts, y nach unten (in der Ebene), z = Normale.
Kamera: X_cam = R·X + t; Bild: u = f·X/Z + cx, v = f·Y/Z + cy.
"""
import math, sys, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import inhalt


def mat_vec(M, v):
    return [sum(M[i][j] * v[j] for j in range(3)) for i in range(3)]


def mat_mul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def transp(M):
    return [[M[j][i] for j in range(3)] for i in range(3)]


def rx(th):
    c, s = math.cos(th), math.sin(th)
    return [[1, 0, 0], [0, c, -s], [0, s, c]]


def norm(v):
    return math.sqrt(sum(x * x for x in v))


def pose(quad_px, breite_mm, hoehe_mm, f, cx, cy):
    """Homographie mm→px zerlegen (bekanntes f, Hauptpunkt cx,cy) → R (3x3), t (3) mit X_cam = R·X_mm + t."""
    src = [(0, 0), (breite_mm, 0), (breite_mm, hoehe_mm), (0, hoehe_mm)]
    dst = [((x - cx) / f, (y - cy) / f) for x, y in quad_px]   # normierte Bildkoordinaten
    h = inhalt.homographie(src, dst)
    Hm = [[h[0], h[1], h[2]], [h[3], h[4], h[5]], [h[6], h[7], 1.0]]
    r1 = [Hm[0][0], Hm[1][0], Hm[2][0]]; r2 = [Hm[0][1], Hm[1][1], Hm[2][1]]; t = [Hm[0][2], Hm[1][2], Hm[2][2]]
    lam = (norm(r1) + norm(r2)) / 2
    r1 = [v / lam for v in r1]; r2 = [v / lam for v in r2]; t = [v / lam for v in t]
    if t[2] < 0:   # Kamera vor dem Blatt
        r1, r2, t = [-v for v in r1], [-v for v in r2], [-v for v in t]
    # r2 orthogonalisieren (Gram-Schmidt), r3 = r1 × r2
    d = sum(a * b for a, b in zip(r1, r2)); r2 = [b - d * a for a, b in zip(r1, r2)]; n2 = norm(r2); r2 = [v / n2 for v in r2]
    r3 = [r1[1] * r2[2] - r1[2] * r2[1], r1[2] * r2[0] - r1[0] * r2[2], r1[0] * r2[1] - r1[1] * r2[0]]
    R = [[r1[0], r2[0], r3[0]], [r1[1], r2[1], r3[1]], [r1[2], r2[2], r3[2]]]
    return R, t


def kamera_zentrum(R, t):
    Rt = transp(R); return [-v for v in mat_vec(Rt, t)]


def projiziere(R, t, X, f, cx, cy):
    Xc = [a + b for a, b in zip(mat_vec(R, X), t)]
    return (f * Xc[0] / Xc[2] + cx, f * Xc[1] / Xc[2] + cy)


def scharnier(R0, t0, h0, theta):
    """Pose des Nachbardrittels (unter Drittel 0, Scharnier an dessen Unterkante y=h0, Drehung um x um theta).
    X_0 = (0,h0,0) + Rx(theta)·X_1  →  X_cam = R0·X_0 + t0 = (R0·Rx)·X_1 + (R0·(0,h0,0) + t0)."""
    R1 = mat_mul(R0, rx(theta)); t1 = [a + b for a, b in zip(mat_vec(R0, [0, h0, 0]), t0)]
    return R1, t1


def exif_brennweite_px(pfad, W, H):
    """f_px aus EXIF FocalLengthIn35mmFilm (35-mm-Äquivalent bezieht sich auf die Bilddiagonale 43,27 mm)."""
    try:
        from PIL import Image
        ex = Image.open(pfad).getexif()
        f35 = ex.get(41989) or ex.get_ifd(0x8769).get(41989)
        if f35:
            return f35 / 43.27 * math.hypot(W, H), f35
    except Exception:
        pass
    return None, None


if __name__ == "__main__":
    import scan_tool as st
    satz = sys.argv[1] if len(sys.argv) > 1 else "benchmark/projektfotos_2026-08-23"
    idx = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    ref = json.load(open(os.path.join(satz, "referenz.json"))); s = ref["seiten"][idx]
    W, H = s["breite"], s["hoehe"]; cx, cy = W / 2, H / 2
    f_exif, f35 = exif_brennweite_px(s["quelle"], W, H) if os.path.exists(s.get("quelle", "")) else (None, None)
    f = f_exif or 0.75 * max(W, H)
    print(f"{s['id'][:24]}: f = {f:.0f} px ({'EXIF ' + str(f35) + ' mm' if f_exif else 'Annahme 0,75·Bild'})")
    mf = st.magic_fit(satz, s)
    n = s["knicke"]; hk = [s["falz_mm"][0]] + [s["falz_mm"][1] - s["falz_mm"][0]] + [297 - s["falz_mm"][1]] if n == 2 else [297]
    px = lambda p: (p[0] * W, p[1] * H)
    for name, P in (("Auto", mf["punkte"]), ("Mats", s["punkte"])):
        print(name)
        posen = []
        for k in range(n + 1):
            q = [px(P[2 * k]), px(P[2 * k + 1]), px(P[2 * k + 3]), px(P[2 * k + 2])]
            R, t = pose(q, 210, hk[k], f, cx, cy); C = kamera_zentrum(R, t); posen.append((R, t))
            print(f"  Drittel {k}: Kamera im Drittelrahmen x={C[0]:+.0f} y={C[1]:+.0f} z={C[2]:+.0f} mm  (Neigung seitlich {math.degrees(math.atan2(C[0]-105, abs(C[2]))):+.1f}°, längs {math.degrees(math.atan2(C[1]-hk[k]/2, abs(C[2]))):+.1f}°)")
        if n >= 1:
            # θ1: Drittel 1 als Scharnier an Drittel 0 — Winkel, der Drittel-1-Ecken am besten reproduziert
            R0, t0 = posen[0]
            best = None
            for deg in range(-60, 61):
                R1, t1 = scharnier(R0, t0, hk[0], math.radians(deg))
                ecken1 = [(0, 0, 0), (210, 0, 0), (210, hk[1], 0), (0, hk[1], 0)]
                soll = [px(P[2]), px(P[3]), px(P[5]), px(P[4])]
                err = sum(math.dist(projiziere(R1, t1, X, f, cx, cy), q) for X, q in zip(ecken1, soll)) / 4
                if best is None or err < best[0]:
                    best = (err, deg, R1, t1)
            print(f"  Scharnier θ1 = {best[1]:+d}° (Reprojektionsfehler Drittel-1-Ecken {best[0]:.1f} px = {best[0]/max(W,H)*100:.2f} %)")
        if n == 2:
            # θ2: Drittel 2 hängt an Drittel 1 (Scharnier-Pose aus θ1); bestimme θ2 über die LINKE Kante (K2L→BL)
            R1, t1 = best[2], best[3]
            bestk = None
            for deg in range(-60, 61):
                R2, t2 = scharnier(R1, t1, hk[1], math.radians(deg))
                links = [projiziere(R2, t2, (0, y, 0), f, cx, cy) for y in (0, hk[2] / 2, hk[2])]
                soll = [px(P[4]), None, px(P[6])]
                err = math.dist(links[0], soll[0]) + math.dist(links[2], soll[2])
                if bestk is None or err < bestk[0]:
                    bestk = (err, deg, R2, t2)
            R2, t2 = bestk[2], bestk[3]
            vBL = projiziere(R2, t2, (0, hk[2], 0), f, cx, cy); vBR = projiziere(R2, t2, (210, hk[2], 0), f, cx, cy); vK2R = projiziere(R2, t2, (210, 0, 0), f, cx, cy)
            M = max(W, H)
            print(f"  Scharnier θ2 = {bestk[1]:+d}° → Vorhersage BL ({vBL[0]/W:.3f},{vBL[1]/H:.3f}) BR ({vBR[0]/W:.3f},{vBR[1]/H:.3f}) K2R ({vK2R[0]/W:.3f},{vK2R[1]/H:.3f})")
            RP = s["punkte"]
            print(f"     Fehler zur Mats-Referenz: BL {math.dist(vBL, px(RP[6]))/M*100:.1f} %  BR {math.dist(vBR, px(RP[7]))/M*100:.1f} %  K2R {math.dist(vK2R, px(RP[5]))/M*100:.1f} %   (Auto aktuell: BL {math.dist(px(mf['punkte'][6]), px(RP[6]))/M*100:.1f} %  BR {math.dist(px(mf['punkte'][7]), px(RP[7]))/M*100:.1f} %)")
