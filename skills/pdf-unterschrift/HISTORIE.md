# HISTORIE — Skill `pdf-unterschrift`

- **2026-07** Entstanden beim Ausfüllen eines Behördenformulars: Unterschrift aus einem bereits signierten PDF
  per `pdfimages` + Alpha-Maske extrahiert; Lehren: RGBA statt weißem Rechteck (überdeckt sonst Feldrahmen),
  pypdf-`PdfWriter` verliert Metadaten, Viewer-gesetzte Feldwerte haben keinen Appearance-Stream.
- **2026-08-13/20** Echte Handschrift per Scan-Freistellung (Dichtefilter gegen Papier-Grain); blaue Kuli-Tinte
  braucht ein Farbkriterium (B−R), Foto vorher eng croppen (BBox-Falle).
- **2026-08-23** In die Skill-Werkstatt umgezogen (`claude-config/skills/`), Symlink aus `~/.claude/skills/`.
  venv → `_lokal/venv` (per `setup.sh` reproduzierbar), Master-Liste mit Namen Dritter → `_lokal/NOTIZEN.md`
  (Repo ist public).
