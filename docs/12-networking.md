## 12. Networking, REST, GraphQL, WebSockets

### REST + axios/fetch
- `fetch` is fine; axios gives interceptors.
- Always set timeout (no default in fetch — wrap with `AbortController`).
- Retry on idempotent methods (GET) with backoff.

### GraphQL
- Apollo Client or urql.
- Normalized cache; query/mutation/subscription.
- Persisted queries (security + perf).

### WebSockets
- `WebSocket` global; reconnect with exponential backoff + jitter.
- Heartbeat ping every 20–30s to detect dead sockets.
- Close cleanly on background/foreground transitions.

### Single-flight token refresh (asked in fintech loops)
```js
let refreshing = null;
async function authedFetch(url, opts) {
  let res = await fetch(url, withToken(opts));
  if (res.status === 401) {
    refreshing ??= refreshToken().finally(() => refreshing = null);
    await refreshing;
    res = await fetch(url, withToken(opts));
  }
  return res;
}
```

### Idempotency keys (payment-grade)
- Client generates UUID per intent → server dedupes.
- Replay-safe; survives retries.

### Must-answer questions
1. Handle 10 concurrent 401s (single-flight).
2. Idempotency for payment retries.
3. WebSocket reconnect strategy.
4. REST vs GraphQL — trade-offs.
5. Cancel in-flight requests on screen unmount.

---

