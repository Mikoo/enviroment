---
name: workstation-isolation
description: Use when deciding how to install, build, isolate, or clean up tools, games, compilers, or heavy multi-dependency stacks (e.g. Hookshot, FriGram, Docker/WSL2, LocalStack, C++ toolchains) without contaminating the Windows host OS, or when optimizing daily PC disk/RAM/display ergonomics.
---

# Workstation Isolation & Physical PC Optimization

## Scope
Keeping the Windows host fast, clean, and reproducible across software development, experimental stacks, and native games/recompilations.

## Decision Ladder (Always Pick Highest Safe Isolation)
1. **Level 4 — VM / Windows Sandbox / Dedicated WSL2 Distro:** Unknown installers, registry-heavy tools, invasive one-off Visual Studio MFC/SDK builds, or dirty Linux experiments (`wsl --import` + `--unregister`).
2. **Level 3 — Docker Compose / Devcontainer:** Multi-service stacks (`Postgres + PostgREST + Deno`, `LocalStack`, `FriGram`-style complex dependencies). Always set `COMPOSE_PROJECT_NAME`, bind ports to `127.0.0.1`, and `docker compose down` when switching tasks.
3. **Level 2 — Language Virtual Env (`uv` / `.venv` / `nvm` / `fnm`):** Standard Python/Node project dependencies inside `D:\Users\Miko\Workspace\<project>`.
4. **Level 1 — Portable / Self-Contained on `D:\`:** Standalone binaries or portable compilers (`llvm-mingw`) that avoid polluting global Windows `PATH` or `%LOCALAPPDATA%`.
5. **Level 0 — Native Host:** Only GPU drivers, core editor, Git, Docker Desktop, and final native Vulkan/gaming binaries needing direct GPU access (compile via portable/isolated tooling whenever possible, then purge intermediate build caches).

## Physical Host Hygiene Rules
- **Git vs Google Drive:** Keep Git repos strictly on `D:\Users\Miko\Workspace\`; keep ONLY Markdown/project notes in `G:\obsidian\`. Never put `.git` or `.venv` inside Google Drive.
- **WSL2 RAM Cap:** Enforce `%USERPROFILE%\.wslconfig` (`memory=6GB`, `autoMemoryReclaim=gradual`, `sparseVhd=true`) so Docker/WSL2 cannot starve Windows.
- **Safe Cleanup:** Run `machine/scripts/audit-host.ps1` (read-only) and `machine/scripts/cleanup-caches.ps1` (`-DryRun` by default; `-Execute` only after review). Never touch `~/.gemini/antigravity` or `~/.gemini/config`.

## Deep Reference
Read `../../../machine/ISOLATION_MATRIX.md` and `../../../machine/WINDOWS_WSL_OPTIMIZATION.md` for `Hookshot`/`FriGram` playbooks and exact `.wslconfig` / PowerShell commands.
