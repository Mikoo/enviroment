# Pattern: AST SQL Guarding & Transaction-Scoped RLS Context

> **Origen:** Verificado en [`InsForge/InsForge`](../../references/repos/InsForge.md) (`backend/src/utils/sql-parser.ts`, `backend/src/services/database/user-context.service.ts`, `backend/src/api/routes/database/advance.routes.ts`).

---

## 1. Problema Arquitectónico

1. **Regex frágiles sobre SQL crudo:** Filtrar sentencias peligrosas con expresiones regulares (`/\bSET ROLE\b/i`) falla ante comentarios SQL (`/*...*/`), literales de cadena, múltiples sentencias encadenadas o sintaxis alternativa de PostgreSQL.
2. **Filtros `WHERE user_id = $1` en servicios:** Confiar en que cada desarrollador o agente recuerde agregar filtros de usuario en cada query genera fugas silenciosas de datos multi-tenant.
3. **URLs firmadas fuera de banda (S3 / descargas):** Una presigned URL se redime directamente contra S3/MinIO sin volver a pasar por PostgreSQL, por lo que RLS no protege al momento de descargar si no se validó visibilidad antes de emitirla.

---

## 2. Solución A: Guardias AST con `libpg-query`

Antes de ejecutar SQL provisto por herramientas o usuarios con privilegios intermedios (`project_admin`), parsear el AST real de PostgreSQL (`libpg-query` en WASM):

- Rechazar nodos AST prohibidos de raíz:
  - `DatabaseManagement` (`CreatedbStmt`, `DropdbStmt`, `AlterDatabaseStmt`)
  - `RoleManagement` (`CreateRoleStmt`, `AlterRoleStmt`, `GrantRoleStmt`, `DropRoleStmt`)
  - `TransactionStmt` (evita romper el control transaccional del servidor)
  - `VariableSetStmt`: bloquear `VAR_RESET_ALL` (`RESET ALL`) y mutaciones sobre `role`, `session_authorization`, `search_path`, `statement_timeout`.
- Bloquear también `set_config(...)` en texto antes del parseo y rechazar cualquier query que falle al parsear (*fail-closed*).
- Separar endpoints según nivel de privilegio real en Postgres:
  - `/rawsql`: corre bajo rol restringido (`project_admin`) + `checkSqlExecutionGuards()`.
  - `/rawsql/unrestricted`: reservado estrictamente a administradores root; tras DDL libre, reasignar propiedad de objetos públicos (`reassign_public_objects_to_project_admin`) para no quebrar futuras migraciones.

---

## 3. Solución B: RLS Transaccional (`withUserContext`)

En rutas de usuario final autenticado:
1. El servicio abre una transacción SQL dedicada sobre el pool.
2. Ejecuta `SET LOCAL ROLE authenticated` y `set_config('request.jwt.claims', jsonClaims, true)` (alcance `LOCAL` = solo esta transacción).
3. Ejecuta las queries de negocio **sin duplicar filtros `WHERE user_id = ...`** en código aplicativo; PostgreSQL evalúa las políticas RLS contra `auth.jwt() ->> 'sub'` o `auth.uid()`.
4. Si la ruta emite un enlace fuera de banda (ej. S3 presigned URL), ejecuta primero una consulta `objectIsVisible` dentro de `withUserContext` antes de firmar la URL.
5. En `finally`, `ROLLBACK` / `COMMIT` y reset de rol garantizan que ninguna conexión devuelta al pool retenga la identidad del usuario anterior.

---

## 4. Reglas de Migración Idempotente Complementarias
- `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`.
- `DROP TRIGGER IF EXISTS` antes de `CREATE TRIGGER`.
- Nunca usar `ALTER TABLE ... RENAME TO` sin verificar ambos nombres en `information_schema.tables` dentro de un bloque `DO $$ ... END $$`.
- Cuando se habilita RLS sobre una tabla ya poblada, instalar políticas por defecto en la misma migración si ya existen filas para no romper sistemas en producción.
