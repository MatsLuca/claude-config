#!/bin/sh
# mats-tools status line — vendored single source of truth.
# Installed to ~/.claude/statusline-command.sh by the `machine-setup` agent.
#
# Self-adapting & portable: renders full-fidelity on capable terminals (256 color,
# UTF-8) and degrades cleanly elsewhere — ASCII glyphs when the locale is not UTF-8,
# no color when NO_COLOR/TERM=dumb. The only platform-specific call (file mtime) goes
# through the mtime() helper. Same file renders correctly on macOS, Linux, containers.
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir=$(basename "$cwd")

# --- terminal capability detection (degrade only on clear signals) -----------
# Default to full fidelity; step down only when a limitation is positively detected,
# so capable terminals (xterm-256color + UTF-8) never regress.
COLOR=1
{ [ -n "${NO_COLOR:-}" ] || [ "${TERM:-}" = "dumb" ]; } && COLOR=0
case "${LC_ALL:-}${LC_CTYPE:-}${LANG:-}" in
  *UTF-8*|*utf-8*|*UTF8*|*utf8*) UNICODE=1 ;;
  *) UNICODE=0 ;;
esac

# --- glyph set (UTF-8 vs ASCII fallback) -------------------------------------
if [ "$UNICODE" = 1 ]; then
  G_FILL='█'; G_EMPTY='░'; G_SEP='·'; G_BR='⎇'; G_REL='⟳'
  G_D='Δ'; G_SUM='Σ'; G_OK='✓'; G_NORE='∅'; G_EUR='€'
else
  G_FILL='#'; G_EMPTY='-'; G_SEP='|'; G_BR='br'; G_REL='~'
  G_D='d'; G_SUM='sum'; G_OK='ok'; G_NORE='no'; G_EUR='EUR'
fi

# --- per-metric identity colors (256-color) ----------------------------------
CTX_C='\033[38;5;51m'    # bright cyan   -> context window
H5_C='\033[38;5;214m'    # vivid orange  -> 5-hour limit
D7_C='\033[38;5;171m'    # vivid violet  -> 7-day limit
GIT_C='\033[38;5;77m'    # green         -> branch / insertions
DIFF_C='\033[38;5;220m'  # yellow        -> pending diff vs remote
DEL_C='\033[38;5;203m'   # soft red      -> deletions
COST_C='\033[38;5;120m'  # mint green    -> session cost ($)
ALERT='\033[1;38;5;196m' # bold red  -> critical override (>=85%)
MODEL_C='\033[1;36m'     # bold cyan -> model name
DIM='\033[2m'
RST='\033[0m'

# strip all color when the terminal can't be trusted with it (output stays readable)
if [ "$COLOR" = 0 ]; then
  CTX_C=''; H5_C=''; D7_C=''; GIT_C=''; DIFF_C=''; DEL_C=''
  COST_C=''; ALERT=''; MODEL_C=''; DIM=''; RST=''
fi

# portable file mtime (epoch): detect stat variant once, then never mix them.
# A `BSD || GNU` one-liner is unsafe — GNU `stat -f` prints a filesystem block
# to stdout before failing, which then concatenates with the fallback's epoch.
if stat -c %Y . >/dev/null 2>&1; then
  mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }   # GNU coreutils (Linux)
else
  mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }   # BSD stat (macOS)
fi

# pick identity color, or red alert when value is critical
hue() { if [ "$1" -ge 85 ]; then printf '%b' "$ALERT"; else printf '%b' "$2"; fi; }

# compact "time until" from a unix epoch -> e.g. 2h13m, 45m, 5d3h
reltime() {
  now=$(date +%s)
  diff=$(( $1 - now ))
  [ "$diff" -lt 0 ] && diff=0
  d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else                      printf '%dm' "$m"
  fi
}

# mini bar: $1=percent  $2=color  -> e.g. ███░░░░░ (or ###----- on ASCII terminals)
bar() {
  total=8
  filled=$(( ($1 * total + 50) / 100 ))
  [ "$filled" -gt "$total" ] && filled=$total
  empty=$(( total - filled ))
  out=""
  i=0; while [ "$i" -lt "$filled" ]; do out="${out}${G_FILL}"; i=$((i+1)); done
  rest=""
  i=0; while [ "$i" -lt "$empty" ];  do rest="${rest}${G_EMPTY}"; i=$((i+1)); done
  printf '%b%s%b%s%b' "$2" "$out" "$DIM" "$rest" "$RST"
}

sep="${DIM}  ${G_SEP}  ${RST}"

# --- context window ----------------------------------------------------------
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  c=$(hue "$used_int" "$CTX_C")
  ctx_str="${DIM}ctx${RST} $(bar "$used_int" "$c") ${c}${used_int}%${RST}"
else
  empty_bar=""; i=0; while [ "$i" -lt 8 ]; do empty_bar="${empty_bar}${G_EMPTY}"; i=$((i+1)); done
  ctx_str="${DIM}ctx ${empty_bar} --${RST}"
fi

# --- rate limits (Claude.ai subscription) ------------------------------------
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_rst=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_rst=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
limits_str=""
if [ -n "$five_pct" ]; then
  v=$(printf '%.0f' "$five_pct"); c=$(hue "$v" "$H5_C")
  r=""; [ -n "$five_rst" ] && r=" ${DIM}${G_REL}$(reltime "$five_rst")${RST}"
  limits_str="${sep}${DIM}5h${RST} ${c}${v}%${RST}${r}"
fi
if [ -n "$week_pct" ]; then
  v=$(printf '%.0f' "$week_pct"); c=$(hue "$v" "$D7_C")
  r=""; [ -n "$week_rst" ] && r=" ${DIM}${G_REL}$(reltime "$week_rst")${RST}"
  limits_str="${limits_str}  ${DIM}7d${RST} ${c}${v}%${RST}${r}"
fi

# --- session cost (Anthropic-Token diese Session, in EUR) --------------------
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cost_str=""
if [ -n "$cost_raw" ]; then
  # USD->EUR Kurs: max. 1x/Tag holen, lokal cachen; offline -> Fallback
  rate_cache="$HOME/.claude/.usd_eur_rate"
  rate=""
  if [ -f "$rate_cache" ]; then
    age=$(( $(date +%s) - $(mtime "$rate_cache") ))
    [ "$age" -lt 86400 ] && rate=$(cat "$rate_cache" 2>/dev/null)
  fi
  if [ -z "$rate" ]; then
    rate=$(curl -s --max-time 1 'https://open.er-api.com/v6/latest/USD' 2>/dev/null | jq -r '.rates.EUR // empty')
    [ -z "$rate" ] && rate=0.86   # Fallback, falls offline
    echo "$rate" > "$rate_cache" 2>/dev/null
  fi
  cost_fmt=$(awk "BEGIN{printf \"%.2f\", $cost_raw * $rate}")
  cost_str="${sep}${COST_C}${cost_fmt}${G_EUR}${RST}"

  # Monats-Summe: pro Session-ID den aktuellen Stand wegschreiben (überschreiben,
  # nicht anhängen!) und alle Sessions des Monats aufaddieren.
  session_id=$(echo "$input" | jq -r '.session_id // empty')
  if [ -n "$session_id" ]; then
    logdir="$HOME/.claude/cost-log/$(date +%Y-%m)"
    mkdir -p "$logdir" 2>/dev/null
    echo "$cost_raw" > "$logdir/$session_id" 2>/dev/null
    month_usd=$(cat "$logdir"/* 2>/dev/null | awk '{s+=$1} END{printf "%.4f", s+0}')
    month_eur=$(awk "BEGIN{printf \"%.2f\", $month_usd * $rate}")
    cost_str="${cost_str} ${DIM}${G_SUM}${month_eur}${G_EUR}${RST}"
  fi
fi

# --- git: lokaler Stand vs. letzter Push (upstream) --------------------------
git_str=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  git_str="${sep}${GIT_C}${G_BR} ${branch}${RST}"

  if git -C "$cwd" rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
    # diff der getrackten Dateien gegen Upstream
    #   = ungepushte Commits + uncommittete Änderungen in einem
    shortstat=$(git -C "$cwd" diff --shortstat @{u} 2>/dev/null)
    files=$(echo "$shortstat"   | grep -oE '[0-9]+ file'      | grep -oE '[0-9]+')
    ins=$(echo "$shortstat"     | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
    del=$(echo "$shortstat"     | grep -oE '[0-9]+ deletion'  | grep -oE '[0-9]+')
    untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    files=${files:-0}; ins=${ins:-0}; del=${del:-0}; untracked=${untracked:-0}

    if [ "$files" -eq 0 ] && [ "$untracked" -eq 0 ]; then
      git_str="${git_str} ${DIM}${G_OK} synced${RST}"
    else
      git_str="${git_str} ${DIFF_C}${G_D}${files}${RST} ${GIT_C}+${ins}${RST}${DIM}/${RST}${DEL_C}-${del}${RST}"
      [ "$untracked" -gt 0 ] && git_str="${git_str} ${DIM}+${untracked} neu${RST}"
    fi
  else
    git_str="${git_str} ${DIM}${G_NORE} remote${RST}"
  fi
fi

# --- render (zweizeilig: schneidet auf schmalen Terminals nicht mehr ab) ------
# Zeile 1: Verzeichnis / Git / Modell
printf "${DIM}%s${RST}%b${sep}${MODEL_C}%s${RST}\n" \
  "$dir" "$git_str" "$model"
# Zeile 2: Kontext / Limits / Kosten
printf "%b%b%b\n" \
  "$ctx_str" "$limits_str" "$cost_str"
