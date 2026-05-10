# Appendix L — 50-Question Drill Bank (per section)

> **How to use:** No answers here by design. Open this file alongside the matching `docs/` chapter. Speak the answer out loud in ≤60s. If you stumble, mark the Q with `[ ]` → `[x]` once fluent. Target: all 1,150 Qs fluent before D-day.
>
> Sections mirror `docs/02–24`. Use the "4-derivative method" inside your head: for each Q, also be able to answer (a) *why*, (b) *tradeoff*, (c) *production failure*, (d) *how you'd code it*.

---

## L.2 — JavaScript core (50)

1. Difference between `var`, `let`, `const` in scope, hoisting, TDZ.
2. What is the temporal dead zone — give an example that throws.
3. Primitive vs reference types — list all 7 primitives.
4. `==` vs `===` — name one case where `==` is "safe".
5. Explain `this` in 5 contexts (default, implicit, explicit, new, arrow).
6. Why arrow functions can't be used as constructors.
7. Closure — define + write a counter using one.
8. Stale closure inside `setInterval` — show bug + fix.
9. IIFE — what is it, when used today.
10. Event loop: stack vs microtask vs macrotask order.
11. Output: `console.log(1); setTimeout(..,0); Promise.resolve().then(..); console.log(4)`.
12. `Promise.all` vs `allSettled` vs `race` vs `any`.
13. Implement `Promise.all` from scratch.
14. Implement `pLimit(n)` — concurrency-limited fetch.
15. Implement `retry(fn, n, delay)` with exponential backoff.
16. Implement `debounce` and `throttle`.
17. Difference between debounce and throttle — RN use cases.
18. Implement `memoize(fn)`.
19. Implement deep clone (handle cycles).
20. Implement `curry(fn)`.
21. Implement `compose` and `pipe`.
22. Implement `Array.prototype.map` polyfill.
23. Implement `Array.prototype.reduce` polyfill.
24. Implement `Function.prototype.bind` polyfill.
25. Prototype chain — explain with `Object.create`.
26. `class` vs prototypal inheritance — what `class` desugars to.
27. `Object.freeze` vs `Object.seal` vs `const`.
28. Shallow vs deep equality — write `deepEqual`.
29. `Map` vs `Object` — when each.
30. `Set` vs array — perf characteristics.
31. WeakMap / WeakSet — use case.
32. Symbol — two real uses.
33. Iterators + generators — `function*` example.
34. `for...in` vs `for...of` vs `forEach`.
35. Spread vs rest — show 3 uses each.
36. Destructuring with defaults + renaming.
37. Optional chaining + nullish coalescing — `??` vs `||` trap.
38. JSON.stringify gotchas (functions, undefined, BigInt, circular).
39. Memory leak sources in JS (timers, listeners, closures, detached DOM/views).
40. Garbage collection — mark and sweep, generational hints.
41. `async/await` error handling vs `.catch`.
42. Top-level await — works in modules?
43. ES modules vs CommonJS — interop pitfalls in RN/Metro.
44. Tree shaking — what enables it.
45. Tagged template literals — example.
46. Proxy + Reflect — one real use case.
47. `eval` and `new Function` — security risks.
48. Strict mode — what it changes.
49. `typeof null` returns what — why.
50. Difference between `null` and `undefined` — when each appears.

---

## L.3 — TypeScript (50)

1. `type` vs `interface` — declarative differences + merge behavior.
2. When to prefer `interface` over `type`.
3. Generics — write `identity<T>`.
4. Generic constraint — `<T extends { id: string }>` example.
5. `keyof T` — what it returns.
6. `typeof variable` in type position.
7. `Pick<T,K>` vs `Omit<T,K>` — implement Pick.
8. `Partial<T>` vs `Required<T>` — implement Partial.
9. `Readonly<T>` — implement.
10. `Record<K,V>` — implement.
11. `ReturnType<typeof f>` — example.
12. `Parameters<typeof f>` — example.
13. `Awaited<P>` — why introduced.
14. `NonNullable<T>` — implement.
15. Conditional types — `T extends U ? X : Y`.
16. Distributive conditional types — gotcha with unions.
17. Mapped types — write `DeepReadonly<T>`.
18. Template literal types — `` `on${Capitalize<E>}` `` example.
19. Discriminated union — write `Result<T>` and narrow it.
20. Exhaustive switch with `never`.
21. Type guard — `function isUser(x): x is User`.
22. `unknown` vs `any` vs `never`.
23. `as const` — what it does to `['a','b']`.
24. `satisfies` operator — when it beats `as`.
25. Index signatures vs `Record`.
26. Function overloads — when needed.
27. `this` parameter typing.
28. Module augmentation — extend a 3rd-party type.
29. Declaration merging — interface example.
30. Ambient declarations — `.d.ts` for an untyped lib.
31. Strict flags — list `strict: true` sub-flags.
32. `noUncheckedIndexedAccess` — what it catches.
33. `exactOptionalPropertyTypes` — why useful.
34. `tsconfig` `paths` for monorepo.
35. Project references — when to split.
36. Type-only imports — `import type` benefit.
37. Enum vs union of literals — which to prefer in RN.
38. `const enum` — pitfalls in libraries.
39. Typing React `forwardRef` with generics.
40. Typing `useReducer` action union.
41. Typing React Navigation `RootStackParamList`.
42. Typing route props with `NativeStackScreenProps`.
43. Typing Zustand store with selector.
44. Typing async thunks in Redux Toolkit.
45. Zod `z.infer<typeof Schema>` — runtime + compile.
46. Branded types — `type UserId = string & { __brand: 'UserId' }`.
47. Variance: covariance vs contravariance — function param example.
48. `infer` keyword — write `MyReturnType<T>`.
49. Recursive types — JSON type definition.
50. Common TS errors: 2322, 2339, 2345 — what they mean.

---

## L.4 — React deep dive (50)

1. Render → reconcile → commit — what happens in each.
2. Fiber — what problem did it solve over stack reconciler.
3. Why keys must be stable + unique — bug from index keys.
4. Reconciliation rules — when React unmounts vs updates.
5. `React.memo` — what equality it uses.
6. When `React.memo` does NOT help.
7. `useState` lazy initializer — when to use.
8. Functional setState — why prefer over direct.
9. `useEffect` — when it fires (after paint).
10. `useLayoutEffect` vs `useEffect` — RN use case.
11. Cleanup function in `useEffect` — when it runs.
12. Missing dep warning — fix without disabling lint.
13. `useRef` — three uses (DOM/native ref, mutable box, previous value).
14. `useMemo` — when it actually helps.
15. `useCallback` — when it actually helps.
16. `useContext` — re-render problem + fix.
17. Context split pattern — state vs dispatch.
18. `useReducer` vs `useState` — when to switch.
19. `useTransition` — what it marks as non-urgent.
20. `useDeferredValue` — typeahead use case.
21. `useId` — why introduced.
22. `useSyncExternalStore` — when needed.
23. `useImperativeHandle` — example with `forwardRef`.
24. Custom hook rules — naming + call order.
25. Stale closure inside hook — show + fix.
26. Why effects run twice in StrictMode (dev).
27. Suspense — what it suspends on.
28. Error boundary — class component why still required.
29. Portals — RN equivalent.
30. Concurrent rendering — what is "tearing".
31. Server components — relevance to RN (none today, watch).
32. `React.lazy` — RN equivalent for code splitting.
33. Controlled vs uncontrolled inputs in RN.
34. Lifting state up — when it becomes prop drilling.
35. Render props vs hooks — modern preference.
36. HOC vs hook — modern preference.
37. Compound components pattern — example.
38. Provider hell — fix with composition.
39. `children` as a function — pattern name.
40. Why pure components matter for memoization.
41. Reconciler's "bailout" — what triggers it.
42. Batching: legacy vs automatic batching in 18.
43. `flushSync` — when to use.
44. Why setState is async.
45. Why two renders of same state value still bail out.
46. Fragment — when needed.
47. `key` on Fragment — `<>` vs `<Fragment key>`.
48. Reading state in event handler — closure trap.
49. Effect race condition on async fetch — cleanup pattern.
50. Top 5 anti-patterns: `useEffect` for derived state, index keys, inline objects in memoized child, deeply nested context, mutating state.

---

## L.5 — RN architecture (50)

1. Old architecture — three threads (JS, native/UI, shadow).
2. Bridge — what it serializes + why it bottlenecks.
3. New architecture — JSI, what it eliminates.
4. JSI — what it is (C++ API exposing JS engine to native).
5. Fabric — new renderer, what changed vs Paper.
6. TurboModules — vs old NativeModules.
7. Codegen — what it generates + from what spec.
8. Hermes — what it is, why default.
9. Hermes precompiled bytecode — startup benefit.
10. Yoga — layout engine, Flexbox subset.
11. Shadow tree — purpose.
12. Synchronous layout — Fabric capability.
13. Concurrent renderer in RN — Suspense status.
14. RuntimeScheduler — what it coordinates.
15. JS thread blocking — symptom on UI.
16. UI thread blocking — symptom.
17. Why animations should run on UI thread (Reanimated worklets).
18. Reanimated 3 — worklet model on UI thread.
19. `react-native-screens` — what it optimizes.
20. Native stack vs JS stack navigator.
21. AppState lifecycle — active/background/inactive.
22. App startup sequence — native → JS bundle → first render.
23. TTI (time to interactive) — how to measure.
24. Bundle splitting in RN — RAM bundles, inline requires.
25. Inline requires — what they delay.
26. Hermes bytecode caching — first vs subsequent launch.
27. Cold start vs warm start.
28. App size budget — typical splits.
29. ProGuard / R8 on Android — what they strip.
30. iOS bitcode — deprecated, what replaced it.
31. Universal APK vs split APKs / AABs.
32. Hermes vs JSC — perf + size tradeoffs.
33. Switching engines — config flag location (Android + iOS).
34. New arch enable — flags (`newArchEnabled`).
35. Interop layer — old modules under new arch.
36. View flattening — Fabric optimization.
37. Pressable vs Touchable — modern choice.
38. Native view hierarchy — how RN translates JSX.
39. `requestAnimationFrame` in RN — runs on which thread.
40. JS → native call sync vs async (JSI).
41. Native → JS event delivery (event emitter).
42. Out-of-tree platforms (Windows, macOS, tvOS).
43. Brownfield integration — embedding RN in native app.
44. Multiple RN instances — pitfalls.
45. Bridgeless mode — what it removes.
46. Fabric + Bridgeless required for full new arch.
47. RN versioning policy — release cadence + LTS.
48. New arch migration risks — third-party libs without TM/Fabric.
49. How to verify new arch is on at runtime.
50. Trace screenshot (Perfetto/Instruments) — what to look for.

---

## L.6 — Hermes, Metro, bundle, startup (50)

1. Hermes — purpose + tradeoffs vs JSC.
2. Hermes bytecode (.hbc) — when generated.
3. Hermes static optimizations (Hermes 0.12+).
4. Hermes Intl support — caveats on Android.
5. Source maps with Hermes — how to symbolicate.
6. Metro — what it does (bundler + dev server).
7. Metro vs Webpack — key differences.
8. Metro `transformer` vs `resolver` vs `serializer`.
9. `metro.config.js` — common customizations.
10. Symlinks in monorepo — Metro support flags.
11. Hermes + Reanimated — worklet babel plugin order.
12. Babel preset for RN — what it includes.
13. Inline requires — Babel plugin behavior.
14. RAM bundles — when they help.
15. Bundle splitting strategies in RN.
16. Hermes profiler — `.cpuprofile` capture.
17. Flipper status (deprecated direction) — replacement (React Native DevTools).
18. Startup tracing on Android — `am start -W`.
19. Startup tracing on iOS — Instruments "App Launch".
20. Cold start phases — process fork → bundle load → first frame.
21. Bundle load time — measurement.
22. JS engine init time — typical Hermes vs JSC.
23. First render — what dominates.
24. Image preloading on splash — pattern.
25. Splash screen native vs JS.
26. `react-native-bootsplash` purpose.
27. Dynamic `require` impact on bundle.
28. Tree shaking in Metro — limitations.
29. Module resolution — `react-native` field vs `main` vs `exports`.
30. Bundle visualization — `react-native-bundle-visualizer`.
31. App size analyzer — Android Studio APK Analyzer.
32. iOS app thinning — what Apple does.
33. Hermes bytecode size vs source.
34. Source map size — strip in production.
35. Sentry source map upload — Hermes flag.
36. ProGuard rules for RN — common keep rules.
37. Hermes garbage collector — generational.
38. Memory profiling Hermes — Chrome DevTools heap.
39. Hermes `enableSampleProfiler` — what it captures.
40. Metro cache — clearing (`--reset-cache`).
41. Watchman — role in Metro.
42. Symlinked workspaces — Yarn/PNPM workspaces.
43. Metro custom resolver — use case.
44. Asset registry — how images bundled.
45. Image require — relative path resolution.
46. Network image vs bundled image perf.
47. Hermes + Intl polyfill cost.
48. Hermes proxy support status.
49. Hermes WeakRef support.
50. Switching from Hermes back to JSC — when justified (almost never).

---

## L.7 — Performance (50)

1. 60fps frame budget — 16.67ms.
2. JS thread blocking — typical causes.
3. UI thread blocking — typical causes.
4. `console.log` perf cost in production.
5. `InteractionManager.runAfterInteractions` — use case.
6. `requestIdleCallback` in RN — alternative.
7. FlatList vs ScrollView — when each.
8. `keyExtractor` — why explicit.
9. `getItemLayout` — when it helps.
10. `initialNumToRender` — tuning.
11. `windowSize` — what it controls.
12. `maxToRenderPerBatch` — tradeoff.
13. `removeClippedSubviews` — gotchas.
14. `FlashList` vs `FlatList` — wins.
15. Recycler view model — how FlashList works.
16. Image perf — `react-native-fast-image` vs core Image.
17. Image cache strategies — disk vs memory.
18. Image resize before display — perf rule.
19. Avoiding overdraw — flat backgrounds.
20. `shouldComponentUpdate` / `React.memo` audits.
21. Why inline `style={{...}}` hurts memoization.
22. `StyleSheet.create` — what it does internally (ID lookup).
23. Reanimated worklet — runs on which thread.
24. `useSharedValue` vs `useState` — when each.
25. `useAnimatedStyle` — re-evaluation rules.
26. `runOnJS` / `runOnUI` — bridging worklet ↔ JS.
27. `react-native-gesture-handler` — why preferred.
28. LayoutAnimation vs Reanimated.
29. JS thread → UI thread bottlenecks (old arch bridge serialization).
30. Memory leaks — common 5 sources in RN.
31. Detecting leaks — Xcode Instruments + Android Studio profiler.
32. Hermes heap snapshot — workflow.
33. Large list memory — virtualization rules.
34. Re-render storm — diagnosis with React DevTools profiler.
35. `useMemo` overuse — when it hurts.
36. Context value identity — memoize the value object.
37. Selector libraries (Reselect, Zustand selectors) — use case.
38. Avoiding unnecessary `Provider` re-renders.
39. Code splitting via dynamic import — RN feasibility.
40. Image lazy loading on scroll.
41. Skeleton screens — UX vs spinner.
42. Optimistic UI — pattern.
43. Network waterfall — measure with Sentry/Reactotron.
44. Slow startup — top 3 mitigations.
45. JSON parse cost — large payload mitigation.
46. WebSocket message backpressure.
47. Animations dropping frames — Reanimated profiler.
48. ANR threshold (Android) — 5s.
49. iOS watchdog kill — 20s startup.
50. Battery drain — common culprits (location, polling, wake locks).

---

## L.8 — Native modules (Swift + Kotlin) (50)

1. Why write a native module — 3 reasons.
2. Old NativeModule (bridge) vs TurboModule (JSI).
3. Codegen spec — TS file location + format.
4. `NativeModule` registration on iOS — `RCT_EXPORT_MODULE`.
5. `NativeModule` registration on Android — `ReactPackage`.
6. Threading on iOS — `methodQueue`.
7. Threading on Android — `@ReactMethod` + executor.
8. Promise vs callback in old modules.
9. Async vs sync method (sync only via JSI).
10. Passing arrays/maps — type mapping table.
11. Returning custom objects — wrap in `WritableMap`.
12. Event emission — `RCTEventEmitter` (iOS) / `DeviceEventManagerModule` (Android).
13. Listener teardown — `startObserving` / `stopObserving`.
14. Native UI component — `RCTViewManager` / `SimpleViewManager`.
15. View props — `@ReactProp` declaration.
16. Commands on native view — old `dispatchViewManagerCommand` vs new (`UIManager`).
17. Fabric component spec — Codegen output structure.
18. Migrating an existing module to TurboModule — steps.
19. Sharing C++ code across iOS/Android — JSI binding.
20. iOS Swift module — bridging header gotchas.
21. Android Kotlin module — `ReactContextBaseJavaModule` base.
22. Calling main thread on iOS — `DispatchQueue.main`.
23. Calling UI thread on Android — `runOnUiThread`.
24. Coroutines in Android module — bridging to RN promise.
25. Concurrency in Swift module — `Task` + `await`.
26. Thread safety — `@Synchronized` / locks.
27. Permissions on iOS — Info.plist keys.
28. Permissions on Android — runtime request.
29. Foreground service — Android Q+ rules.
30. Background task on iOS — `BGTaskScheduler`.
31. WorkManager on Android — when to use.
32. Native logging — `os_log` (iOS) vs `Log` (Android).
33. Symbolicating crashes from native module.
34. Versioning a module — semver + RN compat matrix.
35. Publishing a TM module to npm — checklist.
36. Autolinking — how it discovers modules (iOS vs Android).
37. Manual linking — when still needed.
38. CocoaPods — `pod install` after dep change.
39. Gradle — `react-native-modules.gradle` autolinking.
40. ABI mismatch on Android — `armeabi-v7a` etc.
41. iOS bitcode — current state.
42. JSI Host Object — implement counter example.
43. JSI Host Function — example.
44. Memory management JSI — `jsi::Value` lifetimes.
45. Catching native exceptions and surfacing to JS.
46. Module init cost on startup.
47. Lazy module init — `requiresMainQueueSetup` (iOS).
48. Sensitive data — keychain vs SecureStore.
49. Calling another module from a module — DI patterns.
50. Testing native module — XCTest + JUnit + JS-side mock.

---

## L.9 — Debugging (50)

1. React Native DevTools — what it replaces (Flipper, Hermes Inspector).
2. Chrome DevTools attach to Hermes — workflow.
3. React DevTools — Profiler tab walkthrough.
4. Reactotron — top 3 uses.
5. Network inspection — Reactotron vs Charles vs Proxyman.
6. Charles SSL pinning bypass — for debugging only.
7. Source map symbolication — Hermes bundle.
8. Sentry symbolication — upload artifacts step.
9. Crashlytics symbolication — dSYM upload.
10. Native crash log on iOS — Xcode → Window → Devices.
11. Native crash log on Android — `adb logcat`.
12. ANR trace location — `/data/anr/`.
13. Hermes profiler capture + analyze.
14. Systrace / Perfetto — what they show.
15. Instruments (iOS) — Time Profiler use.
16. Memory leak hunt — heap snapshot diff.
17. Layout debugging — `Show Layout Bounds` (Android).
18. iOS view hierarchy — Xcode debugger.
19. RN Inspector overlay — toggle in dev menu.
20. Performance overlay — what FPS counters mean.
21. `console.log` removal in prod — Babel plugin.
22. Source-mapped stack trace in red box.
23. `LogBox` ignore patterns.
24. Network logging — `XHRInterceptor`.
25. Tracing a slow render — Profiler "why did this render".
26. Tracing JS thread block — Hermes sampling profiler.
27. `setTimeout` drift — diagnosing.
28. Zombie listeners — finding via leaked subscriptions.
29. Reanimated worklet debug — `console.log` in worklet caveat.
30. Gesture handler not firing — common config bugs.
31. Navigation state debug — `useNavigationState`.
32. Deep link not opening — verification flow.
33. Universal link debug on iOS — `apple-app-site-association`.
34. App link debug on Android — `assetlinks.json`.
35. Push not arriving — APNs vs FCM token check.
36. Notification permission denied — re-prompt strategy.
37. Background fetch debug on iOS.
38. WorkManager job debug on Android.
39. WebView debug — Safari (iOS) / Chrome (Android).
40. Network HTTPS errors — ATS (iOS) / cleartext (Android).
41. Time zone bug repro — device settings override.
42. Locale bug repro — RTL mode.
43. Memory pressure simulator — Xcode + Android.
44. Background app crash — OOM kill.
45. App not opening from cold — Hermes corrupt cache.
46. Metro stuck — clear cache + watchman watch-del-all.
47. Pod install fails — `pod repo update`.
48. Gradle daemon crash — JVM heap size.
49. CI flake — emulator boot timing.
50. Production-only bug — JS bundle minification difference.

---

## L.10 — State management (50)

1. Local vs global state — decision rule.
2. Server state vs client state — separation reason.
3. React Query / TanStack Query — what problem it solves.
4. RQ cache invalidation strategies.
5. RQ optimistic updates — pattern.
6. RQ vs SWR — differences.
7. Redux Toolkit — when justified.
8. RTK slice anatomy.
9. RTK Query vs React Query.
10. Redux middleware — thunk vs saga vs listener.
11. Saga vs thunk — when each.
12. Zustand — store creation pattern.
13. Zustand selectors — avoid full re-render.
14. Zustand persist middleware — RN AsyncStorage.
15. Jotai atoms — primitive vs derived.
16. Recoil status (paused) — alternatives.
17. MobX observables — when to choose.
18. Context API — when sufficient.
19. Context split (state + dispatch) reasoning.
20. `useSyncExternalStore` — for libraries.
21. Persisting state — what NOT to persist (auth tokens never in plain).
22. Hydration on app start — race conditions.
23. Optimistic UI — rollback strategy on failure.
24. Pagination — cursor vs offset.
25. Infinite scroll — RQ `useInfiniteQuery`.
26. Cache stale-while-revalidate — meaning.
27. Background refetch — `refetchOnAppFocus`.
28. WebSocket → store sync pattern.
29. Form state — RHF vs Formik.
30. Form validation — Zod resolver pattern.
31. Derived state — compute in render, not state.
32. Store normalization — when to normalize.
33. EntityAdapter (RTK) — purpose.
34. Selector memoization — Reselect / `createSelector`.
35. Storing dates in store — string vs Date object.
36. Time travel debugging — Redux DevTools.
37. Action shape — payload + meta convention.
38. RTK `createAsyncThunk` — auto-generated actions.
39. Error state in thunks — typed reject value.
40. Loading flags — global vs per-resource.
41. Auth state — where to store + how to share.
42. Theme state — context vs store.
43. Locale state — RTL switch flow.
44. Feature flags — store vs remote config.
45. Offline queue — Redux Persist + custom middleware.
46. Migrations on persisted state — versioning.
47. Avoiding store bloat — subdivide by feature.
48. Testing reducers — pure function tests.
49. Testing async thunks — mock fetcher.
50. Anti-pattern: putting form state in Redux — why bad.

---

## L.11 — Navigation + deep linking (50)

1. React Navigation vs Expo Router — choice criteria.
2. Native stack vs JS stack — perf differences.
3. `react-native-screens` — role.
4. Tab navigator — bottom tab perf tips.
5. Drawer navigator — gesture-handler dependency.
6. Nested navigators — common bug (wrong nav prop).
7. Typing `RootStackParamList` end-to-end.
8. `useNavigation` typed hook.
9. `useRoute` typed.
10. Linking config — `prefixes` + `config.screens`.
11. Universal Links iOS — AASA file structure.
12. App Links Android — `assetlinks.json` + verify.
13. Custom URL scheme — fallback.
14. Deferred deep links — Branch / Adjust.
15. Deep link with auth — gate pattern.
16. Initial URL — `Linking.getInitialURL`.
17. Background link open — listener.
18. Notification → screen route — payload contract.
19. Conditional navigator (auth vs main) — re-mount cost.
20. Modal vs screen — when each.
21. Header customization — per-screen vs default.
22. Bottom sheet vs modal — UX rules.
23. Gesture-driven dismissal — gesture handler integration.
24. Screen params serializability warning — fix.
25. Navigation state persistence — restore on relaunch.
26. State container — `NavigationContainer ref`.
27. Programmatic navigation outside components — ref pattern.
28. Reset navigation — `CommonActions.reset`.
29. Replace vs push — UX implications.
30. Back button (Android) — `BackHandler` per-screen.
31. iOS swipe-back gesture — disable per screen.
32. Tab bar visibility per screen.
33. Lazy loading screens — `lazy: true`.
34. Initial route name — vs initial state.
35. Screen options as function vs object.
36. Status bar control per screen.
37. Safe area — `SafeAreaProvider` placement.
38. Deep link testing — `xcrun simctl openurl` + `adb shell am start`.
39. Unhandled deep link — fallback screen.
40. Deep link analytics — track source param.
41. Web fallback page for universal link.
42. Branch SDK link attribution.
43. AppsFlyer attribution differences.
44. SSO redirect — universal link return.
45. Payment redirect (UPI intent → app) — flow.
46. WebView → app handoff.
47. Multi-window deep link (tablet/foldable).
48. App Clip / Instant App — link routing.
49. Cold start vs warm start deep link timing.
50. Test matrix for deep links — table per platform.

---

## L.12 — Networking (50)

1. `fetch` vs `axios` — RN tradeoffs.
2. Axios interceptors — auth + retry.
3. Cancellation — AbortController pattern.
4. Timeout in `fetch` — manual via AbortSignal.
5. Concurrent fetch with limit — `pLimit`.
6. Retry with exponential backoff + jitter.
7. Idempotency keys for POST.
8. ETag / If-None-Match for caching.
9. Conditional GET — 304 handling.
10. Compression — gzip / brotli on RN.
11. HTTP/2 vs HTTP/1.1 — RN client behavior.
12. HTTP/3 (QUIC) — RN status.
13. Multipart form upload pattern.
14. Background upload — iOS `URLSessionConfiguration.background`.
15. Background download — Android WorkManager.
16. WebSocket — keep-alive ping/pong.
17. WebSocket reconnect with backoff.
18. Server-Sent Events — RN polyfill status.
19. GraphQL — Apollo vs urql vs Relay.
20. Apollo cache normalization — `__typename` + id.
21. GraphQL persisted queries — security + size.
22. GraphQL subscriptions — transport choice.
23. REST vs GraphQL — when each.
24. gRPC in RN — feasibility.
25. Protobuf payloads — size win.
26. Pagination — cursor vs offset semantics.
27. Rate limiting on client — sliding window.
28. Circuit breaker pattern.
29. Network state monitoring — `@react-native-community/netinfo`.
30. Offline queue + replay.
31. Request deduplication — RQ does it.
32. SWR / RQ stale time vs cache time.
33. Optimistic update + server reconciliation.
34. CORS — does RN have CORS (no, native client).
35. Cookies in RN — `react-native-cookies`.
36. Auth header injection per-request.
37. Token refresh race — single-flight pattern.
38. Request signing (HMAC) — header construction.
39. Mutual TLS — RN feasibility.
40. Certificate pinning — implementation per platform.
41. Trust kit (iOS) for pinning.
42. Network security config (Android) for pinning.
43. Charles + pinning bypass — dev only.
44. Logging request/response — PII redaction.
45. Sentry network breadcrumb — what's captured.
46. Telemetry — request duration histogram.
47. P50/P95/P99 — what each measures.
48. Slow API mitigation — skeleton + cached fallback.
49. Empty state vs error state UX.
50. Retryable vs non-retryable status codes.

---

## L.13 — Auth, sessions, tokens (50)

1. OAuth 2.0 — 4 flows.
2. PKCE — what it protects (public clients).
3. Authorization Code + PKCE — full flow.
4. Implicit flow — deprecated reason.
5. Client Credentials — when used.
6. Device Code flow — TV use case.
7. Access token vs refresh token — lifetimes.
8. Refresh token rotation — replay protection.
9. ID token (OIDC) — what it contains.
10. JWT structure — header.payload.signature.
11. JWT signing algos — RS256 vs HS256.
12. JWT vs opaque token tradeoffs.
13. Storing access token — Keychain (iOS) / Keystore (Android).
14. SecureStore vs AsyncStorage — never store tokens in AS.
15. Encrypted shared prefs (Android).
16. Biometric prompt — FaceID / fingerprint.
17. Biometric-gated keychain item — `kSecAccessControlBiometryCurrentSet`.
18. Session expiry — silent refresh strategy.
19. Multiple-device sessions — server-side revoke list.
20. SSO — same-app vs cross-app.
21. Sign in with Apple — required if SSO present.
22. Google Sign-In on RN — native SDK use.
23. Magic link auth — UX.
24. OTP — SMS vs TOTP.
25. WebAuthn / passkeys — RN status.
26. CSRF — relevance in mobile (low for token auth).
27. XSS in WebView — auth risk.
28. Token leak in logs — PII redaction.
29. Token leak in crash report — Sentry scrub.
30. App backgrounded → blur sensitive screens.
31. Auto-logout on inactivity — timer pattern.
32. Forced logout on password change — server push.
33. Step-up auth — for high-risk action.
34. Re-auth before payment — UX.
35. Deep link with token — must validate.
36. Auth deep link callback — universal link preferred.
37. WebView OAuth — vs ASWebAuthenticationSession (iOS) / Custom Tabs (Android).
38. `expo-auth-session` flow.
39. Cookie-based session in RN — `react-native-cookies`.
40. Refresh storm on app open — single-flight.
41. Clock skew handling.
42. Token introspection endpoint — RFC 7662.
43. Logout endpoint — server-side revoke.
44. Refresh token reuse detection.
45. Anonymous → logged-in user merge — cart merge example.
46. Multi-tenant auth — tenant in token claim.
47. RBAC vs ABAC — claim shape.
48. Feature flags + auth claims.
49. Audit logging on client actions.
50. Session hijack detection — IP/device fingerprint.

---

## L.14 — Offline-first + storage (50)

1. AsyncStorage — what it is, limits.
2. AsyncStorage size limit Android (6MB default).
3. MMKV — perf vs AsyncStorage.
4. MMKV encryption.
5. SQLite — `react-native-sqlite-storage` / `op-sqlite`.
6. WatermelonDB — when to choose.
7. Realm — when to choose.
8. Drizzle / Kysely — typed query builders.
9. Schema migration — versioning strategy.
10. Encryption at rest — keychain-backed key.
11. SecureStore items size limit.
12. File system — `react-native-fs` vs `expo-file-system`.
13. Cache directory vs documents directory.
14. Image cache eviction policy.
15. Offline queue — store mutation intent.
16. Conflict resolution — LWW vs CRDT.
17. Sync engine design — push/pull vs subscribe.
18. Optimistic write + rollback.
19. Idempotency on retry.
20. Background sync iOS — BGAppRefreshTask.
21. Background sync Android — WorkManager constraints.
22. Network-aware sync — battery + Wi-Fi only.
23. Detecting connectivity changes.
24. Replay queue ordering — FIFO vs priority.
25. Deduplicating queued ops.
26. Storage corruption recovery.
27. Backup/restore — iCloud / Google Backup flags.
28. Excluding sensitive data from backup.
29. App data clear flow.
30. GDPR data export feature.
31. PII at rest — encrypt.
32. Logs at rest — rotate + cap size.
33. Indexed lookups — SQLite indexes.
34. Pagination on local DB.
35. FTS (full-text search) in SQLite.
36. Realm sync vs custom sync.
37. WatermelonDB sync protocol.
38. Conflict-free replicated data types (CRDT) — overview.
39. Last-write-wins pitfalls.
40. Vector clocks — overview.
41. Server-side sync API design.
42. Delta sync vs full sync.
43. Initial sync UX — progress + skeleton.
44. Storage quota monitoring.
45. Migration from AsyncStorage to MMKV.
46. Encryption key rotation.
47. Keychain access group (share between extension + app).
48. App Group container (iOS) for widget sharing.
49. Content provider (Android) for cross-app share.
50. Offline analytics queue.

---

## L.15 — Push notifications (50)

1. APNs vs FCM — architecture.
2. APNs token vs FCM token — lifecycle.
3. Token registration flow — when to upload to server.
4. Token rotation — handle on app open.
5. iOS notification permissions — provisional vs explicit.
6. Android 13+ POST_NOTIFICATIONS runtime permission.
7. Notification categories / channels.
8. Channel importance levels (Android).
9. Critical alerts iOS — entitlement.
10. Silent push — `content-available: 1`.
11. Background fetch trigger via silent push.
12. Notification payload size limits (4KB iOS, 4KB FCM).
13. Rich notifications — image attachments iOS.
14. Notification Service Extension — modify payload.
15. Notification Content Extension — custom UI.
16. Android big-text / big-picture style.
17. Action buttons — handler routing.
18. Notification grouping (Android channel + iOS thread-id).
19. Localized notifications — `loc-key`.
20. Scheduled local notifications.
21. Geofencing notifications.
22. Notification → deep link routing.
23. Cold start from notification — initial notification.
24. Notification while app foregrounded — display rules.
25. iOS foreground notification — `willPresent` delegate.
26. Notification analytics — open rate.
27. Token unregister on logout.
28. Multi-account token mgmt.
29. Device-level mute respect.
30. Quiet hours — server-side.
31. Throttling per-user.
32. Topic subscriptions (FCM).
33. iOS Push to Talk framework.
34. Live Activities iOS — overview.
35. Dynamic Island integration.
36. Android foreground service notification.
37. Notification permission re-prompt strategy.
38. Settings deep link to enable notifications.
39. Push provider abstraction in code.
40. Firebase vs OneSignal vs Airship.
41. Server-side fan-out architecture.
42. Notification template versioning.
43. A/B test push copy.
44. Delivery receipts — feasibility.
45. Push debugging — APNs console / FCM test send.
46. Common bugs: wrong env (dev vs prod APNs).
47. Bundle ID mismatch.
48. Provisioning profile push capability.
49. Voice over IP (VoIP) push — CallKit.
50. PushKit token vs APNs token.

---

## L.16 — Mobile security (50)

1. OWASP Mobile Top 10 — list.
2. Insecure data storage — examples.
3. Insecure communication — TLS pitfalls.
4. Certificate pinning — pros/cons.
5. Root / jailbreak detection — how + bypass risk.
6. Tamper detection — signature check.
7. Reverse engineering JS bundle — minify + Hermes bytecode.
8. Hermes bytecode is NOT encryption — clarify.
9. Code obfuscation — ProGuard / R8 / Hermes.
10. String obfuscation for secrets.
11. Secrets in code — never; use server.
12. API key rotation strategy.
13. App-attest (iOS) / Play Integrity — attestation.
14. SafetyNet (deprecated) → Play Integrity.
15. Device binding — bind token to device.
16. Anti-debugging measures.
17. Frida detection — heuristics.
18. Screenshot prevention on sensitive screens.
19. Screen recording detection.
20. Clipboard sensitive data — clear on background.
21. Keyboard logging — secure text entry.
22. WebView security — `javaScriptEnabled` only when needed.
23. WebView allowlist URLs.
24. Deep link injection — validate params.
25. Intent redirection (Android) — validate scheme + host.
26. URL scheme hijacking iOS — universal links preferred.
27. Biometric storage — not "biometric verifies user".
28. Fallback PIN handling.
29. SSL pinning library — TrustKit / okhttp CertificatePinner.
30. Pin rotation strategy — backup pin.
31. Two-pin (primary + backup) approach.
32. Network security config Android — disable cleartext.
33. iOS ATS — exception domains.
34. Logs PII scrub — Sentry beforeSend.
35. Crash report PII — same.
36. Analytics PII allowlist.
37. GDPR consent flow.
38. App Tracking Transparency iOS.
39. IDFA / GAID — when allowed.
40. Persistent ID alternatives.
41. Encryption export compliance — `ITSAppUsesNonExemptEncryption`.
42. Secrets in CI — vault use.
43. EAS secrets / GitHub Actions secrets.
44. Code-signing key storage.
45. Notarization (macOS) for related tooling.
46. Supply chain — lockfile + audit.
47. Dep vulnerability scan (Snyk / npm audit).
48. SBOM — generate for app.
49. Penetration test scope checklist.
50. Bug bounty program scope for mobile.

---

## L.17 — a11y, color, fonts, i18n (50)

1. `accessibilityLabel` — when needed.
2. `accessibilityHint` vs label.
3. `accessibilityRole` — values list.
4. `accessibilityState` — selected/disabled/expanded.
5. `accessible` prop — grouping children.
6. `accessibilityLiveRegion` (Android).
7. `accessibilityElementsHidden` (iOS).
8. `importantForAccessibility` (Android).
9. Focus order — `accessibilityViewIsModal`.
10. Screen reader testing — VoiceOver + TalkBack.
11. Dynamic type / font scaling.
12. `allowFontScaling` prop.
13. Max font scale clamp.
14. Color contrast ratio — WCAG AA 4.5:1.
15. Tools: `react-native-accessibility-engine`.
16. Touch target size — 44pt iOS / 48dp Android.
17. Hit slop for small icons.
18. Reduced motion — `AccessibilityInfo.isReduceMotionEnabled`.
19. Bold text setting respect.
20. Inverted colors detection.
21. RTL layout — `I18nManager.allowRTL`.
22. RTL flip — automatic vs manual.
23. RTL icons — flip arrows.
24. `start`/`end` instead of `left`/`right`.
25. Locale detection — `expo-localization`.
26. i18n libraries — i18next / react-intl / Lingui.
27. Pluralization — ICU MessageFormat.
28. Date formatting — Intl.DateTimeFormat (Hermes Intl).
29. Number formatting — currency / percent.
30. Hermes Intl on Android — enable flag.
31. Time zone awareness.
32. Currency formatting per locale.
33. Translation management — Lokalise / Crowdin / Phrase.
34. Pseudo-localization for QA.
35. String externalization — never hardcode.
36. Context for translators — comments.
37. Gendered language handling.
38. Language switch in-app — restart vs hot reload.
39. Font loading — `expo-font` / `react-native-vector-icons`.
40. Custom font weight matching.
41. Variable fonts — RN status.
42. Emoji rendering — system font fallback.
43. Color tokens — design system mapping.
44. Dark mode — `useColorScheme`.
45. System theme override toggle.
46. Theme switch animation.
47. High-contrast mode.
48. Voice control commands (iOS).
49. Switch control accessibility.
50. a11y audit checklist before release.

---

## L.18 — Testing (50)

1. Test pyramid for RN — unit / component / e2e ratio.
2. Jest config for RN — preset.
3. Mocking native modules — `jest.setup.js`.
4. `react-native-testing-library` — query priorities.
5. `getByRole` vs `getByText` vs `getByTestId`.
6. `userEvent` vs `fireEvent`.
7. Async assertions — `findBy`.
8. Snapshot tests — when worthwhile.
9. Snapshot stale — update workflow.
10. Mocking timers — `jest.useFakeTimers`.
11. Mocking AsyncStorage.
12. Mocking fetch — MSW vs manual.
13. MSW (Mock Service Worker) RN setup.
14. Testing custom hooks — `renderHook`.
15. Testing navigation — `NavigationContainer` wrapper.
16. Testing context providers — wrapper helper.
17. Testing Reanimated — mock module.
18. Testing gesture handler.
19. Testing redux slice — pure reducer test.
20. Testing thunks — mock dispatch + state.
21. Testing RTK Query — `setupApiStore`.
22. Coverage thresholds — meaningful targets.
23. Coverage gaps — known patterns to ignore.
24. Detox — e2e setup.
25. Detox sync vs idle waiting.
26. Detox flakiness — common causes.
27. Maestro — alternative to Detox, when to choose.
28. Appium — when justified.
29. CI emulator — Android setup.
30. CI simulator — iOS on macOS runners.
31. Visual regression — Storybook + Loki / Chromatic RN feasibility.
32. Storybook for RN — setup.
33. Component variants in Storybook.
34. a11y test in Storybook.
35. Contract tests with backend — Pact.
36. Performance regression — bundle size CI check.
37. Startup time CI check.
38. Memory leak test in CI — Detox + Instruments.
39. Crash-free user rate target — 99.9%.
40. Test data factories — `@faker-js/faker`.
41. Deterministic dates in tests.
42. Locale tests — RTL + non-en.
43. Snapshot per-platform.
44. Mocking Permissions API.
45. Mocking Push notifications.
46. Mocking native bridge for WS.
47. Test seed for property-based tests.
48. Mutation testing — Stryker feasibility.
49. Flake quarantine policy.
50. Manual regression checklist before release.

---

## L.19 — CI/CD, EAS, Fastlane, releases (50)

1. EAS Build vs Fastlane — choice.
2. EAS Build profiles — dev / preview / prod.
3. EAS submit — store upload.
4. EAS Update — OTA flow.
5. CodePush status (sunsetting) — alternatives.
6. OTA constraint — JS only, no native code change.
7. OTA rollback strategy.
8. Channel-based OTA targeting.
9. Versioning strategy — semver + build number.
10. iOS build number must increment per upload.
11. Android versionCode rules.
12. Signing iOS — manual vs automatic in CI.
13. Match (Fastlane) — cert sync.
14. Android keystore — store securely.
15. Play App Signing — what Google manages.
16. Internal testing track Play Console.
17. TestFlight internal vs external.
18. Phased release iOS — 7-day rollout.
19. Staged rollout Android — % bumps.
20. Hotfix flow — expedited review.
21. Beta testers management.
22. Release notes localization.
23. Screenshots automation — Fastlane snapshot.
24. App Store Connect API.
25. Play Developer API.
26. CI provider choice — GitHub Actions / Bitrise / Circle.
27. Pipeline stages — lint / test / build / e2e / deploy.
28. Caching strategies — node_modules / Pods / Gradle.
29. Build matrix — iOS + Android in parallel.
30. Artifact retention.
31. Provisioning profile expiry.
32. Cert expiry monitoring.
33. Sentry release & sourcemap upload step.
34. Crashlytics dSYM upload.
35. App size diff per PR.
36. Bundle analyzer step.
37. Fastlane Match storage — git vs S3.
38. Encrypted env files in CI.
39. PR preview build — EAS preview channel.
40. Branch-per-environment OTA.
41. Feature flag flip on release.
42. Kill switch for forced upgrade.
43. Minimum supported version enforcement.
44. App update prompt — soft vs hard.
45. Native module change → require store release.
46. Submission rejection common reasons.
47. Privacy manifest iOS (PrivacyInfo.xcprivacy).
48. Data safety form Play Console.
49. Pre-launch report Android.
50. Post-release smoke test plan.

---

## L.20 — Observability (50)

1. Three pillars — logs / metrics / traces.
2. Sentry RN setup — wrapping App.
3. Sentry Hermes — `@sentry/react-native` Hermes profiler.
4. Sentry source maps — auto-upload.
5. Crashlytics RN setup.
6. Difference: Sentry vs Crashlytics.
7. Native crash vs JS crash capture.
8. Breadcrumbs — what's auto-captured.
9. Custom breadcrumbs.
10. User context — `setUser` (no PII).
11. Tags vs context.
12. Release tagging.
13. Environment tagging.
14. Sample rate — perf events.
15. Trace propagation header.
16. Distributed tracing — backend correlation.
17. Crash-free session rate.
18. Crash-free user rate.
19. ANR reporting — Sentry / Crashlytics.
20. OOM detection.
21. Slow render detection.
22. Frozen frame detection.
23. Slow startup metric.
24. TTI metric.
25. Custom transactions — name conventions.
26. Network breadcrumb redaction.
27. PII scrub — `beforeSend` hook.
28. Source-map symbolication failures — debug.
29. dSYM upload failures — debug.
30. ProGuard mapping upload.
31. Hermes bundle ID matching.
32. Release health — adoption metric.
33. Issue triage workflow.
34. Alerting rules — error rate spike.
35. SLO definition for mobile.
36. Error budgets.
37. Analytics: GA4 / Mixpanel / Amplitude.
38. Event taxonomy design.
39. Funnel analysis.
40. Retention cohorts.
41. Attribution — Branch / AppsFlyer.
42. Feature flag analytics — variant exposure.
43. A/B test stat-sig.
44. Performance budgets per screen.
45. Network success rate.
46. Backend error correlation.
47. Privacy in analytics — opt-out.
48. Server-side event ingestion.
49. Reverse-ETL of mobile events.
50. Dashboard hygiene — kill stale dashboards.

---

## L.21 — Mobile system design (50)

1. Mobile design framework — Reqs / Constraints / API / Storage / Sync / Offline / Push / Scale / Failure / Telemetry.
2. Functional vs non-functional reqs.
3. Mobile NFRs — battery, data, memory, offline.
4. Capacity sizing — DAU vs requests/sec.
5. Latency budget — P99 target.
6. Estimation — back-of-envelope.
7. Design WhatsApp clone — chat sync.
8. Message ordering — vector clock vs server timestamp.
9. Read receipts — sync model.
10. Typing indicators — WebSocket.
11. End-to-end encryption — Signal protocol overview.
12. Offline message queue.
13. Media upload — chunked + resumable.
14. Design Instagram feed — pagination + caching.
15. Feed ranking — server vs client.
16. Image CDN strategy.
17. Stories — ephemeral storage.
18. Design Uber rider app — location streaming.
19. Background location — battery tradeoffs.
20. Map rendering — vector vs raster.
21. ETA caching.
22. Design Razorpay payment SDK.
23. Idempotency for payment.
24. Retry semantics.
25. PCI-DSS scope reduction.
26. Design food delivery tracking.
27. Order state machine.
28. Live tracking — polling vs WS vs MQTT.
29. Design news reader — offline-first.
30. Pre-fetch strategy.
31. Design notification system at scale.
32. Fan-out vs fan-in.
33. Design analytics SDK.
34. Batching events — flush triggers.
35. Backpressure on bad network.
36. Design SDK for partner integration.
37. Public API surface design.
38. Versioning SDK.
39. Migration / deprecation plan.
40. Design feature flag system.
41. Bucket assignment determinism.
42. Variant exposure logging.
43. Design dynamic config delivery.
44. Cache-first vs network-first config.
45. Design forced upgrade flow.
46. Design auth across multiple apps (SSO).
47. Design data sync for multi-device.
48. Conflict UX surfacing.
49. Design dark mode + theming system.
50. Design A/B testing harness with confidence intervals.

---

## L.22 — DSA (50)

1. Reverse a string in-place.
2. Two-sum (hash map).
3. Three-sum.
4. Best time to buy/sell stock (one pass).
5. Maximum subarray (Kadane).
6. Move zeroes.
7. Container with most water.
8. Trap rain water.
9. Group anagrams.
10. Top-K frequent elements (heap).
11. Longest substring without repeating chars.
12. Longest palindromic substring.
13. String to integer (atoi).
14. Valid parentheses (stack).
15. Min stack.
16. Daily temperatures (monotonic stack).
17. Sliding window max.
18. Linked list reverse (iterative + recursive).
19. Detect cycle (Floyd).
20. Merge two sorted lists.
21. Merge K sorted lists (heap).
22. Remove Nth from end.
23. LRU cache (map + DLL).
24. LFU cache.
25. Binary tree level order traversal (BFS).
26. Inorder traversal iterative.
27. Validate BST.
28. Lowest common ancestor.
29. Diameter of binary tree.
30. Serialize/deserialize binary tree.
31. Number of islands (DFS/BFS).
32. Course schedule (topo sort).
33. Word ladder (BFS).
34. Clone graph.
35. Dijkstra shortest path.
36. Climbing stairs (DP).
37. House robber.
38. Longest increasing subsequence.
39. Coin change (DP).
40. Edit distance.
41. 0/1 knapsack.
42. Word break.
43. Permutations / combinations / subsets (backtracking).
44. N-queens.
45. Sudoku solver.
46. Quick select (kth smallest).
47. Merge sort + quicksort.
48. Heap sort.
49. Trie — implement insert + search.
50. Union-find — implement with path compression.

---

## L.23 — Behavioral / STAR (50)

1. Tell me about yourself (90s).
2. Walk me through a project you led.
3. Biggest production incident — detail RCA.
4. Conflict with PM / designer — how resolved.
5. Conflict with peer — example.
6. Time you disagreed with manager.
7. Time you mentored junior — outcome.
8. Time you got critical feedback — what changed.
9. Time you missed a deadline.
10. Time you said no to scope.
11. Time you broke production.
12. Time you fixed a flaky test suite.
13. Time you reduced bundle / startup.
14. Time you migrated architecture (old → new arch).
15. Time you championed a tech choice that lost.
16. Time you championed one that won.
17. Time you led a hiring loop.
18. Time you wrote an ADR.
19. Time you killed a feature.
20. Most ambiguous problem you owned.
21. Cross-team dependency you unblocked.
22. Time you simplified an over-engineered system.
23. Time you said "we should rewrite" — and were wrong.
24. Time you debugged something for >2 days.
25. Time you owned an on-call.
26. Most impactful 1-line code change.
27. Toughest performance bug.
28. Toughest memory bug.
29. Toughest deep-link bug.
30. Toughest auth bug.
31. Toughest payment bug.
32. Time you handled a security incident.
33. Time you handled a data loss bug.
34. Time you ran a postmortem (blameless).
35. Time you presented to leadership.
36. Time you led a 0→1 launch.
37. Time you migrated 1M users.
38. Time you sunset a feature.
39. Time you balanced quality vs deadline.
40. Time you said "this can wait".
41. Time you pushed back on a leader.
42. Time you took a calculated risk.
43. Time you failed and what you learned.
44. Time you delivered under unclear requirements.
45. Time you proposed a process improvement.
46. Time you handled an underperformer.
47. Time you celebrated a teammate's win.
48. How do you stay technically current.
49. Why this company / role.
50. What questions do you have for us.

---

## L.24 — Resume / LinkedIn / negotiation (50)

1. One-line headline for LinkedIn.
2. About section structure (3 paras).
3. Featured section — what to pin.
4. Banner image — message.
5. Skill ordering — top 3.
6. Recommendations strategy.
7. Open-to-work signal — public vs recruiters-only.
8. Resume length — 1 page vs 2.
9. Resume bullet formula — Action + tech + metric.
10. Top-of-resume summary block.
11. Quantifying impact when no public metric.
12. Listing tech stack — categorize.
13. Listing OSS / side projects.
14. ATS-friendly format.
15. Naming the file (Name_Role_Year.pdf).
16. Cover letter — when needed.
17. Naukri profile completeness checklist.
18. Cutshort / Instahyre presence.
19. Hirist visibility tweaks.
20. Recruiter outreach — first reply template.
21. "Currently CTC?" — defer / range answer.
22. "Expected CTC?" — anchor high.
23. "Notice period?" — flexibility wording.
24. "Why looking?" — positive framing.
25. Past comp disclosure — strategy.
26. Competing offer disclosure timing.
27. Offer acceptance window — buy time.
28. Counter on fixed only.
29. Counter on RSU vesting cliff.
30. Counter on joining bonus.
31. Counter on relocation.
32. Counter on signing bonus clawback.
33. Negotiating WFH / hybrid days.
34. Negotiating title.
35. Negotiating start date.
36. Asking for written offer.
37. Background check prep — past exits.
38. Reference selection.
39. Resignation script for current employer.
40. Counter-offer from current — handling.
41. Buyout request.
42. ESOP question to ask.
43. Vesting schedule clarification.
44. Cliff vs back-loaded vesting.
45. Tax implications of RSU in India.
46. Bonus structure clarity.
47. Variable pay — guaranteed vs target.
48. Performance band questions.
49. Manager / team interview — questions to ask them.
50. Final yes/no decision matrix.

---

## How to drill this bank

1. **Day 1–14**: 100 Qs/day, just speak each in ≤60s.
2. **Day 15–21**: re-do only `[ ]` unmarked Qs.
3. **Day 22+**: random sampling 30 Qs/day to keep fresh.
4. Track in a tracker sheet with columns: section, Q#, fluent (Y/N), last drilled date.

End of Appendix L.
