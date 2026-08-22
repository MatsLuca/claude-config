#!/usr/bin/env bash
# Inventar aller CLAUDE.md unter einem Wurzelordner — für den Skill claude-md.
# Ausgabe je Datei:  <Bytes>B  <Zeilen>Z  <YYYY-MM-DD>  <Höhe|?>  <Pfad>
# Höhe = aus der Kopfzeile "# CLAUDE.md — <Name> (Router|Bereich|Projekt)", "Include" bei
# einem @datei-Einzeiler, sonst "?".
# Portabel macOS (BSD stat) + Linux (GNU stat): einmal Probe, dann eine Variante.
set -euo pipefail

root="${1:-.}"

if stat -c %Y . >/dev/null 2>&1; then
  meta() { stat -c '%s %Y' "$1"; }          # GNU
else
  meta() { stat -f '%z %m' "$1"; }          # BSD
fi

if date -d @0 >/dev/null 2>&1; then
  day() { date -d "@$1" +%F; }              # GNU
else
  day() { date -r "$1" +%F; }               # BSD
fi

find "$root" -name CLAUDE.md -type f \
  -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/8_Archive/*' \
  -not -path '*/_Archiv*' -print 2>/dev/null | sort | while IFS= read -r f; do
  read -r bytes mtime < <(meta "$f")
  lines=$(wc -l < "$f" | tr -d ' ')
  hoehe=$(head -n1 "$f" | sed -nE 's/^# CLAUDE\.md — .*\((Router|Bereich|Projekt)\).*/\1/p; s/^@[^ ]+$/Include/p')
  printf '%7sB %5sZ %s %-8s %s\n' "$bytes" "$lines" "$(day "$mtime")" "${hoehe:-?}" "$f"
done
