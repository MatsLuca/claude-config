# HISTORIE — claude-config

Ersetzte Stand-Blöcke aus der CLAUDE.md, neueste zuerst (geschrieben von `/merken`).

## Stand bis 2026-08-24 (Audit-Pass, vor der Trennung)

Der `/neudenken`-Pass (News-Kanal generisch, dünner Wrapper-Vertrag in `shell/start.sh`,
Eval-Abdeckung im Validator, Guide kennt Skills) und die Skill-Werkstatt (fünf globale Skills
`scan`/`pdf-unterschrift`/`gmail`/`kalender`/`standort` unter `skills/`, `_lokal/` für Privates,
Validator-Check 7) sind **committet und gepusht** — Details in `HISTORIE.md`.

Heute: **Mehrdimensionaler Audit** (4 Subagenten: Commands/Agents, Skill-Werkstatt,
Infrastruktur/Shell, Privacy/Doku) + Umsetzung der Befunde:

- **Privacy:** echte Adresse aus `skills/standort/SKILL.md` und Kita/BuT-Beispiel aus
  `skills/gmail/SKILL.md` durch generische Platzhalter ersetzt (Repo ist public!).
- **Validator gehärtet:** `${CLAUDE_PLUGIN_ROOT}`-Check liest jetzt auch `*.json`
  (hooks.json-Referenz auf `news.sh` war ungeprüft — live reproduziert); Portabilitäts-Lint
  deckt `statusline/` + `bootstrap.sh` ab; `bootstrap.ps1` wird per pwsh geparst (in CI;
  lokal übersprungen, wenn kein pwsh); NEWS.md-Lint gegen doppelte `<!-- claude: -->`-Blöcke.
- **`bootstrap.ps1`:** `-SkillsOnly`-Switch als Pendant zu `--skills-only` (Funktion nach
  vorn gezogen; ungetestet auf echtem Windows, aber Parser-gedeckt).
- **Modellpolitik Plugin-Agents:** `machine-setup` + `pdf-to-markdown` auf `model: inherit` —
  kein Pinning; jeder Subscriber nutzt sein bestes Modell (Mats' Entscheidung 24.08.).
- **scan-Diät:** Magic-Fit-Details + Benchmark-Historie aus der SKILL.md (16,5 KB) nach
  `skills/scan/ALGORITHMUS.md` ausgelagert; SKILL.md wieder operativer Kern.
- **Evals:** fünf Werkstatt-Skills als `## <name> (Werkstatt-Skill)` in `evals.md` +
  Validator-Pflicht; Nachrüst-Modus-Szenario für `machine-setup` ergänzt.
- Kleinkram: `optimieren.md` Schritt 2 als ein Bash-Block; README nennt Skills bei der
  Verifikation.

### HIER WEITERMACHEN (damals)

- [ ] Audit-Stand committen/pushen; danach `/plugin update` + neue Session: Startzeile und
  `news.sh --context` am echten Cache prüfen.
- [ ] `bootstrap.ps1 -SkillsOnly` bei Gelegenheit auf einem echten Windows-Rechner verifizieren
  (nur Parser-geprüft).
- [ ] `bootstrap.sh`/`.ps1` könnten Claude direkt mit „Führe das machine-setup durch." starten
  (Auto-Prompt-Mechanik existiert) — vorher auf Wegwerf-Maschine prüfen, ob der Login-Flow das
  verträgt. Bewusst nicht blind umgesetzt.
- [ ] Eigenen Wrapper in `~/.zshrc` optional auf den dünnen Vertrag umstellen (`MATS_TOOLS_SYNCED`
  setzen, Fetch/Autoprompt-Teil entfernen) — Kickbacks-Blöcke bleiben.
- [ ] Erstes echtes Exemplar des autonomen Nachrüstens kommt von einem der Jungs — deren
  Zwei-Sätze-Zusammenfassung einholen; Windows-Zweig (Step 1W) danach korrigieren, falls nötig.
- [ ] GitHub-Support-Ticket „purge cached sensitive data" ist **eingereicht** (24.08., Kategorie
  Repositories/Branches, alle 9 SHAs aus beiden Rewrites) — auf Antwort warten, danach
  stichprobenartig alte SHAs auf github.com prüfen; dann Anfragetext + Backup-Bundle in
  `~/Documents/9_Temp/` löschen (Bundle enthält die Adresse noch).
- [ ] Optional: Nachrüst-Modus auf einer Test-Maschine/Container live durchspielen (auf diesem
  Mac bewusst nicht — eigener `claude()`-Wrapper).
- [ ] Wiedervorlage 2026-11-22: `inventar.sh ~/Documents`, Budgets/Kopfzeilen prüfen →
  `/optimieren claude-md`.
- [ ] `inventar.sh` GNU-Zweig einmal im Container laufen lassen.
- [ ] `~/Documents/9_Temp/welle*-bak/` (≈200 KB) löschen, wenn nichts vermisst wird.

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
