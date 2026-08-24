# HISTORIE — claude-config

Ersetzte Stand-Blöcke aus der CLAUDE.md, neueste zuerst (geschrieben von `/merken`).

## Stand bis 2026-08-23

- **`/neudenken`-Pass:** Faden trägt, kein Grund-Umbau — vier Re-Optimierungen: News-Kanal
  generisch (`<!-- claude: … -->`-Block pro Eintrag statt fest verdrahteter Nachricht,
  `--context` zeigt Claudes Sicht); Wrapper wirklich dünn (`shell/start.sh` trägt Update-Check,
  Startzeile, Repo-Frische, Auto-Prompt; Vertrag `MATS_TOOLS_SYNCED` rein / `MATS_TOOLS_PROMPT`
  raus, Legacy-Wrapper + PowerShell laufen unverändert; getestet mit Fake-`claude` in bash/zsh);
  Eval-Abdeckung als Validator-Pflicht (vierte Liste); Authoring-Guide kennt Skills
  („Command = Mats tippt, Skill = Situation triggert"). Die `~/.zshrc` dieses Macs blieb
  unangetastet (eigener Wrapper mit Kickbacks-Logik, Legacy-Pfad).
- **Skill-Werkstatt:** fünf globale Skills (`scan`, `pdf-unterschrift`, `gmail`, `kalender`,
  `standort`) aus `~/.claude/skills/` nach `skills/` geholt, Symlinks zurück; `_lokal/` für
  venv/Binary/Benchmark-Fotos/private Notizen; `setup.sh` je Skill; `bootstrap.sh`/`.ps1`
  verlinken; Validator-Check 7. Symlink-Loading in laufender Session verifiziert.

## Stand bis 2026-08-22 (abends, 2. Block)

- **Repo bereinigt (public!):** `plans/` aus Tracking *und* Historie entfernt (`git filter-repo`,
  Force-Push `8274494`), Beispielname in `verfassung.md` neutralisiert. `plugin update` aus einem
  Clone mit alter Historie verifiziert: springt fehlerfrei auf die neue. Alte Commits
  (`0c8a095`, `9aaa01c`, `a635851`) sind auf GitHub noch per SHA erreichbar (dangling).
- **News-Kanal live** (`NEWS.md` + `hooks/news.sh` SessionStart-Hook, verifiziert per `claude -p`):
  erste Nachricht „Live-Nachrichten — dein Claude richtet das jetzt ein". Claude handelt
  eigenständig: 1:1-Setup → `machine-setup` Nachrüst-Modus; angepasstes Setup → `start.sh` +
  `news.sh --shell` an passender Stelle des eigenen Systems, kleinster Eingriff mit Backup.
- **Startzeile fernsteuerbar:** `shell/start.sh` (Update-Alter aus mtime des aktiven Cache-Ordners;
  aktiver Ordner aus `installed_plugins.json`, nicht per `ls -t` — ein Update berührt auch den
  alten Ordner). Wrapper in `~/.zshrc` dieses Macs sourct es bereits; Vorlage in `machine-setup`.
- **machine-setup:** Nachrüst-Modus (nur Wrapper-Block, fragt nichts; bei fremdem `claude()`
  kein zweiter Block), Überschreib-Schutz für Status Line/settings.json im Vollmodus, Windows =
  Unix-Schritte via Git Bash **plus** PowerShell-Profil (Step 1W, ungetestet).
- Seen-Datei auf diesem Mac gesetzt (hier ist alles eingebaut) — `news.sh --reset` zeigt erneut.

## Stand bis 2026-08-22 (abends)


- **CLAUDE.md-Verfassung delivered** (`plans/claude-md-verfassung.md`, waves 1–6 done + post-wave
  fix `d56d653`): skill `claude-md` (+ `verfassung.md`, `inventar.sh`), `/merken` now keeps exactly
  one dated Stand block (replaced content → `HISTORIE.md`) and sets the height header; validator
  covers skills. Ancestor chains under `~/Documents` are ≤ ~5 KB; 28 project-level CLAUDE.md still
  lack a height header (handled lazily by `/merken` / the proactive skill).
- Plugin cache on this Mac is behind the repo until `/plugin update mats-tools@claude-config` (the
  `/merken` that wrote this ran from the old cached text).

### HIER WEITERMACHEN (damals)

- [ ] `/plugin update mats-tools@claude-config`, then a fresh session — verify the new `/merken`
  sentences are in the loaded command text.
- [ ] Wiedervorlage 2026-11-22: run `inventar.sh ~/Documents`, check budgets/height headers, feed
  findings into `/optimieren claude-md` (Meta-Pflege section of the Verfassung).
- [ ] `inventar.sh` GNU branch (Linux) only statically checked — run once in a container.
- [ ] `~/Documents/9_Temp/welle*-bak/` (≈200 KB wave backups) can go once nothing is missed.
