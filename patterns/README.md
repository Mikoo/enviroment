# Catálogo de Patrones Arquitectónicos (`patterns/`)

> Documentación técnica de profundidad (bajo demanda — **no** autocargada en sesión). Para reglas ejecutables rápidas, usar `.agents/skills/`.

| Dominio | Patrón | Origen / Referencia |
| :--- | :--- | :--- |
| **Data** | [`data/database-scalability-uuidv7-bucketing.md`](./data/database-scalability-uuidv7-bucketing.md) | `00_reusables` (Instagram / Discord / Uber patterns) |
| **Backend** | [`backend/pos-financial-integrity-atomic-rpcs.md`](./backend/pos-financial-integrity-atomic-rpcs.md) | `00_reusables` (Stripe / Square patterns) |
| **Backend** | [`backend/ast-sql-guarding-and-rls-context.md`](./backend/ast-sql-guarding-and-rls-context.md) | `InsForge/InsForge` (`sql-parser.ts`, `user-context.service.ts`) |
| **Backend** | [`backend/sse-vs-websockets-event-streams.md`](./backend/sse-vs-websockets-event-streams.md) | `InsForge/InsForge` (`events.routes.ts` vs `realtime.manager.ts`) |
| **Backend** | [`backend/hmac-webhooks-and-convergent-remediation.md`](./backend/hmac-webhooks-and-convergent-remediation.md) | Destilado de sistemas event-driven / AWS SQS / webhooks |
| **Frontend** | [`frontend/dense-data-ui-1366x768-60fps.md`](./frontend/dense-data-ui-1366x768-60fps.md) | `00_reusables` (Linear / Touch 60FPS patterns) |
| **Frontend** | [`frontend/monorepo-ui-host-boundary.md`](./frontend/monorepo-ui-host-boundary.md) | `InsForge/InsForge` (`packages/ui`, `dashboard`, `shared-schemas`) |
| **AI & Agents** | [`ai-agents/cross-ai-skills-packaging-and-sync.md`](./ai-agents/cross-ai-skills-packaging-and-sync.md) | `InsForge/InsForge` + `InsForge/insforge-skills` |
| **AI & Agents** | [`ai-agents/agent-native-cli-and-config-as-code.md`](./ai-agents/agent-native-cli-and-config-as-code.md) | `InsForge/InsForge` (`@insforge/cli`, `insforge.toml`, `diagnose`) |
| **AI & Agents** | [`ai-agents/low-latency-voice-and-3tier-memory.md`](./ai-agents/low-latency-voice-and-3tier-memory.md) | `00_reusables` (WebAudio / Silero VAD / Groq / MemGPT 3-Tier) |
| **AI & Agents** | [`ai-agents/tauri-v2-zero-idle-and-plugin-registry.md`](./ai-agents/tauri-v2-zero-idle-and-plugin-registry.md) | `00_reusables` (Tauri v2 / SvelteKit SPA / Plugin Mode Registry) |
| **Messaging** | [`messaging/whatsapp-cloud-api-serverless-webhook.md`](./messaging/whatsapp-cloud-api-serverless-webhook.md) | `00_reusables` (Meta Cloud API + Edge Functions) |
