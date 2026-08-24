---
name: scan
description: Macht aus Handyfotos von Papier (Briefe, Formulare, auch dreifach gefaltete Blätter mit Knicken) saubere, scanähnliche A4-PDFs — Browser-Editor zum Setzen von 4/6/8 Punkten (Ecken + Knick-Endpunkte), paneelweise Perspektivkorrektur, Schatten-/Beleuchtungsglättung, sRGB ohne Farbprofil. Nutzen, sobald ein Foto als Scan weitergegeben werden soll („mach daraus einen Scan", „entzerr das Foto", Behörden-Anlage aus Fotos, gefalteter Brief), nicht für echte Scanner-PDFs.
---

# Scan-Werkstatt: Foto → Scan-PDF

Eigenes Tooling; braucht `magick` (ImageMagick 7), `img2pdf`, `pdftoppm` und Pillow (System-Python3, für den Gitter-Warp).
Verallgemeinert aus einem Projekt-Eckpunkte-Tool (07/2026); seit 23.08.2026 global, Quelle in `claude-config/skills/scan/`
(Symlink aus `~/.claude/skills/scan`). Lokales (Binary, Benchmark-Fotos) liegt in `_lokal/` — nicht versioniert.

## Standard-Ablauf (seit 23.08.2026 abends) — so wird der Skill benutzt

```bash
python3 ~/.claude/skills/scan/scan_tool.py FOTO1 FOTO2 … -o Ziel.pdf --auto     # Claude: run_in_background=true
```
1. `--auto` importiert alle Fotos, lässt **Magic Fit headless** über jede Seite laufen und speichert
   `punkte.json`, dann öffnet sich der Editor mit den fertigen Vorschlägen (~6 s/Seite). **Knickzahl automatisch:**
   Start mit 2 Knicken; Falzlinien zählen nur ab Stärke ≥ 8 (echte Falzen in 9 Referenzfotos: 12–90, Phantom: 3);
   gefundene < angenommene → Knickzahl senken und neu fitten (Falz bei 148,5 mm für 1 Knick). Ungefaltete
   Blätter landen meist bei 0, gelegentlich bei 1 (Tabellenlinie/zweites Blatt) — im Editor korrigieren,
   ein 1-Knick-Modell auf flachem Papier schadet praktisch nicht.
2. **Mats** klickt die Seiten durch, korrigiert bei Bedarf (Punkte/Wölbung/Knickzahl/Look; „🔍 Volle Vorschau"
   rendert die aktuelle Seite in PDF-Qualität als scrollbares Overlay, Esc schließt) und drückt
   **„✅ Fertig — PDF bauen & schließen"**.
3. Der Server baut das PDF, schreibt `scan_werkstatt/fertig.json`, beendet sich (Exit 0); der Tab zeigt
   „Fertig" und versucht sich zu schließen. **Claude wartet nicht aktiv**, sondern bekommt das Ende des
   Hintergrundprozesses als Task-Benachrichtigung → dann `fertig.json` lesen und weitermachen (PDF liegt unter
   `-o`). Kein Polling, kein Nachfragen „bist du fertig?".
4. Abbruch durch Mats: Tab schließen ohne „Fertig" → Server läuft weiter; Claude beendet ihn mit
   `pkill -f scan_tool.py` (Werkstatt bleibt, `--auto` überspringt Seiten, die schon Punkte haben).

Weitere Aufrufe:
```bash
python3 ~/.claude/skills/scan/scan_tool.py FOTOS… -o Ziel.pdf                  # Editor ohne Vorab-Fit
python3 ~/.claude/skills/scan/scan_tool.py --werkstatt PFAD/scan_werkstatt -o Ziel.pdf --auto --bauen   # komplett headless
```

- Legt `scan_werkstatt/` **neben der Ausgabe** an (`originale/` = auto-orientierte, profilfreie PNGs;
  `vorschau/` fürs Browserbild; `punkte.json` = alle Einstellungen; `arbeit/` = fertige Seiten-JPEGs).
  Erneuter Aufruf mit derselben Werkstatt lädt den Stand; neue Fotos werden angehängt.
- Server auf `localhost:8743` (`--port` bei Kollision; **vorher `pkill -f scan_tool.py`**, falls ein alter läuft).
  „PDF bauen (Vorschau)" baut und öffnet das PDF, ohne den Server zu beenden.
- `--dpi` (Default 200). Ausgabe sRGB/Gray, `-strip` → keine ICC-Falle (Vorschau zeigte bei iPhone-PNG-Profilen
  weiße Seiten), kein jpx.

## Editor-Bedienung (Kurzfassung für die Erklärung an Mats)

| Bereich | Was |
|---|---|
| Links | Seitenliste; Haken = im PDF enthalten; Reihenfolge = Aufrufreihenfolge |
| Blatt | **0 / 1 / 2 Knicke** → 4 / 6 / 8 Punkte. Knicklage auf dem Zielblatt in mm („Standard" = Drittel 99/198 bzw. Hälfte). Format A4/A5/DIN lang/Letter/auto. Drehen ↺↻ (setzt Punkte zurück) |
| Punkte | Reihenfolge pro Zeile links→rechts, Zeilen oben→unten (1 2 = obere Ecken, 3 4 = 1. Knick, …, letzte = untere Ecken). Pfeiltasten = 1 px, ⇧ = 10 px. „Knicke verteilen" legt Knickpunkte gleichmäßig zwischen die Ecken. 10 % Arbeitsrand ums Foto — Punkte dürfen außerhalb liegen (Server füllt weiß). Lupe ist exakt, auch am Rand |
| Wölbung | Klick auf eine Linie → Griff ◆, zieht nur senkrecht zur Sehne (quadratische Bézier). Doppelklick/⌫ = gerade, „Wölbung 0" = alle. **Kopplung links↔rechts je Drittel** (Standard an): gleicher Betrag entlang der jeweiligen Außennormalen — Physik: Papier ist undehnbar, biegt sich je Paneel nur um eine Achse (die Knickrichtung), beide Seitenkanten teilen das Profil, Knicklinien bleiben gerade; verschiedene Drittel dürfen verschieden gewölbt sein. Knick-/Außenlinien sind einzeln wölbbar (quer gerolltes Papier), ungekoppelt |
| Look | `roh` (nur Geometrie) · `farbe` (Schatten/Vignette raus, leicht entsättigt) · `grau` · `sw` (adaptiver Schwellwert) — gilt erst beim Bau |
| Vorschau | live, paneelweise Homographie im Browser (nur Geometrie, ohne Look) |

## Geometrie (warum 8 Punkte reichen)

Gefaltetes Blatt = 2–3 annähernd ebene Paneele. Jedes Paneel wird mit seinen 4 Punkten (eigene Homographie)
auf ein horizontales Band des Zielblatts abgebildet; Bänder werden gestapelt, Knickpunkte sind geteilt → Nähte
passen. Rechnerisch: Paneel → 12×28-Gitter, Zellecken = exakte Homographie + Coons-Überlagerung der vier
Randwölbungen, ein `PIL Image.transform(MESH, BICUBIC)` pro Seite (~1 s). Editor-Vorschau rechnet dasselbe
Gitter (6×14) im Browser. Annahme bei Wölbung: gleicher Kurvenparameter ≙ gleiche Papierlänge (bei moderater
Wölbung zweitrangig). Einzige Annahme: **Lage der Knicke auf dem Ziel** (Default Drittel). Ein Fehler darin staucht nur ein
Paneel leicht (affin, Text bleibt gerade) — unkritisch. Format `auto` schätzt die Knicklage aus den
Kantenlängen im Bild (gut bei frontaler Aufnahme).

## Look-Rezept (ImageMagick)

Beleuchtungsglättung = Bild ÷ stark weichgezeichnete Kopie (`-scale 5% -blur 0x3 -resize zurück`,
`-compose Divide_Dst`), dann `-contrast-stretch 0.3%` und `-level`. `sw` zusätzlich `-lat 30x30-3%`.
Parameter in `scan_tool.py::baue_seite`.

## „Magic Fit" — Button ✨ Ecken finden (Kurzfassung)

Deterministische Pipeline, Details in `ALGORITHMUS.md` (nur nötig, wenn am Fit selbst gearbeitet wird):
**Vision** (Apple-Dokumenterkennung via `docdetect`, beim ersten Aufruf nach `_lokal/bin/` kompiliert,
braucht Xcode-CLT; **nur macOS** — sonst Punkte von Hand) → **Kantenmessung** (robuste Geradenfits,
Ecken auch außerhalb des Fotos) → **Knicksuche** → **Wölbungsschätzung** → **Falzlinien-Suche** →
**inhaltsbasierte Optimierung** (Textzeilen waagerecht + linksbündig, ~2,5 s/Seite) → **Papiermaske**
(alles außerhalb des gemessenen Rands wird weiß). Genauigkeit auf den Referenzsätzen: Ø ≈ 0,9 % der
Bildkante (Vision allein: 3,4 %).

**Bei Algorithmus-Änderungen:** erst `python3 ~/.claude/skills/scan/benchmark.py` (Referenzsätze in
`_lokal/benchmark/`, Anlegen → `skills/README.md`), dann Server neu starten (Python-Code wird nicht
nachgeladen; HTML schon). Benchmark-Stand und Lehren: `ALGORITHMUS.md` + `HISTORIE.md`.

## Grenzen / Zukunft

- Nur horizontale Knicke (Brief im Hochformat). Querliegende Fotos vorher im Editor drehen.
- Stark gewölbtes Papier nahe am Knick bleibt leicht unscharf/schattig (Paneele nicht perfekt eben).
- Ideen für später: siehe `ALGORITHMUS.md` (Zylindermodell, Zeilen-Krümmung, mehr Referenzsätze).
