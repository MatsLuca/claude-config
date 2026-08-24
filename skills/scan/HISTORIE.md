# HISTORIE — Skill `scan`

- **2026-07** Vorläufer: Eckpunkte-Tool im Projekt (4 Punkte, ImageMagick-Perspektive) zum Entzerren eines
  gescannten Mietvertrags.
- **2026-08-23 (ein Tag, ~30 Iterationen)** Verallgemeinert zum globalen Skill für *gefaltete* Briefpost:
  - Geometrie: 4/6/8 Punkte (Ecken + Knick-Endpunkte), ein Paneel je Falz als eigene Homographie; Wölbung
    je Kante als Bézier-Griff, Coons-Überlagerung, ein PIL-MESH-Warp pro Seite. Physik-Argument: undehnbares
    Papier biegt je Paneel nur um eine Achse → Seitenkanten teilen das Profil.
  - „Magic Fit": Apple Vision (Dokument-Viereck + OCR-Zeilen) → Kantenmessung (Stufenfilter, Kontinuitätsfilter,
    robuste Geradenfits, Extrapolation abgeschnittener Ecken) → Knicksuche (Richtungswechsel, Knick ≠ Wölbung
    über zwei Fenstergrößen) → Falzlinie im entzerrten Streifen (Randspalten!) → inhaltsbasierte Optimierung
    (Zeilen waagerecht, Linksbündigkeit, Randtreue, Wölbungs-Kopplung) → Papiermaske.
  - **Methodik:** Mats setzte manuell Referenzpunkte (Benchmark), jede Änderung wurde gemessen statt nach
    Augenmaß beurteilt. Vision allein Ø 3,4 % → Ø 0,6 % (Median 0,4 %) auf 24 Punkten; mit 6 weiteren Fotos
    (9 Seiten / 64 Punkte) Ø 0,9 %, 8 von 9 Seiten ≤ 1 %.
  - **Lehren:** (1) Widersprechen sich Auto und Auge, zuerst die *Messung* anzweifeln — die „Wölbung nach innen"
    war Randbeschnitt wegen eines Kantenfehlers (äußere statt innere Stufe bei hellem Hintergrund hinter dunklem
    Spalt), kein 3D-Effekt. (2) Die Falz ist präziser als der Kantenknick (Papier biegt an der Falz weich).
    (3) Eine asymmetrische Wölbung wirkt wie Scherung und wird vom Optimierer als Neigungskorrektor missbraucht.
    (4) Versuche ohne Benchmark-Netz (Gegenseiten-Richtung, Kamerapose/Scharniermodell) wurden verworfen,
    weil die Zahlen dagegen sprachen — Kamerapose taugt als Beschreibung, nicht als Vorhersage.
  - UX: `--auto` (Vorab-Fit aller Seiten, Knickzahl automatisch), „✅ Fertig" beendet den Server als Signal an
    Claude, „🔍 Volle Vorschau".
- **2026-08-23** In die Skill-Werkstatt umgezogen (`claude-config/skills/scan/`), Symlink aus `~/.claude/skills/`;
  Binary + Benchmark-Fotos (private Briefe) → `_lokal/`.
- **2026-08-24** Audit-Folge: Algorithmus-Details + Benchmark-Historie aus der SKILL.md nach `ALGORITHMUS.md`
  ausgelagert (SKILL.md wieder auf den operativen Kern reduziert); Instituts-Namen in Beispielen generalisiert.
