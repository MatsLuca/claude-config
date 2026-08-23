#!/usr/bin/env bash
# skills/scan/setup.sh — Voraussetzungen prüfen und Lokales bauen (idempotent).
#   Werkzeuge: ImageMagick 7 (magick), img2pdf, poppler (pdftoppm/pdfimages), Python 3 + Pillow.
#   macOS zusätzlich: Xcode Command Line Tools (swiftc) für die Auto-Erkennung (Apple Vision).
set -u
cd "$(dirname "$0")"
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*"; }
fehlt=0
for t in magick img2pdf pdftoppm pdfimages python3; do
  command -v "$t" >/dev/null 2>&1 && ok "$t" || { warn "$t fehlt"; fehlt=1; }
done
python3 -c "import PIL" 2>/dev/null && ok "Pillow" || { warn "Pillow fehlt (python3 -m pip install --user pillow)"; fehlt=1; }
case "$(uname -s)" in
  Darwin)
    if command -v swiftc >/dev/null 2>&1; then
      mkdir -p _lokal/bin
      if [ ! -x _lokal/bin/docdetect ] || [ docdetect.swift -nt _lokal/bin/docdetect ]; then
        swiftc -O -o _lokal/bin/docdetect docdetect.swift && ok "docdetect (Apple Vision) kompiliert" || warn "docdetect-Build fehlgeschlagen"
      else ok "docdetect aktuell"; fi
    else warn "swiftc fehlt (xcode-select --install) — Auto-Erkennung nicht verfügbar, Editor läuft manuell"; fi ;;
  *) warn "Kein macOS: Auto-Erkennung (Apple Vision) nicht verfügbar — Editor läuft manuell" ;;
esac
if [ "$fehlt" = 1 ]; then
  warn "Fehlendes nachinstallieren: macOS → brew install imagemagick img2pdf poppler · Debian/Ubuntu → apt install imagemagick img2pdf poppler-utils python3-pil"
fi
mkdir -p _lokal/benchmark
exit 0
