# Verfassung für CLAUDE.md-Dateien

Der verbindliche Maßstab für jede `CLAUDE.md` in Mats' Ablagesystem (`~/Documents`,
PARA-Ordner) und für `~/.claude/CLAUDE.md`. Genutzt vom Skill `claude-md` als
Prüfgrundlage; `/merken`, `/destillieren`, `/einarbeiten` laden den Skill, wenn sie
eine CLAUDE.md anlegen oder umbauen.

Nicht verwechseln mit dem *Verfassungs-Teil eines Systems* (Zweck & Konventionen,
den `/merken` pflegt): der ist ein **Abschnitt in** einer Projekt-CLAUDE.md — diese
Datei hier sagt, welche CLAUDE.md welche Abschnitte überhaupt haben darf.

## Inhalt
- Das Prinzip (Lademechanik)
- Die drei Höhen
- Verbindende Regeln
- Skelette
- Sonderfälle
- Meta-Pflege
- Prüf-Checkliste

---

## Das Prinzip

Claude Code lädt beim Session-Start die **gesamte Ahnenkette** — `~/.claude/CLAUDE.md`,
dann jede CLAUDE.md von `~/Documents` abwärts bis zum cwd. CLAUDE.md in *Unter*ordnern
kommen erst lazy dazu, wenn dort Dateien gelesen werden.

Daraus folgt alles Weitere: **Je höher, desto billiger und stabiler; je tiefer, desto
reicher und volatiler.** Eine obere Ebene wird in jeder Session darunter mitbezahlt und
fast nie als cwd geöffnet — sie darf deshalb nichts enthalten, das veralten kann.
Status, Fakten und Historie leben ausschließlich dort, wo gearbeitet wird: im Projekt.

## Die drei Höhen

Jede CLAUDE.md ist genau **eine** davon und sagt es in ihrer ersten Zeile
(siehe Kopfzeile unten).

| | **Router** | **Bereich** | **Projekt** |
|---|---|---|---|
| **Wo** | `~/.claude` (Maschine), `Documents`, `4_Projekte`, `3_Studium` | `1_Privat`, ein Semester, `Hetzner_Server` — Ordner mit gleichartigen Kindern | Referenzprojekt, LatexTerm, ein Fach — hier wird gearbeitet |
| **Job** | Karte der Kinder (eine Zeile Zweck je Kind) + Konventionen, die für den ganzen Teilbaum gelten + der Satz „hier oben: Allgemeines; für Details runter nach X" | Arbeitsmuster, die für *alle* Kinder gelten + Kinderliste mit je einer Zeile Zweck | Zweck, Konventionen (Verfassungs-Teil), **Status-Dashboard mit Zeigern**, „HIER WEITERMACHEN" |
| **Nicht-Job** | Fakten, Status, Historie, Verhaltensskripte, Befund-Protokolle | Projektstatus, „Aktueller Stand"-Blöcke, Technik-Details eines Kindes | Erledigt-Verläufe (→ `HISTORIE.md`), Vollreferenz (→ READMEs), Medien-Dumps |
| **Budget** | ≤ 2 KB (`~/.claude`: ≤ 4 KB) | ≤ 4 KB | kein Limit — aber *verdichtet*: **ein** datierter Stand-Block, jeder Punkt Stand + Zeiger; ältere Stände sind Verlauf → `HISTORIE.md` |
| **Pflege** | nur bei Strukturänderung | bei neuem Kind / neuem Muster | `/merken` nach Sessions, `/destillieren` bei Wucherung |

**Maschine** (`~/.claude/CLAUDE.md`) ist ein Router mit Sonderbudget: pro Thema 1–3 Zeilen
*Verhaltensregel* + Pfad nach `~/.claude/reference/<thema>.md`, wo das Protokoll liegt.
Verhaltensregel = ändert, was Claude tut („nie Mail.app per AppleScript", „Browser nur auf
Aufforderung", „Standort über Skill X") — auch die Werkzeugwahl zählt; alles andere ist Referenz.

**Höhe bestimmen:** Hat der Ordner gleichartige Kinder mit je eigener CLAUDE.md/README und
wird selbst selten als cwd geöffnet → Router oder Bereich (Bereich, wenn es gemeinsame
Arbeitsmuster gibt; sonst Router). Wird hier gearbeitet → Projekt. Ein Ordner ohne
CLAUDE.md ist okay, wenn der nächsthöhere Router seine Kinder schon nennt — **keine Datei
aus Vollständigkeit**.

## Verbindende Regeln

- **Abwärts-Zeiger.** Jede Ebene nennt ihre Kinder mit einer Zeile Zweck. Sonst weiß eine
  Session oben nicht, dass unten mehr ist. Zeiger nur auf Dateien, die existieren.
- **Aufwärts-Vertrauen.** Keine Ebene wiederholt Regeln der Eltern — die sind ohnehin
  geladen. Eine Projekt-CLAUDE.md erklärt nicht das PARA-Schema.
- **Eine Quelle pro Fakt.** Ein Fakt steht im Projekt (oder dessen README) und wird
  höher nur referenziert, nie kopiert.
- **Kopfzeile.** Erste Zeile: `# CLAUDE.md — <Ordnername> (<Router|Bereich|Projekt>)`.
  Macht Höhe und Prüfung per Grep trivial.
- **Kein Datum auf Router/Bereich.** Ein „Stand 22.08." ist ein Versprechen, das dort
  niemand einlöst. Datierte Abschnitte nur im Projekt.
- **Höhen-Check beim Schreiben.** Wer Inhalt in eine CLAUDE.md schreibt, prüft: passt er
  zur Höhe? Sonst eine Ebene tiefer ablegen (Kind-CLAUDE.md oder README) und oben
  höchstens einen Zeiger lassen.
- **Verlauf wandert 1:1, Regeln steigen auf.** Datierte Alt-Stände gehen unverändert nach
  `HISTORIE.md` — vorher die dort vergrabenen zeitlosen Konventionen und Fallen (Build-Fallen,
  Verifikations-Workflow, Modell-Konvention) herausziehen und in den Verfassungs-Teil heben.
  Gekürzt wird erst, wenn das Ziel den Inhalt belegt trägt (diff/Zeilenabgleich); was keinen
  Zweitbeleg hat, wird vorher gesichert, nie gelöscht.

## Skelette

**Router**
```markdown
# CLAUDE.md — 4_Projekte (Router)

Ein Satz, was dieser Teilbaum ist. Hier oben werden Allgemeines und Querschnitt besprochen;
für Projektarbeit in den Kind-Ordner wechseln — dessen CLAUDE.md ist dort maßgeblich.

## Kinder
- `01_Aktiv/` — Software-Projekte, je eigenes Git-Repo + CLAUDE.md
- `02_Persoenlich/` — Wissensprojekte (Orga, Server, Geld), meist ohne Git

## Konventionen für den ganzen Teilbaum
- (nur was für *alle* Kinder gilt, z. B. Namensschema)
```

**Bereich**
```markdown
# CLAUDE.md — 1_Privat (Bereich)

Ein Satz, was dieser Bereich ist.

## Kinder
- `02_Reisen/JAPAN_2026/` — Reiseplanung, eigene CLAUDE.md
- `05_Digitales/` — Gmail-Konten & digitale Ordnung, README dort

## Arbeitsmuster (gilt in jedem Kind)
- (Muster, die ein Kind nicht selbst erklären soll: Vorgangsordner `<Thema>_<YYYY-MM>/`,
  README je Vorgang, Belege-Unterordner …)
```

**Projekt**
```markdown
# CLAUDE.md — Steuer_2026 (Projekt)

Zweck in 2–3 Sätzen.

## Struktur & Konventionen
(Verfassungs-Teil: welcher Ordner wofür, Namensschema, wo Historie/Masterplan liegen —
langsam veränderlich, steht vorn)

## Aktueller Stand (<Datum>)
(Dashboard: pro Thema 1–3 Zeilen *Stand* + Zeiger auf README/HISTORIE — kein Verlauf)

## HIER WEITERMACHEN
- [ ] nächster konkreter Schritt
```

## Sonderfälle

- **Finder-Sync mit Gemini** (`GEMINI.md` daneben): Claude Code lädt nur `CLAUDE.md`.
  Abschnitte „Wenn du Gemini bist" gehören nach `GEMINI.md`; gemeinsam genutzter Inhalt
  (Status, Struktur) in eine neutrale Datei (`README.md`, `MASTERPLAN.md`), auf die beide
  zeigen. Kein `# GEMINI Context`-Header in einer CLAUDE.md. Ist `GEMINI.md` ein Symlink
  auf `CLAUDE.md`, gilt die CLAUDE.md für beide — kein Konflikt, nichts aufzuteilen.
- **Include-Einzeiler** (`@AGENTS.md`): eine CLAUDE.md, die nur aus einer `@`-Zeile besteht,
  ist kein Zombie, sondern ein Include — bleibt, Höhe ist die der eingebundenen Datei.
- **Software-Repo** (`4_Projekte/01_Aktiv/*`): Projekt-Höhe; Stack/Build/Test-Teil darf
  länger sein — das ist Konvention, kein Status. Feature-Verlauf ins `CHANGELOG`/Git;
  Debug-Funde und Entscheidungen, die dort nicht stehen, nach `HISTORIE.md`. Bei **zwei
  Autoren** (geteiltes Repo, fremdes Tooling): Kopfzeile setzen, die fremde Kennzeile als
  zweite Zeile behalten, Format-Eigenheiten (BOM, Abschnittsnamen) nicht stillschweigend kippen.
- **Verhaltens-Personas** (Lern-Coach, Autopilot): gehören nicht in eine CLAUDE.md —
  als Command/Skill nach mats-tools, die CLAUDE.md verweist darauf; wird die Persona nicht
  mehr gebraucht, reicht Archivieren (`_Archiv_<Name>_<YYYY-MM>.md` im Ordner, Zeiger bleibt).
- **Beendetes Projekt, Ordner bleibt Datenquelle** (Reise vorbei, App liest weiter daraus):
  Projekt-Höhe bleibt, Stand „beendet (<Datum>)" mit nur noch lebenden Punkten (Nachzahlungen,
  Fristen, Build-Pipeline); ob es nach `8_Archive/` umzieht, ist Mats' Entscheidung und steht
  unter HIER WEITERMACHEN.
- **Archiv** (`8_Archive`, `_Archiv_`-Präfix): keine CLAUDE.md nötig; eine vorhandene
  wird nicht gepflegt.

## Meta-Pflege

Diese Verfassung ist selbst optimierbar (`/optimieren claude-md`). Prüfgrundlage ist dann
nicht sie selbst, sondern: erfüllt sie ihren Zweck — bleiben Router/Bereiche unter Budget,
wandert Status nicht wieder nach oben, stimmt die Lademechanik noch mit Claude Code überein?
Ändert sich die Lademechanik (z. B. Unterordner-CLAUDE.md nicht mehr lazy), ist das ein
Befund für den Prinzip-Abschnitt, nicht stillschweigend wegzuadaptieren.

## Prüf-Checkliste

- [ ] Kopfzeile nennt Höhe; Höhe passt zur Rolle des Ordners.
- [ ] Budget eingehalten (Router ≤ 2 KB, Maschine ≤ 4 KB, Bereich ≤ 4 KB).
- [ ] Router/Bereich: kein Datum, kein Status, keine Fakten, die veralten können.
- [ ] Kinderliste vollständig; jeder Zeiger trifft eine existierende Datei.
- [ ] Nichts wiederholt, was eine Eltern-Ebene schon sagt.
- [ ] Projekt: Verfassungs-Teil vorn, genau ein datierter Stand, Stand-Punkte = Stand + Zeiger, kein Verlauf.
- [ ] Beim Schnitt: Ziel trägt den Inhalt belegt; zeitlose Regeln aus dem Verlauf stehen vorn.
- [ ] Kein Gemini-Header, keine Persona-Skripte, kein Befund-Protokoll (→ `reference/`).
