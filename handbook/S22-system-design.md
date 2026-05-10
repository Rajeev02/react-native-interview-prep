# S22 — Mobile System Design

> Ride-booking · social feeds · chat (E2EE) · fintech ledgers · video streaming · super apps · maps · collaboration

Mobile system design rounds aren't web system design with a screen size constraint. They're **fundamentally different** — battery, intermittent network, OS lifecycle, app-store constraints, native module surface, push as a primary IPC channel, and per-platform divergence. This section gives the playbook for the five most-asked rounds. Cross-refs: [S11 offline-first](S11-offline-first.md), [S9 networking](S09-networking.md), [S10 auth/security](S10-auth-security.md), [S16 architecture](S16-architecture.md), [appendix M architecture diagrams](../appendix/M-architecture-diagrams.md).

---

## Mobile system-design framework (the universal opener)

Whatever the prompt, structure your answer in this order — interviewers love it:

1. **Clarify scope** (1 min): platforms (iOS/Android/web), regions, scale, MAU, online/offline split, regulatory.
2. **Functional requirements** (1 min): top 3–5 user journeys.
3. **Non-functional requirements** (2 min): latency budgets, offline behavior, battery, accessibility, security/PII, compliance.
4. **High-level architecture** (3 min): app modules, network layer, storage layer, push, background tasks, server contracts.
5. **Data model + storage** (3 min): which DB per domain (S11), schema sketches, cache strategy.
6. **Critical flows deep-dive** (8 min): sequence diagrams for the 1–2 hardest flows.
7. **Failure modes + scale** (3 min): network loss, server outage, fan-out, hot keys, abuse.
8. **Observability + rollout** (2 min): telemetry, feature flags, kill switches, staged rollout.
9. **Tradeoffs + extensions** (2 min): what would change at 10× scale or with different constraints.

Memorize this. It works for every prompt.

---

### Q1. Design a ride-booking app (Uber/Ola/Rapido) — mobile scope

---

## Difficulty
- Expert

## Interview Frequency
- Very Common

## Prerequisites
- WebSockets, geo-data, background location, payments

## TL;DR
Two apps (rider, driver) sharing a backend. Hot path: **driver location stream → server matching → rider live ETA**. Use **WebSocket + push fallback** for live channel; **MapView with clustering**; **MMKV** for trip state, **op-sqlite** for trip history; **background location** with foreground service (Android) and significant-change/region monitoring (iOS); **idempotent payment intent** with retry-safe API; **graceful degradation** on tunnel/no-signal — keep last-known state, queue updates, resume on reconnect.

---

## 30-Second Interview Answer

> "Two apps (rider, driver), one backend. Driver app streams location every few seconds via WebSocket; server runs geospatial matching (S2 cell or geohash). Rider app subscribes to driver's WebSocket channel for live ETA + position. Trip state lives locally in MMKV so the app survives kill/restart mid-trip. Payments use an idempotency-key intent so retries don't double-charge. Background location uses Foreground Service on Android (with notification) and significant-location-change on iOS (battery-aware). Failure modes: tunnel = buffer + reconcile on reconnect; server down = cached fares + queued booking; OS kill = restore via push + persisted trip ID."

---

## 2-Minute Practical Answer

**Apps**:
- Rider app: search → fare estimate → book → live tracking → pay → rate.
- Driver app: online toggle → match accept → navigate → trip lifecycle → earnings.

**Critical flows**:
1. **Driver location → server**: WS message every 4–6s when moving; throttle to 15–30s when stationary; coalesce on poor network.
2. **Matching**: server picks nearest available drivers via geohash/S2 grid; sends offer via push + WS to driver app; rider app sees "finding driver".
3. **Live tracking**: rider subscribes to a per-trip WS channel; receives driver position + ETA updates; map redraws.
4. **Payment**: client creates `paymentIntent` with idempotency key; backend (Stripe/Razorpay/PG) charges; webhook confirms; client polls or receives push.
5. **Trip end**: receipt synced; rating queued offline if needed.

**Storage**:
- MMKV: current trip ID, fare snapshot, last driver location, auth tokens (Keychain for secrets).
- op-sqlite: trip history, receipts, support transcripts.
- Image cache: `expo-image` (disk + memory).

**Background**:
- Driver app: Foreground Service (Android) with persistent notification; on iOS, region monitoring + significant-change + headless task on push wake.
- Rider app: silent push for driver-state changes; minimal background CPU.

**Key non-functional**:
- Live update latency P95 < 2s.
- App cold start to map < 1.5s on mid-tier.
- Battery drain < 6%/hr while live-tracking.
- Crash-free sessions > 99.5%.

**Network resilience**:
- WS reconnect with backoff + last-msg-id resume.
- Push as fallback channel for high-importance events (driver assigned, trip ended).
- Booking request queued if offline; visible "pending" state.

---

## 5-Minute Architecture Answer

```
            ┌─────────────────┐                 ┌─────────────────┐
            │   Rider App     │                 │  Driver App     │
            │ (RN, Expo)      │                 │  (RN, Expo)     │
            └─┬───────────────┘                 └───────────────┬─┘
              │ HTTPS (REST)                                    │
              │ WSS (live)                                      │
              │ APNs/FCM (push)                                 │
              ▼                                                 ▼
        ┌──────────────── Edge / API Gateway ────────────────────┐
        │   Auth · Rate-limit · Routing · WAF                    │
        └────┬──────────────┬─────────────┬───────────┬──────────┘
             ▼              ▼             ▼           ▼
        ┌────────┐    ┌──────────┐  ┌──────────┐ ┌──────────┐
        │ Search │    │ Matching │  │ Trip svc │ │ Payments │
        │ + Fare │    │ (geo idx)│  │ (FSM)    │ │ (PSP)    │
        └────┬───┘    └────┬─────┘  └────┬─────┘ └────┬─────┘
             ▼             ▼             ▼            ▼
        ┌─────────────── Kafka / NATS event bus ──────────────┐
        └────┬──────────────┬─────────────┬───────────┬───────┘
             ▼              ▼             ▼           ▼
        ┌─────────┐   ┌──────────┐  ┌──────────┐ ┌──────────┐
        │ Postgres│   │ Redis    │  │ Maps API │ │ Webhooks │
        │ (trips) │   │ (geo)    │  │ (routing)│ │ (PSP→us) │
        └─────────┘   └──────────┘  └──────────┘ └──────────┘
```

**Mobile-side modules**:
- `core/` — auth, network client, telemetry, push, feature flags.
- `maps/` — MapView wrapper (`react-native-maps` or `expo-maps`), clustering, route polyline drawer.
- `live/` — WS client, reconnect manager, channel subscriptions, optimistic state.
- `trip/` — trip FSM (idle → searching → matched → enroute → ongoing → ended → rated), persisted in MMKV.
- `payments/` — payment intent, webhook listener via push, retry handler.
- `location/` — foreground service (Android), background location strategy (iOS).
- `offline/` — outbox for queued bookings, ratings, support tickets.

**Key design choices**:
- **WebSocket vs polling**: WS for live tracking (low overhead, server push). Polling fallback when WS unavailable (corporate firewalls).
- **Geo-indexing**: server-side use S2 cells / H3 hexagons; client doesn't need to know.
- **Map rendering**: native maps (Apple/Google), not WebView. Tile pre-fetch for known route.
- **State machine**: trip is a strict FSM; client and server must agree on transitions; reconcile on reconnect via `GET /trips/:id`.
- **Idempotency**: every booking request carries client UUID; server dedups for 24h.
- **Privacy**: precise location only while app shows tracking UI; switch to "while in use" on iOS; show on-screen indicator.
- **Battery**: cap WS message rate; reduce GPS accuracy when stationary; suspend on background after grace period.

**Failure modes**:
- **Tunnel / no signal**: WS buffer; trip state preserved; reconnect resumes; rider sees "reconnecting".
- **Driver app killed mid-trip**: push wakes app; restores trip from server `GET /trips/:id`; resumes location stream.
- **Server outage**: rider app shows last-known driver position + cached ETA; new bookings queue.
- **Payment failure**: clearly distinguish "pending" vs "failed"; never silently retry charge without user signal.
- **GPS spoofing**: server-side anomaly detection; speed sanity checks.

**Scale considerations** (for the senior-level discussion):
- 100K concurrent trips → 100K WS connections per region → shard by region/city.
- Driver location stream at 6s interval × 1M drivers → ~165K msg/sec → Kafka partitioning by city.
- Map tile traffic offloaded to CDN.
- Push fan-out via FCM/APNs handles bursts.

The 2026 specific:
- **Live Activities (iOS)** + **Persistent Notifications (Android)** for trip status — replaces some in-app live updates.
- **App Clips / Instant Apps** for first-ride users.
- **Privacy Manifests** (iOS) declare location/identifier usage.
- **Predictive App Resources** — ship critical map tiles for user's home region preemptively.

---

## The "Why"

Ride apps are the canonical mobile system-design question because they exercise every dimension: real-time, offline, payments, push, background, geo, scale, regulatory. Companies care because if you can design this, you can design most consumer apps.

---

## Mental Model

A ride app = **finite state machine + live channel + payment ledger**, glued by location streams and push.

---

## Internal Working (2026 Context)

- WS over TLS 1.3, multiplexed; QUIC for newer SDKs.
- Push: APNs (iOS) HTTP/2 + JWT, FCM HTTP v1 (Android).
- Geo: H3 (Uber's own) or S2 (Google) cells; server-side index in Redis or specialized.
- Maps: vector tiles, GPU-rendered.
- Foreground Service (Android 14+): explicit type `location`; persistent notification mandatory.
- iOS background: Significant Location Change, Region Monitoring, BGTaskScheduler.

---

## Modern Implementation (Code)

**WS reconnect with last-message resume**:
```ts
class LiveChannel {
  ws?: WebSocket;
  lastMsgId?: string;
  url: string;
  backoff = 500;

  open(url: string) {
    this.url = url;
    this.connect();
  }

  private connect() {
    this.ws = new WebSocket(`${this.url}?since=${this.lastMsgId ?? ''}`);
    this.ws.onmessage = (e) => {
      const msg = JSON.parse(e.data);
      this.lastMsgId = msg.id;
      bus.emit(msg.type, msg.payload);
    };
    this.ws.onopen = () => { this.backoff = 500; };
    this.ws.onclose = () => {
      setTimeout(() => this.connect(), this.backoff);
      this.backoff = Math.min(this.backoff * 2, 30_000);
    };
  }
}
```

**Trip FSM persisted in MMKV**:
```ts
type TripState =
  | { kind: 'idle' }
  | { kind: 'searching'; pickup: LatLng; drop: LatLng }
  | { kind: 'matched'; tripId: string; driverId: string; eta: number }
  | { kind: 'enroute'; tripId: string; driverPos: LatLng; eta: number }
  | { kind: 'ongoing'; tripId: string }
  | { kind: 'ended'; tripId: string; fare: number }
  | { kind: 'rated'; tripId: string };

const TRIP_KEY = 'trip.current';

export function persistTrip(s: TripState) { mmkv.set(TRIP_KEY, JSON.stringify(s)); }
export function loadTrip(): TripState {
  const raw = mmkv.getString(TRIP_KEY);
  return raw ? JSON.parse(raw) : { kind: 'idle' };
}
```

**Idempotent booking**:
```ts
async function bookRide(req: BookRequest) {
  const idemKey = uuid();
  return await api.post('/bookings', req, {
    headers: { 'Idempotency-Key': idemKey },
  });
}
```

**Foreground service hook (Android, Expo)** — typically via `expo-task-manager` + `expo-location`:
```ts
import * as Location from 'expo-location';
import * as TaskManager from 'expo-task-manager';

const TASK = 'driver-location-stream';

TaskManager.defineTask(TASK, ({ data, error }) => {
  if (error) return;
  const { locations } = data as any;
  for (const loc of locations) liveChannel.send({ type: 'loc', loc });
});

await Location.startLocationUpdatesAsync(TASK, {
  accuracy: Location.Accuracy.High,
  timeInterval: 5000,
  distanceInterval: 10,
  foregroundService: {
    notificationTitle: 'On a trip',
    notificationBody: 'Sharing your location with your rider.',
  },
});
```

---

## Comparison

| Concern | Choice | Alternative |
|---|---|---|
| Live channel | WebSocket | SSE / long-poll |
| Location index | H3/S2 | geohash (good enough) |
| Map | Native maps | MapBox GL Native |
| Storage | MMKV + op-sqlite | Realm (heavier) |
| Push fallback | APNs/FCM | none (risky) |

---

## Production Usage

- **Uber**: H3 hex grid; custom dispatch; in-house RPC.
- **Ola/Rapido**: similar pattern; regional variations.
- **DoorDash/Swiggy**: courier flow nearly identical to ride driver.
- **Lyft**: Pelias for geocoding; Apache Kafka for location bus.

---

## Hands-On Exercise

1. **Implementation**: build the trip FSM with persistence and resume-on-launch.
2. **Debugging**: rider sees stale driver position — root cause: WS lost without reconnect signaling.
3. **Architecture**: extend to "schedule a ride for later" — persistent server-side trip + push trigger.
4. **Scale**: discuss going from 1 city to 100; geo-sharding, multi-region.

---

## Common Mistakes

- Treating WS as reliable — always need reconnect + resume.
- No idempotency on booking → duplicate trips.
- GPS at high accuracy permanently → battery drain.
- Trip state only in memory → loss on app kill.
- Polling for ETA every 1s → battery + cost.

---

## Production Red Flags

- **WS without ping/pong** → silent half-open connections.
- **No background service notification on Android** → OS kills location stream.
- **Payments retried without idempotency** → double charges.
- **Map redraw on every location update** → jank.

---

## Performance & Metrics (MANDATORY)

- Cold start → map: < 1.5s mid-tier
- Live update P95: < 2s
- Battery drain (driver app, live): < 6%/hr
- Crash-free sessions: > 99.5%
- Booking success rate: > 99%

---

## Metrics That Matter

- Trip-state desync rate
- WS reconnect frequency
- Background-location wakeups granted
- Push delivery latency
- Payment success rate

---

## Decision Framework

| Aspect | Pick |
|---|---|
| Live transport | WS (with push fallback) |
| Maps | native (RN-maps / expo-maps) |
| Storage | MMKV + op-sqlite |
| Background | FG service (Android) + SLC/region (iOS) |
| Payments | server-mediated PSP + idempotency |

---

## Senior-Level Insight

The mature take: **the trip FSM is the contract**. Both client and server must agree on states and transitions; reconciliation on reconnect must be deterministic. Senior engineers also: (1) build a "trip inspector" admin tool for support; (2) record client-side telemetry for every state transition; (3) treat the live channel as best-effort and the FSM as truth.

The 2026 specific: **Live Activities + Persistent Notifications** make the trip status a first-class OS surface; design for it, not against it. Privacy Manifests now require declaring location use cases honestly.

---

## Real-World Scenario

**Symptom:** 0.5% of trips show "still searching" forever even after driver matched.
**Investigation:** Server emits `matched` event but client WS missed it during a reconnect; client never asked for fresh state.
**Root Cause:** WS resume relied on `lastMsgId` but client didn't persist it across reconnects on iOS background suspend.
**Fix:** Persist `lastMsgId` to MMKV; on reconnect, also pull `GET /trips/:id` to reconcile; treat WS as a hint, REST as truth.
**Lesson:** Live channels are eventually consistent; periodic reconciliation is mandatory.

---

## Production Failure Story

**Incident:** New release silently dropped driver foreground notification on Android 14+; OS killed location service after ~10 min; riders saw frozen driver positions.
**Impact:** Thousands of trips with stale ETA; support storm.
**Investigation:** Android 14+ requires `foregroundServiceType=location` and runtime permission; build flag missing.
**Root Cause:** Compile-time config drift; no integration test for FG service lifecycle.
**Fix:** Add Android 14+ FG service config; CI test that location stream survives 30 min idle in emulator.
**Prevention:** Per-Android-version smoke test matrix.

---

## Debugging Checklist

1. Inspect WS state + last reconnect time.
2. Verify FG service notification is shown (Android).
3. Check trip FSM state in MMKV vs server `/trips/:id`.
4. Confirm push token registration (silent push works).
5. Telemetry: WS msg lag, location update interval.

---

## Advanced / Internal Knowledge

- H3 (Uber): hex grid, multi-resolution; Postgres extension available.
- S2 (Google): spherical quad-tree; library bindings widespread.
- Apple Live Activities API requires App Intents + WidgetKit shared store.
- Android Foreground Service Type system enforced from API 34.

---

## 2026 AI Tip

- AI is **good at**: scaffolding FSM + WS reconnect logic.
- AI is **bad at**: distributed reconciliation invariants — ask for ADR-style reasoning explicitly.
- **Prompt pattern**: "Design rider app trip FSM: states, allowed transitions, persistence, reconciliation on reconnect, push wake handling."

---

## Related Topics

- Q3 Chat
- Q4 Fintech
- S9 networking
- S11 offline-first

---

## Interview Follow-Up Questions

- How would you handle 10× scale?
- WS vs SSE for this use case?
- What if app is killed mid-trip?
- How do you prevent GPS spoofing?
- How do Live Activities change the design?

---

## Memory Hook

**"FSM + live channel + push fallback."**

## Revision Notes

> Two apps + one backend; trip FSM is truth, WS is hint. MMKV persists trip; FG service for Android driver; SLC/regions for iOS. Idempotent bookings + payments. Reconcile via REST after every reconnect.

---

---

### Q2. Design a social feed (Twitter/Instagram/LinkedIn-style)

---

## Difficulty
- Expert

## Interview Frequency
- Very Common

## Prerequisites
- List virtualization, image pipeline, prefetch, ranking

## TL;DR
Single infinite list with **cursor pagination**, **viewport-aware prefetch**, **image pipeline** (`expo-image` with thumbhash), and **offline cache**. Feed page lives in op-sqlite with TTL; new posts inserted via push or pull-to-refresh. **Ranking** done server-side; client only renders. Telemetry: viewport impressions, dwell time, scroll velocity. Optimize cold start: render skeleton + cached page first, then revalidate.

---

## 30-Second Interview Answer

> "Cursor-paginated feed served by server, cached in op-sqlite with TTL. FlashList for viewport-virtualized rendering. expo-image with thumbhash placeholders + disk cache. On open: render last cached page instantly, then revalidate from network. Prefetch next page when within 2 viewports of end. Viewport-impression telemetry batched and sent on idle. New posts arrive via push (silent) or pull-to-refresh; merged with existing list at top. Ranking is server-side; client just renders. Offline = read cached page, queue likes/comments in outbox, sync when online."

---

## 2-Minute Practical Answer

**App architecture**:
- `feed/` — list, item renderers, prefetcher.
- `media/` — image, video lazy loaders.
- `interaction/` — like, comment, share — all optimistic.
- `outbox/` — offline interactions queue.
- `telemetry/` — viewport impressions, scroll metrics.

**Data flow**:
1. Open app → load cached feed page from op-sqlite (instant).
2. Background revalidate via `GET /feed?cursor=null`.
3. As user scrolls, prefetch next page when within 2 screens of bottom.
4. Each item visible > 500ms = impression event (batch + send on idle).
5. Like/comment = optimistic UI + outbox enqueue + sync.
6. Push notification "new posts" → badge + pull-to-refresh prompt.

**List**:
- `@shopify/flash-list` (FlashList v2) — handles 10K+ items.
- Item types: text, image, video, carousel, ad — declared upfront for recycling.
- Avoid inline anonymous functions; memoize handlers (Compiler helps in 2026).

**Image pipeline**:
- `expo-image` with `placeholder={{ thumbhash: '...' }}`.
- Disk cache 100MB, memory 30MB, LRU.
- Pre-resized thumbnails server-side; client requests right size for screen DP.

**Offline**:
- Last 3 pages persisted in op-sqlite with `(cursor, fetched_at, payload_json)`.
- TTL 1h; if older, show stale + revalidate.
- Likes/comments queued via outbox table (S11 Q5).

**Network**:
- HTTP/2 multiplex; gzip/brotli responses.
- `If-Modified-Since` per page to skip unchanged.
- Auth: Bearer token + refresh.

**Notifications**:
- Silent push for "5 new posts above" → badge + banner inside app.
- Visible push only for direct mentions.

**Performance budgets**:
- TTI < 1.5s on mid-tier.
- 60fps scroll on mid-tier.
- < 100MB memory at 200 items rendered.

---

## 5-Minute Architecture Answer

```
┌─────────────── Mobile App ───────────────┐
│  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │ Feed UI  │→│ Prefetch │→│ Outbox │  │
│  │ FlashList│  │ Manager  │  │ (sync) │  │
│  └─────┬────┘  └────┬─────┘  └────┬───┘  │
│        │            │              │      │
│  ┌─────▼────────────▼──────────────▼───┐  │
│  │  TanStack Query + op-sqlite cache   │  │
│  └─────┬───────────────────────────────┘  │
│        │ HTTPS                             │
└────────┼───────────────────────────────────┘
         ▼
   ┌────────────── Edge ──────────────┐
   │  CDN (images, videos)            │
   │  API Gateway (feed, interactions)│
   └──┬─────────────────────────────┬─┘
      ▼                              ▼
┌──────────┐  ┌──────────┐   ┌──────────────┐
│ Feed svc │  │ Ranker   │   │ Interaction  │
│ (paged)  │←→│ (ML)     │   │ (likes, etc.)│
└────┬─────┘  └────┬─────┘   └────┬─────────┘
     ▼             ▼               ▼
┌──────────────── DBs / Caches ─────────────┐
│ Postgres + Redis + Vector store + Object  │
└───────────────────────────────────────────┘
```

**Critical client decisions**:
- **List engine**: FlashList over FlatList — recycler-style, ~5× memory win. Avoid `LegendList` unless reason.
- **Cache shape**: page-keyed (cursor → list of post IDs) + post-keyed (post ID → post body). This lets you mutate one post (after like) without re-rendering the page.
- **Prefetch policy**: based on scroll velocity. Slow scroll = aggressive prefetch (2 pages ahead). Fast scroll = throttle (don't burn data on flicked-through content).
- **Image priority**: above-fold = high; below-fold = low. Cancel loads on items recycled.
- **Telemetry batching**: collect impressions in memory; flush every 10s or on background.
- **Compiler-aware code**: in 2026, no manual `useMemo` for item renderers; rely on React Compiler.

**Failure modes**:
- **No network**: serve cached pages; show stale banner; queue interactions.
- **Stale cache after rank change**: revalidate on app open; soft-invalidate on background-foreground.
- **Hot post (millions of likes)**: server-side rate limit + counter shard; client shows estimate "~1.2M".
- **Image CDN down**: fall back to thumbhash placeholder permanently; show retry icon.
- **Push storm**: coalesce silent pushes; max 1 refresh hint per minute.

**Scale considerations**:
- Personalized feed → push to user's inbox (Twitter "celebrity problem" addressed by hybrid push/pull).
- 100M MAU → 10M concurrent feed reads → CDN + caching layers handle.
- Image traffic dwarfs JSON; size + format (AVIF, WebP) matters.

The 2026 specific:
- **React Compiler** removes most memoization toil — focus on data shapes, not perf hacks.
- **Static Hermes** fast JSON parse for feed payloads.
- **expo-image v3+** with thumbhash + AVIF support.
- **Live Activities** for ongoing events (e.g., live stream you're watching) — feed item can launch one.
- **App Intents (iOS)** for "open last unread post" Siri/Spotlight integration.

---

## The "Why"

Feeds are the highest-engagement surface in most apps. Every ms of jank loses retention. Every wasted MB of data costs users on metered plans. Companies care because feed performance directly = revenue (ads, content engagement).

---

## Mental Model

Feed = **virtualized list + page cache + image pipeline + outbox** — four subsystems, each independently engineered.

---

## Internal Working (2026 Context)

- FlashList: recycler with cell type estimates; one ViewHolder per type.
- expo-image: native pipeline (Nuke iOS, Coil Android); thumbhash decoded on native side.
- TanStack Query: stale-while-revalidate; persistor → MMKV.
- op-sqlite: page table (cursor PK, JSON), post table (id PK, JSON, fetched_at).

---

## Modern Implementation (Code)

**FlashList feed**:
```tsx
import { FlashList } from '@shopify/flash-list';
import { Image } from 'expo-image';

function Feed() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
    queryKey: ['feed'],
    queryFn: ({ pageParam }) => api.feed({ cursor: pageParam }),
    getNextPageParam: (last) => last.nextCursor,
    initialPageParam: null as string | null,
  });

  const items = data?.pages.flatMap((p) => p.items) ?? [];

  return (
    <FlashList
      data={items}
      keyExtractor={(it) => it.id}
      renderItem={({ item }) => <FeedItem item={item} />}
      getItemType={(it) => it.type}
      onEndReached={() => hasNextPage && !isFetchingNextPage && fetchNextPage()}
      onEndReachedThreshold={1.5}
      onViewableItemsChanged={onImpressions}
      viewabilityConfig={{ itemVisiblePercentThreshold: 60, minimumViewTime: 500 }}
    />
  );
}

function FeedItem({ item }: { item: Post }) {
  return (
    <View>
      <Image
        source={{ uri: item.imageUrl }}
        placeholder={{ thumbhash: item.thumbhash }}
        contentFit="cover"
        transition={150}
        style={{ aspectRatio: 1 }}
      />
      <Text>{item.body}</Text>
      <LikeButton postId={item.id} initial={item.likes} />
    </View>
  );
}
```

**Optimistic like with outbox**:
```tsx
function LikeButton({ postId, initial }: { postId: string; initial: number }) {
  const qc = useQueryClient();
  const [liked, setLiked] = useState(initial > 0);
  const [count, setCount] = useState(initial);

  const mutate = async () => {
    setLiked(!liked);
    setCount((c) => c + (liked ? -1 : 1));
    await enqueueOutbox({ entity: 'like', op: 'toggle', payload: { postId } });
    qc.invalidateQueries({ queryKey: ['post', postId], exact: true });
  };

  return <Pressable onPress={mutate}>{liked ? '♥' : '♡'} {count}</Pressable>;
}
```

**Impression batcher**:
```ts
const buffer: Impression[] = [];
let flushTimer: any;

function onImpressions({ viewableItems }: any) {
  for (const v of viewableItems) buffer.push({ id: v.item.id, ts: Date.now() });
  if (!flushTimer) flushTimer = setTimeout(flush, 10_000);
}

async function flush() {
  if (!buffer.length) return;
  const batch = buffer.splice(0);
  flushTimer = null;
  await api.impressions(batch).catch(() => buffer.unshift(...batch));
}
```

---

## Comparison

| Choice | Pick | Alt |
|---|---|---|
| List | FlashList v2 | LegendList |
| Image | expo-image | FastImage [DEPRECATED for new RN] |
| Cache | TanStack Query + MMKV | Apollo (if GraphQL) |
| Offline | op-sqlite | WatermelonDB |

---

## Production Usage

- **Twitter/X**: hybrid push-pull feed, vector search ranker.
- **Instagram**: image-heavy CDN; aggressive prefetch.
- **LinkedIn**: feed objects of many types; SDUI for ad units.
- **Reddit**: cursor pagination; markdown rendering optimization.

---

## Hands-On Exercise

1. **Implementation**: feed with FlashList + TanStack infinite query + expo-image.
2. **Debugging**: jank on scroll on mid-tier — likely image decode on JS thread; switch to expo-image native decode.
3. **Architecture**: add push-driven "new posts available" banner.
4. **Performance**: measure scroll FPS on 1k items.

---

## Common Mistakes

- FlatList for large feeds (memory blow-up).
- Inline functions in renderItem.
- High-res images on small thumbnails.
- Telemetry sent per impression (network spike).
- No offline cache → 0 content offline.

---

## Production Red Flags

- **Re-renders on every scroll** (React Profiler shows feed re-rendering wholesale).
- **Image cache off** → constant network reload.
- **Likes not optimistic** → tap latency.
- **No prefetch** → bottom-of-page wait.

---

## Performance & Metrics (MANDATORY)

- Cold open → first content: < 1s (cached) / < 2s (fresh)
- Scroll FPS: 60 mid-tier
- Memory at 200 items: < 100MB
- Image load P95: < 600ms
- Like→server P95: < 300ms

---

## Metrics That Matter

- Cache hit rate
- Impression coverage
- Scroll-jank events / session
- Image decode time
- Outbox depth

---

## Decision Framework

| Concern | Pick |
|---|---|
| Many item types | FlashList `getItemType` |
| Real-time updates | silent push + merge at top |
| Heavy ads | server-rendered SDUI |
| Heavy media | adaptive video, lazy load |

---

## Senior-Level Insight

The mature take: **a feed is a perception engine** — perceived speed beats real speed. Render skeletons + cached content first, revalidate quietly. Senior engineers also: (1) ship a "feed devtool" (impression overlay, cache age, prefetch state) for QA; (2) use shadow ranking experiments to test new rankers without UX impact; (3) measure on 3-year-old Android in CI.

The 2026 specific: **React Compiler + Static Hermes** make most micro-optimizations unnecessary. Spend energy on data shapes and image pipelines instead.

---

## Real-World Scenario

**Symptom:** Memory crashes on Android 8 devices with 6GB app size after 20 min scrolling.
**Investigation:** Image cache unbounded; expo-image disk cap not set; OS killed app under memory pressure.
**Root Cause:** Default cache limits too high for low-end devices.
**Fix:** Adaptive cache: 30MB on low-end, 150MB on high-end; respect memory pressure events.
**Lesson:** Cache budgets must scale with device.

---

## Production Failure Story

**Incident:** Roll-out of new "high-res" image format caused 3× data usage; trended on social media as battery/data hog.
**Impact:** PR damage; emergency rollback.
**Investigation:** Server delivered AVIF without size variants; client didn't request smaller sizes.
**Root Cause:** Missing image-variant negotiation.
**Fix:** Server returns multiple sizes; client picks based on screen DP + network class.
**Prevention:** Image-size policy doc; CI test for size delivery.

---

## Debugging Checklist

1. React Profiler → why does row re-render?
2. expo-image cache stats.
3. Network HAR — image sizes vs screen DP.
4. Impression coverage report.
5. FPS profiler.

---

## Advanced / Internal Knowledge

- FlashList v2 uses recycler pattern with type-aware pools.
- Thumbhash 22 chars → tiny LQIP.
- TanStack Query `gcTime` defaults; tune for cache.
- Server-Driven UI (SDUI) reduces release coupling for feed components.

---

## 2026 AI Tip

- AI is **good at**: list+image scaffolding, cache layers.
- AI is **bad at**: ranking signals — domain.
- **Prompt pattern**: "Build a feed with FlashList, infinite query, expo-image with thumbhash, and optimistic like via outbox."

---

## Related Topics

- S7 performance
- S9 networking
- S11 offline
- Q3 chat (similar list patterns)

---

## Interview Follow-Up Questions

- FlashList vs FlatList — when?
- How would you implement "new posts above"?
- How do impressions affect ranker?
- What if push fails — how do you trigger refresh?
- How does React Compiler change feed code?

---

## Memory Hook

**"List + cache + image + outbox."**

## Revision Notes

> FlashList + cursor pagination + op-sqlite cache + expo-image with thumbhash. Optimistic interactions via outbox. Silent push for "new content". Impression telemetry batched. Compiler removes most memo work in 2026.

---

---

### Q3. Design a chat app (WhatsApp/Signal-style with E2EE)

---

## Difficulty
- Expert

## Interview Frequency
- Very Common

## Prerequisites
- WebSockets, push, E2EE basics, offline DB

## TL;DR
**WatermelonDB** for messages (reactive, lazy, sync-aware) — or op-sqlite if rolling sync custom. **WebSocket** for live; **push** for wake when backgrounded. **Signal Protocol (X3DH + Double Ratchet)** for E2EE. Each message has client UUID + idempotency. Delivery semantics: **sent → delivered → read** receipts. Multi-device via per-device session keys. Media via E2EE blob upload to S3-like storage with key in message envelope. Offline: queued sends; merge on reconnect.

---

## 30-Second Interview Answer

> "Messages live in WatermelonDB for reactive lists + lazy load. Live transport is WebSocket; backgrounded chat wakes via push (silent or visible depending on settings). E2EE uses Signal Protocol — X3DH key agreement, Double Ratchet for forward secrecy. Each message carries client UUID for idempotency. Delivery states (sent/delivered/read) tracked client + server. Multi-device sync via Sesame protocol (per-device sessions, fan-out from sender). Media is encrypted client-side, uploaded to blob store, key shipped in message envelope. Offline = queue in outbox, send on reconnect. Listed view uses FlashList; per-thread observer fires on new message."

---

## 2-Minute Practical Answer

**Modules**:
- `crypto/` — Signal Protocol session, key store (Keychain/Keystore for identity key).
- `messages/` — model, repository, FlashList rendering, observers.
- `transport/` — WS client, reconnect, push handler.
- `media/` — encrypt + upload + decrypt + cache.
- `presence/` — typing, online (best-effort).

**Data model**:
```sql
messages(
  id PRIMARY KEY,
  thread_id,
  sender_id,
  body_cipher BLOB,
  body_plain TEXT,           -- decrypted, only on this device
  status,                    -- pending|sent|delivered|read
  created_at,
  delivered_at,
  read_at
)
threads(id, title, last_message_id, unread_count)
```

**Send flow**:
1. User types → on send, encrypt with current ratchet → write to DB with status=pending → enqueue WS send.
2. WS ack → status=sent.
3. Recipient device acks delivery → status=delivered.
4. Recipient opens chat → status=read.

**Receive flow**:
1. WS message or push delivers ciphertext.
2. Decrypt with ratchet; advance state.
3. Insert into DB; observer fires; UI updates.
4. Send delivery ack.

**E2EE**:
- Identity key pair on first install; uploaded to server.
- Pre-keys uploaded to server for X3DH.
- Per-conversation Double Ratchet state stored encrypted in MMKV/Keystore.
- Multi-device: each device has own identity; sender encrypts per-recipient-device.

**Offline**:
- Outgoing: queued via outbox; UI shows clock icon → checkmark on send.
- Incoming: push wake decrypts and stores; user sees on next open.

**UI**:
- FlashList with `inverted` for chat order.
- Reactive query: `messages.where(thread_id=X).observe()`.
- Avatar/status updates via separate query.

**Performance**:
- Lazy decrypt: only decrypt visible messages (or recent N).
- Image thumbnails encrypted + cached.
- Voice notes streamed-decrypt.

---

## 5-Minute Architecture Answer

```
┌────── Mobile App (Sender) ──────┐    ┌── Mobile App (Receiver) ──┐
│  UI ↔ WatermelonDB              │    │  UI ↔ WatermelonDB        │
│  Crypto (Signal Proto)          │    │  Crypto (Signal Proto)    │
│  WS / Push handler              │    │  WS / Push handler        │
└───────┬─────────────────────────┘    └───────────▲───────────────┘
        │ ciphertext + envelope                    │
        ▼                                          │
   ┌────────── Edge ──────────┐                    │
   │  WS gateway              │                    │
   │  Push fan-out (FCM/APNs) │────────────────────┘
   └────┬──────────────────┬──┘
        ▼                  ▼
   ┌──────────┐      ┌──────────┐
   │ Msg svc  │      │ Pre-key  │
   │ (queue,  │      │ store    │
   │  retain) │      │ (X3DH)   │
   └────┬─────┘      └──────────┘
        ▼
   ┌──────────┐
   │ Object   │
   │ store    │
   │ (E2EE    │
   │  media)  │
   └──────────┘
```

**Server is dumb**: stores ciphertext envelopes, fans out, holds pre-keys. Cannot read content.

**Critical client decisions**:
- **DB choice**: WatermelonDB sweet spot — reactive, lazy, sync-protocol-friendly. Heavy chats (10K+ msgs) lazy-load.
- **Crypto storage**: identity key in Keychain/Keystore (hardware-backed); ratchet state in encrypted MMKV (rotates frequently).
- **Live channel**: WebSocket while foregrounded; push for background wake; both deliver via same envelope schema.
- **Push payload**: silent push wakes app; visible push (with content) only on iOS via NSE (Notification Service Extension) for decrypt before display.
- **Multi-device** (Sesame protocol): each device has identity; sender encrypts per-recipient-device; new device added = re-key from existing device.
- **Backups**: encrypted backup to user's cloud (iCloud/Drive) with passphrase or recovery key — never with plaintext.

**Failure modes**:
- **Lost ratchet state** = reset session; user sees "security number changed".
- **Out-of-order messages** = ratchet supports skipped keys (limited window); beyond window, ask resend.
- **Old device reinstall** = new identity; conversation continues with re-key.
- **Server compromise** = E2EE protects content; metadata (who-talks-to-whom) still leaks unless extra protection.
- **Push delivery failure** = on app foreground, full sync from server queue.

**Scale**:
- 1B users → server stores envelopes (small, transient) + pre-keys.
- Group chat fan-out: server multiplexes to per-recipient encryption (sender encrypts N times) — that's why huge groups get expensive.
- Media: blobs in object storage; signed URLs.

The 2026 specific:
- **MLS (Messaging Layer Security)** — RFC 9420 — emerging replacement for Signal in groups; provides efficient large-group key agreement.
- **iOS Notification Service Extension** required for E2EE message preview.
- **Push Provider Endpoints** under privacy regulations.
- **Cross-platform sync** (Web, Desktop) via per-device sessions.

---

## The "Why"

Chat is the highest-stakes mobile system: privacy, real-time, offline, multi-device, scale. Every dimension matters. Companies care because chat is the bedrock of social apps and a privacy-regulation lightning rod.

---

## Mental Model

Chat = **encrypted envelopes + reactive local DB + live channel + push fallback** — server is a relay, not a reader.

---

## Internal Working (2026 Context)

- Signal Protocol: X3DH (Extended Triple Diffie-Hellman) for session init; Double Ratchet for ongoing.
- Per-message: ephemeral DH ratchet step + symmetric KDF chain.
- Forward secrecy: past messages safe even if current key leaks.
- Post-compromise security: future messages safe after fresh DH step.
- MLS: TreeKEM for group key agreement; logarithmic update cost.

---

## Modern Implementation (Code)

**Send (pseudo)**:
```ts
async function sendMessage(threadId: string, plaintext: string) {
  const id = uuid();
  const msg: Message = {
    id, threadId,
    senderId: me.id,
    bodyPlain: plaintext,
    status: 'pending',
    createdAt: new Date(),
  };
  await database.write(async () => {
    await database.collections.get<Message>('messages').create((m) => Object.assign(m, msg));
  });
  const cipher = await signal.encrypt(threadId, plaintext);
  try {
    await transport.send({ id, threadId, cipher });
    await database.write(async () => {
      const m = await database.collections.get<Message>('messages').find(id);
      await m.update((x) => { x.status = 'sent'; });
    });
  } catch {
    await outbox.enqueue({ id, threadId, cipher });
  }
}
```

**Receive**:
```ts
transport.on('message', async (env) => {
  const plaintext = await signal.decrypt(env.threadId, env.cipher);
  await database.write(async () => {
    await database.collections.get<Message>('messages').create((m) => {
      m._raw.id = env.id;  // idempotency
      m.threadId = env.threadId;
      m.senderId = env.senderId;
      m.bodyPlain = plaintext;
      m.status = 'delivered';
      m.createdAt = new Date(env.ts);
    });
  });
  await transport.ack({ id: env.id });
});
```

**Reactive thread view**:
```tsx
const enhance = withObservables(['threadId'], ({ threadId }) => ({
  messages: database.collections.get<Message>('messages')
    .query(Q.where('thread_id', threadId), Q.sortBy('created_at', Q.desc))
    .observe(),
}));

const Thread = enhance(({ messages }: { messages: Message[] }) => (
  <FlashList
    inverted
    data={messages}
    keyExtractor={(m) => m.id}
    renderItem={({ item }) => <Bubble msg={item} />}
  />
));
```

**iOS Notification Service Extension (decrypt before display)**:
```swift
class NotificationService: UNNotificationServiceExtension {
  override func didReceive(_ req: UNNotificationRequest,
                           withContentHandler ch: @escaping (UNNotificationContent) -> Void) {
    let content = req.content.mutableCopy() as! UNMutableNotificationContent
    if let cipher = content.userInfo["cipher"] as? String {
      content.body = SignalDecrypter.decryptOrFallback(cipher) ?? "New message"
    }
    ch(content)
  }
}
```

---

## Comparison

| Crypto | Strength | Note |
|---|---|---|
| Signal (Double Ratchet) | excellent 1:1; group via Sender Key | de-facto standard |
| MLS (RFC 9420) | groups efficient | newer; emerging |
| OMEMO | XMPP context | niche |
| TLS-only (no E2EE) | server can read | "transport security" only |

| DB | Note |
|---|---|
| WatermelonDB | reactive, sync-aware |
| op-sqlite | raw SQL; you build observers |
| Realm | object model + reactive |

---

## Production Usage

- **WhatsApp/Signal**: Signal Protocol; multi-device with Sesame.
- **Telegram**: MTProto (cloud chats not E2EE; secret chats are).
- **iMessage**: Apple's PQ3 (post-quantum upgrade in 2024).
- **Wire/Element**: MLS-based group messaging.

---

## Hands-On Exercise

1. **Implementation**: 1:1 chat with WatermelonDB + WS, no encryption.
2. **Encryption**: integrate `libsignal-client` for E2EE.
3. **Multi-device**: design device add flow with re-key.
4. **Group**: implement Sender Key for groups of 10/100/1000.

---

## Common Mistakes

- Decrypting all messages on app start → battery + RAM hit.
- No idempotency → duplicate delivery.
- Push payload contains plaintext → leaks via lock screen.
- Backup without encryption → cloud provider sees content.
- Ratchet state in plain MMKV → if device compromised, history readable.

---

## Production Red Flags

- **No NSE on iOS** → decrypted content fetched on tap, slow.
- **Identity key in JS heap** → potential leak via bridge / debugger.
- **Group fan-out done client-side for huge groups** → batt/data drain.
- **No outbox** → messages "lost" when sent offline.

---

## Performance & Metrics (MANDATORY)

- Send latency P95 (foreground): < 500ms
- Receive latency (push): < 3s wall
- Decrypt time per message: < 5ms
- Crypto storage size: < 1MB / chat

---

## Metrics That Matter

- Delivery success rate
- Decrypt failure rate
- Re-key events
- Outbox drain time
- Push receipt time

---

## Decision Framework

| Need | Pick |
|---|---|
| 1:1 + small groups | Signal Protocol |
| Large groups (>100) | MLS |
| Open federation | Matrix + MLS |
| Server-mediated (no E2EE OK) | TLS only |

---

## Senior-Level Insight

The mature take: **the security claim is the product**. If you say "E2EE", you must own every gap (push payloads, backups, screenshots, accessibility, OCR by third-party keyboards). Senior engineers also: (1) commission third-party audit; (2) publish protocol whitepaper; (3) treat ratchet state as crown jewels — hardware-backed where possible.

The 2026 specific: **PQ-secure protocols** (Apple PQ3, Signal PQXDH) account for "harvest now, decrypt later" by quantum adversaries. Plan migration paths.

---

## Real-World Scenario

**Symptom:** Some iOS users see "New message" but no preview.
**Investigation:** NSE crashed during decrypt; iOS fell back to default text.
**Root Cause:** NSE bundle missed library symbol after Xcode upgrade.
**Fix:** Re-link NSE target with required frameworks; add CI test for NSE binary.
**Lesson:** NSE is a separate app target; treat as such.

---

## Production Failure Story

**Incident:** Group chat crash for groups > 256 members on Android.
**Impact:** Power users locked out of large groups.
**Investigation:** Sender Key rotation re-encrypted full key list synchronously on UI thread.
**Root Cause:** Crypto on render path for large N.
**Fix:** Move re-key to worker thread via JSI; show progress; cap group size temporarily.
**Prevention:** Group-size load test in CI.

---

## Debugging Checklist

1. Verify ratchet state present in encrypted store.
2. Check NSE bundle linkage on iOS.
3. Inspect outbox for stuck messages.
4. WS connection state + last-receive ts.
5. Telemetry: decrypt failures, re-key counts.

---

## Advanced / Internal Knowledge

- Double Ratchet: combines DH ratchet with KDF chain.
- Skipped keys window: bounded (e.g., 1000) to prevent DoS.
- Sesame: multi-device; sender encrypts per-recipient-device; "device list" verified server-side.
- libsignal-client (Rust): cross-platform; bindings for RN.

---

## 2026 AI Tip

- AI is **good at**: chat UI scaffolding.
- AI is **bad at**: crypto correctness — never let AI write your crypto from scratch; use audited libs.
- **Prompt pattern**: "Implement message send/receive flow using libsignal-client and WatermelonDB; include outbox + reactive thread view."

---

## Related Topics

- S10 auth/security (key storage)
- S11 offline (outbox)
- S12 push (NSE)

---

## Interview Follow-Up Questions

- Why E2EE if server is trusted?
- How does Double Ratchet ensure forward secrecy?
- What is post-compromise security?
- How would you handle 10k-member groups?
- Backups: how to make them E2EE?

---

## Memory Hook

**"Envelopes only — server can't read."**

## Revision Notes

> WatermelonDB + WS + push + Signal Protocol. Identity key in Keychain/Keystore; ratchet in encrypted MMKV. NSE for iOS preview. Outbox for offline send. Multi-device via Sesame; large groups via MLS. Backups must be E2EE too.

---

---

### Q4. Design a fintech transactions app (UPI/Paytm/Cash-style)

---

## Difficulty
- Expert

## Interview Frequency
- Very Common (in fintech orgs)

## Prerequisites
- Idempotency, OCC, PCI/secure storage, biometric auth

## TL;DR
**Server is the ledger** — client is a thin, secure remote control. Every payment intent has **idempotency key**; reads are eventually consistent with strong refresh on critical screens. **Biometric step-up** for transactions above threshold; **token in Keychain**. **Polling + push** for status updates (push is hint, server REST is truth). **Audit log** mirrored locally for "no internet" history. **Detection**: jailbroken/rooted device guards, attestation (DeviceCheck/Play Integrity), and TLS pinning.

---

## 30-Second Interview Answer

> "Server is the source of truth — never compute balances on client. Each transaction is initiated with a client-generated idempotency key; retries are safe. Sensitive ops (transfer, card, change PIN) require biometric step-up via a fresh short-lived assertion. Tokens in Keychain/Keystore; refresh token rotation. Status updates via long-poll or WS plus push fallback; client always re-fetches on confirmation screen. Local audit log in op-sqlite for offline history view. Anti-fraud: device attestation, TLS cert pinning, jailbreak/root detection, secure flag on screens. Offline = read-only history; writes blocked or queued with explicit user signal."

---

## 2-Minute Practical Answer

**Critical principles**:
1. **Server-authoritative**: client never computes money. Display only what server returned.
2. **Idempotent writes**: every payment carries client UUID; PSP webhook eventually confirms.
3. **Auth + step-up**: token (short-lived, ~5–15 min); refresh; biometric step-up (LAContext / BiometricPrompt) for sensitive ops returns a fresh assertion.
4. **Secure storage**: tokens in Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`); never in MMKV plaintext.
5. **Transport**: TLS 1.3 + cert pinning (or strict CT logs); HTTP/2.
6. **Defense in depth**: jailbreak/root detection, app attestation (DeviceCheck on iOS, Play Integrity on Android), `secureTextEntry`, `FLAG_SECURE` on screens with PII, screen-recording detection.
7. **Audit trail**: local op-sqlite mirror for last N transactions (offline view); reconcile with server on connect.

**Critical flows**:
1. **Login**: password / OTP / biometric → server returns access + refresh + scope.
2. **View balance**: GET /accounts → cached with very short TTL (e.g., 30s).
3. **Initiate transfer**: client generates `txn_id`; biometric step-up → POST /transfers with idempotency key + step-up assertion → server returns `pending`.
4. **Status**: client polls or receives push; on `success/failed` show receipt.
5. **History**: GET /transactions paginated; mirror locally for offline view.

**Network resilience**:
- On unknown status (timeout): never assume failed; query `GET /transfers/:id` until terminal state.
- "Pending" UI for indeterminate state.
- Silent push (data-only) to inform client of status change.

**Data model**:
```sql
transactions (
  id PRIMARY KEY,
  amount, currency,
  counterparty,
  status,                -- pending|success|failed|reversed
  initiated_at, settled_at,
  payload_json
)
accounts (id, masked_no, type, balance_snapshot, snapshot_at)
```

**UI**:
- Confirmation screens with explicit amounts, never animations that hide them.
- "Pull to refresh" on balance — shows freshness time.
- Receipt screen with sharable PDF.

---

## 5-Minute Architecture Answer

```
   ┌──────── Mobile App ────────┐
   │  Auth + Biometric step-up  │
   │  Tx initiator              │───▶ POST /transfers (idem key + step-up token)
   │  Receipt + History view    │◀── GET  /transactions
   │  op-sqlite mirror          │
   └─────────┬──────────────────┘
             │ HTTPS + cert pin
             ▼
       ┌──── Edge / API GW ──┐
       │ Auth / Rate / WAF   │
       └──┬──────────────────┘
          ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Tx svc   │───▶│ Ledger   │───▶│ PSP /    │
    │ (FSM)    │    │ DB (ACID)│    │ Bank /   │
    │          │    │          │    │ UPI rail │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         ▼               ▼               ▼
   ┌──────────────── Webhooks bus ─────────────────┐
   └──┬────────────────────────────────────────────┘
      ▼
   Push to mobile (status change), email, audit log
```

**Mobile-side modules**:
- `auth/` — login, refresh, scope guard, step-up.
- `tx/` — initiate, status, retry, idempotency.
- `accounts/` — balance, holdings.
- `history/` — list + filters + mirror.
- `security/` — attestation, jailbreak detection, screen guards.

**Critical client decisions**:
- **Read freshness**: balance has tiny TTL; force refresh on transfer screen open.
- **Write idempotency**: client UUID; even on app crash mid-request, retry safe.
- **Step-up tokens**: fresh, short-lived, single-use, tied to operation.
- **Local mirror**: read-only view of recent history; never used to compute aggregates.
- **Offline writes**: generally blocked. Some apps allow "request a transfer" intent that submits when online; UX must be explicit.

**Failure modes**:
- **Network timeout post-submit**: status is unknown; show "checking…" + GET /transfers/:id loop with backoff.
- **PSP rail down**: server returns retryable; client shows "try again later".
- **App killed mid-flow**: on relaunch, check `pending_intents` in MMKV → query server for status → resume UI.
- **Token theft**: short TTL + step-up + device binding limit blast radius.

**Compliance**:
- **PCI-DSS**: never store card PAN; tokenize via PSP.
- **Local regulations**: India RBI (no card storage post 2022 → tokenization), EU PSD2 (SCA — strong customer auth), US Reg-E.
- **Audit logs**: all auth + tx events logged on server; on-device only summary.
- **App store rules**: Apple In-App Purchase for digital goods (not for money transfers — different category).

The 2026 specific:
- **Apple Wallet integration** for credit-card add (Apple Pay).
- **Passkeys** replacing passwords; WebAuthn flow on RN via `react-native-passkey`.
- **Privacy Manifests** required.
- **eCash / CBDC pilots** — emerging integrations.
- **AI-driven fraud detection** with on-device models for low-friction risk scoring.

---

## The "Why"

Money apps live or die by trust. One missed idempotency key = double charges = headlines. One leaked token = financial loss. Companies care because regulatory + reputational risk dwarf tech risk; engineering rigor is mandatory.

---

## Mental Model

Fintech app = **secure remote control over a server-side ledger** — client never owns truth.

---

## Internal Working (2026 Context)

- iOS LAContext: biometric returns `LAEvaluatedPolicyDomainState` — hash bound to current biometric set; changes on enrollment changes.
- Android BiometricPrompt: returns `BiometricPrompt.CryptoObject` to sign challenge.
- DeviceCheck (iOS) / Play Integrity (Android): server-side verifiable assertions.
- PSP integrations (Stripe, Razorpay, Adyen): SDK + webhook + idempotency-key headers.

---

## Modern Implementation (Code)

**Idempotent transfer**:
```ts
async function initiateTransfer(req: TransferReq) {
  const idemKey = uuid();
  await mmkv.set(`pending.${idemKey}`, JSON.stringify(req));

  const stepUp = await biometric.signChallenge(req);
  try {
    const res = await api.post('/transfers', { ...req, stepUp }, {
      headers: { 'Idempotency-Key': idemKey },
    });
    await mmkv.delete(`pending.${idemKey}`);
    return res;
  } catch (e) {
    if (isNetworkTimeout(e)) {
      // status unknown; do not assume failure
      return { status: 'unknown', idemKey };
    }
    throw e;
  }
}

// on app start
async function reconcilePending() {
  const keys = mmkv.getAllKeys().filter((k) => k.startsWith('pending.'));
  for (const k of keys) {
    const idemKey = k.slice('pending.'.length);
    const final = await api.get(`/transfers?idempotencyKey=${idemKey}`);
    if (final.status === 'success' || final.status === 'failed') {
      await mmkv.delete(k);
      // update UI / history
    }
  }
}
```

**Biometric step-up (Android)**:
```kt
val prompt = BiometricPrompt(activity, executor, callback)
prompt.authenticate(
  PromptInfo.Builder()
    .setTitle("Confirm transfer")
    .setSubtitle("₹2,499 to Acme Pvt Ltd")
    .setNegativeButtonText("Cancel")
    .build(),
  BiometricPrompt.CryptoObject(signatureBoundToTxnId)
)
```

**Cert pinning (RN)**:
```ts
import { fetch as pinnedFetch } from 'react-native-ssl-pinning';

await pinnedFetch('https://api.example.com/transfers', {
  method: 'POST',
  sslPinning: { certs: ['cert1', 'cert2-backup'] },
  headers: { 'Idempotency-Key': idemKey },
  body: JSON.stringify(req),
});
```

**Jailbreak/root detection**:
```ts
import JailMonkey from 'jail-monkey';

if (JailMonkey.isJailBroken() || JailMonkey.canMockLocation()) {
  blockSensitiveFlows();
  telemetry.log('device.compromised');
}
```

---

## Comparison

| Token store | Use |
|---|---|
| Keychain (iOS) | required |
| Keystore (Android) | required |
| MMKV plain | never for tokens |

| Step-up | Use |
|---|---|
| Biometric (Touch/Face/fingerprint) | preferred |
| OTP | fallback |
| Password | last resort |

---

## Production Usage

- **Cash App**: Square's stack; biometric step-up; PSP-grade.
- **Paytm/PhonePe/GPay**: UPI rail integrations.
- **Revolut/N26**: card + transfer + crypto.
- **Stripe Issuing**: card lifecycle from app.

---

## Hands-On Exercise

1. **Implementation**: idempotent transfer flow with biometric step-up.
2. **Reconciliation**: implement pending-intents recovery on launch.
3. **Architecture**: design "pending" UX states for unknown status.
4. **Security**: add cert pinning + jailbreak guard.

---

## Common Mistakes

- Computing balance on client.
- Token in MMKV plaintext.
- No idempotency key.
- Treating timeout as failure.
- Animating amounts (user can be tricked).

---

## Production Red Flags

- **Pending intents not persisted** → ghost duplicate charges.
- **No backoff on status polling** → server hammered.
- **Webhook + push as only sources** → silent failures when push lost.
- **Device attestation off in dev sneaks into prod**.

---

## Performance & Metrics (MANDATORY)

- Transfer initiate P95: < 1.5s
- Status reconcile P95: < 5s
- Login P95: < 2s
- Crash-free in money flows: > 99.9%
- Idempotent retry safe: 100% (test invariant)

---

## Metrics That Matter

- Transfer success rate
- Pending-resolution time
- Step-up success rate
- Token refresh failures
- Compromised-device blocks

---

## Decision Framework

| Concern | Pick |
|---|---|
| Card storage | tokenize via PSP |
| Biometric library | system biometric prompt |
| Cert pinning | yes (with backup pin) |
| Push role | hint only |
| Offline writes | usually no |

---

## Senior-Level Insight

The mature take: **fintech engineering is a culture of paranoia**. Every flow has an "unknown" state; every retry has an idempotency key; every animation hides nothing. Senior engineers also: (1) write a "money invariants" doc — what client must NEVER do; (2) add property tests for idempotency; (3) treat the secure design review as a release gate.

The 2026 specific: **passkeys** replacing passwords; **on-device fraud ML** for instant risk scoring; **regulatory privacy manifests** mandatory.

---

## Real-World Scenario

**Symptom:** Users complaining about double-deductions during peak.
**Investigation:** Server experienced timeouts under load; clients retried; idempotency key rotated per attempt.
**Root Cause:** Idempotency key generated per HTTP attempt instead of per logical operation.
**Fix:** Single key per operation; persist in MMKV before first attempt.
**Lesson:** Idempotency boundary = operation, not attempt.

---

## Production Failure Story

**Incident:** App update inadvertently turned off cert pinning in release build via misplaced flag.
**Impact:** Brief MITM exposure window; no exploitation detected, mandatory disclosure.
**Investigation:** Build flavor flag stripped pinning in release; CI didn't test.
**Root Cause:** No automated check that pinning is on in release artifacts.
**Fix:** Static check in CI for pinning config; runtime self-test on app start.
**Prevention:** Security configuration as code with mandatory tests.

---

## Debugging Checklist

1. Inspect `pending_intents` on launch.
2. Verify token TTL + refresh path.
3. Step-up assertion fresh per op?
4. Pinning cert valid + backup present?
5. Telemetry: status-unknown count, idempotency reuse rate.

---

## Advanced / Internal Knowledge

- Idempotency = (key, request hash) → result; server stores TTL ~24h.
- Webhook delivery: retry with backoff; client must handle out-of-order.
- DeviceCheck token = opaque; verify server-side only.
- Play Integrity attestation classes; verify standard signal at minimum.

---

## 2026 AI Tip

- AI is **good at**: idempotency wrapper, retry policy boilerplate.
- AI is **bad at**: crypto/security invariants — always have human security review.
- **Prompt pattern**: "Design transfer flow with idempotency, biometric step-up, status reconciliation, and offline reconcile-on-launch."

---

## Related Topics

- S10 auth/security
- S11 offline-first
- Q3 chat (idempotency parallel)

---

## Interview Follow-Up Questions

- Why never compute balance on client?
- What does "unknown" status mean and how do you handle it?
- Idempotency boundary — operation vs attempt?
- Step-up token: why short-lived?
- How do you handle device attestation failures?

---

## Memory Hook

**"Server-truth, client-control, idempotent always."**

## Revision Notes

> Server-authoritative ledger; client never computes money. Idempotency key per operation; persist before first attempt. Step-up biometric for sensitive ops. Token in Keychain. Cert pin + attestation + jailbreak guard. "Unknown" status is real; always reconcile.

---

---

### Q5. Design a video streaming app (Netflix/YouTube/Hotstar-style)

---

## Difficulty
- Expert

## Interview Frequency
- Common (media orgs)

## Prerequisites
- HLS/DASH, ABR, DRM, PiP, prefetch

## TL;DR
**HLS or DASH** with **ABR** (server picks variants by bandwidth + buffer). **DRM** (FairPlay iOS / Widevine Android) for protected content. **react-native-video** or **expo-video** as the player. **Pre-buffer** next episode + thumbnail strip; **PiP** + **background audio**; **Cast** support; **offline downloads** with DRM-bound license. Telemetry: bitrate, rebuffer count, startup time, watch progress.

---

## 30-Second Interview Answer

> "HLS or DASH with adaptive bitrate. Player is expo-video (or react-native-video) with native AVPlayer / ExoPlayer underneath. DRM via FairPlay (iOS) / Widevine (Android) — license fetched from license server, cached for offline. ABR picks variants by network class + buffer health. Pre-buffer next-episode preview to make 'autoplay-next' instant. PiP + background audio configured at native level. Offline downloads use HLS/DASH download API with DRM-bound license + expiry. Telemetry: startup time, rebuffer rate, average bitrate, watch position synced to server every 10s."

---

## 2-Minute Practical Answer

**Modules**:
- `player/` — expo-video / react-native-video wrapper, controls, gesture overlay.
- `drm/` — FairPlay/Widevine session, license cache.
- `download/` — offline manager, queue, DRM-bound license.
- `progress/` — watch position, sync.
- `cast/` — Chromecast/AirPlay handoff.
- `analytics/` — QoS metrics.

**Streaming basics**:
- HLS (Apple) / DASH (everywhere): manifest (`.m3u8` / `.mpd`) lists variants (resolutions/bitrates).
- Player chooses initial variant; switches based on throughput + buffer.
- Segments (~2–10s) downloaded incrementally.
- DRM: encrypted segments; license required to decrypt.

**Critical client decisions**:
- **Player**: native engines; React layer thin.
- **Initial variant**: too high → long startup; too low → bad first impression. Use connection class + heuristics.
- **ABR overrides**: user "Auto / Data Saver / High" toggle.
- **Pre-buffer**: 2 segments ahead minimum; up to 30s for stable playback.
- **Background**: configure audio session (iOS `AVAudioSession.Category = .playback`); foreground service (Android) for background playback.
- **PiP**: requires manifest config; iOS automatic on backgrounding video; Android explicit API.

**DRM**:
- **FairPlay** (iOS): SPC/CKC handshake; cert + content key.
- **Widevine** (Android): L1 (hardware) for HD/UHD; L3 (software) for SD only on most devices.
- License server: validates user entitlement; returns key + expiry.
- Persistent license for offline (limited duration, device-bound).

**Offline downloads**:
- HLS: `AVAssetDownloadURLSession` (iOS) / `ExoPlayer DownloadManager` (Android).
- License downloaded with persistent flag.
- Storage in user-visible "Downloads" UI with expiry shown.
- Auto-renew or warn before expiry if streaming.

**Telemetry (QoS)**:
- Startup time (tap → first frame).
- Rebuffer count + duration.
- Average bitrate.
- Variant switches per minute.
- Watch position (heartbeat every 10s + on pause/end).

**UI**:
- Skip-intro / next-up buttons.
- Subtitles + audio track selectors.
- Quality selector with "Auto" default.
- Brightness + volume gestures.

---

## 5-Minute Architecture Answer

```
   ┌──── Mobile App ────┐
   │  Player (native)   │ ◀─── HLS/DASH segments (encrypted)
   │  DRM session       │
   │  Download manager  │
   │  Analytics SDK     │
   └──┬─────┬───────────┘
      │     │ License req
      ▼     ▼
  ┌──────────────────┐    ┌──────────────────┐
  │ Origin / CDN     │    │ License server   │
  │ (segments + mfst)│    │ (FairPlay /      │
  │                  │    │  Widevine)       │
  └──────────────────┘    └──────────────────┘
      ▲
      │ Catalog / metadata API
      │
  ┌──────────────┐    ┌──────────────┐
  │ Catalog svc  │    │ Encoder /    │
  │ + Recs       │    │ Packager     │
  └──────────────┘    └──────────────┘
```

**Mobile-side flow**:
1. User taps title → fetch playback URL + license URL + DRM type.
2. Player initialized with manifest + DRM config.
3. Player fetches license; starts initial variant.
4. ABR adjusts as bandwidth changes.
5. Watch progress sent to server every 10s.
6. On pause/exit → final position saved.
7. On next launch → resume from saved position.

**Critical decisions**:
- **Manifest type**: HLS for everything (broader support); DASH for advanced features (multi-period, low-latency LL-DASH).
- **Pre-fetch**: only manifest + first segment of next-up to avoid wasted data.
- **DRM L1 vs L3**: L1 required for HD on Android (hardware-backed); fallback to SD on L3 devices.
- **Subtitles**: WebVTT side-loaded; render in player (native) for sync.
- **Casting**: integrate Cast SDK; handoff playback state.
- **Analytics**: send via lightweight SDK (Conviva, Mux, in-house).

**Failure modes**:
- **License fetch fail**: error; allow retry; show entitlement reason.
- **Network drop mid-playback**: buffer drains → pause → resume on reconnect.
- **DRM device-binding fail**: e.g., device root → block playback (or downgrade to SD).
- **Storage full during download**: pause; surface error.
- **Background audio rules**: iOS strict — must declare in Info.plist `UIBackgroundModes`.

**Scale considerations**:
- Server: CDN does heavy lifting; origin small. License server scales independently.
- Long-tail content costs more (cache misses); popular content is cheap.
- Live streams add latency budget (LL-HLS / LL-DASH for ~3s glass-to-glass).

The 2026 specific:
- **expo-video** (replacement for legacy expo-av) — first-class New Arch support.
- **HEVC / AV1** delivery for bandwidth efficiency.
- **DRM hardware paths** improving on iOS (Apple Silicon).
- **PiP + Live Activities** combined (iOS 17+).
- **Privacy Manifests** for analytics SDKs.
- **Apple TV companion app** via shared RN code.

---

## The "Why"

Streaming is a perception engine — every ms to first frame matters; rebuffers crater retention. Companies care because content delivery is their cost center and user experience driver simultaneously.

---

## Mental Model

Streaming app = **player + manifest + DRM + ABR + telemetry** — wrapped in UI sugar.

---

## Internal Working (2026 Context)

- HLS: m3u8 master + variant playlists; segments .ts or .mp4 (fMP4).
- DASH: .mpd; segments .m4s.
- ABR algorithms: BBA (buffer-based), throughput-based, hybrid.
- FairPlay: AES-128 with key wrapped in CKC.
- Widevine: CENC encryption; PSSH boxes in manifest.
- ExoPlayer / AVPlayer handle most of the above.

---

## Modern Implementation (Code)

**expo-video player**:
```tsx
import { useVideoPlayer, VideoView } from 'expo-video';

function Player({ src, license }: { src: string; license: string }) {
  const player = useVideoPlayer({
    uri: src,
    drm: { type: 'fairplay', licenseServer: license },
  }, (p) => {
    p.timeUpdateEventInterval = 10;
    p.addListener('timeUpdate', ({ currentTime }) => saveProgress(currentTime));
    p.play();
  });

  return (
    <VideoView
      player={player}
      style={{ flex: 1 }}
      allowsPictureInPicture
      contentFit="contain"
    />
  );
}
```

**Resume on launch**:
```ts
const lastPos = await api.progress(titleId);
player.currentTime = lastPos ?? 0;
```

**Offline download (Android, ExoPlayer via native module)**:
```ts
import { downloadVideo } from './native/Downloads';

await downloadVideo({
  url: hlsUrl,
  licenseUrl,
  variant: 'hd',
  onProgress: (pct) => updateUI(pct),
});
```

**Watch progress sync**:
```ts
let lastSent = 0;
function saveProgress(currentTime: number) {
  if (Math.abs(currentTime - lastSent) < 10) return;
  lastSent = currentTime;
  api.heartbeat({ titleId, position: currentTime }).catch(() => queueOffline({ titleId, position: currentTime }));
}
```

**iOS background audio (Info.plist)**:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

---

## Comparison

| | HLS | DASH |
|---|---|---|
| Origin | Apple | MPEG |
| iOS native | yes | partial |
| Android | via ExoPlayer | native ExoPlayer |
| Low latency | LL-HLS | LL-DASH |
| Subtitles | WebVTT | WebVTT, TTML |

| Player | Notes |
|---|---|
| expo-video | RN-friendly, active |
| react-native-video | mature, large community |
| Native (custom) | most control, most code |

---

## Production Usage

- **Netflix**: in-house DRM stack; aggressive ABR; pre-fetch.
- **YouTube**: DASH; super-aggressive ABR; QUIC delivery.
- **Hotstar**: HLS; LL-HLS for live cricket; massive scale.
- **Disney+**: AVPlayer + custom analytics.

---

## Hands-On Exercise

1. **Implementation**: HLS playback with expo-video.
2. **DRM**: integrate FairPlay license fetch.
3. **Offline**: download flow with persistent license + expiry.
4. **PiP**: enable + handle restore.

---

## Common Mistakes

- Wrong audio session category → no background playback.
- DRM device class fallback missing → playback fails on L3 devices instead of degrading.
- Over-aggressive pre-buffer on cellular → data complaints.
- Not throttling progress saves → backend storm.
- Cast handoff loses position.

---

## Production Red Flags

- **No QoS analytics** → can't tell if rebuffers happen.
- **License cached in plaintext** → security/business risk.
- **Player init on JS thread blocking** → cold-start jank.
- **Subtitles parsed in JS** → frame drops.

---

## Performance & Metrics (MANDATORY)

- Tap-to-first-frame: < 2s
- Rebuffer ratio: < 1%
- Variant switch P95: < 1s
- Download throughput utilization: > 80% on good network
- Battery / hour playback: budget based on device

---

## Metrics That Matter

- Startup time
- Rebuffer count + duration
- Average bitrate
- License success rate
- Watch completion %

---

## Decision Framework

| Concern | Pick |
|---|---|
| Player | expo-video (new arch) |
| Manifest | HLS unless specific need |
| DRM | FairPlay (iOS) + Widevine (Android) |
| Analytics | Mux / Conviva / in-house |

---

## Senior-Level Insight

The mature take: **streaming is 80% native player, 20% RN UI**. Don't rewrite the player; orchestrate it. Senior engineers also: (1) integrate QoS analytics from day one; (2) maintain a per-device matrix of DRM capability; (3) test on bad networks (Network Link Conditioner / Charles throttle).

The 2026 specific: **AV1 delivery** saves ~30% bandwidth; **expo-video** is the new default; **Live Activities** for live event presence.

---

## Real-World Scenario

**Symptom:** UHD playback fails on certain Android tablets.
**Investigation:** Devices report Widevine L3 (software-only); UHD requires L1.
**Root Cause:** No fallback to SD on L3; player throws.
**Fix:** Detect security level pre-playback; offer SD; send analytics for unsupported.
**Lesson:** Always degrade gracefully with DRM constraints.

---

## Production Failure Story

**Incident:** Live cricket stream had 30s+ glass-to-glass latency; users tweeted complaints during boundary moments.
**Impact:** Engagement drop; PR.
**Investigation:** Standard HLS with 6s segments + buffer.
**Root Cause:** Not using LL-HLS.
**Fix:** Migrate to LL-HLS with partial segments; latency dropped to ~5s.
**Prevention:** Latency budgeting per content type in product spec.

---

## Debugging Checklist

1. Player error logs (native side).
2. License success/failure rates.
3. Buffer health time series.
4. Variant switch trace.
5. Background mode config (iOS / Android).

---

## Advanced / Internal Knowledge

- HLS interstitials for ad insertion (X-ASSET-URI tag).
- Server-Side Ad Insertion (SSAI) vs Client-Side (CSAI).
- LL-HLS uses partial segments + blocking playlist requests.
- DASH multi-period supports seamless ad/content stitching.
- Common Media Application Format (CMAF) unifies HLS+DASH segment formats.

---

## 2026 AI Tip

- AI is **good at**: player wrapper, controls UI.
- AI is **bad at**: DRM nuances and device matrix.
- **Prompt pattern**: "Build expo-video player with HLS+FairPlay/Widevine, ABR, PiP, background audio, and offline downloads with persistent license."

---

## Related Topics

- S7 performance
- S9 networking (CDN, throughput)
- S15 native modules

---

## Interview Follow-Up Questions

- HLS vs DASH — when to pick?
- L1 vs L3 Widevine — implications?
- How do you measure QoS?
- Background playback on iOS — what's required?
- LL-HLS — how does it cut latency?

---

## Memory Hook

**"Native player + manifest + DRM + telemetry."**

## Revision Notes

> HLS/DASH with ABR; FairPlay+Widevine for DRM. Player is native (expo-video / react-native-video). Pre-buffer next; PiP + background audio configured at native. Offline = persistent license. QoS analytics mandatory. Degrade gracefully on DRM constraints.

---

> **End of S22.** Next deep section per priority: [S05 Expo & Tooling](S05-expo-tooling.md). Cross-refs throughout point to the relevant deep sections in S7/S9/S10/S11/S15/S16.
