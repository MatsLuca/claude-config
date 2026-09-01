---
description: Leichter /finish für Wissensprojekte — keine Analyse, keine Doku-Pflege: alles committen (Zeitstempel-Message), auf den Default-Branch rebasen und dorthin pushen. Funktioniert identisch lokal und in Cloud-Sessions (Session-Branches landen direkt auf main).
disable-model-invocation: true
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git pull:*), Bash(git push:*), Bash(git rebase:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git symbolic-ref:*), Bash(date:*), Bash(DEF=*), Bash(sh:*)
---

Du synchronisierst den Stand eines Wissensprojekts mit seinem Remote. **Keine Diff-Analyse, keine README/CHANGELOG/Issue-Pflege, keine ausformulierte Commit-Message, keine Rückfrage** — dafür gibt es `/finish`. Nichts vorab inspizieren. Die Reihenfolge ist die Regel; ein Schritt läuft erst, wenn der vorige geglückt ist:

1. Default-Branch: `git symbolic-ref --short refs/remotes/origin/HEAD` ohne das `origin/`, sonst `main`.
2. `git add -A`; ist etwas gestagt, `git commit -m "Stand <YYYY-MM-DD HH:MM>"` (Uhrzeit von `date`) — sonst kein leerer Commit.
3. `git pull --rebase origin <default>`.
4. `git push origin HEAD:<default>` — bewusst branch-agnostisch: auf dem Laptop steht man auf dem Default-Branch, in einer Cloud-Session auf einem Session-Branch (`claude/…`), und so landen die Änderungen ohne PR direkt dort.
5. `sh "${CLAUDE_PLUGIN_ROOT}/shell/sync.sh" --after-push` — zieht nur im Marketplace-Repo von `mats-tools` den Plugin-Cache nach, überall sonst endet es still; nichts dazu prüfen.

## Was am Ende gilt

- **Alles glatt** → eine Zeile: committet ja/nein (mit Message), Remote-Änderungen hereingeholt ja/nein, Push-Ziel und -Ergebnis.
- **Rebase-Konflikt** → sofort `git rebase --abort`, Ursache in einer Zeile, stoppen. Kein `--force`, keine eigenmächtige Konfliktauflösung — Konflikte in Wissensdateien entscheidet Mats.
- **Push abgelehnt** (non-fast-forward, weil sich der Default-Branch währenddessen bewegt hat, oder die Umgebung blockt direkte Pushes auf den Default-Branch) → nicht forcen, Ursache in einer Zeile. Im Blockade-Fall zusätzlich `git push -u origin HEAD`, damit nichts verloren geht, und das sagen.
- **Nichts zu tun** (kein Commit entstanden, „Already up to date", „Everything up-to-date") → nur „Schon synchron."
