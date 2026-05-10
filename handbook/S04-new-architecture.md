# S4 — React Native New Architecture

> Bridgeless · JSI · TurboModules · Fabric · Yoga · Codegen · Interop Layer · Runtime Scheduler

In 2026, the New Architecture is the **default**. Every senior/staff RN interview probes it. This section teaches it from intuition → internals → migration.

## Topics in this section

- [Q1. Legacy Bridge — what it was and why it had to die](#q1-legacy-bridge--what-it-was-and-why-it-had-to-die)
- [Q2. JSI — the new contract between JS and native](#q2-jsi--the-new-contract-between-js-and-native)
- [Q3. TurboModules & Codegen](#q3-turbomodules--codegen)
- [Q4. Fabric renderer & the shadow tree](#q4-fabric-renderer--the-shadow-tree)
- [Q5. Bridgeless Mode & the Runtime Scheduler](#q5-bridgeless-mode--the-runtime-scheduler)
- [Q6. New Architecture Interop Layer & migration](#q6-new-architecture-interop-layer--migration)

---

## Q1. Legacy Bridge — what it was and why it had to die

### Difficulty
Intermediate (mandatory background for every senior RN interview)

### Interview Frequency
Very Common — almost always the lead-in to JSI/Fabric questions.

### Prerequisites
- JS event loop, async messaging
- Basic threading (main thread vs background)

### TL;DR
The Bridge was an **async, batched, JSON-serialized message bus** between JS and native; it was the bottleneck that made deep integrations (sync calls, layout, gestures) painful — JSI replaces it.

### 30-Second Interview Answer
"In the legacy architecture, JS and native communicated via the Bridge: every call was serialized to JSON, queued, and processed asynchronously across threads. That made all native calls async, blocked synchronous APIs (like measuring a view), and serialized large payloads on every frame. The New Architecture removes this with JSI, which lets JS hold direct C++ references to native objects and call them synchronously when needed."

### 2-Minute Practical Answer
The Bridge had three properties that defined RN's pain points:

1. **Asynchronous** — every call (`NativeModules.Foo.bar()`) returned `void` and got a callback later. You could never `read` a value synchronously.
2. **Batched** — calls were queued and flushed in batches (~5ms). Latency for small interactions was variable.
3. **Serialized** — arguments were JSON-encoded on the JS side, decoded on native. Large objects (images, big lists, layout trees) blew up on the bridge.

This is why old RN apps had:
- janky animations driven from JS (every frame went over the bridge)
- `Animated` needing `useNativeDriver` hacks
- expensive list re-renders (every cell over the bridge)
- no synchronous measurement APIs
- separate "shadow thread" doing layout async

The fix is the New Architecture: **JSI** removes serialization, **Fabric** removes the async layout pipeline, **TurboModules** make native calls lazy + typed, and **Bridgeless mode** removes the Bridge entirely.

### 5-Minute Architecture Answer
Picture three threads in old RN:

```
[ JS thread ]  --serialize JSON-->  [ Native modules thread ]  --post-->  [ UI / main thread ]
                                              |
                                              v
                                       [ Shadow / layout thread ]
```

The Bridge sat between JS and native modules. Every call across it had four costs:

1. **JS → JSON serialization** (CPU + GC pressure on JS)
2. **Bridge transport** (queueing, batching latency)
3. **JSON → native deserialization** (CPU on native)
4. **Threading hop** (post to UI thread for view updates)

For UI updates the path was even longer: JS produced a virtual tree → diffed → instructions serialized to native → shadow thread re-laid-out with Yoga → committed to UI thread. End-to-end latency easily missed a 16ms frame budget on slower devices.

Why couldn't this just be optimized? Because the **contract itself** was async + serialized. You couldn't add a synchronous `View.measure()` without breaking the model. You couldn't share a typed array without copying. You couldn't drive a 120Hz gesture from JS without dropping frames.

The New Architecture re-designs the contract:
- **JSI** — JS engine exposes a C++ API; native code installs `HostObject`s that JS can call synchronously, with no serialization.
- **TurboModules** — native modules are typed (Codegen) and lazily instantiated.
- **Fabric** — renderer runs on the **same thread** model but uses a synchronous, concurrent commit mechanism (compatible with React 18/19 concurrent features).
- **Bridgeless** — the Bridge object literally doesn't exist anymore; module access goes through the TurboModule registry on the JS runtime.

### The "Why"
The Bridge existed because, in 2015, embedding a JS engine and exposing C++ pointers to it across iOS/Android was hard. Async JSON was the **portable** path. By 2020, JSI made it possible to do it properly. The Bridge had to go because:
- mobile users expect 120Hz, sub-100ms interactions
- gestures, animations, lists need deterministic synchronous calls
- React 18/19 concurrent rendering needs cooperative scheduling, which an async bridge can't provide

### Mental Model
The Bridge was like sending letters across a river. Every message had to be put in an envelope (serialize), thrown into a boat (batch), and opened on the other side (deserialize). JSI is a **bridge you can walk across** — JS holds a direct handle to the native object.

### Internal Working (2026 Context)
Even though "Bridge" is gone, you'll still see the term in:
- `react-native` source (the `BatchedBridge` shim still exists for legacy modules under the Interop Layer)
- error stacks ("RCTBridge required dispatch_sync to load")
- profiling traces during migration

In Bridgeless mode (default), the JS runtime is initialized with a **TurboModuleManager** instead of a Bridge. Calls to `NativeModules.Foo` are intercepted by a Proxy that resolves to a TurboModule via JSI.

### Modern Implementation (Code)
You don't write Bridge code anymore. The interview value is **recognizing legacy patterns**:

```ts
// [DEPRECATED] Bridge-era pattern — async, untyped, no codegen
import { NativeModules } from 'react-native';
const { LegacyCrypto } = NativeModules;

// returns Promise — was always async on the Bridge
LegacyCrypto.hash('hello').then((h: string) => console.log(h));
```

```ts
// [2026] TurboModule pattern — typed, lazy, JSI-backed
// 1. Spec file consumed by Codegen
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // synchronous! no Promise needed for cheap calls
  hashSync(input: string): string;
  hashAsync(input: string): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCrypto');
```

### Comparison

| Aspect              | Legacy Bridge                | JSI / New Arch              |
| ------------------- | ---------------------------- | --------------------------- |
| Sync calls          | ❌ never                     | ✅ yes (when safe)          |
| Serialization       | JSON, every call             | None — direct C++ refs      |
| Threading           | JS → native modules thread   | Direct from JS runtime      |
| Type safety         | Runtime, manual              | Codegen (compile time)      |
| Module init         | Eager, all on startup        | Lazy on first access        |
| Concurrent React    | ❌ incompatible              | ✅ supports React 19        |
| Gesture/animation   | Needs `useNativeDriver` hack | Native via Reanimated worklets on JSI |

### Production Usage
- Legacy apps still on the Bridge see startup regressions because **all native modules initialize eagerly**. Migration to TurboModules typically saves 200–800ms cold start on mid-tier Android.
- Apps with custom native modules (camera, payments, BLE) cannot stay on the Bridge in 2026 — most popular libs (Reanimated 3, VisionCamera 4, MMKV, op-sqlite) **require** JSI.

### Hands-On Exercise
1. Open an old app pinned to RN ≤0.67. Run `react-native log-ios` and grep for `BatchedBridge` traces.
2. Add a tiny native module via Bridge (`RCTBridgeModule`) returning a value asynchronously.
3. Re-implement the same module as a TurboModule (Spec + Codegen). Measure first-call latency — typically 10–50× faster on a sync path.

### Common Mistakes
- Saying "the Bridge is just slow" — it's not slow per call, it's **serialized + async**, which prevents whole categories of UX.
- Confusing the Bridge with the Metro bundler (different layer entirely).
- Believing turning on the New Arch automatically makes things faster — it removes a ceiling, but you still need Reanimated/FlashList/MMKV to feel the win.

### Production Red Flags
- Candidate says: "we just upgraded RN and got 2× faster" — without being able to attribute gains to specific arch changes.
- Candidate doesn't know that **JSON serialization** was the core bottleneck.
- Candidate confuses **threads** (JS, UI, shadow) with the Bridge itself.

### Performance & Metrics
- **Cold start:** Bridge init typically 150–400ms on mid-tier Android; eliminated in Bridgeless.
- **Per-call latency:** Bridge ~0.5–2ms + serialization cost; JSI sync call ~10–50µs.
- **Memory:** Bridge held a dispatch queue + JSON buffers; Bridgeless removes ~3–5MB resident.
- **Frame budget:** at 120Hz you have 8.3ms — Bridge round-trips often consumed 2–4ms each.

### Metrics That Matter
TTI, JS→native call P95 latency, cold start, crash-free sessions during migration.

### Decision Framework
- Greenfield in 2026 → New Arch only.
- Brownfield with many old native modules → New Arch + **Interop Layer** (Q6) + module-by-module migration.
- Library author → ship both Bridge and TurboModule until you can drop RN ≤0.73.

### Senior-Level Insight
The Bridge wasn't a bug — it was a **portability tradeoff** in 2015. The lesson: when you control the runtime, async-everything looks safe; when users expect 120Hz, the abstraction cost shows. New Arch is RN admitting that the boundary between "JS world" and "native world" must be thinner than a JSON boundary.

### Real-World Scenario
**Symptom:** A fintech app's transaction list scrolls smoothly on iPhone 15 but stutters on a Pixel 4a.
**Investigation:** Systrace shows JS thread idle, but UI thread stalls 30ms every ~200ms. Bridge inspector shows large `RCTViewManager.updateView` batches.
**Root cause:** Each cell pushes ~12 props through the Bridge per frame; JSON serialization on Pixel 4a takes 4ms.
**Fix:** Migrate the list to FlashList + enable New Arch + Reanimated 3 worklets for the swipe gesture. Stutter disappears.
**Lesson:** Bridge cost is **per-byte and per-call** — list virtualization without arch changes only treats symptoms.

### Production Failure Story
**Incident:** A super-app shipped a "fast scroll" feature using `Animated` driven from JS. P95 frame drop went from 0.4% to 6%, ANR rate spiked, Play Store rating dropped 0.3 in a week.
**Investigation:** Frame timeline showed JS→Bridge→UI round-trips every 16ms.
**Root cause:** Bridge serialization on every animation tick.
**Fix:** Rewrote with Reanimated worklets running on the UI thread via JSI. Frame drop returned to 0.5%.
**Prevention:** Lint rule banning `Animated.event` without `useNativeDriver: true`; mandatory perf review for any JS-driven animation.

### Debugging Checklist
1. `console.log(global.RN$Bridgeless)` — confirms mode.
2. Hermes profiler → look for `MessageQueue.flushedQueue` (Bridge era) vs `TurboModuleBinding.install` (new).
3. Systrace / Perfetto → check JS thread vs UI thread overlap.
4. iOS Instruments → "Time Profiler" + "System Trace" for cross-thread hops.
5. If you see `RCTBridge` in stacks under New Arch, you're hitting the **Interop Layer** for an unmigrated module.

### Advanced / Internal Knowledge
- The Bridge was implemented as `MessageQueue.js` + native `RCTBatchedBridge` (iOS) / `CatalystInstance` (Android).
- It used a **module config table** generated at app start, listing every native method ID. This is what made startup expensive.
- TurboModuleManager replaces this with a lazy registry; modules are looked up by name and instantiated on first JS access.

### 2026 AI Tip
Use Copilot/Claude to **audit** legacy modules: paste the `RCTBridgeModule` and ask for the equivalent Spec file + Codegen config. Verify the result against the official Codegen output — AI often forgets `RCT_EXTERN_REMAP_MODULE` quirks and Promise return-type mappings.

### Related Topics
Q2 (JSI), Q3 (TurboModules), Q5 (Bridgeless), Q6 (Interop), S6 (Hermes), S7 (Performance).

### Interview Follow-Up Questions
- "Why couldn't the Bridge be optimized to be synchronous?"
- "What forced the move — React 18 concurrent features or perf?"
- "How do you migrate a brownfield app one module at a time?"
- "What does Bridgeless mode change for native developers?"

### Memory Hook
**"The Bridge spoke JSON across a river — JSI walks across it."**

### Revision Notes
> Bridge = async + JSON + batched message bus; JSI = direct C++ refs, sync calls; New Arch removes the ceiling, doesn't auto-make code fast.

---

## Q2. JSI — the new contract between JS and native

### Difficulty
Advanced

### Interview Frequency
Very Common at Senior+; Architect-level depth expected at FAANG/super-apps.

### Prerequisites
- Q1 (Bridge), basic C++ pointer/reference intuition, Hermes runtime model.

### TL;DR
JSI (JavaScript Interface) is a **C++ abstraction over the JS engine** that lets native code install objects and functions directly into the JS runtime — so JS calls native synchronously without serialization.

### 30-Second Interview Answer
"JSI is a C++ header-only API that abstracts a JS engine like Hermes or JSC. Native code can create `HostObject`s and `HostFunction`s that JS sees as ordinary objects but that execute native code synchronously. There's no serialization — arguments are jsi::Value references. This is what makes Reanimated worklets, MMKV's sync get, and TurboModules possible."

### 2-Minute Practical Answer
JSI exposes three core types you'll see everywhere:

- **`jsi::Runtime`** — represents the JS engine. Hermes and JSC both implement it.
- **`jsi::Value`** — a tagged union representing any JS value (string, number, object, function).
- **`jsi::HostObject`** — a native C++ object exposed to JS. JS sees it as an object with custom getters/setters/methods.

Library authors write something like:

```cpp
class MyHostObject : public jsi::HostObject {
  jsi::Value get(jsi::Runtime& rt, const jsi::PropNameID& name) override {
    if (name.utf8(rt) == "ping") {
      return jsi::String::createFromUtf8(rt, "pong");
    }
    return jsi::Value::undefined();
  }
};

// Install once on app start
runtime.global().setProperty(runtime, "myThing",
  jsi::Object::createFromHostObject(runtime, std::make_shared<MyHostObject>()));
```

Now JS does `global.myThing.ping` and gets `"pong"` synchronously, no Bridge.

This is the foundation of:
- **Reanimated** (worklets call shared values via JSI)
- **MMKV** (sync `getString` reads from MMKV's mmap'd buffer)
- **VisionCamera** (frame processors execute on the camera thread via JSI)
- **TurboModules** (the registry is a HostObject)

### 5-Minute Architecture Answer
JSI's design constraints:

1. **Engine-agnostic.** Same C++ interface works for Hermes, JSC, V8 (RN macOS/Windows), Static Hermes.
2. **Header-only.** No ABI dance — libraries link statically against the running engine's JSI implementation.
3. **Thread-affinity.** A `jsi::Runtime` is **not thread-safe**. Calls into it must happen on the thread that owns it. Multi-threaded code uses a `CallInvoker` to schedule work back on the JS thread.
4. **Lifetime.** `jsi::Value` is tied to the runtime; you can't store it across runtime restarts. For long-lived references you use `jsi::WeakObject` or move ownership into a `HostObject`.

The synchronous power is also the danger. A slow JSI call **blocks the JS thread**. The engineering rule:
- Do **fast** work on the JS thread (counter increments, hashtable lookups, mmap reads).
- Do **slow** work on a worker thread and post results back via `CallInvoker->invokeAsync`.

### The "Why"
Because:
- Synchronous APIs unlock UX patterns the Bridge couldn't support (gesture responders that consult layout mid-frame, sync KV reads on cold start, deterministic measurement).
- React 18/19 concurrent rendering wants to call native synchronously to commit Fabric state.
- Avoiding JSON serialization saves CPU and GC.

### Mental Model
Think of JSI as **FFI for React Native**, like Python's CFFI or Kotlin Native interop. JS objects can hold C++ pointers under the hood, and method calls become C++ vtable dispatches.

### Internal Working (2026 Context)
- Hermes is built with JSI; the Hermes runtime **is** a `jsi::Runtime`.
- Bridgeless mode uses JSI to install the **TurboModuleManager** as a HostObject named `__turboModuleProxy`. Every `TurboModuleRegistry.get('Foo')` is a JSI lookup that lazily instantiates the C++ module.
- Fabric's UIManager is also JSI-installed; commits flow through `RuntimeScheduler` and JSI calls on the JS thread.
- React Compiler does not affect JSI directly, but reduces the rate of re-renders that trigger Fabric commits → fewer JSI crossings.

### Modern Implementation (Code)
You rarely write JSI directly. You write a **Spec** and let Codegen produce the C++:

```ts
// MyModuleSpec.ts — consumed by Codegen
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  readonly getConstants: () => { version: string };
  measureSync(text: string, fontSize: number): { width: number; height: number };
  warmCacheAsync(keys: string[]): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('TextMetrics');
```

Codegen emits the C++ glue. You implement `measureSync` and `warmCacheAsync` in Objective-C++/Kotlin/JNI; the framework wires them into JSI for you.

### Comparison

| Aspect          | Bridge                  | JSI                              |
| --------------- | ----------------------- | -------------------------------- |
| Call cost       | ms (serialize + queue)  | µs (vtable call)                 |
| Sync calls      | No                      | Yes                              |
| Threading       | Cross-thread by design  | Single-thread per runtime        |
| Type system     | Untyped JSON            | C++ types via Codegen            |
| Used by         | Legacy modules          | Reanimated, MMKV, TurboModules   |

### Production Usage
- Reanimated 3 installs a **second `jsi::Runtime`** (the UI runtime) on the UI thread; worklets are serialized once and re-executed there at 120Hz.
- MMKV's `getString` is a JSI HostFunction reading from an mmap'd buffer — no Bridge, no Promise.

### Hands-On Exercise
1. Write a TurboModule Spec for a `NativeMath.fib(n: number): number`.
2. Implement `fib` in C++ and expose via JSI.
3. Benchmark vs a JS implementation. For small `n` JSI loses to Hermes; for `n > 35` C++ wins.
4. Move `fib` off the JS thread using a `CallInvoker`. Observe JS thread idle time recover.

### Common Mistakes
- Calling JSI from the wrong thread → undefined behavior, often a silent crash.
- Holding `jsi::Value` across runtime restarts (e.g. fast refresh) → use-after-free.
- Doing heavy work in a sync HostFunction and blocking the JS thread.

### Production Red Flags
- "JSI = fast, always use sync" — wrong, sync amplifies blocking risk.
- Candidate doesn't mention thread-affinity.
- Candidate confuses JSI with TurboModules (JSI is the mechanism; TM is the pattern built on it).

### Performance & Metrics
- JSI call: ~10–50µs per crossing on modern devices.
- A sync JSI call holding the JS thread for >2ms degrades animations driven from JS.
- Reanimated worklets effectively make the UI thread pay zero JSI crossings during gestures.

### Metrics That Matter
JS thread idle %, frame drop rate, gesture latency P95.

### Decision Framework
- Build a TurboModule when: you need typed sync APIs, replacing a legacy native module, or shipping a JSI-only library.
- Build a Fabric Component when: you need native views (camera preview, map).
- Don't reach for raw JSI unless you're a library author or the framework doesn't yet expose what you need.

### Senior-Level Insight
JSI shifts the failure mode. Bridge bugs were **latency** bugs; JSI bugs are **memory and threading** bugs (use-after-free, race conditions, JS thread starvation). Production rigor moves toward C++ tooling: ASan, TSan, Hermes' debug runtime.

### Real-World Scenario
**Symptom:** App freezes for 300ms on first screen.
**Investigation:** Hermes profiler shows a single `MMKVHostObject.getString` call taking 280ms.
**Root cause:** First read on a 50MB MMKV file triggers full mmap + crc check on JS thread.
**Fix:** Warm the file via a background `CallInvoker` task during splash; expose a `prewarm()` async API.
**Lesson:** Sync JSI is a double-edged sword — guard cold paths.

### Production Failure Story
**Incident:** App random crashes only on Android 14, only after fast refresh in dev.
**Investigation:** Native stack: `jsi::Object::getProperty` on freed runtime.
**Root cause:** A library held a captured `jsi::Runtime&` in a closure that ran after fast refresh tore down the runtime.
**Fix:** Switch to `std::weak_ptr<jsi::Runtime>` checked before each call; library bumped major version.
**Prevention:** Internal lint for raw `jsi::Runtime&` captures in lambdas crossing thread boundaries.

### Debugging Checklist
1. Is the call on the JS thread? `assert(runtime.global().isObject(...))` from the wrong thread crashes.
2. Use Hermes' `HermesRuntime::debugger()` to step through HostFunction entries.
3. ASan / Xcode "Address Sanitizer" build when chasing crashes inside HostObjects.
4. `__DEV__` guards around `jsi::Value::asObject()` (it throws on type mismatch).

### Advanced / Internal Knowledge
- JSI is implemented in `ReactCommon/jsi/jsi.h`. The Hermes implementation lives in `hermes/API/`.
- `jsi::HostFunction` is `std::function<jsi::Value(jsi::Runtime&, const jsi::Value&, const jsi::Value*, size_t)>`.
- Static Hermes can specialize calls into HostFunctions when types are known at AOT time, eliminating dispatch cost.

### 2026 AI Tip
AI is great at generating Spec files but **bad at JSI lifetime correctness**. Always hand-review captures, thread hops, and `runtime` references. Ask AI to "list every place this code touches `jsi::Runtime`" and verify thread-affinity manually.

### Related Topics
Q1 (Bridge), Q3 (TurboModules), Q4 (Fabric), S6 (Hermes), S7 worklets.

### Interview Follow-Up Questions
- "How does Reanimated use a second runtime?"
- "What's the difference between `HostObject` and `HostFunction`?"
- "How would you call native code from JS off the JS thread?"
- "Why is JSI not thread-safe?"

### Memory Hook
**"JSI = JavaScript holds a C++ remote control. One thread, no JSON, sync power, sync danger."**

### Revision Notes
> JSI = C++ API over the JS engine; HostObjects/HostFunctions enable sync, zero-copy native calls; thread-affine; foundation of TurboModules, Reanimated, MMKV.

---

## Q3. TurboModules & Codegen

### Difficulty
Advanced

### Interview Frequency
Very Common — every native module question in 2026 lands here.

### Prerequisites
Q2 (JSI), basic Codegen / build pipeline familiarity.

### TL;DR
TurboModules are **typed, lazily-loaded native modules** built on JSI; **Codegen** reads TS Specs and emits the C++/Obj-C++/Kotlin glue so calls are type-safe and zero-serialization.

### 30-Second Interview Answer
"TurboModules replace legacy native modules. You declare the API in a TypeScript Spec, run Codegen at build time which produces C++ JSI bindings plus iOS/Android scaffolding. Modules are instantiated lazily on first JS access, calls go through JSI synchronously, and the type contract is enforced at compile time on both sides."

### 2-Minute Practical Answer
A TurboModule has three pieces:

1. **Spec** (`NativeFoo.ts`) — TypeScript interface extending `TurboModule`.
2. **Codegen output** — generated headers (`NativeFooSpec.h`) and Java interfaces (`NativeFooSpec.java`).
3. **Implementation** — Obj-C++ class conforming to the spec, Kotlin class extending the generated abstract.

Lazy loading means: the module isn't instantiated until `TurboModuleRegistry.getEnforcing('Foo')` is called. This dramatically improves cold start in apps with many native modules.

### 5-Minute Architecture Answer
The Codegen pipeline:

```
NativeFoo.ts (Spec)
       │
   react-native codegen
       │
   ┌───┴───────────────────────────┐
   │                               │
NativeFooSpec.h (C++)        NativeFooSpec.java
JsiNativeFooHostObject       NativeFooSpec (abstract)
   │                               │
your Obj-C++/Swift impl     your Kotlin impl
   │                               │
   └────────── JSI ────────────────┘
                    ▲
                    │
               JS runtime
```

At runtime, `TurboModuleRegistry.getEnforcing<Spec>('Foo')` triggers a lookup in the `__turboModuleProxy` HostObject installed by Bridgeless. The proxy:
1. Checks an internal cache.
2. If miss, asks the platform `TurboModuleManager` to instantiate `Foo`.
3. The native instance wraps itself in a JSI HostObject and returns it to JS.

After this, every JS call becomes a JSI HostFunction invocation — no Bridge, no JSON.

### The "Why"
- **Type safety:** the same Spec drives both sides; you can't drift.
- **Lazy init:** apps with 60+ native modules saved hundreds of ms on cold start.
- **Zero serialization:** sync calls return primitives directly.
- **Consistent codegen:** library authors stop hand-writing Obj-C++ glue.

### Mental Model
Codegen is **gRPC for native modules**: write the schema once, get typed clients on both ends.

### Internal Working (2026 Context)
- Codegen runs during `pod install` (iOS) and the Gradle `generateCodegenArtifactsFromSchema` task (Android).
- The schema is a JSON intermediate parsed from your TS Spec.
- Bridgeless mode requires every accessed native module to be a TurboModule **or** registered via the Interop Layer (Q6).

### Modern Implementation (Code)

```ts
// specs/NativeAnalytics.ts
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

type EventPayload = Readonly<{
  name: string;
  ts: number;
  props?: Readonly<Record<string, string | number | boolean>>;
}>;

export interface Spec extends TurboModule {
  readonly getConstants: () => { sdkVersion: string };
  trackSync(event: EventPayload): void;        // fire-and-forget, sync queue write
  flush(): Promise<number>;                    // returns count flushed
  setUser(id: string | null): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Analytics');
```

`package.json`:
```json
{
  "codegenConfig": {
    "name": "RNAnalyticsSpec",
    "type": "modules",
    "jsSrcsDir": "./specs"
  }
}
```

iOS implementation outline (Obj-C++):
```objc
#import "RNAnalyticsSpec.h"

@interface Analytics : NSObject <NativeAnalyticsSpec>
@end

@implementation Analytics
RCT_EXPORT_MODULE()

- (void)trackSync:(JS::NativeAnalytics::EventPayload &)event {
  // append to a lock-free ring buffer; flush from a background thread
}
- (void)setUser:(NSString *)id { /* … */ }
- (NSDictionary *)getConstants { return @{@"sdkVersion": @"3.1.0"}; }

- (std::shared_ptr<facebook::react::TurboModule>)
   getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeAnalyticsSpecJSI>(params);
}
@end
```

### Comparison

| Aspect             | Legacy Native Module       | TurboModule                  |
| ------------------ | -------------------------- | ---------------------------- |
| Type contract      | Manual, drift-prone        | Codegen from TS              |
| Init               | Eager on app start         | Lazy on first JS access      |
| Sync calls         | No                         | Yes                          |
| Serialization      | JSON every call            | None                         |
| Bridgeless support | Only via Interop Layer     | Native                       |

### Production Usage
- **Cold start wins:** real apps report 100–500ms savings from lazy module init alone.
- **Type drift fixes:** Codegen catches TS↔native mismatches at build time, not in production crashes.

### Hands-On Exercise
1. Take a legacy module exporting `getDeviceInfo(): Promise<object>`. Convert to a TurboModule with a strict Spec returning a typed struct.
2. Make a sync variant `getDeviceInfoSync()`. Measure cold-start TTI before/after.
3. Add a Codegen-driven enum and prove the Java/Obj-C side won't compile if the TS enum changes.

### Common Mistakes
- Returning `any` in the Spec — Codegen falls back to untyped, defeating the purpose.
- Forgetting to add the module to `RCTAppDelegate`'s autolink list (iOS) or the Application's package list (Android).
- Mixing sync and async methods carelessly — sync methods on slow paths cause ANRs.

### Production Red Flags
- Specs with `Object` / `any` return types.
- Hand-edited Codegen output (it's regenerated each build).
- Native module doing IO on the JS thread inside a sync method.

### Performance & Metrics
- Lazy init: cold start −100 to −500ms for module-heavy apps.
- Sync call: ~10–30µs vs Bridge ~0.5–2ms.
- Memory: small win from not instantiating unused modules.

### Metrics That Matter
TTI, JS thread idle %, ANR rate, native module first-call latency.

### Decision Framework
- Always TurboModule for new code in 2026.
- Brownfield: migrate hot/popular modules first; let cold ones ride the Interop Layer.
- Sync API only when guaranteed fast (<1ms) and main-thread-safe.

### Senior-Level Insight
Codegen pushes the **API design** decision into TS, which means your team's Spec reviews become the most important contract review you do. Treat Spec changes like protobuf changes: backward-compat, deprecation cycles, and version notes.

### Real-World Scenario
**Symptom:** Crash on Android only, only on first launch after install.
**Investigation:** `NoSuchMethodError` for a Spec method that exists in TS.
**Root cause:** Codegen wasn't run because the developer added the Spec but didn't bump `codegenConfig.name`; cached schema was stale.
**Fix:** Clean Gradle cache + rerun Codegen. Add CI check that fails if generated headers are stale vs Spec.
**Lesson:** Treat Codegen output like a build artifact — verify it in CI.

### Production Failure Story
**Incident:** App stops launching for 3% of users after a release.
**Investigation:** Sentry shows `TurboModuleRegistry.getEnforcing('Auth')` throwing.
**Root cause:** Conditional native dependency excluded `Auth` on a build flavor; lazy access blew up only when hit.
**Fix:** Replace `getEnforcing` with `get` (returns null) in the calling code path; add `if (!Auth) fallbackPath()`.
**Prevention:** Lint rule to prefer `get + null check` for optional modules.

### Debugging Checklist
1. Verify Codegen ran: check `build/generated/source/codegen/` (Android) and Pod build phase (iOS).
2. `console.log(Object.keys(global.__turboModuleProxy))` — sanity check registry.
3. Native crash with missing symbol → autolinking issue.
4. JS error "TurboModuleRegistry.getEnforcing(...) module not found" → not registered or build cache stale.

### Advanced / Internal Knowledge
- `getEnforcing` throws; `get` returns null. Use the latter for optional modules.
- TurboModules can return **C++ structs** via Codegen; this avoids per-call object allocation in JS.
- TurboModule instances are cached per `jsi::Runtime` — fast refresh re-instantiates them.

### 2026 AI Tip
Use AI to generate the Spec from existing legacy native code, then **manually verify return-type narrowing** (legacy often returned `Object` / `Promise<any>`; tightening these is the whole point).

### Related Topics
Q2 (JSI), Q4 (Fabric Components are the view-side analog), S6 (build pipeline), S15 (native bridging patterns).

### Interview Follow-Up Questions
- "What does `getEnforcing` do that `get` doesn't?"
- "How does Codegen handle nullable fields?"
- "How do you support both Bridge and TurboModule from one library?"
- "What goes wrong when Spec and impl drift?"

### Memory Hook
**"Spec → Codegen → JSI. Type once, call anywhere, lazy by default."**

### Revision Notes
> TurboModule = typed, lazy, JSI-backed native module; Codegen builds the bridge between TS Spec and native impl; sync calls are powerful but need <1ms guarantees.

---

## Q4. Fabric renderer & the shadow tree

### Difficulty
Advanced → Architect

### Interview Frequency
Very Common at Senior+; Architect probes commit phases and concurrent rendering.

### Prerequisites
Q2 (JSI), React Fiber basics, Yoga layout intuition.

### TL;DR
Fabric is RN's new renderer: React commits a **shadow tree** (immutable C++ nodes) synchronously through JSI; layout runs in Yoga; mounts apply to native views in one atomic transaction — making concurrent rendering and synchronous measurement possible.

### 30-Second Interview Answer
"Fabric replaces the old UIManager. React produces a shadow tree of immutable C++ nodes via JSI. Yoga lays them out synchronously. Then mount instructions are batched and applied to native views atomically on the UI thread. Because the tree is immutable, React can build alternate trees concurrently for transitions and Suspense without tearing the UI."

### 2-Minute Practical Answer
Three phases:

1. **Render** — React (JS thread) calls Fabric's UIManager via JSI to create / clone shadow nodes.
2. **Commit** — when React commits, Fabric atomically swaps the **shadow tree root**. Yoga calculates layout on the same thread.
3. **Mount** — diff between previous and new tree produces mount instructions, posted to the UI thread, applied in one transaction.

Why "shadow tree"? Because nodes are **immutable**. Updating a prop creates a new node + reuses children. This is what enables:
- React 19 concurrent rendering (alternate trees in flight)
- synchronous measurement (`measureSync` reads from the committed tree)
- Suspense boundaries that don't flash

### 5-Minute Architecture Answer
Old architecture mounted views by sending `createView`/`updateView` instructions across the Bridge to the UIManager on the native side, with layout computed on a separate "shadow thread." Issues:
- async commit → tearing under concurrent React
- JSON serialization
- no sync measurement

Fabric fixes this by:
- moving the **shadow node tree** into C++, accessed via JSI
- doing layout (Yoga) **on the JS thread** during commit
- separating commit (deciding the new tree) from mount (applying it on UI thread)

The mounting layer is platform-specific:
- iOS: `RCTMountingManager` translates mount instructions to UIView ops
- Android: `MountingManager` + `SurfaceMountingManager` apply to ViewGroups

Concurrent rendering works because React can build a "work-in-progress" shadow tree alongside the committed one and discard it without ever mounting.

### The "Why"
- Concurrent React + async UIs were incompatible — Fabric makes them possible.
- Sync layout queries (e.g., onboarding tooltips that need exact positions) were unsafe pre-Fabric.
- Removing JSON serialization for view ops cut UI-thread CPU on busy screens.

### Mental Model
Fabric is **React's DOM equivalent for native**. Where React DOM has the browser's mutable DOM, Fabric has an immutable shadow tree it commits atomically — closer in spirit to a game engine's scene-graph swap than to old RN's chatty mutations.

### Internal Working (2026 Context)
- `Scheduler` (RuntimeScheduler) coordinates JS, commit, and mount phases — supports priority-based work like React 19 transitions.
- `ShadowNode` is templated by props/state types; Codegen produces these for custom Fabric components.
- Mounting is double-buffered: the UI thread swaps the active "MountingTransaction" atomically.

### Modern Implementation (Code)
You usually don't write Fabric internals. You **author Fabric components** for custom native views:

```ts
// specs/RNCanvasNativeComponent.ts
import type { ViewProps } from 'react-native';
import type { Float } from 'react-native/Libraries/Types/CodegenTypes';
import { codegenNativeComponent } from 'react-native';

export interface NativeProps extends ViewProps {
  fps: Float;
  paused?: boolean;
}

export default codegenNativeComponent<NativeProps>('RNCanvas');
```

Codegen emits the C++ ShadowNode + ComponentDescriptor; you implement the platform view (UIView / android.view.View) and the prop/state mapper.

### Comparison

| Aspect              | Old UIManager                 | Fabric                       |
| ------------------- | ----------------------------- | ---------------------------- |
| Tree                | Mutable, native-side          | Immutable C++ shadow tree    |
| Commit              | Async via Bridge              | Sync via JSI                 |
| Layout              | Separate shadow thread        | JS thread during commit      |
| Sync measurement    | Unsafe                        | Supported                    |
| Concurrent React    | Incompatible                  | Supported                    |
| Custom native views | `ViewManager` + Bridge        | Fabric Component + Codegen   |

### Production Usage
- Apps shipping React 19 transitions / Suspense need Fabric — old UIManager tears.
- Reanimated 3 talks to Fabric's shadow tree from the UI runtime to avoid JS-thread roundtrips for layout-driven animations.

### Hands-On Exercise
1. Convert a legacy `ViewManager` (e.g., a color-picker) into a Fabric Component.
2. Add a sync `measure()` method and use it during a tooltip layout.
3. Wrap the parent in `<Suspense>` and observe no flash on hydration — only possible because Fabric commits atomically.

### Common Mistakes
- Mutating shadow node props directly (you can't — nodes are immutable; you clone).
- Doing heavy work in `onLayout` callbacks that fires every commit.
- Mixing legacy `ViewManager` and Fabric Component for the same view — picks one path; mixing breaks the Interop Layer.

### Production Red Flags
- Custom view authored as legacy `ViewManager` in a New-Arch app.
- Any code reading layout via `setTimeout(() => view.measure(...))` — pre-Fabric pattern.

### Performance & Metrics
- Commit: typically 0.5–3ms for medium screens.
- Mount: 1–5ms; the UI thread swap is constant-time.
- Fewer JSON crossings → cleaner P95 frame times.

### Metrics That Matter
Frame drop %, commit duration P95, mount duration P95, ANR rate.

### Decision Framework
- New custom native view in 2026 → Fabric Component.
- Existing widely-used `ViewManager` → migrate when you can; Interop covers the rest.
- Need sync measurement / concurrent rendering → Fabric required.

### Senior-Level Insight
Fabric's biggest unlock isn't perf — it's **correctness under concurrency**. The async old UIManager fundamentally couldn't host concurrent React without tearing. Architecturally this is the same lesson React DOM learned with the Fiber rewrite: scheduling needs an immutable data model.

### Real-World Scenario
**Symptom:** During a Suspense fallback → content swap, a brief flash of misaligned UI.
**Investigation:** App still on old UIManager; mount instructions partially applied before the React commit completed.
**Root cause:** Async UIManager couldn't commit the new tree atomically.
**Fix:** Enable Fabric. Flash gone.
**Lesson:** Concurrent React and old UIManager are incompatible at the architecture level.

### Production Failure Story
**Incident:** A retailer migrated to New Arch, custom barcode scanner view stopped rendering on Android.
**Investigation:** Native logs show `Tried to use ViewManager X with Fabric`.
**Root cause:** ViewManager wasn't migrated; Interop Layer wasn't enabled for view managers.
**Fix:** Add the view to the Interop list and ship a Fabric Component in the next release.
**Prevention:** CI gate that lists all ViewManagers and warns on each release until migrated.

### Debugging Checklist
1. `console.log(global.nativeFabricUIManager)` — confirms Fabric installed.
2. Use Perfetto / Systrace; look for `FabricUIManager#commit` and `MountingManager` events.
3. React DevTools (RN) profiler shows Fabric commit vs render time separately.
4. Layout glitches under concurrent rendering → suspect non-Fabric custom views.

### Advanced / Internal Knowledge
- ShadowNode cloning is copy-on-write at the **child pointer** level; subtrees share references.
- Yoga is invoked on dirty nodes only; clean subtrees skip layout.
- The `MountingTransaction` includes `MutationInstructions` ordered to satisfy parent-before-child constraints.

### 2026 AI Tip
AI tends to generate legacy `ViewManager` snippets when asked for "custom native view." Always ask: "give me a Fabric Component using `codegenNativeComponent` with a TS Spec." Verify the build emits `*ComponentDescriptor` files.

### Related Topics
Q2 (JSI), Q3 (TurboModules), Q5 (Bridgeless), S2 (React 19 concurrent), S7 (perf).

### Interview Follow-Up Questions
- "Why are shadow nodes immutable?"
- "What runs on which thread during a Fabric commit?"
- "How does Fabric enable concurrent React?"
- "How would you migrate a `ViewManager` to a Fabric Component?"

### Memory Hook
**"Render → Commit → Mount. Immutable shadow tree, atomic swap, no tearing."**

### Revision Notes
> Fabric = immutable C++ shadow tree, JSI commit, atomic mount; enables React 19 concurrent + sync measurement; custom views via Codegen `codegenNativeComponent`.

---

## Q5. Bridgeless Mode & the Runtime Scheduler

### Difficulty
Advanced → Architect

### Interview Frequency
Common at Senior+; expected at Staff.

### Prerequisites
Q1–Q4.

### TL;DR
Bridgeless mode removes the legacy `RCTBridge` entirely; module access goes through the TurboModule registry and the **RuntimeScheduler** coordinates work across JS, commit, and mount with React 19 priorities.

### 30-Second Interview Answer
"Bridgeless mode is the default execution model in 2026. There's no `RCTBridge` instance — the JS runtime is initialized with a TurboModuleManager (for native modules) and a Fabric UIManager (for views) installed via JSI. The RuntimeScheduler replaces the old MessageQueue and gives React 19 a way to express priority and interruptibility."

### 2-Minute Practical Answer
Pre-Bridgeless apps had a `RCTBridge` that owned:
- the JS executor
- the message queue
- the module registry
- the UIManager

Bridgeless decomposes these:
- **`ReactInstance`** owns the JS runtime.
- **`TurboModuleManager`** is the lazy native module registry.
- **`FabricUIManager`** owns rendering.
- **`RuntimeScheduler`** schedules work units (JS tasks, microtasks, mounting) with priority.

What you observe as a developer:
- `NativeModules.X` still works — it's a Proxy backed by the TurboModule registry.
- Cold start improves because there's no Bridge init + no eager module instantiation.
- React 19 features (`startTransition`, Suspense fallbacks) actually behave correctly.

### 5-Minute Architecture Answer
Bridgeless = Bridge object literally not constructed. The boot sequence in 2026:

```
App start
  ↓
Hermes Runtime created
  ↓
JSI bindings installed:
  ├─ __turboModuleProxy  (TurboModule registry HostObject)
  ├─ nativeFabricUIManager (Fabric UIManager HostObject)
  ├─ RuntimeScheduler (priority queue via JSI)
  └─ Microtask queue
  ↓
JS bundle evaluated (Hermes bytecode)
  ↓
React renders → Fabric commits → MountingManager applies
```

The **RuntimeScheduler** is the unsung hero. It coordinates:
- React's `requestIdleCallback`-style work
- Fabric commit deadlines
- React 19 transition priorities
- Microtask vs macrotask ordering

Without it, concurrent React features couldn't yield cooperatively. With it, `startTransition` work can be interrupted by a higher-priority gesture.

### The "Why"
- Bridge was load-bearing infrastructure that couldn't be optimized further.
- React 19 needed cooperative scheduling on the JS thread.
- App startup was dominated by eager module init in large apps.

### Mental Model
Bridgeless is RN finally adopting the **same scheduler discipline** React DOM has had since Fiber. The thread is shared; work is sliced; priority decides who runs next.

### Internal Working (2026 Context)
- The `ReactNativeFeatureFlags` C++ class (configurable per app) toggles Bridgeless and related features (microtasks, batched event emission, etc.).
- Errors that used to surface as "RCTBridge dispatch_sync" now surface as "TurboModuleManager not initialized" — debugging signal moves up the stack.

### Modern Implementation (Code)
You don't directly toggle Bridgeless in 2026 — it's on by default in new apps and via `expo prebuild` / template upgrade. To verify:

```ts
// app/boot/diagnostics.ts
export function logArchMode(): void {
  // @ts-expect-error — globals injected by RN
  const bridgeless = !!global.RN$Bridgeless;
  // @ts-expect-error
  const fabric = !!global.nativeFabricUIManager;
  // @ts-expect-error
  const tm = !!global.__turboModuleProxy;
  console.log({ bridgeless, fabric, turboModules: tm });
}
```

For brownfield, in `AppDelegate.mm` you'll see `RCTAppDelegate` + `bridgelessEnabled = YES` (template handles this).

### Comparison

| Aspect              | With Bridge                | Bridgeless                   |
| ------------------- | -------------------------- | ---------------------------- |
| `RCTBridge`         | Yes                        | No                           |
| Module init         | Eager                      | Lazy (TurboModule)           |
| Scheduler           | MessageQueue + main runloop| RuntimeScheduler (priorities)|
| React 19 features   | Best-effort                | Fully supported              |
| Cold start          | +150–500ms penalty         | Removed                      |

### Production Usage
- Bridgeless is the only path that lets you ship React 19 transitions correctly.
- Apps with custom native modules must either migrate or rely on the Interop Layer (Q6).

### Hands-On Exercise
1. Boot an app with Bridgeless off. Profile cold start with Hermes Profiler.
2. Enable Bridgeless. Re-profile. Quantify TTI delta.
3. Add a `startTransition` to a heavy filter on a list. With Bridge, observe input lag during transition; with Bridgeless, observe interruption working correctly.

### Common Mistakes
- Calling `[bridge moduleForName:...]` from native code in Bridgeless — there's no bridge.
- Relying on `RCT_EXPORT_METHOD` semantics that assume a Bridge thread.
- Using libraries that haven't migrated and didn't register with the Interop Layer.

### Production Red Flags
- Native code that grabs `RCTBridge.currentBridge` at runtime.
- Custom thread management around `bridge.dispatchBlock:` calls.
- Calls to `RCTRootView` (Fabric uses `RCTFabricSurface`).

### Performance & Metrics
- Cold start: −150 to −500ms typical on Android mid-tier.
- Transition responsiveness: input latency drops measurably during heavy renders.
- Memory: small but real reduction from no Bridge buffers.

### Metrics That Matter
TTI, transition input latency, ANR rate, JS thread occupancy.

### Decision Framework
- New apps → Bridgeless on, no exception.
- Brownfield → Bridgeless + Interop, plan module migrations sprint-by-sprint.
- Legacy library author → ship Spec + TurboModule support; let consumers enable Bridgeless.

### Senior-Level Insight
Bridgeless completes the architectural arc: RN moves from "two worlds talking by mail" to "two worlds sharing a thread, scheduled cooperatively." The cost is sharper failure modes (thread starvation, sync call hangs) that demand better profiling discipline.

### Real-World Scenario
**Symptom:** Crash on launch in production, only on Android, only after the New Arch flip.
**Investigation:** Native log: `getSharedC++JSExecutorFactory not implemented for bridgeless`.
**Root cause:** A native dependency overrode `RCTAppDelegate` to provide a custom JS executor — incompatible with Bridgeless.
**Fix:** Remove the override (executor is built-in), update the dependency.
**Lesson:** Native customization points moved; audit `AppDelegate` and `MainApplication` during migration.

### Production Failure Story
**Incident:** A trading app shipped a "smooth scroll" animation using `requestAnimationFrame` from JS — fps tanked under high tick rates.
**Investigation:** RuntimeScheduler showed `IdlePriority` work blocked by tick handlers (UserBlockingPriority should have been used).
**Root cause:** Wrong priority hint; high-frequency JS work ran ahead of UI commits.
**Fix:** Move animation to Reanimated worklets (UI thread); JS only emits state diffs.
**Prevention:** Ban `requestAnimationFrame` for animation work; team rule.

### Debugging Checklist
1. Verify `global.RN$Bridgeless`.
2. Check Hermes Profiler for `RuntimeScheduler::scheduleTask` patterns.
3. Native logcat / Console for `RCTBridge` references — should be empty.
4. ANR / watchdog events under load → RuntimeScheduler starvation.

### Advanced / Internal Knowledge
- RuntimeScheduler exposes `SchedulerPriority` (Immediate, UserBlocking, Normal, Low, Idle) used by React 19's transitions.
- Microtasks (`queueMicrotask`, Promise jobs) run on the JS thread between tasks; misuse can starve commits.
- Static Hermes is being designed with RuntimeScheduler hooks for AOT-aware scheduling.

### 2026 AI Tip
AI rarely understands RuntimeScheduler priorities. If you ask AI for "smooth animation in RN," it'll often suggest `requestAnimationFrame` — wrong path. Force the prompt: "use Reanimated worklets and explain priority."

### Related Topics
Q2, Q3, Q4, Q6, S2 (React 19), S7 (perf).

### Interview Follow-Up Questions
- "What replaces `RCTBridge.currentBridge` in Bridgeless?"
- "How does RuntimeScheduler interact with React 19 transitions?"
- "What native customizations break under Bridgeless?"

### Memory Hook
**"No Bridge. One runtime, one scheduler, one priority queue."**

### Revision Notes
> Bridgeless = no `RCTBridge`; modules via TurboModule registry; RuntimeScheduler enables cooperative React 19 scheduling; default in 2026.

---

## Q6. New Architecture Interop Layer & migration

### Difficulty
Advanced → Architect

### Interview Frequency
Architect-level — expected for any "how do you migrate a brownfield app" question.

### Prerequisites
Q1–Q5.

### TL;DR
The **Interop Layer** lets legacy native modules and `ViewManager`s work inside Bridgeless / Fabric apps unchanged, by emulating the Bridge contract on top of TurboModuleManager — the official migration runway.

### 30-Second Interview Answer
"The Interop Layer is a compatibility shim that lets legacy `RCTBridgeModule` and `ViewManager` code run inside a Bridgeless + Fabric app. It registers legacy modules with the TurboModuleManager via a fake Bridge, and exposes legacy view managers to Fabric via a wrapping ComponentDescriptor. It's the official path to migrate brownfield apps incrementally — turn New Arch on, then convert modules one by one."

### 2-Minute Practical Answer
Migration without Interop = "stop the world, rewrite every native module before flipping the switch." Impossible for large brownfield apps.

Interop = flip the switch first, then incrementally convert.

It works in two parts:
- **Module Interop** — at boot, the Interop layer enumerates legacy modules and registers them with `TurboModuleManager`. JS sees them at the same names; calls go through the legacy Bridge code paths but inside a Bridgeless container.
- **View Manager Interop** — registers a generic `LegacyViewManagerInterop` ComponentDescriptor that wraps each legacy `ViewManager` so Fabric can mount it.

You opt-in module-by-module via a config (Obj-C++ `RCTLegacyInteropComponents` / Kotlin `LegacyArchitectureLogger`) listing which legacy components participate.

### 5-Minute Architecture Answer
Boot order under Interop:
```
ReactInstance starts
  ↓
TurboModuleManager built
  ↓
Interop registers legacy RCTBridgeModule classes
   → wraps each in a TurboModule adapter
  ↓
FabricUIManager built
  ↓
Interop registers LegacyViewManagerInterop ComponentDescriptors
   → wraps each ViewManager in a Fabric-compatible mount path
  ↓
JS bundle evaluated; calls to NativeModules.X resolve transparently
```

Tradeoffs:
- Interop'd modules **don't gain** sync calls or zero-serialization — they use the legacy code path.
- They **do** work in a Bridgeless app, so you can ship the New Arch without rewriting everything.
- Performance is somewhere between full Bridge and full TurboModule; mostly closer to TurboModule for cold start (lazy registration), closer to Bridge for per-call cost.

Migration pattern:
1. Enable New Arch + Bridgeless + Interop.
2. Validate the app boots, gestures work, custom views render.
3. Pick the **highest-impact** module (usually camera, list cells, animation runtime, payments).
4. Write Spec + TurboModule version, ship behind a flag, migrate JS callers, drop the legacy.
5. Repeat. Track migration coverage as a release metric.

### The "Why"
- Brownfield reality: enterprise apps have dozens or hundreds of native modules they cannot rewrite atomically.
- Without Interop, "go to New Arch" became a years-long blocker; with Interop, it's an iteration plan.

### Mental Model
Interop is a **codepoint translator**. Your app speaks "modern New Arch"; legacy modules speak "Bridge"; Interop translates in both directions, with some performance tax.

### Internal Working (2026 Context)
- iOS: `RCTLegacyViewManagerInteropComponentView` + `RCTBridgeModuleProxy`.
- Android: `LegacyArchitecture` adapter classes wrap `ViewManager` and `NativeModule`.
- Codegen still runs only for migrated specs; non-migrated code is untouched.

### Modern Implementation (Code)
You enable Interop via app config. Example (RN template, simplified):

```objc
// AppDelegate.mm
- (BOOL)bridgelessEnabled { return YES; }
- (BOOL)fabricEnabled { return YES; }

// Opt in legacy ViewManager wrappers
- (NSDictionary<NSString *, Class> *)thirdPartyFabricComponents {
  return @{
    @"RNCWebView": [RNCWebView class],   // Fabric-native
  };
}
```

```ts
// JS side — stays identical
import { NativeModules, requireNativeComponent } from 'react-native';
const Legacy = NativeModules.LegacyAuth; // resolves through Interop
const LegacyView = requireNativeComponent('LegacyChart'); // Fabric Interop wrapper
```

### Comparison

| Aspect            | Bridge era       | Interop                          | Native New Arch          |
| ----------------- | ---------------- | -------------------------------- | ------------------------ |
| Bridgeless        | No               | Yes                              | Yes                      |
| Sync calls        | No               | No                               | Yes                      |
| Zero serialization| No               | No                               | Yes                      |
| Migration effort  | Rewrite all      | Flip flag, migrate gradually     | Migrate before flipping  |
| Long-term home    | Deprecated       | Transitional                     | Target state             |

### Production Usage
- Big-name apps (Discord, Shopify, Instagram-style apps) used Interop to go Bridgeless without halting feature work.
- Track "% modules migrated" as a platform team OKR.

### Hands-On Exercise
1. Take an app with one legacy ViewManager (e.g., a custom map). Enable New Arch + Interop. Verify it renders.
2. Convert the ViewManager to a Fabric Component. Remove from the Interop list.
3. Profile commit + mount times before/after; native Fabric Components measurably win on busy screens.

### Common Mistakes
- Forgetting to add a legacy module to the Interop list → JS sees `null` from `NativeModules.X`.
- Believing Interop performance equals native New Arch — it's a compatibility path, not a perf path.
- Migrating "easy" modules first (low traffic) — wastes effort. Migrate **hot paths** first.

### Production Red Flags
- App has been on Interop for 12+ months with no migration progress → tech debt accumulating.
- Mixing Fabric Components and Interop wrappers for the same view name.
- Custom `RCTBridge` access from native code — won't work even under Interop.

### Performance & Metrics
- Cold start: similar to full New Arch (Interop modules lazy-init too).
- Per-call: similar to Bridge (still serializes for legacy modules).
- Mount: Interop wrappers add a small constant cost; usually invisible.

### Metrics That Matter
% migrated modules, legacy call P95 latency, ANR rate during migration.

### Decision Framework
- Brownfield app, dozens of native modules → enable Interop on day one of migration.
- Greenfield → don't enable Interop; force New-Arch-only discipline.
- Library author → ship both Bridge and TurboModule paths until you can drop RN <0.74.

### Senior-Level Insight
Migration is a **product manager problem disguised as a tech problem**. The Interop Layer turns a binary gate into a continuous metric ("70% migrated, ETA Q3"). Track it; budget for it; assign it owners. Without ownership, Interop becomes permanent.

### Real-World Scenario
**Symptom:** App is on New Arch, but cold start regressed by 200ms after a recent native module addition.
**Investigation:** Profiler shows the new module's Bridge-path init still happens eagerly because Interop registered it in the old code path.
**Root cause:** Module registered as legacy `RCTBridgeModule` with `+ (BOOL)requiresMainQueueSetup { return YES; }`.
**Fix:** Convert to TurboModule (lazy by default) or set `requiresMainQueueSetup = NO` and defer real work.
**Lesson:** Interop preserves legacy semantics including their performance footguns.

### Production Failure Story
**Incident:** A health app shipped New Arch + Interop. A custom ECG view (`ViewManager`) started flickering during navigation transitions.
**Investigation:** Fabric's atomic mount + Interop's mutable `ViewManager` semantics interacted badly: re-attach during transition reset the chart.
**Root cause:** `ViewManager` lifecycle (`view didMount`) fired more often under Fabric than expected.
**Fix:** Migrate to a real Fabric Component with explicit state preservation.
**Prevention:** Add E2E test for navigation transitions on every Interop-wrapped view.

### Debugging Checklist
1. `NativeModules.X === null`? Check the Interop registration list.
2. Custom view not rendering? Confirm it's in `thirdPartyFabricComponents` or the Interop list.
3. Legacy callback never fires? Bridgeless changed thread semantics — check thread of invocation.
4. Cold start regression after migration? Audit `requiresMainQueueSetup` and eager init in legacy code.

### Advanced / Internal Knowledge
- The Interop Layer's source lives in `react-native/Libraries/AppDelegate` (iOS) and `ReactAndroid/src/main/java/com/facebook/react/interop/` (Android).
- Interop'd modules don't get the lazy init benefit if they hook into app boot via class load.
- View Interop wraps the legacy view in a `RCTLegacyViewManagerInteropCoordinator` that proxies prop diffs.

### 2026 AI Tip
AI is good at converting one legacy module to a TurboModule in isolation. It is **bad** at the migration plan — the prioritization, metrics, and rollout are human work. Use AI to convert; use humans to sequence.

### Related Topics
Q1–Q5, S16 (architecture), S20 (release engineering), S27 (runbooks).

### Interview Follow-Up Questions
- "How would you sequence migration of 80 native modules?"
- "What's the perf cost of staying on Interop?"
- "How do you measure migration progress?"
- "What can break in Interop'd ViewManagers under Fabric?"

### Memory Hook
**"Interop = New Arch on top, Bridge inside. Flip the flag, migrate the hot paths, retire the rest."**

### Revision Notes
> Interop Layer = compat shim letting legacy modules/views run under Bridgeless+Fabric; transitional, not a destination; migrate hot paths first; track as a release metric.
