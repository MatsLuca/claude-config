# Eval-Szenarien für mats-tools

Leichtgewichtige Prüf-Checkliste: pro Command/Agent ein paar repräsentative
Szenarien + erwartetes Verhalten. Kein automatischer Runner — manuell am echten
Command/Agent durchspielen.

**Loop:** Szenario ausführen → Verhalten beobachten → Abweichung als Befund in
`/optimieren <ziel>` einspeisen → schärfen → erneut prüfen. `/optimieren` liest
diese Datei und muss das hier beschriebene Verhalten erhalten.

---

## /finish
- **Szenario:** Clean repo, nichts zu committen.
  **Erwartet:** Erkennt „keine Änderungen", meldet das und stoppt ohne Commit.
- **Szenario:** Branch ohne Upstream, neue untracked Datei.
  **Erwartet:** Push mit `git push -u origin <branch>`, untracked Datei wird
  berücksichtigt; „Diff seit Push" = alles ab erstem Commit.
- **Szenario:** Neues Feature mit sichtbarer Änderung, README existiert.
  **Erwartet:** README gezielt aktualisiert; Conventional-Commit-Message im Stil
  der letzten Commits; Co-Author-Trailer gesetzt.
- **Szenario:** Projekt ohne GitHub-Issues bzw. ohne `gh`/Remote.
  **Erwartet:** Issue-Schritt erkennt `KEINE_ISSUES_ODER_KEIN_GH` und wird stumm
  übersprungen; kein Nachhaken, sonst unverändertes Verhalten.
- **Szenario:** Offenes Issue, das die Änderung erledigt.
  **Erwartet:** `Closes #<N>` landet in der Commit-Message (auto-close beim Push);
  Issue-Kommentar nur als Angebot, nicht ungefragt geschrieben.

## /github-pushes
- **Szenario:** Argument leer.
  **Erwartet:** Default `-v-24H`, erwähnt den Default in der Antwort.
- **Szenario:** „letzte Woche".
  **Erwartet:** Übersetzt zu `-v-7d`; Ergebnis pro Repo gruppiert, neueste
  zuerst, private Repos mit 🔒; Kurz-Summary vorangestellt.
- **Szenario:** Keine Commits im Zeitraum.
  **Erwartet:** Meldet knapp „keine Pushes gefunden" (jq `KEINE_COMMITS`).

## /merken
- **Szenario:** Verzeichnis mit existierender CLAUDE.md.
  **Erwartet:** CLAUDE.md ist Ziel; Stand-Abschnitt gepflegt/ergänzt (datiert),
  bestehende gültige Inhalte bleiben.
- **Szenario:** Kein Repo (`KEIN_REPO`).
  **Erwartet:** Git-Schritt übersprungen, kein Commit-Angebot.
- **Szenario:** Repo erkannt.
  **Erwartet:** Committet **nicht** ungefragt — bietet Commit/Push an, wartet auf
  Zustimmung.

## /xcode
- **Szenario:** Verzeichnis mit genau einem `.xcodeproj`.
  **Erwartet:** Öffnet es direkt mit `open`, kurze Bestätigung.
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
- **Szenario:** Ziel ist standard-konform, aber zu knapp/unklar für seinen Zweck
  (fehlender Schritt, fehlendes Beispiel).
  **Erwartet:** Benennt den Zweck, meldet die Zweck-Lücke als Befund und schlägt
  **Ergänzung/Umformulierung** vor — nicht nur Kürzung. Kein blindes Aufblähen.

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
