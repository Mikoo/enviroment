---
name: database-scalability
description: Use when designing or optimizing PostgreSQL or Supabase schemas with high write frequency (telemetry, chat turns, session metrics), replacing UUIDv4 primary keys with RFC 9562 UUIDv7, implementing daily JSONB bucketing, or coalescing writes through atomic RPCs.
---

# Database Scalability (`UUIDv7`, Bucketing & Write Coalescing)

## Scope
PostgreSQL / Supabase schemas and RPCs under heavy write workloads. Avoid applying daily JSONB bucketing to strict accounting ledgers that require normalized per-line SQL audit rows.

## Core Rules
1. **Use time-ordered `UUIDv7` primary keys:** Replace `gen_random_uuid()` (UUIDv4) with `public.uuid_generate_v7()` on high-write tables so inserts append monotonically to the right edge of B-Tree indexes without page splits.
2. **Aggregate high-frequency turns into daily `session_buckets`:** Store 1 row per `(user_id, bucket_date)` with `UNIQUE (user_id, bucket_date)` and an `events_log jsonb` array capped to the most recent 50 events.
3. **Coalesce client writes via atomic RPC (`flush_session_metrics`):** Batch local deltas (`turns_delta`, `coins_delta`, `events_batch`, `facts_batch`) and flush every ~3 turns, on pause, or on window hide using `ON CONFLICT (user_id, bucket_date) DO UPDATE`.
4. **Enforce identity in `SECURITY DEFINER` RPCs:** Set `SET search_path = public` and validate `auth.uid() = p_user_id` before writing.

## Do / Avoid

### Do
- Keep `events_log` bounded (`LIMIT 50` in JSONB aggregation) and index `(user_id, bucket_date DESC)`.
- Protect SQL endpoints with transaction-scoped `withUserContext` + RLS (see `patterns/backend/ast-sql-guarding-and-rls-context.md`).

### Avoid
- Firing separate HTTP `INSERT`/`UPDATE` calls per chat turn or metric tick from the frontend.
- Using unindexed `UUIDv4` keys on append-heavy telemetry or log tables.

## Deep Reference
Read `../../../patterns/data/database-scalability-uuidv7-bucketing.md` when you need the full PL/pgSQL `uuid_generate_v7()`, table DDL, and `flush_session_metrics` RPC implementation.
