---
name: latexterm
description: Steuert das LatexTerm-Terminal von innen — Kacheln (Panes) auflisten/öffnen, Befehle oder Prompts in andere Kacheln schicken, zoomen, fokussieren. Nutzen, wenn die Session in LatexTerm läuft und der User etwas mit „Kachel", „Pane", „Split" oder einem zweiten Terminal will (z. B. „öffne eine Kachel und starte da den Server", „frag die andere Claude-Session").
---

# LatexTerm steuern

Läuft diese Session in LatexTerm (Mats' Terminal-App), ist `$LATEXTERM_PANE_ID`
gesetzt und das CLI `latexterm` steuert die App über einen lokalen Socket.
Fehlt die Variable oder das CLI (`command -v latexterm`): Skill nicht
anwendbar — normal weiterarbeiten, nichts simulieren.

## Befehle

| Befehl | Wirkung |
|---|---|
| `latexterm list-panes [--json]` | Alle Kacheln: Index, UUID-Präfix, CWD, Status (`working` / `awaitingInput` / fokussiert) |
| `latexterm new-pane [--cwd DIR] [--exec CMD]` | Neue Kachel, optional Startordner + Startbefehl |
| `latexterm send [--pane SEL] [--no-enter] TEXT…` | TEXT in eine Kachel tippen; Enter wird standardmäßig mitgesendet |
| `latexterm zoom [--pane SEL]` | Kachel-Zoom an/aus (wie ⌘⏎) |
| `latexterm focus [--pane SEL]` | Kachel fokussieren (Fenster nach vorn) |

- `SEL`: reine Ziffern = 1-basierter Index aus `list-panes`; sonst UUID-Präfix
  (case-insensitiv, muss eindeutig treffen). Ohne `--pane` = die eigene Kachel.
- Exit-Codes: 0 ok · 1 App-Fehler · 2 Usage · 3 App nicht erreichbar.

## Regeln

- `send` tippt in eine ECHTE Shell — der Text wird dort ausgeführt. Vor jedem
  `send` in eine fremde Kachel erst `list-panes` und das Ziel per Index/UUID
  absichern; ein Treffer in der falschen Shell ist Command-Execution.
- Destruktives (`rm`, `git push`, `kill`, …) nie per `send` in fremde Kacheln
  ohne expliziten User-Auftrag.
- Prompts an eine andere Claude-Session sind der Normalfall: `awaitingInput`
  = sie nimmt Input an; `working` = erst warten oder den User fragen.
- Frisch geöffnete Kacheln melden ihren CWD erst nach dem ersten Prompt
  (kurz `?` in `list-panes`) — 1–2 s warten, dann erneut listen.
