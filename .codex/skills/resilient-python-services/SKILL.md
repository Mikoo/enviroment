---
name: resilient-python-services
description: Use when building or reviewing Python FastAPI webhook receivers, AWS/LocalStack SQS/EC2/S3 workers, HMAC raw-byte authentication, non-blocking JSON queue logging, or strict flake8/pylint/pytest microservice delivery.
---

# Resilient Python Services (FastAPI, HMAC, SQS & Convergent Workers)

## Scope
Python backend services, event-driven workers (SQS/Boto3/LocalStack), webhook receivers, and strict quality/observability pipelines.

## Core Rules
1. **Authenticate raw bytes before parsing JSON:** Verify HMAC-SHA256 over `f"{timestamp}.{raw_body}"` **before** `json.loads()`. Enforce max body size (`413` early), single signature header via `headers.getlist()` (`401` on missing/duplicate), reject Python `bool` as `int` (`isinstance(ts, bool)`), enforce anti-replay window (`±300s`), and compare with `hmac.compare_digest()`.
2. **Defensive FastAPI funnel & non-blocking I/O:**
   - Order checks: body size (`413`) $\rightarrow$ HMAC (`401`) $\rightarrow$ UTF-8/JSON (`400`) $\rightarrow$ schema/inventory (`422`) $\rightarrow$ broker publish (`503` on failure, `202` only after `MessageId` confirmation).
   - Offload blocking disk reads and synchronous Boto3 calls inside `async def` routes with `await asyncio.to_thread(...)` or `run_in_threadpool(...)`.
3. **Convergent, idempotent remediation (`at-least-once` queues):**
   - Inspect real state first; return `"already_ok"` if converged. Never run `reboot_instances` on EC2 (breaks idempotency — use `start_instances` + verify target tags like `ManagedBy`/`Project`/`GroupId`). Preserve external tags when updating S3 (`{**current, **required}`).
   - Classify transient errors (`RetryableError` $\rightarrow$ `change_message_visibility` with `min(30, 2 ** count)`) vs permanent errors (`PermanentError` $\rightarrow$ DLQ without leaking secrets/URLs).
4. **Defensive HTTP parsing & zero scaffolding:**
   - Never assume `200 OK` returns valid JSON; fallback cleanly on `(ValueError, json.JSONDecodeError)`.
   - Never leave `try: import ... except ImportError: mock` fallbacks in `main`.
5. **Observability & Quality Gate:**
   - Log structured JSON asynchronously via `QueueHandler` + `QueueListener` + compressed `.gz` rotation.
   - Verify `pytest`, `flake8` (0 warnings), `pylint` (`10.00/10`), and zero 0-byte files before delivery.

## Deep Reference
Read `../../../patterns/backend/hmac-webhooks-and-convergent-remediation.md` for full error taxonomy and pipeline diagrams.
