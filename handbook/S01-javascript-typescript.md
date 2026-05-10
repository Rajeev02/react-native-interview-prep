# S1 — JavaScript & TypeScript

> ES2026 · event loop · promises · memory · TS 5.x · Zod · Temporal API · React Compiler-ready code

In 2026, JS/TS is the foundation every senior RN interview probes — but the **questions have shifted**. Hermes, the React Compiler, and async patterns under Bridgeless mode change what "knowing JS" means for a mobile engineer. This section is the production-grade JS/TS handbook for RN engineers.

## Topics in this section

- [Q1. The event loop in React Native — JS thread, microtasks, RuntimeScheduler](#q1-the-event-loop-in-react-native--js-thread-microtasks-runtimescheduler)
- [Q2. Closures and the most common memory leak patterns in RN](#q2-closures-and-the-most-common-memory-leak-patterns-in-rn)
- [Q3. Promises deep dive — chaining, cancellation, error semantics](#q3-promises-deep-dive--chaining-cancellation-error-semantics)
- [Q4. Advanced TypeScript — generics, conditional types, `infer`](#q4-advanced-typescript--generics-conditional-types-infer)
- [Q5. Discriminated unions and exhaustiveness with `never`](#q5-discriminated-unions-and-exhaustiveness-with-never)
- [Q6. `satisfies` vs type assertion vs annotation](#q6-satisfies-vs-type-assertion-vs-annotation)
- [Q7. Zod for runtime validation at boundaries (API + storage)](#q7-zod-for-runtime-validation-at-boundaries-api--storage)

---

## Q1. The event loop in React Native — JS thread, microtasks, RuntimeScheduler

### Difficulty
Intermediate → Advanced

### Interview Frequency
Very Common at senior+ rounds.

### Prerequisites
JS basics; familiarity with `Promise.then` and `setTimeout`.

### TL;DR
RN runs JS on **one thread** with **microtasks** (Promise callbacks, `queueMicrotask`) and **macrotasks** (timers, native callbacks). In Bridgeless mode, the **RuntimeScheduler** prioritizes work by lane (input > UI > default > idle), so a long Promise chain can starve gestures if you don't yield.

### 30-Second Interview Answer
"React Native runs JavaScript on a single JS thread. The event loop processes one macrotask, drains all microtasks, then yields. In 2026 with Bridgeless + RuntimeScheduler, work is also tagged by priority lane — input and UI updates preempt default work. A long synchronous Promise chain still blocks the JS thread, which means dropped frames on gestures even with the new architecture."

### 2-Minute Practical Answer
The model:
- **One macrotask** runs to completion → drain all **microtasks** → render commit → next macrotask.
- **Microtasks**: `Promise.then`, `queueMicrotask`, `await` continuations.
- **Macrotasks**: `setTimeout(_, 0)`, `setImmediate`, native module callbacks, JSI invocations, scheduled React work.

In RN with the New Arch:
- The **RuntimeScheduler** (RN 0.74+) sits above the loop and assigns priorities (Sync, InputContinuous, Default, Idle).
- React 19 transitions and Suspense ride on these lanes.
- JS work is still single-threaded — but the scheduler can **interrupt** lower-priority React work for a higher-priority one.

What still blocks the UI:
- A `for` loop that runs 100ms of synchronous work → 6 dropped frames at 60fps.
- A long Promise chain without yielding (`for (...) await x()`).
- Synchronous JSI calls that take > 1 frame.

How to yield:
- `setTimeout(fn, 0)` (queues a macrotask, lets gestures process).
- `await new Promise(r => setTimeout(r, 0))` (same idea).
- `InteractionManager.runAfterInteractions()` (defer until gestures finish).
- `startTransition(fn)` (React schedules at Transition lane; preemptible by input).

### 5-Minute Architecture Answer
The legacy bridge model: JS thread → Bridge (serialized JSON queue) → Native thread, with batched flushes every frame. This is mostly historical now.

The Bridgeless model (2026 default):
- JS runs on a JS thread inside Hermes.
- TurboModules are **synchronous JSI calls** (no serialization, no queue).
- Fabric renderer commits shadow trees and notifies the UI thread directly.
- The **RuntimeScheduler** is a C++ scheduler that sits between React and the host platform; it knows about React's lanes, gesture system priorities, and idle time.

Within the JS thread, microtask vs macrotask semantics are unchanged from V8/JSC standards. But the interaction with the rest of the system is different:
- Microtasks **drain before yielding to the host** — so 1000 chained promises still block input.
- Hermes 2026 has a fast microtask queue (much cheaper than legacy JSC).
- The scheduler can yield to the host in the middle of React's render work via cooperative yields.

Key implication: in 2026, the bottleneck for "smooth UI" is not the bridge — it's **your synchronous JS work**. Profile with the Performance tab (DevTools) and look for tasks > 16ms.

### The "Why"
- Mobile UX expectations are 60fps minimum (120fps on ProMotion). One blocking task = visible jank.
- Most "RN is slow" complaints in 2026 trace to JS-thread starvation, not the bridge.

### Mental Model
JS thread = single-lane road. Microtasks = vehicles in your lane queue. Scheduler = traffic light that can switch priority lanes between batches.

### Internal Working (2026 Context)
- Hermes implements the standard microtask queue per HTML spec semantics.
- `queueMicrotask()` is faster than `Promise.resolve().then()` (no Promise allocation).
- RuntimeScheduler integrates with `requestAnimationFrame` / iOS CADisplayLink to know when frames are imminent.
- React 19's `startTransition` interacts with the scheduler to mark work as preemptible.

### Modern Implementation (Code)

```ts
// Bad — blocks the JS thread for ~80ms processing 50k items.
function transformAll(items: Item[]): Result[] {
  return items.map((i) => heavyTransform(i));
}

// Better — chunk and yield to gestures.
async function transformAllChunked(
  items: Item[],
  chunkSize = 500,
): Promise<Result[]> {
  const out: Result[] = [];
  for (let i = 0; i < items.length; i += chunkSize) {
    const slice = items.slice(i, i + chunkSize);
    out.push(...slice.map(heavyTransform));
    // Yield: lets RuntimeScheduler process input before next chunk.
    await new Promise<void>((r) => setTimeout(r, 0));
  }
  return out;
}

// 2026 idiomatic — use a transition for non-urgent rendering.
function SearchResults({ items }: { items: Item[] }) {
  const [query, setQuery] = useState('');
  const [pending, startTransition] = useTransition();

  const filtered = useMemo(() => items.filter((i) => i.name.includes(query)), [items, query]);

  return (
    <>
      <TextInput
        onChangeText={(t) => startTransition(() => setQuery(t))}
      />
      {pending && <ActivityIndicator />}
      <FlashList data={filtered} renderItem={...} />
    </>
  );
}
```

### Comparison

| Pattern | Yields to gestures? | Cost |
|---|---|---|
| Synchronous loop | No | Blocks JS thread |
| Microtask chain (`for await`) | No (drains together) | Blocks JS thread |
| `setTimeout(_, 0)` between chunks | Yes | One extra macrotask per chunk |
| `InteractionManager.runAfterInteractions` | Yes (waits for animations) | Higher latency |
| `startTransition` | Yes (preemptible) | Best for React work |

### Production Usage
- For non-React heavy work (parsing, transforming): chunk + `setTimeout(_, 0)`.
- For React state updates that aren't urgent: `startTransition`.
- For one-shot work after gesture/animation: `InteractionManager.runAfterInteractions`.

### Hands-On Exercise
1. Build a screen that processes 10k items synchronously on mount. Scroll while it runs — observe jank.
2. Refactor with `setTimeout`-yielding chunks. Observe no jank.
3. Refactor again using `startTransition` (for React-driven version). Confirm responsiveness.

### Common Mistakes
- Assuming `Promise.then` yields to the host (it doesn't — microtasks drain together).
- Putting heavy work in `useEffect` without yielding (still blocks the next paint).
- Confusing "async" with "non-blocking" — `await` blocks the next microtask, not the JS thread overall.

### Production Red Flags
- Long-running CPU work in render or `useMemo` (should be off the JS thread or chunked).
- Synchronous parsing of large JSON in JS (use a native module or chunk).
- Tight `for await` over thousands of items.

### Performance & Metrics
- Tasks > 16ms in Performance profiler are smoking-gun jank sources.
- RN DevTools shows "JS thread idle %" — < 60% under load = problematic.

### Decision Framework
- React state updates → `startTransition` (free with React 19).
- Pure computation → chunk with `setTimeout(_, 0)` or move to a worklet (Reanimated UI thread) / native module.
- Parsing huge JSON → native module (e.g., `react-native-json-tree-parser`) or stream.

### Senior-Level Insight
The single most underused tool in RN is `startTransition`. Most "search lag" / "filter lag" bugs disappear with one line: wrap the `setQuery` in `startTransition`. With React Compiler, this scales without manual memoization.

### Real-World Scenario
**Symptom:** Pull-to-refresh on a feed feels sluggish.
**Investigation:** Performance trace shows 240ms task on refresh — a synchronous re-sort of 5k items.
**Root cause:** Sort runs in `useMemo` on every refresh.
**Fix:** Chunk the sort + yield, or move to a Reanimated worklet for the comparison.
**Prevention:** Treat any computed list > 1k items as "needs profiling."

### Production Failure Story
**Incident:** App's search dropped to 12fps in production.
**Investigation:** Each keystroke triggered a synchronous `JSON.parse` of a 2MB cache.
**Root cause:** Cache parsed on every render instead of memoized + parsed once.
**Fix:** Parse once at app start; memoize in MMKV; use `startTransition` for filter.
**Prevention:** Profile before shipping; budget < 16ms per JS task.

### Debugging Checklist
1. Performance profiler: any tasks > 16ms?
2. Are heavy ops in `useEffect` or render?
3. Are state updates wrapped in `startTransition` where appropriate?
4. Could this work move to a Reanimated worklet or native module?

### Advanced / Internal Knowledge
- `queueMicrotask` is faster than `Promise.resolve().then()` because it skips Promise allocation.
- Hermes' microtask queue is FIFO; ordering across `await` continuations is deterministic.
- RuntimeScheduler exposes priority via React's internal `unstable_scheduler` package.

### 2026 AI Tip
AI-suggested code often uses `for await ... of` over arrays — check if that's blocking the JS thread. Replace with chunked + yielding patterns for large datasets.

### Related Topics
Q3, Q4, S07 (performance), S04 (Bridgeless / RuntimeScheduler).

### Interview Follow-Up Questions
- "How does microtask draining differ from macrotask scheduling?"
- "What is the RuntimeScheduler and how does it differ from the legacy bridge model?"
- "How would you process 100k records without dropping frames?"

### Memory Hook
**"One thread, two queues, four lanes — yield or jank."**

### Revision Notes
> RN JS thread runs macrotask → drain microtasks → next; RuntimeScheduler adds priority lanes (Sync > InputContinuous > Default > Idle); microtask chain doesn't yield; chunk + `setTimeout(0)` or `startTransition` to yield.

---

## Q2. Closures and the most common memory leak patterns in RN

### Difficulty
Intermediate

### Interview Frequency
Common at mid–senior rounds.

### Prerequisites
JS scope rules, garbage collection basics.

### TL;DR
Closures retain references to their enclosing scope; in RN the most common leaks are **uncleared subscriptions**, **timers in unmounted components**, **ref-held large objects**, and **stale closures inside long-lived modules**.

### 30-Second Interview Answer
"A closure keeps its enclosing variables alive as long as the closure is referenced. In RN this becomes a leak when a long-lived subscription (event listener, timer, native module callback) holds a closure over a component's props or state — preventing the component (and its tree) from being garbage-collected. Fix: cleanup in `useEffect`'s return function for every subscription, timer, animation, and listener."

### 2-Minute Practical Answer
Closure 101: a function created inside another function "closes over" its enclosing variables. Those variables can't be GC'd while the closure is reachable.

Common RN leaks:
1. **Event subscriptions** without cleanup:
   ```ts
   useEffect(() => {
     const sub = DeviceEventEmitter.addListener('foo', handle);
     return () => sub.remove(); // <-- without this, leak
   }, []);
   ```
2. **Timers** in unmounted components:
   ```ts
   useEffect(() => {
     const id = setInterval(() => setX((x) => x + 1), 1000);
     return () => clearInterval(id);
   }, []);
   ```
3. **Refs holding large objects** (images, parsed JSON) that outlive their need.
4. **Module-level caches** that grow forever (no eviction).
5. **Stale closures** — capturing a state value that's never refreshed (use refs for "always fresh" reads).

In Hermes, GC is generational + Hades concurrent in 2026; small leaks get collected, but **reachable** closures survive forever. The key: kill the references.

### 5-Minute Architecture Answer
RN's memory model:
- JS heap managed by Hermes (Hades GC, mostly concurrent).
- Native heap (UIView/UIViewController on iOS, View on Android) tied to React tree.
- **Bridges between JS and native are the most common leak source** — even in Bridgeless mode, JSI HostObjects can pin native memory if you don't release them.

The leak lifecycle:
- A component mounts → creates closures (event handlers, callbacks, timers).
- Component unmounts → React tears down, **but** if any closure is still reachable from a long-lived owner (global emitter, native module, navigation singleton), the entire component tree (props, state, refs) stays alive.

Detection workflow (2026):
- Xcode Instruments → Allocations / Leaks (iOS).
- Android Studio Profiler → Memory → heap dumps.
- React Native DevTools → Memory tab (works in 2026 for Hermes).
- `console.log(performance.memory.usedJSHeapSize)` periodically.

The fix pattern is uniform: **every subscription needs a return cleanup**. ESLint `react-hooks/exhaustive-deps` + custom rules catch many. The remaining are caught by manual heap-dump diffing across navigation cycles.

### The "Why"
- Mobile RAM is constrained (4GB on mid-range Android in 2026); leaks → OOM → app kills.
- iOS jetsam and Android low-memory killer don't show "leak" — they show crash; leaks are silent until they aren't.

### Mental Model
Closure = invisible thread tying everything in scope to the function. Leak = forgot to cut the thread. GC only collects when **no thread is left**.

### Internal Working (2026 Context)
- Hermes Hades: concurrent generational GC; minor GC is ~1ms, major is amortized.
- React Compiler **doesn't fix leaks** — it can hoist closures, which sometimes makes leaks more obvious.
- Reanimated worklets are JS functions copied to UI runtime; capturing large objects in worklets ships them across runtimes — memory and perf cost.

### Modern Implementation (Code)

```tsx
// Subscription leak — common
function ChatRoom({ roomId }: { roomId: string }) {
  useEffect(() => {
    socket.on(`room:${roomId}`, handleMessage);
    // FORGOT: socket.off — leaks closure over roomId forever
  }, [roomId]);
  return <Messages />;
}

// Fixed
function ChatRoom({ roomId }: { roomId: string }) {
  useEffect(() => {
    const handler = (msg: Msg) => receive(roomId, msg);
    socket.on(`room:${roomId}`, handler);
    return () => socket.off(`room:${roomId}`, handler);
  }, [roomId]);
  return <Messages />;
}

// Stale closure — accidentally captures old state
function Counter() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setCount(count + 1), 1000); // captures count=0 forever
    return () => clearInterval(id);
  }, []);
}

// Fixed: functional update
function Counter() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setCount((c) => c + 1), 1000);
    return () => clearInterval(id);
  }, []);
}
```

### Comparison

| Leak source | Detection | Fix |
|---|---|---|
| Event listener | Heap dump shows handler retained | `return () => unsubscribe()` |
| Timer | Heap dump shows callback + state | `return () => clearTimeout/Interval` |
| Module cache | Steady heap growth across nav | LRU eviction |
| Native module callback | Native heap retained | Explicit invalidation API |
| Stale closure | Wrong values, not memory | Functional update or ref |

### Production Usage
- Set up **memory budgets per screen** (e.g., < 50MB delta after navigation).
- Run **soak tests** in CI: navigate 100 cycles, assert heap returns to baseline ± 10%.
- Sentry / Crashlytics flag OOM crashes (iOS jetsam, Android low-memory) — investigate every one.

### Hands-On Exercise
1. Build a screen with `setInterval`, mount/unmount 50 times. Take heap dumps before/after. See growth.
2. Add cleanup. Re-test. Heap returns to baseline.
3. Add a `Map` cache at module scope. Mount/unmount; observe never-shrinking. Add LRU.

### Common Mistakes
- Cleanup in component body instead of `useEffect` return.
- Forgetting cleanup in custom hooks (cascades to every consumer).
- Stale closure inside `setInterval` (`count` never advances) — use functional update.
- `useRef` to a large object that's never reset.

### Production Red Flags
- Steady heap growth across navigation (not GC-collectible).
- OOM crashes only on low-RAM devices.
- "Memory warnings" from iOS in production logs.

### Performance & Metrics
- Heap baseline + heap-after-soak delta.
- OOM crash rate (target: < 0.1% of sessions on bottom 10% of devices).
- Native memory (UIView count) tracked separately.

### Decision Framework
- Heap grows slowly → stale closure or unbounded cache.
- Heap grows fast → uncleared subscription / timer.
- Crashes only after specific feature → leak in that feature's lifecycle.

### Senior-Level Insight
"Memory leaks in RN are 90% lifecycle bugs and 10% real engine issues." If you find a leak, the cleanup function is missing or wrong. ESLint can find most; soak tests in CI catch the rest.

### Real-World Scenario
**Symptom:** App OOM-crashes after 30 minutes of use.
**Investigation:** Heap dump shows 50 instances of `MessageHandler` retained.
**Root cause:** Push-notification handler subscribed in `useEffect([])` but cleanup was inside an `if` that never ran.
**Fix:** Unconditional cleanup. Crash rate dropped 80% on low-RAM devices.

### Production Failure Story
**Incident:** Live-streaming app crashed after 12 minutes consistently.
**Investigation:** Heap grew 5MB/min; native memory grew 20MB/min.
**Root cause:** Each `<Video>` mount allocated a native AVPlayer; old players never released because of a JS-side ref retained in a context provider.
**Fix:** Provider tracks current player, releases on swap.
**Prevention:** Document lifecycle for all native-backed components; soak test in CI.

### Debugging Checklist
1. Take heap dumps before/after the suspect flow. Diff retained objects.
2. Search for `addListener` / `addEventListener` / `setInterval` / `setTimeout` without paired cleanup.
3. Check Reanimated worklets for captured large objects.
4. Profile native memory (iOS Instruments / Android Profiler) separately from JS heap.

### Advanced / Internal Knowledge
- Hermes' `gc()` (debug builds) forces a major GC — useful for triage.
- WeakMap / WeakSet allow caching without retaining; underused in RN.
- React Compiler hoists closures; check the compiled output if leaks feel mysterious.

### 2026 AI Tip
AI often forgets cleanup functions. After accepting AI-generated `useEffect`, manually verify the return cleanup matches every side-effect set up.

### Related Topics
Q1, Q3, S07 (perf), S17 (testing — soak tests).

### Interview Follow-Up Questions
- "How do you find a memory leak in production?"
- "Why does this `setInterval` always print 0?" (Stale closure.)
- "When should you use `useRef` vs `useMemo`?"

### Memory Hook
**"Every subscription gets a cleanup. Every long-lived ref gets a budget."**

### Revision Notes
> Closures keep enclosing scope alive; RN leaks come from uncleared subs/timers/listeners and refs pinning large objects; fix = `useEffect` return cleanup; detect via heap dump diffs and soak tests.

---

## Q3. Promises deep dive — chaining, cancellation, error semantics

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common at mid–senior; deep at senior+.

### Prerequisites
`async`/`await` syntax, basic event-loop intuition.

### TL;DR
Promises model **single-shot async values**; chains are linear pipelines of microtasks; cancellation needs an `AbortController` (Promises themselves don't cancel); errors propagate down the chain — uncaught rejections crash in 2026.

### 30-Second Interview Answer
"A Promise is a one-time async value with three states: pending, fulfilled, rejected. `.then` and `.catch` schedule microtask continuations. Promises don't natively cancel — you wire an `AbortController` and check `signal.aborted`. Errors propagate down the chain; an uncaught rejection in 2026 RN crashes the JS context unless you handle the global `unhandledrejection`."

### 2-Minute Practical Answer
Core API:
- `Promise.resolve(v)`, `Promise.reject(e)`.
- `.then(onF, onR)`, `.catch(onR)`, `.finally(fn)`.
- `Promise.all`, `Promise.allSettled`, `Promise.any`, `Promise.race`.
- ES2024+ `Promise.withResolvers()` (clean way to expose resolve/reject).

Chaining rules:
- `.then` returns a new Promise. The next `.then` waits for it.
- Throwing in `.then` rejects the next Promise.
- Returning a Promise from `.then` flattens it (no nested promises).

Cancellation:
- Promises don't cancel; you abort the **work**.
- Pass an `AbortSignal` to fetch / your wrapper.
- Check `signal.aborted` in long-running tasks; throw `AbortError`.

Errors:
- Uncaught rejections in RN 2026 → red box in dev, crash in prod (configurable but on by default).
- `await` makes errors throw synchronously inside async functions — wrap in `try/catch`.
- `Promise.all` rejects on first failure; `allSettled` waits for all.

### 5-Minute Architecture Answer
Promise semantics in RN are standard ES; the gotchas are integration:

1. **Microtask draining** — a chain of 1000 `.then`s blocks the JS thread because all microtasks drain before the loop yields. Use `setTimeout(_, 0)` for cooperative yielding.

2. **Cancellation discipline** — RN screens can unmount mid-fetch. Without `AbortController`, the late response can `setState` on an unmounted component (warns in dev, leaks in prod).

3. **Error propagation** — A rejected Promise that no one `await`s or `.catch`es becomes an unhandled rejection. RN 2026 by default crashes in production; this is intentional — silent failures are worse than crashes. Always `.catch` at the top of every async chain.

4. **Concurrency primitives**:
   - `Promise.all` — fail fast.
   - `Promise.allSettled` — wait for all, get results array.
   - `Promise.any` — first success wins.
   - `Promise.race` — first settled (success or failure) wins; useful for timeouts.

5. **Retry / backoff** — wrap with exponential backoff + jitter; pair with `AbortController` for user cancellation.

### The "Why"
- Networking, storage, and native module calls are all async; Promises are the common abstraction.
- Bad Promise hygiene (missing cancellation, swallowed errors) is the #2 cause of mobile bugs after race conditions.

### Mental Model
Promise = a **mailbox** with one slot. Once filled (fulfilled or rejected), it's locked. `.then` = "tell me when the mail arrives, then forward." `AbortController` = "tell the sender to stop trying."

### Internal Working (2026 Context)
- Hermes implements native Promise; allocations are cheap (faster than JSC).
- `await` lowers to `.then` continuations in Hermes' bytecode (no async/await runtime overhead).
- `AbortSignal.timeout(ms)` (ES2024) replaces manual `setTimeout` + abort dance.
- `Promise.withResolvers()` removes the awkward `let resolve; new Promise(...)` pattern.

### Modern Implementation (Code)

```ts
// 2026 idiomatic fetch with cancellation + timeout + retry
async function fetchJSON<T>(url: string, opts: {
  signal?: AbortSignal;
  retries?: number;
  timeoutMs?: number;
} = {}): Promise<T> {
  const { signal, retries = 3, timeoutMs = 8000 } = opts;
  const controller = new AbortController();
  const timeout = AbortSignal.timeout(timeoutMs);
  // Combine user abort + timeout
  const combined = AbortSignal.any([controller.signal, timeout, ...(signal ? [signal] : [])]);

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url, { signal: combined });
      if (!res.ok) throw new HTTPError(res.status, url);
      return (await res.json()) as T;
    } catch (e) {
      if (combined.aborted) throw e;
      if (attempt === retries) throw e;
      const backoff = Math.min(2 ** attempt * 250, 4000) + Math.random() * 200;
      await new Promise((r) => setTimeout(r, backoff));
    }
  }
  throw new Error('unreachable');
}

// Component with cancellation
function Profile({ userId }: { userId: string }) {
  const [data, setData] = useState<User | null>(null);
  useEffect(() => {
    const ctrl = new AbortController();
    fetchJSON<User>(`/users/${userId}`, { signal: ctrl.signal })
      .then(setData)
      .catch((e) => {
        if (e.name !== 'AbortError') logError(e);
      });
    return () => ctrl.abort();
  }, [userId]);
  return <View>...</View>;
}

// Promise.withResolvers pattern (ES2024)
function deferred<T>() {
  const { promise, resolve, reject } = Promise.withResolvers<T>();
  return { promise, resolve, reject };
}
```

### Comparison

| API | Use case |
|---|---|
| `Promise.all` | All must succeed; fast-fail |
| `Promise.allSettled` | Need every result, even failures |
| `Promise.any` | First success wins (e.g., racing replicas) |
| `Promise.race` | First to settle (timeout pattern) |

### Production Usage
- Every `useEffect` doing async work → `AbortController` + cleanup.
- TanStack Query / RTK Query handle this for you — prefer them over hand-rolled fetches.
- Wrap top-level effects in `try/catch` to log to Sentry; never let rejections become silent.

### Hands-On Exercise
1. Build a search box that fetches results on each keystroke. Without cancellation, you'll see racing responses.
2. Add `AbortController` per request; abort on next keystroke. Confirm latest result wins.
3. Replace with TanStack Query — observe the same behavior with less code.

### Common Mistakes
- Forgetting to `await` a Promise → "fire and forget" leaks errors.
- Returning a Promise from `useEffect` (React doesn't await it).
- Using `Promise.all` when one failure should still allow others (use `allSettled`).
- Re-throwing inside `.catch` then forgetting to handle upstream.

### Production Red Flags
- Async functions that never throw / never `try/catch` → silent failures.
- `setState` after unmount warnings → missing cancellation.
- Sentry shows lots of `AbortError` in prod — those are usually fine to filter.

### Performance & Metrics
- Network task duration (P50/P95/P99).
- Cancellation rate (% of in-flight requests aborted) — high rate suggests UX or caching opportunity.
- Unhandled rejection count → should be 0.

### Decision Framework
- New code → use TanStack Query / RTK Query (cancellation, dedup, cache built-in).
- Hand-rolled fetch → always pair with `AbortController` + try/catch.
- Background tasks → use a queue with retries (S11 patterns).

### Senior-Level Insight
"Cancellation is a UX feature, not a perf feature." Without it, users see stale data, you log errors that aren't real bugs, and analytics get noisy. Wire `AbortController` from day one.

### Real-World Scenario
**Symptom:** Search results "flicker" between old and new keywords.
**Investigation:** Network panel shows multiple in-flight requests racing.
**Root cause:** No cancellation on previous searches; later request resolves first occasionally.
**Fix:** `AbortController` per keystroke; abort previous before issuing next.

### Production Failure Story
**Incident:** App started crashing on iOS 17 after silent rejection became hard error.
**Investigation:** A `fetch().then(setState)` chain had no `.catch`; one network failure triggered unhandled rejection.
**Root cause:** Engineer assumed "errors won't happen here."
**Fix:** Mandatory `.catch` at every top-level chain; ESLint rule `no-floating-promises` enforces it.

### Debugging Checklist
1. Is every async chain terminated by `.catch` or `try/catch`?
2. Does every component-scoped Promise have an `AbortController`?
3. Are unhandled-rejection logs going to Sentry?
4. Is `Promise.all` the right primitive (vs `allSettled`)?

### Advanced / Internal Knowledge
- `await` is implemented as `.then` in V8/Hermes; no special runtime.
- `Promise.race` against `AbortSignal.timeout` is a clean timeout pattern.
- Top-level `await` in modules works in Hermes 2026 if Metro is configured for ESM output.

### 2026 AI Tip
AI often suggests `try/catch` around `await` but forgets `AbortController` for cancellation. Add it explicitly when generated code does network work in components.

### Related Topics
Q1, S09 (networking), S08 (state mgmt with TanStack Query).

### Interview Follow-Up Questions
- "How do you cancel a Promise?"
- "What happens to errors in `Promise.all` vs `Promise.allSettled`?"
- "Implement a retry-with-jitter wrapper."

### Memory Hook
**"Promise = mailbox. AbortController = stop sign. Catch or crash."**

### Revision Notes
> Promises = single-shot async values; chain via `.then`/`await`; cancel via `AbortController`; uncaught rejections crash in RN 2026; use `Promise.allSettled` when partial failure is acceptable.

---

## Q4. Advanced TypeScript — generics, conditional types, `infer`

### Difficulty
Advanced

### Interview Frequency
Common at senior+ rounds.

### Prerequisites
TS basics (interfaces, generics 101).

### TL;DR
Generics parameterize types over types; conditional types (`T extends U ? X : Y`) branch at the type level; `infer` extracts inner types from compound types; together they let you write **API-shape-driven** types that catch bugs at compile time.

### 30-Second Interview Answer
"Generics let me write reusable types that adapt to inputs — `function id<T>(x: T): T`. Conditional types branch at the type level: `type IsArray<T> = T extends Array<infer U> ? U : never`. `infer` introduces a fresh type variable I can use only on the true branch. Together they power utility types like `ReturnType`, `Awaited`, and library APIs like TanStack Query's typed queries."

### 2-Minute Practical Answer
Generics:
```ts
function map<T, U>(arr: T[], fn: (t: T) => U): U[] {
  return arr.map(fn);
}
const xs = map([1, 2], (n) => n.toString()); // xs: string[]
```

Constraints:
```ts
function pluck<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

Conditional types + `infer`:
```ts
type Awaited<T> = T extends Promise<infer U> ? Awaited<U> : T;
type ReturnType<F> = F extends (...args: any) => infer R ? R : never;
type ElementOf<A> = A extends Array<infer E> ? E : never;
```

Mapped + conditional combined:
```ts
type Required<T> = { [K in keyof T]-?: T[K] };
type ReadonlyDeep<T> = { readonly [K in keyof T]: T[K] extends object ? ReadonlyDeep<T[K]> : T[K] };
```

### 5-Minute Architecture Answer
Type-level programming in TS lets you encode **invariants** that runtime tests can't catch cheaply. Real wins in RN/web codebases:

1. **API contracts** — given an OpenAPI / GraphQL schema, derive request/response types so route handlers and clients can't drift.
2. **Form validation** — `z.infer<typeof schema>` derives form types from a Zod schema; one source of truth.
3. **Discriminated reducers** — typed Redux/Zustand actions auto-narrow in handlers.
4. **Strongly-typed navigation** — Expo Router and React Navigation expose types where the route name implies the params.
5. **Derived component props** — `ComponentProps<typeof Button>` for wrapping libraries.

The cost: complex type errors. The mitigation: keep type-level code small, well-named, well-tested via `tsd` / type-only test files.

Common patterns:
- **Distributive conditionals** — `T extends U ? ...` distributes over unions: `Exclude<'a' | 'b', 'a'> = 'b'`.
- **`infer` in tuples** — extract head/tail: `type Head<T> = T extends [infer H, ...any] ? H : never`.
- **Template literal types** — `type Route = ` /users/${string}` `; powerful with `infer`: extract path params.
- **Variance markers** (TS 4.7+) — `in` / `out` for generic positions when needed.

### The "Why"
- Type-driven development at scale catches whole classes of bugs (wrong shape, forgotten case, drift between client and server).
- React Compiler + types together let you delete a lot of runtime checks.

### Mental Model
TS types are a small functional language. Generics = parameters. Conditionals = `if`. `infer` = `let`. Mapped types = `for`. The output is a type, not a value.

### Internal Working (2026 Context)
- TS 5.x ships `satisfies`, const type params, and decorators (stage 3).
- TS 5.5 (in 2026) added inferred type predicates.
- TypeScript LSP performance is significantly faster on large codebases vs 2023.
- React 19 + types: `useActionState` and `useOptimistic` have first-class type inference.

### Modern Implementation (Code)

```ts
// Path-param extraction from a string literal
type ExtractParams<S extends string> =
  S extends `${string}:${infer P}/${infer Rest}` ? P | ExtractParams<`/${Rest}`>
  : S extends `${string}:${infer P}` ? P
  : never;

type R = ExtractParams<'/users/:userId/posts/:postId'>; // 'userId' | 'postId'

// Strongly-typed reducer
type Action =
  | { type: 'add'; payload: { item: string } }
  | { type: 'remove'; payload: { id: string } };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'add':    return { ...state, items: [...state.items, action.payload.item] };
    case 'remove': return { ...state, items: state.items.filter((i) => i.id !== action.payload.id) };
    default: {
      const _exhaustive: never = action; // compile error if a case is missed
      return state;
    }
  }
}

// Generic API hook
function useFetch<T>(url: string): { data: T | null; error: Error | null } { /* ... */ }
const { data } = useFetch<User>('/me'); // data: User | null
```

### Comparison

| Pattern | Use |
|---|---|
| Generic function | Reuse logic across types |
| Constrained generic | Reuse + safety (`K extends keyof T`) |
| Conditional type | Branch at type level |
| `infer` | Extract sub-types |
| Mapped type | Transform every key |
| Template literal type | Type-level string parsing |

### Production Usage
- API client types derived from OpenAPI or GraphQL codegen.
- Zod schemas + `z.infer` as the single source of types.
- Strongly typed events for analytics (one wrong field = compile error).

### Hands-On Exercise
1. Implement `Awaited<T>` from scratch.
2. Implement `Pick<T, K>` and `Omit<T, K>`.
3. Type a typed event emitter: `emit<E extends keyof Events>(e: E, p: Events[E])`.

### Common Mistakes
- Over-generic APIs that lose specific type info.
- `as any` to silence compiler — defeats the purpose.
- Deeply nested conditional types that are unreadable; refactor into named utility types.
- Forgetting that `extends` distributes over unions.

### Production Red Flags
- `// @ts-ignore` / `// @ts-expect-error` in core domains without a comment explaining why.
- `any` in public function signatures.
- Type assertions used to bypass narrowing.

### Performance & Metrics
- TS compile time (`tsc --noEmit`); large codebases need project references.
- Editor responsiveness — slow IntelliSense often = type complexity issue.

### Decision Framework
- Logic that runs against many shapes → generic.
- API that returns different shapes per input → conditional type.
- Need to extract a piece of a type → `infer`.

### Senior-Level Insight
The strongest TS codebases use **boring types in the domain** and **clever types only in 1–2 utility files**. Cleverness in business code = onboarding pain.

### Real-World Scenario
**Symptom:** Backend returns `total_count` but app expects `totalCount`; bug ships.
**Investigation:** Type was `any`.
**Root cause:** Hand-written types diverged from API.
**Fix:** Generate types from OpenAPI spec; CI fails if out of sync.
**Prevention:** Codegen from source of truth.

### Production Failure Story
**Incident:** Analytics event firing wrong field name; data team blind for 2 weeks.
**Root cause:** Event payload typed as `Record<string, unknown>`.
**Fix:** Strongly typed `EventMap` with discriminated union per event name. Compiler catches drift.

### Debugging Checklist
1. Is `any` present? Replace with `unknown` or specific type.
2. Are types derived from a single source of truth (API, schema)?
3. Is the `default` branch in a switch using `never` for exhaustiveness?
4. Are public function signatures fully typed (no inferred `any`)?

### Advanced / Internal Knowledge
- TS 5.x's `const` type parameters preserve literal types: `function f<const T>(x: T): T`.
- Variance annotations (`in`/`out`) on generics for soundness.
- Inferred type predicates (TS 5.5+): `function isString(x: unknown) { return typeof x === 'string' }` now infers `x is string`.

### 2026 AI Tip
AI generates verbose `any`-laden types. After accepting, look for `any` and replace with proper generics/conditionals. AI is good at suggesting utility-type names.

### Related Topics
Q5, Q6, Q7, S08 (state management types).

### Interview Follow-Up Questions
- "Implement `DeepReadonly<T>`."
- "Why does `T extends U ? X : Y` distribute over unions?"
- "What's the difference between `interface` and `type`?"

### Memory Hook
**"Generics parameterize, conditionals branch, `infer` extracts."**

### Revision Notes
> Generics + conditional types + `infer` enable type-level programming; use for API contracts, derived types, exhaustive switches; keep cleverness in utility files; codegen from source of truth.

---

## Q5. Discriminated unions and exhaustiveness with `never`

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common at senior+ rounds.

### Prerequisites
Generics, switch statements.

### TL;DR
A discriminated (tagged) union is `{ tag: 'A'; ... } | { tag: 'B'; ... }`; TS narrows by the discriminant; `const _: never = x` in the `default` branch enforces exhaustiveness at compile time.

### 30-Second Interview Answer
"Discriminated unions model 'one of N shapes' with a literal `kind` field. In a switch on `kind`, TS narrows to that case's full type. To enforce exhaustiveness, I assert the default branch's value to `never` — adding a new variant becomes a compile error until I handle it. This is how I model Redux actions, async states, and parser results."

### 2-Minute Practical Answer
```ts
type AsyncState<T> =
  | { kind: 'idle' }
  | { kind: 'loading' }
  | { kind: 'success'; data: T }
  | { kind: 'error'; error: Error };

function render(s: AsyncState<User>) {
  switch (s.kind) {
    case 'idle':    return <Idle />;
    case 'loading': return <Spinner />;
    case 'success': return <Profile user={s.data} />;
    case 'error':   return <Err msg={s.error.message} />;
    default: {
      const _exhaustive: never = s;
      throw new Error('non-exhaustive');
    }
  }
}
```

When you add `{ kind: 'cancelled' }` to the union, the `_exhaustive` line becomes a TS error → you must handle it.

Why this beats nullable booleans (`isLoading`, `isError`):
- Impossible states are unrepresentable (can't have `isLoading=true` AND `data` set).
- Refactors are safe: TS forces you to handle every case.
- Pattern matching is natural.

### 5-Minute Architecture Answer
Discriminated unions are the **single best TS feature for modeling business logic**. They eliminate the "boolean explosion" anti-pattern (`isLoading && !isError && data && !cancelled`) by representing each state as a distinct shape.

Use cases:
- **Async state** — replaces `useState({ loading, data, error })` triples.
- **Form state** — `{ status: 'editing' | 'submitting' | 'success' | 'error' }`.
- **Reducers** — Redux Toolkit, Zustand actions.
- **Parsing results** — `{ ok: true; value } | { ok: false; error }`.
- **Domain events** — `OrderCreated | OrderShipped | OrderCancelled`.

The exhaustiveness pattern (`const _: never = x`) is the **safety contract**. When the team adds a new variant, the compiler walks every switch and refuses to build until each is updated. This is the single highest-ROI TS pattern.

Pairs beautifully with:
- **Pattern matching libraries** (`ts-pattern`) — exhaustiveness without the `never` boilerplate.
- **Zod** — `z.discriminatedUnion('kind', [...])` validates and narrows.
- **TanStack Query** — its returned status (`pending | success | error`) is itself a discriminated union.

### The "Why"
- Boolean state is a code smell when > 2 booleans correlate; the truth table has impossible cells.
- Discriminated unions match the domain (a request can't be loading AND failed); fewer bugs at the boundary.

### Mental Model
Boolean state = a grid of cells; discriminated union = a list of rows that actually exist.

### Internal Working (2026 Context)
- TS narrowing for discriminated unions is constant-time (no inference cost).
- `ts-pattern` library is mature in 2026 and removes most exhaustiveness boilerplate.
- React 19's `use()` hook and `Suspense` reduce the need for explicit async unions in many cases — but reducers and forms still benefit.

### Modern Implementation (Code)

```ts
// With ts-pattern (2026 idiomatic)
import { match } from 'ts-pattern';

const view = match(state)
  .with({ kind: 'idle' }, () => <Idle />)
  .with({ kind: 'loading' }, () => <Spinner />)
  .with({ kind: 'success' }, ({ data }) => <Profile user={data} />)
  .with({ kind: 'error' }, ({ error }) => <Err msg={error.message} />)
  .exhaustive(); // throws / errors if a case is missing
```

```ts
// Zod-driven
import { z } from 'zod';

const Event = z.discriminatedUnion('type', [
  z.object({ type: z.literal('click'), x: z.number(), y: z.number() }),
  z.object({ type: z.literal('submit'), formId: z.string() }),
  z.object({ type: z.literal('error'), message: z.string() }),
]);
type Event = z.infer<typeof Event>;
```

### Comparison

| Approach | Bugs caught at compile time? |
|---|---|
| Multiple booleans | Few |
| Object with optional fields | Some |
| Discriminated union | Most |
| Discriminated union + `never` exhaustiveness | All |

### Production Usage
- Async screens model state as `{ kind: 'idle' | 'loading' | 'success' | 'error' }`.
- Redux/RTK action types are discriminated.
- Domain events serialized for analytics keep their discriminant.

### Hands-On Exercise
1. Refactor a boolean-heavy component (`isLoading`, `isError`, `data`) into a discriminated union. Notice how many `if` branches collapse.
2. Add a new state. Watch the compiler walk you through every switch.
3. Wire `ts-pattern` and remove the manual `never` assertions.

### Common Mistakes
- Forgetting the `default: never` branch (silent gap).
- Discriminant field types not literal (`type: string` defeats narrowing).
- Mixing discriminated and undiscriminated members in one union.

### Production Red Flags
- `if (loading) ... if (data) ... if (error) ...` chains.
- Switch without exhaustiveness guard.
- `as any` cast inside a switch case.

### Performance & Metrics
N/A at runtime — pure type-level safety.

### Decision Framework
- 2+ booleans that correlate → discriminated union.
- Domain has named events → discriminated union per event.
- Reducer or finite state machine → discriminated union always.

### Senior-Level Insight
The single biggest leap in code quality I see when teams adopt TS deeply is moving from booleans to unions. The bug rate in async screens drops noticeably; refactors stop being scary.

### Real-World Scenario
**Symptom:** A "no data" empty state showed alongside an error toast — impossible state in design.
**Investigation:** State was `{ data, error, loading }` triple; both `data` and `error` could be set after a refetch failure.
**Fix:** Discriminated union; compiler refused old code that assumed independence.

### Production Failure Story
**Incident:** Form sometimes submitted twice.
**Root cause:** `isSubmitting` was a boolean; "submit success" briefly overlapped with "ready to submit again."
**Fix:** Discriminated state machine with explicit transitions.

### Debugging Checklist
1. Is the discriminant a string literal type?
2. Is there a `never` exhaustiveness check (or `.exhaustive()` from ts-pattern)?
3. Are there impossible boolean combinations in current code?
4. Can a switch be replaced with a typed map?

### Advanced / Internal Knowledge
- Discriminated unions narrow correctly through `in` operator: `if ('data' in s) ...`.
- Zod's `discriminatedUnion` is faster than plain `z.union` because it short-circuits on tag.
- `ts-pattern`'s `.exhaustive()` is implemented via the `never` trick under the hood.

### 2026 AI Tip
AI defaults to boolean async state. After accepting, refactor to a discriminated union if the screen has > 2 states.

### Related Topics
Q4, Q7, S08 (state).

### Interview Follow-Up Questions
- "Why use a discriminated union over multiple booleans?"
- "How do you enforce exhaustiveness?"
- "What's wrong with `type State = { isLoading: boolean; data?: T; error?: Error }`?"

### Memory Hook
**"One tag to narrow, `never` to enforce."**

### Revision Notes
> Discriminated unions = one-of-N shapes with a literal tag; switch narrows by tag; `default: never` enforces exhaustiveness; replaces boolean state explosions; pairs with ts-pattern and Zod.

---

## Q6. `satisfies` vs type assertion vs annotation

### Difficulty
Intermediate

### Interview Frequency
Common at senior rounds (modern TS).

### Prerequisites
Basic TS typing.

### TL;DR
**Annotation** widens to the declared type. **Assertion (`as`)** lies to the compiler. **`satisfies`** validates the value matches a type **without widening** — keep the literal type, gain the constraint.

### 30-Second Interview Answer
"`satisfies` checks that a value conforms to a type, but **preserves the value's specific type**. Annotation widens, losing literals; `as` is an unchecked cast. I use `satisfies` for config objects, route maps, and tagged tuples where I want both the safety of the constraint and the precision of the literal."

### 2-Minute Practical Answer
```ts
type Color = 'red' | 'green' | 'blue';

// Annotation: widens to Record<string, Color>; loses specific keys.
const colors1: Record<string, Color> = {
  primary: 'red',
  secondary: 'green',
};
colors1.primary; // type Color — but you've lost that 'primary' is a known key.

// Assertion: lies; no check.
const colors2 = {
  primary: 'red',
  secondary: 'banana', // no error!
} as Record<string, Color>;

// satisfies: checks shape, preserves literal types.
const colors3 = {
  primary: 'red',
  secondary: 'green',
} satisfies Record<string, Color>;
colors3.primary; // type 'red' (the literal) — full precision retained
```

When to use each:
- **Annotation** — public APIs / function signatures (you want the broad type).
- **Assertion** — only when you genuinely know more than the compiler (parsing untrusted JSON, DOM types). Pair with runtime check.
- **`satisfies`** — config objects, route tables, theme tokens, anywhere you want literal precision + a guarantee.

### 5-Minute Architecture Answer
TS 4.9 introduced `satisfies` to fix a long-standing problem: there was no way to **constrain** a value against a type without **widening** it. Before `satisfies`, you either:
- Annotated (widened, lost literals).
- Cast (no safety).
- Did neither (ad-hoc constraint via separate test).

`satisfies` separates **validation** from **inference**. The expression is:
```ts
expr satisfies T  // expr must be assignable to T; type of the whole = type of expr (not T)
```

This unlocks patterns:
- **Theme tokens** — define a deeply nested theme; assert it satisfies a `Theme` interface; consumers get full literal types for autocomplete.
- **Routes** — define a route table; satisfies `Routes`; `keyof typeof routes` gives literal route names.
- **Action creators** — satisfies `ActionCreators<State>`; preserves return type literals.
- **Const config** — satisfies `Config`; preserves nested literal precision.

The inverse pitfall: don't use `satisfies` on function signatures (you usually want widening for callers). Use annotation there.

### The "Why"
- TS literal precision is valuable (better narrowing, better autocomplete, better refactoring).
- Pre-`satisfies`, the cost of safety was losing precision; `satisfies` removed the tradeoff.

### Mental Model
- Annotation = "this is a Color." (Loses literal.)
- Assertion = "trust me, this is a Color." (No check.)
- `satisfies` = "check that this is a Color, but remember the exact value." (Best of both.)

### Internal Working (2026 Context)
- Implemented in TS 4.9; widely supported in editors.
- Works alongside `const` assertions: `const x = { a: 1 } as const satisfies Config`.
- TS 5.x added `const` type parameters which complement `satisfies` for generic functions.

### Modern Implementation (Code)

```ts
// Theme tokens
type Theme = {
  colors: Record<string, string>;
  spacing: Record<string, number>;
};

const theme = {
  colors: { primary: '#3b82f6', success: '#10b981', danger: '#ef4444' },
  spacing: { sm: 4, md: 8, lg: 16 },
} satisfies Theme;

// theme.colors.primary has type '#3b82f6' (literal), still autocompletes
type ColorKey = keyof typeof theme.colors; // 'primary' | 'success' | 'danger'

// Routes
const routes = {
  home: '/',
  profile: '/users/:id',
  settings: '/settings',
} satisfies Record<string, string>;

type RouteName = keyof typeof routes; // 'home' | 'profile' | 'settings'
```

### Comparison

| Form | Validates? | Preserves literals? | Use when |
|---|---|---|---|
| `const x: T = ...` | Yes | No (widens) | Public signatures |
| `const x = ... as T` | No (cast) | Cast to T | After runtime check |
| `const x = ... satisfies T` | Yes | Yes | Configs, tables, themes |

### Production Usage
- Theme files in design systems use `satisfies`.
- Route tables in Expo Router 2026 commonly use `satisfies`.
- Analytics event maps: `satisfies Record<string, Schema>`.

### Hands-On Exercise
1. Find an annotation that widens (`Record<string, X>`). Replace with `satisfies`. Notice better autocomplete on keys.
2. Find an `as` cast that lies. Replace with proper validation (Zod) + `satisfies`.

### Common Mistakes
- Using `as` when `satisfies` would catch the bug.
- Using `satisfies` on function signatures (use annotation).
- Forgetting `as const` when you want all string values to be literals: `{ a: 'x' } as const satisfies T`.

### Production Red Flags
- `as` casts in domain code.
- Theme/config files with annotation that widens to `Record<string, ...>`.

### Performance & Metrics
N/A — compile time only.

### Decision Framework
- Public API signature → annotation.
- Trusted external value (JSON) → assertion + runtime guard.
- Config / table / theme → `satisfies`.

### Senior-Level Insight
The shift from `as` to `satisfies` in a codebase usually surfaces real bugs (silent typos in theme keys, wrong route paths). It's a fast cleanup with high ROI.

### Real-World Scenario
Theme file widened with annotation; designer renamed `primary` to `brand`; consumers using `theme.colors.primary` got runtime `undefined` because `Record<string, string>` accepts any key. `satisfies` would have caught it; missing-key access becomes a compile error.

### Production Failure Story
**Incident:** Route table had a typo (`/setings` instead of `/settings`); only one place used it.
**Root cause:** `as Record<string, string>` cast hid the typo.
**Fix:** Replace with `satisfies`; add a `Routes` type with literal keys.

### Debugging Checklist
1. Search for `as Record<` and `as Partial<` — likely candidates for `satisfies`.
2. Search for theme/config files using annotations.
3. Are public function signatures using annotations (not satisfies)?

### Advanced / Internal Knowledge
- `satisfies` does not narrow at runtime — it's compile-only.
- Combine with `as const` for deeply literal config: `{...} as const satisfies T`.
- Works with generics: `function make<const T>(x: T): T satisfies Spec` patterns.

### 2026 AI Tip
AI still defaults to annotation or `as`. Manually convert config objects to `satisfies` for better autocomplete and safety.

### Related Topics
Q4, Q5, Q7.

### Interview Follow-Up Questions
- "Why does `satisfies` preserve literal types?"
- "When would you use `as` over `satisfies`?"
- "Show an example where annotation hides a bug that `satisfies` would catch."

### Memory Hook
**"Annotate widens. Assert lies. Satisfies validates without widening."**

### Revision Notes
> `satisfies` checks a value against a type without widening; perfect for configs, themes, route tables; preserves literals for autocomplete and safer refactors; pairs with `as const`.

---

## Q7. Zod for runtime validation at boundaries (API + storage)

### Difficulty
Intermediate

### Interview Frequency
Common at mid–senior rounds.

### Prerequisites
TS basics.

### TL;DR
Zod schemas validate **untrusted data at the boundary** (network, storage, deep links) and **derive TS types** from one source. Pairs with TanStack Query and `satisfies` for end-to-end safety.

### 30-Second Interview Answer
"Zod is a TypeScript-first validation library. I define a schema once; `z.infer<typeof S>` gives me the TS type, and `S.parse(data)` validates at runtime. I put it at every boundary: API responses, deep links, MMKV reads, push payloads. It catches drift between client and server before bugs reach UI."

### 2-Minute Practical Answer
```ts
import { z } from 'zod';

const User = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  createdAt: z.coerce.date(),
  role: z.enum(['admin', 'user']),
  settings: z.object({
    notifications: z.boolean().default(true),
  }).optional(),
});
type User = z.infer<typeof User>; // exact TS type

// At the boundary
const data = await fetch('/me').then(r => r.json());
const user = User.parse(data); // throws ZodError if invalid
// user is fully typed and validated
```

Where to use Zod:
- **Network boundary** — every API response.
- **Storage boundary** — MMKV / SQLite reads (data may be from old app version).
- **Deep links** — params from URL strings.
- **Push notifications** — payload schema.
- **Native module returns** — bridge values are `unknown` in spirit.
- **Forms** — react-hook-form integrates via `zodResolver`.

### 5-Minute Architecture Answer
The "TS lies at the boundary" problem: TypeScript types are erased at runtime. A `User` typed as `User` from `fetch().then(r => r.json() as User)` is a **promise**, not a guarantee. A backend deploy that renames `email` to `emailAddress` ships a runtime crash with no compile-time warning.

Zod fixes this by making types **derived from runtime checks**:
- One schema → TS type + validator.
- Drift is caught at the first parse, not at field access deep in the tree.
- Errors are structured (path + message), enabling great error messages.

Architectural patterns:
1. **Boundary layer** — every fetch/storage op goes through a schema-validated wrapper. UI code never sees `unknown`.
2. **Discriminated unions** — `z.discriminatedUnion('type', [...])` for typed events.
3. **Branded types** — `z.string().uuid().brand<'UserId'>()` for compile-time distinction.
4. **Default + transform** — Zod fills missing fields, coerces types (Date, number).
5. **Async validation** — `z.string().refine(async (v) => ...)` for server-side checks.

Costs:
- Bundle size — Zod adds ~12KB gzipped; usually fine.
- Runtime cost — small per-parse cost; negligible at API boundaries, measurable in tight loops.
- Dual maintenance with backend types — solve via codegen (e.g., from OpenAPI to Zod) when possible.

### The "Why"
- Backends drift; clients break silently.
- Storage migrations bring stale shapes into new code.
- Mobile clients run for years on old data; defensive validation is cheap insurance.

### Mental Model
TS = compile-time wishful thinking. Zod = runtime contract. Use both: TS for happy path, Zod at boundaries.

### Internal Working (2026 Context)
- Zod 3.x is mature; Zod 4 in beta in 2026 with smaller bundle, faster parser.
- `zod-to-ts` and `openapi-zod-client` generate Zod from OpenAPI specs.
- TanStack Query has `select` to apply schemas inline.
- React Hook Form's `zodResolver` is standard for forms.

### Modern Implementation (Code)

```ts
// API client wrapped with Zod
import { z } from 'zod';

const Post = z.object({
  id: z.string(),
  title: z.string(),
  body: z.string(),
  authorId: z.string(),
  publishedAt: z.coerce.date(),
});
type Post = z.infer<typeof Post>;

const PostsResponse = z.object({
  posts: z.array(Post),
  total: z.number().int().nonnegative(),
  cursor: z.string().nullable(),
});

async function fetchPosts(cursor?: string) {
  const res = await fetch(`/api/posts?cursor=${cursor ?? ''}`);
  if (!res.ok) throw new HTTPError(res.status);
  const json = await res.json();
  return PostsResponse.parse(json); // throws on drift
}

// MMKV with schema
const SettingsSchema = z.object({
  theme: z.enum(['light', 'dark', 'auto']).default('auto'),
  notifications: z.boolean().default(true),
  lastSync: z.coerce.date().optional(),
});

function loadSettings(): z.infer<typeof SettingsSchema> {
  const raw = mmkv.getString('settings');
  if (!raw) return SettingsSchema.parse({});
  try {
    return SettingsSchema.parse(JSON.parse(raw));
  } catch {
    // migration / corruption fallback
    return SettingsSchema.parse({});
  }
}

// Discriminated union event
const Event = z.discriminatedUnion('type', [
  z.object({ type: z.literal('login'), userId: z.string() }),
  z.object({ type: z.literal('purchase'), itemId: z.string(), amount: z.number() }),
]);
```

### Comparison

| Tool | Strength | Weakness |
|---|---|---|
| Zod | TS-first, derives types | Bundle ~12KB |
| Yup | Older, mature | Worse TS integration |
| io-ts | fp-ts ecosystem | Steeper learning curve |
| Valibot | Tiny (1KB) | Smaller ecosystem |
| Hand-written guards | No deps | Drift-prone, lots of code |

### Production Usage
- Wrap every fetch / storage read with a schema.
- Cache the validated result, not the raw response.
- Log Zod errors to Sentry with the path — fastest way to detect API drift.

### Hands-On Exercise
1. Pick an API endpoint. Write a Zod schema for its response. Wrap fetch calls.
2. Deploy a "broken" version (rename a field). Confirm Zod throws with a useful path.
3. Add a default + migration to handle the old shape gracefully.

### Common Mistakes
- Validating only at the network boundary, not at storage.
- Catching ZodError too broadly; mask real bugs.
- Schemas in hot loops without caching.
- `z.any()` everywhere — defeats the purpose.

### Production Red Flags
- Untyped `JSON.parse` results flowing into UI.
- `as User` casts after fetch.
- No Sentry alerts on schema parse failures.

### Performance & Metrics
- Parse time per response (P50/P99).
- Schema-failure rate to Sentry — should be near zero in steady state.
- Bundle size delta from Zod (~12KB gzipped).

### Decision Framework
- Untrusted data crossing a boundary → Zod schema.
- Hot path (parse 10k records per render) → consider Valibot or hand-rolled guard.
- Tightly coupled to backend → codegen Zod from OpenAPI.

### Senior-Level Insight
"The fastest way to find a server bug is to alert on the client's schema failures." Zod errors hitting Sentry surface backend regressions hours before users notice.

### Real-World Scenario
**Symptom:** A new feature crashes on profile load — but only for some users.
**Investigation:** Sentry shows `ZodError: invalid_type at path 'createdAt' expected date received null`.
**Root cause:** Backend returned `null` for very old accounts.
**Fix:** Schema accepts `z.coerce.date().nullable()`; default fallback in UI.

### Production Failure Story
**Incident:** App started showing garbled text for 5% of users after a backend deploy.
**Investigation:** No client errors; data flowed through `as` casts.
**Root cause:** Backend returned new field `displayName`; old field `username` removed.
**Fix:** Wrap responses in Zod; add CI integration test that runs schemas against staging API.
**Prevention:** Codegen Zod schemas from OpenAPI; CI fails on drift.

### Debugging Checklist
1. Are all API responses parsed by Zod?
2. Is storage read parsed too?
3. Are Zod errors logged to Sentry with paths?
4. Are schemas single-source-of-truth (`z.infer` for TS types)?

### Advanced / Internal Knowledge
- `z.brand<'X'>()` creates nominal types preventing accidental cross-use of IDs.
- `z.preprocess` runs a transform before validation (great for legacy date strings).
- `z.lazy` enables recursive schemas (trees, comments).

### 2026 AI Tip
AI is excellent at generating Zod schemas from sample JSON. Provide a real response, ask for a schema, then refine literals/enums.

### Related Topics
Q4, Q5, Q6, S09 (networking), S11 (offline-first storage migrations).

### Interview Follow-Up Questions
- "Why validate at runtime when you have TS?"
- "How do you handle schema drift across deploys?"
- "Show how you'd type a discriminated union of events with Zod."

### Memory Hook
**"TS at compile, Zod at the boundary."**

### Revision Notes
> Zod = runtime validation + derived TS types; use at every boundary (network, storage, deep links, push); discriminated unions narrow naturally; log parse failures to Sentry to detect drift.

---

> Cross-refs: `docs/02-javascript-core.md`, `docs/03-typescript.md`, S04 (RuntimeScheduler), S07 (perf), S08 (state), S09 (networking), S11 (offline storage).
