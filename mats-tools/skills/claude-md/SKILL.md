---
name: claude-md
description: Hält CLAUDE.md-Dateien auf der richtigen Höhe (Router / Bereich / Projekt) nach Mats' Verfassung — prüft eine Datei oder einen Teilbaum, verschiebt Ballast nach unten, ergänzt Zeiger. Laden, sobald eine CLAUDE.md angelegt, substanziell umgebaut oder auf Ballast/Veraltung geprüft werden soll („leg eine CLAUDE.md an", „räum die CLAUDE.md auf", „gehört das hier rein?", Inventar der CLAUDE.md unter einem Ordner) — nicht beim bloßen Lesen oder beim Stand-Nachtrag per /merken (der lädt den Skill selbst, wenn er schreibt).
---

# CLAUDE.md auf Höhe halten

Maßstab ist `verfassung.md` neben dieser Datei
(`${CLAUDE_PLUGIN_ROOT}/skills/claude-md/verfassung.md`) — lies sie zuerst, sie ist kurz.
Kern: Claude Code lädt die ganze Ahnenkette in jeder Session; obere Ebenen müssen billig
und unveraltbar sein, Status lebt nur im Projekt. Jede CLAUDE.md ist **Router**, **Bereich**
oder **Projekt** und sagt es in der Kopfzeile.

## Zwei Betriebsarten

**Wartungsgang** (`/claude-md [pfad]`): Datei oder Teilbaum prüfen, Bericht, Umbau erst nach Zustimmung.
**Proaktiv** (beim Anlegen/Umbauen einer CLAUDE.md aus anderer Arbeit heraus): Höhe bestimmen,
Skelett aus der Verfassung nehmen, Höhen-Check auf den Inhalt — ohne eigenen Bericht, der
Umbau ist Teil der laufenden Aufgabe.

## Schritt 1 — Lage erfassen

Ohne Pfad-Argument: Inventar des Teilbaums unter cwd (eine Bash-Runde):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/claude-md/scripts/inventar.sh" .
```

(Pro CLAUDE.md: Bytes, Zeilen, Änderungsdatum, Höhe laut Kopfzeile oder `?`, Pfad. Portabel macOS/Linux.)

Mit Pfad: diese eine Datei lesen **plus** die Ahnenkette (`~/.claude/CLAUDE.md`, jede CLAUDE.md
von `~/Documents` bis zum Ordner) — nur dann ist prüfbar, was oben schon gesagt wird. Was
bereits im Kontext ist, nicht neu lesen.

## Schritt 2 — Höhe bestimmen

Regel aus der Verfassung: gleichartige Kinder + selten cwd → Router (ohne gemeinsame
Arbeitsmuster) oder Bereich (mit); hier wird gearbeitet → Projekt. Widerspricht die
Kopfzeile der Rolle, ist *das* der erste Befund. Fehlt die Datei und der nächsthöhere
Router nennt die Kinder schon → keine anlegen.

## Schritt 3 — Gegen die Checkliste prüfen

Die Prüf-Checkliste der Verfassung Punkt für Punkt. Jeder Befund braucht eine **Aktion mit Ziel**:
- *Ballast* → wohin genau (Kind-CLAUDE.md, README des Vorgangs, `HISTORIE.md`,
  `~/.claude/reference/<thema>.md`) — nie löschen, immer verschieben; oben höchstens ein Zeiger.
- *Fehlender Zeiger* → welche Zeile wo ergänzen.
- *Toter Zeiger* → korrigieren oder streichen.
- *Budget* → Bytes jetzt vs. Limit, welcher Block geht.

Ehrlich melden, wenn wenig zu tun ist — nichts erfinden, wo die Datei ihre Höhe erfüllt.

## Schritt 4 — Bericht, dann Umbau

Bericht knapp: Höhe (ist/soll), Bytes, Befunde als Liste `Befund → Aktion → Ziel`.
Im Wartungsgang Zustimmung per `AskUserQuestion` holen (mehrere unabhängige Eingriffe:
`multiSelect`, ein Eintrag je Eingriff). Reinheilung ohne Rückfrage erlaubt: Kopfzeile setzen,
toten Zeiger korrigieren.

Umbau: **erst das Ziel schreiben, dann oben kürzen** — Inhalt darf nie nur gelöscht werden.
`Edit` für punktuelle Änderungen, `Write` nur für neue Dateien. Stil der Zieldatei wahren.
Nach dem Umbau: Bytes erneut messen, Checkliste nochmal — erst wenn alle Punkte grün, fertig.

## Abschluss

Melde: Datei(en), Höhe, Bytes vorher → nachher, was wohin verschoben wurde, was bewusst blieb.
