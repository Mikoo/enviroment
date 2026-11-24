---
type: project-rules
project: <NombreProyecto>
updated: YYYY-MM-DD
---

# PROJECT_RULES — <NombreProyecto>

## Reglas Innegociables
1. **Arquitectura:** (ej. nunca acceder a Postgres desde rutas HTTP; usar RPCs atómicas).
2. **Seguridad:** (ej. RLS activo en toda tabla operativa; jamás confiar en `created_by` del cliente; nunca commitear `.env`).
3. **Convenciones:** (idioma de código, linters, estilo).

## Comandos Oficiales del Proyecto
- **Dev:** `...`
- **Build:** `...`
- **Tests / Lint:** `...`

## Archivos Protegidos / Restricciones para IAs
- **NO tocar sin confirmación explícita:** `...`
- **Antes de agregar dependencias:** verificar utilidades existentes en el repo y compatibilidad con el entorno de aislamiento declarado en `ENVIROMENT_IMPORTS.md`.
- **Al cerrar la sesión:** actualizar `CHANGES.md` con fecha, cambios, estado de pruebas y próximo paso concreto.
