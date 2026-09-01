#!/usr/bin/env bash
# tools/eval.sh — Verhaltens-Evals real laufen lassen: ein Command headless (`claude -p`) aus der
# Repo-Quelle (--plugin-dir, nicht der installierte Cache) in einem Wegwerf-Fixture; danach das
# Transkript neben dem Eval-Abschnitt aus reference/evals.md — und wo es sich mechanisch prüfen
# lässt, eine automatische Bewertung auf der Platte. Kostet echte Tokens; läuft deshalb nicht in CI.
#
#   tools/eval.sh <szenario> [--keep]      benannte Szenarien mit Fixture + Prüfung (Liste: --list)
#   tools/eval.sh <command> [prompt-zusatz] freier Lauf im leeren Fixture, Urteil von Hand
#
# Ergebnis je Szenario: PASS/FAIL-Zeilen, Transkript unter $EVAL_OUT (Default: mktemp).
set -u
cd "$(dirname "$0")/.."
ROOT="$PWD"; PLUGIN="$ROOT/mats-tools"; EVALS="$PLUGIN/reference/evals.md"
OUT="${EVAL_OUT:-$(mktemp -d)}"; KEEP=0
MAXTURNS="${EVAL_MAX_TURNS:-12}"

pass() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; }
fail() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; FAILS=$((FAILS+1)); }
FAILS=0

# allowed-tools aus dem Command-Frontmatter → --allowedTools (headless gibt es sonst keine Freigabe)
allowed_tools() {
  awk 'NR==1{next} /^---$/{exit} /^allowed-tools:/{sub(/^allowed-tools:[[:space:]]*/,""); print}' "$PLUGIN/commands/$1.md"
}

# Headless-Lauf: $1 = command, $2 = Fixture-Dir, $3 = Transkript-Datei, $4 = Prompt-Zusatz (optional)
run_cmd() {
  local cmd="$1" fx="$2" log="$3" extra="${4:-}" tools
  tools=$(allowed_tools "$cmd")
  ( cd "$fx" && command claude -p "/mats-tools:$cmd${extra:+ $extra}" \
      --plugin-dir "$PLUGIN" --permission-mode acceptEdits --max-turns "$MAXTURNS" \
      --output-format text ${tools:+--allowedTools "$tools"} ) >"$log" 2>&1
}

# Eval-Abschnitt eines Commands aus evals.md
eval_section() {
  awk -v h="## /$1" '$0 == h {p=1; print; next} /^## / {p=0} p' "$EVALS"
}

# Fixture: Bare-Remote + Klon mit einem Commit (für finish-lite)
fixture_repo() {
  local d="$1"; mkdir -p "$d/remote.git" "$d/work"
  git -C "$d/remote.git" init -q --bare -b main
  git -C "$d/work" init -q -b main
  git -C "$d/work" -c user.name=eval -c user.email=eval@beispiel.de commit -q --allow-empty -m "init"
  git -C "$d/work" remote add origin "$d/remote.git"
  git -C "$d/work" push -q -u origin main
  git -C "$d/remote.git" symbolic-ref HEAD refs/heads/main
  printf 'Notiz\n' > "$d/work/notiz.md"
}

szenario() {
  local name="$1" fx="$OUT/$1"; mkdir -p "$fx"
  printf '\n\033[1m▶ %s\033[0m  (Fixture: %s)\n' "$name" "$fx"
  case "$name" in
    finish-lite:sync)
      fixture_repo "$fx"; git -C "$fx/work" add -A; git -C "$fx/work" -c user.name=eval -c user.email=eval@beispiel.de commit -qm "Basis"; git -C "$fx/work" push -q
      printf 'Neue Zeile\n' >> "$fx/work/notiz.md"
      run_cmd finish-lite "$fx/work" "$fx/transcript.txt"
      [ -z "$(git -C "$fx/work" status --porcelain)" ] && pass "Arbeitsbaum sauber" || fail "Arbeitsbaum nicht sauber"
      git -C "$fx/work" log -1 --format=%s | grep -q '^Stand ' && pass "Commit mit Zeitstempel-Message" || fail "kein Stand-Commit: $(git -C "$fx/work" log -1 --format=%s)"
      [ "$(git -C "$fx/work" rev-parse HEAD)" = "$(git -C "$fx/remote.git" rev-parse main)" ] && pass "Remote main == lokal (gepusht)" || fail "Remote hängt hinterher"
      ;;
    finish-lite:synchron)
      fixture_repo "$fx"; rm "$fx/work/notiz.md"
      before=$(git -C "$fx/work" rev-parse HEAD)
      run_cmd finish-lite "$fx/work" "$fx/transcript.txt"
      [ "$(git -C "$fx/work" rev-parse HEAD)" = "$before" ] && pass "kein leerer Commit" || fail "Commit entstanden, obwohl nichts zu tun"
      grep -qi 'synchron' "$fx/transcript.txt" && pass "meldet „Schon synchron“" || fail "Meldung fehlt"
      ;;
    xcode:leer)
      run_cmd xcode "$fx" "$fx/transcript.txt"
      grep -qi 'kein xcode-projekt' "$fx/transcript.txt" && pass "meldet: kein Xcode-Projekt" || fail "Meldung fehlt"
      ;;
    finish:feature)
      fixture_repo "$fx"
      printf '# Demo\n\nEin kleines Werkzeug.\n\n## Befehle\n\n- `demo hallo` — grüßt.\n' > "$fx/work/README.md"
      git -C "$fx/work" add -A; git -C "$fx/work" -c user.name=eval -c user.email=eval@beispiel.de commit -qm "feat: demo hallo"; git -C "$fx/work" push -q
      printf '#!/bin/sh\ncase "$1" in hallo) echo Hallo;; tschuess) echo Tschüss;; esac\n' > "$fx/work/demo.sh"
      before=$(git -C "$fx/work" rev-parse HEAD)
      run_cmd finish "$fx/work" "$fx/transcript.txt"
      [ -z "$(git -C "$fx/work" status --porcelain)" ] && pass "Arbeitsbaum sauber" || fail "Arbeitsbaum nicht sauber"
      [ "$(git -C "$fx/work" rev-parse HEAD)" != "$before" ] && pass "neuer Commit" || fail "kein Commit"
      git -C "$fx/work" log -1 --format=%s | grep -Eq '^[a-z]+(\([^)]*\))?!?: ' && pass "Conventional-Commit-Subject" || fail "Subject nicht konventionell: $(git -C "$fx/work" log -1 --format=%s)"
      git -C "$fx/work" log -1 --format=%B | grep -q 'Co-Authored-By: Claude' && pass "Co-Author-Trailer" || fail "Co-Author-Trailer fehlt"
      [ "$(git -C "$fx/work" rev-parse HEAD)" = "$(git -C "$fx/remote.git" rev-parse main)" ] && pass "gepusht" || fail "Remote hängt hinterher"
      grep -q 'tschuess' "$fx/work/README.md" && pass "README nennt den neuen Befehl" || fail "README nicht nachgezogen"
      ;;
    finish:clean)
      fixture_repo "$fx"; rm "$fx/work/notiz.md"
      before=$(git -C "$fx/work" rev-parse HEAD)
      run_cmd finish "$fx/work" "$fx/transcript.txt"
      [ "$(git -C "$fx/work" rev-parse HEAD)" = "$before" ] && pass "kein Commit" || fail "Commit entstanden, obwohl nichts zu tun"
      grep -Eqi 'keine Änderungen|nichts zu (tun|committen)' "$fx/transcript.txt" && pass "meldet: nichts zu tun" || fail "Meldung fehlt"
      ;;
    merken:stand)
      fixture_repo "$fx"; rm "$fx/work/notiz.md"
      printf '# CLAUDE.md — work (Projekt)\n\nNotizprojekt: ein Buch, Kapitel für Kapitel.\n\n## Aktueller Stand (2026-08-01)\n\n- Kapitel 1 steht in `kapitel1.md`.\n- [ ] Kapitel 2 schreiben\n' > "$fx/work/CLAUDE.md"
      printf 'Kapitel 1\n' > "$fx/work/kapitel1.md"; printf 'Kapitel 2\n' > "$fx/work/kapitel2.md"
      git -C "$fx/work" add -A; git -C "$fx/work" -c user.name=eval -c user.email=eval@beispiel.de commit -qm "Kapitel 1+2"; git -C "$fx/work" push -q
      before=$(git -C "$fx/work" rev-parse HEAD)
      run_cmd merken "$fx/work" "$fx/transcript.txt" "Kontext dieser Session: Kapitel 2 ist fertig geschrieben (kapitel2.md). Entschieden: jedes Kapitel bleibt eine eigene Datei. Nächster Schritt: Kapitel 3 skizzieren."
      [ "$(grep -c '^## Aktueller Stand (' "$fx/work/CLAUDE.md")" = 1 ] && pass "genau ein Stand-Block" || fail "Stand-Blöcke: $(grep -c '^## Aktueller Stand (' "$fx/work/CLAUDE.md")"
      grep -q "^## Aktueller Stand ($(date +%Y-%m)" "$fx/work/CLAUDE.md" && pass "Stand-Block datiert heute" || fail "Stand-Block nicht neu datiert"
      grep -qi 'kapitel 3' "$fx/work/CLAUDE.md" && pass "nächster Schritt notiert" || fail "Kapitel 3 fehlt in CLAUDE.md"
      grep -q '2026-08-01' "$fx/work/HISTORIE.md" 2>/dev/null && pass "alter Stand in HISTORIE.md" || fail "HISTORIE.md fehlt oder ohne alten Stand"
      [ "$(git -C "$fx/work" rev-parse HEAD)" = "$before" ] && pass "kein ungefragter Commit" || fail "hat ungefragt committet"
      ;;
    *) echo "unbekanntes Szenario: $name (siehe --list)"; return 2 ;;
  esac
  printf '  Transkript: %s\n' "$fx/transcript.txt"
}

case "${1:-}" in
  --list|"")
    cat <<EOF
Szenarien mit Fixture + automatischer Prüfung:
  finish:feature         neues Skript + README-Bezug → konventioneller Commit mit Trailer, README nachgezogen, gepusht
  finish:clean           nichts zu committen → meldet das, kein Commit
  finish-lite:sync       geänderte Datei → Stand-Commit, Rebase, Push auf Default-Branch
  finish-lite:synchron   nichts geändert → „Schon synchron.", kein leerer Commit
  merken:stand           CLAUDE.md mit altem Stand-Block + Session-Kontext → ein neuer Stand, alter in HISTORIE.md, kein Commit
  xcode:leer             leeres Verzeichnis → „kein Xcode-Projekt gefunden"
  alle                   alle obigen nacheinander
Freier Lauf:  tools/eval.sh <command> [prompt-zusatz]   (Transkript + Eval-Abschnitt, Urteil von Hand)
EOF
    exit 0 ;;
  alle) for s in finish:feature finish:clean finish-lite:sync finish-lite:synchron merken:stand xcode:leer; do szenario "$s"; done ;;
  *:*)  szenario "$1" ;;
  *)
    cmd="$1"; shift; [ -f "$PLUGIN/commands/$cmd.md" ] || { echo "kein Command: $cmd"; exit 2; }
    fx="$OUT/$cmd"; mkdir -p "$fx"
    printf '\n\033[1m▶ /%s (freier Lauf)\033[0m  Fixture: %s\n' "$cmd" "$fx"
    run_cmd "$cmd" "$fx" "$fx/transcript.txt" "$*"
    printf '\n\033[1m── Transkript ──\033[0m\n'; cat "$fx/transcript.txt"
    printf '\n\033[1m── Erwartete Outcomes (evals.md) ──\033[0m\n'; eval_section "$cmd"
    exit 0 ;;
esac

echo
[ "$FAILS" -gt 0 ] && { printf '\033[1;31m✗ %d Prüfung(en) rot\033[0m — Transkripte unter %s\n' "$FAILS" "$OUT"; exit 1; }
printf '\033[1;32m✓ alle Prüfungen grün\033[0m — Transkripte unter %s\n' "$OUT"
