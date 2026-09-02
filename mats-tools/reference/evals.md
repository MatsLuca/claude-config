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
da, gepusht, Baum sauber), prüft `tools/eval.sh` auf der Platte. Claude Codes
`claude plugin eval` (Early Access, Fälle = `prompt.md` + `graders/*.md`) ergänzt später den
Vergleichslauf ohne Plugin und LLM-bewertete Kriterien — es ersetzt den Runner nicht.

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
  der letzten Commits; Co-Author-Trailer gesetzt.
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
- **Szenario:** Inventar ohne Pfad auf macOS **und** Linux.
  **Erwartet:** Eine Zeile je CLAUDE.md mit Bytes, Zeilen, Datum, Höhe/`Include`/`?`;
  Archiv-Ordner ausgeschlossen; kein Abbruch wegen `stat`/`date`-Dialekt.

## latexterm (Skill)
- **Szenario:** Session läuft in LatexTerm; Mats bittet „öffne eine Kachel und
  starte da den Dev-Server".
  **Erwartet:** Neue Kachel entsteht, der Befehl läuft dort; die eigene Kachel
  bleibt frei; kurze Meldung, welche Kachel es ist.
- **Szenario:** Session läuft **nicht** in LatexTerm (kein `$LATEXTERM_PANE_ID`,
  z.B. bei einem Abonnenten), Frage „was kannst du mit dem Terminal machen".
  **Erwartet:** Sagt ehrlich, dass die LatexTerm-Steuerung hier nicht verfügbar
  ist, und arbeitet normal weiter — nichts wird simuliert, nichts scheitert laut.
- **Szenario:** „Frag die andere Claude-Session, ob sie fertig ist."
  **Erwartet:** Der Prompt landet in der anderen Kachel und wird dort abgeschickt
  (nicht nur eingetippt); Mats' eigene Kachel wird nicht überschrieben.
