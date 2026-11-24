# Pattern: Cross-AI Skills Packaging, Mirroring & Document Governance

> **Origen:** Verificado en [`InsForge/InsForge`](../../references/repos/InsForge.md) (`scripts/sync-skills.sh`, `.claude/skills/README.md`, `.internal/docs/README.md`) y [`InsForge/insforge-skills`](https://github.com/InsForge/insforge-skills).

---

## 1. Problema

Cada agente de codificación busca skills y reglas en ubicaciones ligeramente distintas (`.agents/skills/`, `.claude/skills/`, `.codex/skills/`, `~/.gemini/config/skills/`), y los symlinks en Git **se rompen en checkouts de Windows** (se vuelven archivos de texto plano) y hacen fallar herramientas como Prettier. Además, los documentos internos de planeamiento terminan mezclados con la documentación oficial o la referencia de los agentes.

---

## 2. Solución Implementada en `InsForge`

### A. SSOT en `.agents/skills/` + Espejo por Script + Gate en CI
1. Editar **únicamente** `.agents/skills/<skill>/`.
2. Correr `scripts/sync-skills.sh` (o `.ps1` en Windows) para generar copias byte-a-byte en `.claude/skills/` y `.codex/skills/`.
3. Commitear los tres árboles juntos.
4. En CI (`.github/workflows/lint-and-format.yml`), correr `scripts/sync-skills.sh --check` para impedir que alguien edite una copia y genere drift.

### B. Empaquetado Cross-IA Limpio
- `SKILL.md` lleva **solo `name` y `description`** (+ `license` opcional). **Sin `metadata:` ni `tags:` en el frontmatter raíz** (OpenAI/Codex rechaza campos no permitidos en su portal de plugins).
- Las propiedades visuales para Codex (`display_name`, `short_description`, `brand_color`, `default_prompt`) viven en `agents/openai.yaml` dentro de la carpeta del skill.
- Un mismo catálogo `skills/` puede exponerse con manifests propios para cada ecosistema: `.agents/plugins/marketplace.json`, `.claude-plugin/{plugin,marketplace}.json`, `.codex-plugin/plugin.json`.

### C. Skills Externos Vendored sin Perder Personalizaciones
Cuando adoptás un skill de terceros (ej. un skill oficial de Mintlify o framework):
1. Mantener el `SKILL.md` upstream **intacto** (actualizado vía script que verifica licencia y SHA origen).
2. Colocar todas tus reglas u overrides locales en un archivo hermano (ej. `LOCAL_OVERRIDES.md` o `INSFORGE.md`) dentro de la misma carpeta del skill.

### D. Gobernanza Documental en 5 Zonas
Separar estrictamente por propósito para evitar contaminación de contexto:
1. `docs/` — documentación pública / usuario final.
2. `.internal/docs/{plans,specs,audits}/` — planes, specs y auditorías internas (en nuestro esquema: carpetas `01_Projects` en `G:\obsidian\`).
3. `.agents/docs/` — guías de lectura técnica destinadas a agentes.
4. `.archive/docs/deprecated/` — material obsoleto aislado.
5. `.agents/skills/` — instrucciones ejecutables bajo demanda (`< 500` líneas por `SKILL.md`).
