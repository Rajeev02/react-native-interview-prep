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



---

## Top 25 Q&A — JavaScript core

### 1. Difference between `var`, `let`, `const`?
- `var`: function-scoped, hoisted as `undefined`, can redeclare.
- `let`: block-scoped, in TDZ until declared, cannot redeclare in same scope.
- `const`: block-scoped, must initialize, binding is immutable (object contents still mutable).
```js
const u = { name: 'a' }; u.name = 'b'; // OK
u = {}; // TypeError
```

### 2. Explain hoisting.
JS engine moves declarations to top of scope at compile time. `var` → declared + `undefined`. Function declarations → fully hoisted. `let`/`const` → hoisted but in TDZ.
```js
console.log(x); // undefined  (var hoisted)
console.log(y); // ReferenceError (TDZ)
var x = 1; let y = 2;
```

### 3. What is a closure? Real-world example.
A function that retains access to its lexical scope.
```js
function rateLimiter(limit) {
  let calls = 0;
  return () => ++calls <= limit;
}
const allow = rateLimiter(3);
allow(); allow(); allow(); allow(); // true,true,true,false
```

### 4. `==` vs `===`.
`==` does type coercion; `===` checks type + value. Always use `===` except `x == null` (covers null + undefined).

### 5. Explain the event loop.
Stack runs sync code → on empty, drains all microtasks (Promise.then, queueMicrotask) → then one macrotask (setTimeout, I/O) → render → repeat.
```js
console.log(1);
setTimeout(() => console.log(2));
Promise.resolve().then(() => console.log(3));
console.log(4);
// 1, 4, 3, 2
```

### 6. `call`, `apply`, `bind` — difference?
- `call(thisArg, a, b)` — invokes with args list.
- `apply(thisArg, [a, b])` — invokes with args array.
- `bind(thisArg, a)` — returns new function with `this` and args fixed.

### 7. Arrow function vs regular function?
Arrows have **lexical `this`** (no own `this`/`arguments`/`super`/`prototype`), can't be `new`'d.
```js
class C { val=1; reg(){ setTimeout(function(){console.log(this.val)},0);} }
// undefined — `this` lost
```

### 8. What is `this` in different contexts?
- Standalone: `undefined` (strict) / `globalThis`.
- Method call `o.f()`: `o`.
- `new F()`: new instance.
- Arrow: enclosing lexical.
- `f.call(x)`: `x`.

### 9. Implement `debounce` and `throttle`.
```js
const debounce = (fn, ms) => { let t; return (...a)=>{clearTimeout(t); t=setTimeout(()=>fn(...a),ms);}; };
const throttle = (fn, ms) => { let last=0; return (...a)=>{const n=Date.now(); if(n-last>=ms){last=n; fn(...a);}}; };
```

### 10. `Promise.all` vs `allSettled` vs `race` vs `any`.
- `all`: rejects on first failure.
- `allSettled`: never rejects, returns `{status, value|reason}[]`.
- `race`: settles with first result (fulfill or reject).
- `any`: fulfills with first success, rejects only if all fail (`AggregateError`).

### 11. What's a microtask vs macrotask?
Micro = `Promise.then`, `queueMicrotask`, `MutationObserver`. Macro = `setTimeout`, `setInterval`, `setImmediate`, I/O. All micros drain before next macro.

### 12. How does prototypal inheritance work?
Every object has `__proto__` link to its prototype. Property lookup walks the chain.
```js
function Animal(n){this.n=n} Animal.prototype.speak=function(){return this.n};
const a = new Animal('cat'); a.speak(); // walks to prototype
```

### 13. Difference between `null` and `undefined`?
`undefined`: not assigned. `null`: explicitly empty. `typeof null === 'object'` (legacy bug). `null == undefined` is `true`.

### 14. What is currying?
Transform `f(a,b,c)` → `f(a)(b)(c)`.
```js
const curry = fn => function c(...a){ return a.length>=fn.length ? fn(...a) : (...b)=>c(...a,...b); };
```

### 15. Deep clone an object — approaches?
- `structuredClone(obj)` (modern, handles cyclic).
- `JSON.parse(JSON.stringify(obj))` — loses functions, dates, undefined.
- Recursive walk for custom needs.

### 16. Explain `async`/`await` under the hood.
Sugar over promises + generators. `await` pauses, returns to caller, resumes when promise settles. Errors propagate via `try/catch`.
```js
async function f(){ try{ const x = await api(); } catch(e){ /* network err */ } }
```

### 17. What is a generator?
Function returning iterator that can pause via `yield`.
```js
function* range(n){ for(let i=0;i<n;i++) yield i; }
[...range(3)]; // [0,1,2]
```

### 18. Memory leak patterns in JS / RN.
Retained timers, unremoved event listeners, closures capturing big objects, navigation refs holding old screens, cached images without LRU eviction. Detect via Hermes profiler / Xcode Instruments.

### 19. Implement `pLimit(n)`.
```js
function pLimit(n){
  const q=[]; let active=0;
  const next=()=>{ if(!q.length||active>=n)return; active++; const {fn,res,rej}=q.shift();
    Promise.resolve().then(fn).then(res,rej).finally(()=>{active--;next();}); };
  return fn => new Promise((res,rej)=>{ q.push({fn,res,rej}); next(); });
}
```

### 20. Difference: `forEach` vs `map` vs `for...of`.
- `forEach` — side effects, no return.
- `map` — returns new array, pure transform.
- `for...of` — supports `await`, `break`, `continue`.

### 21. What is `Symbol`?
Unique primitive, used for non-colliding keys + well-known protocols (`Symbol.iterator`, `Symbol.asyncIterator`).

### 22. Explain `Object.freeze` vs `Object.seal`.
`freeze`: no add/remove/modify. `seal`: no add/remove, can modify existing.

### 23. Implement `retry(fn, n, delay)`.
```js
const retry = async (fn, n, delay) => {
  for (let i=0;i<n;i++){ try { return await fn(); } catch(e){ if(i===n-1) throw e; await new Promise(r=>setTimeout(r,delay*2**i)); } }
};
```

### 24. What is the temporal dead zone (TDZ)?
Period between scope entry and `let`/`const` declaration where access throws `ReferenceError`. Prevents using before declared.

### 25. `Array.prototype.flat` / `flatMap` example.
```js
[[1,2],[3,4]].flat(); // [1,2,3,4]
[1,2,3].flatMap(x => [x, x*2]); // [1,2,2,4,3,6]
```
