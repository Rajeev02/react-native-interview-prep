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



---

## Top 25 Q&A — React deep dive

### 1. How does React decide to re-render?
A component re-renders when (a) its state changes, (b) its parent re-renders, (c) a context it consumes changes. React diffs the new fiber tree against the old and commits only changed nodes.

### 2. Virtual DOM in React Native?
RN uses a "shadow tree" computed by Yoga (layout) on a background thread. Fabric replaces the bridge with JSI for synchronous host calls.

### 3. Why are keys important in lists?
Keys let React match items between renders. Index keys break on insertion/reorder.
```jsx
{items.map(it => <Row key={it.id} item={it} />)}
```

### 4. `useState` — functional updater, why?
Avoids stale closures when next state depends on previous.
```jsx
setCount(c => c + 1); // safe inside setInterval
```

### 5. `useEffect` cleanup — when does it run?
Before next effect runs and on unmount. Use to clear timers, subscriptions, listeners.

### 6. Stale closure — example + fix.
```jsx
useEffect(() => {
  const id = setInterval(() => setN(n+1), 1000); // n frozen at initial
  return () => clearInterval(id);
}, []);
// Fix: setN(n => n+1)
```

### 7. `useMemo` vs `useCallback`.
`useMemo(fn, deps)` caches a value. `useCallback(fn, deps)` caches a function reference. Use only when result is expensive or passed to memoized children.

### 8. `React.memo` — when does it fail?
When props include new object/function references each render.
```jsx
<Child onPress={() => x()} />  // new fn each render → memo useless
```

### 9. `useLayoutEffect` vs `useEffect`.
`useLayoutEffect` fires sync after DOM/host mutations, before paint. Use for measurement / preventing flicker. Rare in RN.

### 10. `useRef` — three uses.
(a) Mutable box that doesn't trigger re-render. (b) DOM/native ref. (c) Storing latest value for closures.

### 11. Why does Context cause re-renders?
Every consumer re-renders when context value identity changes. Split state vs dispatch contexts; or use selectors (Zustand / use-context-selector).

### 12. Implement a custom hook `useDebouncedValue`.
```jsx
function useDebouncedValue<T>(v: T, ms = 300){
  const [d,setD]=useState(v);
  useEffect(()=>{ const t=setTimeout(()=>setD(v),ms); return ()=>clearTimeout(t); },[v,ms]);
  return d;
}
```

### 13. Controlled vs uncontrolled component.
Controlled: value lives in state. Uncontrolled: value lives in ref/DOM. RN inputs are typically controlled.

### 14. Error boundary — how & limitations.
Class component with `componentDidCatch` / `static getDerivedStateFromError`. Catches render errors only — NOT event handlers, async, server rendering. Wrap critical screens; use `react-native-error-boundary` for hooks.

### 15. `Suspense` in React Native?
Available with React 18+. Used with concurrent features (transitions) and Suspense-enabled libs (Relay, custom). Not yet broadly used in RN.

### 16. `useTransition` and `useDeferredValue`.
Mark non-urgent updates so urgent ones (typing) stay snappy.
```jsx
const [isPending, startTransition] = useTransition();
startTransition(() => setQuery(input));
```

### 17. Reconciliation — keys + types.
React compares element type + key. Different type → unmount/remount. Same type, different props → update.

### 18. Why arrow functions in render are a perf concern?
They create new references each render → break memoization downstream. Solve via `useCallback` only when child is memoized.

### 19. What is React Strict Mode?
Dev-only; double-invokes render + effects to surface side-effect bugs. Helps catch missing cleanups in RN with React 18.

### 20. Implement `useEventCallback` for stable handlers.
```jsx
function useEvent(fn){
  const ref = useRef(fn); useLayoutEffect(()=>{ ref.current = fn; });
  return useCallback((...a)=>ref.current(...a), []);
}
```

### 21. Why move state up?
When two siblings need same data → lift to nearest common ancestor or use a store. Keeps single source of truth.

### 22. Composition vs inheritance.
React favors composition — pass children, render props, hooks. Inheritance is rare/anti-pattern.

### 23. How to avoid prop drilling without context for everything?
Component composition (children prop), colocated state, dedicated stores (Zustand) per concern.

### 24. Render-as-you-fetch vs fetch-on-render.
React Query / Suspense lets you start fetching on navigation event before component mounts → faster perceived perf vs starting fetch in `useEffect`.

### 25. Code example: optimized list row.
```jsx
const Row = React.memo(function Row({item, onPress}){
  return <Pressable onPress={onPress}><Text>{item.title}</Text></Pressable>;
}, (a,b) => a.item.id === b.item.id && a.item.updatedAt === b.item.updatedAt);
```
