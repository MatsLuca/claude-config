#!/usr/bin/env bash
# tools/validate.sh — Strukturelle Verifikation des Marketplace-Repos.
#
# Läuft lokal (macOS + Linux) und in CI (.github/workflows/validate.yml).
# Prüft alles, was sich mechanisch prüfen lässt:
#   1. Manifeste sind valides JSON; plugin.json hat keinen version-Key (SHA = Version).
#   2. Jeder Command/Agent/Skill hat vollständiges Frontmatter.
#   3. Listing-Sync: jeder Command/Agent/Skill ist in README, plugin.json und
#      marketplace.json erwähnt (die Dreifach-Listung driftet sonst) — und hat einen
#      Abschnitt in reference/evals.md (sonst ist er vom Optimier-Loop abgekoppelt).
#   4. Plugin-interne ${CLAUDE_PLUGIN_ROOT}-Referenzen (*.md und *.json, also auch
#      hooks.json) zeigen auf existierende Dateien.
#   5. Portabilitäts-Lint: BSD-only Aufrufe (date -v / stat -f) nur mit GNU-Fallback
#      in derselben Datei (Regressionsschutz, siehe authoring-guide.md) — inkl.
#      statusline und bootstrap.sh.
#   6. Shell-Syntax (bash -n) aller Skripte; bootstrap.ps1 per pwsh-Parse, wo pwsh da ist.
#      Dazu: NEWS.md hat höchstens einen <!-- claude: -->-Block pro Eintrag.
#   7. Skill-Werkstatt (skills/): Frontmatter, README-Listing, HISTORIE, Eval-Abschnitt,
#      und dass nichts Lokales/Privates (_lokal/, venv, Bilder, PDFs) getrackt ist —
#      das Repo ist public.
#
# Verhaltens-Evals (reference/evals.md) prüft das hier NICHT — die laufen headless
# bzw. manuell, siehe den Loop-Abschnitt in evals.md.

set -u
cd "$(dirname "$0")/.."

FAILS=0
fail() { printf '✗ %s\n' "$*"; FAILS=$((FAILS+1)); }
ok()   { printf '✓ %s\n' "$*"; }

README=README.md
PLUGIN_JSON=mats-tools/.claude-plugin/plugin.json
MARKET_JSON=.claude-plugin/marketplace.json
EVALS=mats-tools/reference/evals.md

# Frontmatter (Zeilen zwischen erstem und zweitem ---) extrahieren; rc 1 wenn keins.
frontmatter() {
  awk 'NR==1 { if ($0 != "---") exit 1; next } /^---$/ { found=1; exit } { print }
       END { exit found ? 0 : 1 }' "$1"
}

# ── 1. Manifeste ──────────────────────────────────────────────────────────────
json_valid() {
  if command -v jq >/dev/null 2>&1; then jq empty "$1" >/dev/null 2>&1
  else python3 -m json.tool "$1" >/dev/null 2>&1; fi
}
command -v jq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 \
  || fail "weder jq noch python3 vorhanden — JSON-Checks unmöglich"

for f in "$MARKET_JSON" "$PLUGIN_JSON" mats-tools/hooks/hooks.json; do
  [ -f "$f" ] || { fail "Manifest fehlt: $f"; continue; }
  json_valid "$f" && ok "JSON valide: $f" || fail "ungültiges JSON: $f"
done

if grep -q '"version"' "$PLUGIN_JSON" 2>/dev/null; then
  fail "plugin.json enthält einen version-Key — der Git-SHA ist die Version (siehe CLAUDE.md)"
else
  ok "plugin.json ohne version-Key (SHA-Versionierung intakt)"
fi

# ── 2 + 3. Commands: Frontmatter + Listing-Sync ───────────────────────────────
for f in mats-tools/commands/*.md; do
  name=$(basename "$f" .md)
  if fm=$(frontmatter "$f"); then
    printf '%s\n' "$fm" | grep -q '^description:' || fail "$f: description fehlt im Frontmatter"
    if grep -q '\$ARGUMENTS' "$f"; then
      printf '%s\n' "$fm" | grep -q '^argument-hint:' \
        || fail "$f: nutzt \$ARGUMENTS, aber argument-hint fehlt"
    fi
  else
    fail "$f: kein YAML-Frontmatter"
  fi
  grep -q "/$name" "$README"      || fail "Command /$name fehlt in README.md"
  grep -q "$name" "$PLUGIN_JSON"  || fail "Command $name fehlt in der plugin.json-description"
  grep -q "$name" "$MARKET_JSON"  || fail "Command $name fehlt in der marketplace.json-description"
  grep -Eq "^## /$name( |$)" "$EVALS" || fail "Command /$name hat keinen Abschnitt in $EVALS (Outcome-Evals)"
done
ok "Commands: Frontmatter + Listing-Sync + Eval-Abdeckung geprüft"

# ── 2 + 3. Agents: Frontmatter + Listing-Sync ─────────────────────────────────
for f in mats-tools/agents/*.md; do
  base=$(basename "$f" .md)
  if fm=$(frontmatter "$f"); then
    for key in name description model color; do
      printf '%s\n' "$fm" | grep -q "^$key:" || fail "$f: $key fehlt im Frontmatter"
    done
    agent=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)
    [ "$agent" = "$base" ] || fail "$f: Frontmatter-name ($agent) ≠ Dateiname ($base)"
    printf '%s' "$agent" | grep -Eq '^[a-z0-9-]{1,64}$' \
      || fail "$f: Agent-Name '$agent' verletzt die Namensregel (lowercase, a-z/0-9/-, max 64)"
  else
    fail "$f: kein YAML-Frontmatter"
  fi
  grep -q "$base" "$README"      || fail "Agent $base fehlt in README.md"
  grep -q "$base" "$PLUGIN_JSON" || fail "Agent $base fehlt in der plugin.json-description"
  grep -q "$base" "$MARKET_JSON" || fail "Agent $base fehlt in der marketplace.json-description"
  grep -q "^## $base (Agent)" "$EVALS" || fail "Agent $base hat keinen Abschnitt in $EVALS (Outcome-Evals)"
done
ok "Agents: Frontmatter + Listing-Sync + Eval-Abdeckung geprüft"

# ── 2 + 3. Skills: Frontmatter + Listing-Sync ─────────────────────────────────
for f in mats-tools/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  dir=$(basename "$(dirname "$f")")
  if fm=$(frontmatter "$f"); then
    for key in name description; do
      printf '%s\n' "$fm" | grep -q "^$key:" || fail "$f: $key fehlt im Frontmatter"
    done
    skill=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)
    [ "$skill" = "$dir" ] || fail "$f: Frontmatter-name ($skill) ≠ Ordnername ($dir)"
  else
    fail "$f: kein YAML-Frontmatter"
  fi
  grep -q "$dir" "$README"      || fail "Skill $dir fehlt in README.md"
  grep -q "$dir" "$PLUGIN_JSON" || fail "Skill $dir fehlt in der plugin.json-description"
  grep -q "$dir" "$MARKET_JSON" || fail "Skill $dir fehlt in der marketplace.json-description"
  grep -q "^## $dir (Skill)" "$EVALS" || fail "Skill $dir hat keinen Abschnitt in $EVALS (Outcome-Evals)"
done
ok "Skills: Frontmatter + Listing-Sync + Eval-Abdeckung geprüft"

# ── 4. Plugin-interne Referenzen ──────────────────────────────────────────────
refs=$(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT(:-)?\}[A-Za-z0-9_./-]*' mats-tools --include='*.md' --include='*.json' \
       | sed 's/^[^}]*}//' | sort -u)
for p in $refs; do
  [ -n "$p" ] || continue
  [ -e "mats-tools$p" ] || fail "tote Plugin-Referenz: \${CLAUDE_PLUGIN_ROOT}$p"
done
ok "\${CLAUDE_PLUGIN_ROOT}-Referenzen zeigen auf existierende Dateien"

# ── 5. Portabilitäts-Lint (Commands + Agents + Skills) ─────────────────────────────────
# BSD-only Muster brauchen einen GNU-Gegenpart in derselben Datei (oder umgekehrt) —
# sonst bricht der Command auf Linux (Container/Codespaces) bzw. macOS.
for f in mats-tools/commands/*.md mats-tools/agents/*.md mats-tools/skills/*/SKILL.md mats-tools/skills/*/scripts/*.sh mats-tools/hooks/*.sh mats-tools/shell/*.sh mats-tools/statusline/*.sh bootstrap.sh skills/*/SKILL.md skills/*/setup.sh; do
  [ -f "$f" ] || continue
  if grep -Eq -- '-v-[0-9]' "$f" && ! grep -q 'date -u -d\|date -d' "$f"; then
    fail "$f: BSD-date-Offset (-v-N) ohne GNU-Fallback (date -u -d \"… ago\")"
  fi
  if grep -q 'stat -f' "$f" && ! grep -q 'stat -c' "$f"; then
    fail "$f: BSD-stat (-f) ohne GNU-Fallback (stat -c)"
  fi
done
ok "Portabilitäts-Lint (date/stat GNU↔BSD) durchlaufen"

# ── 6. Shell-Syntax der Skripte ───────────────────────────────────────────────
for s in bootstrap.sh tools/validate.sh mats-tools/statusline/statusline-command.sh mats-tools/skills/*/scripts/*.sh mats-tools/hooks/*.sh mats-tools/shell/*.sh; do
  bash -n "$s" 2>/dev/null && ok "Syntax ok: $s" || fail "Shell-Syntaxfehler: $s"
done
# bootstrap.ps1: PowerShell-Parse, wo pwsh vorhanden ist (CI: ubuntu-latest bringt es mit).
if command -v pwsh >/dev/null 2>&1; then
  if pwsh -NoProfile -Command '$e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile("bootstrap.ps1",[ref]$null,[ref]$e); if ($e) { $e | ForEach-Object { Write-Output $_.Message }; exit 1 }' >/dev/null 2>&1; then
    ok "Syntax ok: bootstrap.ps1 (pwsh-Parse)"
  else
    fail "PowerShell-Syntaxfehler: bootstrap.ps1"
  fi
else
  ok "bootstrap.ps1: pwsh nicht vorhanden — Parse-Check übersprungen (läuft in CI)"
fi

# NEWS.md: höchstens ein <!-- claude: -->-Block pro Eintrag (news.sh verkettet mehrere stumm).
doppel=$(awk '/^## / { if (n > 1) print head; head=$0; n=0 } /<!-- claude:/ { n++ }
              END { if (n > 1) print head }' mats-tools/NEWS.md)
[ -z "$doppel" ] && ok "NEWS.md: max. ein claude-Block pro Eintrag" \
  || fail "NEWS.md: mehrere <!-- claude: -->-Blöcke in Eintrag: $doppel"

# ── 7. Skill-Werkstatt (skills/) ──────────────────────────────────────────────
# Globale Skills, per Symlink in ~/.claude/skills eingehängt (siehe skills/README.md). Kein Listing in
# plugin.json/marketplace.json (kein Plugin-Inhalt), aber: Frontmatter, Name = Ordner, README-Zeile —
# und NICHTS Lokales/Privates im Tracking (Repo ist public).
for f in skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  dir=$(basename "$(dirname "$f")")
  if fm=$(frontmatter "$f"); then
    for key in name description; do
      printf '%s\n' "$fm" | grep -q "^$key:" || fail "$f: $key fehlt im Frontmatter"
    done
    skill=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)
    [ "$skill" = "$dir" ] || fail "$f: Frontmatter-name ($skill) ≠ Ordnername ($dir)"
  else
    fail "$f: kein YAML-Frontmatter"
  fi
  grep -q "\`$dir\`" skills/README.md || fail "Werkstatt-Skill $dir fehlt in skills/README.md"
  grep -q "$dir" "$README" || fail "Werkstatt-Skill $dir fehlt in README.md"
  [ -f "skills/$dir/HISTORIE.md" ] || fail "skills/$dir/HISTORIE.md fehlt (Werkstatt-Chronik)"
  grep -q "^## $dir (Werkstatt-Skill)" "$EVALS" || fail "Werkstatt-Skill $dir hat keinen Abschnitt in $EVALS (Outcome-Evals)"
done
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  privat=$(git ls-files skills | grep -E '/_lokal/|/venv/|__pycache__|\.(png|jpe?g|JPG|heic|pdf|json)$' || true)
  [ -z "$privat" ] && ok "skills/: nichts Lokales/Privates getrackt" \
    || fail "skills/: lokale/private Dateien im Tracking:
$privat"
fi
for s in skills/*/setup.sh; do
  [ -f "$s" ] || continue
  bash -n "$s" 2>/dev/null && ok "Syntax ok: $s" || fail "Shell-Syntaxfehler: $s"
done
ok "Skill-Werkstatt (skills/): Frontmatter, README-Listing, HISTORIE, Privates geprüft"

# ── Ergebnis ──────────────────────────────────────────────────────────────────
echo
if [ "$FAILS" -gt 0 ]; then
  printf '✗ %d Befund(e) — Validierung fehlgeschlagen.\n' "$FAILS"
  exit 1
fi
echo "✓ Alle Checks grün."
