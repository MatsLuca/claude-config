---
description: Optimiert einen Command oder Agent nach dem Authoring-Standard — prüft Frontmatter, Klarheit und Token-Effizienz und schärft die Definition. Meta-Pass über Standard/Evals selbst möglich.
argument-hint: <command-, agent- oder referenz-name, z.B. "finish", "pdf-to-markdown" oder "authoring-guide">
allowed-tools: Read, Edit, Glob, Bash(ls:*), Bash(git status:*), Bash(diff:*), Bash(git pull --ff-only:*), Bash(./tools/validate.sh:*), WebFetch(domain:platform.claude.com), AskUserQuestion
---

Du optimierst einen Command, Agent oder eine Referenzdatei dieses Plugins gegen den Authoring-Standard, damit das Ziel seinen **Zweck besser erfüllt** — klarer, eindeutiger, token-effizienter. Optimieren ist nicht gleich Kürzen: oft heißt das verdichten, genauso aber **ergänzen oder umformulieren**, wo etwas fehlt oder schief steht — ein zu knappes oder unklares Ziel wird durch Addition besser, nicht durch weiteres Streichen.

Zu optimierendes Ziel: **$ARGUMENTS**

**Token-effizient bündeln:** Unabhängige Reads parallel — Standard (Schritt 1) und Ziel-Auflösung (Schritt 2) zusammen, dann Ziel-Datei + Evals (Schritt 3) zusammen. Vollen Inhalt nur bei Bedarf.

## Schritt 1 — Standard laden

Lies den Authoring-Standard: `${CLAUDE_PLUGIN_ROOT}/reference/authoring-guide.md`.

Falls die Variable nicht aufgelöst wird (Datei nicht gefunden), suche sie per `Glob`: `**/reference/authoring-guide.md`. Ohne den Standard nicht weitermachen — er ist die Prüfgrundlage.

## Schritt 2 — Ziel bestimmen

`$ARGUMENTS` ist ein Name oder Pfad. Löse ihn zur Datei auf:
- Billige Übersicht in *einer* Bash-Runde: `ls mats-tools/commands mats-tools/agents mats-tools/reference` — listet alle Kandidaten auf einmal. Den Namen (ohne `/` und `.md`) dagegen matchen. Greift `ls` nicht (anderes Arbeitsverzeichnis), per `Glob` `**/commands/*.md`, `**/agents/*.md` und `**/reference/*.md` nachladen.
- **Genau ein Treffer** → diese Datei. **Mehrere/keine** → per `AskUserQuestion` kurz rückfragen statt zu raten.
- Ist `$ARGUMENTS` leer → frage, welches Ziel (Command, Agent oder Referenzdatei) optimiert werden soll.
- **Meta-Pass:** Liegt der Treffer in `reference/` (z.B. `authoring-guide`, `evals`), ist die Referenzdatei *selbst* das Ziel. Prüfgrundlage ist dann **nicht** der Standard selbst (Zirkelschluss), sondern der Abschnitt „Meta-Pflege des Standards" im Guide: Zweck-Erfüllung + Abgleich gegen die dort verlinkten Upstream-Best-Practices (per `WebFetch`) und die aktuellen Plattform-Fähigkeiten.
- Immer die **Repo-Quelle** auflösen und bearbeiten — nie die installierte Kopie unter `${CLAUDE_PLUGIN_ROOT}` (Plugin-Cache, wird beim nächsten Update überschrieben).
- **Frische-Check (an die `ls`-Runde anhängen):** `git status --porcelain` und `diff -rq mats-tools "${CLAUDE_PLUGIN_ROOT}"`. Cleaner Baum, aber Abweichung → das Repo hängt vermutlich hinter dem Remote (Push von anderer Maschine): `git pull --ff-only`, danach Geändertes neu lesen. Meldet der Pull „up to date", ist das Repo schlicht voraus — dann gilt die Repo-Fassung auch für Standard + Evals (statt der Cache-Fassung aus Schritt 1/3). Schlägt er fehl: melden und stoppen. Nie eine veraltete Fassung schärfen.

Merke dir, ob es ein **Command**, **Agent** oder eine **Referenzdatei** ist — die Prüfregeln unterscheiden sich.

## Schritt 3 — Ziel + Evals lesen

- Ziel-Datei lesen.
- Falls vorhanden, die zugehörigen Szenarien aus `${CLAUDE_PLUGIN_ROOT}/reference/evals.md` (bzw. per Glob `**/reference/evals.md`) lesen — sie sagen, welches Verhalten erhalten bleiben muss.

## Schritt 4 — Zweck klären, dann gegen den Standard prüfen

Erst inhaltlich, dann mechanisch. Formuliere in *einem* Satz: **Was soll dieses Ziel erreichen?** Dann prüfe zwei Richtungen:
- **Wirkt es?** Erreicht das Ziel seinen Zweck zuverlässig — oder fehlt etwas (ein Schritt, ein Beispiel, eine Klärung, ein Eval-Fall), das es wirksamer machen würde? Steht etwas unklar oder schief, das umformuliert gehört? Solche Zweck-Lücken sind echte Befunde, auch wenn nichts gegen die Checkliste verstößt.
- **Standard-Konformität:** Geh die Review-Checkliste des Standards Punkt für Punkt durch (Command- vs. Agent-Teil je nach Typ).

Erstelle eine knappe **Befund-Liste**:
- was bereits gut ist (kurz),
- Zweck-Lücken (fehlt / unklar / schief) — mit kurzer Begründung, *was* das Ziel wirksamer macht,
- Standard-Verstöße — mit Checklisten-Bezug und kurzer Begründung *warum*.

Jeder Befund braucht Wirkung: jede vorgeschlagene Änderung — Streichen, Umformulieren *oder* Ergänzen — muss das Ziel messbar besser machen. Nichts erfinden, wo Zweck **und** Standard erfüllt sind; und nichts ergänzen, was nur die Knappheit aufbläht (siehe „Knapp ist König").

## Schritt 5 — Schärfen

Setze die Befunde per `Edit` gezielt um:
- Nur die betroffenen Stellen ändern, **nicht** die ganze Datei neu schreiben.
- Sprach-Split und Format-Konventionen wahren (siehe Standard).
- Noch gültige Inhalte nicht überschreiben — je nach Befund verdichten, präzisieren oder gezielt **ergänzen/umformulieren**; nicht verwässern und nicht aufblähen.
- Die **Outcomes** der Eval-Szenarien müssen erhalten bleiben — die Implementierung dahinter darf sich verbessern. Berührt eine Verbesserung den *Wortlaut* eines Evals, passe `evals.md` explizit mit an (nie stillschweigend).

## Schritt 6 — Verifizieren

Existiert `tools/validate.sh` im Repo-Root, führe es aus (`./tools/validate.sh`). Rote Befunde, die deine Edits verursacht haben, sofort fixen und erneut laufen lassen — erst grün abschließen. Vorbestehende Rot-Befunde fremder Herkunft nicht stillschweigend mitfixen — nur melden.

## Schritt 7 — Housekeeping prüfen

Wenn sich `description`, Name oder das nach außen sichtbare Verhalten geändert haben, weise darauf hin, dass `README.md`, `marketplace.json` und `plugin.json` synchronisiert werden müssen — und biete an, das via `/finish` mitzunehmen. Diese Dateien hier **nicht** ungefragt ändern.

## Abschluss

Melde knapp:
- Welche Datei optimiert wurde + 2-3 wichtigste Änderungen (mit dem jeweiligen Standard-Bezug).
- Ein Testszenario, mit dem der User die optimierte Fassung gegenprüfen kann.
