---
title: "Pattern: Database Scalability - UUIDv7, Date Bucketing & Write Coalescing"
tags:
  - pattern/database
  - postgresql
  - supabase
  - scalability
  - uuidv7
  - write-coalescing
created: 2026-10-26
status: active
---

# 🗄️ Pattern: Database Scalability — UUIDv7, Date Bucketing & Write Coalescing

> **Contexto:** Patrón reutilizable de arquitectura de datos en PostgreSQL / Supabase inspirado en las prácticas de ingeniería de **Instagram** (IDs ordenados temporalmente para localidad en B-Tree), **Discord** (agrupación de actividad por *buckets* diarios) y **Uber** (*Write Coalescing* mediante RPC transaccional).

Relacionado con: [Catálogo de Patrones](../README.md) | `ADR-004` (proyecto PeraTomo en Obsidian)

---

## 1. Problema Arquitectónico

En aplicaciones interactivas (compañeros de IA por voz, videojuegos con telemetría o chats de alta frecuencia), tres antipatrones suelen degradar rápidamente una base de datos PostgreSQL:

1. **Fragmentación de B-Tree por `UUIDv4` (`gen_random_uuid()`):** Los UUIDv4 son completamente aleatorios. Cada `INSERT` escribe en una página distinta del índice B-Tree, causando *page splits* constantes, invalidación del caché en RAM (*shared buffers*) y alto I/O en disco.
2. **Explosión de filas por micro-interacciones:** Insertar una fila en `messages` o `telemetry_events` por cada turno de voz o cambio de estadística multiplica el costo de almacenamiento, ralentiza los `SELECT` históricos y satura el *vacuuming*.
3. **Chatter de red (N+1 Writes):** Actualizar perfil, monedas, energía, hechos de memoria y logs en múltiples peticiones HTTP desde el cliente genera condiciones de carrera y agota el pool de conexiones (Supavisor / PgBouncer).

---

## 2. Solución 1: UUIDv7 Ordenados por Tiempo (Estilo Instagram)

**RFC 9562 UUIDv7** codifica un timestamp Unix en milisegundos en los primeros 48 bits y rellena el resto con entropía criptográfica aleatoria.

### Beneficios Clave
- **Localidad de inserción 100% secuencial (Append-Only B-Tree):** Todas las filas nuevas se insertan al final del índice primario.
- **Ordenamiento cronológico implícito:** Ordenar por `id` equivale a ordenar por `created_at` sin necesidad de un índice secundario adicional.
- **Zero colisiones distribuidas:** Puede generarse tanto en el cliente como en PostgreSQL sin coordinación central.

### Implementación SQL en PostgreSQL / Supabase

```sql
-- Función pura en PL/pgSQL para generar UUIDv7 (RFC 9562)
CREATE OR REPLACE FUNCTION public.uuid_generate_v7()
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
  v_time timestamp with time zone:= clock_timestamp();
  v_secs bigint := EXTRACT(EPOCH FROM v_time);
  v_msec bigint := MOD(EXTRACT(MILLISECONDS FROM v_time)::numeric, 1000::numeric);
  v_unix_t_ms bigint := (v_secs * 1000) + v_msec;
  v_rand_a bigint := floor(random() * 4096)::bigint; -- 12 bits
  v_rand_b bigint := floor(random() * 4611686018427387904)::bigint; -- 62 bits
  v_hex text;
BEGIN
  v_hex := lpad(to_hex(v_unix_t_ms), 12, '0') ||
           lpad(to_hex((7 << 12) | v_rand_a), 4, '0') ||
           lpad(to_hex((2::bigint << 62) | v_rand_b), 16, '0');
  RETURN v_hex::uuid;
END;
$$;
```

---

## 3. Solución 2: `session_buckets` JSONB Particionados por Fecha (Estilo Discord)

En lugar de crear una fila por cada turno de conversación, agrupamos toda la actividad diaria de un usuario en un único registro (`bucket`) identificado por `(user_id, bucket_date)`.

### Esquema SQL de `session_buckets`

```sql
CREATE TABLE IF NOT EXISTS public.session_buckets (
  id uuid PRIMARY KEY DEFAULT public.uuid_generate_v7(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bucket_date date NOT NULL DEFAULT CURRENT_DATE,
  turns_count integer NOT NULL DEFAULT 0,
  english_seconds numeric(10,2) NOT NULL DEFAULT 0,
  total_words integer NOT NULL DEFAULT 0,
  avg_wpm numeric(6,2) NOT NULL DEFAULT 0,
  gse_score_snapshot integer,
  cefr_snapshot text,
  events_log jsonb NOT NULL DEFAULT '[]'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_session_buckets_user_date UNIQUE (user_id, bucket_date)
);

-- Índice compuesto para lecturas rápidas de historial reciente (últimos 7-30 días)
CREATE INDEX IF NOT EXISTS idx_session_buckets_user_date
  ON public.session_buckets (user_id, bucket_date DESC);
```

### Estructura del Array `events_log` (JSONB Compacto)
Cada elemento dentro de `events_log` almacena el resumen del turno o lote de turnos sin inflar las tablas relacionales:

```json
[
  {
    "ts": "2026-10-26T01:15:00Z",
    "u_txt": "I went to the gym yesterday, pero estaba cerrado.",
    "ai_txt": "No way! Was it closed for maintenance? Let's say: 'but it was closed'.",
    "en_ratio": 0.65,
    "wpm": 112.4,
    "coins_delta": 5,
    "energy_delta": 10
  }
]
```

---

## 4. Solución 3: Write Coalescing con RPC `flush_session_metrics`

El cliente acumula métricas en memoria local (o las agrupa al finalizar una ráfaga de turnos / al pasar a background) y ejecuta **una sola llamada RPC atómica** a Supabase.

### Implementación SQL de `flush_session_metrics`

```sql
CREATE OR REPLACE FUNCTION public.flush_session_metrics(
  p_user_id uuid,
  p_bucket_date date,
  p_turns_delta integer,
  p_english_seconds_delta numeric,
  p_words_delta integer,
  p_wpm_sample numeric,
  p_coins_delta integer,
  p_energy_delta integer,
  p_new_gse integer,
  p_new_cefr text,
  p_events_batch jsonb DEFAULT '[]'::jsonb,
  p_facts_batch jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile record;
  v_fact jsonb;
BEGIN
  -- Seguridad: validar que el usuario autenticado coincida con p_user_id
  IF auth.uid() IS NOT NULL AND auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized flush_session_metrics call';
  END IF;

  -- 1. Upsert atómico del bucket diario (Write Coalescing)
  INSERT INTO public.session_buckets (
    user_id,
    bucket_date,
    turns_count,
    english_seconds,
    total_words,
    avg_wpm,
    gse_score_snapshot,
    cefr_snapshot,
    events_log,
    updated_at
  )
  VALUES (
    p_user_id,
    COALESCE(p_bucket_date, CURRENT_DATE),
    p_turns_delta,
    p_english_seconds_delta,
    p_words_delta,
    p_wpm_sample,
    p_new_gse,
    p_new_cefr,
    p_events_batch,
    now()
  )
  ON CONFLICT (user_id, bucket_date)
  DO UPDATE SET
    turns_count = session_buckets.turns_count + EXCLUDED.turns_count,
    english_seconds = session_buckets.english_seconds + EXCLUDED.english_seconds,
    total_words = session_buckets.total_words + EXCLUDED.total_words,
    avg_wpm = ROUND(
      ((session_buckets.avg_wpm * session_buckets.turns_count) + (EXCLUDED.avg_wpm * EXCLUDED.turns_count))
      / NULLIF(session_buckets.turns_count + EXCLUDED.turns_count, 0),
      2
    ),
    gse_score_snapshot = COALESCE(EXCLUDED.gse_score_snapshot, session_buckets.gse_score_snapshot),
    cefr_snapshot = COALESCE(EXCLUDED.cefr_snapshot, session_buckets.cefr_snapshot),
    -- Mantiene los últimos 50 eventos del día en el bucket para acotar tamaño de fila
    events_log = (
      SELECT COALESCE(jsonb_agg(elem), '[]'::jsonb)
      FROM (
        SELECT elem
        FROM jsonb_array_elements(session_buckets.events_log || EXCLUDED.events_log) WITH ORDINALITY AS t(elem, ord)
        ORDER BY ord DESC
        LIMIT 50
      ) sub
    ),
    updated_at = now();

  -- 2. Actualización atómica de perfil, economía y métricas CEFR/GSE
  UPDATE public.profiles
  SET
    pera_coins = GREATEST(0, pera_coins + p_coins_delta),
    energy = LEAST(100, GREATEST(0, energy + p_energy_delta)),
    gse_score = COALESCE(p_new_gse, gse_score),
    cefr_level = COALESCE(p_new_cefr, cefr_level),
    last_active_at = now(),
    updated_at = now()
  WHERE id = p_user_id
  RETURNING pera_coins, energy, gse_score, cefr_level INTO v_profile;

  -- 3. Upsert de hechos episódicos / Open Loops (si vienen en el lote)
  FOR v_fact IN SELECT * FROM jsonb_array_elements(p_facts_batch)
  LOOP
    INSERT INTO public.user_life_facts (
      user_id,
      category,
      fact_key,
      fact_value,
      is_open_loop,
      follow_up_after,
      status,
      updated_at
    )
    VALUES (
      p_user_id,
      COALESCE(v_fact->>'category', 'daily_life'),
      v_fact->>'fact_key',
      v_fact->>'fact_value',
      COALESCE((v_fact->>'is_open_loop')::boolean, false),
      (v_fact->>'follow_up_after')::timestamptz,
      COALESCE(v_fact->>'status', 'active'),
      now()
    )
    ON CONFLICT (user_id, fact_key)
    DO UPDATE SET
      fact_value = EXCLUDED.fact_value,
      is_open_loop = EXCLUDED.is_open_loop,
      follow_up_after = EXCLUDED.follow_up_after,
      status = EXCLUDED.status,
      updated_at = now();
  END LOOP;

  RETURN jsonb_build_object(
    'ok', true,
    'pera_coins', v_profile.pera_coins,
    'energy', v_profile.energy,
    'gse_score', v_profile.gse_score,
    'cefr_level', v_profile.cefr_level
  );
END;
$$;
```

---

## 5. Cuándo Aplicar este Patrón

| Escenario | Recomendación |
| :--- | :--- |
| Tablas con alto volumen de escritura (`buckets`, `facts`, `transactions`) | Usar `uuid_generate_v7()` como `DEFAULT` en `id`. |
| Eventos de voz, telemetría o chat turno a turno | Agrupar en `session_buckets` por `(user_id, bucket_date)`. |
| Sincronización cliente → servidor | Usar `flush_session_metrics` con *debounce* (ej. cada 3 turnos o al cerrar sesión/ventana). |
