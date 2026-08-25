# Eval-Szenarien für mats-tools

Leichtgewichtige Prüf-Checkliste: pro Command/Agent ein paar repräsentative
Szenarien + erwartetes Verhalten.

**Grundprinzip — Outcomes, nicht Implementierung.** Szenarien beschreiben
*beobachtbares Verhalten* (was der User sieht und was auf der Platte passiert),
nie interne Marker, Flags oder konkrete Tool-Aufrufe. Ein Eval darf eine bessere
Neuimplementierung niemals blockieren: Ändert sich das *Wie*, bleibt der Eval
gültig; ändert sich das *Was*, wird der Eval bewusst mitgeändert — nie stillschweigend.

**Loop:** Szenario ausführen → Verhalten beobachten → Abweichung als Befund in
`/optimieren <ziel>` einspeisen → schärfen → erneut prüfen. `/optimieren` liest
diese Datei und muss die hier beschriebenen Outcomes erhalten.

**Ausführen:** Strukturelles prüft `tools/validate.sh` automatisch (lokal + CI).
Verhaltens-Szenarien laufen am echten Command — `tools/eval.sh` startet ihn headless
aus der Repo-Quelle in einem Wegwerf-Fixture:

```bash
tools/eval.sh --list             # benannte Szenarien mit Fixture + automatischer Prüfung
tools/eval.sh finish-lite:sync   # ein Szenario; `alle` für alle
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

## /github-pushes
- **Szenario:** Argument leer.
  **Erwartet:** Nimmt die letzten 24 Stunden als Default und erwähnt das in
  der Antwort.
- **Szenario:** „letzte Woche".
  **Erwartet:** Zeitraum-Start liegt 7 Tage zurück; Ergebnis pro Repo gruppiert,
  neueste zuerst, private Repos mit 🔒; Kurz-Summary vorangestellt.
- **Szenario:** Lauf auf Linux/Container **und** auf macOS.
  **Erwartet:** Der Zeitraum-Start wird auf beiden Plattformen korrekt
  berechnet — kein Abbruch wegen `date`-Dialekt.
- **Szenario:** Keine Commits im Zeitraum.
  **Erwartet:** Meldet knapp, dass im Zeitraum keine Pushes gefunden wurden.

## /wrapped
- **Szenario:** Argument leer.
  **Erwartet:** Nimmt 7 Tage ohne Rückfrage; Ausgabe enthält einen `png`-Pfad, und
  die Antwort nennt Zeitraum, Hero-Zahl und Kosten-Vergleich in wenigen Zeilen.
- **Szenario:** „diesen Monat" mit `--plan pro`.
  **Erwartet:** `--days 30 --plan pro`; der „×-rausgeholt"-Wert rechnet gegen den
  anteiligen Pro-Preis, nicht gegen max20.
- **Szenario:** Zwei Läufe am selben Tag, ohne `--theme`.
  **Erwartet:** Dieselbe Farbwelt — die Wahl hängt am Datum, nicht an der Uhrzeit.
- **Szenario:** Kein Netz und kein Wechselkurs-Cache.
  **Erwartet:** Die Karte zeigt trotzdem Euro (letzter bekannter oder Näherungskurs),
  statt abzubrechen oder auf Dollar zurückzufallen.
- **Szenario:** Offline (Limit-Abruf schlägt fehl).
  **Erwartet:** Kein Abbruch — die Karte zeigt statt der Limit-Auslastung den
  Modell-Mix, und die Antwort erwähnt die fehlenden Limit-Zahlen.
- **Szenario:** Zweiter Lauf am selben Tag (Zieldatei vom ersten Lauf liegt noch da).
  **Erwartet:** Das Bild wird neu gerendert und zeigt die aktuellen Zahlen — nie wird
  ein altes PNG als Ergebnis ausgegeben oder in die Zwischenablage gelegt.
- **Szenario:** Kein Chromium-Browser installiert.
  **Erwartet:** Klare Meldung „Kein Chrome/Chromium gefunden" mit dem Hinweis auf
  `CHROME_PATH`; kein Selbst-Installieren, kein halbes PNG.
- **Szenario:** Zeitraum ohne jede Aktivität (z.B. `--since` in der Zukunft).
  **Erwartet:** Bild entsteht trotzdem mit Nullen statt NaN/leeren Kacheln.
- **Szenario:** Dieselbe Arbeit, einmal mit einem geschwätzigen und einmal mit einem
  sparsamen Modell erledigt (50 statt 5 Werkzeug-Aufrufe).
  **Erwartet:** Die Handarbeits-Schätzung bleibt praktisch gleich — gezählt werden
  Aufträge, nicht Aufrufe — und die Karte trägt sichtbar ein `≈`.
- **Szenario:** Session besteht überwiegend aus „ja"/„mach weiter"-Zurufen.
  **Erwartet:** Diese Aufträge fallen als `trivial` mit 1 Minute ins Gewicht und
  blähen die Zahl nicht auf.
- **Szenario:** Arbeit lag in privat benannten Projekten.
  **Erwartet:** Weder Karte noch `/tmp/wrapped.json` enthalten Projekt-, Ordner- oder
  Dateinamen — nur Zählungen und Werkzeugnamen.

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
  Stand „angelegt" und einem konkreten ersten Schritt unter HIER WEITERMACHEN; kein Zeiger in
  `4_Projekte/CLAUDE.md` (der Router sagt, `ls` zeigt die Projekte).
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
  **Erwartet:** Die System-Kartierung (Schritt 1) liefert auf beiden Plattformen
  die nach Änderungsdatum sortierte Dateiliste — kein Abbruch wegen `stat`-Dialekt.
- **Szenario:** System ist gesund, wenig bis nichts zu tun.
  **Erwartet:** Meldet das ehrlich; erfindet keine Eingriffe.

## /einarbeiten
- **Szenario:** Argument leer.
  **Erwartet:** Fragt, was eingearbeitet werden soll, und stoppt — kein Raten.
- **Szenario:** Input ist fürs Projekt klar irrelevant (z.B. fachfremder Artikel).
  **Erwartet:** Überspringt die Rückfragen (Schritt 5), entscheidet „kein
  Handlungsbedarf", ändert keine Datei.
- **Szenario:** URL, deren Inhalt bestehendes Projektwissen ergänzt.
  **Erwartet:** Holt den Inhalt; stellt gezielte, aus Input + Projekt
  abgeleitete Rückfragen (keine generischen); arbeitet punktuell ein —
  Synthese im Stil der Zieldatei, kein Roh-Copy-Paste.
- **Szenario:** Input widerspricht einer Annahme in CLAUDE.md glaubwürdig.
  **Erwartet:** Wählt „Infragestellen": benennt den Konflikt explizit, schlägt
  Revision mit Begründung vor; bei größerem Eingriff erst Plan + Zustimmung.

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
  **Erwartet:** Step 6 fixt die **installierte** Kopie und meldet was/warum;
  die vendored Plugin-Kopie bleibt unangetastet.
- **Szenario:** settings.json hat bereits `model=sonnet` (bewusst gewählt).
  **Erwartet:** Der Wert wird nicht stillschweigend überschrieben — er wird
  genannt und Mats gefragt; alle übrigen Defaults sind trotzdem gemerged.
- **Szenario:** Windows (Git Bash + PowerShell).
  **Erwartet:** Beide Startwege bekommen den Wrapper; der Nutzer wird gebeten,
  in einer neuen PowerShell `claude` zu starten und die Startzeile zu bestätigen —
  ein gemeldeter Fehler wird als eigener behandelt, nicht abgewimmelt.

## pdf-to-markdown (Agent)
- **Szenario:** Altklausur-PDF.
  **Erwartet:** Klassifiziert als Klausur; Frontmatter `type: exam`;
  Aufgaben/Punkte erhalten; Diagramme rekonstruierbar beschrieben.
- **Szenario:** Vorlesungsfolien-PDF.
  **Erwartet:** Klassifiziert als Folien; jede Folie getrackt; animierte Folien
  zum Endzustand gemerged; TOC bei > 20 Folien.
- **Szenario:** Paper/Skript-PDF.
  **Erwartet:** Generischer Modus; lineare, vollständige Reproduktion; eigene
  Überschriftenhierarchie gespiegelt.

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
