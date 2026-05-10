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

