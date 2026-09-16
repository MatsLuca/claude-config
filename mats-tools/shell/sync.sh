#!/bin/sh
# shell/sync.sh — hält mats-tools (Plugin-Cache) und lokale Klone aktuell, ohne den Session-Start
# aufzuhalten. Der claude()-Wrapper startet dieses Skript IM HINTERGRUND; was es hereinholt, wirkt
# in der nächsten Session — genau wie der eingebaute Auto-Updater von Claude Code. POSIX sh.
#
#   sync.sh                Hintergrund-Modus: wartet kurz (Session bootet), dann Sync — aber nur,
#                          wenn der letzte Sync länger als SYNC_MIN_AGE (600 s) her ist.
#   sync.sh --now          sofort und synchron (Alias `frisch`, /finish nach einem Push).
#   sync.sh --after-push   nur wenn das aktuelle Repo das Marketplace-Repo ist → wie --now;
#                          sonst still Exit 0 (für /finish in beliebigen Repos: kostet nichts).
#   sync.sh --age          Alter des letzten Syncs in Sekunden (für die Startzeile), leer = nie.
#
# Schritt 0 hält auch Claude Code selbst aktuell — aber nur bei tragfähigem Netz: erst ein kurzer
# Versionsabgleich (5 s), dann eine Tempoprobe (3 MB); liegt sie unter CC_MIN_SPEED (1 MB/s) oder
# scheitert DNS, wird KEIN Download angestoßen (kein „Auto-update failed" im Café-WLAN). Dafür
# schaltet setup.sh den eingebauten Updater ab (DISABLE_AUTOUPDATER=1 in settings.json). Nur für
# die native Installation (~/.local/share/claude/versions); MATS_CC_UPDATE=0 schaltet den Schritt aus.
#
# Zusätzlich gepflegte Klone: ~/.config/mats-tools/sync-repos, eine absolute Pfadzeile je Repo
# (z. B. die private Werkstatt, siehe deren einhaengen.sh). Je Repo: fetch, dann ff-only-Pull —
# nur bei sauberem Baum, sonst bleibt der Klon stehen (die Startzeile meldet den Rückstand).
# $MATS_SYNC_CWD (vom Wrapper: Startordner) wird zusätzlich nur gefetcht, damit die Startzeile
# den Rückstand des Projekt-Repos ohne Netz kennt.
#
# Protokoll: ~/.claude_plugin_sync.log (eine Zeile je Lauf). Stempel: ~/.cache/mats-tools/sync.stamp;
# ~/.cache/mats-tools/plugin-neu = Version, mit der noch keine Session lief (start.sh löscht ihn);
# ~/.cache/mats-tools/claude-neu = frisch installierte Claude-Code-Version, analog.

set -u
MODE="${1:-bg}"
CACHE="$HOME/.cache/mats-tools"; STAMP="$CACHE/sync.stamp"; LOCK="$CACHE/sync.lock"
LOG="$HOME/.claude_plugin_sync.log"; REPOS="$HOME/.config/mats-tools/sync-repos"
SYNC_MIN_AGE="${SYNC_MIN_AGE:-600}"
CC_URL="https://downloads.claude.ai/claude-code-releases"; CC_MIN_SPEED="${CC_MIN_SPEED:-1000000}"
mkdir -p "$CACHE"

_timeout() {
  if command -v timeout >/dev/null 2>&1; then timeout "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$@"
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm shift; exec @ARGV' "$@"
  else shift; "$@"; fi
}
_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }
_age() { t=$(_mtime "$STAMP") || return 1; echo $(( $(date +%s) - t )); }
_plugin_dir() {   # aktiver mats-tools-Ordner laut installed_plugins.json (Version = Ordnername)
  f="$HOME/.claude/plugins/installed_plugins.json"
  [ -f "$f" ] && awk '/"mats-tools@claude-config"/{b=1} b&&/"scope": *"user"/{u=1} b&&u&&/"installPath"/{sub(/.*"installPath": *"/,""); sub(/",?[[:space:]]*$/,""); print; exit}' "$f"
}
_market_repo() {  # GitHub-Slug des Marketplace „claude-config" (Fallback: Name)
  f="$HOME/.claude/plugins/known_marketplaces.json"
  r=$([ -f "$f" ] && awk '/"claude-config"/{b=1} b&&/"repo"/{sub(/.*"repo": *"/,""); sub(/".*/,""); print; exit}' "$f")
  echo "${r:-claude-config}"
}

case "$MODE" in
  --age) _age; exit 0 ;;
  --after-push)
    url=$(git remote get-url origin 2>/dev/null) || exit 0
    case "$url" in *"$(_market_repo)"*) MODE=--now ;; *) exit 0 ;; esac ;;
  --now) ;;
  bg)
    a=$(_age) && [ "$a" -lt "$SYNC_MIN_AGE" ] && exit 0
    sleep 5 ;;
  *) echo "usage: sync.sh [--now|--after-push|--age]" >&2; exit 2 ;;
esac

# Ein Sync zur Zeit; verwaiste Sperre (> 5 min) wird übergangen.
if ! mkdir "$LOCK" 2>/dev/null; then
  t=$(_mtime "$LOCK"); if [ -n "$t" ] && [ $(( $(date +%s) - t )) -lt 300 ]; then exit 0; fi
  rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || exit 0
fi
trap 'rm -rf "$LOCK"' EXIT INT TERM

ergebnis=""
# 0. Claude Code selbst — nur native Install, nur bei tragfähigem Netz (siehe Kopf)
_cc_update() {
  [ "${MATS_CC_UPDATE:-1}" = 1 ] || return 0
  [ -d "$HOME/.local/share/claude/versions" ] || { echo "cc nicht nativ"; return 0; }
  cur=$(readlink "$HOME/.local/bin/claude" 2>/dev/null); cur=${cur##*/}
  [ -n "$cur" ] || { echo "cc ?"; return 0; }
  neu=$(curl -fsS -m 5 "$CC_URL/latest" 2>/dev/null | tr -d '[:space:]')
  case "$neu" in ''|*[!0-9.]*) echo "cc offline"; return 0 ;; esac
  [ "$neu" = "$cur" ] && { echo "cc ok"; return 0; }
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) pf=darwin-arm64 ;; Darwin-*) pf=darwin-x64 ;;
    Linux-aarch64|Linux-arm64) pf=linux-arm64 ;; Linux-*) pf=linux-x64 ;; *) echo "cc $neu (Plattform?)"; return 0 ;;
  esac
  # Tempoprobe: 3 MB vom echten Binary, max 8 s → B/s (Vergleich ohne Nachkommastellen)
  sp=$(curl -fsS -m 8 -r 0-3000000 -o /dev/null -w '%{speed_download}' "$CC_URL/$neu/$pf/claude" 2>/dev/null); sp=${sp%%.*}
  if [ "${sp:-0}" -lt "$CC_MIN_SPEED" ]; then echo "cc $neu wartet (Netz $(( ${sp:-0} / 1000 )) KB/s)"; return 0; fi
  if _timeout 600 claude install "$neu" >/dev/null 2>&1 && [ "$(readlink "$HOME/.local/bin/claude" 2>/dev/null)" != "${cur}" ]; then
    echo "$neu" > "$CACHE/claude-neu"; echo "cc NEU $neu"
  else
    rm -f "$HOME/.local/share/claude/versions/$neu" 2>/dev/null   # halbe Datei nicht liegen lassen
    echo "cc $neu Install fehlgeschlagen"
  fi
}
ergebnis=$(_cc_update)
# 1. Plugin
vorher=$(_plugin_dir)
if _timeout 30 claude plugin update mats-tools@claude-config >/dev/null 2>&1; then
  nachher=$(_plugin_dir)
  if [ -n "$nachher" ] && [ "$nachher" != "$vorher" ]; then
    ergebnis="$ergebnis; plugin NEU $(basename "$nachher")"
    basename "$nachher" > "$CACHE/plugin-neu"   # Marker: „noch keine Session damit" — start.sh löscht ihn
  else ergebnis="$ergebnis; plugin ok"; fi
else ergebnis="$ergebnis; plugin timeout/offline"; fi

# 2. Klone aus sync-repos: fetch + ff-only, nur bei sauberem Baum
if [ -f "$REPOS" ]; then
  while IFS= read -r r; do
    case "$r" in ''|'#'*) continue ;; esac
    [ -d "$r/.git" ] || { ergebnis="$ergebnis; $(basename "$r") fehlt"; continue; }
    if GIT_TERMINAL_PROMPT=0 _timeout 20 git -C "$r" fetch --quiet 2>/dev/null; then
      n=$(git -C "$r" rev-list --count 'HEAD..@{u}' 2>/dev/null); n=${n:-0}
      if [ "$n" -gt 0 ]; then
        if [ -z "$(git -C "$r" status --porcelain 2>/dev/null)" ] && git -C "$r" pull --quiet --ff-only 2>/dev/null; then
          ergebnis="$ergebnis; $(basename "$r") +$n"
        else ergebnis="$ergebnis; $(basename "$r") hängt $n (lokale Änderungen)"; fi
      else ergebnis="$ergebnis; $(basename "$r") ok"; fi
    else ergebnis="$ergebnis; $(basename "$r") fetch timeout"; fi
  done < "$REPOS"
fi

# 3. Startordner nur fetchen (Rückstand für die Startzeile), falls nicht schon oben dabei
if [ -n "${MATS_SYNC_CWD:-}" ] && git -C "$MATS_SYNC_CWD" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  top=$(git -C "$MATS_SYNC_CWD" rev-parse --show-toplevel 2>/dev/null)
  if ! { [ -f "$REPOS" ] && grep -qxF "$top" "$REPOS"; }; then
    GIT_TERMINAL_PROMPT=0 _timeout 20 git -C "$top" fetch --quiet 2>/dev/null || true
  fi
fi

touch "$STAMP"
echo "$(date '+%Y-%m-%d %H:%M:%S')  sync($MODE) $ergebnis" >> "$LOG"
case "$MODE" in --now) echo "🔄 $ergebnis" ;; esac
exit 0
