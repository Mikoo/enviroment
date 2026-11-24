---
name: whatsapp-cloud-webhook
description: Use when implementing serverless Meta WhatsApp Cloud API webhooks on Supabase Edge Functions (Deno), verifying webhook handshakes and HMAC signatures, or separating free 24h Service replies from pre-approved Utility templates.
---

# WhatsApp Cloud API Serverless Webhook

## Scope
Meta WhatsApp Cloud API integration using serverless edge functions (Deno/TypeScript) and PostgreSQL event triggers.

## Core Rules
1. **Verify both HTTP methods securely:**
   - `GET` (Meta verification handshake): validate `hub.mode === 'subscribe'` and `hub.verify_token === META_VERIFY_TOKEN`, returning `hub.challenge` with HTTP 200 (or 403 otherwise).
   - `POST` (incoming messages): validate `x-hub-signature-256` HMAC-SHA256 against `META_APP_SECRET` over raw request bytes **before** parsing JSON or querying DB.
2. **Respond 200 OK fast to Meta:** Offload heavy downstream tasks or answer immediately so Meta does not trigger exponential webhook retries.
3. **Minimize billing via Service vs. Utility split:**
   - **Service Window (24h, user-initiated):** Use freeform text or interactive lists when replying to incoming customer questions (daily menu, prices, status).
   - **Utility Conversation (business-initiated):** Trigger pre-approved Meta `template` messages (e.g., `pedido_en_camino`) **only** on critical state transitions (such as `status = 'delivery'`).
4. **Never expose `META_ACCESS_TOKEN` or `SUPABASE_SERVICE_ROLE_KEY` to client code.** Keep all Graph API calls inside Edge Functions or server workers.

## Deep Reference
Read `../../../patterns/messaging/whatsapp-cloud-api-serverless-webhook.md` for full Deno `serve()` handler and template sender code.
