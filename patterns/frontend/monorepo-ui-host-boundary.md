# Pattern: Monorepo UI / Dashboard / Host Boundary + Shared Schemas

> **Origen:** Verificado en [`InsForge/InsForge`](../../references/repos/InsForge.md) (`packages/ui`, `packages/dashboard`, `packages/shared-schemas`, `frontend/`).

---

## 1. El Problema

Cuando un producto necesita ejecutarse en más de un entorno (ej. **self-hosted OSS** y **cloud**, o web app + desktop shell) y comparte contratos entre backend, frontend y CLI/MCP:
- Duplicar tipos TypeScript o validaciones Zod entre backend y frontend genera drift silencioso.
- Mezclar bootstrap local (`.env`, shell layout, auth local) dentro del paquete de UI compartido rompe el despliegue en otros hosts.

---

## 2. Separación de Capas en 4 Paquetes

```text
packages/shared-schemas/   <-- Única fuente de verdad de contratos Zod + tipos TS + errores
        ▲            ▲
        │            │
    backend/    packages/ui/  (primitivos puros: Button, Dialog, Input, CVA + cn())
                     ▲
                     │
               packages/dashboard/  (producto completo: service -> hook -> UI + host context)
                     ▲
                     │
                frontend/   (shell delgado: solo montaje, env local y estilos de host)
```

### Reglas de Frontera
1. **Cambios de contrato arrancan en `shared-schemas`:** Todo payload compartido o código de error vive allí y se compila primero (`turbo run build --filter=@org/shared-schemas`), disparando `typecheck` en backend y frontend.
2. **`ui` nunca conoce reglas de negocio ni llamadas HTTP:** Solo componentes presentacionales accesibles y utilidades (`cn()`).
3. **`dashboard` no importa nada de `frontend/`:** Las diferencias entre modos (`self-hosting` vs `cloud-hosting`) se inyectan mediante un `HostContext` / props de host, nunca acoplando al shell.
4. **Flujo frontend estricto `service -> hook -> UI`:** Un cliente HTTP centralizado (`apiClient`) maneja refresh de tokens y errores; los componentes UI nunca llaman `fetch` directamente ni usan `any` en TypeScript.
5. **Validación por capas (pirámide rápida):**
   - Pure helpers / formatters $\rightarrow$ `test:unit` (sin DOM ni mocks de red).
   - Componentes / formularios / modales $\rightarrow$ `test:component` (Testing Library mockeando hooks/contexto en el límite del paquete).
   - Rutas y flujos críticos completos $\rightarrow$ `test:ui` (Playwright).
6. **Guardas de debug local:** Si temporalmente forzaste flags para probar UI exclusiva de otro modo, marcá cada línea con `// LOCAL DEBUG: <original>` y validá `git grep "LOCAL DEBUG"` en cero antes de commitear.
