#!/usr/bin/env bash
# shell/setup.sh — richtet eine Claude-Code-Installation wie bei Mats ein (der deterministische
# Teil des machine-setup-Agenten): yolo-Alias + Start-Wrapper als verwalteter Block in der rc-Datei
# (Windows: zusätzlich PowerShell-Profil), Status Line, settings.json-Defaults, VS-Code-Tweaks in
# Codespaces/Remote-Containern. Idempotent, portabel (macOS, Linux, Git Bash), testbar (bash -n,
# Sandbox-HOME in tools/validate.sh). Der Agent ruft dieses Skript und kümmert sich nur um das,
# was Urteil braucht (Konflikte, Diffs, Terminal-Check).
#
#   bash setup.sh [--dry-run] [--rc DATEI] [--force-block] [--force-statusline] [--force-settings] [--no-vscode]
#
# Ausgabe: eine Zeile je Befund, maschinenlesbar („SCHLÜSSEL: wert"). Marker, auf die der Agent reagiert:
#   WRAPPER_CONFLICT    eigene claude()/yolo-Definition außerhalb des Blocks → Block NICHT geschrieben
#   STATUSLINE_DIFFERS  installierte Status Line weicht von der gebündelten ab → nicht überschrieben
#   SETTINGS_DIFFERS    settings.json hat andere Werte für Default-Keys → nicht überschrieben
#   JQ_MISSING          jq fehlt (Status Line + settings-Merge brauchen es)
#   PWSH_PROFILE_FAIL   Windows: PowerShell-Profilpfad nicht ermittelbar
# --force-* überschreibt den jeweiligen Schutz (der Agent setzt es nur nach Rückfrage).
set -u

DRY=0; RC=""; FORCE_BLOCK=0; FORCE_SL=0; FORCE_SET=0; NO_VSCODE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --rc) RC="$2"; shift ;;
    --force-block) FORCE_BLOCK=1 ;;
    --force-statusline) FORCE_SL=1 ;;
    --force-settings) FORCE_SET=1 ;;
    --no-vscode) NO_VSCODE=1 ;;
    *) echo "usage: setup.sh [--dry-run] [--rc DATEI] [--force-block] [--force-statusline] [--force-settings] [--no-vscode]" >&2; exit 2 ;;
  esac; shift
done

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -f "$ROOT/statusline/statusline-command.sh" ] || { echo "FATAL: Plugin-Ordner nicht gefunden ($ROOT)"; exit 1; }
say() { printf '%s\n' "$*"; }
MARK_A='# >>> mats-tools machine-setup >>>'
MARK_B='# <<< mats-tools machine-setup <<<'

# ── Recon ─────────────────────────────────────────────────────────────────────
OS=$(uname -s); ARCH=$(uname -m)
case "$OS" in MINGW*|MSYS*|CYGWIN*) WIN=1 ;; *) WIN=0 ;; esac
CONTAINER=no
{ [ -f /.dockerenv ] || [ -n "${CODESPACES:-}" ] || [ -n "${REMOTE_CONTAINERS:-}" ] \
  || grep -qa 'docker\|kubepods' /proc/1/cgroup 2>/dev/null; } && CONTAINER=yes
if [ -z "$RC" ]; then
  case "${SHELL:-}" in
    */zsh) RC="$HOME/.zshrc" ;;
    *) if [ -f "$HOME/.zshrc" ]; then RC="$HOME/.zshrc"
       elif [ "$OS" = Darwin ]; then RC="$HOME/.bash_profile"
       elif [ -f "$HOME/.bashrc" ] || [ "$WIN" = 1 ] || [ "$OS" = Linux ]; then RC="$HOME/.bashrc"
       else RC="$HOME/.profile"; fi ;;
  esac
fi
PKG=""
for p in brew apt-get dnf apk winget; do command -v "$p" >/dev/null 2>&1 && { PKG="$p"; break; }; done
say "OS: $OS $ARCH"
say "SHELL: ${SHELL:-unbekannt}"
say "RC: $RC"
say "CONTAINER: $CONTAINER"
say "PKG: ${PKG:-keiner}"
say "PLUGIN_ROOT: $ROOT"
command -v jq >/dev/null 2>&1 && say "JQ: ok" || say "JQ_MISSING: ${PKG:+$PKG install jq}${PKG:-kein Paketmanager gefunden}"
[ "$DRY" = 1 ] && say "DRY_RUN: nichts wird geschrieben"

# ── 1. Verwalteter Block in der rc-Datei ──────────────────────────────────────
block_unix() {
cat <<'BLOCK'

# >>> mats-tools machine-setup >>>
# Managed by the mats-tools `machine-setup` agent — safe to re-run, this block is regenerated.
alias yolo='claude --dangerously-skip-permissions'

# Aktiver mats-tools-Ordner im Plugin-Cache: laut installed_plugins.json (user-scope);
# Fallback: jüngster Versionsordner.
_mats_tools_dir() {
  f="$HOME/.claude/plugins/installed_plugins.json"; d=""
  [ -f "$f" ] && d=$(awk '/"mats-tools@claude-config"/{b=1} b&&/"scope": *"user"/{u=1} b&&u&&/"installPath"/{sub(/.*"installPath": *"/,""); sub(/",?[[:space:]]*$/,""); print; exit}' "$f")
  c="$HOME/.claude/plugins/cache/claude-config/mats-tools"   # kein Glob: zsh bricht bei leerem Muster ab
  { [ -n "$d" ] && [ -d "$d" ]; } || { n=$(ls -t "$c" 2>/dev/null | head -1); [ -n "$n" ] && d="$c/$n"; }
  [ -n "$d" ] && [ -d "$d" ] && printf '%s' "${d%/}"
}

# Befehl mit Zeitlimit (Sekunden): timeout/gtimeout/perl, sonst ohne Limit.
_mats_tools_timeout() {
  if command -v timeout >/dev/null 2>&1; then timeout "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$@"
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm shift; exec @ARGV' "$@"
  else shift; command "$@"; fi
}

# Wrap `claude`: Start sofort; shell/sync.sh (Plugin-Update + Klone) läuft im HINTERGRUND und
# wirkt ab der nächsten Session — wie der eingebaute Auto-Updater von Claude Code. Erststart ohne
# Plugin-Cache synchron. `frisch` = jetzt synchron syncen, dann starten (z. B. direkt nach einem Push).
claude() {
  local mt; mt=$(_mats_tools_dir)
  if [ -z "$mt" ] || [ ! -f "$mt/shell/sync.sh" ]; then
    echo "⏳ mats-tools wird erstmals geholt…"
    _mats_tools_timeout 60 claude plugin update mats-tools@claude-config >/dev/null 2>&1
    mt=$(_mats_tools_dir)
  fi
  if [ -n "$mt" ] && [ -f "$mt/shell/sync.sh" ]; then
    if [ "${MATS_TOOLS_FRISCH:-0}" = 1 ]; then sh "$mt/shell/sync.sh" --now
    else ( MATS_SYNC_CWD="$PWD" sh "$mt/shell/sync.sh" >/dev/null 2>&1 & ); fi
    MATS_TOOLS_DIR="$mt" . "$mt/shell/start.sh"
  fi
  command claude "$@"
}
frisch() { MATS_TOOLS_FRISCH=1 claude --dangerously-skip-permissions "$@"; }
# <<< mats-tools machine-setup <<<
BLOCK
}

# Fremde claude()/yolo-Definition außerhalb der Marker?
foreign_wrapper() {
  [ -f "$1" ] || return 1
  awk -v a="$MARK_A" -v b="$MARK_B" '
    $0 == a { inblk = 1 } $0 == b { inblk = 0; next }
    !inblk && /^[[:space:]]*(alias yolo=|claude[[:space:]]*\(\))/ { found = 1 }
    END { exit found ? 0 : 1 }' "$1"
}

write_block() {   # $1 = Datei, $2 = Blockinhalt (Funktion)
  touch "$1"
  # Alten Block entfernen (sed -i.bak läuft auf GNU und BSD), neuen anhängen
  sed -i.bak "/^$MARK_A\$/,/^$MARK_B\$/d" "$1" && rm -f "$1.bak"
  "$2" >> "$1"
}

if foreign_wrapper "$RC" && [ "$FORCE_BLOCK" = 0 ]; then
  say "WRAPPER_CONFLICT: $RC hat eine eigene claude()/yolo-Definition außerhalb des Blocks — Block nicht geschrieben"
elif [ "$DRY" = 1 ]; then
  say "BLOCK: würde nach $RC geschrieben"
else
  write_block "$RC" block_unix
  say "BLOCK: $RC (yolo-Alias + Start-Wrapper)"
fi

# ── 1W. Windows: PowerShell-Profil ────────────────────────────────────────────
block_pwsh() {
cat <<'BLOCK'

# >>> mats-tools machine-setup >>>
# Managed by the mats-tools `machine-setup` agent — safe to re-run, this block is regenerated.
function claude {
    $exe = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    if (-not (Test-Path $exe)) { $exe = (Get-Command claude.exe -ErrorAction SilentlyContinue).Source }
    # Plugin-Sync, max. 8s, hängt nie.
    $job = Start-Job -ScriptBlock { param($e) & $e plugin update mats-tools@claude-config *> $null; $LASTEXITCODE } -ArgumentList $exe
    $rc = if (Wait-Job $job -Timeout 8) { Receive-Job $job } else { 1 }
    Remove-Job $job -Force
    if ($rc -eq 0) {
        $reg = Join-Path $env:USERPROFILE '.claude\plugins\installed_plugins.json'
        $dir = $null
        if (Test-Path $reg) {
            $e = (Get-Content $reg -Raw | ConvertFrom-Json).plugins.'mats-tools@claude-config' | Where-Object scope -eq 'user' | Select-Object -First 1
            if ($e) { $dir = $e.installPath }
        }
        $start = if ($dir) { Join-Path $dir 'shell\start.sh' } else { $null }
        if ($start -and (Test-Path $start) -and (Get-Command bash -ErrorAction SilentlyContinue)) {
            $env:MATS_TOOLS_DIR = $dir -replace '\\','/'
            bash ($start -replace '\\','/')
        } else { Write-Host '🔄 mats-tools aktuell.' }
    }
    & $exe @args
}
function yolo { claude --dangerously-skip-permissions @args }
# <<< mats-tools machine-setup <<<
BLOCK
}

if [ "$WIN" = 1 ]; then
  PROF=$(powershell.exe -NoProfile -Command 'Write-Output $PROFILE' 2>/dev/null | tr -d '\r')
  if [ -n "$PROF" ] && command -v cygpath >/dev/null 2>&1; then
    PROF=$(cygpath -u "$PROF")
    if [ "$DRY" = 1 ]; then say "PWSH_BLOCK: würde nach $PROF geschrieben"
    else mkdir -p "$(dirname "$PROF")"; write_block "$PROF" block_pwsh; say "PWSH_BLOCK: $PROF (ungetestet auf echtem Windows — Nutzer bitten, neue PowerShell zu öffnen und claude zu starten)"; fi
  else
    say "PWSH_PROFILE_FAIL: powershell.exe/cygpath nicht gefunden — PowerShell-Block übersprungen"
  fi
fi

# ── 2. Status Line ────────────────────────────────────────────────────────────
SRC="$ROOT/statusline/statusline-command.sh"; DST="$HOME/.claude/statusline-command.sh"
[ "$DRY" = 1 ] || mkdir -p "$HOME/.claude"
if [ -f "$DST" ] && cmp -s "$SRC" "$DST"; then
  say "STATUSLINE: aktuell ($DST)"
elif [ -f "$DST" ] && [ "$FORCE_SL" = 0 ]; then
  say "STATUSLINE_DIFFERS: $DST weicht von der gebündelten ab — nicht überschrieben (diff \"$SRC\" \"$DST\")"
elif [ "$DRY" = 1 ]; then
  say "STATUSLINE: würde nach $DST kopiert"
else
  cp "$SRC" "$DST"; chmod +x "$DST"; say "STATUSLINE: installiert ($DST)"
fi

# ── 3. settings.json ──────────────────────────────────────────────────────────
S="$HOME/.claude/settings.json"
if ! command -v jq >/dev/null 2>&1; then
  say "SETTINGS_SKIPPED: jq fehlt"
else
  [ -f "$S" ] || { [ "$DRY" = 1 ] && S=/dev/null || echo '{}' > "$S"; }
  # Default-Keys, die auf einer frischen Maschine gesetzt werden; bestehende andere Werte melden.
  diffs=$(CUR="$(cat "$S" 2>/dev/null || echo "{}")" jq -rn '
    ($ENV.CUR | fromjson) as $cur
    | {model:"opus", effortLevel:"high", skipDangerousModePermissionPrompt:true, agentPushNotifEnabled:true}
    | to_entries[] | select($cur[.key] != null and $cur[.key] != .value) | "\(.key)=\($cur[.key])"' 2>/dev/null)
  if [ -n "$diffs" ] && [ "$FORCE_SET" = 0 ]; then
    say "SETTINGS_DIFFERS: $(printf '%s' "$diffs" | tr '\n' ' ') — Default-Keys nicht überschrieben (Rest gemerged)"
    op='//='
  else
    op='='
  fi
  if [ "$DRY" = 1 ]; then
    say "SETTINGS: würde gemerged ($S)"
  else
    tmp=$(mktemp)
    jq "
      .model $op \"opus\"
      | .effortLevel $op \"high\"
      | .skipDangerousModePermissionPrompt $op true
      | .agentPushNotifEnabled $op true
      | .statusLine //= {type:\"command\", command:\"sh \\\"\$HOME/.claude/statusline-command.sh\\\"\"}
      | .extraKnownMarketplaces[\"claude-config\"] //= {source:{source:\"github\", repo:\"MatsLuca/claude-config\"}}
      | .enabledPlugins[\"mats-tools@claude-config\"] //= true
    " "$S" > "$tmp" && mv "$tmp" "$S" && say "SETTINGS: gemerged ($S)" || { rm -f "$tmp"; say "SETTINGS_FAIL: jq-Merge fehlgeschlagen"; }
  fi
fi

# ── 4. VS Code (nur Codespace / Remote-Container mit VS-Code-Server) ──────────
VSD=""
if [ "$NO_VSCODE" = 0 ] && [ "$CONTAINER" = yes ]; then
  for base in "$HOME/.vscode-remote" "$HOME/.vscode-server"; do
    [ -d "$base" ] && { VSD="$base/data/Machine"; break; }
  done
  [ -z "$VSD" ] && [ "${CODESPACES:-}" = true ] && VSD="$HOME/.vscode-remote/data/Machine"
fi
if [ -z "$VSD" ]; then
  say "VSCODE: übersprungen (kein Codespace/Remote-Container mit VS-Code-Server)"
elif ! command -v jq >/dev/null 2>&1; then
  say "VSCODE_SKIPPED: jq fehlt"
elif [ "$DRY" = 1 ]; then
  say "VSCODE: würde $VSD/settings.json mergen"
else
  mkdir -p "$VSD"; VSS="$VSD/settings.json"; [ -f "$VSS" ] || echo '{}' > "$VSS"
  tmp=$(mktemp)
  jq '."workbench.colorTheme" = "Default Dark Modern"
      | ."chat.commandCenter.enabled" = false
      | ."workbench.secondarySideBar.defaultVisibility" = "hidden"' "$VSS" > "$tmp" && mv "$tmp" "$VSS" \
    && say "VSCODE: gemerged ($VSS) — Fenster neu laden" || { rm -f "$tmp"; say "VSCODE_FAIL: jq-Merge fehlgeschlagen"; }
fi

say "DONE"
exit 0
