# S9 — Networking

> Retries · cancellation · WebSockets · HTTP/3 · certificate pinning

Five Q-topics in the mandatory per-topic format. Production RN networking concerns: idempotent retries, cancellation correctness, long-lived sockets across foreground/background transitions, modern transport (HTTP/3 / QUIC), and TLS pinning with rotation.

---

### Q1. Retry policy design — jitter, exponential backoff, idempotency

---

## Difficulty
- Advanced

## Interview Frequency
- Very Common (asked in nearly every backend-adjacent RN interview)

## Prerequisites
- HTTP basics, async/await, basic distributed systems concepts

## TL;DR
Retry only **idempotent** requests, with **exponential backoff + full jitter**, capped attempts, and an idempotency key sent to the server so duplicates don't double-execute. Never retry on 4xx (except 408/429); always retry on network errors and 5xx (except 501).

---

## 30-Second Interview Answer

> "A correct retry policy has four parts: classify the error (retryable vs not), backoff with jitter (`min(cap, base * 2^attempt) * random(0,1)`), max-attempts cap, and an idempotency key on the wire so the server can dedupe. The classic mistake is retrying POST `/charge` on 5xx without an idempotency key — the server may have processed the request before the timeout. Use AWS-style 'full jitter' to avoid thundering herd on backend recovery. TanStack Query has retry built in but you still own the idempotency contract."

---

## 2-Minute Practical Answer

Decision matrix per error:

| Error | Retry? |
|---|---|
| Network failure (no response) | Yes (with idempotency key for non-GET) |
| 408 Request Timeout | Yes |
| 429 Too Many Requests | Yes — honor `Retry-After` |
| 500, 502, 503, 504 | Yes |
| 501, 505 | No (server cannot handle) |
| 4xx (other) | No (client bug; retrying won't help) |
| 401 | Refresh token then retry once |
| 403 | No (permissions) |

Backoff formula (full jitter, AWS style):
```
delay = random_between(0, min(cap, base * 2^attempt))
```
Default: `base = 200ms`, `cap = 30s`, `max_attempts = 3-5`.

Idempotency: client generates UUID per logical operation; sends as `Idempotency-Key` header. Server stores key + response in cache (TTL 24h+); duplicate keys return cached response without re-executing.

For RN specifically: `fetch` doesn't auto-retry; libraries like `ky` or `axios-retry` add retry; TanStack Query's `retry` / `retryDelay` handle it for query/mutation calls.

---

## 5-Minute Architecture Answer

Three layers must agree:

1. **Client retry library** — backoff, jitter, classification, max attempts.
2. **Wire protocol** — idempotency keys, `Retry-After` headers, ETags for conditional requests.
3. **Server semantics** — idempotent endpoints, idempotency-key dedup window, replay-safe logic.

Failure modes:

- **Thundering herd**: 100k clients retry simultaneously after backend recovers from a 30s outage. Without jitter, they all hit at `t=200ms, 400ms, 800ms…`. With full jitter, retries spread across the window, smoothing load.
- **Double-execution**: POST `/transfer` times out (network blip). Client retries. Server actually processed first request. Without idempotency key, money moves twice.
- **Infinite retry**: no max-attempts cap → battery drain, server abuse, user stuck.
- **Wrong classification**: retrying on 422 (validation error) wastes everyone's time.
- **Retry-After ignored**: server says "wait 60s"; client retries in 200ms → rate-limit ban.

Backoff variants:
- **Exponential** — `base * 2^n`. Simple but synchronizes (thundering herd).
- **Exponential + equal jitter** — `(d/2) + random(0, d/2)`. Smoother.
- **Exponential + full jitter** — `random(0, d)`. AWS-recommended; spreads best, slightly higher mean retry latency.
- **Decorrelated jitter** — `random(base, prev * 3)`. Even smoother for high-contention scenarios.

For mobile specifically: respect **network type** (don't aggressively retry on cellular when there's a 503; user pays for data and battery). Pause retries when app backgrounds (no point); resume on foreground. NetInfo + `onlineManager` integration with TanStack Query handles this.

The 2026 specific: **HTTP/3 / QUIC** changes retry economics — connection setup is faster (0-RTT for known origins), so retries cost less; but QUIC's connection migration also masks some failures that classical HTTP would surface. Tune retry timeouts accordingly.

---

## The "Why"

Networks fail constantly. A naive client either drops user actions on the floor (no retry → bad UX) or duplicates them dangerously (retry without idempotency → wrong server state). Companies care because the retry contract is where mobile reliability meets backend correctness — get it wrong and you have either lost transactions or duplicate transactions, both of which are visible to customers and finance teams.

---

## Mental Model

A retry policy is a **negotiation** with the network: "I'll wait longer each time, and I'll back off entirely if you tell me to. I'll only retry if you might have failed; I won't retry if I know I was wrong." Without the negotiation, you're either too quiet (lose data) or too loud (DDoS yourself).

---

## Internal Working (2026 Context)

`fetch` in RN (Hermes runtime) wraps native `URLSession` (iOS) / `OkHttp` (Android). Retries happen at JS-layer wrappers (TanStack Query, ky, axios-retry) — not at the native layer. This means:
- Cancellation via `AbortController` works at the JS+native boundary (signal flows down).
- Retries re-create the request from scratch (new `fetch` call).
- The native layer's TCP/TLS connection is reused via HTTP/2 or HTTP/3 multiplexing.

TanStack Query retry mechanics:
- `retry: number | boolean | (failureCount, error) => boolean` — controls if/when to retry.
- `retryDelay: number | (failureCount, error) => number` — controls backoff.
- Retries happen between `queryFn` invocations; cache state shows `isFetching`.
- Default: 3 retries, exponential backoff capped at 30s.

Idempotency on the wire: header `Idempotency-Key: <uuid>`. Server stores response (status + body) in Redis or DB keyed by (idempotency_key, route, user_id), TTL 24h+.

---

## Modern Implementation (Code)

```ts
// fetcher.ts — RN fetch wrapper with retry, jitter, idempotency, signal
import { v4 as uuid } from 'uuid';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const NON_RETRYABLE_STATUS = new Set([501, 505]);
const MAX_ATTEMPTS = 4;
const BASE_MS = 200;
const CAP_MS = 30_000;

type FetchOpts = RequestInit & {
  signal?: AbortSignal;
  idempotencyKey?: string;
};

export async function apiFetch(url: string, opts: FetchOpts = {}): Promise<Response> {
  const isWrite = !!opts.method && !['GET', 'HEAD', 'OPTIONS'].includes(opts.method.toUpperCase());
  const headers = new Headers(opts.headers);
  if (isWrite) {
    headers.set('Idempotency-Key', opts.idempotencyKey ?? uuid());
  }

  let lastErr: unknown;
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    if (opts.signal?.aborted) throw new DOMException('aborted', 'AbortError');
    try {
      const res = await fetch(url, { ...opts, headers });
      if (res.ok) return res;
      if (NON_RETRYABLE_STATUS.has(res.status)) return res;
      if (!RETRYABLE_STATUS.has(res.status)) return res; // 4xx generally
      // retryable status
      const retryAfter = res.headers.get('Retry-After');
      const delay = retryAfter
        ? parseRetryAfter(retryAfter)
        : fullJitter(attempt);
      await sleep(delay, opts.signal);
      continue;
    } catch (err: any) {
      if (err.name === 'AbortError') throw err;
      lastErr = err;
      // network error → retry
      await sleep(fullJitter(attempt), opts.signal);
    }
  }
  throw lastErr ?? new Error('network failed after retries');
}

function fullJitter(attempt: number): number {
  const exp = Math.min(CAP_MS, BASE_MS * 2 ** attempt);
  return Math.random() * exp;
}

function parseRetryAfter(v: string): number {
  const seconds = Number(v);
  if (!Number.isNaN(seconds)) return seconds * 1000;
  const date = new Date(v).getTime();
  return Math.max(0, date - Date.now());
}

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const t = setTimeout(resolve, ms);
    signal?.addEventListener('abort', () => {
      clearTimeout(t);
      reject(new DOMException('aborted', 'AbortError'));
    });
  });
}
```

```ts
// usage with TanStack Query
useMutation({
  mutationFn: ({ orderId, key }: { orderId: string; key: string }) =>
    apiFetch(`/orders/${orderId}/pay`, {
      method: 'POST',
      idempotencyKey: key,         // stable across retries for same logical op
    }),
  retry: (count, err: any) => err?.status >= 500 && count < 2,
});
```

---

## Comparison

| Library | Retry | Jitter | Idempotency | Notes |
|---|---|---|---|---|
| `fetch` (built-in) | none | none | none | bring your own wrapper |
| `ky` | yes | yes (configurable) | manual | small, modern |
| `axios` + `axios-retry` | yes | yes | manual | older, larger |
| TanStack Query | yes (per-call) | exponential default | manual | best-in-class for hooks |
| `react-native-tcp-socket` | n/a | n/a | n/a | low-level only |

| Backoff strategy | Best for |
|---|---|
| Exponential | low contention, simple |
| Equal jitter | medium contention |
| Full jitter | high contention (recommended default) |
| Decorrelated jitter | very high contention |

---

## Production Usage

- **Idempotent reads (GET)**: aggressive retry (5+ attempts) since safe.
- **Mutations (POST/PUT/DELETE)**: retry with idempotency key, fewer attempts (2-3).
- **Auth refresh**: dedicated path — refresh once on 401 then retry original.
- **Background sync**: longer backoff (minutes), respect battery/data.
- **Real-time (WebSocket)**: exponential reconnect with jitter; see Q2.

Scaling: standardize the wrapper across the app — don't let teams reinvent retry. Provide telemetry hooks (retry count, final outcome).

---

## Hands-On Exercise

1. **Implementation**: build `apiFetch` above; add metrics (retry count per request).
2. **Debugging**: a POST is being processed twice on the server; trace why (likely missing idempotency key or key regenerated per retry).
3. **Architecture**: design retry behavior for an app that runs in foreground + background (quotas differ).
4. **Optimization**: under network outage, the app fires hundreds of retries; add a "circuit breaker" that pauses retries entirely after N consecutive failures.

---

## Common Mistakes

- Retrying 4xx errors → wastes attempts, frustrates user.
- No idempotency key on POST → server-side duplicates.
- New idempotency key on each retry attempt → defeats the purpose.
- No jitter → thundering herd on recovery.
- No max attempts → battery drain, infinite loops.
- Ignoring `Retry-After` → rate-limit bans.
- Retrying while user has navigated away → wasted work, abandoned state.

---

## Production Red Flags

- **`while (true) { try fetch... }`** in code → no max attempts.
- **`Idempotency-Key: ${Date.now()}`** → not stable across retries.
- **No backoff between retries** → server abuse.
- **No telemetry on retry count** → can't tell if your network is healthy.

---

## Performance & Metrics (MANDATORY)

- **FPS**: nil impact (retries are async).
- **TTI**: P95 worsens with retries; tune max attempts vs latency.
- **Battery**: aggressive retries on weak networks drain battery; cap & backoff.
- **Data**: each retry costs bytes; respect cellular vs WiFi.
- **Bundle**: retry wrapper ~1KB.

---

## Metrics That Matter

- Retry count per request (distribution)
- Final success rate (after retries)
- Idempotency-key hit rate on server (duplicates avoided)
- P50 / P95 / P99 latency including retries
- Mean attempts per outcome

---

## Decision Framework

| Operation | Strategy |
|---|---|
| GET (read) | retry 3-5×, full jitter |
| POST/PUT/DELETE (write) | retry 2-3× with idempotency key |
| Auth refresh | retry once, then sign out |
| Telemetry / analytics | retry once, drop on failure |
| File upload (resumable) | retry indefinitely with longer backoff |
| Real-time WebSocket | reconnect with cap, see Q2 |

---

## Senior-Level Insight

The mature take: **retry is a contract between client, network, and server**. Each side has obligations. Client: classify correctly, jitter, cap. Network: best-effort delivery (TCP retransmits, QUIC connection migration). Server: idempotency keys, `Retry-After`, replay-safe logic. Senior engineers ensure all three layers cooperate; junior engineers tune client retries in isolation.

Org-level: ban raw `fetch` outside the wrapper; lint rule. Standardize idempotency-key generation. Coordinate with backend on dedup window TTL. For fintech / payments, audit every mutation path for idempotency.

---

## Real-World Scenario

**Symptom:** Customers report being charged twice for some orders during peak load.
**Investigation:** Backend logs show two `POST /charge` requests with identical bodies, ~3s apart, different `X-Request-ID` values.
**Root Cause:** Client retried after a 504 timeout; the first request had completed on the server but the response was lost. No idempotency key meant the second request was processed as new.
**Fix:** Generate idempotency key once per user intent (button press); reuse across retries; server-side dedup by key.
**Lesson:** Without idempotency keys, retry on writes is dangerous.

---

## Production Failure Story

**Incident:** A streaming service's mobile app DDoSed its own auth backend during a regional outage. Auth tier autoscaled but cost spiked 20× and latency stayed bad.
**Impact:** ~$80k unplanned cloud spend in 6 hours; bad press about app reliability.
**Investigation:** Every client retried token refresh aggressively, no jitter, exponential cap was 10s. When the auth service came back, all clients hit it within a 10s window.
**Root Cause:** Synchronous backoff (no jitter), low cap, no circuit breaker.
**Fix:** Full jitter, raised cap to 60s for auth, added client-side circuit breaker (pause for 5min after 10 consecutive failures).
**Prevention:** Retry policy review for all critical paths; load test with simulated outage + recovery.

---

## Debugging Checklist

1. Capture request/response with retry-count tag in observability tool.
2. Verify idempotency keys are stable across attempts.
3. Check server-side dedup is enabled and TTL is reasonable.
4. Audit retry classification — are we retrying 4xx by mistake?
5. Verify `Retry-After` honored.
6. Test with simulated network failures (Network Link Conditioner / Charles).

---

## Advanced / Internal Knowledge

- AWS Architecture Blog "Exponential Backoff and Jitter" is the canonical reference for jitter strategies.
- HTTP/2 multiplexes streams over one TCP connection — a retry reuses the connection, so cost is low (no TLS handshake).
- HTTP/3 / QUIC has 0-RTT for known origins — even faster retries.
- `Retry-After` accepts seconds OR HTTP-date format.
- Circuit breaker patterns (Hystrix-style): closed → open → half-open. Mobile rarely needs full circuit breaker but a "pause retries" timer is useful.

---

## 2026 AI Tip

- AI is **good at**: scaffolding retry wrappers, suggesting backoff formulas.
- AI is **bad at**: knowing your server's idempotency contract — verify with backend.
- **Hallucination risk**: AI sometimes generates retry on all errors including 4xx.
- **Prompt pattern**: "Build an `apiFetch` wrapper with full jitter backoff, idempotency keys for non-GET, AbortController support, and TanStack Query integration."

---

## Related Topics

- Q3 Cancellation
- S8 mutation queues
- S10 Auth refresh flows
- S18 observability

---

## Interview Follow-Up Questions

- Why is full jitter better than exponential alone?
- How does an idempotency key prevent double-charge?
- Which 4xx codes are retryable?
- How would you implement a circuit breaker on mobile?
- How does HTTP/3 change retry economics?

---

## Memory Hook

**"Classify, jitter, cap, key it."** Four words, one safe retry.

## Revision Notes

> Retry only retryable errors. Full jitter exponential backoff. Cap attempts. Idempotency key for writes. Honor `Retry-After`. Circuit-break on sustained failure.

---

---

### Q2. WebSocket lifecycle on mobile — foreground/background, reconnect, heartbeat

---

## Difficulty
- Advanced

## Interview Frequency
- Common (chat, presence, real-time pricing, ride-share)

## Prerequisites
- WebSocket basics, RN AppState, basic networking

## TL;DR
Mobile WebSockets must handle: backgrounding (OS suspends sockets), network changes (WiFi→cellular), reconnect with exponential backoff + jitter, heartbeat to detect dead connections, and resync of missed messages on reconnect (server-side cursor or sequence number).

---

## 30-Second Interview Answer

> "WebSockets on mobile aren't fire-and-forget. iOS suspends sockets ~30s after backgrounding; Android varies. You need a state machine — `connecting / open / closing / closed` — that handles `AppState` transitions, NetInfo network changes, server-initiated closes, and idle timeouts. Heartbeat (ping/pong every 20-30s) detects half-open connections. On reconnect, request a sync cursor from the server to replay missed messages. Backoff with jitter on reconnect to avoid herd. For push-style realtime in background, switch to APNs / FCM, not WebSocket."

---

## 2-Minute Practical Answer

State machine:

```
DISCONNECTED ── connect() ──► CONNECTING ── onopen ──► OPEN
     ▲                            │                      │
     │                            │ onerror               │ onclose
     │                            ▼                      ▼
     └────── backoff + retry ─── CLOSED ◄─── close() ───┘
```

Key behaviors:

1. **Heartbeat**: send ping every 20-30s; if no pong within timeout, treat as dead and reconnect. Detects "half-open" connections (TCP thinks it's alive but path is broken).
2. **AppState handling**: on background, the OS may suspend the socket. Strategy: keep open while in background (short window) and reconnect on foreground. For long backgrounds, close cleanly + rely on push notifications.
3. **Network changes**: NetInfo signals WiFi↔cellular transition. Existing socket may survive (with QUIC connection migration) or die. Handle either way.
4. **Reconnect backoff**: same as Q1 — exponential + full jitter, capped at ~30-60s.
5. **Sync on reconnect**: server tracks message cursor per client (Last-Event-ID style). On reconnect, client sends last-known cursor; server replays missed messages.
6. **Auth**: tokens expire; either reconnect with fresh token on 401-equivalent, or use a long-lived session.

Don't roll your own from scratch unless you must. Libraries: `socket.io-client`, `@stomp/stompjs`, native vendor SDKs (Pusher, Ably, Supabase Realtime). Each handles much of this.

---

## 5-Minute Architecture Answer

Mobile WebSockets are the messiest networking problem on the platform because three separate failure axes interact:

1. **Network layer**: TCP/TLS connection. Survives intermittent packet loss; dies on long disconnects, network type changes (sometimes), or NAT timeouts.
2. **Transport layer**: WebSocket protocol on top of HTTP. Must handle frames, ping/pong, close codes.
3. **OS lifecycle**: app foreground/background/terminated. iOS aggressively suspends; Android more lenient but Doze mode kicks in.

The state machine must be the **single source of truth** for connection state. Components subscribe (e.g., presence indicator); they don't manage the socket directly.

Reconnect strategy nuances:
- **First reconnect**: immediate (network blip).
- **Subsequent reconnects**: exponential + jitter.
- **Cap**: 30-60s; beyond that, give up and rely on user-initiated reconnect or push notification.
- **Backoff reset**: after sustained connection (e.g., 1 minute), reset attempt counter.
- **Don't reconnect when**: app is backgrounded (depends on use case), user has signed out, server returned a permanent close code (4001 etc.).

Heartbeat strategy:
- Server-driven (server pings, client pongs) preferred — saves battery.
- Or client-driven (every 20-30s).
- Some load balancers / proxies time out idle connections at 60s; heartbeat keeps alive.

Cross-cutting concerns:
- **Backpressure**: if server sends faster than client processes, queue grows. Drop old messages or throttle.
- **Ordering**: messages must be ordered per channel; server-assigned sequence numbers.
- **Idempotency**: replays on reconnect — client must dedupe by message ID.
- **Multiplexing**: one socket can carry multiple "channels" / "topics" (Phoenix Channels, STOMP, socket.io rooms).

The 2026 specific:
- **HTTP/3 + WebTransport** is becoming viable as a WebSocket alternative — better connection migration, multiple streams, datagrams. Still nascent on RN; libraries emerging.
- **Server-Sent Events (SSE)** is simpler and one-way — for read-only feeds, often a better choice than WebSocket.
- **Push notifications** (APNs/FCM) are still the right answer for background "wake" — WebSocket cannot replace them on iOS.

---

## The "Why"

Real-time UX (chat, live scores, presence, collab cursors) requires bidirectional persistent connections. Mobile makes them hard because the device is not a stable host. Apps that don't handle the messy edges (background, network change, partial failures) lose messages, show stale presence, drop user input. Companies care because real-time reliability is a brand signal — broken chat = lost users.

---

## Mental Model

A WebSocket on mobile is like a phone call on a moving train: it works most of the time, but tunnels (background), changing carriers (WiFi→LTE), and dropped signal (network blip) all interrupt it. You need a redial strategy and a way to catch up on what was said while you were disconnected.

---

## Internal Working (2026 Context)

- RN's `WebSocket` global wraps native: iOS uses `URLSessionWebSocketTask` (modern) or `SocketRocket` (legacy); Android uses `OkHttp`'s WebSocket.
- Native socket lives on a background thread; events flow to JS thread via JSI (Bridgeless) or bridge (legacy).
- AppState transitions on iOS: `active → inactive → background`. iOS gives ~30s in background before suspending sockets (without specific entitlements).
- Android Doze: after extended idle, network restricted; sockets may close.
- NetInfo events fire on connectivity changes; libraries like `socket.io-client` integrate.

---

## Modern Implementation (Code)

```ts
// realtime.ts — minimal resilient WebSocket manager
import { AppState } from 'react-native';
import NetInfo from '@react-native-community/netinfo';
import { v4 as uuid } from 'uuid';

type State = 'idle' | 'connecting' | 'open' | 'closing' | 'closed';

export class RealtimeClient {
  private ws: WebSocket | null = null;
  private state: State = 'idle';
  private attempt = 0;
  private heartbeat: ReturnType<typeof setInterval> | null = null;
  private lastCursor: string | null = null;
  private listeners = new Set<(msg: unknown) => void>();
  private url: string;

  constructor(url: string) {
    this.url = url;
    AppState.addEventListener('change', this.onAppState);
    NetInfo.addEventListener(this.onNetInfo);
  }

  connect() {
    if (this.state === 'open' || this.state === 'connecting') return;
    this.state = 'connecting';
    const url = this.lastCursor ? `${this.url}?cursor=${this.lastCursor}` : this.url;
    this.ws = new WebSocket(url);
    this.ws.onopen = () => {
      this.state = 'open';
      this.attempt = 0;
      this.startHeartbeat();
    };
    this.ws.onmessage = (e) => {
      try {
        const msg = JSON.parse(e.data);
        if (msg.type === 'pong') return;
        if (msg.cursor) this.lastCursor = msg.cursor;
        this.listeners.forEach((l) => l(msg));
      } catch {}
    };
    this.ws.onerror = () => { /* error event; close will follow */ };
    this.ws.onclose = (e) => {
      this.state = 'closed';
      this.stopHeartbeat();
      if (e.code !== 1000 && e.code < 4000) this.scheduleReconnect();
    };
  }

  private scheduleReconnect() {
    const cap = 30_000;
    const base = 500;
    const delay = Math.random() * Math.min(cap, base * 2 ** this.attempt);
    this.attempt += 1;
    setTimeout(() => this.connect(), delay);
  }

  private startHeartbeat() {
    this.heartbeat = setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: 'ping', id: uuid() }));
      }
    }, 25_000);
  }

  private stopHeartbeat() {
    if (this.heartbeat) clearInterval(this.heartbeat);
    this.heartbeat = null;
  }

  private onAppState = (next: string) => {
    if (next === 'active' && this.state !== 'open') this.connect();
    if (next === 'background') {
      // optional: close cleanly to save battery
      // this.ws?.close(1000);
    }
  };

  private onNetInfo = (info: { isConnected: boolean | null }) => {
    if (info.isConnected && this.state !== 'open') this.connect();
  };

  send(payload: unknown) {
    if (this.state === 'open') this.ws?.send(JSON.stringify(payload));
    // else: queue (omitted — see S8 Q5)
  }

  on(listener: (msg: unknown) => void) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  close() {
    this.state = 'closing';
    this.ws?.close(1000);
    this.stopHeartbeat();
  }
}
```

---

## Comparison

| Library | Best for |
|---|---|
| Raw `WebSocket` | full control, custom protocol |
| `socket.io-client` | rooms, fallbacks, batteries-included |
| `@stomp/stompjs` | STOMP / RabbitMQ / ActiveMQ |
| Phoenix Channels | Elixir/Phoenix backend |
| Pusher / Ably / PubNub | hosted realtime, presence built-in |
| Supabase Realtime | Postgres CDC streams |
| MQTT (`mqtt.js`) | IoT, low-bandwidth |
| SSE | one-way, simpler than WS |

| Transport | Pros | Cons |
|---|---|---|
| WebSocket | bidirectional, mature | needs lifecycle handling |
| SSE | simple, one-way, auto-reconnect | not bidirectional |
| WebTransport (HTTP/3) | streams + datagrams, modern | nascent on RN |
| Long polling | works behind proxies | inefficient |
| Push (APNs/FCM) | wakes app | server-controlled, latency |

---

## Production Usage

- **Chat**: WebSocket with rooms, message cursor for resync.
- **Presence**: WebSocket with last-seen pings.
- **Live scores**: SSE (one-way feed) often simpler than WebSocket.
- **Trading / pricing**: WebSocket with binary frames for throughput.
- **Collab cursors**: WebSocket + CRDT (Yjs).
- **Background "wake"**: APNs/FCM (WebSocket cannot reliably wake suspended apps).

---

## Hands-On Exercise

1. **Implementation**: build the `RealtimeClient` above; add message queue for offline send (see S8 Q5).
2. **Debugging**: socket reconnects every 60s — diagnose (likely a load-balancer idle timeout; add heartbeat or shorten interval).
3. **Architecture**: design real-time presence for an app with 100k concurrent connections.
4. **Optimization**: incoming message rate spikes; backpressure strategy (drop old, batch UI updates with `requestAnimationFrame`).

---

## Common Mistakes

- No heartbeat → silent dead connections (half-open).
- No reconnect backoff → thundering herd on outage recovery.
- Reconnecting in background indefinitely → battery drain.
- No cursor / sync on reconnect → missed messages.
- Components managing socket directly → multiple connections, leaks.
- Treating WebSocket as a substitute for push notifications → impossible in background on iOS.
- No close-code handling → reconnecting on intentional server close (e.g., auth revoked).

---

## Production Red Flags

- **`new WebSocket()` inside a component without cleanup** → leak on unmount.
- **Reconnect immediately on close** without backoff → server abuse.
- **No telemetry on disconnect rate / reason** → can't tune.
- **Different pages create separate sockets** → resource waste.

---

## Performance & Metrics (MANDATORY)

- **FPS**: high incoming message rate can jank if you re-render per message. Batch with `requestAnimationFrame` or `unstable_batchedUpdates`.
- **TTI**: first connect ~RTT + TLS handshake; reuses connection on subsequent.
- **Battery**: heartbeat every 25-30s is acceptable; aggressive heartbeat (5s) drains.
- **Data**: WebSocket frames are small; binary frames for high-throughput.
- **Memory**: per-connection ~tens of KB.

---

## Metrics That Matter

- Connection uptime per session
- Mean reconnect time
- Disconnect reason distribution (server close codes, network, idle)
- Heartbeat round-trip latency
- Message lag (server timestamp → client receive)

---

## Decision Framework

| Need | Pick |
|---|---|
| Bidirectional realtime | WebSocket |
| One-way feed | SSE |
| Background wake | Push (APNs/FCM) |
| IoT / low bandwidth | MQTT |
| Hosted, fast time-to-market | Pusher / Ably |
| Streams + datagrams (2026+) | WebTransport |
| Postgres change streams | Supabase Realtime |

---

## Senior-Level Insight

The mature take: **WebSocket is a transport, not a feature**. The product feature ("chat", "presence") needs a state model (last cursor, message store, dedup, ordering) that's independent of transport. Treat WebSocket as a pluggable layer — you should be able to swap to SSE or polling without rewriting the feature. Senior engineers design the realtime *feature* contract first, then choose transport.

Org-level: one realtime client per app (singleton); shared connection across features; centralized telemetry. Treat connection state as a Zustand store consumed by features.

---

## Real-World Scenario

**Symptom:** Chat shows "online" for users who closed the app 2 minutes ago.
**Investigation:** Client doesn't send ping; server only knows user is offline when TCP times out (~5min on this LB).
**Root Cause:** No client heartbeat; presence relies entirely on TCP keepalive.
**Fix:** Client sends ping every 25s; server marks offline after 60s of no ping.
**Lesson:** Presence accuracy requires application-layer heartbeats.

---

## Production Failure Story

**Incident:** A trading app's live price feed silently froze for ~10 minutes for ~3% of users during market open. They saw stale prices and made trades based on wrong data.
**Impact:** Trades had to be reversed; regulatory inquiry triggered.
**Investigation:** Sentry traces showed WebSocket reported "open" but no messages arrived. TCP connection survived a network handoff (WiFi→cellular) but the path was actually broken.
**Root Cause:** Half-open connection; no heartbeat to detect.
**Fix:** Aggressive heartbeat (10s during market hours), force-reconnect on missed pong, banner UI when last-message > 30s old.
**Prevention:** Stale-data detection in UI (timestamp every quote); chaos test simulating network handoffs.

---

## Debugging Checklist

1. Charles / mitmproxy: inspect WebSocket frames.
2. Server logs: connection lifecycle (connect, ping, close, reason code).
3. NetInfo / AppState: log every transition with timestamp.
4. Test on real device with airplane mode toggle.
5. Verify heartbeat actually sends and pong actually arrives.
6. Telemetry: disconnect reasons distribution.

---

## Advanced / Internal Knowledge

- WebSocket close codes: 1000 (normal), 1001 (going away), 1006 (abnormal — no close frame), 4xxx (application-defined).
- iOS `URLSessionWebSocketTask` (iOS 13+) replaces older `SocketRocket`; better integration with URL session config (caches, cookies, certs).
- HTTP/3 WebSocket bootstrap (RFC 9220) lets WebSocket run over QUIC — better connection migration.
- Permessage-deflate compression: trades CPU for bandwidth; usually on for chat.

---

## 2026 AI Tip

- AI is **good at**: scaffolding state machines, suggesting backoff.
- AI is **bad at**: knowing your server's close code semantics or LB idle timeouts.
- **Prompt pattern**: "Build a resilient WebSocket client with reconnect, heartbeat, AppState/NetInfo handling, and message-cursor resync."

---

## Related Topics

- Q1 retries
- S15 background tasks
- S12 push notifications
- S22 real-time system design

---

## Interview Follow-Up Questions

- How does heartbeat detect a half-open connection?
- What happens to a WebSocket when the app backgrounds on iOS?
- How would you sync missed messages on reconnect?
- When would you choose SSE over WebSocket?
- How does HTTP/3 change WebSocket reliability?

---

## Memory Hook

**"State machine, heartbeat, jitter-reconnect, cursor-resync."** Four checks, one solid socket.

## Revision Notes

> WebSocket needs a state machine. Heartbeat detects dead links. Reconnect with jitter. Resync via cursor. Push for background wake. Don't reinvent — use a library when possible.

---

---

### Q3. Request cancellation patterns — AbortController + TanStack Query

---

## Difficulty
- Intermediate → Advanced

## Interview Frequency
- Common (asked when discussing perf or correctness)

## Prerequisites
- async/await, Promises, basic React lifecycle

## TL;DR
Pass the `AbortSignal` from TanStack Query into `fetch` so navigating away or changing the query key cancels the in-flight request — saves bandwidth, battery, and avoids race conditions where stale responses overwrite fresh state.

---

## 30-Second Interview Answer

> "Request cancellation matters for two reasons: avoiding wasted work (user navigates away mid-fetch) and avoiding race conditions (search-as-you-type where the slow first response lands after the fast second). Use `AbortController.signal` passed to `fetch`; TanStack Query's `queryFn` receives a `signal` automatically and cancels on unmount or key change. The mistake is forgetting to pass the signal — `fetch` ignores cancellation otherwise. For non-fetch async work (sleeps, polling), wire `signal.addEventListener('abort')` manually."

---

## 2-Minute Practical Answer

The race condition that motivates cancellation:

```
t=0    user types "a" → fetch /search?q=a  (slow, takes 2s)
t=200  user types "ab" → fetch /search?q=ab (fast, takes 100ms)
t=300  /ab response arrives → setState(ab results) ✅
t=2000 /a response arrives → setState(a results) ❌ stale!
```

Without cancellation, the slow stale response overwrites the fresh one. Solutions:

1. **AbortController**: cancel the first fetch when the second starts.
2. **Request ID check**: assign each request an ID; ignore responses whose ID isn't current.
3. **TanStack Query**: changing query key cancels prior; `signal` is provided to `queryFn` automatically.

`AbortController` semantics:
- `controller.abort()` triggers `signal.aborted = true` and fires `abort` event.
- `fetch(url, { signal })` rejects with `AbortError` if signal aborts mid-request.
- Pass signal to all async work (sleep, recursive fetches, third-party SDKs that accept it).

In TanStack Query:
```ts
useQuery({
  queryKey: ['search', q],
  queryFn: ({ signal }) => fetch(`/search?q=${q}`, { signal }).then(r => r.json()),
});
```
On `q` change, prior query is cancelled.

---

## 5-Minute Architecture Answer

Cancellation is correctness *and* performance:

- **Correctness**: prevent stale state. Without cancellation, race conditions corrupt UI.
- **Performance**: don't waste bytes/CPU on responses you won't use. Especially on cellular.

Where cancellation matters most:
- **Search-as-you-type**: every keystroke fires a query.
- **Tab/route changes**: navigating away mid-fetch.
- **Mutation cleanup**: user dismisses optimistic action before server responds.
- **Background sync**: app backgrounds; cancel pending non-critical requests.

`AbortController` propagation:
- Most modern fetch-based libraries (`ky`, `axios v1+`, `apollo`, `urql`) accept signals.
- Native fetch in RN respects `signal`.
- WebSocket close is the equivalent for sockets.
- Long-running async ops (e.g., file I/O) must wire signal manually.

Subtle issues:
- **AbortError vs other errors**: catch and ignore `AbortError` in error handlers (it's expected, not a real failure).
- **Backend cleanup**: when client cancels, server-side work may continue (HTTP/1.1 typically does; HTTP/2 sends RST_STREAM). For long server-side ops, design endpoints to honor client disconnect.
- **Cleanup in React**: cancel in `useEffect` cleanup or via TanStack Query's auto-cancellation on unmount.

The 2026 specific: **React Server Functions / Actions** also accept signals; cancellation flows end-to-end. With Suspense + transitions, stale renders are aborted by React's concurrent renderer too.

---

## The "Why"

Mobile users navigate fast: tab switches, back button, search-as-you-type. Without cancellation, every navigation triggers wasted work — wasted bytes (cellular cost, battery), wasted CPU (parsing JSON of unused responses), and worst of all wasted *correctness* (stale responses overwriting fresh state). Companies care because cancellation bugs manifest as confusing UI ("why is my old search still showing?") that's hard to debug.

---

## Mental Model

`AbortSignal` is a "kill switch" you hand to every async operation. Pulling it terminates them all immediately. React/TanStack Query pull the kill switch automatically when components unmount or query keys change.

---

## Internal Working (2026 Context)

- `AbortController` is a standard Web API; RN's Hermes provides it.
- `fetch(url, { signal })` checks signal at multiple stages: before send, during waiting, during body read. Aborts at any stage reject the promise with `AbortError`.
- TanStack Query creates an `AbortController` per query attempt; signal passed to `queryFn`. On unmount / key change / refetch, prior controller is aborted.
- Native layer: iOS `URLSession.cancel()`, Android `OkHttp Call.cancel()`. RN's `fetch` wires through.

Threading: cancellation flows through JS thread; native layer handles actual TCP RST.

---

## Modern Implementation (Code)

```ts
// useSearch.ts — search-as-you-type with cancellation
import { useQuery } from '@tanstack/react-query';
import { useDebounce } from '@/hooks/useDebounce';

export function useSearch(query: string) {
  const debounced = useDebounce(query, 250);
  return useQuery({
    queryKey: ['search', debounced],
    queryFn: async ({ signal }) => {
      const res = await fetch(`/api/search?q=${encodeURIComponent(debounced)}`, { signal });
      if (!res.ok) throw new Error(String(res.status));
      return res.json();
    },
    enabled: debounced.length >= 2,
  });
}
```

```ts
// manual cancellation in a non-Query effect
import { useEffect, useState } from 'react';

function MyScreen({ id }: { id: string }) {
  const [data, setData] = useState<unknown>(null);

  useEffect(() => {
    const ctrl = new AbortController();
    fetch(`/api/item/${id}`, { signal: ctrl.signal })
      .then(r => r.json())
      .then(setData)
      .catch(err => {
        if (err.name !== 'AbortError') throw err;
      });
    return () => ctrl.abort();
  }, [id]);
  // ...
}
```

```ts
// composing signals (cancel if either source cancels)
function combineSignals(...signals: AbortSignal[]): AbortSignal {
  const ctrl = new AbortController();
  for (const s of signals) {
    if (s.aborted) { ctrl.abort(); break; }
    s.addEventListener('abort', () => ctrl.abort(), { once: true });
  }
  return ctrl.signal;
}

// usage
const combined = combineSignals(querySignal, userTimeoutSignal);
fetch(url, { signal: combined });
```

Note: modern environments have `AbortSignal.any([s1, s2])` — prefer where supported.

---

## Comparison

| Approach | Pros | Cons |
|---|---|---|
| AbortController + signal | standard, composable | requires plumbing |
| Request ID + ignore stale | works without lib support | wastes bandwidth |
| Boolean "isCurrent" ref | simple | manual, brittle |
| TanStack Query (auto) | zero config | only for queries |

---

## Production Usage

- **Search-as-you-type**: critical.
- **Tab navigation with prefetched data**: cancel on tab leave if not yet rendered.
- **Modal dismiss mid-load**: cancel.
- **Map pan / pinch**: cancel previous tile fetches.
- **Image search infinite scroll**: cancel out-of-viewport batches.

---

## Hands-On Exercise

1. **Implementation**: build a search input with TanStack Query + debounce + abort; verify in network panel that prior requests are cancelled.
2. **Debugging**: stale results flash briefly on fast typing — confirm signal passed to fetch.
3. **Architecture**: design cancellation across a multi-step flow (user starts checkout, navigates back; cancel inventory/price/tax fetches).
4. **Optimization**: cancel-and-restart loops on every keystroke spike CPU; combine debounce + cancel.

---

## Common Mistakes

- Not passing `signal` to `fetch` → cancellation is no-op.
- Re-throwing `AbortError` instead of swallowing → noisy logs.
- Aborting in `useEffect` without dependency control → cancels too aggressively.
- Forgetting that some libraries (older axios, etc.) don't accept `AbortSignal`.
- Aborting after success → harmless but log noise.

---

## Production Red Flags

- **No `signal` in fetch wrappers** → no cancellation possible.
- **Custom "is mounted" booleans** → reinventing abort badly.
- **AbortError treated as failure** → polluted error metrics.

---

## Performance & Metrics (MANDATORY)

- **FPS**: nil direct; indirect by avoiding wasted renders from stale responses.
- **TTI**: nil; can improve perceived TTI by not blocking on stale fetches.
- **Battery / data**: real savings on chatty apps.
- **CPU**: avoid parsing canceled JSON responses.

---

## Metrics That Matter

- Cancellation rate per query (high = aggressive nav patterns)
- Stale-response error count (should approach 0 with proper abort)
- Bytes saved by cancellation (RUM)

---

## Decision Framework

| Situation | Cancel? |
|---|---|
| Search-as-you-type | Yes (always) |
| Component unmount mid-fetch | Yes (TanStack auto) |
| Tab change | Yes for non-essential prefetch |
| Critical mutation | No (let it complete) |
| Background sync on backgrounded app | Yes |

---

## Senior-Level Insight

Cancellation is **a contract**, not a feature. The code must agree end-to-end: caller passes signal, fetch respects it, callbacks handle abort. Breaks at any layer defeat the chain. Senior engineers audit the wrapper layer to ensure signals propagate; junior engineers add cancellation in one place and assume it works everywhere.

Server-side: HTTP/2 + HTTP/3 propagate cancel as RST_STREAM, freeing server resources. For long-running endpoints (reports, large queries), design to honor client disconnect (Node: `req.on('close')`; Go: `ctx.Done()`).

---

## Real-World Scenario

**Symptom:** Search-as-you-type sometimes shows results from a previous query.
**Investigation:** Code uses a custom fetch wrapper that doesn't accept `signal`.
**Root Cause:** Wrapper was built before cancellation requirements; AbortSignal ignored.
**Fix:** Update wrapper to accept and forward signal; add lint rule preventing raw fetch.
**Lesson:** Wrappers must propagate signals or cancellation is a mirage.

---

## Production Failure Story

**Incident:** A maps app saturated user data plans on launch — preloading 200+ tiles, then cancelling 180 when the user panned away. Native cancellation worked, but the client kept downloading until the abort propagated through all layers.
**Impact:** Customer complaints about excessive data usage; ASO ratings dropped.
**Investigation:** Network panel showed full response bodies arriving for "cancelled" requests.
**Root Cause:** Custom HTTP layer didn't pass `AbortSignal` to native fetch — only marked requests as "ignored" in JS.
**Fix:** Plumb signal end-to-end so native cancels mid-stream.
**Prevention:** Integration test asserting cancelled requests close at the TCP level.

---

## Debugging Checklist

1. Network panel: cancelled requests should show as "cancelled" with truncated body.
2. Verify `signal` passed at every layer.
3. Catch `AbortError` separately from real errors.
4. TanStack Query Devtools: see query state on key change.
5. Test on slow network (Network Link Conditioner) to make races easy to repro.

---

## Advanced / Internal Knowledge

- `AbortSignal.timeout(ms)` — built-in timeout signal (modern envs).
- `AbortSignal.any([s1, s2])` — combine signals (modern envs).
- HTTP/2 RST_STREAM frame for cancellation; HTTP/1.1 closes the connection (less efficient).
- React 19 `use()` + Suspense with transitions: stale renders are auto-aborted.

---

## 2026 AI Tip

- AI is **good at**: adding signal propagation through fetch wrappers.
- AI is **bad at**: knowing which third-party SDKs honor signals — verify.
- **Prompt pattern**: "Audit this fetch wrapper for AbortSignal propagation and add cancellation support."

---

## Related Topics

- Q1 retries
- S2 React 19 Suspense + transitions
- S8 TanStack Query

---

## Interview Follow-Up Questions

- Why is `AbortError` typically swallowed?
- How does TanStack Query auto-cancel?
- How would you compose multiple abort signals?
- What happens server-side when a client cancels?
- How does HTTP/2 cancellation differ from HTTP/1.1?

---

## Memory Hook

**"Pass the signal end-to-end, swallow the AbortError."**

## Revision Notes

> AbortController + signal everywhere. TanStack Query auto-cancels. Search-as-you-type is the canonical use case. Swallow AbortError. Propagate through wrappers and SDKs.

---

---

### Q4. HTTP/3 and QUIC on mobile — why it matters

---

## Difficulty
- Advanced

## Interview Frequency
- Niche but increasing (asked at top-tier perf-focused roles)

## Prerequisites
- HTTP/1.1 vs HTTP/2 basics, TCP/UDP basics

## TL;DR
HTTP/3 runs over QUIC (UDP-based), eliminating TCP head-of-line blocking, shrinking handshake to 1-RTT (or 0-RTT for known origins), and surviving network changes (WiFi→cellular) without dropping the connection. Big wins for mobile.

---

## 30-Second Interview Answer

> "HTTP/3 = HTTP over QUIC over UDP. The mobile-specific wins are: connection migration (network change doesn't break the connection), 1-RTT or 0-RTT handshake (faster cold requests), and per-stream loss recovery (one packet loss doesn't stall all streams like TCP head-of-line blocking does in HTTP/2). On flaky networks, HTTP/3 can cut tail latency by 20-40%. RN's native HTTP stack supports it (URLSession on iOS 15+, Cronet on Android via OkHttp + plugin). Worth enabling for any user-facing API; verify with `Alt-Svc` header and curl-impersonate testing."

---

## 2-Minute Practical Answer

What HTTP/3 / QUIC fix:

1. **TCP head-of-line blocking**: HTTP/2 multiplexes streams over one TCP connection; one lost packet stalls all streams. QUIC streams are independent — loss in stream A doesn't affect stream B.
2. **Slow handshakes**: TCP + TLS 1.2 = 3 RTTs. QUIC = 1 RTT (TLS 1.3 baked in). 0-RTT for resumed connections.
3. **Connection migration**: WiFi→cellular changes IP, which kills TCP connections (HTTP/1.1, HTTP/2). QUIC uses Connection IDs, survives IP changes.
4. **Better congestion control**: pluggable, evolving (BBR, CUBIC).

Mobile-specific gains:
- Subway / elevator / spotty networks: less retransmit cost.
- Network handoffs: no reconnect overhead.
- TLS handshake on cold start: shaved 100-200ms.

Enabling on RN:
- **iOS**: `URLSession` uses HTTP/3 automatically when server advertises via `Alt-Svc` header.
- **Android**: stock `OkHttp` doesn't speak QUIC; use Cronet (`okhttp-cronet` adapter, or `react-native-cronet`).
- **Verification**: curl with `--http3` flag, or browser devtools showing protocol = `h3`.

Not silver bullet:
- UDP is sometimes blocked by corporate firewalls / hotel WiFi → fallback to HTTP/2 over TCP.
- Server must support; CDN configuration matters (Cloudflare, Fastly, Akamai all support).
- Slightly more CPU for encryption (TLS over UDP).

---

## 5-Minute Architecture Answer

Three eras of HTTP performance:

1. **HTTP/1.1**: one request per connection (or pipelined poorly). Solved by opening 6 connections per origin. Each pays TCP+TLS handshake cost (~3 RTTs).
2. **HTTP/2**: multiplexed streams over one TCP connection. Solves connection count, but introduces head-of-line blocking at TCP layer (one lost packet stalls all streams).
3. **HTTP/3 / QUIC**: independent streams over UDP. No HoL blocking. Faster handshake. Connection migration.

Mobile angle:
- **Cold start**: every cold request pays handshake. HTTP/3's 1-RTT (or 0-RTT) is a big TTI win.
- **Lossy networks**: HTTP/3 outperforms HTTP/2 on links with >1% packet loss — common on cellular fringes.
- **Network handoffs**: switching WiFi↔cellular is invisible to QUIC; HTTP/2 must reconnect (and re-handshake).
- **Push notifications**: APNs and FCM use HTTP/2, not yet HTTP/3 universally.

Adoption status (2026):
- **iOS 15+** (and iOS 17+ default): URLSession speaks HTTP/3 transparently.
- **Android Chrome WebView, Cronet**: HTTP/3 mature.
- **OkHttp (default Android RN networking)**: no native HTTP/3 yet (in 2026); requires Cronet adapter.
- **CDNs**: Cloudflare, Fastly, Akamai, AWS CloudFront — all production HTTP/3.
- **Origins / APIs**: variable; many use CDN edge with HTTP/3, origin still HTTP/2.

Operational concerns:
- **Observability**: distinguish HTTP/3 vs HTTP/2 in logs (per-request protocol tag).
- **Fallback**: client should retry over HTTP/2 if HTTP/3 fails (some networks block UDP/443).
- **Privacy**: QUIC encrypts more metadata (SNI in early data); harder for ISPs to inspect — generally good for privacy.

The 2026 specific:
- **WebTransport** (HTTP/3-based bidi streams + datagrams) is the long-term WebSocket successor.
- **MASQUE** (Multiplexed Application Substrate over QUIC Encryption) for proxy/VPN over QUIC.
- **iOS 17+** Privacy Manifests and ATT have no direct relation but app reviewers occasionally ask about transport security; HTTP/3 + TLS 1.3 is a clean answer.

---

## The "Why"

Mobile networks are the worst environment for HTTP. High latency, packet loss, frequent handoffs, NAT timeouts. HTTP/2 was a step forward but TCP's HoL blocking hurts most on lossy links — exactly mobile's worst case. HTTP/3 was designed for this. Companies that ship HTTP/3 see measurable improvements in P95 / P99 latency for international and rural users — exactly the segments hardest to retain.

---

## Mental Model

HTTP/2 over TCP = a single-lane road where one stalled car blocks all behind it.
HTTP/3 over QUIC = a multi-lane highway where each lane is independent.
Plus: the highway follows your car when you change cities (connection migration).

---

## Internal Working (2026 Context)

- QUIC = transport protocol on UDP/443. Encryption built-in (TLS 1.3 in the protocol, not a layer above).
- Streams = independent unidirectional or bidirectional byte streams within one connection.
- Connection ID = identifier surviving IP changes; client/server use it to route packets.
- 0-RTT = client resumes prior connection with cached params; sends data in first packet (replay attack risk for non-idempotent ops).
- Loss detection: per-stream, faster than TCP RTO.

Native stacks:
- **iOS** `URLSession` enables HTTP/3 automatically when server advertises via `Alt-Svc` HTTP/2 response header.
- **Android** OkHttp lacks native QUIC; **Cronet** (Chrome's networking stack) is the recommended HTTP/3 client. RN integration via plugins.
- **Hermes / RN fetch** wraps native; HTTP/3 enabled iff native stack supports.

---

## Modern Implementation (Code)

```ts
// no JS API change — HTTP/3 is transparent to fetch.
// Verify protocol used by inspecting response headers in observability:
const res = await fetch('https://api.example.com/orders');
// On iOS 15+, URLSession may have used HTTP/3 if server advertised Alt-Svc.
// Check via server-side logs (preferred) or:
console.log(res.headers.get('Alt-Svc')); // hint about server support
```

```kotlin
// Android — enabling Cronet via custom RN networking
// In your native module / OkHttp client builder:
import org.chromium.net.CronetEngine
import com.google.net.cronet.okhttptransport.CronetCallFactory

val engine = CronetEngine.Builder(context)
  .enableQuic(true)
  .addQuicHint("api.example.com", 443, 443)
  .build()

val client = OkHttpClient.Builder()
  .callFactory(CronetCallFactory.newBuilder(engine).build())
  .build()
```

```bash
# verify HTTP/3 from server side
curl -I --http3 https://api.example.com/health
# look for: HTTP/3 200
# look for response header: alt-svc: h3=":443"; ma=86400
```

---

## Comparison

| Feature | HTTP/1.1 | HTTP/2 | HTTP/3 |
|---|---|---|---|
| Transport | TCP | TCP | QUIC over UDP |
| Multiplexing | no (or pipelining, broken) | yes | yes |
| Head-of-line blocking | per-connection | per-TCP-connection | per-stream only |
| Handshake | 3 RTT (TCP+TLS) | 2-3 RTT | 1 RTT, 0 RTT resumed |
| Connection migration | no | no | yes |
| Lossy network perf | poor | poor | excellent |
| iOS support | always | iOS 9+ | iOS 15+ |
| Android default | always | yes | needs Cronet |

| Network condition | HTTP/2 P95 | HTTP/3 P95 | Improvement |
|---|---|---|---|
| WiFi, low loss | similar | similar | ~0% |
| Cellular, 1% loss | baseline | -15-25% | meaningful |
| Cellular, 3% loss | baseline | -30-40% | significant |
| Network handoff | reconnect cost | seamless | qualitative |

---

## Production Usage

- **Global apps** (Instagram, TikTok, Netflix) use HTTP/3 for measurable tail-latency wins.
- **Chat apps** benefit from connection migration during walking/driving.
- **Streaming apps** love QUIC's per-stream loss recovery.
- **APIs behind CDN edge** get HTTP/3 essentially free.
- **B2B / enterprise** sometimes blocked by firewalls on UDP — verify before assuming wins.

---

## Hands-On Exercise

1. **Implementation**: configure Cronet on Android RN; verify HTTP/3 used.
2. **Debugging**: HTTP/3 not used despite server support — check `Alt-Svc` header, iOS version, network conditions.
3. **Architecture**: design fallback strategy for networks blocking UDP/443.
4. **Measurement**: A/B test HTTP/3 vs HTTP/2 in production; measure P95 latency by network type.

---

## Common Mistakes

- Assuming HTTP/3 is faster always — equivalent on perfect WiFi, big wins on bad networks.
- Forgetting Android needs Cronet — defaults to OkHttp + HTTP/2.
- Not setting `Alt-Svc` correctly on origin — clients won't upgrade.
- 0-RTT for non-idempotent requests — replay risk.
- No fallback when UDP blocked — connections fail.

---

## Production Red Flags

- **No protocol tagging** in observability → can't measure improvement.
- **Origin doesn't support HTTP/3** → CDN-only wins (still good but partial).
- **Custom HTTP client bypassing native** → loses HTTP/3.

---

## Performance & Metrics (MANDATORY)

- **TTI / TTFB**: significant wins on cold start + lossy links.
- **CPU**: slight increase for encryption (TLS in protocol).
- **Battery**: small increase from CPU; offset by fewer retransmits.
- **Data**: minor framing overhead; usually offset by header compression (QPACK).

---

## Metrics That Matter

- % requests over HTTP/3 (per platform, per region)
- P95 / P99 latency by protocol
- Connection success rate (UDP blocked = fall back)
- TLS handshake count (should drop with 0-RTT resumption)

---

## Decision Framework

| Situation | Use HTTP/3? |
|---|---|
| New API behind modern CDN | Yes |
| Origin supports it | Yes |
| Enterprise users on locked-down corporate networks | Test fallback |
| Realtime over WebSocket | Consider WebTransport |
| Internal services (server-to-server) | HTTP/2 is fine |

---

## Senior-Level Insight

The mature take: HTTP/3 is a **tail-latency** play. Mean latency improvements are modest; P95/P99 improvements on bad networks are big. The right way to evaluate is per-percentile, per-network-type, per-region — not "average ms saved". Senior engineers run regional A/B tests and report tail-latency deltas, not global means.

Org-level: align with backend / CDN team to enable HTTP/3 at edge. For RN-specific, push for Cronet adoption on Android. Add protocol tagging to observability.

---

## Real-World Scenario

**Symptom:** P99 latency on Android in India is 3-5× higher than on iOS in same region.
**Investigation:** Logs show iOS uses HTTP/3 (URLSession default); Android uses HTTP/2 (OkHttp default). Indian cellular networks have higher packet loss → HTTP/2 HoL blocking dominates.
**Root Cause:** Android client lacks HTTP/3 support.
**Fix:** Adopt Cronet for Android networking; protocol parity restored.
**Lesson:** Platform-specific networking stack quality affects regional UX dramatically.

---

## Production Failure Story

**Incident:** A streaming app rolled out HTTP/3 globally; ~2% of users (corporate WiFi) saw all requests fail.
**Impact:** App appeared completely broken for those users.
**Investigation:** Networks blocked UDP/443; client had no fallback path.
**Root Cause:** Eager HTTP/3 with no graceful degradation.
**Fix:** Race HTTP/3 vs HTTP/2 (happy eyeballs style); fall back to HTTP/2 quickly if HTTP/3 fails.
**Prevention:** Test in restrictive network environments before global rollout.

---

## Debugging Checklist

1. Server: verify `Alt-Svc: h3=":443"` header set.
2. iOS: minimum iOS 15+; URLSession should auto-upgrade.
3. Android: Cronet integrated and `enableQuic(true)`.
4. Test from `curl --http3` to confirm server.
5. Wireshark / tcpdump: observe UDP/443 traffic.
6. Server logs: protocol per request.

---

## Advanced / Internal Knowledge

- QUIC is RFC 9000; HTTP/3 is RFC 9114; QPACK header compression is RFC 9204.
- Connection IDs are negotiated; server can rotate to prevent linkability across networks.
- 0-RTT data is replayed on retry — only safe for idempotent GET; risky for POST.
- "Happy eyeballs" for HTTP/3: race v3 vs v2 connection establishment, use winner.
- WebTransport (W3C) standardizes browser/client API on top of HTTP/3 for streams + datagrams.

---

## 2026 AI Tip

- AI is **good at**: explaining protocol concepts, generating Cronet integration boilerplate.
- AI is **bad at**: knowing your CDN's exact HTTP/3 config — verify with provider docs.
- **Prompt pattern**: "Generate Cronet HTTP/3 integration for an RN Android app with fallback to OkHttp on QUIC failure."

---

## Related Topics

- Q1 retries (HTTP/3 fast handshakes change retry economics)
- S10 TLS / pinning
- S20 CDN / edge

---

## Interview Follow-Up Questions

- Why doesn't HTTP/2 solve head-of-line blocking entirely?
- How does QUIC connection migration work?
- What's the risk of 0-RTT?
- How do you fall back when UDP is blocked?
- How would you measure HTTP/3 wins in production?

---

## Memory Hook

**"UDP, 1-RTT, per-stream, migrate."** Four properties, mobile networking won.

## Revision Notes

> HTTP/3 = HTTP over QUIC over UDP. Wins: no HoL, fast handshake, connection migration. iOS 15+ auto; Android needs Cronet. Tail-latency play; measure by percentile and network type.

---

---

### Q5. Certificate pinning — static, dynamic, and rotation

---

## Difficulty
- Advanced

## Interview Frequency
- Common (asked for fintech, healthcare, security-focused roles)

## Prerequisites
- TLS basics, X.509 certificate basics

## TL;DR
Certificate pinning binds your app to specific server certs/keys, blocking MITM via rogue CAs. Pin to **public-key hashes** (SPKI), not to leaf certs; **always include backup pins**; have a **rotation strategy** (server-side via OTA config or app updates) — pinning without rotation is a foot-gun.

---

## 30-Second Interview Answer

> "Pin SPKI hashes (public-key fingerprints), not leaf certs — leaf rotates often. Pin at least two keys (current + backup) so cert rotation doesn't brick the app. Implement via native APIs: iOS App Transport Security pins or `URLSessionDelegate`; Android `NetworkSecurityConfig`. For RN, libraries like `react-native-ssl-pinning` wrap both. Critical: have a rotation runbook — update the app or fetch pins via OTA before the pinned cert expires. The risk of pinning is bricking the app; mitigate with backup pins and a kill-switch."

---

## 2-Minute Practical Answer

What pinning prevents: a malicious CA (compromised, coerced, or rogue) issuing a cert for your domain. Without pinning, the OS trusts any CA; pinning narrows trust to specific keys/certs you've embedded.

What to pin:
- **SPKI hash** (Subject Public Key Info SHA-256) — preferred. Survives leaf cert rotation as long as the key stays the same.
- **Leaf cert hash** — works but breaks on every cert renewal (typically 90 days for Let's Encrypt).
- **Intermediate CA hash** — pins a smaller trust set than full PKI but larger than leaf-only.

Always pin **multiple** keys: current + backup (a key you have in reserve). Without backup, losing the pinned key = bricked app for everyone until forced update.

Rotation strategies:
1. **App update**: ship new pins in the next release. Slow (review + adoption time).
2. **OTA pin update**: fetch pin list from a signed endpoint at startup. Fast but adds attack surface (need to authenticate the pin source).
3. **Pin TTL**: pins expire after N days; gradual fallback to system trust.

Frameworks:
- iOS: `URLSession` with `URLSessionDelegate.didReceiveChallenge`; or `Network.framework` `NWConnection`.
- Android: `NetworkSecurityConfig` XML (pre-built support).
- RN libs: `react-native-ssl-pinning`, `react-native-cert-pinner`, `react-native-pinch`.

---

## 5-Minute Architecture Answer

Pinning is a **trust narrowing** technique. Standard TLS trusts the OS root store (~150 CAs). Any of them could issue a cert for your domain (with the right authorization). Pinning says: "even if the OS trusts a cert chain, I additionally require it match my pin."

Threat model:
- **Mitigated**: rogue CA, compromised CA, government-coerced CA, MITM via custom root cert installed on device.
- **NOT mitigated**: compromised server (attacker has your real key), zero-day in TLS, malware on device with root.

Failure modes:
- **Bricking**: pinned cert expires or gets rotated unexpectedly → app refuses to connect to your own backend.
- **Pin set too narrow**: only one key pinned, lost in incident → bricked.
- **Pin set too broad**: pinning all root CAs = no protection.
- **Pinning irrelevant hosts**: don't pin third-party APIs you don't control.

Operational requirements:
1. **Pin inventory**: documented list of pinned hosts + keys + expiration.
2. **Backup pins**: ≥2 keys per host, ideally one offline.
3. **Rotation runbook**: how to update pins safely.
4. **Monitoring**: count of pin-failure events; spike means rotation issue.
5. **Kill switch**: server-controlled flag to disable pinning in emergency (controversial — also weakens the protection).

The 2026 specific:
- **iOS Privacy Manifests** require declaring tracking domains; pinning is orthogonal but related security posture.
- **Network Security Config** (Android) supports pin-set with expiration since Android 7.
- **Certificate Transparency** (CT) is now required by Apple — adds another layer of trust verification, but doesn't replace pinning.
- **Public Key Pinning HTTP header (HPKP)** has been **deprecated** in browsers — but mobile app-level pinning is still recommended for high-risk apps.

When NOT to pin:
- General consumer apps with low security risk → adds operational burden without much gain.
- Apps using third-party APIs you don't control.
- MVPs / fast iteration.

When to pin:
- Fintech, banking, healthcare, government.
- Any app handling auth tokens for sensitive systems.
- Apps in countries with state-level MITM concerns.

---

## The "Why"

TLS trusts CAs implicitly. Bad CAs have shipped before (DigiNotar 2011, Symantec 2017, more). State actors can coerce CAs in their jurisdiction. Without pinning, an attacker with a malicious cert + network access (rogue WiFi, compromised ISP) can MITM your traffic and your app won't notice. For high-value apps (banking, healthcare), this is unacceptable. Pinning is the standard mitigation.

---

## Mental Model

System TLS trust is "anyone on a guest list can enter". Pinning is "anyone on the guest list AND with a specific signed photo we recognize". Even a fake guest with a real-looking pass can't get in.

---

## Internal Working (2026 Context)

- Standard TLS handshake: server presents cert chain → client verifies signatures back to a trusted root in OS store → connection proceeds.
- Pinning adds a step: after standard verification, compare cert/key in chain against pin list; reject if no match.
- iOS `URLSession`: implement `urlSession(_:didReceive:completionHandler:)`; extract `SecTrust`, validate, compute SPKI hash, compare.
- Android `NetworkSecurityConfig`: declare pins in XML; OkHttp/HttpsURLConnection enforce automatically.
- RN libraries wrap these; pinning happens at native layer (correct — JS can't be trusted with TLS validation).

---

## Modern Implementation (Code)

**Android `NetworkSecurityConfig`** (`res/xml/network_security_config.xml`):

```xml
<network-security-config>
  <domain-config>
    <domain includeSubdomains="true">api.example.com</domain>
    <pin-set expiration="2027-01-01">
      <pin digest="SHA-256">YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=</pin>
      <pin digest="SHA-256">backupPinHashHere==</pin>
    </pin-set>
  </domain-config>
</network-security-config>
```

Reference in `AndroidManifest.xml`:
```xml
<application android:networkSecurityConfig="@xml/network_security_config" ...>
```

**iOS** — Info.plist for ATS settings, custom `URLSessionDelegate` for pinning logic:

```swift
class PinningDelegate: NSObject, URLSessionDelegate {
  let pinnedSpkiHashes: Set<Data> = [...]

  func urlSession(_ session: URLSession,
                  didReceive challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
          let serverTrust = challenge.protectionSpace.serverTrust else {
      completionHandler(.cancelAuthenticationChallenge, nil); return
    }
    // standard trust eval
    var error: CFError?
    guard SecTrustEvaluateWithError(serverTrust, &error) else {
      completionHandler(.cancelAuthenticationChallenge, nil); return
    }
    // SPKI pin check
    for i in 0..<SecTrustGetCertificateCount(serverTrust) {
      guard let cert = SecTrustGetCertificateAtIndex(serverTrust, i) else { continue }
      let spki = computeSpkiHash(cert) // SHA-256 of SubjectPublicKeyInfo
      if pinnedSpkiHashes.contains(spki) {
        completionHandler(.useCredential, URLCredential(trust: serverTrust)); return
      }
    }
    completionHandler(.cancelAuthenticationChallenge, nil)
  }
}
```

**RN with `react-native-ssl-pinning`**:

```ts
import { fetch } from 'react-native-ssl-pinning';

const res = await fetch('https://api.example.com/orders', {
  method: 'GET',
  sslPinning: {
    certs: ['cert1', 'cert2'], // bundled cert files in app
  },
  timeoutInterval: 10000,
});
```

---

## Comparison

| Pin type | Pros | Cons |
|---|---|---|
| Leaf cert | precise | breaks on every cert renewal |
| SPKI (public key) | survives cert renewal | breaks on key rotation |
| Intermediate CA | broader trust, fewer rotations | wider attack surface |

| Strategy | Pros | Cons |
|---|---|---|
| Static pins in app | simple, secure | bricking risk; requires app update to rotate |
| OTA-fetched pins | fast rotation | source of pins must be authenticated |
| `NetworkSecurityConfig` (Android) | declarative, expiring | Android-only |
| Pin TTL | gradual fallback | weaker security after expiration |

---

## Production Usage

- **Banks, fintech**: pin always, with strict rotation runbook.
- **Healthcare**: pin per HIPAA-aligned threat model.
- **Government / defense**: pin + custom CA bundles.
- **Consumer apps**: usually skip; ops cost > security benefit.
- **Crypto wallets**: pin always.

---

## Hands-On Exercise

1. **Implementation**: enable pinning on iOS via `URLSessionDelegate` and Android via `NetworkSecurityConfig`; test with both pinned and unpinned hosts.
2. **Debugging**: pinning works on iOS but fails on Android — likely a hash format / encoding mismatch.
3. **Architecture**: design a pin rotation runbook covering: planned rotation, emergency rotation, lost backup key.
4. **Threat modeling**: diagram what pinning protects against and what it doesn't.

---

## Common Mistakes

- Only one pin → bricking risk.
- Pinning leaf cert → breaks on every renewal.
- Pinning third-party APIs you don't control.
- No expiration on pins → outdated pins linger.
- Disabling pinning entirely "for debugging" without removing the bypass before release → backdoor in production.
- Hardcoding pins in JS layer → JS can be tampered.

---

## Production Red Flags

- **No pin rotation runbook** → ticking time bomb.
- **Pinning enabled in dev with disable flag in prod** → flag flip risk.
- **One pin per host** → no resilience.
- **Pinning + no telemetry** → can't detect rotation issues.

---

## Performance & Metrics (MANDATORY)

- **TLS handshake**: pin check adds <1ms — negligible.
- **Memory**: pin set is bytes.
- **Bundle**: pinning library ~10-30KB.
- **Battery**: nil.

---

## Metrics That Matter

- Pin failure rate (per host, per app version)
- Successful connection rate after pin enforcement
- Time-to-rotation execution

---

## Decision Framework

| Risk profile | Pin? |
|---|---|
| Bank, broker | Yes (mandatory) |
| Healthcare PHI | Yes |
| Crypto wallet | Yes |
| E-commerce | Optional |
| News reader | No |
| Internal employee app | Yes |
| Third-party APIs | No (you can't control rotation) |

---

## Senior-Level Insight

Pinning is **operational discipline disguised as a security feature**. The protection only works if rotation discipline is rock-solid. The cost is: a runbook, a monitoring dashboard, an inventory, and culture awareness. Without the discipline, pinning increases risk (you brick yourself before an attacker bricks you).

Senior engineers ensure: (1) ≥2 pins always, (2) expiration tracked in calendar, (3) rotation rehearsed before crisis, (4) telemetry on pin failures, (5) emergency override path documented (not necessarily enabled).

The 2026 specific: with Apple's Privacy Manifests and Google's similar moves, transparency about network behavior is increasingly required — pinning is one part of a "responsible network posture" story you tell App Store reviewers and security auditors.

---

## Real-World Scenario

**Symptom:** Mobile app suddenly can't connect to backend; web works fine.
**Investigation:** Backend rotated TLS certs as planned; pinned key was the *intermediate CA* and that intermediate was retired.
**Root Cause:** Pinning intermediate CA created tight coupling to PKI structure; a planned PKI change broke the app.
**Fix:** Switch to SPKI pins of the leaf's public key (which is stable across cert renewals as long as key reused); rotate via app update.
**Lesson:** Pin SPKI, not certs. Coordinate with PKI team on rotation calendar.

---

## Production Failure Story

**Incident:** A regional bank's app stopped working for ~12 hours when a pinned cert expired unnoticed. Customers couldn't access accounts; branches overwhelmed by phone calls.
**Impact:** Brand damage; estimated $2M in productivity loss; regulatory inquiry.
**Investigation:** Pinned cert had 1-year validity; team forgot the renewal. No backup pin. Forced app update was the only fix; rolling out to entire user base took ~24h.
**Root Cause:** No backup pin; no expiration alerting.
**Fix:** Two-pin minimum (current + backup); calendar reminder 30 days before expiration; OTA pin-update endpoint added (signed payload).
**Prevention:** Pin inventory dashboard; quarterly pinning fire drills.

---

## Debugging Checklist

1. Compute SPKI hash from the live server cert; compare to pinned hashes.
2. Check expiration on `NetworkSecurityConfig` pin set.
3. Verify pinning enabled in release builds, not just debug.
4. Test with proxy (mitmproxy with custom root) — should fail.
5. Log pin-failure events with hostname + cert details.
6. Check for OS version requirements (Android 7+ for NetworkSecurityConfig).

---

## Advanced / Internal Knowledge

- SPKI hash computation: extract `SubjectPublicKeyInfo` ASN.1 sequence from cert, SHA-256, base64.
- iOS `SecTrustGetCertificateChain` (iOS 15+) replaces deprecated index-based access.
- Android `NetworkSecurityConfig` supports per-domain pin sets, debug overrides, certificate transparency.
- HPKP browser deprecation reasons: rare and high blast-radius bricking; mobile app pinning is more controllable.
- Dynamic pin update needs its own trust chain (signed pin manifests, e.g., Ed25519 signature over JSON).

---

## 2026 AI Tip

- AI is **good at**: generating boilerplate pin code, computing SPKI hashes from sample certs.
- AI is **bad at**: understanding your PKI rotation calendar — verify with security team.
- **Prompt pattern**: "Generate iOS URLSessionDelegate + Android NetworkSecurityConfig for pinning api.example.com with these two SPKI hashes and expiration 2027-01-01."

---

## Related Topics

- S10 Auth & Security
- TLS 1.3 / certificate transparency
- App Store / Play Store security review

---

## Interview Follow-Up Questions

- Why pin SPKI rather than the leaf cert?
- What's the minimum number of pins and why?
- How would you rotate pins without bricking users?
- What does pinning NOT protect against?
- Why was HPKP deprecated in browsers but pinning still recommended for mobile?

---

## Memory Hook

**"Pin SPKI, two minimum, rotate before you must."**

## Revision Notes

> Pinning binds app to known keys. Use SPKI hashes. Always backup pin. Rotation runbook mandatory. Telemetry on failure. Consider OTA-signed pin updates.

---

> **End of S9.** Cross-refs: S8 (mutation queues), S10 (auth/security), S11 (offline), S15 (native modules), S18 (observability). Next deep section: [S15 Native Bridging](S15-native-bridging.md).
