# S2 — React 19+ and React Compiler

> Concurrent rendering · Actions · `use` · `useOptimistic` · Suspense · React Compiler (auto-memoization) · RSC for mobile

In 2026, React 19 patterns are mainstream and the React Compiler removes most manual memoization. Senior interviews probe **what changes in your code** and **what doesn't**.

## Topics in this section

- [Q1. React Compiler — what it is and how it changes your code](#q1-react-compiler--what-it-is-and-how-it-changes-your-code)
- [Q2. Concurrent rendering, transitions, `useDeferredValue`](#q2-concurrent-rendering-transitions-usedeferredvalue)
- [Q3. Actions, `useActionState`, `useFormStatus`, `useOptimistic`](#q3-actions-useactionstate-useformstatus-useoptimistic)
- [Q4. The `use` hook and Suspense for data on mobile](#q4-the-use-hook-and-suspense-for-data-on-mobile)
- [Q5. Reconciliation, Fiber, batching — the model behind it all](#q5-reconciliation-fiber-batching--the-model-behind-it-all)

---

## Q1. React Compiler — what it is and how it changes your code

### Difficulty
Intermediate → Advanced

### Interview Frequency
Very Common in 2026 — lead question for any React 19 / RN modernization round.

### Prerequisites
React rendering basics, hooks, memoization (`useMemo`, `useCallback`, `React.memo`).

### TL;DR
React Compiler is a **build-time tool** that auto-memoizes your components and hooks; in well-written code you delete most `useMemo` / `useCallback` / `memo` and get equivalent or better performance.

### 30-Second Interview Answer
"React Compiler is a Babel-like compiler that statically analyzes your components and emits memoized versions automatically. It infers stable values, hoists allocations, and inserts the equivalent of `useMemo`/`useCallback`/`React.memo` only where it provably helps. In React 19 + RN 0.76+, this means in idiomatic code you stop hand-writing memoization. You keep `useMemo` only when the compiler bails out — which it tells you about via the `react-compiler` ESLint plugin."

### 2-Minute Practical Answer
What the compiler does:
- Treats components and hooks as pure (per the Rules of React).
- For each render, computes a **dependency graph** of expressions.
- Caches stable subexpressions across renders, equivalent to wrapping them in `useMemo`/`useCallback`.
- Wraps components in an automatic `memo` when their props are stable.

What you do:
- Follow the Rules of React strictly (no mutation of props/state/refs you didn't create, no side effects in render).
- Run the **`react-compiler` ESLint plugin** — it flags non-compilable functions ("compiler bailouts").
- Stop adding `useMemo`/`useCallback` defensively. Add them **only** when the linter says the compiler skipped a function.

What stays your job:
- `useEffect` deps still matter (compiler doesn't fix bad deps; it would change behavior).
- Expensive **side effects** (network, storage) — compiler doesn't memoize those.
- `useMemo` for **referential stability across stores** (e.g., a Redux selector returning new objects) — compiler can help, but you still need stable selectors.

### 5-Minute Architecture Answer
Pre-compiler React performance was a manual optimization game:
- Did you remember `useMemo` on this object literal?
- Did you wrap that callback in `useCallback`?
- Did you `React.memo` this child?

This was **error-prone** (premature memoization is also a bug — over-memoizing creates GC pressure and hides bugs) and **inconsistent** across codebases.

The compiler reframes the problem: treat memoization as a **compiler optimization**, not a runtime API. The developer expresses intent (the code), the compiler decides where caching pays off.

Tradeoffs to discuss in interviews:
- **Wins:** less code, fewer bugs (forgotten/wrong deps), consistent perf, easier reviews.
- **Costs:** harder mental model when debugging ("did the compiler memoize this?"), build-time cost, requires Rules-of-React compliance.
- **Bailouts:** dynamic patterns (assigning to refs in render, mutating state, indirect function calls) cause the compiler to skip a function — performance reverts to "no memoization" for that scope.

In RN 0.76+, the compiler is enabled via Babel preset; Expo SDK 51+ ships it on by default. In production apps, Meta reports double-digit % render-count reductions on real screens; the typical practical benefit is "stop thinking about memoization" rather than a flat speedup.

### The "Why"
- React's hand-memoization tax was real engineering time + a recurring source of bugs.
- React 19 doubles down on concurrent features that benefit from stable references (transitions, Suspense).
- The compiler is the bridge: idiomatic code that performs well by default.

### Mental Model
The compiler is like a **JIT for renders**. You write the readable version; the compiler emits the fast version. Same shift as Hermes' bytecode vs source JS, just at the React layer.

### Internal Working (2026 Context)
- Implemented as a Babel plugin (`babel-plugin-react-compiler`).
- Uses an internal IR (HIR/MIR) to reason about effect-freeness and stability.
- Emits a `useMemoCache` runtime helper (small bookkeeping, much cheaper than nested `useMemo`).
- Bailouts logged at compile time + via the `react-compiler` ESLint rule.
- React DevTools Profiler shows memoized components; the new "Compiler" tab shows skipped functions.

### Modern Implementation (Code)

```tsx
// Pre-compiler (manual, defensive) — 2024-style
type Props = { ids: number[]; onSelect: (id: number) => void };

const ListPre = React.memo(function ListPre({ ids, onSelect }: Props) {
  const sorted = React.useMemo(() => [...ids].sort((a, b) => a - b), [ids]);
  const handle = React.useCallback(
    (id: number) => onSelect(id),
    [onSelect],
  );
  return (
    <FlashList
      data={sorted}
      keyExtractor={(id) => String(id)}
      renderItem={({ item }) => <Row id={item} onPress={handle} />}
    />
  );
});
```

```tsx
// 2026 with React Compiler — same perf, less code
type Props = { ids: number[]; onSelect: (id: number) => void };

export function List({ ids, onSelect }: Props) {
  const sorted = [...ids].sort((a, b) => a - b);
  return (
    <FlashList
      data={sorted}
      keyExtractor={(id) => String(id)}
      renderItem={({ item }) => (
        <Row id={item} onPress={() => onSelect(item)} />
      )}
    />
  );
}
```

The compiler infers `sorted` and the `renderItem` arrow are stable when `ids`/`onSelect` are stable, and skips re-renders accordingly.

ESLint config (always pair with the compiler):

```js
// eslint.config.js
import reactCompiler from 'eslint-plugin-react-compiler';
export default [
  { plugins: { 'react-compiler': reactCompiler },
    rules: { 'react-compiler/react-compiler': 'error' } },
];
```

### Comparison

| Aspect                | Manual memoization        | React Compiler           |
| --------------------- | ------------------------- | ------------------------ |
| Code volume           | High (`useMemo`/`useCallback` everywhere) | Low |
| Bug surface           | Wrong deps, missed memos  | Compiler bailouts (linted)|
| Predictability        | Depends on author         | Consistent across codebase |
| Debug story           | Read the code             | DevTools "Compiler" tab  |
| Works without         | Required for perf         | App runs fine, just slower |

### Production Usage
- Real teams report **30–60% fewer wasted renders** on list-heavy screens.
- Code review velocity improves: fewer "did you memoize this?" comments.
- Teams report **bigger wins from concurrent features** (transitions, Suspense) because compiler-stabilized props make them more effective.

### Hands-On Exercise
1. Take an existing screen with heavy `useMemo`/`useCallback` usage. Enable the compiler. Measure render count via DevTools.
2. Delete one `useMemo` at a time. Run the linter. Confirm no bailout warning.
3. Introduce an intentional Rules-of-React violation (mutate a prop). Watch the compiler bail out and the linter scream.

### Common Mistakes
- Keeping defensive `useMemo` everywhere "just in case" — defeats the point and adds noise.
- Ignoring linter bailouts — leaves compiler-disabled hot paths with no memoization at all.
- Assuming `useEffect` deps are auto-fixed — they aren't; bad deps still cause bugs.

### Production Red Flags
- Compiler enabled but linter not configured.
- Mutation patterns (`props.foo.bar = x`) still in the codebase.
- Heavy use of `useRef` to mutate render-time values.

### Performance & Metrics
- Render count: typically −30 to −60% on list/feed screens.
- JS thread time: small but consistent improvement; biggest gains on slow Android.
- Bundle size: compiler emits a small runtime helper (`useMemoCache`); negligible.

### Metrics That Matter
Wasted renders, JS thread CPU, frame drop %, TTI.

### Decision Framework
- New code in 2026 → compiler on.
- Brownfield → enable in non-critical screens first; iterate to remove manual memoization.
- Library author → make sure your hooks follow Rules of React; consumers' compiler will memoize call sites.

### Senior-Level Insight
The deeper change is cultural: stop reviewing for memoization, start reviewing for **purity and Rules-of-React compliance**. The compiler can only help if your code is honest about effects.

### Real-World Scenario
**Symptom:** A search screen re-renders the entire results list on every keystroke even after enabling the compiler.
**Investigation:** DevTools "Compiler" tab shows the `Results` component bailed out.
**Root cause:** `Results` mutated a `useRef`'d cache during render.
**Fix:** Move the cache update into a `useEffect` triggered by results.
**Lesson:** Compiler bailouts aren't subtle — they show up as zero memoization for that component.

### Production Failure Story
**Incident:** After enabling the compiler, an analytics event fired twice on every screen mount.
**Investigation:** The component logged the event in a `useMemo` (anti-pattern).
**Root cause:** With manual memoization, the `useMemo` ran rarely; with the compiler, it was hoisted differently.
**Fix:** Move the analytics call into `useEffect`.
**Prevention:** Treat any side effect outside `useEffect` as a bug; compiler will surface them.

### Debugging Checklist
1. Is the `react-compiler` ESLint rule clean?
2. DevTools → Compiler tab: which components were skipped?
3. Is the suspect component pure (no mutation in render)?
4. Are you fighting the compiler with manual `useMemo`s? Try removing them.

### Advanced / Internal Knowledge
- The compiler emits a per-component `useMemoCache(n)` array for stable values.
- It uses a "scope" abstraction (HIR) to find the smallest cached unit.
- Bailout granularity is per-function; one bad component doesn't disable the compiler globally.

### 2026 AI Tip
AI assistants still suggest `useMemo`/`useCallback` reflexively. After accepting AI code, run the linter and **delete** memoization the compiler can do for you. Inverse problem: AI sometimes writes mutation in render — review carefully.

### Related Topics
Q2 (transitions), Q5 (reconciliation), S7 (perf), S4 (Fabric — fewer renders means fewer commits).

### Interview Follow-Up Questions
- "What does the compiler do that you can't do by hand?"
- "What forces a compiler bailout?"
- "How do you debug a missed memoization?"
- "How does this interact with concurrent React?"

### Memory Hook
**"Compiler memoizes; you keep purity. Lint or it doesn't count."**

### Revision Notes
> React Compiler auto-memoizes pure components/hooks; delete manual `useMemo`/`useCallback`; pair with `react-compiler` ESLint; bailouts revert to no memoization for that scope.

---

## Q2. Concurrent rendering, transitions, `useDeferredValue`

### Difficulty
Advanced

### Interview Frequency
Very Common at Senior+.

### Prerequisites
React 18+ basics, scheduling intuition.

### TL;DR
Concurrent rendering lets React **interrupt and resume** work; `startTransition` / `useTransition` mark updates as low-priority so urgent input stays responsive; `useDeferredValue` debounces a derived value at React's scheduling layer.

### 30-Second Interview Answer
"React 18 introduced concurrent rendering — work is sliced and prioritized. `startTransition` marks an update as non-urgent; React keeps the previous UI visible and renders the new one in the background, interruptible by higher-priority input. `useDeferredValue` is the same idea but for a single value: React renders with the stale value first, then renders again with the fresh one when idle. Both unlock smooth typing into a search box that drives an expensive list."

### 2-Minute Practical Answer
The core problem: a state change can trigger a re-render that **takes longer than a frame**, blocking input. Pre-React 18 your only options were debouncing in user code or lifting expensive work out of render.

React 18+:
- **`useTransition`** wraps state updates: `const [pending, startTransition] = useTransition(); startTransition(() => setQuery(q));` The update is treated as low priority. `pending` lets you render a subtle indicator.
- **`useDeferredValue`** wraps a value: `const deferredQ = useDeferredValue(q);` React renders with the previous value first, schedules a second render with the new one. Useful when you don't own the setter (e.g., props).

In RN with the New Arch + RuntimeScheduler, this is fully cooperative — gestures and scrolling preempt transition work.

### 5-Minute Architecture Answer
Concurrent React's machinery:
- **Lanes** — each update is tagged with a priority lane (Sync, InputContinuous, Default, Transition, Idle).
- **Work loop** — React schedules render work via `MessageChannel` (web) / RuntimeScheduler (RN) and yields to the host every ~5ms.
- **Double buffering** — work-in-progress Fiber tree is built alongside the committed tree; only commits if it finishes.
- **Interruption** — higher-priority lanes restart render at the new state.

`startTransition` puts an update on the Transition lane. The previous tree stays committed; new tree builds in the background; commits when ready or restarts if a higher-priority update arrives.

In RN, this hands off cleanly to Fabric — commit/mount happen atomically when the new tree is ready, no tearing.

### The "Why"
- Real apps hit "search box that lags" problems daily. Debouncing in user code couples concerns and is awkward.
- Transitions move "what's urgent vs what's not" into a declarative API React can schedule against.

### Mental Model
Lanes = OS scheduler priorities for render work. Sync = "do it now"; Transition = "do it when nothing more important is happening."

### Internal Working (2026 Context)
- React 19 RuntimeScheduler integration in RN means transitions truly yield to gestures.
- Suspense boundaries inside a transition can show their **previous** content while loading, avoiding a fallback flash.
- Compiler-stabilized props help transitions avoid re-rendering already-rendered subtrees.

### Modern Implementation (Code)

```tsx
type Props = { items: Item[] };

export function SearchableList({ items }: Props) {
  const [query, setQuery] = useState('');
  const [pending, startTransition] = useTransition();

  const filtered = useDeferredValue(query)
    ? items.filter((i) => i.title.includes(query))
    : items;

  return (
    <View>
      <TextInput
        value={query}
        onChangeText={(text) => {
          // typing stays responsive; filter happens on Transition lane
          startTransition(() => setQuery(text));
        }}
      />
      {pending && <ActivityIndicator />}
      <FlashList
        data={filtered}
        renderItem={({ item }) => <ItemRow item={item} />}
        keyExtractor={(i) => i.id}
      />
    </View>
  );
}
```

### Comparison

| Tool                | Use when                                                              |
| ------------------- | --------------------------------------------------------------------- |
| `useTransition`     | You own the state setter and want to mark whole updates non-urgent    |
| `useDeferredValue`  | You receive a value as prop and want to defer renders depending on it |
| Manual debounce     | You want time-based throttling (per-keystroke), not priority-based    |

Debounce ≠ transition. Debounce delays the input itself; transitions render with the **fresh** input but at lower priority.

### Production Usage
- Search boxes, filter chips, tab switches that load heavy content.
- Suspense fallbacks inside `startTransition` show the previous screen until ready, eliminating loading flashes during navigation.

### Hands-On Exercise
1. Build a list of 5,000 items with a search input. Wrap `setQuery` in `startTransition`. Observe input remains responsive while filtering.
2. Combine with `useDeferredValue` on an expensive derived computation.
3. Add a `<Suspense>` boundary fetching details for the selected item; observe no fallback flash inside a transition.

### Common Mistakes
- Wrapping every `setState` in `startTransition` — defeats the priority model.
- Putting input value updates inside `startTransition` (then typing visibly lags).
- Using transitions for time-based throttling — wrong tool.

### Production Red Flags
- "We added `startTransition` and it didn't help." Usually means the expensive work is in a side effect, not in render.
- `useDeferredValue` on a primitive that doesn't drive expensive children — pointless.

### Performance & Metrics
- Input latency: bounded by frame budget under transitions.
- Render time: unchanged in total, but distributed and interruptible.
- Bundle: zero cost.

### Metrics That Matter
Input latency P95, frame drop %, TTI for filtered views.

### Decision Framework
- Need responsive input + expensive derived render → `useTransition`.
- Don't own the setter → `useDeferredValue`.
- Need server fetch deferral → React 19 Actions / Suspense (Q3, Q4), not transitions alone.

### Senior-Level Insight
Transitions are React saying: "scheduling is a first-class concern." This forces you to model UX in terms of **what's interactive** vs **what's derived**. That mental shift outlives the API.

### Real-World Scenario
**Symptom:** Typing into a search input freezes for ~150ms per keystroke on Pixel 4a.
**Investigation:** Profiler shows the entire results list re-rendering on every change.
**Root cause:** State update was sync; expensive filter blocked input.
**Fix:** Wrap filter-driving setState in `startTransition`; show subtle pending indicator.
**Lesson:** Sync updates make every dependent render a frame-budget risk on slower devices.

### Production Failure Story
**Incident:** A retailer's filter UI shipped `startTransition` and broke analytics — events fired with stale state.
**Investigation:** Analytics handler read `query` from a closure captured before the transition committed.
**Root cause:** Misunderstood "the previous UI is shown" — closures captured pre-transition values.
**Fix:** Read state via a ref or pass the new value explicitly.
**Prevention:** Code-review checklist: any side effect inside a transition must use refs or explicit args.

### Debugging Checklist
1. DevTools Profiler → are commits tagged "Transition"?
2. Is the work actually in render, not in `useEffect`?
3. Are there sync updates immediately following the transition that re-render the same tree?
4. Suspense fallback flashing? Check the boundary is **inside** the transitioning subtree.

### Advanced / Internal Knowledge
- Transitions use the `TransitionLane` group in React's lane model.
- Concurrent features cooperate with RN's RuntimeScheduler in Bridgeless mode for true preemption.
- `useDeferredValue` is implemented via a hidden second render scheduled on the Transition lane.

### 2026 AI Tip
AI conflates `startTransition` with debounce. Always specify the difference in prompts; verify generated code doesn't wrap setters that drive controlled input fields.

### Related Topics
Q1 (Compiler), Q3 (Actions), Q4 (Suspense), S4 (Fabric atomic commit), S7 (perf).

### Interview Follow-Up Questions
- "When would you choose `useDeferredValue` over `useTransition`?"
- "How do transitions interact with Suspense?"
- "What can go wrong with side effects inside a transition?"
- "How does RN's RuntimeScheduler enable preemption?"

### Memory Hook
**"Sync = right now. Transition = when nothing better is happening. Deferred = render twice, stale first."**

### Revision Notes
> Concurrent React = lanes + interruptible render; `startTransition` for non-urgent updates; `useDeferredValue` for non-urgent values; pairs with Fabric atomic commit for tear-free UI.

---

## Q3. Actions, `useActionState`, `useFormStatus`, `useOptimistic`

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common — newer API, often a differentiator at Senior+.

### Prerequisites
React 19 basics, async/await, optimistic UI concept.

### TL;DR
React 19 **Actions** are async functions React tracks for pending/error state automatically; `useActionState` exposes form state, `useFormStatus` reads ambient submission state, and `useOptimistic` lets you render expected results before the action completes.

### 30-Second Interview Answer
"Actions are async functions React knows about. When you call one (typically from a form submit or a button), React tracks pending state, errors, and ordering. `useActionState` gives you a `[state, formAction, isPending]` tuple driven by an async reducer. `useFormStatus` lets descendants of a form read its pending state without prop drilling. `useOptimistic` lets you render an optimistic value during the action and roll back on error. Together they replace a ton of `useState` + `try/catch` + manual loading flag boilerplate."

### 2-Minute Practical Answer
What problem they solve: every async-mutation form has the same shape — pending flag, error state, optimistic update, retry. React 19 standardizes that shape.

```tsx
const [state, formAction, isPending] = useActionState(
  async (prev, formData) => {
    try {
      const updated = await api.updateName(formData.get('name') as string);
      return { ok: true, user: updated };
    } catch (e) {
      return { ok: false, error: (e as Error).message };
    }
  },
  { ok: true, user: initial },
);
```

You wire `formAction` to a `<form>` action prop (web) or call it imperatively (RN doesn't have native `<form>`, but the hooks still work as plain async reducers).

`useOptimistic`:
```tsx
const [optimisticItems, addOptimistic] = useOptimistic(items, (state, draft) => [...state, draft]);
async function submit(text: string) {
  addOptimistic({ id: 'tmp', text });
  await api.add(text); // React reverts optimistic state if this throws
}
```

In RN you typically use these from a button's `onPress` handler — there's no DOM form, but the hook semantics are identical.

### 5-Minute Architecture Answer
Actions formalize three patterns:
- **Pending tracking** — automatic across nested components via `useFormStatus`.
- **Sequencing** — submitting an action while another is pending queues correctly.
- **Optimistic + rollback** — `useOptimistic` keeps your store source-of-truth honest while UI shows the expected outcome.

The gain isn't raw lines of code — it's **error-handling discipline**. Every async mutation now has a known shape, observable from anywhere.

In RN 2026, this pairs with TanStack Query / RTK Query for server cache, while Actions handle the **submission lifecycle** itself. Don't double-implement: pick one for cache, the other for submit.

### The "Why"
- Mutations were the most boilerplate-heavy part of React.
- React 19 wants to push more state-machine concerns into the framework so app code shrinks.
- Optimistic UI is mandatory for modern UX; doing it correctly with rollback is hard without primitives.

### Mental Model
Actions = **async reducers with framework-managed pending state**. Like Redux Toolkit's `createAsyncThunk` but built into React.

### Internal Working (2026 Context)
- Actions integrate with React's scheduling: an action's render commits are typically on the Transition lane.
- `useOptimistic` snapshots the current state, applies the optimistic patch for the next renders, and reverts if the action throws.
- In RN, Actions just use the JS thread + Fabric like any state update; no Bridge involvement.

### Modern Implementation (Code)

```tsx
type Todo = { id: string; text: string; done: boolean };

export function TodoList({ initial }: { initial: Todo[] }) {
  const [todos, setTodos] = useState(initial);
  const [optimistic, addOptimistic] = useOptimistic(
    todos,
    (state, draft: Todo) => [...state, draft],
  );

  async function add(text: string) {
    addOptimistic({ id: 'tmp_' + Date.now(), text, done: false });
    try {
      const created = await api.createTodo(text);
      setTodos((t) => [...t, created]);
    } catch (e) {
      // optimistic auto-reverts; surface error
      Toast.show('Could not save: ' + (e as Error).message);
    }
  }

  return (
    <View>
      <FlashList
        data={optimistic}
        renderItem={({ item }) => <TodoRow todo={item} />}
        keyExtractor={(t) => t.id}
      />
      <AddTodoButton onAdd={add} />
    </View>
  );
}
```

### Comparison

| Pattern                                  | Pre-React 19              | React 19                        |
| ---------------------------------------- | ------------------------- | ------------------------------- |
| Pending state                            | Manual `useState(false)`  | `useActionState` / `useFormStatus` |
| Optimistic UI                            | Manual snapshot + revert  | `useOptimistic`                 |
| Form submission with error               | Custom reducer            | `useActionState`                |
| Sequencing concurrent submits            | Race-prone manual         | Framework-tracked               |

### Production Usage
- Forms (auth, profile, settings) lose ~50% of their state code.
- Lists with add/remove gain instant-feeling UX with safe rollback.

### Hands-On Exercise
1. Convert a profile-edit screen with manual loading flags to `useActionState`. Measure code volume.
2. Add `useOptimistic` to a "like" button — UI updates instantly, reverts if API fails.
3. Simulate slow network + cancellation — verify rollback fires.

### Common Mistakes
- Using `useOptimistic` to update server cache (it's UI-local; pair with TanStack Query for the cache).
- Forgetting that `useOptimistic` reverts only when the action throws — non-throwing failures (HTTP 500 returned as data) need explicit handling.
- Over-using actions where a simple `useState` would suffice.

### Production Red Flags
- Optimistic updates that don't revert on failure (poison cache).
- Manual loading flags coexisting with `useFormStatus` — choose one.
- Error toasts inside reducers (side effects in render-adjacent code).

### Performance & Metrics
- No raw perf change; UX improves dramatically (perceived latency).
- Optimistic UI typically halves perceived submit latency.

### Metrics That Matter
Submit latency P95, optimistic-revert rate, error rate per action.

### Decision Framework
- Submission lifecycle → React 19 Actions.
- Server cache → TanStack Query / RTK Query.
- Local UI state → `useState`.

### Senior-Level Insight
Actions push you toward an **action-oriented architecture** even on mobile. Each user intent becomes a named async function with a predictable lifecycle — easier to log, retry, and observe.

### Real-World Scenario
**Symptom:** Likes count "double-jumps" — goes up, down, up.
**Investigation:** `useOptimistic` updates UI; server response triggers `setState` to the same value; an unrelated polling refresh briefly returns stale.
**Root cause:** Mixing `useOptimistic` with stale poll data.
**Fix:** Reconcile poll responses against pending optimistic actions; ignore polls older than the latest action timestamp.
**Lesson:** Optimistic UI without action-aware reconciliation = visible flicker.

### Production Failure Story
**Incident:** Banking app submitted a transfer twice on flaky network.
**Investigation:** Action threw on timeout; user retried; first request actually succeeded server-side.
**Root cause:** No idempotency key.
**Fix:** Generate idempotency key inside the action; server dedupes.
**Prevention:** Standard helper `withIdempotency(action)`; lint rule for any mutating action.

### Debugging Checklist
1. Action thrown? Check `useActionState`'s state for the error shape.
2. Optimistic doesn't revert? Verify the action **throws** on failure (returning an error object isn't enough).
3. Pending state stuck? An unawaited promise inside the action.
4. UI flickers? Mixing optimistic with periodic refresh.

### Advanced / Internal Knowledge
- Actions are scheduled inside React's transition lane by default.
- `useFormStatus` reads from the nearest ancestor form context (React Native–wise, you create your own form-like wrapper).
- React 19 added `use(promise)` (Q4) which composes naturally with Actions returning promises.

### 2026 AI Tip
AI loves writing `useState(loading)` reflexively. Re-prompt: "implement using React 19 `useActionState` and `useOptimistic`." Verify the AI didn't keep a redundant manual loading flag.

### Related Topics
Q4 (`use`), S8 (state management), S9 (networking), S11 (offline-first).

### Interview Follow-Up Questions
- "How does `useOptimistic` know to revert?"
- "How do Actions interact with TanStack Query?"
- "How would you implement idempotency on top of Actions?"
- "When would you NOT use Actions?"

### Memory Hook
**"Action = async reducer React watches. Optimistic = render the future, revert on throw."**

### Revision Notes
> React 19 Actions standardize async mutation lifecycle (pending, error, sequencing); `useOptimistic` for instant UI with auto-revert on throw; pair with idempotency keys; don't double-cache vs TanStack Query.

---

## Q4. The `use` hook and Suspense for data on mobile

### Difficulty
Advanced

### Interview Frequency
Common — emerging pattern, differentiates strong candidates.

### Prerequisites
Suspense basics, Promises, React 19 Actions.

### TL;DR
`use(promise)` lets a component **read** a promise's resolved value during render; Suspense above it shows a fallback until the promise resolves. Together they replace a lot of `useEffect` + state for one-shot async data.

### 30-Second Interview Answer
"`use` is React 19's primitive for reading promises and contexts inside render. If you call `use(promise)` and it's not resolved, React suspends and the nearest `<Suspense>` boundary renders its fallback. When the promise resolves, React re-renders with the value. It's not a fetcher — you still cache promises (TanStack Query, RSC) — but it lets you write linear async code in components."

### 2-Minute Practical Answer
Pre-`use`, fetching looked like:
```tsx
const [data, setData] = useState();
const [error, setError] = useState();
useEffect(() => { fetch(...).then(setData).catch(setError) }, []);
if (error) return <Err />;
if (!data) return <Spinner />;
return <View data={data} />;
```

With `use` + Suspense + a cached promise:
```tsx
function Profile({ id }: { id: string }) {
  const user = use(getUserPromise(id)); // suspends until ready
  return <UserView user={user} />;
}
function Screen() {
  return (
    <Suspense fallback={<Spinner />}>
      <ErrorBoundary fallback={<Err />}>
        <Profile id="42" />
      </ErrorBoundary>
    </Suspense>
  );
}
```

The cache (here `getUserPromise`) is critical — `use(fetch(...))` would refetch on every render. TanStack Query, Apollo, or RSC's data layer provide stable promises.

`use` also reads contexts conditionally (unlike `useContext`):
```tsx
const theme = condition ? use(ThemeContext) : defaultTheme;
```

### 5-Minute Architecture Answer
`use` formalizes Suspense for **data** (it already worked for code via lazy). The key insight: throwing a promise during render was the unofficial mechanism libraries used. `use` makes it ergonomic and safe.

In RN 2026, `use` enables:
- **Data-driven layouts** with no manual loading state.
- **Predictable nav transitions** — the new screen suspends; old screen stays committed (under `startTransition`); no flash.
- **Composability** — multiple `use` calls in one component, multiple Suspense levels for granular skeletons.

What `use` doesn't do:
- It's not a fetcher (no caching, no request dedup).
- It doesn't auto-cancel on unmount (your fetcher must).
- It doesn't replace mutations — those are Actions (Q3).

### The "Why"
- Async data is the most common reason RN screens have boilerplate.
- Suspense + `use` makes loading a **layout concern** (where the boundary is), not a per-component concern.

### Mental Model
`use` = "await for renders." React handles the "before resolved" state by walking up to the nearest Suspense boundary.

### Internal Working (2026 Context)
- `use(promise)` throws an internal sentinel React catches and uses to mark the component as suspended.
- React tracks the promise; when it settles, React schedules a re-render at the boundary's lane.
- Inside `startTransition`, suspended subtrees keep showing the **previous** UI instead of the fallback — eliminating flashes during nav.

### Modern Implementation (Code)

```tsx
// queries/user.ts — caching layer
const cache = new Map<string, Promise<User>>();
export function getUserPromise(id: string): Promise<User> {
  if (!cache.has(id)) cache.set(id, fetchUser(id));
  return cache.get(id)!;
}

// screens/Profile.tsx
function ProfileBody({ id }: { id: string }) {
  const user = use(getUserPromise(id));
  const posts = use(getPostsPromise(id));
  return (
    <>
      <UserHeader user={user} />
      <PostsList posts={posts} />
    </>
  );
}

export function ProfileScreen({ id }: { id: string }) {
  return (
    <ErrorBoundary fallback={<ErrorView />}>
      <Suspense fallback={<ProfileSkeleton />}>
        <ProfileBody id={id} />
      </Suspense>
    </ErrorBoundary>
  );
}
```

In real apps, replace the hand-rolled cache with TanStack Query's `queryClient.ensureQueryData(...)` returning a stable promise.

### Comparison

| Pattern                | useEffect + state           | `use` + Suspense                     |
| ---------------------- | --------------------------- | ------------------------------------ |
| Loading state          | Manual (`if (!data)`)       | Suspense boundary                    |
| Error handling         | Manual (`useState`)         | Error boundary                       |
| Code volume            | High                        | Low                                  |
| Composability          | Each component its own      | Boundary controls fallback layout    |
| With transitions       | Flash on navigate           | Previous UI stays committed          |

### Production Usage
- Screens with parallel queries collapse to clean code with co-located fallbacks.
- Pairs with TanStack Query: `queryClient.fetchQuery` returns a promise; cache under your key; `use(...)` it.

### Hands-On Exercise
1. Build a profile screen with `use` reading user + posts in parallel. Confirm both fire concurrently.
2. Wrap in `<Suspense>` with a skeleton; navigate from a list inside `startTransition`. Observe no flash.
3. Throw inside the promise; confirm Error Boundary catches it.

### Common Mistakes
- Calling `use(fetch(...))` directly — refetches forever.
- Forgetting Error Boundary; rejected promises crash the tree.
- Sequential `use` chains where parallel was intended (same as JS — use `Promise.all`).

### Production Red Flags
- Components fetching inside `use` without a cache layer.
- Suspense boundaries placed too low (skeleton renders even for cheap data).
- Suspense boundaries placed too high (one slow query blocks an entire screen).

### Performance & Metrics
- TTI improves when boundaries are placed at the right granularity.
- Network: no inherent change — depends on your cache.

### Metrics That Matter
Time to first paint, time to interactive, % of navigations without fallback flash.

### Decision Framework
- One-shot data on screen mount → `use` + Suspense.
- Mutations → Actions (Q3).
- Polled / subscription data → TanStack Query / WebSocket; don't `use` a fresh promise per render.

### Senior-Level Insight
Suspense placement is a **design system decision**. Where the boundary lives controls what skeleton users see and how navigation feels. Treat it like layout, not like data plumbing.

### Real-World Scenario
**Symptom:** Profile screen flashes a spinner every navigation, even when data is cached.
**Investigation:** `use(fetchUser(id))` was called without a cache; promise was new each render.
**Root cause:** Missing cache layer.
**Fix:** Wrap with TanStack Query's `ensureQueryData`.
**Lesson:** `use` requires stable promise identity to avoid refetches.

### Production Failure Story
**Incident:** App white-screened on a deep link to a profile that had been deleted.
**Investigation:** `use(getUserPromise(id))` rejected; no Error Boundary.
**Root cause:** Boundary missing at the route level.
**Fix:** Wrap every route with an Error Boundary; standard layout helper.
**Prevention:** Lint rule requiring `<ErrorBoundary>` ancestor for every screen using `use`.

### Debugging Checklist
1. Is the promise stable across renders?
2. Is there a Suspense boundary above?
3. Is there an Error Boundary above?
4. Are parallel queries actually parallel (not awaiting in sequence)?

### Advanced / Internal Knowledge
- `use` is the only hook that can be called conditionally (after early returns).
- React tracks suspended promises per-component to avoid re-throwing on resolve.
- React 19 added the ability to `use(context)` for conditional context reads.

### 2026 AI Tip
AI tends to write `use(fetch(...))` patterns that refetch infinitely. Always specify a cache provider (TanStack Query) and verify the AI uses it.

### Related Topics
Q3 (Actions), Q2 (transitions), S8 (state), S9 (networking).

### Interview Follow-Up Questions
- "How does `use` interact with `startTransition`?"
- "Why do you need a cache layer?"
- "Where do you place Suspense boundaries?"
- "How does `use` differ from `useContext`?"

### Memory Hook
**"`use` waits, Suspense fills, ErrorBoundary catches. Cache the promise or refetch forever."**

### Revision Notes
> `use(promise)` reads async data in render and suspends to nearest boundary; needs stable cached promises (TanStack Query); pair with Error Boundary; placement is layout design.

---

## Q5. Reconciliation, Fiber, batching — the model behind it all

### Difficulty
Intermediate → Advanced

### Interview Frequency
Very Common foundational question.

### Prerequisites
React rendering basics.

### TL;DR
React reconciles by diffing the new element tree against a **Fiber tree** (mutable work units), schedules render in interruptible chunks, and **batches** state updates within a single tick into one commit — even across async boundaries since React 18.

### 30-Second Interview Answer
"Reconciliation is React's diffing process. Each render produces an element tree; React walks it and updates a parallel **Fiber tree** of mutable work nodes. Fiber lets render pause, resume, and prioritize work — the foundation of concurrent features. Batching means all state updates within a single event (or async tick, since React 18) commit together as one re-render. In React 19 with the compiler, fewer renders are wasted, and Fabric's atomic mount keeps RN's UI tear-free."

### 2-Minute Practical Answer
Three intertwined concepts:

1. **Reconciliation** — given old vs new element trees, produce a minimal set of mutations.
2. **Fiber** — each component instance has a Fiber node holding its state, hooks, work queue, and pointers to siblings/children. Fibers form a doubly-linked tree React traverses incrementally.
3. **Batching** — multiple `setState` calls in one event handler / promise / setTimeout callback collapse into one render. Pre-React 18, batching was limited to React-controlled events; React 18 added **automatic batching** everywhere.

Practical implications:
- Two `setState` in one handler → one re-render.
- `setState` followed by reading state in the same function → still see old state (state is snapshot per render).
- Functional updates (`setX(prev => prev + 1)`) are required when sequencing.

### 5-Minute Architecture Answer
Render flow (concurrent React):
```
state change → schedule work on a lane
             → React picks the highest-priority pending lane
             → walks Fiber tree, calling components ("render")
             → produces new element tree
             → diffs against current Fiber tree (reconcile)
             → builds a "work-in-progress" Fiber tree
             → commits: applies changes to host (DOM / Fabric shadow tree)
             → fires layout effects sync, then passive effects async
```

In RN with Fabric:
- "Commit to host" = commit a new shadow tree to Fabric via JSI.
- Mount on UI thread happens atomically after commit.

Key invariants:
- Render must be **pure** (Rules of React).
- Fibers are **mutable** (perf), but the work-in-progress tree is **separate** until commit (safety).
- Hooks store state in the Fiber, indexed by call order — that's why they can't be conditional.

### The "Why"
- Without reconciliation, you'd manually mutate the DOM/native tree (jQuery era).
- Without Fiber, you couldn't pause work; long renders blocked input.
- Without batching, every `setState` would commit individually — a render storm.

### Mental Model
Element tree = **the description**. Fiber tree = **React's bookkeeping of how it built that description**, with state attached. Reconciliation matches one to the other and emits mutations.

### Internal Working (2026 Context)
- Lanes (priorities) decide which pending work runs first.
- Hooks live on Fibers as a linked list (`memoizedState`).
- React Compiler reduces work React does inside render by pre-memoizing.
- Fabric makes the commit→mount step atomic on the UI thread, removing tearing.

### Modern Implementation (Code)
You don't write Fiber directly. The interview test is **predicting render behavior**:

```tsx
function Counter() {
  const [n, setN] = useState(0);
  const handle = () => {
    setN(n + 1);   // captures n=0
    setN(n + 1);   // also captures n=0
    // result after one render: n = 1, not 2
  };
  const handleCorrect = () => {
    setN((p) => p + 1);
    setN((p) => p + 1); // result: n = 2
  };
  return <Button onPress={handle} />;
}
```

```tsx
// React 18+ automatic batching: this also batches into one render
async function load() {
  const data = await fetchData();
  setLoading(false);
  setData(data); // one re-render, not two
}
```

### Comparison

| Concept            | Pre-React 18                         | React 18 / 19              |
| ------------------ | ------------------------------------ | -------------------------- |
| Batching scope     | Inside React event handlers only     | Everywhere (auto)          |
| Render interruption| No                                   | Yes (concurrent)           |
| Memoization        | Manual                               | Compiler (Q1)              |
| Commit to host     | Async UIManager (RN)                 | Atomic Fabric              |

### Production Usage
- Mental model is foundation for every perf discussion.
- Misunderstanding state snapshots / batching is the #1 cause of "stale state" bugs.

### Hands-On Exercise
1. Write the buggy counter above. Observe `n` only goes up by 1 per click.
2. Switch to functional updates. Observe correct.
3. Trigger two `setState` from inside a `setTimeout` (pre-React 18 would re-render twice; in React 18+ they batch).

### Common Mistakes
- Reading `state` right after `setState` in the same scope.
- Conditional hooks (breaks Fiber's hook-by-index storage).
- Heavy work inside render (slows reconciliation).

### Production Red Flags
- "We `setTimeout(setState, 0)` to force a re-render" — almost always wrong.
- Using `useRef` to mirror state for "freshness" everywhere.
- Inline component definitions inside parents (new identity → forced reconciliation).

### Performance & Metrics
- Render duration P95 — biggest signal of reconciliation cost.
- Wasted renders — React DevTools profiler.
- Compiler reduces both.

### Metrics That Matter
Render P95, commit duration, frame drop %, JS thread idle %.

### Decision Framework
- Stale state issue → functional updates.
- Render storm → check batching context.
- Slow renders → memoize (compiler) or split state.

### Senior-Level Insight
Reconciliation and Fiber are React's bet that **declarative + scheduled** beats **imperative + immediate**. Every modern React feature (Suspense, transitions, Compiler) flows from this bet. Engineers who internalize "render is just a function from state to elements; commit is React's job" debug far faster.

### Real-World Scenario
**Symptom:** A counter increments by 1 instead of 2 when both buttons of a "double tap" handler call `setN(n+1)`.
**Investigation:** Both calls captured the same `n` (0 → 1).
**Root cause:** Stale closure over state.
**Fix:** Functional update.
**Lesson:** State is a snapshot; updaters access the latest.

### Production Failure Story
**Incident:** A list re-rendered every keystroke despite `React.memo`.
**Investigation:** Parent passed `style={{ marginTop: 10 }}` inline → new identity each render.
**Root cause:** Reference inequality bypassed memo.
**Fix:** Stable style (or rely on Compiler hoisting).
**Prevention:** Compiler + lint banning inline objects on hot lists.

### Debugging Checklist
1. DevTools Profiler → which components rendered? Why?
2. Hook order changed? You'll see "Rendered more hooks than during the previous render."
3. Stale state? Switch to functional updates.
4. Inline objects/functions on memoized children? Stabilize them (or trust the compiler).

### Advanced / Internal Knowledge
- Fiber's "double buffering" = `current` tree + `workInProgress` tree.
- Effects are queued during render and fired after commit (`useLayoutEffect` sync, `useEffect` async).
- Concurrent React's commit phase is still synchronous; only render is interruptible.

### 2026 AI Tip
AI often "fixes" stale state bugs by switching to refs — that's a smell. The right fix is functional updates or restructuring effects. Re-prompt for the root cause.

### Related Topics
Q1 (Compiler), Q2 (Concurrent), Q4 (Suspense), S4 (Fabric commit/mount), S7 (perf).

### Interview Follow-Up Questions
- "Why are conditional hooks illegal?"
- "What changed in batching between React 17 and 18?"
- "Walk me through what happens when I call `setState`."
- "Why is render expected to be pure?"

### Memory Hook
**"Render = function. Fiber = bookkeeping. Commit = atomic. Batching = one render per tick."**

### Revision Notes
> Reconciliation diffs new elements vs Fiber tree; Fiber is mutable work-unit tree enabling concurrent + hooks; React 18+ batches everywhere; render is pure, commit is atomic, effects fire after.
