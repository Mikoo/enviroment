# CLAUDE.md

Read and follow @[AGENTS.md](./AGENTS.md) as the canonical ruleset for this repository.

## Claude Code Notes

- Canonical skills live in `.agents/skills/` and are mirrored into `.claude/skills/` via `scripts/sync-skills.sh` (or `scripts/sync-skills.ps1` on Windows).
- Edit **only** `.agents/skills/<name>/` and re-run the sync script; never edit `.claude/skills/` directly or CI will fail with drift.
- After modifying skills or scripts, run `bash scripts/check-repo.sh`.
