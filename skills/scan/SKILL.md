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

## „Magic Fit" — Button ✨ Ecken finden (Stand 23.08.2026)

Drei Stufen hintereinander, alles deterministisch, ~0,3 s pro Seite:
1. **Vision** (`docdetect.swift`, Apple `VNDetectDocumentSegmentationRequest`; wird beim ersten Aufruf per
   `swiftc` nach `_lokal/bin/docdetect` kompiliert, braucht Xcode-CLT; **nur macOS** — sonst meldet „Ecken finden" das, Punkte von Hand) → grobes Viereck + Konfidenz.
2. **Kantenmessung** (`verfeinere_ecken`, Python + PIL auf 1400-px-Grau): je Kante 150 Abtastungen, senkrecht
   dazu die stärkste Helligkeitsstufe = Papierrand; Treffer am Fotorand (< 0,6 %) und mit schwachem Kontrast
   verworfen; **Kontinuitätsfilter** (`saeubere_kante`: Sprünge raus, nach Lücke nur auf der Verlängerung der
   letzten Kante weiter). Geraden robust (PCA + MAD) fitten und schneiden → **Ecken auch außerhalb des Fotos**.
3. **Knicksuche** (`finde_knicke`): Hauptsignal = Richtungswechsel der gemessenen Seitenkante in Grad,
   **Knick ≠ Wölbung** über Minimum aus kleinem (0,07) und großem (0,13) t-Fenster; Nebensignal
   Helligkeitsstufe je Blatthälfte (grob entzerrt, 90. Perzentil; trägt allein, wo keine Kante messbar ist);
   schwacher Prior „ungefähr Drittel", Mindestabstand 0,18. Segmente je Seite: „abgeschnitten" (mehr
   Abtastungen am Rand als Treffer) / „abweichend" (> 9 % neben der Vision-Sehne) / „schwach" (< 20 Punkte)
   übernehmen Richtung bzw. Anker vom nächsten guten Segment. Status meldet extrapolierte Ecken und Fallbacks.
4. **Wölbung** (`schaetze_woelbung`, Stufe 3, seit 23.08. abends): je Kantensegment senkrechter Abstand der
   Messpunkte zur Sehne, Parabel `e(u)=4u(1-u)·D` per Least Squares → D = Griff-Vektor des Editors (Seitenkanten
   segmentweise, Ober-/Unterkante ganz, Knicklinien gerade). Folgt der *physischen* Papierkante; Mats' manuelle
   Griffe weichen teils davon ab (G3: nach innen statt außen), weil er nach dem entzerrten *Inhalt* justiert —
   Motivation für die inhaltsbasierte Verfeinerung (Textzeilen via Vision-OCR), noch offen.

5. **Inhaltsbasierte Verfeinerung** (`inhalt.py`, Stufe B, 23.08. nachts): `docdetect --text` liefert per
   `VNRecognizeTextRequest` (accurate, Bild auf 2200 px verkleinert, ~0,4 s, Cache `text/<id>.json`) die
   Quads aller Textzeilen. Modell (Punkte + Wölbung) wird per Mustersuche so optimiert, dass Zeilen nach der
   Entzerrung waagerecht liegen (Grad², gedeckelt) + gemessene Randpunkte auf den Modellkanten landen (mm²) +
   schwache Regularisierung zum Startwert. Inverse Abbildung Quelle→Zielblatt numerisch (inverse
   Paneel-Homographie + Newton). ~2,5 s/Seite. **Das ist die Metrik, die das Auge sieht** — Mats' manuelle
   Wölbungsgriffe richteten sich nach dem entzerrten Inhalt, nicht nach der Papierkante.

6. **Falzlinie im entzerrten Streifen** (`inhalt.finde_falzlinie`, vor Schritt 5): Streifen ±0,07 (Zielblatt-v)
   um die angenommene Naht rendern; Linienantwort `I(y) − Mittel(I(y±5))`; Kandidatengerade (yl, yr) mit
   **Median über die Randspalten (äußere 2–11 % links/rechts)** — eine Falz läuft durch den Papierrand,
   gedruckte Linien/Text nicht (volle Breite fing Tabellenlinien mit Antwort 30–50 statt Falz ~10). Beide
   Knickpunkte werden direkt auf die gefundene Linie gesetzt (2 Durchläufe). Das löste G3: an der Falz biegt
   Papier weich, der Kantenknick ist ±2 % unscharf; die sichtbare Falz ist präzise. Die ältere
   Naht-Stetigkeits-Suche (`verfeinere_falten`) bleibt als Alternative im Code (schwingt mit Textzeilen).

7. **Wölbungs-Disziplin im Optimierer** (23.08. spät): Startwölbung = Mittel links/rechts je Drittel; weiche
   **Kopplung** links↔rechts (0,3·Δmm²) — eine asymmetrische Wölbung wirkt wie höhenabhängige Scherung und wurde
   vom Optimierer als „Neigungskorrektor" missbraucht (einseitig +3,4 %, teils invertiert); symmetrische Wölbung
   kann Zeilen nicht neigen. Dazu neue Zielgröße **Linksbündigkeit**: Zeilen derselben Startspalte (±2,5 mm,
   ≥ 3 Zeilen über ≥ 25 mm, Gruppen im Startmodell gebildet) stehen nach der Entzerrung untereinander — das
   bestimmt die symmetrische Wölbung. Ergebnis: Asymmetrie ≤ 0,5 %, Vorzeichen bei G1/G2 wie Referenz, G2
   Drittel 1 exakt (+1,35/+1,35). Offen: G3 Drittel 0/1 — Kantenmessung sagt „außen", Mats' Auge „innen";
   vermutlich Grenze des Bildraum-Modells (Zylinderkrümmung verändert auch den Zeilenabstand/Foreshortening,
   was die Bézier-Wölbung nicht abbildet) → nächster Schritt wäre ein 3D-Zylindermodell je Drittel
   (page-dewarp-Idee) oder erst mehr Referenzfotos.

8. **Kanten-Mehrdeutigkeit + Papiermaske** (23.08. nachts, größter Einzelgewinn): Liegt hinter einem dunklen
   Spalt wieder Helles (zweites Blatt, Wand), rastete der Stufenfilter auf die *äußere* Kante (hell→dunkel) statt
   der Papierkante (dunkel→hell) — 2,5–4 % zu weit außen; Mats hatte das im Editor mit Wölbung *nach innen*
   kompensiert (= Rand wegschneiden). Regel jetzt: unter den starken Stufen (≥ 50 % der stärksten) die
   **innerste, deren Innenseite papierhell** ist (≥ 75 % der Papierhelligkeit tief innen). Zusätzlich
   **Papiermaske** (`papiermaske`): Polygon aus den gemessenen Randpunkten (gleitender Median, 1 mm nach innen),
   alles außerhalb wird vor dem Warp weiß — Restfehler der Geometrie werden weißer Rand statt dunkler Keil.
   Editor zeichnet die Maske gestrichelt; „Ecken zurücksetzen" löscht sie.

9. **Generalisierung auf neue Fotos** (23.08. spät, 6 Projekt-Fotos: AOK/Holztisch, Familienkasse, Rundfunk/
   Blümchendecke, Elternabend + JC + Schulbuch auf rosa Bettwäsche): (a) **Papierheits-Kanal** (`papierheit`):
   Farbachse Hintergrund→Papier aus dem Vision-Viereck (innen 80 %, außen 112 %) — nur wenn der Luminanz-
   Kontrast < 60 (rosa Bettwäsche: Luminanz 32, Farbachse 57); sonst Luminanz (erprobt). (b) Ober-/Unterkante:
   Fit > 4 % von Visions Kante → Vision. (c) Segmentklassen: „schwach"-Segmente behalten ihre Punkte nur, wenn sie
   nahe Visions Kante liegen („schwach+"); sonst weder Wölbung noch Randpunkte, Wölbung im Optimierer eingefroren
   und an die Gegenseite gekoppelt (`fest=`), Richtung vom Nachbarn (bei > 8° Abweichung komplett).
   Versuch „Richtung von der Gegenseite + Perspektiv-Konvergenz" zerschoss den SWG-Benchmark (PCA-Richtungen
   sind vorzeichen-mehrdeutig) → zurückgenommen.
10. **Referenzsatz 2** (`_lokal/benchmark/projektfotos_2026-08-23/`, 6 Fotos, Mats' Punkte): 5 von 6 sofort ≤ 1,1 % Ø —
   Generalisierung bestätigt. Rundfunk-Brief: erste Falz lag außerhalb des Falzlinien-Fensters (±0,07 um 99 mm)
   → Fenster **±0,13 mit Distanz-Prior** (`wert·(1−0,8·abst)`), zweiter Durchlauf nur Feinjustage ±0,03 (sonst
   Runaway auf gedruckte Linien/Falzmarken — Familienkasse sprang auf 14,7 %). **Offen:** Rundfunk unten
   (BL 7 %, BR 5 %, TR 4 %): Blümchendecke, zwei schwache Segmente rechts, Referenz-Unterkante liegt weit außen.



11. **Experiment Kamerapose/Scharnier** (`perspektive.py`, 23.08., nicht verdrahtet): Pose je Drittel aus der
   Homographie des bekannten Rechtecks (210×99 mm) bei fester Brennweite (EXIF 35-mm-Äquivalent über die
   Diagonale, sonst 0,75·Bildlänge; Schätzung von f aus einem einzelnen Drittel ist schlecht konditioniert —
   oft keine reelle Lösung). Ergebnis: Kameraposition plausibel und stabil (AOK: 21 cm über dem Blatt, 29° von
   unten, 2° seitlich; Auto ≈ Mats). **Als Kantenvorhersage aber unbrauchbar:** Scharniermodell (Drittel als
   starre Rechtecke, Knickwinkel θ aus Konsistenz) reproduziert Drittel 1 nur auf 1–4 % und sagt die Ecken von
   Drittel 2 mit 13–22 % Fehler voraus (Auto im Bildraum: 1–7 %). Gründe: Drittel sind gewölbt, f bei PNG-Exporten
   unbekannt, Falzlagen angenommen, Fehler addieren sich über zwei Scharniere. Brauchbar bleibt die Pose als
   *Beschreibung* (Aufnahmewinkel) und evtl. künftig als Perspektiv-Verhältnis für die Wölbungs-Kopplung
   (kameranähere Seite erscheint stärker gewölbt) — nicht umgesetzt.

**Benchmark** (`benchmark.py [1|1b|B] [satz…]`, Referenz = manuell gesetzte Punkte in `_lokal/benchmark/<satz>/referenz.json` + Originale; Anlegen → `skills/README.md`):
`python3 ~/.claude/skills/scan/benchmark.py` druckt Fehler je Punkt in % der längeren Bildkante, Stufe 1 vs. 1b.
Druckt je Seite zusätzlich die **Zeilen-Neigung nach Entzerrung** (Auto vs. Mats-Referenz, Grad) und den
Wölbungs-Vergleich. Stand 23.08. nachts (3 SWG-Fotos, 24 Punkte): Vision allein Ø 3,4 % / max 12,6 % → Stufe 1b
Ø 1,5 % / Median 0,8 % → Stufe B mit Falzlinie Ø 0,58 % / Median 0,30 % → mit Kopplung + Linksbündigkeit Ø 0,65 % → **mit Kanten-Disambiguierung Ø 0,57 % / Median 0,52 % /
max 1,2 %** (alle 24 Punkte ≤ 1,2 %!), Wölbungs-Δ zur Referenz Ø 0,20/0,11/0,14 % (G1 0,6 / G2 0,7 / G3 0,5 %).
**Stand nach Referenzsatz 2 (9 Fotos / 64 Punkte): Ø 0,92 %, Median 0,60 %** — 8 von 9 Seiten Ø ≤ 1,0 %, Ausreißer Rundfunk (2,9 %); Zeilen-Neigung Auto 0,49°/0,44°/0,79° vs. Mats 0,52°/0,45°/0,86°. Rest: G1 BL (abgeschnitten + gewölbt,
2,9 %). Literatur-Check 23.08.: Forschung ist meist Deep Learning (DocTr, DewarpNet, DocScanner); „Unfolder"
(Computer Optics 2024) ist ein geometrischer Ansatz für halb gefaltete Blätter (0,25 s auf iPhone, besser als DocTr)
— bestätigt die Richtung „Falz explizit modellieren statt generisch dewarpen". Bei jeder Algorithmus-Änderung erst Benchmark,
dann Server neu starten (Python-Code wird nicht nachgeladen; HTML schon). Neue Referenzsätze: im Editor sauber
setzen, „Speichern", `scan_werkstatt/` als `_lokal/benchmark/<name>/` kopieren (`originale/` + `punkte.json` → `referenz.json`).

## Grenzen / Zukunft

- Auto-Erkennung für Ecken, Knicke, Wölbung + inhaltsbasierte Verfeinerung. Ideen für später: linksbündige Textränder als zweite Zielgröße (Scherung), Zeilen-*Krümmung* (3 Punkte je Zeile) statt nur Neigung, mehr Referenzsätze aus neuer Briefpost, Optimierer beschleunigen (Gauß-Newton statt Mustersuche).
- Nur horizontale Knicke (Brief im Hochformat). Querliegende Fotos vorher im Editor drehen.
- Stark gewölbtes Papier nahe am Knick bleibt leicht unscharf/schattig (Paneele nicht perfekt eben).
