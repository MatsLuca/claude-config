#!/usr/bin/env bash
#
# bootstrap.sh — Frischen Rechner in einem Rutsch einrichten:
#   1. Claude Code installieren (falls noch nicht da)
#   2. Marketplace `claude-config` registrieren
#   3. Plugin `mats-tools` installieren (user-scope)
#   4. Skill-Werkstatt (skills/) nach ~/.claude/skills verlinken — nur aus einem Clone
#      (`bash bootstrap.sh --skills-only` auf Rechnern, die sonst schon eingerichtet sind)
#
# Danach beim nächsten `claude`-Start: einloggen und den
# `machine-setup`-Agent triggern (yolo-Alias, Status Line, Auto-Update, settings.json).
#
# Aufruf auf einem neuen Rechner (macOS / Linux):
#   curl -fsSL https://raw.githubusercontent.com/MatsLuca/claude-config/master/bootstrap.sh | bash
#
# Idempotent: erneutes Ausführen schadet nicht.

set -euo pipefail

# --skills-only: nur die Skill-Werkstatt einhängen (Symlinks + setup.sh), Rest überspringen —
# für Rechner, auf denen Plugin und Claude schon laufen. Braucht einen lokalen Clone dieses Repos.
SKILLS_ONLY=0
[ "${1:-}" = "--skills-only" ] && SKILLS_ONLY=1

MARKETPLACE="MatsLuca/claude-config"
PLUGIN="mats-tools@claude-config"
INSTALL_URL="https://claude.ai/install.sh"

# ── Ausgabe-Helfer ────────────────────────────────────────────────────────────
log()  { printf '\033[1;34m▶  %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✓  %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!  %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✗  %s\033[0m\n' "$*" >&2; exit 1; }

# ── 0. Skill-Werkstatt einhängen (skills/ → ~/.claude/skills/<name>) ──────────
# Läuft nur, wenn das Script aus einem Clone heraus gestartet wird (per curl | bash gibt es keinen).
link_skills() {
  local repo skills_src n src dst
  repo="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
  skills_src="$repo/skills"
  [ -d "$skills_src" ] || { warn "Kein skills/-Ordner neben dem Script — Werkstatt übersprungen (Repo klonen, dann: bash bootstrap.sh --skills-only)."; return 0; }
  mkdir -p "$HOME/.claude/skills"
  for src in "$skills_src"/*/; do
    n="$(basename "$src")"; dst="$HOME/.claude/skills/$n"
    [ -f "$src/SKILL.md" ] || continue
    if [ -L "$dst" ]; then
      ln -sfn "${src%/}" "$dst"; ok "Skill $n verlinkt"
    elif [ -e "$dst" ]; then
      warn "~/.claude/skills/$n existiert als echter Ordner — nicht angefasst (sichern, entfernen, erneut ausführen)"
      continue
    else
      ln -s "${src%/}" "$dst"; ok "Skill $n verlinkt"
    fi
    [ -x "$src/setup.sh" ] && { log "setup $n"; bash "$src/setup.sh" | sed 's/^/   /' || warn "setup.sh von $n meldete Probleme"; }
  done
}
if [ "$SKILLS_ONLY" = 1 ]; then
  link_skills; ok "Skill-Werkstatt eingehängt."; exit 0
fi

# ── 1. OS-Guard ───────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin|Linux) ;;
  *)
    die "Nur macOS/Linux. Für Windows (PowerShell):
       irm https://raw.githubusercontent.com/MatsLuca/claude-config/master/bootstrap.ps1 | iex" ;;
esac

# ── 2. Voraussetzungen ────────────────────────────────────────────────────────
command -v curl >/dev/null 2>&1 || die "curl wird benötigt."
command -v git  >/dev/null 2>&1 || die "git wird benötigt (klont den Marketplace)."

# ── 3. Claude Code finden oder installieren ───────────────────────────────────
# Bevorzugt die echte Binärdatei (~/.local/bin), umgeht so PATH-Timing-Probleme
# direkt nach der Installation und etwaige Shell-Funktions-Wrapper.
find_claude() {
  local c
  for c in "$HOME/.local/bin/claude" "$(command -v claude 2>/dev/null || true)"; do
    [ -n "$c" ] && [ -x "$c" ] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

CLAUDE="$(find_claude || true)"
if [ -z "${CLAUDE:-}" ]; then
  log "Claude Code nicht gefunden — installiere ..."
  curl -fsSL "$INSTALL_URL" | bash
  export PATH="$HOME/.local/bin:$PATH"   # Installer legt das Binary hierhin
  CLAUDE="$(find_claude || true)"
  [ -n "${CLAUDE:-}" ] || die "Installation lief durch, aber 'claude' ist nicht auffindbar.
       Öffne eine neue Shell und führe das Skript erneut aus."
  ok "Claude Code installiert: $CLAUDE"
else
  ok "Claude Code vorhanden: $CLAUDE"
fi

# ── 4. Marketplace + Plugin (idempotent) ──────────────────────────────────────
log "Registriere Marketplace: $MARKETPLACE"
"$CLAUDE" plugin marketplace add "$MARKETPLACE" 2>&1 | sed 's/^/   /' \
  || warn "Marketplace evtl. bereits registriert — fahre fort."

log "Installiere Plugin: $PLUGIN"
"$CLAUDE" plugin install "$PLUGIN" --scope user 2>&1 | sed 's/^/   /' \
  || warn "Plugin evtl. bereits installiert — fahre fort."

# ── 4b. Skill-Werkstatt (nur aus einem Clone) ────────────────────────────────
link_skills

# ── 5. Fertig ─────────────────────────────────────────────────────────────────
ok "Bootstrap abgeschlossen. Beim nächsten Start ist $PLUGIN aktiv."
echo
echo "Nächster Schritt:"
echo "  'claude' starten (beim ersten Mal ggf. einloggen) und als ersten Prompt schicken:"
echo "      \"Führe das machine-setup durch.\""
