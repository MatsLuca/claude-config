---
description: Leichter /finish für Wissensprojekte — keine Analyse, keine Doku-Pflege: alles committen (Zeitstempel-Message), Remote-Stand einrebasen, pushen.
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git pull:*), Bash(git push:*), Bash(git rebase:*), Bash(git rev-parse:*), Bash(git status:*)
---

Du synchronisierst den Stand eines Wissensprojekts mit seinem Remote. **Keine Diff-Analyse, keine README/CHANGELOG/Issue-Pflege, keine ausformulierte Commit-Message** — dafür gibt es `/finish`. Hier zählt nur: lokalen Stand wegschreiben, Remote-Änderungen (z. B. aus Cloud-Sessions vom Handy) hereinholen, pushen.

Führe genau diesen kombinierten Befehl aus (eine Bash-Runde, keine Einzelaufrufe, nichts vorab inspizieren):

```bash
git add -A && \
{ git diff --cached --quiet || git commit -m "Stand $(date '+%Y-%m-%d %H:%M')"; } && \
git pull --rebase && \
git push
```

Auswertung:

- **Alles glatt** → melde in einer Zeile: committet ja/nein (mit Message), Remote-Änderungen hereingeholt ja/nein, Push-Ergebnis. Fertig.
- **`git pull --rebase` meldet Konflikt** → sofort `git rebase --abort`, dann Ursache melden und stoppen. **Kein** `--force`, keine eigenmächtige Konfliktauflösung — Konflikte in Wissensdateien entscheidet Mats.
- **Kein Upstream** (Push schlägt mit "no upstream" fehl) → einmalig `git push -u origin $(git rev-parse --abbrev-ref HEAD)`.
- **Nichts zu tun** (kein Commit entstanden, pull "Already up to date", push "Everything up-to-date") → melde nur „Schon synchron."
