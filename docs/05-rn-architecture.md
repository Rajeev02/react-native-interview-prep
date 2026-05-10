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



---

## Top 25 Q&A — React Native architecture (old + new)

### 1. Old bridge — how does it work?
JS thread ↔ native (UI + module) threads communicate over an **async, batched, JSON-serialized** bridge. Every call is queued + serialized.

### 2. What's wrong with the bridge?
Async only (no sync calls), JSON serialization overhead, poor for high-frequency interactions (gestures, animations driven from JS).

### 3. What is JSI?
**JavaScript Interface** — a lightweight C++ API letting JS hold direct references to native (host) objects and call them synchronously. Replaces serialized bridge calls.

### 4. What is Fabric?
The new RN renderer. C++ core, runs on JSI, supports synchronous layout, view flattening, concurrent React.

### 5. What are TurboModules?
Lazy-loaded native modules that use JSI; type-safe via codegen from TS specs. Replace legacy NativeModules.

### 6. What is Codegen?
Generates C++/Java/ObjC bindings from your TS module/component spec at build time → safer + faster than reflective calls.

### 7. Hermes — what is it?
JS engine optimized for RN: ahead-of-time bytecode, low memory, faster startup. Default since RN 0.70.

### 8. New arch enabled — how do I check?
`newArchEnabled=true` in `gradle.properties` and `RCT_NEW_ARCH_ENABLED=1` env for iOS Pod install. At runtime, `global.RN$Bridgeless` is `true`.

### 9. View flattening — what & why?
Fabric collapses unnecessary view containers (ones with no visual props) into parents → fewer native views, faster layout.

### 10. Where does Yoga sit?
Cross-platform layout engine (flexbox). Runs on a background thread; outputs frames to native.

### 11. Threads in RN.
Main / UI thread, JS thread, layout (Yoga) thread, optional shadow / native module threads. Gestures + animations should avoid JS thread.

### 12. How does `useNativeDriver` help?
Animations driven on the UI thread without crossing the bridge each frame. Limits: only transform + opacity (no layout props).

### 13. Reanimated 2/3 — what's different?
Worklets — JS subset compiled to run on the UI thread via JSI. Enables shared values, gestures (with Gesture Handler), 60+ fps animations driven natively.

### 14. Why does brownfield (native + RN) need careful arch?
Lifecycle conflicts (RN root view inside native VC), separate navigation stacks, shared auth state, bundle loading strategy (single vs multiple roots).

### 15. Bridgeless mode?
RN 0.74+ — fully removes the bridge; JS runtime runs entirely on JSI. Fewer modes, smaller startup.

### 16. Code example: minimal TurboModule spec.
```ts
// NativeBiometric.ts
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
export interface Spec extends TurboModule {
  authenticate(reason: string): Promise<boolean>;
}
export default TurboModuleRegistry.getEnforcing<Spec>('Biometric');
```

### 17. How does the new arch handle event dispatch?
Events flow from native → JSI → React state synchronously where possible (e.g., `onScroll` can update Reanimated values without JS thread).

### 18. Migration path: old → new arch.
(1) Upgrade to latest stable RN. (2) Enable Hermes. (3) Migrate libs to JSI/Fabric-compatible. (4) Enable new arch flag in dev. (5) Per-screen rollout, fix issues, then full enable.

### 19. What happens if a library isn't Fabric-ready?
Interop layer wraps legacy components — works but loses optimizations. Check compatibility table for major libs (RN Screens, Reanimated, Gesture Handler, Skia).

### 20. How is the JS bundle delivered?
Dev: Metro server. Prod: bundled at build time, optionally split into multiple bundles (RAM bundle / inline requires).

### 21. RAM bundle vs single bundle?
RAM bundle = modules loaded on demand. Reduces startup time. Largely superseded by Hermes bytecode + inline requires.

### 22. Inline requires — what?
Babel transform converting top-level `require` into lazy calls executed when first used. Cuts startup work.

### 23. What is Skia in RN context?
2D graphics library wrapped by `@shopify/react-native-skia` for high-perf custom drawing on UI thread (charts, masks, shaders).

### 24. Memory model differences old vs new arch?
New arch shares immutable shadow trees across threads, less copying. Hermes uses generational GC tuned for short-lived objects.

### 25. Why might Fabric *worsen* perf in some apps?
Many incompatible legacy native modules forced through interop layer; large brownfield apps with custom render pipelines; missing Fabric versions of core libs. Profile before migrating.
