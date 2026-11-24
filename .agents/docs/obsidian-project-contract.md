# Contrato de Integración: `G:\obsidian\` (Proyectos) ↔ `Mikoo/enviroment` (Librería)

Este documento define cómo separar **el estado vivo de cada proyecto** (que permanece en tus carpetas de Obsidian en `G:\obsidian\<proyecto>\`) de **la lógica técnica reutilizable** (que vive versionada en `Mikoo/enviroment`).

---

## 1. Principio de Diseño: Proyectos como Consumidores, `enviroment` como Librería

| Vive en `G:\obsidian\<proyecto>\` | Vive en `Mikoo/enviroment` |
| :--- | :--- |
| Qué hace este negocio/TP (`PROJECT_OVERVIEW.md`) | Skills Cross-IA ejecutables (`.agents/skills/`) |
| Reglas innegociables propias (`PROJECT_RULES.md`) | Patrones arquitectónicos agnósticos (`patterns/`) |
| Bitácora cronológica y próximo paso (`CHANGES.md`) | Auditorías de repositorios externos (`references/repos/`) |
| **Manifiesto de importación (`ENVIROMENT_IMPORTS.md`)** | Perfil físico de PC, aislamiento e higiene (`machine/`) |
| ADRs específicos, auditorías de UI/DB, transcripciones, entregas | Plantillas estándar (`templates/`) y scripts de sync (`scripts/`) |

---

## 2. Cómo Funciona `ENVIROMENT_IMPORTS.md` (Importación Explícita)

Igual que `package.json` declara librerías de código sin copiar `node_modules` dentro del proyecto, cada carpeta en `G:\obsidian\<proyecto>\` declara en `ENVIROMENT_IMPORTS.md`:

1. **Skills importados** desde `enviroment/.agents/skills/` (solo los relevantes al proyecto, no los 10).
2. **Patrones consultados** desde `enviroment/patterns/` (para lectura profunda puntual, nunca auto-carga).
3. **Perfil físico de aislamiento** desde `enviroment/machine/ISOLATION_MATRIX.md` (ej. `.venv` + LocalStack Docker vs Node + Supabase Cloud vs Sandbox/VM).
4. **Overrides locales:** cualquier regla del proyecto que extienda o modifique un patrón general (ej. en TP académico *Fénix*, usar `run_in_threadpool` con Worker secuencial sin `ExceptionGroup`).

---

## 3. Reglas para Proyectos Universitarios o Temporales (Anti-Ruido)

- Carpetas como `P2/` (`VulcanoPay`, `Fenix`, `clases/`, guiones de video `speech.md`) permanecen **exclusivamente** en `G:\obsidian\P2\` (preferiblemente separadas en subcarpetas por TP).
- Si de un trabajo práctico surge una práctica verdaderamente reusable (por ejemplo: validación HMAC sobre `raw_bytes`, remediación convergente en AWS/Boto3, calidad estricta `flake8`/`pylint`), se **destila de forma agnóstica** hacia `enviroment` (`resilient-python-services`), dejando las consignas y guiones fuera de `enviroment`.

---

## 4. Protocolo de Arranque para Cualquier Agente en un Proyecto

Al abrir o retomar un proyecto después de semanas o meses:
1. Leer **solo** 4 archivos en `G:\obsidian\<proyecto>\`:
   - `PROJECT_OVERVIEW.md`
   - `PROJECT_RULES.md`
   - `CHANGES.md` (últimas entradas)
   - `ENVIROMENT_IMPORTS.md`
2. Cargar de `enviroment` **únicamente** los skills y patrones listados en `ENVIROMENT_IMPORTS.md`.
3. Al cerrar el bloque de trabajo, actualizar `CHANGES.md` con archivos tocados, decisiones tomadas y el próximo paso exacto.
