# Pattern: Webhooks HMAC sobre Raw Bytes, Embudo HTTP Defensivo y Remediación Convergente

> **Origen:** Destilado agnóstico de arquitecturas orientadas a eventos (FastAPI + SQS + AWS/LocalStack + Boto3).

---

## 1. Firma y Verificación HMAC sobre Bytes Crudos

1. **Nunca parsear JSON antes de autenticar:** Un atacante podría enviar payloads malformados o gigantes para provocar DoS en el parser, y dos JSON equivalentes con distinto espaciado producen firmas diferentes.
2. **Validar exactamente la frontera:**
   - Acotar tamaño máximo del cuerpo (ej. `<= 16 KiB` $\rightarrow$ responder `HTTP 413` antes de calcular HMAC).
   - Usar `headers.getlist(...)` (exigir exactamente 1 cabecera de firma; rechazar ausentes o duplicadas con `HTTP 401` para evitar *header smuggling*).
   - Verificar timestamp entero estricto (rechazar `bool` en Python ya que `isinstance(True, int)` es `True`), ventana anti-replay (`±300s`), longitud acotada de secreto/cabecera y comparación en tiempo constante (`hmac.compare_digest`).
   - Firmar `f"{timestamp}.{raw_body_utf8}"` con `HMAC-SHA256`.

---

## 2. Embudo HTTP Defensivo en `POST /webhook`

Orden estricto de validación para no desperdiciar cola ni cómputo:
1. **Tamaño de body (`413`)** sobre bytes crudos.
2. **Autenticación HMAC (`401`)** sobre bytes crudos.
3. **Decodificación UTF-8 y `json.loads` (`400`)**.
4. **Contrato de esquema e inventario (`422`)**, leyendo disco o DB sin bloquear el *event loop* (`await asyncio.to_thread(...)` o `run_in_threadpool(...)` en FastAPI).
5. **Publicación síncrona confirmada en cola (`503` si falla el broker, `202 Accepted` solo cuando el broker devuelve `MessageId`)**. Nunca confirmar `202` si no persistió en cola.

---

## 3. Remediación Convergente e Idempotente (Workers *At-Least-Once*)

En colas distribuidas (SQS), un mismo mensaje puede entregarse más de una vez:
1. **Consultar $\rightarrow$ Verificar propiedad $\rightarrow$ Actuar solo si hace falta $\rightarrow$ Re-consultar:**
   - Si el recurso ya está en el estado deseado $\rightarrow$ devolver `"already_ok"` sin ejecutar mutaciones destructivas (ej. usar `start_instances`, **jamás** `reboot_instances` en EC2; hacer merge conservando tags ajenas `{**current_tags, **required_tags}` en S3).
   - Validar etiquetas de pertenencia (`ManagedBy`, `Project`, `GroupId`) antes de modificar un recurso externo.
2. **Clasificación explícita de errores:**
   - `RetryableError` (red/transporte, throttling `429`, `5xx`, estados transitorios `pending`/`stopping`) $\rightarrow$ reencolar con backoff exponencial acotado (`min(30, 2 ** attempt)`) vía `change_message_visibility`.
   - `PermanentError` (recurso inexistente, contrato roto, conflicto de payload con mismo `event_id`) $\rightarrow$ enviar directo a Dead Letter Queue (`DLQ`) sin quemar reintentos, registrando mensajes sanitizados (nunca filtrar tokens ni URLs privadas en logs o excepciones).
3. **Telemetría no bloqueante y respuestas resilientes:**
   - Logging estructurado JSON mediante `QueueHandler` + `QueueListener` + rotación comprimida `.gz`.
   - Al consumir endpoints HTTP externos, nunca asumir que un `200 OK` trae JSON válido: capturar `(ValueError, json.JSONDecodeError)` y preservar texto plano como fallback.
