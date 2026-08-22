# NEWS — Nachrichten von Mats an alle mats-tools-Abonnenten

Neuester Eintrag oben. Jeder Eintrag beginnt mit `## <Datum> · <Titel>`; der Hook
`hooks/news.sh` zeigt ungelesene Einträge beim Session-Start genau einmal pro Maschine
(Seen-Datei `~/.claude/mats-tools-news-seen`, `news.sh --reset` zeigt alles erneut).
Kurz halten — das landet 1:1 im Terminal der Leute.

## 2026-08-22 · Bitte einmal das machine-setup neu laufen lassen

Neu in mats-tools: die Startzeile sagt jetzt, wie lange das letzte Plugin-Update her ist,
und dieser News-Kanal hier. Damit künftige Verbesserungen am Start-Wrapper automatisch bei
dir ankommen, braucht es einmalig ein frisches Setup — einfach als Prompt schicken:

    Führe das machine-setup durch.

Ist idempotent, überschreibt nichts Eigenes. Danach neues Terminal öffnen — fertig.
