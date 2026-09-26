---
description: Analysiert die Änderungen dieser Session seit dem letzten Push, pflegt README/CHANGELOG und zugehörige GitHub-Issues falls nötig, committet und pusht in einem Rutsch — Änderungen anderer Sessions bleiben liegen und werden benannt.
argument-hint: <optional: „alles" = auch fremde Änderungen mitnehmen>
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh issue list:*), Bash(gh issue view:*), Bash(gh issue comment:*), Bash(export PATH=*), Bash(echo:*), Bash(ls:*), Bash(sh:*), Read, Edit
---

Du schließt die Arbeit **dieser Session** ab: ihre Änderungen seit dem letzten Push verstehen, wo nötig README/CHANGELOG und GitHub-Issues nachziehen, committen, pushen. Wie du dir den Überblick verschaffst, entscheidest du — wenige Runden, unabhängige Aufrufe parallel, Übersicht vor Vollinhalt (`git status --short`, `git log @{u}..HEAD --oneline`, `git diff @{u} --stat`, die letzten Commits als Stil-Referenz); den vollen Diff nur gezielt für Dateien, deren Stat-Zeile für Commit-Message und Doku-Entscheidung nicht reicht. Untracked Dateien sind neu — kurz ansehen, wenn relevant.

## Nur die eigenen Änderungen

Oft arbeiten mehrere Claude-Sessions parallel im selben Ordner; ihre halbfertigen Dateien dürfen nicht in deinen Commit. **Eigen** ist, was diese Session selbst angelegt, geändert oder gelöscht hat (Edit/Write, per Bash erzeugt, von deinen Subagenten, dazu die Doku, die `/finish` gleich nachzieht) — das weißt du aus dem Verlauf, nicht aus dem Baum. Alles andere in `git status` ist **fremd**: nicht stagen, nicht committen, nicht anfassen, sondern in der Meldung benennen.

- Steht `alles` in `$ARGUMENTS` oder sagt Mats, das Fremde gehöre dazu → dann wie früher alles mitnehmen.
- Hat diese Session nichts geändert (frischer Aufruf) → die offenen Änderungen auflisten und einmal fragen, welche mitsollen; ohne Antwort nichts committen.
- Enthält eine eigene Datei zusätzlich Hunks, die nicht von dir stammen → die Datei nicht committen, benennen und fragen.
- Den Index teilen sich alle Sessions: Hat jemand anders schon etwas gestagt, nimmt ein bloßes `git commit` das mit. Deshalb eigene Pfade gezielt stagen (`git add -A -- <pfade>`, erfasst auch Löschungen) und nur sie committen (`git commit … -- <pfade>`); Fremd-Gestagtes bleibt gestagt.
- Bereits committete, noch nicht gepushte Commits sind abgeschlossene Arbeit — sie gehen mit dem Push raus; die Meldung nennt fremde darunter.

## Was am Ende gilt

- **Nichts zu tun** (keine eigenen Änderungen, keine unpushed Commits) → melden und stoppen, fremde Änderungen dabei benennen. Nichts Eigenes offen, aber unpushed Commits → nur pushen, kein leerer Commit.
- **Kein Upstream** → der Branch wurde nie gepusht: „Diff seit Push" ist alles ab dem ersten Commit (`git diff HEAD --stat` plus untracked), Push mit `git push -u origin <branch>`.
- **README** nur anfassen, wenn die Änderung dort Dokumentiertes sichtbar verändert (Features, Commands, Setup, API) — punktuell per `Edit` in den betroffenen Abschnitten, nicht neu schreiben; interne Refactors und Bugfixes brauchen meist nichts. **CHANGELOG** nur ergänzen, wenn einer existiert, im Format und an der Stelle, die die Datei vorgibt (`## [Unreleased]` oder oben, mit heutigem Datum, falls die Datei Daten nutzt); keinen anlegen.
- **Issues** nur, wenn das Projekt sie nutzt: `gh issue list --state open --limit 30 --json number,title` (PATH um `/opt/homebrew/bin` ergänzen); schlägt es fehl oder ist leer, entfällt der Schritt ohne Nachhaken. Erledigt die Arbeit ein Issue → `Closes #<N>` in die Commit-Message, GitHub schließt es beim Push. Betroffen, aber nicht erledigt → einen Status-Kommentar nur anbieten; `gh issue comment` erst nach Zustimmung (externer Schreibzugriff). Bei Unsicherheit `gh issue view <N>`.
- **Commit:** Conventional-Commits-Subject (`type: kurze Beschreibung`, imperativ, im Stil der letzten Commits), bei mehreren logischen Änderungen ein kurzer Body mit dem *Warum*, je Issue eine Zeile `Closes #<N>`, zuletzt der Trailer `Co-Authored-By: Claude <noreply@anthropic.com>`. Message per Heredoc, damit Mehrzeiler sauber bleiben; die eigenen Pfade (inklusive nachgezogener Docs) stagen und committen wie oben, pushen.
- **Push abgelehnt** (Remote weiter als lokal) → abbrechen und Ursache melden. Kein `--force`, kein automatischer Pull/Rebase.
- **Nach erfolgreichem Push** einmal `sh "${CLAUDE_PLUGIN_ROOT}/shell/sync.sh" --after-push`: im Marketplace-Repo von `mats-tools` zieht es den Plugin-Cache nach, überall sonst endet es still. Nichts dazu prüfen oder erklären — nur eine etwaige Ausgabe in die Meldung übernehmen.

## Meldung

Mats liest nur diese Meldung, nicht das Terminal — sie muss den Abschluss vollständig belegen: das Commit-Subject wörtlich (mit Kurz-Hash), welche Doku-Datei wie ergänzt wurde (falls), verlinkte, geschlossene oder kommentierte Issues (falls), Push-Ziel und -Ergebnis, und — falls vorhanden — eine Zeile „Liegen gelassen (andere Session): <Pfade>". Wenige Zeilen, keine Erklärung des Vorgehens; ein bloßes „Fertig." ist keine Meldung.
