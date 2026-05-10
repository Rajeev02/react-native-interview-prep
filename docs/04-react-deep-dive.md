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

