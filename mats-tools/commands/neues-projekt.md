---
description: Legt im aktuellen Ordner ein neues Projekt an — kurzes Interview, CLAUDE.md auf Projekt-Höhe (Skill claude-md), Zeiger in der Eltern-CLAUDE.md, optional Git/GitHub. Mit --nachruesten für bestehende Ordner ohne CLAUDE.md; mit --einordnen <Name>: <Zweck> erst den richtigen Ort im Ablagebaum klären und den Ordner dann selbst anlegen.
argument-hint: <optional - Zweck in einem Satz | --nachruesten | --einordnen <Name>: <Zweck>>
allowed-tools: Bash(pwd:*), Bash(cd:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(date:*), Bash(mkdir:*), Bash(git rev-parse:*), Bash(git init:*), Bash(git -C:*), Bash(git add:*), Bash(git commit:*), Bash(git branch:*), Bash(gh repo create:*), Bash(gh auth status:*), Read, Write, Edit, AskUserQuestion, Skill
---

Du richtest den **aktuellen Ordner** als Projekt ein: eine CLAUDE.md auf Projekt-Höhe nach Mats'
Verfassung, ein Zeiger in der Eltern-CLAUDE.md, auf Wunsch Git + GitHub. Der Ordner existiert schon
(der Launcher `start` oder Mats hat ihn angelegt) — du legst **keine** Ordner außerhalb an.

**Ausnahme `--einordnen`** (`$ARGUMENTS` beginnt mit `--einordnen <Name>: <Zweck>`): Mats weiß noch
nicht, wo das Projekt hingehört. Du stehst dann in der Wurzel des Ablagesystems und gehst zuerst
durch **Schritt 0**; erst danach beginnt der normale Ablauf — im dann angelegten Ordner, mit
absoluten Pfaden, denn die Shell bleibt in der Wurzel.

## Schritt 0 — Einordnen (nur `--einordnen`)

1. Lies die CLAUDE.md der Wurzel (Kinder-Abschnitt) und die der in Frage kommenden Bereiche eine
   Ebene tiefer (`head -40`), so weit nötig, um 2–3 **Kandidaten-Orte** zu finden. Kriterien: Art
   des Projekts (Software → `4_Projekte/01_Aktiv`, Wissens-/Orga-Projekt → `4_Projekte/02_Persoenlich`
   oder der Lebensbereich unter `1_Privat`, Studium → das Semester), Nachbarn (wo liegen ähnliche
   Ordner?), Konventionen des Bereichs (Präfix-Nummern, Namensmuster).
2. **Ein** `AskUserQuestion`: die Kandidaten als Optionen, je eine Zeile Begründung, der beste zuerst
   und mit „(Empfohlen)"; dazu, falls der Bereich Präfix-Nummern führt, der daraus folgende
   Ordnername (`030_Japan` statt `Japan`). Option „Other" = eigener Pfad.
3. Ordner anlegen: `mkdir -p <absoluter Pfad>`; leer lassen — dann weiter mit Schritt 1 im Modus
   **neu**, jedem Bash-Aufruf `cd <absoluter Pfad> && ` vorangestellt (die Shell vergisst das
   Verzeichnis zwischen zwei Aufrufen), `Write`/`Edit` mit absolutem Pfad. Nichts in der Wurzel ablegen.

## Schritt 1 — Lage in EINEM Aufruf

```bash
echo "=== ORDNER ===" && pwd && \
echo "=== INHALT ===" && ls -1A | head -40 && \
echo "=== EIGENE CLAUDE.md ===" && (head -1 CLAUDE.md 2>/dev/null || echo "KEINE") && \
echo "=== AHNEN (Kopfzeile + Kinder-Abschnitt) ===" && d="$(pwd)"; while [ "$d" != "$HOME" ] && [ "$d" != "/" ]; do d="$(dirname "$d")"; [ -f "$d/CLAUDE.md" ] && { echo "--- $d"; head -1 "$d/CLAUDE.md"; awk '/^## Kinder/{p=1;next} /^## /{p=0} p' "$d/CLAUDE.md"; }; done; \
echo "=== GIT ===" && (git rev-parse --is-inside-work-tree 2>/dev/null || echo "KEIN_REPO")
```

Modus bestimmen — fertig ist der Schritt, wenn genau einer feststeht:
- **CLAUDE.md vorhanden** → nichts anlegen; sagen, dass `/claude-md` der Wartungsgang dafür ist. Ende.
- **Ordner leer** (oder nur `.DS_Store`) → Modus **neu**.
- **Ordner mit Inhalt, ohne CLAUDE.md** → Modus **nachrüsten** (`--nachruesten` in `$ARGUMENTS` oder
  automatisch). Lies 2–3 aussagekräftige Dateien (README, Hauptdatei) nur so weit, dass du den Zweck
  formulieren kannst.

## Schritt 2 — Interview (ein `AskUserQuestion`-Aufruf)

Der Zweck-Satz kommt aus `$ARGUMENTS`; fehlt er, im Modus *nachrüsten* aus dem Inhalt vorschlagen,
sonst als erste Frage stellen (Option „Other" = Freitext). Dazu, soweit nicht aus der Lage offensichtlich:

1. **Art:** Software-Repo · Wissens-/Orga-Projekt · Studium-Fach · Persona/Vorlage (→ gehört nicht
   hierher, sondern als Command/Skill nach mats-tools; abbrechen und das sagen).
2. **Git:** kein Repo · lokal · GitHub privat · GitHub öffentlich (Default: unter `01_Aktiv` GitHub
   privat, sonst kein Repo).
3. **Kinder absehbar?** (mehrere gleichartige Unterordner, in denen je gearbeitet wird) → dann ist die
   Höhe **Bereich**, nicht Projekt.

Nicht fragen, was die Lage schon beantwortet (Studium-Ordner unter `3_Studium/<Semester>` ist ein Fach).

## Schritt 3 — CLAUDE.md schreiben

Lade den Skill `claude-md` (Betriebsart *proaktiv*) und nimm das Skelett der passenden Höhe aus seiner
`verfassung.md`. Pflicht:
- Kopfzeile `# CLAUDE.md — <Ordnername> (Projekt)` (bzw. `(Bereich)`).
- Zweck in 2–3 Sätzen aus dem Interview; **Struktur & Konventionen** nur mit dem, was jetzt schon
  entschieden ist (Software-Repo: Stack/Build/Test-Platzhalter mit `TODO`, kein erfundener Stack);
  **Aktueller Stand (<`date +%F`>)**: „angelegt, leer" bzw. was beim Nachrüsten vorgefunden wurde;
  **HIER WEITERMACHEN** mit dem ersten konkreten Schritt aus dem Interview.
- Nichts wiederholen, was Ahnen-CLAUDE.md schon sagen (Aufwärts-Vertrauen). Ziel < 2 KB.

Fertig, wenn die Datei steht und `head -1 CLAUDE.md` die Höhe nennt.

## Schritt 4 — Zeiger nach oben

Nur wenn die nächste Ahnen-CLAUDE.md einen **Kinder-Abschnitt mit Geschwistern** führt: dort eine Zeile
im vorhandenen Muster ergänzen (`- \`<Ordner>/\` — <ein Satz Zweck>`), per `Edit`. Sagt der Ahne, dass
`ls` die Kinder zeigt (wie `4_Projekte` für `01_Aktiv`/`02_Persoenlich`), **keinen** Zeiger setzen.

## Schritt 5 — Git (nur nach Interview-Antwort)

- *lokal / GitHub:* `git init -b main`, minimale `.gitignore` (`.DS_Store`, plus Stack-Übliches),
  `git add -A && git commit -m "Projekt angelegt: <Ordnername>"`.
- *GitHub:* `gh auth status` prüfen, dann `gh repo create <Ordnername> --private|--public --source . --push`.
  Öffentlich → vorher die Privacy-Regel anwenden: keine echten Namen Dritter, Adressen, Domains in
  getrackten Dateien.

## Schritt 6 — Abschluss

Drei Zeilen: Pfad + Höhe, ob Eltern-Zeiger gesetzt, Git-Status (Repo-URL oder „kein Repo"). Hat der
Ordner noch keinen Shell-Alias, erwähne `hier <name>`. Dann in der Session weiterarbeiten — der erste
Schritt aus HIER WEITERMACHEN kann sofort losgehen.

**Nach `--einordnen` nicht weiterarbeiten** — diese Session steht in der Wurzel, alles hier Getane
landet im falschen Ordner. Letzte Zeile, fett und für sich:
**Fertig — ⌘N, `<Ordnername>` im Baum wählen, ⏎ für die erste richtige Session. Diese hier kannst du
schließen.**
