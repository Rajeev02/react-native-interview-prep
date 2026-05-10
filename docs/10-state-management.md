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

