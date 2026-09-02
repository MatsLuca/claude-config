# Authoring-Standard für mats-tools

Der verbindliche Maßstab für Commands (`commands/*.md`), Agents (`agents/*.md`)
und Skills (`skills/<name>/SKILL.md`) in diesem Plugin. Destilliert aus Anthropics
[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
und den Repo-Konventionen aus `CLAUDE.md`.

Genutzt vom `/optimieren`-Command als Prüfgrundlage — für das Plugin *und* für die
Werkstatt (privates Repo `claude-werkstatt` für alles mit Konten oder Maschinenzustand).
Wer hier etwas ändert, ändert den Standard für alle Commands, Agents und Skills. Der Zweck, dem alles dient: *ein Werkzeugkasten für die Arbeit mit Claude, der
sich durch die Arbeit mit ihm selbst schärft.*

## Inhalt
- Geteilte Prinzipien
- Commands (`commands/*.md`)
- Agents (`agents/*.md`)
- Skills (`skills/<name>/SKILL.md`) — inkl. der Entscheidung Command vs. Skill
- Repo-Konventionen
- Meta-Pflege des Standards
- Review-Checkliste

---

## Geteilte Prinzipien

Gelten für Commands, Agents **und** Skills.

- **Knapp ist König.** Jeder Satz teilt sich das Kontextfenster mit allem
  anderen. Nur Kontext aufnehmen, den Claude *nicht* schon hat. Der Test pro
  Satz: *Ändert er das Verhalten gegenüber dem Default?* Wenn nein, ist er ein
  No-op — raus damit, auch wenn er „richtig" klingt. Triviales weglassen.
- **Eine Quelle pro Bedeutung.** Jede Aussage lebt an *einer* autoritativen
  Stelle; anderswo nur darauf verweisen, nicht neu formulieren. Dieselbe
  Botschaft mehrfach ausbuchstabiert kostet Tokens und Pflege und bläht ihre
  Wichtigkeit über ihren echten Rang.
- **Leitwörter statt Umschreibungen.** Wo ein im Pretraining verankertes Wort
  ein ganzes Verhalten trägt (`tight`, „grün/rot", „Frische-Check"), es als
  *einen* Token setzen und wiederholen, statt die Idee mehrfach zu umschreiben —
  das ankert Verhalten in wenigsten Tokens und schärft zugleich das Triggern,
  wenn dasselbe Wort in Prompts und Code lebt. Drei Qualitäten nebeneinander
  („klar, eindeutig, token-effizient") sind ein Kandidat zum Kollabieren.
- **Auftrag vor Rezept.** Ein Baustein sagt zuerst, *was* am Ende gelten muss
  (das Outcome, wie in `evals.md`) und welche Regeln dabei unverletzlich sind
  (kein `--force`, Commit nur anbieten, Verlauf nach `HISTORIE.md`). *Wie* das
  Modell dorthin kommt, entscheidet es selbst. Ein wörtlicher Schritt oder
  Bash-Block steht nur dort, wo ein Eval-Lauf zeigt, dass das Modell ohne ihn
  scheitert — und trägt dann den Grund als Kommentar, damit der nächste Pass ihn
  erneut prüft. Die Beweislast liegt beim Rezept, nicht bei der Freiheit.
- **Passende Freiheitsgrade.** *Schmaler Grat* (eine Abweichung kostet Daten:
  Rebase, Push, Löschen) → die **Regel** wörtlich, der Weg frei. *Offenes Feld*
  (mehrere Wege gültig) → Richtung geben, Claude den besten Weg finden lassen.
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
- **Evals beschreiben Outcomes, nicht Implementierung.** Szenarien in `evals.md`
  fixieren *beobachtbares Verhalten*, nie interne Marker, Flags oder konkrete
  Tool-Aufrufe. Sonst konserviert jeder Optimierungs-Pass die heutige
  Implementierung und blockiert bessere — das Gegenteil des Zwecks.
- **Heutige Krücken nicht als Dogma gießen.** Workarounds für aktuelle
  Modell-/Tool-Limitierungen (exakt vorgegebene Blöcke, harte Reihenfolgen) als
  das kennzeichnen, was sie sind — bei jedem Modellwechsel und jedem
  Optimier-Pass prüfen, ob die Limitierung noch existiert, statt die Krücke zu
  verewigen. Ein Eval-Lauf vorher/nachher ist der Beleg.

---

## Commands (`commands/*.md`)

Ein Command ist ein **deutsches** Prompt-Template, das der User per `/name`
auslöst — technisch ein Skill als flache Datei (siehe „Command oder Skill?").
`$ARGUMENTS` wird im Body durch die User-Eingabe ersetzt.

### Frontmatter
- `description:` — **deutsch**, eine Zeile, picker-tauglich. Sagt knapp, *was*
  der Command tut; Synonyme, die dasselbe zweimal sagen, kollabieren, und keine
  Identität, die im Body ohnehin steht.
- `allowed-tools:` — **eng gescopt**. Bash-Pattern verengen
  (`Bash(git status:*)`, `Bash(gh search commits:*)`) statt blanket `Bash`.
  Nur Tools listen, die der Command tatsächlich braucht.
- `argument-hint:` — optional; zeigt im Picker das erwartete Argument
  (z.B. `<Zeitraum, z.B. "1 Woche">`).
- `disable-model-invocation: true` — Pflicht, wo der Command Fremdsysteme
  anfasst oder Inhalte bewegt (Push, Versand, Browser): ohne das Flag startet
  Claude jeden Command auch selbst über das Skill-Tool. Bewusst offen lassen,
  wo das gewollt ist (`/merken` auf Zuruf).

### Body
- **Sprache: deutsch.**
- **Aufbau:** Zweck in einem Absatz, dann die unverletzlichen Regeln, dann was
  am Ende gemeldet wird. Nummerierte Schritte nur, wo die Reihenfolge selbst
  eine Regel ist (erst Drift, dann Struktur) — dann endet jeder Schritt auf
  einem *prüfbaren* Fertig-Kriterium (binär beobachtbar, Vorbild: „erst
  **grün** abschließen" in `optimieren.md`), sonst wird er vorzeitig abgehakt.
- **Token-effizient:** wenige Werkzeug-Runden, unabhängige Aufrufe parallel,
  Übersicht vor Vollinhalt. Kein Pflicht-Einzeiler „genau so ausführen":
  zusammengesetzte Befehle mit `&&`/`$(…)` scheitern an eng gescopten
  `allowed-tools`, und das Modell zerlegt sie ohnehin selbst.
- **Portabel (macOS + Linux):** Commands laufen auch in Containern/Codespaces.
  Bei BSD↔GNU-Dialekten (`date`, `stat`, `sed -i`) das **Probe-dann-Variante**-Muster
  nutzen: einmal billig die GNU-Variante testen, dann konsequent eine der beiden
  fahren (Vorbild: `mtime()` in `statusline-command.sh`). Kein `BSD || GNU` ohne Probe — manche Tools verschmutzen
  stdout, bevor sie fehlschlagen. `/opt/homebrew/bin` im PATH zu ergänzen ist
  okay (auf Linux wirkungslos). Rein macOS-gebundene Commands (z.B. `/xcode`
  mit `open`) sind die markierte Ausnahme.
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
  Stichworten; „use proactively“, wo der Agent von selbst anspringen soll.
  **Knapp:** die description liegt in jeder Session im Kontext, der Body nur
  beim Lauf — Details gehören in den Body. `<example>`-Blöcke sind in der
  Claude-Code-Doku nicht mehr beschrieben; nur nachrüsten, wenn das Triggern
  nachweislich versagt. Vorbild: `machine-setup.md`.
- `model:`, `color:` — setzen. `tools:` — Namensliste (kein `Bash(…)`-Muster),
  nur was der Body braucht. Ein Subagent kann den Nutzer nicht fragen —
  Entscheidungen gehen als Frage im Bericht an die Hauptsession.

### Body
- **Instruktionen auf englisch**, **Output-Templates auf deutsch**
  (`## Aufgabe`, `**Gegeben:**`) — Berichte gehen an deutsche Nutzer.
- **Progressive disclosure:** Body schlank halten (Richtwert < 500 Zeilen).
  Details in separate Referenzdateien, die *eine Ebene tief* von hier verlinkt
  sind (keine Referenz-auf-Referenz-Ketten).
- **Inhaltsverzeichnis** bei Referenzdateien > 100 Zeilen.
- **Workflows/Checklisten** für komplexe Mehrschritt-Aufgaben, damit kein
  kritischer Schritt übersprungen wird.

---

## Skills (`skills/<name>/SKILL.md`)

Ein Skill ist ein Prompt-Paket, das Claude **selbst lädt**, sobald die
`description` zur Situation passt — und das der User zusätzlich per `/name`
aufrufen kann. Companion-Dateien (Verfassung, Skripte) liegen im selben Ordner.

### Entscheidung: Command oder Skill?
Technisch **ein** Mechanismus: `commands/<name>.md` ist ein Skill als flache
Datei, Claude Code listet beide gleich und ruft beide über das Skill-Tool auf
(`claude plugin details` zählt sie zusammen). Die Trennung im Repo ist nur noch
Ablage, die Regel dafür:
- **Command**, wenn der Ablauf ein Verb ist, das Mats tippt (`/finish`,
  `/merken`). Ob Claude ihn *auch* selbst starten darf, entscheidet allein
  `disable-model-invocation` — nicht der Ordner. Bestehende Commands bleiben
  Commands; kein Umzug um der Einheitlichkeit willen.
- **Skill** (`skills/<name>/SKILL.md`), wenn Companion-Dateien dazugehören oder
  Claude den Inhalt *von sich aus* laden soll, weil eine Situation ihn braucht
  (`claude-md` beim Anlegen einer CLAUDE.md, `latexterm` bei Terminal-Fragen) —
  die `description` trägt dann das Triggern. Neue Bausteine mit Dateien daneben
  werden Skills.

### Frontmatter
- `name:` — gleich dem Ordnernamen (der Validator prüft das).
- `description:` — **deutsch**, 3. Person, trägt das **Triggern**: *was* der
  Skill tut **und wann** er zu laden ist, mit den Wörtern, die in echten
  Anfragen vorkommen („Kachel", „Pane", „leg eine CLAUDE.md an"), plus der
  Abgrenzung, wann *nicht* (sonst lädt er bei jedem Streifen des Themas).
  Vorbild: `claude-md/SKILL.md`.

### Body
- **Sprache: deutsch** (wie Commands — der Body ist Mats' Arbeitsanweisung).
- **Anwendbarkeit zuerst klären**, wenn der Skill an eine Umgebung gebunden ist
  (`$LATEXTERM_PANE_ID`): fehlt sie, normal weiterarbeiten, nichts simulieren.
- **Betriebsarten benennen**, wenn der Skill sowohl per `/name` als auch
  proaktiv läuft (Wartungsgang mit Bericht vs. stiller Teil der laufenden
  Aufgabe) — sonst erzeugt der proaktive Fall ungewollte Berichte.
- **Companion-Dateien** über `${CLAUDE_PLUGIN_ROOT}/skills/<name>/…` referenzieren,
  eine Ebene tief; Skripte unter `scripts/` laufen portabel (Probe-dann-Variante).
- Sonst gelten die Command-Regeln (Schritte mit Fertig-Kriterium, kombinierte
  Bash-Runde, knappe Abschlussmeldung).

---

## Repo-Konventionen

(Aus `CLAUDE.md` — beim Optimieren mitprüfen.)

- **Sprach-Split:** Command-Body + *alle* `description`-Felder deutsch.
  Agent-Instruktionen englisch, Agent-Output-Templates deutsch.
- **Keine `version` in `plugin.json`** — der Git-SHA ist die Version. Nicht
  hinzufügen, außer der User will gepinnte Releases.
- **Auto-Discovery:** Commands/Agents/Skills werden über die Verzeichnisse
  gefunden, nicht im Manifest gelistet. Bei neuem/geändertem Ziel: Zeile in
  `README.md` (die einzige Liste; Manifest-Descriptions sind statisch) **und**
  einen Abschnitt in `evals.md` (der Validator verlangt beides; ohne Evals ist
  ein Ziel vom Optimier-Loop abgekoppelt).
- **Werkstatt → Plugin:** Was Mats' Konten oder Maschinenzustand braucht, lebt
  im Werkstatt-Repo; hierher gehört, was ohne beides läuft, portabel ist und
  auch anderen nützt — Code ist erlaubt (`inventar.sh`).
  Ein Werkstatt-Baustein folgt demselben Standard und hat seine Evals in
  `<werkstatt>/evals.md`.
- **Plugin-interne Datei-Referenzen:** über `${CLAUDE_PLUGIN_ROOT}/…`. Keine
  Pfade aus dem Plugin heraus (`../…`) — die werden im installierten Zustand
  nicht mitkopiert.
- **Mechanische Verifikation:** `tools/validate.sh` (läuft auch in CI) prüft
  Manifeste, Frontmatter, Listing-Sync, Plugin-Referenzen, Portabilitäts-Lint,
  lässt `shell/setup.sh` im Sandbox-HOME laufen und ruft, wo `claude` installiert
  ist, `claude plugin validate` dazu (ohne `--strict`: die fehlende Version ist
  gewollt). Nach jeder Änderung ausführen — grün ist die Mindestbedingung.
  `claude plugin details mats-tools` zeigt die Token-Grundlast je Baustein —
  der Messwert zu „Knapp ist König". **Verhaltens-Evals** laufen mit
  `tools/eval.sh` (headless, echte Tokens, nicht in CI): benannte Szenarien mit
  Fixture + Prüfung auf der Platte, oder freier Lauf mit Transkript neben dem
  Eval-Abschnitt.

---

## Meta-Pflege des Standards

Dieser Guide und `evals.md` sind selbst optimierbare Ziele (`/optimieren
authoring-guide`, `/optimieren evals`) — sie sind von der Schleife, die sie
definieren, nicht ausgenommen. Beim Meta-Pass gilt:

- **Prüfgrundlage ist nicht der Standard selbst** (Zirkelschluss), sondern:
  erfüllt er seinen Zweck — und ist er noch deckungsgleich mit den aktuellen
  [Upstream-Best-Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
  und den Fähigkeiten der Plattform (Skills, Hooks, neue Frontmatter-Felder)?
  Der Guide ist ein Destillat mit Verfallsdatum, keine Verfassung.
- **Format-Annahmen hinterfragen:** Wandert Claude Code zu einem neuen
  Mechanismus, gehört das als Befund auf den Tisch — nicht stillschweigend
  wegadaptiert (so geschehen mit der Verschmelzung von Commands und Skills,
  siehe „Command oder Skill?").
- Änderungen hier ändern den Standard für alle Commands und Agents — Plan
  zeigen, dann umsetzen.

---

## Review-Checkliste

Beim Optimieren eines Commands/Agents/Skills abhaken:

**Frontmatter**
- [ ] `description` spezifisch — sagt *was* (Agent und Skill zusätzlich: *wann*;
      Skill auch: wann *nicht*).
- [ ] Agent-`description` in 3. Person, knapp (Details in den Body); `tools:` gesetzt.
- [ ] Skill: Command-oder-Skill-Entscheidung hält (Trigger ist die Situation,
      nicht ein Tipp-Befehl); Anwendbarkeit wird im Body zuerst geklärt.
- [ ] `allowed-tools` eng gescopt (verengte Bash-Pattern, nur Nötiges) — und
      passend zu den *einzelnen* Befehlen, die der Body nahelegt.
- [ ] `argument-hint` vorhanden, falls der Command Argumente nutzt.
- [ ] `disable-model-invocation` gesetzt, wo der Command Fremdsysteme anfasst
      oder Inhalte bewegt; bewusst offen, wo Claude ihn selbst starten soll.

**Body**
- [ ] Knapp — kein Token ohne Mehrwert; No-op-Test bestanden (ändert der Satz
      das Verhalten ggü. dem Default?).
- [ ] Konsistente Begriffe; jede Bedeutung nur an einer Quelle (keine
      Duplikation). Keine zeit-sensitiven Infos.
- [ ] Leitwörter genutzt, wo ein Wort ein Verhalten trägt (statt es zu umschreiben).
- [ ] Token-effizient: Übersicht zuerst, voller Inhalt nur bei Bedarf; wenige
      Runden, parallel — kein Pflicht-Einzeiler.
- [ ] Auftrag vor Rezept: Outcome + Regeln zuerst; wörtliche Blöcke nur mit
      Eval-Beleg (Kommentar nennt den Grund); Schritte nur, wo die Reihenfolge
      selbst eine Regel ist, dann mit prüfbarem Fertig-Kriterium.
- [ ] Ein Default statt vieler Optionen; konkrete Beispiele.

**Konventionen**
- [ ] Sprach-Split eingehalten.
- [ ] Portabel (macOS + Linux): keine BSD-only Aufrufe ohne Probe/Fallback —
      außer der Command ist inhärent macOS-gebunden.
- [ ] Agent: Referenzen max. eine Ebene tief; Body < ~500 Zeilen.
- [ ] Listing-Dateien synchron, falls description/Name/Verhalten sich ändert.
- [ ] Evals outcome-formuliert; bei geänderter Implementierung Eval-Wortlaut
      mit angepasst (nicht stillschweigend).
- [ ] `tools/validate.sh` grün.
