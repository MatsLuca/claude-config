# Skill-Werkstatt

Quelle der **globalen Claude-Code-Skills**, die in `~/.claude/skills/<name>` per Symlink eingehängt sind
(`bootstrap.sh` legt die Links an). Änderungen hier wirken sofort in jeder Session — und sind versioniert.
Das ist die Werkstatt-Stufe vor dem Plugin: Skills mit Code, Binaries oder Maschinenzustand, an denen noch
gearbeitet wird. Fertige, reine Markdown-Skills graduieren nach `mats-tools/skills/` (dann mit Listing-Sync
und Eval-Abschnitt, wie `tools/validate.sh` verlangt).

| Skill | Zweck | Lokales (`_lokal/`, nicht versioniert) |
|---|---|---|
| `scan` | Handyfotos von (gefalteter) Briefpost → scanähnliches A4-PDF: Browser-Editor + „Magic Fit" (Apple Vision, Kantenmessung, Falzlinien, Textzeilen-Optimierung) | `bin/docdetect` (Swift, macOS), `benchmark/` (eigene Referenzfotos) |
| `pdf-unterschrift` | Digitale Unterschrift freistellen und druckfest in ein PDF-Formular einbrennen | `venv/` (per `setup.sh`), `NOTIZEN.md` (bekannte Master je Person) |
| `gmail` | Gmail-Entwürfe mit Anhängen/Thread-Antwort über ein eigenes API-Script bauen | — (Script + Token in `~/.config/google-gmail/`) |
| `kalender` | Termine in einen Google-Unterkalender schreiben | — (Script + Token in `~/.config/google-calendar/`) |
| `standort` | Standort des Macs per CoreLocationCLI | — (Homebrew-Cask, Ortungsfreigabe) |

## Konventionen

- **`SKILL.md`** mit Frontmatter `name` (= Ordnername) und `description` (deutsch, sagt *was* und *wann laden*),
  Stil nach `mats-tools/reference/authoring-guide.md`. Companion-Dateien liegen daneben und werden relativ
  zum Skill-Ordner referenziert (`~/.claude/skills/<name>/…` funktioniert durch den Symlink überall).
- **`HISTORIE.md`** je Skill: Entstehung, Lehren, Umbauten — die Werkstatt-Chronik, die ein Projekt überlebt.
- **`_lokal/`** je Skill: alles, was nicht ins Repo gehört — venv, kompilierte Binaries, Caches, Benchmark-Fotos,
  private Notizen (Namen Dritter, Pfade in persönliche Ordner). Per `.gitignore` ausgeschlossen;
  `tools/validate.sh` bricht ab, wenn Bilder/PDFs/venv unter `skills/` getrackt würden. **Das Repo ist öffentlich.**
- **`setup.sh`** (optional, idempotent): prüft Werkzeuge und baut `_lokal/` auf (venv, Binary). Wird von
  `bootstrap.sh` nach dem Verlinken aufgerufen und kann jederzeit erneut laufen. Plattform-Hinweise stehen im
  Script (macOS: Homebrew; Debian/Ubuntu: apt; Windows: Git Bash, venv unter `Scripts/`).
- **Secrets** (OAuth-Tokens, Client-Secrets) liegen nie im Skill, sondern in `~/.config/<dienst>/`.

## Einhängen auf einem Rechner

```bash
bash bootstrap.sh --skills-only     # nur Symlinks + setup.sh (Rest des Bootstraps überspringen)
```
Existiert `~/.claude/skills/<name>` schon als echter Ordner, lässt das Script ihn in Ruhe und sagt Bescheid —
lokale Änderungen erst sichern, dann Ordner entfernen und erneut ausführen.

## scan: eigenen Benchmark anlegen

Die Auto-Erkennung wurde gegen manuell gesetzte Referenzpunkte gemessen (Ø-Fehler in % der Bildkante).
Die Referenzfotos sind private Briefe und liegen nicht im Repo — jeder kann sich mit eigenen Fotos einen
Benchmark bauen:

1. `python3 ~/.claude/skills/scan/scan_tool.py FOTO… -o Test.pdf` → im Editor pro Seite Knickzahl, alle Punkte
   und Wölbungen **so exakt wie möglich von Hand** setzen, „Speichern".
2. `scan_werkstatt/` kopieren nach `skills/scan/_lokal/benchmark/<name>/` und dort `punkte.json` in
   `referenz.json` umbenennen (`originale/` muss mitkommen).
3. `python3 ~/.claude/skills/scan/benchmark.py` — vergleicht Vision allein / Kantenmessung / Magic Fit gegen die
   Referenz, je Punkt und je Seite, plus Zeilen-Neigung nach Entzerrung. Jede Algorithmus-Änderung erst
   messen, dann behalten.

Plattform: Der Editor und der Warp laufen überall (Python 3 + Pillow, ImageMagick, img2pdf, poppler); die
Auto-Erkennung braucht **macOS** (Apple Vision, `swiftc`). Ohne sie setzt man die Punkte von Hand.
