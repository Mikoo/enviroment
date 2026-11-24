---
title: "Pattern: High-Density UI (1366x768), Zero-CLS & 60FPS Direct-DOM Gestures"
tags:
  - pattern/ui-ux
  - pattern/performance
  - tailwindcss-v4
  - responsive-1366x768
  - pointer-events
  - zero-cls
created: 2026-11-01
status: active
---

# 🖥️ Pattern: High-Density UI (1366x768), Zero-CLS & 60FPS Direct-DOM Gestures

> **Contexto:** Heurísticas de ingeniería de interfaz para paneles operativos de alta densidad (POS, tableros de cocina/logística, ERPs y dashboards administrativos) optimizados para pantallas de laptop estándar (`1366x768`) y tablets táctiles con interacciones a `60 FPS`.

Relacionado con: [Catálogo de Patrones](../README.md)

---

## 1. Problema Arquitectónico

Los sistemas operativos de mostrador y logística suelen ejecutarse en laptops de `1366x768` (donde la altura útil del viewport tras descontar barra de tareas del SO y pestañas del navegador es de apenas **~640–660px**) o en tablets de reparto. Cuatro antipatrones degradan la operatividad:

1. **Asfixia Vertical por Paddings Simétricos:** Usar `p-8` (`64px` verticales) en el layout principal desperdicia el 10% del viewport vertical antes de mostrar un solo dato.
2. **Tablas Infinitas y Modales Desbordados:** Tablas sin `max-h` empujan los filtros fuera de la pantalla al hacer scroll, y modales con footers externos (`-mt-6` fuera del contenedor scrollable) esconden alertas críticas de stock bajo el borde inferior en `768px`.
3. **Cumulative Layout Shift (CLS) y Clases Dinámicas Rotas en Tailwind:** Retornar `null` durante `loading` provoca saltos bruscos cuando llegan los datos de Supabase, mientras que interpolar clases como ``bg-${color}-500`` falla en producción porque el escáner estático de Tailwind v4 las purga.
4. **Jank en Gestos de Swipe por `useState` en `pointermove`:** Actualizar el estado de React en cada píxel de desplazamiento táctil dispara 60–120 reconciliaciones del Virtual DOM por segundo, congelando dispositivos móviles/tablets.

---

## 2. Solución 1: Heurísticas de Viewport `1366x768` (Presupuesto Vertical de 650px)

### A. Padding Asimétrico en Layout Principal
Preservar la respiración horizontal pero comprimir el eje vertical en el contenedor `<main>`:

```tsx
// ❌ Antipatrón: md:p-8 desperdicia 64px verticales en 1366x768
// ✅ Patrón: md:py-4 md:px-6 ahorra 32px verticales manteniendo legibilidad lateral
<main className="flex-1 md:py-4 md:px-6 overflow-x-hidden">
  {children}
</main>
```

### B. Tablas de Datos Acotadas al Viewport con Header Fijo
Encapsular las tablas operativas en contenedores con altura calculada respecto al viewport (`calc(100vh - offset)`) para que los buscadores y filtros superiores permanezcan siempre visibles:

```tsx
<div className="hidden lg:block card-organic p-0 max-h-[calc(100vh-240px)] overflow-y-auto overflow-x-auto">
  <table className="w-full border-collapse">
    <thead className="sticky top-0 z-10 bg-surface-elevated">
      {/* Columnas fijas */}
    </thead>
    <tbody>
      {/* Filas con acciones rápidas en hover */}
    </tbody>
  </table>
</div>
```

### C. Modales Flex-Col con Footer Estático (`shrink-0`)
Nunca posicionar alertas o barras de acciones fuera del contenedor límite del modal. Usar un único wrapper `max-h-[90vh] flex flex-col`:

```tsx
<div className="w-full max-w-4xl max-h-[90vh] flex flex-col rounded-3xl bg-white shadow-2xl overflow-hidden">
  {/* 1. Cabecera Fija */}
  <header className="shrink-0 px-6 py-4 border-b">...</header>

  {/* 2. Cuerpo Scrollable (absorbe el espacio disponible) */}
  <div className="flex-1 overflow-y-auto p-6">
    {/* Grilla horizontal de 2 columnas para aprovechar los 1366px de ancho */}
  </div>

  {/* 3. Footer / Alerta de Stock siempre visible al pie */}
  <footer className="shrink-0 px-6 py-3 bg-amber-50 border-t">
    <StockAlertFooter />
  </footer>
</div>
```

---

## 3. Solución 2: Prevención de Layout Shifts (Zero-CLS) y Mapas Estáticos en Tailwind v4

### A. Skeletons con Dimensiones Reservadas
Reemplazar cualquier `if (loading) return null;` en bloques superiores (como configuradores de menú diario o KPIs) por un contenedor con la misma altura geométrica:

```tsx
if (loading) {
  return (
    <div
      aria-busy="true"
      className="h-[180px] mb-6 rounded-3xl border border-sage-100 bg-sage-50/50 animate-pulse"
    />
  );
}
```

### B. Diccionario Estático de Variantes (`colorMap`) para Tailwind v4
Tailwind CSS v4 (con `@tailwindcss/postcss` y `@theme` en `index.css`) analiza archivos de forma estática. Nunca interpolar nombres de tokens dinámicamente:

```tsx
const KPI_COLOR_MAP = {
  emerald: {
    bg: 'bg-emerald-50',
    text: 'text-emerald-700',
    border: 'border-emerald-200',
  },
  amber: {
    bg: 'bg-amber-50',
    text: 'text-amber-700',
    border: 'border-amber-200',
  },
  rose: {
    bg: 'bg-rose-50',
    text: 'text-rose-700',
    border: 'border-rose-200',
  },
} as const;
```

---

## 4. Solución 3: Pipeline de Gestos Swipe a 60 FPS (Direct-DOM PointerEvents)

Para avanzar o retroceder estados en listas operativas (ej. `Pendiente` $\leftrightarrow$ `En Reparto` $\leftrightarrow$ `Entregado`) mediante deslizamiento táctil o con mouse sin provocar re-renders durante el arrastre:

1. **Durante `pointermove`:** Mutar directamente `cardRef.current.style.transform = translate3d(${deltaX}px, 0, 0)` usando referencias DOM, manteniendo **0 llamadas a `setState`**.
2. **Durante `pointerup` / `pointercancel`:** Evaluar si `Math.abs(deltaX) >= SWIPE_THRESHOLD_PX` (ej. `80px`). Solo en ese instante se invoca el callback de transición de estado de React y se restaura la transición CSS.

```typescript
import { useRef, useCallback } from 'react';

interface SwipeOptions {
  thresholdPx?: number;
  onSwipeRight?: () => void;
  onSwipeLeft?: () => void;
}

export function useSwipeGesture<T extends HTMLElement>({
  thresholdPx = 80,
  onSwipeRight,
  onSwipeLeft,
}: SwipeOptions) {
  const elementRef = useRef<T | null>(null);
  const startXRef = useRef<number | null>(null);
  const currentDeltaXRef = useRef<number>(0);

  const onPointerDown = useCallback((e: React.PointerEvent<T>) => {
    startXRef.current = e.clientX;
    currentDeltaXRef.current = 0;
    if (elementRef.current) {
      elementRef.current.style.transition = 'none';
      elementRef.current.setPointerCapture(e.pointerId);
    }
  }, []);

  const onPointerMove = useCallback((e: React.PointerEvent<T>) => {
    if (startXRef.current === null || !elementRef.current) return;
    const deltaX = e.clientX - startXRef.current;
    currentDeltaXRef.current = deltaX;
    // Mutación directa al compositor GPU (60 FPS garantizados, 0 React re-renders)
    elementRef.current.style.transform = `translate3d(${deltaX}px, 0, 0)`;
  }, []);

  const onPointerUp = useCallback(() => {
    if (startXRef.current === null || !elementRef.current) return;
    const deltaX = currentDeltaXRef.current;
    startXRef.current = null;

    elementRef.current.style.transition = 'transform 200ms cubic-bezier(0.2, 0.8, 0.2, 1)';
    elementRef.current.style.transform = 'translate3d(0, 0, 0)';

    if (deltaX >= thresholdPx && onSwipeRight) {
      onSwipeRight();
    } else if (deltaX <= -thresholdPx && onSwipeLeft) {
      onSwipeLeft();
    }
  }, [thresholdPx, onSwipeRight, onSwipeLeft]);

  return {
    elementRef,
    swipeHandlers: {
      onPointerDown,
      onPointerMove,
      onPointerUp,
      onPointerCancel: onPointerUp,
    },
  };
}
```
