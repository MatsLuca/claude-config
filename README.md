# claude-config

> **Mein Claude Code — auf jedem Rechner identisch.**

![Platform](https://img.shields.io/badge/platform-macOS%20·%20Linux%20·%20Windows-blue)
![Plugin](https://img.shields.io/badge/plugin-mats--tools-8A2BE2)
![Updates](https://img.shields.io/badge/updates-automatisch%20per%20git%20SHA-success)
[![validate](https://github.com/MatsLuca/claude-config/actions/workflows/validate.yml/badge.svg)](https://github.com/MatsLuca/claude-config/actions/workflows/validate.yml)

Ein persönlicher **Claude-Code-Marketplace** mit einem Plugin (`mats-tools`): meine
Slash-Commands und Subagents, geräteübergreifend versioniert und synchronisiert.
Neuer Laptop, Codespace oder Container? Ein Befehl — und die komplette Werkbank ist da:
vom Git-Workflow über PDF→Markdown bis zum fertig eingerichteten Terminal.

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

Ein Plugin, `mats-tools` — Commands für den Alltag, Agents für die schwere Arbeit:

### ⚡ Commands

| Command | Zweck |
|---|---|
| `/finish` | Änderungen seit letztem Push analysieren, README/CHANGELOG & zugehörige GitHub-Issues pflegen, committen & pushen — in einem Rutsch |
| `/github-pushes` | Eigene GitHub-Pushes in einem Zeitraum strukturiert anzeigen |
| `/merken` | Aktuellen Session-Stand in CLAUDE.md / Kontextdateien festhalten, bevor das Fenster zugeht |
| `/xcode` | Xcode-Projekt aus dem aktuellen Verzeichnis öffnen |
| `/optimieren` | Einen Command oder Agent nach dem Authoring-Standard schärfen |
| `/einarbeiten` | Beliebigen Input (Text/Datei/URL) semantisch analysieren, Projekt-Relevanz prüfen und ins Wissenssystem einarbeiten — oder bestehende Strukturen begründet infrage stellen |
| `/destillieren` | Gewachsenes Wissenssystem pflegen: Drift (veraltete/widersprüchliche Querverweise) heilen, dann Redundanz verdichten & Ordnerstrukturen neu denken — strukturelle Eingriffe erst nach Plan-Zustimmung |

### 🤖 Agents

| Agent | Zweck |
|---|---|
| `pdf-to-markdown` | Beliebige PDFs in LLM-optimiertes Markdown konvertieren — erkennt Klausur / Folien / generisch und wählt die passende Struktur |
| `machine-setup` | Frische Claude-Code-Installation einrichten wie zuhause: `yolo`-Alias, Status Line, Plugin-Auto-Update beim Start, settings.json-Defaults; in Codespaces/Remote zusätzlich VS Code (Dark Mode, Copilot-Chat aus). Portabel (macOS + Linux), idempotent |

Der Authoring-Standard und die Eval-Szenarien, gegen die `/optimieren` prüft,
liegen in `mats-tools/reference/` (`authoring-guide.md`, `evals.md`).

---

## ✅ Verifikation

Zwei Ebenen halten das Repo gesund — auch wenn Claude selbst daran weiterbaut:

- **Strukturell (automatisch):** `tools/validate.sh` prüft Manifeste, Frontmatter,
  Listing-Sync, Plugin-Referenzen und Portabilität (BSD↔GNU). Läuft lokal und
  bei jedem Push als GitHub Action.
- **Verhalten (Szenarien):** `mats-tools/reference/evals.md` beschreibt pro
  Command/Agent die erwarteten **Outcomes** — bewusst implementierungs-agnostisch,
  damit bessere Umsetzungen nie an alten Details scheitern. Ausführbar interaktiv
  oder headless (`claude -p "/command"` im Wegwerf-Fixture).

---

## 🔄 Updates

Das Plugin hat bewusst **keine feste Versionsnummer** in `plugin.json`. Dadurch nutzt
Claude Code den Git-Commit-SHA als Version: **jeder Push hierhin** wird beim nächsten
`/plugin update` automatisch übernommen — kein manuelles Versions-Bumping nötig.

Nach dem `machine-setup` passiert das sogar von selbst: der Agent installiert einen
Shell-Wrapper, der das Plugin **bei jedem `claude`-Start automatisch aktualisiert**.
Manuell braucht es nur, falls der Wrapper (noch) nicht eingerichtet ist:

```bash
/plugin update mats-tools@claude-config
```

---

## 🗂️ Struktur

```
claude-config/
├── bootstrap.sh                  # Einzeiler-Setup für neue Rechner (macOS/Linux)
├── bootstrap.ps1                 # Einzeiler-Setup für neue Rechner (Windows)
├── tools/
│   └── validate.sh               # strukturelle Verifikation (lokal + CI)
├── .github/workflows/
│   └── validate.yml              # führt validate.sh bei jedem Push/PR aus
├── .claude-plugin/
│   └── marketplace.json          # Marketplace-Manifest
└── mats-tools/                   # das Plugin
    ├── .claude-plugin/
    │   └── plugin.json           # Plugin-Manifest
    ├── commands/                 # Slash-Commands (*.md)
    ├── agents/                   # Subagents (*.md)
    ├── statusline/               # vendored Status-Line-Skript (vom machine-setup Agent installiert)
    └── reference/                # Authoring-Standard + Eval-Szenarien
```
