---
description: Leichter /finish für Wissensprojekte — keine Analyse, keine Doku-Pflege: die Änderungen dieser Session committen (Zeitstempel-Message), auf den Default-Branch rebasen und dorthin pushen; Änderungen anderer Sessions bleiben liegen. Funktioniert identisch lokal und in Cloud-Sessions (Session-Branches landen direkt auf main).
argument-hint: <optional: „alles" = auch fremde Änderungen mitnehmen>
disable-model-invocation: true
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git pull:*), Bash(git push:*), Bash(git rebase:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git symbolic-ref:*), Bash(date:*), Bash(DEF=*), Bash(sh:*)
---

Du synchronisierst den Stand eines Wissensprojekts mit seinem Remote. **Keine Diff-Analyse, keine README/CHANGELOG/Issue-Pflege, keine ausformulierte Commit-Message, keine Rückfrage** — dafür gibt es `/finish`. Nichts vorab inspizieren außer `git status --short`: Oft arbeiten mehrere Claude-Sessions parallel im selben Ordner, und nur **eigene** Änderungen gehören in den Commit — was diese Session laut Verlauf selbst angelegt, geändert oder gelöscht hat. Alles andere ist fremd: liegen lassen und in der Meldung benennen. Steht `alles` in `$ARGUMENTS`, gilt alles als eigen. Die Reihenfolge ist die Regel; ein Schritt läuft erst, wenn der vorige geglückt ist:

1. Default-Branch: `git symbolic-ref --short refs/remotes/origin/HEAD` ohne das `origin/`, sonst `main`.
2. Eigene Pfade stagen (`git add -A -- <pfade>`) und nur sie committen: `git commit -m "Stand <YYYY-MM-DD HH:MM>" -- <pfade>` (Uhrzeit von `date`; die Pfadangabe hält fremd Gestagtes aus dem Commit) — nichts Eigenes offen → kein Commit.
3. `git pull --rebase --autostash origin <default>` — `--autostash`, weil fremde, nicht committete Änderungen den Rebase sonst blockieren; sie liegen danach unverändert wieder im Baum.
4. `git push origin HEAD:<default>` — bewusst branch-agnostisch: auf dem Laptop steht man auf dem Default-Branch, in einer Cloud-Session auf einem Session-Branch (`claude/…`), und so landen die Änderungen ohne PR direkt dort.
5. `sh "${CLAUDE_PLUGIN_ROOT}/shell/sync.sh" --after-push` — zieht nur im Marketplace-Repo von `mats-tools` den Plugin-Cache nach, überall sonst endet es still; nichts dazu prüfen.

## Was am Ende gilt

- **Alles glatt** → eine Zeile: committet ja/nein (mit Message), Remote-Änderungen hereingeholt ja/nein, Push-Ziel und -Ergebnis; gibt es fremde Änderungen, dahinter „liegen gelassen: <Pfade>".
- **Rebase-Konflikt** → sofort `git rebase --abort`, Ursache in einer Zeile, stoppen. Kein `--force`, keine eigenmächtige Konfliktauflösung — Konflikte in Wissensdateien entscheidet Mats.
- **Push abgelehnt** (non-fast-forward, weil sich der Default-Branch währenddessen bewegt hat, oder die Umgebung blockt direkte Pushes auf den Default-Branch) → nicht forcen, Ursache in einer Zeile. Im Blockade-Fall zusätzlich `git push -u origin HEAD`, damit nichts verloren geht, und das sagen.
- **Nichts zu tun** (kein Commit entstanden, „Already up to date", „Everything up-to-date") → nur „Schon synchron." — bei fremden Änderungen mit dem Zusatz „liegen gelassen: <Pfade> (`/finish-lite alles` nimmt sie mit)".
