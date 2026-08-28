#!/usr/bin/env bash
# hooks/start-timer.sh — Start-Timer: wie lange hat es vom Tastendruck bis zur laufenden Session
# gedauert, und welche Phase hat es gekostet? Läuft als SessionStart-Hook, protokolliert jeden
# Start still im Detail (Terminal-Zeile nur mit MATS_START_TIMER_SHOW=1 — der Normalfall ist
# das Log; LatexTerm zeigt die gefühlte Zeit als Live-Zähler auf dem Start-Vorhang) nach
#   ~/.cache/mats-tools/start-timer.log        (eine Zeile je Start, Schlüssel=Wert, ms-genau)
#
# Zeitstempel (Millisekunden seit Epoch) kommen als Umgebungsvariablen aus der Startkette:
#   MATS_START_T0   Tastendruck in der Oberfläche (z. B. LatexTerm-Home-Kachel: `MATS_START_T0=… claude`)
#   MATS_T_RC       erste Zeile der rc-Datei (Shell bootet) — schreibt shell/setup.sh
#   MATS_T_WRAP     Eintritt in den claude()-Wrapper
#   MATS_T_EXEC     unmittelbar vor `command claude` (Wrapper fertig: Sync losgetreten, Startzeile)
#   jetzt           dieser Hook (Claude Code hat Hooks geladen ≈ Session steht)
# Fehlende Stempel = Phase unbekannt. Stempel älter als 120 s gelten als veraltet (die Shell lief
# schon länger, z. B. zweiter `claude`-Aufruf) und werden verworfen.
#
#   --hook      JSON für den SessionStart-Hook (Standard)
#   --tail [n]  letzte n Zeilen des Logs (Standard 10)
#   --self      Selbsttest mit Kunstwerten, nichts wird geloggt
set -u
LOG="$HOME/.cache/mats-tools/start-timer.log"
mode="${1:---hook}"

now_ms() {
  if [ -n "${EPOCHREALTIME:-}" ]; then f=${EPOCHREALTIME#*.}; echo $(( ${EPOCHREALTIME%.*}*1000 + 10#${f:0:3} ))
  elif command -v perl >/dev/null 2>&1; then perl -MTime::HiRes=time -e 'printf "%.0f\n", time*1000'
  elif command -v python3 >/dev/null 2>&1; then python3 -c 'import time;print(int(time.time()*1000))'
  else echo $(( $(date +%s) * 1000 )); fi
}
sec() { # ms → "1,23" (deutsches Komma, 2 Nachkommastellen)
  awk -v ms="$1" 'BEGIN{ s=sprintf("%.2f", ms/1000); gsub(/\./,",",s); print s }'
}

case "$mode" in
  --tail) n="${2:-10}"; [ -f "$LOG" ] && tail -n "$n" "$LOG"; exit 0 ;;
  --self) NOW=$(now_ms); MATS_START_T0=$((NOW-2600)); MATS_T_RC=$((NOW-2300)); MATS_T_WRAP=$((NOW-2050))
          MATS_T_EXEC=$((NOW-1800)); SELF=1 ;;
  --hook) SELF=0 ;;
  *) echo "usage: start-timer.sh [--hook|--tail [n]|--self]" >&2; exit 2 ;;
esac

NOW=${NOW:-$(now_ms)}
T0=${MATS_START_T0:-}; RC=${MATS_T_RC:-}; WRAP=${MATS_T_WRAP:-}; EXEC=${MATS_T_EXEC:-}
MAXAGE=120000
valid() { [ -n "$1" ] && [ "$1" -gt 0 ] 2>/dev/null && [ $((NOW - $1)) -ge 0 ] && [ $((NOW - $1)) -lt "$MAXAGE" ]; }
valid "$T0"   || T0=""
valid "$RC"   || RC=""
valid "$WRAP" || WRAP=""
valid "$EXEC" || EXEC=""
# Ohne den Wrapper-Stempel gibt es nichts zu messen (Start ohne Wrapper) → still.
[ -n "$EXEC" ] || exit 0

# Monotonie erzwingen: ein Stempel, der VOR seinem Vorgänger liegt, ist veraltet.
[ -n "$RC" ] && [ -n "$WRAP" ] && [ "$RC" -gt "$WRAP" ] && RC=""
[ -n "$T0" ] && [ -n "$RC" ] && [ "$T0" -gt "$RC" ] && T0=""
[ -n "$WRAP" ] && [ "$WRAP" -gt "$EXEC" ] && WRAP=""

# Phasen (ms); leer = unbekannt
p_ui="";   [ -n "$T0" ] && [ -n "$RC" ]   && p_ui=$((RC - T0))          # Tastendruck → Shell liest rc
p_rc="";   [ -n "$RC" ] && [ -n "$WRAP" ] && p_rc=$((WRAP - RC))        # rc-Datei bis zum Wrapper
p_wrap=""; [ -n "$WRAP" ]                 && p_wrap=$((EXEC - WRAP))     # Wrapper (Sync anstoßen, Startzeile)
p_cc=$((NOW - EXEC))                                                     # Claude Code bis SessionStart
start=${T0:-${RC:-${WRAP:-$EXEC}}}; total=$((NOW - start))

# Session-Infos aus dem Hook-Input (stdin-JSON), falls vorhanden
sid=""; src=""; cwd="$PWD"
if [ "$SELF" = 0 ] && [ ! -t 0 ] && command -v jq >/dev/null 2>&1; then
  in=$(cat 2>/dev/null || true)
  [ -n "$in" ] && { sid=$(printf '%s' "$in" | jq -r '.session_id // empty' 2>/dev/null)
                    src=$(printf '%s' "$in" | jq -r '.source // empty' 2>/dev/null)
                    c=$(printf '%s' "$in" | jq -r '.cwd // empty' 2>/dev/null); [ -n "$c" ] && cwd="$c"; }
fi

# Anzeige: nur bekannte Phasen
parts=""
[ -n "$p_ui" ]   && parts="$parts · Kachel→Shell $(sec "$p_ui")"
[ -n "$p_rc" ]   && parts="$parts · Shell-rc $(sec "$p_rc")"
[ -n "$p_wrap" ] && parts="$parts · Wrapper $(sec "$p_wrap")"
parts="$parts · Claude Code $(sec "$p_cc")"
from="ab Wrapper"; [ -n "$RC" ] && from="ab Shell"; [ -n "$T0" ] && from="ab Tastendruck"
msg="⏱ Start $(sec "$total") s ($from)${parts}"

if [ "$SELF" = 0 ]; then
  mkdir -p "$(dirname "$LOG")"
  printf '%s  t0=%s rc=%s wrap=%s exec=%s hook=%s  ui=%s rcfile=%s wrapper=%s claude=%s gesamt=%s  von=%s source=%s pane=%s cwd=%s session=%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "${T0:--}" "${RC:--}" "${WRAP:--}" "$EXEC" "$NOW" \
    "${p_ui:--}" "${p_rc:--}" "${p_wrap:--}" "$p_cc" "$total" "$from" "${src:--}" "${LATEXTERM_PANE_ID:--}" "$cwd" "${sid:--}" >> "$LOG"
fi

ctx="[start-timer] $msg — Einheiten in Sekunden; Phasen: Kachel→Shell = Oberfläche bis die Shell die rc-Datei liest, Shell-rc = rc-Datei bis zum claude()-Wrapper, Wrapper = Sync anstoßen + Startzeile, Claude Code = Prozessstart bis SessionStart-Hook. Detail-Log: $LOG (start-timer.sh --tail)."
if command -v jq >/dev/null 2>&1; then
  if [ "${MATS_START_TIMER_SHOW:-0}" = 1 ] || [ "$SELF" = 1 ]; then
    jq -n --arg m "$msg" --arg c "$ctx" '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
  else
    jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
  fi
else
  printf '%s\n' "$ctx"
fi
exit 0
