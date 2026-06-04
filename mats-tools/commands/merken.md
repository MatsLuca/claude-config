---
description: Hält den aktuellen Stand dieser Session in CLAUDE.md / projektrelevanten Kontextdateien fest, damit du das Fenster schließen kannst, ohne Kontext zu verlieren.
allowed-tools: Bash(ls:*), Bash(git status:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Read, Edit, Write
---

Du hältst den aktuellen Arbeitsstand fest, damit der aktive Chat verlassen werden kann, ohne dass Kontext verloren geht. Das ist **kein** Programmier-/Git-Abschluss (dafür gibt es `/finish`) — hier geht es darum, **Wissen und Stand in Kontextdateien zu sichern**, in beliebigen Umgebungen (Studium, Notizen, Recherche, Schreibprojekte, Code).

**Arbeite token-effizient: erst billige Übersicht, dann gezielt schreiben.**

## Schritt 1 — Lage in EINEM Aufruf erfassen

```bash
echo "=== ORDNER ===" && pwd && \
echo "=== MARKDOWN & KONTEXT ===" && ls -1 *.md *.markdown 2>/dev/null || echo "(keine .md im Root)" && \
echo "=== CLAUDE.md? ===" && ls CLAUDE.md 2>/dev/null && echo "JA" || echo "NEIN" && \
echo "=== GIT? ===" && git rev-parse --is-inside-work-tree 2>/dev/null && git branch --show-current 2>/dev/null || echo "KEIN_REPO"
```

## Schritt 2 — Verstehen, was in dieser Session passierte

Geh den bisherigen Chatverlauf gedanklich durch und destilliere **nur das, was für ein Weitermachen morgen wirklich zählt**:
- **Was wurde getan / entschieden** (Ergebnisse, Festlegungen, verworfene Wege inkl. Grund).
- **Was ist offen** — der nächste konkrete Schritt, offene Fragen, Blocker.
- **Wichtiger Kontext**, der sonst verloren ginge (Fundstellen, Annahmen, Zwischenergebnisse, Links/Dateipfade).

Halte es knapp und handlungsorientiert. Kein Verlaufsprotokoll — der Future-Du soll in 30 Sekunden wieder drin sein. Lass Triviales weg.

## Schritt 3 — Zieldatei(en) bestimmen

- **`CLAUDE.md` existiert** → sie ist immer ein Ziel. Aktualisiere/ergänze sie. Wenn es schon einen Stand-/Status-/„Aktueller Stand"-Abschnitt gibt, pflege diesen; sonst ergänze einen klar benannten Abschnitt am Ende (z.B. `## Aktueller Stand (<heutiges Datum>)`).
- **Weitere projektrelevante Dateien** (meist Markdown): Wenn Inhalt thematisch klar woanders hingehört (z.B. eine `NOTES.md`, `STATUS.md`, ein Themen-Markdown, eine Mitschrift), aktualisiere zusätzlich gezielt **diese** Datei. Lies große Dateien gezielt in den betroffenen Abschnitten, nicht komplett.
- **Keine CLAUDE.md, kein passendes Ziel** → schlage dem User eine Datei vor (i.d.R. `CLAUDE.md` für ein Arbeitsverzeichnis, sonst eine themenpassende `*.md`) und lege sie nach kurzer Bestätigung an.

Bei Unsicherheit, welche Datei wohin: kurz beim User rückfragen, statt zu raten.

## Schritt 4 — Schreiben

- Nutze `Edit` für punktuelle Ergänzungen in bestehenden Dateien, `Write` nur für neu anzulegende.
- **Passe dich an Stil und Struktur der jeweiligen Datei an** (Überschriftenebenen, Sprache, Ton). Schreibe nicht über bestehende, noch gültige Inhalte — ergänze oder aktualisiere veraltete Stellen.
- Datiere den Stand-Abschnitt mit dem heutigen Datum, wenn die Datei mit Daten arbeitet.
- Markiere offene Punkte klar (z.B. als Checkliste `- [ ]`), damit der nächste Einstieg sofort sichtbar ist.

## Schritt 5 — Git nur anbieten (nicht automatisch)

- **`KEIN_REPO`** → überspringen.
- **Repo erkannt** → committe **nicht** ungefragt. Biete am Ende kurz an: „Soll ich die Doku-Änderung committen (und pushen)?" Erst auf Zustimmung:

```bash
git add -A && git commit -m "docs: Stand festgehalten (/merken)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>" && git push
```

(Wenn der User nur committen, nicht pushen will, das `&& git push` weglassen.)

## Abschluss

Melde knapp:
- Welche Datei(en) aktualisiert/angelegt wurden.
- 2-3 Stichpunkte: was festgehalten wurde und was als nächster Schritt notiert ist.

Damit ist der Stand gesichert — das Fenster kann gefahrlos geschlossen werden.
