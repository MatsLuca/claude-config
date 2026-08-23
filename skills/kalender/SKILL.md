---
name: kalender
description: Trägt Termine in Mats' Google-Kalender ein (Unterkalender "Claude", synct aufs iPhone). Nutzen, sobald Mats einen Termin eintragen, ändern, löschen oder abfragen will — „trag mir das in den Kalender ein", „was steht nächste Woche an", „verschieb den Termin", auch beiläufig mitten in anderer Arbeit.
---

# Kalender

Alle Aktionen laufen über ein Script (Ausgabe: JSON):

```bash
~/.config/google-calendar/gcal.py <befehl> …
```

## Termin anlegen

```bash
~/.config/google-calendar/gcal.py add --title "Zahnarzt" --start 2026-07-15T09:30 [--end 2026-07-15T10:15] [--location "…"] [--description "…"]
```

- Zeiten als ISO ohne Zeitzone — das Script setzt Europe/Berlin. Ohne `--end`: 60 min.
- Ganztägig: `--all-day --start 2026-07-15` (Datum statt Zeitpunkt; `--end` exklusiv).
- Wiederkehrend: `--rrule "FREQ=WEEKLY;BYDAY=MO;UNTIL=20261231T000000Z"`.
- Relative Angaben („morgen", „nächsten Dienstag") selbst in konkrete Daten auflösen — heutiges Datum steht im Kontext. Bei mehrdeutiger Zeit (z. B. „um 8") kurz nachfragen statt raten.
- Nach dem Anlegen bestätigen: Titel, Datum/Zeit — keinen Link-Spam.

## Abfragen / Löschen

```bash
~/.config/google-calendar/gcal.py list --days 7
~/.config/google-calendar/gcal.py delete --id <EVENT_ID>
```

Zum Ändern eines Termins: alten löschen, neuen anlegen (IDs liefert `list`).

## Fehlerfälle

- `"Nicht authentifiziert"` → Mats soll einmalig `! ~/.config/google-calendar/gcal.py auth` ausführen (öffnet Browser).
- `"Kein Kalender konfiguriert"` → einmalig `~/.config/google-calendar/gcal.py setup-calendar` ausführen (geht ohne Browser, kannst du selbst).
