# S6 — Hermes & Metro

> Hermes bytecode · Hades GC · Static Hermes · Metro bundler · RAM bundles · inline requires · symbolication · startup optimization

## Topics

- [Q1. Hermes — what it is, why it's the default](#q1-hermes--what-it-is-why-its-the-default)
- [Q2. Static Hermes — the AOT future](#q2-static-hermes--the-aot-future)
- [Q3. Metro bundler internals](#q3-metro-bundler-internals)
- [Q4. Inline requires, RAM bundles, lazy loading](#q4-inline-requires-ram-bundles-lazy-loading)
- [Q5. Source maps & symbolication](#q5-source-maps--symbolication)

---

## Q1. Hermes — what it is, why it's the default

### Difficulty
Intermediate → Advanced

### Interview Frequency
Very Common.

### Prerequisites
JS engines basics, GC concepts.

### TL;DR
Hermes is a JS engine purpose-built for React Native: **AOT-compiled bytecode** (`.hbc`), small binary, fast startup, generational GC (Hades), tight integration with JSI.

### 30-Second Interview Answer
"Hermes is the default JS engine for RN since 0.70. Instead of parsing JS at runtime, the bundler precompiles your JS to Hermes bytecode at build time. The app loads bytecode directly — no parse, no JIT warm-up. It uses a generational GC (Hades) tuned for short-lived allocations, a small heap footprint, and integrates natively with JSI. Compared to JSC, you get faster cold start, lower TTI, and smaller memory."

### 2-Minute Practical Answer
What you give up vs JSC: no JIT (Hermes is interpreter + selective optimizations). What you gain:
- **Cold start:** 30–60% faster on Android in real apps because there's no parse step.
- **App size:** smaller install footprint than JSC + bytecode payload is compact.
- **Memory:** Hades GC (concurrent generational) is tuned for mobile.
- **Debugging:** Hermes ships its own debugger protocol; React Native DevTools speaks it.

You enable it by default in new RN apps. To verify:
```ts
const isHermes = !!global.HermesInternal;
```

In production:
- Always ship symbolicated source maps (Q5) — Hermes stack traces are bytecode offsets without them.
- Profile with the Hermes Profiler (records to `.cpuprofile` you can open in Chrome DevTools).

### 5-Minute Architecture Answer
Hermes is **interpreter-first** by design. The bet: on mobile, JIT warmup costs and code-cache memory hurt more than they help for typical app workloads.

Pipeline:
```
your JS  →  Metro bundler  →  hermesc  →  bytecode (.hbc)  →  app binary
                                           │
                                           └─ Hermes runtime (interpreter + Hades GC + JSI)
```

Why no JIT?
- JIT memory cost (~10–30MB code cache) is significant on low-end Android.
- Mobile workloads are short-lived and bursty; JIT amortization is poor.
- Static Hermes (Q2) reclaims the perf upside via AOT type-driven optimization.

Hades (the GC):
- Generational: young + old generations.
- Concurrent old-gen sweep on a background thread; minimal stop-the-world pauses.
- Tuned for mobile heaps (typical RN app: 50–200MB JS heap).

JSI integration: Hermes' `Runtime` **is** a `jsi::Runtime`. This is what makes TurboModules and Reanimated worklets possible.

### The "Why"
- JSC was Apple-controlled and Android-bundled (2–3MB extra binary).
- Mobile users feel cold start more than steady-state perf.
- A purpose-built engine could optimize for RN's exact workload.

### Mental Model
Hermes is **AOT-compiled JS for mobile**. Like Java's `.class` files vs interpreting Java source — same idea applied to JS, on-device.

### Internal Working (2026 Context)
- Default in all new apps; required for the New Architecture's full benefit.
- `hermesc` runs inside Metro (or as a build phase) producing `.hbc`.
- The bytecode format includes string tables, function tables, and pre-resolved literal values.
- Reanimated worklets are serialized JS code that Hermes can compile into separate bytecode for the UI runtime.

### Modern Implementation (Code)
Verify and instrument:
```ts
// app/boot/hermes.ts
export function logHermes(): void {
  // @ts-expect-error
  const v = global.HermesInternal?.getRuntimeProperties?.();
  console.log('Hermes:', v); // { 'OSS Release Version': '...', Build: 'Release', ... }
}
```

To start a Hermes profile programmatically (dev only):
```ts
// @ts-expect-error
global.HermesInternal?.enableSamplingProfiler?.(true);
// ... run scenario ...
// dump to file via the built-in Profile API or React Native DevTools
```

### Comparison

| Aspect            | JSC                | Hermes                  | Static Hermes (Q2)         |
| ----------------- | ------------------ | ----------------------- | -------------------------- |
| Mode              | JIT                | Interpreter + AOT bytecode | AOT native (typed)        |
| Cold start        | Baseline           | −30–60%                 | Further wins               |
| Steady-state perf | Strong (JIT)       | Slightly behind JIT     | Approaches native for typed |
| App size          | +JSC binary        | Smaller                 | Larger artifacts (AOT)     |
| Memory            | JIT code cache     | Compact                 | Compact                    |

### Production Usage
- Default everywhere; turning Hermes off in 2026 is a red flag without a specific reason.
- Reanimated, MMKV, VisionCamera all assume Hermes-grade JSI.

### Hands-On Exercise
1. Disable Hermes (use JSC) on a sample app. Measure cold start with `react-native-startup-time`.
2. Re-enable; compare. Typical Android mid-tier savings: 200–600ms.
3. Open the `.hbc` file size; compare to the equivalent JS bundle.

### Common Mistakes
- Shipping un-symbolicated stack traces and trying to debug bytecode offsets.
- Holding `WeakRef`s in hot paths (Hermes' weak refs have specific semantics).
- Assuming JIT-style microbenchmarks transfer (some patterns are slower in Hermes than V8).

### Production Red Flags
- Hermes off without justification.
- Stack traces in production with `0x123abc` offsets — missing source maps.
- Memory profiles with constant young-gen pressure (allocation storm) and no investigation.

### Performance & Metrics
- Cold start: −30–60% vs JSC.
- App size: −2–4MB on Android.
- Memory: −10–20% steady-state vs JSC.

### Metrics That Matter
TTI, JS heap size, GC pause P95, crash-free sessions.

### Decision Framework
- New RN app → Hermes always.
- Migrating a JSC app → flip Hermes, run regression suite, monitor heap and CPU for a week.
- Need real JIT (heavy crypto in JS) → reconsider; usually move to a TurboModule instead.

### Senior-Level Insight
Hermes' interpreter-first design encodes a real product insight: mobile apps spend most CPU in **render + native module crossings**, not in pure JS. Optimize startup and memory; let TurboModules handle compute-heavy work.

### Real-World Scenario
**Symptom:** App's JS heap grows unbounded after a long session.
**Investigation:** Hermes Profiler heap dump shows huge `Map` allocations from a stale event subscription.
**Root cause:** Listeners not unsubscribed.
**Fix:** AbortController-based subscription teardown.
**Lesson:** Hades helps but won't compensate for retained references.

### Production Failure Story
**Incident:** App crash spike after enabling Hermes for the first time.
**Investigation:** Crashes tied to `Object.freeze` on a circular structure that JSC tolerated and Hermes didn't.
**Root cause:** Engine semantics drift in an obscure edge case.
**Fix:** Avoid freezing the structure; ship a hotfix.
**Prevention:** Hermes-specific smoke test suite added to CI.

### Debugging Checklist
1. `global.HermesInternal` confirms engine.
2. Enable sampling profiler for slow JS sections.
3. Symbolicate every stack trace.
4. Check Hades stats via DevTools Memory tab for GC pressure.

### Advanced / Internal Knowledge
- Bytecode format is versioned; Hermes runtime in the app must match the `hermesc` used by Metro.
- String tables in `.hbc` deduplicate literals → smaller payload.
- Hermes intentionally doesn't support some ES features the same way V8 does (e.g., Proxies are slower); audit hot paths.

### 2026 AI Tip
Ask AI to analyze an `.hbc` only if you can verify against `hermes-disasm`. Don't trust AI-generated "Hermes optimizations" without measuring.

### Related Topics
Q2 (Static Hermes), Q3 (Metro), S4 (JSI/New Arch), S7 (perf).

### Interview Follow-Up Questions
- "Why doesn't Hermes JIT?"
- "What does the Hades GC do differently?"
- "How does bytecode loading affect cold start?"
- "How do you profile Hermes in production?"

### Memory Hook
**"Hermes = bytecode in, no parse, mobile-tuned GC, JSI native."**

### Revision Notes
> Hermes = AOT-bytecode interpreter for RN; Hades concurrent generational GC; default in 2026; ship source maps; profile via Hermes Profiler.

---

## Q2. Static Hermes — the AOT future

### Difficulty
Architect

### Interview Frequency
Common at FAANG / staff loops.

### Prerequisites
Q1 (Hermes), TypeScript types, AOT compilation concepts.

### TL;DR
Static Hermes is an experimental AOT compiler that uses **TS/Flow types** to emit specialized native code, dramatically narrowing the JIT/native gap while keeping Hermes' startup and memory wins.

### 30-Second Interview Answer
"Static Hermes is Meta's next-gen Hermes that AOT-compiles typed JavaScript (Flow/TypeScript) into specialized native code. Where regular Hermes interprets, Static Hermes can emit direct native instructions for typed code paths. The result is JIT-like steady-state performance without runtime warmup or memory cost. In 2026 it's emerging — used in production at Meta scale, starting to appear in OSS RN behind flags."

### 2-Minute Practical Answer
What it changes:
- Builds become longer (AOT cost).
- Untyped or `any`-heavy code falls back to interpreter (no win).
- Typed code paths approach native speed.

What you do today:
- Adopt strict TS in hot paths (lists, animations, parsers).
- Avoid `any` where you want Static Hermes wins later.
- Watch RN release notes; expect opt-in flags before defaults.

### 5-Minute Architecture Answer
Regular Hermes treats JS as dynamic — every property access is a hash lookup, every arithmetic operation type-checks at runtime. Static Hermes uses the **type information from your source** to:
- pre-resolve property offsets,
- specialize numeric operations,
- inline calls when callees are statically known,
- emit native code (ARM64 / x86_64) instead of bytecode for hot functions.

This brings JS toward what Kotlin/Swift achieve naturally — without losing JS ergonomics.

The catch: types must be **trusted**. Static Hermes inserts runtime checks where it can't prove safety. Lying types (cast `any as User`) cause check failures and bailouts.

### The "Why"
- Mobile users want both fast cold start (Hermes) and fast steady-state (JIT).
- TypeScript adoption gives the compiler real type information for free.
- AOT lets RN approach the perf ceiling without runtime cost.

### Mental Model
Static Hermes is **like Kotlin/Native for typed JS**. The more honest your types, the more it can optimize.

### Internal Working (2026 Context)
- Pipeline: `hermesc --static` produces native object files plus a residual interpreter for dynamic parts.
- App bundles include both AOT artifacts and bytecode fallbacks.
- Per-arch builds (arm64-v8a, etc.) replace the universal `.hbc` for AOT-compiled functions.

### Modern Implementation (Code)
Until Static Hermes is GA, prepare:
```ts
// Bad — Static Hermes can't optimize
function sum(items: any) {
  let s = 0;
  for (const it of items) s += it.value;
  return s;
}

// Good — typed enough to specialize
type Item = Readonly<{ value: number }>;
function sumStrict(items: ReadonlyArray<Item>): number {
  let s = 0;
  for (let i = 0; i < items.length; i++) s += items[i].value;
  return s;
}
```

### Comparison

| Aspect            | Hermes (today)        | Static Hermes (emerging)    | V8 with JIT (web)        |
| ----------------- | --------------------- | --------------------------- | ------------------------ |
| Compilation       | AOT bytecode          | AOT native (typed) + bytecode| Runtime JIT             |
| Steady state      | Interpreter speed     | Near-native for typed       | Near-native              |
| Cold start        | Fast                  | Fast (no warmup)            | Slower (warmup)          |
| Memory            | Compact               | Compact                     | Code cache overhead      |
| Build time        | Fast                  | Slower                      | N/A                      |

### Production Usage
- Watch for opt-in flags in RN releases.
- Internal at Meta on production apps.
- Plan TS strictness now to be ready.

### Hands-On Exercise
- Strictify one hot module (`as`-cast bans, no `any`).
- Add benchmarks (`Reassure`); record baseline.
- When Static Hermes lands in your RN version, flip the flag and re-measure.

### Common Mistakes
- Adding types just for Static Hermes without enforcing them — `any` cast leaks defeat the point.
- Expecting wins on UI code that's mostly React + JSI; the wins are in **pure JS hot loops**.

### Production Red Flags
- "We'll just turn Static Hermes on later" without strict TS adoption.
- `// @ts-ignore` in critical paths.

### Performance & Metrics
- Reported experimentally: 2–10× speedup on numeric / parsing workloads.
- Unchanged or marginal wins on UI-bound code.

### Metrics That Matter
JS thread CPU on hot paths, parser/encoder throughput, frame budget headroom.

### Decision Framework
- Library author shipping numeric/parser code → invest in strict types now.
- App engineer → strict TS pays off independent of Static Hermes; don't gamble on it.
- Architect → roadmap budgets a 1-quarter Static Hermes evaluation when GA.

### Senior-Level Insight
Static Hermes is RN admitting that **typed JS is a real language** and treating it as compilation input. The architectural lesson: type adoption stops being just developer ergonomics — it becomes a **runtime asset**.

### Real-World Scenario
N/A yet — Static Hermes is emerging. Discuss preparation strategy in interviews instead.

### Production Failure Story
N/A. Discuss "what could go wrong": type lies → runtime check failures → bailouts → silent perf regressions.

### Debugging Checklist
1. Confirm Static Hermes flag is on.
2. Run AOT report (Static Hermes will list bailed-out functions).
3. Check arch-specific binaries shipped (no fat AOT for unused arch).

### Advanced / Internal Knowledge
- Static Hermes uses a typed IR (sh-typed) derived from Flow/TS via BabelFlow.
- Compile-time inference can prove inlining safe in many cases.
- `hermes-parser` is the front-end shared with the regular toolchain.

### 2026 AI Tip
Ask AI to "audit this module for Static Hermes friendliness" — it can flag `any`, dynamic property access, and inconsistent shapes.

### Related Topics
Q1 (Hermes), S1 (TypeScript), S7 (perf).

### Interview Follow-Up Questions
- "How does Static Hermes use types?"
- "What kinds of code see the biggest wins?"
- "What can go wrong if your types are wrong?"
- "How does this affect build times and binary size?"

### Memory Hook
**"Honest types in → native code out. Lie about types → bailouts and disappointment."**

### Revision Notes
> Static Hermes = AOT-typed JS to native code; preserves Hermes startup wins; needs strict TS; emerging in 2026; prepare with strict types now.

---

## Q3. Metro bundler internals

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common.

### Prerequisites
Module bundling basics, JS module systems.

### TL;DR
Metro is RN's bundler: a **resolver + transformer + serializer** producing a single JS bundle (or split bundles), with platform-aware extensions, fast incremental rebuilds, and integration with `hermesc`.

### 30-Second Interview Answer
"Metro is the RN bundler. It walks your require graph, resolves modules with platform-aware extensions (`.ios.tsx`, `.android.tsx`), transforms each file through Babel (and now optional `swc`), then serializes a single bundle (or RAM bundle / split bundles). For Hermes apps it pipes the output through `hermesc` to produce bytecode. Metro is incremental — file watcher invalidates only the changed module."

### 2-Minute Practical Answer
Three stages:
1. **Resolution** — given `require('foo')`, Metro finds the file using `node_modules` rules + RN platform extensions + `package.json` `main`/`react-native`/`exports` fields.
2. **Transformation** — each file goes through Babel (configurable plugins/presets); output is a Metro-friendly module wrapper (`__d(function() {...})`).
3. **Serialization** — modules are concatenated in dependency order (or split into RAM bundle / chunks), with a small Metro runtime at the top.

Important Metro features:
- **Watchman**-backed file watching for fast incremental builds.
- **Inline requires** (Q4) — moves `require` calls inside functions for lazy execution.
- **Custom resolver / transformer** via `metro.config.js`.
- **Platform-specific files** — Metro tries `.ios.tsx` → `.ios.ts` → `.tsx` → `.ts` etc.

### 5-Minute Architecture Answer
Metro's design priorities:
- **Fast incremental rebuilds** for dev (sub-second).
- **Predictable production bundles** for release.
- **No tree shaking** by default (RN code patterns weren't friendly historically).

Production output:
```
[ Metro runtime header (~5KB) ]
[ Module 1 (__d(function() { ... }, 0, [deps]); ]
[ Module 2 ]
...
[ require(0); // entry ]
```

Hermes transforms this into bytecode via `hermesc`. The bytecode is what ships in the app.

Metro is **not** Webpack:
- Module IDs are numeric (smaller, no string overhead).
- No HMR by default in production; dev gets fast refresh via the Metro server.
- No traditional code-splitting; alternatives are RAM bundles, OTA via EAS Update, dynamic imports (limited support).

In 2026:
- Metro 0.80+ supports **package exports** (npm `exports` field).
- **swc**-based transformer is opt-in and gaining ground (faster than Babel for large repos).
- Symbolication tooling (Q5) reads the source map Metro emits (`*.bundle.map`).

### The "Why"
- Webpack/Vite assumed a browser; RN needed platform-aware resolution and Hermes integration.
- Mobile build cycles need to be fast to keep developers productive.

### Mental Model
Metro is **a smart Babel pipeline with a graph** plus an HTTP dev server.

### Internal Working (2026 Context)
- Dev: HTTP server returns the bundle on request, fast refresh patches modules in place.
- Prod: bundle written to disk, fed to `hermesc`, embedded in the app.
- Source maps emitted in both modes; Hermes' bytecode source map round-trips through them.

### Modern Implementation (Code)
`metro.config.js`:
```js
const { getDefaultConfig } = require('expo/metro-config'); // or '@react-native/metro-config'
const config = getDefaultConfig(__dirname);

config.resolver.sourceExts = [...config.resolver.sourceExts, 'svg'];
config.transformer.babelTransformerPath = require.resolve('react-native-svg-transformer');

// Inline requires (default true in modern templates) — see Q4
config.transformer.getTransformOptions = async () => ({
  transform: { experimentalImportSupport: false, inlineRequires: true },
});

module.exports = config;
```

### Comparison

| Bundler  | Target          | Key trait                         |
| -------- | --------------- | --------------------------------- |
| Metro    | React Native    | Platform extensions, Hermes pipe  |
| Webpack  | Web             | Plugin ecosystem, tree shaking    |
| Vite     | Web             | ESM dev, Rollup prod              |
| esbuild  | Web/general     | Speed                             |

### Production Usage
- Mono-repo support (`watchFolders`, `nodeModulesPaths`).
- Custom resolvers for design-system aliases.
- swc transformer for large codebases (significant build-time win).

### Hands-On Exercise
1. Add a custom resolver that maps `@app/*` → `src/*`.
2. Switch to swc transformer; measure clean build time.
3. Inspect the output bundle (`react-native bundle`); identify the Metro runtime header and module wrappers.

### Common Mistakes
- Editing inside `node_modules` and expecting Metro to pick it up without clearing caches.
- Misconfiguring `extraNodeModules` in monorepos.
- Forgetting platform extensions — code that should be Android-only ships everywhere.

### Production Red Flags
- Slow builds without swc evaluation.
- Custom transforms that aren't deterministic (cache poisoning).
- Source maps not uploaded to crash reporter.

### Performance & Metrics
- Dev incremental: should be <500ms typical.
- Cold prod build: minutes for large apps; swc helps significantly.
- Bundle size: track in CI; spikes are usually accidental imports.

### Metrics That Matter
Build time P50/P95, bundle size, source map upload success rate.

### Decision Framework
- Default Metro for RN.
- Add swc when build time hurts.
- Avoid custom transformers unless necessary; they slow rebuilds.

### Senior-Level Insight
Metro's lack of aggressive tree-shaking is intentional: RN modules often have side effects (registering native modules at import time). Aggressive elimination would break apps. Optimize bundle size by **import discipline**, not by trusting the bundler.

### Real-World Scenario
**Symptom:** A new dependency added 2MB to the bundle.
**Investigation:** `react-native bundle --analyze` shows the dep imports a CSV of locale data.
**Root cause:** No tree shaking in Metro for that pattern.
**Fix:** Switch to a smaller locale dep or load the data dynamically.
**Lesson:** Audit deps with bundle visualization before merging.

### Production Failure Story
**Incident:** Builds started failing intermittently after monorepo migration.
**Investigation:** Metro resolver picked one of two duplicate React copies depending on cache state.
**Root cause:** Two `react` versions hoisted differently across packages.
**Fix:** Pin `react` at root, add `resolver.unstable_enableSymlinks` and dedupe.
**Prevention:** CI step `npm ls react` failing on duplicates.

### Debugging Checklist
1. `npx react-native start --reset-cache` for stale-cache issues.
2. `npx react-native bundle --dev false` to inspect prod output.
3. `metro inspect` for resolver decisions.
4. Validate Babel/swc cache directory health.

### Advanced / Internal Knowledge
- Metro caches transforms by file hash + transformer config; mis-tuning your transformer disables cache.
- Numeric module IDs are stable across builds when the input file paths don't change.
- Inline-requires interaction with side-effectful imports must be considered (Q4).

### 2026 AI Tip
AI is solid at writing Metro configs but often suggests Webpack-style aliases (`alias` instead of `extraNodeModules`). Verify against the current Metro API.

### Related Topics
Q1 (Hermes), Q4 (inline requires), Q5 (source maps), S5 (Expo + tooling), S20 (CI/CD).

### Interview Follow-Up Questions
- "How does Metro resolve `react-native` from a monorepo?"
- "Why doesn't Metro tree-shake?"
- "How does Metro feed Hermes?"
- "When would you switch to swc?"

### Memory Hook
**"Resolve → Transform → Serialize → Hermes. Metro is the pipe."**

### Revision Notes
> Metro = RN bundler with platform-aware resolver + Babel/swc transformer + serializer feeding Hermes; incremental dev builds; no tree shaking by default; configure via `metro.config.js`.

---

## Q4. Inline requires, RAM bundles, lazy loading

### Difficulty
Advanced

### Interview Frequency
Common at Senior+ — startup optimization is a recurring topic.

### Prerequisites
Q3 (Metro), JS module evaluation order.

### TL;DR
**Inline requires** transform top-of-file `require` into call-site `require`, deferring module evaluation; **RAM bundles** load modules from disk on demand. Both target startup time on large apps.

### 30-Second Interview Answer
"Top-of-file `require` evaluates the module's code immediately on import. With inline requires, Metro moves the `require` to the call site, so the module evaluates only when first used — drastically cutting cold-start work in large apps. RAM bundles take this further: modules are stored as separate records on disk and loaded on demand. Both are mostly outdated wins thanks to Hermes bytecode + the New Arch's lazy module init, but they still matter for large feature graphs."

### 2-Minute Practical Answer
Inline requires (default in modern templates):
```js
// Before transform
const Foo = require('./Foo');
function useFoo() { return Foo.bar(); }

// After transform
function useFoo() { return require('./Foo').bar(); }
```

The `require` call is cheap (cached after first call). The win is **not evaluating** code paths the user never hits.

RAM bundles ship modules as a binary index (iOS unbundle / Android RAM bundle) — module bodies stay on disk until needed. With Hermes' compact bytecode, the win is smaller, so most apps just use Hermes + inline requires.

What still matters in 2026:
- Inline requires for big feature graphs (deep import chains).
- Code-splitting by route via Expo Router lazy boundaries.
- Avoiding "barrel files" (`index.ts` re-exporting everything) that defeat inline requires.

### 5-Minute Architecture Answer
Why barrel files hurt: a `barrel.ts` that re-exports 50 modules causes a single import to drag all 50 module **definitions** into the require graph (Metro treats each as a dependency). With inline requires, individual call sites still avoid evaluation, but the **graph** is huge — slowing Metro builds and inflating bundle size.

Solutions:
- Direct imports (`import { X } from './foo/X'`) instead of barrel imports.
- ESLint rule to forbid deep barrels in app code.
- Lazy boundaries at routes (Expo Router lazy files / `React.lazy` for tabs).

In 2026:
- TurboModule lazy init removes another category of startup work.
- Bridgeless mode means no eager module registry construction.
- Combined: cold start is dramatically better than 2022, but architecture still matters for >100k LoC apps.

### The "Why"
- Cold start is the most user-visible perf metric.
- Large apps load far more JS than they need on first screen.
- Defer the rest until the user navigates there.

### Mental Model
Inline requires = "evaluate when called, not when seen." RAM bundles = "load when called, not on launch."

### Internal Working (2026 Context)
- Inline requires is a Babel transform (`@babel/plugin-transform-modules-commonjs` with options or RN's transformer flag).
- The Metro require runtime caches module exports by ID after first evaluation.
- Hermes bytecode loads quickly enough that RAM bundles are rarely worth the complexity.

### Modern Implementation (Code)
`metro.config.js` snippet:
```js
config.transformer.getTransformOptions = async () => ({
  transform: { experimentalImportSupport: false, inlineRequires: true },
});
```

Code-splitting at the route level (Expo Router):
```tsx
// app/_layout.tsx
import { Stack } from 'expo-router';
export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="settings" />
    </Stack>
  );
}
```
Each route file is loaded lazily by Expo Router's runtime; combined with inline requires, the initial bundle parses only what the entry route needs.

Avoid barrels:
```ts
// Bad — pulls 30 modules just to use Button
import { Button } from '@app/ui';

// Good — single direct path
import { Button } from '@app/ui/Button';
```

### Comparison

| Technique         | Win                    | Cost                          | When                     |
| ----------------- | ---------------------- | ----------------------------- | ------------------------ |
| Inline requires   | Defer module eval      | None at runtime               | Always on                |
| RAM bundles       | Defer module load      | Build complexity, smaller win | Rare in 2026             |
| Route splitting   | Defer feature graph    | Architecture discipline       | Always on for big apps   |
| Barrel removal    | Smaller require graph  | Refactor work                 | Always on                |

### Production Usage
- Big apps (Walmart, Discord, Shopify-style) report measurable cold-start wins from inline requires + barrel removal.
- Combined with TurboModule lazy init: 200–700ms saved on Android mid-tier.

### Hands-On Exercise
1. Profile cold start with inline requires off vs on (clean-build).
2. Add a barrel to your design system, measure require graph size growth.
3. Replace with direct imports; measure again.

### Common Mistakes
- Modules with **side-effectful top-level code** (registering listeners, setting globals) that no longer fire because of deferred eval.
- Mixing inline requires with circular dependencies — bugs appear only on certain access orders.
- Heavy use of `React.lazy` without an upper Suspense boundary.

### Production Red Flags
- Barrel imports through massive `@/components/index.ts`.
- Modules registering analytics or polyfills at top level.
- Cold-start regression after adding a single dep — usually a barrel transitively pulls a giant.

### Performance & Metrics
- TTI: −100 to −500ms typical from these techniques combined.
- Bundle size: smaller after barrel cleanup.
- JS heap: smaller, less GC pressure on first screen.

### Metrics That Matter
TTI, JS bundle size, JS heap at first screen, modules evaluated count.

### Decision Framework
- Always inline requires.
- Avoid barrels in app code.
- Route splitting for any app with >5 distinct major flows.
- RAM bundles only if Hermes is off (rare).

### Senior-Level Insight
Inline requires is a **discipline multiplier**: it works best when you also avoid side-effectful imports and barrel re-exports. Without that discipline, the technique helps but doesn't unlock the full win. The architectural lesson: import patterns are a startup-perf concern, not just a style concern.

### Real-World Scenario
**Symptom:** Adding a feature flag SDK regressed cold start by 250ms.
**Investigation:** SDK ran network init at top-level import.
**Root cause:** Even with inline requires, the first require evaluated heavy code.
**Fix:** Wrap SDK init in a lazy initializer; trigger from a post-mount hook.
**Lesson:** Inline requires defers eval, but eval itself must be cheap.

### Production Failure Story
**Incident:** Crashes on Android after enabling inline requires app-wide.
**Investigation:** A polyfill that set `global.fetch` was at top level of a module no longer imported eagerly.
**Root cause:** Polyfill never ran.
**Fix:** Move polyfills into the entry file `index.js`.
**Prevention:** Code-review checklist: side-effect imports must be in entry.

### Debugging Checklist
1. `metro` `--verbose` to see resolved graph size.
2. Use `react-native-startup-time` for cold-start measurement.
3. Hermes Profiler `.cpuprofile` → look for early `require` calls eating time.
4. Check entry file for missing polyfills after enabling inline requires.

### Advanced / Internal Knowledge
- Inline requires turns each require into a function call but Hermes bytecode caches the lookup.
- The Metro require runtime tracks module factories vs evaluated exports separately.
- For very large apps, route-level splits + EAS Update lets you ship partial updates without re-bundling unchanged code.

### 2026 AI Tip
AI sometimes refactors imports and silently breaks side-effect ordering. After AI edits, run cold-start tests and grep for moved polyfills.

### Related Topics
Q1 (Hermes), Q3 (Metro), S4 (TurboModule lazy init), S5 (Expo Router), S7 (perf).

### Interview Follow-Up Questions
- "What's the difference between inline requires and RAM bundles?"
- "Why are barrel files an anti-pattern at scale?"
- "How does Bridgeless lazy module init relate to inline requires?"
- "How would you measure the impact of these techniques?"

### Memory Hook
**"Inline requires defer eval. RAM bundles defer load. Barrels undo both."**

### Revision Notes
> Inline requires moves `require` to call sites, deferring module evaluation; RAM bundles defer load (less needed with Hermes); avoid barrel files; pair with route splitting + TurboModule lazy init for big startup wins.

---

## Q5. Source maps & symbolication

### Difficulty
Intermediate

### Interview Frequency
Common.

### Prerequisites
Stack trace basics, build pipeline familiarity.

### TL;DR
Hermes ships **bytecode**, so production stack traces are bytecode offsets; you must upload **source maps** to Sentry/Crashlytics so traces become readable. Each release needs its own source map tied to the build's bundle hash.

### 30-Second Interview Answer
"In production, Hermes runs bytecode. Stack traces look like `Function:0x12abc` — useless without symbolication. Metro emits a source map; you upload it to your crash reporter (Sentry, Crashlytics) keyed by the release version. The reporter rewrites stacks to original file:line:column. Without this, you can't actually debug production crashes."

### 2-Minute Practical Answer
Two artifacts you must keep:
1. **JS source map** (`index.android.bundle.map`) — bytecode offset → JS line.
2. **Native debug symbols** (dSYM iOS, ProGuard/R8 mapping Android) — for native crashes.

For RN:
- iOS: Sentry CLI uploads source maps + dSYMs as part of the build.
- Android: Sentry/Crashlytics Gradle plugins upload mapping + source maps automatically.
- EAS Build: Expo's CI handles both with `eas.json` config.

Versioning matters: the source map must match the **bundle hash** in the released app. Mismatched maps produce wrong line numbers — sometimes worse than no map.

### 5-Minute Architecture Answer
RN's symbolication chain:
```
JS source → Babel → Metro module → Hermes bytecode
   ▲          ▲         ▲              ▲
   │          │         │              │
   └── source map (combined chain) ────┘
```

Sentry's `react-native-sentry` injects a unique build ID into both the bundle and the uploaded map. At crash time, the reporter looks up the map by build ID and rewrites the stack.

In 2026:
- Hermes' built-in source-map-aware stack traces (set via `compose-source-maps`) work in dev and tests.
- For OTA updates (EAS Update), every update generates a new bundle and must upload its own source map.
- Native frames (TurboModules in C++) need dSYM/ProGuard mapping in addition to JS source maps.

### The "Why"
- Production crash data is only as useful as it is readable.
- Hermes bytecode is intentionally opaque; source maps re-attach human meaning.

### Mental Model
Source map = **decoder ring** between what you wrote and what runs.

### Internal Working (2026 Context)
- Hermes bytecode includes a debug section pointing into the source map.
- React Native CLI's bundle command (`react-native bundle --sourcemap-output`) emits both.
- EAS Update's CLI auto-uploads to Sentry on publish if configured.

### Modern Implementation (Code)
`sentry.properties` (per platform) and Gradle/CocoaPods plugin handle uploads. The relevant config in `app.config.ts` (Expo):
```ts
export default {
  expo: {
    plugins: [
      [
        '@sentry/react-native/expo',
        { url: 'https://sentry.io/', organization: 'org', project: 'mobile' },
      ],
    ],
  },
};
```

CI gate (GitHub Actions excerpt):
```yaml
- name: Verify source map upload
  run: |
    eas build:list --status finished --limit 1 --json | jq '.[0].artifacts'
    sentry-cli releases files "$RELEASE" list
```

### Comparison

| Crash type           | What you need                       |
| -------------------- | ----------------------------------- |
| JS error             | JS source map                       |
| Hermes-specific      | Hermes-aware map (Metro emits this) |
| Native iOS           | dSYM                                |
| Native Android       | ProGuard/R8 mapping + native symbols|
| OTA update crash     | Source map for that specific update |

### Production Usage
- Required for Sentry/Crashlytics to be useful.
- EAS Build + Sentry plugin = zero-touch in good setups.
- Audit: every release must have all 4 artifact types uploaded.

### Hands-On Exercise
1. Build a release; capture a synthetic crash; check the stack in Sentry — should show your source line.
2. Bump the bundle without uploading the map; observe wrong line numbers.
3. Test an OTA update path; confirm the update's map uploads.

### Common Mistakes
- Forgetting to upload source maps for OTA updates.
- Stripping debug info too aggressively in ProGuard rules.
- Mismatched bundle/map versions (rebuild without re-upload).

### Production Red Flags
- "We can't reproduce the crash" — usually wrong line numbers from bad maps.
- Stack traces showing `0x...` hex offsets in prod.
- Missing dSYMs after iOS releases (Apple processing delay; verify upload).

### Performance & Metrics
- Source map upload adds seconds to CI.
- No runtime cost.

### Metrics That Matter
Crash-free sessions, % crashes symbolicated, mean time to root cause.

### Decision Framework
- Always upload all artifacts.
- Always tie maps to release version + bundle hash.
- Always test with a deliberate crash before trusting the pipeline.

### Senior-Level Insight
Symbolication is a **release-engineering invariant**, not a feature. Treat it like CI passing: if a release lacks symbols, it isn't really released — you've shipped a black box.

### Real-World Scenario
**Symptom:** New crash appears in 2% of sessions; stack trace says `<unknown>:0`.
**Investigation:** Source map upload silently failed in CI for that release.
**Root cause:** Sentry CLI auth token expired.
**Fix:** Rotate token; re-upload the map; reprocess.
**Lesson:** Add a CI gate that fails if source maps don't reach Sentry.

### Production Failure Story
**Incident:** Following an OTA update, all crashes pointed to the wrong file.
**Investigation:** OTA bundle uploaded but its source map wasn't.
**Root cause:** EAS Update step omitted Sentry upload.
**Fix:** Configure `expo-updates` + Sentry integration; re-issue update.
**Prevention:** Required CI step `eas update && sentry-cli react-native expo` post-publish.

### Debugging Checklist
1. Is the bundle ID in the crash matching an uploaded map?
2. Is the map's source root correct?
3. For OTA, did the update's map upload?
4. For Hermes-specific issues, did you compose maps with `compose-source-maps`?

### Advanced / Internal Knowledge
- Source maps are large; gzipped on upload, often 10–50MB per release.
- Sentry's "release health" feature ties crash data to deploys via the same release ID.
- ProGuard/R8 mapping files must be retained per release for years if you support old versions.

### 2026 AI Tip
AI is good at generating Sentry config snippets; bad at validating that uploads actually happen. Always verify with `sentry-cli releases files <release> list` after CI.

### Related Topics
S17 (testing/debugging), S18 (observability), S20 (CI/CD), S27 (runbooks).

### Interview Follow-Up Questions
- "What if Hermes is off — do you still need maps?"
- "How do you handle OTA updates and symbolication?"
- "What's the difference between dSYM and ProGuard mapping?"
- "How do you guarantee maps are uploaded?"

### Memory Hook
**"No map, no signal. Bytecode without symbols = blackbox."**

### Revision Notes
> Hermes ships bytecode → must upload source maps + dSYM (iOS) + ProGuard mapping (Android) keyed by release; OTA updates need their own map; CI gate to enforce.
