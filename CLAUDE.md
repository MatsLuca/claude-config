# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal **Claude Code plugin marketplace** — not an app. There is no build, lint, or
test step. The "source" is a set of structured Markdown + JSON manifests that Claude Code
loads as slash-commands and subagents. To "test" a change, install/update the plugin
locally and invoke the command/agent (see *Local testing*).

## Architecture

Three nesting levels, each with its own manifest:

1. **Marketplace** — `.claude-plugin/marketplace.json` declares the marketplace `claude-config`
   and lists its plugins. Each plugin entry points at a subdirectory via `source` (e.g. `./mats-tools`).
2. **Plugin** — `mats-tools/.claude-plugin/plugin.json` is the plugin manifest.
   Commands and agents are auto-discovered from convention directories, *not* listed in the manifest.
3. **Commands & agents** — Markdown files with YAML frontmatter:
   - `mats-tools/commands/*.md` → slash-commands (filename = command name, so `finish.md` → `/finish`).
   - `mats-tools/agents/*.md` → subagents (the `name:` field in frontmatter is the agent id).

Adding a command or agent = dropping a new `.md` file in the right directory with valid
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
  round (cheap overview first, full content only when needed), and target macOS tooling
  (e.g. `date -v` offsets, `open` for Xcode). Follow this pattern in new commands.

## Local testing

```bash
# First time on a machine:
/plugin marketplace add <github-user>/claude-config
/plugin install mats-tools@claude-config

# After pushing changes:
/plugin update mats-tools@claude-config
```

Then invoke the command (`/finish`, `/xcode`, …) or trigger the agent to verify behavior.
