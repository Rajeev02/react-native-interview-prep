# S8 — State Management

> Server state vs client state · TanStack Query · Zustand · Redux Toolkit · optimistic updates · cache invalidation · offline mutation queues

The 2026 default split: **TanStack Query for server state, Zustand for client state, Redux Toolkit only when you have a strong reason**. Five Q-topics in the mandatory per-topic format.

---

### Q1. Server state vs client state — the TanStack Query + Zustand split

---

## Difficulty
- Intermediate → Advanced

## Interview Frequency
- Very Common (asked in nearly every senior RN interview)

## Prerequisites
- React hooks, async/await, basic networking concepts

## TL;DR
Server state (cached remote data) and client state (local UI/session) have different needs and should use different tools — TanStack Query for the former, a small client-state library (Zustand/Jotai) for the latter. Putting everything in Redux is the 2026 anti-pattern.

---

## 30-Second Interview Answer

> "In 2026 you split state along the server/client axis. Server state — anything you fetch from a backend — has its own lifecycle: stale, fresh, refetch, retry, dedupe, cache. TanStack Query owns it. Client state — UI mode, drafts, filters, auth status — has totally different semantics. Zustand or Jotai handle it in <1KB without Redux's boilerplate. Putting fetched data in Redux means you re-implement caching, deduplication, retries, garbage collection — all things TanStack Query gives you for free."

---

## 2-Minute Practical Answer

The 2010s default was Redux for everything: requests dispatched as actions, responses normalized into the store, components selected slices. This conflated two problems:

1. **Server state** — derived from a remote source of truth. You don't *own* it; you cache it. Concerns: staleness, refetching, retries, deduplication, pagination, optimistic updates, garbage collection. TanStack Query is purpose-built for this.
2. **Client state** — owned locally. The user toggled a filter, opened a modal, drafted a message. Concerns: subscriptions, derived values, persistence. Zustand / Jotai / React Context cover this with minimal ceremony.

The 2026 architecture:

```
┌─────────────────────────────────────┐
│  Server state                       │
│  - useQuery / useInfiniteQuery      │
│  - useMutation                      │
│  - cache invalidation by key        │
│  → TanStack Query                   │
├─────────────────────────────────────┤
│  Client state                       │
│  - auth flag, theme, filters        │
│  - drafts, UI mode                  │
│  → Zustand / Jotai                  │
├─────────────────────────────────────┤
│  Form state                         │
│  - controlled inputs, validation    │
│  → React Hook Form / Conform        │
├─────────────────────────────────────┤
│  Navigation state                   │
│  → Expo Router / React Navigation   │
└─────────────────────────────────────┘
```

Each layer owns a clear concern. No single store mixes them.

---

## 5-Minute Architecture Answer

The deeper insight is **state has a lifecycle**, and lifecycle should drive tooling.

- **Cached/server state** lifecycle: `idle → fetching → success/error → stale → refetch → garbage-collected`. TanStack Query encodes this as a state machine per query key. Built-ins: window-focus refetch, network-resume refetch, exponential backoff retries, request deduplication, structural sharing for cheap re-renders.
- **Owned/client state** lifecycle: `mounted → updated by user → persisted → unmounted`. Zustand/Jotai expose subscribable atoms/stores with selectors.
- **Form state** lifecycle: `pristine → dirty → submitted → success/error`. Form libraries handle field-level subscriptions to avoid full-form re-renders.
- **URL/navigation state** lifecycle: `route push/pop`. Owned by router.

When these lifecycles are mixed in one global store, every interaction touches every layer — leading to over-rendering, brittle selectors, and unclear data flow.

The 2026 React 19 angle: **Actions** (`useActionState`, `<form action={...}>`) and `useOptimistic` give you React-native primitives for mutations + optimistic UI, which compose cleanly with TanStack Query's `useMutation`. RSC is still nascent on RN, but where used, the server-side data fetching subsumes part of TanStack Query's role for first paint.

When **does Redux Toolkit still make sense?** (Q2) — complex client state with time-travel debugging needs, redux middleware ecosystem dependence, or migration cost from a large existing Redux codebase.

---

## The "Why"

Network-bound data has fundamentally different operational concerns from local UI state. A user toggling a switch vs. a list of orders fetched from a backend should not be modeled the same way. Conflating them produces:
- excessive boilerplate (action types, reducers, sagas/thunks for what should be a one-line `useQuery`)
- broken cache semantics (you reinvent staleness, retries, dedup poorly)
- unnecessary re-renders (everything subscribes to one store)
- harder offline behavior (no built-in queue/retry)

Companies care because state architecture is the #2 source of frontend tech debt (after styling). Bad choices here echo for years.

---

## Mental Model

Two warehouses:
- **Server state warehouse**: stocked from a supplier (the API). You don't manufacture goods; you stock and re-stock based on freshness rules. Inventory expires. TanStack Query is the warehouse manager.
- **Client state warehouse**: your own workshop. You build things on demand (drafts, filters, modes). You own everything inside. Zustand is the workshop foreman.

Trying to use one warehouse for both confuses ownership and lifecycle.

---

## Internal Working (2026 Context)

**TanStack Query**:
- A `QueryClient` holds a `QueryCache` (Map<queryKey, Query>).
- Each `useQuery` subscribes to a query identified by `queryKey`. On mount, the hook returns cached data immediately (if present and fresh) and triggers a fetch if stale.
- Queries have observers (subscribers); when data changes, only observers with affected `select` outputs re-render (structural sharing).
- Mutations (`useMutation`) don't use cache automatically; you invalidate keys (`queryClient.invalidateQueries`) or set data directly (`queryClient.setQueryData`).

**Zustand**:
- A store is a function returning state + actions.
- Components subscribe via selectors (`useStore((s) => s.user)`). Only re-render when selector output changes (Object.is by default, can use `shallow`).
- No reducers, no actions — direct setters via closures.
- Vanilla store works outside React (event handlers, native modules).

**Threading on RN**: both libraries run on JS thread. Their efficiency comes from **selective subscriptions** (avoiding cascade re-renders), not from threading.

**React Compiler**: complements both — auto-memoizes selector callsites; you no longer need `useMemo(() => selector, [])` patterns.

---

## Modern Implementation (Code)

```tsx
// queryClient.ts
import { QueryClient } from '@tanstack/react-query';
import { onlineManager } from '@tanstack/react-query';
import NetInfo from '@react-native-community/netinfo';

onlineManager.setEventListener((setOnline) => {
  return NetInfo.addEventListener((state) => setOnline(!!state.isConnected));
});

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,        // data fresh for 30s
      gcTime: 5 * 60_000,       // garbage-collect after 5min unused
      retry: 2,
      refetchOnWindowFocus: false, // mobile: use AppState focus instead
    },
  },
});
```

```tsx
// useOrders.ts — server state
import { useQuery } from '@tanstack/react-query';
import { fetchOrders } from '@/api/orders';

export function useOrders(userId: string) {
  return useQuery({
    queryKey: ['orders', userId],
    queryFn: ({ signal }) => fetchOrders(userId, { signal }),
    enabled: !!userId,
  });
}
```

```tsx
// useUiStore.ts — client state with Zustand
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV();

type UiState = {
  theme: 'light' | 'dark';
  filtersOpen: boolean;
  toggleFilters: () => void;
  setTheme: (t: 'light' | 'dark') => void;
};

export const useUiStore = create<UiState>()(
  persist(
    (set) => ({
      theme: 'dark',
      filtersOpen: false,
      toggleFilters: () => set((s) => ({ filtersOpen: !s.filtersOpen })),
      setTheme: (theme) => set({ theme }),
    }),
    {
      name: 'ui',
      storage: createJSONStorage(() => ({
        getItem: (k) => storage.getString(k) ?? null,
        setItem: (k, v) => storage.set(k, v),
        removeItem: (k) => storage.delete(k),
      })),
    },
  ),
);
```

```tsx
// OrdersScreen.tsx — composing both
import { useOrders } from './useOrders';
import { useUiStore } from './useUiStore';

export function OrdersScreen({ userId }: { userId: string }) {
  const { data, isLoading, error } = useOrders(userId);
  const filtersOpen = useUiStore((s) => s.filtersOpen);
  // ...
}
```

---

## Comparison

| Concern | TanStack Query | Zustand | Redux Toolkit | Context |
|---|---|---|---|---|
| Server caching | first-class | manual | manual | manual |
| Optimistic updates | first-class | manual | RTK Query has it | manual |
| Bundle | ~13KB | ~1KB | ~12KB | 0 |
| Boilerplate | low | minimal | moderate | low |
| Selector perf | structural sharing | shallow / custom | reselect | re-render whole subtree |
| DevTools | yes | yes | best-in-class | none |
| Time-travel debug | no | no | yes | no |
| Offline persistence | via persistor plugin | via persist middleware | redux-persist | manual |

| Server state libs | TanStack Query | Apollo | urql | RTK Query |
|---|---|---|---|---|
| Backend | REST/anything | GraphQL | GraphQL | REST/anything |
| Bundle | small | large | small | medium |
| Cache normalization | optional | required | optional | optional |
| RN-friendly | excellent | good | good | good |

---

## Production Usage

- **Feeds, lists, detail pages**: `useInfiniteQuery` + `useQuery`.
- **Mutations** (create/update/delete): `useMutation` with `onMutate` for optimistic updates and `onSettled` for invalidation.
- **Auth state**: client state in Zustand (token, user profile cached here for sync access).
- **Theme / language**: client state.
- **Drafts**: client state, persisted to MMKV.
- **Filter UI**: client state, often URL-synced (Expo Router params).
- **Persistence**: TanStack Query has `persistQueryClient` for offline-friendly cache persistence.

Scaling notes: standardize **query key conventions** (`['orders', userId, { status }]`) and create a small `keys` helper module — uncoordinated keys lead to invalidation bugs at scale.

---

## Hands-On Exercise

1. **Implementation**: build a paginated orders screen with TanStack Query (`useInfiniteQuery`), pull-to-refresh, retry-on-failure, and optimistic mutation for marking an order as paid.
2. **Debugging**: a screen re-renders 4× per scroll because Zustand selector returns a new object — fix with `shallow` comparator or selecting primitives.
3. **Architecture**: design the query key system for a multi-tenant SaaS app where data is scoped by `tenantId`.
4. **Optimization**: a heavy detail screen flashes "loading" on every revisit even when data is cached — adjust `staleTime` / `gcTime` strategy.

---

## Common Mistakes

- Putting server data in Redux/Zustand and re-implementing caching badly.
- Using `useState` for shared state across screens instead of Zustand.
- Inline Zustand selectors returning new objects every render (`(s) => ({ a: s.a, b: s.b })`) without `shallow` comparator → over-rendering.
- Calling `useQuery` inside conditionals or loops (breaks rules of hooks).
- Forgetting to pass `signal` to fetch — queries don't cancel on unmount/key change.
- Using `setQueryData` without invalidation when the data changed server-side too — stale UI.
- Persisting the entire Zustand store including ephemeral fields → MMKV bloat.

---

## Production Red Flags

- **"All our state is in Redux"** in 2026 → likely over-engineered.
- **No `staleTime` set anywhere** → constant re-fetches drain network and battery.
- **`useEffect` to fetch data, with manual loading/error state** → hand-rolled TanStack Query badly.
- **Multiple sources of truth** for the same data (cached query + Zustand mirror) → invalidation hell.
- **No offline strategy** for mutations → users lose data on network drops.

---

## Performance & Metrics (MANDATORY)

- **FPS**: selector design dominates render perf. Compiler memoizes consumer components; selectors must return stable references.
- **TTI**: TanStack Query's first-paint is fast (cache hits return synchronously); Zustand has near-zero overhead.
- **Memory**: TanStack Query gc clears unused cache after `gcTime`; tune for memory-constrained devices.
- **Thread**: pure JS; no UI/shadow impact.
- **Bundle**: TanStack Query (~13KB) + Zustand (~1KB) ≈ 14KB. Vs Redux Toolkit + RTK Query (~22KB).
- **Battery / data**: `staleTime` is the main lever — avoid refetching unnecessarily on focus/resume on cellular.
- **Optimization strategies**: tune `staleTime`/`gcTime` per query; use `select` to derive minimal data; combine related queries with `useQueries`.

---

## Metrics That Matter

- Cache hit rate (custom RUM, fetch deduplication count)
- API call count per session (network panel / Sentry)
- Re-render count per screen (Reassure)
- Time-to-interactive after navigation (cold vs warm)
- Mutation P95 latency

---

## Decision Framework

| Need | Pick |
|---|---|
| Fetched remote data | TanStack Query |
| GraphQL fetched data | Apollo or urql + TanStack Query for non-GQL |
| Local UI state shared across screens | Zustand |
| Local atomic state, derived | Jotai |
| Form state | React Hook Form / Conform |
| Navigation state | Router |
| Time-travel debugging mandate | Redux Toolkit |
| Existing large Redux app | Stay; add TanStack Query for new server state |

When NOT to use TanStack Query: tiny apps with one or two screens; data that's pure client (no server). When NOT to use Zustand: in a Redux-heavy codebase where consistency matters.

Migration cost: Redux → TanStack Query + Zustand is incremental — start with new screens, leave old slices alone.

---

## Senior-Level Insight

State architecture is a **lifecycle decomposition exercise**. Senior engineers don't pick libraries; they identify lifecycles (server, client, form, navigation) and assign each to the smallest tool that fits. Library choice falls out of that analysis. The Redux-everything era taught us what happens when one tool owns all lifecycles: bloated stores, unclear ownership, painful refactors.

The org-level insight: **standardize key conventions** for TanStack Query (`['domain', id, params]`), and standardize Zustand store boundaries (one store per domain, not one giant store). Without standards, query keys diverge across teams and invalidation bugs proliferate.

For platform/foundation engineers: provide a thin wrapper layer (`useOrders`, `useUiStore`) so app teams don't touch raw libraries — gives you upgrade flexibility and uniform telemetry.

---

## Real-World Scenario

**Symptom:** After adding push-to-refresh, the orders list flickers to "loading" briefly then shows data.
**Investigation:** Devtools show `isLoading` is true on refetch.
**Root Cause:** Code uses `isLoading` (true only on initial fetch when no cached data) vs `isFetching` (true during any fetch). On refetch with cached data, you want `isFetching` for spinner state, not `isLoading` (which would unmount the list).
**Fix:** Use `isFetching && !data` for full-screen loading; `isFetching && data` for inline refresh indicator.
**Lesson:** TanStack Query's flag distinctions matter — read the docs.

---

## Production Failure Story

**Incident:** A travel app's flight-search screen made 50+ API calls per session because every screen mount triggered a fresh fetch.
**Impact:** API bill spiked 10× over a weekend; backend team paged.
**Investigation:** Network panel showed identical queries firing on every navigation.
**Root Cause:** `staleTime: 0` (default) meant data was always considered stale; refetch on mount fired every navigation.
**Fix:** Set sensible `staleTime` defaults (30-60s for most data, longer for static).
**Prevention:** Org-wide `defaultOptions` in `QueryClient`; lint rule warning on per-query `staleTime: 0`; cost monitoring on backend.

---

## Debugging Checklist

1. Open **TanStack Query Devtools** (works in RN with `react-query-native-devtools`) — see all queries, their states, stale flags, last fetched.
2. Check `staleTime` / `gcTime` settings.
3. Verify query keys are stable (no `Date.now()` or fresh objects in keys).
4. Check `enabled` flag — query may be disabled inadvertently.
5. For mutation issues: log `onMutate` / `onError` / `onSettled` to verify rollback.
6. Zustand: log selector outputs to verify referential stability.
7. Sentry: tag queries with key for distributed tracing.

---

## Advanced / Internal Knowledge

- TanStack Query uses **structural sharing**: when fetched data is deep-equal to cached data, the same reference is returned, avoiding downstream re-renders. This is why mutating cached data via `setQueryData` requires returning a new object.
- Query observers form a graph; `invalidateQueries({ queryKey })` matches by prefix (`['orders']` invalidates `['orders', 1]` and `['orders', 2]`).
- Zustand's subscription model uses a custom store with `useSyncExternalStore` under the hood (React 18+) — concurrent-safe.
- React Compiler treats Zustand selectors and TanStack Query results as opaque; no special handling needed, but auto-memoizes consumers.
- **React 19 Actions** can wrap `useMutation`'s `mutate` for transition + optimistic UX integration.

---

## 2026 AI Tip

- AI is **good at**: scaffolding `useQuery` / `useMutation` hooks, generating Zustand stores from a type, suggesting query key shapes.
- AI is **bad at**: choosing the right `staleTime` / `gcTime` for *your* data freshness needs. Requires product knowledge.
- **Hallucination risk**: AI sometimes mixes Tanstack Query v4 and v5 APIs (e.g., `cacheTime` vs `gcTime`). Verify against current docs.
- **Prompt pattern**: "Generate a TanStack Query hook for `GET /orders?status=…` with infinite pagination, abort signal, and optimistic mutation for marking paid."
- **Agentic workflow**: have AI audit query keys for consistency across the codebase.

---

## Related Topics

- S2 React 19 Actions / `useOptimistic`
- S9 Networking — fetch, AbortController
- S11 Offline-first — mutation queues
- React Compiler

---

## Interview Follow-Up Questions

- Why is putting fetched data in Redux problematic in 2026?
- How does TanStack Query deduplicate concurrent identical fetches?
- What's the difference between `isLoading` and `isFetching`?
- How would you implement offline mutation persistence?
- How does Zustand avoid unnecessary re-renders?

---

## Memory Hook

**"Server state belongs to the server; cache it, don't store it."** Zustand for what you own, TanStack Query for what you borrow.

## Revision Notes

> Default 2026: TanStack Query (server) + Zustand (client). Redux Toolkit only with strong reason. Standardize query keys. Tune `staleTime` / `gcTime`. Never duplicate server data into client store.

---

---

### Q2. Redux Toolkit — when it still makes sense (and when it's legacy)

---

## Difficulty
- Intermediate

## Interview Frequency
- Common (still asked because many codebases run RTK)

## Prerequisites
- Q1, basic Redux concepts (actions, reducers)

## TL;DR
Redux Toolkit is still a fine choice for complex *client* state in apps that need time-travel debugging or have a deep middleware ecosystem dependency — but for new server-state work in 2026, TanStack Query wins.

---

## 30-Second Interview Answer

> "RTK fixed Redux's boilerplate problem with `createSlice` and Immer-driven reducers. RTK Query bolted on a TanStack-Query-like layer. It's a solid choice if your team is already on Redux, needs time-travel debugging, or has middleware dependencies (sagas, observable). For new apps, the TanStack Query + Zustand split is lighter and more idiomatic. The honest 2026 answer: 'great toolkit, but no longer the default'."

---

## 2-Minute Practical Answer

What RTK does well:
- **`createSlice`** — collapses reducers + action creators + types into one declaration.
- **Immer** — mutate-style reducers under the hood; less buggy than spread.
- **`createAsyncThunk`** — async actions with built-in pending/fulfilled/rejected.
- **RTK Query** — caching, dedup, mutations layer; competitive with TanStack Query for REST endpoints.
- **Excellent DevTools** — time travel, action replay, state diff. Unmatched.
- **Middleware ecosystem** — sagas, observables, redux-persist, analytics middleware.

What's changed in 2026:
- Server state is better served by TanStack Query (smaller, more idiomatic, framework-agnostic).
- Client state is better served by Zustand/Jotai (1KB, no providers, no boilerplate).
- React 19 Actions handle many "form submit + state update" cases without Redux thunks.
- React Compiler reduces the need for `reselect`-style memoization at consumer side.

So: RTK is no longer the default *new-project* choice but remains a reasonable pick for large existing Redux codebases or specific debugging needs.

---

## 5-Minute Architecture Answer

The architecture lens: Redux is a **single-store, single-stream-of-actions** model. Every state change goes through the dispatch pipeline. This is brilliant for:
- **Debuggability**: action log replays the world; time travel works because reducers are pure.
- **Middleware composition**: log every action, retry on failure, sync to backend, persist — all as middleware.
- **Predictability**: pure reducers are easy to test.

It's painful for:
- **Scale**: large stores have many slices, many subscribers; selectors get complex; over-rendering needs `reselect`.
- **Async**: thunks/sagas are extra layer; native async/await + TanStack Query is simpler.
- **Bundle**: ~12KB for RTK, more with middleware; vs Zustand's 1KB.

The 2026 framing: **Redux's strength (centralized event log) is also its weakness (one store for unrelated lifecycles)**. The right move is often:
- Use Zustand for client state.
- Use TanStack Query for server state.
- Keep Redux only for the *specific* slice that genuinely benefits from time-travel debugging or middleware (often: complex domain logic, undo/redo systems, real-time collab state).

For brownfield migrations, the standard play is to **stop adding to Redux** and add new features in the new architecture; over time the store shrinks.

---

## The "Why"

Redux solved "where does state live in a Flux app" in 2015. By 2018 it was the FE default. By 2022 the server-state portion got better tools. By 2024-2026 the client-state portion did too. Redux itself didn't get worse; the alternatives got better at narrower problems. Companies care because rip-and-replace migrations are expensive — knowing when RTK is "good enough to keep" vs "blocking velocity" matters.

---

## Mental Model

Redux = a city's central post office. Every letter goes through it; full audit trail; great for forensics. But for a quick note across the room (local UI state), the post office is overkill. TanStack Query = a courier service for cross-town packages (server state). Zustand = a sticky note on your monitor (local state).

---

## Internal Working (2026 Context)

- **`createSlice`** generates action types and creators automatically; reducers use Immer to allow mutate-style code (`state.users.push(newUser)`).
- **`configureStore`** wires up Redux DevTools, default middleware (thunk, immutability check, serializability check).
- **RTK Query** generates hooks (`useGetOrdersQuery`, `useUpdateOrderMutation`) from an `endpoints` definition; under the hood it manages a normalized cache keyed by endpoint + args.
- **Subscription**: components use `useSelector` (memoized via Object.is by default; `shallowEqual` for objects). `useDispatch` returns the store's dispatch.
- **Threading**: pure JS, single-threaded reducers. No UI thread interaction.
- **React Compiler**: complements `useSelector` (auto-memoizes consumer components). RTK already uses good memoization internally.

---

## Modern Implementation (Code)

```tsx
// store.ts
import { configureStore } from '@reduxjs/toolkit';
import authReducer from './authSlice';
import { ordersApi } from './ordersApi';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    [ordersApi.reducerPath]: ordersApi.reducer,
  },
  middleware: (getDefault) => getDefault().concat(ordersApi.middleware),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

```tsx
// authSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

type AuthState = { token: string | null; userId: string | null };
const initial: AuthState = { token: null, userId: null };

const authSlice = createSlice({
  name: 'auth',
  initialState: initial,
  reducers: {
    signedIn(state, action: PayloadAction<{ token: string; userId: string }>) {
      state.token = action.payload.token;
      state.userId = action.payload.userId;
    },
    signedOut(state) {
      state.token = null;
      state.userId = null;
    },
  },
});

export const { signedIn, signedOut } = authSlice.actions;
export default authSlice.reducer;
```

```tsx
// ordersApi.ts — RTK Query
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const ordersApi = createApi({
  reducerPath: 'ordersApi',
  baseQuery: fetchBaseQuery({ baseUrl: '/api' }),
  tagTypes: ['Order'],
  endpoints: (builder) => ({
    getOrders: builder.query<Order[], string>({
      query: (userId) => `/orders?user=${userId}`,
      providesTags: (result) =>
        result ? [...result.map((o) => ({ type: 'Order' as const, id: o.id })), 'Order'] : ['Order'],
    }),
    markPaid: builder.mutation<Order, string>({
      query: (id) => ({ url: `/orders/${id}/pay`, method: 'POST' }),
      invalidatesTags: (_r, _e, id) => [{ type: 'Order', id }],
    }),
  }),
});

export const { useGetOrdersQuery, useMarkPaidMutation } = ordersApi;
```

---

## Comparison

| Concern | RTK | TanStack Query + Zustand |
|---|---|---|
| Server state | RTK Query | TanStack Query |
| Client state | slices | Zustand |
| Bundle | ~12KB + middleware | ~14KB |
| Boilerplate | moderate | minimal |
| DevTools | best-in-class | good |
| Time travel | yes | no |
| Async patterns | thunk/saga/observable | hooks only |
| Learning curve | moderate | gentle |
| Default in 2026 | ⚠️ legacy choice | ✅ |

| RTK Query | TanStack Query |
|---|---|
| Coupled to Redux | standalone |
| Hooks generated from endpoints | hooks per-call |
| Tag-based invalidation | key-based invalidation |
| Normalization optional | normalization optional |
| Smaller community | larger community |

---

## Production Usage

- **Apps with deep Redux history** (5+ years, 100+ slices) — RTK is the upgrade path.
- **Apps needing time-travel debugging** (complex domain logic, financial workflows).
- **Apps with saga/observable middleware** (legacy patterns, not greenfield).
- **Greenfield apps in 2026** — usually skip RTK; use TanStack + Zustand.

Scaling pitfalls: organize slices by feature, not by data shape; standardize selector style; lint against direct state access.

---

## Hands-On Exercise

1. **Implementation**: build a Redux Toolkit slice for an undo/redo text editor (where time-travel is genuinely useful).
2. **Debugging**: an RTK Query mutation succeeds but the list doesn't refresh — check tag setup.
3. **Architecture**: design a migration plan from a 50-slice RTK store to TanStack Query + Zustand.
4. **Optimization**: a slice causes 200+ component re-renders per dispatch — use `reselect` and shallow comparators.

---

## Common Mistakes

- Using thunks for everything when RTK Query would suffice.
- Selectors returning new objects per call without `reselect` → over-rendering.
- Spreading state in reducers (Immer makes mutate-style safe — use it).
- Storing non-serializable data (functions, class instances) in the store.
- Mixing RTK Query and TanStack Query in the same project (pick one).

---

## Production Red Flags

- **Greenfield 2026 app starting with RTK** as default → likely a ladder-pattern reflex.
- **Slices for transient UI state** (modal open/closed) → use local state or Zustand.
- **Manual normalization with `entities`** when RTK Query's tag system would suffice.

---

## Performance & Metrics (MANDATORY)

- **FPS**: dispatch is fast; perf risk is in selector design and over-rendering.
- **TTI**: Redux store init is ~5-10ms; with persistence rehydration adds more.
- **Memory**: tiny.
- **Thread**: pure JS.
- **Bundle**: ~12-22KB depending on features.
- **Battery**: nil.
- **Optimization**: use `createSelector` from reselect; subscribe with `shallowEqual`; split slices by feature.

---

## Metrics That Matter

- Re-render count per screen (Reassure)
- Dispatch frequency per session
- Bundle size impact

---

## Decision Framework

| Situation | Pick RTK? |
|---|---|
| New app in 2026 | Usually no |
| Existing Redux codebase | Yes (modernize via RTK) |
| Need time-travel debugging | Yes |
| Need saga/observable middleware | Yes |
| Pure server state | No (TanStack Query) |
| Pure UI state | No (Zustand) |
| Undo/redo | Yes (Redux's strength) |
| Real-time collab | Maybe (consider Yjs CRDT instead) |

Migration cost: RTK → TanStack Query is incremental; you can leave RTK in place and add TanStack Query for new features.

---

## Senior-Level Insight

The mature take: **RTK is not "bad", it's "default-no" in 2026**. Senior engineers respect the codebase's history — ripping out a working RTK setup to chase the new shiny is poor judgment. Adding Zustand/TanStack Query for new domains while leaving RTK in place is pragmatic. The org-level decision is "stop investing in Redux as our state strategy" without a forced migration.

Watch out for the inverse error: teams that adopted Zustand because it's trendy and now have 30 disconnected stores with no consistency. Tooling choice without convention is just spreading the problem.

---

## Real-World Scenario

**Symptom:** RTK store's auth slice is causing every screen to re-render on token refresh.
**Investigation:** Components select the entire `auth` object instead of specific fields.
**Root Cause:** `useSelector((s) => s.auth)` returns a new object reference even when fields didn't change (because Immer produces a new object).
**Fix:** Select primitives (`useSelector((s) => s.auth.token)`) or use `shallowEqual`.
**Lesson:** Selector design is everything in Redux.

---

## Production Failure Story

**Incident:** A B2B app's RTK Query cache grew unboundedly because `keepUnusedDataFor` defaulted to 60s but a custom polling setup kept queries "in use" forever.
**Impact:** Memory grew over multi-hour sessions; eventually OOM on Android.
**Investigation:** Memory profiler showed the RTK Query cache holding tens of MB.
**Root Cause:** Polling setup never let queries become unused; cache never gc'd.
**Fix:** Limit polling scope; use `refetchOnFocus` instead of always-on polling; tune `keepUnusedDataFor`.
**Prevention:** Memory regression test; cache size telemetry.

---

## Debugging Checklist

1. Open Redux DevTools; replay actions to find the trigger.
2. Use `useSelector` with `shallowEqual` to test if reference stability is the issue.
3. Check `createSelector` chains for reselect bugs.
4. RTK Query: verify tags + invalidation match.
5. Persistence: check `redux-persist` rehydration timing (don't render until rehydrated).
6. Measure bundle: ensure you're not importing entire RTK + middleware.

---

## Advanced / Internal Knowledge

- RTK uses Immer's `produce` under the hood; reducers receive a `Draft<State>` proxy.
- `createAsyncThunk` returns a thunk action creator; pending/fulfilled/rejected actions have predictable types.
- RTK Query's cache is stored in a slice (`api.reducerPath`) — you can inspect it like any Redux state.
- Subscriptions use `useSyncExternalStore` (React 18+).

---

## 2026 AI Tip

- AI is **good at**: converting old Redux to RTK; generating slices and RTK Query endpoints.
- AI is **bad at**: deciding *whether* to use Redux at all — it'll happily generate Redux for problems better solved otherwise.
- **Hallucination risk**: AI may suggest deprecated `createReducer` with switch statements or old `connect()` HOCs.
- **Prompt pattern**: "Migrate this RTK slice to Zustand, keeping behavior identical, and write equivalent tests."

---

## Related Topics

- Q1 (TanStack Query + Zustand split)
- React 19 Actions / `useOptimistic`
- Migration patterns

---

## Interview Follow-Up Questions

- When would you pick RTK Query over TanStack Query?
- How does Immer make Redux reducers safer?
- Why is selector design so critical in Redux?
- How would you migrate from RTK to TanStack Query incrementally?
- What's the role of redux-persist on mobile, and what are its pitfalls?

---

## Memory Hook

**"RTK is the default of yesterday, the legitimate-choice of today."**

## Revision Notes

> RTK still strong for: time-travel debugging, middleware ecosystem, large existing codebases. Default-no for new server state in 2026.

---

---

### Q3. Optimistic updates and rollback at scale

---

## Difficulty
- Advanced

## Interview Frequency
- Common (asked when role mentions UX polish or fintech/social)

## Prerequisites
- Q1, async/await, basic mutation concepts

## TL;DR
Optimistic updates apply mutation results to the UI immediately, before the server confirms — combined with rollback on failure they make apps feel instant. The 2026 stack is `useMutation` + `onMutate` (TanStack Query) or React 19's `useOptimistic`.

---

## 30-Second Interview Answer

> "Optimistic updates predict the server's response and apply it locally so the UI feels instant. With TanStack Query, you implement them in `onMutate`: cancel in-flight queries for the affected key, snapshot the previous data, write the optimistic value, and on `onError` restore the snapshot. React 19's `useOptimistic` provides a hook-level primitive for the same pattern. The hard parts are: idempotency (mutation must be safe to retry), rollback semantics (what UI state to restore), and conflict resolution (optimistic value disagrees with server response)."

---

## 2-Minute Practical Answer

The pattern in TanStack Query:

```ts
const mutation = useMutation({
  mutationFn: markOrderPaid,
  onMutate: async (orderId) => {
    await queryClient.cancelQueries({ queryKey: ['orders'] });
    const previous = queryClient.getQueryData<Order[]>(['orders']);
    queryClient.setQueryData<Order[]>(['orders'], (old) =>
      old?.map((o) => (o.id === orderId ? { ...o, paid: true } : o)) ?? [],
    );
    return { previous };  // returned context for onError
  },
  onError: (_err, _vars, ctx) => {
    if (ctx?.previous) queryClient.setQueryData(['orders'], ctx.previous);
  },
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['orders'] }),
});
```

Steps:
1. **Cancel pending queries** — avoid race where a refetch lands after our optimistic write.
2. **Snapshot** — keep the pre-optimistic data for rollback.
3. **Write optimistic value** — `setQueryData` with the predicted shape.
4. **On error** — restore snapshot; show user-facing error.
5. **On settled** — invalidate to re-sync with server (handles partial server-side changes).

React 19's `useOptimistic` does this at component level for ephemeral state (most useful for forms / Actions).

---

## 5-Minute Architecture Answer

Optimistic updates trade **correctness latency** for **perceived latency**. The user sees the result instantly; the server confirms (or rejects) milliseconds later. The architecture must handle:

1. **Idempotency**: the mutation may be retried (network blip, optimistic-then-server-then-retry). Server endpoints should be idempotent (idempotency keys, upsert semantics).
2. **Rollback semantics**: what does "undo" look like? Sometimes restoring the snapshot is right (toggle a switch). Sometimes you need to merge with subsequent edits (chat: user typed more after optimistic send). Plan per mutation.
3. **Conflict resolution**: server returns a value different from your optimistic prediction (server-set timestamp, computed fields, validation transformations). The reconciliation strategy is per-domain — usually server wins, sometimes merge.
4. **Telemetry**: track optimistic-then-rollback rate. High rate means your prediction model is wrong; investigate.
5. **Offline handling**: optimistic updates work especially well offline — the user's action lands locally immediately, queues for sync. (See S11 for offline patterns.)
6. **UX cues**: subtle "syncing" indicators for in-flight optimistic state; clear error UX on failure (toast + restored state).

The deeper insight: optimistic UI is a **trust contract** with the user. You promise that what they see is what will happen. Failures must be communicated clearly; silent rollback erodes trust faster than a slow API.

---

## The "Why"

Mobile networks are unreliable. Even on great connections, RTT to a backend can be 50-300ms. A 200ms delay between tap and visual feedback feels sluggish. Optimistic updates compress that to <16ms (next frame). Companies care because perceived performance is the dominant UX metric — Instagram's like button, Twitter's retweet, Slack's reactions all use optimistic UI to feel instant. Without it, the app feels broken on cellular networks even when nothing is wrong.

---

## Mental Model

Optimistic UI = a waiter writing your order on the kitchen board *before* getting it confirmed by the chef. If the chef rejects (out of stock), the waiter erases and apologizes. The customer felt heard immediately; the rare correction is the cost of speed.

---

## Internal Working (2026 Context)

TanStack Query mutation lifecycle:

```
mutate(args)
   │
   ▼
onMutate(args) → returns context (optional)
   │
   ▼ (parallel)
   │      mutationFn(args) executes
   │           │
   │           ▼
   │      ┌── success ──┐         ┌── error ──┐
   │      ▼             │         ▼            │
   │  onSuccess(data,   │     onError(err,    │
   │     args, ctx)     │       args, ctx)    │
   │      │             │         │           │
   │      └─────────────┴─────────┘           │
   │                    │                      │
   │                    ▼                      │
   │              onSettled(data?, err?, args, ctx)
```

Key points:
- `onMutate` runs synchronously before the network call — that's where you do optimistic writes.
- The returned `context` flows to all later callbacks for rollback data.
- `onSettled` always runs (success or error) — perfect for invalidation/refetch.

React 19's `useOptimistic`:
- Returns `[optimisticValue, addOptimistic]`.
- `addOptimistic(value)` immediately updates `optimisticValue` for the current transition.
- When the underlying state (props) updates, optimistic state resets.
- Designed to compose with Actions (`<form action={...}>`).

Threading: all on JS thread; the UI updates because React re-renders synchronously (or in a transition).

---

## Modern Implementation (Code)

**TanStack Query optimistic mutation:**

```tsx
// useToggleLike.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toggleLike } from '@/api/posts';
import type { Post } from '@/types';

export function useToggleLike(postId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => toggleLike(postId),
    onMutate: async () => {
      await qc.cancelQueries({ queryKey: ['post', postId] });
      const prev = qc.getQueryData<Post>(['post', postId]);
      qc.setQueryData<Post>(['post', postId], (p) =>
        p ? { ...p, liked: !p.liked, likes: p.likes + (p.liked ? -1 : 1) } : p,
      );
      return { prev };
    },
    onError: (_err, _vars, ctx) => {
      if (ctx?.prev) qc.setQueryData(['post', postId], ctx.prev);
    },
    onSettled: () => qc.invalidateQueries({ queryKey: ['post', postId] }),
  });
}
```

**React 19 useOptimistic + Action:**

```tsx
// CommentForm.tsx
import { useOptimistic, useState } from 'react';

type Comment = { id: string; text: string; pending?: boolean };

export function CommentList({ initial, postComment }: {
  initial: Comment[];
  postComment: (text: string) => Promise<Comment>;
}) {
  const [comments, setComments] = useState(initial);
  const [optimisticComments, addOptimistic] = useOptimistic(
    comments,
    (state, newText: string) => [
      ...state,
      { id: `temp-${Date.now()}`, text: newText, pending: true },
    ],
  );

  async function action(formData: FormData) {
    const text = formData.get('text') as string;
    addOptimistic(text);
    const real = await postComment(text);
    setComments((c) => [...c, real]);
  }

  return (
    <>
      {optimisticComments.map((c) => (
        <Text key={c.id} style={{ opacity: c.pending ? 0.5 : 1 }}>{c.text}</Text>
      ))}
      <form action={action}>
        <TextInput name="text" />
        <SubmitButton />
      </form>
    </>
  );
}
```

---

## Comparison

| Approach | TanStack `onMutate` | React 19 `useOptimistic` |
|---|---|---|
| Scope | global cache | local component |
| Rollback | manual via context | automatic on state update |
| Retry | configurable per mutation | manual |
| Best for | data shared across screens | form-local UI |
| Composability | with Query cache | with Actions |

| Strategy | Use when |
|---|---|
| Optimistic + invalidate on settle | most cases |
| Optimistic + setQueryData with server response | mutation returns the canonical entity |
| No optimistic, just loading state | rare, destructive ops (delete account) |
| Pessimistic with confirmation modal | irreversible actions |

---

## Production Usage

- **Likes / reactions** — instant feedback essential.
- **Toggles** (favorite, pin, archive) — same.
- **Comment posting** — appears immediately with "sending" state.
- **Cart updates** — quantity changes feel snappy.
- **Status changes** (mark as read, mark paid) — optimistic with rollback.
- **DON'T optimistic for**: payments, irreversible deletes, identity changes — confirm first.

Scaling: standardize the optimistic pattern in your design system / data layer; provide a `useOptimisticMutation` wrapper that encodes cancel + snapshot + restore.

---

## Hands-On Exercise

1. **Implementation**: build a like button with optimistic update, rollback on failure, and a "syncing" indicator for in-flight state.
2. **Debugging**: optimistic update flickers — old value briefly visible after server response. Diagnose (likely missing `cancelQueries`).
3. **Architecture**: design optimistic UX for a chat app where messages can fail and need retry.
4. **Optimization**: 100 simultaneous optimistic updates jank the UI — batch them or use transitions.

---

## Common Mistakes

- Skipping `cancelQueries` → race with in-flight refetch overwrites your optimistic value.
- No rollback in `onError` → inconsistent UI on failure.
- Optimistic for non-idempotent ops without idempotency keys → duplicate server state.
- Trusting optimistic value as canonical → ID mismatches when server assigns real IDs.
- Showing optimistic state without any "pending" indicator → user can't tell what's confirmed.

---

## Production Red Flags

- **No optimistic UI anywhere** → laggy app on cellular.
- **Optimistic everywhere including payments** → dangerous, user thinks something happened that didn't.
- **Silent rollback** (no error toast) → users confused when state "reverts mysteriously".
- **No telemetry on optimistic-rollback rate** → flying blind.

---

## Performance & Metrics (MANDATORY)

- **FPS**: optimistic updates run on JS thread; if mutation triggers heavy re-render, can cause frame drops. Use `startTransition` for large updates.
- **TTI**: nil impact.
- **Memory**: snapshot adds O(query data size); negligible.
- **Battery / data**: same as without optimistic; mutation still hits server.
- **Perceived latency**: drops from 100-300ms to <16ms (next frame).
- **Optimization**: batch optimistic updates with `unstable_batchedUpdates` or transitions.

---

## Metrics That Matter

- Optimistic-rollback rate (telemetry on `onError` after `onMutate`)
- Time-to-feedback (tap → visual change)
- User-perceived NPS / app-feel surveys

---

## Decision Framework

| Action type | Use optimistic? |
|---|---|
| Reaction / like | Yes |
| Toggle / pin | Yes |
| Comment / message | Yes (with pending state) |
| Cart update | Yes |
| Marking read | Yes |
| Payment | No |
| Account deletion | No |
| Password change | No |
| Bulk delete | Confirm first, then optimistic |

---

## Senior-Level Insight

Optimistic UX is a **product decision masquerading as a technical one**. Engineers default to "should we make it optimistic?" but the right question is "what's the user's mental model when this fails?" For a like button, momentary failure is fine. For a payment, a momentary "success" that rolls back is catastrophic. Senior engineers map mutation type to UX promise before choosing technical strategy.

Org-level: maintain a registry of "blessed optimistic mutations" with documented rollback UX; review new mutations against the list. Don't let every team invent their own pattern.

---

## Real-World Scenario

**Symptom:** User likes a post; like count flashes to +1, then back to 0, then back to +1.
**Investigation:** Devtools show three setQueryData calls + a refetch in quick succession.
**Root Cause:** No `cancelQueries`; an in-flight feed refetch landed mid-mutation, overwrote optimistic, then settled refetch fixed it.
**Fix:** Add `await qc.cancelQueries(...)` at start of `onMutate`.
**Lesson:** Cancel before optimistic write, always.

---

## Production Failure Story

**Incident:** A fintech app's "transfer money" button used optimistic UI. ~0.3% of users saw "Transfer complete" then "Transfer failed" 2 seconds later because the backend rejected for insufficient funds. Confusion and support tickets spiked.
**Impact:** ~500 support tickets in 24h; brand trust dent.
**Investigation:** Optimistic UI was applied regardless of mutation type.
**Root Cause:** Engineering default was "optimistic everywhere"; financial mutations were not exempted.
**Fix:** Reverted financial mutations to pessimistic UI with explicit pending modal; ML model now warns on optimistic patterns near `payments` / `transfers` keywords in code review.
**Prevention:** Mutation classification framework in design system: `safe-optimistic | confirm-then-optimistic | pessimistic`. Default for `$$$` flows is `pessimistic`.

---

## Debugging Checklist

1. Verify `await qc.cancelQueries` runs before `setQueryData`.
2. Verify rollback uses the snapshot from `onMutate` context.
3. Check `onSettled` invalidation key matches affected queries.
4. Inspect Devtools to see mutation lifecycle states.
5. For React 19 useOptimistic: ensure underlying state updates after action completes.
6. Telemetry: `(onError after onMutate)` count — is it spiking?

---

## Advanced / Internal Knowledge

- TanStack Query's `cancelQueries` aborts in-flight `signal`-aware fetches; if `queryFn` doesn't honor signal, cancellation is best-effort.
- `setQueryData` triggers structural sharing — if your update produces equal data, no re-render.
- React 19's `useOptimistic` uses concurrent transitions; optimistic state survives re-renders within the transition.
- `useOptimistic` resets when the source state updates — this is intentional but can surprise (don't store mutable derived state in optimistic value).

---

## 2026 AI Tip

- AI is **good at**: scaffolding `onMutate`/`onError`/`onSettled` boilerplate.
- AI is **bad at**: knowing when NOT to use optimistic UI. Push back when AI optimistically suggests optimism for destructive ops.
- **Prompt pattern**: "Generate an optimistic mutation for `markPaid` on order `id`, with rollback, idempotency key, and a 'syncing' indicator."

---

## Related Topics

- Q1 TanStack Query
- S2 React 19 Actions / `useOptimistic`
- S11 Offline mutation queues

---

## Interview Follow-Up Questions

- Why must you `cancelQueries` before writing optimistic data?
- How do you handle optimistic state when the server assigns the real ID?
- When is optimistic UI the wrong choice?
- How would you design a retry queue for failed mutations?
- How do you tell from telemetry that your optimistic predictions are wrong?

---

## Memory Hook

**"Predict, snapshot, write; on error, restore; always invalidate."** Five steps, one button feels instant.

## Revision Notes

> Optimistic UI = perceived latency win for safe mutations. Always: cancel → snapshot → write → rollback on error → invalidate on settle. Never optimistic for payments/destructive ops.

---

---

### Q4. Cache invalidation strategies — query key design and mutation flows

---

## Difficulty
- Advanced

## Interview Frequency
- Common (asked when discussing caching at scale)

## Prerequisites
- Q1, Q3, basic caching concepts

## TL;DR
Cache invalidation is "the hardest problem in computer science" because it's *design*, not just code. In TanStack Query, design hierarchical query keys (`[domain, scope, params]`) so you can invalidate by prefix; pair with mutations that invalidate the smallest possible scope.

---

## 30-Second Interview Answer

> "Invalidation strategy is query-key design. TanStack Query matches keys by prefix, so a key like `['orders', userId, { status: 'pending' }]` lets you invalidate `['orders']` (everything), `['orders', userId]` (one user), or precisely (`['orders', userId, { status: 'pending' }]`). The trick is to design keys hierarchically so mutations can invalidate the smallest possible scope. Over-invalidation kills perf; under-invalidation creates stale UI."

---

## 2-Minute Practical Answer

The decision points:

1. **Key shape**: array of `[domain, scope, params]`. Domain = table/resource (`'orders'`). Scope = ID or category (`userId`). Params = filters/sort (`{ status, sort }`). This shape enables prefix matching.
2. **Granularity**: too narrow keys (every filter combo) explode cache size. Too broad keys (one key for all orders) lose deduplication. Aim for the natural cardinality of your queries.
3. **Invalidation strategy**:
   - **Tag-based** (RTK Query): mutations declare `invalidatesTags`; queries declare `providesTags`.
   - **Key-based** (TanStack Query): mutations call `invalidateQueries({ queryKey, exact: false })`.
   - **Direct write** (`setQueryData`): when you know the new value, skip refetch.
4. **Mutation flow**:
   - Server returns canonical entity → `setQueryData` for the entity, `invalidateQueries` for affected lists.
   - Server returns side effects (e.g., paying an order updates user balance) → invalidate affected queries (`['user', userId]`).
5. **Stale-time vs invalidation**: `staleTime` is a passive bound (fetch happens when stale); invalidation is active (fetch right now). Use both.

---

## 5-Minute Architecture Answer

Cache invalidation has three failure modes:

1. **Stale UI** — under-invalidation. User pays an order, list still shows it as pending. Annoying.
2. **Over-fetching** — over-invalidation. Every minor mutation invalidates the world; perf collapses.
3. **Cache fragmentation** — keys with too much variance, low hit rate, memory bloat.

The architectural answer is **explicit hierarchy**:

```ts
// keys.ts — single source of truth
export const orderKeys = {
  all: ['orders'] as const,
  lists: () => [...orderKeys.all, 'list'] as const,
  list: (filters: OrderFilters) => [...orderKeys.lists(), filters] as const,
  details: () => [...orderKeys.all, 'detail'] as const,
  detail: (id: string) => [...orderKeys.details(), id] as const,
};

// usage
useQuery({ queryKey: orderKeys.list({ status: 'pending' }), queryFn: ... });
useQuery({ queryKey: orderKeys.detail(orderId), queryFn: ... });

// mutation
qc.invalidateQueries({ queryKey: orderKeys.lists() }); // all order lists
qc.invalidateQueries({ queryKey: orderKeys.detail(orderId) }); // one detail
```

Benefits:
- Single source of truth for keys; no typos across files.
- Hierarchical structure makes invalidation precise.
- Refactors are tractable (rename `orderKeys.detail` once).

For **GraphQL** (Apollo, urql), normalization handles invalidation differently: every entity has an ID, and mutations return updated entities, which automatically update all queries that reference them. This is a different model and works well for highly relational data.

For **offline-aware** systems (S11), invalidation is paired with a mutation queue: optimistic write → queue mutation → on success, invalidate; on permanent failure, rollback + alert.

The 2026 specific: **React 19 Actions** integrate with TanStack Query — an Action that mutates can invalidate queries directly. RSC (where used) lets you invalidate on the server side and stream new data, but RN's RSC story is still nascent.

---

## The "Why"

Caches exist to make UIs fast. Invalidation exists because data goes stale. The wrong invalidation strategy creates either constant refetches (battery, bandwidth, server load) or stale data (broken UX, user mistrust). At scale (10+ engineers, 100+ queries) without a system, invalidation becomes the #1 source of "ghost bugs" — UI doesn't refresh, no one knows why, fixes are local hacks. Companies care because cache strategy is invisible until it breaks, then it's expensive everywhere at once.

---

## Mental Model

Query keys are folder paths in a filesystem. Invalidation is `rm -rf path/`. Hierarchical paths (`/orders/list/pending`) let you delete precisely or broadly. Flat paths (`/orders_list_pending`) force binary choices.

---

## Internal Working (2026 Context)

- TanStack Query stores queries in a Map keyed by stringified query keys. `invalidateQueries({ queryKey })` matches keys whose first N elements equal the given key (prefix match).
- `exact: true` requires full equality; `exact: false` (default) does prefix match.
- After invalidation, queries with active observers refetch immediately; idle queries refetch on next mount.
- `setQueryData` writes directly to cache without fetching — used when you have the new value.
- Structural sharing means re-renders only happen for components whose `select`-output changed.

---

## Modern Implementation (Code)

```ts
// keys.ts
export const keys = {
  orders: {
    all: ['orders'] as const,
    list: (filters: OrderFilters) => ['orders', 'list', filters] as const,
    detail: (id: string) => ['orders', 'detail', id] as const,
  },
  user: {
    me: () => ['user', 'me'] as const,
    balance: (userId: string) => ['user', userId, 'balance'] as const,
  },
};
```

```ts
// usePayOrder.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { keys } from '@/queries/keys';
import { payOrder } from '@/api/orders';

export function usePayOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: payOrder,
    onSuccess: (paidOrder, vars) => {
      // direct write for the entity we know
      qc.setQueryData(keys.orders.detail(paidOrder.id), paidOrder);
      // invalidate lists (they may include or exclude this order)
      qc.invalidateQueries({ queryKey: ['orders', 'list'] });
      // invalidate user balance (side effect)
      qc.invalidateQueries({ queryKey: keys.user.balance(vars.userId) });
    },
  });
}
```

---

## Comparison

| Strategy | TanStack Query | RTK Query | Apollo |
|---|---|---|---|
| Mechanism | prefix-match invalidation | tag-based | normalization |
| Cache shape | per-key entries | per-endpoint + tags | normalized graph |
| Mutation declaration | call `invalidateQueries` | `invalidatesTags` | mutation returns entity |
| Granularity control | manual via key design | tag granularity | per-entity |
| Best for | REST, mixed | REST | GraphQL |

| Operation | Strategy |
|---|---|
| Entity created | invalidate lists; setQueryData detail |
| Entity updated | setQueryData detail + maybe lists |
| Entity deleted | invalidate lists; remove detail |
| Cross-entity side effect | invalidate affected entities |
| Bulk operation | invalidate at the broadest necessary scope |

---

## Production Usage

- **List + detail patterns** dominate: invalidate list when entity changes, write detail directly.
- **Search results**: don't invalidate on every keystroke — debounce + new key per query.
- **Pagination** (`useInfiniteQuery`): invalidate the entire infinite query (it'll refetch all pages or just first depending on config).
- **Real-time sync** (WebSocket): server pushes update → `setQueryData` for affected entity, `invalidateQueries` for affected lists.

Scaling: as the app grows, key conventions become organizational law — without them, teams diverge and invalidation bugs proliferate.

---

## Hands-On Exercise

1. **Implementation**: build a `keys.ts` for an e-commerce app (products, cart, orders, user) and use it across mutations.
2. **Debugging**: a list doesn't refresh after a mutation; trace through invalidation to find the missing key.
3. **Architecture**: design a cache invalidation strategy for a chat app where messages, threads, and user presence all interact.
4. **Optimization**: a mutation invalidates 50 queries; reduce to 2 by improving key design.

---

## Common Mistakes

- Inline keys (`['orders', userId]`) scattered across files — refactors are painful.
- Invalidation too broad (`invalidateQueries(['orders'])` for a single entity update) — refetches unnecessarily.
- Invalidation too narrow — UI shows stale data.
- Mixing `setQueryData` + `invalidateQueries` for the same data — race conditions.
- Forgetting cross-entity side effects (paying an order changes user balance too).

---

## Production Red Flags

- **No keys.ts file** in a 50-screen app — convention chaos.
- **`invalidateQueries()` with no arg** anywhere — nuking the entire cache.
- **Manual local-state mirrors** of cached data — invalidation hell.
- **Cache size telemetry not collected** — silent memory bloat.

---

## Performance & Metrics (MANDATORY)

- **FPS**: invalidation triggers refetches → renders. If many at once, can jank.
- **TTI**: cache hits are instant; cache misses block on network.
- **Memory**: cache size = sum of all query data; tune `gcTime` to bound.
- **Battery / data**: over-invalidation spikes both.
- **Optimization**: prefer `setQueryData` over invalidation when you have canonical data; invalidate at the smallest necessary scope.

---

## Metrics That Matter

- Cache hit rate
- Refetch count per session
- Time between mutation and UI consistency
- Cache memory footprint

---

## Decision Framework

| Mutation effect | Strategy |
|---|---|
| Updates entity | `setQueryData(detail)` + invalidate lists |
| Creates entity | invalidate lists |
| Deletes entity | remove detail + invalidate lists |
| Affects related entities | invalidate each |
| Bulk import | invalidate at broad scope |
| Optimistic | `setQueryData` in `onMutate`, invalidate on settle |

---

## Senior-Level Insight

The deeper insight: **cache invalidation is an API contract design problem**, not a frontend problem. If your backend returns rich responses (the updated entity + side-effect deltas), frontend invalidation becomes trivial. If your backend returns only `{ ok: true }`, you must guess what changed and over-invalidate to be safe. Push for richer mutation responses; the cache strategy follows.

Org-level: maintain `keys.ts` as a versioned contract; reviews must touch it for any new query/mutation. Document side effects per mutation (a "depends on" graph). For large orgs, consider a typed mutation framework that generates invalidation calls from declared dependencies.

---

## Real-World Scenario

**Symptom:** After paying an order, the orders list updates but the user's balance shown in the header doesn't.
**Investigation:** Mutation invalidated `['orders']` but not `['user', 'balance']`.
**Root Cause:** Engineer didn't realize the side effect crossed entity boundaries.
**Fix:** Add `qc.invalidateQueries({ queryKey: keys.user.balance(userId) })` to the mutation's `onSuccess`.
**Lesson:** Mutations have side effects beyond their primary entity; document them explicitly.

---

## Production Failure Story

**Incident:** A workplace SaaS app's feed flooded the API with 1000 requests/min during peak hours.
**Impact:** Backend autoscaled but cost spiked 3×; users saw spinners on every interaction.
**Investigation:** Each comment post invalidated `['feed']` — feed has 50 entries, each invalidation triggered a refetch from N components subscribed.
**Root Cause:** Over-invalidation: comment on post X shouldn't invalidate the entire feed.
**Fix:** Mutations now invalidate `['post', postId, 'comments']` only; feed list itself is stale-time-bounded (60s).
**Prevention:** Cost telemetry on API; lint rule warning on invalidation of high-fanout keys; pre-merge review of new mutation invalidation patterns.

---

## Debugging Checklist

1. Open Devtools; inspect cache after mutation — what changed?
2. Verify keys match between query and invalidation (typos, shape mismatches).
3. Check `gcTime` — query may have been evicted before invalidation.
4. For optimistic + invalidate: verify cancel before write order.
5. Trace which components are subscribed to invalidated keys; are they re-rendering correctly?

---

## Advanced / Internal Knowledge

- TanStack Query keys are stringified for hashmap lookup; objects in keys are deep-stringified deterministically.
- `invalidateQueries` accepts `predicate` for arbitrary matching beyond prefix.
- `removeQueries` evicts without refetch (vs invalidate which refetches active).
- RTK Query tags use a string-tag system; tag IDs (`{ type: 'Order', id: 1 }`) enable per-entity invalidation.
- Apollo's normalized cache uses entity IDs (`__typename` + `id`) automatically.

---

## 2026 AI Tip

- AI is **good at**: generating `keys.ts` factories, suggesting invalidation patterns.
- AI is **bad at**: detecting cross-entity side effects without product context. Always review.
- **Prompt pattern**: "Given these mutations and their server-side side effects, generate the TanStack Query invalidation calls for each."

---

## Related Topics

- Q1, Q3
- S9 Networking — request lifecycle
- S11 Offline mutation queues

---

## Interview Follow-Up Questions

- Why is hierarchical key design important?
- When would you use `setQueryData` instead of invalidation?
- How do you handle a mutation that affects 5 different entities?
- What's the cost of over-invalidation in production?
- How does Apollo's normalization differ from TanStack Query's invalidation?

---

## Memory Hook

**"Keys hierarchical, invalidation surgical, writes direct."** Three rules, a sane cache.

## Revision Notes

> Design keys as `[domain, scope, params]` in a `keys.ts` factory. Invalidate at the smallest necessary scope. `setQueryData` when you have canonical data. Track cross-entity side effects explicitly.

---

---

### Q5. Offline mutation queues and idempotency

---

## Difficulty
- Advanced → Architect

## Interview Frequency
- Common (asked for offline-first, fintech, ride-share roles)

## Prerequisites
- Q3, Q4, basic networking + persistence

## TL;DR
Offline-first apps queue mutations to disk while disconnected and replay them on reconnect — paired with server-side idempotency keys to safely handle retries and duplicates.

---

## 30-Second Interview Answer

> "Offline mutations need three things: a durable queue (MMKV/SQLite), idempotency keys (so server-side replays are safe), and a sync engine that drains the queue on reconnect with backoff and conflict handling. TanStack Query's `persistQueryClient` plus a custom mutation persister handles much of this; for fintech-grade reliability you build a dedicated mutation log (event-sourced) and reconcile against server state on reconnect. The hardest part is conflict resolution when the user's offline change collides with a server-side change."

---

## 2-Minute Practical Answer

The pattern:

1. **Optimistic update** when user acts offline (`onMutate` writes to cache).
2. **Persist mutation** to disk with: idempotency key (UUID), payload, timestamp, retry count.
3. **Try to send**; on success → mark sent, invalidate queries, remove from queue. On network failure → keep in queue, retry on reconnect.
4. **On reconnect** (NetInfo listener), drain the queue in order. Handle conflicts (server returned 409 → reconcile).
5. **Idempotency**: server rejects duplicate idempotency keys (same request repeated → returns original response, doesn't re-execute).

Components:
- **Persistor**: MMKV for small payloads (KB scale), SQLite (op-sqlite) for larger queues or relational data.
- **Network detector**: `@react-native-community/netinfo` + `onlineManager` integration with TanStack Query.
- **Retry policy**: exponential backoff with jitter; max attempts; permanent-failure dead letter.
- **Conflict resolution**: last-write-wins (simple), CRDTs (complex collaborative apps), domain-specific merge.

---

## 5-Minute Architecture Answer

Offline mutation queues are an **event sourcing** problem:

```
User action (offline)
   │
   ▼
Local optimistic update (TanStack Query cache write)
   │
   ▼
Mutation log entry persisted (MMKV/SQLite)
   │  [idempotency_key, type, payload, ts, attempts]
   │
   ▼
Network status: offline → wait
                 online → drain
   │
   ▼
For each entry in order:
   ├── POST with Idempotency-Key header
   │       │
   │       ├── 200 → mark sent, invalidate queries, remove entry
   │       ├── 409 conflict → resolve (merge / drop / surface to user)
   │       ├── 4xx other → permanent fail, dead letter, rollback optimistic
   │       └── 5xx / network → backoff, retry
   │
   ▼
Sync complete
```

Considerations:

1. **Ordering**: mutations may have dependencies (create user → create order). Queue must preserve order, or mutations must be commutative.
2. **Idempotency key strategy**: client-generated UUID per intent; server stores a window of recent keys (e.g., 24h) and returns cached response for duplicates.
3. **Conflict resolution policies**:
   - **Last-write-wins**: simplest; lose user data sometimes.
   - **Server-wins**: user changes discarded if server changed.
   - **Client-wins**: user changes overwrite server.
   - **Merge**: domain-specific (CRDT, three-way merge).
   - **Surface to user**: present conflict UI ("you and someone else edited this; keep yours / theirs").
4. **Dead letter queue**: mutations that permanently fail (validation, auth) need a recovery path — usually surfaced in UI as "this didn't sync, retry / discard".
5. **Storage limits**: MMKV is fast but should hold KB scale; for large or relational queues, SQLite (op-sqlite is the 2026 default).
6. **Security**: queued mutations may contain sensitive data; encrypt at rest (Keychain-wrapped key + MMKV encryption, or SQLCipher).
7. **Telemetry**: queue depth, sync latency, failure rate, conflict rate.

The 2026 specific: tools like **TanStack Query persistor**, **WatermelonDB sync**, and **PowerSync** offer turnkey offline-first patterns; for fintech and ride-share, custom event-sourced systems remain common.

---

## The "Why"

Mobile networks fail constantly: subway, elevators, rural areas, flaky WiFi. Apps that lose user data on disconnect are unusable for many real-world flows. Offline-first design makes the network an optional optimization, not a requirement. Companies care because offline reliability is the difference between an app that's usable everywhere and one that's only usable on perfect WiFi.

---

## Mental Model

Think of an old-fashioned mailbox: you drop letters in (mutations), the mail carrier picks them up when available (sync). Each letter has a tracking number (idempotency key) so even if you accidentally drop two copies, the post office only delivers one.

---

## Internal Working (2026 Context)

- **NetInfo** listens to OS network change events; integrates with TanStack Query's `onlineManager`.
- **TanStack Query persistor** serializes the cache (queries + mutations) to storage; on app boot, rehydrates so cached data is immediately available.
- **Mutation persister** stores in-flight + queued mutations; on reconnect, replays them.
- **op-sqlite** uses JSI for synchronous SQLite calls — much faster than legacy `react-native-sqlite-storage` (which uses the bridge).
- **MMKV** uses memory-mapped files via JSI; fast, persistent, encryptable.

Threading: persistence I/O can run on background threads via JSI in op-sqlite/MMKV; TanStack Query orchestration is on JS thread.

---

## Modern Implementation (Code)

```ts
// queue.ts — minimal mutation queue
import { MMKV } from 'react-native-mmkv';
import { v4 as uuid } from 'uuid';

const storage = new MMKV({ id: 'mutation-queue' });

export type QueuedMutation = {
  id: string;        // idempotency key
  type: string;      // discriminator
  payload: unknown;
  ts: number;
  attempts: number;
};

const KEY = 'pending';

export function enqueue(m: Omit<QueuedMutation, 'id' | 'ts' | 'attempts'>): QueuedMutation {
  const entry: QueuedMutation = { ...m, id: uuid(), ts: Date.now(), attempts: 0 };
  const list = read();
  list.push(entry);
  storage.set(KEY, JSON.stringify(list));
  return entry;
}

export function read(): QueuedMutation[] {
  const s = storage.getString(KEY);
  return s ? JSON.parse(s) : [];
}

export function remove(id: string) {
  const list = read().filter((x) => x.id !== id);
  storage.set(KEY, JSON.stringify(list));
}

export function bumpAttempts(id: string) {
  const list = read().map((x) => (x.id === id ? { ...x, attempts: x.attempts + 1 } : x));
  storage.set(KEY, JSON.stringify(list));
}
```

```ts
// sync.ts — drainer
import NetInfo from '@react-native-community/netinfo';
import { read, remove, bumpAttempts, type QueuedMutation } from './queue';
import { sendMutation } from '@/api/sync';

const handlers: Record<string, (m: QueuedMutation) => Promise<void>> = {
  payOrder: async (m) => sendMutation('/orders/pay', m.payload, m.id),
  // ...
};

let draining = false;

export async function drain() {
  if (draining) return;
  draining = true;
  try {
    const queue = read();
    for (const m of queue) {
      try {
        await handlers[m.type](m);
        remove(m.id);
      } catch (err: any) {
        bumpAttempts(m.id);
        if (err.status >= 400 && err.status < 500 && err.status !== 409) {
          // permanent fail — move to dead letter (omitted)
          remove(m.id);
        } else {
          // transient — leave in queue; will retry next drain
          break;
        }
      }
    }
  } finally {
    draining = false;
  }
}

NetInfo.addEventListener((state) => {
  if (state.isConnected) drain().catch(console.warn);
});
```

```ts
// usage in mutation hook
import { enqueue } from './queue';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { drain } from './sync';

export function usePayOrderOffline() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (orderId: string) => {
      const entry = enqueue({ type: 'payOrder', payload: { orderId } });
      drain().catch(console.warn);
      return entry;
    },
    onMutate: async (orderId) => {
      // optimistic write
      qc.setQueryData(['order', orderId], (old: any) => ({ ...old, paid: true, _pending: true }));
    },
  });
}
```

---

## Comparison

| Approach | Best for | Cons |
|---|---|---|
| TanStack Query persistor + custom drain | Most apps | Manual conflict handling |
| WatermelonDB sync | Relational offline-first | Steeper learning curve |
| PowerSync (2026) | SQLite-based bidirectional sync | Backend coupling |
| Custom event-sourced | Fintech, audit-heavy | Complex; maintain yourself |
| CRDTs (Yjs/Automerge) | Collaborative editing | Memory cost; not for transactional |

| Storage | Use for |
|---|---|
| MMKV | small queue, fast access, KB-scale |
| op-sqlite | large queue, complex queries, MB-scale |
| WatermelonDB | offline-first relational |
| Realm | offline-first object store with sync |

---

## Production Usage

- **Fintech**: payment intents queued with idempotency keys; bank-grade.
- **Ride-share**: location updates buffered offline, replayed on reconnect.
- **E-commerce**: cart updates, wishlist toggles.
- **Field-service apps**: form submissions queued when offline.
- **Chat**: outbound messages queued; recipients see "sending"/"sent" states.

Scaling: for >1000 queued mutations per device, move to SQLite; for >10k, partition by feature.

---

## Hands-On Exercise

1. **Implementation**: build the queue + drainer above, add exponential backoff, dead letter queue, and a UI that shows pending mutation count.
2. **Debugging**: queue grows unboundedly because permanent failures aren't moved to dead letter. Fix.
3. **Architecture**: design conflict resolution for a collaborative document where two users edit offline simultaneously.
4. **Optimization**: drainer blocks the JS thread when queue is large — make it batch-yield.

---

## Common Mistakes

- No idempotency keys → server processes duplicates on retry.
- Order-sensitive mutations sent in parallel → race conditions.
- Dead letter not surfaced to user → silent data loss.
- No max-attempts → queue retries forever, drains battery.
- Optimistic write without persisting the queued mutation → lost on app restart.
- Storing PII in plain MMKV → privacy/security issue.

---

## Production Red Flags

- **No queue** in a fintech/ride-share app → unfit for purpose.
- **No idempotency keys** → servers will process duplicates.
- **No telemetry on queue depth / failure rate** → flying blind.
- **Sync runs on every render** → battery and CPU waste.

---

## Performance & Metrics (MANDATORY)

- **FPS**: drainer must yield (don't process 1000 entries synchronously); use `requestIdleCallback` or batched processing.
- **Memory**: queue size in memory + on disk; bound it.
- **Battery**: aggressive retries on bad networks drain battery; use exponential backoff with cap.
- **Data**: failed retries waste data; respect backoff.
- **Storage**: encrypted MMKV ~negligible overhead; SQLCipher slight cost.

---

## Metrics That Matter

- Queue depth (current + max in last hour)
- Sync latency (queued → sent)
- Permanent failure rate
- Conflict rate
- Battery impact (RUM)

---

## Decision Framework

| Need | Pick |
|---|---|
| Simple offline mutations | MMKV queue + custom drainer |
| Rich offline data with relations | WatermelonDB / op-sqlite |
| Bidirectional sync of large datasets | PowerSync / Realm Sync |
| Collaborative real-time editing | CRDTs (Yjs / Automerge) |
| Fintech / regulated | Custom event-sourced log |

---

## Senior-Level Insight

The deeper truth: **offline-first is an architecture, not a feature**. You can't bolt it on at the end. The data model, mutation API, and conflict policy must be designed for it from day one. Apps that try to retrofit offline-first usually end up with unreliable hybrids.

The 2026 specific: as Apple and Google both push for resilience to network loss (Privacy Sandbox features, in-app browser restrictions), offline-first capability is increasingly a baseline expectation for any serious mobile app. Senior engineers should be able to design the queue + sync engine from scratch in an interview.

Org-level: have one offline subsystem owned by a foundation team; per-feature teams build on top. Conflict resolution policy is a product decision, not engineering — engage product/design early.

---

## Real-World Scenario

**Symptom:** Users report that toggling a "favorite" button doesn't persist after airplane mode + reconnect.
**Investigation:** Optimistic write happens; `enqueue` runs, but `MMKV.set` is called inside an async function that's never awaited.
**Root Cause:** The optimistic toggle wrote to cache but the queue persist call was lost.
**Fix:** Make `enqueue` synchronous (MMKV is sync); ensure persist happens before optimistic UI.
**Lesson:** Optimistic write without persisted mutation = data loss on restart.

---

## Production Failure Story

**Incident:** A delivery app's drivers lost ~5% of completed-delivery confirmations during a major network outage.
**Impact:** Drivers had to re-enter completions; some duplicate payments processed.
**Investigation:** Mutations queued correctly but drainer didn't restart after app was force-killed mid-drain. Idempotency keys weren't unique per attempt — server saw duplicates as new.
**Root Cause:** Two bugs: (1) drainer state not persisted across app launches; (2) idempotency keys regenerated on retry.
**Fix:** Persist drainer state; idempotency keys are stable per logical mutation, generated once at enqueue.
**Prevention:** Chaos test: force-kill app mid-sync, assert no data loss; randomized network failure test in CI.

---

## Debugging Checklist

1. Inspect MMKV/SQLite contents — is the queue persisting?
2. Trace NetInfo events — is reconnect detected?
3. Verify idempotency keys are stable across retries.
4. Check server returns the same response for duplicate keys.
5. Telemetry on queue depth / drain frequency.
6. Force kill + relaunch test for resilience.

---

## Advanced / Internal Knowledge

- Idempotency keys are typically UUIDv4 or content-hashes; server stores in Redis / DB with TTL.
- Conflict resolution can use vector clocks / Lamport timestamps for ordering across distributed devices.
- CRDTs (Yjs, Automerge) provide automatic merge for collaborative data; cost is memory per operation.
- WatermelonDB uses a `change tracking` model: every record has `_status` and `_changed`; sync engine batches changes to/from server.
- op-sqlite via JSI: synchronous SQLite calls without bridge serialization → 10× faster than legacy lib.

---

## 2026 AI Tip

- AI is **good at**: scaffolding the queue + drainer pattern.
- AI is **bad at**: conflict resolution semantics — those are product decisions.
- **Hallucination risk**: AI may suggest non-idempotent retry patterns. Verify.
- **Prompt pattern**: "Build an offline mutation queue with MMKV persistence, idempotency keys, exponential backoff, dead letter, and TanStack Query integration."

---

## Related Topics

- S11 Offline-first systems
- S9 Networking — retries / backoff
- Q3 Optimistic updates

---

## Interview Follow-Up Questions

- How does your idempotency strategy survive client retries + server crashes?
- How would you handle a queue that grows to 10k entries?
- What's your conflict resolution policy for two offline users editing the same record?
- How do you secure a queue containing payment data?
- How would you test the offline → online transition reliably?

---

## Memory Hook

**"Queue it, key it, drain it on reconnect."** Three verbs, one resilient app.

## Revision Notes

> Offline mutations need: durable queue, idempotency keys, backoff retries, conflict resolution, dead letter, telemetry. Architecture, not bolt-on.

---

> **End of S8.** Cross-refs: S2 (React 19 Actions), S9 (networking), S11 (offline-first), S22 (system design). Next deep section: [S09 Networking](S09-networking.md).
