---
name: tauri-v2-crossplatform
description: Use when configuring SvelteKit SPA builds with Tauri v2 across Windows, macOS, Android, and iOS, transparent always-on-top desktop overlays, Zero-Idle connection/FPS management, or extensible Plugin Mode Registry patterns.
---

# Tauri v2 Cross-Platform, Zero-Idle & Plugin Registry

## Scope
SvelteKit static SPA frontends bundled into Tauri v2 binaries for desktop (Windows/macOS) and mobile (Android/iOS).

## Core Rules
1. **Static SPA only (`ssr = false`):** Configure `@sveltejs/adapter-static` (`fallback: 'index.html'`, `strict: true`) and set `export const ssr = false; export const prerender = true;` in `src/routes/+layout.ts` because Tauri serves assets inside WebViews with no Node server.
2. **OS-specific window and permission rules:**
   - Desktop transparent floating window (`decorations: false`, `transparent: true`, `alwaysOnTop: true`) requires `"macOSPrivateApi": true` in `tauri.conf.json` for macOS WKWebView alpha rendering.
   - Mobile builds ignore desktop transparency/alwaysOnTop; respect CSS `safe-area-inset-*` and declare mic permissions (`NSMicrophoneUsageDescription` on Apple, `RECORD_AUDIO` on Android).
3. **Zero-Idle Connections & FPS throttling:**
   - Never keep persistent WebSocket / Supabase Realtime subscriptions open when idle; sync via coalesced HTTPS RPCs.
   - After 120s inactivity: pause Silero VAD, call `audioCtx.suspend()`, and throttle animation (`60 FPS` active $\rightarrow$ `12 FPS` idle $\rightarrow$ `0 FPS` hidden).
4. **Plugin Mode Registry:** Register interaction modes via `CompanionModePlugin` (`onEnter`, `onTurnInput`, `onExit`) instead of giant `if/else` conditionals so modes like `inkjs` stories plug in cleanly and release mic/timers on exit.

## Deep Reference
Read `../../../patterns/ai-agents/tauri-v2-zero-idle-and-plugin-registry.md` for `svelte.config.js`, `tauri.conf.json`, state machine, and TypeScript `ModeRegistry` code.
