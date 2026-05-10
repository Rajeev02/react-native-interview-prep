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

