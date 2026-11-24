# 00_WEB_CHAT_INDEX — Context Pack para Chats Web / Móvil (Cross-IA)

> **Cuándo usar este archivo:** Cuando trabajes desde **Gemini Web/App móvil**, **Claude.ai** o **ChatGPT Web** (sin acceso directo al disco local). Adjuntá o enlazá este archivo (o la URL raw en GitHub) junto con el `CONTEXT_PACK.md` y `ENVIROMENT_IMPORTS.md` de tu proyecto en `G:\obsidian\<proyecto>\`.

---

## 1. Reglas de Operación para el Chat de IA

1. **Punto de vista agnóstico:** No asumas un único agente ni un único sistema operativo. El usuario trabaja en **Windows** (`D:\Users\Miko\Workspace` para Git, `G:\obsidian` para notas de proyectos) + **WSL2/Docker** y también opera desde **chats móviles/web**, **Antigravity**, **Claude Code**, **Codex CLI** y **Gemini CLI**.
2. **Separación estricta:**
   - **Este repo (`Mikoo/enviroment`)** = librería reutilizable (skills, patrones técnicos, auditorías de repositorios, templates, optimización física de PC). No guardar aquí datos privados ni lógica específica de negocio o materias universitarias.
   - **`G:\obsidian\<proyecto>\`** = estado vivo del proyecto, tracking e importaciones explícitas (`ENVIROMENT_IMPORTS.md`).
3. **Al proponer un nuevo Skill:** respetar el estándar `agentskills.io` (`name` + `description` únicamente en el frontmatter YAML de `SKILL.md`; sin `tags:` ni `metadata:` en raíz; cuerpo `< 500` líneas; detalles largos en `references/`).
4. **Al proponer scripts o setups para Windows/Docker:** considerar separación `;` vs `COMPOSE_PATH_SEPARATOR=:` en `COMPOSE_FILE`, permisos seguros de `.env`, aislamiento de dependencias (no ensuciar el host) y verificación idempotente.

---

## 2. Catálogo Rápido de Skills Disponibles (`.agents/skills/`)

| Skill | Cuándo activarlo |
| :--- | :--- |
| `database-scalability` | Esquemas Postgres/Supabase con alta escritura (`UUIDv7`, `session_buckets` JSONB, RPC `flush_session_metrics`). |
| `pos-financial-integrity` | Órdenes, pagos, cajas o arqueos (`rpc_*` atómicas, `auth.uid()`, aritmética en centavos enteros, `react-hook-form`). |
| `dense-ui-1366x768` | Dashboards/POS en `1366x768` (~650px útiles), Zero-CLS skeletons, `colorMap` estático Tailwind v4, swipe 60 FPS GPU. |
| `docker-compose-overlays` | Stacks Docker self-hosted, `setup.sh` idempotente, `COMPOSE_FILE` multi-archivo Windows/Linux, `gen_secret`, bind `127.0.0.1`. |
| `voice-and-memory-pipeline` | Audio WebKit/Chromium (`mp4`/`webm`), iOS `AudioContext`, Silero VAD 600ms, Groq STT/LLM JSON, memoria 3 capas. |
| `tauri-v2-crossplatform` | SvelteKit SPA (`ssr = false`) + Tauri v2 (Win/macOS/iOS/Android), *Zero-Idle*, `Plugin Mode Registry`. |
| `whatsapp-cloud-webhook` | Webhooks Meta Cloud API en Edge Functions, handshake HMAC, ventana gratuita 24h vs plantillas *Utility*. |
| `resilient-python-services` | Servicios Python/FastAPI/SQS/AWS/LocalStack: HMAC sobre raw bytes, embudo HTTP defensivo, remediación convergente, `flake8`/`pylint` 10/10. |
| `cross-ai-repo-audit` | Auditar un repo nuevo de GitHub en profundidad -> ficha en `references/repos/` + patrones + skills Cross-IA. |
| `workstation-isolation` | Optimizar la PC física y decidir dónde instalar apps/juegos/stacks pesados (`Hookshot`, `FriGram`, etc.) sin contaminar Windows. |

---

## 3. Catálogo de Patrones Técnicos (`patterns/`)

- **Data:** `patterns/data/database-scalability-uuidv7-bucketing.md`
- **Backend:**
  - `patterns/backend/pos-financial-integrity-atomic-rpcs.md`
  - `patterns/backend/ast-sql-guarding-and-rls-context.md` *(de InsForge: `libpg-query` AST + `withUserContext`)*
  - `patterns/backend/sse-vs-websockets-event-streams.md` *(de InsForge: SSE admin vs Socket.IO realtime)*
  - `patterns/backend/hmac-webhooks-and-convergent-remediation.md` *(de VulcanoPay/Fenix)*
- **Frontend:**
  - `patterns/frontend/dense-data-ui-1366x768-60fps.md`
  - `patterns/frontend/monorepo-ui-host-boundary.md` *(de InsForge: `ui` -> `dashboard` -> `frontend` + `shared-schemas`)*
- **AI & Agents:**
  - `patterns/ai-agents/agent-native-cli-and-config-as-code.md` *(de InsForge: CLI `--json`, `insforge.toml`, `diagnose`)*
  - `patterns/ai-agents/cross-ai-skills-packaging-and-sync.md` *(de InsForge: `.agents` SSOT, `sync-skills.sh`, `openai.yaml`, `.internal/docs`)*
  - `patterns/ai-agents/low-latency-voice-and-3tier-memory.md`
  - `patterns/ai-agents/tauri-v2-zero-idle-and-plugin-registry.md`
- **Messaging:** `patterns/messaging/whatsapp-cloud-api-serverless-webhook.md`

---

## 4. Pilar Físico de la PC (`machine/`)

- `machine/ISOLATION_MATRIX.md`: Matriz de decisión **Host vs Toolchain portable vs Venv/uv vs Docker/Devcontainer vs Sandbox/VM** (incluye casos prácticos tipo `Hookshot` y `FriGram`).
- `machine/WINDOWS_WSL_OPTIMIZATION.md`: Límites RAM WSL2 (`.wslconfig`), separación Git `D:\` vs Google Drive `G:\`, ergonomía `1366x768`, configuración global de skills sin trampas.
- `machine/scripts/audit-host.ps1` y `cleanup-caches.ps1`: Diagnóstico solo lectura y limpieza segura (`-DryRun` por defecto).

---

## 5. Prompts Listos para Copiar en Chat Web/Móvil

### A) Retomar un proyecto de Obsidian sin perder foco
> "Lee `00_WEB_CHAT_INDEX.md` de `enviroment` y estos 3 archivos de mi proyecto en `G:\obsidian\<Proyecto>\`: `ENVIROMENT_IMPORTS.md`, `PROJECT_OVERVIEW.md`, `PROJECT_RULES.md` y `CHANGES.md`. Trabaja estrictamente bajo las reglas e imports declarados ahi. Al terminar, propone las lineas exactas para actualizar `CHANGES.md`."

### B) Investigar un repositorio nuevo con estándar `enviroment`
> "Analiza minuciosamente este repositorio usando el protocolo `.agents/skills/cross-ai-repo-audit/SKILL.md` de `enviroment`. Verifica implementaciones reales en código (no solo el README) y genera: 1) ficha tecnica para `references/repos/<Repo>.md`, 2) que patrones nuevos conviene extraer a `patterns/`, y 3) que skills nuevos o actualizaciones corresponden en `.agents/skills/`."

### C) Evaluar dónde instalar una herramienta o juego pesado sin contaminar la PC
> "Quiero usar/instalar `<NombreToolOApp>` en mi Windows. Evalua sus dependencias reales contra `machine/ISOLATION_MATRIX.md` de `enviroment` y dame el plan exacto de instalacion aislada (portable, venv, Docker o Sandbox/VM) sin ensuciar el host."
