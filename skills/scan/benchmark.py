#!/usr/bin/env python3
"""Benchmark für „Magic Fit": Auto-Erkennung gegen Mats' manuelle Referenz messen.

    python3 benchmark.py [benchmark/<satz> …]     (Default: alle Sätze unter benchmark/)

Je Satz (unter _lokal/benchmark/<satz>/, nicht versioniert — eigene Fotos!): originale/<id>.png + referenz.json
(= punkte.json aus dem Editor, manuell sauber gesetzt). Anleitung: skills/README.md → „scan: eigenen Benchmark anlegen".
Ausgabe je Seite: Fehler je Ecke/Knickpunkt in % der längeren Bildkante, Knicklagen (t) Auto vs. Referenz.
Wölbungen (rundung) werden nur mitgelistet — die Auto-Erkennung schätzt sie (noch) nicht.
"""
import glob, json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scan_tool as st

HIER = os.path.dirname(os.path.abspath(__file__))


def lauf(satz, stufe="1b"):
    ref = json.load(open(os.path.join(satz, "referenz.json")))
    zeilen, gesamt = [], []
    for s in ref["seiten"]:
        n = s["knicke"]; R = s["punkte"]; M = max(s["breite"], s["hoehe"])
        v = st.finde_ecken(satz, s)
        if stufe == "1":
            TL, TR, BR, BL = v["corners"]; auto = [TL, TR]
            for i in range(n):
                t = (i + 1) / (n + 1); auto += [[TL[0] + (BL[0] - TL[0]) * t, TL[1] + (BL[1] - TL[1]) * t], [TR[0] + (BR[0] - TR[0]) * t, TR[1] + (BR[1] - TR[1]) * t]]
            auto += [BL, BR]; info, rund = {}, {}
        else:
            mf = st.magic_fit(satz, s, inhalt_an=(stufe == "B"))
            auto, rund, info = mf["punkte"], mf["rundung"], mf["info"]
            if stufe == "B": info = dict(info, inhalt=mf.get("inhalt"), naht=mf.get("naht"))
        # Zeilen-Metrik (Neigung nach Entzerrung) für Auto und Referenz
        import inhalt
        fm = inhalt.FORMATE_MM.get(s.get("format", "A4"), inhalt.FORMATE_MM["A4"])
        zl = inhalt.zeilen_aufbereiten(v.get("lines", []), v["corners"], s["breite"], s["hoehe"])
        neig_auto = inhalt.zeilen_neigung(inhalt.Modell(auto, rund, n, s["falz_mm"], fm, s["breite"], s["hoehe"]), zl)
        neig_ref = inhalt.zeilen_neigung(inhalt.Modell(R, s.get("rundung") or {}, n, s["falz_mm"], fm, s["breite"], s["hoehe"]), zl)
        fehler = [math.hypot((a[0] - r[0]) * s["breite"], (a[1] - r[1]) * s["hoehe"]) / M * 100 for a, r in zip(auto, R)]
        namen = ["TL", "TR"] + [f"K{i+1}{lr}" for i in range(n) for lr in "LR"] + ["BL", "BR"]
        # Knicklagen als t entlang der linken Kante (Referenz: Projektion auf TL→BL)
        def t_von(p, A, B):
            ax, ay = B[0] - A[0], B[1] - A[1]; return ((p[0] - A[0]) * ax + (p[1] - A[1]) * ay) / (ax * ax + ay * ay)
        ref_t = [round(t_von(R[2 + 2 * i], R[0], R[-2]), 2) for i in range(n)]
        auto_t = [round(sum(b) / 2, 2) if isinstance(b, list) else round(b, 2) for b in (info.get("bruch") or [])] if info else []
        # Wölbung: Differenz der Griff-Vektoren je Kante in % der längeren Bildkante
        refr = s.get("rundung") or {}
        wkeys = sorted(set(refr) | set(rund))
        wf = {k: math.hypot((rund.get(k, [0, 0])[0] - refr.get(k, [0, 0])[0]) * s["breite"],
                            (rund.get(k, [0, 0])[1] - refr.get(k, [0, 0])[1]) * s["hoehe"]) / M * 100 for k in wkeys}
        zeilen.append((s["id"][:6], fehler, namen, ref_t, auto_t, info, wf, (neig_auto, neig_ref, len(zl))))
        gesamt += fehler
    return zeilen, gesamt


def main():
    stufen = [a for a in sys.argv[1:] if a in ("1", "1b", "B")] or ["1", "1b", "B"]
    saetze = [a for a in sys.argv[1:] if a not in ("1", "1b", "B")] or sorted(glob.glob(os.path.join(HIER, "_lokal", "benchmark", "*")))
    for stufe in stufen:
        print(f"\n=== Stufe {stufe} {'(nur Vision)' if stufe == '1' else '(Vision + Kantenmessung)' if stufe == '1b' else '(+ inhaltsbasierte Verfeinerung)'} ===")
        alle = []
        for satz in saetze:
            zeilen, gesamt = lauf(satz, stufe); alle += gesamt
            for sid, fehler, namen, ref_t, auto_t, info, wf, (na, nr, nz) in zeilen:
                teile = "  ".join(f"{nm}:{f:4.1f}" for nm, f in zip(namen, fehler))
                print(f"{sid}  Ø{sum(fehler)/len(fehler):4.1f}%  max{max(fehler):4.1f}%  | {teile}")
                print(f"        Zeilen-Neigung nach Entzerrung ({nz} Zeilen): Auto {na:.2f}°   Mats-Referenz {nr:.2f}°" if na is not None else "        (keine Zeilen)")
                if info.get("inhalt"): print(f"        Inhalt-Optimierung: J {info['inhalt']['start']:.0f} → {info['inhalt']['ende']:.0f}   Naht: {info.get('naht')}")
                if stufe != "1":
                    print(f"        Knicke t  Ref {ref_t}  Auto {auto_t}  {info.get('unsicher') or ''} {info.get('fallback') or ''}")
                    print("        Wölbung Δ " + "  ".join(f"{k}:{v:.2f}" for k, v in wf.items()) + f"   (Ø {sum(wf.values())/max(1,len(wf)):.2f} %; 0 = wie Referenz)")
        print(f"→ Mittel {sum(alle)/len(alle):.2f} %   Median {sorted(alle)[len(alle)//2]:.2f} %   max {max(alle):.1f} %   (n={len(alle)} Punkte)")


if __name__ == "__main__":
    main()
