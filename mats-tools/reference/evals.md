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
Verhaltens-Szenarien laufen am echten Command/Agent — interaktiv oder headless
in einem Wegwerf-Fixture, z.B.:

```bash
cd "$(mktemp -d)" && git init -q .   # Fixture passend zum Szenario aufbauen
claude -p "/finish" --permission-mode acceptEdits   # Transkript gegen das Szenario lesen
```

Kein automatischer Assertion-Runner (noch) — die Outcome-Formulierungen unten
sind bewusst so geschrieben, dass ein späterer Runner sie direkt prüfen kann.

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
- **Szenario:** Kein Git-Repo.
  **Erwartet:** Git-Schritt übersprungen, kein Commit-Angebot.
- **Szenario:** Repo erkannt.
  **Erwartet:** Committet **nicht** ungefragt — bietet Commit/Push an, wartet auf
  Zustimmung.

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
  Ergebnis; rote Befunde werden gefixt, bevor abgeschlossen wird.

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
