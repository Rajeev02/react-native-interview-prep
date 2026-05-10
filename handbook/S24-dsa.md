# S24 — DSA for Mobile Engineers

> LRU cache · sliding window · BFS/DFS · gesture FSM · top-K min-heap

DSA for mobile interviews focuses on **practical applications** — the data structures you'd actually use in an RN app. Each topic is grounded in a real mobile use case.

## Topics in this section

- [Q1. LRU cache (image cache use case)](#q1-lru-cache-image-cache-use-case)
- [Q2. Sliding window — longest substring without repeating chars](#q2-sliding-window--longest-substring-without-repeating-chars)
- [Q3. BFS / DFS — directory traversal](#q3-bfs--dfs--directory-traversal)
- [Q4. Gesture finite state machine (swipe-to-dismiss)](#q4-gesture-finite-state-machine-swipe-to-dismiss)
- [Q5. Top-K via min-heap (top trending hashtags)](#q5-top-k-via-min-heap-top-trending-hashtags)

---

## Q1. LRU cache (image cache use case)

### Difficulty
Intermediate

### Interview Frequency
Very common.

### Prerequisites
JS Map.

### TL;DR
Combine `Map` (preserves insertion order) with capacity check. On `get`, delete and re-insert to refresh recency. On `set`, evict oldest (`map.keys().next().value`) if at capacity. O(1) ops.

### 30-Second Interview Answer
"LRU cache: `Map` for ordering + capacity. `get` moves the key to the most-recent end (delete + re-set). `set` evicts the oldest key when over capacity. JS `Map` preserves insertion order — that's the trick. O(1) for both ops. Real use case: image cache for FlashList."

### 2-Minute Practical Answer

```ts
class LRU<K, V> {
  private cache = new Map<K, V>();
  constructor(private capacity: number) {}

  get(key: K): V | undefined {
    if (!this.cache.has(key)) return undefined;
    const val = this.cache.get(key)!;
    this.cache.delete(key);
    this.cache.set(key, val); // re-insert to mark as most-recent
    return val;
  }

  set(key: K, value: V): void {
    if (this.cache.has(key)) this.cache.delete(key);
    this.cache.set(key, value);
    if (this.cache.size > this.capacity) {
      const oldest = this.cache.keys().next().value as K;
      this.cache.delete(oldest);
    }
  }

  has(key: K) { return this.cache.has(key); }
  size() { return this.cache.size; }
}
```

### 5-Minute Architecture Answer
LRU is the foundation of:
- Image caches (expo-image uses LRU disk cache).
- TanStack Query's gcTime eviction.
- HTTP response caches.
- React Compiler's memoization (conceptually similar).

Implementation choices:
- **Map-based** (above) — clean, O(1), works in JS.
- **Doubly linked list + hashmap** — classic interview answer; same Big-O; more code.
- **WeakMap variant** — if values are objects you want garbage-collected when unreferenced elsewhere.

For RN 2026:
- expo-image's cache is LRU at the disk level.
- TanStack Query exposes `gcTime` for memory eviction.
- For custom caches (e.g., parsed SDUI schemas), `Map`-based LRU is enough.

Edge cases:
- Capacity 0 (degenerate; no caching).
- Same key re-set with different value (treat as update; refresh recency).
- TTL extension (LRU + expiry → LRU-with-TTL: tombstone or check on access).

### The "Why"
Image caches, response caches, and any bounded-memory store needs eviction policy. LRU is the most common.

### Mental Model
Cache = bounded ordered map; access updates position to "front."

### Internal Working (2026 Context)
- `Map` insertion order is spec-defined.
- V8 / JSC / Hermes all preserve it.
- Deletion + re-insertion is the canonical refresh pattern.

### Modern Implementation (Code)
See above. With TTL:

```ts
type Entry<V> = { value: V; expires: number };

class LRUWithTTL<K, V> {
  private cache = new Map<K, Entry<V>>();
  constructor(private capacity: number, private ttlMs: number) {}

  get(key: K): V | undefined {
    const entry = this.cache.get(key);
    if (!entry) return undefined;
    if (entry.expires < Date.now()) { this.cache.delete(key); return undefined; }
    this.cache.delete(key);
    this.cache.set(key, entry);
    return entry.value;
  }

  set(key: K, value: V): void {
    if (this.cache.has(key)) this.cache.delete(key);
    this.cache.set(key, { value, expires: Date.now() + this.ttlMs });
    if (this.cache.size > this.capacity) {
      const oldest = this.cache.keys().next().value as K;
      this.cache.delete(oldest);
    }
  }
}
```

### Comparison

| Cache | Eviction |
|---|---|
| LRU | Least Recently Used |
| LFU | Least Frequently Used |
| FIFO | First In First Out |
| TTL | Time-based |
| Random | Unbiased; rarely good |

### Production Usage
- expo-image disk cache.
- TanStack Query memory cache.
- Custom: parsed SDUI schemas, computed thumbnail metadata.

### Hands-On Exercise
Implement LRU; test capacity overflow; add TTL variant; benchmark vs object literal.

### Common Mistakes
- Forgetting to refresh recency on `get`.
- Using object literal (no insertion-order guarantee for non-string keys).
- Off-by-one on capacity (allow exactly N or N+1?).

### Production Red Flags
- Unbounded caches → memory bloat → crashes.
- Wrong eviction policy for workload (e.g., FIFO when LRU needed).

### Performance & Metrics
- Hit rate (target > 80% for warm workloads).
- Eviction rate.
- Memory footprint.

### Decision Framework
- Bounded memory + recency matters → LRU.
- Frequency matters more → LFU.
- Time-based → TTL.

### Senior-Level Insight
"Most cache bugs are about wrong eviction or no bounds. Pick LRU as default; add TTL if data goes stale."

### Real-World Scenario
**Symptom:** Image grid scroll causes OOM after 300+ scrolled images.
**Fix:** LRU cap of 200 images in memory; older ones evicted.

### Production Failure Story
**Incident:** Background image preloader leaked memory.
**Root cause:** Cache with no bounds.
**Fix:** LRU with capacity tied to device memory class.

### Debugging Checklist
1. Capacity bounded?
2. `get` refreshes recency?
3. Eviction order verified?

### Advanced / Internal Knowledge
- ARC (Adaptive Replacement Cache) blends LRU + LFU.
- W-TinyLFU used by Caffeine (Java); modern best-in-class.
- For RN, LRU is enough 95% of the time.

### 2026 AI Tip
AI generates LRU well. Verify capacity edge cases (0, 1, large).

### Related Topics
Q5, S07, S11.

### Interview Follow-Up Questions
- "Why does `Map` work here?"
- "How would you add TTL?"
- "When to use LFU?"

### Memory Hook
**"Map preserves order. Get refreshes. Set evicts oldest."**

### Revision Notes
> LRU = Map + capacity; get → delete + re-set; set → evict oldest if over cap; O(1) ops; image caches, query caches use it.

---

## Q2. Sliding window — longest substring without repeating chars

### Difficulty
Intermediate

### Interview Frequency
Very common.

### Prerequisites
Set / Map.

### TL;DR
Two pointers `l, r`; expand `r`, track chars in a Set. When duplicate, shrink `l` until duplicate gone. Track max window size. O(n) time, O(min(n, alphabet)) space.

### 30-Second Interview Answer
"Sliding window: two pointers, left and right. Expand right; if char already in window, shrink left until it's gone. Track max window size. Use Map of char → last index for O(1) jumps. O(n) time."

### 2-Minute Practical Answer

```ts
function lengthOfLongestSubstring(s: string): number {
  const lastIndex = new Map<string, number>();
  let max = 0;
  let left = 0;
  for (let right = 0; right < s.length; right++) {
    const c = s[right];
    if (lastIndex.has(c) && lastIndex.get(c)! >= left) {
      left = lastIndex.get(c)! + 1;
    }
    lastIndex.set(c, right);
    max = Math.max(max, right - left + 1);
  }
  return max;
}
```

### 5-Minute Architecture Answer
Sliding window is a pattern, not a single algorithm:
- **Variable window** — expand/shrink based on condition (above).
- **Fixed window** — size K; slide one step at a time.
- **Two pointers** — generic family; sliding window is a subset.

Mobile applications:
- Search debounce buffer (last K keystrokes).
- Network throttling (requests in last N seconds).
- Gesture velocity tracking (frames in window).
- Performance budget windows (e.g., FPS over last 60 frames).

For 2026 interview:
- Recognize the pattern (max/min subarray with constraints).
- Differentiate from prefix sum / DP.
- Know Set vs Map vs counter array variants.

### The "Why"
Common interview topic; foundation for many string + array problems.

### Mental Model
A window expands right, contracts left to maintain a constraint.

### Internal Working (2026 Context)
- JS `Map` and `Set` both O(1) average for this.
- `s.charCodeAt(i)` slightly faster than `s[i]` for hot loops.

### Modern Implementation (Code)
See above. Variant — max length where you can change at most K chars:

```ts
function characterReplacement(s: string, k: number): number {
  const count = new Map<string, number>();
  let left = 0;
  let maxCount = 0;
  let result = 0;
  for (let right = 0; right < s.length; right++) {
    const c = s[right];
    count.set(c, (count.get(c) ?? 0) + 1);
    maxCount = Math.max(maxCount, count.get(c)!);
    if (right - left + 1 - maxCount > k) {
      const lc = s[left];
      count.set(lc, count.get(lc)! - 1);
      left++;
    }
    result = Math.max(result, right - left + 1);
  }
  return result;
}
```

### Comparison

| Pattern | When |
|---|---|
| Sliding window | Contiguous subarray with constraint |
| Two pointers | Sorted array / palindrome |
| Prefix sum | Range sum queries |
| DP | Overlapping subproblems |

### Production Usage
- Rate limiters (requests in last N).
- Velocity calculators (gesture handlers).
- Streaming aggregates.

### Hands-On Exercise
Solve "longest substring without repeating," "longest with at most K distinct," "min window substring."

### Common Mistakes
- Not jumping `left` past the duplicate (just incrementing).
- Off-by-one in window size calc (`right - left + 1`).
- Forgetting `lastIndex.get(c)! >= left` check (stale entry from earlier window).

### Production Red Flags
- Nested loops where sliding window applies → O(n²) when O(n) possible.

### Performance & Metrics
- O(n) time.
- O(min(n, alphabet)) space.

### Decision Framework
- "Subarray / substring with constraint" → sliding window.
- Sorted + pair → two pointers.

### Senior-Level Insight
"Recognize the pattern fast. The trick is identifying the invariant the window maintains."

### Real-World Scenario
Rate limiter: allow N requests per 60s. Use sliding window of timestamps.

### Production Failure Story
Inefficient O(n²) sliding window in a search-as-you-type field caused jank on long queries; rewrote as O(n).

### Debugging Checklist
1. Window invariant clearly defined?
2. Left moves correctly on violation?
3. Edge: empty string, all same char?

### Advanced / Internal Knowledge
- Counter array (size 26 or 128) faster than Map for ASCII.
- Monotonic deque for sliding window max/min.

### 2026 AI Tip
AI solves these well; double-check edge cases (empty, length 1, all duplicates).

### Related Topics
Q1, Q3.

### Interview Follow-Up Questions
- "What if K characters can be replaced?"
- "How to find the actual substring, not just length?"
- "Time/space complexity?"

### Memory Hook
**"Two pointers. Expand right. Shrink left. Track max."**

### Revision Notes
> Sliding window: l/r pointers; expand right; shrink left when constraint violated; track max; Map for char → index gives O(1) jumps; O(n) time.

---

## Q3. BFS / DFS — directory traversal

### Difficulty
Intermediate

### Interview Frequency
Common.

### Prerequisites
Recursion, queue / stack.

### TL;DR
DFS = recursion (or explicit stack); BFS = queue. For directory traversal: BFS gives breadth-first listing; DFS goes deep first. Track visited (cycle detection — symlinks).

### 30-Second Interview Answer
"DFS uses recursion or a stack and goes deep before wide. BFS uses a queue and explores all neighbors at depth N before depth N+1. For directory traversal: BFS for shallow listings, DFS for full deep walks. Track visited paths to handle symlinks (cycles). For mobile-relevant variants: tree of UI components, JSON tree validation, navigation graph."

### 2-Minute Practical Answer

```ts
type FileNode = { name: string; isDir: boolean; children?: FileNode[] };

// DFS recursive
function dfs(node: FileNode, depth = 0): void {
  console.log(' '.repeat(depth * 2) + node.name);
  if (node.children) for (const c of node.children) dfs(c, depth + 1);
}

// DFS iterative
function dfsIter(root: FileNode): string[] {
  const stack: FileNode[] = [root];
  const result: string[] = [];
  while (stack.length) {
    const node = stack.pop()!;
    result.push(node.name);
    if (node.children) for (let i = node.children.length - 1; i >= 0; i--) stack.push(node.children[i]);
  }
  return result;
}

// BFS
function bfs(root: FileNode): string[] {
  const queue: FileNode[] = [root];
  const result: string[] = [];
  while (queue.length) {
    const node = queue.shift()!;
    result.push(node.name);
    if (node.children) for (const c of node.children) queue.push(c);
  }
  return result;
}
```

### 5-Minute Architecture Answer
Mobile uses for graph/tree algorithms:
- **React tree traversal** — finding a node by ID, computing layout.
- **Navigation stack** — DFS to find a route.
- **SDUI schema** — DFS to validate tree.
- **Image directory scan** — file system walk.
- **Reachability** — BFS for "shortest path between two nodes" (rare in mobile).

Cycle detection:
- For trees, no cycles by definition.
- For graphs (or symlinked dirs), use a visited Set.
- For navigation graphs (deep links), check before pushing.

Performance:
- DFS: O(n) time, O(h) space where h = depth.
- BFS: O(n) time, O(w) space where w = width.
- Trade-off: skinny tree → DFS cheaper; bushy tree → BFS expensive memory.

For 2026:
- Recursive DFS hits JS stack limit ~10k frames (Hermes); use iterative for very deep trees.
- `Array.shift` is O(n); use a real queue (e.g., index pointer) for big BFS.

### The "Why"
Foundation for tree/graph problems; common in coding rounds.

### Mental Model
Stack = depth (LIFO). Queue = breadth (FIFO).

### Internal Working (2026 Context)
- Hermes call-stack limit ~10–20k.
- `Array` as queue is O(n) per shift; use circular buffer or two-stack queue for hot paths.

### Modern Implementation (Code)
See above. Real queue:

```ts
class Queue<T> {
  private data: T[] = [];
  private head = 0;
  enqueue(x: T) { this.data.push(x); }
  dequeue(): T | undefined { return this.head < this.data.length ? this.data[this.head++] : undefined; }
  get length() { return this.data.length - this.head; }
}
```

### Comparison

| Algo | Order | Space | Use |
|---|---|---|---|
| DFS | Deep first | O(h) | Path-finding, schema walk |
| BFS | Breadth first | O(w) | Shortest path, level order |

### Production Usage
- React tree walking (devtools).
- Navigation stack search.
- File system scan (rare on mobile).

### Hands-On Exercise
Implement DFS + BFS on a JSON tree; find a node by ID with both.

### Common Mistakes
- Recursive DFS on huge tree → stack overflow.
- `Array.shift` for BFS → O(n²).
- Forgetting visited tracking on cyclic graphs.

### Production Red Flags
- Recursion without depth check.
- Naive BFS on large graphs.

### Performance & Metrics
- O(n) time for both.
- O(h) vs O(w) space difference matters at scale.

### Decision Framework
- Need shortest path → BFS.
- Memory-constrained, deep tree → DFS iterative.
- Validation walk → either, prefer iterative.

### Senior-Level Insight
"Iterative DFS with explicit stack is what you reach for in production code; recursive feels nice but breaks on deep trees."

### Real-World Scenario
Validating a deeply nested SDUI schema with 10k nodes: recursive Zod blew the stack; switched to iterative validation.

### Production Failure Story
Devtools tree walker recursed 50k deep; iOS crashed.
**Fix:** Iterative DFS with explicit stack.

### Debugging Checklist
1. Stack overflow risk?
2. Visited set for cycles?
3. Queue impl O(1) per op?

### Advanced / Internal Knowledge
- Bidirectional BFS for fast shortest-path.
- Iterative deepening (IDDFS) blends both.
- Topological sort for dependency graphs.

### 2026 AI Tip
AI does textbook DFS/BFS well. Verify iterative variant for large trees.

### Related Topics
Q4 (state machine), S04 (component tree).

### Interview Follow-Up Questions
- "Iterative DFS — how?"
- "BFS shortest path — show it."
- "Cycle detection — when needed?"

### Memory Hook
**"Stack deep. Queue wide. Visited for cycles."**

### Revision Notes
> DFS = stack/recursion; BFS = queue; track visited for cycles; iterative for deep trees; real queue (indexed) for perf; mobile uses: SDUI walk, navigation graph, devtools.

---

## Q4. Gesture finite state machine (swipe-to-dismiss)

### Difficulty
Advanced

### Interview Frequency
Common at gesture-heavy companies.

### Prerequisites
Q3, Reanimated basics.

### TL;DR
Model gesture lifecycle as states: `idle → tracking → committed | cancelled`. Each state has guards, entry/exit actions, and event handlers. Reanimated worklets implement the runtime.

### 30-Second Interview Answer
"Swipe-to-dismiss is naturally an FSM: states are idle, tracking, committed, cancelled. Events are gesture begin, update, end. Transitions have guards (velocity > threshold OR distance > threshold for commit). Reanimated worklet drives translation; on commit, animate off-screen and unmount; on cancel, snap back. FSM keeps the logic explicit and testable."

### 2-Minute Practical Answer

```ts
type State = 'idle' | 'tracking' | 'committed' | 'cancelled';
type Event = { type: 'begin' } | { type: 'update'; dx: number } | { type: 'end'; dx: number; vx: number };

const COMMIT_DISTANCE = 100;
const COMMIT_VELOCITY = 800;

function next(state: State, event: Event): State {
  switch (state) {
    case 'idle':
      return event.type === 'begin' ? 'tracking' : state;
    case 'tracking':
      if (event.type === 'end') {
        const shouldCommit = Math.abs(event.dx) > COMMIT_DISTANCE || Math.abs(event.vx) > COMMIT_VELOCITY;
        return shouldCommit ? 'committed' : 'cancelled';
      }
      return state;
    case 'committed':
    case 'cancelled':
      return 'idle';
  }
}
```

In Reanimated:
```tsx
const translateX = useSharedValue(0);
const gesture = Gesture.Pan()
  .onUpdate((e) => { translateX.value = e.translationX; })
  .onEnd((e) => {
    const commit = Math.abs(e.translationX) > COMMIT_DISTANCE || Math.abs(e.velocityX) > COMMIT_VELOCITY;
    if (commit) {
      translateX.value = withTiming(Math.sign(e.translationX) * SCREEN_WIDTH, { duration: 200 }, () => runOnJS(onDismiss)());
    } else {
      translateX.value = withSpring(0);
    }
  });
```

### 5-Minute Architecture Answer
Gestures get gnarly without explicit states:
- Multi-touch interactions overlap.
- Cancellation paths multiply (parent gesture takes over, ancestor scroll).
- Animations + state transitions need coordination.

FSM benefits:
- **Explicit transitions** — every state has known events / next-states.
- **Testable** — pure function `next(state, event)` is unit-testable without UI.
- **Visualizable** — diagrams clarify behavior.
- **Refactorable** — adding a state (e.g., `paused`) is a localized change.

For 2026:
- XState library is overkill for most RN gestures; hand-rolled FSM is fine.
- Reanimated 3+ Gesture API has built-in state model (`BEGAN | ACTIVE | END | CANCELLED`).
- `useAnimatedGestureHandler` deprecated; use `Gesture.Pan()` etc.

Common gestures modeled as FSMs:
- Swipe-to-dismiss (above).
- Pull-to-refresh.
- Pinch-to-zoom (`idle → pinching → zoomed → idle`).
- Long press (`idle → pressing → activated → idle`).

### The "Why"
Complex gestures without FSMs = bug factories.

### Mental Model
Each state knows what it can become; events fire transitions; entry/exit run side effects.

### Internal Working (2026 Context)
- Reanimated runs gestures on the UI thread (worklet).
- `runOnJS` to bridge state changes back.

### Modern Implementation (Code)
See above. With explicit FSM in worklet:

```tsx
const state = useSharedValue<State>('idle');
const gesture = Gesture.Pan()
  .onBegin(() => { 'worklet'; state.value = 'tracking'; })
  .onUpdate((e) => { 'worklet'; if (state.value === 'tracking') translateX.value = e.translationX; })
  .onEnd((e) => {
    'worklet';
    const commit = Math.abs(e.translationX) > COMMIT_DISTANCE;
    state.value = commit ? 'committed' : 'cancelled';
    if (commit) translateX.value = withTiming(SCREEN_WIDTH, {}, () => runOnJS(onDismiss)());
    else translateX.value = withSpring(0);
  });
```

### Comparison

| Approach | Pros | Cons |
|---|---|---|
| Hand-rolled FSM | Simple, fast | Manual |
| XState | Visualizer, devtools | Heavyweight |
| Implicit (useState) | Easiest start | Bugs scale |

### Production Usage
- Swipe actions in mail / lists.
- Pull-to-refresh.
- Modal dismissal gestures.

### Hands-On Exercise
Build swipe-to-dismiss with explicit FSM states; add `committing` state with mid-animation cancel.

### Common Mistakes
- Implicit state in multiple booleans (`isTracking`, `isCommitting`, `isCancelled`) → impossible states.
- No velocity check (only distance) → bad UX for fast flicks.
- Missing cancellation path (parent gesture interrupts).

### Production Red Flags
- Boolean soup for gesture state.
- Animations not interruptible.
- "Sometimes the swipe doesn't dismiss."

### Performance & Metrics
- 60fps during gesture.
- Cancellation responsiveness.

### Decision Framework
- Multi-step gesture → FSM.
- Single-trigger (tap) → no FSM needed.
- Coordinated multi-gesture → consider XState.

### Senior-Level Insight
"Gestures are state machines whether you draw them or not. Drawing them avoids bugs."

### Real-World Scenario
Lyft / Uber bottom sheets: position has states like `collapsed | half | expanded | dragging`. FSMs prevent invalid transitions (e.g., `expanded → dragging → expanded` is fine; `collapsed → expanded` skipping intermediate is forbidden).

### Production Failure Story
Mail app's swipe-to-archive sometimes dismissed without animation.
**Root cause:** Boolean state race; `isTracking` lingered.
**Fix:** Single FSM state variable; transitions enforced.

### Debugging Checklist
1. States enumerable + finite?
2. Transitions explicit?
3. Worklet vs JS coordination clear?
4. Cancellation path tested?

### Advanced / Internal Knowledge
- Hierarchical state machines (XState) for nested gestures.
- Statecharts for parallel states.
- Gesture coordination across siblings (waitFor, simultaneousHandlers).

### 2026 AI Tip
AI rarely models gestures as FSMs; it'll write boolean soup. Refactor.

### Related Topics
Q3, S07.

### Interview Follow-Up Questions
- "Why FSM over booleans?"
- "How does Reanimated worklet bridge to JS state?"
- "What if parent ScrollView intercepts?"

### Memory Hook
**"States explicit. Transitions guarded. Worklet drives. JS reacts."**

### Revision Notes
> Gesture lifecycle = FSM (idle → tracking → committed | cancelled); commit guard = distance OR velocity threshold; Reanimated worklet for runtime; hand-rolled FSM beats boolean soup.

---

## Q5. Top-K via min-heap (top trending hashtags)

### Difficulty
Advanced

### Interview Frequency
Common.

### Prerequisites
Heap basics.

### TL;DR
For top K: maintain a min-heap of size K; for each item, push if heap < K, else if item > heap.top, pop + push. O(n log K).

### 30-Second Interview Answer
"Top-K with a min-heap: keep K largest seen so far. For each new item, if heap size < K, push; else if item > heap.peek(), replace top. End: heap contains top K. O(n log K) time, O(K) space — beats sorting all n which is O(n log n)."

### 2-Minute Practical Answer

```ts
class MinHeap<T> {
  private data: T[] = [];
  constructor(private cmp: (a: T, b: T) => number) {}

  push(x: T) {
    this.data.push(x);
    this.bubbleUp(this.data.length - 1);
  }

  pop(): T | undefined {
    if (!this.data.length) return undefined;
    const top = this.data[0];
    const last = this.data.pop()!;
    if (this.data.length) { this.data[0] = last; this.sinkDown(0); }
    return top;
  }

  peek() { return this.data[0]; }
  size() { return this.data.length; }

  private bubbleUp(i: number) {
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (this.cmp(this.data[i], this.data[p]) < 0) {
        [this.data[i], this.data[p]] = [this.data[p], this.data[i]];
        i = p;
      } else break;
    }
  }

  private sinkDown(i: number) {
    const n = this.data.length;
    while (true) {
      const l = 2 * i + 1, r = 2 * i + 2;
      let smallest = i;
      if (l < n && this.cmp(this.data[l], this.data[smallest]) < 0) smallest = l;
      if (r < n && this.cmp(this.data[r], this.data[smallest]) < 0) smallest = r;
      if (smallest === i) break;
      [this.data[i], this.data[smallest]] = [this.data[smallest], this.data[i]];
      i = smallest;
    }
  }
}

function topK<T>(items: T[], k: number, score: (x: T) => number): T[] {
  const heap = new MinHeap<T>((a, b) => score(a) - score(b));
  for (const item of items) {
    if (heap.size() < k) heap.push(item);
    else if (score(item) > score(heap.peek()!)) { heap.pop(); heap.push(item); }
  }
  const result: T[] = [];
  while (heap.size()) result.push(heap.pop()!);
  return result.reverse(); // largest first
}
```

### 5-Minute Architecture Answer
Top-K is the streaming-friendly version of sorting:
- Sorting all = O(n log n) time, O(n) extra (or in-place).
- Top-K = O(n log K) time, O(K) extra. Massive win when K << n.
- Streaming: as items arrive, maintain running top-K.

Mobile use cases:
- Top trending hashtags from event stream.
- Top 5 most-pressed UI elements (analytics).
- Top K closest stores (geo).
- Top K largest images in cache (eviction candidates for LFU).

For 2026:
- JS doesn't have a built-in heap; hand-roll or use `js-heap` lib.
- Hermes is fast enough for K up to ~10k items in O(n log K).
- For huge n, consider server-side aggregation.

Variants:
- **Bottom-K** — flip to max-heap.
- **Top-K with TTL** — expire old items.
- **Distributed top-K** — each node tracks; merge at coordinator (handle ties carefully).

### The "Why"
Real algo applied to mobile telemetry / analytics / ranking.

### Mental Model
Min-heap of size K = "moving window of K winners." Anyone smaller than the smallest winner can't displace.

### Internal Working (2026 Context)
- Heap operations are O(log K).
- Hermes well-optimized for tight loops.

### Modern Implementation (Code)
See above. Streaming variant:

```ts
class TopKStream<T> {
  private heap: MinHeap<T>;
  constructor(private k: number, private score: (x: T) => number) {
    this.heap = new MinHeap<T>((a, b) => score(a) - score(b));
  }
  add(item: T) {
    if (this.heap.size() < this.k) this.heap.push(item);
    else if (this.score(item) > this.score(this.heap.peek()!)) { this.heap.pop(); this.heap.push(item); }
  }
  snapshot(): T[] {
    const arr: T[] = [];
    const copy = new MinHeap<T>((a, b) => this.score(a) - this.score(b));
    for (const x of [...(this.heap as any).data]) copy.push(x);
    while (copy.size()) arr.push(copy.pop()!);
    return arr.reverse();
  }
}
```

### Comparison

| Approach | Time | Space |
|---|---|---|
| Sort all → take K | O(n log n) | O(n) |
| Min-heap size K | O(n log K) | O(K) |
| Quickselect | O(n) avg | O(1) extra |
| Streaming heap | O(log K) per add | O(K) |

### Production Usage
- Trending feeds (server-side mostly).
- On-device: top-K cache eviction; top-K nearby items.

### Hands-On Exercise
Implement min-heap; solve top-K hashtags from a stream of 1M events.

### Common Mistakes
- Using max-heap (then top stays largest; can't peek smallest).
- Allowing heap > K size (then complexity slips to O(n log n)).
- Comparing wrong direction.

### Production Red Flags
- Sorting full data when top-K suffices.
- No heap when streaming.

### Performance & Metrics
- O(n log K) verified.
- Real benchmark vs full sort.

### Decision Framework
- K << n → heap.
- Need rank K only → quickselect.
- Streaming → heap (online).

### Senior-Level Insight
"Top-K is the algo most often confused with sort. Sort is overkill 90% of the time."

### Real-World Scenario
Analytics pipeline computed top 10 events per session by sorting full event list (~5k); switched to heap; saved CPU on low-end devices.

### Production Failure Story
Hashtag aggregator sorted full feed each time; lag spiked at peak.
**Fix:** Streaming top-K heap; maintained incrementally.

### Debugging Checklist
1. Min-heap (not max) for top-K?
2. Heap size capped at K?
3. Comparator direction correct?

### Advanced / Internal Knowledge
- Quickselect for one-shot top-K (not streaming) is O(n).
- Reservoir sampling for fair sampling (different problem).
- Count-min sketch for approximate frequency (huge streams).

### 2026 AI Tip
AI scaffolds heap correctly but often confuses min vs max for top-K. Verify direction.

### Related Topics
Q1, Q3.

### Interview Follow-Up Questions
- "Why min-heap for top-K?"
- "When to use quickselect instead?"
- "Streaming variant?"

### Memory Hook
**"Min-heap of K. Replace top when bigger comes. O(n log K)."**

### Revision Notes
> Top-K via min-heap of size K; push if size < K, else if item > peek replace; O(n log K) vs O(n log n) sort; mobile uses: trending, analytics, eviction.

---

> Cross-refs: S01 (data structures in JS), S07 (perf).
