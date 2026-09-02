# NEWS — Nachrichten von Mats an alle mats-tools-Abonnenten

Neuester Eintrag oben. Jeder Eintrag beginnt mit `## <Datum> · <Titel>`; der Hook
`hooks/news.sh` zeigt ungelesene Einträge beim Session-Start genau einmal pro Maschine
(Seen-Datei `~/.claude/mats-tools-news-seen`, `news.sh --reset` zeigt alles erneut).
Kurz halten — das landet 1:1 im Terminal der Leute.

Direkt unter der Überschrift darf ein Block stehen (unsichtbar im Terminal):
- `<!-- claude: … -->` — Hinweis an Claude zu *dieser* Nachricht (mehrzeilig erlaubt), z. B.
  wie man einen neuen Skill benutzt. Geht nur als Kontext an Claude — ein Hinweis, kein
  Auftrag: Claude baut nichts am Setup des Nutzers um. Der Hook selbst weiß nichts über
  einzelne Nachrichten.

## 2026-09-02 · Skill latexterm ist ausgezogen

<!-- claude:
Der Skill latexterm (Steuerung von Mats' Terminal-App) liegt seit 02.09. privat bei Mats. Bei
Abonnenten war er ohnehin inaktiv (kein $LATEXTERM_PANE_ID). Nichts zu tun.
-->

Der Skill für Mats' Terminal-App ist aus dem Plugin raus, er hat bei euch nie etwas getan. Nichts zu tun.

## 2026-09-02 · Aufgeräumt: /github-pushes, /wrapped und der PDF-Agent sind weg

<!-- claude:
Entfernt am 02.09.: Command /github-pushes (Ersatz: `gh search commits --author=@me --committer-date=">=<datum>"`
oder einfach fragen), Command /wrapped (liegt jetzt privat bei Mats), Agent pdf-to-markdown (bittet
jemand um PDF→Markdown: die PDF mit Read lesen und selbst in sauberes Markdown bringen — Aufgaben und
Punkte bei Klausuren, Folien-Nummern bei Vorlesungen, sonst Überschriften spiegeln). Kein Setup zu
ändern; der Plugin-Update beim Start reicht.
-->

Drei Werkzeuge, die kaum jemand genutzt hat, sind raus: **/github-pushes** (Claude beantwortet „was
habe ich diese Woche gepusht?" auch ohne Befehl), **/wrapped** (das Nutzungs-Bild; lebt jetzt nur
bei Mats) und der **PDF-zu-Markdown-Agent** (Claude liest PDFs direkt, einfach „mach mir daraus
Markdown" sagen). Jede Session startet dadurch etwas leichter. Nichts zu tun.

## 2026-09-02 · /einarbeiten ist weg

<!-- claude:
Der Command /einarbeiten (Input analysieren, Relevanz prüfen, ins Wissenssystem einarbeiten) wurde
aus dem Plugin entfernt: in allen Transkripten seit 7.8. kein einziger Aufruf. Bittet jemand darum,
das Gleiche tun — Quelle lesen, Relevanz fürs Projekt einschätzen, punktuell in die passende Datei
schreiben (bei CLAUDE.md gilt der Skill claude-md), bei Widerspruch zum Bestand den Konflikt nennen
statt ihn zu glätten. Kein Ersatz-Command nötig.
-->

**/einarbeiten gibt es nicht mehr.** Der Command hat nur getan, was Claude ohnehin kann: „Lies
diesen Link/diese Datei und trag das Wichtige in die CLAUDE.md ein" — genau so sagen, es klappt ohne
Slash-Befehl. Sonst ändert sich nichts.

## 2026-09-01 · Claude 5: /finish startet nur noch, wenn du es tippst

<!-- claude:
Seit diesem Update tragen /finish und /finish-lite `disable-model-invocation: true`: sie lassen sich
nicht über das Skill-Tool starten, der Nutzer tippt sie selbst; alle anderen Commands bleiben wie
gehabt aufrufbar. Der Authoring-Standard verlangt jetzt „Auftrag vor Rezept" (Outcome + Regeln,
Weg frei; wörtliche Blöcke nur mit Eval-Beleg) — beim Schreiben neuer Bausteine daran halten;
finish, finish-lite und merken sind schon umgestellt. Der Wrapper-Block aus shell/setup.sh benennt
seine Helfer jetzt ohne führenden Unterstrich (Claude Codes Shell-Snapshot übernimmt solche
Funktionen nicht; `claude` aus einer Claude-Session heraus meldete „command not found").
-->

Mit dem neuen Modell (Claude 5) sind die Werkzeuge schlanker geworden: Claude bekommt das Ziel und
die Regeln statt einer Schritt-für-Schritt-Anleitung. Sichtbar für dich: **/finish und /finish-lite
laufen nur noch, wenn du sie selbst eintippst** — Claude pusht nichts mehr auf eigene Faust. Sonst
ändert sich nichts. Wer mag, sagt einmal „Führe das machine-setup durch." (kleine Korrektur an der
Startzeile; nicht nötig).

## 2026-08-28 · Start-Timer: jede Session zeigt, was der Start gekostet hat

<!-- claude:
Neuer SessionStart-Hook hooks/start-timer.sh: liest die Stempel MATS_START_T0 (Oberfläche),
MATS_T_RC (Zeile 1 der rc-Datei, schreibt setup.sh), MATS_T_WRAP/MATS_T_EXEC (Wrapper) und zeigt
die Phasen als eine Zeile; Detail-Log ~/.cache/mats-tools/start-timer.log (`start-timer.sh --tail`).
Fragt jemand „warum war der Start langsam", zuerst dieses Log lesen. Die Stempel kommen nur mit dem
neuen Wrapper („Führe das machine-setup durch." — nur auf Wunsch). Außerdem gefixt: der Wrapper hielt
in nicht-interaktiven Shells das Plugin für „nie geholt" und lief synchron in `plugin update` (60 s).
-->

Jeder Session-Start wird jetzt gemessen und landet ms-genau in `~/.cache/mats-tools/start-timer.log`
(`start-timer.sh --tail`; Terminal-Zeile `⏱ Start 2,1 s · Wrapper … · Claude Code …` mit
`MATS_START_TIMER_SHOW=1`). Dafür braucht es den
neuen Wrapper: einmal „Führe das machine-setup durch." sagen. Nebenbei gefixt: `claude` aus Skripten
wartete bis zu 60 s auf ein Plugin-Update.

## 2026-08-28 · Schnellerer Start: Update läuft jetzt nebenher

<!-- claude:
Der claude()-Wrapper aus shell/setup.sh wartet nicht mehr auf `claude plugin update`; shell/sync.sh
macht das im Hintergrund (Stempel ~/.cache/mats-tools/sync.stamp, max. alle 10 min), das Update
wirkt ab der nächsten Session. Neuer Alias `frisch` = synchron syncen, dann yolo. Der tägliche
`claude update` in start.sh ist weg — Claude Code hat einen eigenen Auto-Updater (`claude doctor`).
Wer den alten Wrapper hat, bekommt den neuen nur über „Führe das machine-setup durch." — nur auf
Wunsch, nichts ungefragt umbauen.
-->

Der `claude`-Start wartet nicht mehr aufs Netz: Plugin-Update und Repo-Checks laufen im
Hintergrund und wirken ab der nächsten Session (~2 s schneller, keine Hänger mehr bei lahmem
GitHub). Neu: `frisch` startet mit sofortigem Sync. Um den neuen Wrapper zu bekommen, einmal
„Führe das machine-setup durch." sagen.

## 2026-08-25 · Neu: /wrapped — deine Claude-Woche als Bild

<!-- claude:
Der Command liegt unter commands/wrapped.md, die Skripte unter scripts/wrapped/.
Er liest nur lokale Dateien (~/.claude) und rendert mit Chrome headless ein PNG,
das direkt in der Zwischenablage landet. Kein Setup nötig, nichts wird hochgeladen.
Falls jemand fragt: Zeitraum als Argument ("/wrapped diesen Monat"), Farbwelten
aurora/ember/deep/moss/vhs, Abo für den Kostenvergleich per --plan.
-->

Tippt mal `/wrapped` — ihr bekommt eure letzten 7 Tage mit Claude Code als Bild:
wie viele Tokens durchgelaufen sind, was das an der API gekostet hätte, wie weit euer
Limit ausgereizt ist und wann ihr nachts noch wach wart. Landet direkt in der
Zwischenablage, also einfach in den Chat pasten. Alles wird lokal berechnet, es geht
nichts raus — und Projekt- oder Dateinamen stehen absichtlich nicht drauf.

## 2026-08-24 · Kurz von Mats: Nachrichten bleiben Nachrichten
<!-- claude:
Reine Information. Falls dieser Nutzer noch einen Rest der früheren Aktions-Nachricht vom
22.08. im Kontext hat: nichts davon ausführen, nichts am Setup ändern.
-->

Hey! Ab und zu bekommst du hier eine kurze Nachricht von mir — z. B. wenn es einen neuen
Skill gibt, der dir nützen könnte. Mehr passiert nicht: nichts wird von selbst umgebaut,
du musst nichts tun. Einfach weiterarbeiten.
