## 21. Mobile system design

### Framework (use this in every answer)
1. **Clarify requirements** (functional + non-functional).
2. **Define APIs** (REST endpoints + payloads).
3. **Data model** (server + client).
4. **Client architecture** (layers, modules).
5. **Offline + sync**.
6. **Security** (auth, storage, transport).
7. **Observability** (crashes, perf, analytics).
8. **Scaling** (users, devices, network).
9. **Trade-offs** (you must say "I would NOT do X because Y").

### 5 problems to rehearse cold

#### 1. Insta-style feed
- Cursor pagination (keyset, not offset).
- Image prefetch for next N items.
- FlashList for recycling.
- Cache normalized in React Query.
- Offline: persist last page in MMKV.

#### 2. WhatsApp messaging
- Local SQLite (or WatermelonDB) for messages.
- Outbox queue for sends.
- WebSocket for real-time + push as fallback.
- Message states: pending → sent → delivered → read.
- Conflict-free message IDs (UUID v7 or ULID).

#### 3. Zerodha-style order placement
- Idempotency key per order.
- Optimistic UI with reconciliation.
- WebSocket for live order book + price.
- On reconnect: fetch order status → update local.
- Crash mid-order: on next open, query backend by idempotency key.

#### 4. Offline-first neobank account screen
- MMKV for hot data (balance, last 10 txns).
- WatermelonDB for full transaction history.
- Outbox for pending transfers.
- Background sync on foreground + push.
- Show "as of HH:MM" timestamp when offline.

#### 5. Payments flow (PCI-aware)
- Server-generated payment intent / order.
- Client uses payment SDK (PCI scope offloaded).
- Idempotency key client → server.
- Webhook confirms final state on backend.
- Client polls / listens for state.
- On crash: reconcile from backend on next open.

### Must-answer questions
1. Walk me through designing offline-first banking screen.
2. How would you architect a 10-engineer RN monorepo?
3. Real-time portfolio: WebSocket vs polling.
4. No-duplicate-charge guarantee.
5. Modularize a 50-screen RN app.

---



---

## Top 25 Q&A — Mobile system design

### 1. Framework for any mobile system design.
**RDA-CSPO**: Requirements → Data model → APIs → Client architecture → Storage → Performance → Observability. Always clarify scale + offline behavior first.

### 2. Design WhatsApp-like chat (mobile).
Local SQLite for messages, WS for real-time, push for delivery, FCM/APNs payload triggers fetch, idempotent send via clientMsgId, end-to-end encryption optional.

### 3. Design Instagram feed.
GraphQL pagination (cursor), prefetch next page, image CDN with multi-resolution, FlashList virtualization, optimistic likes, stale-while-revalidate cache.

### 4. Design Uber-like map.
Map SDK with native module, polling driver location every 4–8s (or WS), background location with battery-aware throttling, offline trip queue.

### 5. Design payment flow (PhonePe-style).
Tokenized card via PCI vault, biometric step-up, idempotency key per txn, server-driven UI for compliance, retry with backoff, post-success webhook + client polling.

### 6. Design KYC flow.
Step machine (XState), camera capture with on-device compression, upload with resumable multipart, server OCR, status long-poll, allow resume across sessions.

### 7. Offline-first todo app.
Local SQLite/Watermelon, mutation outbox, sync engine with delta cursor, LWW conflict resolution, background sync via WorkManager/BGTask.

### 8. Push-driven order tracking.
Initial GET on screen mount, WS subscribe for live, push for OS-killed scenarios (silent + foreground combo), local cache replay on reopen.

### 9. Image upload at scale.
Compress on device (target 1080p, 80% quality), pre-signed URL flow, parallel chunks for >5MB, retry per chunk, exponential backoff.

### 10. Video upload + processing.
Background task; multi-part to S3; server transcodes; client polls / push on completion. Show local preview immediately.

### 11. Real-time stock ticker.
WS multiplexed channel; throttle UI updates to 4–10/s using requestAnimationFrame batching; Reanimated worklets for animations off JS thread.

### 12. Design discount/cart engine on client.
Pure functional rules engine; server is source of truth — client mirrors for UX speed; final amount confirmed server-side at checkout.

### 13. Multi-tenant white-label app.
Theme tokens via Context, feature flags per tenant, separate signing per build, EAS profiles per tenant, shared core monorepo.

### 14. Brownfield: integrate RN screen into native app.
Single RN bundle + multiple root views OR multiple bundles. Bridgeless mode helps. Pass nav state via props. Share auth via native module.

### 15. Background sync architecture.
Outbox queue in SQLite/MMKV; WorkManager (Android) / BGTaskScheduler (iOS); reconciler with cursor; observability per attempt.

### 16. Feature flags strategy.
Remote config (Firebase / LaunchDarkly / Statsig). Bucket by userId, persist evaluation, cache 5–10 min, kill-switch keys for incidents.

### 17. App update enforcement.
Soft (banner) and hard (blocking) update screens, fetched from `/version` endpoint, gracefully handle in-flight requests.

### 18. Search with autocomplete.
Debounce 200ms, cancel previous, in-memory LRU cache by query, server-side typeahead, abort on screen blur.

### 19. End-to-end encryption (chat).
Per-user X25519 key, prekeys uploaded, double-ratchet (Signal Protocol). RN: native module wrapping libsignal.

### 20. Voice / video call architecture.
Native SDK (Twilio, Agora, WebRTC). RN orchestrates UI; native handles media. CallKit (iOS) / ConnectionService (Android) for incoming.

### 21. Multi-account support.
Profile namespace in storage (`MMKV.id = userId`), separate token slots in Keychain, allow switch without logout.

### 22. Server-driven UI (SDUI).
Backend returns JSON describing components; client renders via registry. Pros: ship UI fast. Cons: harder a11y, complex client renderer, debugging.

### 23. Caching strategy across layers.
Memory (React Query) → MMKV (warm) → SQLite (cold). TTL + invalidation by tag. Show stale + revalidate.

### 24. Resilient checkout.
Stateful order on server pre-payment; client shows status; idempotent POST with key; reconnect UI shows last known state; retry via deep link.

### 25. Capacity & cost considerations for mobile system design.
Bandwidth (image sizes, payload), storage on device (cap, evict), battery (location, WS heartbeat), API cost (cache, batch). Always quantify per active user.
