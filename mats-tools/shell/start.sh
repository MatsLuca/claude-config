# shell/start.sh — wird vom claude()-Wrapper (machine-setup, Step 1) nach erfolgreichem
# Plugin-Sync GESOURCT (sh/bash/zsh; unter Windows via `bash start.sh`). Hier lebt die
# Startzeile — was hier steht, kommt per Plugin-Update automatisch auf alle Maschinen.
# Muss POSIX-sh-kompatibel bleiben und darf nichts Langsames tun (kein Netz).

# Wie lange ist das letzte *echte* mats-tools-Update her? Neuester Versionsordner im
# Plugin-Cache; `plugin update` lässt dessen mtime bei No-op unangetastet. GNU stat
# zuerst, BSD-Fallback.
_mats_tools_alter() {
  dir=$(ls -td "$HOME"/.claude/plugins/cache/claude-config/mats-tools/*/ 2>/dev/null | head -1)
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

echo "🔄 mats-tools aktuell (letztes Update $(_mats_tools_alter || echo unbekannt))."
