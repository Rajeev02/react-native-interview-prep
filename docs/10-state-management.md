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



---

## Top 25 Q&A — State management

### 1. When do you need a state library at all?
When state is shared across distant components, persisted, or has complex update rules. For local + lifted state, `useState` / `useReducer` are enough.

### 2. Redux Toolkit vs Zustand vs Jotai vs Recoil — quick pick.
- **Redux Toolkit**: large teams, time-travel debugging, well-typed slices.
- **Zustand**: minimal API, selectors, great for medium apps.
- **Jotai**: atomic, fine-grained reactivity.
- **Recoil**: similar to Jotai; less momentum now.

### 3. Why did Redux become "easy" again?
Redux Toolkit removed boilerplate: `createSlice`, `createAsyncThunk`, RTK Query for server state.

### 4. Show a Zustand store.
```ts
const useAuth = create<{ user: User|null; setUser:(u:User|null)=>void }>(set => ({
  user: null,
  setUser: u => set({ user: u }),
}));
const user = useAuth(s => s.user); // selector → only re-renders when user changes
```

### 5. Show a Redux Toolkit slice.
```ts
const slice = createSlice({
  name: 'cart',
  initialState: { items: [] as Item[] },
  reducers: { add: (s, a: PayloadAction<Item>) => { s.items.push(a.payload); } },
});
export const { add } = slice.actions;
```

### 6. Server state vs client state — separate?
Yes. Use **React Query / RTK Query / SWR** for server cache (refetch, dedupe, retry, mutations). Use Zustand/Redux for UI state (modals, filters).

### 7. React Query basics.
```ts
const { data, isLoading } = useQuery({ queryKey: ['user', id], queryFn: () => api.get(id) });
const mut = useMutation({ mutationFn: api.update, onSuccess: () => qc.invalidateQueries({queryKey:['user',id]}) });
```

### 8. How to persist Zustand store?
`persist` middleware with `AsyncStorage` or `MMKV` storage adapter.
```ts
create(persist(creator, { name: 'auth', storage: createJSONStorage(()=>mmkvStorage) }));
```

### 9. Why avoid Context for everything?
Every consumer re-renders on value change. Splits + selectors mitigate; for frequent updates, prefer a store with subscription model.

### 10. Optimistic updates pattern.
```ts
const mut = useMutation({
  mutationFn: api.like,
  onMutate: async (id) => {
    await qc.cancelQueries({queryKey:['post',id]});
    const prev = qc.getQueryData(['post',id]);
    qc.setQueryData(['post',id], (p:any)=>({...p, liked:true}));
    return { prev };
  },
  onError: (_e,_v,ctx) => qc.setQueryData(['post',_v], ctx?.prev),
});
```

### 11. Normalizing data — when?
When entities relate (lists referencing same user). Use `entities` shape `{ byId: {...}, allIds: [...] }`. RTK has `createEntityAdapter`.

### 12. How to model loading / error states cleanly?
Discriminated union: `'idle'|'loading'|'success'|'error'`. Avoid boolean flags soup.

### 13. Selector memoization — `reselect`.
```ts
const selectVisible = createSelector([state => state.todos, state => state.filter],
  (todos, f) => todos.filter(...));
```

### 14. How does Redux middleware work?
Function `({getState, dispatch}) => next => action => {...}`. Wraps `dispatch`. Common: thunk, saga, RTK listener middleware.

### 15. Saga vs Thunk?
Thunk: simple async functions. Saga: generator-based, declarative effects, easier to test complex flows. RTK promotes thunks; sagas for long-running orchestration.

### 16. Where to put navigation params: URL, state lib, route params?
Route params for screen-specific transient data. Persisted state lib for cross-screen state. URL/deep link for shareable.

### 17. Form state — local or store?
Local with `react-hook-form`. Lift only the result on submit. Avoid putting every keystroke in Redux.

### 18. Avoiding rerenders in Zustand.
Use selectors `useStore(s => s.x)` plus `shallow` equality.
```ts
const { a, b } = useStore(s => ({a:s.a,b:s.b}), shallow);
```

### 19. How to debug Redux/RTK?
Redux DevTools Extension via remote debugger or RN DevTools. Time-travel + diff. Add `logger` middleware in dev.

### 20. Persisting Redux — redux-persist?
Yes, but heavy. Alternative: RTK + custom subscription writing to MMKV. Whitelist only needed slices.

### 21. Server state staleness strategy.
React Query: `staleTime` per query. Background refetch on window focus / reconnect. Mutations invalidate keys.

### 22. State machine for complex flows — XState?
For multi-step KYC / payment flows with many states + guards, XState eliminates boolean flags. Visualize via XState Inspector.

### 23. Code split state per feature?
Yes — feature folders own their slices/atoms. Combine reducers at root; lazy-inject for huge apps.

### 24. Avoid double-fetch on mount + focus.
React Query: `refetchOnMount: 'stale'`, `refetchOnWindowFocus` (not relevant in RN, but `refetchOnReconnect`). Use `useFocusEffect` + invalidation.

### 25. End-to-end pattern: cart with optimistic add + persist.
```ts
const useCart = create(persist((set,get) => ({
  items: [] as Item[],
  add: async (i: Item) => {
    set({ items: [...get().items, i] });
    try { await api.cartAdd(i); } catch { set({ items: get().items.filter(x=>x.id!==i.id) }); }
  },
}), { name:'cart', storage: createJSONStorage(()=>mmkvStorage) }));
```
