# Cross-AI Interoperability Spec (2026)

Cómo hacer que un mismo conjunto de reglas y skills funcione de forma idéntica en **Google Antigravity**, **Claude Code**, **OpenAI Codex**, **Gemini CLI**, **Cursor / VS Code** y **chats web/móvil**.

---

## 1. Matriz Oficial de Descubrimiento

| Cliente IA | Reglas Raíz / Persistentes | Skills de Proyecto | Skills Globales (Usuario) | Notas / Trampas Críticas |
| :--- | :--- | :--- | :--- | :--- |
| **Google Antigravity** (App / CLI / IDE) | `AGENTS.md`, `GEMINI.md`, `.agents/rules/*.md` (`trigger: always_on \| model_decision \| glob \| manual`) | `<root>/.agents/skills/<name>/SKILL.md` (o `.agents/skills.json` para rutas custom) | `~/.gemini/config/skills/<name>/SKILL.md` *(App + CLI + IDE)* | **TRAMPA:** `~/.gemini/config/skills.json` **NO** se expande globalmente. Límite de reglas `always_on`: 24 KB/archivo y 20k tokens totales. |
| **Claude Code** | `CLAUDE.md` (soporta `@AGENTS.md`) + `.claude/rules/*.md` | `<root>/.claude/skills/<name>/SKILL.md` | `~/.claude/skills/<name>/SKILL.md` | Pass-rate óptimo manteniendo catálogo curado (`< 100` skills activos). |
| **OpenAI Codex** (CLI / App) | `AGENTS.md` jerárquico hasta raíz Git + `~/.codex/AGENTS.md` | `<root>/.agents/skills/<name>/SKILL.md` y `.codex/skills/` | `~/.agents/skills/<name>/SKILL.md` y `~/.codex/skills/` | **TRAMPA:** Portal de plugins rechaza `metadata:` o campos arbitrarios en frontmatter de `SKILL.md`; poner UI en `agents/openai.yaml`. Budget inicial ~2% / ~8k chars. |
| **Gemini CLI** | `GEMINI.md` (configurable hacia `AGENTS.md`) | `<root>/.agents/skills/<name>/SKILL.md` | `~/.agents/skills/` y `~/.gemini/skills/` | Antigravity App no lee `~/.gemini/skills/`, por eso sincronizamos también `~/.gemini/config/skills/`. |
| **Chats Web / Móvil** (Gemini, Claude.ai, ChatGPT) | `00_WEB_CHAT_INDEX.md` + `CONTEXT_PACK.md` | Adjuntos manuales o lectura por URL / Drive | Gems / Projects / Custom Instructions | No resuelven `[[wikilinks]]` ni `@includes`; requieren Markdown GFM plano y autocontenido. |

---

## 2. Reglas Estrictas de Autoría de Skills (`agentskills.io`)

1. **Frontmatter mínimo universal en `SKILL.md`:**
   ```yaml
   ---
   name: nombre-en-kebab-case
   description: Qué hace exactamente y cuándo debe activarse (en tercera persona o imperativo; max 1024 chars).
   ---
   ```
   - `name` debe coincidir exactamente con el nombre de la carpeta (`^[a-z0-9]+(-[a-z0-9]+)*$`, <= 64 chars).
   - **Prohibido** agregar `tags:`, `author:`, `version:` o `metadata:` en el frontmatter raíz de `SKILL.md` (evita rechazos en Codex/OpenAI y mantiene limpio el parser).
   - Metadatos de interfaz para Codex van en `agents/openai.yaml` al lado de `SKILL.md`.
2. **Divulgación Progresiva (Progressive Disclosure):**
   - `SKILL.md` < 500 líneas (< 5.000 tokens). Solo reglas operativas, criterios de decisión, checklist y comandos.
   - Código largo (SQL, scripts extensos, payloads de ejemplo) va en `references/*.md` o `scripts/*` dentro de la carpeta del skill, indicando explícitamente en `SKILL.md` *cuándo* leer cada referencia.
3. **Copias reales en lugar de Symlinks dentro de Git:**
   - En Windows, los checkouts de Git pueden convertir symlinks en texto plano y linters como Prettier fallan al inspeccionarlos.
   - **Solución adoptada (patrón InsForge):** `.agents/skills/` es la única fuente de verdad (SSOT). `scripts/sync-skills.sh` y `scripts/sync-skills.ps1` generan copias idénticas en `.claude/skills/` y `.codex/skills/`, y CI ejecuta `scripts/sync-skills.sh --check` para evitar desvíos.
