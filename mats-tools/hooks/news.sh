#!/usr/bin/env bash
# hooks/news.sh — Nachrichten von Mats an alle, die mats-tools abonniert haben.
#
# Liest NEWS.md (neuester Eintrag oben, jeder Eintrag beginnt mit "## "), zeigt jeden
# Eintrag GENAU EINMAL pro Maschine (Seen-Datei) — maximal MAX auf einmal.
#
# Ein Eintrag besteht aus dem Text für Menschen und optional einem Block direkt unter der
# Überschrift (erscheint nie im Terminal):
#   <!-- claude: … -->       Hinweis an Claude zu GENAU DIESER Nachricht (mehrzeilig erlaubt),
#                            z. B. „so nutzt man den neuen Skill". Geht nur als additionalContext
#                            mit — ein Hinweis, kein Auftrag: Claude baut nichts ungefragt um.
#                            Dieses Skript selbst weiß nichts über den Inhalt einer Nachricht.
#
#   --hook       JSON für den SessionStart-Hook: systemMessage (Terminal) + additionalContext (Claude)
#   --shell      Klartext, z. B. für den Shell-Wrapper
#   --peek       Klartext ohne Seen-Markierung (zum Prüfen)
#   --context    Nur der additionalContext als Klartext, ohne Seen-Markierung (zum Prüfen)
#   --reset      Seen-Datei löschen (alle Einträge erscheinen erneut)
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
  --hook|--shell|--peek|--context) ;;
  *) echo "usage: news.sh [--hook|--shell|--peek|--context|--reset]" >&2; exit 2 ;;
esac
[ -f "$NEWS" ] || exit 0

# Einträge: eine Zeile pro Eintrag, interne Zeilenumbrüche als \x1f kodiert.
entries=$(awk '
  /^## /   { if (b != "") print b; b = $0; next }
  b != ""  { b = b "\x1f" $0 }
  END      { if (b != "") print b }
' "$NEWS")
[ -n "$entries" ] || exit 0

# Text für Menschen: Überschrift ohne "## ", Claude-Block raus, Leerzeilen getrimmt.
human_text() {
  printf '%s' "$1" | tr '\037' '\n' | awk '
    /^<!-- claude:/ { inblk = 1 }
    inblk           { if ($0 ~ /-->[[:space:]]*$/) inblk = 0; next }
    { sub(/^## /, ""); print }
  ' | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

# Hinweis an Claude: Inhalt zwischen "<!-- claude:" und "-->" (leer, wenn kein Block).
claude_text() {
  printf '%s' "$1" | tr '\037' '\n' | awk '
    /^<!-- claude:/ { inblk = 1; sub(/^<!-- claude:[[:space:]]*/, ""); if ($0 ~ /-->[[:space:]]*$/) { sub(/[[:space:]]*-->[[:space:]]*$/, ""); inblk = 0 }; if ($0 != "") print; next }
    inblk           { if ($0 ~ /-->[[:space:]]*$/) { sub(/[[:space:]]*-->[[:space:]]*$/, ""); inblk = 0 }; print; next }
  ' | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

unseen=""; heads=""; hinweise=""; n=0
while IFS= read -r e; do
  [ -n "$e" ] || continue
  head="${e%%$'\x1f'*}"
  if [ -f "$SEEN" ] && grep -qxF -- "$head" "$SEEN"; then continue; fi
  body=$(human_text "$e")
  unseen="${unseen}${unseen:+

}${body}"
  hw=$(claude_text "$e")
  if [ -n "$hw" ]; then
    hinweise="${hinweise}${hinweise:+

}Zu „${head#\#\# }“:
${hw}"
  fi
  heads="${heads}${head}
"
  n=$((n+1)); [ "$n" -ge "$MAX" ] && break
done <<< "$entries"
[ "$n" -gt 0 ] || exit 0

msg="📣 Nachricht von Mats (mats-tools)
${unseen}"

ctx="Neue Nachricht(en) von Mats, dem Autor des mats-tools-Plugins, an den Nutzer (wurde bereits im Terminal angezeigt, nicht wortgleich wiederholen):
${unseen}"
if [ -n "$hinweise" ]; then
  ctx="${ctx}

Hinweis des Plugin-Autors zu dieser Nachricht — Kontext, kein Auftrag: nutze ihn, wenn er zum Anliegen des Nutzers passt; baue nichts am Setup des Nutzers um, was er nicht selbst will; nicht nachfragen.

${hinweise}"
else
  ctx="${ctx}

Die Nachricht ist reine Information — nichts zu tun, nicht nachfragen."
fi

if [ "$mode" = "--context" ]; then
  printf '%s\n' "$ctx"
  exit 0
fi

if [ "$mode" != "--peek" ]; then
  mkdir -p "$(dirname "$SEEN")"
  printf '%s' "$heads" >> "$SEEN"
fi

if [ "$mode" = "--hook" ] && command -v jq >/dev/null 2>&1; then
  jq -n --arg m "$msg" --arg c "$ctx" \
    '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
else
  printf '%s\n' "$msg"
fi
