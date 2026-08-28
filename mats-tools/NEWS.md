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
