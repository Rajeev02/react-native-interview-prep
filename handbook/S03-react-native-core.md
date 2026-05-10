# S3 — React Native Core

> Lists · gestures · Reanimated · Skia · styling · keyboard · edge-to-edge · deep linking

This section covers the day-to-day primitives every senior RN engineer must operate with surgical precision. Five Q-topics, each in the mandatory per-topic format from [final-prompt.md](../final-prompt.md).

---

### Q1. List components decision tree — `ScrollView` vs `FlatList` vs `SectionList` vs `FlashList`

---

## Difficulty
- Intermediate → Advanced

## Interview Frequency
- Very Common (asked in 90%+ of senior RN interviews)

## Prerequisites
- React reconciliation, keys, virtualization concept
- RN threading model (S4), basic Fabric awareness

## TL;DR
Use `ScrollView` only for tiny finite content; `FlatList` for medium homogeneous lists; `FlashList` (recycler) for any production list of unknown/large size; `SectionList` only when sectioned headers are essential.

---

## 30-Second Interview Answer

> "`ScrollView` mounts every child up-front — never use it for unbounded data. `FlatList` virtualizes by unmounting offscreen rows but still allocates new components on scroll, causing GC pressure. `FlashList` v2 recycles native views the way RecyclerView/UICollectionView do, with `getItemType` and `estimatedItemSize` driving recycling pools. For any production feed I default to FlashList; FlatList only when I need its `VirtualizedList` API contract (e.g. inverted chat with sticky behaviors)."

---

## 2-Minute Practical Answer

Three mental categories:

1. **Eager render** — `ScrollView`. Mounts everything. Memory grows linearly with item count. Fine for ≤20 small items, settings screens, hero sections. Disastrous for feeds.
2. **Virtualization (unmount/remount)** — `FlatList`, `SectionList`. Built on `VirtualizedList`. Renders a window around the viewport, unmounts offscreen rows. The cost is **render cost on scroll**: every newly-visible row is a fresh React mount. With heavy rows (images, animations) you blow frame budget.
3. **Recycling** — `FlashList` (Shopify). Maintains a pool of mounted "view holders" per `itemType`. Scrolling a holder offscreen frees it back to the pool; new data is bound to it without React re-mounting. Net result: drastically lower JS/UI work per scroll frame.

Decision rule: **if the list can grow past one screen of items, default to FlashList**. The only reasons to stay on FlatList are (a) you need a third-party that hardcodes `VirtualizedList` props, (b) you're on a workspace that hasn't adopted FlashList yet, or (c) the list is genuinely tiny and FlashList's `estimatedItemSize` overhead isn't worth it.

---

## 5-Minute Architecture Answer

Lists are where the **JS thread**, **shadow/Fabric thread**, and **UI thread** meet under load. The primary cost categories:

1. **JS render cost** — running `renderItem` for each newly-visible row. Solved by recycling (FlashList) or by making `renderItem` cheap (Compiler-friendly, no inline closures over heavy state).
2. **Shadow/layout cost** — Yoga laying out new subtrees. With Fabric this happens on the shadow thread, but it still steals from the same C++ budget. Recycling keeps the layout tree shape stable.
3. **UI thread cost** — view creation, decoding images, uploading textures. Recycling avoids native view allocation/deallocation churn.
4. **Memory** — eager `ScrollView` keeps every native view live; virtualized lists keep only a window; recycled lists keep a *constant* pool size regardless of dataset size.

`FlashList` v2 (released 2025-2026) deepened the recycling model with: `getItemType(item)` for heterogeneous feeds (story header vs ad vs post — each gets its own pool); auto-sized cells (no `estimatedItemSize` required for static content); first-class support for Reanimated layout animations on cells; and built-in `viewabilityConfig` callbacks for impression telemetry. On Fabric, FlashList batches commits to keep the shadow thread under 16ms even at 120Hz.

`SectionList` is just a `VirtualizedList` with section indexing. Replace it with a flattened FlashList plus `stickyHeaderIndices` unless you need RN's specific sticky header semantics — flattening typically wins on perf because there's only one virtualization pass.

`ScrollView` does have one production use case people forget: parallax/horizontal carousels of small fixed-count items where you want gesture continuity with Reanimated's `useAnimatedScrollHandler`. For 5–10 stories at the top of a feed, `ScrollView horizontal` is correct.

---

## The "Why"

Mobile screens render at 60Hz (16.67ms budget) or 120Hz (8.33ms). A scrolling list must produce a new frame every cycle. With React's default model, every scroll exposes new rows that must run through reconciliation → commit → mount → layout → draw. Without recycling, you're doing all five steps per row per frame for newly-visible content. The phone's battery, GC, and frame pacing cannot keep up. **Recycling exists to amortize those costs to zero on the steady-state scroll.**

Companies care because feeds are the #1 source of jank complaints, the #1 source of OOM crashes on low-end Android, and the #1 source of negative store reviews about "laggy app".

---

## Mental Model

Think of three restaurant models:

- **`ScrollView`** = a buffet where every dish is laid out before the first guest arrives. Beautiful for 5 dishes; bankrupt at 5,000.
- **`FlatList`** = a kitchen that makes a fresh plate for every new guest and throws away plates when guests leave. Fine throughput, but the dishwasher (GC) is always running.
- **`FlashList`** = a sushi conveyor. A fixed set of plates rotates; when a plate leaves the customer it's wiped and reused for the next dish. Throughput approaches the speed of the belt — independent of how many guests show up.

---

## Internal Working (2026 Context)

`FlashList` v2 internals:

```
DataSource (props.data) ─┐
                         │
                         ▼
              ┌─────────────────────┐
              │  Layout Manager     │  computes window + offsets
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │  Recycler Pool      │  keyed by getItemType(item)
              │  (per-type holders) │
              └──────────┬──────────┘
                         │ binds
              ┌──────────▼──────────┐
              │  React tree slot    │  renderItem({ item }) into stable slot
              └──────────┬──────────┘
                         │ commit
              ┌──────────▼──────────┐
              │  Fabric shadow tree │  diff against previous bind, minimal mutation
              └──────────┬──────────┘
                         │
                         ▼
                    UI thread mount
```

Key 2026 details:
- On **Fabric**, FlashList uses `unstable_batchedUpdates` + concurrent React to batch holder rebinds within a single commit.
- On **Bridgeless** mode, scroll events arrive via JSI synchronously (no serialized bridge), so `useAnimatedScrollHandler` from Reanimated runs on the UI thread without round-tripping JS.
- `getItemType` is the single most important perf knob — wrong type granularity defeats recycling. Too few types (everything is `'item'`) means a video cell gets recycled into a text cell — the View tree shape changes and React has to re-mount. Too many types (every item is unique) means the pool can't reuse anything.
- **React Compiler** auto-memoizes `renderItem` body, so you no longer need `useCallback` around it. Just don't capture mutable refs that change every render.

---

## Modern Implementation (Code)

```tsx
// FeedList.tsx — production FlashList v2 pattern
import { FlashList, ListRenderItem } from '@shopify/flash-list';
import { useFeedQuery } from '@/features/feed/api';
import { PostCell } from './PostCell';
import { AdCell } from './AdCell';
import { StoryStripCell } from './StoryStripCell';
import { Empty } from '@/ui/Empty';
import { ListFooter } from '@/ui/ListFooter';

type FeedItem =
  | { kind: 'story-strip'; id: string; stories: Story[] }
  | { kind: 'post'; id: string; post: Post }
  | { kind: 'ad'; id: string; ad: Ad };

const renderItem: ListRenderItem<FeedItem> = ({ item }) => {
  switch (item.kind) {
    case 'story-strip': return <StoryStripCell stories={item.stories} />;
    case 'post':        return <PostCell post={item.post} />;
    case 'ad':          return <AdCell ad={item.ad} />;
  }
};

export function FeedList() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useFeedQuery();
  const items = data?.pages.flatMap((p) => p.items) ?? [];

  return (
    <FlashList
      data={items}
      renderItem={renderItem}
      keyExtractor={(it) => it.id}
      getItemType={(it) => it.kind}            // THE perf knob
      onEndReached={hasNextPage ? fetchNextPage : undefined}
      onEndReachedThreshold={0.6}
      ListEmptyComponent={Empty}
      ListFooterComponent={isFetchingNextPage ? <ListFooter /> : null}
      onViewableItemsChanged={trackImpressions}  // for analytics
      viewabilityConfig={{ itemVisiblePercentThreshold: 50 }}
    />
  );
}
```

Notes:
- No `useCallback` / `useMemo` — React Compiler handles it.
- `getItemType` returns the union discriminant — recycler pool per kind.
- `onViewableItemsChanged` ties impressions to the same scroll pass — avoid a second viewport tracker.

---

## Comparison

| Property | `ScrollView` | `FlatList` | `SectionList` | `FlashList` v2 |
|---|---|---|---|---|
| Mount strategy | Eager (all) | Virtualized window | Virtualized window | Recycled holders |
| Memory at N=10k | O(N) catastrophic | O(window) | O(window) | O(pool) constant |
| Cost per new visible row | n/a (already mounted) | Fresh React mount | Fresh React mount | Bind to existing holder |
| Heterogeneous lists | n/a | Slow (all types share window) | Sections only | `getItemType` pools |
| Sticky headers | manual | partial | yes | `stickyHeaderIndices` |
| Reanimated layout anims on cells | manual | brittle | brittle | first-class |
| Default in 2026 | ❌ for any list | ⚠️ legacy code only | ⚠️ niche | ✅ |

---

## Production Usage

- **Social feeds** (Instagram, Twitter clones) — FlashList with `getItemType` per content kind. Pre-warm pools by initial `data` containing one of each type.
- **Chat** — FlashList inverted, with message-shape-based `getItemType` (text / image / system / receipt).
- **E-commerce grids** — FlashList with `numColumns`, item type per card variant (product / ad / banner).
- **Settings screens** — `ScrollView` is fine; don't over-engineer.
- **Carousels of 5–10 items** — `ScrollView horizontal` + `useAnimatedScrollHandler`. FlashList horizontal works but `estimatedItemSize` becomes finicky.

Scaling notes: for feeds >5k items in memory, paginate aggressively (TanStack Query infinite queries) and **drop pages from cache** beyond a window — FlashList handles huge `data` arrays, but JS memory still grows linearly with array size.

---

## Hands-On Exercise

1. **Implementation:** convert a `FlatList` chat screen of 1000 messages (text + image + receipt) to `FlashList` with proper `getItemType`. Measure before/after with Reassure or Perf Monitor.
2. **Debugging:** a `FlashList` shows momentary "wrong content" flicker on scroll. Diagnose (likely cause: `renderItem` reads from a ref or external store that doesn't update synchronously when the holder re-binds — fix with derived state from `item` only).
3. **Architecture:** design the data pipeline for an infinite feed where each post can have 0–N comments preview. How do you key, type, and paginate?
4. **Optimization:** make a heterogeneous feed maintain steady 120fps on a Pixel 7 with mixed posts + ads + videos.

---

## Common Mistakes

- Wrapping a FlashList in a `ScrollView` (defeats virtualization, RN warns).
- Using item index as `keyExtractor` — destroys recycling and animations.
- Returning a different component shape across the same `getItemType` (recycler hands you a holder shaped for type A, you render type B → flicker).
- Inline `renderItem={({ item }) => <Heavy />}` capturing fresh closures — the Compiler memoizes the function, but if you capture `Date.now()` it's a new dep every render.
- Mixing `estimatedItemSize` very wrong — under-estimating triggers a "blank" zone on fast scroll; over-estimating wastes memory in pool warm-up.
- Putting `ScrollView`-style content (headers, hero, list, footer) all inside one FlashList with unique types per row — defeats pooling. Use `ListHeaderComponent` / `ListFooterComponent` instead.

---

## Production Red Flags

- **"We use ScrollView with .map"** for a feed → instant junior signal.
- **"FlatList is fine, FlashList is just hype"** → out of date; recycling is a category win, not a vendor flex.
- **"We removed virtualization to fix a layout bug"** → root cause was almost certainly absolute positioning or measurement timing; turning off virtualization is treating the symptom.
- **No `getItemType` on a heterogeneous FlashList** → recycler is effectively off; you have a fancy FlatList.
- **Impression analytics in a separate `IntersectionObserver`-style hook** → wasted scroll work; piggyback on `onViewableItemsChanged`.

---

## Performance & Metrics (MANDATORY)

- **FPS:** scrolling P95 should hit refresh-rate ceiling (60 or 120). FlashList typically gets you there with ≤2ms JS per frame on mid-range Android.
- **TTI:** first list paint should be <1 frame after data arrives. Use `initialNumToRender`-style equivalents (FlashList auto-sizes) and avoid waiting on images for first-paint.
- **Memory:** a recycled list of 50k items should be O(visible window + pool), typically <30MB extra. A `ScrollView` of 50k mounts will OOM on 2GB Android devices.
- **Thread:** with Fabric + Bridgeless, scroll handlers run on UI thread (Reanimated worklets) and FlashList's commits are batched on shadow thread. JS thread should be near-idle while scrolling.
- **Bundle:** `@shopify/flash-list` adds ~30KB minified+gzipped. Negligible.
- **Battery:** recycling keeps GPU/CPU duty cycle low → measurable battery wins on long sessions (chat, feed).
- **Optimization strategies:** image dimensions known up-front (avoid layout shift), `expo-image` with proper `cachePolicy`, defer comment counts / heavy data to viewability callbacks.

---

## Metrics That Matter

- Scroll FPS P50 / P95 (per-screen RUM)
- Frozen frames per session (Sentry / Firebase Performance)
- ANR rate on scroll-heavy screens
- Memory delta on `Feed` screen mount
- "Janky frames" % on Android (Play Console vitals)

---

## Decision Framework

| Use case | Pick |
|---|---|
| Settings / forms / hero blocks | `ScrollView` |
| Tiny carousels with gesture | `ScrollView horizontal` |
| Legacy code, can't add dep | `FlatList` |
| Production feed of unknown size | `FlashList` ✅ |
| Chat | `FlashList inverted` |
| Sticky multi-section navigation list | `FlashList` + `stickyHeaderIndices`, flatten sections |
| You think you need `SectionList` | Re-evaluate — flat FlashList usually wins |

When NOT to use FlashList: <10 fixed items where set-up cost (`estimatedItemSize`, pool warm-up) exceeds savings.

Migration cost: FlatList → FlashList is usually a single-file change (props are nearly compatible). Watch for: `getItemLayout` becomes `estimatedItemSize`; `extraData` semantics differ; you must pass stable `keyExtractor`.

---

## Senior-Level Insight

The deeper insight: **virtualization is a JS-thread optimization; recycling is a native/UI-thread optimization**. RN's history of perf wins on lists has been a stepwise march down the stack — first virtualizing in JS (FlatList), then recycling native views (FlashList), and on Fabric, batching shadow tree commits. Each layer attacks a different bottleneck. Senior engineers reason about which thread is starving (use Perfetto / Instruments) before picking a list component. If your jank is in `RCTSurfacePresenter` commits on the UI thread, switching to FlashList helps a lot. If your jank is in JS `renderItem` doing JSON parsing, no list component will save you — fix the work.

Organizationally: standardize FlashList in your design system's list primitives. Don't let teams roll their own list wrappers — you'll end up with five subtly different recycler configs and inconsistent feed performance.

---

## Real-World Scenario

**Symptom:** Feed FPS drops to ~25 on Android mid-tier devices when ads start appearing every 5 posts.
**Investigation:** Perfetto trace shows long native view inflation on scroll exposing ads. JS thread is fine.
**Root Cause:** `getItemType` returned `'post'` for both posts and ads. Recycler handed back post-shaped holders, React detected a different tree shape (ad uses a different View hierarchy), and forced full re-mount per scroll event.
**Fix:** `getItemType: (item) => item.kind` so ads get their own pool.
**Lesson:** Heterogeneous lists need explicit type discrimination. The recycler is only as smart as the type function.

---

## Production Failure Story

**Incident:** Black Friday e-commerce feed crashed with OOM on Android 8 devices for ~3% of sessions. Crash-free dropped from 99.6% to 96.1% in 2 hours.
**Impact:** Estimated $400k in lost orders during the spike window.
**Investigation:** Crashlytics traces pointed to `Bitmap allocation`. Memory profiler showed image cache + list mounts both peaking simultaneously.
**Root Cause:** A junior engineer had wrapped the product grid (FlashList) inside a `ScrollView` to add a parallax hero. RN silently disabled virtualization. With the campaign banner image (full-screen WebP) plus 200+ products mounted at once, the heap blew past Android 8's 256MB per-app limit.
**Fix:** Move parallax hero to FlashList's `ListHeaderComponent`. Add an integration test asserting that `FlashList` is not nested in a `ScrollView` (lint rule + runtime warning).
**Prevention:** ESLint rule banning `ScrollView` with FlashList descendants; design-system list primitive that exposes a `Header` slot natively; on-call playbook entry for "OOM on feed".

---

## Debugging Checklist

1. Reproduce on a low-end device (Pixel 4a / iPhone SE 2nd gen).
2. Open **React Native DevTools** → Performance Monitor; check JS FPS vs UI FPS while scrolling.
3. Run **Perfetto** (Android) or **Instruments → Time Profiler** (iOS) for a 10s scroll capture.
4. If JS thread is busy: examine `renderItem`, look for synchronous JSON, regex, sort.
5. If UI thread is busy: check view inflation cost; misuse of `getItemType`; large image decode without sizing.
6. Check `console.warn` for "VirtualizedList: nested in ScrollView" or "missing getItemType".
7. Profile with **React Native DevTools profiler** to see per-item commit time on Fabric.
8. Sentry → Performance → check `Slow Frames` and `Frozen Frames` for the screen.

---

## Advanced / Internal Knowledge

- `VirtualizedList` (the base of FlatList/SectionList) maintains an internal `Cell` component per row that wraps your `renderItem` output and tracks visibility via `onLayout` + scroll offset. Each scroll event runs a `_updateCellsToRender` pass through JS — this is the per-frame cost.
- FlashList sits on top of [recyclerlistview](https://github.com/Flipkart/recyclerlistview), which uses a `LayoutProvider` + `DataProvider` model. v2 added a Fabric-aware commit batcher and a TS-strict rewrite.
- On Fabric, the shadow tree diff for an item swap is shallow if the holder's children types match; deep if they don't. This is *why* `getItemType` matters at the C++ layer, not just the JS layer.
- `inverted` lists on iOS use `transform: [{ scaleY: -1 }]` and double-flip cells. On chat with images, this can cause subtle layout issues with absolute-positioned reactions; use FlashList's native inverted support which is implemented at the layout-manager level on Fabric.
- Bridgeless + JSI lets `useAnimatedScrollHandler` (Reanimated) deliver scroll events directly to UI-thread worklets — making sticky headers and parallax buttery without JS bouncing.

---

## 2026 AI Tip

- AI is **good at**: generating boilerplate `renderItem`, suggesting `getItemType` for a typed union, converting FlatList to FlashList syntactically.
- AI is **bad at**: choosing the *right* `getItemType` granularity for *your* data shape — it'll either lump or over-split. Verify pool sizes empirically.
- **Hallucination risk:** older models still suggest deprecated FlatList props (`getItemLayout` with FlashList, `removeClippedSubviews` as a magic fix). Verify against current FlashList docs.
- **Prompt pattern:** "Given this discriminated union `FeedItem = ...`, write a FlashList screen with item-type pools, viewability impression telemetry, and Reanimated layout animation on insert."
- **Agentic workflow:** have the agent run Reassure to compare before/after benchmarks for a list refactor, not just trust eyeballed scrolling.

---

## Related Topics

- S4 Fabric & shadow tree commits
- S7 Performance — FPS, TTI, image perf
- S8 TanStack Query infinite queries
- Reanimated 3/4 (Q2 below)
- Edge-to-edge layouts (Q5 below)

---

## Interview Follow-Up Questions

- Why does `getItemType` matter at the native layer, not just JS?
- How would you instrument scroll FPS in production?
- How would you design a list that mixes images, videos, and text without dropping frames on Android Go?
- What's the failure mode if you change `keyExtractor` mid-session?
- How does FlashList interact with Reanimated layout animations under Fabric?

---

## Memory Hook

**"Eager mounts, virtual unmounts, recyclers re-bind."** Three eras of RN lists, one sentence.

## Revision Notes

> Default to FlashList. Always set `getItemType` for heterogeneous data. Never nest virtualized lists in ScrollView. Recycling beats virtualization beats eager mount.

---

---

### Q2. Gesture Handler 2 + Reanimated 3/4 — composing gestures, conflict resolution, and 120fps animations

---

## Difficulty
- Advanced

## Interview Frequency
- Common (asked when role mentions animations, custom UI, gestures)

## Prerequisites
- Q1 (lists), threading model (S4), worklets concept

## TL;DR
Gesture Handler 2 turns gestures into composable, declarative state machines that run on the UI thread; Reanimated 3/4 worklets co-locate animation logic on the same thread. Together they enable 120fps interactions without JS round-trips.

---

## 30-Second Interview Answer

> "RN's built-in `PanResponder` runs on the JS thread — every touch round-trips through the bridge/JSI, so JS lag jankifies gestures. Gesture Handler 2 implements gesture recognizers natively (UIGestureRecognizer / Android MotionEvent stack) and exposes them as composable `Gesture.Pan() / .Pinch() / .Tap()` objects with `.simultaneousWithExternalGesture` and `.requireExternalGestureToFail` for conflict resolution. Reanimated worklets read shared values on the UI thread, so a `useAnimatedStyle` reading a shared value updated by a gesture handler never crosses thread boundaries. That's how you get 120Hz swipes."

---

## 2-Minute Practical Answer

Gesture Handler 2's mental model:

1. Gestures are **first-class objects**, not props on Views. You build them with `Gesture.Pan()`, `Gesture.Tap()`, etc.
2. **Composition**: `Gesture.Simultaneous(a, b)`, `Gesture.Race(a, b)`, `Gesture.Exclusive(a, b)`. This replaces the imperative `simultaneousHandlers` ref-juggling of v1.
3. **Worklet callbacks**: `.onUpdate((e) => { 'worklet'; sharedX.value = e.translationX; })`. The body runs on the UI thread; no JS round-trip.
4. **`GestureDetector`** wraps the View; the gesture is attached natively.

Reanimated 3/4 mental model:

1. **Shared values** (`useSharedValue`) live in a UI-thread runtime alongside JS-thread runtime. Mutations propagate via JSI.
2. **Worklets** are JS functions tagged `'worklet'` that the Reanimated Babel plugin extracts and compiles to run in the UI runtime. They can call other worklets and read/write shared values without thread crossing.
3. **`useAnimatedStyle`** runs a worklet on each frame to compute style from shared values; updates are applied directly to native props on UI thread.
4. **Layout animations** (`entering={FadeIn}`, `layout={LinearTransition}`) run natively when items mount/unmount/reorder.

Combined, a swipe-to-dismiss looks like: PanGesture → onUpdate worklet → mutate sharedX → useAnimatedStyle reads sharedX → native transform updates. JS thread is uninvolved after initial setup.

---

## 5-Minute Architecture Answer

Three thread runtimes are in play:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  JS Runtime     │    │  UI Runtime     │    │  Native UI      │
│  (Hermes)       │◄──►│  (Reanimated)   │◄──►│  thread (RCT)   │
│  business logic │JSI │  worklets       │    │  view tree      │
│  React tree     │    │  shared values  │    │  Core Animation │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

- **Setup**: React renders `<GestureDetector gesture={pan}><Animated.View style={animStyle} /></GestureDetector>`. Gesture Handler attaches a native recognizer; Reanimated installs the `useAnimatedStyle` worklet into the UI runtime.
- **Gesture in flight**: native recognizer fires `onUpdate` → Gesture Handler invokes the worklet on the UI runtime → worklet writes shared value → Reanimated's per-frame loop on UI thread re-evaluates `useAnimatedStyle` → native prop set on the view. Zero JS thread involvement.
- **Conflict resolution**: solved declaratively by composition. A swipeable row inside a vertically scrolling FlashList uses `Gesture.Pan().activeOffsetX([-10, 10]).failOffsetY([-5, 5])` so vertical scroll claims the gesture if user moves vertically first. Or `pan.simultaneousWithExternalGesture(scrollRef)` for parallel.
- **120fps targeting**: ProMotion (iOS) and 90/120Hz Android panels need an animation that runs at the panel rate. Reanimated 3+ uses `requestAnimationFrame` on the UI runtime which is paced by Choreographer / CADisplayLink. Worklets must be cheap (<2ms) to hit 8.33ms/frame at 120Hz.
- **Reanimated 4** (2025-2026) added: better TS inference for shared values, layout animation interruption (you can grab a mid-flight layout anim and re-target), Skia integration for canvas-driven animations, and improved error stacks for worklet crashes.

---

## The "Why"

Touch latency is the most visceral perf metric in mobile UX. Users tolerate slow networks; they don't tolerate a button that responds 100ms late. The legacy bridge added 16-50ms of lag to every touch event because gesture state machines ran in JS while the OS dispatched events at 120Hz. Gesture Handler + Reanimated rebuilt the touch pipeline on the UI thread to close that gap. Companies care because gesture quality is a brand signal — Instagram's swipe, Tinder's card flick, Apple Music's drag are products in themselves.

---

## Mental Model

Two clocks: the **JS clock** (event loop, can stall on a heavy render) and the **UI clock** (Choreographer/CADisplayLink, ticks at refresh rate). Legacy gestures lived on the JS clock. Modern gestures (Gesture Handler 2 + Reanimated worklets) live on the UI clock — they keep ticking even if the JS thread is busy parsing JSON or running React reconciliation.

A useful image: the gesture pipeline is a rope between user finger and pixel. Every JS hop adds a knot. Worklets remove the knots.

---

## Internal Working (2026 Context)

```
Touch event (OS)
    │
    ▼
RNGestureHandlerModule (native)         ← UIGestureRecognizer / MotionEvent
    │
    ├── recognizer state machine (BEGAN/ACTIVE/END/FAIL/CANCEL)
    │
    ▼
Worklet runtime (UI thread)             ← onBegin / onUpdate / onEnd
    │
    ├── mutate SharedValue via JSI
    │
    ▼
Reanimated UI runtime per-frame loop
    │
    ├── re-run useAnimatedStyle worklet
    │
    ▼
ShadowNode prop update (Fabric)         ← synchronous on UI thread
    │
    ▼
Native view prop applied
    │
    ▼
Frame submitted at refresh rate
```

Key 2026 specifics:
- On **Bridgeless**, gesture handler events use JSI to call into the worklet runtime synchronously.
- **Fabric** lets Reanimated bypass the legacy `setNativeProps` path; updates are applied to ShadowNodes directly, then committed.
- **React Compiler** doesn't touch worklets (the Reanimated Babel plugin extracts them before Compiler runs).
- **Static Hermes**: when worklets are typed (TS), Static Hermes can AOT-compile them, shaving startup cost for pages with many animations.

---

## Modern Implementation (Code)

```tsx
// SwipeableRow.tsx — production swipe-to-delete with conflict-aware composition
import {
  Gesture,
  GestureDetector,
  GestureType,
} from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  runOnJS,
} from 'react-native-reanimated';
import { useRef } from 'react';

type Props = {
  onDelete: () => void;
  scrollGesture?: GestureType; // pass parent FlashList scroll handle
  children: React.ReactNode;
};

const DELETE_THRESHOLD = -100;

export function SwipeableRow({ onDelete, scrollGesture, children }: Props) {
  const translateX = useSharedValue(0);

  const pan = Gesture.Pan()
    .activeOffsetX([-15, 15])     // horizontal-only intent
    .failOffsetY([-10, 10])       // yield to vertical scroll
    .onUpdate((e) => {
      'worklet';
      translateX.value = Math.min(0, e.translationX);
    })
    .onEnd(() => {
      'worklet';
      if (translateX.value < DELETE_THRESHOLD) {
        translateX.value = withTiming(-500, { duration: 200 }, (finished) => {
          if (finished) runOnJS(onDelete)();
        });
      } else {
        translateX.value = withSpring(0);
      }
    });

  const composed = scrollGesture
    ? Gesture.Simultaneous(pan, scrollGesture)
    : pan;

  const animStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
  }));

  return (
    <GestureDetector gesture={composed}>
      <Animated.View style={animStyle}>{children}</Animated.View>
    </GestureDetector>
  );
}
```

Notes:
- `'worklet'` directive marks UI-thread code.
- `runOnJS(onDelete)` to call back into JS for state updates.
- `activeOffsetX` / `failOffsetY` resolves the conflict with vertical scroll declaratively — no `waitFor` ref dance.

---

## Comparison

| Property | Legacy `PanResponder` | Gesture Handler 2 + Reanimated |
|---|---|---|
| Thread | JS | UI |
| Latency | 16–50ms JS-bound | <8ms (UI clock) |
| Composition | imperative refs | declarative `Simultaneous/Race/Exclusive` |
| Survives JS jank | ❌ | ✅ |
| 120fps capable | ❌ | ✅ |
| TS support | weak | first-class (Reanimated 4) |
| Status (2026) | [DEPRECATED] for new code | default |

| Reanimated 2 | Reanimated 3 | Reanimated 4 (2025–2026) |
|---|---|---|
| Worklets via Babel | Layout animations | Skia + canvas animations |
| Shared values | `Sensor`, `Keyframe` | Layout anim interruption |
| Manual cleanup | Auto cleanup | Better worklet error stacks |

---

## Production Usage

- **Swipe-to-delete** in lists (chat, email).
- **Drag-to-reorder** (Trello cards, Spotify playlist).
- **Pinch-to-zoom** (image viewer with double-tap reset).
- **Bottom sheets** (`@gorhom/bottom-sheet` is built on Gesture Handler + Reanimated).
- **Swipe navigation** (`react-native-screens` + Gesture Handler).
- **Custom carousels** with snap behavior.

Scaling: standardize a small set of "blessed" gesture patterns in your design system. Custom gestures are bug magnets — share the implementation across the org.

---

## Hands-On Exercise

1. **Implementation:** Build a draggable bottom sheet with three snap points (collapsed/half/expanded), velocity-based snapping, and a content `ScrollView` that takes over scrolling when the sheet is fully expanded.
2. **Debugging:** A swipeable row inside a vertical FlashList sometimes "swallows" the vertical scroll. Diagnose (likely missing `failOffsetY` or wrong `activeOffsetX` polarity).
3. **Architecture:** design a gesture system for an e-commerce product detail page with: pinch-to-zoom on hero image, vertical scroll, horizontal swipe between images. Resolve all conflicts declaratively.
4. **Optimization:** an animation drops to 30fps on Android mid-tier during a heavy JS task. Make it stay at 60fps using worklets.

---

## Common Mistakes

- Forgetting `'worklet'` directive on a gesture callback → it falls back to JS thread silently.
- Calling `setState` from inside a worklet without `runOnJS` → crash.
- Reading a regular ref inside a worklet → crash or stale data; use shared values.
- Animating layout props (`width`, `height`, `top`) instead of `transform` → triggers Yoga relayout on every frame.
- Chaining `.simultaneousWithExternalGesture(scrollRef)` without also setting `activeOffsetX` → both gestures fire on every touch, jittering.
- Using `Animated` (the built-in API, no native driver) for gesture-driven animation → JS-bound, will jank.

---

## Production Red Flags

- **"We use PanResponder for our slider"** → JS-thread gesture in 2026 is a deprecation smell.
- **"We disabled animations for performance"** → wrong fix; the animation library was misused.
- **No worklet directive in gesture callbacks across the codebase** → silent JS fallback, you're paying bridge cost without knowing.
- **`useEffect`-driven animations** instead of `useAnimatedStyle` → bypasses the UI-thread runtime.

---

## Performance & Metrics (MANDATORY)

- **FPS:** worklet-driven gestures should hold refresh-rate FPS even with the JS thread blocked. Test by spinning JS in a tight loop while gesturing.
- **TTI:** Reanimated/Gesture Handler add ~100ms to startup on cold launch (worklet runtime init). Acceptable on modern hardware; on Android Go, worth profiling.
- **Memory:** shared values are tiny (boxed primitives). Worklet code is duplicated into the UI runtime — keep them small.
- **Thread:** UI thread does the animation work; if a worklet is heavy (synchronous JSON parse, big array map) it jankifies — keep them <2ms.
- **Bundle:** Reanimated + Gesture Handler ~150KB combined gzipped. Worth it.
- **Battery:** native-driven animations are GPU-friendly; the cost is the same as native iOS/Android animations.
- **Optimization strategies:** avoid `withSpring` on layout props, prefer `transform` + `opacity`; don't allocate inside `useAnimatedStyle`; batch shared value updates.

---

## Metrics That Matter

- Touch-to-paint latency (P50/P95)
- Gesture frame drops per session (Sentry)
- ANR rate during gesture-heavy interactions
- Battery delta on animation-rich screens

---

## Decision Framework

| Need | Pick |
|---|---|
| Custom touch interaction | Gesture Handler 2 |
| Animation triggered by gesture | Reanimated worklet |
| Mount/unmount animation | `entering=`/`exiting=` (Reanimated 3+) |
| Layout reorder anim | `layout={LinearTransition}` |
| Lottie / pre-baked animation | Lottie + Reanimated trigger |
| 2D canvas / shaders | RN Skia (Q3) |
| Simple `Animated.View.fadeIn` | Reanimated still preferred; legacy `Animated` only with `useNativeDriver: true` |

When NOT to use Reanimated: a one-off opacity transition with `LayoutAnimation.configureNext` is fine for tiny apps; otherwise standardize on Reanimated.

---

## Senior-Level Insight

The architectural insight is that **interaction quality is a thread-isolation problem**, not an animation-library problem. Once you accept that the JS thread cannot be trusted to keep up with 120Hz input, every gesture/animation question becomes "what runs on which thread?" Reanimated and Gesture Handler are the canonical answer in 2026, but the *concept* (UI-thread runtime + shared state via JSI) generalizes — VisionCamera frame processors, Skia graphics, react-native-skia/draw — all use the same pattern. A senior engineer who internalizes the worklet model can reason about any new RN library that promises 60/120fps.

Organizationally: prevent worklet sprawl by centralizing complex gestures (bottom sheets, swipe rows, image viewers) in the design system; enforce `'worklet'` directive via ESLint rule.

---

## Real-World Scenario

**Symptom:** Card-stack swipe (Tinder-style) feels great on iPhone 15 but stutters on Pixel 4a at the apex of velocity flicks.
**Investigation:** Perfetto trace shows UI thread saturated for 80ms during release; Reanimated worklet doing `Math.atan2` and trig per frame.
**Root Cause:** Worklet was recomputing rotation matrix and shadow values from scratch each frame using expensive math.
**Fix:** Pre-compute lookup tables in the worklet's outer scope (`const sinTable = ...`); cache rotation in a shared value updated only on velocity change, not every frame.
**Lesson:** Worklets run on UI thread; that's not a free pass. Profile them like native code.

---

## Production Failure Story

**Incident:** A retail app's product carousel gesture froze the app for ~2 seconds whenever a low-stock toast was shown mid-swipe.
**Impact:** ~12% of swipe sessions during a flash sale resulted in users dropping the gesture and bouncing.
**Investigation:** Sentry showed a spike in slow frames correlated with toast displays. JS thread was busy rendering a heavy toast component (icon library, shadow, blur backdrop).
**Root Cause:** Gesture animation was running fine on UI thread; toast itself was fine. But the **`onEnd` callback used `runOnJS` to dispatch a Redux action**, which ran on the busy JS thread and didn't return for ~2s. The gesture was technically over, but the next gesture couldn't start because the recognizer was waiting for JS to acknowledge.
**Fix:** Move the analytics dispatch into a debounced, non-blocking call; reduce toast cost. Add a `requestAnimationFrame` boundary so gesture state isn't blocked on Redux dispatch.
**Prevention:** Code review rule: any `runOnJS` callback in a gesture must be O(1) and non-blocking; route heavy work through a queue.

---

## Debugging Checklist

1. Verify `'worklet'` directive in every gesture callback (lint rule).
2. Check `GestureHandlerRootView` wraps your app root.
3. On Android, ensure `MainActivity` extends `ReactActivity` and gesture handler is properly initialized.
4. Use **Reanimated DevTools** (Reanimated 4) to inspect shared values live.
5. Toggle "Slow Animations" in dev menu to visually inspect.
6. Profile worklet cost with `console.log` in dev (only — strip in prod).
7. If gestures feel laggy: confirm `useNativeDriver: true` if any legacy `Animated` is in the same screen.
8. Check for nested `GestureDetector` and use composition primitives instead.

---

## Advanced / Internal Knowledge

- Reanimated installs a **second JS runtime** (the "UI runtime") on the UI thread. Worklets are serialized at build time (Babel plugin), then materialized in the UI runtime via `ReanimatedRuntimeManager`.
- Shared values are JSI HostObjects with reference semantics; reads/writes go through atomic operations to prevent torn reads across threads.
- Gesture Handler 2 implements gestures as state machines with explicit transitions (UNDETERMINED → BEGAN → ACTIVE → END/FAIL/CANCEL). Composition operators are state-machine combinators.
- On iOS, recognizers are `UIGestureRecognizer` subclasses; on Android, they sit on a custom `MotionEvent` dispatcher because Android's framework doesn't expose composable recognizers.
- Reanimated 4's layout animation interruption requires the Fabric renderer; on legacy arch it falls back to non-interruptible animations.

---

## 2026 AI Tip

- AI is **good at**: scaffolding gesture composition, suggesting `activeOffsetX` polarity, generating swipe-to-dismiss patterns.
- AI is **bad at**: knowing when a worklet is too heavy or when conflict resolution will fail in subtle multi-touch scenarios. Test on device.
- **Hallucination risk:** older models suggest Reanimated 1 / 2 APIs (`Animated.timing` style). Always verify against current Reanimated docs.
- **Prompt pattern:** "Write a Reanimated 4 + Gesture Handler 2 swipeable row with these snap points, this conflict resolution, and worklet-only animation."
- **Agentic workflow:** have the agent generate a Maestro test that records frame timing on a real device and asserts P95 frame drop count < threshold.

---

## Related Topics

- S4 threading model, JSI
- S7 perf — 60/120fps targeting
- Reanimated layout animations (entering/exiting)
- `@gorhom/bottom-sheet`
- VisionCamera frame processors (worklets in another domain)

---

## Interview Follow-Up Questions

- How would you implement a draggable list reorder with snap-back-on-drop?
- What's the precise difference between `simultaneousWithExternalGesture` and `requireExternalGestureToFail`?
- Why does `runOnJS` exist, and when is it dangerous?
- How would you debug a gesture that fires but the animation doesn't move?
- What changes about gesture handling under Bridgeless mode?

---

## Memory Hook

**"Gestures on UI clock, JS only when state must change."** Worklets do the dance; JS only writes the diary entry afterwards.

## Revision Notes

> Gesture Handler 2 = native composable recognizers; Reanimated 3/4 = UI-thread worklet runtime. `'worklet'` directive is mandatory. Resolve gesture conflicts declaratively with `activeOffsetX/failOffsetY` and composition operators — never with imperative refs.

---

---

### Q3. React Native Skia — when and how to drop down to a 2D canvas

---

## Difficulty
- Advanced

## Interview Frequency
- Common (when role mentions custom UI, charts, games, generative graphics)

## Prerequisites
- Q2 (Reanimated worklets), basic graphics concepts (paths, paints, shaders)

## TL;DR
React Native Skia gives you Google's Skia 2D graphics library (the same engine behind Chrome and Flutter) as React components, with Reanimated-driven worklet animations — use it for charts, custom drawing, shaders, and anything Yoga + RN primitives can't render at frame rate.

---

## 30-Second Interview Answer

> "Skia is the 2D graphics library underneath Chrome and Flutter. `@shopify/react-native-skia` exposes it as RN components — `<Canvas>`, `<Circle>`, `<Path>`, `<Shader>` — that render via the GPU on a separate Skia thread. You reach for it when Views + Yoga can't express your UI at 60fps: charts with thousands of data points, signature pads, custom progress rings, generative art, image filters, even small games. Reanimated integrates so animation values drive Skia paths on the UI/Skia thread without JS round-trips."

---

## 2-Minute Practical Answer

The core question is: **can I express this with Views?** If yes, do that — Yoga + Fabric is well-trodden. If you need:
- Many lightweight shapes (>100 elements that animate together)
- Pixel-precise drawing (signatures, freehand)
- Shaders / filters / blurs / gradients beyond what `expo-blur` gives you
- Charts with smooth interpolation between data updates
- Custom progress indicators / loaders

…then Views fail (each becomes a full ShadowNode + native view, expensive at scale) and you should drop to Skia.

API shape:

```tsx
<Canvas style={{ flex: 1 }}>
  <Circle cx={100} cy={100} r={50} color="hotpink" />
  <Path path={pathFromPoints(points)} color="black" style="stroke" strokeWidth={3} />
</Canvas>
```

Animations integrate with Reanimated:

```tsx
const cx = useSharedValue(100);
// gesture or animation drives cx
<Canvas><Circle cx={cx} cy={100} r={50} color="hotpink" /></Canvas>
```

Skia reads the shared value on the Skia thread per frame. No re-render of the React tree.

---

## 5-Minute Architecture Answer

Skia adds a third runtime to the picture:

```
JS Runtime ────► UI Runtime (Reanimated) ────► Skia Runtime
                                                 │
                                                 ▼
                                            GPU (Metal/Vulkan/OpenGL)
```

- **Skia thread** runs an offscreen GPU command buffer recorder. The `<Canvas>` component owns a `SkiaSurface`. Each animation frame, Skia replays the scene description against the GPU.
- **Drawing model**: declarative React tree → Skia translates to immediate-mode GPU commands. There's no shadow tree per shape; Skia is a render-to-texture pipeline, fundamentally different from Yoga/Fabric's view tree.
- **Picture vs Canvas modes**: Skia can pre-record a `SkPicture` (immutable scene) and replay it cheaply. Use `<Canvas mode="continuous">` for animations, `<Canvas mode="default">` for static-ish scenes.
- **Reanimated bridge**: Skia values can be Reanimated shared values directly; Skia subscribes and re-paints on change without JS thread involvement.
- **Image / video integration**: Skia can sample frames from a `react-native-vision-camera` frame processor, apply shaders, and present back — used for live filters, AR-lite effects, document scanning.
- **Skia Web (2026)**: same API renders to Canvas/WebGL on RN Web, so chart components share code across mobile and web.

---

## The "Why"

Yoga + Fabric is optimized for **layout-driven UIs**: rectangles, text, images, with declarative box model. It's terrible at **paint-driven UIs**: thousands of vector primitives, freehand lines, shader effects. Each `<View>` allocates a ShadowNode, runs Yoga measurement, mounts a native view — for 1000 chart points that's 1000 of each. Skia treats the whole canvas as a single native view + GPU texture; 1000 shapes are just GPU draw calls. Companies care because charts, signatures, custom progress, and visual polish are increasingly product differentiators that can't be shipped with Views alone.

---

## Mental Model

Yoga = Word document (paragraphs, tables, layout reflow).
Skia = Photoshop canvas (pixels, brushes, layers).

Use the right tool. A pie chart with animated slice transitions is Photoshop. A settings list is Word.

---

## Internal Working (2026 Context)

Skia in RN 2026:

```
React tree (<Canvas>, <Circle>, <Path>, ...)
    │
    ▼
Skia React reconciler                    ← maintains a Skia-native scene graph
    │
    ▼
SkSurface (per Canvas)
    │
    ├── Reanimated shared values subscribed by primitives
    │
    ▼
Skia render loop on Skia thread          ← Choreographer-driven on Android, CADisplayLink iOS
    │
    ▼
Metal / Vulkan / OpenGL command buffer
    │
    ▼
GPU
```

2026 specifics:
- **Fabric integration**: `<Canvas>` is a Fabric component; sizing/layout participates in Yoga normally.
- **Reanimated 4** added bidirectional value sharing — Skia's animation primitives (`useClock`, `useValue`) and Reanimated shared values are interoperable.
- **Static Hermes** doesn't affect Skia (it's C++ all the way down).
- **visionOS** support added — Skia compiles against Apple's Metal on visionOS for spatial 2D content.

---

## Modern Implementation (Code)

```tsx
// AnimatedRing.tsx — production progress ring with smooth value interpolation
import { Canvas, Path, Skia, vec, BlurMask } from '@shopify/react-native-skia';
import {
  useDerivedValue,
  useSharedValue,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { useEffect } from 'react';

type Props = { progress: number; size?: number; stroke?: number };

export function AnimatedRing({ progress, size = 120, stroke = 12 }: Props) {
  const animated = useSharedValue(0);

  useEffect(() => {
    animated.value = withTiming(progress, { duration: 600, easing: Easing.out(Easing.cubic) });
  }, [progress, animated]);

  const path = useDerivedValue(() => {
    const p = Skia.Path.Make();
    const r = (size - stroke) / 2;
    const c = size / 2;
    p.addArc({ x: c - r, y: c - r, width: r * 2, height: r * 2 }, -90, 360 * animated.value);
    return p;
  });

  return (
    <Canvas style={{ width: size, height: size }}>
      <Path path={path} color="#22c55e" style="stroke" strokeWidth={stroke} strokeCap="round">
        <BlurMask blur={2} style="solid" />
      </Path>
    </Canvas>
  );
}
```

Notes:
- `useDerivedValue` builds a fresh Skia `Path` whenever `animated` changes — runs on UI thread.
- The `Canvas` re-paints on Skia thread; React tree doesn't re-render.
- `<BlurMask>` applies a real Skia blur (not a pseudo-blur trick).

---

## Comparison

| Need | Use |
|---|---|
| Layout-driven UI | Views + Yoga |
| Static SVG icon | `react-native-svg` |
| Animated SVG / many shapes | RN Skia |
| Charts (line/bar/pie) | Victory Native XL (built on Skia) |
| Lottie animation | Lottie (own renderer; Skia for custom) |
| 3D / WebGL | `react-three-fiber/native` |
| Camera filters | Skia + VisionCamera frame processors |
| Signature pad | Skia (`Path` + Pan gesture) |

| Library | Tech | Strength | Weakness |
|---|---|---|---|
| RN Skia | Skia C++ | full 2D power, GPU, shaders | bundle size (+~3MB native), learning curve |
| react-native-svg | native SVG | declarative SVG | slow with many elements |
| Lottie | bodymovin runtime | After Effects exports | fixed assets only |

---

## Production Usage

- **Wealthsimple, Robinhood-style charts** — line charts with smooth scrubbing.
- **Signature capture** — onboarding, KYC.
- **Custom loaders / splash animations**.
- **Story creators** — text overlays, stickers, filters (Instagram-style).
- **Receipt previews** — document rendering with custom layouts.
- **Map overlays** with custom shapes (when `react-native-maps` overlays are insufficient).

Scaling: keep Skia scenes small per Canvas; use multiple `<Canvas>` instances rather than one giant one for unrelated visuals — Skia's batching is per-surface.

---

## Hands-On Exercise

1. **Implementation:** build a candlestick chart with 200 candles, smooth zoom/pan via Gesture Handler, and tooltip on tap.
2. **Debugging:** a Skia Canvas paints once but won't animate; figure out why (likely missing `useDerivedValue` or passing a static path).
3. **Architecture:** design a "story editor" with text, stickers, filters, and undo/redo using Skia.
4. **Optimization:** an animated chart drops frames when data updates; use `Skia.Path.MakeFromSVGString` caching to avoid path rebuilding.

---

## Common Mistakes

- Trying to mix `<View>` and `<Canvas>` siblings expecting them to overlap perfectly with stacking — use `<Canvas>` sized to the screen and draw into it; or place `<View>` on top with absolute positioning.
- Re-creating Skia objects (`Skia.Path.Make()`) inside the React render — do it inside `useDerivedValue` or `useMemo`.
- Forgetting that Skia text needs `useFonts` or font loading — text won't render and you'll see nothing.
- Using Skia for a settings screen because it looks "modern" — wrong tool, kills accessibility and inflates bundle.
- Not handling pixel density (`PixelRatio.get()`) for crisp lines — strokes look fuzzy.

---

## Production Red Flags

- **"We rebuilt our entire UI in Skia for performance"** → over-engineering; you just lose accessibility, native input, RTL handling, and gain bundle bloat.
- **Skia inside FlashList items** with per-item animations → re-evaluate; one Canvas per row is heavy.
- **No font preloading strategy** → first text frame is invisible.

---

## Performance & Metrics (MANDATORY)

- **FPS**: Skia + Reanimated routinely hits 120Hz on modern devices; on older Android (2020-) it can struggle with many primitives. Profile.
- **TTI**: Skia native binary ~3MB adds ~50-100ms to cold start. Measurable but acceptable.
- **Memory**: SkSurface allocations are GPU memory; many large Canvases blow VRAM. One full-screen Canvas + a few small ones is fine.
- **Thread**: Skia thread is GPU-bound; doesn't compete with JS or UI thread for work, but does compete for GPU bandwidth with image decoding.
- **Bundle**: ~3MB native, ~80KB JS gzipped.
- **Battery**: GPU-accelerated; comparable to native animations. Continuous animations (e.g. always-running loaders) drain battery — gate them on visibility.
- **Optimization**: pre-build paths; use `<Picture>` for static portions; downsample for low-end devices.

---

## Metrics That Matter

- Skia Canvas FPS (custom RUM)
- GPU memory usage on long sessions
- Cold start delta with/without Skia in bundle
- Frame drops correlated with Skia-heavy screens

---

## Decision Framework

| Use case | Use Skia? |
|---|---|
| Settings screen | No |
| Static icon | No (SVG) |
| Custom progress ring | Yes |
| Chart with animation | Yes |
| Signature pad | Yes |
| Story creator | Yes |
| Game-like UI | Yes |
| 3D scene | No (use react-three-fiber) |
| One-off splash logo | Lottie or SVG |

When NOT to use: small apps where every MB matters; teams without graphics expertise; UI that's purely layout.

---

## Senior-Level Insight

The deeper story: **RN's UI primitives are a layout abstraction; Skia is a paint abstraction**. Modern mobile apps need both. Treating them as alternatives is wrong; treating them as complementary tools (Skia for visual content; Views for layout, input, accessibility) is right. The mental shift is the same one HTML/CSS engineers make when they reach for `<canvas>` for a chart but keep the rest of the page in DOM.

Org-level: keep Skia behind a small set of well-tested components (Chart, Ring, Sparkline, Signature, FilterCanvas). Don't let every team write raw Skia code; the abstraction surface is wide and easy to misuse.

---

## Real-World Scenario

**Symptom:** A custom progress ring stutters at 30fps on a budget Android device.
**Investigation:** Profiler shows the ring's `useDerivedValue` rebuilds the entire `Path` each frame, allocating a new `SkPath`.
**Root Cause:** Path rebuild is fine math-wise but allocates GPU resources every frame.
**Fix:** Switch to `useDerivedValue` returning only the sweep angle and pass it to `<Path path={staticArc} start={0} end={angle} />` (Skia supports parametric path trimming).
**Lesson:** Allocation patterns matter on the Skia thread just like on any GPU pipeline.

---

## Production Failure Story

**Incident:** A trading app's live chart screen ran out of GPU memory and crashed iOS app on iPad after ~30 minutes of use.
**Impact:** ~5% of iPad sessions in the affected build; long-session traders lost positions visualization.
**Investigation:** Instruments → Allocations showed monotonic growth in Skia surfaces.
**Root Cause:** Each chart re-mount (on tab switch + back) created a new `SkSurface` but the previous one wasn't released because a closure held a reference in a memoized callback.
**Fix:** Use `useCanvasRef` and explicit dispose in cleanup; audit all Skia object lifecycles.
**Prevention:** Add a memory regression test: scripted nav between screens N times, assert Skia memory bounded.

---

## Debugging Checklist

1. Is `<Canvas>` actually on screen and sized? (check via inspector)
2. Are Skia objects allocated outside render? (`useDerivedValue` / `useMemo`)
3. Are fonts loaded before text renders? (`useFonts`)
4. On Android, is the device's GPU driver up to date? (Skia uses Vulkan when available)
5. Profile with **Xcode GPU Frame Capture** for iOS; **Android GPU Inspector** for Android.
6. Check for memory leaks via Instruments / Android Studio Profiler.
7. Reduce primitives count and re-test to isolate scaling issue.

---

## Advanced / Internal Knowledge

- Skia uses **Vulkan** on Android (when available) and **Metal** on iOS. Falls back to OpenGL on older devices.
- The Skia React reconciler is a custom one (not React DOM / RN), purpose-built for Skia's scene graph.
- `<Picture>` records draw commands into an `SkPicture` for replay — like a display list. Use for static portions of complex scenes.
- Skia shaders are written in **SkSL** (Skia Shading Language) — basically GLSL. Custom shaders unlock effects impossible in vanilla CSS/SVG.
- Skia text rendering uses the same shaping engine (HarfBuzz) as Chrome — full international/RTL support.

---

## 2026 AI Tip

- AI is **good at**: scaffolding chart components, generating Skia path math, suggesting shader patterns from natural language ("make a wavy gradient").
- AI is **bad at**: GPU memory lifecycles, performance tuning of paint pipelines. Always profile.
- **Hallucination risk:** AI sometimes mixes web Canvas API with Skia API — verify against `@shopify/react-native-skia` docs.
- **Prompt pattern:** "Write a Skia component that animates a line chart with Reanimated shared values for `data: number[]`, with smooth interpolation between data updates."
- **Agentic workflow:** generate the chart, then use Maestro + screenshot diffing to verify visual correctness across iOS/Android.

---

## Related Topics

- Q2 Reanimated worklets
- VisionCamera frame processors
- `react-three-fiber/native` for 3D
- `react-native-svg` for static SVG

---

## Interview Follow-Up Questions

- When would you NOT use Skia for a chart?
- How does Skia's threading model interact with Fabric's commit phase?
- What's the difference between `<Canvas>` and `<Picture>`?
- How would you debug a Skia memory leak on iOS?
- Walk through how a Reanimated shared value drives a Skia primitive without re-rendering the React tree.

---

## Memory Hook

**"Yoga lays out boxes; Skia paints pixels."** Reach for Skia when boxes can't paint fast enough.

## Revision Notes

> RN Skia = GPU-accelerated 2D drawing; use for charts, signatures, generative graphics; integrates with Reanimated; ~3MB native bundle hit; never replaces Views for layout.

---

---

### Q4. Styling at scale — NativeWind vs Unistyles vs StyleSheet

---

## Difficulty
- Intermediate

## Interview Frequency
- Common (asked when role mentions design systems or scale)

## Prerequisites
- React component composition, design system basics

## TL;DR
`StyleSheet.create` is the baseline (compiled, cheap). NativeWind brings Tailwind's utility-first DX to RN with build-time extraction; Unistyles is RN-native, runtime-themed, with theme-switching, breakpoints, and platform variants — pick by team familiarity and theming complexity.

---

## 30-Second Interview Answer

> "RN's `StyleSheet.create` is essentially a frozen object hashed at module load — fine for static styles, but it doesn't help with theming, dark mode, breakpoints, or DRY. NativeWind compiles Tailwind class strings to RN styles at build time — great for teams already on Tailwind for web. Unistyles is RN-native, designed for theming with reactive `useStyles` hooks, runtime breakpoint resolution, and zero re-renders on theme switch via JSI. For a new app in 2026, I default to Unistyles 2/3 for theming-heavy designs and NativeWind for cross-platform monorepos that share a Tailwind config with web."

---

## 2-Minute Practical Answer

Three choices, three philosophies:

1. **`StyleSheet`** — built-in. Define styles as objects, reference by `styles.foo`. Compiled into IDs at module load. Fastest at runtime; weakest DX. No theming, no breakpoints, no cascading.
2. **NativeWind** — Tailwind for RN. Write `<View className="flex-1 p-4 bg-slate-900">`. A Babel/Metro plugin extracts class strings at build time and produces RN styles. Theming via Tailwind config + dark mode via `dark:` prefix. Cross-platform with RN Web because both speak Tailwind.
3. **Unistyles** — RN-native, runtime-reactive. Define a `unistyles` theme object; use `useStyles(stylesheet)` to get themed styles. Built-in breakpoints, platform variants, automatic theme switching without re-render (it patches native props via JSI). 2026's default for serious design systems.

Decision: monorepo with web on Tailwind → NativeWind. RN-only with serious theming + breakpoints → Unistyles. Tiny app or perf-critical → StyleSheet.

---

## 5-Minute Architecture Answer

Each system trades off three axes:
- **DX** (how easy to write/maintain)
- **Runtime cost** (per render style resolution)
- **Theming/responsive power** (dark mode, breakpoints, locale, accessibility)

**StyleSheet** wins runtime, loses DX/theming. **NativeWind** is build-time extraction so runtime is comparable to StyleSheet; DX is excellent if your team knows Tailwind; theming is via Tailwind config (good but limited at runtime). **Unistyles** has runtime cost (theme resolution per render), but uses JSI to apply theme changes at the native layer without React re-renders — net cost very low after warm-up.

For a design system at scale, you also want:
- **Tokens** (colors, spacing, radii) as the single source of truth — both NativeWind (Tailwind config) and Unistyles (theme object) support this; StyleSheet does not.
- **Variants** (button.primary, button.ghost) — Unistyles has first-class `variants`; NativeWind via class composition; StyleSheet via manual switch.
- **Breakpoints** — Unistyles built-in; NativeWind via Tailwind breakpoints (limited on RN — no media query, dimensions API instead); StyleSheet manual.
- **Dark mode** — Unistyles + NativeWind both support; StyleSheet manual.
- **RTL** — RN has built-in RTL flipping for `start/end` properties; both libs respect it.

Cross-platform: NativeWind shines for monorepos with RN + RN Web both on Tailwind. Unistyles 3 (2026) added RN Web support but it's newer.

---

## The "Why"

Inline styles + raw `StyleSheet` works for prototypes but explodes at design-system scale. You end up with: duplicated color literals, inconsistent spacing, no dark mode, no responsive breakpoints, no theme switching, no platform variants. Companies with 100+ screens need a system. The two main approaches (utility-first via NativeWind, themed-runtime via Unistyles) reflect different team cultures (web-cross-trained vs mobile-native).

---

## Mental Model

- StyleSheet = CSS in `<style>` blocks: cheap, dumb.
- NativeWind = Tailwind classes: composable utility, build-time.
- Unistyles = CSS-in-JS with a theme provider: reactive, runtime, powerful.

---

## Internal Working (2026 Context)

- **StyleSheet.create**: at module-load, produces an object with numeric IDs for each style. The native bridge / Fabric maps IDs to style props. Effectively zero runtime cost per render.
- **NativeWind**: Babel plugin parses `className` strings at build time. Converts to RN styles array `[{ flex: 1, padding: 16, ... }]`. Runtime is similar to StyleSheet. `useColorScheme` hook drives dark mode by selecting the right variant at render.
- **Unistyles**: at theme registration, builds a theme tree. `useStyles(stylesheet)` returns memoized styles for the current theme/breakpoint. On theme change, Unistyles uses JSI to patch native props directly on existing views — no React re-render. This is the key 2026 perf trick.

Threading: all three resolve at JS render time; styles are passed to Fabric's commit phase. Unistyles' theme switching bypasses React entirely on update — it's a JSI-level optimization.

---

## Modern Implementation (Code)

**StyleSheet (baseline):**

```tsx
import { StyleSheet, View, Text } from 'react-native';

export function Card({ title }: { title: string }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>{title}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { padding: 16, borderRadius: 12, backgroundColor: '#0f172a' },
  title: { color: '#f8fafc', fontSize: 18, fontWeight: '600' },
});
```

**NativeWind:**

```tsx
import { View, Text } from 'react-native';

export function Card({ title }: { title: string }) {
  return (
    <View className="p-4 rounded-xl bg-slate-900 dark:bg-slate-50">
      <Text className="text-lg font-semibold text-slate-50 dark:text-slate-900">{title}</Text>
    </View>
  );
}
```

**Unistyles:**

```tsx
import { createStyleSheet, useStyles } from 'react-native-unistyles';
import { View, Text } from 'react-native';

export function Card({ title }: { title: string }) {
  const { styles } = useStyles(stylesheet);
  return (
    <View style={styles.card}>
      <Text style={styles.title}>{title}</Text>
    </View>
  );
}

const stylesheet = createStyleSheet((theme, rt) => ({
  card: {
    padding: theme.spacing.md,
    borderRadius: theme.radii.lg,
    backgroundColor: theme.colors.surface,
    width: { xs: '100%', md: '50%' },
  },
  title: { color: theme.colors.text, fontSize: theme.typography.lg, fontWeight: '600' },
}));
```

The Unistyles version is theme-reactive, breakpoint-aware (`{ xs, md }`), and switches between light/dark/AMOLED without React re-renders.

---

## Comparison

| Property | `StyleSheet` | NativeWind | Unistyles |
|---|---|---|---|
| Runtime cost | ~0 | ~0 (build-time) | low (JSI-optimized) |
| Theming | manual | Tailwind config + dark | first-class, runtime |
| Breakpoints | manual | limited (RN has no media queries) | first-class |
| Variants | manual | class composition | first-class |
| Dark mode | manual | `dark:` prefix | automatic |
| RN Web compat | yes | excellent | good (v3) |
| TS support | OK | with types plugin | excellent |
| Bundle | 0 | small | small |
| Learning curve | none | tailwind | small RN-native |

---

## Production Usage

- **Cross-platform monorepo (RN + RN Web + Next.js)**: NativeWind wins for shared Tailwind config.
- **RN-only enterprise app with brand themes / white-label**: Unistyles wins.
- **Tiny app, single dev**: StyleSheet is fine.
- **Design system package consumed by many apps**: Unistyles' theme provider model scales.

Scaling pitfalls: in NativeWind, runaway class strings hurt readability — establish component-level abstractions. In Unistyles, deeply nested theme objects hurt onboarding — flatten where possible.

---

## Hands-On Exercise

1. **Implementation:** build a `Button` component with `primary | ghost | destructive` variants in all three systems.
2. **Debugging:** in NativeWind, classes don't apply on iOS only — diagnose (likely missing Babel plugin or Metro config).
3. **Architecture:** design a theme system that supports light/dark + brand themes for 3 white-label apps.
4. **Optimization:** measure render perf of a 100-card screen across the three systems with Reassure.

---

## Common Mistakes

- Inline `style={{ ... }}` everywhere → no memoization, allocates each render. Even with React Compiler, prefer named styles.
- Mixing NativeWind classes with `style={...}` haphazardly — works but hurts maintainability.
- Defining Unistyles `createStyleSheet` inside a component body — re-runs each render. Must be module-level.
- Hard-coding colors instead of theme tokens — kills dark mode and white-labeling.
- Using `Dimensions.get('window')` for responsive — doesn't react to rotation/foldables; use Unistyles' breakpoints or `useWindowDimensions`.

---

## Production Red Flags

- **No theme tokens** in a multi-screen app → instant tech-debt smell.
- **Hard-coded `#fff` / `#000`** → no dark mode path.
- **Per-component dark-mode `if`s** → should be expressed as a single themed style.
- **Mixing all three styling libs** in one codebase → migration was abandoned half-way.

---

## Performance & Metrics (MANDATORY)

- **FPS**: styling resolution happens at render; all three are fine. The differentiator is **theme switching** — Unistyles' JSI patch avoids the re-render cascade.
- **TTI**: NativeWind's build-time extraction adds slight Metro time; runtime nil. Unistyles' theme registration adds a few ms at startup. Negligible.
- **Memory**: tiny in all cases; theme objects are KB scale.
- **Thread**: pure JS; no UI thread impact unless theme switch triggers re-renders (Unistyles avoids this).
- **Bundle**: NativeWind ~50KB, Unistyles ~80KB.
- **Optimization**: prefer module-level styles; use Compiler-friendly pure renders; measure theme switch cost on slow devices.

---

## Metrics That Matter

- Render time per screen (Reassure)
- Theme switch time (custom telemetry)
- Bundle size delta vs StyleSheet baseline

---

## Decision Framework

| Situation | Pick |
|---|---|
| New RN-only app, theming-heavy | Unistyles |
| Monorepo with Tailwind on web | NativeWind |
| Tiny utility app | StyleSheet |
| Already on styled-components | continue, but evaluate Unistyles for new code |
| White-label multi-brand app | Unistyles |
| Marketing landing screens with web parity | NativeWind |

Migration cost: StyleSheet → Unistyles is mechanical (object → `createStyleSheet`); StyleSheet → NativeWind is a design-thinking shift (object → class strings). Don't mix systems long-term.

---

## Senior-Level Insight

Styling decisions look small but compound. A bad system means every dark-mode bug, every accessibility-color-contrast fix, every brand refresh is a multi-day refactor. The right framing is: **styling is part of your design-system architecture**. Treat the choice with the same rigor as your state management library. The wrong choice is recoverable but expensive at 100+ screens.

The 2026 specific insight: Unistyles 3's JSI-based theme switching is a **categorical improvement** — instant dark mode, instant brand swap, no flash. NativeWind doesn't have an equivalent because Tailwind's mental model is build-time. Pick based on which axis matters more for your business.

---

## Real-World Scenario

**Symptom:** Toggling dark mode on a settings screen takes ~600ms with visible flash.
**Investigation:** React DevTools Profiler shows the entire screen re-renders, including 50+ components reading `useColorScheme`.
**Root Cause:** Custom `ThemeContext` re-renders all subscribers on theme change.
**Fix:** Migrate to Unistyles, whose theme switch patches native props via JSI without re-rendering. Switch becomes instant.
**Lesson:** Theme distribution is an architecture problem, not a CSS problem.

---

## Production Failure Story

**Incident:** A white-label fintech released a new client brand and discovered ~30 screens with hard-coded brand colors that didn't update. App store reviewers rejected the build for branding mismatch.
**Impact:** 1-week launch delay; embarrassing to commercial team.
**Investigation:** Codebase audit found 200+ literal color strings.
**Root Cause:** No tokens system; each engineer used hex literals.
**Fix:** Migrate to Unistyles with theme tokens; lint rule banning hex literals outside the theme file.
**Prevention:** Token-only styling enforced by ESLint + design-system component library; brand-swap test in CI.

---

## Debugging Checklist

1. NativeWind: verify Babel plugin in `babel.config.js` and Metro config.
2. Unistyles: verify `Unistyles.configure({ ... })` ran before any `useStyles` call.
3. Check `useColorScheme()` returns correct value on platform.
4. Verify theme tokens exist for all colors used.
5. For mysterious style misses: log resolved style at render and compare to expectation.
6. Use React DevTools Inspector to see applied styles per element.

---

## Advanced / Internal Knowledge

- `StyleSheet.create` returns an object where each value is a numeric ID; the native side resolves IDs to style props during view creation. This is why mutating `styles.foo` after creation is undefined behavior.
- NativeWind's Babel plugin walks JSX, finds `className`, parses Tailwind tokens, generates style objects, and rewrites JSX. It also injects a runtime for dark-mode reactivity.
- Unistyles 2/3 wraps the theme provider in a singleton with a JSI binding; theme switches publish updates via the binding, and Unistyles patches view props on the UI thread.
- All three libs ultimately produce RN style objects passed to Fabric, which then maps to native UIView/Android View properties.

---

## 2026 AI Tip

- AI is **good at**: converting StyleSheet to NativeWind classes; generating themed Unistyles stylesheets.
- AI is **bad at**: choosing the right axis for *your* org. Pushes back: "tell me about your team's web stack and theming needs."
- **Hallucination risk:** AI sometimes uses Tailwind utilities that don't exist in NativeWind (e.g. CSS-only properties).
- **Prompt pattern:** "Convert this component from StyleSheet to Unistyles with theme tokens for these colors and breakpoints xs/md/lg."

---

## Related Topics

- Design tokens
- Reanimated layout animations (style transitions)
- Accessibility colors / contrast (S19)
- RTL handling

---

## Interview Follow-Up Questions

- How does Unistyles avoid re-renders on theme change?
- What's the runtime cost of NativeWind vs StyleSheet?
- How would you set up a white-label app with three brand themes?
- What lint rules would you add to enforce a token-based design system?
- Why might `Dimensions.get('window')` be wrong for responsive layout?

---

## Memory Hook

**"StyleSheet is dumb-fast, NativeWind is build-time, Unistyles is JSI-themed."**

## Revision Notes

> Pick by theming needs and team stack. Always use tokens, never literal colors. Unistyles for theming-heavy RN-only; NativeWind for cross-stack Tailwind shops; StyleSheet for tiny apps.

---

---

### Q5. Edge-to-edge layouts, SafeArea, and keyboard handling

---

## Difficulty
- Intermediate

## Interview Frequency
- Common (every production app hits these)

## Prerequisites
- RN core View/StyleSheet basics, platform differences (iOS notch, Android navigation bar)

## TL;DR
Modern apps render edge-to-edge under translucent system bars on iOS (notch / Dynamic Island) and Android 15+ (mandatory). Use `react-native-safe-area-context` to inset content; `react-native-keyboard-controller` for jank-free keyboard avoidance.

---

## 30-Second Interview Answer

> "Apple has required edge-to-edge for years; Android 15 made it mandatory. That means your app draws under the status bar and navigation bar, and you must inset interactive content yourself. `react-native-safe-area-context` provides `useSafeAreaInsets()` returning `{top, right, bottom, left}` driven by native. The built-in `KeyboardAvoidingView` is unreliable across platforms; `react-native-keyboard-controller` runs keyboard animations on the UI thread, mirrors the iOS keyboard frame on Android, and provides hooks like `useKeyboardHandler` for synchronized animations."

---

## 2-Minute Practical Answer

Three concerns, three tools:

1. **Safe area** (notch, Dynamic Island, status bar, home indicator, Android nav bar) → `react-native-safe-area-context`. Wrap app in `<SafeAreaProvider>`; use `useSafeAreaInsets()` (hook) or `<SafeAreaView edges={['top','bottom']}>` (component) to apply padding/margin. The built-in `SafeAreaView` from `react-native` is iOS-only and limited; always prefer the community library.
2. **Edge-to-edge on Android 15+** → `<StatusBar translucent />` + `<NavigationBar />` translucent + apply `paddingBottom: insets.bottom`. From Android 15, your `MainActivity` must opt in (or rather, you can't opt out). Expo SDK 51+ handles this by default.
3. **Keyboard** → `react-native-keyboard-controller`. Provides `<KeyboardAvoidingView>` (drop-in replacement, but UI-thread driven), `<KeyboardStickyView>` (pinned to keyboard top), `useKeyboardHandler` (worklet hook for custom animations). The built-in `KeyboardAvoidingView` is brittle on Android and choppy on iOS.

---

## 5-Minute Architecture Answer

The interplay:

```
┌─────────────────────────────────────┐
│ Status bar / Dynamic Island / notch │ ← top inset
├─────────────────────────────────────┤
│                                     │
│        Your app's draw area         │
│        (edge-to-edge canvas)        │
│                                     │
├─────────────────────────────────────┤
│ Keyboard (when shown)               │ ← keyboard inset
├─────────────────────────────────────┤
│ Home indicator / nav bar            │ ← bottom inset
└─────────────────────────────────────┘
```

- **Insets are dynamic**: rotation, foldables, multitasking on iPad, split-screen on Android all change them. Hooks re-render automatically on change.
- **Keyboard is special**: keyboard appearance is animated by the OS (iOS uses CADisplayLink-paced animation; Android uses WindowInsets animation API since 11). To avoid jank, your layout animation must run on the UI thread synchronized with the OS animation. `react-native-keyboard-controller` does this; legacy `KeyboardAvoidingView` does not.
- **Edge-to-edge** is mandatory on Android 15+ (API 35+); apps targeting it must draw under system bars. Old `fitsSystemWindows="true"` opt-out is gone. This makes `SafeAreaProvider` non-negotiable.
- **iOS Dynamic Island** doesn't change top inset (still status bar height) but interactive Live Activities can; ensure your top-region UI doesn't overlap Live Activity targets.
- **visionOS** introduces "ornaments" and immersive spaces — your safe area logic mostly carries over but with extra spatial considerations.

---

## The "Why"

Mobile screens have hardware "intrusions": notches, cameras, home indicators, navigation bars. Treating these as part of the draw area produces a polished look but requires explicit content insets. The keyboard is the most disruptive overlay — it can hide a form's submit button, and naive avoidance code produces visible jank that reads as "cheap" to users. Companies care because polished safe-area + keyboard handling is a hallmark of professional apps; broken behavior here is one of the most common cited reasons for poor app store ratings.

---

## Mental Model

Think of the screen as a frame with adjustable margins. The OS dictates the margins; your app must respect them. Padding must be **dynamic**: rotation changes top/right/bottom/left; keyboard appearance changes bottom.

---

## Internal Working (2026 Context)

- **`react-native-safe-area-context`** uses native `UIView.safeAreaInsets` (iOS) and `WindowInsetsCompat` (Android). Updates flow through a native event when the inset changes. The `<SafeAreaProvider>` is a React Context that distributes the latest insets to consumers.
- **`react-native-keyboard-controller`** installs UI-thread workers that subscribe to keyboard frame updates via native APIs (iOS: `UIResponder` keyboard notifications synced with `CADisplayLink`; Android 11+: `WindowInsetsAnimationCallback`). Worklet hooks (`useKeyboardHandler`) run on the UI runtime so animations are jank-free even when JS is busy.
- On **Bridgeless + Fabric**, inset changes trigger a Fabric commit; keyboard frame updates flow through JSI directly to Reanimated worklets.

---

## Modern Implementation (Code)

```tsx
// App.tsx — root setup
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { KeyboardProvider } from 'react-native-keyboard-controller';
import { StatusBar } from 'expo-status-bar';

export function App() {
  return (
    <SafeAreaProvider>
      <KeyboardProvider>
        <StatusBar style="auto" translucent />
        <RootNavigator />
      </KeyboardProvider>
    </SafeAreaProvider>
  );
}
```

```tsx
// LoginScreen.tsx — safe area + keyboard handling
import { View, TextInput, Text, Pressable } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { KeyboardAwareScrollView } from 'react-native-keyboard-controller';

export function LoginScreen() {
  const insets = useSafeAreaInsets();

  return (
    <KeyboardAwareScrollView
      style={{ flex: 1, backgroundColor: '#0f172a' }}
      contentContainerStyle={{
        paddingTop: insets.top + 24,
        paddingBottom: insets.bottom + 24,
        paddingHorizontal: 24,
      }}
      bottomOffset={20}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={{ color: 'white', fontSize: 28, marginBottom: 24 }}>Sign in</Text>
      <TextInput placeholder="Email" autoComplete="email" inputMode="email" />
      <TextInput placeholder="Password" secureTextEntry autoComplete="password" />
      <Pressable onPress={submit}><Text>Continue</Text></Pressable>
    </KeyboardAwareScrollView>
  );
}
```

Notes:
- `KeyboardAwareScrollView` from `react-native-keyboard-controller` (not the legacy `react-native-keyboard-aware-scroll-view`).
- `bottomOffset` ensures the focused input has space above the keyboard.
- Insets cover top/bottom; horizontal usually fine without insets unless landscape.

---

## Comparison

| Concern | Built-in | Modern (2026) |
|---|---|---|
| Safe area | `SafeAreaView` (iOS-only) | `react-native-safe-area-context` |
| Keyboard avoidance | `KeyboardAvoidingView` (brittle) | `react-native-keyboard-controller` |
| Status bar | `StatusBar` from RN | `expo-status-bar` (recommended) |
| Edge-to-edge on Android | manual via styles.xml | Expo handles by default |
| Dimensions | `Dimensions.get` | `useWindowDimensions` (reactive) |

---

## Production Usage

- Every screen in a production app uses safe area insets (top/bottom at minimum).
- Forms, chat, comment composers all need keyboard-aware layouts.
- Edge-to-edge enables full-bleed images, immersive video, modern visual design.
- White-label apps need theme-aware status bar (`expo-status-bar` `style="auto"` adapts to bg).

---

## Hands-On Exercise

1. **Implementation:** build a chat composer that pins to keyboard top with a smooth animation, even with a long message list above it.
2. **Debugging:** on Android, the bottom system nav overlaps the floating action button — fix with insets.
3. **Architecture:** design a `Screen` HOC/wrapper used by every screen in the app that handles safe area + keyboard + status bar consistently.
4. **Optimization:** keyboard animation drops frames on a slow Android phone — switch from built-in `KeyboardAvoidingView` to `react-native-keyboard-controller` and measure.

---

## Common Mistakes

- Using built-in `SafeAreaView` from `react-native` (iOS-only, doesn't update reactively).
- Hardcoding `paddingTop: 44` for status bar (varies by device).
- Forgetting bottom inset for home indicator on iPhone X+.
- Wrapping every screen individually instead of in a layout component.
- Using `KeyboardAvoidingView` `behavior="padding"` on iOS and `"height"` on Android with no fallback for keyboard hide events.
- Ignoring `Dimensions` rotation (use `useWindowDimensions` instead).

---

## Production Red Flags

- **Top of screen content cut off by status bar** on Android 15+ → app didn't migrate to edge-to-edge.
- **Submit button hidden behind keyboard** → no keyboard handling.
- **Janky keyboard slide-up** → using JS-thread keyboard avoidance.
- **No consideration for foldables / iPad split-screen** → insets not respected.

---

## Performance & Metrics (MANDATORY)

- **FPS**: keyboard handling is the main perf risk; UI-thread keyboard controller keeps 60/120fps.
- **TTI**: SafeAreaProvider adds ~10ms; KeyboardProvider adds ~10ms. Negligible.
- **Memory**: tiny.
- **Thread**: keyboard worklets on UI thread.
- **Bundle**: `react-native-safe-area-context` ~30KB, `react-native-keyboard-controller` ~60KB. Worth it.
- **Battery**: nil incremental cost.
- **Optimization**: apply insets via a single `Screen` wrapper rather than per-component.

---

## Metrics That Matter

- Frame drops during keyboard animation
- Layout shift count on rotation (Sentry can sample)
- Crash-free sessions on Android 15+ (test for layout-related crashes)

---

## Decision Framework

| Situation | Use |
|---|---|
| Any screen with text inputs | `react-native-keyboard-controller` |
| Any screen, period | `useSafeAreaInsets` via wrapper |
| Status bar | `expo-status-bar` |
| Custom keyboard animation | `useKeyboardHandler` worklet |
| Form-heavy screen | `KeyboardAwareScrollView` |
| Modal with input | `KeyboardStickyView` |

---

## Senior-Level Insight

Edge-to-edge + safe area + keyboard handling are individually trivial but collectively a major source of low-quality apps. A `Screen` component in your design system that handles all three correctly *once* saves your team thousands of bugs over a product's lifetime. The senior insight is: **layout chrome (safe area, keyboard, status bar) is design-system infrastructure, not per-screen logic**. Centralize it.

Android 15+ mandatory edge-to-edge is a forcing function — apps that don't migrate will look broken. This is a 2026 deadline most teams underestimated.

---

## Real-World Scenario

**Symptom:** New iPhone 15 Pro Max users report the bottom button is "stuck behind the home bar".
**Investigation:** Inspector shows the button has `paddingBottom: 0`; legacy code from before Dynamic Island.
**Root Cause:** Bottom inset was hardcoded as 0 because original devs developed on iPhone 8.
**Fix:** Apply `paddingBottom: insets.bottom + 16` in the screen wrapper.
**Lesson:** Always use dynamic insets; never hardcode.

---

## Production Failure Story

**Incident:** A banking app's transfer screen hid the "Confirm" button under the keyboard on Android Pixel 7. ~8% of transfer flows abandoned.
**Impact:** Estimated $50k/day in lost transactional revenue.
**Investigation:** Bug repro: open keyboard, button gone, no scroll.
**Root Cause:** Used built-in `KeyboardAvoidingView` `behavior="padding"` which works on iOS but adds zero on Android (Android handles via window resize, but the `Dialog` modal context broke that resize).
**Fix:** Migrated to `react-native-keyboard-controller`'s `KeyboardAwareScrollView`; fix shipped via OTA in 4 hours.
**Prevention:** Standardized form components in design system that always wrap in `KeyboardAwareScrollView`; visual regression tests for forms with keyboard open.

---

## Debugging Checklist

1. Confirm `<SafeAreaProvider>` and `<KeyboardProvider>` at app root.
2. Use Inspector to see live inset values per screen.
3. Test on real devices: iPhone with notch, iPhone with Dynamic Island, Android with gesture nav, Android with 3-button nav, foldable.
4. Test rotation: ensure insets update.
5. Test keyboard open/close on all input types (email, numeric, secure).
6. Sentry: filter slow/frozen frames by screen name to find keyboard-related jank.
7. Visually inspect on Android 15 (mandatory edge-to-edge).

---

## Advanced / Internal Knowledge

- iOS `safeAreaInsets` is a `UIEdgeInsets` propagated through the view hierarchy; it changes on rotation, status-bar visibility, multitasking modes.
- Android `WindowInsetsCompat` includes `systemBars()`, `displayCutout()`, `ime()` (keyboard) — all separate inset categories.
- `react-native-keyboard-controller` uses `WindowInsetsAnimationCallback` (Android 11+) and `UIResponder` keyboard notifications (iOS) and synchronizes with `Choreographer` / `CADisplayLink` for jank-free animation.
- Bridgeless mode delivers keyboard events via JSI — Reanimated can subscribe directly.
- visionOS: `safeAreaInsets` includes ornament space; immersive spaces have different rules.

---

## 2026 AI Tip

- AI is **good at**: scaffolding `Screen` wrappers, suggesting inset usage.
- AI is **bad at**: knowing platform-specific quirks (Android edge-to-edge mandate, Dynamic Island specifics) — verify against latest docs.
- **Hallucination risk:** AI may suggest deprecated `SafeAreaView` from `react-native` instead of community library.
- **Prompt pattern:** "Build a `Screen` wrapper component using `react-native-safe-area-context` and `react-native-keyboard-controller` that all my screens will use, with optional bottom-button slot pinned above the keyboard."

---

## Related Topics

- S5 Expo (StatusBar setup)
- S7 perf (frame drops on keyboard)
- S19 a11y (focus management with keyboard)
- React Compiler (no need for memoizing inset readers)

---

## Interview Follow-Up Questions

- Why is the built-in `SafeAreaView` insufficient?
- How does `react-native-keyboard-controller` achieve jank-free keyboard animation?
- What changed with Android 15 edge-to-edge?
- How would you handle insets on iPad split-screen?
- How do insets behave on visionOS?

---

## Memory Hook

**"Provider at the root, insets in the wrapper, keyboard on the UI thread."** Three rules, every screen.

## Revision Notes

> Use `react-native-safe-area-context` (not built-in SafeAreaView). Use `react-native-keyboard-controller` (not built-in KeyboardAvoidingView). Android 15+ requires edge-to-edge. Centralize all three in a `Screen` design-system component.

---

> **End of S3.** Cross-refs: S4 (Fabric, JSI, threading), S7 (FPS / TTI), S15 (native bridging for keyboard internals). Next deep section: [S08 State Management](S08-state-management.md).
