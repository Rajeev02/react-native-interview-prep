## 9. Debugging toolkit

### Tools (know what each is for)
| Tool | Use |
|---|---|
| **React Native DevTools** (RN 0.76+) | New default debugger; console, sources, profiler |
| **Hermes Inspector** (Chrome DevTools) | Step debug Hermes, sampling profiler |
| **Flipper** (legacy) | Old default; mention migration to RN DevTools |
| **Reactotron** | State, network, action log inspection |
| **Xcode Instruments** | Time Profiler, Allocations, Leaks, Network, Energy |
| **Android Studio Profiler** | CPU, Memory, Network, Energy |
| **Perfetto / Systrace** | Native trace, ANR analysis (Android) |
| **LayoutInspector** (Android) / View Hierarchy (Xcode) | UI tree |
| **Charles Proxy / Proxyman / mitmproxy** | Network inspect, cert pinning bypass in dev |
| **adb logcat** | Android logs |
| **`xcrun simctl` / `idb`** | iOS sim control |
| **Sentry** | Crashes, breadcrumbs, sourcemaps, release health |
| **Crashlytics** | Crash stack traces |

### Crash symbolication
- **iOS**: dSYM file (Xcode build output) → `atos` or upload to Sentry → readable stack.
- **Android**: ProGuard/R8 mapping file → `retrace` or upload to Sentry/Crashlytics.
- **JS**: source maps uploaded to Sentry → original file:line:col.
- **Native crash via NDK**: `ndk-stack` with mapping.

### ANR (Android) debug
- Caused by main thread blocked >5s (or 10s for broadcast).
- Perfetto trace → find blocking call.
- Common: heavy work on main, network on main, lock contention, DB query on main.

### Network bug repro
1. Reproduce on device.
2. Charles/Proxyman → see actual request/response.
3. If pinned: dev build with pinning bypass.
4. Check headers, body, status, retry.
5. If only on prod: enable Sentry network breadcrumbs + add backend logs.

### Memory leak hunt (iOS)
1. Instruments → Allocations.
2. Mark generation, exercise feature, mark again.
3. Inspect persistent allocations between marks.
4. Leaks instrument for retain cycles.

### Memory leak hunt (Android)
1. Android Studio Profiler → Memory.
2. Force GC, take heap dump.
3. Look for unexpectedly retained activities/fragments.
4. LeakCanary in dev build.

### Must-answer questions (one rehearsed story per scenario)
1. Walk me through debugging a Sentry crash → root cause.
2. Slow on Android low-end devices — your plan.
3. Memory leak — tool + steps + fix.
4. Network bug only on prod — repro + debug.
5. ANR on Android — causes, tools, fix.

---



---

## Top 25 Q&A — Debugging toolkit

### 1. Default RN debugging tools.
React Native DevTools (since 0.76+), Flipper (legacy), Hermes Inspector via Chrome DevTools, Xcode/Android Studio, RN Perf Monitor.

### 2. How to open the in-app dev menu?
Shake device, `Cmd+D` (iOS sim), `Cmd+M` (Android emu), `adb shell input keyevent 82`.

### 3. Reload, debug remote JS, perf monitor — what each does?
Reload reloads bundle. Debug JS forwards to Chrome (only with JSC). Perf Monitor overlays JS/UI FPS and bridge calls.

### 4. Why is "Debug Remote JS" deprecated for Hermes?
Hermes has its own inspector (DevTools protocol). Remote debug ran JS in Chrome's V8 — different runtime, masked Hermes-only bugs.

### 5. Symbolicate native crashes — how?
Upload dSYM (iOS) and ProGuard mapping (Android) + JS source map to Sentry/Crashlytics. Otherwise: `npx react-native bundle --sourcemap-output` + `metro-symbolicate`.

### 6. Find why a screen re-renders.
React DevTools Profiler → record interaction → "Why did this render?" panel. Or `why-did-you-render` library in dev only.

### 7. Inspect network calls.
RN DevTools Network tab, Reactotron, or Flipper Network plugin. For raw native: Charles Proxy (set device trust + proxy).

### 8. Inspect Redux / Zustand state.
RN DevTools or Reactotron with redux/zustand integrations. `Zustand devtools` middleware logs to Redux DevTools.

### 9. Common crash: "Invariant Violation: Module ... is not a registered callable module".
Cause: native module missing or autolinking failed. Fix: `cd ios && pod install`, rebuild, check `react-native config`.

### 10. "Cannot read property X of undefined" in prod only.
Source map missing or property expected but absent. Add Zod validation at API boundary; ship source maps to crash reporter.

### 11. ANR on Android — how to investigate.
`adb shell am dumpheap`, `adb bugreport`, look at `/data/anr/traces.txt`. Common: sync work on UI thread, blocked main thread by JS-thread call.

### 12. Find UI thread blocks (iOS).
Xcode → Debug → View Debugging → Capture View Hierarchy. Instruments → Time Profiler → Main Thread track.

### 13. Memory leak in long sessions — workflow.
1) Repro: navigate A→B→A 50 times. 2) Heap snapshot before/after in Hermes Inspector. 3) Diff retainer paths. 4) Fix retained closures/subscriptions.

### 14. Use `LogBox` correctly.
`LogBox.ignoreLogs(['warning patterns'])` only as last resort. Prefer fixing root cause; never `ignoreAllLogs()`.

### 15. Lint + type errors as part of dev loop.
`tsc --noEmit` in CI, ESLint with `@react-native` config, husky + lint-staged on pre-commit.

### 16. Reactotron — what does it add over DevTools?
Custom commands, API timeline, async storage explorer, image overlay tool, benchmarks. Lightweight extra.

### 17. Inspect AsyncStorage / MMKV?
RN DevTools storage plugin, Flipper Async Storage plugin. MMKV: `mmkv` library has built-in inspector via Flipper plugin.

### 18. Debug deep links.
`adb shell am start -a android.intent.action.VIEW -d "myapp://path"`, iOS `xcrun simctl openurl booted "myapp://path"`. Add `Linking.addEventListener('url', ...)` log.

### 19. Network errors on Android emulator only.
Emulator localhost = `10.0.2.2`. Use `adb reverse tcp:3000 tcp:3000` for local servers. Cleartext traffic — set `usesCleartextTraffic` in `network_security_config.xml`.

### 20. Production debugging — how?
Sentry breadcrumbs, custom logs (`captureMessage`), feature flags to enable verbose log per user, remote-configurable kill switches.

### 21. Repro race conditions — strategy.
Slow JS via `Math.random` delays in dev, Chaos Monkey hooks, deterministic timers in tests, replay event sequences.

### 22. JS crash but app stays alive — pattern?
Wrap routes in error boundaries; `react-native-error-boundary` provides hooks. Report to Sentry, show fallback UI, allow user to retry.

### 23. Native crash but JS unaware — how surfaced?
Crashlytics/Sentry catch via signal handlers. JS sees app restart. Use `getCurrentlyRunningSession` cookie to detect crash on next launch.

### 24. Tooling for screenshot diff in PR?
Detox + jest-image-snapshot, or Chromatic for storybook. Storybook for RN gives component sandbox.

### 25. Quick checklist when "it works on iOS, breaks Android".
Permissions, Hermes flag parity, ProGuard rules, fonts manifest, image extensions, file paths case sensitivity, network security config.
