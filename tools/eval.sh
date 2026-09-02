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

# Fixture: Mini-Ablagebaum mit zwei Router-CLAUDE.md (für neues-projekt); $1 = Wurzel
fixture_tree() {
  local d="$1"; mkdir -p "$d/Documents/4_Projekte/01_Aktiv" "$d/Documents/4_Projekte/02_Persoenlich"
  printf '# CLAUDE.md — Documents (Router)\n\nPersönliches Ablagesystem (PARA). Für konkrete Arbeit in den Kind-Ordner wechseln — dessen CLAUDE.md ist dort maßgeblich.\n\n## Kinder\n- `4_Projekte/` — Software- und Wissensprojekte · eigene CLAUDE.md\n' > "$d/Documents/CLAUDE.md"
  printf '# CLAUDE.md — 4_Projekte (Router)\n\nProjekte. Für Projektarbeit in den Projektordner wechseln — dessen CLAUDE.md ist die einzige Quelle für Zweck und Stand.\n\n## Kinder\n- `01_Aktiv/` — Software-Projekte, meist mit eigenem Git-Repo\n- `02_Persoenlich/` — Wissens- und Orga-Projekte ohne Build\n\n`01_Aktiv/` und `02_Persoenlich/` haben bewusst keine eigene CLAUDE.md — `ls` zeigt die Projekte.\n' > "$d/Documents/4_Projekte/CLAUDE.md"
}
# Fixture: Wegwerf-Klon dieses Repos mit einem absichtlich schlampigen Command `zaehlen` (für optimieren);
# $1 = Wurzel → Klon liegt unter $1/repo. Der Klon hängt an diesem Repo als origin, pusht aber nie.
fixture_clone() {
  local d="$1" r="$1/repo"; git clone -q "$ROOT" "$r"
  cat > "$r/mats-tools/commands/zaehlen.md" <<'EOF'
---
description: Counts the markdown files in the current directory and shows the biggest ones (counts markdown files, shows the largest markdown files).
allowed-tools: Bash, Read, Write, Edit, WebFetch, Glob, Grep
---

Du bist ein hilfreicher Assistent. Du zählst Markdown-Dateien. Du zählst die Markdown-Dateien im aktuellen Ordner und zeigst die größten. Zähle die Markdown-Dateien im aktuellen Ordner. Zeige dann die größten Markdown-Dateien. Gewünschte Anzahl: $ARGUMENTS.

Seit August 2025 gibt es drei Wege, das zu tun: du kannst `find` benutzen, oder `ls -R`, oder das Glob-Tool — such dir einen aus und erkläre dem Nutzer ausführlich, warum du diesen Weg gewählt hast und was die anderen Wege gewesen wären.

## Schritt 1
Zähle die Dateien. Denk daran, dass Markdown-Dateien auf `.md` enden. Markdown-Dateien enden auf `.md`.

## Schritt 2
Zeige die größten Dateien. Die Größe bekommst du mit `stat -f %z` (macOS).

## Schritt 3
Erkläre am Ende noch einmal ausführlich, was du getan hast, wie viele Dateien es gibt, welche die größten sind, und bedanke dich beim Nutzer.
EOF
  printf '| `/zaehlen` | Zählt Markdown-Dateien im aktuellen Ordner und zeigt die größten |\n' >> "$r/README.md"
  printf '\n## /zaehlen\n- **Szenario:** Ordner mit drei Markdown-Dateien, `/zaehlen 2`.\n  **Erwartet:** Meldet die Anzahl 3 und nennt die zwei größten Dateien; nichts wird geschrieben.\n' >> "$r/mats-tools/reference/evals.md"
  git -C "$r" add -A; git -C "$r" -c user.name=eval -c user.email=eval@beispiel.de commit -qm "zaehlen: Probe-Command"
}
# Prüfsumme einer Datei (cksum ist auf BSD und GNU gleich; ohne Dateiname im Output)
sum() { cksum < "$1"; }

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
    neues-projekt:leer)
      fixture_tree "$fx"; p="$fx/Documents/4_Projekte/01_Aktiv/Notizzaehler"; mkdir -p "$p"
      r1=$(sum "$fx/Documents/CLAUDE.md"); r2=$(sum "$fx/Documents/4_Projekte/CLAUDE.md")
      run_cmd neues-projekt "$p" "$fx/transcript.txt" "Kleines CLI-Werkzeug, das Markdown-Notizen zählt. Software-Repo, kein Git, keine Unterprojekte."
      [ -f "$p/CLAUDE.md" ] && head -1 "$p/CLAUDE.md" | grep -q '^# CLAUDE.md — Notizzaehler (Projekt)$' && pass "Kopfzeile nennt Höhe Projekt" || fail "CLAUDE.md fehlt oder Kopfzeile falsch: $(head -1 "$p/CLAUDE.md" 2>/dev/null)"
      grep -q "^## Aktueller Stand ($(date +%Y-%m)" "$p/CLAUDE.md" 2>/dev/null && pass "Stand-Block datiert heute" || fail "kein heutiger Stand-Block"
      grep -q '^## HIER WEITERMACHEN' "$p/CLAUDE.md" 2>/dev/null && grep -q '^- \[ \]' "$p/CLAUDE.md" && pass "HIER WEITERMACHEN mit Checkliste" || fail "HIER WEITERMACHEN/Checkliste fehlt"
      grep -qi 'notiz' "$p/CLAUDE.md" 2>/dev/null && pass "Zweck aus dem Argument übernommen" || fail "Zweck nicht übernommen"
      [ ! -d "$p/.git" ] && pass "kein Repo (Antwort: kein Git)" || fail "git init trotz „kein Git“"
      [ "$(sum "$fx/Documents/CLAUDE.md")" = "$r1" ] && [ "$(sum "$fx/Documents/4_Projekte/CLAUDE.md")" = "$r2" ] && pass "Router unangetastet (ls zeigt die Projekte)" || fail "Router-CLAUDE.md verändert"
      ;;
    neues-projekt:vorhanden)
      fixture_tree "$fx"; p="$fx/Documents/4_Projekte/01_Aktiv/Altprojekt"; mkdir -p "$p"
      printf '# CLAUDE.md — Altprojekt (Projekt)\n\nBestehendes Werkzeug, fertig eingerichtet.\n\n## Aktueller Stand (2026-08-01)\n\n- läuft\n' > "$p/CLAUDE.md"; printf '# Altprojekt\n' > "$p/README.md"
      c1=$(sum "$p/CLAUDE.md")
      run_cmd neues-projekt "$p" "$fx/transcript.txt"
      [ "$(sum "$p/CLAUDE.md")" = "$c1" ] && pass "bestehende CLAUDE.md unangetastet" || fail "CLAUDE.md wurde verändert"
      grep -q 'claude-md' "$fx/transcript.txt" && pass "verweist auf /claude-md als Wartungsgang" || fail "Hinweis auf /claude-md fehlt"
      [ ! -d "$p/.git" ] && pass "kein Repo angelegt" || fail "git init ohne Auftrag"
      ;;
    neues-projekt:nachruesten)
      fixture_tree "$fx"; p="$fx/Documents/4_Projekte/02_Persoenlich/Rezeptsammlung"; mkdir -p "$p/vorspeisen" "$p/hauptgerichte"
      printf '# Rezeptsammlung\n\nFamilienrezepte als Markdown, ein Ordner je Gang.\n' > "$p/README.md"
      printf '# Kürbissuppe\n\nZutaten: Kürbis, Zwiebel, Brühe.\n' > "$p/vorspeisen/kuerbissuppe.md"; printf '# Linsen\n\nZutaten: Linsen, Karotte.\n' > "$p/hauptgerichte/linsen.md"
      f1=$(sum "$p/README.md"); f2=$(sum "$p/vorspeisen/kuerbissuppe.md"); f3=$(sum "$p/hauptgerichte/linsen.md")
      run_cmd neues-projekt "$p" "$fx/transcript.txt" "--nachruesten"
      [ -f "$p/CLAUDE.md" ] && head -1 "$p/CLAUDE.md" | grep -q '^# CLAUDE.md — Rezeptsammlung (Projekt)$' && pass "Kopfzeile nennt Höhe Projekt" || fail "CLAUDE.md fehlt oder Kopfzeile falsch: $(head -1 "$p/CLAUDE.md" 2>/dev/null)"
      grep -qi 'rezept' "$p/CLAUDE.md" 2>/dev/null && pass "Zweck aus dem Inhalt abgeleitet" || fail "Zweck nicht aus dem Inhalt"
      grep -q "^## Aktueller Stand ($(date +%Y-%m)" "$p/CLAUDE.md" 2>/dev/null && pass "Stand-Block datiert heute" || fail "kein heutiger Stand-Block"
      [ "$(sum "$p/README.md")" = "$f1" ] && [ "$(sum "$p/vorspeisen/kuerbissuppe.md")" = "$f2" ] && [ "$(sum "$p/hauptgerichte/linsen.md")" = "$f3" ] && pass "bestehende Dateien unangetastet" || fail "bestehende Dateien verändert"
      [ ! -d "$p/.git" ] && pass "kein Repo ohne ausdrückliche Antwort" || fail "git init ohne Antwort"
      ;;
    optimieren:probe)
      fixture_clone "$fx"; r="$fx/repo"; z="$r/mats-tools/commands/zaehlen.md"
      g1=$(sum "$r/mats-tools/reference/authoring-guide.md"); z1=$(sum "$z")
      [ -n "${EVAL_MAX_TURNS:-}" ] || MAXTURNS=40   # Standard + Ziel + Szenario anlegen + zwei Läufe + Validator brauchen Runden
      run_cmd optimieren "$r" "$fx/transcript.txt" "zaehlen"
      [ "$(sum "$z")" != "$z1" ] && pass "Ziel-Datei geschärft" || fail "zaehlen.md unverändert"
      ! grep -Eq '^allowed-tools:.*(^|[ ,])Bash([ ,]|$)' "$z" && pass "kein blanket Bash mehr" || fail "allowed-tools noch mit blanket Bash"
      grep -q '^argument-hint:' "$z" && pass "argument-hint ergänzt" || fail "argument-hint fehlt"
      ! grep -q 'August 2025' "$z" && pass "zeit-sensitive Info entfernt" || fail "„Seit August 2025“ steht noch drin"
      ! grep -q 'bedanke dich' "$z" && pass "Füllsel entfernt" || fail "Dank-Floskel steht noch drin"
      [ "$(sum "$r/mats-tools/reference/authoring-guide.md")" = "$g1" ] && pass "Standard unangetastet" || fail "authoring-guide.md verändert"
      "$r/tools/eval.sh" --list | grep -q 'zaehlen:' && pass "Runner-Szenario angelegt" || fail "kein zaehlen-Szenario in eval.sh --list"
      (cd "$r" && ./tools/validate.sh >"$fx/validate.txt" 2>&1) && pass "Validator im Klon grün" || fail "Validator im Klon rot (siehe $fx/validate.txt)"
      grep -qi 'befund' "$fx/transcript.txt" && pass "Befund-Liste im Transkript" || fail "keine Befunde gemeldet"
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
  neues-projekt:leer     leerer Ordner unter 01_Aktiv, Zweck + Antworten als Argument → CLAUDE.md (Projekt, Stand, HIER WEITERMACHEN), kein Interview, kein Git, Router unangetastet
  neues-projekt:vorhanden  CLAUDE.md existiert → unverändert, Hinweis auf /claude-md
  neues-projekt:nachruesten  Ordner mit Inhalt, --nachruesten → CLAUDE.md mit Zweck aus dem Inhalt, Dateien unangetastet, kein Git
  optimieren:probe       Repo-Klon mit schlampigem Command → Ziel geschärft (enge Tools, argument-hint, kein Ballast), Szenario angelegt, Standard unangetastet, Validator grün
  alle                   alle obigen nacheinander
Freier Lauf:  tools/eval.sh <command> [prompt-zusatz]   (Transkript + Eval-Abschnitt, Urteil von Hand)
EOF
    exit 0 ;;
  alle) for s in finish:feature finish:clean finish-lite:sync finish-lite:synchron merken:stand neues-projekt:leer neues-projekt:vorhanden neues-projekt:nachruesten optimieren:probe xcode:leer; do szenario "$s"; done ;;
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
