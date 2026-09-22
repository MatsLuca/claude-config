# CLAUDE.md — claude-config (Projekt)

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**A toolbox for working with Claude that sharpens itself through the work done with it**
(purpose fixed by `/neudenken`, 2026-08-24). Technically a personal **Claude Code plugin
marketplace** — not an app, no build step: structured Markdown + JSON manifests that Claude
Code loads as slash-commands, subagents and skills. The private sibling `claude-werkstatt`
holds everything with code, accounts or private notes (aliases `kasten` / `werkstatt`;
placement rule and recipes in `~/.claude/reference/werkzeugkasten.md`). There **is** a check: `tools/validate.sh` verifies manifests,
frontmatter, listing sync, plugin-internal references, portability, and (where `claude` is
installed) calls the native `claude plugin validate` — run it after any change to
commands/agents/manifests (CI runs it on every push via `.github/workflows/validate.yml`). Behavior is verified against the outcome-level scenarios
in `mats-tools/reference/evals.md` — interactively or headless (see the Loop section there).

## Architecture

Three nesting levels, each with its own manifest:

1. **Marketplace** — `.claude-plugin/marketplace.json` declares the marketplace `claude-config`
   and lists its plugins. Each plugin entry points at a subdirectory via `source` (e.g. `./mats-tools`).
2. **Plugin** — `mats-tools/.claude-plugin/plugin.json` is the plugin manifest.
   Commands and agents are auto-discovered from convention directories, *not* listed in the manifest.
3. **Commands, agents & skills** — Markdown files with YAML frontmatter:
   - `mats-tools/commands/*.md` → slash-commands (filename = command name, so `finish.md` → `/finish`).
     Technically skills as flat files: Claude Code merged commands into skills (2026), so the
     model can start them via the Skill tool too — `disable-model-invocation: true` marks the ones
     only the user may start (`/finish`, `/finish-lite`).
   - `mats-tools/agents/*.md` → subagents (the `name:` field in frontmatter is the agent id).
   - `mats-tools/skills/<name>/SKILL.md` → skills (user-invocable *and* model-triggered via
     `description`); companion files live next to the SKILL.md (e.g. `claude-md/verfassung.md`,
     `claude-md/scripts/inventar.sh`) and are referenced as `${CLAUDE_PLUGIN_ROOT}/skills/<name>/…`.

   - `mats-tools/hooks/hooks.json` → plugin hooks, both SessionStart: **start-timer**
     (`hooks/start-timer.sh`: Startdauer je Phase aus den Stempeln `MATS_START_T0`/`MATS_T_RC`/
     `MATS_T_WRAP`/`MATS_T_EXEC`, still ins Log (Terminal-Zeile und Modell-Kontext nur mit `MATS_START_TIMER_SHOW=1`), Log `~/.cache/mats-tools/start-timer.log`,
     `--tail`/`--self`) and the **news hook** (`hooks/news.sh` reads `mats-tools/NEWS.md`, shows unread entries once per machine
     as `systemMessage` + hands them to Claude as `additionalContext`). Writing to `NEWS.md`
     = messaging every subscriber at their next session start.
   - `mats-tools/shell/start.sh` → sourced by the `claude()` wrapper that `machine-setup`
     installs; the wrapper in the rc file stays thin, the start line evolves here. **No network**
     here — `shell/sync.sh` does plugin update + clone pulls in the background (throttled 10 min,
     `--now` for the `frisch` alias, `--after-push` from `/finish`), effective next session.
     Step 0 also updates Claude Code itself, gated on a speed probe (≥ 1 MB/s) so bad Wi-Fi
     never starts a download; the built-in auto-updater is off (`DISABLE_AUTOUPDATER=1`,
     merged by `setup.sh`).
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
  templates* (e.g. `## Aufgabe`) since reports go to German users. Keep new commands German and
  new agents English-instructions/German-output unless asked otherwise.
- **Auftrag vor Rezept** (authoring-guide, since the Claude 5 pass on 2026-09-01): a command states
  the outcome and the inviolable rules; the model finds the way. Literal bash blocks only where an
  eval run proves the model fails without them (a comment names the reason). Few tool rounds,
  independent calls in parallel — no mandated one-liners: compound `&&`/`$(…)` commands collide
  with narrowed `allowed-tools`, and the model splits them anyway. `finish`, `finish-lite`, `merken`
  are the reference implementations; `neues-projekt` and `destillieren` followed on 2026-09-01/02.
  `einarbeiten` was removed on 2026-09-02 (16 uses, all in June/July 2026, none since; the model
  does it unprompted, `claude-md` governs the target file).
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
  repo source, throwaway fixture, on-disk checks for finish, finish-lite, merken, xcode; costs
  tokens, so not in CI). The native `claude plugin eval` (cases in `mats-tools/evals/<case>/`,
  sharing the fixtures via `scaffold.sh`) adds the with/without-plugin comparison, regex/file graders
  and an LLM judge, but cannot check git state (pushed? tree clean?) — it is the instrument of `/neudenken` (does the block beat bare
  Claude?), `eval.sh` the instrument of `/optimieren` (did the edit keep the outcome?) — except for skills,
  which the runner cannot trigger headless: there the native case with `--ablation none` is `/optimieren`'s
  before/after too (first used for `42`, 2026-09-22). **Ritual:** a new
  model or a new Claude Code capability → `/neudenken` over this repo, then `/optimieren` per
  building block, with an `eval.sh` run before and after. A change that touches an eval's wording
  updates `evals.md` explicitly.
- **Public repo, real subscribers.** Two friends pull this plugin automatically at every
  launch, but use it only rarely (Mats, 2026-09-22); they are not programmers, trust Mats' setup, and one has rebuilt his Windows terminal
  (own status panel, start output suppressed). So: keep their setup from breaking, but build no
  new subscriber-only features (the PowerShell block stays parked). Consequences: nothing private or third-party in
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

## Aktueller Stand (2026-09-22)

**`/neudenken` mit Opus 5.5** (erste Session hier mit dem Modell). Urteil: gesund, Umbau im Detail —
am selben Abend umgesetzt. Mats: die zwei Abonnenten nutzen das Plugin nur selten → keine neuen
Abonnenten-Features, ihr Setup nur nicht brechen.

- **Belege:** Nutzung seit 02.09. (merken 33× getippt + 24× vom Modell, finish 18, finish-lite 17,
  42 3+10, claude-md 7; Werkstatt 50 Commits gegen 3 hier). Natives Eval mit/ohne Plugin (3,49 $):
  finish-lite 0,25 → 0,75, merken 0,50 → 0,78, finish 0,87 → 1,0 — die Lücken mit Plugin waren
  Grader-Fehler (unten). Doku-Abgleich 2.1.280: Marketplace-`autoUpdate` gibt es (opt-in, ersetzt nur
  den Plugin-Teil von sync.sh), Function Hooks weiter hinter Flag (Mods bleiben Werkstatt),
  Hintergrundprozesse aus SessionStart-Hooks fragil (Issue #43123 → der rc-Wrapper bleibt richtig).
- **`/merken` + Git:** nach „ja, committen und pushen" (5 von 9 Folgeantworten seit 02.09.) pushte
  Claude frei Hand, ohne Remote-Abgleich. Jetzt: auf Zustimmung nur eigene Dateien, `pull --rebase`
  → Push, Konflikt → Abbruch, `--after-push`; `/merken und pushen` = Zustimmung vorab; Änderungen in
  anderen Repos nennt das Angebot mit. Runner-Szenario `merken:push` vorher 3/5 (Push abgelehnt,
  zweite Runde nötig), nachher 5/5; `merken:stand` 5/5, `finish-lite:sync` 3/3.
- **Evals repariert:** `finish-lite-sync/stand-commit` prüfte den Aufruf statt das Ergebnis → Reflog
  `.git/logs/HEAD`; `merken-stand/criteria` widersprach merkens eigener Regel (Entscheidung als
  Konvention nach vorn) → beides zulässig; `stand-heute` hatte `2026-09` fest verdrahtet (wäre im
  Oktober rot) → „datiert, nicht 2026-08-01". Nachher nativ: finish-lite 1,0 ×2, merken 1,0 ×3.
- `marketplace.json` warb noch mit „PDF→Markdown" → wörtlich = plugin.json, Validator prüft das.
- Start-Timer gibt Claude keinen Kontext mehr (~100 Token je Session) — nur Log, sichtbar mit
  `MATS_START_TIMER_SHOW=1`.
- `/neudenken` stützt sich bei Claude-Werkzeugen auch auf die echte Nutzung (history.jsonl, Transkripte).

## HIER WEITERMACHEN

- [x] `/feedback` abgeschickt am 02.09. (Early Access für `plugin eval`, Receipt 7867cf1b). Am 15.09.
      frei — Selbsttest, drei Fälle, `/neudenken` und `/optimieren finish` am selben Tag (Stand-Block).
- [ ] Ritus fortsetzen, ein Ziel je Session, `/optimieren` macht den Ablauf selbst (Szenario anlegen,
      Eval vorher, schärfen, Eval nachher, Validator). Reihenfolge nach Nutzung, Erledigtes abhaken:
      - [x] `/optimieren neues-projekt` (01.09.: 97→79 Zeilen, Runner-Szenarien leer/vorhanden/nachruesten, 14/14 grün)
      - [x] `/optimieren destillieren` (02.09.: 75→49 Zeilen, Auftrag vor Rezept, Runner-Szenarien drift/gesund, 8/8 grün)
      - [x] `/optimieren einarbeiten` → gestrichen (02.09.: 0 Aufrufe in allen Transkripten seit 7.8., Zweck ohne Command erfüllt)
      - [x] `/optimieren machine-setup` (02.09.: Description 1373→~330 Zeichen ohne Beispielblöcke, `tools:` gesetzt, awk-Fallback raus — `${CLAUDE_PLUGIN_ROOT}` expandiert im Agent-Body nachweislich —, Rückfrage-Regel für Subagenten; Live-Lauf auf Mats' Mac vorher/nachher 8→7 Tool-Aufrufe, nichts verändert)
      - [x] `/optimieren 42` (22.09.: Auslöser = Erörtern statt Auftrag, auch mit Heimat; eine Frage je Antwort; Alltagssprache; Bündeln erlaubt; native Fälle `42-idee` 0,5→1,0 ×3, `42-auftrag` 3/3)
      - [ ] danach die meistgenutzten Werkstatt-Skills: `gmail` (23 Modell-Aufrufe seit 02.09.), `erinnerungen` (17)
- [x] GitHub-Support-Ticket „purge cached sensitive data" (eingereicht 24.08.): am 02.09. alle 9 alten SHAs 404,
      Anfragetext und beide Bundles in `9_Temp/` gelöscht.
- [~] PowerShell-Block (`setup.sh`, Schritt 1W) — geparkt 02.09.: nur Syntax-geprüft, echter Windows-Lauf
      erst wenn ein Abonnent den Agenten laufen lässt und Rückmeldung gibt; nichts vorab zu tun (22.09.:
      Abonnenten nutzen das Plugin selten — bleibt geparkt).
- [ ] Erster echter Neu-Rechner (oder Wegwerf-Container): den `machine-setup`-Agenten einmal auf einer
      leeren Maschine sehen. Live gelaufen ist er bisher nur als Re-Run auf Mats' Mac (02.09., headless:
      Konflikt-Marker korrekt gedeutet, nichts überschrieben). Sandbox-HOME headless geht auf macOS nicht
      (Keychain-Login hängt am Config-Pfad) — deshalb kein Runner-Szenario für Agents.
- [ ] Befunde aus `/optimieren claude-md` (02.09., Inventar über `~/Documents`): `~/.claude/CLAUDE.md` liegt mit
      4,5 KB über dem 4-KB-Budget; 30 von 46 CLAUDE.md haben keine Höhen-Kopfzeile; drei Projekt-Dateien
      über 280 Zeilen (LatexTerm, RT-B, japan-crew) und Projektarbeit mit 101 KB. Wartungsgänge per
      `/claude-md <pfad>`, eine Datei je Session.
- [x] Erfolgsfall von sync.sh Schritt 0: `cc NEU 2.1.274` (17.09.) bis 2.1.278 im Log, 2.1.280 installiert;
      die 0-Byte-Leiche 2.1.273 ist weg (geprüft 22.09.).
- [ ] Nur falls sync.sh ohnehin angefasst wird: den Plugin-Teil durch natives Marketplace-`autoUpdate`
      (settings.json, via setup.sh) ersetzen — vorher prüfen, dass es den Start in schlechtem WLAN nicht bremst.
- [ ] Wiedervorlage 2026-11-22: `inventar.sh ~/Documents` → `/optimieren claude-md`; `inventar.sh`
      GNU-Zweig einmal im Container laufen lassen.
