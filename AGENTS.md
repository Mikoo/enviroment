# AGENTS.md — Canonical Cross-AI Contract

This repository (`enviroment`) is the **AI-agnostic single source of truth** for engineering workflows, reusable technical skills, architectural patterns, repository audits, and physical workstation optimization.

It is intentionally separated from project-specific business data (which lives in Obsidian / Google Drive per-project folders) so any AI agent or web chat can load clean, modular engineering context without hallucinating or hitting token bloat.

## 1. Core Principles (All Agents & Chats)

1. **Progressive Disclosure First:**
   - Do **not** read `patterns/` or `references/` upfront unless the task specifically requires deep background.
   - Start with the active skill in `.agents/skills/<skill-name>/SKILL.md`, then read its `references/` only when needed.
   - If working on an external project (e.g., in `G:\obsidian\<project>\`), read that project's `PROJECT_OVERVIEW.md`, `PROJECT_RULES.md`, `CHANGES.md`, and `ENVIROMENT_IMPORTS.md` before proposing changes.
2. **Strict Separation of Concerns (Logic vs. Project State):**
   - `enviroment` stores **reusable logic**: skills, universal patterns, repository references, templates, and physical workstation optimization.
   - Never commit project-specific business rules, university class transcripts, client data, credentials, `.env` secrets, or local machine passwords here.
3. **Cross-AI Standard Compliance:**
   - `.agents/skills/` is the canonical source of truth following the open `agentskills.io` specification.
   - Keep `SKILL.md` frontmatter minimal (`name` and `description` only; optional `license`/`compatibility`). Never add `tags:` or `metadata:` to `SKILL.md` frontmatter (rejected by Codex plugin validation); put Codex UI metadata in `agents/openai.yaml`.
   - Keep `SKILL.md` concise (`< 500` lines); push deep SQL/code recipes into `references/`.
   - Write Markdown in standard GitHub-Flavored Markdown (GFM). Avoid Obsidian-only `[[wikilinks]]` inside `.agents/skills/` or root files so web chats and non-Obsidian tools resolve paths unambiguously.
4. **Windows-First Path & Isolation Hygiene:**
   - Developer workstation uses Windows (`D:\Users\Miko\Workspace` for Git checkouts, `G:\obsidian` for Obsidian/Google Drive project notes) alongside WSL2/Docker and Linux devboxes.
   - Never place `.git` repositories inside Google Drive (`G:\`) to avoid sync lock corruption.
   - Never rely on Git symlinks for cross-agent skill discovery on Windows; run `scripts/sync-skills.sh` (Linux/macOS/WSL) or `scripts/sync-skills.ps1` (Windows) to generate byte-identical mirrors in `.claude/skills/` and `.codex/skills/`.
   - Never pollute the host OS with project-specific toolchains when `.venv`/`uv`, Docker Compose, Devcontainers, or Sandbox/VM isolation applies (see `machine/ISOLATION_MATRIX.md`).
5. **Verification Before Claiming Done:**
   - After editing skills, scripts, or docs in this repository, run `bash scripts/check-repo.sh`.

## 2. Repository Map

| Path | Purpose | Auto-loaded by Agents? |
| :--- | :--- | :--- |
| `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` | Canonical entry rules and tool pointers | **Yes** |
| `00_WEB_CHAT_INDEX.md` | Single-file compact index for Gemini/Claude/ChatGPT web & mobile chats | Manual / Chat attach |
| `.agents/skills/<name>/SKILL.md` | Canonical Cross-AI executable skills (SSOT) | **Yes** (metadata at startup, body on demand) |
| `.claude/skills/`, `.codex/skills/` | Auto-synced mirrors for Claude Code and Codex | **Yes** (per-client native paths) |
| `.agents/docs/` | Cross-AI interoperability and Obsidian import contract specs | On demand |
| `patterns/` | Deep, domain-organized reusable engineering patterns | On demand |
| `references/repos/` | Detailed repository audits (e.g., `InsForge.md`) | On demand |
| `machine/` | Physical PC optimization, `.wslconfig`, isolation matrix, cleanup & audit scripts | On demand |
| `templates/` | Drop-in templates for `G:\obsidian\<project>\`, skills, ADRs, repo audits | On demand |
| `scripts/` | Skill mirroring, web-chat index validation, and CI invariant checks | Execution tools |
