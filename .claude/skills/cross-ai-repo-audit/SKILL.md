---
name: cross-ai-repo-audit
description: Use when asked to research, audit, or re-analyze an external GitHub repository or codebase and distill its real engineering architecture, cross-AI setup, patterns, and reusable skills into enviroment without superficial README summaries.
---

# Cross-AI Repository Audit & Pattern Distillation

## Scope
Deep technical audits of external repositories (`github.com/<owner>/<repo>`) to populate `references/repos/<Repo>.md`, `patterns/`, and `.agents/skills/`.

## Workflow (Verify Source, Never Trust README Alone)
1. **Inspect actual repository tree & companion repos:**
   - Check root configs, CI workflows (`.github/workflows/*`), agent configs (`.agents/`, `.claude/`, `.codex/`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`), deploy scripts, and companion skill/plugin repos.
2. **Verify every architectural claim in real code:**
   - Read the actual parser, middleware, SQL migration, compose overlay, or CLI harness implementation — never parrot README marketing bullets without verifying how the code implements them (including edge cases and Windows/Linux caveats).
3. **Check for Cross-IA and workstation lessons:**
   - Look for how the repo handles skill syncing, frontmatter compatibility, `openai.yaml`, internal docs governance (`.internal/docs`), and static script checks (`check-setup-sh`).
4. **Produce 3 structured outputs in `enviroment`:**
   - **Reference note:** `references/repos/<Repo>.md` following `templates/Template_Repo_Analysis.md` (with file paths + corrections of any prior shallow notes).
   - **Agnostic patterns:** Extract generalizable architecture into `patterns/<domain>/<pattern>.md`.
   - **Executable skills (only when genuinely reusable):** Author `<skill>/SKILL.md` (`name` + `description` only in YAML, `< 500` lines) + `agents/openai.yaml`, then run `scripts/sync-skills.sh` (or `.ps1`) and `bash scripts/check-repo.sh`.

## Do / Avoid
- **Do:** Cite exact files/functions inspected and distinguish what works on Linux/macOS vs Windows.
- **Avoid:** Generating a 30-line summary based only on the repo homepage or copying repo-specific business rules into global skills.
