---
description: Hält den aktuellen Stand dieser Session in CLAUDE.md / projektrelevanten Kontextdateien fest — und erntet dabei Zweck & gewachsene Konventionen des Systems.
allowed-tools: Bash(echo:*), Bash(pwd:*), Bash(ls:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Read, Edit, Write, AskUserQuestion
---

Du hältst den Arbeitsstand dieser Session in den Kontextdateien des Projekts fest, damit der Chat verlassen werden kann, ohne dass Kontext verloren geht — in jeder Umgebung (Studium, Notizen, Recherche, Schreibprojekte, Code). Kein Programmier-/Git-Abschluss, dafür gibt es `/finish`. Erst billige Übersicht (Ordner, Markdown-Dateien, Repo ja/nein), dann gezielt schreiben.

## Was du festhältst

Aus dem Verlauf nur, was für ein Weitermachen morgen zählt — der Future-Du soll in 30 Sekunden wieder drin sein: Ergebnisse und Entscheidungen (auch verworfene Wege mit Grund), der nächste konkrete Schritt, offene Fragen und Blocker, Fundstellen, Pfade und Zwischenergebnisse, die sonst verloren gingen. Kein Verlaufsprotokoll, nichts Triviales.

**Verfassungs-Befunde** getrennt davon: hat die Session sichtbar gemacht oder geändert, *wozu* das System existiert oder *wie* es organisiert ist (welcher Ordner wofür, Namensschema, Verlinkung, Grundsatz-Entscheidungen)? Nur Beobachtetes und Entschiedenes zählt — kein Interview, nichts spekulieren.

## Wohin

- **`CLAUDE.md` existiert** → immer Ziel. Stand in den vorhandenen Stand-/Status-Abschnitt, sonst neu als `## Aktueller Stand (<heutiges Datum>)` am Ende. Verfassungs-Befunde in den Zweck-/Konventions-Teil vorn — ohne Befund bleibt er unangetastet, ein junges System darf eine Ein-Satz-Verfassung haben, nichts erfinden, nichts aufblähen. Genau diese Teile lesen `/einarbeiten` und `/destillieren` später als beabsichtigte Konvention des Systems.
- Gehört Inhalt thematisch klar in eine andere Datei (`NOTES.md`, `STATUS.md`, Themen-Markdown, Mitschrift), dort gezielt ergänzen; große Dateien nur in den betroffenen Abschnitten lesen.
- **Kein passendes Ziel** → eine Datei vorschlagen (für ein Arbeitsverzeichnis i.d.R. `CLAUDE.md`, sonst ein themenpassendes `*.md`) und nach kurzer Bestätigung anlegen. Unsicher, welche Datei wohin → per `AskUserQuestion` fragen, nicht raten.
- **Höhe (Skill `claude-md`):** ist die Ziel-CLAUDE.md laut Kopfzeile oder Rolle des Ordners ein Router oder Bereich (gleichartige Kinder, selten cwd), gehört dort kein Stand hinein — in die CLAUDE.md/README des betroffenen Kindes schreiben, oben höchstens ein Zeiger. Beim Neuanlegen den Skill laden (Höhe + Skelett); fehlt der Projekt-CLAUDE.md die Kopfzeile `# CLAUDE.md — <Ordnername> (Projekt)`, beim Schreiben setzen, sonst nichts umbauen.

## Regeln beim Schreiben

- `Edit` für Bestehendes, `Write` nur für Neues. Stil, Überschriftenebenen, Sprache und Ton der Datei wahren; Gültiges nicht überschreiben, Veraltetes aktualisieren statt duplizieren.
- **Genau ein datierter Stand-Block.** Was du dabei ersetzt, wandert 1:1 nach `HISTORIE.md` im selben Ordner (neueste zuerst; anlegen, falls sie fehlt) — nie als „Vorheriger Stand" in der CLAUDE.md stehen lassen.
- Offenes als Checkliste (`- [ ]`), damit der nächste Einstieg sofort sichtbar ist.
- **Git nur anbieten.** Im Repo nicht ungefragt committen: am Ende kurz anbieten („Soll ich die Doku-Änderung committen (und pushen)?") und erst auf Zustimmung nur die geänderten Dateien committen — Message `docs: Stand festgehalten (/merken)` mit dem Trailer `Co-Authored-By: Claude <noreply@anthropic.com>`; pushen nur, wenn gewünscht. Kein Repo → kein Angebot.

## Meldung

Welche Datei(en) aktualisiert oder angelegt; 2–3 Stichpunkte, was festgehalten ist und was als nächster Schritt notiert steht. Dann kann das Fenster zu.
