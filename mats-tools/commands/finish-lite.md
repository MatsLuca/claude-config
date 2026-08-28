---
description: Leichter /finish für Wissensprojekte — keine Analyse, keine Doku-Pflege: alles committen (Zeitstempel-Message), auf den Default-Branch rebasen und dorthin pushen. Funktioniert identisch lokal und in Cloud-Sessions (Session-Branches landen direkt auf main).
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git pull:*), Bash(git push:*), Bash(git rebase:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git symbolic-ref:*), Bash(DEF=*), Bash(sh:*)
---

Du synchronisierst den Stand eines Wissensprojekts mit seinem Remote. **Keine Diff-Analyse, keine README/CHANGELOG/Issue-Pflege, keine ausformulierte Commit-Message** — dafür gibt es `/finish`. Hier zählt nur: lokalen Stand wegschreiben, Remote-Änderungen hereinholen, pushen.

Der Befehl ist bewusst **branch-agnostisch**, damit er überall gleich funktioniert: Auf dem Laptop steht man ohnehin auf dem Default-Branch; in einer Cloud-Session (eigener Session-Branch wie `claude/…`) sorgt `push HEAD:<default>` dafür, dass die Änderungen **direkt auf dem Default-Branch** landen — kein PR, kein manuelles Nachhelfen.

Führe genau diesen kombinierten Befehl aus (eine Bash-Runde, keine Einzelaufrufe, nichts vorab inspizieren):

```bash
DEF=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); DEF=${DEF#origin/}; DEF=${DEF:-main} && \
git add -A && \
{ git diff --cached --quiet || git commit -m "Stand $(date '+%Y-%m-%d %H:%M')"; } && \
git pull --rebase origin "$DEF" && \
git push origin HEAD:"$DEF" && \
sh "${CLAUDE_PLUGIN_ROOT}/shell/sync.sh" --after-push
```

(Die letzte Zeile zieht nur im Marketplace-Repo von `mats-tools` den Plugin-Cache nach — die nächste Session hat das Update dann sofort; überall sonst endet sie still. Nichts dazu prüfen.)

Auswertung:

- **Alles glatt** → melde in einer Zeile: committet ja/nein (mit Message), Remote-Änderungen hereingeholt ja/nein, Push-Ziel und -Ergebnis. Fertig.
- **`git pull --rebase` meldet Konflikt** → sofort `git rebase --abort`, dann Ursache melden und stoppen. **Kein** `--force`, keine eigenmächtige Konfliktauflösung — Konflikte in Wissensdateien entscheidet Mats.
- **Push abgelehnt** (non-fast-forward, weil der Default-Branch sich währenddessen bewegt hat, oder die Umgebung direkte Pushes auf den Default-Branch blockiert) → nicht forcen; Ursache in einer Zeile melden. Im Blockade-Fall zusätzlich den normalen Branch-Push (`git push -u origin HEAD`) ausführen, damit nichts verloren geht, und das sagen.
- **Nichts zu tun** (kein Commit entstanden, pull "Already up to date", push "Everything up-to-date") → melde nur „Schon synchron."
