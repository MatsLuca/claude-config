---
description: Frisst beliebigen Input (Text, Datei, URL), analysiert ihn semantisch, prüft die Relevanz fürs aktuelle Projekt und arbeitet das Brauchbare gezielt ins Wissenssystem ein — oder stellt bestehende Strukturen begründet infrage.
argument-hint: <Text, Dateipfad oder URL — der zu verarbeitende Input>
allowed-tools: Bash(pwd), Bash(ls:*), Bash(git rev-parse:*), Read, Edit, Write, Glob, Grep, WebFetch, AskUserQuestion
---

Du nimmst einen beliebigen Input und entscheidest fundiert, was davon — wenn überhaupt — wie ins aktuelle Projekt gehört. Kein blindes Reinkopieren: erst verstehen, dann Relevanz prüfen, Motivation klären, dann gezielt einarbeiten oder bestehende Annahmen infrage stellen.

Zu verarbeitender Input: **$ARGUMENTS**

**Token-effizient:** erst billige Übersicht (Input + Projektkontext), Vollinhalt nur gezielt nachladen.

## Schritt 1 — Input auflösen & lesen

`$ARGUMENTS` ist dreierlei:
- **Dateipfad** (existiert auf der Platte) → mit `Read` laden, bei großem Dokument gezielt die inhaltstragenden Teile.
- **URL** (http/https) → mit `WebFetch` holen.
- **Inline-Text** → direkt verwenden.

Leer? → frage den User, was eingearbeitet werden soll, und stoppe.

## Schritt 2 — Projektkontext in EINEM Aufruf erfassen

```bash
echo "=== ORDNER ===" && pwd && \
echo "=== PROJEKT-WURZEL ===" && git rev-parse --show-toplevel 2>/dev/null || echo "KEIN_REPO" && \
echo "=== KONTEXTDATEIEN ===" && ls -1 CLAUDE.md README* 2>/dev/null || echo "(keine im Root)" && \
echo "=== STRUKTUR ===" && ls -1 2>/dev/null
```

`CLAUDE.md` ist die Hauptquelle für „worum geht es in diesem Projekt". Lies sie (und ggf. README) gezielt, um Zweck, Stack und das bestehende Wissenssystem zu verstehen. Was schon im Kontext ist, nicht neu lesen.

## Schritt 3 — Semantische Analyse des Inputs

Destilliere, **worum es im Input wirklich geht** — nicht die Oberfläche, sondern den Kern:
- Hauptaussagen / Erkenntnisse / Fakten / Behauptungen.
- Art des Materials (Anleitung, Konzept, Daten, Meinung, Spezifikation …).
- Implizite Annahmen, und was strittig oder unbelegt ist.

Halte das knapp für dich fest — es ist die Grundlage für die Relevanzprüfung.

## Schritt 4 — Relevanz fürs Projekt prüfen

Gleiche den Input-Kern gegen das in Schritt 2 verstandene Projekt ab. Ordne jeden tragenden Punkt ein:
- **Direkt relevant** — betrifft unmittelbar Code / Doku / Ziele des Projekts.
- **Indirekt relevant** — Hintergrund, Methodik, angrenzend, später nützlich.
- **Irrelevant** — gehört nicht hierher; klar so benennen, nicht künstlich einpassen.

Halte zusätzlich fest, wo der Input bestehendes Projektwissen **bestätigt**, **ergänzt** oder ihm **widerspricht**.

## Schritt 5 — Motivation klären (bis zu 5 gezielte Rückfragen)

Ergibt Schritt 4 schon klar, dass **nichts** fürs Projekt relevant ist, überspringe die Rückfragen und geh direkt zu Schritt 6 (kein Handlungsbedarf) — frag nicht ins Leere.

Sonst, bevor du etwas einarbeitest: kläre, **warum** der User genau diesen Input einbringt — das entscheidet, was „richtig" heißt. Formuliere **bis zu 5 spezifische, aus dem konkreten Input + Projekt abgeleitete** Fragen (keine generischen Floskeln); lass weg, was sich aus dem Input schon eindeutig ergibt. Nutze `AskUserQuestion` mit sinnvollen Optionen (max. 4 Fragen pro Runde). Zielrichtungen, die du auf den realen Input zuschneidest:
- Ziel hinter dem Einbringen (lösen / belegen / hinterfragen / sammeln)?
- Vertrauen / Autorität der Quelle?
- Soll bestehendes Wissen ersetzt, ergänzt oder nur abgeglichen werden?
- Umfang und Tiefe der Einarbeitung?
- Wo im Projekt vermutet der User die Anbindung?

## Schritt 6 — Entscheiden

Auf Basis von Analyse + Relevanz + Antworten genau eine Richtung wählen:
- **Einsortieren** — Input bestätigt/ergänzt das Wissenssystem → Zieldatei(en) und Form bestimmen (neuer Abschnitt, Ergänzung, Notiz, Code). Per `Glob`/`Grep` die richtige Stelle finden, statt zu raten.
- **Infragestellen** — Input widerspricht bestehenden Strukturen/Annahmen glaubwürdig → den Konflikt explizit benennen, statt ihn zu glätten. Vorschlagen, was zu revidieren wäre, mit Begründung.
- **Kein Handlungsbedarf** — nichts Substanzielles fürs Projekt → klar sagen und ohne Änderung stoppen.

Entscheide ehrlich: nicht einarbeiten um des Einarbeitens willen.

## Schritt 7 — Durchführen

Wenn Handlungsbedarf besteht:
- **Synthese statt Copy-Paste** — Input in Sprache und Struktur des Projekts übersetzen, nicht roh einkleben.
- `Edit` für punktuelle Ergänzungen, `Write` nur für neu anzulegende Dateien; Stil der Zieldatei wahren, gültige Inhalte nicht überschreiben.
- Bei größeren Eingriffen oder beim Infragestellen bestehender Strukturen erst kurz den Plan zeigen und Zustimmung holen, bevor du schreibst.

## Abschluss

Melde knapp: Input-Kern in 1-2 Sätzen, die Relevanz-Einschätzung, die getroffene Entscheidung und — falls eingearbeitet — welche Datei(en) wie geändert wurden bzw. welche bestehende Annahme infrage gestellt wurde.
