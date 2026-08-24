# shell/start.sh — wird vom claude()-Wrapper (machine-setup, Step 1) nach dem Plugin-Sync
# GESOURCT (sh/bash/zsh; unter Windows via `bash start.sh`). Hier lebt alles, was beim
# Start passiert und sich ändern darf — was hier steht, kommt per Plugin-Update automatisch
# auf alle Maschinen. Muss POSIX-sh-kompatibel bleiben und darf nicht hängen (Netz nur mit
# Zeitlimit).
#
# Vertrag mit dem Wrapper:
#   rein  MATS_TOOLS_DIR     aktiver Plugin-Ordner (optional, sonst selbst ermittelt)
#         MATS_TOOLS_SYNCED  0 = Plugin-Sync ok, 1 = fehlgeschlagen/Timeout. Nur der dünne
#                            Wrapper (ab 2026-08-23) setzt sie; ist sie unverändert leer, ist
#                            es ein älterer Wrapper, der Update-Check, Repo-Fetch und
#                            Auto-Prompt noch selbst macht — dann hier nur Startzeile + Datei.
#         "$@"               die claude-Argumente (beim Sourcen in der Funktion sichtbar)
#   raus  MATS_TOOLS_PROMPT  immer leer. (Bis 24.08.2026 trug sie einen Auto-Prompt aus einer
#                            NEWS-Aktion; der Kanal ist seitdem reine Information. Wrapper, die
#                            die Variable oder ~/.claude/mats-tools-autoprompt noch lesen, finden
#                            nichts und starten normal.)

# Aktiver mats-tools-Ordner im Plugin-Cache: laut installed_plugins.json (user-scope);
# Fallback: jüngster Versionsordner. (Ein Update berührt auch den alten Ordner — mtime allein
# ist deshalb kein sicheres Kriterium.) Bewusst identisch zur Kopie im Wrapper — der braucht
# sie, um diese Datei überhaupt zu finden.
_mats_tools_dir() {
  f="$HOME/.claude/plugins/installed_plugins.json"; d=""
  [ -f "$f" ] && d=$(awk '/"mats-tools@claude-config"/{b=1} b&&/"scope": *"user"/{u=1} b&&u&&/"installPath"/{sub(/.*"installPath": *"/,""); sub(/",?[[:space:]]*$/,""); print; exit}' "$f")
  c="$HOME/.claude/plugins/cache/claude-config/mats-tools"   # kein Glob: zsh bricht bei leerem Muster ab
  { [ -n "$d" ] && [ -d "$d" ]; } || { n=$(ls -t "$c" 2>/dev/null | head -1); [ -n "$n" ] && d="$c/$n"; }
  [ -n "$d" ] && [ -d "$d" ] && printf '%s' "${d%/}"
}

# Befehl mit Zeitlimit (Sekunden): timeout/gtimeout/perl, sonst ohne Limit. Der Wrapper
# bringt dieselbe Funktion mit (er braucht sie vor dem Sync); hier nur als Fallback.
command -v _mats_tools_timeout >/dev/null 2>&1 || _mats_tools_timeout() {
  if command -v timeout >/dev/null 2>&1; then timeout "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$@"
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm shift; exec @ARGV' "$@"
  else shift; command "$@"; fi
}

# Wie lange ist das letzte *echte* mats-tools-Update her? mtime des aktiven Versionsordners;
# `plugin update` lässt sie bei No-op unangetastet. GNU stat zuerst, BSD-Fallback.
_mats_tools_alter() {
  dir="${MATS_TOOLS_DIR:-$(_mats_tools_dir)}"
  [ -n "$dir" ] || return 1
  ts=$(stat -c %Y "$dir" 2>/dev/null || stat -f %m "$dir" 2>/dev/null) || return 1
  now=$(date +%s); d=$(( now - ts )); [ "$d" -lt 0 ] && d=0
  if   [ "$d" -lt 60 ];      then echo "vor ${d} Sek."
  elif [ "$d" -lt 3600 ];    then echo "vor $(( d/60 )) Min."
  elif [ "$d" -lt 86400 ];   then echo "vor $(( d/3600 )) Std."
  elif [ "$d" -lt 604800 ];  then echo "vor $(( d/86400 )) Tag(en)"
  elif [ "$d" -lt 2629800 ]; then echo "vor $(( d/604800 )) Woche(n)"
  else                            echo "vor $(( d/2629800 )) Monat(en)"
  fi
}

_mt="${MATS_TOOLS_DIR:-$(_mats_tools_dir)}"
_thin="${MATS_TOOLS_SYNCED+x}"   # gesetzt = dünner Wrapper, Start-Logik liegt hier

# ── Täglicher Selbst-Update-Check von Claude Code (nur dünner Wrapper) ─────────────────
if [ -n "$_thin" ]; then
  _luf="$HOME/.claude_last_update"; _today=$(date +%Y-%m-%d)
  if [ "$_today" != "$(cat "$_luf" 2>/dev/null)" ]; then
    echo "⏳ Täglicher Update-Check für Claude Code…"
    _mats_tools_timeout 60 claude update >/dev/null 2>&1
    echo "$_today" > "$_luf"
  fi
  unset _luf _today
fi

# ── Startzeile ─────────────────────────────────────────────────────────────────────────
if [ -z "$_thin" ] || [ "${MATS_TOOLS_SYNCED:-0}" = 0 ]; then
  echo "🔄 mats-tools aktuell (letztes Update $(_mats_tools_alter || echo unbekannt))."
else
  echo "⚠️  mats-tools-Sync übersprungen (offline/Timeout) — Stand: Update $(_mats_tools_alter || echo unbekannt)"
fi

# ── Repo-Frische: hängt der lokale Klon hinter origin? (nur dünner Wrapper) ───────────
if [ -n "$_thin" ] && git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  GIT_TERMINAL_PROMPT=0 _mats_tools_timeout 5 git fetch --quiet 2>/dev/null
  _behind=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null)
  [ "${_behind:-0}" -gt 0 ] && echo "⬇️  Repo hängt $_behind Commit(s) hinter $(git rev-parse --abbrev-ref '@{u}') — ggf. git pull."
  unset _behind
fi

# ── Kein Auto-Prompt mehr (Vertrag oben); Altlast-Datei wegräumen, falls vorhanden ─────
MATS_TOOLS_PROMPT=""
rm -f "$HOME/.claude/mats-tools-autoprompt"
unset _mt _thin
