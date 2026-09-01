---
description: Optimiert einen Command, Agent oder Skill nach dem Authoring-Standard — prüft Frontmatter, Klarheit und Token-Effizienz und schärft die Definition, mit Eval-Lauf vorher und nachher (Runner-Szenario wird angelegt, falls es fehlt). Meta-Pass über Standard/Evals selbst möglich.
argument-hint: <command-, agent-, skill- oder referenz-name, z.B. "finish", "pdf-to-markdown", "authoring-guide" — oder Pfad eines Werkstatt-Skills, z.B. "skills/scan">
allowed-tools: Read, Edit, Glob, Bash(ls:*), Bash(git status:*), Bash(diff:*), Bash(git pull --ff-only:*), Bash(./tools/validate.sh:*), Bash(tools/eval.sh:*), Bash(EVAL_OUT=*), Bash(mkdir:*), WebFetch(domain:platform.claude.com), AskUserQuestion
---

Du optimierst einen Command, Agent, Skill oder eine Referenzdatei — aus diesem Plugin oder aus der Skill-Werkstatt (privates Repo `claude-werkstatt`) — gegen den Authoring-Standard, damit das Ziel seinen **Zweck besser erfüllt** — klarer, eindeutiger, token-effizienter. Optimieren ist nicht gleich Kürzen: oft heißt das verdichten, genauso aber **ergänzen oder umformulieren**, wo etwas fehlt oder schief steht — ein zu knappes oder unklares Ziel wird durch Addition besser, nicht durch weiteres Streichen.

Zu optimierendes Ziel: **$ARGUMENTS**

**Token-effizient bündeln:** Unabhängige Reads parallel — Standard (Schritt 1) und Ziel-Auflösung (Schritt 2) zusammen, dann Ziel-Datei + Evals (Schritt 3) zusammen. Vollen Inhalt nur bei Bedarf.

## Schritt 1 — Standard laden

Lies den Authoring-Standard: `${CLAUDE_PLUGIN_ROOT}/reference/authoring-guide.md`.

Falls die Variable nicht aufgelöst wird (Datei nicht gefunden), suche sie per `Glob`: `**/reference/authoring-guide.md`. Ohne den Standard nicht weitermachen — er ist die Prüfgrundlage.

## Schritt 2 — Ziel bestimmen

`$ARGUMENTS` ist ein Name oder Pfad. Löse ihn zur Datei auf:
- Billige Übersicht + Frische-Check in *einer* Bash-Runde:

```bash
ls mats-tools/commands mats-tools/agents mats-tools/reference mats-tools/skills && \
git status --porcelain && \
diff -rq --exclude=.in_use mats-tools "${CLAUDE_PLUGIN_ROOT}"
```

  Den Namen (ohne `/` und `.md`) gegen die Liste matchen; ein Skill-Name trifft dessen `SKILL.md`. Greift `ls` nicht (anderes Arbeitsverzeichnis), per `Glob` `**/commands/*.md`, `**/agents/*.md`, `**/reference/*.md` und `**/skills/*/SKILL.md` nachladen.
- **Werkstatt-Skill** (Pfad wie `skills/scan` oder cwd ist das Werkstatt-Repo): Ziel ist dessen `SKILL.md`; Prüfgrundlage bleibt der Standard aus dem Plugin, die Evals kommen aus `<repo-root>/evals.md` des Werkstatt-Repos (Abschnitt `## <name>`). Frische-Check dann nur `git status` (kein Plugin-Cache-Diff). Companion-Dateien (Code, `setup.sh`) werden nicht optimiert — nur die Prosa, die Claude lädt.
- **Genau ein Treffer** → diese Datei. **Mehrere/keine** → per `AskUserQuestion` kurz rückfragen statt zu raten.
- Ist `$ARGUMENTS` leer → frage, welches Ziel (Command, Agent oder Referenzdatei) optimiert werden soll.
- **Meta-Pass:** Liegt der Treffer in `reference/` (z.B. `authoring-guide`, `evals`), ist die Referenzdatei *selbst* das Ziel. Prüfgrundlage ist dann **nicht** der Standard selbst (Zirkelschluss), sondern der Abschnitt „Meta-Pflege des Standards" im Guide: Zweck-Erfüllung + Abgleich gegen die dort verlinkten Upstream-Best-Practices (per `WebFetch`) und die aktuellen Plattform-Fähigkeiten. Gleiches gilt für `skills/claude-md/verfassung.md` (Ziel `claude-md` = SKILL.md **und** Verfassung): Prüfgrundlage ist deren Abschnitt „Meta-Pflege" — bleiben Router/Bereiche unter Budget, stimmt die Lademechanik noch?
- Immer die **Repo-Quelle** auflösen und bearbeiten — nie die installierte Kopie unter `${CLAUDE_PLUGIN_ROOT}` (Plugin-Cache, wird beim nächsten Update überschrieben).
- **Frische-Check (die `git status`/`diff`-Teile der Runde oben):** (nur *inhaltliche* Abweichungen zählen — Cache-Marker wie `.in_use`, die nur im Cache liegen, sind kein Divergenz-Signal und werden ausgeblendet). Cleaner Baum, aber Abweichung → das Repo hängt vermutlich hinter dem Remote (Push von anderer Maschine): `git pull --ff-only`, danach Geändertes neu lesen. Meldet der Pull „up to date", ist das Repo schlicht voraus — dann gilt die Repo-Fassung auch für Standard + Evals (statt der Cache-Fassung aus Schritt 1/3). Schlägt er fehl: melden und stoppen. Nie eine veraltete Fassung schärfen.

Merke dir, ob es ein **Command**, **Agent** oder eine **Referenzdatei** ist — die Prüfregeln unterscheiden sich.

## Schritt 3 — Ziel + Evals lesen

- Ziel-Datei lesen.
- Falls vorhanden, die zugehörigen Szenarien lesen — sie sagen, welches Verhalten erhalten bleiben muss: Plugin-Ziele aus `${CLAUDE_PLUGIN_ROOT}/reference/evals.md` (bzw. per Glob `**/reference/evals.md`), Werkstatt-Ziele aus `<repo-root>/evals.md`. Fehlt der Abschnitt, ist das selbst ein Befund (Schritt 4): erst Szenarien schreiben, dann schärfen.
- **Runner-Szenario (Plugin-Commands):** `tools/eval.sh --list` zeigt, ob das Ziel eines hat. Fehlt es, schreibe zuerst eines nach dem Muster der vorhandenen (Fixture im Wegwerf-Ordner, Prüfungen auf der Platte oder am Transkript, Eintrag in `--list` und `alle`) — ohne Szenario gibt es keinen Beleg, dass das Schärfen nichts bricht. Dann der Lauf **vor** dem Schärfen als Baseline (`EVAL_OUT=<ordner> tools/eval.sh <szenario>`; rot vorher ist selbst ein Befund für Schritt 4) und in Schritt 6 der Lauf **danach** als Beweis. Agents, Skills und Werkstatt-Ziele laufen interaktiv bzw. im freien Lauf (`tools/eval.sh <command> [zusatz]`) — dort bleibt das Transkript neben dem Eval-Abschnitt der Beleg.

## Schritt 4 — Zweck klären, dann gegen den Standard prüfen

Erst inhaltlich, dann mechanisch. Formuliere in *einem* Satz: **Was soll dieses Ziel erreichen?** Dann prüfe zwei Richtungen:
- **Wirkt es?** Erreicht das Ziel seinen Zweck zuverlässig — oder fehlt etwas (ein Schritt, ein Beispiel, eine Klärung, ein Eval-Fall), das es wirksamer machen würde? Steht etwas unklar oder schief, das umformuliert gehört? Solche Zweck-Lücken sind echte Befunde, auch wenn nichts gegen die Checkliste verstößt.
- **Standard-Konformität:** Bei **Command/Agent** die Review-Checkliste des Standards Punkt für Punkt durchgehen (Command- vs. Agent-Teil je nach Typ). Bei einer **Referenzdatei** gilt stattdessen der Meta-Pass aus Schritt 2: *nicht* gegen die Checkliste prüfen (Zirkelschluss), sondern gegen Zweck-Erfüllung + Deckung mit den Upstream-Best-Practices und den aktuellen Plattform-Fähigkeiten.

Erstelle eine knappe **Befund-Liste**:
- was bereits gut ist (kurz),
- Zweck-Lücken (fehlt / unklar / schief) — mit kurzer Begründung, *was* das Ziel wirksamer macht,
- Standard-Verstöße — mit Checklisten-Bezug und kurzer Begründung *warum*.

Jeder Befund braucht Wirkung: jede Änderung muss das Ziel messbar besser machen. Nichts erfinden, wo Zweck **und** Standard erfüllt sind; und nichts ergänzen, was nur die Knappheit aufbläht (siehe „Knapp ist König").

## Schritt 5 — Schärfen

Setze die Befunde per `Edit` gezielt um:
- Nur die betroffenen Stellen ändern, **nicht** die ganze Datei neu schreiben.
- Sprach-Split und Format-Konventionen wahren (siehe Standard).
- Noch gültige Inhalte nicht überschreiben — je nach Befund verdichten, präzisieren oder gezielt ergänzen.
- Die **Outcomes** der Eval-Szenarien müssen erhalten bleiben — die Implementierung dahinter darf sich verbessern. Berührt eine Verbesserung den *Wortlaut* eines Evals, passe `evals.md` explizit mit an (nie stillschweigend).

## Schritt 6 — Verifizieren

Existiert `tools/validate.sh` im Repo-Root, führe es aus (`./tools/validate.sh`). Rote Befunde, die deine Edits verursacht haben, sofort fixen und erneut laufen lassen — erst grün abschließen. Vorbestehende Rot-Befunde fremder Herkunft nicht stillschweigend mitfixen — nur melden.

Dann das Runner-Szenario aus Schritt 3 erneut laufen lassen. Bleibt eine Prüfung rot, die vorher grün war, nachbessern oder die Änderung zurücknehmen — nie rot abschließen.

## Schritt 7 — Housekeeping prüfen

Wenn sich `description`, Name oder das nach außen sichtbare Verhalten geändert haben, weise darauf hin, dass die README-Zeile (Plugin: `README.md`; Werkstatt: dessen `README.md`) nachgezogen werden muss — und biete an, das via `/finish` mitzunehmen. Diese Datei hier **nicht** ungefragt ändern.

## Abschluss

Melde knapp:
- Welche Datei optimiert wurde + 2-3 wichtigste Änderungen (mit dem jeweiligen Standard-Bezug).
- Eval vorher/nachher: Szenario, Prüfungen grün/rot, Zeilen vorher → nachher; ohne Runner-Szenario stattdessen ein Testszenario, mit dem der User gegenprüfen kann.
