#!/usr/bin/env bash
# tools/validate.sh — Strukturelle Verifikation des Marketplace-Repos.
#
# Läuft lokal (macOS + Linux) und in CI (.github/workflows/validate.yml).
# Prüft alles, was sich mechanisch prüfen lässt:
#   1. Manifeste sind valides JSON; plugin.json hat keinen version-Key (SHA = Version).
#   2. Jeder Command/Agent hat vollständiges Frontmatter.
#   3. Listing-Sync: jeder Command/Agent ist in README, plugin.json und
#      marketplace.json erwähnt (die Dreifach-Listung driftet sonst).
#   4. Plugin-interne ${CLAUDE_PLUGIN_ROOT}-Referenzen zeigen auf existierende Dateien.
#   5. Portabilitäts-Lint: BSD-only Aufrufe (date -v / stat -f) nur mit GNU-Fallback
#      in derselben Datei (Regressionsschutz, siehe authoring-guide.md).
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

for f in "$MARKET_JSON" "$PLUGIN_JSON"; do
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
done
ok "Commands: Frontmatter + Listing-Sync geprüft"

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
done
ok "Agents: Frontmatter + Listing-Sync geprüft"

# ── 4. Plugin-interne Referenzen ──────────────────────────────────────────────
refs=$(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT(:-)?\}[A-Za-z0-9_./-]*' mats-tools --include='*.md' \
       | sed 's/^[^}]*}//' | sort -u)
for p in $refs; do
  [ -n "$p" ] || continue
  [ -e "mats-tools$p" ] || fail "tote Plugin-Referenz: \${CLAUDE_PLUGIN_ROOT}$p"
done
ok "\${CLAUDE_PLUGIN_ROOT}-Referenzen zeigen auf existierende Dateien"

# ── 5. Portabilitäts-Lint (Commands + Agents) ─────────────────────────────────
# BSD-only Muster brauchen einen GNU-Gegenpart in derselben Datei (oder umgekehrt) —
# sonst bricht der Command auf Linux (Container/Codespaces) bzw. macOS.
for f in mats-tools/commands/*.md mats-tools/agents/*.md; do
  if grep -Eq -- '-v-[0-9]' "$f" && ! grep -q 'date -u -d\|date -d' "$f"; then
    fail "$f: BSD-date-Offset (-v-N) ohne GNU-Fallback (date -u -d \"… ago\")"
  fi
  if grep -q 'stat -f' "$f" && ! grep -q 'stat -c' "$f"; then
    fail "$f: BSD-stat (-f) ohne GNU-Fallback (stat -c)"
  fi
done
ok "Portabilitäts-Lint (date/stat GNU↔BSD) durchlaufen"

# ── 6. Shell-Syntax der Skripte ───────────────────────────────────────────────
for s in bootstrap.sh tools/validate.sh mats-tools/statusline/statusline-command.sh; do
  bash -n "$s" 2>/dev/null && ok "Syntax ok: $s" || fail "Shell-Syntaxfehler: $s"
done

# ── Ergebnis ──────────────────────────────────────────────────────────────────
echo
if [ "$FAILS" -gt 0 ]; then
  printf '✗ %d Befund(e) — Validierung fehlgeschlagen.\n' "$FAILS"
  exit 1
fi
echo "✓ Alle Checks grün."
