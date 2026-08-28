# shell/start.sh — wird vom claude()-Wrapper (machine-setup, Step 1) GESOURCT (sh/bash/zsh; unter
# Windows via `bash start.sh`). Hier lebt die Startzeile — was hier steht, kommt per Plugin-Update
# automatisch auf alle Maschinen. Muss POSIX-sh-kompatibel bleiben und darf nichts Langsames tun:
# KEIN Netz — Netz macht shell/sync.sh im Hintergrund (Vertrag: MATS_TOOLS_DIR, MATS_TOOLS_FRISCH).
#
# Claude Code selbst hält sich über seinen eingebauten Auto-Updater aktuell (nachts im Hintergrund,
# aktiv beim nächsten Start; `claude doctor` zeigt es). Ein eigener täglicher `claude update` stand
# bis 2026-08-28 hier — gestrichen, er kostete bis zu 60 s beim ersten Start des Tages.

# Aktiver mats-tools-Ordner im Plugin-Cache: laut installed_plugins.json (user-scope);
# Fallback: jüngster Versionsordner. (Ein Update berührt auch den alten Ordner — mtime allein
# ist deshalb kein sicheres Kriterium.)
_mats_tools_dir() {
  f="$HOME/.claude/plugins/installed_plugins.json"; d=""
  [ -f "$f" ] && d=$(awk '/"mats-tools@claude-config"/{b=1} b&&/"scope": *"user"/{u=1} b&&u&&/"installPath"/{sub(/.*"installPath": *"/,""); sub(/",?[[:space:]]*$/,""); print; exit}' "$f")
  { [ -n "$d" ] && [ -d "$d" ]; } || d=$(ls -td "$HOME"/.claude/plugins/cache/claude-config/mats-tools/*/ 2>/dev/null | head -1)
  [ -n "$d" ] && printf '%s' "${d%/}"
}

# Sekunden → „vor 3 Min." usw.
_mats_tools_vor() {
  d=$1; [ "$d" -lt 0 ] && d=0
  if   [ "$d" -lt 60 ];      then echo "vor ${d} Sek."
  elif [ "$d" -lt 3600 ];    then echo "vor $(( d/60 )) Min."
  elif [ "$d" -lt 86400 ];   then echo "vor $(( d/3600 )) Std."
  elif [ "$d" -lt 604800 ];  then echo "vor $(( d/86400 )) Tag(en)"
  elif [ "$d" -lt 2629800 ]; then echo "vor $(( d/604800 )) Woche(n)"
  else                            echo "vor $(( d/2629800 )) Monat(en)"
  fi
}

# Wie lange ist das letzte *echte* mats-tools-Update her? mtime des aktiven Versionsordners;
# `plugin update` lässt sie bei No-op unangetastet. GNU stat zuerst, BSD-Fallback.
_mats_tools_alter() {
  dir="${MATS_TOOLS_DIR:-$(_mats_tools_dir)}"
  [ -n "$dir" ] || return 1
  ts=$(stat -c %Y "$dir" 2>/dev/null || stat -f %m "$dir" 2>/dev/null) || return 1
  _mats_tools_vor $(( $(date +%s) - ts ))
}

# ── Startzeile ─────────────────────────────────────────────────────────────────────────
_mt_upd=$(_mats_tools_alter || echo unbekannt)
if [ -f "$HOME/.cache/mats-tools/plugin-neu" ]; then
  echo "🆕 mats-tools $(cut -c1-7 "$HOME/.cache/mats-tools/plugin-neu") — erste Session mit dem Update."
  rm -f "$HOME/.cache/mats-tools/plugin-neu"
elif [ "${MATS_TOOLS_FRISCH:-0}" = 1 ]; then
  echo "🔄 mats-tools frisch synchronisiert (Update $_mt_upd)."
else
  _mt_sync=$(sh "${MATS_TOOLS_DIR:-$(_mats_tools_dir)}/shell/sync.sh" --age 2>/dev/null)
  if [ -n "$_mt_sync" ] && [ "$_mt_sync" -lt 600 ]; then
    echo "🔄 mats-tools (Update $_mt_upd · Sync $(_mats_tools_vor "$_mt_sync"))."
  else
    echo "🔄 mats-tools (Update $_mt_upd · Sync läuft nebenher, wirkt ab nächster Session — sofort: frisch)."
  fi
  unset _mt_sync
fi
unset _mt_upd

# ── Repo-Frische ohne Netz: Rückstand gegen die zuletzt gefetchten Refs ─────────────────
# (sync.sh fetcht Startordner und sync-repos im Hintergrund; hier nur der lokale Vergleich.)
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  _behind=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null)
  [ "${_behind:-0}" -gt 0 ] && echo "⬇️  Repo hängt $_behind Commit(s) hinter $(git rev-parse --abbrev-ref '@{u}') — ggf. git pull."
  unset _behind
fi
if [ -f "$HOME/.config/mats-tools/sync-repos" ]; then
  while IFS= read -r _r; do
    case "$_r" in ''|'#'*) continue ;; esac
    [ -d "$_r/.git" ] || continue
    _behind=$(git -C "$_r" rev-list --count 'HEAD..@{u}' 2>/dev/null)
    [ "${_behind:-0}" -gt 0 ] && echo "⬇️  $(basename "$_r") hängt $_behind Commit(s) hinter origin — lokale Änderungen offen, bitte selbst pullen."
  done < "$HOME/.config/mats-tools/sync-repos"
  unset _r _behind
fi

MATS_TOOLS_PROMPT=""
