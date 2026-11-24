# Pattern: SSE vs. WebSockets (Frontera de Streaming de Eventos)

> **Origen:** Verificado en [`InsForge/InsForge`](../../references/repos/InsForge.md) (`backend/src/api/routes/dashboard/events.routes.ts` vs. `backend/src/infra/realtime/realtime.manager.ts`).

---

## 1. Principio de Decisión

No todo "tiempo real" necesita WebSockets / Socket.IO. Mantener conexiones WebSocket con handshake custom, reconexión y estado de salas agrega complejidad innecesaria cuando el flujo es **exclusivamente servidor $\rightarrow$ cliente**.

| Necesidad | Tecnología Correcta | Por qué |
| :--- | :--- | :--- |
| **Telemetría, progreso de deploys, logs en vivo, invalidación de caché de dashboard** (1 dirección: servidor $\rightarrow$ navegador) | **SSE (`text/event-stream`)** | HTTP estándar, reconexión nativa del navegador (`EventSource`), pasa limpio por proxies/CDNs, mínimo consumo de memoria y sin protocolo bidireccional que mantener. |
| **Chat multiusuario, presencia efímera (`online users`), cursores colaborativos o pub/sub cliente $\leftrightarrow$ cliente** | **WebSockets / Socket.IO + `pg_notify`** | Requiere envío bidireccional de mensajes por el mismo canal, salas dinámicas y eventos de desconexión inmediata (*presence*). |
| **App de escritorio o compañero con largos períodos inactivos** | **HTTP `POST` coalesced (Zero-Idle)** | Evita mantener sockets abiertos en reposo gastando batería y conexiones DB. |

---

## 2. Reglas de Implementación para un Endpoint SSE Robusto

Basado en `handleDashboardEvents` de InsForge:
1. **Headers obligatorios:**
   - `Content-Type: text/event-stream`
   - `Cache-Control: no-cache, no-transform`
   - `Connection: keep-alive`
   - `X-Accel-Buffering: no` *(crucial detrás de Nginx / reverse proxies para que no retengan chunks en buffer).*
2. **Evento inicial `ready`:** Enviar inmediatamente `data: {"type":"ready"}\n\n` tras `flushHeaders()` para confirmar apertura al cliente sin esperar el primer evento de negocio.
3. **Heartbeat periódico (`20–30s`):** Emitir comentarios SSE `: keepalive\n\n` mediante `setInterval` para evitar timeouts silenciosos en load balancers (AWS ALB, Cloudflare, Nginx).
4. **Cleanup garantizado e idempotente:** Registrar `cleanup()` en **ambos** eventos `res.once('close', cleanup)` y `res.once('error', cleanup)` usando una bandera `closed` para limpiar el `setInterval` y desuscribirse del bus interno sin fugas de memoria.

---

## 3. Reglas para Canales Pub/Sub (cuando sí usás WebSockets + Postgres)

- Usar `pg_notify` desde triggers de Postgres hacia el broker de sockets en el backend.
- Definir patrones de canal con prefijo claro (`order:%` usando `:` como separador y `%` como wildcard SQL `LIKE`, evitando `_` por ser wildcard de un carácter en SQL).
- Desacoplar efectos secundarios pesados (enviar email, cobrar, llamar APIs externas) fuera del socket hacia funciones serverless o colas duraderas.
