---
type: enviroment-imports
project: <NombreProyecto>
enviroment_repo: https://github.com/Mikoo/enviroment
updated: YYYY-MM-DD
---

# ENVIROMENT_IMPORTS — Dependencias de Conocimiento y Entorno

> Manifiesto de "importación" hacia `Mikoo/enviroment`. Declara exactamente qué skills, patrones técnicos y perfil físico utiliza este proyecto, sin copiar la lógica de `enviroment` dentro de Obsidian.

## 1. Skills Importados (`enviroment/.agents/skills/`)
- `database-scalability` — *(ej. usar si el proyecto tiene escritura frecuente en Postgres)*
- `pos-financial-integrity` — *(quitar los que no apliquen)*

## 2. Patrones de Referencia (`enviroment/patterns/`)
- `patterns/backend/...` — *(motivo por el cual aplica)*

## 3. Perfil de Aislamiento Físico (`enviroment/machine/ISOLATION_MATRIX.md`)
- **Nivel asignado:** *(Nivel 1 Portable / Nivel 2 `.venv` o toolchain / Nivel 3 Docker Compose / Nivel 4 VM o Sandbox)*
- **Runtime / Puertos reservados:** *(ej. Node 22 + Vite en `:5173`, LocalStack en `:4566`)*
- **Ubicación de código:** `D:\Users\Miko\Workspace\<proyecto>` *(fuera de `G:\`)*

## 4. Adaptaciones / Overrides Locales
- *(Anotar aquí únicamente diferencias intencionales respecto al patrón estándar de `enviroment`)*
