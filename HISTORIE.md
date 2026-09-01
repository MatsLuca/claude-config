# HISTORIE — claude-config

Ersetzte Stand-Blöcke aus der CLAUDE.md, neueste zuerst (geschrieben von `/merken`).

## 2026-09-01 — `/neudenken` mit Fable 5.1: Auftrag vor Rezept

Vierter Neudenken-Pass in zehn Tagen, Anlass neues Modell. Belege: Baseline `eval.sh alle` 6/6 grün
unter Fable 5.1; in zwei von drei Läufen lehnte die Berechtigungsprüfung den vorgeschriebenen
Bash-Einzeiler ab und das Modell zerlegte ihn selbst — Outcome hielt, Rezept nicht. `claude plugin
details` zählt alle elf Commands als Skills; Skill-Tool-Aufrufe von finish-lite/finish/optimieren in
den Transkripten seit 7.8. Nutzung 7.8.–1.9.: merken 87, finish-lite 33, claude-md/finish je 14,
einarbeiten/github-pushes/Agents 0. Seit 25.8. kein `/optimieren`-Pass; sechs von zehn Commits
Infrastruktur; Plugin hält 2417 Zeilen Code gegen 1875 Prosa. Guide-Agent (Doku): Commands→Skills
offiziell verschmolzen, `disable-model-invocation`/`context: fork`/`model`/`effort`/`hooks` im
Skill-Frontmatter, `permissionMode`/`mcpServers`/`hooks` bei Plugin-Agents ignoriert, natives
`claude plugin validate` GA, `claude plugin eval` Early Access ohne Platten-Grader, keine
modellspezifische Prompt-Anleitung in der Claude-Code-Doku.

Urteil: gesund, Umbau im Detail. Umgesetzt (Details im Stand-Block der CLAUDE.md vom 01.09.):
Sperr-Flag auf finish/finish-lite/claude-chats, Guide auf „Auftrag vor Rezept", finish/finish-lite/
merken geschärft (98/28/66 → 21/20/30 Zeilen), Runner-Szenarien finish:feature/finish:clean/
merken:stand, Validator-Check 8 (natives validate), Wrapper-Helfer ohne Unterstrich, NEWS-Eintrag,
Wiedervorlage 15.09., Feedback-Entwurf. Verworfen nach Test: `${CLAUDE_SKILL_DIR}` in
`allowed-tools`. Ersetzte Stand-Blöcke darunter.

## Aktueller Stand (2026-08-25)

**`/wrapped`** dazugekommen — der erste Command mit eigenen Skripten
(`mats-tools/scripts/wrapped/`: `aggregate.py`, `card.html`, `render.py`). Er baut aus den
lokalen Dateien unter `~/.claude` ein teilbares PNG (Chrome headless, Zwischenablage).
Zwei Entscheidungen, die man nicht aus dem Code ablesen kann:

- **Nichts Privates aufs Bild.** Projekt-, Ordner- und Dateinamen fehlen *im Aggregat*, nicht
  erst in der Karte — das Bild geht in Gruppenchats. Wer den Command erweitert, hält das so.
- **Handarbeit wird pro Auftrag geschätzt, nicht pro Werkzeug-Aufruf** (`TASK_MINUTES`).
  Grund: ohne Claude hätte man dieselben Shell-Befehle nie getippt, sondern das Ziel anders
  erreicht; außerdem bleibt die Zahl stabil, wenn ein Modell dieselbe Aufgabe mit 5 statt 50
  Aufrufen löst. Die Zahl trägt sichtbar ein `≈` und wird als Schätzung benannt.

Layout-Prinzip der Karte: wenige große Aussagen (eine Hero-Zahl, drei Kacheln, zwei Werte,
eine Kurve), keine Panel-Rahmen. Ein reicheres Bild war gebaut und wurde bewusst halbiert.

## Stand bis 2026-08-24 (abends)

`/neudenken` → Zweck-Satz (oben) → Plan mit vier Wellen, **alle am 24.08. umgesetzt** (Protokoll:
`../claude-werkstatt/plans/werkzeugkasten_2026-08-24.md`; Welle-Details in `HISTORIE.md`):

- **Getrennt:** Werkstatt (`skills/` mit Code, `plans/`) → privates `claude-werkstatt`; hier nichts
  Privates mehr per Konstruktion (Checks 7/8, Sperrlisten-Lint weg). −3400 Zeilen insgesamt.
- **Geschnitten:** News reine Info (kein Auto-Prompt/Nachrüst-Modus); `machine-setup` =
  `shell/setup.sh` (Marker, Sandbox-Test = Validator-Check 7) + dünner Agent; README einzige Liste;
  `start.sh` hat nur noch einen Wrapper-Vertrag (`MATS_TOOLS_SYNCED`).
- **Loop scharf:** `tools/eval.sh` (headless, Fixtures, 6/6 grün), `/optimieren` kennt Werkstatt-Ziele,
  Ritus in den Conventions.
- **Kontext-Gerüst:** Router-Regel + `~/.claude/reference/werkzeugkasten.md` (Ortsfrage statt Pflichtweg,
  „mach das global"-Rezept), Memory, Aliase `kasten`/`werkstatt`, eigener Wrapper = dünner Vertrag +
  Werkstatt-Pull beim Start.
- Live geprüft: Plugin-Cache `e6f2a91`, Startzeilen `🔄 mats-tools` / `🔧 Werkstatt`, Setup-Kette aus dem
  Cache im Sandbox-HOME, auf diesem Mac meldet der Agent korrekt `WRAPPER_CONFLICT`/`STATUSLINE_DIFFERS`
  (Kickbacks-Block)/`SETTINGS_DIFFERS` und fasst nichts an.


## 2026-08-28 — Session-Start ohne Netz-Wartezeit

- Timeline gemessen: ~3 s bis zum Prompt, davon ~1,8 s zwei serielle GitHub-Roundtrips im Wrapper
  (Plugin-Update 0,9 s, Werkstatt-Fetch 0,8 s), bei lahmem Netz bis 13 s (Timeouts 8 s + 5 s);
  einmal täglich zusätzlich `claude update` synchron mit 60-s-Timeout — obwohl Claude Code (native)
  einen eigenen Auto-Updater hat (`claude doctor`: enabled, nächtliche Versionen im Ordner).
  Claude selbst bootet in ~1 s (setup 118 ms, MCP/LSP nicht-blockierend).
- **Umbau:** `shell/sync.sh` (neu) macht Plugin-Update + ff-only-Pull der Klone aus
  `~/.config/mats-tools/sync-repos` im Hintergrund (Stempel, 10-min-Drossel, mkdir-Lock, 5 s
  Anlaufpause, damit die Session vorher fertig geladen hat). Wrapper startet Claude sofort;
  Erststart ohne Cache bleibt synchron. `frisch` = `--now`, dann yolo. `start.sh` ohne Netz und
  ohne täglichen `claude update`; Repo-Frische nur noch lokal gegen die gefetchten Refs.
- **„Gepusht → Strg-C → yolo" bleibt sauber:** `/finish` und `/finish-lite` rufen nach dem Push
  `sync.sh --after-push` (Einzeiler, entscheidet selbst: nur im Marketplace-Repo, sonst still —
  keine Prosa, keine Token in fremden Repos). Home-Kachel (`projekte list --json`) wärmt den Sync vor.
- Mats' eigener Wrapper in `~/.zshrc` folgt dem neuen Block (+ Kickbacks-Teil); Sicherung
  `~/.zshrc.bak-2026-08-28`.

## 2026-08-26 — /neues-projekt: Modus --einordnen

- Neuer Weg für „ich weiß noch nicht, wo das hingehört": die Home-Kachel in LatexTerm startet in der
  Wurzel mit `--einordnen <Name>: <Zweck>`; Schritt 0 liest Router-CLAUDE.md + Bereiche, bietet 2–3
  Orte mit Begründung an (AskUserQuestion, bester zuerst), legt den Ordner an und läuft dann den
  normalen Ablauf mit `cd <Pfad> && ` vor jedem Bash-Aufruf (die Shell vergisst das Verzeichnis).
- **Regel:** nach `--einordnen` nicht weiterarbeiten — die Session steht in der Wurzel. Der Abschluss
  endet mit dem fetten Hinweis „⌘N, Ordner wählen, ⏎" — sonst arbeitet man in Documents drauflos.
- `allowed-tools` um `Bash(cd:*)`, `Bash(mkdir:*)`, `Bash(git -C:*)` erweitert; `{purpose}` aus
  dem Dialog kommt als `$ARGUMENTS` und spart die erste Interviewfrage.

## Stand bis 2026-08-24 (Umbau-Wellen 1–4, Detail)

Nach dem Audit-Pass (Privacy, Validator-Härtung, Evals — Details `HISTORIE.md`) hat ein
`/neudenken` den Zweck neu gefasst: **ein Werkzeugkasten für die Arbeit mit Claude, der sich durch
die Arbeit mit ihm selbst schärft.** Freunde sind Empfänger von Geschenken, kein Vertrag. Plan mit
vier Wellen — **alle umgesetzt am 24.08.** — Protokoll in `../claude-werkstatt/plans/werkzeugkasten_2026-08-24.md`.

- **Welle 1 (Trennen) — erledigt:** Werkstatt (`skills/`, `plans/`, `_lokal`-Inhalte) ins private
  Repo `claude-werkstatt` gezogen, Symlinks umgebogen, `_lokal/` dort aufgelöst. Hier entfernt:
  `skills/`, `plans/`, `--skills-only`/`-SkillsOnly`, Validator-Checks 7 + 8, Werkstatt-Evals.
  Sperrliste `~/.config/claude-config/privat-lint.txt` bleibt als Rezept (`~/.claude/reference/privacy.md`).
- **Welle 4 (Kontext-Gerüst) — erledigt:** `~/.claude/CLAUDE.md` hat die Werkzeugkasten-Regel,
  `~/.claude/reference/werkzeugkasten.md` trägt Orte, Skill-Weg, Loop, Ritus, Neuer-Mac-Rezept;
  `privacy.md` auf „Struktur statt Lint" umgestellt; Memory, zsh-Alias `claude-werkstatt`,
  Wiedervorlage 2026-09-24 (Legacy-Pfad in `start.sh`).
- **Welle 3 (Loop scharf) — erledigt:** `tools/eval.sh` (Szenarien `finish-lite:sync`,
  `finish-lite:synchron`, `xcode:leer` + freier Lauf; erster Lauf 6/6 grün), `/optimieren` kennt
  Werkstatt-Ziele + `<werkstatt>/evals.md` + Runner, Guide trägt Zweck-Satz und Werkstatt→Plugin,
  Ritus in den Conventions oben.
- **Welle 2 (Schneiden) — erledigt:** News-Kanal reine Info (kein `<!-- aktion -->`, kein
  Auto-Prompt, kein Nachrüst-Modus; `<!-- claude: -->` = Hinweis, nicht Auftrag; Eintrag 22.08.
  durch Info-Eintrag ersetzt). `machine-setup` = `shell/setup.sh` (deterministisch, Marker,
  Sandbox-getestet im Validator-Check 7) + dünner Agent (Urteil: Konflikte, Diffs, Rendering).
  Dreifach-Listung aufgelöst (README einzige Liste, Manifeste statisch). README-Story = Zweck-Satz
  + „Der Loop". `start.sh`-Legacy-Pfad am Abend entfernt (ein Vertrag für alle Wrapper; alte
  Wrapper sehen die Fetch-Zeile ggf. doppelt, bis sie einmal `machine-setup` laufen lassen).

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
