# MASTER INTERVIEW GUIDE 2026 — Senior / Lead React Native (Rajeev, 9+ YOE, target ₹40+ LPA)

> **Single source of truth.** Built from your `study/` folder + archived PDFs in `Study-Pre/archive/`, deduped, organized by interview frequency, scoped to Tier S/A India loops (PhonePe, CRED, Razorpay, Groww, Zerodha, Swiggy, Flipkart, Microsoft, Walmart, Atlassian, Coinbase, Booking, etc.).
>
> **How to use:** read top-to-bottom once. Then revise by topic. Every section ends with **"Must-answer questions"** — if you can answer those out loud in 60 seconds, you're ready for that topic.

---

## Table of Contents

1. [Profile positioning + numbers](#1-profile-positioning--numbers)
2. [JavaScript core](#2-javascript-core)
3. [TypeScript for senior RN](#3-typescript-for-senior-rn)
4. [React deep dive](#4-react-deep-dive)
5. [React Native architecture (old + new)](#5-react-native-architecture-old--new)
6. [Hermes, Metro, bundle, startup](#6-hermes-metro-bundle-startup)
7. [Performance: lists, animations, images, memory](#7-performance-lists-animations-images-memory)
8. [Native modules (Swift + Kotlin)](#8-native-modules-swift--kotlin)
9. [Debugging toolkit](#9-debugging-toolkit)
10. [State management](#10-state-management)
11. [Navigation + deep linking](#11-navigation--deep-linking)
12. [Networking, REST, GraphQL, WebSockets](#12-networking-rest-graphql-websockets)
13. [Auth, sessions, tokens](#13-auth-sessions-tokens)
14. [Offline-first + storage](#14-offline-first--storage)
15. [Push notifications](#15-push-notifications)
16. [Mobile security (fintech-critical)](#16-mobile-security-fintech-critical)
17. [Accessibility (a11y), color, fonts, i18n](#17-accessibility-a11y-color-fonts-i18n)
18. [Testing strategy](#18-testing-strategy)
19. [CI/CD, EAS, Fastlane, releases](#19-cicd-eas-fastlane-releases)
20. [Observability: Sentry, Crashlytics, analytics](#20-observability-sentry-crashlytics-analytics)
21. [Mobile system design](#21-mobile-system-design)
22. [DSA must-knows](#22-dsa-must-knows)
23. [Behavioral + leadership (STAR)](#23-behavioral--leadership-star)
24. [Resume, LinkedIn, applications, negotiation](#24-resume-linkedin-applications-negotiation)
25. [Last-mile cheatsheet](#25-last-mile-cheatsheet)

---

## 1. Profile positioning + numbers

**One-liner**: `Senior Mobile / RN Tech Lead, 9+ YOE, fintech depth (LetsVenture), end-to-end Android+iOS ownership, auth + payments + deep linking + observability.`

**Target roles**: Senior RN Engineer (IC4/SDE-3) → Lead RN Developer → Mobile Tech Lead → Fintech Mobile Lead.

**Comp targets (Bengaluru, 2026)**: ₹40+ LPA floor, ₹45–55 LPA target, ₹55–70 LPA stretch with competing offers. Anchor recruiter at ₹48–55 LPA fixed. Never disclose ₹23 LPA early — say *"low-20s fixed; evaluating ₹45–55 LPA band based on scope"*.

**Top-20 targets**: PhonePe, Razorpay, CRED, Groww, Zerodha, Jupiter, Slice, Freecharge / Swiggy, Zomato, Flipkart, Meesho, Dream11, PharmEasy / Microsoft, Walmart, Atlassian, Coinbase, Booking, Postman/Zeta. Full breakdown: [job-market-2026-top20-plan.md](job-market-2026-top20-plan.md).

---

## 2. JavaScript core

### Basics
- **Execution context, hoisting, scope chain**: `var` is function-scoped + hoisted with `undefined`; `let`/`const` are block-scoped + in TDZ until declaration.
- **Primitive vs reference**: numbers/strings/bool/null/undefined/symbol/bigint copied by value; objects/arrays/functions by reference.
- **`==` vs `===`**: never use `==`. `null == undefined` is the one trap.
- **`this` binding**: default (global/undefined in strict), implicit (`obj.fn()`), explicit (`call`/`apply`/`bind`), `new`, arrow (lexical — does NOT bind `this`).

### Closures (asked in 80%+ of loops)
A function "remembers" the scope it was created in.
```js
function makeCounter() { let n = 0; return () => ++n; }
const c = makeCounter(); c(); c(); // 2
```
**Stale closure trap in RN**:
```js
useEffect(() => {
  const id = setInterval(() => setCount(count + 1), 1000); // stale!
  return () => clearInterval(id);
}, []); // count frozen at initial value
// Fix: use functional update setCount(c => c + 1) OR add count to deps
```

### Async + event loop
- **Stack → microtasks (Promise.then, queueMicrotask) → macrotasks (setTimeout, setInterval, I/O) → render frame**
- All microtasks drain before next macrotask.
- `async/await` is just sugar over Promises.

```js
console.log(1);
setTimeout(() => console.log(2), 0);
Promise.resolve().then(() => console.log(3));
console.log(4);
// 1, 4, 3, 2
```

**Promise utilities**:
- `Promise.all` — fail fast on first rejection
- `Promise.allSettled` — wait for all, never rejects
- `Promise.race` — first to settle
- `Promise.any` — first to fulfill (ignores rejections)

**Concurrency-limited fetch** (asked in Razorpay/PhonePe):
```js
async function pLimit(items, limit, fn) {
  const results = []; const executing = [];
  for (const item of items) {
    const p = Promise.resolve().then(() => fn(item));
    results.push(p);
    if (limit <= items.length) {
      const e = p.then(() => executing.splice(executing.indexOf(e), 1));
      executing.push(e);
      if (executing.length >= limit) await Promise.race(executing);
    }
  }
  return Promise.all(results);
}
```

### Memory + GC
- Mark-and-sweep. Leaks = lingering references (timers, listeners, closures over big objects, navigation refs).

### Must-answer questions
1. Stale closure in `useEffect` — show + fix.
2. Output of `console.log + setTimeout + Promise.then` interleave.
3. `Promise.all` vs `allSettled` — when each.
4. Implement `pLimit(n)` and `retry(fn, n, delay)`.
5. Why arrow function doesn't bind `this`.

---

## 3. TypeScript for senior RN

### Must-know
- `type` vs `interface`: interface is extendable + merge-able; type does unions/intersections/mapped. Use interface for object shapes, type for unions.
- **Generics**: `function identity<T>(x: T): T`. Constraints: `<T extends { id: string }>`.
- **Utility types**: `Partial`, `Required`, `Pick<T,K>`, `Omit<T,K>`, `Record<K,V>`, `Readonly`, `ReturnType<typeof f>`, `Parameters<typeof f>`, `Awaited<P>`, `NonNullable`.
- **Discriminated unions** (the most useful pattern):
  ```ts
  type Result<T> = { ok: true; data: T } | { ok: false; error: string };
  if (r.ok) r.data; else r.error; // narrowed
  ```
- **Type guards**: `typeof`, `instanceof`, `in`, custom `function isUser(x): x is User`.
- **`as const`**: `const tabs = ['home','profile'] as const;` → readonly tuple of literals.
- **`unknown` > `any`**: `unknown` forces narrowing; `any` disables checks. Use `never` for exhaustiveness.

### Typing RN navigation (asked often)
```ts
type RootStackParamList = {
  Home: undefined;
  Profile: { userId: string };
  Payment: { orderId: string; amount: number };
};
type Props = NativeStackScreenProps<RootStackParamList, 'Payment'>;
```

### Typing API responses with Zod (runtime + compile)
```ts
const User = z.object({ id: z.string(), name: z.string() });
type User = z.infer<typeof User>;
const data = User.parse(await res.json()); // throws on shape mismatch
```

### Must-answer questions
1. `type` vs `interface` — when to use which.
2. Write a generic `useFetch<T>` hook.
3. Discriminated union for API result.
4. `unknown` vs `any` vs `never`.
5. End-to-end typed React Navigation.

---

## 4. React deep dive

### Render model
- React schedules render → reconciler diffs new vs old fiber tree → commits to host (Fabric in RN).
- A component re-renders when: state changes, parent re-renders, or context value changes.
- **Keys**: stable, unique, NOT array index for dynamic lists.

### Hooks (must know cold)
| Hook | Use | Gotcha |
|---|---|---|
| `useState` | local state | functional update for stale closures |
| `useEffect` | side effects after paint | missing deps = stale closures; cleanup function |
| `useLayoutEffect` | sync before paint | rare in RN; use for measurements |
| `useRef` | mutable box, no re-render | doesn't trigger updates |
| `useMemo` | memoize value | only if expensive |
| `useCallback` | memoize fn ref | only if passed to memoized child |
| `useContext` | consume context | re-renders all consumers on value change |
| `useReducer` | complex local state | predictable updates |

### Performance
- **`React.memo(Comp)`** — skips re-render if props shallow-equal. Breaks if parent passes inline `{}` or `() => {}`.
- **Context split**: separate state context from dispatch context to avoid full-tree re-renders.
- **Selector pattern** (Zustand-style): subscribe to slice of state.
- **`useTransition` / `useDeferredValue`**: mark non-urgent updates.

### Stale closure (asked everywhere)
```js
function Chat() {
  const [msgs, setMsgs] = useState([]);
  useEffect(() => {
    socket.on('msg', m => setMsgs([...msgs, m])); // stale!
  }, []); // msgs frozen
  // Fix: setMsgs(prev => [...prev, m])
}
```

### Lifecycle in hook terms
- `componentDidMount` → `useEffect(fn, [])`
- `componentDidUpdate` → `useEffect(fn, [deps])`
- `componentWillUnmount` → cleanup return of `useEffect`
- `getDerivedStateFromProps` → derive in render or `useMemo`

### Suspense + error boundaries
- Error boundaries are still class components (`componentDidCatch`).
- Suspense for code-split lazy components.

### Must-answer questions
1. Stale closure — show + fix.
2. Why `React.memo` doesn't always help.
3. How Context causes wide re-renders + the fix.
4. `useMemo` vs `useCallback`.
5. `useLayoutEffect` vs `useEffect`.
6. Class lifecycle → hook equivalents.

---

## 5. React Native architecture (old + new)

### What RN is
- Renders **real native UI** (UIView/ViewGroup), not WebView.
- JS runs in Hermes (default) or JSC, separate from main thread.
- Three threads (old arch): **JS thread** (your code), **UI/main thread** (touch + render), **Shadow thread** (Yoga layout).

### Old bridge
- Async, batched, JSON-serialized message passing JS↔native.
- Slow for high-frequency calls (gestures, animations).

### New Architecture (asked in 90% of senior loops)
- **JSI (JavaScript Interface)**: C++ layer letting JS hold references to native (host) objects, call methods synchronously without serialization. Foundation for everything below.
- **Fabric**: new renderer. Synchronous layout possible, concurrent React features, better priority scheduling. Replaces UIManager.
- **TurboModules**: lazy-loaded native modules accessed via JSI. Replaces NativeModule. Type-safe via Codegen.
- **Codegen**: TypeScript spec file → C++/ObjC/Java boilerplate generated at build time. Eliminates runtime type checks.

### Why it matters
- Cold start: TurboModules load on demand (not all at boot).
- Animations: Reanimated 3 worklets run on UI thread via JSI.
- Cross-boundary calls: synchronous when needed.

### Migration gotchas
- Some libraries still on old arch — check compatibility.
- iOS: `RCT_NEW_ARCH_ENABLED=1` in Podfile.
- Android: `newArchEnabled=true` in `gradle.properties`.

### Must-answer questions (the ones that show up)
1. Walk me through `npx react-native run-ios` → app on screen.
2. Old bridge vs JSI — explain to a junior in 90 sec.
3. What is Fabric? What does it improve?
4. TurboModule vs NativeModule.
5. What is Codegen and why does it matter?
6. How does Reanimated 3 use JSI?

---

## 6. Hermes, Metro, bundle, startup

### Hermes
- AOT-compiled bytecode (vs JSC's interpreter + JIT).
- Faster startup, lower memory, smaller heap.
- Sampling profiler built in.
- Default since RN 0.70+.

### Metro
- RN's bundler (Webpack-equivalent).
- Resolves, transforms (Babel), and serves bundle to device.
- `inlineRequires: true` defers `require()` until first use → faster startup.
- RAM bundles (legacy) split bundle for lazy load.

### Cold start anatomy
```
native init → load JS bundle → parse → execute root → first render → first interaction
```
Each phase is measurable.

### Reduce cold start (the answer they want)
1. Enable Hermes.
2. `inlineRequires` + lazy import heavy screens.
3. Defer SDK init (Sentry, analytics, push) post first paint.
4. TurboModules (lazy native modules).
5. Smaller bundle (tree-shake, drop unused libs).
6. Hermes bundle (`hermesc`) prebuilt.
7. iOS: shrink launch storyboard work.
8. Android: enable R8/ProGuard, baseline profiles.

### App size levers
- Hermes (smaller than JSC).
- ProGuard/R8 (Android).
- Asset compression (WebP, AVIF, vector icons).
- Code splitting (rare in RN; use lazy screens).
- Strip unused locales.

### Must-answer questions
1. Why is Hermes faster?
2. Reduce 4s cold start to <2s — your plan.
3. What does `inlineRequires` do?
4. How do you measure cold start?
5. Top 3 levers to shrink IPA/APK.

---

## 7. Performance: lists, animations, images, memory

### Lists
| Tool | When |
|---|---|
| `ScrollView` | Small fixed content (<10 items) |
| `FlatList` | Default for any list |
| `SectionList` | Grouped lists |
| `FlashList` (Shopify) | Heavy rows, infinite feeds, perf-critical |

**FlatList tuning**:
- Stable `keyExtractor` (id, never index).
- `getItemLayout` if rows are fixed-height (skips measurement).
- `removeClippedSubviews` (Android wins).
- `initialNumToRender`, `maxToRenderPerBatch`, `windowSize` tuned to row size.
- Memoized row component (`React.memo` + stable callbacks).

**FlashList wins**:
- Recycles views like RecyclerView/UITableView.
- Predictable FPS for complex rows.
- `estimatedItemSize` is required.

### Animations
- **Reanimated 3 worklets**: run on UI thread via JSI; 60 FPS even when JS is busy.
- **Gesture Handler**: native gestures, no bridge round-trip.
- **`useAnimatedStyle`, `useSharedValue`, `withTiming`, `withSpring`**.
- `runOnJS` to call back into JS thread; `runOnUI` to enter worklet.
- Avoid `Animated` (legacy) for new perf-critical work.

### Images
- `expo-image` (default in 2026) or `FastImage`.
- Right-size on server, not client.
- Cache aggressively, prefetch above-the-fold.
- WebP/AVIF for size; PNG only for transparency cases.

### Memory leaks (top causes)
1. `setInterval`/`setTimeout` not cleared.
2. Event listeners not removed (`AppState`, `Keyboard`, sockets).
3. Navigation refs held in module scope.
4. Large arrays/blobs in closures.
5. Subscriptions to streams without cleanup.

**Detect**: Xcode Allocations + Leaks instrument; Android Studio Memory Profiler; React DevTools Profiler.

### Frame drops debug flow
1. Reproduce consistently.
2. Identify thread: JS jank vs UI jank vs render jank.
3. Hermes sampling profiler → JS hot spots.
4. Systrace/Perfetto (Android) or Time Profiler (iOS) → native side.
5. Fix highest-cost path; re-measure.

### Must-answer questions
1. FlatList → FlashList — when and why.
2. Fix scroll jank in a feed — your steps.
3. Why Reanimated worklets are faster than `Animated`.
4. Memory leak — find + fix flow.
5. Image pipeline best practices.

---

## 8. Native modules (Swift + Kotlin)

### When to write your own
- No community module exists.
- Existing one is unmaintained or missing platform.
- Need access to a private/new platform API.
- Performance-sensitive bridge crossing.

### Old NativeModule pattern (still asked)
**iOS (Swift)**:
```swift
@objc(BatteryModule)
class BatteryModule: NSObject {
  @objc func getLevel(_ resolve: @escaping RCTPromiseResolveBlock,
                      reject: @escaping RCTPromiseRejectBlock) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    resolve(UIDevice.current.batteryLevel)
  }
  @objc static func requiresMainQueueSetup() -> Bool { return false }
}
```
Plus an `.m` file with `RCT_EXTERN_MODULE` + `RCT_EXTERN_METHOD`.

**Android (Kotlin)**:
```kotlin
class BatteryModule(ctx: ReactApplicationContext): ReactContextBaseJavaModule(ctx) {
  override fun getName() = "BatteryModule"
  @ReactMethod
  fun getLevel(promise: Promise) {
    val bm = reactApplicationContext.getSystemService(BATTERY_SERVICE) as BatteryManager
    promise.resolve(bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY))
  }
}
```
Register in a `ReactPackage`.

### TurboModule (new arch)
- Define TS spec → Codegen produces C++/ObjC/Java interfaces.
- Implement the generated protocol/interface.
- Lazy-loaded via JSI on first JS access.

### Threading
- iOS: by default runs on a serial background queue; override `methodQueue` for main thread.
- Android: runs on the native modules thread; use `UiThreadUtil.runOnUiThread` for UI work.

### Return patterns
- **Promise**: `resolve(...)` / `reject(...)`.
- **Callback**: legacy; one-shot.
- **Event Emitter** (`RCTEventEmitter` / `DeviceEventManagerModule`): for streams/subscriptions.

### Must-answer questions
1. When to write a native module instead of using a community one.
2. Walk through writing a battery module on both platforms.
3. How to emit events native → JS.
4. Threading — what runs where, by default.
5. Promise vs callback vs event emitter — when each.

---

## 9. Debugging toolkit

### Tools (know what each is for)
| Tool | Use |
|---|---|
| **React Native DevTools** (RN 0.76+) | New default debugger; console, sources, profiler |
| **Hermes Inspector** (Chrome DevTools) | Step debug Hermes, sampling profiler |
| **Flipper** (legacy) | Old default; mention migration to RN DevTools |
| **Reactotron** | State, network, action log inspection |
| **Xcode Instruments** | Time Profiler, Allocations, Leaks, Network, Energy |
| **Android Studio Profiler** | CPU, Memory, Network, Energy |
| **Perfetto / Systrace** | Native trace, ANR analysis (Android) |
| **LayoutInspector** (Android) / View Hierarchy (Xcode) | UI tree |
| **Charles Proxy / Proxyman / mitmproxy** | Network inspect, cert pinning bypass in dev |
| **adb logcat** | Android logs |
| **`xcrun simctl` / `idb`** | iOS sim control |
| **Sentry** | Crashes, breadcrumbs, sourcemaps, release health |
| **Crashlytics** | Crash stack traces |

### Crash symbolication
- **iOS**: dSYM file (Xcode build output) → `atos` or upload to Sentry → readable stack.
- **Android**: ProGuard/R8 mapping file → `retrace` or upload to Sentry/Crashlytics.
- **JS**: source maps uploaded to Sentry → original file:line:col.
- **Native crash via NDK**: `ndk-stack` with mapping.

### ANR (Android) debug
- Caused by main thread blocked >5s (or 10s for broadcast).
- Perfetto trace → find blocking call.
- Common: heavy work on main, network on main, lock contention, DB query on main.

### Network bug repro
1. Reproduce on device.
2. Charles/Proxyman → see actual request/response.
3. If pinned: dev build with pinning bypass.
4. Check headers, body, status, retry.
5. If only on prod: enable Sentry network breadcrumbs + add backend logs.

### Memory leak hunt (iOS)
1. Instruments → Allocations.
2. Mark generation, exercise feature, mark again.
3. Inspect persistent allocations between marks.
4. Leaks instrument for retain cycles.

### Memory leak hunt (Android)
1. Android Studio Profiler → Memory.
2. Force GC, take heap dump.
3. Look for unexpectedly retained activities/fragments.
4. LeakCanary in dev build.

### Must-answer questions (one rehearsed story per scenario)
1. Walk me through debugging a Sentry crash → root cause.
2. Slow on Android low-end devices — your plan.
3. Memory leak — tool + steps + fix.
4. Network bug only on prod — repro + debug.
5. ANR on Android — causes, tools, fix.

---

## 10. State management

### The 3-bucket model
| Bucket | What | Tool |
|---|---|---|
| **Local UI state** | toggle, form, modal | `useState`, `useReducer` |
| **Global client state** | auth, theme, feature flags | Zustand / RTK |
| **Server state** | API data, cache, mutations | React Query / TanStack Query |

### Redux Toolkit
- `createSlice` for reducers + actions.
- `createAsyncThunk` for async, or use **RTK Query** for fetching/caching.
- Middleware: logger, sentry, analytics.
- Use when team needs structure, traceability, devtools.

### Zustand
- Tiny, no boilerplate. Selector-based subscriptions = no wide re-renders.
- `persist` middleware with MMKV for offline.
```js
const useAuth = create(persist((set) => ({
  user: null,
  login: (u) => set({ user: u }),
}), { name: 'auth', storage: createJSONStorage(() => mmkvStorage) }));
```

### React Query
- `staleTime` — how long data is "fresh" (no refetch).
- `cacheTime` (now `gcTime`) — how long unused data lingers.
- `useMutation` with `onMutate` for optimistic updates + `onError` rollback.
- `queryClient.invalidateQueries` for cache busting after mutations.

### Optimistic update pattern
```js
useMutation({
  mutationFn: updateTodo,
  onMutate: async (newTodo) => {
    await qc.cancelQueries(['todos']);
    const prev = qc.getQueryData(['todos']);
    qc.setQueryData(['todos'], old => [...old, newTodo]);
    return { prev };
  },
  onError: (e, v, ctx) => qc.setQueryData(['todos'], ctx.prev),
  onSettled: () => qc.invalidateQueries(['todos']),
});
```

### Must-answer questions
1. RTK vs Zustand vs React Query — when each.
2. `staleTime` vs `cacheTime`.
3. Optimistic update with rollback.
4. Why Context fails for high-frequency updates.
5. Persisting Redux/Zustand with MMKV.

---

## 11. Navigation + deep linking

### React Navigation
- **Native Stack** (`@react-navigation/native-stack`) — uses iOS/Android native nav, fast.
- **JS Stack** (`@react-navigation/stack`) — fully JS; more customizable, slightly slower.
- **Tab**, **Drawer**, **Material Top Tabs**.
- **Nested navigators** for tabs-inside-stack patterns.

### Expo Router
- File-based routing on top of React Navigation.
- Typed routes via `expo-router/typed-routes`.

### Deep linking
- **URL scheme**: `myapp://order/123` (universal but weak — no domain ownership).
- **iOS Universal Links**: `apple-app-site-association` file on `https://yourdomain/.well-known/`.
- **Android App Links**: `assetlinks.json` + verified domain in manifest.
- **Branch.io**: deferred deep linking (works even pre-install — attribution chain).
- **Firebase Dynamic Links** — deprecated 2025; migrate to Branch or self-host.

### Auth-gated navigation
```js
function Root() {
  const user = useAuth(s => s.user);
  return user ? <AppStack /> : <AuthStack />;
}
```
Avoid imperatively pushing/replacing — let conditional rendering swap navigators.

### Typed params (TS)
```ts
type Stack = { Order: { id: string } };
const Nav = createNativeStackNavigator<Stack>();
function Order({ route }: NativeStackScreenProps<Stack, 'Order'>) {
  route.params.id; // typed
}
```

### Must-answer questions
1. Native Stack vs JS Stack.
2. Universal Links + App Links setup.
3. How Branch deferred deep links work.
4. Auth-gate routing pattern.
5. Type-safe params end-to-end.

---

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

## 13. Auth, sessions, tokens

### OAuth 2.0 + PKCE (mobile-correct flow)
1. App generates `code_verifier` + `code_challenge`.
2. Open browser/AuthSession → user logs in → redirect with `code`.
3. Exchange `code` + `code_verifier` for tokens.
4. Store tokens in Keychain/Keystore.

### Tokens
- **Access token**: short-lived (5–60 min), JWT, sent as `Authorization: Bearer`.
- **Refresh token**: longer-lived, opaque, **rotate on every use** (refresh rotation).
- Never put refresh in JS memory longer than needed; never log.

### Auth0 / Cognito (your stack)
- Auth0: hosted login, social, MFA, rules/actions.
- Cognito: AWS-native, integrates with API Gateway, has user pools + identity pools.

### Biometric gating
- `expo-local-authentication` or `react-native-keychain` with biometric prompt.
- Gate on app foreground after timeout, before sensitive screens.

### Must-answer questions
1. OAuth PKCE flow on mobile.
2. Refresh token rotation — why.
3. Where to store tokens (Keychain/Keystore, not AsyncStorage).
4. Biometric session timeout pattern.
5. Logout — what to clear.

---

## 14. Offline-first + storage

### Storage choices
| Tool | Use |
|---|---|
| **MMKV** | Fast key-value, sync, encrypted. AsyncStorage replacement. |
| **SQLite** (`react-native-quick-sqlite`) | Relational, queryable. |
| **WatermelonDB** | Lazy-loaded reactive DB on top of SQLite. |
| **Realm** | Object DB with sync (paid). |
| **expo-secure-store** | Tiny secure values (tokens). |

### Outbox pattern (offline writes)
1. User action → write to local DB + enqueue in outbox table.
2. UI reads from local DB (optimistic).
3. Background sync drains outbox to server.
4. On success → mark synced; on failure → retry with backoff.
5. Conflict → last-write-wins or server-side merge.

### Sync strategies
- **Pull** (poll on foreground/interval).
- **Push** (server pushes via WebSocket/SSE).
- **Hybrid** (push for live + pull on resume).

### Conflict resolution
- LWW (last-write-wins) — simple, lossy.
- Vector clocks / CRDT — advanced (mention only if asked).
- Server-side merge with version field.

### NetInfo
- `@react-native-community/netinfo` for connectivity changes.
- Don't trust "online" — try the actual request.

### Must-answer questions
1. Design offline-first transaction list.
2. Outbox pattern walkthrough.
3. MMKV vs AsyncStorage — why switch.
4. Conflict resolution options.
5. App killed mid-sync — recovery.

---

## 15. Push notifications

### iOS (APNs)
- Capability + entitlement + provisioning profile.
- Token generated by APNs, sent to your backend.
- **Notification Service Extension** for rich content (modify payload before display).
- **Notification Content Extension** for custom UI.
- Silent push: `content-available: 1` for background fetch (limited frequency).

### Android (FCM)
- Token from FCM, sent to backend.
- Channels (Android 8+) — required, set importance.
- Foreground notifications need explicit handler (not shown by default).

### Common stack
- **Expo Notifications** (wraps both) or **Notifee** (more control).
- Backend: send to FCM/APNs directly or via Firebase Cloud Messaging unified.

### Token lifecycle
- Refresh on app start; sync to backend; clear on logout.

### Deep link from notification
- Tap → cold start → read launch payload → navigate.
- Tap (background) → foreground → handle in listener → navigate.

### Must-answer questions
1. APNs vs FCM setup at high level.
2. Silent push use cases + limits.
3. Rich notification on iOS (NSE).
4. Token refresh + backend sync.
5. Deep link from notification cold-start flow.

---

## 16. Mobile security (fintech-critical)

### OWASP MASVS L1 vs L2 (know the headlines)
- **L1**: standard hygiene — secure storage, TLS, no debug enabled in prod, no hardcoded secrets.
- **L2**: defense in depth — cert pinning, anti-tampering, jailbreak/root detection, obfuscation (R8), runtime integrity checks (RASP).

### Secure storage
- **iOS**: Keychain (`react-native-keychain`).
- **Android**: EncryptedSharedPreferences or Keystore-backed.
- Never AsyncStorage for tokens/PII.

### Cert pinning
- Pin server cert or public key.
- **Have a rotation strategy**: pin both current + next cert; expire old after rotation.
- iOS: `NSAppTransportSecurity` + URLSession delegate / `react-native-ssl-pinning`.
- Android: Network Security Config XML.

### Jailbreak / root detection
- `jail-monkey` library.
- Heuristics: known files, mounted paths, suspect packages.
- Don't hard-block — warn + degrade (e.g., disable payments).

### iOS Privacy Manifest (`PrivacyInfo.xcprivacy`)
- Required since 2024 for App Store.
- Declare data collected + reasons + tracking domains.

### Android privacy
- Play Console Data Safety form.
- Permissions justification.
- Foreground service types (Android 14+).

### Anti-patterns
- Logging tokens / PII to Sentry/console.
- Storing PII in analytics events.
- Deep links accepting unsigned intents (intent redirection).
- WebView with `javaScriptEnabled` + untrusted URL.

### PCI-DSS basics (fintech mention)
- Don't store full PAN on device.
- Use payment SDK (Razorpay/Cashfree) — they handle PCI scope.
- Tokenized cards only.

### Must-answer questions
1. Secure token storage end-to-end.
2. Cert pinning + rotation.
3. Jailbreak/root — detect + react.
4. MASVS L2 highlights.
5. PII hygiene in logs/analytics.

---

## 17. Accessibility (a11y), color, fonts, i18n

> Heavily asked at Microsoft, Walmart, Atlassian, Booking. Differentiator at fintechs.

### Accessibility (a11y)
- **Roles**: `accessibilityRole="button"` (also `link`, `header`, `image`, `text`, `summary`, `adjustable`).
- **Labels**: `accessibilityLabel` (screen reader reads this), `accessibilityHint` (extra context).
- **State**: `accessibilityState={{ disabled, selected, checked, busy, expanded }}`.
- **Live regions**: `accessibilityLiveRegion="polite" | "assertive"` (Android) and `AccessibilityInfo.announceForAccessibility(msg)` (cross-platform).
- **Focus management**: `findNodeHandle` + `AccessibilityInfo.setAccessibilityFocus(handle)` after navigation.
- **Touch target**: min **44×44pt** (iOS HIG) / **48×48dp** (Android Material). Use `hitSlop` for small icons.
- **Group decorative children**: `accessible={true}` on parent, `accessibilityElementsHidden={true}` on iOS for decorative; `importantForAccessibility="no-hide-descendants"` on Android.
- **Reduce motion**: respect `AccessibilityInfo.isReduceMotionEnabled()` — disable parallax/large transitions.
- **Screen readers**: VoiceOver (iOS), TalkBack (Android). Test with both.

### Color + contrast
- **WCAG 2.2 AA**: contrast **≥ 4.5:1** for normal text, **≥ 3:1** for large text (≥18pt or 14pt bold) and UI components.
- **WCAG AAA**: 7:1 normal, 4.5:1 large.
- Tools: Stark, Figma plugins, browser DevTools contrast checker.
- **Never use color alone** to convey meaning (red=bad, green=good fails for ~8% of men with red-green color blindness).

### Color blindness (deuteranopia, protanopia, tritanopia)
- ~8% of men, ~0.5% of women.
- Pair color with **icon + label + pattern**.
  - ✅ Error: red border + ❌ icon + "Error" text
  - ❌ Just red border
- Test with simulators: Sim Daltonism (macOS), Color Oracle (cross-platform), iOS accessibility filters (Settings → Accessibility → Display & Text Size → Color Filters).
- Avoid problem combos: red/green, green/brown, blue/purple, light blue/pink.
- Charts: use distinct hues + patterns + labels.

### Dark mode
- `useColorScheme()` from RN.
- Define color tokens (semantic: `text.primary`, `bg.surface`) not raw hex.
- Test both modes for contrast.
- Status bar: switch `barStyle` per scheme.

### Fonts + typography
- **System fonts** load instantly; custom fonts add startup cost.
- **Custom fonts**:
  - iOS: add to bundle, list in `Info.plist` (`UIAppFonts`).
  - Android: place in `android/app/src/main/assets/fonts/`.
  - Or Expo Font: `useFonts({ Inter: require('./Inter.ttf') })` — async, gate render.
- **Variable fonts** (Inter, Roboto Flex) — single file, multiple weights, smaller total size.
- **Font scaling (Dynamic Type)**:
  - iOS respects user font size by default.
  - Cap with `allowFontScaling={false}` ONLY if it breaks layout — better to make layout flexible.
  - `maxFontSizeMultiplier={1.5}` is a sane cap.
- **Line height**: 1.4–1.6× font size for body text.
- **Letter spacing**: tighter for headings (-0.5px), looser for ALL CAPS (+1px).
- **Hierarchy**: limit to 4–5 sizes (e.g., 32 / 24 / 18 / 16 / 14 / 12).

### Internationalization (i18n)
- **`i18next` + `react-i18next`** is the de-facto stack.
- `expo-localization` for device locale + timezone.
- **RTL** (Arabic, Hebrew): `I18nManager.forceRTL(true)` requires app reload; design with logical properties (`marginStart` not `marginLeft`).
- **Pluralization**: ICU MessageFormat (`{count, plural, one {# item} other {# items}}`).
- **Number/date/currency**: `Intl.NumberFormat`, `Intl.DateTimeFormat` (Hermes 0.74+ supports full Intl).
- Don't concatenate strings — use placeholders. Word order varies per language.

### Must-answer questions
1. How do you make a button accessible to screen readers?
2. WCAG AA contrast minimums.
3. Designing for color blindness — examples.
4. Dynamic Type / font scaling — when to cap.
5. RTL support — what changes in code.
6. Loading custom fonts in RN — iOS + Android steps.

---

## 18. Testing strategy

### Test pyramid (mobile)
```
       ▲ E2E (Detox / Maestro) — few, critical flows
      ▲▲ Integration / component (RNTL)
     ▲▲▲ Unit (Jest) — pure logic, hooks
```

### Jest
- Snapshot tests sparingly — high churn.
- Mock native modules: `jest.mock('react-native-keychain', () => ({...}))`.
- Use `jest.useFakeTimers()` for async.

### React Native Testing Library (RNTL)
- Query by accessibility role/label (forces a11y too).
- `userEvent` for realistic interactions.
- Wrap in `QueryClientProvider`, `NavigationContainer`, theme provider.

### Detox
- Gray-box E2E (knows app internals).
- Synchronization: waits for animations/network automatically.
- Flake reduction: avoid `waitFor(timeout)`; use idle sync.

### Maestro (newer, simpler)
- YAML flows, no code needed.
- Cloud runs, easier CI.

### Coverage targets (sane)
- 70–80% on business logic / reducers / utils.
- 50–60% on components.
- E2E: 5–10 critical paths only.

### Must-answer questions
1. Test pyramid for RN.
2. Reduce E2E flakiness.
3. Mock a native module.
4. Test a hook using React Query.
5. Why RNTL over Enzyme.

---

## 19. CI/CD, EAS, Fastlane, releases

### Fastlane
- `fastlane match` for cert/profile sync (encrypted git repo).
- Lanes: `build`, `beta`, `release`.
- Plugins: changelog, slack, sentry-cli upload.

### GitHub Actions / Bitrise
- macOS runners for iOS builds.
- Cache `node_modules`, Pods, Gradle.
- Parallel jobs: lint, test, build per platform.

### EAS (Expo Application Services)
- **EAS Build**: cloud builds for iOS/Android, no local Xcode/Android Studio needed.
- **EAS Update**: OTA JS updates per channel (preview/production).
- **EAS Submit**: uploads to stores.
- **Config plugins**: modify native config without ejecting (`app.json` extras).

### OTA (over-the-air) policy
- **Safe**: JS/asset changes, bug fixes, copy edits, feature flags.
- **NOT safe**: native module changes, permissions, native deps. Requires store build.
- **Apple rules**: OTA must not alter app's primary purpose / bypass review.

### Release strategy
- **Staged rollout**: Play Console (1/5/10/25/50/100%), TestFlight groups, then App Store phased.
- **Sentry release health gate**: halt rollout if crash-free sessions < 99.5%.
- **Feature flags** (Statsig/LaunchDarkly/GrowthBook) decouple release from launch.

### Code signing
- **iOS**: cert + provisioning profile per env (dev/adhoc/appstore). Match handles rotation.
- **Android**: keystore (`.jks` or `.keystore`) — back up offline. Play App Signing recommended.

### Must-answer questions
1. End-to-end release pipeline walkthrough.
2. What's safe vs not safe via OTA.
3. Bad release rollback.
4. Manage secrets in CI.
5. EAS vs Fastlane — when each.

---

## 20. Observability: Sentry, Crashlytics, analytics

### Sentry
- **Crashes** + **performance traces** + **release health**.
- Source maps upload per release.
- Breadcrumbs (auto + manual).
- User context (without PII): hashed user id only.
- Sample rates: errors 100%, perf traces 10–25%.

### Crashlytics
- Native crash focus.
- Pair with Sentry for JS — many teams do both.

### Analytics
- **PostHog** (your stack), Mixpanel, Amplitude, Firebase Analytics.
- Event taxonomy: `noun_verb` (`payment_succeeded`).
- Event versioning when payload changes.
- PII-free properties.

### Performance metrics to track
- **Cold start ms** (TTID, TTFD).
- **Crash-free sessions %** (target 99.5%+).
- **JS frame rate / UI frame rate**.
- **API latency P50/P95/P99**.
- **Bundle size**.

### Must-answer questions
1. Source maps + release flow with Sentry.
2. Sample rate strategy.
3. PII-safe event design.
4. KPIs you track on a mobile app.
5. Crashlytics vs Sentry — when each / both.

---

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

## 22. DSA must-knows

### Patterns (cover 80% of mediums)
| Pattern | Examples |
|---|---|
| Two pointers | Reverse, palindrome, 3-sum |
| Sliding window | Longest substring, max sum subarray |
| Hashmap freq | Anagrams, two-sum, group anagrams |
| Prefix sum | Subarray sum equals K |
| Binary search | Search rotated, sqrt, kth element |
| BFS / DFS | Trees, islands, course schedule |
| Heap (top-K) | Kth largest, merge K sorted |
| Monotonic stack | Next greater, daily temps |
| DP (1D, easy) | House robber, coin change, climb stairs |
| Linked list | Reverse, cycle, merge two |
| Trie | Word search, autocomplete |
| LRU cache | (Razorpay/PhonePe favorite) |

### LRU cache (memorize)
```js
class LRU {
  constructor(cap) { this.cap = cap; this.map = new Map(); }
  get(k) {
    if (!this.map.has(k)) return -1;
    const v = this.map.get(k); this.map.delete(k); this.map.set(k, v);
    return v;
  }
  put(k, v) {
    if (this.map.has(k)) this.map.delete(k);
    this.map.set(k, v);
    if (this.map.size > this.cap) this.map.delete(this.map.keys().next().value);
  }
}
```

### Plan
- 3 LeetCode mediums/day for 4 weeks.
- Cover all patterns above at least 2× each.
- 1 hard/week (just for exposure).

---

## 23. Behavioral + leadership (STAR)

### 10 stories to prepare (45-sec + 3-min versions)
1. LetsVenture flagship app — end-to-end ownership.
2. RN → Capacitor migration trade-off.
3. Auth0 / Cognito design decision.
4. Cashfree / Razorpay payment flow.
5. Branch deep linking rollout.
6. Biggest production incident — your role + fix.
7. Performance win (with before/after numbers).
8. Conflict with PM / designer / engineer — how resolved.
9. Mentoring a junior who struggled.
10. Deadline vs quality trade-off.

### STAR template
- **Situation** (1 sentence context)
- **Task** (your specific responsibility)
- **Action** (what YOU did, not "we")
- **Result** (numbers: %, ms, $, users, crash-free)

### Top behavioral questions
1. Tell me about yourself (90 sec polished).
2. Why are you leaving? (forward-looking, never bash current employer).
3. Time you disagreed with a senior.
4. Biggest mistake in production.
5. How do you give feedback?
6. Why this company? (research per company).
7. Where in 3 years?
8. Manager-track vs IC-track preference.

### Lead-track signals to drop in answers
- "I wrote the RFC and got buy-in from..."
- "I mentored 3 juniors through their first..."
- "I owned the on-call rotation for..."
- "I drove the decision to..." (own it).
- "The trade-off was X vs Y; we chose X because..."

---

## 24. Resume, LinkedIn, applications, negotiation

### Resume (1 page)
- **Header + Title**: `Senior React Native / Mobile Tech Lead`.
- **Summary**: 3 lines, customize per company.
- **Experience**: bullets = `verb → what → number`. Example:
  - ✅ "Cut iOS cold start from 4.1s → 1.6s by lazy-loading TurboModules; D1 retention +6%."
  - ❌ "Worked on performance improvements."
- **Skills**: grouped (Mobile / Frontend / State / Quality / Release / Other).
- Full template: [study/17-resume-template.md](study/17-resume-template.md).

### LinkedIn
- **Headline**: `Senior React Native Developer | 9+ Years | Android & iOS | Fintech | Architecture, Performance, Payments, Auth`.
- **About**: same 3-line summary.
- **Skills section**: pin React Native, TypeScript, iOS, Android, Redux, React Query.
- **Open to Work**: recruiters only.
- Full positioning: [linkedin-naukri-react-native-positioning.md](linkedin-naukri-react-native-positioning.md).

### Application strategy
1. **Referrals first** (~70% of Tier S/A offers come via referral). Find 2–3 contacts per target on LinkedIn.
2. Apply in clusters of 5–8/week.
3. Track: Company / Role / Source / Contact / Applied / Stage / Expected CTC / Next.
4. Customize Summary line per JD.

### Negotiation (₹40+ LPA target)
- Walk-away: ₹38 LPA fixed. Target: ₹45 LPA fixed. Stretch: ₹55+ with offers.
- Recruiter script for "current CTC?": *"My current fixed is in the low-20s; I'm evaluating roles in the ₹45–55 LPA fixed band based on scope and 9 YOE."*
- Recruiter script for "expected?": *"Looking at ₹48–55 LPA fixed; total comp open depending on RSU/ESOP."*
- Always run 3+ processes in parallel. One offer = no leverage.
- Joining bonus: ₹3–8 LPA is fair when leaving variable/RSU on table.
- Per-tier bands:
  - **Tier S fintech**: ₹40–60 LPA fixed + 10–25% var + ESOPs.
  - **Tier A**: ₹38–55 LPA fixed + RSU/ESOP.
  - **Tier A− globals**: ₹42–65 LPA fixed + ₹15–40 LPA RSU.

### Risks + mitigations
- **Capacitor migration narrative** — frame as business decision, not skill regression.
- **No FAANG brand** — counter with depth + numbers.
- **DSA rust** — 30 min/day for 4 weeks closes it.

Full plan: [job-market-2026-top20-plan.md](job-market-2026-top20-plan.md). 30-day study schedule: [30-day-interview-prep-plan.md](30-day-interview-prep-plan.md).

---

## 25. Last-mile cheatsheet

### Numbers to memorize about your own apps
- Cold start (before / after).
- Crash-free sessions %.
- DAU / MAU.
- App size (IPA / APK).
- P95 API latency.
- # of releases / month.
- Team size, mentees, RFCs authored.

### Words to use (lead-track vocab)
Architected, Authored, Migrated, Owned, Drove, Established, Mentored, Productionized, Profiled, Reduced, Scaled, Shipped, Standardized, Unblocked.

### Words to avoid
"Worked on", "Helped with", "Was involved in", "Just", "Basically", "Try to", "Sort of".

### Recruiter screen — prep these 5 cold
1. Tell me about yourself (90 sec).
2. Why looking?
3. What kind of role?
4. Notice period?
5. Expected CTC? (anchor high, deflect current.)

### Final 24-hr checklist before any loop
- [ ] Re-read company's product + recent news (30 min).
- [ ] Re-read JD; map 3 of your bullets to it.
- [ ] Have 5 questions ready to ask them.
- [ ] Test mic/camera, charge laptop, water bottle.
- [ ] Sleep 7+ hrs. No new topics night before.

---

# APPENDICES (everything inlined — no jumping)

---

## Appendix A — Top-20 Target Companies + Market Signals

### Tier S — strongest fit, actively hiring senior RN / mobile leads
1. **PhonePe** — fintech, RN + native, payments scale
2. **Razorpay** — you already integrated their SDK, huge plus
3. **CRED** — RN-heavy, fintech, premium UX bar
4. **Groww** — RN, investing/fintech, your domain
5. **Zerodha (Kite / Coin)** — investing fintech, mobile-first
6. **Jupiter Money** — RN, neobank
7. **Slice** — RN, fintech
8. **Freecharge / Axio / KreditBee** — RN fintech, lending

### Tier A — strong fit, mobile-led product orgs
9. **Swiggy** — RN + native, large mobile org
10. **Zomato / Blinkit** — RN, hyperlocal scale
11. **Flipkart / Myntra** — native + RN bridges, mobile hiring active
12. **Meesho** — RN, performance/low-end Android focus
13. **Dream11** — high-perf mobile, fintech-adjacent (real-money gaming)
14. **PharmEasy / Tata 1mg** — RN, healthtech mobile

### Tier A− — global product cos hiring in India for RN/mobile
15. **Microsoft (India)** — RN contributor org, Outlook/Teams mobile
16. **Walmart Global Tech (Bengaluru)** — RN + native
17. **Atlassian (Bengaluru)** — mobile platform
18. **Coinbase / Binance India teams** — RN, crypto fintech
19. **Booking.com / Agoda (India)** — mobile, perf-heavy
20. **Postman / Zeta / Setu** — fintech infra, mobile/SDK roles

> Skip-or-deprioritize: pure-Android-only shops, generic services companies (TCS/Infy/Wipro mobile), early seed startups under 2 YOE founders.

### What ₹40+ LPA actually requires

| Bar | What it means | Where you stand |
|---|---|---|
| 8+ YOE | Yes, 9+ ✅ | clear |
| Senior or Lead title in interview | Position as Lead RN / Mobile Tech Lead | needs LinkedIn/resume update |
| 1–2 strong domain stories with numbers | Fintech (LetsVenture) ✅ — but quantify | story polish needed |
| Clear new-arch / perf vocabulary | Fabric, TurboModules, JSI, Hermes, FlashList | medium gap, ~1 wk |
| Clean DSA medium round | LeetCode mediums | refresh needed, ~3–4 wks |
| 1 mobile system design rehearsed | Offline-first fintech | gap, ~1 wk |
| Competing offers | 2+ in-flight at decision time | strategy, not skill |

If you hit the first 6, **₹40 LPA is the floor offer**. The 7th (competing offers) pushes ₹40 → ₹50+.

### Why the ₹23 → ₹40+ jump works
1. You are likely **underpaid for 9 YOE fintech RN** in Bengaluru — market rate is ₹35–45 LPA fixed.
2. Switch hikes are calculated on **market rate**, not current CTC, when the candidate is in demand.
3. **Lead-track positioning** (not Senior IC) adds ₹8–15 LPA on the same skills.
4. **Fintech domain premium** is real — PhonePe/CRED/Razorpay pay 20–30% above generic product cos.
5. **Competing offers** convert ₹35 LPA offers into ₹45 LPA offers in 2–3 days.

### What can break it
- Accepting the first offer.
- Disclosing current CTC too early (anchors them low).
- Targeting only Senior IC roles instead of Lead.
- Going to services companies / mid-tier startups — bands cap at ₹30–35 LPA.
- Weak DSA (1 round failure can drop the band by ₹5–10 LPA).

### Application strategy
1. **Referrals > portals.** ~70% of Tier S/A senior offers come via referrals. For each target, find 2–3 ex-colleagues / 2nd-degree connections on LinkedIn, send a short DM.
2. **Apply in clusters of 5–8 cos/week**, not 30 at once.
3. **Customize the Summary line** of the resume per company.
4. **Track everything** in a sheet: company, contact, applied date, stage, expected CTC, next step.
5. **Negotiate hard but kindly.** 9 YOE + fintech + lead signal = top 5–10% of RN talent in India.

### Honest risks to manage
- **Capacitor migration** can be read as "moved away from RN" — own the narrative: business decision, not skill regression.
- **No FAANG brand** — counter with depth, fintech ownership, and metrics.
- **Single-company recent tenure** (LetsVenture-heavy) — emphasize multi-app shipping + variety of integrations.
- **DSA rust** — 30 min/day for 4 weeks is enough.

### What to learn first if you only have 1 week
1. **Fabric + TurboModules + JSI** narrative (asked in every Tier S/A loop).
2. **Cold start + list perf** numbers from your own app (carry screenshots).
3. **One mobile system design** rehearsed cold (offline-first fintech).
4. **Top 10 STAR stories** rehearsed out loud, with numbers.
5. **Updated resume + LinkedIn headline** (see Appendix D).

---

## Appendix B — 30-Day Study Schedule (basics → advanced)

> Cadence: 6–8 hrs/day, 6 days/week, 1 day rest.
> Daily template (8 hrs): 90 min theory + 90 min hands-on + 60 min Qs + 60 min DSA + 60 min recall + 30 min review + 30 min buffer.

### Week 1 — JS/TS + React fundamentals (the screen-out filter)
- **Day 1 — JS core**: execution context, hoisting, scope, closures, `this` binding. *Hands-on*: 5 closure puzzles + 5 `this` puzzles. → Section 2.
- **Day 2 — JS async**: event loop, microtasks/macrotasks, Promises, `async/await`, `Promise.all/allSettled/race/any`. *Hands-on*: implement `pLimit` + `retry` + `Promise.all` from scratch. → Section 2.
- **Day 3 — TypeScript**: type vs interface, generics, utility types, discriminated unions, type guards, narrowing. *Hands-on*: typed `useFetch<T>`, typed navigation, Zod for one API. → Section 3.
- **Day 4 — React + hooks**: render cycle, `useState/Effect/Ref/Memo/Callback/Context/Reducer`, dependency arrays. *Hands-on*: build `useDebounce`, `usePrevious`, `useToggle`, `useInterval`, `useAsync`. → Section 4.
- **Day 5 — React advanced + perf**: reconciliation, keys, `React.memo`, Context perf, Suspense, error boundaries, `useTransition`. *Hands-on*: profile sample app, fix 3 unnecessary re-renders. → Section 4.
- **Day 6 — DSA + mock**: 5 LeetCode mediums (arrays, hashmap, two-pointer) + 1 mock JS/React interview (45 min, recorded).
- **Day 7 — Rest**.

### Week 2 — RN core + new architecture + debugging
- **Day 8 — RN architecture basics**: threading, old bridge, Metro, Hermes vs JSC, project structure. *Hands-on*: fresh RN app, toggle Hermes, measure startup. → Section 5.
- **Day 9 — New Architecture**: JSI, Fabric, TurboModules, Codegen, migration. *Hands-on*: enable new arch, write a tiny TurboModule for battery level. → Section 5.
- **Day 10 — Hermes + bundle + cold start**: bytecode, `inlineRequires`, lazy loading, cold start anatomy. *Hands-on*: profile cold start, reduce 30%. → Section 6.
- **Day 11 — Performance: lists/animations/images**: FlatList → FlashList, Reanimated 3, expo-image. *Hands-on*: 1000-row feed FlatList → FlashList, measure FPS gain. → Section 7.
- **Day 12 — Native modules**: Swift + Kotlin authoring, threading, return patterns. *Hands-on*: write Swift + Kotlin battery module emitting charging state. → Section 8.
- **Day 13 — Debugging deep day**: RN DevTools, Hermes Inspector, Reactotron, Instruments, Android Profiler, Charles, symbolication, ANR. *Hands-on*: plant a memory leak (uncleaned listener), find via Allocations + Android Profiler, fix; symbolicate a crash. → Section 9.
- **Day 14 — DSA + mock**: 5 LeetCode mediums (linked list, tree, BFS/DFS) + 1 mock RN deep-dive (45 min).

### Week 3 — State, navigation, offline, testing, CI/CD, security
- **Day 15 — State management**: 3-bucket model, RTK, Zustand, React Query, optimistic updates. *Hands-on*: screen using all three. → Section 10.
- **Day 16 — Navigation + deep links**: Native Stack vs JS Stack, Universal Links, App Links, Branch, auth gating, typed params. *Hands-on*: typed RN project with auth gate + deep links. → Section 11.
- **Day 17 — Offline-first**: MMKV, WatermelonDB, outbox pattern, sync, conflicts. *Hands-on*: offline todo with MMKV + outbox + sync on reconnect. → Section 14.
- **Day 18 — Testing**: Jest, RNTL, Detox, Maestro, mocking native modules. *Hands-on*: 5 RNTL tests + 1 Maestro flow. → Section 18.
- **Day 19 — CI/CD + release**: Fastlane, GitHub Actions, EAS Build/Update, code signing, OTA policy. *Hands-on*: GH Actions for sample app: lint → test → EAS build preview. → Section 19.
- **Day 20 — Mobile security**: Keychain/Keystore, OAuth PKCE, single-flight refresh, cert pinning, MASVS L2, Privacy Manifest, biometric gating. *Hands-on*: secure token store wrapper. → Section 16.
- **Day 21 — DSA + mock**: 5 LeetCode mediums (DP-easy, sliding window) + 1 mixed mock.

### Week 4 — System design, behavioral, DSA, conversion
- **Day 22 — Mobile system design (basics)**: framework, layering, modularization, monorepo. *Practice*: Insta feed, WhatsApp messaging. → Section 21.
- **Day 23 — Mobile system design (fintech)**: Zerodha order placement, neobank account, payments. *Hands-on*: 1 written design doc. → Section 21.
- **Day 24 — DSA focused day**: 8 LeetCode mediums covering all patterns + LRU cache from scratch. → Section 22.
- **Day 25 — Behavioral + STAR**: prepare 10 stories in 45-sec + 3-min versions. Record. → Section 23 + Appendix E.
- **Day 26 — Resume, LinkedIn, applications**: rewrite resume per Appendix C, update LinkedIn per Appendix D, set Open-to-Work, apply to **Tier S top 8** with referrals, send 10 referral DMs.
- **Day 27 — Apply Tier A + recruiter screen prep**: apply to **Tier A 6 cos**, prep 5 recruiter answers cold (TMAY, why looking, notice, expected CTC, current CTC deflection).
- **Day 28 — Full mock day**: recruiter (15 min) → DSA (1 medium) → RN deep dive → System design (45 min) → Behavioral (5 STAR) → Retro.
- **Day 29 — Weak-area repair**: pick top 3 gaps from Day 28, re-read those sections, rehearse 5x. Apply to **Tier A− globals**.
- **Day 30 — Cheatsheet review + go live**: skim Section 25, refresh top-50 Qs, rest. **Day 31 onwards: interview season.**

### Topic-by-topic question count
| Topic | Qs | Hands-on |
|---|---|---|
| JS core + async | 25 | 5 puzzles, `pLimit`, custom `Promise.all` |
| TypeScript | 15 | Typed `useFetch`, navigation types |
| React + hooks | 20 | 5 custom hooks, profiler fix |
| RN architecture + new arch | 25 | TurboModule for battery |
| Hermes + perf + lists | 20 | Cold start −30%, FlashList migration |
| Native modules | 15 | Swift + Kotlin battery module |
| Debugging | 20 | Memory leak find+fix, sourcemap symbolication |
| State management | 15 | RTK + Zustand + React Query screen |
| Navigation + deep links | 12 | Typed RN with auth gate + deep links |
| Offline-first | 12 | MMKV + outbox + sync demo |
| Testing | 12 | RNTL + Maestro suite |
| CI/CD | 10 | GH Actions + EAS pipeline |
| Security | 15 | Secure token store wrapper |
| System design | 5 problems | 1 written design doc |
| Behavioral | 10 STAR | Recorded 45s + 3min versions |
| DSA | 30 mediums | LRU cache, common patterns |
| **Total** | **~250** | **15 artifacts** |

### Rules to not break
1. **Speak answers aloud** every day. Reading is not preparing.
2. **Build the hands-on artifact** for each day. Have a repo to show.
3. **Quote numbers** from your own work.
4. **Don't disclose ₹23 LPA** to recruiters. Anchor at ₹45–55 LPA fixed.
5. **Run 3+ processes in parallel** in week 5.
6. **Sleep 7+ hrs**.

### If you fall behind
- Skip DSA day, not a topic day.
- Always do the hands-on, even if you cut theory short.
- Re-do mock days if scores are low.

### After Day 30
- Week 5: interview-driven prep. Each interview tells you the next gap.
- Week 6: offer optimization (see Section 24 negotiation).
- Target: **first offer by Day 45, signed offer at ₹40+ LPA by Day 60.**

---

## Appendix C — Resume Template (1 page)

### Header
**Rajeev Joshi** · Senior React Native Engineer / Mobile Tech Lead
Bengaluru, India · <email> · <phone> · linkedin.com/in/<you> · github.com/<you>

### Summary (3 lines, rewrite per company)
Senior mobile engineer with 9+ years shipping React Native apps used by **<N>M users** across iOS and Android. Specialize in **fintech / offline-first / performance** — most recently led the LetsVenture mobile platform that **<cut cold-start 60% / lifted retention 12% / shipped to N+ markets>**. Comfortable across the stack from JSI/TurboModules to release pipelines and on-call.

### Experience

**LetsVenture, Lead Mobile Engineer — <Mon YYYY – Present>**
*Investor-facing fintech platform across Android + iOS; React Native + Capacitor.*
- Led mobile development for LVX and LVXQ apps across React Native, Android, and Capacitor; owned end-to-end delivery for **<N>** investor-facing screens.
- Built secure auth using **Auth0 + AWS Cognito** for production fintech workflows; cut auth-related Sentry events to zero via single-flight refresh.
- Integrated **Cashfree + Razorpay** payment flows with idempotent submission; reduced duplicate-charge support tickets **<32%>**.
- Implemented **Branch deep linking** + push notifications + PostHog analytics across **<N>** screens; eliminated **<class of>** runtime errors via typed routes.
- Owned Play Store + App Store release cycles, EAS/Fastlane pipeline; introduced staged rollouts cutting MTTR for JS regressions from **<24h → 30min>**.
- Led RN → Capacitor migration for LVXQ as a business + engineering trade-off; documented the ADR; trained **<N>** engineers on the new pipeline.

**SpaceBasic, Senior Mobile Engineer — <Mon YYYY – Mon YYYY>**
- Built RN apps used by **<N>** users; drove architecture, perf optimization, release management, cross-functional collaboration.
- Profiled and fixed list-scroll jank: replaced FlatList with FlashList + memoized rows; raised P95 scroll FPS **<42 → 58>**.
- Reduced crash-free sessions floor from **<98.1% → 99.7%>** by introducing Sentry release-health gates blocking promotion.

**WildTrails, Mobile Engineer — <Mon YYYY – Mon YYYY>**
- Built Android apps for travel/wildlife platforms with focus on bookings, media flows, mobile UX.
- Reduced APK size **<X MB>** via Hermes + R8 + dynamic imports; install conversion **+<Y>%**.

**Dunst, Mobile Engineer — <Mon YYYY – Mon YYYY>**
- Developed Android apps including Wanderlust and SIFF: VR/travel experiences, multimedia content, mobile feature delivery.

**Plurebus, Mobile Engineer — <Mon YYYY – Mon YYYY>**
- Android app development for entertainment/consumer use cases: API integration, app features, product delivery.

### Skills
- **Mobile**: React Native (new arch, Hermes, Fabric, TurboModules, JSI), Expo (EAS, Router, Modules), iOS (Swift), Android (Kotlin)
- **Frontend**: TypeScript, React 18, Reanimated 3, Gesture Handler, FlashList, Tamagui/Restyle
- **State / Data**: Redux Toolkit, Zustand, TanStack Query, MMKV, WatermelonDB, SQLite
- **Quality**: Jest, RNTL, Detox, Maestro, Storybook
- **Release / Ops**: EAS Build/Update, Fastlane, GitHub Actions, Sentry, Crashlytics, PostHog, Firebase
- **Auth & Payments**: Auth0, AWS Cognito, OAuth/OIDC, Cashfree, Razorpay
- **Other**: GraphQL, REST, WebSockets, OWASP MASVS, Branch deep linking, A/B testing, feature flags

### Education
**<Degree>**, <University>, <Year>

### Bullet rewrite checklist
For every bullet ask:
1. Verb-led? (Led, Cut, Built, Shipped, Designed, Reduced, Migrated, Authored, Mentored)
2. Has a **number**? (Users, %, ms, $, MB, FPS, hours, headcount.)
3. Business impact clear?
4. Could a non-mobile engineer understand the value?
5. < 2 lines?

### Verb bank
Architected · Authored · Automated · Benchmarked · Built · Cut · Delivered · Designed · Diagnosed · Eliminated · Established · Improved · Instrumented · Introduced · Led · Migrated · Mentored · Optimized · Owned · Productionized · Profiled · Reduced · Refactored · Rolled out · Scaled · Shipped · Standardized · Streamlined · Unblocked

### Resume filename
`Rajeev_Joshi_Senior_React_Native_Developer_Resume.pdf`

---

## Appendix D — LinkedIn + Naukri Positioning

### LinkedIn headline (pick one)
- `Senior React Native Developer | Android & iOS | Fintech Mobile Apps | Payments, Auth, Deep Linking`
- `Lead React Native Developer | 9+ YOE | Android & iOS | Fintech, Performance, Architecture`

### LinkedIn About
> I'm a Senior Mobile Engineer with 9+ years of experience building and shipping Android and iOS applications, with a strong focus on React Native. I've worked across fintech, travel, and consumer products, leading mobile delivery for secure, scalable apps with features such as authentication, payments, analytics, deep linking, push notifications, and release management.
>
> At LetsVenture, I led mobile development for investor-facing platforms including LVX and LVXQ, working across React Native, Android, and Capacitor. I've owned production releases for both Play Store and App Store and enjoy solving problems in architecture, performance, reliability, and product execution.
>
> I'm currently targeting Senior React Native Developer and Lead React Native Developer opportunities where I can build high-quality Android and iOS mobile experiences with strong product and engineering ownership.

### Pin top skills (in order)
1. React Native
2. TypeScript
3. Mobile Application Development
4. Android Development
5. iOS Development
6. Redux Toolkit
7. React Navigation
8. Firebase
9. Auth0 / AWS Cognito
10. Razorpay / Cashfree
11. Sentry / PostHog
12. Performance Optimization

### LinkedIn experience bullets (action → tech → impact)
- Led development of investor mobile applications across React Native and Capacitor for Android and iOS.
- Implemented secure authentication using Auth0 and AWS Cognito for production fintech workflows.
- Integrated payment systems including Cashfree and Razorpay for investor transaction journeys.
- Owned Play Store and App Store release cycles, production stability, analytics, and crash monitoring.

### Naukri changes
- **Profile title**: change from `Lead Mobile Engineer` → `Senior React Native Developer` or `Lead React Native Developer`.
- **Resume headline**: `Senior React Native Developer | 9+ Years | Android & iOS Apps | Fintech, Payments, Auth, Push Notifications, App Store & Play Store Releases`
- **Key skills (add)**: React Native CLI, Expo, React Navigation, Redux Toolkit, Zustand, React Query, TypeScript, Jest, Detox, Fastlane, CI/CD, App Store Deployment, Play Store Deployment, Deep Linking, Branch.io, Auth0, AWS Cognito, Razorpay, Cashfree, Sentry, PostHog, Performance Optimization
- **Key skills (remove)**: Mobile Development (generic), Mobile Application Development (generic), Android Application Development (generic), Visual Studio, Context API
- **Preferred locations**: Bengaluru, Remote, Hyderabad, Pune, Chennai, Gurugram, Noida (drop Kolkata)
- **Expected salary**: bump from ₹25L → ₹28–32L on Naukri (filters by band)
- **Notice period**: state explicitly with last working date if known

### Best search keywords (sprinkle across headline/summary/experience/skills)
React Native · Android · iOS · TypeScript · Mobile App Development · App Store · Play Store · Performance Optimization · Deep Linking · Push Notifications · Authentication · Payments

### Avoid leading with
- Generic `Lead Mobile Engineer`
- Generic `Mobile / App Developer`
- Generic `Software Development`

---

## Appendix E — STAR Story Bank (10 stories with worked examples)

### Story template
```
TITLE: <short memorable name>
PROMPTS IT ANSWERS: <impact / hardest tech / ownership / influence>

S — Situation (1–2 sentences): company, team, scale, constraint.
T — Task (1 sentence): YOUR specific responsibility.
A — Action (4–6 bullets): decisions + why, trade-offs rejected, buy-in, concrete moves, risk mitigated.
R — Result (2 bullets): quantified outcome + second-order impact.
L — Lesson (1 sentence): "what I'd do differently" / "what I now look for first."
```

### 10 stories (worked examples — adapt with your numbers)

#### 1. Largest impact — *"The 4-second cold start"*
- **S**: 8-engineer mobile team, 2M MAU consumer app; iOS cold start crept to 4.1s, blamed for D1 dip.
- **T**: Owned mobile perf for the quarter; goal was sub-2s + measurable retention lift.
- **A**: Profiled with Hermes + Instruments; 60% of pre-render time in eager TurboModule init + sync remote-config fetch. Lazy-loaded 14 modules; moved remote-config to async with cached defaults; trimmed Hermes bundle 38% (moment → dayjs, code-split onboarding); wrote a perf budget + CI gate.
- **R**: Cold start 4.1s → 1.6s P50; D1 retention +6.2%, D7 +3.1%. Perf budget still in use 18 months later.
- **L**: Always ship the measurement before the optimization.

#### 2. Hardest technical problem — *"The phantom crash on Android 12"*
- **S**: 0.4% crash on Android 12 only, no symbols.
- **T**: Crash-free sessions back above 99.5% within 2 weeks before board review.
- **A**: Reproduced via 14 navigations + low-memory pressure; isolated to Reanimated worklet capturing stale shared value after screen unmount race. Fixed with `cancelAnimation` in cleanup; upstreamed repro; added Detox regression.
- **R**: Crash-free 99.1% → 99.78% in 9 days.
- **L**: Concurrency bugs look like memory bugs first.

#### 3. Conflict — *"Native rewrite vs RN at the redesign"*
- **S**: New design head wanted SwiftUI/Compose during redesign; would split team + double timeline.
- **T**: Defend RN on merits, not defensively.
- **A**: 2-week spike comparing both stacks on 3 real screens. Quantified parity (FPS, dev velocity). Invited design team to drive iOS spike. Presented to CTO with data.
- **R**: Team chose RN + Reanimated 3. Redesign shipped on original timeline. Designer became RN advocate.
- **L**: When you disagree, build the smallest experiment that resolves it.

#### 4. Failure — *"The OTA that froze 4% of Android users"*
- **S**: EAS Update with Hermes-only API, broke on specific OEM keyboard.
- **T**: I owned release; on-call.
- **A**: Sentry alert in 11 min; rolled back; opened post-mortem in 24h. Root cause: weak device matrix. Fix: 12-device cloud test farm gate + forced staged OTA 10/50/100.
- **R**: Impact window 38 min; 0 lasting churn. New release-gate adopted org-wide.
- **L**: Speed of detection > prevention.

#### 5. Leadership without authority — *"The cross-team auth refactor"*
- **S**: Mobile/web/backend each had different refresh-token strategies; tokens leaked into Sentry.
- **T**: No mandate; cared because mobile bore worst UX.
- **A**: Wrote RFC for single rotation + reuse detection. 1:1s with each tech lead. Built reference impl on mobile. Shepherded rollout across 3 teams over a quarter.
- **R**: Token-leak Sentry events to zero; refresh-storm incidents eliminated; pattern adopted in 2 sister apps.
- **L**: RFC + working reference is more persuasive than either alone.

#### 6. Mentorship — *"From new-grad to feature owner in 9 months"*
- **S**: Inherited a new-grad with strong CS but no mobile experience.
- **T**: Get them owning a feature E2E by H2.
- **A**: Weekly 1:1s with growth plan tied to RN topics. Pair-debugged real prod issues. Gradually larger scope: bug → small feature → cross-cutting refactor. Introduced to design partners.
- **R**: Led notifications redesign solo (3 months, 4 engineers' worth of design touchpoints). Promoted to mid-level on schedule.
- **L**: Stretch comes from owning conversations, not just code.

#### 7. Ambiguity — *"Defining 'engagement' for the mobile team"*
- **S**: Leadership asked mobile to "improve engagement" with no metric defined.
- **T**: Pick a metric mobile could move and commit.
- **A**: Interviewed PM, data, exec stakeholders. Proposed 3 candidate metrics with trade-offs. Recommended sessions/user as most mobile-actionable; built dashboard; committed to 15% lift in Q2.
- **R**: 18% lift via push re-engagement, faster cold start, home-screen redesign. Metric became team's north star.
- **L**: When asked something vague, return with a definition before a plan.

#### 8. Trade-off — *"Picking React Query over Apollo"*
- **S**: Greenfield app; team split between Apollo (existing GraphQL backend) and React Query + REST.
- **T**: Pick within a week; commit for 18 months.
- **A**: Listed criteria (offline, bundle size, learning curve, server-state caching, mutation ergonomics). Prototyped both for 2 days. Chose React Query + thin GQL client.
- **R**: Bundle 220KB smaller; offline UX shipped in week 6 instead of "later"; 0 regrets in retro.
- **L**: Document trade-offs in an ADR the moment you decide.

#### 9. Saying no — *"Pushing back on the 'just add WebView' shortcut"*
- **S**: PM wanted partner integration as in-app WebView in 2 weeks; security concerns around token passthrough.
- **T**: Balance speed and risk.
- **A**: Mapped threat model in 1 doc. Proposed 3-week native bridge using ASWebAuthenticationSession / Custom Tabs with scoped tokens. Got security + PM in one room.
- **R**: Shipped safer version on original date by cutting an unrelated nice-to-have. Zero security findings in next audit.
- **L**: "No" lands better as "here's the smaller thing that gets you 90% safely."

#### 10. Customer obsession — *"The accessibility bug nobody filed"*
- **S**: VoiceOver users couldn't dismiss our bottom sheet; never reported because affected users churned silently.
- **T**: Self-driven; not on any roadmap.
- **A**: Audited 12 critical flows with VoiceOver + TalkBack; filed 23 issues; fixed 9; created a11y checklist in PR template; ran a brown-bag.
- **R**: VoiceOver users (opt-in analytics) up 3× over the next year. Featured in an a11y newsletter.
- **L**: The users who can't tell you they're leaving are the ones to look for hardest.

### Story-to-prompt cheat map
| Prompt | Story |
|---|---|
| Tell me about your biggest impact | 1, 5 |
| Hardest technical problem | 2, 8 |
| Conflict / disagreement | 3, 9 |
| Time you failed | 4 |
| Led without authority | 5, 7 |
| Mentored someone | 6 |
| Ambiguous problem | 7 |
| Made a trade-off | 8, 3 |
| Said no | 9 |
| Customer obsession | 10 |
| Outage / on-call | 4, 2 |
| Disagree & commit | 3, 9 |

### Common follow-up traps (rehearse)
- "What would you do differently?" — Have a real answer, not "nothing."
- "What did your manager think?" — Show alignment + your role in earning it.
- "What did the team think?" — Show empathy for dissenters.
- "How did you measure success?" — Always cite the metric + how you instrumented it.
- "What was the alternative you rejected?" — Show the trade-off explicitly.
- "What was your specific contribution vs the team's?" — "I" for your part; credit team for theirs.

### Practice protocol
1. Write each story in the template (text).
2. Record yourself telling it — strict 2-min cap.
3. Listen back; cut filler ("kind of", "basically", "so yeah").
4. Have a peer ask 3 follow-ups per story; capture the gaps.
5. Repeat weekly until natural, not memorized.

---

## Appendix F — Extended Q&A Bank (rehearse short + deep versions)

> For every important answer, prepare **20-sec / 60-sec / 3-min** versions. That is how you sound senior and controlled.

### F.1 — Why React Native?
**Short**: RN lets teams build iOS + Android with shared TS codebase rendering native UI — faster iteration, shared logic, lower cost without giving up near-native UX.
**Deep**: Best when product needs fast feature velocity across both platforms with mostly standard mobile UX. Weaker when graphics-heavy, deeply platform-specific, or extremely native-API-dependent. I frame RN as a trade-off between velocity, native depth, team composition, long-term maintainability.

### F.2 — Old bridge vs JSI
**Short**: Bridge serialized messages async between JS and native, adding overhead. JSI lets JS interact directly with native objects/functions, cutting serialization cost and improving performance.
**Deep**: In bridge model, every cross-boundary call required marshalling JSON, sending across, reconstructing — latency + expense for high-frequency calls. JSI exposes native via JS interfaces without that bottleneck. Especially valuable for animations, large data transfers, custom modules. Reanimated 3 worklets use JSI to run on UI thread.

### F.3 — Fabric and TurboModules
**Short**: Fabric is the new renderer; TurboModules are the new way to build native modules with better startup + invocation perf.
**Deep**: Fabric modernizes UI rendering with efficient scheduling + mounting. TurboModules modernize loading + access — often lazy-loaded, work with JSI + Codegen. The new arch improves perf, startup, and native interop.

### F.4 — Designing a scalable RN app for fintech
**Short**: Modular feature-based architecture with clear separation of UI, domain, API, storage, analytics, security. Optimized for release safety, observability, secure auth + payments.
**Deep**: Feature modules (onboarding, portfolio, transactions, KYC, payments, notifications). Shared layers: navigation, API client, auth/session, secure storage, analytics, error reporting, design system. Separate client state from server state. Typed contracts. Route guards. Centralized error handling. Sentry + analytics first-class. Goal: predictable delivery with low regression risk.

### F.5 — RTK vs Zustand vs React Query
**Short**: RTK for large shared app state + team consistency; Zustand for lightweight client state; React Query for server state (cache, retry, invalidation).
**Deep**: Not mutually exclusive. React Query: caching, stale data, retry, background refresh, mutations. RTK: structured global state, traceability, middleware, conventions. Zustand: localized global state with low ceremony. Lead-level maturity = choose by state category, not preference.

### F.6 — Debug performance issues in RN
**Short**: Identify whether bottleneck is JS thread, UI thread, network, image, or memory. Profile, reproduce with instrumentation, optimize highest-cost path.
**Deep**: Workflow: reproduce consistently → define user symptom → check JS thread load, re-renders, list virtualization, image sizes, network waterfall, startup path, native resources. Tools: Hermes profiler, Instruments, Android Profiler, Sentry traces. Common fixes: memoize rows, reduce re-renders, batch work, defer SDK init, optimize images, reduce bridge overhead.

### F.7 — FlatList vs ScrollView vs FlashList
**Short**: ScrollView for small content. FlatList virtualizes — default for larger. FlashList for perf-critical, complex rows.
**Deep**: Choose by data size, row complexity, scroll expectations. ScrollView risky for long/media-heavy lists. FlatList: virtualization + config. FlashList: consistency for complex feeds at scale. Always: stable keys, `getItemLayout` when possible, tuned batch settings, lightweight rows, image strategy.

### F.8 — Secure auth tokens
**Short**: Access + refresh tokens in Keychain (iOS) / Keystore-backed (Android), not AsyncStorage.
**Deep**: Storage + lifecycle + transport. Short-lived access tokens with refresh flow. Single-flight refresh logic. Clear sensitive caches on logout. Avoid logging tokens. Guard sensitive screens with re-auth/biometrics. Fintech: session timeout, compromised device risk, secure deep links, minimum PII in analytics/crashes.

### F.9 — Multiple concurrent 401s
**Short**: Single-flight refresh — only one token refresh happens; pending requests wait for new token.
**Deep**: Without single-flight, concurrent 401s create refresh storms, token invalidation, inconsistent session. Approach: queue/pause failed requests, refresh once, replay after success, fail cleanly if refresh fails. Important for background fetches, parallel dashboards, real-time reconnection.

### F.10 — Safe payment flow design
**Short**: Backend is source of truth. App handles initiation, status polling/callbacks, retry UX, idempotent submission.
**Deep**: Server-generated payment intent/order, idempotency keys, SDK integration, webhook reconciliation, clear retry states. Assume crash/connectivity loss mid-payment — on next open, reconcile from backend. Lead-level: analytics, failure categorization, user trust, support tooling.

### F.11 — RN → Capacitor migration narrative
**Short**: Business + engineering trade-off, not framework religion. Decision depends on product needs, team strengths, web reuse, perf, release speed.
**Deep**: Honest framing — what RN gave you, what it cost, why Capacitor improved some areas, trade-offs that remained. Cover architecture, dev velocity, native plugin model, UI feel, perf, migration risk, QA cost, user-impact mitigation during rollout.

### F.12 — Senior testing approach
**Short**: Pyramid: unit (Jest) for logic, component (RNTL) for UI, integration for important flows, selective E2E (Detox/Maestro) for release confidence.
**Deep**: Optimize for confidence per dollar of maintenance. Unit: pure utilities, state, edge cases. Component: screen behavior + contracts. Integration: login, payment, critical nav. E2E: minimum path protecting release. Care about mocking, flake reduction, suite speed.

### F.13 — RN CI/CD pipeline contents
**Short**: Lint, type-check, unit tests, build validation, versioning, signed release, source map / symbol upload, staged rollout.
**Deep**: Dependency caching, env separation, secrets handling, Android + iOS build jobs, build-number strategy, store-ready artifacts, crash symbol uploads, release notes automation. Reduce human error; make hotfixes safe.

### F.14 — Secure deep linking
**Short**: Validate route params, enforce auth guards, never trust arbitrary link data, sensitive destinations require session state.
**Deep**: Deep linking is an input surface. Validate route shape, restrict unsupported actions, handle deferred install links carefully, route protected destinations through auth + state checks. Avoid leaking sensitive values via URLs, notifications, analytics.

### F.15 — Mobile tech lead leadership
**Short**: Sound technical decisions, improved delivery quality, mentoring, alignment with product, ownership of production outcomes.
**Deep**: Lead is hands-on but operates wider. Set engineering standards, guide architecture, do high-leverage code reviews, unblock cross-team dependencies, improve release reliability, help team make better independent decisions. Strong examples: improved velocity, code quality, incident prevention.

### DSA topics to prioritize
1. Arrays + hashing
2. Two pointers
3. Sliding window
4. Stack + queue
5. Binary search
6. Linked list
7. Trees + BFS/DFS
8. Heaps + top K
9. Backtracking
10. DP basics
11. Graph traversal
12. LRU cache

### DSA questions worth practicing first
1. Two Sum
2. Longest Substring Without Repeating Characters
3. Valid Parentheses
4. Merge Intervals
5. Binary Search
6. Search in Rotated Sorted Array
7. Reverse Linked List
8. Detect Cycle in Linked List
9. Level Order Traversal
10. Lowest Common Ancestor
11. Number of Islands
12. Top K Frequent Elements
13. Course Schedule
14. Coin Change
15. LRU Cache

### First behavioral questions to prepare cold
1. Tell me about yourself.
2. Why are you looking for a change now?
3. Tell me about a difficult production issue you handled.
4. Tell me about a technical disagreement with product or management.
5. Tell me about mentoring a junior engineer.
6. Tell me about a project where you made an architecture trade-off.
7. Tell me about a release that went wrong.
8. Why should we hire you for a mobile lead role?

---

## Appendix G — Deep Q&A Bank with Code Samples + Production Scenarios

> The complete interview coverage map. For each topic: short answer, deep answer, code sample (where relevant), production scenario, and follow-up traps. Read once end-to-end. Re-read sections weakest for you.

---

### G.1 — JavaScript: Execution Context, Call Stack, Hoisting

**Q: Explain execution context.**
**Short**: A container the JS engine creates to run code — has variable environment, lexical environment, and `this` binding.
**Deep**: Two phases — **creation** (memory allocated; `var` → `undefined`, `let/const` → uninitialized in TDZ, function declarations fully hoisted) and **execution** (line-by-line). Three types: Global, Function, Eval. Each call pushes a new context onto the **call stack**.

**Q: What causes stack overflow?**
Unbounded recursion (no base case, or async-look-alike recursion accidentally called sync). In RN, often hits via reducer recursion or render loops.

```js
// stack overflow trap — recursive setState during render
function Bad() {
  const [n, setN] = useState(0);
  setN(n + 1); // ❌ infinite re-render → "Maximum update depth exceeded"
  return <Text>{n}</Text>;
}

// fix: schedule in effect or event
function Good() {
  const [n, setN] = useState(0);
  useEffect(() => { setN(1); }, []); // runs once
  return <Text>{n}</Text>;
}
```

**Q: TDZ (Temporal Dead Zone)?**
The window between entering scope and the `let/const` declaration line. Access throws `ReferenceError`. `var` returns `undefined` instead — that's why TDZ exists, to catch bugs.

**Production scenario — stale state in polling**:
```js
// ❌ stale closure: `count` captured at first render, always 0
useEffect(() => {
  const id = setInterval(() => console.log(count), 1000);
  return () => clearInterval(id);
}, []); // empty deps

// ✅ use ref or functional updater
const countRef = useRef(count);
useEffect(() => { countRef.current = count; }, [count]);
useEffect(() => {
  const id = setInterval(() => console.log(countRef.current), 1000);
  return () => clearInterval(id);
}, []);
```

---

### G.2 — JavaScript: Closures (the most-asked topic)

**Q: What is a closure?**
A function plus the lexical environment it was defined in. Lets the inner function "remember" outer variables after the outer function returns.

```js
function makeCounter() {
  let count = 0;
  return () => ++count;
}
const c = makeCounter();
c(); c(); c(); // 3 — `count` survives via closure
```

**Q: Closure trap in loops.**
```js
// ❌ var → all log 5
for (var i = 0; i < 5; i++) setTimeout(() => console.log(i), 0);

// ✅ let → block-scoped, logs 0..4
for (let i = 0; i < 5; i++) setTimeout(() => console.log(i), 0);
```

**Q: Implement debounce.**
```ts
function debounce<T extends (...args: any[]) => void>(fn: T, ms: number) {
  let t: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    if (t) clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}
// usage: search input — fire only after user stops typing
const debouncedSearch = debounce((q: string) => api.search(q), 300);
```

**Q: Implement throttle.**
```ts
function throttle<T extends (...args: any[]) => void>(fn: T, ms: number) {
  let last = 0;
  return (...args: Parameters<T>) => {
    const now = Date.now();
    if (now - last >= ms) { last = now; fn(...args); }
  };
}
// usage: scroll handler — fire at most once per 100ms
```

**Q: Memoization.**
```ts
function memo<T extends (...args: any[]) => any>(fn: T) {
  const cache = new Map<string, ReturnType<T>>();
  return (...args: Parameters<T>): ReturnType<T> => {
    const k = JSON.stringify(args);
    if (!cache.has(k)) cache.set(k, fn(...args));
    return cache.get(k)!;
  };
}
```

---

### G.3 — JavaScript: Event Loop, Microtasks, Macrotasks

**Q: Microtask vs macrotask order.**
After each macrotask, the engine drains **all** microtasks before the next macrotask or render.
Order: sync code → microtasks (Promises, queueMicrotask) → render → macrotask (setTimeout, setInterval, I/O).

```js
console.log('1');
setTimeout(() => console.log('2'), 0);
Promise.resolve().then(() => console.log('3'));
console.log('4');
// Output: 1, 4, 3, 2
```

**Q: Why does `await` "block"?**
It doesn't block the thread — it suspends the async function and queues continuation as a microtask. The JS thread is free.

**Production scenario — UI freeze**:
A heavy synchronous JSON.parse on a 10MB payload blocks the JS thread → no UI updates, no touch handling. Fix: chunk with `InteractionManager.runAfterInteractions`, move to a Worker (web), or do it natively in a TurboModule.

---

### G.4 — JavaScript: Promises & Async

**Q: Implement `Promise.all` from scratch.**
```ts
function pAll<T>(promises: Promise<T>[]): Promise<T[]> {
  return new Promise((resolve, reject) => {
    const results: T[] = new Array(promises.length);
    let done = 0;
    if (promises.length === 0) return resolve([]);
    promises.forEach((p, i) =>
      Promise.resolve(p).then(
        (v) => { results[i] = v; if (++done === promises.length) resolve(results); },
        reject
      )
    );
  });
}
```

**Q: Concurrency limiter (`pLimit`).**
```ts
function pLimit(n: number) {
  const queue: Array<() => void> = [];
  let active = 0;
  const next = () => { active--; queue.shift()?.(); };
  return <T,>(fn: () => Promise<T>): Promise<T> =>
    new Promise((resolve, reject) => {
      const run = () => {
        active++;
        fn().then(resolve, reject).finally(next);
      };
      active < n ? run() : queue.push(run);
    });
}
// usage: upload 100 images, max 5 concurrent
const limit = pLimit(5);
await Promise.all(images.map(img => limit(() => upload(img))));
```

**Q: API retry with exponential backoff + jitter.**
```ts
async function retry<T>(fn: () => Promise<T>, tries = 3, base = 300): Promise<T> {
  for (let i = 0; i < tries; i++) {
    try { return await fn(); }
    catch (e) {
      if (i === tries - 1) throw e;
      const delay = base * 2 ** i + Math.random() * 100; // jitter
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw new Error('unreachable');
}
```

**Q: `Promise.all` vs `allSettled` vs `race` vs `any`.**
- `all`: rejects fast on first failure. Use when **all must succeed**.
- `allSettled`: never rejects; returns status per promise. Use for **independent fetches**.
- `race`: first to settle (resolve OR reject). Use for **timeout vs request**.
- `any`: first to **resolve** (ignores rejections). Use for **multi-mirror fetch**.

---

### G.5 — TypeScript: Type System Essentials

**Q: `type` vs `interface`.**
- `interface`: declaration merging, extends, best for object/class shapes.
- `type`: unions, intersections, mapped, conditional — more flexible.
- Pick `interface` for public API surfaces, `type` for everything else.

**Q: `any` vs `unknown` vs `never`.**
- `any`: opt-out of type system. Avoid.
- `unknown`: top type. Must narrow before use → safer `any`.
- `never`: bottom type. Functions that throw / infinite loop / exhaustive switch defaults.

```ts
function assertNever(x: never): never { throw new Error(`unexpected ${x}`); }
type Status = 'idle' | 'loading' | 'success' | 'error';
function render(s: Status) {
  switch (s) {
    case 'idle': return null;
    case 'loading': return <Spinner/>;
    case 'success': return <Data/>;
    case 'error': return <Err/>;
    default: return assertNever(s); // compile error if Status grows
  }
}
```

**Q: Generic `useFetch` hook.**
```ts
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [err, setErr] = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    let cancelled = false;
    fetch(url).then(r => r.json()).then((d: T) => {
      if (!cancelled) { setData(d); setLoading(false); }
    }).catch(e => { if (!cancelled) { setErr(e); setLoading(false); } });
    return () => { cancelled = true; };
  }, [url]);
  return { data, err, loading };
}
// usage
const { data } = useFetch<{ id: string; name: string }[]>('/users');
```

**Q: Discriminated unions for API responses.**
```ts
type ApiResult<T> =
  | { status: 'ok'; data: T }
  | { status: 'err'; code: number; message: string };

function handle(r: ApiResult<User>) {
  if (r.status === 'ok') return r.data; // narrowed
  return null; // r is err branch
}
```

**Q: Typed React Navigation.**
```ts
type RootStack = {
  Home: undefined;
  Profile: { userId: string };
  Payment: { orderId: string; amount: number };
};
type Props = NativeStackScreenProps<RootStack, 'Profile'>;
function Profile({ route, navigation }: Props) {
  const { userId } = route.params; // typed
  return <Text>{userId}</Text>;
}
```

**Q: Utility types in real code.**
```ts
interface User { id: string; name: string; email: string; passwordHash: string; }
type PublicUser = Omit<User, 'passwordHash'>;
type UserPatch = Partial<Pick<User, 'name' | 'email'>>;
type UsersById = Record<string, User>;
type FetchReturn = Awaited<ReturnType<typeof fetchUser>>;
```

---

### G.6 — React: Rendering, Reconciliation, Fiber

**Q: What triggers a re-render?**
1. State change (`setState`).
2. Parent re-rendered.
3. Context value changed.
4. Hook causing re-evaluation (e.g., `useSyncExternalStore`).
Props change alone doesn't trigger — parent re-render does.

**Q: Fiber in one paragraph.**
A linked-list tree of work units. Fiber lets React **pause**, **abort**, and **resume** rendering. Two phases: **render** (interruptible — builds work-in-progress tree) and **commit** (synchronous — applies to host). Concurrent features (`useTransition`, Suspense) leverage this.

**Q: Reconciliation rules.**
- Different element types → unmount old, mount new (state lost).
- Same type → reuse, diff props.
- Lists → use **stable unique keys**, not array index when items reorder.

```jsx
// ❌ key=index → wrong unmounts on insert
{items.map((it, i) => <Row key={i} item={it} />)}
// ✅
{items.map(it => <Row key={it.id} item={it} />)}
```

---

### G.7 — React Hooks deep

**Q: `useEffect` cleanup matters.**
Cleanup runs (a) before next effect with changed deps, (b) on unmount. Forgetting cleanup → memory leaks, duplicate listeners, ghost timers.

```jsx
useEffect(() => {
  const sub = api.subscribe(handle);
  return () => sub.unsubscribe(); // ✅ cleanup
}, []);
```

**Q: `useMemo` vs `useCallback` — when not to use.**
Both have a cost (memo + comparison). Skip them for cheap computations or when downstream isn't memoized. Use when:
- Dependency of another memoized component / hook.
- Expensive computation (>1ms).
- Reference stability needed for context/effect deps.

**Q: `useRef` use cases.**
- Mutable value that doesn't trigger render (timer ids, latest props).
- DOM/native handle.
- Imperative APIs via `useImperativeHandle`.

**Q: Custom hook — `usePrevious`.**
```ts
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => { ref.current = value; }, [value]);
  return ref.current;
}
```

**Q: Custom hook — `useDebouncedValue`.**
```ts
function useDebouncedValue<T>(value: T, ms = 300): T {
  const [v, setV] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setV(value), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return v;
}
```

**Q: `useReducer` over `useState` when?**
- Multiple related fields move together.
- Next state depends on previous + action payload.
- You want predictable transitions (testable reducer).

**Q: Context performance trap.**
Every consumer re-renders when context value changes. Fix: split contexts (read vs write), use selectors via `use-context-selector` or Zustand, memoize provider value.

```jsx
// ❌ new object every render
<Ctx.Provider value={{ user, setUser }}>...

// ✅ memoized
const value = useMemo(() => ({ user, setUser }), [user]);
<Ctx.Provider value={value}>...
```

---

### G.8 — React Performance: prevent unnecessary renders

**Q: How to find wasted renders?**
- React DevTools Profiler → "Why did this render?".
- `console.log` with `useRef` counter.
- `whyDidYouRender` lib.

**Q: Stop a list row re-rendering.**
```jsx
const Row = React.memo(function Row({ item, onPress }) {
  return <TouchableOpacity onPress={() => onPress(item.id)}>...</TouchableOpacity>;
});

// parent
const handlePress = useCallback((id) => { /* ... */ }, []);
<FlatList data={data} renderItem={({item}) => <Row item={item} onPress={handlePress}/>}/>
```

**Q: `useTransition` example.**
```jsx
const [isPending, startTransition] = useTransition();
const onChange = (q) => {
  setQuery(q); // urgent
  startTransition(() => setResults(filter(big, q))); // non-urgent
};
```

---

### G.9 — React Native Architecture (Old vs New)

**Q: Threads in RN.**
- **JS thread**: your JS, React reconciler, business logic.
- **UI (Main) thread**: native views, gesture handling, paints.
- **Shadow thread**: Yoga layout calculations.
- **Native modules thread(s)**: long-running native work (network, storage).

**Q: Old bridge problems.**
- Async: every call serialized to JSON, sent across.
- Batched: latency for high-frequency calls (animations, gestures).
- Single bottleneck: JS thread block → UI freeze.

**Q: New Architecture.**
- **JSI**: C++ layer letting JS hold references to native objects, call methods sync.
- **Fabric**: new renderer; concurrent-safe, sync layout when needed.
- **TurboModules**: lazy-loaded native modules, JSI-backed, sync calls possible.
- **Codegen**: generates type-safe interfaces from TS specs at build time → no manual marshalling.

**Q: Concrete migration steps.**
1. Bump RN to ≥0.71 (ideally 0.74+).
2. Enable `newArchEnabled=true` in `gradle.properties` and Podfile.
3. Convert custom modules to TurboModules / Fabric components (write specs in TS, run codegen).
4. Audit third-party libs — many still ship interop shims.
5. Test thoroughly: gestures, animations, memory.

---

### G.10 — Hermes & Metro

**Q: Hermes wins.**
- Bytecode precompiled at build → no parse cost on device.
- Faster cold start (~30–50% on low-end Android).
- Smaller memory footprint, smaller heap.
- Better GC tuned for short-lived RN objects.

**Q: Hermes vs JSC trade-offs.**
JSC has historically had faster steady-state JIT for some hot loops; Hermes wins startup + memory. For RN apps, startup matters most → Hermes default.

**Q: Metro `inlineRequires`.**
Defers `require` until first call → modules load only when needed → faster startup.
```js
// metro.config.js
module.exports = {
  transformer: {
    getTransformOptions: async () => ({
      transform: { experimentalImportSupport: false, inlineRequires: true },
    }),
  },
};
```

**Q: Bundle splitting in RN.**
RN doesn't natively split like web. Approaches: lazy import + `React.lazy` + Suspense for screens, RAM bundles (legacy), Hermes segmented bundles.

---

### G.11 — RN Performance: Lists, Animations, Images

**Q: Why is FlatList laggy on 5000 rows?**
- Rows not memoized → every parent render re-renders all rows.
- Large complex rows → blow virtualization budget.
- No `getItemLayout` → measure-on-mount cost.
- Synchronous heavy work in `renderItem`.

**Q: FlatList → FlashList migration tips.**
```jsx
import { FlashList } from '@shopify/flash-list';

<FlashList
  data={data}
  estimatedItemSize={64}     // required-ish; tune
  keyExtractor={(it) => it.id}
  renderItem={renderRow}
  drawDistance={400}         // px
  removeClippedSubviews
  // for grids: numColumns, overrideItemLayout
/>
```
Wins: 5–10× perf on long lists, lower memory, no blank cells.

**Q: Reanimated 3 worklet.**
```ts
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';

const x = useSharedValue(0);
const style = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));
const onPress = () => { x.value = withSpring(x.value === 0 ? 100 : 0); };

return <Animated.View style={[styles.box, style]} />;
```
Worklets run on UI thread → no JS-bridge round-trip per frame.

**Q: `runOnJS` vs `runOnUI`.**
- Worklets execute on UI thread. To call regular JS (e.g., `setState`, navigation), wrap in `runOnJS`.
- To send code to UI thread from JS, `runOnUI`.

**Q: Image best practices (expo-image).**
```jsx
import { Image } from 'expo-image';
<Image
  source={{ uri }}
  placeholder={blurhash}
  contentFit="cover"
  transition={200}
  cachePolicy="memory-disk"
/>
```
- Pre-resize on backend (don't ship 4096×4096 thumbnails).
- Use blurhash placeholders.
- WebP/AVIF if supported.
- Avoid `Image` inside heavy `renderItem` w/o memoization.

---

### G.12 — Native Modules (Swift + Kotlin TurboModule)

**Q: When to write a native module?**
- Need a platform API not exposed (e.g., specific Bluetooth profile).
- Heavy work better done off JS thread.
- Bridging existing native SDK.

**Swift TurboModule (battery)**:
```swift
@objc(BatteryModule)
class BatteryModule: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool { false }
  @objc func getLevel(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    resolve(UIDevice.current.batteryLevel)
  }
}
```

**Kotlin module (battery)**:
```kotlin
class BatteryModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
  override fun getName() = "BatteryModule"
  @ReactMethod fun getLevel(promise: Promise) {
    val bm = reactApplicationContext.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    promise.resolve(bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY))
  }
}
```

**JS side**:
```ts
import { NativeModules } from 'react-native';
const { BatteryModule } = NativeModules;
const level = await BatteryModule.getLevel(); // 0..1 (iOS) or 0..100 (Android)
```

---

### G.13 — Debugging Production: full toolkit

**Q: Memory leak — find and fix.**
Symptom: app gets slower over time, eventually crashes (OOM). Steps:
1. Reproduce with repeated nav into the suspect screen.
2. **iOS**: Xcode → Product → Profile → **Allocations** + **Leaks** instrument. Mark generations, navigate, see retained objects.
3. **Android**: Android Studio Profiler → Memory → record allocations → trigger GC → snapshot heap.
4. RN: use **react-devtools** to inspect component tree count over navigations.
5. Common culprits: uncleaned listeners, captured large closures, navigation stack retaining screens, anonymous functions in subscriptions.

```jsx
// ❌ leak
useEffect(() => {
  api.on('update', handle);
}, []);

// ✅
useEffect(() => {
  api.on('update', handle);
  return () => api.off('update', handle);
}, []);
```

**Q: ANR (Android) investigation.**
ANR = main thread blocked >5s. Sources: large JSON parse on UI thread, sync sqlite on UI, sync bridge calls. Check `/data/anr/traces.txt` (`adb pull /data/anr/`), Play Console → Android vitals → ANRs. Fix: move heavy work off main thread (TurboModule on background queue / coroutine).

**Q: Symbolicate a crash.**
- iOS: upload `.dSYM` to Sentry (Fastlane plugin or `sentry-cli upload-dif`).
- Android: upload `mapping.txt` per build (R8/Proguard).
- Hermes: upload sourcemap + bytecode map (`hbc` format) — Sentry CLI has `react-native-sourcemaps`.

```sh
sentry-cli react-native xcode --bundle main.jsbundle --dist 1234 \
  --sourcemap main.jsbundle.map --release com.app@1.2.3
```

**Q: Charles Proxy use cases.**
Inspect HTTPS traffic on device (install root CA), throttle for offline tests, replay/edit requests, find token leaks in logs.

---

### G.14 — State Management: realistic patterns

**Q: 3-bucket model.**
- **Server state** → React Query / RTK Query (cache, retry, invalidation).
- **Global UI / domain state** → RTK or Zustand (auth, theme, feature flags).
- **Local component state** → `useState` / `useReducer`.

**Q: React Query — optimistic update with rollback.**
```ts
const qc = useQueryClient();
const mutation = useMutation({
  mutationFn: (todo) => api.updateTodo(todo),
  onMutate: async (newTodo) => {
    await qc.cancelQueries({ queryKey: ['todos'] });
    const prev = qc.getQueryData(['todos']);
    qc.setQueryData(['todos'], (old: Todo[]) => old.map(t => t.id === newTodo.id ? newTodo : t));
    return { prev };
  },
  onError: (_e, _v, ctx) => qc.setQueryData(['todos'], ctx?.prev), // rollback
  onSettled: () => qc.invalidateQueries({ queryKey: ['todos'] }),
});
```

**Q: Zustand store with selector.**
```ts
import { create } from 'zustand';
type Store = { count: number; inc: () => void; };
const useStore = create<Store>((set) => ({
  count: 0,
  inc: () => set((s) => ({ count: s.count + 1 })),
}));
// component subscribes only to slice → no re-render on other fields
const count = useStore((s) => s.count);
```

**Q: Redux Toolkit slice.**
```ts
const cartSlice = createSlice({
  name: 'cart',
  initialState: { items: [] as Item[] },
  reducers: {
    add: (s, a: PayloadAction<Item>) => { s.items.push(a.payload); }, // immer
    clear: (s) => { s.items = []; },
  },
});
```

---

### G.15 — Offline-first architecture

**Q: Outbox pattern.**
Writes go to a local queue first. Background worker drains queue → server. Each item has unique idempotency key. On retry, server dedupes.

```ts
type OutboxItem = { id: string; op: 'createTodo' | 'updateTodo'; payload: any; tries: number };

async function enqueue(op: OutboxItem['op'], payload: any) {
  const item: OutboxItem = { id: uuid(), op, payload, tries: 0 };
  const q = JSON.parse(await mmkv.getString('outbox') || '[]');
  q.push(item);
  await mmkv.set('outbox', JSON.stringify(q));
}

async function flush() {
  const q: OutboxItem[] = JSON.parse(await mmkv.getString('outbox') || '[]');
  for (const it of q) {
    try {
      await api[it.op](it.payload, { idempotencyKey: it.id });
      remove(it.id);
    } catch (e) {
      it.tries++;
      if (it.tries >= 5) deadLetter(it);
    }
  }
}
```

**Q: Conflict resolution strategies.**
- **Last-Write-Wins (LWW)**: simple, lossy.
- **Server-wins**: trust source of truth; surface conflicts to user.
- **CRDTs**: for concurrent collaborative editing (rare in mobile).
- **Merge by field**: domain-specific (e.g., merge cart line items by SKU).

**Q: MMKV vs AsyncStorage.**
MMKV is sync, mmap-backed, ~30× faster, encrypted out of the box. Default to MMKV for any KV. AsyncStorage only for legacy.

```ts
import { MMKV } from 'react-native-mmkv';
const storage = new MMKV({ id: 'auth', encryptionKey: 'k' });
storage.set('token', 'abc');
const t = storage.getString('token');
```

---

### G.16 — Navigation & Deep Linking (secure)

**Q: Native Stack vs JS Stack.**
Native Stack uses platform navigators (UINavigationController / Fragment) → faster transitions, native gestures, lower JS load. Use it unless you need a feature only JS Stack supports.

**Q: Auth gate pattern.**
```jsx
function Root() {
  const { user, loading } = useAuth();
  if (loading) return <Splash/>;
  return (
    <NavigationContainer linking={linking}>
      {user ? <AppStack/> : <AuthStack/>}
    </NavigationContainer>
  );
}
```
Switching the entire stack on auth change avoids back-stack leaking authed screens.

**Q: Secure deep linking checklist.**
- Validate every param (`zod` schema).
- Reject unknown routes.
- Never auto-execute side effects (e.g., `payment://confirm?amount=999`) — always require user confirmation.
- Strip and ignore unexpected query params.
- Authenticated routes go through auth gate; do **not** trust deep link to bypass auth.
- Don't include tokens / OTPs in deep links.

```ts
const PaymentParams = z.object({ orderId: z.string().uuid(), amount: z.number().int().positive() });
function PaymentScreen({ route }) {
  const parsed = PaymentParams.safeParse(route.params);
  if (!parsed.success) return <NotFound/>;
  // ...
}
```

**Q: Universal Links vs App Links vs Branch.**
- iOS Universal Links: requires AASA file at `https://yourdomain/.well-known/apple-app-site-association`.
- Android App Links: requires `assetlinks.json` + `autoVerify=true` in intent filter.
- Branch: deferred deep links (works pre-install, attribution).

---

### G.17 — Networking & API layer

**Q: Single-flight token refresh.**
```ts
let refreshPromise: Promise<string> | null = null;

async function getValidToken(): Promise<string> {
  if (!isExpired()) return getToken();
  if (!refreshPromise) {
    refreshPromise = api.refresh().finally(() => { refreshPromise = null; });
  }
  return refreshPromise;
}

// axios interceptor
axios.interceptors.response.use(
  (r) => r,
  async (err) => {
    if (err.response?.status === 401) {
      const token = await getValidToken();
      err.config.headers.Authorization = `Bearer ${token}`;
      return axios(err.config);
    }
    throw err;
  }
);
```

**Q: Request cancellation with AbortController.**
```ts
useEffect(() => {
  const ctrl = new AbortController();
  fetch('/feed', { signal: ctrl.signal }).then(...).catch(e => {
    if (e.name === 'AbortError') return;
    setErr(e);
  });
  return () => ctrl.abort();
}, [feedId]);
```

**Q: WebSocket reconnection with backoff.**
```ts
function connect() {
  const ws = new WebSocket(url);
  let attempt = 0;
  ws.onopen = () => { attempt = 0; };
  ws.onclose = () => {
    const wait = Math.min(30000, 1000 * 2 ** attempt++) + Math.random() * 500;
    setTimeout(connect, wait);
  };
  ws.onmessage = handle;
  // heartbeat
  const id = setInterval(() => ws.readyState === 1 && ws.send('ping'), 25000);
  ws.onclose = () => clearInterval(id);
}
```

---

### G.18 — Security: tokens, pinning, biometrics

**Q: Where to store tokens.**
- iOS: Keychain (`react-native-keychain` with `accessControl: BIOMETRY_ANY`).
- Android: EncryptedSharedPreferences / Keystore-backed.
- **Never** in AsyncStorage / MMKV unencrypted / Redux persist plain.

```ts
import * as Keychain from 'react-native-keychain';
await Keychain.setGenericPassword('token', accessToken, {
  service: 'auth',
  accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET,
  accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
});
```

**Q: OAuth PKCE flow (mobile).**
1. App generates `code_verifier` + `code_challenge` (SHA-256).
2. Open `ASWebAuthenticationSession` (iOS) / Custom Tabs (Android) to authorize URL.
3. Receive code via deep link callback.
4. Exchange code + verifier for tokens (no client secret needed → safe for public clients).

**Q: Certificate pinning.**
Pin via `react-native-ssl-pinning` or native config. Pin to **public key** (SPKI), not full cert (rotation-friendly). Always have a backup pin.

**Q: OWASP MASVS L2 quick checks.**
- No secrets in source / strings.xml / Info.plist.
- TLS 1.2+, no plaintext (`cleartextTrafficPermitted=false`).
- Detect rooted/jailbroken devices for fintech (`jail-monkey`).
- No sensitive data in logs / Sentry breadcrumbs.
- App backgrounding → blur screen content for sensitive screens.

```jsx
useEffect(() => {
  const sub = AppState.addEventListener('change', s => {
    setBlur(s !== 'active');
  });
  return () => sub.remove();
}, []);
```

---

### G.19 — Testing in depth

**Jest + RNTL component test**:
```tsx
import { render, fireEvent, screen } from '@testing-library/react-native';

test('login button submits credentials', async () => {
  const onSubmit = jest.fn();
  render(<Login onSubmit={onSubmit} />);
  fireEvent.changeText(screen.getByPlaceholderText('Email'), 'a@b.com');
  fireEvent.changeText(screen.getByPlaceholderText('Password'), 'pw');
  fireEvent.press(screen.getByText('Sign in'));
  expect(onSubmit).toHaveBeenCalledWith({ email: 'a@b.com', password: 'pw' });
});
```

**Mocking native module**:
```ts
jest.mock('react-native-keychain', () => ({
  setGenericPassword: jest.fn().mockResolvedValue(true),
  getGenericPassword: jest.fn().mockResolvedValue({ password: 'tok' }),
}));
```

**Maestro flow** (`flow.yaml`):
```yaml
appId: com.app
---
- launchApp
- tapOn: "Email"
- inputText: "a@b.com"
- tapOn: "Password"
- inputText: "pw"
- tapOn: "Sign in"
- assertVisible: "Welcome"
```

**Detox config snippet**:
```js
// .detoxrc.js
module.exports = {
  apps: { 'ios.debug': { type: 'ios.app', binaryPath: 'ios/build/.../App.app' } },
  devices: { simulator: { type: 'ios.simulator', device: { type: 'iPhone 15' } } },
  configurations: { 'ios.sim.debug': { device: 'simulator', app: 'ios.debug' } },
};
```

---

### G.20 — CI/CD: GitHub Actions + EAS

```yaml
# .github/workflows/mobile.yml
name: mobile
on: [pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'pnpm' }
      - uses: pnpm/action-setup@v3
        with: { version: 9 }
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm test --ci --coverage
  preview-build:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: expo/expo-github-action@v8
        with: { eas-version: latest, token: ${{ secrets.EXPO_TOKEN }} }
      - run: eas build --platform all --profile preview --non-interactive --no-wait
```

**Q: OTA rollout policy.**
- Stage rollouts: 10% → 50% → 100% over 24–72h.
- Auto-rollback on Sentry crash signature spike.
- No native code in OTA — that requires store submission.
- Canary channel for internal users.

---

### G.21 — Observability: Sentry + Performance

```ts
import * as Sentry from '@sentry/react-native';
Sentry.init({
  dsn: 'https://...',
  tracesSampleRate: 0.2,
  profilesSampleRate: 0.1,
  beforeBreadcrumb: (b) => {
    if (b.category === 'console' && b.message?.includes('token')) return null;
    return b;
  },
  beforeSend: (e) => scrubPII(e),
});

// trace a screen
const t = Sentry.startTransaction({ name: 'PortfolioScreen' });
Sentry.getCurrentHub().configureScope(s => s.setSpan(t));
// ...work...
t.finish();
```

---

### G.22 — Mobile System Design (3 worked walkthroughs)

#### Design 1 — Offline-first fintech portfolio
**Requirements**: live prices, offline view, secure transactions, low-end Android.
**Layers**:
- UI (RN + FlashList for holdings).
- Domain (use cases: viewPortfolio, placeOrder).
- Data: Repository → React Query (cache) + WatermelonDB (persistent) + WebSocket for prices.
- Sync: outbox for orders, idempotency keys, server is source of truth.
- Security: Keychain tokens, biometric on order, cert pinning, rooted-device block.
- Observability: Sentry + custom perf marks for order placement.
**Trade-offs**: WatermelonDB chosen over SQLite for reactivity; React Query for cache lifecycle; WebSocket multiplexed per-symbol subscription.

#### Design 2 — WhatsApp-like messaging
- Local SQLite for messages; pagination by `created_at` cursor.
- Send queue with retry + ordering per chat.
- Push notifications (FCM/APNS) carry payload hash → fetch full content on open.
- E2E encryption via Signal protocol (out-of-scope for mobile lead, but mention).
- Media: chunked upload, resumable, thumbnail-first.

#### Design 3 — Swiggy-like home + tracking
- Home: SSR-feel via RN (server-driven UI JSON + RN renderer).
- Live tracking: WebSocket + Map clustering, throttled location updates.
- Performance: 5–10s budget for cold start, FlashList for restaurants, image CDN with WebP.

---

### G.23 — DSA: 12 must-rehearse with patterns

#### Two Sum (HashMap)
```ts
function twoSum(nums: number[], target: number): number[] {
  const m = new Map<number, number>();
  for (let i = 0; i < nums.length; i++) {
    const need = target - nums[i];
    if (m.has(need)) return [m.get(need)!, i];
    m.set(nums[i], i);
  }
  return [];
}
```

#### Longest Substring Without Repeating Characters (Sliding Window)
```ts
function lengthOfLongestSubstring(s: string): number {
  const seen = new Map<string, number>();
  let l = 0, best = 0;
  for (let r = 0; r < s.length; r++) {
    if (seen.has(s[r]) && seen.get(s[r])! >= l) l = seen.get(s[r])! + 1;
    seen.set(s[r], r);
    best = Math.max(best, r - l + 1);
  }
  return best;
}
```

#### Valid Parentheses (Stack)
```ts
function isValid(s: string): boolean {
  const pair: Record<string, string> = { ')': '(', ']': '[', '}': '{' };
  const st: string[] = [];
  for (const c of s) {
    if (c in pair) { if (st.pop() !== pair[c]) return false; }
    else st.push(c);
  }
  return st.length === 0;
}
```

#### Merge Intervals
```ts
function merge(intervals: number[][]): number[][] {
  intervals.sort((a, b) => a[0] - b[0]);
  const out: number[][] = [];
  for (const [s, e] of intervals) {
    if (out.length && s <= out[out.length - 1][1]) out[out.length - 1][1] = Math.max(out[out.length - 1][1], e);
    else out.push([s, e]);
  }
  return out;
}
```

#### Binary Search
```ts
function bsearch(a: number[], t: number): number {
  let l = 0, r = a.length - 1;
  while (l <= r) {
    const m = (l + r) >> 1;
    if (a[m] === t) return m;
    a[m] < t ? l = m + 1 : r = m - 1;
  }
  return -1;
}
```

#### Reverse Linked List
```ts
function reverse(head: Node | null): Node | null {
  let prev = null, cur = head;
  while (cur) { const n = cur.next; cur.next = prev; prev = cur; cur = n; }
  return prev;
}
```

#### Detect Cycle (Floyd)
```ts
function hasCycle(head: Node | null): boolean {
  let slow = head, fast = head;
  while (fast?.next) { slow = slow!.next; fast = fast.next.next; if (slow === fast) return true; }
  return false;
}
```

#### Level Order Traversal (BFS)
```ts
function levelOrder(root: TreeNode | null): number[][] {
  if (!root) return [];
  const q = [root], out: number[][] = [];
  while (q.length) {
    const lvl: number[] = []; const n = q.length;
    for (let i = 0; i < n; i++) {
      const node = q.shift()!;
      lvl.push(node.val);
      if (node.left) q.push(node.left);
      if (node.right) q.push(node.right);
    }
    out.push(lvl);
  }
  return out;
}
```

#### Number of Islands (DFS)
```ts
function numIslands(grid: string[][]): number {
  let count = 0;
  const dfs = (i: number, j: number) => {
    if (i<0||j<0||i>=grid.length||j>=grid[0].length||grid[i][j] !== '1') return;
    grid[i][j] = '0';
    dfs(i+1,j); dfs(i-1,j); dfs(i,j+1); dfs(i,j-1);
  };
  for (let i = 0; i < grid.length; i++)
    for (let j = 0; j < grid[0].length; j++)
      if (grid[i][j] === '1') { count++; dfs(i, j); }
  return count;
}
```

#### Top K Frequent (Heap / Bucket sort)
```ts
function topKFrequent(nums: number[], k: number): number[] {
  const cnt = new Map<number, number>();
  nums.forEach(n => cnt.set(n, (cnt.get(n) ?? 0) + 1));
  const buckets: number[][] = Array.from({ length: nums.length + 1 }, () => []);
  cnt.forEach((c, n) => buckets[c].push(n));
  const out: number[] = [];
  for (let i = buckets.length - 1; i >= 0 && out.length < k; i--) out.push(...buckets[i]);
  return out.slice(0, k);
}
```

#### LRU Cache
```ts
class LRU<K, V> {
  private map = new Map<K, V>();
  constructor(private cap: number) {}
  get(k: K): V | -1 {
    if (!this.map.has(k)) return -1 as any;
    const v = this.map.get(k)!;
    this.map.delete(k); this.map.set(k, v); // refresh
    return v;
  }
  put(k: K, v: V) {
    if (this.map.has(k)) this.map.delete(k);
    else if (this.map.size === this.cap) this.map.delete(this.map.keys().next().value);
    this.map.set(k, v);
  }
}
```

#### Coin Change (DP)
```ts
function coinChange(coins: number[], amount: number): number {
  const dp = new Array(amount + 1).fill(Infinity); dp[0] = 0;
  for (let i = 1; i <= amount; i++)
    for (const c of coins) if (i - c >= 0) dp[i] = Math.min(dp[i], dp[i - c] + 1);
  return dp[amount] === Infinity ? -1 : dp[amount];
}
```

---

### G.24 — Real Production Scenarios (12 walkthroughs)

#### S1 — App startup is 5s on Android
**Diagnose**: Hermes profiler + Android Studio CPU profiler on cold start. Look for: eager imports, sync bridge calls, large JSON in initial bundle, font loading.
**Fix toolkit**:
- Enable Hermes + `inlineRequires`.
- Lazy-load heavy screens with `React.lazy`.
- Defer non-critical SDKs (analytics, A/B) to `InteractionManager.runAfterInteractions(...)`.
- Move remote config to async with cached defaults.
- Trim bundle: `dayjs` over `moment`, `date-fns` per-fn imports.
- Pre-warm JS bundle on splash for low-end Android.

#### S2 — Memory leak in production
- Symptom: P95 RAM grows from 120MB → 380MB after 30 min of use.
- Tooling: Xcode Allocations + Android Profiler heap snapshots between navigations.
- Common: navigation kept screens mounted (use `unmountOnBlur` for tab screens), uncleaned listeners, Reanimated worklets capturing stale refs, Sentry breadcrumb buffers too large.

#### S3 — Infinite re-renders
- "Maximum update depth exceeded".
- Causes: setState in render, object/array recreated each render passed to memoized child via context, useEffect with deps that include a new object every render.
- Fix: stabilize deps with `useMemo`/`useCallback`; move setState into events/effects.

#### S4 — Push notifications delayed 10+ minutes
- Android: Doze mode, manufacturer battery optimizers (Xiaomi/Oppo/OnePlus killing services). Solutions: high-priority FCM, request battery-optimization exception with rationale UI, silent push + sync on open.
- iOS: APNS priority 10 for visible alerts, priority 5 for background.

#### S5 — Razorpay duplicate charge
- Cause: user double-tapped pay → 2 SDK calls → 2 successful charges.
- Fix: idempotency key per order on backend; disable button on press + show spinner; client-side request dedup with in-flight map; reconcile from backend on app reopen.

#### S6 — Deep link breaks on iOS 17 update
- AASA file might be cached. Force re-validation: bump app version, AASA `apps` array changed. Verify with `/apps` JSON endpoint, AASA validator. Check Universal Link entitlement signed correctly.

#### S7 — OTA update crashes 4% of users
- Sentry release health → see crash spike on new bundle.
- Action: revert OTA channel immediately (`eas update --branch production --message "rollback"` or republish previous). Post-mortem: missing device matrix, no staged rollout.

#### S8 — Large list lagging on low-end Android
- Switch to FlashList; memoize rows; `removeClippedSubviews`; reduce row complexity (no nested ScrollView), images via expo-image with sized URLs.

#### S9 — Crash only on Android 12, 0.4% rate
- Symbolicate via `mapping.txt`. Check OEM-specific (often Samsung One UI). Look for: foreground service crashes (Android 12 restricted), exact alarm restrictions, splash screen API changes.

#### S10 — iOS code signing failure in CI
- Cause: provisioning profile expired / wrong team / capability mismatch.
- Use Fastlane `match` with read-only mode in CI, store certs in private repo. Rotate via `match nuke development` then re-provision.

#### S11 — API timeouts spike at peak hours
- Diagnose: Sentry performance, distinguish DNS vs TLS vs server time.
- Mitigations: client-side request coalescing, `Cache-Control: stale-while-revalidate`, exponential backoff with jitter, circuit breaker (open after N failures, fail fast for cooldown period).

#### S12 — WebSocket reconnect loops drain battery
- Bug: reconnect with 0ms backoff after server forcibly closes.
- Fix: exponential backoff with jitter (capped at 30s), heartbeat every 25s, only reconnect when network reachable (`@react-native-community/netinfo`), exponential backoff resets on stable connection >2 min.

---

### G.25 — Company-specific prep (deeper)

#### PhonePe — fintech architecture, performance, reliability
- Will ask: how do you guarantee at-most-once payment? (idempotency keys + backend reconciliation), offline payment queue design, secure token storage, performance on Android Go.
- Bring numbers: cold start, crash-free %, payment success rate.

#### CRED — animation, UI polish
- Reanimated 3 + Skia. Show worklet code. Discuss frame budget (16.67ms @ 60fps). Discuss gesture-driven animations vs spring physics.
- Will probe: how do you keep 60fps in long lists with parallax + blur?

#### Razorpay — payments + reliability
- Idempotency, reconciliation, webhook handling, SDK integration patterns, PCI scope minimization (tokens, not card numbers).
- "Tell me about a payment failure incident" → STAR story 4 + 9.

#### Groww — realtime + offline
- WebSocket multiplexing for tickers, throttling UI updates (RAF or 250ms windows), persistent local store for last seen prices, optimistic order placement.

#### Swiggy — performance + realtime
- Map clustering, location update throttling, deep link to order, server-driven UI for home feed, A/B test infra.

#### Flipkart — list optimization + low-end Android
- FlashList, image strategy, bundle slimming, RAM-bundle / segment loading, ANR debugging on Android Go.

#### Microsoft / Atlassian — RN platform depth
- Will go deep on JSI, native modules, monorepo, codegen. Be ready to whiteboard a TurboModule spec and explain when you'd write a Fabric component.

---

### G.26 — Cross-cutting interview wisdom

**The 5 questions you should always be ready to ask back**:
1. "What does success look like for this role at 6 months and 1 year?"
2. "Where does the team spend the most time today — and where would you want it to spend more?"
3. "How are mobile decisions made — eng-led, PM-led, design-led?"
4. "What's the on-call rotation and incident process?"
5. "What's the biggest tech-debt item the next hire would inherit?"

**Red flags in interviews** (yours to spot):
- No mention of testing or CI in their process.
- Single mobile engineer with no growth path.
- "Move fast" without "rollback fast".
- Comp band refused even after final round.
- Recruiter pushes back hard on competing-offer disclosure.

**Negotiation script (after offer)**:
> "Thank you for the offer — I'm excited about the role. I'm currently in final stages with [N] other companies in similar bands, and the offers I'm seeing are in the ₹[X]–[Y] LPA fixed range. Given my fintech mobile lead profile, what flexibility is there to bring this in line? I'd love to commit to [Company] this week if we can land in that range."

---

## End

This is your single source. Read top-to-bottom once. Then revise by section. If you can answer every question in Appendix G out loud — short and deep versions — you're ready for any RN/mobile-lead loop in India.

Hands-on artifacts to build alongside (do at least 10):
1. Custom hooks lib (`useDebounce`, `useFetch`, `usePrevious`, `useInterval`, `useAsync`).
2. `pLimit` + `retry` + `Promise.all` from scratch.
3. Typed RN navigation with auth gate + secure deep links.
4. Single-flight refresh interceptor.
5. MMKV-backed outbox with sync-on-reconnect.
6. RN screen with React Query optimistic mutation + rollback.
7. FlatList → FlashList migration with measured FPS gain.
8. Reanimated 3 gesture-driven animation.
9. Swift + Kotlin native module returning battery + emitting changes.
10. Sentry + sourcemap upload via Fastlane in GitHub Actions.
11. Maestro E2E flow for login + payment.
12. Mobile system design doc for offline-first fintech (1 page).
13. LRU cache + 5 LeetCode mediums per pattern.
14. Recorded 2-min versions of all 10 STAR stories.
15. Resume + LinkedIn updated per Appendices C & D.

Old PDFs archived at `Study-Pre/archive/`. Existing `study/01-20.md` files remain as deeper reference but are no longer required reading — everything essential is here.

---

## Appendix H — Gap-fill: topics promised by the handbook but missing earlier

> Theory + code + real-world problem + solution. Read after Appendix G.

---

### H.1 — Push Notifications (FCM + APNs + Expo)

**Theory**: FCM delivers to Android, APNs to iOS. Expo Notifications wraps both. Three message kinds:
- **Notification message** — system shows alert; OS handles when app killed.
- **Data-only / silent push** — app code runs on receipt; budget-limited on iOS, throttled on Android Doze.
- **Notification + data** — alert + custom payload (recommended for routing).

**Setup (Expo)**:
```ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true, shouldPlaySound: true, shouldSetBadge: true,
  }),
});

export async function registerForPush() {
  if (!Device.isDevice) return null;
  const { status: existing } = await Notifications.getPermissionsAsync();
  let status = existing;
  if (status !== 'granted') ({ status } = await Notifications.requestPermissionsAsync());
  if (status !== 'granted') return null;
  const token = (await Notifications.getExpoPushTokenAsync({ projectId: '...' })).data;
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'default', importance: Notifications.AndroidImportance.HIGH,
      vibrationPattern: [0, 250, 250, 250], lightColor: '#FF231F7C',
    });
  }
  return token;
}
```

**Routing on tap (deep link via notification)**:
```ts
useEffect(() => {
  const sub = Notifications.addNotificationResponseReceivedListener((resp) => {
    const data = resp.notification.request.content.data as { route?: string; params?: any };
    if (data.route) navigationRef.navigate(data.route, data.params);
  });
  return () => sub.remove();
}, []);
```

**Real production problems & solutions**:
| Problem | Cause | Fix |
|---|---|---|
| Notifications delayed 10+ min on Xiaomi/Oppo | OEM kills background services | Send as `priority: high` FCM, prompt user to disable battery optimization, fall back to sync-on-open |
| Duplicate notifications | Multiple FCM tokens registered for same device | Server-side dedupe by `installation_id`; clean tokens on app reinstall |
| Notification opens wrong screen on cold start | Initial notification not handled | Use `getLastNotificationResponseAsync()` on launch + buffer until navigator ready |
| iOS silent push not delivered | Wrong `content-available: 1` or low system priority | Use `apns-priority: 5`, payload size ≤4KB, no UI keys |
| Notifications on Android 13+ never appear | `POST_NOTIFICATIONS` permission required | Request runtime permission post-install, gracefully degrade |

---

### H.2 — Accessibility (a11y) + Internationalization (i18n)

**Theory**: WCAG 2.2 AA is the baseline. RN exposes `accessibilityLabel`, `accessibilityHint`, `accessibilityRole`, `accessibilityState`. Screen readers: VoiceOver (iOS), TalkBack (Android). 4.5:1 contrast for body text, 3:1 for large text. Min touch target 44×44 pt (iOS) / 48×48 dp (Android).

**Code — accessible button**:
```jsx
<Pressable
  onPress={onSubmit}
  accessible
  accessibilityRole="button"
  accessibilityLabel="Confirm payment of ₹2,499"
  accessibilityHint="Double-tap to charge your card"
  accessibilityState={{ disabled: loading, busy: loading }}
  style={({ pressed }) => [styles.btn, pressed && styles.btnPressed]}
>
  <Text style={styles.btnText}>Pay ₹2,499</Text>
</Pressable>
```

**Color-blind safe palette** — never use color alone. Pair with icon/text.
```jsx
<View style={{ flexDirection: 'row', alignItems: 'center' }}>
  <Icon name={ok ? 'check' : 'alert'} color={ok ? '#0a7' : '#c33'} />
  <Text>{ok ? 'Verified' : 'Failed — retry'}</Text>
</View>
```

**Dynamic type / font scaling**:
```jsx
<Text allowFontScaling style={{ fontSize: 16 }} maxFontSizeMultiplier={1.6}>
  Body
</Text>
```
Cap multiplier (1.4–1.6) to prevent layout breakage on max accessibility font.

**i18n with `i18next`**:
```ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
i18n.use(initReactI18next).init({
  resources: { en: { tr: { hello: 'Hello {{name}}' } }, hi: { tr: { hello: 'नमस्ते {{name}}' } } },
  lng: 'en', fallbackLng: 'en', interpolation: { escapeValue: false },
});

// component
const { t, i18n } = useTranslation('tr');
<Text>{t('hello', { name: 'Rajeev' })}</Text>
```

**RTL handling**:
```ts
import { I18nManager } from 'react-native';
I18nManager.allowRTL(true);
I18nManager.forceRTL(lang === 'ar');
// requires app reload (RNRestart) to take effect
```

**Real problems**:
| Problem | Solution |
|---|---|
| VoiceOver reads "image" for an icon button | Add `accessibilityLabel` + `accessibilityRole="button"` |
| Modal blocks screen reader from reaching content behind | Use `accessibilityViewIsModal` on iOS, `importantForAccessibility="yes-hide-descendants"` on siblings |
| RTL flips icons that shouldn't flip (e.g., logo) | Wrap with `style={{ transform: [{ scaleX: I18nManager.isRTL ? -1 : 1 }] }}` only on directional icons |
| Large fonts break button width | Use `numberOfLines`, `adjustsFontSizeToFit` (iOS), `flexShrink: 1` |

---

### H.3 — Android platform deep (lifecycle, Gradle, R8/Proguard)

**Activity lifecycle (RN single-activity)**:
`onCreate` → `onStart` → `onResume` → (running) → `onPause` → `onStop` → `onDestroy`. RN entry point `MainActivity` extends `ReactActivity`.

**ANR debugging**:
```sh
adb shell ps | grep com.app
adb pull /data/anr/traces.txt   # main-thread stack snapshots
adb logcat -s ActivityManager:I  # ANR markers
```

**Gradle build variants** (`android/app/build.gradle`):
```groovy
android {
  flavorDimensions "env"
  productFlavors {
    dev      { applicationIdSuffix ".dev"; resValue "string", "app_name", "App Dev" }
    staging  { applicationIdSuffix ".staging" }
    prod     { /* default */ }
  }
  buildTypes {
    release {
      minifyEnabled true
      shrinkResources true
      proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
    }
  }
}
```

**R8/Proguard rules — keep RN Hermes intact**:
```
-keep class com.facebook.hermes.unicode.** { *; }
-keep class com.facebook.jni.** { *; }
-keepattributes *Annotation*,SourceFile,LineNumberTable
```

**APK size reduction**:
- Enable Hermes + R8.
- ABI splits: `splits { abi { enable true; reset(); include "armeabi-v7a", "arm64-v8a"; universalApk false } }`.
- Compress PNGs → WebP.
- Drop unused locales: `resConfigs "en", "hi"`.

**Real problem — APK 78MB → 22MB on Flipkart-style app**:
1. Enable Hermes (+ shrink JS).
2. ABI splits (drop x86, x86_64).
3. Convert PNG → WebP (saved 12MB).
4. Lottie → Rive for complex anim.
5. Strip unused fonts.
6. Use App Bundle (.aab) so Play delivers per-device.

---

### H.4 — iOS platform deep (lifecycle, signing, Universal Links)

**App lifecycle** (SceneDelegate-based):
`willConnectToScene` → `sceneDidBecomeActive` → `sceneWillResignActive` → `sceneDidEnterBackground` → `sceneWillEnterForeground`.

**RN handle background blur for sensitive screens**:
```jsx
useEffect(() => {
  const sub = AppState.addEventListener('change', (s) => {
    setBlurred(s === 'inactive' || s === 'background'); // hide PII in app switcher
  });
  return () => sub.remove();
}, []);
```

**Code signing — Fastlane match**:
```ruby
# Fastfile
lane :beta do
  setup_ci
  match(type: 'appstore', readonly: true)
  build_app(scheme: 'App', export_method: 'app-store')
  upload_to_testflight
end
```

**Universal Links setup**:
1. Host AASA at `https://yourdomain/.well-known/apple-app-site-association` (no extension, `Content-Type: application/json`):
```json
{
  "applinks": {
    "apps": [],
    "details": [{ "appID": "TEAMID.com.app", "paths": ["/order/*", "/profile/*"] }]
  }
}
```
2. Xcode → Signing & Capabilities → Associated Domains → `applinks:yourdomain`.
3. Validate with Apple's [validator](https://search.developer.apple.com/appsearch-validation-tool/).

**Common signing failures + fixes**:
| Error | Cause | Fix |
|---|---|---|
| "No matching provisioning profile" | Cert/profile mismatch | `match nuke development && match development` |
| "Failed to register bundle id" | Capability changed | Update App ID in dev portal, regenerate |
| Build OK locally, fails CI | Keychain locked | `setup_ci` lane unlocks temp keychain |
| Push not working in TestFlight | APNs cert/key not set | Upload `.p8` AuthKey to App Store Connect |

---

### H.5 — Architecture Decision Records (ADRs) — 3 worked examples

**ADR template**:
```markdown
# ADR-NNN: <decision title>
Date: YYYY-MM-DD | Status: Accepted | Owner: <name>

## Context
<problem, constraints>

## Decision
<chosen approach>

## Alternatives considered
- A: <pros/cons>
- B: <pros/cons>

## Consequences
- Positive: ...
- Negative: ...
- Mitigations: ...
```

#### ADR-001: Use FlashList over FlatList for product feed
**Context**: Catalog of 5k+ items; FlatList drops to 28 FPS on Pixel 6a.
**Decision**: Migrate to `@shopify/flash-list`.
**Alternatives**: (a) Optimize FlatList (`getItemLayout`, memo, `removeClippedSubviews`) — got us to 42 FPS, not enough. (b) Native RecyclerView bridge — too much maintenance.
**Consequences**: +memory savings, +stable 58 FPS; −requires `estimatedItemSize` tuning per row variant; −one third-party dep added.

#### ADR-002: Keychain + biometric gate for refresh tokens
**Context**: Fintech compliance, MASVS L2.
**Decision**: Store access token in memory (lifetime ≤15min); refresh token in Keychain with `BIOMETRY_CURRENT_SET`.
**Alternatives**: Encrypted MMKV (rejected: weaker than secure enclave). Plain MMKV (rejected: fails audit).
**Consequences**: +regulator-friendly; −user must re-auth biometrics on app cold start; mitigated with grace period (5 min in foreground).

#### ADR-003: React Query over Redux for server state
**Context**: 60% of Redux store was server cache copies.
**Decision**: React Query for server state; keep Redux for auth + feature flags.
**Alternatives**: SWR (similar; ecosystem smaller); RTK Query (good but team uses Redux only for global UI now).
**Consequences**: +-220KB bundle; +stale/refetch built in; −two state libs to teach new hires.

---

### H.6 — Mock Interview format (weak / good / lead-level answers)

**Q: "Walk me through how you'd debug a 4-second cold start on Android Go."**

**Weak answer** (junior signal):
> "I'd check the code and remove unused stuff. Maybe enable Hermes."

**Good answer** (mid signal):
> "I'd profile cold start using Android Studio CPU Profiler and the Hermes profiler. I'd look at what runs before first paint — usually eager imports, sync remote config, font loading. Then I'd lazy-load heavy modules and defer SDK init."

**Lead-level answer** (target):
> "Three steps: measure, hypothesize, gate.
> **Measure**: instrument app start with `react-native-performance` markers — TTI, JS bundle parse, first useful paint. Capture P50/P95 from a beta cohort, not just my Pixel.
> **Hypothesize from data**: typical cold-start budget on Android Go is 2.5s. If we're at 4s, the top three suspects are eager TurboModule init, sync remote config / feature flags, and large bundle parse. Hermes profiler tells me which.
> **Gate**: I don't ship optimizations without a CI gate that fails the PR if cold-start P95 regresses >10%. Last time I did this we got 4.1s → 1.6s P50 with measurable D1 retention lift of +6.2%, and the budget kept holding 18 months later because of the gate, not the fix."

**Follow-up traps** the interviewer will throw:
- "What if the regression came from a dependency, not your code?" → Answer: bundle-size diff per PR, dependency review CODEOWNERS.
- "How would you convince PM to delay a feature for perf work?" → Show retention/D1 graph correlated with cold start.

Use this 3-tier structure to rehearse for: lists perf, memory leaks, payment design, RN→Capacitor migration, OTA rollback, native module decision.

---

### H.7 — Sample app skeletons (just enough to ship a demo repo)

> Build at least 3 of these. Push to GitHub. Link from resume.

#### App 1 — Auth demo (PKCE + Keychain + biometric)
Files:
- `auth/oauth.ts` — PKCE generator (`expo-auth-session`).
- `auth/storage.ts` — Keychain wrapper.
- `auth/refresh.ts` — single-flight (see G.17).
- `screens/Login.tsx` + `screens/Home.tsx` + auth gate from G.16.
Demo: login → store tokens → 401 → silent refresh → biometric gate after 5min idle.

#### App 2 — Realtime chat demo
- WS reconnect (G.17), heartbeat, optimistic send + rollback, local SQLite for messages, push notification routing (H.1), typing indicator throttled at 200ms.

#### App 3 — Offline-first fintech (portfolio)
- WatermelonDB tables: `holdings`, `orders`, `outbox`.
- Sync engine: pull on foreground + WS for live prices.
- Order placement = optimistic + outbox (G.15).
- Biometric gate before order submit (H.4).
- Sentry + perf marks for `placeOrder`.

#### App 4 — Offline todo
- MMKV-backed list + outbox + reconnect-flush. Smallest demo, easiest to finish first.

#### App 5 — Performance playground
- 5000-row FlatList vs FlashList toggle. Show on-screen FPS counter (`react-native-performance`). Profile screen with Hermes recordings checked in.

---

### H.8 — Recruiter round scripts (the first 15 min that often filter you out)

**"Tell me about yourself" (60 sec)**:
> "I'm a senior mobile engineer with 9+ years shipping React Native and native apps, currently leading mobile at LetsVenture — a fintech where I own the LVX and LVXQ apps across React Native, Capacitor, and native pieces. I've owned auth with Auth0 + Cognito, payment integrations with Razorpay and Cashfree, deep linking with Branch, and the EAS / Play / App Store release pipeline. The work I'm proudest of recently is **<one number — e.g., cutting cold start 4s → 1.6s and lifting D1 retention 6%>**. I'm now looking for a senior or lead role at a product company — ideally fintech — where I can own mobile platform decisions end-to-end."

**"Why are you looking for a change?"**:
> "I've taken LVX and LVXQ from feature-light to a production fintech platform, and I'm at the point where the next leap for me is leading mobile at a larger product org — owning architecture decisions across multiple apps and engineers. LetsVenture is a great team; this move is about scope, not dissatisfaction."

**"What's your current CTC?" (deflect)**:
> "I'd rather we align on the band the role is open to first — I want to make sure we're in the same range before we get into specifics. My expected fixed is **₹45–55 LPA** based on what the market is offering for senior fintech RN roles in Bengaluru. Happy to share details once we have a mutual fit."

**"What's your notice period?"**:
> "Officially 60 days, but I've had similar moves negotiated down to 30–45 days with a clean handover plan. I can commit a date once an offer is concrete."

**"Why should we hire you?"**:
> "Three reasons: (1) I've shipped fintech mobile end-to-end including auth, payments, releases — not just one slice; (2) I optimize for production reliability, with measurable wins like **<crash-free 99.78%, cold start 1.6s>**; (3) I work as a tech lead — I write RFCs, mentor, and run incident reviews — so I add value beyond IC."

---

### H.9 — Suspense + Error Boundaries (with code)

**Suspense for code-split screens**:
```jsx
const Profile = React.lazy(() => import('./screens/Profile'));
function App() {
  return (
    <Suspense fallback={<Splash/>}>
      <Profile/>
    </Suspense>
  );
}
```

**Error Boundary (class component — only way today)**:
```tsx
class ErrorBoundary extends React.Component<{ fallback: React.ReactNode; children: React.ReactNode }, { err: Error | null }> {
  state = { err: null as Error | null };
  static getDerivedStateFromError(err: Error) { return { err }; }
  componentDidCatch(err: Error, info: React.ErrorInfo) {
    Sentry.captureException(err, { extra: { componentStack: info.componentStack } });
  }
  render() {
    if (this.state.err) return this.props.fallback;
    return this.props.children;
  }
}
// usage
<ErrorBoundary fallback={<ErrorScreen onRetry={() => RNRestart.restart()}/>}>
  <App/>
</ErrorBoundary>
```

**Real problem**: A bad WebSocket payload crashed the chat screen and took the whole app down. Fix: wrap each screen in an `ErrorBoundary`, so only that screen shows the fallback. Bonus: log + auto-recover on retry.

---

### H.10 — Functional patterns: pure functions, currying, composition

**Pure function** — same input → same output, no side effects. Easy to test, memoize, parallelize.

**Currying**:
```ts
const curry = <A, B, C>(f: (a: A, b: B) => C) => (a: A) => (b: B) => f(a, b);
const add = curry((a: number, b: number) => a + b);
add(2)(3); // 5
const add10 = add(10);
[1,2,3].map(add10); // [11,12,13]
```

**Composition**:
```ts
const pipe = <T,>(...fns: Array<(x: T) => T>) => (x: T) => fns.reduce((v, f) => f(v), x);
const slug = pipe<string>(
  (s) => s.toLowerCase(),
  (s) => s.trim(),
  (s) => s.replace(/\s+/g, '-')
);
slug(' Hello World '); // "hello-world"
```

**Real-world usage**: data normalization pipelines (API → UI), reducer composition in Redux, validation chains.

---

### H.11 — Polyfills (interview classic)

**Implement `Array.prototype.map`**:
```ts
Array.prototype.myMap = function<T, U>(this: T[], cb: (v: T, i: number, a: T[]) => U): U[] {
  const out: U[] = [];
  for (let i = 0; i < this.length; i++) {
    if (i in this) out[i] = cb(this[i], i, this);
  }
  return out;
};
```

**`reduce`**:
```ts
Array.prototype.myReduce = function<T, U>(this: T[], cb: (acc: U, v: T, i: number, a: T[]) => U, init?: U): U {
  let acc = init as U; let start = 0;
  if (init === undefined) { acc = this[0] as unknown as U; start = 1; }
  for (let i = start; i < this.length; i++) acc = cb(acc, this[i], i, this);
  return acc;
};
```

**`bind`**:
```ts
Function.prototype.myBind = function (ctx: any, ...preset: any[]) {
  const fn = this;
  return function (this: any, ...later: any[]) {
    return fn.apply(ctx, [...preset, ...later]);
  };
};
```

---

### H.12 — Coverage checklist (so nothing's missed)

| Handbook section | Where covered |
|---|---|
| §1 JS Fundamentals | G.1–G.4, H.10, H.11 |
| §2 Advanced JS | G.2, G.4, H.10, H.11 |
| §3 TypeScript | G.5 |
| §4 React Deep Dive | G.6–G.8, H.9 |
| §5 RN Fundamentals | G.9, G.10 |
| §6 New Architecture | G.9, G.12 |
| §7 Performance | G.10, G.11, G.13, S1, S8 |
| §8 Native (Android) | H.3, S9 |
| §8 Native (iOS) | H.4, S10 |
| §9 Native Modules | G.12 |
| §10 State Management | G.14 |
| §11 Navigation + Deep Linking | G.16, S6 |
| §12 Networking + Realtime | G.17, S11, S12 |
| §13 Auth + Security | G.18 |
| §14 Offline-first | G.15 |
| §15 Push Notifications | H.1, S4 |
| §16 a11y + i18n | H.2 |
| §17 Testing | G.19 |
| §18 CI/CD | G.20, H.4 |
| §19 Debugging + Observability | G.13, G.21 |
| §20 System Design | G.22, ADRs in H.5 |
| §21 DSA | G.23 |
| §22 Leadership + Behavioral | Appendix E (10 STAR) |
| §23 Recruiter + Comp | Appendix C, D, H.8 |
| Production scenarios library | G.24 (12 walkthroughs) + S-prefix above |
| Mock interview format | H.6 |
| ADRs | H.5 |
| Sample apps | H.7 |
| Suspense + Error Boundaries | H.9 |
| Functional / Polyfills | H.10, H.11 |

If you can:
- Recite the **short and deep** version of every Q in Appendix G.
- Write the code in G.4, G.7, G.11, G.12, G.15, G.17, G.23 from memory.
- Tell every story in Appendix E in 2 minutes with numbers.
- Walk through the 3 system designs in G.22.
- Handle the recruiter scripts in H.8 cold.
- Build at least 3 sample apps from H.7 and link them on your resume.

…then you are ready for ₹40+ LPA RN/mobile-lead loops in India. Go land them.

---

## Appendix I — The Six Engineering Tracks (lead-level breakdown)

> Lead/Architect roles are evaluated across six tracks, not one. Most engineers are strong in 2–3 and weak in the rest. This appendix gives you the **bar**, the **interview signals**, the **questions asked**, and the **gap-fill code/practice** for each track. Score yourself 1–5 per track. Anything ≤3 is your next 2 weeks.

---

### Track 1 — Core Engineering (JS / TS / React / RN)

**The bar at lead level**:
- Can explain JS execution model + event loop + microtasks without flinching.
- Writes type-safe APIs with discriminated unions, generics, and runtime validators (Zod).
- Knows React render model deeply enough to debug "why did this render" cold.
- Knows RN architecture (old bridge → JSI/Fabric/TurboModules) deeply enough to make migration calls.

**Interview signals you've nailed it**:
- You correct the interviewer when they conflate microtask/macrotask.
- You spot the closure bug in their code snippet in <30 sec.
- You explain a concept in 20s, 60s, 3min versions on demand.

**Questions they will ask** (covered: G.1–G.12, H.9–H.11):
- Walk me through what happens between `setState` and pixels on screen.
- Why does `useEffect` run twice in dev? What changes in prod?
- When would you write a TurboModule vs a regular native module vs JS-only?
- Type a polymorphic component (`<Button as="a">` style) — show me.
- Implement `Promise.all` and explain ordering guarantees.

**Score 5/5 if you can**:
- Recite G.1–G.12 short+deep without notes.
- Type the code from G.4, G.5, G.7, G.11, H.10, H.11 from memory.

---

### Track 2 — Product Engineering (UI / UX / Figma / Storybook / Design Systems)

**The bar**:
- Can sit with a designer in Figma, pull tokens (colors, spacing, type scale) into code, and ship pixel-faithful UI.
- Knows when a "design choice" is actually an a11y bug (contrast, target size, motion).
- Owns a component library / design system in Storybook with variants + a11y addon.
- Pushes back on PM with **user-research** language, not "I think".

**Figma → code workflow** (this is what most RN engineers fake — own it):
1. **Read tokens**: Figma Variables panel → name them by intent (`color/bg/surface`, not `gray/100`).
2. **Export to code** via Figma MCP or Tokens Studio → JSON → `theme.ts`.
3. **Component map**: each Figma component → one Storybook story with controls.
4. **Annotate**: get designer to add states (default/hover/pressed/disabled/loading/error) in Figma.

**Token file (real example)**:
```ts
// theme/tokens.ts (generated from Figma; do not hand-edit)
export const tokens = {
  color: {
    bg: { surface: '#FFFFFF', muted: '#F6F7F9', elevated: '#FFFFFF' },
    fg: { default: '#0B1220', muted: '#5B6472', onPrimary: '#FFFFFF' },
    brand: { 50: '#EEF2FF', 500: '#4F46E5', 700: '#3730A3' },
    intent: { success: '#0A7E3D', warning: '#B7791F', danger: '#C0392B' },
  },
  space: { 0: 0, 1: 4, 2: 8, 3: 12, 4: 16, 5: 24, 6: 32, 8: 48 },
  radius: { sm: 4, md: 8, lg: 16, full: 9999 },
  type: {
    body: { fontSize: 16, lineHeight: 24, fontWeight: '400' },
    h1: { fontSize: 28, lineHeight: 36, fontWeight: '700' },
  },
} as const;
```

**Themed component (light/dark, no hardcodes)**:
```tsx
import { useColorScheme } from 'react-native';
import { tokens } from '@/theme/tokens';

const palette = {
  light: { bg: tokens.color.bg.surface, fg: tokens.color.fg.default },
  dark:  { bg: '#0B1220',                fg: '#E5E7EB' },
};

export function Card({ children }: { children: React.ReactNode }) {
  const c = palette[useColorScheme() ?? 'light'];
  return (
    <View style={{ backgroundColor: c.bg, padding: tokens.space[4], borderRadius: tokens.radius.lg }}>
      <Text style={{ color: c.fg, ...tokens.type.body }}>{children}</Text>
    </View>
  );
}
```

**Storybook for RN (`.storybook/`)** — every component gets:
```tsx
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react-native';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Primitives/Button',
  component: Button,
  args: { children: 'Pay ₹2,499' },
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'ghost'] },
    size:    { control: 'select', options: ['sm', 'md', 'lg'] },
    loading: { control: 'boolean' },
  },
};
export default meta;

export const Primary:   StoryObj<typeof Button> = { args: { variant: 'primary' } };
export const Loading:   StoryObj<typeof Button> = { args: { variant: 'primary', loading: true } };
export const Disabled:  StoryObj<typeof Button> = { args: { variant: 'primary', disabled: true } };
```

**Component variants pattern (CVA-style without web deps)**:
```ts
// helpers/variants.ts
type V<T extends Record<string, Record<string, object>>> = {
  [K in keyof T]?: keyof T[K];
};

export function variants<T extends Record<string, Record<string, object>>>(base: object, map: T) {
  return (props: V<T>) => {
    const out = { ...base };
    for (const key in map) {
      const v = props[key];
      if (v) Object.assign(out, (map[key] as any)[v as string]);
    }
    return out;
  };
}

// Button.tsx
const styled = variants(
  { paddingHorizontal: 16, borderRadius: 12, alignItems: 'center' },
  {
    variant: {
      primary:   { backgroundColor: tokens.color.brand[500] },
      secondary: { backgroundColor: tokens.color.bg.muted },
      ghost:     { backgroundColor: 'transparent' },
    },
    size: { sm: { paddingVertical: 8 }, md: { paddingVertical: 12 }, lg: { paddingVertical: 16 } },
  }
);
```

**Empty / loading / error / success states — the four screens designers forget**:
Every screen must define all four. Example contract:
```tsx
type ScreenState<T> =
  | { kind: 'loading' }
  | { kind: 'empty' }
  | { kind: 'error'; retry: () => void; message: string }
  | { kind: 'ready'; data: T };

function Screen<T>({ state, render }: { state: ScreenState<T>; render: (d: T) => React.ReactNode }) {
  switch (state.kind) {
    case 'loading': return <Spinner/>;
    case 'empty':   return <EmptyState/>;
    case 'error':   return <ErrorState message={state.message} onRetry={state.retry}/>;
    case 'ready':   return <>{render(state.data)}</>;
  }
}
```

**Motion / haptics (the senior detail)**:
- Match Figma motion specs (duration + easing). Use Reanimated `withTiming(value, { duration: 200, easing: Easing.bezier(0.2, 0, 0, 1) })`.
- Haptics on commit-level actions only (`expo-haptics` `Haptics.impactAsync(Light)` on add-to-cart; never on scroll).
- Respect `AccessibilityInfo.isReduceMotionEnabled()` → skip parallax / shake.

**Common designer ↔ engineer fights (and the senior way to resolve)**:
| Tension | Junior reaction | Senior move |
|---|---|---|
| Designer ships pixel-perfect mock; doesn't include error state | "You didn't give me an error state" | Block PR until designer adds 4-state view; offer to design it together first time |
| Designer asks for shadows that wreck FPS on Android | Implement and ship laggy | Show benchmarks; propose alternative (border, bg layering); document in design system |
| PM wants animation that breaks reduce-motion | "Sure" | Add a11y note to ticket; ship with reduce-motion fallback |
| Inconsistent spacing across screens | Eyeball + ship | Build spacing tokens; lint hardcoded values via custom ESLint rule |

**Questions they will ask**:
- "How do you keep design and engineering in sync?" → Token pipeline + Storybook + design reviews.
- "Show me your Storybook for one component." → Have a public repo link.
- "How do you handle dark mode / theming?" → Token palette per scheme, no hardcoded hex outside tokens.
- "How do you ensure visual consistency across 6 engineers?" → Design system + Storybook + visual regression (Chromatic or Loki).

**Visual regression** (lead-level — most candidates miss this):
```js
// loki.config.js
module.exports = {
  configurations: {
    'ios.iphone15': { target: 'ios.simulator', deviceName: 'iPhone 15', preset: 'iPhone 15' },
  },
};
// scripts: "loki test" in CI; fails PR on diff.
```

**Score 5/5 if you can**:
- Show a working `tokens.ts` generated from Figma.
- Show a Storybook with at least one primitive (Button) + 3+ variants + dark mode.
- Show a visual regression run in CI on a PR.

---

### Track 3 — Platform Engineering (Native / Debugging / Performance / Security)

**The bar**:
- Reads native crash logs and symbolicates without help.
- Writes Swift + Kotlin TurboModules.
- Owns startup, FPS, memory, ANR — with budgets in CI.
- Owns mobile security: Keychain/Keystore, OAuth PKCE, cert pinning, MASVS L2.

**Already covered**: G.9, G.11, G.12, G.13, G.18, H.3, H.4.

**Gap-fill — Performance budgets in CI**:
```yaml
# .github/workflows/perf-gate.yml
- name: Cold start budget
  run: node scripts/perf-gate.js --metric cold_start --max 1800 --baseline main
- name: Bundle size budget
  run: node scripts/perf-gate.js --metric bundle_kb --max 2400
```
The script pulls metrics from a measurement run (e.g., `react-native-performance` + Detox run on a controlled device farm) and exits non-zero on regression > threshold.

**Gap-fill — Frame drop instrumentation (Reanimated 3)**:
```ts
import { runOnJS, useFrameCallback } from 'react-native-reanimated';

const droppedFrames = useSharedValue(0);
useFrameCallback(({ timeSincePreviousFrame }) => {
  'worklet';
  if (timeSincePreviousFrame && timeSincePreviousFrame > 18) {
    droppedFrames.value += 1;
    runOnJS(reportFrameDrop)(timeSincePreviousFrame);
  }
});
```

**Gap-fill — RASP (runtime app self-protection) for fintech**:
```ts
import JailMonkey from 'jail-monkey';
if (JailMonkey.isJailBroken() || JailMonkey.canMockLocation() || JailMonkey.isDebuggedMode()) {
  blockAndNotify();
}
```
Pair with: cert pinning (G.18), screenshot prevention (`FLAG_SECURE` Android, blur on background iOS), root/jailbreak escalation policy, anti-tamper checksum.

**Questions they will ask**:
- "Walk me through symbolicating an iOS Hermes crash." → G.13 CLI + dSYM + Hermes sourcemap.
- "How do you detect a memory leak in production, not just locally?" → Sentry release health → memory percentile alerts → reproduce via heap snapshot.
- "When would you bypass RN and write native?" → Latency-critical (camera, BLE), large-data (file processing), platform-only API.

**Score 5/5 if you can**:
- Ship the Swift + Kotlin TurboModule from G.12 to a real app.
- Show a perf budget gate in a public CI run.
- Walk through a real production crash you symbolicated.

---

### Track 4 — Architecture Engineering (System Design / Scaling / Offline-first)

**The bar**:
- Can design a mobile system end-to-end in 45 min on a whiteboard.
- Writes ADRs (H.5) before big decisions, not after.
- Knows when to modularize, when to monorepo, when to microfrontend (server-driven UI).
- Designs offline-first by default for fintech / consumer.

**Already covered**: G.15, G.22, H.5.

**Gap-fill — Modularization patterns**:
- **Feature-first**: `features/portfolio/{ui,domain,data}` — best for product apps.
- **Layer-first**: `data/`, `domain/`, `ui/` — best for libraries / shared kernels.
- **Hybrid (recommended for lead-scale RN)**:
```
apps/
  consumer/
  internal/
packages/
  ui/          # design system + primitives (Track 2)
  features/
    auth/
    payments/
    portfolio/
  data/        # api clients, schemas, react-query keys
  native/      # turbo modules
  config/      # eslint, tsconfig, metro
```

**Gap-fill — Server-Driven UI (SDUI, used at Swiggy/CRED scale)**:
```ts
// server returns:
type Component = { type: 'card' | 'list' | 'cta'; props: any; children?: Component[] };

const registry = {
  card: Card,
  list: List,
  cta: CTAButton,
} as const;

function Render({ node }: { node: Component }) {
  const C = registry[node.type] as React.ComponentType<any>;
  if (!C) return null;
  return <C {...node.props}>{node.children?.map((c, i) => <Render key={i} node={c}/>)}</C>;
}
```
**Trade-off**: ship UI without store release; cost: every component must be in registry (security boundary), can't use arbitrary code from server.

**Gap-fill — Multi-app monorepo (turbo + pnpm)**:
```json
// turbo.json
{
  "tasks": {
    "build":   { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "test":    { "dependsOn": ["^build"], "outputs": [] },
    "lint":    { "outputs": [] },
    "typecheck": { "dependsOn": ["^build"] }
  }
}
```
Real benefit: shared `packages/ui` ships to 2 apps; shared `packages/features/auth` means one team owns auth across both.

**Questions they will ask**:
- "Design WhatsApp message sync." → G.22 design 2 expanded.
- "How would you structure a 6-app monorepo for a fintech?" → Hybrid above + ADR for boundaries.
- "When would you NOT do offline-first?" → Real-time-only data (live trading book), regulatory (some KYC steps require online attestation).
- "How do you roll out a new SDK across 3 apps?" → Shared package + version pinning + canary app first.

**Score 5/5 if you can**:
- Whiteboard offline-first fintech in 45 min including outbox, conflict policy, and security boundaries.
- Show 3+ ADRs you've written.
- Explain a real modularization migration with before/after structure and what broke.

---

### Track 5 — Production Engineering (Releases / Monitoring / Incidents)

**The bar**:
- Owns the release: signing, store policy, OTA gating, rollback in <10 min.
- Owns observability: Sentry, structured logs, perf traces, alerting.
- Runs incidents calmly: detect → mitigate → communicate → post-mortem.
- Has an on-call rotation and a runbook per incident class.

**Already covered**: G.20, G.21, G.24 (S1–S12).

**Gap-fill — Release readiness checklist** (steal this for every release):
```
[ ] Crashlytics/Sentry rate baseline captured for previous release
[ ] All P0/P1 bugs from previous release closed or knowingly accepted
[ ] Native version bumped (build number = unique)
[ ] Sourcemaps + dSYMs uploaded
[ ] Privacy manifest updated (iOS PrivacyInfo.xcprivacy)
[ ] App Privacy section updated in App Store Connect (data collection)
[ ] Release notes drafted (user-facing + internal)
[ ] Feature flags set for new features (default OFF, enable post-rollout)
[ ] Backend dependencies deployed first
[ ] Staged rollout configured (10/50/100)
[ ] On-call notified, runbook linked
[ ] Rollback plan documented
```

**Gap-fill — Incident runbook template**:
```markdown
# Runbook: Payment failure spike
## Detect
- Sentry alert: `payment_failed` rate > 5% for 5 min
- Pager: payments-oncall

## Triage (≤5 min)
1. Check Sentry → which release / device / API endpoint
2. Check backend status page
3. Check FCM/APNs status

## Mitigate (≤15 min)
- If client bug → roll back OTA channel: `eas update --branch production --message "rollback to <sha>"`
- If backend → flip feature flag `payments_enabled=false`, show maintenance UI
- If 3rd party (Razorpay) → switch to Cashfree fallback

## Communicate
- #incident-payments channel: post template (severity, scope, mitigation, ETA)
- Status page update if user-visible >5 min

## Post-mortem (≤48h)
- Blameless template: timeline, root cause, contributing factors, action items with owners + dates
```

**Gap-fill — SLOs (Service Level Objectives) for mobile**:
| SLO | Target | Source |
|---|---|---|
| Crash-free sessions | ≥ 99.7% | Sentry / Crashlytics |
| ANR-free sessions (Android) | ≥ 99.5% | Play vitals |
| Cold start P95 | ≤ 2.0s | RN performance + farm |
| API success rate | ≥ 99.5% | Sentry traces |
| OTA rollout time-to-50% | ≤ 24h | EAS metrics |

When an SLO burns 50% of its monthly error budget, you stop shipping features and fix.

**Gap-fill — Feature flags (LaunchDarkly / GrowthBook / homegrown)**:
```ts
const enabled = useFlag('new_checkout_v2', { default: false });
return enabled ? <CheckoutV2/> : <CheckoutV1/>;
```
Pattern: every new feature behind a flag; default OFF; enable to internal → 1% → 10% → 50% → 100% with metric checks at each step.

**Questions they will ask**:
- "Walk me through the worst incident you handled." → STAR story #4.
- "How do you decide between OTA vs binary release for a fix?" → OTA for JS-only + low-risk; binary for native or schema migration; both with staged rollout.
- "What does your on-call week look like?" → Pager rotation, runbook usage, follow-up actions.

**Score 5/5 if you can**:
- Show a real post-mortem you wrote (sanitize names).
- Show a runbook for a real incident class.
- Quote your team's SLOs and current error budget.

---

### Track 6 — Leadership Engineering (Team / Process / Mentoring)

**The bar**:
- Grows the engineers under you (Track Mentee → Mid → Senior).
- Owns delivery without micromanaging.
- Writes RFCs, runs reviews, drives consensus.
- Says no to PMs with data, not opinions.
- Hires (designs interview loops, gives clear feedback).

**Already covered**: Section 23, Appendix E (10 STAR stories).

**Gap-fill — RFC template** (use this for any decision spanning >1 sprint or >1 engineer):
```markdown
# RFC-NNN: <Title>
Author: <name> · Reviewers: <list> · Status: Draft / Review / Accepted / Rejected
Date: YYYY-MM-DD

## Problem
What hurts today, with evidence.

## Proposal
The change in 3 sentences. Then sections:
- Scope (in / out)
- API / data model changes
- Migration plan
- Rollout plan
- Observability plan

## Alternatives considered
For each: pros, cons, why rejected.

## Open questions
List explicit Qs needing reviewer input.

## Decision log
Append after review.
```

**Gap-fill — Growth ladder (mobile)**:
| Level | Scope | Signals you look for when promoting |
|---|---|---|
| Mid (E3) | Owns features end-to-end | Reliable delivery, asks good questions, writes tests by default |
| Senior (E4) | Owns systems / domains | Reduces complexity, mentors mids, runs incident response |
| Lead (E5) | Owns multi-team outcomes | RFCs, hiring, cross-team unblocking, defines standards |
| Staff (E6) | Owns engineering strategy | Multi-quarter roadmap, sets technical direction org-wide |
| Architect / Principal (E7) | Owns multi-org technical bets | Influences without managing, depth + breadth |

**Gap-fill — 1:1 framework** (weekly, 30 min):
```
[5 min] Personal check-in (energy, blockers outside work)
[10 min] Their agenda (let them drive)
[10 min] Your agenda (feedback, context, growth)
[5 min]  Action items + owners (you write them down, send after)
```
Anti-pattern: status updates. That's what standup is for.

**Gap-fill — Code review etiquette (lead version)**:
- **Comment levels**: prefix with `nit:`, `suggestion:`, `question:`, `must-fix:`. Only `must-fix` blocks merge.
- **Praise the good parts** — esp. for juniors; reviews are 50% teaching.
- **Pull big changes into a chat or pairing session**; don't do design via PR comments.
- **Time-box**: respond within 1 working day or hand off explicitly.
- **Approve with caveats** rather than block when the author can self-correct.

**Gap-fill — Saying no to PM (script)**:
> "I want to ship this — and to ship it well, I need to flag two risks. **Risk 1**: <specific tech risk with data>. **Risk 2**: <delivery risk>. Here are 3 options:
> (a) Ship as designed in 4 weeks with risks A, B accepted.
> (b) Ship reduced scope in 2 weeks, follow-up in next sprint.
> (c) Spike for 3 days first, then commit.
> I'd recommend (b) because <reason>. What's your call?"
This gives PM agency, makes you look like a lead, and creates a written trade-off record.

**Gap-fill — Hiring loop you'd run for an RN senior**:
1. Recruiter screen (15 min).
2. Coding (60 min, easy-medium DSA + 1 RN concept).
3. RN deep-dive (60 min, JSI/Fabric, perf, native modules).
4. System design (60 min, mobile system).
5. Behavioral / leadership (45 min, STAR + scenario).
6. Hiring manager close (30 min, role + comp).
**Calibration**: every interviewer files written feedback in a shared rubric (Strong Hire / Hire / No Hire / Strong No Hire) **before** seeing others' notes. Hiring committee makes the call.

**Questions they will ask**:
- "Tell me about an engineer you grew." → STAR #6.
- "Tell me about a time you disagreed with your manager." → STAR #3 or #9 framing.
- "How do you give feedback to a senior peer who's underperforming?" → Direct, in 1:1, specific, behavior-not-character, with a check-in cadence.
- "What's your interview rubric for a senior RN hire?" → The loop above + signals per round.

**Score 5/5 if you can**:
- Show 2+ RFCs you authored.
- Show feedback you wrote for a promotion case (sanitize).
- Show 3+ engineers whose growth you owned.

---

### Self-assessment scorecard (fill this before applying)

| Track | Bar | Your score (1–5) | Top 1 gap | Action this week |
|---|---|---|---|---|
| Core | Fluent JS/TS/React/RN deep | __ | | |
| Product | Figma → tokens → Storybook → app | __ | | |
| Platform | Native + perf + security | __ | | |
| Architecture | System design + ADRs + offline | __ | | |
| Production | Releases + SLOs + incidents | __ | | |
| Leadership | RFCs + mentoring + hiring | __ | | |

**Lead-role readiness**: aim for ≥4 in Core + Platform + Architecture, ≥3 in the other three. Anything 5/5 becomes a STAR story.
**Architect readiness**: ≥4 across all six.

---

### Track ↔ company emphasis (where they probe hardest)

| Company | Heaviest tracks |
|---|---|
| PhonePe | Platform (security, perf), Architecture (offline payments), Production (reliability) |
| CRED | Product (UI/UX/motion), Core (Reanimated, Skia), Platform (FPS) |
| Razorpay | Platform (security), Architecture (idempotency), Core (TS depth) |
| Groww / Zerodha | Architecture (realtime + offline), Platform (perf), Production (zero-downtime) |
| Swiggy / Zomato | Architecture (SDUI), Production (release velocity), Platform (low-end Android) |
| Flipkart / Meesho | Platform (perf, low-end Android), Architecture (modular monorepo), Production (release scale) |
| Microsoft / Atlassian | Core (RN platform depth), Architecture (multi-app monorepo), Leadership (RFCs, process) |
| Walmart Global | Core, Architecture, Production |
| Dream11 | Platform (perf at scale), Production (incidents on match days), Architecture (realtime) |

---

This six-track model is also the structure for your **resume**: every bullet should map to one of the six tracks, and across the whole resume you should have at least 2 strong bullets per track.

---

## Appendix J — Last gap-fill (Expo Router, Config Plugins, AI-assisted engineering, Top-50 Q index)

> The user's handbook spec called out three more things explicitly: **Expo ecosystem deep**, **AI-assisted engineering**, and a standardized **Top-50 Q index per topic**. This appendix closes them honestly.

---

### J.1 — Expo Router (file-based routing for RN)

**Why it matters in 2026**: Expo Router is becoming the default for new RN apps. Most Tier-S/A interviews now ask about it.

**Mental model**: file system = navigation tree. `app/` is the root. Every `.tsx` file is a route. Layouts (`_layout.tsx`) wrap children. Groups `(name)` don't add to URL.

**Project structure example**:
```
app/
  _layout.tsx              # root: NavigationContainer + auth gate
  index.tsx                # /
  (tabs)/
    _layout.tsx            # tab bar
    home.tsx               # /home
    portfolio.tsx          # /portfolio
    profile.tsx            # /profile
  (auth)/
    _layout.tsx            # stack for auth screens
    login.tsx              # /login
    otp.tsx                # /otp
  order/
    [id].tsx               # /order/:id  (dynamic)
    [...rest].tsx          # /order/* catch-all
  +not-found.tsx
```

**Root `_layout.tsx` with auth gate**:
```tsx
import { Slot, useRouter, useSegments } from 'expo-router';
import { useEffect } from 'react';
import { useAuth } from '@/auth';

export default function Root() {
  const { user, ready } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    if (!ready) return;
    const inAuthGroup = segments[0] === '(auth)';
    if (!user && !inAuthGroup) router.replace('/login');
    if (user && inAuthGroup) router.replace('/');
  }, [user, ready, segments]);

  return <Slot />;
}
```

**Typed dynamic route**:
```tsx
// app/order/[id].tsx
import { useLocalSearchParams } from 'expo-router';
export default function Order() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <OrderScreen orderId={id} />;
}
```

**Deep link mapping** is automatic — `myapp://order/123` and `https://myapp.com/order/123` both resolve to `app/order/[id].tsx`. Configure in `app.json`:
```json
{ "expo": { "scheme": "myapp", "deepLinking": true } }
```

**Top interview questions**:
- File-based vs config-based navigation — when would you pick which?
- How do you guard a route in Expo Router? (segments + redirect in layout)
- How do you pass typed params? (`useLocalSearchParams<T>` + Zod)
- How does Expo Router handle universal links? (`scheme` + AASA + `assetlinks.json`)
- Trade-offs vs React Navigation directly?

---

### J.2 — EAS Build, EAS Update, Config Plugins

**EAS Build profiles** (`eas.json`):
```json
{
  "cli": { "version": ">= 3.0.0" },
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview":     { "distribution": "internal", "channel": "preview" },
    "production":  { "channel": "production", "autoIncrement": true }
  },
  "submit": {
    "production": {
      "ios":     { "appleId": "you@x.com", "ascAppId": "12345", "appleTeamId": "ABCDE" },
      "android": { "serviceAccountKeyPath": "./play-key.json", "track": "internal" }
    }
  }
}
```

**EAS Update channel + branch model**:
- **Channels** (set at build time): `preview`, `production`. Channel pins what updates the binary will accept.
- **Branches** (set at publish time): you can map `production` channel → `production` branch. Hot-swap by re-mapping for emergency rollback.
```sh
eas update --branch production --message "feat: new home"
eas channel:edit production --branch production-v2  # safe canary swap
eas update --branch production --message "rollback" --republish --group <previous-id>
```

**OTA limits to remember**:
- JS + assets only. **No native code.** No new permissions. No new native modules.
- Updates apply on **next cold start** by default; for visible-now, use `Updates.fetchUpdateAsync()` then `Updates.reloadAsync()`.

**Config plugin (a plugin that mutates native config at prebuild time)**:
```ts
// plugins/with-android-permission.ts
import { ConfigPlugin, withAndroidManifest, AndroidConfig } from 'expo/config-plugins';

const withCameraPermission: ConfigPlugin = (config) => {
  return withAndroidManifest(config, (cfg) => {
    AndroidConfig.Permissions.addPermission(cfg.modResults, 'android.permission.CAMERA');
    return cfg;
  });
};
export default withCameraPermission;
```

```json
// app.json
{ "expo": { "plugins": ["./plugins/with-android-permission"] } }
```

**Top interview questions**:
- When do you need a config plugin vs a regular Expo module?
- Difference between EAS channels and branches?
- What can / can't go in an OTA update?
- How would you do staged rollout in EAS?
- How do you migrate a bare RN app to Expo Modules?

---

### J.3 — AI-Assisted Engineering (the 2026 differentiator)

**Why interviewers ask**: every product team is wiring Copilot / Cursor / Claude Code into their workflow. They want leads who use AI safely and **make their team faster** with it, not slower.

**Where AI actually helps in mobile**:
| Task | Tool pattern | Risk to manage |
|---|---|---|
| Boilerplate (CRUD screens, RTK slices, stories) | Cursor / Copilot inline | Hallucinated APIs — always typecheck + run |
| Test generation (RNTL, Jest) | Claude / Copilot Chat with file context | Tests that pass-on-empty — review assertions |
| Codemods (RN upgrade, RTK migration) | Claude Code agent + git diff review | Cross-file regressions — run full test suite |
| Debugging stack traces | Paste stack + relevant file → ask root cause | Hallucinated fix — verify against repro |
| Architecture sounding board | Claude / GPT for ADR draft critique | Generic advice — always reground in your constraints |
| Native module scaffolding (Swift/Kotlin) | Copilot for plumbing | Threading + memory bugs — review carefully |
| PR review triage | LLM summarizer over diff | Misses context — humans still gate |
| Documentation | LLM from code → MDX | Drift — regenerate per release |

**Senior workflow patterns (cite these in interviews)**:
1. **Spec-first**: write a clear prompt with file paths, types, and a 3-sentence goal. Don't free-form.
2. **Small surface, fast loop**: ask for one function at a time; run + commit before next.
3. **Tests as the contract**: ask AI to write the test first, then implement.
4. **Block AI from touching**: secrets, native build files, prod config, anything mentioned in `.cursorignore` / `.aiignore`.
5. **Code review**: AI drafts, human reviews. Never the reverse.

**`.cursorignore` / `.aiignore` example** (real fintech):
```
# secrets
**/*.env
**/google-services.json
**/GoogleService-Info.plist
android/app/keystore.properties
ios/PrivacyInfo.xcprivacy

# generated
ios/Pods
android/.gradle
node_modules
.expo
dist
build

# legal/security-sensitive
docs/security/**
infra/**
```

**Production guardrails (lead-level talking points)**:
- License hygiene: AI suggestions can carry incompatible licenses — pair with a tool that flags.
- PII in prompts: never paste real user data. Anonymize or use synthetic.
- IP boundary: enterprise plans + zero-data-retention only for client codebases.
- Telemetry: track team adoption + escape rate (AI-written code that gets reverted) as a lead metric.

**Interview Q examples**:
- "How does your team use AI without shipping bad code?" → Spec-first + tests-first + ignore boundaries + PR review unchanged.
- "What's a task you'd never give to AI?" → Cryptography, payment math, native threading, anything compliance-bounded.
- "How do you measure if AI is helping the team?" → Cycle time (idea → merged), revert rate, review time per PR, plus qualitative team retro.
- "Show a case AI saved real time." → STAR-style: codemod across 80 files for RN upgrade; AI-drafted, human-reviewed; cut from 3 days to 4 hours.

---

### J.4 — Top-50 Question Index (where each topic's 50+ Qs live)

> The handbook spec asked for "Top 50 Questions" per section. Practical truth: 50 × 23 sections = 1,150 questions, which kills the value of a single document. Instead, this index points you at where the questions for each topic are **already** written, and how to scale to 50 by drilling each one short / deep / follow-up.

**How to expand any answer to 50 questions worth of practice**:
For each Q in the file, generate 4 derivatives:
1. **Short** (20 sec, recruiter-friendly).
2. **Deep** (60–180 sec, technical-friendly).
3. **Follow-up trap** (the "yes, but…" the interviewer throws).
4. **Code / war story** (the "show me, don't tell me" version).

That converts ~12 written Qs per topic into ~50 spoken Qs per topic — without padding the file.

**Index — where to find each topic's Q&A in this file**:

| Topic | Q&A locations |
|---|---|
| JS execution model, closures, event loop, promises | Sections 2; G.1–G.4; H.10–H.11 |
| TypeScript (incl. generics, utility, discriminated, infer) | Section 3; G.5 |
| React rendering, hooks, perf, Suspense, EBs | Section 4; G.6–G.8; H.9 |
| RN architecture (old + new), Hermes, Metro | Sections 5–6; G.9–G.10 |
| Performance (lists, anim, images, memory, startup) | Section 7; G.11; G.13; S1, S8 |
| Native modules (Swift / Kotlin / TurboModule) | Section 8; G.12 |
| Debugging toolkit (Hermes / Flipper / Reactotron / Instruments / Profiler / Charles / Sentry) | Section 9; G.13; H.3, H.4 |
| State management (RTK / Zustand / RQ / MMKV) | Section 10; G.14 |
| Navigation + deep linking + Expo Router | Section 11; G.16; J.1 |
| Networking (REST / GraphQL / WS / retry / token refresh) | Section 12; G.17; S11–S12 |
| Auth + Security (OAuth PKCE, Keychain, pinning, MASVS) | Sections 13, 16; G.18 |
| Offline-first + outbox + conflict | Section 14; G.15 |
| Push notifications (FCM / APNs / Expo) | Section 15; H.1; S4 |
| Accessibility + i18n + RTL | Section 17; H.2 |
| Testing (Jest / RNTL / Detox / Maestro) | Section 18; G.19 |
| CI/CD (Fastlane / GH Actions / EAS / OTA) | Section 19; G.20; J.2 |
| Observability (Sentry / Crashlytics / sourcemaps) | Section 20; G.21 |
| Mobile system design (3 walkthroughs) | Section 21; G.22; H.5; I.4 |
| DSA (12 LeetCode patterns with code) | Section 22; G.23 |
| Behavioral + STAR (10 stories) | Section 23; Appendix E |
| Resume / LinkedIn / Naukri / negotiation | Section 24; Appendices C–D; H.8 |
| Production scenarios (12 walkthroughs S1–S12) | G.24 |
| Company-specific prep | G.25; I (track-↔-company table) |
| Mock interview format (weak / good / lead) | H.6 |
| Architecture Decision Records | H.5 |
| Six engineering tracks (Core / Product / Platform / Architecture / Production / Leadership) | Appendix I |
| Sample apps (5 demo skeletons) | H.7 |
| Expo Router + EAS + config plugins | J.1, J.2 |
| AI-assisted engineering | J.3 |

---

## Final Verification — does this single file cover the entire handbook spec?

Result of auditing the file against the user's full handbook spec (Phase 1–4, Parts 1–7, Standard Topic Structure, Production Incident Library, Final Goal):

### ✅ Fully covered
| Spec | Where |
|---|---|
| About / target roles / target companies | Top, Section 1, Appendix A |
| How-to-use (4 steps) | Sections 1, 25; Appendix B |
| Phase 1 — all 23 sections of topics | Sections 2–24 + Appendices F, G, H, I, J |
| Phase 2 — deep theory + code + perf + memory + debugging + Q&A + tradeoffs + production failures + hands-on per topic | G.1–G.26 + H.1–H.12 + I.1–I.6 + J.1–J.3 |
| Phase 3 — production engineering library | G.24 (12 walkthroughs S1–S12), H.1/H.3/H.4 incident tables, I.5 release/incident/SLO frameworks |
| Phase 3 — sample apps | H.7 (5 app skeletons) |
| Phase 3 — ADRs | H.5 (template + 3 worked) |
| Phase 4 — communication mastery, mock interview structure (weak/good/lead/follow-up) | H.6 |
| Phase 4 — recruiter / behavioral / STAR / negotiation | Section 24, Appendix E (10 stories), H.8 (verbatim scripts) |
| Daily routine & golden rules | Section 25, Appendix B |
| Six engineering tracks (Core / Product / Platform / Architecture / Production / Leadership) | Appendix I |
| Production Incident Library categories | G.24 + H.1/H.3/H.4 |
| Storybook & Component Engineering | I.2 (full token pipeline + Storybook config + variants + visual regression) |
| Figma → Production workflow | I.2 |
| Expo ecosystem (Expo Router + EAS + Config Plugins) | J.1, J.2 |
| AI-assisted engineering | J.3 |
| Top-50 Questions index | J.4 (with explicit method to scale to 50 per topic) |

### ⚠️ Intentionally not done as a literal "50 Qs per section"
Producing 50 verbatim questions per each of 23 sections (= 1,150 Qs) would balloon this file to ~10k lines and dilute the existing high-density Q&A. **J.4 instead gives you the index + the 4-derivative method** to convert each existing Q into 4 spoken variants → ~250 written Qs become ~1,000 rehearsed Qs. That's the senior way to use the file.

If you want me to literally generate 50 Qs (no answers, just bank) per major section so you can drill them, say the word and I'll add an Appendix K — be aware the file will jump to ~6,000 lines.

### What is **not** in this file (and why)
- **Hands-on app source code in full** — only skeletons + key snippets. The file is a reference; the apps belong in their own GitHub repos (H.7 lists what to build).
- **Visual diagrams** (thread flow, render flow, fiber tree). Markdown can't render them well; for these use Excalidraw / Whimsical and link from your study notes if needed. The `renderMermaidDiagram` tool can produce inline diagrams later if you ask.
- **Per-company specific recent interview questions** (e.g., "what PhonePe asked Anand Kumar in Oct 2025"). That's interview-leak territory — unreliable and date-stale; not included by design. Use Section 24 + G.25 + I track-mapping for evergreen prep.

### Final verdict
**Yes — this file is now a complete single-source RN Lead/Architect handbook.** It implements:
- 25 numbered chapters (Sections 1–25)
- 11 appendices (A–J)
- ~250 written Q&A (expandable to ~1,000 with the 4-derivative method)
- ~80 runnable code samples
- 12 production incident walkthroughs + 4 incident tables (push, ANR, signing, deep links)
- 10 STAR stories + 5 recruiter scripts
- 3 mobile system designs + 3 ADRs + 1 RFC template
- Six engineering tracks with score-yourself rubric
- 5 sample-app build specs + 1 monorepo blueprint

Read top-to-bottom once. Then revise by section. Build at least 3 of the H.7 sample apps. Record the 10 STAR stories. Run mock loops with someone for 2 weeks. You're then ready for ₹40+ LPA RN/mobile-lead loops in India.
