---
name: pos-financial-integrity
description: Use when implementing or auditing orders, payments, cash register closings, inventory deductions, combo discounts, or dense financial forms in PostgreSQL/Supabase + React to guarantee atomic transactions, server-side auth.uid() attribution, integer-cents arithmetic, and zero-lag forms.
---

# POS Financial Integrity & Atomic RPCs

## Scope
Multi-table financial mutations, cash register closings, client account ledgers, and monetary arithmetic in PostgreSQL/Supabase + JS/TS frontends.

## Core Rules
1. **One atomic RPC per multi-table financial operation:** Never chain separate client requests (`insert order` -> `delete items` -> `insert items`, or `insert closing` -> `archive orders`). Wrap everything in a single `plpgsql` `SECURITY DEFINER` RPC (`SET search_path = public`) so PostgreSQL commits or rolls back atomically.
2. **Server-side operator identity (`auth.uid()`):** Reject `auth.uid() IS NULL` and derive `created_by`, `updated_by`, and `closed_by` strictly on the server. Ignore client-supplied user IDs.
3. **Integer cents arithmetic only:** Never calculate totals, discounts, or cash differences with `parseFloat` or floating-point multiplication in JS. Convert inputs with `toCents()`, compute in integer `bigint`/`*_cents`, and format only at display time via `Intl.NumberFormat`.
4. **Scope closings and exclude voided orders:** Cash closings must aggregate and archive strictly `WHERE order_date = p_closing_date` and exclude `status IN ('voided', 'cancelled')`.
5. **Isolate dense form re-renders:** Use `react-hook-form` (`register`, `useFieldArray`, `useWatch` isolated to summary components) instead of top-level `useState` per keystroke.

## Do / Avoid

### Do
- Recalculate order totals and daily cash summaries inside PostgreSQL rather than trusting frontend totals.
- Use `SECURITY DEFINER` RPCs for FIFO debt reconciliation and `>= 1000` row aggregations (bypassing PostgREST default row caps safely).

### Avoid
- `value={formData.amount}` + `setFormData({...})` on large item grids or bill counters.
- `qty * parseFloat(price)` in browser code for persistent financial values.

## Deep Reference
Read `../../../patterns/backend/pos-financial-integrity-atomic-rpcs.md` when implementing `rpc_process_order`, `rpc_close_cash_register`, `toCents`, or `react-hook-form` patterns.
