---
name: voice-and-memory-pipeline
description: Use when building real-time WebAudio voice pipelines across Chromium and Apple WebKit (Safari/iOS WKWebView), Silero VAD speech segmentation, Groq Whisper + structured JSON LLM inference, or 3-tier episodic memory with Open Loops.
---

# Low-Latency Voice & 3-Tier Episodic Memory

## Scope
Browser/WebView voice capture, client-side VAD, fast STT+LLM JSON turns, and relational episodic memory without vector database overhead.

## Core Rules
1. **Adaptive multi-codec capture:** Probe `MediaRecorder.isTypeSupported` across `audio/webm;codecs=opus` (Chromium/Android) down to `audio/mp4;codecs=mp4a.40.2` / `audio/mp4` (Apple WebKit/iOS Safari).
2. **Unlock iOS `AudioContext` on user gesture:** Resume suspended `AudioContext` inside `pointerdown`/`touchend` and play a 1-sample silent buffer to unlock hardware playback.
3. **Client-side Silero VAD (`@ricky0123/vad-web`):** Set `redemptionFrames: 6` (~600ms pause cutoff so bilingual learners can think mid-sentence without clipping), `positiveSpeechThreshold: 0.65`, `minSpeechFrames: 3`.
4. **Bilingual STT + Strict JSON LLM:** Use `whisper-large-v3-turbo` with `verbose_json` and `word` timestamps for live WPM/speech-duration math. Never force `language: "en"` if code-switching (Spanglish) is expected. Enforce JSON output schema for reply, emotion, language metrics, and `memory_updates`.
5. **3-Tier Memory (`Working RAM` $\rightarrow$ `user_life_facts` Open Loops $\rightarrow$ `session_buckets`):** Mark future/ongoing user events (`is_open_loop: true`, `follow_up_after`) to trigger proactive recall in the next session.

## Deep Reference
Read `../../../patterns/ai-agents/low-latency-voice-and-3tier-memory.md` for `resolveSupportedAudioMime()`, `unlockAudioContextOnGesture()`, `MicVAD` setup, and the LLM JSON contract.
