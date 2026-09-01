---
description: Analysiert alle Änderungen seit dem letzten Push, pflegt README/CHANGELOG und zugehörige GitHub-Issues falls nötig, committet und pusht in einem Rutsch.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh issue list:*), Bash(gh issue view:*), Bash(gh issue comment:*), Bash(export PATH=*), Bash(echo:*), Bash(ls:*), Bash(sh:*), Read, Edit
---

Du schließt die aktuelle Arbeit ab: Änderungen seit dem letzten Push verstehen, wo nötig README/CHANGELOG und GitHub-Issues nachziehen, committen, pushen. Wie du dir den Überblick verschaffst, entscheidest du — wenige Runden, unabhängige Aufrufe parallel, Übersicht vor Vollinhalt (`git status --short`, `git log @{u}..HEAD --oneline`, `git diff @{u} --stat`, die letzten Commits als Stil-Referenz); den vollen Diff nur gezielt für Dateien, deren Stat-Zeile für Commit-Message und Doku-Entscheidung nicht reicht. Untracked Dateien sind neu — kurz ansehen, wenn relevant.

## Was am Ende gilt

- **Nichts zu tun** (Baum sauber, keine unpushed Commits) → melden und stoppen. Baum sauber, aber unpushed Commits → nur pushen, kein leerer Commit.
- **Kein Upstream** → der Branch wurde nie gepusht: „Diff seit Push" ist alles ab dem ersten Commit (`git diff HEAD --stat` plus untracked), Push mit `git push -u origin <branch>`.
- **README** nur anfassen, wenn die Änderung dort Dokumentiertes sichtbar verändert (Features, Commands, Setup, API) — punktuell per `Edit` in den betroffenen Abschnitten, nicht neu schreiben; interne Refactors und Bugfixes brauchen meist nichts. **CHANGELOG** nur ergänzen, wenn einer existiert, im Format und an der Stelle, die die Datei vorgibt (`## [Unreleased]` oder oben, mit heutigem Datum, falls die Datei Daten nutzt); keinen anlegen.
- **Issues** nur, wenn das Projekt sie nutzt: `gh issue list --state open --limit 30 --json number,title` (PATH um `/opt/homebrew/bin` ergänzen); schlägt es fehl oder ist leer, entfällt der Schritt ohne Nachhaken. Erledigt die Arbeit ein Issue → `Closes #<N>` in die Commit-Message, GitHub schließt es beim Push. Betroffen, aber nicht erledigt → einen Status-Kommentar nur anbieten; `gh issue comment` erst nach Zustimmung (externer Schreibzugriff). Bei Unsicherheit `gh issue view <N>`.
- **Commit:** Conventional-Commits-Subject (`type: kurze Beschreibung`, imperativ, im Stil der letzten Commits), bei mehreren logischen Änderungen ein kurzer Body mit dem *Warum*, je Issue eine Zeile `Closes #<N>`, zuletzt der Trailer `Co-Authored-By: Claude <noreply@anthropic.com>`. Message per Heredoc, damit Mehrzeiler sauber bleiben; alles stagen (`git add -A`, inklusive geänderter Docs), committen, pushen.
- **Push abgelehnt** (Remote weiter als lokal) → abbrechen und Ursache melden. Kein `--force`, kein automatischer Pull/Rebase.
- **Nach erfolgreichem Push** einmal `sh "${CLAUDE_PLUGIN_ROOT}/shell/sync.sh" --after-push`: im Marketplace-Repo von `mats-tools` zieht es den Plugin-Cache nach, überall sonst endet es still. Nichts dazu prüfen oder erklären — nur eine etwaige Ausgabe in die Meldung übernehmen.

## Meldung

Knapp: Commit-Message, aktualisierte Docs (falls), verlinkte, geschlossene oder kommentierte Issues (falls), Push-Ergebnis.
