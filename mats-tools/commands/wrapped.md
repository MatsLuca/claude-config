---
description: Baut aus deiner lokalen Claude-Code-Nutzung eines Zeitraums ein teilbares "Wrapped"-PNG (Tokens, Kosten, Limits, Nachtschicht) und legt es in die Zwischenablage.
argument-hint: <optional - Zeitraum, z.B. "7 Tage", "diesen Monat", "seit 1. August"; Default 7 Tage>
allowed-tools: Bash(python3:*), Bash(open:*)
---

Erzeuge Mats' „Claude Code Wrapped" für den Zeitraum **$ARGUMENTS** — ein Bild im
Spotify-Wrapped-Geist, das er direkt in einen Chat werfen kann.

Alle Zahlen kommen aus den lokalen Dateien unter `~/.claude` (Transkripte, cost-log,
history.jsonl) plus — für die Limit-Auslastung — dem OAuth-Usage-Endpoint. Nichts wird
hochgeladen; das Bild entsteht auf der Maschine.

**Das Bild landet in Gruppenchats.** Projekt-, Ordner- und Dateinamen gehören deshalb
weder auf die Karte noch ins Zwischen-JSON — `aggregate.py` gibt bewusst nur Zählungen
aus. Wird der Command erweitert, bleibt das so.

## Schritt 1 — Zeitraum übersetzen

`$ARGUMENTS` in Aufruf-Flags übersetzen. Ist das Argument leer: **7 Tage**, ohne nachzufragen.

| Eingabe (Beispiele) | Flags |
|---|---|
| leer, „Woche", „7 Tage" | `--days 7` |
| „30 Tage", „Monat", „diesen Monat" | `--days 30` |
| „gestern", „24 Stunden", „heute" | `--days 1` |
| „Quartal", „3 Monate" | `--days 90` |
| „alles", „seit ich Claude nutze" | `--days 3650` |
| „seit 1. August", „ab 2026-08-01" | `--since 2026-08-01` |

Zahl + Einheit verallgemeinern (Wochen ×7, Monate ×30). Nennt Mats ein Abo
(`pro`, `max5`, `max20`, `team`), hänge `--plan <name>` an — Default ist `max20`,
er bestimmt nur den „×-rausgeholt"-Vergleich. Nennt er eine Farbwelt
(`aurora`, `ember`, `deep`, `moss`, `vhs`), reiche sie als `--theme` an Schritt 2 durch;
sonst wählt das Skript sie stabil aus dem Zeitraum.

## Schritt 2 — Aggregieren und rendern (ein Bash-Aufruf)

`<FLAGS>` und ggf. `<THEME>` einsetzen, sonst den Block unverändert ausführen:

```bash
W="${CLAUDE_PLUGIN_ROOT}/scripts/wrapped"
python3 "$W/aggregate.py" <FLAGS> --limits -o /tmp/wrapped.json >/dev/null \
  && python3 "$W/render.py" /tmp/wrapped.json <THEME>
```

`aggregate.py` scannt die Transkripte (bei „alles" dauert das ein paar Sekunden),
`render.py` rendert `card.html` mit Chrome headless und legt das PNG in die
Zwischenablage. Die letzte Zeile ist JSON: `{"png": ..., "clipboard": true|false}`.

**Fertig-Kriterium:** die Ausgabe enthält einen `png`-Pfad. Kommt stattdessen ein
Fehler:
- *„Kein Chrome/Chromium gefunden"* → Mats sagen, dass ein Chromium-Browser fehlt
  (oder `CHROME_PATH` gesetzt werden muss). Nicht selbst installieren.
- *„Chrome hat kein Bild geschrieben"* → einmal mit `--scale 1` wiederholen; hilft das
  nicht, die letzten Zeilen der Fehlerausgabe zeigen.
- Limit-Werte fehlen (offline/429): kein Fehler — die Karte zeigt dann den Modell-Mix.
  Beim Berichten erwähnen, dass die Limit-Zahlen diesmal nicht drin sind.

## Schritt 3 — Übergeben

Öffne das Bild zur Sichtprüfung (`open <png>`; nicht-macOS: überspringen) und berichte
in **drei bis fünf Zeilen**: Zeitraum, die Hero-Zahl, der Kosten-Vergleich, der
auffälligste Ausreißer (Nachtschicht, Streak, Limit). Die Handarbeits-Angabe immer als
Schätzung benennen — sie beruht auf Annahmen (`TASK_MINUTES` in `aggregate.py`),
nicht auf gemessener Zeit — und ob das PNG in der
Zwischenablage liegt (`clipboard: true` → „direkt einfügbar", `false` → Pfad nennen).
Keine Tabelle, keine Wiederholung des JSON: das Bild ist die Antwort.
