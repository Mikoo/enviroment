---
name: docker-compose-overlays
description: Use when designing, hardening, or debugging self-hosted Docker Compose stacks, modular compose overlays via COMPOSE_FILE, idempotent setup.sh bootstrap scripts, .env secret generation, or multi-instance port isolation on Windows and Linux.
---

# Docker Compose Overlays & Idempotent Setup

## Scope
Self-hosted Docker Compose architectures, overlay composition (`docker-compose.prod.yml` + optional storage/monitoring overlays), and idempotent initialization scripts (`setup.sh`).

## Core Rules
1. **Idempotent `setup.sh` with atomic secret safety:**
   - Guard against touching non-self-host dev checkouts **before** modifying files (`[ -e "$TARGET/.git" ]` handles linked worktrees where `.git` is a file, unlike `-d`).
   - Generate cryptographic secrets (`JWT_SECRET`, `ENCRYPTION_KEY` separately from JWT, `POSTGRES_PASSWORD`, prefixed keys) via a dedicated `gen_secret()` helper that aborts and deletes partial `.env` if `openssl rand` fails (never write empty prefixes like `ik_` via `set_var`).
   - Apply `chmod 600 .env` and never overwrite an existing `.env` on re-runs (only reconcile missing `COMPOSE_FILE`).
2. **Compose Overlays via `COMPOSE_FILE` (Cross-Platform Windows + Linux):**
   - Separate the development compose (`docker-compose.yml` mounting source) from the production/image-only compose (`deploy/docker-compose/docker-compose.yml`).
   - Always set `COMPOSE_PROJECT_NAME` and `COMPOSE_PATH_SEPARATOR=:` inside `.env` when using `:` separators (`COMPOSE_FILE=deploy/docker-compose/docker-compose.yml:docker-compose.minio.yml`) so Windows native Docker Compose (whose default separator is `;`) behaves identically to Linux/WSL2.
3. **Minimal Host Exposure & Security:**
   - Bind internal DBs, admin ports, and runtimes to `127.0.0.1:${PORT:-...}:...` by default; expose only the public entrypoint port.
   - Add `security_opt: [no-new-privileges:true]`, mount read-only configs `:ro,z` (SELinux compatible), and pin explicit `PGDATA` subdirectories when custom Postgres images define them.
   - Never expose internal S3/MinIO/RustFS ports when the backend can proxy bytes (`S3_USE_PRESIGNED_URLS=false`).
4. **Invariant Testing in CI:**
   - Add a static structural checker (like InsForge's `scripts/check-setup-sh.sh`) asserting guard ordering, secret-generation invariants, and parity between compose mounts and fetched files.

## Do / Avoid

### Do
```env
COMPOSE_PROJECT_NAME=mi-app-prod
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=deploy/docker-compose/docker-compose.yml:docker-compose.minio.yml
POSTGRES_PORT=5432
```

### Avoid
```yaml
# Exposing Postgres directly to 0.0.0.0 with hardcoded ports or mixing dev/prod files
ports:
  - "5432:5432"
```

## Deep Reference
Read `references/setup-invariants.md` or `../../../references/repos/InsForge.md` when writing a new `setup.sh` or structural check script.
