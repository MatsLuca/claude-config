# HISTORIE — claude-config

Ersetzte Stand-Blöcke aus der CLAUDE.md, neueste zuerst (geschrieben von `/merken`).

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
