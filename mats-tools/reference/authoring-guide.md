# Authoring-Standard für mats-tools

Der verbindliche Maßstab für Commands (`commands/*.md`) und Agents (`agents/*.md`)
in diesem Plugin. Destilliert aus Anthropics
[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
und den Repo-Konventionen aus `CLAUDE.md`, adaptiert auf das hiesige
Command/Agent-Format (kein `SKILL.md`).

Genutzt vom `/optimieren`-Command als Prüfgrundlage. Wer hier etwas ändert,
ändert den Standard für alle Commands und Agents.

## Inhalt
- Geteilte Prinzipien (Command + Agent)
- Commands (`commands/*.md`)
- Agents (`agents/*.md`)
- Repo-Konventionen
- Review-Checkliste

---

## Geteilte Prinzipien

Gelten für Commands **und** Agents.

- **Knapp ist König.** Jeder Satz teilt sich das Kontextfenster mit allem
  anderen. Nur Kontext aufnehmen, den Claude *nicht* schon hat. Bei jedem
  Absatz fragen: „Muss Claude das wirklich erklärt bekommen?" Triviales weglassen.
- **Passende Freiheitsgrade.** Anweisungstiefe an die Fragilität der Aufgabe
  koppeln:
  - *Schmaler Grat* (fragil, exakte Reihenfolge nötig) → präzise, wörtliche
    Anweisung, keine Abweichung (z.B. ein exakter Bash-Block).
  - *Offenes Feld* (mehrere Wege gültig, kontextabhängig) → Richtung geben,
    Claude den besten Weg finden lassen.
- **Konsistente Terminologie.** Ein Begriff pro Konzept, durchgängig. Nicht
  „Datei/Ziel/Pfad" mischen, wenn dasselbe gemeint ist.
- **Keine zeit-sensitiven Infos.** Nichts, was veraltet („ab August 2025…").
  Veraltetes in einen klar markierten „Alt-Muster"-Abschnitt, nicht in den
  Hauptfluss.
- **Einen Default statt vieler Optionen.** Nicht drei Wege anbieten — den besten
  vorgeben, mit knappem Escape-Hatch für den Sonderfall.
- **Konkret statt abstrakt.** Beispiele mit echten Werten schlagen abstrakte
  Beschreibungen. Bei Output-Format: ein Muster zeigen.
- **Evaluation-first.** Erst die Lücke/das Szenario benennen (siehe `evals.md`),
  dann die minimal nötige Anweisung schreiben, die es löst — nicht Anweisungen
  für eingebildete Probleme.

---

## Commands (`commands/*.md`)

Ein Command ist ein **deutsches** Prompt-Template, das der User per `/name`
auslöst. `$ARGUMENTS` wird im Body durch die User-Eingabe ersetzt.

### Frontmatter
- `description:` — **deutsch**, eine Zeile, picker-tauglich. Sagt knapp, *was*
  der Command tut.
- `allowed-tools:` — **eng gescopt**. Bash-Pattern verengen
  (`Bash(git status:*)`, `Bash(gh search commits:*)`) statt blanket `Bash`.
  Nur Tools listen, die der Command tatsächlich braucht.
- `argument-hint:` — optional; zeigt im Picker das erwartete Argument
  (z.B. `<Zeitraum, z.B. "1 Woche">`).

### Body
- **Sprache: deutsch.**
- **Token-effizient:** Status/Übersicht in *einer* kombinierten Bash-Runde
  erfassen (billige Übersicht zuerst, vollen Inhalt nur bei Bedarf nachladen).
  Vorbild: der kombinierte `echo … && …`-Block in `finish.md`.
- **Klare nummerierte Schritte** mit `## Schritt N — …`. Pro Schritt eine
  abgegrenzte Aufgabe.
- **macOS-Tooling:** `date -v` für Zeit-Offsets, `open` für Apps/Dateien,
  `/opt/homebrew/bin` im PATH wenn `gh`/`jq` gebraucht werden.
- **Fragile Schritte wörtlich vorgeben** (exakter Bash-Block zum Kopieren),
  offene Entscheidungen Claude überlassen.
- **Abschlussmeldung:** knapp halten — was getan wurde, keine langen
  Erklärungen außer bei Auffälligkeiten.

---

## Agents (`agents/*.md`)

Ein Agent ist ein Subagent mit eigenem Kontextfenster, den Claude proaktiv oder
auf Anfrage startet.

### Frontmatter
- `name:` — lowercase, nur Buchstaben/Zahlen/Bindestriche, max. 64 Zeichen.
  Nicht „claude"/„anthropic". Gerund-Form bevorzugt (`processing-pdfs`), klare
  Nomen-Phrasen okay. Keine vagen Namen (`helper`, `tools`).
- `description:` — in **3. Person** geschrieben („Converts PDFs…", nicht „I
  can…"/„You can…"); inkonsistente Perspektive stört das Triggern. Enthält
  *was* der Agent tut **und wann** er genutzt werden soll, mit konkreten
  Stichworten. Eingebettete `<example>`-Blöcke (User-Anfrage +
  `<commentary>`) steuern das proaktive Triggern — Vorbild: `pdf-to-markdown.md`.
- `model:`, `color:` — setzen.

### Body
- **Instruktionen auf englisch**, **Output-Templates auf deutsch**
  (`## Aufgabe`, `**Gegeben:**`, `**Lösung:**`) — die erzeugten Dateien sind
  deutsches Studienmaterial.
- **Progressive disclosure:** Body schlank halten (Richtwert < 500 Zeilen).
  Details in separate Referenzdateien, die *eine Ebene tief* von hier verlinkt
  sind (keine Referenz-auf-Referenz-Ketten).
- **Inhaltsverzeichnis** bei Referenzdateien > 100 Zeilen.
- **Workflows/Checklisten** für komplexe Mehrschritt-Aufgaben, damit kein
  kritischer Schritt übersprungen wird.

---

## Repo-Konventionen

(Aus `CLAUDE.md` — beim Optimieren mitprüfen.)

- **Sprach-Split:** Command-Body + *alle* `description`-Felder deutsch.
  Agent-Instruktionen englisch, Agent-Output-Templates deutsch.
- **Keine `version` in `plugin.json`** — der Git-SHA ist die Version. Nicht
  hinzufügen, außer der User will gepinnte Releases.
- **Auto-Discovery:** Commands/Agents werden über die Verzeichnisse gefunden,
  nicht im Manifest gelistet. Trotzdem bei neuem/geändertem Command/Agent die
  menschenlesbaren Listen synchron halten: `README.md`, `marketplace.json`,
  `plugin.json` (description/keywords).
- **Plugin-interne Datei-Referenzen:** über `${CLAUDE_PLUGIN_ROOT}/…`. Keine
  Pfade aus dem Plugin heraus (`../…`) — die werden im installierten Zustand
  nicht mitkopiert.

---

## Review-Checkliste

Beim Optimieren eines Commands/Agents abhaken:

**Frontmatter**
- [ ] `description` spezifisch — sagt *was* (Agent zusätzlich: *wann*).
- [ ] Agent-`description` in 3. Person, mit `<example>`-Blöcken.
- [ ] `allowed-tools` eng gescopt (verengte Bash-Pattern, nur Nötiges).
- [ ] `argument-hint` vorhanden, falls der Command Argumente nutzt.

**Body**
- [ ] Knapp — kein Token ohne Mehrwert, nichts was Claude schon weiß.
- [ ] Konsistente Begriffe, keine zeit-sensitiven Infos.
- [ ] Token-effizient: Übersicht zuerst, voller Inhalt nur bei Bedarf
      (Commands: kombinierte Bash-Runde).
- [ ] Freiheitsgrade passend (fragil → exakt, offen → Richtung).
- [ ] Ein Default statt vieler Optionen; konkrete Beispiele.
- [ ] Klare Schritte/Checkliste bei komplexen Workflows.

**Konventionen**
- [ ] Sprach-Split eingehalten.
- [ ] Agent: Referenzen max. eine Ebene tief; Body < ~500 Zeilen.
- [ ] Listing-Dateien synchron, falls description/Name/Verhalten sich ändert.
