---
description: Schärft einen Command, Agent, Skill oder eine Referenzdatei gegen den Authoring-Standard — Befund-Liste, gezielte Edits, Eval-Lauf vorher und nachher (ein fehlendes Runner-Szenario legt der Command selbst an). Meta-Pass über Standard/Evals selbst möglich.
argument-hint: <command-, agent-, skill- oder referenz-name, z.B. "finish", "pdf-to-markdown", "authoring-guide" — oder Pfad eines Werkstatt-Skills, z.B. "skills/scan">
allowed-tools: Read, Edit, Glob, Grep, Bash(ls:*), Bash(wc:*), Bash(git status:*), Bash(diff:*), Bash(git pull --ff-only:*), Bash(./tools/validate.sh:*), Bash(tools/eval.sh:*), Bash(EVAL_OUT=*), Bash(mkdir:*), WebFetch(domain:platform.claude.com), AskUserQuestion
---

Du schärfst einen Command, Agent, Skill oder eine Referenzdatei — aus diesem Plugin oder aus der Skill-Werkstatt (privates Repo `claude-werkstatt`) — gegen den Authoring-Standard `${CLAUDE_PLUGIN_ROOT}/reference/authoring-guide.md` (nicht auffindbar → `Glob` `**/reference/authoring-guide.md`; ohne Standard keine Prüfung). Ziel ist, dass der Baustein seinen **Zweck besser erfüllt**. Schärfen ist nicht Kürzen: was fehlt oder schief steht, wird ergänzt oder umformuliert — ein zu knappes Ziel wird durch Addition besser. Wenige Runden, unabhängige Reads parallel, große Dateien nur in den betroffenen Abschnitten.

Ziel: **$ARGUMENTS**

## Ziel auflösen

- Name (ohne `/` und `.md`) gegen `commands/`, `agents/`, `reference/` und `skills/*/SKILL.md` des Repos matchen; Übersicht billig per `ls`, sonst `Glob`. Genau ein Treffer → diese Datei. Mehrere, keiner oder leeres Argument → per `AskUserQuestion` fragen, nicht raten. Merke dir den Typ (Command, Agent, Skill, Referenzdatei) — die Prüfregeln unterscheiden sich.
- Immer die **Repo-Quelle** bearbeiten, nie die installierte Kopie unter `${CLAUDE_PLUGIN_ROOT}` (Plugin-Cache, wird beim Update überschrieben).
- **Frische-Check** vor dem ersten Edit: `git status` plus `diff -rq --exclude=.in_use mats-tools "${CLAUDE_PLUGIN_ROOT}"`. Cleaner Baum, aber inhaltliche Abweichung → das Repo hängt vermutlich hinter dem Remote: `git pull --ff-only`, Geändertes neu lesen. Meldet der Pull „up to date", ist das Repo voraus — dann gilt die Repo-Fassung auch für Standard und Evals. Schlägt er fehl → melden und stoppen. Nie eine veraltete Fassung schärfen.
- **Werkstatt-Skill** (Pfad wie `skills/scan` oder cwd ist das Werkstatt-Repo): Ziel ist dessen `SKILL.md`, Prüfgrundlage bleibt der Plugin-Standard, Evals aus `<repo-root>/evals.md` (Abschnitt `## <name>`), Frische-Check nur `git status`. Companion-Dateien (Code, `setup.sh`) bleiben unangetastet — nur die Prosa, die Claude lädt.
- **Meta-Pass** (Treffer in `reference/`, z.B. `authoring-guide`, `evals`; ebenso `claude-md` = SKILL.md **und** `verfassung.md`): die Referenzdatei ist selbst das Ziel. Prüfgrundlage ist dann nicht die Checkliste (Zirkelschluss), sondern der Abschnitt „Meta-Pflege" der Datei: Zweck-Erfüllung, Abgleich mit den dort verlinkten Upstream-Best-Practices (`WebFetch`) und den aktuellen Plattform-Fähigkeiten.

## Was am Ende gilt

- **Zweck in einem Satz, dann Befund-Liste** in zwei Richtungen: Zweck-Lücken (fehlt, unklar, schief — was das Ziel wirksamer macht) und Standard-Verstöße (Command/Agent/Skill: Review-Checkliste des Standards Punkt für Punkt, je Typ). Kurz, was schon gut ist. Jeder Befund braucht Wirkung; nichts erfinden, wo Zweck **und** Standard erfüllt sind, nichts ergänzen, was nur die Knappheit aufbläht.
- **Beleg vorher und nachher.** Der Eval-Abschnitt des Ziels (Plugin: `reference/evals.md`, Werkstatt: `<repo-root>/evals.md`) sagt, welches Verhalten erhalten bleibt; fehlt er, ist das ein Befund — erst Szenarien schreiben, dann schärfen. Plugin-Commands brauchen ein Runner-Szenario in `tools/eval.sh` (`--list`); fehlt es, legst du zuerst eines nach dem Muster der vorhandenen an (Fixture im Wegwerf-Ordner, Prüfungen auf der Platte oder am Transkript, Eintrag in `--list` und `alle`). Baseline **vor** dem ersten Edit: `EVAL_OUT=<ordner> tools/eval.sh <szenario>` — rot vorher ist selbst ein Befund. Agents, Skills und Werkstatt-Ziele laufen interaktiv oder im freien Lauf (`tools/eval.sh <command> [zusatz]`); dort ist das Transkript der Beleg.
- **Schärfen per `Edit`** an den betroffenen Stellen, nicht die Datei neu schreiben; Sprach-Split und Format-Konventionen des Standards wahren, Gültiges nicht überschreiben. Die **Outcomes** der Eval-Szenarien bleiben erhalten, die Implementierung darf sich verbessern; berührt eine Änderung den *Wortlaut* eines Evals, passe `evals.md` explizit an — nie stillschweigend.
- **Verifiziert:** `./tools/validate.sh` (falls vorhanden) und danach das Runner-Szenario erneut. Rot, das deine Edits verursacht haben, fixen oder zurücknehmen — erst grün abschließen; vorbestehendes Rot fremder Herkunft nur melden.
- **Housekeeping:** haben sich `description`, Name oder sichtbares Verhalten geändert, weise auf die README-Zeile hin (Plugin oder Werkstatt) und biete an, sie per `/finish` mitzunehmen — die README nicht ungefragt ändern.

## Meldung

Welche Datei geschärft wurde; die 2–3 wichtigsten Befunde und was daraus wurde, jeweils mit Standard-Bezug; Eval vorher/nachher (Szenario, Prüfungen grün/rot, Zeilen vorher → nachher) — ohne Runner-Szenario stattdessen ein Testszenario, mit dem der User gegenprüfen kann.
