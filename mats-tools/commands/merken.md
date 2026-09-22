---
description: Hält den aktuellen Stand dieser Session in CLAUDE.md / projektrelevanten Kontextdateien fest — und erntet dabei Zweck & gewachsene Konventionen des Systems.
argument-hint: <optional: „und pushen" = Zustimmung zu Commit + Push vorab>
allowed-tools: Bash(echo:*), Bash(pwd:*), Bash(ls:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git add:*), Bash(git commit:*), Bash(git pull:*), Bash(git rebase:*), Bash(git push:*), Bash(git branch:*), Bash(sh:*), Read, Edit, Write, AskUserQuestion
---

Du hältst den Arbeitsstand dieser Session in den Kontextdateien des Projekts fest, damit der Chat verlassen werden kann, ohne dass Kontext verloren geht — in jeder Umgebung (Studium, Notizen, Recherche, Schreibprojekte, Code). Kein Programmier-/Git-Abschluss, dafür gibt es `/finish`. Erst billige Übersicht (Ordner, Markdown-Dateien, Repo ja/nein), dann gezielt schreiben.

## Was du festhältst

Aus dem Verlauf nur, was für ein Weitermachen morgen zählt — der Future-Du soll in 30 Sekunden wieder drin sein: Ergebnisse und Entscheidungen (auch verworfene Wege mit Grund), der nächste konkrete Schritt, offene Fragen und Blocker, Fundstellen, Pfade und Zwischenergebnisse, die sonst verloren gingen. Kein Verlaufsprotokoll, nichts Triviales.

**Verfassungs-Befunde** getrennt davon: hat die Session sichtbar gemacht oder geändert, *wozu* das System existiert oder *wie* es organisiert ist (welcher Ordner wofür, Namensschema, Verlinkung, Grundsatz-Entscheidungen)? Nur Beobachtetes und Entschiedenes zählt — kein Interview, nichts spekulieren.

## Wohin

- **`CLAUDE.md` existiert** → immer Ziel. Stand in den vorhandenen Stand-/Status-Abschnitt, sonst neu als `## Aktueller Stand (<heutiges Datum>)` am Ende. Verfassungs-Befunde in den Zweck-/Konventions-Teil vorn — ohne Befund bleibt er unangetastet, ein junges System darf eine Ein-Satz-Verfassung haben, nichts erfinden, nichts aufblähen. Genau diese Teile liest `/destillieren` später als beabsichtigte Konvention des Systems.
- Gehört Inhalt thematisch klar in eine andere Datei (`NOTES.md`, `STATUS.md`, Themen-Markdown, Mitschrift), dort gezielt ergänzen; große Dateien nur in den betroffenen Abschnitten lesen.
- **Kein passendes Ziel** → eine Datei vorschlagen (für ein Arbeitsverzeichnis i.d.R. `CLAUDE.md`, sonst ein themenpassendes `*.md`) und nach kurzer Bestätigung anlegen. Unsicher, welche Datei wohin → per `AskUserQuestion` fragen, nicht raten.
- **Höhe (Skill `claude-md`):** ist die Ziel-CLAUDE.md laut Kopfzeile oder Rolle des Ordners ein Router oder Bereich (gleichartige Kinder, selten cwd), gehört dort kein Stand hinein — in die CLAUDE.md/README des betroffenen Kindes schreiben, oben höchstens ein Zeiger. Beim Neuanlegen den Skill laden (Höhe + Skelett); fehlt der Projekt-CLAUDE.md die Kopfzeile `# CLAUDE.md — <Ordnername> (Projekt)`, beim Schreiben setzen, sonst nichts umbauen.

## Regeln beim Schreiben

- `Edit` für Bestehendes, `Write` nur für Neues. Stil, Überschriftenebenen, Sprache und Ton der Datei wahren; Gültiges nicht überschreiben, Veraltetes aktualisieren statt duplizieren.
- **Genau ein datierter Stand-Block.** Was du dabei ersetzt, wandert 1:1 nach `HISTORIE.md` im selben Ordner (neueste zuerst; anlegen, falls sie fehlt) — nie als „Vorheriger Stand" in der CLAUDE.md stehen lassen.
- Offenes als Checkliste (`- [ ]`), damit der nächste Einstieg sofort sichtbar ist.
- **Git nur mit Zustimmung.** Im Repo nicht ungefragt committen: am Ende kurz anbieten („Soll ich committen und pushen?") — hat die Session auch in anderen Repos Änderungen hinterlassen, diese im selben Satz nennen. Steht die Zustimmung schon im Aufruf (`/merken und pushen`), ohne Rückfrage weiter. Kein Repo → kein Angebot.
- **Auf Zustimmung** nur die Dateien committen, die du geändert hast (bzw. die genannten) — Message `docs: Stand festgehalten (/merken)` mit dem Trailer `Co-Authored-By: Claude <noreply@anthropic.com>`. Pushen heißt: erst `git pull --rebase`, dann `git push`; bei Konflikt `git rebase --abort`, Ursache in einer Zeile, stoppen — Konflikte in Wissensdateien entscheidet Mats; nie `--force`. Danach `sh "${CLAUDE_PLUGIN_ROOT}/shell/sync.sh" --after-push` (zieht nur im Marketplace-Repo von `mats-tools` den Plugin-Cache nach, sonst still).

## Meldung

Welche Datei(en) aktualisiert oder angelegt; 2–3 Stichpunkte, was festgehalten ist und was als nächster Schritt notiert steht; bei Git eine Zeile Commit/Push-Ergebnis. Dann kann das Fenster zu.
