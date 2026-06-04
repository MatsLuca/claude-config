---
description: Optimiert einen Command oder Agent nach dem Authoring-Standard — prüft Frontmatter, Klarheit und Token-Effizienz und schärft die Definition.
allowed-tools: Read, Edit, Glob
---

Du optimierst einen Command oder Agent dieses Plugins gegen den Authoring-Standard. Ziel: klarer, eindeutiger, token-effizienter — ohne gültige Inhalte zu verlieren.

Zu optimierendes Ziel: **$ARGUMENTS**

**Token-effizient bündeln:** Unabhängige Reads parallel — Standard (Schritt 1) und Ziel-Glob (Schritt 2) zusammen, dann Ziel-Datei + Evals (Schritt 3) zusammen. Vollen Inhalt nur bei Bedarf.

## Schritt 1 — Standard laden

Lies den Authoring-Standard: `${CLAUDE_PLUGIN_ROOT}/reference/authoring-guide.md`.

Falls die Variable nicht aufgelöst wird (Datei nicht gefunden), suche sie per `Glob`: `**/reference/authoring-guide.md`. Ohne den Standard nicht weitermachen — er ist die Prüfgrundlage.

## Schritt 2 — Ziel bestimmen

`$ARGUMENTS` ist ein Name oder Pfad. Löse ihn zur Datei auf:
- Per `Glob` in `commands/*.md` **und** `agents/*.md` suchen (Name ohne `/` und ohne `.md`).
- **Genau ein Treffer** → diese Datei. **Mehrere/keine** → kurz beim User rückfragen statt zu raten.
- Ist `$ARGUMENTS` leer → frage, welcher Command/Agent optimiert werden soll.

Merke dir, ob es ein **Command** oder **Agent** ist — die Standard-Regeln unterscheiden sich.

## Schritt 3 — Ziel + Evals lesen

- Ziel-Datei lesen.
- Falls vorhanden, die zugehörigen Szenarien aus `${CLAUDE_PLUGIN_ROOT}/reference/evals.md` (bzw. per Glob `**/reference/evals.md`) lesen — sie sagen, welches Verhalten erhalten bleiben muss.

## Schritt 4 — Gegen den Standard prüfen

Geh die Review-Checkliste des Standards Punkt für Punkt durch (Command- vs. Agent-Teil je nach Typ). Erstelle eine knappe **Befund-Liste**:
- was bereits gut ist (kurz),
- was gegen welchen Checklisten-Punkt verstößt — jeweils mit kurzer Begründung *warum*.

Keine Verbesserung erfinden, wo der Standard erfüllt ist.

## Schritt 5 — Schärfen

Setze die Befunde per `Edit` gezielt um:
- Nur die betroffenen Stellen ändern, **nicht** die ganze Datei neu schreiben.
- Sprach-Split und Format-Konventionen wahren (siehe Standard).
- Noch gültige Inhalte nicht überschreiben — verdichten/präzisieren, nicht verwässern.
- Verhalten aus den Eval-Szenarien muss erhalten bleiben.

## Schritt 6 — Housekeeping prüfen

Wenn sich `description`, Name oder das nach außen sichtbare Verhalten geändert haben, weise darauf hin, dass `README.md`, `marketplace.json` und `plugin.json` synchronisiert werden müssen — und biete an, das via `/finish` mitzunehmen. Diese Dateien hier **nicht** ungefragt ändern.

## Abschluss

Melde knapp:
- Welche Datei optimiert wurde + 2-3 wichtigste Änderungen (mit dem jeweiligen Standard-Bezug).
- Ein Testszenario, mit dem der User die optimierte Fassung gegenprüfen kann.
