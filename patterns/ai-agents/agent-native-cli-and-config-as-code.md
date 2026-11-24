# Pattern: Agent-Native CLI Harness, Diagnostics & Config-as-Code

> **Origen:** Verificado en [`InsForge/InsForge`](../../references/repos/InsForge.md) (`docs/agent-native/{overview,cli-harness,config-as-code,diagnostics}.mdx` y `InsForge/insforge-skills`).

---

## 1. Por qué CLI + Skills suele superar a MCP masivo

Exponer decenas de herramientas MCP en el contexto inicial infla los tokens del prompt del sistema y reduce la precisión de selección de herramienta. En cambio, un **CLI determinista + un `SKILL.md` ligero** permiten que el agente opere cualquier sistema desde cualquier terminal, IDE o CI con mínimo consumo de contexto.

---

## 2. Contrato de un CLI "Agent-Friendly"

1. **`--json` en todo comando:** Salida estructurada predecible para parseo automático sin raspar tablas ASCII ni colores ANSI. Cuando `--json` está activo, desactivar prompts interactivos de selección/texto y fallar explícitamente si falta un parámetro.
2. **`-y` / `--yes` / `--auto-approve`:** Para confirmar operaciones destructivas solo cuando el humano o script lo autoriza explícitamente; nunca asumir confirmación silenciosa en borrados irreversibles.
3. **Códigos de salida semánticos:**
   - `0`: Éxito
   - `1`: Error general / fallo de ejecución
   - `2`: No autenticado
   - `3`: Proyecto no vinculado / contexto faltante
   - `4`: Recurso no encontrado
   - `5`: Permiso denegado
4. **Ejecución aislada a la versión del proyecto:** Preferir `npx @pkg/cli` o `.venv/bin/tool` antes que instalaciones globales que causan conflictos entre proyectos.

---

## 3. Cuatro Primitivas Operativas para Evitar Alucinaciones

1. **Inspección de estado vivo (`metadata --json`):** El agente consulta esquemas, versiones y configuración real antes de proponer cambios, en lugar de adivinar desde notas viejas.
2. **Diagnóstico accionable (`diagnose --json`):** Agrupar hallazgos de seguridad (ej. políticas RLS permisivas), salud de base de datos, métricas y logs de error junto con su **remediación sugerida**.
3. **Config-as-Code (`plan` / `apply` / `export` en TOML/YAML):**
   - Declarar configuración versionable en texto (`insforge.toml`) con referencias `env(VAR_NAME)` para secretos (jamás secretos literales en Git).
   - `export` genera el archivo desde un entorno existente; `plan` muestra el diff contra el estado vivo; `apply --dry-run` previsualiza sin mutar.
4. **Memoria de gotchas en proyecto (`memory list` / `memory remember`):** Al iniciar tareas no triviales, consultar decisiones previas y registrar descubrimientos en el momento en que ocurren.
