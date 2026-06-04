# claude-config

Persönlicher Claude-Code-Marketplace von Mats — meine Slash-Commands und Subagents,
geräteübergreifend versioniert und synchronisiert.

## Inhalt

Das Repo ist ein **Marketplace** (`.claude-plugin/marketplace.json`) mit einem Plugin:

### `mats-tools`
| Typ | Name | Zweck |
|---|---|---|
| Command | `/finish` | Änderungen seit letztem Push analysieren, README/CHANGELOG pflegen, committen & pushen |
| Command | `/github-pushes` | Eigene GitHub-Pushes in einem Zeitraum strukturiert anzeigen |
| Command | `/merken` | Aktuellen Session-Stand in CLAUDE.md / Kontextdateien festhalten |
| Command | `/xcode` | Xcode-Projekt aus dem aktuellen Verzeichnis öffnen |
| Agent | `exam-pdf-to-markdown` | Altklausur-PDFs in LLM-freundliches Markdown konvertieren |
| Agent | `lecture-slides-to-markdown` | Vorlesungsfolien-PDFs in strukturiertes Markdown konvertieren |

## Installation auf einem neuen Rechner

```bash
# Marketplace registrieren (einmalig pro Rechner)
/plugin marketplace add <github-user>/claude-config

# Plugin installieren
/plugin install mats-tools@claude-config
```

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
├── .claude-plugin/
│   └── marketplace.json      # Marketplace-Manifest
└── mats-tools/               # das Plugin
    ├── .claude-plugin/
    │   └── plugin.json        # Plugin-Manifest
    ├── commands/              # Slash-Commands (*.md)
    └── agents/                # Subagents (*.md)
```
