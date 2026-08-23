#!/usr/bin/env bash
# skills/pdf-unterschrift/setup.sh — venv in _lokal/venv anlegen/aktualisieren (idempotent, optional:
# nur nötig, wenn der Skill genutzt werden soll). Braucht python3 ≥ 3.10; Ghostscript (gs) + poppler fürs Rendern.
set -u
cd "$(dirname "$0")"
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*"; }
command -v python3 >/dev/null 2>&1 || { warn "python3 fehlt"; exit 1; }
[ -d _lokal/venv ] || { mkdir -p _lokal && python3 -m venv _lokal/venv && ok "venv angelegt"; }
# Windows (Git Bash): Scripts/ statt bin/
PY=_lokal/venv/bin/python; [ -x "$PY" ] || PY=_lokal/venv/Scripts/python.exe
"$PY" -m pip install -q --upgrade pip >/dev/null 2>&1
"$PY" -m pip install -q -r requirements.txt && ok "Pakete aktuell (pypdf, reportlab, pillow, numpy)" || warn "pip install fehlgeschlagen"
for t in gs pdfimages pdfinfo; do command -v "$t" >/dev/null 2>&1 && ok "$t" || warn "$t fehlt (macOS: brew install ghostscript poppler · Debian: apt install ghostscript poppler-utils)"; done
[ -f _lokal/NOTIZEN.md ] || printf '# Lokale Notizen (nicht versioniert)\n\nBekannte Unterschrifts-Master (Person → Pfad), Besonderheiten je Person.\n' > _lokal/NOTIZEN.md
exit 0
