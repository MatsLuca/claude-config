---
description: Optimiert einen Command oder Agent nach dem Authoring-Standard — prüft Frontmatter, Klarheit und Token-Effizienz und schärft die Definition.
argument-hint: <command- oder agent-name, z.B. "finish" oder "pdf-to-markdown">
allowed-tools: Read, Edit, Glob, Bash(ls:*)
---

Du optimierst einen Command oder Agent dieses Plugins gegen den Authoring-Standard. Ziel: das Ziel soll seinen **Zweck besser erfüllen** — klarer, eindeutiger, token-effizienter. Das heißt oft verdichten, manchmal aber auch **ergänzen oder umformulieren**, wo etwas fehlt oder schief steht. Optimieren ist nicht gleich Kürzen: gültige Inhalte bleiben, und ein zu knapp oder unklar formuliertes Ziel wird durch Addition besser, nicht durch weiteres Streichen.

Zu optimierendes Ziel: **$ARGUMENTS**

**Token-effizient bündeln:** Unabhängige Reads parallel — Standard (Schritt 1) und Ziel-Glob (Schritt 2) zusammen, dann Ziel-Datei + Evals (Schritt 3) zusammen. Vollen Inhalt nur bei Bedarf.

## Schritt 1 — Standard laden

Lies den Authoring-Standard: `${CLAUDE_PLUGIN_ROOT}/reference/authoring-guide.md`.

Falls die Variable nicht aufgelöst wird (Datei nicht gefunden), suche sie per `Glob`: `**/reference/authoring-guide.md`. Ohne den Standard nicht weitermachen — er ist die Prüfgrundlage.

## Schritt 2 — Ziel bestimmen

`$ARGUMENTS` ist ein Name oder Pfad. Löse ihn zur Datei auf:
- Billige Übersicht in *einer* Bash-Runde: `ls mats-tools/commands mats-tools/agents` — listet alle Kandidaten auf einmal. Den Namen (ohne `/` und `.md`) dagegen matchen. Greift `ls` nicht (anderes Arbeitsverzeichnis), per `Glob` `**/commands/*.md` und `**/agents/*.md` nachladen.
- **Genau ein Treffer** → diese Datei. **Mehrere/keine** → kurz beim User rückfragen statt zu raten.
- Ist `$ARGUMENTS` leer → frage, welcher Command/Agent optimiert werden soll.

Merke dir, ob es ein **Command** oder **Agent** ist — die Standard-Regeln unterscheiden sich.

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
- Verhalten aus den Eval-Szenarien muss erhalten bleiben.

## Schritt 6 — Housekeeping prüfen

Wenn sich `description`, Name oder das nach außen sichtbare Verhalten geändert haben, weise darauf hin, dass `README.md`, `marketplace.json` und `plugin.json` synchronisiert werden müssen — und biete an, das via `/finish` mitzunehmen. Diese Dateien hier **nicht** ungefragt ändern.

## Abschluss

Melde knapp:
- Welche Datei optimiert wurde + 2-3 wichtigste Änderungen (mit dem jeweiligen Standard-Bezug).
- Ein Testszenario, mit dem der User die optimierte Fassung gegenprüfen kann.
