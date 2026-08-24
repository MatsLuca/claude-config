# ALGORITHMUS — „Magic Fit" im Detail (Stand 23.08.2026)

Companion zur `SKILL.md`: die volle Algorithmus-Doku inkl. Benchmark-Zahlen und verworfener
Experimente. Fürs *Benutzen* des Skills nicht nötig — lesen, wenn am Fit selbst gearbeitet wird.
Chronologie und Lehren: `HISTORIE.md`.

## Stufen

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
9. **Generalisierung auf neue Fotos** (23.08. spät, 6 Projekt-Fotos, zweiter Referenzsatz): (a) **Papierheits-Kanal**
   (`papierheit`): Farbachse Hintergrund→Papier aus dem Vision-Viereck (innen 80 %, außen 112 %) — nur wenn der
   Luminanz-Kontrast < 60 (farbiger Stoffhintergrund: Luminanz 32, Farbachse 57); sonst Luminanz (erprobt).
   (b) Ober-/Unterkante: Fit > 4 % von Visions Kante → Vision. (c) Segmentklassen: „schwach"-Segmente behalten
   ihre Punkte nur, wenn sie nahe Visions Kante liegen („schwach+"); sonst weder Wölbung noch Randpunkte,
   Wölbung im Optimierer eingefroren und an die Gegenseite gekoppelt (`fest=`), Richtung vom Nachbarn (bei > 8°
   Abweichung komplett). Versuch „Richtung von der Gegenseite + Perspektiv-Konvergenz" zerschoss den Benchmark
   von Satz 1 (PCA-Richtungen sind vorzeichen-mehrdeutig) → zurückgenommen.
10. **Referenzsatz 2** (`_lokal/benchmark/projektfotos_2026-08-23/`, 6 Fotos, Mats' Punkte): 5 von 6 sofort ≤ 1,1 % Ø —
   Generalisierung bestätigt. Ein Brief: erste Falz lag außerhalb des Falzlinien-Fensters (±0,07 um 99 mm)
   → Fenster **±0,13 mit Distanz-Prior** (`wert·(1−0,8·abst)`), zweiter Durchlauf nur Feinjustage ±0,03 (sonst
   Runaway auf gedruckte Linien/Falzmarken — ein Formular sprang auf 14,7 %). **Offen:** der Ausreißer unten
   (BL 7 %, BR 5 %, TR 4 %): gemusterter Hintergrund, zwei schwache Segmente rechts, Referenz-Unterkante liegt
   weit außen.
11. **Experiment Kamerapose/Scharnier** (`perspektive.py`, 23.08., nicht verdrahtet): Pose je Drittel aus der
   Homographie des bekannten Rechtecks (210×99 mm) bei fester Brennweite (EXIF 35-mm-Äquivalent über die
   Diagonale, sonst 0,75·Bildlänge; Schätzung von f aus einem einzelnen Drittel ist schlecht konditioniert —
   oft keine reelle Lösung). Ergebnis: Kameraposition plausibel und stabil (Beispiel: 21 cm über dem Blatt, 29° von
   unten, 2° seitlich; Auto ≈ Mats). **Als Kantenvorhersage aber unbrauchbar:** Scharniermodell (Drittel als
   starre Rechtecke, Knickwinkel θ aus Konsistenz) reproduziert Drittel 1 nur auf 1–4 % und sagt die Ecken von
   Drittel 2 mit 13–22 % Fehler voraus (Auto im Bildraum: 1–7 %). Gründe: Drittel sind gewölbt, f bei PNG-Exporten
   unbekannt, Falzlagen angenommen, Fehler addieren sich über zwei Scharniere. Brauchbar bleibt die Pose als
   *Beschreibung* (Aufnahmewinkel) und evtl. künftig als Perspektiv-Verhältnis für die Wölbungs-Kopplung
   (kameranähere Seite erscheint stärker gewölbt) — nicht umgesetzt.

## Benchmark-Stand

`benchmark.py [1|1b|B] [satz…]`, Referenz = manuell gesetzte Punkte in `_lokal/benchmark/<satz>/referenz.json`
+ Originale (Anlegen → `skills/README.md`). Druckt Fehler je Punkt in % der längeren Bildkante, Stufe 1 vs. 1b,
je Seite zusätzlich die **Zeilen-Neigung nach Entzerrung** (Auto vs. Mats-Referenz, Grad) und den Wölbungs-Vergleich.

Stand 23.08. nachts (Satz 1: 3 Fotos, 24 Punkte): Vision allein Ø 3,4 % / max 12,6 % → Stufe 1b
Ø 1,5 % / Median 0,8 % → Stufe B mit Falzlinie Ø 0,58 % / Median 0,30 % → mit Kopplung + Linksbündigkeit
Ø 0,65 % → **mit Kanten-Disambiguierung Ø 0,57 % / Median 0,52 % / max 1,2 %** (alle 24 Punkte ≤ 1,2 %!),
Wölbungs-Δ zur Referenz Ø 0,20/0,11/0,14 % (G1 0,6 / G2 0,7 / G3 0,5 %).
**Stand nach Referenzsatz 2 (9 Fotos / 64 Punkte): Ø 0,92 %, Median 0,60 %** — 8 von 9 Seiten Ø ≤ 1,0 %,
ein Ausreißer (2,9 %); Zeilen-Neigung Auto 0,49°/0,44°/0,79° vs. Mats 0,52°/0,45°/0,86°.

Literatur-Check 23.08.: Forschung ist meist Deep Learning (DocTr, DewarpNet, DocScanner); „Unfolder"
(Computer Optics 2024) ist ein geometrischer Ansatz für halb gefaltete Blätter (0,25 s auf iPhone, besser als
DocTr) — bestätigt die Richtung „Falz explizit modellieren statt generisch dewarpen".

## Ideen für später

Linksbündige Textränder als zweite Zielgröße (Scherung), Zeilen-*Krümmung* (3 Punkte je Zeile) statt nur
Neigung, mehr Referenzsätze aus neuer Briefpost, Optimierer beschleunigen (Gauß-Newton statt Mustersuche),
3D-Zylindermodell je Drittel (page-dewarp-Idee).
