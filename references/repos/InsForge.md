---
type: repo-analysis
repo: https://github.com/InsForge/InsForge
companion_repo: https://github.com/InsForge/insforge-skills
reviewed: 2026-11-24
version_or_commit: v2.3.5 (4c7e5c2) / insforge-skills v1.3.0
license: Apache-2.0
---

# Análisis Profundo: InsForge (`InsForge/InsForge` + `InsForge/insforge-skills`)

> Re-análisis completo realizado directamente sobre el código fuente de ambos repositorios para reemplazar la ficha superficial inicial y extraer todos los patrones aplicables a `enviroment` (tanto de backend/infraestructura como de arquitectura Cross-IA).

---

## 1. Resumen Ejecutivo

**InsForge** es una plataforma Backend-as-a-Service (BaaS) open-source diseñada desde cero bajo el paradigma **Agent-Native**: asume que el operador principal no es un humano haciendo clic en un dashboard, sino un agente de codificación operando desde terminal, archivos declarativos y salidas JSON estructuradas.

Además del producto en sí, la organización mantiene una de las implementaciones más maduras de **gestión Cross-IA de skills, documentación interna y scripts de despliegue auditados en CI** vista en producción en 2026.

---

## 2. Arquitectura y Stack Verificados en Código

| Capa / Paquete | Tecnología | Contrato y Límite de Responsabilidad |
| :--- | :--- | :--- |
| **Monorepo** | Turborepo + npm workspaces (`package.json`, `turbo.json`) | Orquesta `backend`, `frontend`, `packages/*` con `typecheck`, `lint`, `test`, `build`. |
| **Contratos** | `@insforge/shared-schemas` (`packages/shared-schemas/src/*.schema.ts`) + `openapi/*.yaml` | Única fuente de verdad de esquemas Zod y tipos TS para backend, dashboard, SDKs y MCP. Prohibido usar `any`. |
| **Design System** | `@insforge/ui` (`packages/ui/`) | Primitivos genéricos (Radix + `class-variance-authority` + `cn()`). |
| **Dashboard Dual** | `@insforge/dashboard` (`packages/dashboard/`) | Producto compartido para modos `self-hosting` y `cloud-hosting`, desacoplado del shell host (`frontend/`). |
| **Shell Self-Host** | `frontend/` (React + Vite) | Solo bootstrap, variables de entorno locales y montaje de `packages/dashboard/` en modo self-hosted. |
| **Backend API** | Express + TypeScript ESM (`.js` specifiers) (`backend/src/`) | Capas estrictas: `route -> service -> provider/infra`. Solo el service layer toca Postgres. |
| **Base de Datos** | PostgreSQL 15 + PostgREST (`v12.2.12`) + `pgvector` + `pg_cron` | Migraciones idempotentes (`backend/src/infra/database/migrations/`), RLS por transacción vía `withUserContext`. |
| **Edge Functions** | Deno (`denoland/deno:alpine-2.0.6`, `functions/server.ts`) | Worker template aislado con `--no-lock` sobre volumen `:ro`. |
| **Storage** | Filesystem local o gateway S3 (`MinIO` / `RustFS` / S3) | Overlays Compose; en modo proxy (`S3_USE_PRESIGNED_URLS=false`), los bytes pasan por backend sin exponer puertos de MinIO/RustFS. |
| **Interfaz Agentes** | MCP + `@insforge/cli` (`--json`, `-y`, exit codes 0..5) + `insforge.toml` | CLI como interfaz principal de bajo consumo de tokens; MCP para inspección/deploy directo. |

---

## 3. Prácticas de Ingeniería Destacables (Verificadas Archivo por Archivo)

### A. Arquitectura Cross-IA y Gestión de Skills (`InsForge` + `InsForge/insforge-skills`)
1. **SSOT en `.agents/skills/` + Espejo con Copias Reales (`scripts/sync-skills.sh`):**
   - La fuente única de verdad vive en `.agents/skills/insforge-dev/` (con sub-skills por dominio: `backend`, `dashboard`, `ui`, `shared-schemas`, `docs`, `e2e-testing`).
   - `scripts/sync-skills.sh` copia byte-a-byte hacia `.claude/skills/insforge-dev/` y `.codex/skills/insforge-dev/`.
   - **Lección clave para Windows:** el script documenta explícitamente que *no usan symlinks* porque los checkouts de Git en Windows los rompen y Prettier falla sobre symlinks. En CI (`.github/workflows/lint-and-format.yml`), `scripts/sync-skills.sh --check` falla el build si hay drift.
2. **Empaquetado Multi-Agente en `InsForge/insforge-skills`:**
   - Separan skills de **contribuidores del repo** (`InsForge/.agents/skills/insforge-dev/`) de skills **para usuarios del producto** (`InsForge/insforge-skills/skills/{insforge,insforge-cli,insforge-debug,insforge-integrations}`).
   - Un mismo árbol `skills/` sirve simultáneamente a `.agents/plugins/marketplace.json`, `.claude-plugin/{plugin,marketplace}.json` y `.codex-plugin/plugin.json`.
   - **Trampa descubierta por ellos en `AGENTS.md`:** el portal de Codex/OpenAI rechaza bloques `metadata:` dentro del YAML frontmatter de `SKILL.md`. Por eso `SKILL.md` lleva únicamente `name` + `description` (+ `license` opcional), y los metadatos visuales/prompts de Codex viven aparte en `agents/openai.yaml`.
3. **Skills Externos Vendored + Override Local (`.claude/skills/doc-author/`):**
   - `SKILL.md` se sincroniza verbatim desde `mintlify/docs` mediante `scripts/update-mintlify-skill.sh` (verificando licencia MIT), mientras que las convenciones propias de InsForge viven al lado en `INSFORGE.md`. Así se evitan conflictos al actualizar skills de terceros.
4. **Gobernanza Documental de 5 Zonas (`.internal/docs/README.md`):**
   - `docs/` (público Mintlify, validado bidireccionalmente contra `docs/docs.json`)
   - `.internal/docs/{plans,specs,audits}/` (documentos internos de trabajo)
   - `.agents/docs/` (referencias de dominio para agentes, ej. `payments-stripe.md`, `real-time.md`)
   - `.archive/docs/deprecated/` (material obsoleto aislado)
   - `.agents/skills/` (procedimientos accionables)

### B. Seguridad SQL, RLS y Eventos
5. **AST SQL Guarding con `libpg-query` (`backend/src/utils/sql-parser.ts`):**
   - No dependen de regex frágiles para filtrar SQL crudo. Usan el parser WASM real de PostgreSQL (`parseSync` de `libpg-query`) en `checkSqlExecutionGuards()` y `checkSqlReadOnly()` para bloquear `SET ROLE`, `session_authorization`, `search_path`, `statement_timeout`, `RESET ALL`, gestión de roles/bases, transacciones manuales y `set_config`.
   - Separan `/api/database/advance/rawsql` (ejecución bajo rol `project_admin`) de `/rawsql/unrestricted` (privilegios root) y ejecutan `system.reassign_public_objects_to_project_admin()` tras DDL sin restricciones.
6. **RLS por Transacción (`withUserContext` en `backend/src/services/database/user-context.service.ts`):**
   - En rutas autenticadas de usuario final, en lugar de filtrar manualmente `WHERE user_id = $1` en código JS/TS, abren una transacción, aplican `SET LOCAL ROLE` + `set_config('request.jwt.claims', ...)` y dejan que PostgreSQL evalúe `auth.jwt() ->> 'sub'` vía políticas RLS.
   - Rutas que emiten URLs firmadas fuera de banda (S3 presigned URLs) hacen un chequeo explícito de visibilidad RLS previo (`StorageService.objectIsVisible`) porque el cliente redime la URL sin pasar por Postgres.
7. **SSE vs. Socket.IO (`backend/src/api/routes/dashboard/events.routes.ts` vs. `realtime.manager.ts`):**
   - **Matiz real:** InsForge usa **SSE (`text/event-stream`)** con keepalive cada `25s` y `X-Accel-Buffering: no` para el stream unidireccional de eventos administrativos del dashboard (`/api/dashboard/events`).
   - Pero **mantiene Socket.IO + `pg_notify`** para el módulo Realtime orientado a apps (presencia efímera y pub/sub bidireccional).

### C. Despliegue Idempotente, Guardas Estructurales y Agent-Native Ops
8. **`deploy/setup.sh` + `scripts/check-setup-sh.sh`:**
   - `deploy/setup.sh` soporta descarga dual (Git sparse-checkout `--no-cone` o `curl` puro sin Git vía `INSFORGE_NO_GIT=1`), verifica `-e "$TARGET/.git"` (para no romper git worktrees donde `.git` es archivo), genera secretos vía `gen_secret()` borrando `.env` si `openssl` falla (evita dejar prefijos vacíos como `ACCESS_API_KEY=ik_`), aplica `chmod 600 .env`, y fija `COMPOSE_FILE=deploy/docker-compose/docker-compose.yml`.
   - `scripts/check-setup-sh.sh` codifica cada bug histórico del script como una aserción estática que corre en CI (`lint-and-format.yml`), incluyendo verificar que todo volumen montado en Compose exista en la lista `FILES` del script.
9. **Primitivas Agent-Native (`docs/agent-native/`):**
   - **CLI Harness (`@insforge/cli`):** `--json`, `-y/--yes`, códigos de salida semánticos (`0` ok, `1` error general, `2` no autenticado, `3` no vinculado, `4` no encontrado, `5` sin permisos) y preferencia por `npx @insforge/cli` (sin instalación global).
   - **Config-as-Code (`insforge.toml`):** `config plan`, `config apply --dry-run / --auto-approve`, `config export`, resolviendo secretos con `env(VAR)` para poder versionar el archivo sin credenciales.
   - **Diagnóstico y Memoria (`diagnose`, `memory`):** `diagnose --json` + `diagnose --ai` para cerrar hallazgos de advisor/RLS sin abrir dashboard, y `memory list / remember` para persistir decisiones y gotchas en el proyecto vinculado.

---

## 4. Correcciones respecto a la Ficha Anterior del ZIP

1. El ZIP sugería usar `COMPOSE_FILE=docker-compose.yml:docker-compose.minio.yml` con `:` (lo cual falla en Windows nativo sin `COMPOSE_PATH_SEPARATOR=:` y apunta al Compose de desarrollo en lugar de `deploy/docker-compose/docker-compose.yml`).
2. El ZIP resumía el SQL hardening como "bloqueo de DDL/DML en esquemas de sistema" cuando el mecanismo real destacable es **parsing AST con `libpg-query`** + aislamiento por roles Postgres (`project_admin`).
3. El ZIP decía que se migraron eventos internos de Socket.IO a SSE sin aclarar la frontera: SSE se usa para telemetría unidireccional del dashboard, mientras Socket.IO + `pg_notify` sigue activo para Realtime de aplicaciones.
4. El ZIP omitió por completo la arquitectura Cross-IA de InsForge (`sync-skills.sh`, `agents/openai.yaml`, `doc-author` vendored, `.internal/docs/`, `check-setup-sh.sh`, `insforge.toml` y CLI `--json`).

---

## 5. Patrones y Skills Extraídos en `enviroment`

- `patterns/ai-agents/cross-ai-skills-packaging-and-sync.md`
- `patterns/ai-agents/agent-native-cli-and-config-as-code.md`
- `patterns/backend/ast-sql-guarding-and-rls-context.md`
- `patterns/backend/sse-vs-websockets-event-streams.md`
- `patterns/frontend/monorepo-ui-host-boundary.md`
- `.agents/skills/docker-compose-overlays/` *(actualizado con separador Windows, `gen_secret` y `check-setup-sh`)*
- `.agents/skills/cross-ai-repo-audit/` *(metodología para replicar este nivel de análisis en futuros repositorios)*
- `machine/scripts/check-machine-scripts.sh` *(adaptado directamente de `scripts/check-setup-sh.sh`)*

---

## 6. Fuentes y Links de Seguimiento
- **Repositorio principal:** https://github.com/InsForge/InsForge
- **Repositorio público de skills:** https://github.com/InsForge/insforge-skills
- **Documentación oficial:** https://docs.insforge.dev
