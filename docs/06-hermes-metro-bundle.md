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

