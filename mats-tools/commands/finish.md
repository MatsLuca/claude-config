---
description: Analysiert alle Änderungen seit dem letzten Push, aktualisiert README/CHANGELOG falls nötig, committet und pusht in einem Rutsch.
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Read, Edit
---

Du schließt die aktuelle Arbeit ab: Änderungen seit dem letzten GitHub-Push analysieren, ggf. README/CHANGELOG pflegen, dann committen und pushen.

**Arbeite token-effizient: erst billige Übersichten, vollen Inhalt nur bei Bedarf.**

## Schritt 1 — Zustand in EINEM Aufruf erfassen

Führe genau diesen kombinierten Befehl aus (eine Bash-Runde, keine Einzelaufrufe):

```bash
echo "=== BRANCH ===" && git rev-parse --abbrev-ref HEAD && \
echo "=== UPSTREAM ===" && git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "NO_UPSTREAM" && \
echo "=== STATUS ===" && git status --short && \
echo "=== UNPUSHED COMMITS ===" && git log @{u}..HEAD --oneline 2>/dev/null || echo "(kein upstream / alle commits via stat unten)" && \
echo "=== DIFFSTAT (tracked, seit Push) ===" && git diff @{u} --stat 2>/dev/null || git diff HEAD --stat
```

Auswertung:
- **Keine Änderungen** (leerer Status, keine unpushed commits) → melde das und stoppe. Nichts zu tun.
- **Kein Upstream** (`NO_UPSTREAM`) → der Branch wurde nie gepusht. Nimm beim Push `git push -u origin <branch>`. Als "Diff seit Push" gilt dann alles ab dem ersten Commit; nutze `git diff HEAD --stat` plus untracked Dateien aus dem Status.

## Schritt 2 — Verstehen, was passiert ist

Die `--stat`-Übersicht reicht meist, um Umfang und Art der Änderung zu erkennen.
- Nur wenn die Stat-Liste nicht ausreicht, um eine gute Commit-Message und README/CHANGELOG-Entscheidung zu treffen, lies den vollen Diff **gezielt** für die relevanten Dateien: `git diff @{u} -- <pfad>`. Lade nicht den kompletten Diff blind.
- Untracked Dateien (`??` im Status) sind neu — kurz anschauen, wenn relevant.

Fasse für dich in 1-2 Sätzen zusammen, was die Änderung bewirkt (Feature / Fix / Refactor / Docs / Chore).

## Schritt 3 — README & CHANGELOG prüfen

Existenz billig prüfen, bevor du liest:

```bash
ls README* CHANGELOG* 2>/dev/null
```

- **README**: Nur lesen/aktualisieren, wenn die Änderung etwas Sichtbares betrifft, das dort dokumentiert ist (neue Features, geänderte Commands, Setup, API). Reine interne Refactors/Bugfixes brauchen meist kein README-Update. Wenn du liest und es groß ist, lies gezielt die betroffenen Abschnitte.
- **CHANGELOG**: Falls vorhanden, neuen Eintrag passend zum bestehenden Format/Stil ergänzen (z.B. unter `## [Unreleased]` oder oben, je nach Konvention der Datei). Datum heute verwenden, falls das Format Daten nutzt. Existiert kein CHANGELOG, erstelle KEINS von dir aus.

Nutze `Edit` für punktuelle Änderungen statt die Datei neu zu schreiben.

## Schritt 4 — Commit-Message überlegen

Conventional-Commits-Stil, an den Stil der letzten Commits angepasst. Knappe imperative Subject-Zeile (`type: kurze Beschreibung`), bei mehreren logischen Änderungen kurze Bullet-Body. Beschreibe das *Warum*, nicht nur das *Was*.

## Schritt 5 — Committen & Pushen in einem Rutsch

Wenn alles bereit ist (inkl. ggf. geänderter README/CHANGELOG), alles stagen und committen. Message via heredoc, damit Mehrzeiler sauber sind, und mit Co-Author-Trailer:

```bash
git add -A && git commit -m "$(cat <<'EOF'
<subject>

<optionaler body>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)" && git push
```

(Bei fehlendem Upstream stattdessen `git push -u origin <branch>`.)

Melde am Ende kurz: Commit-Message, welche Docs aktualisiert wurden (falls), und das Push-Ergebnis.
