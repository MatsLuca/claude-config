# HISTORIE — Skill `gmail`

- **2026-08-22** Entstanden aus einem Mail-Versandfehler: Apple-Mail-Entwürfe per AppleScript kamen beim Empfänger
  als eingeklapptes Zitat an (`<blockquote type="cite">`). Nach Tests (Gmail-MCP-Entwurf, mailto:, AppleScript-reply)
  Umstieg auf ein eigenes Script `~/.config/google-gmail/gmail_draft.py` (Gmail-API: Anhänge bis 25 MB,
  Thread-Header, deutsches Zitat, Deep-Link in die Gmail-Dock-App). Regel „letzte Zeile nie der Name" gegen
  Gmails Signatur-Einklappen. Am selben Tag: Hauptkonto aufgeräumt (Kategorien, Labels, Filter) → Abschnitt
  „Ordnung halten".
- **2026-08-23** In die Skill-Werkstatt (`claude-config/skills/`) umgezogen, `~/.claude/skills/gmail` ist Symlink.
  Script, Token und Kontenliste bleiben in `~/.config/google-gmail/`.
