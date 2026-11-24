# Setup Script Invariants (Patrón `InsForge/scripts/check-setup-sh.sh`)

Checklist de invariantes verificables automáticamente para scripts `setup.sh` de despliegue:

1. **Guardia de working tree primero:** Verificar si `$TARGET` es un repo Git de desarrollo (`-e "$TARGET/.git"`, nunca `-d` porque en worktrees `.git` es un archivo) **antes** de ejecutar `git checkout`, `git sparse-checkout` o `cp .env.example`.
2. **Separación de modos Git vs. HTTP (`NO_GIT`):** Si el usuario elige fetch por HTTPS (`curl`), omitir toda llamada `git` en funciones auxiliares (`[ -z "${NO_GIT:-}" ] || return 0`).
3. **Fallo limpio al generar secretos:** `gen_secret()` debe validar que `openssl rand` devolvió un valor no vacío antes de anteponer prefijos (`ik_`, `anon_`) y borrar el `.env` parcial si falla.
4. **Preservación de secretos existentes:** Si `.env` ya existe, re-correr `setup.sh` jamás sobrescribe contraseñas/claves previas; solo corrige o agrega `COMPOSE_FILE`.
5. **Paridad `FILES` $\leftrightarrow$ Compose mounts:** Todo archivo montado por `docker-compose.yml` (`../docker-init/...`, `functions/...`) debe existir en la lista `FILES` del script de descarga.
6. **Documentación de `.env.example`:** Toda variable leída en algún `docker-compose*.yml` debe estar declarada en `.env.example`.
