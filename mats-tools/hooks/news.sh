#!/usr/bin/env bash
# hooks/news.sh — Nachrichten von Mats an alle, die mats-tools abonniert haben.
#
# Liest NEWS.md (neuester Eintrag oben, jeder Eintrag beginnt mit "## "), zeigt jeden
# Eintrag GENAU EINMAL pro Maschine (Seen-Datei) — maximal MAX auf einmal.
#
# Ein Eintrag besteht aus dem Text für Menschen und optional zwei Markern direkt unter
# der Überschrift (beide erscheinen nie im Terminal):
#   <!-- aktion -->          Claude soll von selbst loslegen → der Wrapper startet Claude
#                            mit einem Auto-Prompt (siehe --autoprompt / shell/start.sh).
#   <!-- claude: … -->       Anweisung an Claude zu GENAU DIESER Nachricht (mehrzeilig
#                            erlaubt). Sie geht nur als additionalContext mit. Dieses
#                            Skript selbst weiß nichts über den Inhalt einer Nachricht.
#
#   --hook       JSON für den SessionStart-Hook: systemMessage (Terminal) + additionalContext (Claude)
#   --shell      Klartext, z. B. für den Shell-Wrapper
#   --peek       Klartext ohne Seen-Markierung (zum Prüfen)
#   --context    Nur der additionalContext als Klartext, ohne Seen-Markierung (zum Prüfen)
#   --autoprompt Steht unter den ungelesenen Einträgen einer mit Aktions-Marker, gib den
#                Start-Prompt aus, mit dem der Wrapper Claude aufruft. Markiert nichts als
#                gelesen (das tut der Hook beim Session-Start).
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
  --hook|--shell|--peek|--context|--autoprompt) ;;
  *) echo "usage: news.sh [--hook|--shell|--peek|--context|--autoprompt|--reset]" >&2; exit 2 ;;
esac
[ -f "$NEWS" ] || exit 0

# Einträge: eine Zeile pro Eintrag, interne Zeilenumbrüche als \x1f kodiert.
entries=$(awk '
  /^## /   { if (b != "") print b; b = $0; next }
  b != ""  { b = b "\x1f" $0 }
  END      { if (b != "") print b }
' "$NEWS")
[ -n "$entries" ] || exit 0

# Text für Menschen: Überschrift ohne "## ", Marker und Claude-Block raus, Leerzeilen getrimmt.
human_text() {
  printf '%s' "$1" | tr '\037' '\n' | awk '
    /^<!-- claude:/ { inblk = 1 }
    inblk           { if ($0 ~ /-->[[:space:]]*$/) inblk = 0; next }
    /^<!-- aktion -->[[:space:]]*$/ { next }
    { sub(/^## /, ""); print }
  ' | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

# Anweisung an Claude: Inhalt zwischen "<!-- claude:" und "-->" (leer, wenn kein Block).
claude_text() {
  printf '%s' "$1" | tr '\037' '\n' | awk '
    /^<!-- claude:/ { inblk = 1; sub(/^<!-- claude:[[:space:]]*/, ""); if ($0 ~ /-->[[:space:]]*$/) { sub(/[[:space:]]*-->[[:space:]]*$/, ""); inblk = 0 }; if ($0 != "") print; next }
    inblk           { if ($0 ~ /-->[[:space:]]*$/) { sub(/[[:space:]]*-->[[:space:]]*$/, ""); inblk = 0 }; print; next }
  ' | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

unseen=""; heads=""; anweisungen=""; n=0; aktion=0
while IFS= read -r e; do
  [ -n "$e" ] || continue
  head="${e%%$'\x1f'*}"
  if [ -f "$SEEN" ] && grep -qxF -- "$head" "$SEEN"; then continue; fi
  case "$e" in *'<!-- aktion -->'*) aktion=1 ;; esac
  body=$(human_text "$e")
  unseen="${unseen}${unseen:+

}${body}"
  anw=$(claude_text "$e")
  if [ -n "$anw" ]; then
    anweisungen="${anweisungen}${anweisungen:+

}Zu „${head#\#\# }“:
${anw}"
  fi
  heads="${heads}${head}
"
  n=$((n+1)); [ "$n" -ge "$MAX" ] && break
done <<< "$entries"
[ "$n" -gt 0 ] || exit 0

if [ "$mode" = "--autoprompt" ]; then
  [ "$aktion" = 1 ] && echo "Hi. Bitte setz zuerst die neue Nachricht von Mats (mats-tools) um, die du im Kontext hast — eigenständig, wie dort beschrieben. Danach sag mir kurz, was du gemacht hast."
  exit 0
fi

msg="📣 Nachricht von Mats (mats-tools)
${unseen}"

ctx="Neue Nachricht(en) von Mats, dem Autor des mats-tools-Plugins, an den Nutzer (wurde bereits im Terminal angezeigt, nicht wortgleich wiederholen):
${unseen}"
if [ -n "$anweisungen" ]; then
  ctx="${ctx}

Anweisung des Plugin-Autors an dich zu dieser Nachricht. Die Nutzer sind keine Programmierer und vertrauen auf Mats' Setup — keine technischen Rückfragen, keine Optionen zur Auswahl. Erledige es JETZT als ersten Schritt, eigenständig, bevor du dich dem eigentlichen Anliegen des Nutzers widmest: kündige es in einem Satz an, tu es, fasse in zwei einfachen Sätzen zusammen. Wenn etwas wirklich nicht geht: das Gemachte behalten, kurz sagen, was offen ist, und Mats Bescheid geben lassen.

${anweisungen}"
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
