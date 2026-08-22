#!/usr/bin/env bash
# hooks/news.sh — Nachrichten von Mats an alle, die mats-tools abonniert haben.
#
# Liest NEWS.md (neuester Eintrag oben, jeder Eintrag beginnt mit "## "), zeigt jeden
# Eintrag GENAU EINMAL pro Maschine (Seen-Datei) — maximal MAX auf einmal.
#
#   --hook   JSON für den SessionStart-Hook: systemMessage (Terminal) + additionalContext (Claude)
#   --shell  Klartext, z. B. für den Shell-Wrapper
#   --peek   Klartext ohne Seen-Markierung (zum Prüfen)
#   --reset  Seen-Datei löschen (alle Einträge erscheinen erneut)
#
# Läuft unter bash auf macOS/Linux und in Git Bash auf Windows. Ohne jq: Klartext statt
# JSON (Claude Code nimmt plain stdout bei SessionStart als Kontext — nur die Terminal-
# Anzeige entfällt dann).
set -u
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
NEWS="$ROOT/NEWS.md"
SEEN="$HOME/.claude/mats-tools-news-seen"
MAX=3
mode="${1:---hook}"

case "$mode" in
  --reset) rm -f "$SEEN"; exit 0 ;;
  --hook|--shell|--peek) ;;
  *) echo "usage: news.sh [--hook|--shell|--peek|--reset]" >&2; exit 2 ;;
esac
[ -f "$NEWS" ] || exit 0

# Einträge: eine Zeile pro Eintrag, interne Zeilenumbrüche als \x1f kodiert.
entries=$(awk '
  /^## /   { if (b != "") print b; b = $0; next }
  b != ""  { b = b "\x1f" $0 }
  END      { if (b != "") print b }
' "$NEWS")
[ -n "$entries" ] || exit 0

unseen=""; heads=""; n=0
while IFS= read -r e; do
  [ -n "$e" ] || continue
  head="${e%%$'\x1f'*}"
  if [ -f "$SEEN" ] && grep -qxF -- "$head" "$SEEN"; then continue; fi
  body=$(printf '%s' "$e" | tr '\037' '\n' | sed -e 's/^## //' -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
  unseen="${unseen}${unseen:+

}${body}"
  heads="${heads}${head}
"
  n=$((n+1)); [ "$n" -ge "$MAX" ] && break
done <<< "$entries"
[ "$n" -gt 0 ] || exit 0

msg="📣 Nachricht von Mats (mats-tools)
${unseen}"

if [ "$mode" != "--peek" ]; then
  mkdir -p "$(dirname "$SEEN")"
  printf '%s' "$heads" >> "$SEEN"
fi

if [ "$mode" = "--hook" ] && command -v jq >/dev/null 2>&1; then
  ctx="Neue Nachricht(en) von Mats, dem Autor des mats-tools-Plugins, an den Nutzer (wurde bereits im Terminal angezeigt, nicht wortgleich wiederholen):
${unseen}

Regeln für dich: Beim ersten Prompt kurz darauf eingehen. Verlangt die Nachricht eine Aktion, dann NICHT einfach ausführen, sondern zuerst prüfen, ob dieser Nutzer Mats' Setup 1:1 nutzt oder es angepasst hat (verwalteter Block '# >>> mats-tools machine-setup >>>' in rc-Datei/PowerShell-Profil vorhanden? ~/.claude/statusline-command.sh identisch mit der gebündelten unter \${CLAUDE_PLUGIN_ROOT}/statusline/? eigene Wrapper/Funktionen?). 1:1-Setup → die vorgeschlagene Aktion anbieten und erst nach Zustimmung ausführen. Angepasstes Setup → nur den minimalen, zum System des Nutzers passenden Eingriff vorschlagen, an der Stelle, wo sein System das Plugin-Update macht; Status Line, settings.json und eigene Shell-Logik nie anfassen. Im Zweifel erst zeigen, was geändert würde."
  jq -n --arg m "$msg" --arg c "$ctx" \
    '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
else
  printf '%s\n' "$msg"
fi
