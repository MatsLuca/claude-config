# CLAUDE.md — claude-config (Projekt)

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**A toolbox for working with Claude that sharpens itself through the work done with it**
(purpose fixed by `/neudenken`, 2026-08-24). Technically a personal **Claude Code plugin
marketplace** — not an app, no build step: structured Markdown + JSON manifests that Claude
Code loads as slash-commands, subagents and skills. The private sibling `claude-werkstatt`
holds everything with code, accounts or private notes (aliases `kasten` / `werkstatt`;
placement rule and recipes in `~/.claude/reference/werkzeugkasten.md`). There **is** a check: `tools/validate.sh` verifies manifests,
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

   - `mats-tools/hooks/hooks.json` → plugin hooks, both SessionStart: **start-timer**
     (`hooks/start-timer.sh`: Startdauer je Phase aus den Stempeln `MATS_START_T0`/`MATS_T_RC`/
     `MATS_T_WRAP`/`MATS_T_EXEC`, eine Zeile im Terminal, Log `~/.cache/mats-tools/start-timer.log`,
     `--tail`/`--self`) and the **news hook** (`hooks/news.sh` reads `mats-tools/NEWS.md`, shows unread entries once per machine
     as `systemMessage` + hands them to Claude as `additionalContext`). Writing to `NEWS.md`
     = messaging every subscriber at their next session start.
   - `mats-tools/shell/start.sh` → sourced by the `claude()` wrapper that `machine-setup`
     installs; the wrapper in the rc file stays thin, the start line evolves here. **No network**
     here — `shell/sync.sh` does plugin update + clone pulls in the background (throttled 10 min,
     `--now` for the `frisch` alias, `--after-push` from `/finish`), effective next session.
   - `mats-tools/shell/setup.sh` → the deterministic installer behind `machine-setup` (managed
     rc block, status line, settings.json merge, VS Code tweaks). The agent only runs it and
     handles its markers (`WRAPPER_CONFLICT`, `STATUSLINE_DIFFERS`, …). Validator check 7 runs
     it twice in a sandbox HOME — change the script, not the agent prose, when setup logic moves.

Skills with code, binaries or machine state are **not** here: they live in the private sibling repo
`claude-werkstatt` (`../claude-werkstatt/`, symlinked into `~/.claude/skills/`) and graduate into
`mats-tools/skills/` once they are markdown-only and useful to others. Multi-session plans (`plans/`)
live there too — this repo is public and carries nothing private by construction.

Adding a command, agent or skill = dropping a new file in the right directory with valid
frontmatter + a row in the `README.md` table (the **only** listing; the manifest descriptions
are static one-liners) + an outcome section in `reference/evals.md`. The validator enforces both.

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
- **The loop is the point.** Behaviour evals run for real via `tools/eval.sh` (headless from the
  repo source, throwaway fixture, on-disk checks; costs tokens, so not in CI). **Ritual:** a new
  model or a new Claude Code capability → `/neudenken` over this repo, then `/optimieren` per
  building block, with an `eval.sh` run before and after. A change that touches an eval's wording
  updates `evals.md` explicitly.
- **Public repo, real subscribers.** Two friends pull this plugin automatically at every
  launch; they are not programmers, trust Mats' setup, and one has rebuilt his Windows terminal
  (own status panel, start output suppressed). Consequences: nothing private or third-party in
  tracked files — **examples never use real data** (no real addresses, institutions, domains, or
  names of third parties, not even "just as an illustration"; use Musterstraße/beispiel.de; lesson
  from the 2026-08-24 history rewrite). Anything private belongs in `claude-werkstatt`, not here.
  `NEWS.md` entries are written for non-coders; `machine-setup`
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

## HIER WEITERMACHEN

- [ ] GitHub-Support-Ticket „purge cached sensitive data" (eingereicht 24.08.; Kontrolle 24.08. abends:
      alle 9 alten SHAs noch 200) — auf Antwort warten, dann erneut prüfen
      (`curl -o /dev/null -w '%{http_code}' https://github.com/MatsLuca/claude-config/commit/<sha>`),
      danach Anfragetext + beide Bundles in `9_Temp/` löschen.
- [ ] PowerShell-Block (`setup.sh`, `PWSH_BLOCK`) bewährt sich erst beim ersten echten Windows-Lauf —
      der Agent bittet den Nutzer dann um den Testlauf; nichts vorab zu tun.
- [ ] Erster echter Neu-Rechner (oder Wegwerf-Container): den `machine-setup`-Agenten einmal ganz
      durchlaufen sehen (Recon → Skript → Marker deuten → Bericht) — der Prosa-Teil ist noch nie live gelaufen.
- [ ] Wiedervorlage 2026-11-22: `inventar.sh ~/Documents` → `/optimieren claude-md`; `inventar.sh`
      GNU-Zweig einmal im Container laufen lassen.
