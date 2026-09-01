# claude-config

> **Ein Werkzeugkasten für die Arbeit mit Claude, der sich durch die Arbeit mit ihm selbst schärft.**

![Platform](https://img.shields.io/badge/platform-macOS%20·%20Linux%20·%20Windows-blue)
![Plugin](https://img.shields.io/badge/plugin-mats--tools-8A2BE2)
![Updates](https://img.shields.io/badge/updates-automatisch%20per%20git%20SHA-success)
[![validate](https://github.com/MatsLuca/claude-config/actions/workflows/validate.yml/badge.svg)](https://github.com/MatsLuca/claude-config/actions/workflows/validate.yml)

Ein persönlicher **Claude-Code-Marketplace** mit einem Plugin, `mats-tools`: die Werkzeuge
(Commands, Agents, Skills) *und* der Loop, der sie besser macht — `/optimieren` schärft jeden
Baustein gegen einen Authoring-Standard und Outcome-Evals, `/neudenken` stellt bei jedem neuen
Modell die Prämissen infrage. Per git-SHA versioniert, auf jedem Rechner identisch: neuer Laptop,
Codespace oder Container — ein Befehl, und die Werkbank ist da.

---

## 🚀 Installieren

Ein Befehl pro Plattform — installiert Claude Code (falls nötig), registriert den
Marketplace und installiert `mats-tools` (user-scope, idempotent — mehrfach
ausführen schadet nicht).

### 🍎 macOS / 🐧 Linux

```bash
curl -fsSL https://raw.githubusercontent.com/MatsLuca/claude-config/master/bootstrap.sh | bash
```

### 🪟 Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/MatsLuca/claude-config/master/bootstrap.ps1 | iex
```

> [!IMPORTANT]
> ### 👉 NÄCHSTER SCHRITT
> **`claude` starten (beim ersten Mal einloggen) — und als ersten Prompt schicken:**
>
> ```text
> Führe das machine-setup durch.
> ```
>
> Der `machine-setup`-Agent richtet dann alles ein: `yolo`-Alias, Status Line,
> Plugin-Auto-Update beim Start und die settings.json-Defaults.

<details>
<summary><strong>🔧 Manuell — Fallback</strong> (direkt aus einer laufenden Claude-Session)</summary>

<br>

```bash
/plugin marketplace add MatsLuca/claude-config   # Marketplace registrieren (einmalig pro Rechner)
/plugin install mats-tools@claude-config         # Plugin installieren
```

*(Im Terminal statt in der Session: dieselben Befehle als `claude plugin marketplace add …` / `claude plugin install …`.)*

</details>

---

## 🧰 Was drin ist

Ein Plugin, `mats-tools` — Commands für den Alltag, Agents für die schwere Arbeit. Commands sind
technisch Skills als flache Datei; Claude darf sie auch selbst starten, außer `/finish` und
`/finish-lite` (`disable-model-invocation`) — die laufen nur, wenn du sie tippst:

### ⚡ Commands

| Command | Zweck |
|---|---|
| `/finish` | Änderungen seit letztem Push analysieren, README/CHANGELOG & zugehörige GitHub-Issues pflegen, committen & pushen — in einem Rutsch |
| `/finish-lite` | Leichter /finish für Wissensprojekte: committen mit Zeitstempel-Message, auf den Default-Branch rebasen & dorthin pushen — ohne Analyse & Doku-Pflege; identisch auf Laptop und in Cloud-Sessions (Session-Branch landet direkt auf main) |
| `/github-pushes` | Eigene GitHub-Pushes in einem Zeitraum strukturiert anzeigen |
| `/neues-projekt` | Aktuellen Ordner als Projekt einrichten: kurzes Interview, CLAUDE.md auf Projekt-Höhe, Zeiger in der Eltern-CLAUDE.md, optional Git/GitHub; `--nachruesten` für bestehende Ordner ohne CLAUDE.md; `--einordnen <Name>: <Zweck>` klärt erst den Ort im Ablagebaum (2–3 Kandidaten mit Begründung) und legt den Ordner dann selbst an |
| `/merken` | Session-Stand in CLAUDE.md / Kontextdateien festhalten — erntet dabei Zweck & gewachsene Konventionen des Wissenssystems |
| `/xcode` | Xcode-Projekt aus dem aktuellen Verzeichnis öffnen |
| `/wrapped` | Aus der lokalen Claude-Code-Nutzung eines Zeitraums ein teilbares „Wrapped"-PNG bauen (Tokens, API-Gegenwert, Limit-Auslastung, Nachtschicht) und in die Zwischenablage legen |
| `/optimieren` | Einen Command, Agent oder Skill nach dem Authoring-Standard schärfen |
| `/einarbeiten` | Beliebigen Input (Text/Datei/URL) semantisch analysieren, Projekt-Relevanz prüfen und ins Wissenssystem einarbeiten — oder bestehende Strukturen begründet infrage stellen |
| `/destillieren` | Gewachsenes Wissenssystem pflegen: Drift (veraltete/widersprüchliche Querverweise) heilen, dann Redundanz verdichten & Ordnerstrukturen neu denken — strukturelle Eingriffe erst nach Plan-Zustimmung |
| `/neudenken` | Ein digitales System vom Zweck her neu denken: Ziele belegt rekonstruieren, Prämissen mit vollem Urteil hinterfragen und einschätzen, ob und wie tief sich ein Umbau lohnt — ohne selbst umzusetzen |

### 🤖 Agents

| Agent | Zweck |
|---|---|
| `pdf-to-markdown` | Beliebige PDFs in LLM-optimiertes Markdown konvertieren — erkennt Klausur / Folien / generisch und wählt die passende Struktur |
| `machine-setup` | Frische Claude-Code-Installation einrichten wie zuhause — führt `shell/setup.sh` aus (`yolo`-Alias, Auto-Update-Wrapper, Status Line, settings.json-Defaults; VS Code in Codespaces; PowerShell-Profil auf Windows) und kümmert sich nur um das, was Urteil braucht: fremde Wrapper, angepasste Dateien, Terminal-Rendering. Idempotent, portabel |

### 🧩 Skills

| Skill | Zweck |
|---|---|
| `latexterm` | LatexTerm-Terminal von innen steuern (Kacheln auflisten/öffnen, Befehle/Prompts in andere Kacheln schicken, zoomen, fokussieren) — lädt sich von selbst, sobald es ums Terminal geht (Kachel, Pane, Split, zweite Session, „was kannst du mit dem Terminal"); auf Rechnern ohne LatexTerm inaktiv |
| `claude-md` | Hält CLAUDE.md-Dateien auf der richtigen Höhe — Router / Bereich / Projekt nach der Verfassung in `skills/claude-md/verfassung.md`: prüft eine Datei oder inventarisiert einen Teilbaum, verschiebt Ballast nach unten, ergänzt Zeiger; lädt sich von selbst, sobald eine CLAUDE.md angelegt oder umgebaut wird |

Der Authoring-Standard und die Eval-Szenarien, gegen die `/optimieren` prüft,
liegen in `mats-tools/reference/` (`authoring-guide.md`, `evals.md`).


---

## 🔁 Der Loop

Der Kasten verbessert sich durch die Arbeit mit sich selbst:

- **Bauen:** Was Konten oder Maschinenzustand braucht, entsteht in der privaten Werkstatt (Symlink
  nach `~/.claude/skills`); hierher gehört, was ohne beides läuft und auch für andere nützlich ist —
  Code inklusive (`/wrapped`).
- **Schärfen:** `/optimieren <baustein>` prüft gegen den Authoring-Standard
  (`mats-tools/reference/authoring-guide.md`) und die Outcome-Evals (`reference/evals.md`) —
  die beschreiben *beobachtbares Verhalten*, nie Implementierung, damit eine bessere
  Umsetzung nie an alten Details scheitert. Seit Claude 5 gilt **Auftrag vor Rezept**: ein
  Baustein nennt Outcome und Regeln, den Weg findet das Modell; wörtliche Bash-Blöcke nur, wo
  ein Eval zeigt, dass es ohne sie scheitert. `tools/eval.sh` lässt Szenarien headless im
  Wegwerf-Fixture laufen und prüft das Ergebnis auf der Platte.
- **Neu denken:** Neues Modell, neue Claude-Code-Fähigkeit → `/neudenken` über den Kasten.
- **Absichern:** `tools/validate.sh` (lokal + GitHub Action bei jedem Push) prüft Manifeste,
  Frontmatter, README-Listing, Eval-Abdeckung, Plugin-Referenzen, Portabilität (BSD↔GNU),
  lässt `shell/setup.sh` real in einem Sandbox-HOME laufen und ruft lokal das native
  `claude plugin validate` dazu.

---

## 🔄 Updates

Das Plugin hat bewusst **keine feste Versionsnummer** in `plugin.json`. Dadurch nutzt
Claude Code den Git-Commit-SHA als Version: **jeder Push hierhin** wird beim nächsten
`/plugin update` automatisch übernommen — kein manuelles Versions-Bumping nötig.

Nach dem `machine-setup` passiert das sogar von selbst: der Agent installiert einen
Shell-Wrapper, der das Plugin **im Hintergrund aktualisiert** (`shell/sync.sh`, höchstens alle
10 Minuten) — der Start wartet nicht aufs Netz, das Update wirkt ab der nächsten Session. Wer es
*jetzt* braucht (z. B. direkt nach einem Push): `frisch` = synchron syncen, dann `yolo`.
Manuell braucht es nur, falls der Wrapper (noch) nicht eingerichtet ist:

```bash
/plugin update mats-tools@claude-config
```

---

## 📣 News an alle Abonnenten

Wer das Plugin installiert hat, zieht es bei jedem Start. Das ist auch ein Nachrichtenkanal:
ein neuer Eintrag oben in `mats-tools/NEWS.md` (`## <Datum> · <Titel>` + kurzer Text) wird
beim nächsten Session-Start **einmal** im Terminal angezeigt und Claude als Kontext mitgegeben.
Ein Block `<!-- claude: … -->` (unsichtbar im Terminal) ist ein Hinweis an Claude — etwa wie man
einen neuen Skill benutzt —, nie ein Auftrag: nichts wird von selbst umgebaut. Gelesenes merkt
sich `~/.claude/mats-tools-news-seen`; `hooks/news.sh --reset` zeigt alles erneut, `--peek`
zeigt ohne zu markieren, `--context` zeigt, was Claude bekommt.

## ⏱ Start-Timer

Jeder Start wird still gemessen (Terminal-Zeile `⏱ Start 2,1 s (ab Tastendruck) · Kachel→Shell 0,3 ·
Shell-rc 0,2 · Wrapper 0,2 · Claude Code 1,4` nur mit `MATS_START_TIMER_SHOW=1`). Die Stempel setzt die Startkette (`machine-setup`:
Zeile 1 der rc-Datei = `MATS_T_RC`, der Wrapper = `MATS_T_WRAP`/`MATS_T_EXEC`; eine Oberfläche kann
`MATS_START_T0=<ms>` vor `claude` stellen), der SessionStart-Hook `hooks/start-timer.sh` rechnet
und protokolliert jeden Start ms-genau nach `~/.cache/mats-tools/start-timer.log`
(`start-timer.sh --tail`). Ohne Wrapper-Stempel bleibt der Hook still.

## 🗂️ Struktur

```
claude-config/
├── bootstrap.sh                  # Einzeiler-Setup für neue Rechner (macOS/Linux)
├── bootstrap.ps1                 # Einzeiler-Setup für neue Rechner (Windows)
├── tools/
│   ├── validate.sh               # strukturelle Verifikation (lokal + CI)
│   └── eval.sh                   # Verhaltens-Evals headless im Fixture (echte Tokens, nicht in CI)
├── .github/workflows/
│   └── validate.yml              # führt validate.sh bei jedem Push/PR aus
├── .claude-plugin/
│   └── marketplace.json          # Marketplace-Manifest
└── mats-tools/                   # das Plugin
    ├── .claude-plugin/
    │   └── plugin.json           # Plugin-Manifest
    ├── commands/                 # Slash-Commands = Skills als flache Datei (*.md)
    ├── agents/                   # Subagents (*.md)
    ├── skills/                   # Skills (latexterm, claude-md + dessen Verfassung)
    ├── hooks/                    # SessionStart-Hooks: Start-Timer (Dauer je Phase → Terminal + ~/.cache/mats-tools/start-timer.log) und NEWS.md-Einträge einmal zeigen
    ├── shell/start.sh            # Startzeile des claude()-Wrappers, ohne Netz (ändert sich per Plugin-Update; der Wrapper bleibt dünn)
    ├── shell/sync.sh             # Hintergrund-Sync: Plugin-Update + Klone aus ~/.config/mats-tools/sync-repos; --now (frisch), --after-push (/finish)
    ├── shell/setup.sh            # der Installer hinter machine-setup: Wrapper-Block, Status Line, settings.json, VS Code — idempotent, im Validator sandbox-getestet
    ├── NEWS.md                   # Nachrichten an alle Abonnenten (neuester Eintrag oben)
    ├── statusline/               # vendored Status-Line-Skript (vom machine-setup Agent installiert)
    └── reference/                # Authoring-Standard + Eval-Szenarien
```
