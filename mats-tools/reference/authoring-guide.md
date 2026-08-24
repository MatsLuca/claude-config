# Authoring-Standard für mats-tools

Der verbindliche Maßstab für Commands (`commands/*.md`), Agents (`agents/*.md`)
und Skills (`skills/<name>/SKILL.md`) in diesem Plugin. Destilliert aus Anthropics
[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
und den Repo-Konventionen aus `CLAUDE.md`.

Genutzt vom `/optimieren`-Command als Prüfgrundlage — für das Plugin *und* für die
Skill-Werkstatt (privates Repo `claude-werkstatt`, aus der reife Skills hierher
graduieren). Wer hier etwas ändert, ändert den Standard für alle Commands, Agents und
Skills. Der Zweck, dem alles dient: *ein Werkzeugkasten für die Arbeit mit Claude, der
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
- **Evals beschreiben Outcomes, nicht Implementierung.** Szenarien in `evals.md`
  fixieren *beobachtbares Verhalten*, nie interne Marker, Flags oder konkrete
  Tool-Aufrufe. Sonst konserviert jeder Optimierungs-Pass die heutige
  Implementierung und blockiert bessere — das Gegenteil des Zwecks.
- **Heutige Krücken nicht als Dogma gießen.** Workarounds für aktuelle
  Modell-/Tool-Limitierungen (exakt vorgegebene Blöcke, harte Reihenfolgen) als
  das kennzeichnen, was sie sind — beim Optimieren prüfen, ob die Limitierung
  noch existiert, statt die Krücke zu verewigen.

---

## Commands (`commands/*.md`)

Ein Command ist ein **deutsches** Prompt-Template, das der User per `/name`
auslöst. `$ARGUMENTS` wird im Body durch die User-Eingabe ersetzt.

### Frontmatter
- `description:` — **deutsch**, eine Zeile, picker-tauglich. Sagt knapp, *was*
  der Command tut; Synonyme, die dasselbe zweimal sagen, kollabieren, und keine
  Identität, die im Body ohnehin steht.
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
  abgegrenzte Aufgabe, die auf einem *prüfbaren* Fertig-Kriterium endet (binär
  beobachtbar, nicht „fühlt sich fertig an" — Vorbild: „erst **grün**
  abschließen" in `optimieren.md`). Ein unscharfes Kriterium lädt dazu ein, den
  Schritt vorzeitig abzuhaken, bevor die eigentliche Arbeit getan ist.
- **Portabel (macOS + Linux):** Commands laufen auch in Containern/Codespaces.
  Bei BSD↔GNU-Dialekten (`date`, `stat`, `sed -i`) das **Probe-dann-Variante**-Muster
  nutzen: einmal billig die GNU-Variante testen, dann konsequent eine der beiden
  fahren (Vorbild: `mtime()` in `statusline-command.sh`, Schritt 1 in
  `destillieren.md`). Kein `BSD || GNU` ohne Probe — manche Tools verschmutzen
  stdout, bevor sie fehlschlagen. `/opt/homebrew/bin` im PATH zu ergänzen ist
  okay (auf Linux wirkungslos). Rein macOS-gebundene Commands (z.B. `/xcode`
  mit `open`) sind die markierte Ausnahme.
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

## Skills (`skills/<name>/SKILL.md`)

Ein Skill ist ein Prompt-Paket, das Claude **selbst lädt**, sobald die
`description` zur Situation passt — und das der User zusätzlich per `/name`
aufrufen kann. Companion-Dateien (Verfassung, Skripte) liegen im selben Ordner.

### Entscheidung: Command oder Skill?
Die Trennung im Repo ist historisch gewachsen (Commands zuerst, Skills seit
2026-07). Die Regel, damit das nächste Feature nicht zufällig entscheidet:
- **Command**, wenn nur der User den Ablauf auslöst (`/finish`, `/merken`) —
  ein Verb, das Mats tippt. Bestehende Commands bleiben Commands; kein Umzug um
  der Einheitlichkeit willen.
- **Skill**, wenn Claude den Inhalt *von sich aus* brauchen soll, weil er in
  anderer Arbeit relevant wird (`claude-md` beim Anlegen einer CLAUDE.md,
  `latexterm` bei Terminal-Fragen) — der Trigger ist die Situation, nicht ein
  Tipp-Befehl.
- Wandert die Plattform weiter (Commands als Skill-Sonderfall), ist das ein
  Befund für die Meta-Pflege — nicht stillschweigend migrieren.

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
- **Werkstatt → Plugin:** Skills mit Code, Konten oder Maschinenzustand leben im
  Werkstatt-Repo; hierher graduiert nur, was markdown-rein ist und auch anderen
  nützt. Ein Werkstatt-Skill folgt demselben Standard und hat seine Evals in
  `<werkstatt>/evals.md`.
- **Plugin-interne Datei-Referenzen:** über `${CLAUDE_PLUGIN_ROOT}/…`. Keine
  Pfade aus dem Plugin heraus (`../…`) — die werden im installierten Zustand
  nicht mitkopiert.
- **Mechanische Verifikation:** `tools/validate.sh` (läuft auch in CI) prüft
  Manifeste, Frontmatter, Listing-Sync, Plugin-Referenzen, Portabilitäts-Lint
  und lässt `shell/setup.sh` im Sandbox-HOME laufen. Nach jeder Änderung
  ausführen — grün ist die Mindestbedingung. **Verhaltens-Evals** laufen mit
  `tools/eval.sh` (headless, echte Tokens, nicht in CI): benannte Szenarien mit
  Fixture + Prüfung, oder freier Lauf mit Transkript neben dem Eval-Abschnitt.

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
  Mechanismus (z.B. Skills statt Commands), gehört das als Befund auf den
  Tisch — nicht stillschweigend wegadaptiert.
- Änderungen hier ändern den Standard für alle Commands und Agents — Plan
  zeigen, dann umsetzen.

---

## Review-Checkliste

Beim Optimieren eines Commands/Agents/Skills abhaken:

**Frontmatter**
- [ ] `description` spezifisch — sagt *was* (Agent und Skill zusätzlich: *wann*;
      Skill auch: wann *nicht*).
- [ ] Agent-`description` in 3. Person, mit `<example>`-Blöcken.
- [ ] Skill: Command-oder-Skill-Entscheidung hält (Trigger ist die Situation,
      nicht ein Tipp-Befehl); Anwendbarkeit wird im Body zuerst geklärt.
- [ ] `allowed-tools` eng gescopt (verengte Bash-Pattern, nur Nötiges).
- [ ] `argument-hint` vorhanden, falls der Command Argumente nutzt.

**Body**
- [ ] Knapp — kein Token ohne Mehrwert; No-op-Test bestanden (ändert der Satz
      das Verhalten ggü. dem Default?).
- [ ] Konsistente Begriffe; jede Bedeutung nur an einer Quelle (keine
      Duplikation). Keine zeit-sensitiven Infos.
- [ ] Leitwörter genutzt, wo ein Wort ein Verhalten trägt (statt es zu umschreiben).
- [ ] Token-effizient: Übersicht zuerst, voller Inhalt nur bei Bedarf
      (Commands: kombinierte Bash-Runde).
- [ ] Freiheitsgrade passend (fragil → exakt, offen → Richtung).
- [ ] Ein Default statt vieler Optionen; konkrete Beispiele.
- [ ] Klare Schritte mit prüfbarem Fertig-Kriterium bei komplexen Workflows.

**Konventionen**
- [ ] Sprach-Split eingehalten.
- [ ] Portabel (macOS + Linux): keine BSD-only Aufrufe ohne Probe/Fallback —
      außer der Command ist inhärent macOS-gebunden.
- [ ] Agent: Referenzen max. eine Ebene tief; Body < ~500 Zeilen.
- [ ] Listing-Dateien synchron, falls description/Name/Verhalten sich ändert.
- [ ] Evals outcome-formuliert; bei geänderter Implementierung Eval-Wortlaut
      mit angepasst (nicht stillschweigend).
- [ ] `tools/validate.sh` grün.
