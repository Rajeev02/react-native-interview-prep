## 5. React Native architecture (old + new)

### What RN is
- Renders **real native UI** (UIView/ViewGroup), not WebView.
- JS runs in Hermes (default) or JSC, separate from main thread.
- Three threads (old arch): **JS thread** (your code), **UI/main thread** (touch + render), **Shadow thread** (Yoga layout).

### Old bridge
- Async, batched, JSON-serialized message passing JS↔native.
- Slow for high-frequency calls (gestures, animations).

### New Architecture (asked in 90% of senior loops)
- **JSI (JavaScript Interface)**: C++ layer letting JS hold references to native (host) objects, call methods synchronously without serialization. Foundation for everything below.
- **Fabric**: new renderer. Synchronous layout possible, concurrent React features, better priority scheduling. Replaces UIManager.
- **TurboModules**: lazy-loaded native modules accessed via JSI. Replaces NativeModule. Type-safe via Codegen.
- **Codegen**: TypeScript spec file → C++/ObjC/Java boilerplate generated at build time. Eliminates runtime type checks.

### Why it matters
- Cold start: TurboModules load on demand (not all at boot).
- Animations: Reanimated 3 worklets run on UI thread via JSI.
- Cross-boundary calls: synchronous when needed.

### Migration gotchas
- Some libraries still on old arch — check compatibility.
- iOS: `RCT_NEW_ARCH_ENABLED=1` in Podfile.
- Android: `newArchEnabled=true` in `gradle.properties`.

### Must-answer questions (the ones that show up)
1. Walk me through `npx react-native run-ios` → app on screen.
2. Old bridge vs JSI — explain to a junior in 90 sec.
3. What is Fabric? What does it improve?
4. TurboModule vs NativeModule.
5. What is Codegen and why does it matter?
6. How does Reanimated 3 use JSI?

---

