---
description: Legt im aktuellen Ordner ein neues Projekt an — kurzes Interview, CLAUDE.md auf Projekt-Höhe (Skill claude-md), Zeiger in der Eltern-CLAUDE.md, optional Git/GitHub. Mit --nachruesten für bestehende Ordner ohne CLAUDE.md; mit --einordnen <Name>: <Zweck> erst den richtigen Ort im Ablagebaum klären und den Ordner dann selbst anlegen.
argument-hint: <optional - Zweck in einem Satz, ggf. mit Antworten (Art, Git) | --nachruesten | --einordnen <Name>: <Zweck>>
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(date:*), Bash(mkdir:*), Bash(git rev-parse:*), Bash(git init:*), Bash(git -C:*), Bash(git add:*), Bash(git commit:*), Bash(git branch:*), Bash(gh repo create:*), Bash(gh auth status:*), Read, Write, Edit, AskUserQuestion, Skill
---

Du richtest den **aktuellen Ordner** als Projekt ein: eine CLAUDE.md auf Projekt-Höhe nach Mats'
Verfassung, ein Zeiger in der Eltern-CLAUDE.md, auf Wunsch Git + GitHub. Der Ordner existiert schon —
du legst **keine** Ordner außerhalb an (Ausnahme `--einordnen`, unten). Wie du dir die Lage verschaffst,
entscheidest du: wenige Runden, unabhängige Aufrufe parallel — Ordnerinhalt, eigene CLAUDE.md ja/nein,
Git-Repo ja/nein. Die Ahnen-CLAUDE.md sind schon im Kontext (Claude Code lädt die Kette), nicht neu lesen.

## Modus — fertig, wenn genau einer feststeht

- **CLAUDE.md vorhanden** → nichts anlegen, nichts ändern; sagen, dass `/claude-md` der Wartungsgang
  dafür ist. Ende.
- **Ordner leer** (oder nur `.DS_Store`) → **neu**.
- **Ordner mit Inhalt, ohne CLAUDE.md** → **nachrüsten** (`--nachruesten` oder automatisch): 2–3
  aussagekräftige Dateien (README, Hauptdatei) nur so weit lesen, dass du den Zweck vorschlagen kannst.

## Interview — höchstens ein `AskUserQuestion`

Gefragt wird nur, was weder `$ARGUMENTS` noch die Lage beantworten („kein Git" im Argument ist
beantwortet; ein Ordner unter `3_Studium/<Semester>` ist ein Fach). Offen bleiben können:
- **Zweck** in einem Satz — aus `$ARGUMENTS`; im Modus *nachrüsten* aus dem Inhalt vorschlagen
  (Option „Other" = Freitext).
- **Art:** Software-Repo · Wissens-/Orga-Projekt · Studium-Fach · Persona/Vorlage (→ gehört nicht
  hierher, sondern als Command/Skill nach mats-tools; abbrechen und das sagen).
- **Git:** kein Repo · lokal · GitHub privat · GitHub öffentlich — Empfehlung unter `01_Aktiv` GitHub
  privat, sonst kein Repo.
- **Kinder absehbar?** (mehrere gleichartige Unterordner, in denen je gearbeitet wird) → Höhe
  **Bereich** statt Projekt.

Ist `AskUserQuestion` nicht verfügbar (nicht-interaktive Session): Art aus der Lage, Höhe Projekt,
**kein Git**, fehlender Zweck als `TODO` — und diese Annahmen in der Meldung nennen.

## Was am Ende gilt

- **CLAUDE.md** nach dem Skelett der passenden Höhe aus dem Skill `claude-md` (laden, Betriebsart
  *proaktiv*): Kopfzeile `# CLAUDE.md — <Ordnername> (Projekt)` bzw. `(Bereich)`; Zweck in 2–3 Sätzen;
  **Struktur & Konventionen** nur mit dem, was jetzt entschieden ist — Offenes als `TODO`
  (Software-Repo: Stack/Build/Test), keine erfundenen Features, Formate oder Konventionen;
  **Aktueller Stand (<heutiges Datum>)** „angelegt, leer" bzw. das Vorgefundene; **HIER WEITERMACHEN**
  mit dem ersten konkreten Schritt aus dem Interview. Fertig, wenn `head -1 CLAUDE.md` die Höhe nennt.
- **Zeiger nach oben** nur, wenn die nächste Ahnen-CLAUDE.md einen Kinder-Abschnitt mit Geschwistern
  führt: eine Zeile im vorhandenen Muster (`- \`<Ordner>/\` — <ein Satz Zweck>`) per `Edit`. Sagt der
  Ahne, dass `ls` die Kinder zeigt, **keinen** Zeiger.
- **Git nur auf ausdrückliche Antwort** (Interview oder `$ARGUMENTS`), nie aus der Empfehlung.
  *lokal/GitHub:* `git init -b main`, minimale `.gitignore` (`.DS_Store` plus Stack-Übliches), alles
  committen: `Projekt angelegt: <Ordnername>`. *GitHub:* `gh auth status`, dann
  `gh repo create <Ordnername> --private|--public --source . --push`; öffentlich erst nach der
  Privacy-Prüfung der getrackten Dateien (keine echten Namen Dritter, Adressen, Domains).

## Meldung

Drei Zeilen: Pfad + Höhe, Eltern-Zeiger gesetzt ja/nein, Git (Repo-URL oder „kein Repo"). Dann in
der Session weiterarbeiten — der erste Schritt aus HIER WEITERMACHEN kann sofort losgehen.

## `--einordnen <Name>: <Zweck>` — Ort klären, dann Ordner anlegen

Mats weiß noch nicht, wo das Projekt hingehört; die Session steht in der Wurzel des Ablagesystems.
Die Reihenfolge ist die Regel:
1. Aus der Wurzel-CLAUDE.md (Kinder) und den CLAUDE.md der in Frage kommenden Bereiche (`head -40`)
   2–3 **Kandidaten-Orte** finden: Art des Projekts (Software → `4_Projekte/01_Aktiv`, Wissens-/
   Orga-Projekt → `4_Projekte/02_Persoenlich` oder der Lebensbereich unter `1_Privat`, Studium → das
   Semester), Nachbarn (wo liegen ähnliche Ordner?), Konventionen des Bereichs (Präfix-Nummern,
   Namensmuster).
2. **Ein** `AskUserQuestion`: die Kandidaten als Optionen, je eine Zeile Begründung, der beste zuerst
   mit „(Empfohlen)"; führt der Bereich Präfix-Nummern, der daraus folgende Ordnername (`030_Japan`
   statt `Japan`). „Other" = eigener Pfad.
3. `mkdir -p <absoluter Pfad>`, dann der normale Ablauf im Modus **neu** — durchgehend mit absoluten
   Pfaden (`git -C <Pfad>`, `Write`/`Edit` absolut), denn die Shell bleibt in der Wurzel; nichts dort
   ablegen. Die Ahnen zwischen Wurzel und neuem Ordner sind hier *nicht* geladen — für den Zeiger
   nach oben lesen.

**Danach nicht weiterarbeiten** — alles hier Getane landet im falschen Ordner. Letzte Zeile, fett und
für sich:
**Fertig — ⌘N, `<Ordnername>` im Baum wählen, ⏎ für die erste richtige Session. Diese hier kannst du
schließen.**
