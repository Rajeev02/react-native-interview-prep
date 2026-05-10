## 2. JavaScript core

### Basics
- **Execution context, hoisting, scope chain**: `var` is function-scoped + hoisted with `undefined`; `let`/`const` are block-scoped + in TDZ until declaration.
- **Primitive vs reference**: numbers/strings/bool/null/undefined/symbol/bigint copied by value; objects/arrays/functions by reference.
- **`==` vs `===`**: never use `==`. `null == undefined` is the one trap.
- **`this` binding**: default (global/undefined in strict), implicit (`obj.fn()`), explicit (`call`/`apply`/`bind`), `new`, arrow (lexical — does NOT bind `this`).

### Closures (asked in 80%+ of loops)
A function "remembers" the scope it was created in.
```js
function makeCounter() { let n = 0; return () => ++n; }
const c = makeCounter(); c(); c(); // 2
```
**Stale closure trap in RN**:
```js
useEffect(() => {
  const id = setInterval(() => setCount(count + 1), 1000); // stale!
  return () => clearInterval(id);
}, []); // count frozen at initial value
// Fix: use functional update setCount(c => c + 1) OR add count to deps
```

### Async + event loop
- **Stack → microtasks (Promise.then, queueMicrotask) → macrotasks (setTimeout, setInterval, I/O) → render frame**
- All microtasks drain before next macrotask.
- `async/await` is just sugar over Promises.

```js
console.log(1);
setTimeout(() => console.log(2), 0);
Promise.resolve().then(() => console.log(3));
console.log(4);
// 1, 4, 3, 2
```

**Promise utilities**:
- `Promise.all` — fail fast on first rejection
- `Promise.allSettled` — wait for all, never rejects
- `Promise.race` — first to settle
- `Promise.any` — first to fulfill (ignores rejections)

**Concurrency-limited fetch** (asked in Razorpay/PhonePe):
```js
async function pLimit(items, limit, fn) {
  const results = []; const executing = [];
  for (const item of items) {
    const p = Promise.resolve().then(() => fn(item));
    results.push(p);
    if (limit <= items.length) {
      const e = p.then(() => executing.splice(executing.indexOf(e), 1));
      executing.push(e);
      if (executing.length >= limit) await Promise.race(executing);
    }
  }
  return Promise.all(results);
}
```

### Memory + GC
- Mark-and-sweep. Leaks = lingering references (timers, listeners, closures over big objects, navigation refs).

### Must-answer questions
1. Stale closure in `useEffect` — show + fix.
2. Output of `console.log + setTimeout + Promise.then` interleave.
3. `Promise.all` vs `allSettled` — when each.
4. Implement `pLimit(n)` and `retry(fn, n, delay)`.
5. Why arrow function doesn't bind `this`.

---

