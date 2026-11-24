---
title: "Pattern: POS Financial Integrity, Atomic RPCs & Cents Arithmetic"
tags:
  - pattern/database
  - pattern/finance
  - pattern/security
  - postgresql
  - supabase
  - atomic-transactions
  - react-hook-form
created: 2026-11-01
status: active
---

# 💰 Pattern: POS Financial Integrity, Atomic RPCs & Cents Arithmetic

> **Contexto:** Patrón de arquitectura transaccional y precisión aritmética para sistemas POS (Point of Sale), e-commerce, gestión de pedidos y arqueos de caja sobre **Supabase (PostgreSQL) + React**, inspirado en prácticas de ingeniería financiera de **Stripe** (aritmética en enteros / *minor units*) y **Square** (transacciones todo-o-nada e identidad criptográfica en servidor).

Relacionado con: [Catálogo de Patrones](../README.md) | [Database Scalability UUIDv7 & Bucketing](../data/database-scalability-uuidv7-bucketing.md)

---

## 1. Problema Arquitectónico

En sistemas de gestión comercial con múltiples mutaciones encadenadas (creación de órdenes con ítems, descuentos por combos y cierres de caja diarios), cuatro antipatrones recurrentes comprometen la integridad contable y el rendimiento:

1. **Mutaciones No Atómicas desde el Cliente (Partial Failure State):** Ejecutar desde el frontend llamadas separadas (`insert client` $\rightarrow$ `insert order` $\rightarrow$ `delete old order_items` $\rightarrow$ `insert new order_items`, o `insert cash_closing` $\rightarrow$ `update orders set status = 'archived'`) deja la base de datos corrupta si se corta la conexión a mitad del flujo.
2. **Suplantación de Auditoría (`created_by` enviado desde el Frontend):** Confiar en que el cliente envíe `payload.created_by = user.id` permite adulterar quién registró una venta, egreso o arqueo de caja.
3. **Corrupción Decimal por Punto Flotante (IEEE 754):** Operar precios en JavaScript usando `parseFloat(amount)` y `(qty * price)` introduce errores de redondeo (`0.1 + 0.2 === 0.30000000000000004`) que descuadran los cierres de caja y el libro mayor.
4. **Re-renders Masivos en Formularios Densos:** Controlar formularios complejos de órdenes o contadores de billetes con `useState` por campo dispara el re-renderizado de tablas e inventarios enteros en cada pulsación de tecla.

---

## 2. Solución 1: Transacciones Financieras Atómicas vía PostgreSQL RPCs

Toda operación que modifique más de una tabla o cierre un ciclo contable debe encapsularse en una única función `plpgsql` en Supabase. PostgreSQL ejecuta cada llamada RPC dentro de una transacción implícita (`BEGIN ... COMMIT` con `ROLLBACK` automático ante cualquier excepción).

### A. RPC Atómica de Procesamiento de Orden (`rpc_process_order`)

Resuelve el cliente, valida criptográficamente al operador con `auth.uid()`, inserta/actualiza la cabecera de la orden y reemplaza sus líneas de detalle (`order_items`) en un solo viaje de red:

```sql
CREATE OR REPLACE FUNCTION public.rpc_process_order(
  p_order_id uuid DEFAULT NULL,
  p_client_data jsonb DEFAULT NULL,
  p_order_data jsonb DEFAULT '{}'::jsonb,
  p_items jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
  v_client_id uuid;
  v_order_id uuid;
  v_calculated_total_cents bigint := 0;
  v_item jsonb;
BEGIN
  -- 1. Verificación criptográfica de sesión
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: valid JWT session required for financial mutations';
  END IF;

  -- 2. Resolución o creación atómica del cliente
  IF p_client_data IS NOT NULL AND (p_client_data->>'id') IS NOT NULL THEN
    v_client_id := (p_client_data->>'id')::uuid;
  ELSIF p_client_data IS NOT NULL AND (p_client_data->>'name') IS NOT NULL THEN
    INSERT INTO public.clients (name, phone, address, created_by)
    VALUES (
      p_client_data->>'name',
      p_client_data->>'phone',
      p_client_data->>'address',
      v_actor_id
    )
    RETURNING id INTO v_client_id;
  END IF;

  -- 3. Cálculo determinístico del total en centavos desde los ítems
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_calculated_total_cents := v_calculated_total_cents +
      ((v_item->>'quantity')::integer * (v_item->>'unit_price_cents')::bigint);
  END LOOP;

  -- 4. Upsert de la orden asignando identidad de auditoría desde auth.uid()
  IF p_order_id IS NULL THEN
    INSERT INTO public.orders (
      client_id,
      status,
      payment_method,
      payment_status,
      notes,
      total_cents,
      created_by,
      updated_by
    )
    VALUES (
      v_client_id,
      COALESCE(p_order_data->>'status', 'pending'),
      p_order_data->>'payment_method',
      COALESCE(p_order_data->>'payment_status', 'pending'),
      p_order_data->>'notes',
      v_calculated_total_cents,
      v_actor_id,
      v_actor_id
    )
    RETURNING id INTO v_order_id;
  ELSE
    UPDATE public.orders
    SET
      client_id = COALESCE(v_client_id, client_id),
      status = COALESCE(p_order_data->>'status', status),
      payment_method = COALESCE(p_order_data->>'payment_method', payment_method),
      payment_status = COALESCE(p_order_data->>'payment_status', payment_status),
      notes = COALESCE(p_order_data->>'notes', notes),
      total_cents = v_calculated_total_cents,
      updated_by = v_actor_id,
      updated_at = now()
    WHERE id = p_order_id
    RETURNING id INTO v_order_id;

    DELETE FROM public.order_items WHERE order_id = v_order_id;
  END IF;

  -- 5. Inserción masiva de líneas de pedido
  INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_cents)
  SELECT
    v_order_id,
    (item->>'product_id')::bigint,
    (item->>'quantity')::integer,
    (item->>'unit_price_cents')::bigint
  FROM jsonb_array_elements(p_items) AS item;

  RETURN jsonb_build_object(
    'ok', true,
    'order_id', v_order_id,
    'total_cents', v_calculated_total_cents
  );
END;
$$;
```

### B. RPC Atómica de Cierre de Caja (`rpc_close_cash_register`)

Garantiza que el registro del arqueo (`cash_closings`) y el archivado de órdenes del día (`status = 'archived'`) ocurran de forma indivisible y estrictamente acotada a la fecha operativa (`p_closing_date`), previniendo el borrado accidental de órdenes de otras jornadas:

```sql
CREATE OR REPLACE FUNCTION public.rpc_close_cash_register(
  p_closing_date date,
  p_expected_cash_cents bigint,
  p_actual_cash_cents bigint,
  p_expenses_cents bigint,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
  v_closing_id bigint;
  v_archived_count integer;
BEGIN
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: valid session required to close cash register';
  END IF;

  -- 1. Registrar o actualizar el arqueo de la fecha indicada
  INSERT INTO public.cash_closings (
    closing_date,
    expected_cash_cents,
    actual_cash_cents,
    difference_cents,
    expenses_cents,
    notes,
    closed_by
  )
  VALUES (
    p_closing_date,
    p_expected_cash_cents,
    p_actual_cash_cents,
    (p_actual_cash_cents - p_expected_cash_cents),
    p_expenses_cents,
    p_notes,
    v_actor_id
  )
  ON CONFLICT (closing_date)
  DO UPDATE SET
    expected_cash_cents = EXCLUDED.expected_cash_cents,
    actual_cash_cents = EXCLUDED.actual_cash_cents,
    difference_cents = EXCLUDED.difference_cents,
    expenses_cents = EXCLUDED.expenses_cents,
    notes = EXCLUDED.notes,
    closed_by = v_actor_id,
    updated_at = now()
  RETURNING id INTO v_closing_id;

  -- 2. Archivar exclusivamente las órdenes correspondientes a la fecha cerrada
  WITH archived AS (
    UPDATE public.orders
    SET
      status = 'archived',
      updated_by = v_actor_id,
      updated_at = now()
    WHERE order_date = p_closing_date
      AND status <> 'archived'
    RETURNING id
  )
  SELECT count(*) INTO v_archived_count FROM archived;

  RETURN jsonb_build_object(
    'ok', true,
    'closing_id', v_closing_id,
    'archived_orders', v_archived_count
  );
END;
$$;
```

---

## 3. Solución 2: Estandarización Monetaria en Enteros (Centavos)

Nunca se debe operar dinero con `parseFloat` en el cliente. Todo cálculo de subtotales, combos de precio fijo y arqueos de billetes se ejecuta en **enteros (centavos)**:

```typescript
/** Convierte un input decimal o numérico de usuario a centavos enteros sin error IEEE 754 */
export function toCents(amount: number | string): number {
  const normalized = typeof amount === 'string' ? amount.replace(',', '.').trim() : String(amount);
  const parsed = Number(normalized);
  if (Number.isNaN(parsed)) return 0;
  return Math.round(parsed * 100);
}

/** Convierte centavos enteros a representación visual formateada */
export function formatCurrencyFromCents(
  cents: number,
  locale = 'es-AR',
  currency = 'ARS'
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(cents / 100);
}

/** Calcula porcentaje de ahorro en un Combo/Oferta de precio fijo usando enteros */
export function calculateComboDiscountPercent(
  items: Array<{ unitPriceCents: number; quantity: number }>,
  comboFixedPriceCents: number
): number {
  const originalTotalCents = items.reduce(
    (acc, item) => acc + item.unitPriceCents * item.quantity,
    0
  );
  if (originalTotalCents <= 0 || comboFixedPriceCents >= originalTotalCents) return 0;
  return Math.round(((originalTotalCents - comboFixedPriceCents) / originalTotalCents) * 100);
}
```

---

## 4. Solución 3: Aislamiento de Re-Renders con `react-hook-form`

En formularios transaccionales con grillas dinámicas (ítems de pedido, contadores de denominaciones de billetes), se prohíbe el patrón `value={formData.field}` + `onChange={e => setFormData({...formData, field: e.target.value})}`.

### Reglas de Implementación
1. **Inputs Nativos No Controlados (`register`):** Conectar campos de texto y cantidades mediante `register('client_name')` para que las pulsaciones no re-rendericen la vista padre.
2. **Listas Dinámicas (`useFieldArray`):** Administrar líneas de `order_items` o denominaciones de billetes con `useFieldArray` para mutar filas individuales en $O(1)$ renders.
3. **Cálculos Derivados Suscritos (`useWatch`):** Aislar el componente `<OrderTotalSummary control={control} />` usando `useWatch` únicamente en el subcomponente que muestra el total.

---

## 5. Cuándo Aplicar este Patrón

| Escenario | Regla de Ingeniería |
| :--- | :--- |
| Creación/edición de órdenes, facturas o cierres de caja | Ejecutar en una sola RPC transaccional (`BEGIN...COMMIT`). |
| Registro de autoría (`created_by`, `updated_by`, `closed_by`) | Asignar siempre en servidor mediante `auth.uid()`, nunca desde el body del cliente. |
| Cálculos de subtotales, vueltos, descuentos de combos y arqueo | Operar en enteros (`*_cents`) y formatear con `Intl.NumberFormat` solo en la vista. |
| Formularios POS con más de 5 inputs o tablas anidadas | Usar `react-hook-form` + `useFieldArray` + `useWatch`. |
