# enviroment

> **Centro personal Cross-IA de ingeniería, skills reutilizables, patrones arquitectónicos y optimización física de estación de trabajo.**

`enviroment` desacopla **la lógica reutilizable** (versionada en GitHub y agnóstica de herramienta de IA) del **estado vivo de cada proyecto** (que vive en tus carpetas de `G:\obsidian\<proyecto>\` junto a un manifiesto de importación `ENVIROMENT_IMPORTS.md`).

---

## ¿Por qué existe este repositorio?

1. **Cero pérdida de enfoque al retomar proyectos:** Los proyectos específicos (`Monex`, `PeraTomo`, trabajos universitarios, etc.) mantienen su estado y seguimiento en `G:\obsidian\<proyecto>\`, importando únicamente los skills y patrones necesarios desde `enviroment`.
2. **Cross-IA real (local, CLI y chats web/móvil):**
   - `AGENTS.md` actúa como contrato único, enlazado por `CLAUDE.md` y `GEMINI.md`.
   - `.agents/skills/` sigue el estándar abierto [`agentskills.io`](https://agentskills.io/) y se espeja automáticamente hacia `.claude/skills/` y `.codex/skills/` mediante script (sin depender de symlinks rotos en checkouts de Windows).
   - `00_WEB_CHAT_INDEX.md` permite operar todo el sistema desde Gemini Chat móvil/web u otros chats sin acceso al filesystem local.
3. **Pilar físico + pilar técnico:** Además de código y arquitectura, `machine/` define cómo mantener tu PC Windows + WSL2 + Docker limpia, rápida y aislada frente a instalaciones pesadas (recompilaciones nativas/C++ como `Hookshot`, stacks complejos como `FriGram`, múltiples SDKs y cachés).

---

## Inicio Rápido

### 1. Clonar en tu Workspace (fuera de Google Drive)
```powershell
# En Windows: mantener repos Git en D:\, nunca dentro de G:\ (Google Drive)
git clone https://github.com/Mikoo/enviroment.git D:\Users\Miko\Workspace\enviroment
cd D:\Users\Miko\Workspace\enviroment
```

### 2. Sincronizar Skills Globales en tu Máquina
- **Windows (PowerShell):**
  ```powershell
  .\scripts\sync-skills.ps1 -Global
  ```
  Esto copia los skills canónicos de `.agents/skills/` hacia:
  - `%USERPROFILE%\.gemini\config\skills\` *(Antigravity App + CLI + IDE — evita la trampa de `~/.gemini/config/skills.json`)*
  - `%USERPROFILE%\.agents\skills\` *(Codex CLI / Gemini CLI / estándar abierto)*
  - `%USERPROFILE%\.claude\skills\` *(Claude Code)*
- **Linux / macOS / WSL2:**
  ```bash
  ./scripts/sync-skills.sh --global
  ```

### 3. Validar Integridad del Repositorio
```bash
bash scripts/check-repo.sh
```

---

## Conectar un Proyecto en `G:\obsidian\<proyecto>\`

Copia los archivos de [`templates/obsidian-project/`](./templates/obsidian-project/) dentro de tu carpeta de proyecto en Obsidian (`G:\obsidian\<proyecto>\`):
- `PROJECT_OVERVIEW.md`
- `PROJECT_RULES.md`
- `CHANGES.md`
- `ENVIROMENT_IMPORTS.md` *(declara qué skills, patrones y perfil físico de `enviroment` importa el proyecto)*
- `CONTEXT_PACK.md` *(resumen autocontenido para pegar en chats móviles)*

Ver especificación completa en [`.agents/docs/obsidian-project-contract.md`](./.agents/docs/obsidian-project-contract.md).
