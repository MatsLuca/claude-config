# CLAUDE.md — claude-config (Projekt)

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal **Claude Code plugin marketplace** — not an app. There is no build step. The
"source" is a set of structured Markdown + JSON manifests that Claude Code loads as
slash-commands and subagents. There **is** a check: `tools/validate.sh` verifies manifests,
frontmatter, listing sync, plugin-internal references, and portability — run it after any
change to commands/agents/manifests (CI runs it on every push via
`.github/workflows/validate.yml`). Behavior is verified against the outcome-level scenarios
in `mats-tools/reference/evals.md` — interactively or headless (see the Loop section there).

## Architecture

Three nesting levels, each with its own manifest:

1. **Marketplace** — `.claude-plugin/marketplace.json` declares the marketplace `claude-config`
   and lists its plugins. Each plugin entry points at a subdirectory via `source` (e.g. `./mats-tools`).
2. **Plugin** — `mats-tools/.claude-plugin/plugin.json` is the plugin manifest.
   Commands and agents are auto-discovered from convention directories, *not* listed in the manifest.
3. **Commands, agents & skills** — Markdown files with YAML frontmatter:
   - `mats-tools/commands/*.md` → slash-commands (filename = command name, so `finish.md` → `/finish`).
   - `mats-tools/agents/*.md` → subagents (the `name:` field in frontmatter is the agent id).
   - `mats-tools/skills/<name>/SKILL.md` → skills (user-invocable *and* model-triggered via
     `description`); companion files live next to the SKILL.md (e.g. `claude-md/verfassung.md`,
     `claude-md/scripts/inventar.sh`) and are referenced as `${CLAUDE_PLUGIN_ROOT}/skills/<name>/…`.

   - `mats-tools/hooks/hooks.json` → plugin hooks; the only one is the **SessionStart news
     hook** (`hooks/news.sh` reads `mats-tools/NEWS.md`, shows unread entries once per machine
     as `systemMessage` + hands them to Claude as `additionalContext`). Writing to `NEWS.md`
     = messaging every subscriber at their next session start.
   - `mats-tools/shell/start.sh` → sourced by the `claude()` wrapper that `machine-setup`
     installs; the wrapper in the rc file stays thin, the start line evolves here.

4. **Skill-Werkstatt** — `skills/<name>/` (top-level, *not* plugin content): global skills with code,
   binaries or machine state, linked into `~/.claude/skills/<name>` via symlink (`bootstrap.sh
   --skills-only`). Edits take effect immediately; each skill carries `HISTORIE.md`; everything local or
   private (venv, binaries, benchmark photos, notes naming third parties) lives in `_lokal/` (gitignored —
   the repo is public; validator check 7 enforces it). Mature, markdown-only skills graduate into
   `mats-tools/skills/`. Conventions: `skills/README.md`.

`plans/` holds multi-session work plans (waves with checkboxes + protocol) — not plugin content and
**gitignored** (local only): the protocols name private folders/people, and the repo is public.

Adding a command, agent or skill = dropping a new file in the right directory with valid
frontmatter. No manifest edit is needed for discovery — but **do** update the human-facing
tables in `README.md`, `marketplace.json` description, and `plugin.json` description/keywords
so the listing stays accurate.

## Versioning convention (important)

`plugin.json` intentionally has **no `version` field**. This makes Claude Code use the git
commit SHA as the version, so every push is picked up by the next `/plugin update` without
manual version bumps. Do not add a `version` key unless the user explicitly wants pinned releases.

## Frontmatter conventions

**Commands** (`commands/*.md`):
- `description:` — one line, shown in the slash-command picker.
- `allowed-tools:` — scope tightly. Use narrowed Bash patterns like `Bash(git status:*)`,
  `Bash(gh search commits:*)` rather than blanket `Bash`. Match the existing style.
- `argument-hint:` — optional; the user's input is interpolated as `$ARGUMENTS` in the body.

**Agents** (`agents/*.md`):
- `name:`, `description:` (with embedded `<example>` usage blocks that drive proactive
  invocation), `model:`, `color:`.

## Conventions

- **Language split:** command bodies + all `description` frontmatter are **German** (the author's
  working language). Agent *instruction bodies* are written in **English**, with German *output
  templates* (e.g. `## Aufgabe`, `**Gegeben:**`) since the produced files are for German study
  material. Keep new commands German and new agents English-instructions/German-output unless asked otherwise.
- Command bodies emphasize **token efficiency** — combine status-gathering into a single Bash
  round (cheap overview first, full content only when needed). Follow this pattern in new commands.
- **Portability (macOS + Linux):** commands must also work in containers/Codespaces. For
  BSD↔GNU dialect splits (`date`, `stat`, `sed -i`) use the probe-then-variant pattern
  (cheap GNU probe once, then stick to one dialect — see `mtime()` in
  `statusline/statusline-command.sh`). Inherently macOS-bound commands (`/xcode`) are the
  marked exception. The validator's portability lint guards against regressions.
- **Evals describe outcomes, not implementation** (`mats-tools/reference/evals.md`): they pin
  observable behavior, never internal markers or specific tool calls — so a better
  re-implementation is never blocked by an eval. If an implementation change touches an
  eval's wording, update the eval explicitly, never silently.
- The authoring standard (`mats-tools/reference/authoring-guide.md`) is itself an optimizable
  target (`/optimieren authoring-guide`) — see its "Meta-Pflege" section.
- **Public repo, real subscribers.** Two friends pull this plugin automatically at every
  launch; they are not programmers, trust Mats' setup, and one has rebuilt his Windows terminal
  (own status panel, start output suppressed). Consequences: nothing private or third-party in
  tracked files (`plans/` stays gitignored; protocols live in `HISTORIE.md` only if harmless);
  `NEWS.md` entries are written for non-coders and make Claude *act*, never ask; `machine-setup`
  never overwrites customised pieces without being in its own managed block.
- **Precedence over plugin-dev:** Anthropic's `plugin-dev` plugin (if installed) serves as a
  *technical reference only* (hook definitions, MCP bundling, plugin.json/marketplace schemas).
  For style and quality questions about commands/agents/skills (frontmatter, clarity, token
  efficiency), the `/optimieren` authoring standard is authoritative — do not apply plugin-dev's
  style recommendations unprompted.

## Local testing

```bash
# First time on a machine:
/plugin marketplace add <github-user>/claude-config
/plugin install mats-tools@claude-config

# After pushing changes:
/plugin update mats-tools@claude-config
```

Then invoke the command (`/finish`, `/xcode`, …) or trigger the agent to verify behavior.

## Aktueller Stand (2026-08-24)

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

## HIER WEITERMACHEN

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
- [ ] Entscheidung Mats: GitHub-Support anfragen, um die dangling Commits mit `plans/` zu purgen —
  dabei auch die alten Commits mit der echten Adresse in `skills/standort/SKILL.md` nennen
  (forward gefixt am 24.08., Historie enthält sie noch).
- [ ] Optional: Nachrüst-Modus auf einer Test-Maschine/Container live durchspielen (auf diesem
  Mac bewusst nicht — eigener `claude()`-Wrapper).
- [ ] Wiedervorlage 2026-11-22: `inventar.sh ~/Documents`, Budgets/Kopfzeilen prüfen →
  `/optimieren claude-md`.
- [ ] `inventar.sh` GNU-Zweig einmal im Container laufen lassen.
- [ ] `~/Documents/9_Temp/welle*-bak/` (≈200 KB) löschen, wenn nichts vermisst wird.
