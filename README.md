# claude-config

> **Mein Claude Code — auf jedem Rechner identisch.**

Ein persönlicher **Claude-Code-Marketplace** mit einem Plugin (`mats-tools`): meine
Slash-Commands und Subagents, geräteübergreifend versioniert und synchronisiert.
Neuer Laptop, Codespace oder Container? Ein Befehl — und die komplette Werkbank ist da:
vom Git-Workflow über PDF→Markdown bis zum fertig eingerichteten Terminal.

## Installieren

### Schnell — ein Befehl

Installiert Claude Code (falls nötig), registriert den Marketplace und installiert
`mats-tools` (user-scope, idempotent — mehrfach ausführen schadet nicht).

```bash
curl -fsSL https://raw.githubusercontent.com/MatsLuca/claude-config/master/bootstrap.sh | bash
```

Danach `claude` starten, ggf. einmalig einloggen und den `machine-setup`-Agent triggern.

> **Windows (PowerShell):** `irm https://claude.ai/install.ps1 | iex`, dann
> `claude plugin marketplace add MatsLuca/claude-config` und `claude plugin install mats-tools@claude-config`.

### Per Prompt — den Agenten machen lassen

Kein Bock, selbst zu tippen? Kopier diesen Prompt in eine laufende Claude-Code-Session.
Der Agent installiert alles im Terminal und sagt dir, falls etwas manuell nötig ist:

```text
Richte mir den persönlichen Claude-Code-Marketplace „claude-config" mit dem Plugin
„mats-tools" ein. Führ dazu im Terminal das Bootstrap-Skript aus (macOS/Linux,
idempotent — installiert Claude Code falls nötig, registriert den Marketplace,
installiert das Plugin user-scoped):

  curl -fsSL https://raw.githubusercontent.com/MatsLuca/claude-config/master/bootstrap.sh | bash

Prüf danach, ob „mats-tools" installiert ist. Falls ein Schritt fehlschlägt oder etwas
manuell nötig ist (Login, neue Shell, oder Windows → PowerShell), sag mir in einem Satz
genau, was ich tun muss. Erklär zum Schluss kurz, wie ich den machine-setup-Agent auslöse.
```

### Manuell — Fallback

Falls die Wege oben nicht passen, z. B. direkt aus einer laufenden Claude-Session:

```bash
/plugin marketplace add MatsLuca/claude-config   # Marketplace registrieren (einmalig pro Rechner)
/plugin install mats-tools@claude-config         # Plugin installieren
```

## Was drin ist

Ein Plugin, `mats-tools` — Commands für den Alltag, Agents für die schwere Arbeit:

### Commands

| Command | Zweck |
|---|---|
| `/finish` | Änderungen seit letztem Push analysieren, README/CHANGELOG & zugehörige GitHub-Issues pflegen, committen & pushen — in einem Rutsch |
| `/github-pushes` | Eigene GitHub-Pushes in einem Zeitraum strukturiert anzeigen |
| `/merken` | Aktuellen Session-Stand in CLAUDE.md / Kontextdateien festhalten, bevor das Fenster zugeht |
| `/xcode` | Xcode-Projekt aus dem aktuellen Verzeichnis öffnen |
| `/optimieren` | Einen Command oder Agent nach dem Authoring-Standard schärfen |
| `/einarbeiten` | Beliebigen Input (Text/Datei/URL) semantisch analysieren, Projekt-Relevanz prüfen und ins Wissenssystem einarbeiten — oder bestehende Strukturen begründet infrage stellen |
| `/destillieren` | Gewachsenes Wissenssystem pflegen: Drift (veraltete/widersprüchliche Querverweise) heilen, dann Redundanz verdichten & Ordnerstrukturen neu denken — strukturelle Eingriffe erst nach Plan-Zustimmung |

### Agents

| Agent | Zweck |
|---|---|
| `pdf-to-markdown` | Beliebige PDFs in LLM-optimiertes Markdown konvertieren — erkennt Klausur / Folien / generisch und wählt die passende Struktur |
| `machine-setup` | Frische Claude-Code-Installation einrichten wie zuhause: `yolo`-Alias, Status Line, Plugin-Auto-Update beim Start, settings.json-Defaults; in Codespaces/Remote zusätzlich VS Code (Dark Mode, Copilot-Chat aus). Portabel (macOS + Linux), idempotent |

Der Authoring-Standard und die Eval-Szenarien, gegen die `/optimieren` prüft,
liegen in `mats-tools/reference/` (`authoring-guide.md`, `evals.md`).

## Updates

Das Plugin hat bewusst **keine feste Versionsnummer** in `plugin.json`. Dadurch nutzt
Claude Code den Git-Commit-SHA als Version: **jeder Push hierhin** wird beim nächsten
`/plugin update` automatisch übernommen — kein manuelles Versions-Bumping nötig.

```bash
/plugin update mats-tools@claude-config
```

## Struktur

```
claude-config/
├── bootstrap.sh                  # Einzeiler-Setup für neue Rechner
├── .claude-plugin/
│   └── marketplace.json          # Marketplace-Manifest
└── mats-tools/                   # das Plugin
    ├── .claude-plugin/
    │   └── plugin.json            # Plugin-Manifest
    ├── commands/                  # Slash-Commands (*.md)
    ├── agents/                    # Subagents (*.md)
    ├── statusline/                # vendored Status-Line-Skript (vom machine-setup Agent installiert)
    └── reference/                 # Authoring-Standard + Eval-Szenarien
```
