# NEWS — Nachrichten von Mats an alle mats-tools-Abonnenten

Neuester Eintrag oben. Jeder Eintrag beginnt mit `## <Datum> · <Titel>`; der Hook
`hooks/news.sh` zeigt ungelesene Einträge beim Session-Start genau einmal pro Maschine
(Seen-Datei `~/.claude/mats-tools-news-seen`, `news.sh --reset` zeigt alles erneut).
Kurz halten — das landet 1:1 im Terminal der Leute.

## 2026-08-22 · Neu: Live-Nachrichten & fernsteuerbare Startzeile — einmal nachrüsten

Zwei neue Dinge in mats-tools: (1) dieser Kanal hier — ich kann euch ab jetzt Nachrichten
direkt in den Session-Start schicken (seht ihr genau einmal). (2) Die Startzeile des
Auto-Update-Wrappers („🔄 mats-tools aktuell …") kommt jetzt aus dem Plugin selbst und
zeigt, wie lange das letzte Update her ist.

Damit (2) bei dir ankommt, muss dein Wrapper einmal neu erzeugt werden — je nachdem, wie
du Claude Code nutzt:
- Nutzt du mein Setup 1:1 → sag deinem Claude „Führe das machine-setup im Nachrüst-Modus
  durch" — das erneuert nur den Wrapper-Block, sonst nichts.
- Hast du dein Terminal/deine Status Line selbst umgebaut → **nicht** blind das
  machine-setup laufen lassen. Lass dir von Claude zeigen, wo bei dir das Plugin-Update
  beim Start läuft, und bau nur dort die eine Zeile ein, die `shell/start.sh` aus dem
  aktiven Plugin-Ordner sourct. Claude weiß, wie das geht.

Kaputt machen kann der Nachrüst-Modus nichts Eigenes — aber frag im Zweifel erst, was er
ändern würde.
