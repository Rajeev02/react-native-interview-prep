# S1 — JavaScript & TypeScript

> ES2026 · event loop · promises · memory · TS 5.x · Zod · Temporal API

> Status: **scaffold** — fill with content using the per-topic format from `final-prompt.md`.

## Topics

- ES5 → ES2026 (key additions per year, what RN/Hermes supports)
- Closures, scope, hoisting, TDZ
- Event loop, microtasks, macrotasks (RN's RuntimeScheduler nuance)
- Promises, async/await, AbortController, Promise.withResolvers
- Memory management & leaks (closures, listeners, timers)
- Prototype inheritance vs class syntax
- Temporal API (replacement for Date)
- Modules (ESM vs CJS, package.json `exports`, `imports`)
- Advanced TypeScript (generics, conditional types, mapped types, template literal types)
- Discriminated unions
- Utility types
- `satisfies`, const type parameters, decorators
- Zod / runtime validation

## Q-topics (stubs)

- Q1. Event loop in RN — JS thread, microtasks, RuntimeScheduler
- Q2. Closures and the most common memory leak patterns
- Q3. Promises deep dive — chaining, cancellation, error semantics
- Q4. Advanced TypeScript — generics, conditional types, infer
- Q5. Discriminated unions and exhaustiveness with `never`
- Q6. `satisfies` vs type assertion vs annotation
- Q7. Zod for runtime validation at boundaries (API + storage)
- Q8. Temporal API and why Date is finally going away

> Cross-refs: `docs/02-javascript-core.md`, `docs/03-typescript.md`.
