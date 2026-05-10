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

