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



---

## Top 25 Q&A — Networking, REST, GraphQL, WebSockets

### 1. `fetch` vs `axios` in RN — which?
Both fine. `axios` adds interceptors, request/response transforms, cancel tokens, easier error shape. For modern RN, `fetch` + small wrapper is enough.

### 2. Standard API client pattern.
```ts
const api = axios.create({ baseURL, timeout: 10000 });
api.interceptors.request.use(cfg => { cfg.headers.Authorization = `Bearer ${getToken()}`; return cfg; });
api.interceptors.response.use(r => r, async err => {
  if (err.response?.status === 401) { await refresh(); return api(err.config); }
  throw err;
});
```

### 3. Token refresh — handle race conditions.
Queue concurrent 401s, refresh once, replay all. Use a single in-flight refresh promise.

### 4. Cancel requests on unmount.
```ts
useEffect(() => {
  const ctrl = new AbortController();
  fetch(url, { signal: ctrl.signal });
  return () => ctrl.abort();
}, [url]);
```

### 5. Retry with exponential backoff.
```ts
async function withRetry(fn, n=3, base=300){
  for (let i=0; i<n; i++){ try { return await fn(); }
    catch(e){ if(i===n-1) throw e; await new Promise(r=>setTimeout(r, base*2**i + Math.random()*100)); } }
}
```

### 6. REST vs GraphQL — when each?
REST: simple resources, caching by URL, public APIs. GraphQL: aggregated screen data, mobile-first, evolving schemas.

### 7. Apollo Client vs urql vs Relay?
Apollo: most popular, normalized cache. urql: lighter, exchanges plugin model. Relay: strictest, fragment-driven, perf-best, steeper.

### 8. WebSocket basics in RN.
```ts
const ws = new WebSocket('wss://api.example.com');
ws.onopen = () => ws.send('hi');
ws.onmessage = e => console.log(e.data);
ws.onclose = () => reconnect();
```

### 9. Reconnect strategy for WS.
Exponential backoff + jitter, cap max delay (~30s), heartbeat ping every 25–30s, reset on visibility/foreground change.

### 10. Server-Sent Events (SSE) in RN?
No native EventSource. Use `react-native-sse` or polyfill. Useful for one-way streams (live scores, order status).

### 11. Pagination strategies.
- **Offset** (`?page=1&limit=20`): simple, breaks on inserts.
- **Cursor** (`?after=xyz`): stable for live feeds.
- **Infinite scroll** with React Query `useInfiniteQuery`.

### 12. Caching — HTTP layer.
RN respects `Cache-Control` via native HTTP stack but JS doesn't expose easily. Use React Query / RTK Query for app-level cache.

### 13. Multipart upload (image/file).
```ts
const fd = new FormData();
fd.append('file', { uri, name: 'a.jpg', type: 'image/jpeg' } as any);
fetch(url, { method: 'POST', body: fd });
```

### 14. Background upload?
Use `react-native-background-upload` / Expo `BackgroundFetch`. iOS requires URLSession background config; Android requires WorkManager.

### 15. Validate API responses with Zod.
```ts
const User = z.object({ id: z.string(), email: z.string().email() });
const data = User.parse(await res.json()); // throws on shape mismatch
```

### 16. Handle slow networks gracefully.
Skeleton loaders, optimistic UI, exponential backoff, allow user to "retry now", show offline banner via `NetInfo`.

### 17. NetInfo usage.
```ts
NetInfo.addEventListener(state => setOnline(state.isConnected && state.isInternetReachable));
```

### 18. Idempotency keys — why?
Client retries can duplicate writes. Send `Idempotency-Key: <uuid>`; server dedupes within a window. Critical for payments.

### 19. Cert pinning — how?
`react-native-cert-pinner` / `react-native-ssl-pinning`. Pin SPKI hash; ship multiple pins (current + next) to allow rotation.

### 20. JWT vs opaque token vs session cookie?
JWT: stateless, big payload, hard revocation. Opaque + introspect: revocable, server lookup. Cookies: web/native shared sessions.

### 21. Avoid sending cookies on RN fetch.
Defaults differ; explicitly `credentials: 'include'` if using cookie auth. For Bearer tokens, set `Authorization` header.

### 22. Polling vs WS — choose.
Polling: simple, fine for low-frequency (every 30s+). WS: bi-directional, real-time. Hybrid: poll on background, WS on foreground.

### 23. GraphQL persisted queries — why?
Send only a hash, server resolves to query → smaller payload, can be CDN-cached, hides queries.

### 24. Error normalization across API versions.
Map server errors to a single `AppError` with `code`, `message`, `userFacing`. UI maps `code` → toast/dialog.

### 25. Code: typed React Query hook.
```ts
export const useUser = (id: string) =>
  useQuery({
    queryKey: ['user', id],
    queryFn: async ({ signal }) => User.parse(await fetch(`/u/${id}`, { signal }).then(r => r.json())),
    staleTime: 60_000,
  });
```
