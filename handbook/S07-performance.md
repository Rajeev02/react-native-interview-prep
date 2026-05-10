# S7 — Performance Optimization

> Cold start · TTI · 60/120fps · list virtualization · animations · image optimization · app size

## Topics

- [Q1. Cold/warm/hot start and TTI](#q1-coldwarmhot-start-and-tti)
- [Q2. The three threads and where work happens](#q2-the-three-threads-and-where-work-happens)
- [Q3. List performance: FlashList, virtualization, recycling](#q3-list-performance-flashlist-virtualization-recycling)
- [Q4. Animations at 60/120fps with Reanimated](#q4-animations-at-60120fps-with-reanimated)
- [Q5. Image performance and modern formats](#q5-image-performance-and-modern-formats)
- [Q6. App size optimization](#q6-app-size-optimization)

---

## Q1. Cold/warm/hot start and TTI

### Difficulty
Intermediate → Advanced

### Interview Frequency
Very Common.

### Prerequisites
RN startup pipeline, Hermes basics.

### TL;DR
**Cold** = process not in memory; **warm** = process killed but cached; **hot** = process backgrounded. TTI = time-to-interactive, the moment the user can act. Optimize cold first because it's the worst and most visible.

### 30-Second Interview Answer
"Cold start is launching the app from a fully terminated state — process spawn, native init, JS engine init, JS bundle load + execute, first React render, mount, and ready to interact. TTI is when the user can do something useful. Warm start skips process spawn; hot start just resumes. Optimization targets in order: native init (lazy TurboModules, defer SDK init), JS load (Hermes bytecode), JS execute (inline requires, avoid heavy top-level work), first render (reduce work, avoid sync queries), mount (use Suspense to defer below-the-fold)."

### 2-Minute Practical Answer
The cold-start budget on Pixel 4a class devices is ~2 seconds before users notice. Breakdown:
1. **Native init** (~400ms) — process spawn, libraries linked, RN runtime constructed.
2. **JS engine init** (~100ms with Hermes) — runtime, JSI bridges.
3. **Bundle load** (~150–400ms) — bytecode mmap'd; size matters.
4. **JS execute** (~200–600ms) — module top-level eval; inline requires + barrel removal cuts this.
5. **First render** (~100–300ms) — React reconciles initial tree.
6. **First commit/mount on UI thread** (~50–100ms) — Fabric atomic mount.
7. **Async ready** — fonts, images, first network response.

Tools:
- `react-native-startup-time` for end-to-end measurement.
- Android `am start -W` reports system-level cold start.
- iOS `os_signpost` + Instruments.
- EAS Build performance reports + Expo's built-in startup tracker.

### 5-Minute Architecture Answer
The senior framing: **TTI is not one number, it's a budget per stage.** Improvements compound:
- Hermes bytecode skips parse (-150ms vs JSC).
- Bridgeless skips bridge construction (-50–100ms).
- TurboModule lazy init skips eager native module setup (-50–200ms).
- Inline requires defer module evaluation (-100–500ms).
- Splash → first screen skeleton via Suspense (-perceived 200–500ms).

Anti-patterns that secretly cost startup:
- SDK init at top of `App.tsx` (analytics, feature flags, push).
- Synchronous MMKV/SQLite reads on first render.
- Large theme/i18n JSON parsed at boot.
- Eager screen registration (react-navigation `screens` array referencing every screen file).

### The "Why"
- App store conversions, retention, and crash-free rates all correlate with startup.
- Slow cold start is the #1 user complaint after crashes.

### Mental Model
Cold start = an **assembly line**. Each station has a budget. One slow station throttles the whole line.

### Internal Working (2026 Context)
- New Arch (Bridgeless + TurboModules) cuts ~200ms on average.
- Hermes bytecode load is mmap'd (effectively free I/O on warm cache).
- Static Hermes (Q2 of S6) will further reduce execute cost.

### Modern Implementation (Code)
Defer heavy SDK init:
```tsx
// app/_layout.tsx (Expo Router)
import { useEffect } from 'react';

export default function RootLayout() {
  useEffect(() => {
    // Run AFTER first paint, off the critical path
    requestAnimationFrame(() => {
      void initAnalytics();
      void initFeatureFlags();
      void initPushPermissions();
    });
  }, []);
  return <Slot />;
}
```

Splash control (avoid hiding splash before TTI):
```tsx
import * as SplashScreen from 'expo-splash-screen';
SplashScreen.preventAutoHideAsync();
// after first screen renders + critical data ready:
useEffect(() => { SplashScreen.hideAsync(); }, [ready]);
```

### Comparison

| Phase                   | Cold      | Warm     | Hot      |
| ----------------------- | --------- | -------- | -------- |
| Process spawn           | ✓         |          |          |
| Native init             | ✓         |          |          |
| JS engine init          | ✓         | ✓        |          |
| Bundle load + execute   | ✓         |          |          |
| First render            | ✓         | ✓        |          |
| Resume from background  |           |          | ✓        |

### Production Usage
- Track P50/P75/P95 TTI per device class.
- Set per-release budgets; CI alarms on regressions >100ms.

### Hands-On Exercise
1. Measure baseline cold start; record per-stage timings.
2. Defer one SDK init; remeasure.
3. Convert one route to lazy load; remeasure.

### Common Mistakes
- Optimizing JS while native init dominates — measure before fixing.
- Hiding the splash screen before content is ready (perceived flash).
- Treating warm starts as cold (different optimization techniques).

### Production Red Flags
- TTI > 3s on mid-tier Android.
- Cold start regression on every release without rollback gate.
- Splash hide before fonts/icons ready.

### Performance & Metrics
- Target: cold TTI <1.5s on Pixel 6, <2.5s on Pixel 4a.
- Warm TTI: <800ms.
- Frame budget: 16.6ms (60fps), 8.3ms (120fps).

### Metrics That Matter
TTI P50/P95, per-stage timings, splash hide → first interaction.

### Decision Framework
- Always profile before optimizing.
- Start with the biggest stage.
- Defer non-critical work past first paint.
- Measure on real low-end devices, not simulators.

### Senior-Level Insight
The trap is local optimization. Saving 50ms in JS load while leaving an SDK that takes 800ms in `App.tsx` is worse than nothing — you've added complexity without moving the metric. Always carry per-stage timings into reviews.

### Real-World Scenario
**Symptom:** TTI regressed 400ms after a sprint.
**Investigation:** Per-stage trace shows native init ballooned.
**Root cause:** New SDK initialized synchronously in `Application.onCreate()`.
**Fix:** Move to deferred init via WorkManager.
**Lesson:** Native-side SDK init is invisible from JS profiling.

### Production Failure Story
**Incident:** Splash flickered then re-appeared on launch.
**Investigation:** App hid splash too early; first render suspended waiting on i18n.
**Root cause:** Race between SplashScreen.hide and React render.
**Fix:** Hide splash inside the route's `useEffect` after data ready.
**Prevention:** Splash hide ONLY after first interactive frame.

### Debugging Checklist
1. Per-stage trace exists?
2. Native init under 400ms?
3. Bundle size under target?
4. Top-level imports audited?
5. Splash hidden post-TTI?

### Advanced / Internal Knowledge
- Bridgeless cuts native init bursts visible in `am start -W`.
- Hermes bytecode is memory-mapped; large bundles hurt only on first cold cache.
- iOS Pre-Warming (since iOS 15) makes cold starts measured by users different from your tests.

### 2026 AI Tip
Ask AI to identify "top-of-file work" in your `App.tsx` — it can audit imports for side-effect risks.

### Related Topics
S6 (Hermes/Metro), S4 (Bridgeless), Q2 (threads), Q6 (app size).

### Interview Follow-Up Questions
- "Walk me through cold start phases."
- "What's the difference between cold/warm/hot?"
- "How do you measure TTI?"
- "Where would you defer work?"

### Memory Hook
**"Process → native → engine → bundle → execute → render → mount. Defer the optional, profile before tuning."**

### Revision Notes
> Cold = full launch; warm = cached process; hot = resume; TTI per-stage budget; defer SDK init, use Hermes + Bridgeless + inline requires + Suspense; measure on real low-end Android.

---

## Q2. The three threads and where work happens

### Difficulty
Intermediate → Advanced

### Interview Frequency
Very Common.

### Prerequisites
RN architecture basics, JSI.

### TL;DR
RN runs on three primary threads: **JS** (your code), **UI** (native rendering, gestures), **Shadow / Layout** (Yoga layout). Knowing what runs where is the key to fixing jank.

### 30-Second Interview Answer
"RN's main threads are JS (your React code, business logic), UI (native rendering, animation drivers, touch handling), and Shadow/Layout (Yoga calculates layout, runs background in legacy or as part of Fabric in New Arch). Jank comes from blocking the UI thread or from JS taking longer than a frame to react to gestures. Fix it by moving work — animations to UI thread via Reanimated worklets, layout via Fabric, heavy compute via TurboModules or worklets."

### 2-Minute Practical Answer
| Thread | Job | Block it = |
| --- | --- | --- |
| JS | React render, your app logic | Slow gesture response, dropped JS-driven animations |
| UI (Main) | Native view updates, gestures, native animation | Frame drops, frozen UI |
| Shadow (legacy) / Fabric (new) | Yoga layout | Layout lag |
| Native modules' own threads | TurboModule work, image decode, etc. | Their queue backs up |

Reanimated 3/4 worklets execute on a **separate JS runtime that runs on the UI thread**, letting animations run independently of your main JS thread. This is why a slow JS thread doesn't drop a Reanimated animation.

### 5-Minute Architecture Answer
Pre-New Arch:
- JS ↔ Bridge (async, batched) ↔ Shadow ↔ UI.
- Bridge serialization was the single biggest bottleneck.

New Arch:
- JS ↔ JSI (sync) ↔ C++ ↔ Fabric (UI-thread mount).
- Reanimated worklet runtime piggybacks on the UI thread for gesture-driven animations.
- TurboModules can run on their own threads but expose JSI to JS.

Key principle: **the rendering pipeline is only as fast as the slowest thread.** Frame budget is 16.6ms (60Hz) or 8.3ms (120Hz). Each thread must complete its slice within that window.

### The "Why"
- Mobile is multi-threaded by necessity (gestures must respond instantly, even when JS is busy).
- Understanding thread boundaries diagnoses 90% of perf bugs.

### Mental Model
Three lanes on a highway. JS lane, UI lane, layout lane. Anything in your JS lane that takes >16ms causes pile-ups; the UI lane keeps moving thanks to native gesture handlers and Reanimated.

### Internal Working (2026 Context)
- Bridgeless mode: JS↔native is synchronous over JSI; no message queue lag.
- Fabric: shadow tree built in C++ in the New Arch, committed atomically to UI thread.
- Reanimated 4 (rewritten on Fabric): true UI-thread layout sync with React state.

### Modern Implementation (Code)
Run gesture-driven animation entirely on UI thread:
```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle } from 'react-native-reanimated';

function Draggable() {
  const x = useSharedValue(0);
  const pan = Gesture.Pan().onUpdate((e) => {
    'worklet';
    x.value = e.translationX; // runs on UI thread
  });
  const style = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));
  return (
    <GestureDetector gesture={pan}>
      <Animated.View style={[styles.box, style]} />
    </GestureDetector>
  );
}
```

Move heavy compute off JS thread via TurboModule:
```ts
// JS-side
const result = NativeImageHash.computeHash(uri); // JSI sync, fast on native
```

### Comparison

| Work type            | Best thread             | Tool                       |
| -------------------- | ----------------------- | -------------------------- |
| Gesture animation    | UI                      | Reanimated worklets        |
| List rendering       | JS                      | FlashList                  |
| Layout               | Fabric/Shadow           | Yoga                       |
| Image decode         | Native bg               | expo-image / Fast Image    |
| Heavy compute        | Native TurboModule      | Custom TurboModule         |
| Network              | Native                  | Fetch / RNFetchBlob        |

### Production Usage
- Move animations to Reanimated worklets when JS thread is contended.
- Wrap compute-heavy ops in TurboModules.
- Profile with `react-native-performance` or DevTools Profiler.

### Hands-On Exercise
1. Build a list with a parallel JS-busy animation; observe drops.
2. Convert the animation to Reanimated worklets; observe smooth 60fps.
3. Add a heavy JSON parse during the animation; confirm worklets unaffected.

### Common Mistakes
- Animating with `setState` in `Animated.event` — runs on JS thread, drops frames.
- Doing image decode on JS via `Image.getSize` in render.
- Chaining many sync TurboModule calls in render (each is fast, but together they add up).

### Production Red Flags
- `setInterval` driving animations.
- Long sync `for` loops in render handlers.
- `console.log` in production hot paths (still costs JS time even silenced).

### Performance & Metrics
- Frame budget breach P95.
- JS thread CPU %.
- Worklet runtime CPU.

### Metrics That Matter
Frame drops, frozen frames, JS thread idle %, worklet CPU.

### Decision Framework
- Animation tied to gesture → worklet, UI thread.
- Compute >5ms → TurboModule.
- Layout-heavy → trust Fabric, avoid manual measurement.

### Senior-Level Insight
RN's threading model is a strict productivity multiplier: putting work on the right thread is usually a 10× win vs micro-optimizing on the wrong one. Always ask "which thread does this run on?" before optimizing.

### Real-World Scenario
**Symptom:** Carousel jank during a list refresh.
**Investigation:** Carousel animation used JS-driven `Animated.timing` with native driver disabled.
**Root cause:** Animation competed for JS thread time.
**Fix:** Migrate to Reanimated worklets.
**Lesson:** Native driver / worklets aren't optional for production animations.

### Production Failure Story
**Incident:** Camera screen FPS dropped on flagship Android during photo upload.
**Investigation:** Upload progress used `setState` per chunk on JS thread.
**Root cause:** State updates flooded JS thread, contending with camera gestures.
**Fix:** Throttle progress updates to 4Hz; offload upload to a TurboModule.
**Prevention:** Code review checklist for `setState` in tight loops.

### Debugging Checklist
1. DevTools → JS thread CPU profile.
2. Perfetto / Instruments → UI thread budget.
3. Are animations using worklets?
4. Are heavy ops in JS or in modules?

### Advanced / Internal Knowledge
- Reanimated worklet runtime is its own JSI runtime; data is shared via SharedValues.
- Fabric mount commits happen on the UI thread atomically; no interleaving with gestures.
- Bridgeless mode allows direct UI-thread → JS calls when needed (rare; controlled).

### 2026 AI Tip
AI often suggests `Animated.timing` (legacy). Re-prompt for Reanimated 3/4 worklets explicitly.

### Related Topics
Q4 (animations), S4 (New Arch), S8 (native modules).

### Interview Follow-Up Questions
- "What runs on the UI thread vs JS thread?"
- "How do worklets escape JS thread contention?"
- "What changed in threading with Bridgeless?"
- "How do you debug a frame drop?"

### Memory Hook
**"JS = logic. UI = pixels & gestures. Layout = math. Worklets cross over. Wrong thread = jank."**

### Revision Notes
> Three threads (JS, UI, Shadow/Fabric); Reanimated worklets run on UI; heavy work goes to TurboModules; always identify the thread before optimizing.

---

## Q3. List performance: FlashList, virtualization, recycling

### Difficulty
Advanced

### Interview Frequency
Very Common — one of the most asked topics.

### Prerequisites
React rendering, RN list components.

### TL;DR
**FlashList** (Shopify) recycles cells like native; **FlatList** is fine for small lists; **ScrollView** is for dozens of items max. For 2026, FlashList is the default for any list over ~30 items.

### 30-Second Interview Answer
"FlatList virtualizes (mounts/unmounts off-screen) but creates new component instances on each render. FlashList recycles existing native views — the biggest win on long lists. Pick FlashList for anything large. Tune with stable `keyExtractor`, accurate `estimatedItemSize`, type tagging via `getItemType`, and avoid heavy work in `renderItem`. Move expensive cells to memoized components or rely on the React Compiler."

### 2-Minute Practical Answer
FlashList recipe:
```tsx
<FlashList
  data={items}
  keyExtractor={(it) => it.id}
  estimatedItemSize={88}
  getItemType={(it) => it.kind}        // helps recycling pools
  renderItem={({ item }) => <Row item={item} />}
  drawDistance={250}
/>
```

Rules:
- `keyExtractor` must be stable + unique.
- `estimatedItemSize` should match the average row height — bad estimate = jank during fast scroll.
- `getItemType` enables type-specific recycling pools; critical for heterogenous lists (header + cards + ads).
- `renderItem` should be pure and fast; no heavy work, no fetches, no animations created per render.
- Use stable images (Q5).

### 5-Minute Architecture Answer
Why FlashList exists:
- FlatList unmounts off-screen items, then mounts new components when they re-enter; React reconciliation cost adds up on long lists.
- Native lists (RecyclerView / UITableView) recycle views — same view object reused with new data.
- FlashList ports recycling to RN: a fixed pool of cell instances; data updates them in place.

Tradeoffs:
- Recycling means stale state — your row component must be **idempotent on prop change** (no in-cell `useState` that survives recycle without reset).
- `getItemType` partitions pools; heterogenous lists without it cause type churn.
- `estimatedItemSize` errors translate to scroll jitter.

In 2026:
- React Compiler stabilizes `renderItem` automatically when deps are clean.
- Reanimated 4 + Fabric makes scroll-coordinated animations smoother.
- FlashList v2 supports masonry, sticky headers, and real-world heterogeneity.

### The "Why"
- Lists are everywhere (feeds, settings, search results) and scroll perf is what users feel.
- Bad lists drop frames in the most obvious place — under the user's thumb.

### Mental Model
FlashList is RN's `RecyclerView`. Cells are **slots**, not new instances. Stale state in a slot = bug.

### Internal Working (2026 Context)
- Pool of cell wrappers; `renderItem` re-runs into the wrapper on data change.
- Layout sized per `estimatedItemSize`, corrected by measure on first render.
- Type pools: each `getItemType` value gets its own recycling bucket.

### Modern Implementation (Code)
```tsx
type Item =
  | { kind: 'post'; id: string; title: string }
  | { kind: 'ad';   id: string; copy: string };

function Row({ item }: { item: Item }) {
  return item.kind === 'post' ? <Post post={item} /> : <Ad ad={item} />;
}

export function Feed({ items }: { items: Item[] }) {
  return (
    <FlashList
      data={items}
      keyExtractor={(it) => it.id}
      estimatedItemSize={120}
      getItemType={(it) => it.kind}
      renderItem={({ item }) => <Row item={item} />}
      drawDistance={300}
    />
  );
}
```

Avoid in-cell local state for derived UI; lift to selector or memoize.

### Comparison

| Component  | When                                 |
| ---------- | ------------------------------------ |
| ScrollView | Dozens of items max                  |
| FlatList   | <500 items, light cells              |
| FlashList  | Anything big, heterogenous, hot path |
| SectionList| Section UX needed (with care)        |

### Production Usage
- Default to FlashList in new code.
- Migrate hot lists from FlatList.
- Pair with `expo-image` for images.

### Hands-On Exercise
1. Build a 5,000-row FlatList with mixed cell heights; measure JS thread spikes during scroll.
2. Switch to FlashList; configure `getItemType`; measure again.
3. Inject random heights with bad `estimatedItemSize`; observe jitter; correct.

### Common Mistakes
- Wrong `estimatedItemSize` → visible jitter on fast scroll.
- Inline `renderItem` defining new components every render (compiler helps but barrels still hurt).
- Local `useState` in cells expecting persistence.

### Production Red Flags
- FlatList with >1000 items.
- Inline images without caching.
- Heavy `renderItem` (network calls, large `Date` formatting per row).

### Performance & Metrics
- Scroll JS thread CPU.
- Frame drops during scroll.
- Cell recycle rate (FlashList exposes via dev menu).

### Metrics That Matter
Scroll P95 frame time, JS thread idle during scroll, image cache hit rate.

### Decision Framework
- Long, heterogenous → FlashList + `getItemType`.
- Static, short → FlatList or ScrollView.
- Grid → FlashList masonry.
- Infinite feed → FlashList + virtualized pagination via TanStack Query.

### Senior-Level Insight
Lists are where the React Compiler pays off most: every render-cycle saved per cell × thousands of cells = a lot of CPU. Combined with FlashList's recycling, the total work shrinks an order of magnitude.

### Real-World Scenario
**Symptom:** Search results scroll stutters every ~10 rows.
**Investigation:** `getItemType` not set; recycler couldn't pool ad cells with post cells.
**Root cause:** Type churn forced re-mount on every type boundary.
**Fix:** Add `getItemType`.
**Lesson:** Heterogenous lists need type tagging.

### Production Failure Story
**Incident:** Like button state flickered wrong when scrolling fast.
**Investigation:** Cell stored its own `useState(liked)`; recycle reused stale state.
**Root cause:** State in the cell, not the data.
**Fix:** Move liked state to data + global store.
**Prevention:** Lint rule banning `useState` inside `renderItem` cells.

### Debugging Checklist
1. Is `keyExtractor` stable?
2. Is `estimatedItemSize` accurate?
3. Is `getItemType` set for heterogenous data?
4. Is `renderItem` pure?
5. Are images cached?

### Advanced / Internal Knowledge
- FlashList uses RecyclerListView under the hood with optimized recycling.
- v2 leverages Fabric for layout sync.
- `drawDistance` controls how many off-screen pixels to keep mounted.

### 2026 AI Tip
AI defaults to FlatList examples. Ask explicitly for FlashList with `getItemType`. Validate recycling assumptions.

### Related Topics
Q5 (images), Q4 (animations), S2 (Compiler), S4 (Fabric).

### Interview Follow-Up Questions
- "Why is FlashList faster than FlatList?"
- "What goes wrong with bad `estimatedItemSize`?"
- "How do you handle heterogenous lists?"
- "How does cell recycling interact with React state?"

### Memory Hook
**"FlatList virtualizes; FlashList recycles. Stable keys, accurate size, type pools, pure cells."**

### Revision Notes
> FlashList for any non-trivial list; configure `keyExtractor` + `estimatedItemSize` + `getItemType`; pure `renderItem`; never store state in recycled cells.

---

## Q4. Animations at 60/120fps with Reanimated

### Difficulty
Advanced

### Interview Frequency
Very Common.

### Prerequisites
Q2 (threads), basic animation concepts.

### TL;DR
**Reanimated 3/4** runs animations on the UI thread via a **worklet runtime**, decoupled from your JS thread. Use `useSharedValue`, `useAnimatedStyle`, gesture handlers — never touch `setState` for animation.

### 30-Second Interview Answer
"Reanimated lets you write JS code (worklets) that runs on the UI thread alongside the renderer. SharedValues hold animatable state; `useAnimatedStyle` derives styles from them on the UI thread. Combined with `react-native-gesture-handler`, gestures and animation never touch the JS thread, so a slow JS thread doesn't drop frames. Reanimated 4 (Fabric-native) extends this with true layout animations and React state sync."

### 2-Minute Practical Answer
Core APIs:
- `useSharedValue(initial)` — UI-thread mutable cell.
- `useAnimatedStyle(() => ({...}))` — derives style from shared values.
- `withTiming/withSpring/withDecay` — animation primitives.
- `runOnJS(fn)(args)` — call back into JS thread when needed.

Pattern:
```tsx
const x = useSharedValue(0);
const style = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));
function open() { x.value = withSpring(120); }
return <Animated.View style={style} />;
```

The `withSpring` runs on the UI thread; React doesn't re-render per frame.

### 5-Minute Architecture Answer
Reanimated's secret is its **second JSI runtime** running on the UI thread:
- The main React runtime drives your component lifecycle.
- The worklet runtime executes worklet functions on the UI thread.
- SharedValues are JSI hostobjects readable from both.
- Gesture handlers' callbacks (with `'worklet'` directive) run on UI thread.

Reanimated 4 changes:
- Built on Fabric's commit pipeline.
- Layout animations sync with React state changes (no flicker).
- Better React Compiler interop.

This means a 120Hz device truly hits 120fps for animations even if your JS thread is doing heavy work.

### The "Why"
- JS-thread animations (`Animated` API legacy without native driver) drop frames any time JS is busy.
- Mobile users instantly notice 1-frame stutter.
- 120Hz devices demand stricter budgets (8.3ms vs 16.6ms).

### Mental Model
Two JS engines side by side: one for app logic, one for animation. SharedValues are atomic ints/floats they both see.

### Internal Working (2026 Context)
- Worklet code is compiled by Babel plugin to be serialized into the worklet runtime.
- JSI-based shared memory between runtimes.
- Fabric integration for layout-sync animations in v4.

### Modern Implementation (Code)
Pinch-to-zoom on the UI thread:
```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';

function Zoomable({ children }: { children: React.ReactNode }) {
  const scale = useSharedValue(1);
  const start = useSharedValue(1);

  const pinch = Gesture.Pinch()
    .onStart(() => { 'worklet'; start.value = scale.value; })
    .onUpdate((e) => { 'worklet'; scale.value = start.value * e.scale; })
    .onEnd(() => { 'worklet'; scale.value = withSpring(1); });

  const style = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));

  return (
    <GestureDetector gesture={pinch}>
      <Animated.View style={style}>{children}</Animated.View>
    </GestureDetector>
  );
}
```

### Comparison

| Tool                       | Thread | Use case                           |
| -------------------------- | ------ | ---------------------------------- |
| Reanimated 3/4 worklets    | UI     | Production animations + gestures   |
| Animated API + native driver| UI    | Simple property animations         |
| Animated API (no native)   | JS     | [DEPRECATED] avoid in production   |
| LayoutAnimation            | UI     | Quick layout transitions           |
| Lottie                     | UI     | Pre-baked vector animations        |

### Production Usage
- Default for any gesture-driven animation.
- Pair with Skia for canvas-style effects on the UI thread.

### Hands-On Exercise
1. Build a draggable card with Reanimated worklets; verify frame rate during heavy JS work.
2. Add a spring-back on release; tune stiffness/damping.
3. Replace with `Animated.timing` (no native driver) and observe jank.

### Common Mistakes
- Forgetting `'worklet'` directive — function runs on JS thread.
- Mutating `.value` outside a worklet without `runOnUI` — race conditions.
- Using `useState` to drive an animation — defeats the purpose.

### Production Red Flags
- Inline `Animated.timing(...)` chains.
- `setInterval` driving an animated value.
- Reading `.value` synchronously from JS thread (sometimes works, sometimes lags).

### Performance & Metrics
- Frame drop %.
- Worklet CPU usage.
- Gesture latency.

### Metrics That Matter
Animation frame budget, gesture-to-pixel latency, jank events.

### Decision Framework
- Gesture + animation → Reanimated worklets always.
- Quick state-driven transition → LayoutAnimation acceptable.
- Pre-baked illustration → Lottie or Skia.

### Senior-Level Insight
Reanimated's design says: **the UI thread is the animation thread.** Once you accept this, JS thread perf becomes about logic, not animation. Two threads, two concerns — a major mental simplifier.

### Real-World Scenario
**Symptom:** Bottom sheet drag works at 60fps when idle, drops to 30fps during list refresh.
**Investigation:** Drag used `Animated.event` with native driver false.
**Root cause:** Animation tied to JS thread.
**Fix:** Reanimated worklet with `Gesture.Pan()`.
**Lesson:** Native driver ≠ worklet; worklets are the modern answer.

### Production Failure Story
**Incident:** Animation triggered double-firing on Android 14.
**Investigation:** `runOnJS` callback fired multiple times due to duplicated worklet builds.
**Root cause:** Misconfigured Babel plugin.
**Fix:** Pin Reanimated/Babel versions; reset Metro cache; test.
**Prevention:** Pin version compatibility matrix for Reanimated, RN, Babel.

### Debugging Checklist
1. `'worklet'` directive present?
2. `Animated.View`/`Animated.ScrollView` used?
3. Babel plugin order correct (Reanimated last)?
4. `useSharedValue` not re-created each render?

### Advanced / Internal Knowledge
- Reanimated 4 supports React-state-aware layout transitions.
- `runOnUI`/`runOnJS` cross runtime boundaries; minimize crossings.
- Skia + Reanimated can power 120fps custom rendering.

### 2026 AI Tip
AI mixes Reanimated v1, v2, v3 syntax. Always specify Reanimated 3/4 in prompts and verify imports.

### Related Topics
Q2 (threads), Q3 (lists), S4 (Fabric), S2 (Compiler).

### Interview Follow-Up Questions
- "How does Reanimated avoid the JS thread?"
- "What's `'worklet'` and why does it matter?"
- "Reanimated 3 vs 4?"
- "When would you fall back to LayoutAnimation?"

### Memory Hook
**"SharedValue + worklet + AnimatedStyle = UI-thread animation. setState ≠ animation."**

### Revision Notes
> Reanimated 3/4 = worklet runtime on UI thread; SharedValues + useAnimatedStyle for declarative animation; gestures via react-native-gesture-handler; never use `setState` for animation.

---

## Q5. Image performance and modern formats

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common.

### Prerequisites
HTTP basics, image formats, RN image components.

### TL;DR
Use **`expo-image`** (or Fast Image) for caching, decoding, and progressive loading; serve **WebP/AVIF**; size images server-side; never load originals into thumbnails.

### 30-Second Interview Answer
"`expo-image` does memory + disk caching, format negotiation, progressive load, and blurhash placeholders. Pair with a CDN that serves WebP/AVIF based on `Accept` header. Always request server-resized variants — never load a 4K original into a 200×200 thumbnail. Set `recyclingKey` on lists to align with FlashList recycling."

### 2-Minute Practical Answer
```tsx
import { Image } from 'expo-image';

<Image
  source={{ uri }}
  placeholder={blurhash}
  transition={150}
  contentFit="cover"
  cachePolicy="memory-disk"
  recyclingKey={item.id}
/>
```

CDN setup:
- Cloudinary / Imgix / next-gen image proxy.
- Accept-aware delivery (WebP/AVIF on supporting clients).
- Width-based variants (`?w=320`).

Avoid:
- Built-in `Image` component for hot paths (no caching, no recycle hint).
- `Image.getSize` per render (sync network call).
- Loading SVG via `Image` (use `react-native-svg`).

### 5-Minute Architecture Answer
Image perf has three axes:
1. **Network** — bytes over the wire. WebP saves 25–35% vs JPEG; AVIF saves 50%.
2. **Decode** — CPU/GPU on native thread. Smaller images decode faster; modern formats vary.
3. **Memory** — pixel buffer (width × height × 4 bytes). A 4K image is 33MB even if the file is 500KB.

Cache layers:
- **Memory cache** (LRU, fast).
- **Disk cache** (persists across launches).
- **HTTP cache** (set proper headers).

`expo-image` handles 1 + 2 with sensible defaults; FlashList `recyclingKey` aligns image and cell pools.

### The "Why"
- Images dominate mobile bandwidth and memory.
- Bad image handling causes OOM crashes on low-end Android.
- Users notice slow images far more than slow JSON.

### Mental Model
Image pipeline = network → decode → memory bitmap → GPU upload. Each step is a budget; control all three.

### Internal Working (2026 Context)
- `expo-image` uses SDWebImage (iOS) and Glide (Android) under the hood.
- Disk cache writes are async; memory cache is LRU-bounded.
- Modern devices accelerate WebP/AVIF decode in hardware.

### Modern Implementation (Code)
Avatar list with FlashList:
```tsx
function AvatarRow({ user }: { user: User }) {
  return (
    <Image
      source={{ uri: `${user.avatar}?w=120` }}
      placeholder={user.blurhash}
      style={{ width: 60, height: 60, borderRadius: 30 }}
      cachePolicy="memory-disk"
      recyclingKey={user.id}
    />
  );
}
```

Preload during route prefetch:
```ts
import { Image } from 'expo-image';
await Image.prefetch(['https://cdn/.../1.webp', 'https://cdn/.../2.webp']);
```

### Comparison

| Component / lib  | Cache | Decode | Recycle hint | Notes               |
| ---------------- | ----- | ------ | ------------ | ------------------- |
| `expo-image`     | ✓✓    | Native | ✓            | Default in 2026     |
| Fast Image       | ✓✓    | Native | partial      | Mature, alternative |
| Built-in Image   | basic | basic  | ✗            | Avoid for lists     |
| `react-native-svg`| n/a  | CPU    | n/a          | Vector only         |

### Production Usage
- Use `expo-image` everywhere except SVGs.
- Always serve resized images.
- Always provide blurhash or low-res placeholder.

### Hands-On Exercise
1. Replace built-in Image with `expo-image` in a feed; measure scroll JS time.
2. Switch CDN to deliver WebP; measure bytes.
3. Add blurhash; observe perceived load improvement.

### Common Mistakes
- Loading originals at thumbnail size.
- No `recyclingKey` in lists.
- Caching "everything forever" → OOM.
- Sync `Image.getSize` calls in render.

### Production Red Flags
- OOM crashes on Android with image-heavy screens.
- Constant network re-fetches of same image.
- No cache headers on CDN responses.

### Performance & Metrics
- Bytes per screen.
- Decode time per image.
- Memory cache hit rate.
- Image-related OOM.

### Metrics That Matter
Page weight, image cache hit rate, OOM rate, perceived first paint.

### Decision Framework
- Big lists → FlashList + `expo-image` + `recyclingKey`.
- Hero images → blurhash + AVIF.
- SVGs → `react-native-svg`.
- Animated GIFs → consider video instead.

### Senior-Level Insight
Image perf is mostly a **product/CDN** problem masquerading as an RN problem. Fix the pipeline — sizing, format negotiation, caching headers — and the client code becomes trivial.

### Real-World Scenario
**Symptom:** Profile screen showed blurry avatars even on Wi-Fi.
**Investigation:** Avatar URL had no size param; CDN served 1500×1500.
**Root cause:** No size negotiation.
**Fix:** Append `?w=120`; introduce a typed image-URL helper.
**Lesson:** Design your image API to require size.

### Production Failure Story
**Incident:** Android OOMs on image-heavy gallery screen.
**Investigation:** Loaded full 4K originals; memory cache exceeded heap budget.
**Root cause:** No size resizing + unbounded memory cache.
**Fix:** Server thumbnails + bounded LRU.
**Prevention:** Memory budget alarm in tests.

### Debugging Checklist
1. Are images sized at request time?
2. Is `expo-image` (or Fast Image) used?
3. Is `recyclingKey` aligned with cell key?
4. Cache headers set?

### Advanced / Internal Knowledge
- Hardware decoders accelerate WebP/AVIF on modern devices.
- Disk cache eviction policy can be tuned in `expo-image`.
- For 120Hz scrolling, prefetch upcoming images using FlashList's `onViewableItemsChanged`.

### 2026 AI Tip
AI defaults to built-in Image. Always re-prompt for `expo-image` and check that `recyclingKey` is included in list contexts.

### Related Topics
Q3 (FlashList), S9 (networking/CDN), S15 (offline/storage).

### Interview Follow-Up Questions
- "What's the difference between WebP and AVIF?"
- "How does `expo-image` cache?"
- "How do you avoid OOM on image-heavy lists?"
- "What is blurhash and when do you use it?"

### Memory Hook
**"Resize on server. Cache on device. Recycle in lists. Blurhash for the wait."**

### Revision Notes
> `expo-image` for caching/decoding; serve WebP/AVIF; always size server-side; `recyclingKey` for FlashList; blurhash placeholders; bounded memory cache to prevent OOM.

---

## Q6. App size optimization

### Difficulty
Advanced

### Interview Frequency
Common at Senior+ — emerging concern with Privacy/Compliance and emerging-market focus.

### Prerequisites
Build pipeline knowledge, ProGuard/R8, App Bundles.

### TL;DR
**App Bundle (AAB)** + **App Thinning (iOS)** + **R8/ProGuard** + **resource shrinking** + **lean dependencies**. Target <30MB on Android, <100MB on iOS.

### 30-Second Interview Answer
"On Android, ship as Android App Bundle (AAB) so the Play Store generates per-device APKs (only the right ABI, language, density). Use R8 with shrink + obfuscation enabled. On iOS, App Thinning + bitcode-free builds. Strip unused locales, fonts, and assets. Audit native dependencies — each adds binary. Target <30MB Android download, <100MB iOS. Anything over 150MB hurts conversion significantly in emerging markets."

### 2-Minute Practical Answer
Levers (Android):
- AAB instead of universal APK.
- R8 enabled (`minifyEnabled true`, `shrinkResources true`).
- Per-architecture splits.
- Remove unused locales (`resConfigs ['en']`).
- Audit `node_modules` for native deps.

Levers (iOS):
- App Thinning (default for App Store).
- On-demand resources for large optional assets.
- Strip debug symbols from release.

Cross-cutting:
- Hermes bytecode (smaller than minified JS).
- Avoid duplicate font weights.
- Image assets at the right resolution.
- Don't bundle the world's locale data.

### 5-Minute Architecture Answer
Modern app size is a **distribution + dependencies** problem. Two phases:
1. **Build artifact** — what your CI produces.
2. **User download** — what the user actually downloads (after AAB / Thinning).

Optimize both. AAB matters because a 60MB universal APK becomes a 25MB user download for the right device. iOS App Thinning does the same.

Native dependencies are the biggest single cost — each `pod` / `aar` adds binary. Audit:
```bash
# iOS
otool -L App.app/App | sort -u
# Android
./gradlew :app:dependencies | grep -i "implementation"
```

For RN libraries: prefer pure-JS alternatives when binary cost outweighs benefit.

### The "Why"
- App Store rankings, install conversion, and user reviews all penalize large apps.
- Emerging markets often have data caps and slow networks.
- iOS WiFi-only download threshold (200MB historically) is a hard ceiling for many users.

### Mental Model
App size = **(native libs) + (assets) + (JS bundle as bytecode) + (resources)**. Optimize each.

### Internal Working (2026 Context)
- Android App Bundle is the default in Play Console.
- iOS App Thinning happens during App Store processing.
- R8 is the modern replacement for ProGuard (built into AGP).

### Modern Implementation (Code)
`android/app/build.gradle`:
```gradle
android {
  buildTypes {
    release {
      minifyEnabled true
      shrinkResources true
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
  }
  defaultConfig {
    resConfigs 'en' // ship only English; add others as needed
    ndk {
      abiFilters 'arm64-v8a', 'armeabi-v7a' // drop x86 unless needed
    }
  }
}
```

iOS: in `Podfile.properties.json` and Xcode build settings, ensure `Strip Debug Symbols During Copy = YES` for release.

### Comparison

| Lever                  | Android win  | iOS win        |
| ---------------------- | ------------ | -------------- |
| AAB / Thinning         | -30 to -50%  | -20 to -40%    |
| R8 minify + shrink     | -10 to -30%  | n/a            |
| Resource shrinking     | -5 to -15%   | n/a            |
| Locale strip           | -3 to -10%   | -3 to -10%     |
| Lean deps              | -5 to -25%   | -5 to -25%     |
| Hermes vs JSC          | -2 to -5MB   | -1 to -3MB     |

### Production Usage
- Track download size per release in CI.
- Set per-platform budget; fail builds on regression.
- Quarterly dependency audit.

### Hands-On Exercise
1. Build a release APK; measure size.
2. Switch to AAB; check Play Console's per-device download estimates.
3. Enable R8 + shrink resources; remeasure.
4. Drop unneeded locales; remeasure.

### Common Mistakes
- Shipping universal APK in production.
- Bundling all `moment.js` locales.
- Including duplicate fonts (.otf and .ttf for same family).
- Adding heavy SDKs for a single feature.

### Production Red Flags
- Universal APK in CI artifacts.
- Release build without R8.
- 200MB+ iOS app.
- No per-architecture splits.

### Performance & Metrics
- Download size by ABI (Android).
- Universal vs per-device estimate (Android).
- IPA size (iOS).
- Install conversion rate (Play/App Store Connect).

### Metrics That Matter
Download size, install funnel conversion, uninstall rate.

### Decision Framework
- Always AAB (Android), default Thinning (iOS).
- Always R8 + shrink resources.
- Audit deps quarterly.
- Lazy-load assets (videos, big images, fonts).

### Senior-Level Insight
App size is the canary for **dependency discipline**. A team that lets size creep is a team that adds dependencies without auditing. Make size a CI gate to enforce that culture.

### Real-World Scenario
**Symptom:** Android download grew from 22MB to 38MB over a quarter.
**Investigation:** Multiple analytics SDKs added; one shipped per-arch native libs.
**Root cause:** No CI gate on size.
**Fix:** Remove duplicate analytics; add CI size budget.
**Lesson:** Size grows silently without enforcement.

### Production Failure Story
**Incident:** App rejected from Play Store for exceeding 150MB AAB.
**Investigation:** Bundled ML model (50MB) for one feature 1% of users used.
**Root cause:** Shipped optional model with binary.
**Fix:** Move model to on-demand download (Play Asset Delivery / On-Demand Resources).
**Prevention:** Asset budget per feature.

### Debugging Checklist
1. Universal APK or AAB?
2. R8 + resource shrink enabled?
3. Locales pruned?
4. Native deps audited?
5. Per-arch sizes recorded?

### Advanced / Internal Knowledge
- Play Asset Delivery / iOS On-Demand Resources allow gigabyte assets without bloating install.
- Dynamic Feature Modules (Android) for optional features.
- iOS App Clips for tiny entry-point experiences.

### 2026 AI Tip
AI is good at suggesting Gradle config but rarely audits dependencies for size impact. Use `bundle-phobia`-style analysis on top.

### Related Topics
S6 (Hermes), S20 (CI/CD), S30 (compliance — privacy manifests can grow size if mishandled).

### Interview Follow-Up Questions
- "AAB vs APK?"
- "How does App Thinning work?"
- "How do you guard against size regressions?"
- "When would you use on-demand assets?"

### Memory Hook
**"AAB + R8 + Thinning + lean deps + asset audit. Size is a CI gate, not an afterthought."**

### Revision Notes
> Ship AAB (Android) / Thinned (iOS); R8 minify + shrink resources; prune locales; audit native deps; CI size budget; on-demand resources for large optional assets.
