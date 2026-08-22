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

## Aktueller Stand (2026-08-22)

- **CLAUDE.md-Verfassung delivered** (`plans/claude-md-verfassung.md`, waves 1–6 done + post-wave
  fix `d56d653`): skill `claude-md` (+ `verfassung.md`, `inventar.sh`), `/merken` now keeps exactly
  one dated Stand block (replaced content → `HISTORIE.md`) and sets the height header; validator
  covers skills. Ancestor chains under `~/Documents` are ≤ ~5 KB; 28 project-level CLAUDE.md still
  lack a height header (handled lazily by `/merken` / the proactive skill).
- Plugin cache on this Mac is behind the repo until `/plugin update mats-tools@claude-config` (the
  `/merken` that wrote this ran from the old cached text).

## HIER WEITERMACHEN

- [ ] `/plugin update mats-tools@claude-config`, then a fresh session — verify the new `/merken`
  sentences are in the loaded command text.
- [ ] Wiedervorlage 2026-11-22: run `inventar.sh ~/Documents`, check budgets/height headers, feed
  findings into `/optimieren claude-md` (Meta-Pflege section of the Verfassung).
- [ ] `inventar.sh` GNU branch (Linux) only statically checked — run once in a container.
- [ ] `~/Documents/9_Temp/welle*-bak/` (≈200 KB wave backups) can go once nothing is missed.
