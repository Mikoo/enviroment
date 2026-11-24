---
name: dense-ui-1366x768
description: Use when building or refactoring dense operational dashboards, POS screens, tables, or modals targeted at 1366x768 laptop displays (~650px usable height), Tailwind CSS v4 themes, Zero-CLS loading states, or 60 FPS touch/pointer swipe interactions.
---

# High-Density UI (`1366x768`), Zero-CLS & 60 FPS Gestures

## Scope
Operational web dashboards, React/Vite/Tailwind v4 interfaces, data tables, modals, and mobile/tablet swipe cards.

## Core Rules
1. **Respect the 650px vertical budget (`1366x768`):**
   - Use asymmetric main padding (`md:py-4 md:px-6`) instead of `md:p-8` (saves 32px vertically).
   - Bound table containers with `max-h-[calc(100vh-240px)] overflow-y-auto` and `sticky top-0 z-10` headers so top filters never scroll off-screen.
   - Structure modals as `flex flex-col max-h-[90vh] overflow-hidden` with `shrink-0` header/footer and `flex-1 overflow-y-auto` body (never hang footers outside with `-mt-6`).
2. **Prevent Layout Shift (Zero-CLS):** Never `if (loading) return null` on above-the-fold panels. Render fixed-height skeleton placeholders matching the loaded geometry.
3. **Tailwind CSS v4 static tokens:** Never interpolate class names like ``bg-${color}-500`` (purged by static scanner). Use a static lookup dictionary (`colorMap`). Keep `@theme` rules in `src/index.css` with `@tailwindcss/postcss` rather than legacy `tailwind.config.js`.
4. **60 FPS Direct-DOM Gestures:** During `pointermove`, mutate `elementRef.current.style.transform = translate3d(${dx}px, 0, 0)` directly via refs with **zero `setState` calls**. Commit React state only on `pointerup` past threshold.

## Deep Reference
Read `../../../patterns/frontend/dense-data-ui-1366x768-60fps.md` for full JSX modal templates, `colorMap` pattern, and the `useSwipeGesture` TypeScript hook.
