## 6. Hermes, Metro, bundle, startup

### Hermes
- AOT-compiled bytecode (vs JSC's interpreter + JIT).
- Faster startup, lower memory, smaller heap.
- Sampling profiler built in.
- Default since RN 0.70+.

### Metro
- RN's bundler (Webpack-equivalent).
- Resolves, transforms (Babel), and serves bundle to device.
- `inlineRequires: true` defers `require()` until first use → faster startup.
- RAM bundles (legacy) split bundle for lazy load.

### Cold start anatomy
```
native init → load JS bundle → parse → execute root → first render → first interaction
```
Each phase is measurable.

### Reduce cold start (the answer they want)
1. Enable Hermes.
2. `inlineRequires` + lazy import heavy screens.
3. Defer SDK init (Sentry, analytics, push) post first paint.
4. TurboModules (lazy native modules).
5. Smaller bundle (tree-shake, drop unused libs).
6. Hermes bundle (`hermesc`) prebuilt.
7. iOS: shrink launch storyboard work.
8. Android: enable R8/ProGuard, baseline profiles.

### App size levers
- Hermes (smaller than JSC).
- ProGuard/R8 (Android).
- Asset compression (WebP, AVIF, vector icons).
- Code splitting (rare in RN; use lazy screens).
- Strip unused locales.

### Must-answer questions
1. Why is Hermes faster?
2. Reduce 4s cold start to <2s — your plan.
3. What does `inlineRequires` do?
4. How do you measure cold start?
5. Top 3 levers to shrink IPA/APK.

---



---

## Top 25 Q&A — Hermes, Metro, bundle, startup

### 1. What is Hermes?
JS engine for RN by Meta. AOT-compiles JS → bytecode at build time. Optimized for low-memory devices.

### 2. Hermes vs JSC — key differences.
Hermes: faster startup, smaller memory, bytecode, no JIT (smaller TTI). JSC: better steady-state perf for heavy compute due to JIT.

### 3. Enable Hermes — where?
Android: `hermesEnabled=true` in `gradle.properties`. iOS: `:hermes_enabled => true` in Podfile. RN 0.70+ default true.

### 4. What is Metro?
RN's JS bundler — graph builds, transformations (Babel), serialization, dev server with HMR.

### 5. What is `metro.config.js` typically used for?
Custom resolvers, transformer (SVG, MDX), asset extensions, watch folders for monorepo, blockList.

### 6. How does Metro handle assets (images)?
`require('./img.png')` resolves at bundle time; metro generates 1x/2x/3x maps based on filename suffixes.

### 7. What's a source map and why care?
Maps minified bundle lines back to original TS for stack traces. Upload to Sentry/Crashlytics for symbolicated crashes.

### 8. How to measure startup time?
Android: `am start -W` for cold start. RN: `Performance.now()` from index → first screen mount. Tools: Hermes `--trace-bytecode`, Systrace, RN Performance Monitor.

### 9. Inline requires — what & why?
Babel plugin lazily evaluates modules at first use → reduces TTI by deferring code parse/eval.

### 10. RAM bundle — when?
Older approach for large apps; loads modules on demand. Mostly replaced by Hermes + inline requires.

### 11. Code splitting in RN — possible?
Limited. Approaches: separate JS bundles per route (`reload`-style), Re.Pack (webpack-based), Repack federation. Not common.

### 12. Tree-shaking in RN — does it work?
Yes for ESM via Metro/Hermes pipeline; CJS limits. Avoid `import * as` for big libs (`lodash` → `lodash/debounce`).

### 13. Bundle size analysis tools.
`react-native-bundle-visualizer`, `source-map-explorer`, Hermes `hbcdump`. Look for moment.js, large icon sets, dup React versions.

### 14. How to reduce bundle size — top wins.
Replace moment with date-fns / dayjs, lazy import heavy screens, tree-shake icons (use SVG-on-demand), remove dev-only code via `__DEV__` checks.

### 15. What is Hermes bytecode (HBC)?
Pre-compiled, version-pinned binary form of JS — faster startup, no parse cost at runtime. Cached on device.

### 16. Memory profiling Hermes app?
Hermes Sampling Profiler from Flipper/DevTools. Hermes heap snapshot (JSON) → analyze with Chrome DevTools.

### 17. What is App Startup composed of?
Process init → native init → JS engine init → bundle load + parse → JS run → first render commit → first frame.

### 18. Cold vs warm vs hot start?
Cold: process killed, full init. Warm: process alive but app backgrounded. Hot: JS context retained — instant.

### 19. Native splash screen pattern.
Show native splash (storyboard/drawable) until JS reports ready (`SplashScreen.hide()` from `react-native-bootsplash`/`expo-splash-screen`).

### 20. Why does first JS execution appear slow on Android?
Disk read of bundle, decompression, parse (JSC) or load HBC. Fixes: HBC + read-ahead, smaller bundle, defer non-critical modules.

### 21. Metro symlinks / monorepo issue?
Metro doesn't follow symlinks by default. Solutions: `nohoist`, `metro-config` `watchFolders` + `nodeModulesPaths`, or use pnpm + `extraNodeModules`.

### 22. Hermes and Proxy / `eval` support?
Proxy supported (since 0.70+). `eval` not supported (security + AOT). `Function('return ...')` also blocked.

### 23. How to enable React Compiler / Reanimated worklets?
Babel plugins in `babel.config.js`. `react-native-reanimated/plugin` MUST be last.

### 24. What is `enableProguardInReleaseBuilds`?
Android shrinker; reduces native + JS thin layers. With Hermes, set `enableHermes=true` and ensure ProGuard rules for any reflection.

### 25. Show a snippet for measuring TTI.
```js
import { InteractionManager } from 'react-native';
const t0 = Date.now();
InteractionManager.runAfterInteractions(() => {
  console.log('TTI ms:', Date.now() - t0);
});
```
