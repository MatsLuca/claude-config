# Eval-Szenarien für mats-tools

Leichtgewichtige Prüf-Checkliste: pro Command/Agent ein paar repräsentative
Szenarien + erwartetes Verhalten.

**Grundprinzip — Outcomes, nicht Implementierung.** Szenarien beschreiben
*beobachtbares Verhalten* (was der User sieht und was auf der Platte passiert),
nie interne Marker, Flags oder konkrete Tool-Aufrufe. Ein Eval darf eine bessere
Neuimplementierung niemals blockieren: Ändert sich das *Wie*, bleibt der Eval
gültig; ändert sich das *Was*, wird der Eval bewusst mitgeändert — nie stillschweigend.

**Schreibweise (nativ-kompatibel):** *Szenario* = Ausgangslage + Aufruf, so konkret,
dass daraus später ein Prompt mit Fixture wird; *Erwartet* = ein Kriterium, das ein Richter
am Transkript oder an erzeugten Dateien prüfen kann. Was nur der Arbeitsbaum zeigt (Commit
da, gepusht, Baum sauber), prüft `tools/eval.sh` auf der Platte. Claude Codes natives
`claude plugin eval` (seit 15.09.2026 frei; Fälle unter `mats-tools/evals/<fall>/`: `case.yaml` mit
`scaffold.sh`, `prompt.md`, `graders/*.md`) ergänzt den Vergleichslauf ohne Plugin, Regex-/Datei-Grader
und einen LLM-Richter — es ersetzt den Runner nicht (kein Platten-Check auf Git-Zustand).

```bash
claude plugin eval ./mats-tools --scaffold --allow-tools Bash Edit Write --trust-plugin --no-publish   # aus der Repo-Wurzel
```

**Wann:** `tools/eval.sh` bei jedem `/optimieren`-Pass (vorher/nachher, Platte, billig). Das native Eval bei
`/neudenken` über den Kasten — neues Modell oder Inventur — mit `--runs 3 --judge-model opus`: es beantwortet
die Existenzfrage (schlägt der Baustein nacktes Claude?), nicht die Edit-Frage. Fixtures gibt es nur einmal:
`evals/<fall>/scaffold.sh` speist beide Prüfwege.

Grenzen (Stand 15.09.2026): Fälle mit `disable-model-invocation` (finish, finish-lite) brauchen den
Slash-Aufruf als erste Prompt-Zeile — der Arm „ohne Plugin" bricht dann mit „Unknown command" ab, der
Vergleich gegen nacktes Claude geht nur über eine Kopie des Prompts ohne Slash-Zeile. Der Slash-Aufruf
zählt nicht als Skill-Tool-Aufruf (`tool_used: Skill` greift nur bei modellgewählten Skills wie merken).
`--keep-temp` bewahrt die Transkripte (`tracePath` im `--json`); die `xcrun_db`-Fehler im Sandbox-Git
sind Rauschen.

**Loop:** Szenario ausführen → Verhalten beobachten → Abweichung als Befund in
`/optimieren <ziel>` einspeisen → schärfen → erneut prüfen. `/optimieren` liest
diese Datei und muss die hier beschriebenen Outcomes erhalten.

**Ausführen:** Strukturelles prüft `tools/validate.sh` automatisch (lokal + CI).
Verhaltens-Szenarien laufen am echten Command — `tools/eval.sh` startet ihn headless
aus der Repo-Quelle in einem Wegwerf-Fixture:

```bash
tools/eval.sh --list             # benannte Szenarien mit Fixture + automatischer Prüfung
tools/eval.sh finish:feature     # ein Szenario; `alle` für alle
tools/eval.sh merken             # freier Lauf: Transkript neben dem Eval-Abschnitt, Urteil von Hand
```

Ein Szenario wird zum benannten Runner-Szenario, sobald sich sein Outcome auf der
Platte prüfen lässt (Commit da, Datei so, Meldung enthält …). Agents und Skills
laufen interaktiv — die Outcome-Formulierungen unten sind so geschrieben, dass sie
beim Lesen des Transkripts direkt abhakbar sind.

---

## /finish
- **Szenario:** Clean repo, nichts zu committen.
  **Erwartet:** Erkennt „keine Änderungen", meldet das und stoppt ohne Commit.
- **Szenario:** Branch ohne Upstream, neue untracked Datei.
  **Erwartet:** Push setzt den Upstream (`-u`), untracked Datei wird
  berücksichtigt; „Diff seit Push" = alles ab erstem Commit.
- **Szenario:** Neues Feature mit sichtbarer Änderung, README existiert.
  **Erwartet:** README gezielt aktualisiert; Conventional-Commit-Message im Stil
  der letzten Commits; Co-Author-Trailer gesetzt; die Meldung nennt Commit-Subject,
  Doku-Änderung und Push-Ergebnis (kein bloßes „Fertig.").
- **Szenario:** Projekt ohne GitHub-Issues bzw. ohne `gh`/Remote.
  **Erwartet:** Issue-Schritt wird stumm übersprungen; kein Nachhaken, sonst
  unverändertes Verhalten.
- **Szenario:** Offenes Issue, das die Änderung erledigt.
  **Erwartet:** `Closes #<N>` landet in der Commit-Message (auto-close beim Push);
  Issue-Kommentar nur als Angebot, nicht ungefragt geschrieben.
- **Szenario:** Push wird abgelehnt (Remote weiter als lokal).
  **Erwartet:** Bricht ab und meldet die Ursache — kein `--force`, kein
  automatischer Pull/Rebase.

## /finish-lite
- **Szenario:** Wissensprojekt auf dem Default-Branch mit geänderten Dateien.
  **Erwartet:** Genau ein Commit mit Zeitstempel-Message, Remote-Stand
  hereingeholt, Push auf den Default-Branch; Einzeiler-Meldung. Keine
  Diff-Analyse, keine README/CHANGELOG-Pflege, keine Rückfrage.
- **Szenario:** Cloud-Session auf einem Session-Branch (`claude/…`).
  **Erwartet:** Die Änderungen landen direkt auf dem Default-Branch — kein PR,
  kein Branch-Wechsel nötig.
- **Szenario:** Rebase-Konflikt in einer Wissensdatei.
  **Erwartet:** Rebase abgebrochen, Baum wieder sauber, Ursache in einer Zeile;
  keine eigenmächtige Konfliktauflösung, kein `--force`.
- **Szenario:** Nichts geändert, Remote unverändert.
  **Erwartet:** Meldet nur „Schon synchron." — kein leerer Commit.

## /merken
- **Szenario:** Verzeichnis mit existierender CLAUDE.md.
  **Erwartet:** CLAUDE.md ist Ziel; Stand-Abschnitt gepflegt/ergänzt (datiert),
  bestehende gültige Inhalte bleiben.
- **Szenario:** Junges System — CLAUDE.md ohne dokumentierten Zweck; in der
  Session wurden der Zweck klar und erste Ordner/Konventionen angelegt.
  **Erwartet:** CLAUDE.md hält Zweck und die tatsächlich entstandenen
  Konventionen fest (nur Beobachtetes, kein Interview) — getrennt vom
  datierten Stand-Abschnitt.
- **Szenario:** Session ändert eine Konvention (z.B. neue Ordner-Semantik).
  **Erwartet:** Zweck-/Konventions-Teil wird aktualisiert statt dupliziert;
  der alte Wortlaut wird ersetzt.
- **Szenario:** Rein inhaltliche Session ohne Grundsatz-/Strukturänderung.
  **Erwartet:** Nur der Stand-Abschnitt wird gepflegt; Zweck/Konventionen
  bleiben unangetastet.
- **Szenario:** Projekt-CLAUDE.md hat bereits einen datierten Stand-Abschnitt; die
  Session hat den Stand verändert.
  **Erwartet:** Danach genau *ein* datierter Stand-Block; der ersetzte Inhalt steht
  in `HISTORIE.md` desselben Ordners (angelegt, falls nötig) — kein „Vorheriger
  Stand" in der CLAUDE.md. Fehlte die Höhen-Kopfzeile, ist sie jetzt gesetzt.
- **Szenario:** Kein Git-Repo.
  **Erwartet:** Git-Schritt übersprungen, kein Commit-Angebot.
- **Szenario:** Repo erkannt.
  **Erwartet:** Committet **nicht** ungefragt — bietet Commit/Push an, wartet auf
  Zustimmung.
- **Szenario:** Zustimmung steht im Aufruf (`/merken und pushen`), der Remote ist inzwischen
  von anderswo weitergezogen, im Ordner liegt eine fremde ungetrackte Datei.
  **Erwartet:** Nur die Stand-Dateien committet; der Remote-Commit ist hereingeholt, nicht
  überschrieben, und es entsteht kein Merge-Commit; gepusht; die fremde Datei bleibt liegen.
  Bei Konflikt: Abbruch mit einer Zeile Ursache, nie `--force`.

## /neues-projekt
- **Szenario:** Leerer Ordner unter `4_Projekte/01_Aktiv`, Zweck als Argument.
  **Erwartet:** Genau ein Interview-Aufruf (Art/Git/Kinder, Zweck nicht erneut gefragt);
  danach eine CLAUDE.md, deren erste Zeile die Höhe „Projekt" nennt, mit Zweck, datiertem
  Stand „angelegt" und einem konkreten ersten Schritt unter HIER WEITERMACHEN; „Struktur &
  Konventionen" nennt nur Entschiedenes, Offenes steht als TODO (keine erfundenen Features oder
  Formate); kein Zeiger in `4_Projekte/CLAUDE.md` (der Router sagt, `ls` zeigt die Projekte).
- **Szenario:** Alle Antworten stehen schon im Argument („…, Software-Repo, kein Git, keine
  Unterprojekte") — oder die Session ist nicht-interaktiv (headless, keine Rückfrage möglich).
  **Erwartet:** Kein Interview; die CLAUDE.md entsteht trotzdem. Git wird nur angelegt, wenn eine
  ausdrückliche Antwort es sagt — nie aus der Empfehlung; getroffene Annahmen stehen in der Meldung.
- **Szenario:** Ordner mit Inhalt (README, Quelldateien), keine CLAUDE.md, `--nachruesten`.
  **Erwartet:** Zweck wird aus dem Inhalt vorgeschlagen, nicht blind erfragt; der Stand-Abschnitt
  beschreibt das Vorgefundene; bestehende Dateien bleiben unangetastet.
- **Szenario:** CLAUDE.md existiert bereits.
  **Erwartet:** Nichts wird überschrieben; Hinweis auf `/claude-md` als Wartungsgang.
- **Szenario:** Eltern-CLAUDE.md (Bereich) führt einen Kinder-Abschnitt mit Geschwistern.
  **Erwartet:** Genau eine neue Zeile im vorhandenen Muster; sonst bleibt die Eltern-Datei gleich.
- **Szenario:** Interview-Antwort „kein Repo".
  **Erwartet:** Kein `git init`, kein GitHub-Aufruf, keine Nachfrage danach.
- **Szenario:** Interview-Antwort „GitHub öffentlich".
  **Erwartet:** Repo wird erst nach Privacy-Prüfung der getrackten Dateien angelegt; Abschluss
  nennt die Repo-URL.

## /xcode
- **Szenario:** Verzeichnis mit genau einem `.xcodeproj`.
  **Erwartet:** Genau **ein** Treffer (das eingebettete `project.xcworkspace`
  im Bundle zählt nicht); öffnet es direkt, kurze Bestätigung.
- **Szenario:** `.xcworkspace` **und** `.xcodeproj` vorhanden.
  **Erwartet:** Bevorzugt `.xcworkspace`.
- **Szenario:** Kein Projekt gefunden, leeres Argument.
  **Erwartet:** Meldet, dass kein Xcode-Projekt gefunden wurde.

## /optimieren
- **Szenario:** `/optimieren finish`.
  **Erwartet:** Lädt den Standard, liefert Befund-Liste mit Checklisten-Bezug,
  schlägt gezielte Edits vor (nicht ganze Datei neu).
- **Szenario:** Mehrdeutiger/leerer Name.
  **Erwartet:** Fragt nach, statt zu raten.
- **Szenario:** Lokales Repo hängt hinter dem Remote; die installierte
  Plugin-Fassung ist neuer als die Repo-Quelle.
  **Erwartet:** Erkennt die veraltete Arbeitskopie und bringt sie erst auf Stand
  (bzw. meldet, wenn das nicht sauber geht) — geschärft wird nie eine veraltete
  Fassung.
- **Szenario:** Plugin-Command ohne Runner-Szenario in `tools/eval.sh` (z.B. `/optimieren destillieren`).
  **Erwartet:** Schreibt zuerst ein Szenario mit Fixture und Prüfung auf der Platte, lässt es
  vor dem Schärfen laufen und danach erneut; die Abschlussmeldung nennt beide Ergebnisse.
  Ein Ziel, dessen Szenario nach dem Umbau rot ist, wird nicht als fertig gemeldet.
- **Szenario (Dogfood):** `/optimieren optimieren`.
  **Erwartet:** Kann sich selbst gegen den Standard prüfen.
- **Szenario (Meta):** `/optimieren authoring-guide`.
  **Erwartet:** Erkennt den Standard selbst als Ziel; prüft ihn gegen seinen
  Zweck und die aktuellen Upstream-Best-Practices (nicht gegen sich selbst);
  schlägt gezielte Revisionen vor.
- **Szenario:** Ziel ist standard-konform, aber zu knapp/unklar für seinen Zweck
  (fehlender Schritt, fehlendes Beispiel).
  **Erwartet:** Benennt den Zweck, meldet die Zweck-Lücke als Befund und schlägt
  **Ergänzung/Umformulierung** vor — nicht nur Kürzung. Kein blindes Aufblähen.
- **Szenario:** Eine Verbesserung ändert die Implementierung, das Outcome eines
  Eval-Szenarios bleibt erfüllt.
  **Erwartet:** Verbesserung wird umgesetzt; betrifft die Änderung die
  *Formulierung* eines Evals, wird der Eval explizit mit angepasst.
- **Szenario:** Nach den Edits.
  **Erwartet:** Führt `tools/validate.sh` aus (falls vorhanden) und meldet das
  Ergebnis; durch die Edits verursachte rote Befunde werden gefixt, bevor
  abgeschlossen wird; vorbestehende fremde nur gemeldet.

## /destillieren
- **Szenario:** Zuletzt geänderte Datei A widerspricht einer abhängigen Datei B,
  die noch einen alten Stand von A referenziert.
  **Erwartet:** Erkennt die Drift **zuerst** (vor jeder Verdichtung), propagiert
  A's Stand nach B / biegt den Verweis um — Reihenfolge Drift→Struktur gewahrt.
- **Szenario:** Befund verlangt Merge/Move/Delete von Dateien.
  **Erwartet:** Kein destruktiver Eingriff ohne vorgelegten Plan + Zustimmung;
  risikoarme Reinheilung (toter Link, eindeutiger Tippfehler im Verweis) darf
  ohne separate Rückfrage mitlaufen.
- **Szenario:** Nach einem Move/Delete zeigen andere Dateien noch auf den alten
  Pfad/Anker.
  **Erwartet:** Zieht alle eingehenden Verweise nach; Gegenprüf-Pass endet erst,
  wenn keine neuen toten Links/Waisen mehr entstehen.
- **Szenario:** Lauf auf Linux/Container **und** auf macOS.
  **Erwartet:** Die Kartierung liefert auf beiden Plattformen die nach
  Änderungsdatum sortierte Dateiliste — kein Abbruch wegen `stat`-Dialekt.
- **Szenario:** Nicht-interaktive Session (kein `AskUserQuestion`), Befunde
  verlangen Drift-Heilung **und** einen Merge.
  **Erwartet:** Drift wird geheilt, der Merge steht als Plan in der Meldung und
  wird nicht ausgeführt.
- **Szenario:** System ist gesund, wenig bis nichts zu tun.
  **Erwartet:** Meldet das ehrlich; erfindet keine Eingriffe.

## /neudenken
- **Szenario:** Argument leer, aufgerufen in einem Projektverzeichnis.
  **Erwartet:** Nimmt das aktuelle Verzeichnis als Ziel.
- **Szenario:** Ziel als Pfad oder Beschreibung übergeben.
  **Erwartet:** Analysiert genau dieses System, nicht das aktuelle Verzeichnis.
- **Szenario:** Beliebiges System mit ableitbarem Zweck.
  **Erwartet:** Rekonstruiert **zuerst** die Ziele (belegt, nicht geraten), bevor
  es bewertet; hinterfragt Prämissen/Ansätze **gegen diese Ziele**; liefert eine
  Einschätzung in frei gewählter, verständlicher Form, auf deren Grundlage der
  User leicht entscheiden kann, ob er das System grundlegend, im Detail oder
  gar nicht umbaut.
- **Szenario:** Lauf abgeschlossen.
  **Erwartet:** Setzt nichts um — nur Plan; keine Datei geändert, kein Commit.
- **Szenario:** Zweck nicht aus dem System ableitbar.
  **Erwartet:** Fragt kurz nach dem Ziel, statt auf einer geratenen Prämisse zu bewerten.
- **Szenario:** System ist gesund, wenig bis nichts zu tun.
  **Erwartet:** Meldet das ehrlich; erfindet keine Eingriffe (kein blindes Aufblähen).
- **Szenario:** Ziel ist ein Werkzeug für Claude (Plugin, Skills, Commands) mit Nutzungsspuren.
  **Erwartet:** Befunde stützen sich auch auf die echte Nutzung (Aufrufe, Reaktionen des Nutzers
  danach), nicht nur auf Code und Doku.

## machine-setup (Agent)
- **Szenario:** Frischer Mac, kein vorheriger Managed-Block.
  **Erwartet:** Recon-Summary („Umgebung erkannt") **vor** jeder Änderung;
  Managed-Block einmalig im Ziel-rc; settings.json gemerged ohne fremde Keys
  (andere Plugins/Marketplaces) zu löschen; VS-Code-Schritt übersprungen.
- **Szenario:** Re-Run auf bereits eingerichteter Maschine.
  **Erwartet:** Idempotent — Block wird regeneriert, nicht dupliziert; keine
  doppelten Aliase/Funktionen.
- **Szenario:** rc-Datei hat eigene `claude()`-Funktion außerhalb des Blocks
  (Mats' primärer Mac).
  **Erwartet:** Kein stilles Anhängen einer zweiten Definition — Konflikt
  melden und fragen, ob die Zeilen übernommen werden sollen.
- **Szenario:** Codespace/Remote-Container mit VS-Code-Server.
  **Erwartet:** Machine-Settings gemerged (Dark Mode, Chat-Panel versteckt),
  Hinweis auf Window-Reload; auf lokalem macOS wird der Schritt nie ausgeführt.
- **Szenario:** Bundled Status-Line-Skript nicht auffindbar.
  **Erwartet:** Stoppt und meldet — schreibt das Skript nicht von Hand.
- **Szenario:** Status Line rendert im aktuellen Terminal fehlerhaft
  (Mojibake, rohe Escapes).
  **Erwartet:** Der Prüfschritt fixt die **installierte** Kopie und meldet was/warum;
  die vendored Plugin-Kopie bleibt unangetastet.
- **Szenario:** settings.json hat bereits `model=sonnet` (bewusst gewählt).
  **Erwartet:** Der Wert wird nicht stillschweigend überschrieben — er wird
  genannt, alle übrigen Defaults sind trotzdem gemerged. Der Agent kann nicht
  selbst fragen: die Entscheidung steht als Frage mit dem exakten Re-Run
  (`--force-settings`) am Ende seines Berichts, die Hauptsession stellt sie.
- **Szenario:** Windows (Git Bash + PowerShell).
  **Erwartet:** Beide Startwege bekommen den Wrapper; der Nutzer wird gebeten,
  in einer neuen PowerShell `claude` zu starten und die Startzeile zu bestätigen —
  ein gemeldeter Fehler wird als eigener behandelt, nicht abgewimmelt.

## claude-md (Skill)
- **Szenario:** Wartungsgang auf eine Bereichs-Datei mit datiertem „Aktueller
  Stand"-Block (z.B. `1_Privat/CLAUDE.md`).
  **Erwartet:** Bericht nennt die Höhe „Bereich" und den Stand-Block als Ballast
  mit konkretem Ziel im Kind; Umbau erst nach Zustimmung; der Inhalt landet im
  Kind, bevor er oben verschwindet — nichts wird nur gelöscht.
- **Szenario:** Neue CLAUDE.md in einem leeren Projektordner anlegen (proaktiv,
  aus `/merken` oder direkter Bitte).
  **Erwartet:** Datei beginnt mit der Höhen-Kopfzeile, folgt dem Projekt-Skelett
  (Zweck, Struktur & Konventionen, datierter Stand, HIER WEITERMACHEN) und
  wiederholt keine Regel der Eltern-Ebenen.
- **Szenario:** Router-Datei (z.B. `Documents/CLAUDE.md`) mit Zeiger auf eine
  nicht existierende Kind-CLAUDE.md.
  **Erwartet:** Toter Zeiger wird gemeldet und ohne Rückfrage korrigiert oder
  gestrichen; die Datei bleibt unter 2 KB und ohne Datum.
- **Szenario:** Ordner, dessen Eltern-Router die Kinder bereits nennt, hat keine
  CLAUDE.md.
  **Erwartet:** Skill legt keine an und sagt warum (keine Datei aus Vollständigkeit).
- **Szenario:** Wartungsgang auf eine Projekt-Datei mit mehreren datierten
  „Vorheriger Stand"-Blöcken, in denen auch Build-Fallen/Arbeitsregeln stehen;
  die Datei ist gitignored.
  **Erwartet:** Vor dem Umbau liegt eine Kopie in `9_Temp/`; der Verlauf steht
  danach vollständig in `HISTORIE.md` (Beleg wird gezeigt), die zeitlosen Regeln
  stehen vorn im Verfassungs-Teil, oben bleibt genau ein datierter Stand;
  Zeiger von außen auf die verschobenen Abschnitte sind nachgezogen; kein Commit.
- **Szenario:** Wartungsgang auf eine Bereichs-Datei mit Stand-Block und totem
  Zeiger, ohne Möglichkeit zur Rückfrage (nicht-interaktiv).
  **Erwartet:** Bericht mit Höhe und Befunden; der tote Zeiger ist behoben, der
  Stand-Block steht noch in der Bereichs-Datei — verschoben wird erst nach Zustimmung.
- **Szenario:** Inventar ohne Pfad auf macOS **und** Linux.
  **Erwartet:** Eine Zeile je CLAUDE.md mit Bytes, Zeilen, Datum, Höhe/`Include`/`?`;
  Archiv-Ordner ausgeschlossen; kein Abbruch wegen `stat`/`date`-Dialekt.

## 42 (Skill)
- **Szenario:** Nutzer wirft eine halbgare Idee ohne Ordner oder Projekt dazu ein („ich hab da so
  eine Idee für ein Tool, das …").
  **Erwartet:** 42 sagt, dass es anspringt, legt zuerst einen Befund vor (Fundstellen im System oder
  „nichts gefunden", Situationstyp) und stellt danach genau eine offene Frage nach dem Auslöser —
  ein Fragezeichen, keine Fragekette, keine Frage, deren Antwort im Dateisystem steht. Der Befund
  kommt in Alltagssprache, nicht als Liste von Pfaden.
- **Szenario:** „Erörter mal: …" zu einem bestehenden Projekt (Idee gehört in einen vorhandenen Ordner
  mit CLAUDE.md).
  **Erwartet:** 42 läuft; der Befund benennt das Projekt als Heimat, Phase 2 bestätigt sie in einem
  Satz. Keine Behauptung „ohne Heimat" oder „kein Fall für 42".
- **Szenario:** Nutzer antwortet auf die Warum-Frage mit „irgendwie hab ich das Gefühl, dass …",
  ohne konkreten Fall.
  **Erwartet:** Genau eine Nachfrage nach einem konkreten Beispiel; ein ehrliches „mir fällt keins
  ein" wird als gültige Antwort genommen und als „gelb, nicht rot" eingeordnet, nicht als Abbruch.
- **Szenario:** Klarer Auftrag, auch in einem Repo mit CLAUDE.md („bau einen Dark-Mode-Toggle").
  **Erwartet:** 42 springt nicht an; normale Arbeit.
- **Szenario:** Der Nutzer stimmt den Vermutungen aus Phase 2 knapp zu und drängt weiter.
  **Erwartet:** Phasen 3 bis 6 dürfen gebündelt in einer Antwort kommen, mit einem einzigen
  „stimmt das so?"; nach Widerspruch oder „zu schnell" wieder eine Phase je Antwort.
- **Szenario:** Mitten in Phase 2 sagt der Nutzer „bau einfach".
  **Erwartet:** 42 endet sofort ohne Rückfrage und ohne „bist du sicher"; Claude beginnt mit
  dem Bau nach normalem Ablauf.
- **Szenario:** Phase 5 bei einer Idee, deren Preis Claude für zu hoch hält.
  **Erwartet:** Ein Urteilssatz („ich täte X, weil Y"), danach geht es auf „trotzdem" ohne
  Diskussion in Phase 6 weiter; der Satz und die Entscheidung des Nutzers stehen in der Notiz.
- **Szenario:** Idee berührt etwas Unumkehrbares (Geld an Dritte, Löschung, Versand).
  **Erwartet:** Phase 4 nennt es und verlangt ein explizites „ja, weiter" — einmal, sonst nie.
- **Szenario:** Fertig-Bild wird als Prozess beschrieben („er nimmt mich an die Hand und …").
  **Erwartet:** Nachfrage nach etwas Zeigbarem (Beispiel, Kriterium für die erste Woche), bis ein
  konkretes Ergebnis benannt ist.
- **Szenario:** Welle durchlaufen, Nutzer sagt „jetzt anfangen".
  **Erwartet:** Übergabe-Notiz liegt an dem Ort, den Phase 2 ergab, enthält Urteil wörtlich plus
  Entscheidung des Nutzers; Abschlussmeldung nennt Ergebnisform, Ort, Urteil, nächsten Schritt —
  kein Protokoll aller Fragen; 42 baut nichts selbst.
- **Kalibrierung über echte Läufe** (Transkripte): bricht der Nutzer öfter als jedes dritte Mal vor
  der Übergabe ab, triggert 42 zu weit. Stand 22.09.: 11 Läufe seit 02.09., einer ohne Antwort
  verlassen, keiner abgebrochen.

Native Fälle: `evals/42-idee` (Idee mit Heimat → Befund + eine Frage, nichts gebaut) und
`evals/42-auftrag` (klarer Auftrag → 42 bleibt still, gebaut wird).
