# GEMINI.md

Read and follow @[AGENTS.md](./AGENTS.md) as the canonical ruleset for this repository.

## Gemini CLI & Google Antigravity Notes

- Workspace skills are read directly from `.agents/skills/<skill>/SKILL.md`.
- **Important Antigravity Global Rule Trap:** Antigravity does **not** expand `~/.gemini/config/skills.json` at the global level. To use these skills globally across all projects on Windows or Linux/macOS, run `scripts/sync-skills.ps1 -Global` (Windows) or `scripts/sync-skills.sh --global` (Linux/macOS) to populate `~/.gemini/config/skills/` cleanly alongside `~/.agents/skills/` and `~/.claude/skills/`.
- For Gemini Web / Mobile chats without filesystem access, start from `00_WEB_CHAT_INDEX.md` and attach the target project's `ENVIROMENT_IMPORTS.md` + `CONTEXT_PACK.md`.
