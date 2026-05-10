# S15 — Native Bridging

> TurboModules · Fabric components · Codegen · background tasks · IAP · VisionCamera

Five Q-topics in the mandatory per-topic format. Native bridging in 2026 means the **New Architecture** path: TypeScript specs feed Codegen, which generates C++ / ObjC++ / Kotlin glue; you implement the native side; JSI provides synchronous, type-safe access from JS. Legacy `NativeModules` (Bridge) is **[DEPRECATED]** for new code.

---

### Q1. Writing a TurboModule end-to-end — TS spec → native → JS

---

## Difficulty
- Advanced

## Interview Frequency
- Very Common (any role touching native)

## Prerequisites
- TS, basic ObjC++/Kotlin, RN New Architecture (S4)

## TL;DR
Define a **TS spec** (`Native<Name>.ts` with `TurboModuleRegistry.getEnforcing`), enable **Codegen**, implement the generated protocol/interface in **ObjC++** (iOS) and **Kotlin/Java** (Android), register the module in your **package**, then call from JS. JSI gives you sync calls, typed args, and zero serialization vs the legacy Bridge.

---

## 30-Second Interview Answer

> "TurboModules are the New Architecture replacement for `NativeModules`. The flow: write a TS spec extending `TurboModule`; Codegen reads it and emits C++ headers + native protocol stubs; implement the protocol in ObjC++ and Kotlin; register via the new module provider in your `RCTAppDelegate` (iOS) and `ReactPackage` (Android). Now JS calls are typed, can be sync, and skip JSON serialization. The big wins: type safety end-to-end, lazy loading, and synchronous methods where they make sense (e.g., reading a config flag)."

---

## 2-Minute Practical Answer

End-to-end pipeline:

1. **TS spec** declares the contract.
2. **Codegen** runs at build time, generating:
   - C++ JSI bindings.
   - ObjC++ protocol (`<RNFooSpec>`).
   - Java/Kotlin abstract class (`NativeFooSpec`).
3. **Native impl** implements the generated interface.
4. **Registration** wires the module into the runtime.
5. **JS usage** imports the spec; `TurboModuleRegistry.getEnforcing<Spec>('Foo')` returns a typed handle.

Sync vs async: JSI supports synchronous calls. Use sparingly — sync calls block the JS thread. Good for: cheap config reads, device info. Bad for: I/O, network, anything > 1ms.

Codegen lives in `package.json`:
```json
"codegenConfig": {
  "name": "RNFooSpec",
  "type": "modules",
  "jsSrcsDir": "src"
}
```

Module registration on iOS (New Arch): override `getModuleInstance` in your bridge delegate. On Android: extend `BaseReactPackage` and override `getModule()` + `getReactModuleInfoProvider()`.

---

## 5-Minute Architecture Answer

The Bridge era required: registering a module via macros (`RCT_EXPORT_MODULE`), declaring methods (`RCT_EXPORT_METHOD`), JSON-serializing every argument and return value, and asynchronous-only invocation via the message queue. Type checking happened at runtime if at all.

The New Architecture (2026 default since RN 0.76+) replaces this with:

- **JSI** (JavaScript Interface): C++ API that lets native code expose `HostObject`s directly to the JS engine. No JSON. No bridge. Native references can be passed by reference.
- **TurboModules**: the modern equivalent of native modules, exposed via JSI. Lazy-loaded (only when first imported). Sync or async.
- **Codegen**: a build-time tool that reads TS specs and emits native interfaces. Eliminates "spec drift" — JS and native cannot disagree about the API.
- **Bridgeless mode**: removes the legacy bridge entirely. Default in 0.74+.

The TS spec is the single source of truth:

```ts
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // Note: codegen-supported types only:
  //   number | string | boolean | Object | Array | Promise | (...) => void | null
  readonly getConstants: () => { defaultName: string };
  multiply(a: number, b: number): number; // sync
  fetchUserAsync(id: string): Promise<{ id: string; name: string }>;
  addListener(eventName: string): void;
  removeListeners(count: number): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('RNFoo');
```

Constraints (Codegen type system):
- No union types (except null).
- No generics in spec.
- Object types must be inline or imported from a shared types file with named export.
- Methods returning `void` are fire-and-forget; for async results use `Promise<T>` or callbacks.
- `getConstants()` is sync, called once, results cached.

Failure modes:
- Spec changes without rebuilding native → runtime crash.
- Sync method doing slow work → JS thread blocked, frame drops.
- Forgetting `addListener` / `removeListeners` for event-emitting modules → warnings.
- Mixing legacy `NativeModules.Foo` and new `TurboModuleRegistry` for same module → confusion.

The 2026 specific:
- **Static Hermes** (early 2026 betas) compiles TS modules ahead of time, making TurboModule bindings even faster.
- **Expo Modules API** is the recommended layer on top — easier ergonomics (Swift/Kotlin DSL), still uses TurboModules under the hood.
- **C++ TurboModules** (cross-platform impl in C++) are a thing for libraries that share logic across platforms.
- **Interop layer** lets you progressively migrate: legacy `NativeModules` still work alongside TurboModules in the same app (deprecated path; remove eventually).

---

## The "Why"

Native APIs are how mobile apps access camera, biometrics, BLE, payments, OS features. The bridging layer is the seam between JS and native — historically the slowest, most fragile part of RN. The New Architecture's TurboModules + JSI eliminate JSON serialization (huge perf win), enable sync calls, and add type safety end-to-end via Codegen. Companies care because every shipped feature touches some native module; reducing breakage and improving perf at this layer compounds across the app.

---

## Mental Model

Old bridge = mailing letters between JS and native, written in JSON, no return address typed. TurboModules = direct phone line with caller ID, the other side picks up immediately, both sides agree on the schema before the call.

---

## Internal Working (2026 Context)

- JSI lives in C++; both iOS (`Hermes::makeHermesRuntime`) and Android use the same JSI surface.
- A TurboModule is a C++ `HostObject` that the JS runtime sees as a regular JS object.
- Each method is a `HostFunction` (C++ lambda) bound by Codegen-generated glue.
- Lazy loading: `TurboModuleRegistry.getEnforcing` triggers native instantiation on first import.
- Registration: iOS uses `RCTTurboModuleManager` + `RCTAppDelegate`; Android uses `BaseReactPackage` + `ReactPackageTurboModuleManagerDelegate`.

Threading:
- By default, methods run on a module-specific thread (configurable via `getMethodQueue` on iOS, `@ReactMethod` queue config on Android).
- Sync methods run on whatever thread called them (usually JS thread).
- Use a serial dispatch queue for state mutations.

---

## Modern Implementation (Code)

**1) Codegen config** (`package.json`):
```json
{
  "name": "react-native-foo",
  "codegenConfig": {
    "name": "RNFooSpec",
    "type": "modules",
    "jsSrcsDir": "src",
    "android": { "javaPackageName": "com.foo" }
  }
}
```

**2) TS spec** (`src/NativeFoo.ts`):
```ts
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  readonly getConstants: () => { version: string };
  multiply(a: number, b: number): number;
  fetchUserAsync(id: string): Promise<{ id: string; name: string }>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('RNFoo');
```

**3) iOS impl** (`ios/RNFoo.mm`):
```objc++
#import "RNFoo.h"
#import <RNFooSpec/RNFooSpec.h>  // generated by Codegen

@interface RNFoo () <NativeFooSpec>
@end

@implementation RNFoo
RCT_EXPORT_MODULE()

- (NSNumber *)multiply:(double)a b:(double)b {
  return @(a * b);
}

- (void)fetchUserAsync:(NSString *)userId
               resolve:(RCTPromiseResolveBlock)resolve
                reject:(RCTPromiseRejectBlock)reject {
  // Off-main-thread work; resolve when done
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSDictionary *user = @{ @"id": userId, @"name": @"Ada" };
    resolve(user);
  });
}

- (NSDictionary *)getConstants {
  return @{ @"version": @"1.0.0" };
}

- (std::shared_ptr<facebook::react::TurboModule>)
  getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeFooSpecJSI>(params);
}

@end
```

**4) Android impl** (`android/src/main/java/com/foo/FooModule.kt`):
```kotlin
package com.foo

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = FooModule.NAME)
class FooModule(reactContext: ReactApplicationContext) : NativeFooSpec(reactContext) {
  companion object { const val NAME = "RNFoo" }

  override fun getName(): String = NAME

  override fun multiply(a: Double, b: Double): Double = a * b

  override fun fetchUserAsync(id: String, promise: Promise) {
    // off-thread
    Thread {
      val map = com.facebook.react.bridge.Arguments.createMap().apply {
        putString("id", id); putString("name", "Ada")
      }
      promise.resolve(map)
    }.start()
  }

  override fun getTypedExportedConstants(): MutableMap<String, Any> =
    mutableMapOf("version" to "1.0.0")
}
```

**5) Android package** (`FooPackage.kt`):
```kotlin
class FooPackage : BaseReactPackage() {
  override fun getModule(name: String, ctx: ReactApplicationContext) =
    if (name == FooModule.NAME) FooModule(ctx) else null

  override fun getReactModuleInfoProvider() = ReactModuleInfoProvider {
    mapOf(
      FooModule.NAME to ReactModuleInfo(
        FooModule.NAME, FooModule::class.java.name,
        false, false, false, true /* isTurboModule */
      )
    )
  }
}
```

**6) JS usage**:
```ts
import Foo from 'react-native-foo/src/NativeFoo';

const result = Foo.multiply(3, 4);                 // sync, 12
const user = await Foo.fetchUserAsync('user-1');   // async
console.log(Foo.getConstants().version);
```

---

## Comparison

| Aspect | Legacy NativeModules [DEPRECATED] | TurboModule (2026) |
|---|---|---|
| Transport | JSON over Bridge | JSI direct |
| Sync calls | no | yes |
| Type safety | runtime only | compile-time via Codegen |
| Lazy load | no (eager) | yes |
| Perf | JSON ser/deser per call | near-zero overhead |
| Error mode | silent type mismatch | Codegen build error |

| Layer | Pick |
|---|---|
| New library, full control | TurboModule via Codegen |
| Faster iteration, Expo-managed | Expo Modules API (wraps TurboModule) |
| Cross-platform impl in C++ | C++ TurboModule |
| Legacy module in older app | NativeModules (migrate when possible) |

---

## Production Usage

- **Camera** (VisionCamera v3+): Fabric component + TurboModule for control surface.
- **Biometrics**: TurboModule with sync `getConstants` + async `authenticate`.
- **Storage** (MMKV): TurboModule with sync get/set — perfect sync use case.
- **Crypto / hashing**: TurboModule sync OK for cheap ops.
- **Large native libs** (maps, AR): Fabric component + TurboModule pair.

---

## Hands-On Exercise

1. **Implementation**: scaffold a TurboModule with Codegen for both platforms; implement `multiply`, `fetchUserAsync`, `getConstants`.
2. **Debugging**: spec change not reflected in native build — re-run Codegen (`pod install` triggers iOS, Gradle build triggers Android).
3. **Architecture**: design which methods should be sync vs async (criteria).
4. **Migration**: convert a legacy `NativeModules.Foo` to a TurboModule; preserve JS API surface.

---

## Common Mistakes

- Sync methods doing I/O → JS thread freeze.
- Forgetting `getMethodQueue` (iOS) → main thread mutation.
- Spec types unsupported by Codegen (unions, generics) → build fails cryptically.
- Not implementing `getTurboModule` on iOS → module not exposed under New Arch.
- Mixed registration paths (legacy + TurboModule) for same name.
- Forgetting to run Codegen after spec changes.

---

## Production Red Flags

- **`RCT_EXPORT_METHOD`** in new code → using legacy bridge path.
- **Sync method with `dispatch_sync` to main queue** → deadlock risk.
- **Promise rejected with non-Error object** → loses stack trace.
- **No tests for native module** → silent regression.

---

## Performance & Metrics (MANDATORY)

- **Method call overhead**: ~microseconds with JSI (vs ~ms with Bridge for non-trivial JSON).
- **TTI**: lazy loading delays cost; first import pays instantiation.
- **Bundle**: Codegen output adds to native binary (small).
- **Memory**: HostObject ~hundreds of bytes per module.

---

## Metrics That Matter

- Native module load time (first import → first call)
- Sync method P95 duration
- Promise resolution P95 duration
- Native method error rate
- Codegen build time

---

## Decision Framework

| Need | Pick |
|---|---|
| Stateless utility (hash, crypto) | TurboModule sync |
| OS API (camera, biometrics) | TurboModule async |
| Custom view | Fabric component |
| Both | Pair them |
| Library distributed via npm | Codegen + TS spec mandatory |
| Internal one-off | Expo Modules API for ergonomics |

---

## Senior-Level Insight

The mature take: **TurboModules raise the floor of quality but don't replace good API design**. A well-designed TurboModule has: (1) a minimal sync surface (config reads only), (2) async for everything I/O, (3) typed events with explicit `addListener`/`removeListeners`, (4) error returns as rejected Promises with structured payloads (code + message + cause), (5) Codegen spec versioned alongside the JS API.

Org-level: prefer **Expo Modules API** for new internal modules — same TurboModule guarantees, much less boilerplate, Swift/Kotlin DSL. Reserve raw TurboModule for library publishers who need full control.

---

## Real-World Scenario

**Symptom:** JS calls a native method and gets `undefined` back instead of a number.
**Investigation:** Spec declared `multiply(a, b): number`. Native impl returns `NSNumber *` (boxed) but generated header expects `double`. Type mismatch silently became 0.
**Root Cause:** Codegen wasn't re-run after spec change; old generated header in build cache.
**Fix:** Clean build (`cd ios && pod deintegrate && pod install`); rebuild; values match.
**Lesson:** Codegen output is build-time; spec changes require a clean rebuild.

---

## Production Failure Story

**Incident:** A team migrated their analytics module from legacy `NativeModules` to TurboModule. After release, ~5% of devices crashed on launch — only on Android 8.
**Impact:** Crash-free sessions dropped from 99.7% to 94.8%; rollback required.
**Investigation:** New Arch was enabled but the analytics module was registered via the legacy path on Android 8 due to a Gradle config issue. The crash was a class-not-found at boot.
**Root Cause:** Conditional New-Arch enablement wasn't tested on min-SDK devices; `BaseReactPackage` registration failed.
**Fix:** Unify package registration; matrix-test New-Arch + minSdk combos.
**Prevention:** CI includes minSdk + maxSdk emulators with New-Arch flag toggled.

---

## Debugging Checklist

1. Verify spec file is in `jsSrcsDir`.
2. Run `npx react-native codegen` (or rely on autolink) and inspect generated headers.
3. iOS: check `Pods/Headers/Public/RNFooSpec/` exists.
4. Android: check `build/generated/source/codegen/java/com/foo/NativeFooSpec.java`.
5. Verify `getTurboModule` (iOS) / Module registered in `BaseReactPackage` (Android).
6. Test sync vs async behavior via React DevTools profiler.

---

## Advanced / Internal Knowledge

- `HostObject` lifetime: held by JS GC; native side gets `~HostObject()` when JS releases.
- JSI `Value` is a tagged union (number, string, object, function, etc.); conversions cost cycles, batch where possible.
- C++ TurboModules: implement once in C++, ship same lib for both platforms — used by react-native-mmkv, react-native-quick-sqlite ancestor.
- Method queues: iOS `dispatch_queue_t`, returned by `methodQueue`. Async = serial queue typically.
- Promise rejection codes: standardize across modules (e.g., `E_PERMISSION_DENIED`, `E_NETWORK`).

---

## 2026 AI Tip

- AI is **good at**: scaffolding TS specs and matching native stubs.
- AI is **bad at**: knowing your minSdk / iOS version Codegen quirks — verify against current RN.
- **Hallucination risk**: AI may emit unsupported spec types (unions) — catch in build.
- **Prompt pattern**: "Generate a TurboModule named `RNFoo` with sync `multiply(a,b): number`, async `fetchUserAsync(id): Promise<{id,name}>`, and Codegen spec — full iOS Obj-C++, Android Kotlin, package registration."

---

## Related Topics

- S4 New Architecture (JSI, Fabric, Bridgeless)
- S5 Expo Modules API
- Q2 Fabric components

---

## Interview Follow-Up Questions

- Why does Codegen exist at all?
- When is a sync TurboModule method appropriate?
- How does JSI eliminate JSON serialization?
- How would you migrate a legacy NativeModule incrementally?
- What's the relationship between Expo Modules API and TurboModules?

---

## Memory Hook

**"Spec → Codegen → native impl → register → JS calls."**

## Revision Notes

> TS spec is truth. Codegen emits native interfaces. Implement protocol both sides. Sync sparingly, async by default. Lazy load + JSI = no JSON. Use Expo Modules API for ergonomics.

---

---

### Q2. Writing a Fabric component — custom native views

---

## Difficulty
- Advanced

## Interview Frequency
- Common (any role with custom UI/native views)

## Prerequisites
- TurboModules (Q1), basic UIKit/Android View, RN Shadow tree concepts

## TL;DR
A Fabric component is a **native view** exposed to RN with a TS spec, Codegen, and a `ComponentDescriptor` on each platform. JS sees it as a regular JSX component with typed props and events. Replaces legacy `ViewManager` / `requireNativeComponent`.

---

## 30-Second Interview Answer

> "Fabric components are the New Architecture replacement for `ViewManager`. You write a TS spec extending `ViewProps` with `codegenNativeComponent`, Codegen emits descriptors and prop types, you implement the view on iOS (`RCTViewComponentView`) and Android (`ViewManager` + `ViewGroupManager` style with new APIs). The wins: synchronous prop application via the Fabric renderer, type-safe events, and concurrent-safe layout. The classic example is a Map or Camera surface where you need real native rendering."

---

## 2-Minute Practical Answer

Pipeline mirrors TurboModules:

1. **TS spec** with `codegenNativeComponent<Props>('RNFooView')`.
2. **Props** include standard `ViewProps` plus your custom typed props.
3. **Events** declared as `DirectEventHandler<{ ... }>` or `BubblingEventHandler<...>`.
4. **Codegen** emits ObjC++ + Kotlin component descriptors.
5. **iOS impl**: subclass `RCTViewComponentView`; override `updateProps`, `updateEventEmitter`, `mountChildComponentView`.
6. **Android impl**: extend `SimpleViewManager<View>` (or `ViewGroupManager`) with `@ReactProp`; New Arch wires it via the generated descriptor.

Why Fabric is better than legacy:
- Layout runs on the same thread as state (synchronous in many cases).
- Concurrent React features (transitions, Suspense) work properly with native views.
- Props apply atomically (no half-updated views).
- Events are typed both ways.

---

## 5-Minute Architecture Answer

Legacy renderer (Paper) used Shadow Nodes on a background "shadow thread"; layout completed asynchronously, then the UI thread mutated views. Concurrent React (transitions, Suspense) cannot safely interleave with this model — too easy to get torn renders.

Fabric (New Arch) replaces this with:

- **C++ shadow tree**: shared between iOS and Android.
- **Synchronous commits**: state → shadow tree → mount in one pass.
- **Concurrent-safe**: React can render multiple alternate trees; Fabric only mounts the committed one.
- **Component descriptors**: define how props flow into shadow nodes and into native views.
- **Typed events**: declared in spec; Codegen generates native event emitters.

Your Fabric component plugs into this:
- **Spec** declares props + events (Codegen-typed).
- **iOS** `RCTViewComponentView` is the new base class; lifecycle hooks (`updateProps`, `prepareForRecycle`) replace legacy view manager methods.
- **Android** still uses `ViewManager` API but the descriptor and the prop application are New-Arch-aware.

Performance properties:
- View recycling: reuse instances across cells (huge for FlashList-like UIs).
- Atomic prop updates: no flickering from staged updates.
- Native event emitters: typed payloads, no JSON.

The 2026 specific:
- Some legacy components (e.g., `RCTScrollView`) have Fabric counterparts; some third-party libs are migrated, others not. Always check.
- **Interop layer** lets you use a legacy `ViewManager` under Fabric for a transitional period.
- **Expo Modules API** has a `View` DSL on top of Fabric — same benefits, less boilerplate.
- **visionOS** Fabric adds 3D layout primitives (early 2026).

---

## The "Why"

Custom native views (camera, maps, AR, video, charts, signature pads) require pixel-level integration with the platform. Fabric provides the only correct path under the New Architecture; legacy `requireNativeComponent` works in the interop layer but doesn't get atomic prop application or concurrent safety. Companies care because UI components are the most visible part of the app — broken ones are loudly broken.

---

## Mental Model

A Fabric component is a typed two-way bridge: props flow JS→native atomically; events flow native→JS with typed payloads. The renderer guarantees consistency.

---

## Internal Working (2026 Context)

- Each Fabric component has a **`ComponentDescriptor`** registered in C++ (auto-registered by Codegen).
- JS render → Fiber → C++ shadow tree → layout (Yoga) → mount on UI thread.
- View instances are cached and recycled where possible.
- Event emitter is a C++ object owned by the shadow node; native code calls it; events flow to JS via JSI.

---

## Modern Implementation (Code)

**1) TS spec** (`src/RNFooViewNativeComponent.ts`):
```ts
import type { ViewProps, HostComponent } from 'react-native';
import type { DirectEventHandler, Float } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

type RingChangeEvent = Readonly<{ value: Float }>;

export interface NativeProps extends ViewProps {
  color?: string;
  progress?: Float;            // 0..1
  onRingChange?: DirectEventHandler<RingChangeEvent>;
}

export default codegenNativeComponent<NativeProps>('RNFooView') as HostComponent<NativeProps>;
```

**2) iOS impl** (`ios/RNFooView.mm`):
```objc++
#import "RNFooView.h"
#import <React/RCTViewComponentView.h>
#import <react/renderer/components/RNFooSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNFooSpec/EventEmitters.h>
#import <react/renderer/components/RNFooSpec/Props.h>
#import <react/renderer/components/RNFooSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

@interface RNFooView () <RCTRNFooViewViewProtocol>
@end

@implementation RNFooView {
  CAShapeLayer *_ringLayer;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<RNFooViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _ringLayer = [CAShapeLayer layer];
    _ringLayer.fillColor = UIColor.clearColor.CGColor;
    _ringLayer.strokeColor = UIColor.systemBlueColor.CGColor;
    _ringLayer.lineWidth = 6;
    [self.layer addSublayer:_ringLayer];
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &p = *std::static_pointer_cast<RNFooViewProps const>(props);
  // color
  _ringLayer.strokeColor = [self colorFromHex:p.color].CGColor;
  // progress 0..1
  _ringLayer.strokeEnd = p.progress;
  [super updateProps:props oldProps:oldProps];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGFloat r = MIN(self.bounds.size.width, self.bounds.size.height) / 2 - 6;
  UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.bounds),
                                                                          CGRectGetMidY(self.bounds))
                                                       radius:r
                                                   startAngle:-M_PI_2
                                                     endAngle:3 * M_PI_2
                                                    clockwise:YES];
  _ringLayer.path = path.CGPath;
}

- (void)emitChange:(double)value {
  if (_eventEmitter) {
    std::dynamic_pointer_cast<RNFooViewEventEmitter const>(_eventEmitter)
      ->onRingChange({ .value = (float)value });
  }
}

@end
```

**3) Android impl** (`android/src/main/java/com/foo/FooViewManager.kt`):
```kotlin
class FooViewManager : SimpleViewManager<FooView>() {
  override fun getName() = "RNFooView"
  override fun createViewInstance(ctx: ThemedReactContext) = FooView(ctx)

  @ReactProp(name = "color")
  fun setColor(view: FooView, color: String?) { view.setRingColor(color ?: "#0A84FF") }

  @ReactProp(name = "progress", defaultFloat = 0f)
  fun setProgress(view: FooView, value: Float) { view.setProgress(value) }

  override fun receiveCommand(view: FooView, commandId: String, args: ReadableArray?) { /* ... */ }

  // For New Arch: register in your package via Codegen-generated provider.
}
```

**4) JS usage**:
```tsx
import RNFooView from 'react-native-foo/src/RNFooViewNativeComponent';

<RNFooView
  style={{ width: 80, height: 80 }}
  color="#0A84FF"
  progress={0.6}
  onRingChange={(e) => console.log(e.nativeEvent.value)}
/>
```

---

## Comparison

| Aspect | Legacy ViewManager [DEPRECATED] | Fabric Component (2026) |
|---|---|---|
| Renderer thread | shadow thread | C++ shadow tree |
| Prop application | staged | atomic |
| Concurrent React | unsafe | safe |
| Type safety | runtime | Codegen-typed |
| Event payloads | JSON | typed C++ |
| Recycling | no built-in | yes |

---

## Production Usage

- **Camera surface** (VisionCamera v3+).
- **Map view** (react-native-maps Fabric build).
- **Video player** (react-native-video v6+).
- **Charts**, **signature pads**, **AR overlays**, **WebView replacements**.
- **Skia canvases** for custom drawing (interop with shaders).

---

## Hands-On Exercise

1. **Implementation**: build the `RNFooView` ring-progress component above.
2. **Debugging**: prop changes don't apply — verify `componentDescriptorProvider` registered and `updateProps` casting correct.
3. **Architecture**: design a video-player Fabric component (props: source, paused; events: onLoad, onProgress, onError).
4. **Optimization**: measure recycle benefit by reusing instances in a list vs creating fresh.

---

## Common Mistakes

- Forgetting `componentDescriptorProvider` registration → component not recognized.
- Casting Props to wrong type → silent default values.
- Doing heavy work in `updateProps` → frame drops.
- Emitting events without `_eventEmitter` null check → crash on unmount.
- Not handling `prepareForRecycle` → stale state across cells.

---

## Production Red Flags

- **`requireNativeComponent('Foo')`** in new code → legacy path under interop.
- **Manual layout in `updateProps`** → races with Fabric's layout pass.
- **Heavy allocations per `updateProps` call** → GC churn.

---

## Performance & Metrics (MANDATORY)

- **FPS**: atomic props + recycling → smoother scrolling.
- **TTI**: lower vs legacy — no shadow-thread roundtrip.
- **Memory**: reuse keeps view count bounded.
- **Bundle**: small (descriptor C++ generated).

---

## Metrics That Matter

- View instance churn (created vs recycled)
- updateProps duration P95
- Mount latency (shadow tree → screen)
- Native event emit rate (don't drown JS)

---

## Decision Framework

| Need | Pick |
|---|---|
| Pure JS UI | RN core components |
| Custom drawing 2D | Skia canvas |
| Native widget surface | Fabric component |
| Legacy code with no Fabric impl yet | Interop with legacy ViewManager (transitional) |
| Cross-platform native UI in C++ | C++ Fabric components |

---

## Senior-Level Insight

The mature take: **Fabric components are first-class citizens of React's reconciliation**. They participate in transitions, suspend correctly, and can be hidden/shown without thrash. Senior engineers design components with: typed events (no `Object` payloads), atomic prop sets (don't fire 5 props that need to apply together as separate calls), and recycling-friendly state (reset in `prepareForRecycle`).

Org-level: pair Fabric component with a TurboModule for control APIs (e.g., `cameraRef.takePhoto()`). Standardize event naming (`onSomethingHappened`, payload `nativeEvent`). Document min RN version supported.

---

## Real-World Scenario

**Symptom:** A custom map component flickers between marker positions during pan.
**Investigation:** JS sets `markers` prop incrementally as data streams in. Each set triggers a full re-render of marker layer.
**Root Cause:** Non-atomic prop application; updateProps ran before all marker data arrived.
**Fix:** Batch markers in JS (collect in state with transition); send single prop update.
**Lesson:** Atomic props at the renderer don't mean atomic logic in your code — batch upstream.

---

## Production Failure Story

**Incident:** A photo-editing app's Fabric image viewer leaked GPU memory, crashing after ~20 large images.
**Impact:** App crashes mid-edit; user data loss.
**Investigation:** `prepareForRecycle` not implemented; recycled views kept references to old `CGImage` backing stores.
**Root Cause:** Recycling without resource reset.
**Fix:** Implement `prepareForRecycle`; release GPU-backed resources; verify with Instruments.
**Prevention:** Lint check for `prepareForRecycle` on Fabric views holding resources; memory soak test in CI.

---

## Debugging Checklist

1. Codegen output exists at expected path.
2. `componentDescriptorProvider` returns the right descriptor.
3. Props casting matches generated type.
4. `_eventEmitter` non-null before emitting.
5. Recycling: `prepareForRecycle` resets state and resources.
6. RN version supports the spec features used (e.g., `DirectEventHandler` shape).

---

## Advanced / Internal Knowledge

- C++ shadow tree is immutable; each commit produces a new tree, diff applied to mounted views.
- `ComponentDescriptor` registers with `ComponentDescriptorProviderRegistry`; multiple modules can extend.
- `RCTViewComponentView` lifecycle: `updateProps`, `updateState`, `updateEventEmitter`, `updateLayoutMetrics`, `finalizeUpdates`, `prepareForRecycle`.
- Yoga handles layout in C++; props affecting layout (width, padding) flow through Yoga before view mount.
- visionOS Fabric adds `entity` / `volumetric` props (2026).

---

## 2026 AI Tip

- AI is **good at**: scaffolding component classes both platforms.
- AI is **bad at**: knowing exact RN version's Fabric API (it churns) — verify against current docs.
- **Prompt pattern**: "Generate a Fabric component `RNRing` with props `color: string`, `progress: float`, event `onRingChange`, full TS spec + iOS RCTViewComponentView + Android SimpleViewManager."

---

## Related Topics

- S4 New Architecture (Fabric internals)
- Q1 TurboModule (control surface pair)
- S3 Skia drawing alternative

---

## Interview Follow-Up Questions

- Why does Fabric apply props atomically?
- What's `prepareForRecycle` for?
- How do you pair a Fabric component with a TurboModule?
- When would you use Skia instead of a Fabric component?
- How does Fabric interact with React 19 transitions?

---

## Memory Hook

**"Spec, descriptor, view, recycle."**

## Revision Notes

> Fabric = New Arch native views. Codegen TS spec → component descriptor + typed events. iOS RCTViewComponentView, Android ViewManager + descriptor registration. Atomic props, recycling, concurrent-safe.

---

---

### Q3. Background tasks across iOS and Android

---

## Difficulty
- Advanced

## Interview Frequency
- Very Common (every app eventually needs background work)

## Prerequisites
- iOS BGTaskScheduler, Android WorkManager basics, JS event loop

## TL;DR
Use **`BGTaskScheduler` + `BGAppRefreshTask` / `BGProcessingTask`** on iOS and **WorkManager** on Android. Each has strict OS-controlled budgets (battery, opportunity, network). RN Headless JS is **[DEPRECATED]** for iOS; use Expo Background Tasks API or `react-native-background-actions` patterns. The hard parts are: (1) limited time, (2) no guaranteed execution, (3) JS engine cold start cost.

---

## 30-Second Interview Answer

> "Background work on mobile is OS-budgeted, not free. iOS gives you `BGAppRefreshTask` (~30s, periodic) and `BGProcessingTask` (longer, requires charging/network constraints). Android uses WorkManager — `OneTimeWorkRequest` or `PeriodicWorkRequest` with `Constraints` (network, charging, idle). Both run native code; if you need JS in background, either spin up a headless RN context (Android) or pre-compute results so native can finish without JS. Common gotchas: iOS won't run if user force-quit, Doze mode delays Android jobs, push notifications are still the right way to wake apps for user-visible events."

---

## 2-Minute Practical Answer

Decision tree:

```
Need to do work when app is closed?
├─ User-visible result needed immediately → Push notification (APNs/FCM)
├─ Periodic sync (e.g., every few hours) → BGAppRefreshTask / PeriodicWorkRequest
├─ Heavy work (download, ML) → BGProcessingTask / OneTimeWorkRequest with constraints
├─ Continuous (audio, navigation) → background mode entitlement / foreground service
└─ Geofence / location → CoreLocation / FusedLocation background updates
```

iOS specifics:
- Register task identifiers in `Info.plist` (`BGTaskSchedulerPermittedIdentifiers`).
- Schedule with `BGTaskScheduler.shared.submit`.
- iOS decides *if and when* to run based on usage patterns (ML model).
- Force-quit by user → no background execution until next foreground launch.
- Time limit ~30s for `BGAppRefreshTask`; minutes for `BGProcessingTask` with constraints.

Android specifics:
- WorkManager handles deferrable, guaranteed-eventual work.
- Constraints: `setRequiredNetworkType`, `setRequiresCharging`, `setRequiresBatteryNotLow`.
- Doze mode batches jobs; expedited work requires user opt-in or specific use case.
- Foreground services for user-visible long-running work (notification required).

JS in background:
- **Android Headless JS** (legacy) still works — spins up an RN instance; expensive cold start.
- **iOS** has no direct equivalent; must do work in native or preload data.
- **Expo TaskManager** + Background Fetch wraps both with a TS API.
- **Better pattern**: do critical state in native (SQLite/Kotlin/Swift); JS only on next foreground.

---

## 5-Minute Architecture Answer

The fundamental tension: users want apps to be "always up to date" but OSes ruthlessly throttle background work to save battery. The mobile contract is:

- **Foreground = unlimited** (within reason).
- **Background = budgeted, scheduled by OS, may not run**.
- **Force-quit = nothing runs** (iOS) or **delayed indefinitely** (Android).

This shapes your architecture:

1. **Critical state must reach the device via push** (APNs/FCM). Polling in background is unreliable.
2. **Background work is opportunistic**: assume it might not run today; design for skip-recovery.
3. **Stateful work must be resumable**: track progress in persistent storage; if killed, resume on next run.
4. **Idempotency**: same job may run multiple times; design accordingly.

iOS BGTaskScheduler architecture:
- Tasks declared in `Info.plist`.
- Registered handlers in `application(_:didFinishLaunchingWithOptions:)`.
- Scheduled with `submit(BGAppRefreshTaskRequest)` after each successful run.
- iOS chooses timing based on user patterns + system load.
- `expirationHandler` fires when time's up — must cancel work and call `setTaskCompleted`.

Android WorkManager architecture:
- Backed by JobScheduler (newer) or AlarmManager (older), depending on API level.
- Persistent across reboots.
- Handles retry with exponential backoff out of the box.
- `CoroutineWorker` for Kotlin coroutines; `Worker` for callable.
- Chained workers for pipelines (`beginWith(a).then(b)`).

The 2026 specific:
- **iOS 17+ `Live Activities`** + `ActivityKit` for foreground-style updates without full background execution.
- **Android 14+ stricter foreground service types** — must declare type (location, dataSync, mediaPlayback…).
- **Expo Background Tasks API** (2025) is the recommended cross-platform RN abstraction.
- **Battery API impact**: foreground tasks count toward "Battery Usage" UI; users can disable per-app background.
- **Privacy Sandbox** on Android adds budget restrictions on background network for ad/measurement contexts.

When NOT to background:
- User-visible chat → push notification with payload.
- Realtime location during navigation → foreground service.
- Quick tasks → defer to next foreground.

---

## The "Why"

Mobile apps run mostly *not* in the foreground. Background work powers: feed prefetching, sync, location-aware reminders, IAP receipt validation, analytics flushing, OTA download. Get this wrong and the app feels stale ("why didn't my messages refresh?") or drains battery ("why is this app at the top of usage?"). Companies care because background reliability is a retention signal.

---

## Mental Model

Background tasks = "leave a note for the OS that says: when convenient, run this code for ≤N seconds, but don't promise me anything." Plan for the OS to say no.

---

## Internal Working (2026 Context)

- **iOS** `BGTaskScheduler` lives in BackgroundTasks framework; registers handlers per task identifier.
- iOS uses an on-device ML model to predict when user opens app; schedules background refresh shortly before.
- **Android** WorkManager picks underlying scheduler (JobScheduler API 23+, AlarmManager + BroadcastReceiver fallback).
- Constraints satisfied → job dispatched to a `WorkerThread`; result stored in WorkManager DB.
- Expedited work uses `setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)` — quota-limited.

JS engine in background:
- **Android Headless JS**: starts a new RN instance (Hermes), runs your registered handler, kills instance. Cold start ~hundreds of ms.
- **iOS**: no JS engine in background unless you keep the app foregrounded.

---

## Modern Implementation (Code)

**iOS — register a refresh task** (in `AppDelegate`):
```swift
import BackgroundTasks

// In didFinishLaunchingWithOptions
BGTaskScheduler.shared.register(
  forTaskWithIdentifier: "com.app.refresh",
  using: nil
) { task in
  self.handleRefresh(task: task as! BGAppRefreshTask)
}

func handleRefresh(task: BGAppRefreshTask) {
  scheduleNextRefresh()  // always reschedule
  let queue = OperationQueue()
  queue.maxConcurrentOperationCount = 1
  let op = SyncFeedOperation()
  task.expirationHandler = { queue.cancelAllOperations() }
  op.completionBlock = { task.setTaskCompleted(success: !op.isCancelled) }
  queue.addOperation(op)
}

func scheduleNextRefresh() {
  let req = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
  req.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
  try? BGTaskScheduler.shared.submit(req)
}
```

In `Info.plist`:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array><string>com.app.refresh</string></array>
<key>UIBackgroundModes</key>
<array><string>fetch</string></array>
```

**Android — WorkManager**:
```kotlin
class SyncFeedWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
  override suspend fun doWork(): Result = try {
    val data = api.fetchFeed()
    db.feedDao().upsert(data)
    Result.success()
  } catch (e: IOException) {
    Result.retry()
  }
}

// schedule (e.g., from app startup)
val request = PeriodicWorkRequestBuilder<SyncFeedWorker>(15, TimeUnit.MINUTES)
  .setConstraints(Constraints.Builder()
    .setRequiredNetworkType(NetworkType.CONNECTED)
    .setRequiresBatteryNotLow(true)
    .build())
  .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
  .build()

WorkManager.getInstance(context).enqueueUniquePeriodicWork(
  "sync-feed", ExistingPeriodicWorkPolicy.KEEP, request
)
```

**Cross-platform via Expo TaskManager**:
```ts
import * as TaskManager from 'expo-task-manager';
import * as BackgroundFetch from 'expo-background-fetch';

const TASK = 'sync-feed';

TaskManager.defineTask(TASK, async () => {
  try {
    await syncFeedFromAPI();
    return BackgroundFetch.BackgroundFetchResult.NewData;
  } catch {
    return BackgroundFetch.BackgroundFetchResult.Failed;
  }
});

// register once at startup
await BackgroundFetch.registerTaskAsync(TASK, {
  minimumInterval: 15 * 60,   // seconds; OS may run less often
  stopOnTerminate: false,     // Android only
  startOnBoot: true,          // Android only
});
```

---

## Comparison

| API | Platform | Best for |
|---|---|---|
| BGAppRefreshTask | iOS | short periodic (≤30s) |
| BGProcessingTask | iOS | long jobs with constraints |
| Live Activities | iOS 17+ | foreground-style updates |
| WorkManager | Android | reliable deferrable jobs |
| Foreground service | Android | continuous user-visible |
| Headless JS [DEPRECATED] | Android | legacy JS in bg |
| Expo TaskManager / BackgroundFetch | both | cross-platform RN ergonomics |
| react-native-background-fetch | both | community alternative |

---

## Production Usage

- **News feed prefetch**: BGAppRefreshTask + WorkManager periodic.
- **Photo upload**: BGProcessingTask (charging) + WorkManager (network).
- **Subscription receipt revalidation**: Background fetch.
- **Geofence triggers**: CoreLocation / FusedLocationProvider with background entitlements.
- **Music/Podcast playback**: foreground service + audio background mode.
- **Navigation**: foreground service (location type).

---

## Hands-On Exercise

1. **Implementation**: implement a "refresh feed every 15 min if battery > 20%" using both native APIs.
2. **Debugging**: task isn't running on iOS — verify Info.plist identifiers, check `_simulateBackgroundFetch` lldb command.
3. **Architecture**: design background sync that survives force-quit (push notification triggers).
4. **Optimization**: heavy ML inference job — use BGProcessingTask with `requiresExternalPower`.

---

## Common Mistakes

- Assuming background runs reliably on a schedule.
- Long sync work without checkpoint → killed mid-flight, restarts from scratch.
- iOS: not rescheduling next task in handler → tasks never run again after first.
- Android: spawning threads outside Worker's coroutine scope → leaks.
- Polling in background instead of push for user-critical events.
- Heavy JS engine spin-up for trivial work (use native).

---

## Production Red Flags

- **No `setTaskCompleted` call on iOS** → task budget reduced; fewer future runs.
- **Indefinite WorkManager retry** without max attempts → battery drain.
- **Background network without observability** → silent failures.
- **Foreground service without notification** (Android 8+) → app killed.

---

## Performance & Metrics (MANDATORY)

- **Battery**: top concern; aggressive bg work → user disables in Settings.
- **TTI of bg job**: cold start native ~tens of ms; with JS engine on Android ~hundreds.
- **Network**: respect metered network constraint.
- **Memory**: bg processes get killed under pressure.

---

## Metrics That Matter

- Background-task execution success rate
- Mean delay between schedule and execution
- Force-quit rate (iOS) — indicates user frustration
- Battery impact (Profile in Xcode / Battery Historian on Android)
- Per-task duration distribution

---

## Decision Framework

| Need | Pick |
|---|---|
| User-visible event | Push notification |
| Periodic sync (≤30s) | BGAppRefreshTask + WorkManager |
| Long sync (charging) | BGProcessingTask + WorkManager constraints |
| Continuous (audio/nav) | Foreground service / background mode |
| Geofence | OS geofence APIs |
| JS-heavy work | Avoid bg; do on next foreground |

---

## Senior-Level Insight

The mature take: **background work is a contract with the OS, not a guarantee**. Senior engineers design for "ran zero times today" as a normal case. They use push notifications for anything user-critical, defer best-effort sync to background, and instrument heavily to understand actual run rates. They also design jobs to be: idempotent, resumable, and bounded in time. They never block on background completion in critical paths.

Org-level: maintain a "background job catalog" — what runs when, who owns it, what budget, what telemetry. Review quarterly for retired jobs.

---

## Real-World Scenario

**Symptom:** Photo backup feature works for ~30% of users; others see "queued" forever.
**Investigation:** WorkManager scheduled with `setRequiredNetworkType(UNMETERED)` — only WiFi. Many users on cellular plans never trigger.
**Root Cause:** Constraint too strict; user expectation didn't match.
**Fix:** Default to CONNECTED; expose user setting for "WiFi only".
**Lesson:** Constraints reflect product decisions; surface them to users.

---

## Production Failure Story

**Incident:** A fitness app's step-sync background job consumed 8% of daily battery for active users.
**Impact:** 1-star reviews citing battery drain; Apple rejected next update for "excessive background activity".
**Investigation:** App scheduled `BGProcessingTask` every 5 minutes, doing CoreMotion + network sync each time.
**Root Cause:** Misuse of `BGProcessingTask` for frequent short work; should have used `BGAppRefreshTask` with longer interval.
**Fix:** Move to `BGAppRefreshTask` every 30+ min; batch step counts; sync on next foreground.
**Prevention:** Battery soak tests in pre-release; alerts on bg execution time.

---

## Debugging Checklist

1. iOS: Xcode lldb `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.refresh"]`.
2. Android: `adb shell dumpsys jobscheduler` to see scheduled jobs.
3. Verify task identifiers match Info.plist.
4. Check OS Settings: Background App Refresh enabled; app not in Low Power Mode restrictions.
5. Telemetry: log start/end of every bg invocation with duration.
6. Test with airplane mode + restored connectivity.

---

## Advanced / Internal Knowledge

- iOS BGTaskScheduler uses Duet (private framework) for usage prediction.
- Android WorkManager DB persists state in `androidx.work.workdb`.
- Doze mode buckets (Android): active, working_set, frequent, rare, restricted — affect job frequency.
- iOS background modes: `audio`, `location`, `voip`, `fetch`, `processing`, `bluetooth-central`, etc.
- Expo TaskManager wraps both with a unified `defineTask` API.

---

## 2026 AI Tip

- AI is **good at**: scaffolding WorkManager / BGTask boilerplate.
- AI is **bad at**: knowing your app's actual budget — don't trust suggested intervals blindly.
- **Prompt pattern**: "Generate iOS BGAppRefreshTask + Android WorkManager with 15-min interval, network-required, retry on failure, in Swift + Kotlin."

---

## Related Topics

- S12 push notifications
- S11 offline sync
- S5 Expo TaskManager

---

## Interview Follow-Up Questions

- Why isn't background guaranteed to run?
- Difference between BGAppRefreshTask and BGProcessingTask?
- When do you use a foreground service vs WorkManager?
- How do you make a bg job resumable?
- Why are push notifications often the right answer?

---

## Memory Hook

**"Push for now, schedule for later, foreground for always."**

## Revision Notes

> Background = OS-budgeted. iOS BGTaskScheduler, Android WorkManager. Push for user-critical. Foreground service for continuous. Idempotent + resumable + bounded.

---

---

### Q4. In-App Purchases — StoreKit 2 + Google Play Billing

---

## Difficulty
- Advanced

## Interview Frequency
- Common (any consumer app with monetization)

## Prerequisites
- Native module basics, async/await, server-side validation concepts

## TL;DR
Use **StoreKit 2** (Swift, async/await) on iOS and **Google Play Billing v6+** on Android. Always **server-side validate** receipts/purchase tokens before granting entitlements. Handle: restore, refunds, family sharing, subscription state changes, grace periods, and the messy "purchase made but app crashed before grant" recovery via transaction observers. Libraries: `react-native-iap` or RevenueCat for cross-platform abstraction.

---

## 30-Second Interview Answer

> "IAP is one of the highest-stakes integrations because money is involved and Apple/Google constantly change the rules. StoreKit 2 (iOS 15+) gives a clean async/await API: products fetched via `Product.products(for:)`, purchase via `product.purchase()`, transaction listener via `Transaction.updates`. Play Billing v6+ has `BillingClient` + `purchasesUpdatedListener`. Three rules: (1) server-side validate every receipt, (2) listen for transactions in a global observer (purchases can come from outside your purchase flow), (3) handle refunds/revocations to remove access. Most teams use RevenueCat or `react-native-iap` to reduce platform divergence."

---

## 2-Minute Practical Answer

The IAP flow:

1. **Fetch products** (SKU IDs configured in App Store Connect / Play Console).
2. **User taps Buy** → call `purchase()` / `launchBillingFlow()`.
3. **System UI** handles auth, payment, family-sharing prompts.
4. **Transaction completes** (or fails / pending).
5. **Validate receipt** with your server, which validates with Apple/Google.
6. **Grant entitlement** server-side; client gets confirmation.
7. **Acknowledge / finish** the transaction (else iOS / Google refunds after a window).

Failure modes you must handle:
- App crashes between purchase and grant → transaction listener picks up on next launch.
- User refunded → server webhook (App Store Server Notifications, Google RTDN) → revoke.
- Family sharing → entitlement may apply to non-purchaser.
- Subscription state changes (upgrade, downgrade, billing retry, grace period) → server is source of truth.
- Restore purchases (legal requirement on iOS) → call StoreKit restore.

Server-side validation is **mandatory**:
- iOS: validate JWS signed transactions with Apple's public keys (StoreKit 2) or `verifyReceipt` (legacy).
- Android: validate `purchaseToken` via Play Developer API.
- Never trust the client to report "I paid".

---

## 5-Minute Architecture Answer

IAP is the most adversarial environment in mobile dev. Bad actors will: replay receipts, jailbreak phones, intercept and modify responses, exploit refund flows, share entitlements illegally. The architecture must assume hostility.

Layers:

1. **Client (RN/native)**: orchestrates UI flow, calls platform APIs, sends receipts to server. Untrusted.
2. **Server**: validates receipts with Apple/Google APIs, persists entitlements per user, exposes "what does this user own" API.
3. **Webhook listener**: handles async events from Apple (App Store Server Notifications V2) and Google (Real-Time Developer Notifications). These are the source of truth for state changes.
4. **Entitlement system**: client queries server (not local cache) for paid feature gates.

State machine for a subscription:
```
purchased → active → (renewing | grace_period | billing_retry | expired | refunded | cancelled)
```
Each transition has a webhook event; server updates DB; client refreshes on next foreground or via push.

Edge cases:
- **Sandbox vs Production**: receipts have different signatures; backend must handle both.
- **Promotional offers**: signed offer payloads; backend must verify signature.
- **Win-back offers** (iOS 18+): re-engage churned subs.
- **Family sharing** (iOS): purchaser ≠ user receiving entitlement; map by `originalTransactionId`.
- **Multiple devices**: same user signs in elsewhere → restore flow.

The 2026 specific:
- **StoreKit 2** is the modern API; older `SKPaymentQueue` is **[DEPRECATED]** for new code (still supported).
- **iOS 18+** Win-Back offers, App Store Connect API for offer signing.
- **Google Play Billing v6+** introduced `ProductDetails` (replacing `SkuDetails`); v7+ added one-time products + subscriptions in unified API.
- **Privacy Manifests** require declaring purchase data usage (NSPrivacyAccessedAPIType).
- **DSA / EU rules** require external payment options for EU apps; design for alternative billing.
- **RevenueCat / Adapty** dominate the cross-platform abstraction market — most teams use one.

---

## The "Why"

IAP is direct revenue. Bugs lose money — either through unhonored purchases (refund storms, support cost, churn) or fraudulent grants (revenue leak). Companies treat IAP as P0 reliability, with on-call rotation and dedicated owners. The platform APIs are arcane and Apple/Google add new requirements every WWDC/I/O — keeping current is a continuous effort.

---

## Mental Model

IAP = a state machine spanning client, OS, store backend, and your server. Your server is the only trustworthy node. Webhooks are your truth feed; client is just UI.

---

## Internal Working (2026 Context)

- **StoreKit 2** uses Swift concurrency; transactions arrive as an `AsyncSequence` (`Transaction.updates`). Each carries a JWS-signed payload your server can verify with Apple's JWKs.
- **Play Billing v6+** uses `BillingClient` + `PurchasesUpdatedListener`; tokens validated via Google Play Developer API (OAuth-protected).
- **Webhooks**: signed JWTs (Apple) or signed POSTs (Google Pub/Sub). Your server authenticates and updates state.
- **Native bridging**: in RN, libs like `react-native-iap` expose JS APIs that wrap StoreKit / Play Billing as TurboModules.

---

## Modern Implementation (Code)

**Cross-platform via `react-native-iap`** (most common in RN):
```ts
import {
  initConnection, getProducts, requestPurchase,
  purchaseUpdatedListener, purchaseErrorListener,
  finishTransaction, type Product,
} from 'react-native-iap';

const SKUS = ['premium_monthly', 'premium_yearly'];

export async function setupIAP() {
  await initConnection();
  const products = await getProducts({ skus: SKUS });

  // global listener — must be registered at app start
  purchaseUpdatedListener(async (purchase) => {
    try {
      const granted = await api.validateAndGrant({
        platform: Platform.OS,
        receipt: purchase.transactionReceipt,
        productId: purchase.productId,
        userId: currentUser.id,
      });
      if (granted) {
        await finishTransaction({ purchase, isConsumable: false });
      }
    } catch (e) {
      // do NOT finish — will retry on next launch
      log.error('iap.grant.failed', e);
    }
  });

  purchaseErrorListener((err) => {
    log.warn('iap.error', err.code, err.message);
  });

  return products;
}

export async function buy(productId: string) {
  await requestPurchase({ sku: productId });   // iOS
  // Android uses skus: [productId]
}
```

**Server-side validation (StoreKit 2)** — pseudo-Node:
```ts
import { verifyAppStoreJWS } from './apple-jws-verifier';

app.post('/iap/validate', async (req, res) => {
  const { platform, receipt, productId, userId } = req.body;
  if (platform === 'ios') {
    const tx = await verifyAppStoreJWS(receipt); // verifies with Apple's JWKs
    if (tx.productId !== productId) return res.status(400).json({ ok: false });
    if (tx.revocationReason) return res.status(409).json({ ok: false });
    await db.entitlements.upsert({
      userId, productId, originalTransactionId: tx.originalTransactionId,
      expiresAt: new Date(tx.expiresDate),
    });
    return res.json({ ok: true });
  }
  if (platform === 'android') {
    const purchase = await playApi.purchases.subscriptionsv2.get({
      packageName: 'com.app',
      token: receipt,
    });
    if (purchase.subscriptionState !== 'SUBSCRIPTION_STATE_ACTIVE') {
      return res.status(409).json({ ok: false });
    }
    await db.entitlements.upsert({
      userId, productId,
      expiresAt: new Date(Number(purchase.lineItems[0].expiryTime)),
    });
    return res.json({ ok: true });
  }
});
```

**Webhook handler** (Apple App Store Server Notifications V2):
```ts
app.post('/webhooks/appstore', express.json(), async (req, res) => {
  const tx = await verifyAppStoreJWS(req.body.signedPayload);
  switch (tx.notificationType) {
    case 'DID_RENEW':       await extendEntitlement(tx); break;
    case 'EXPIRED':         await revokeEntitlement(tx); break;
    case 'REFUND':          await revokeEntitlement(tx); break;
    case 'GRACE_PERIOD_EXPIRED': await revokeEntitlement(tx); break;
  }
  res.sendStatus(200);
});
```

---

## Comparison

| Library / approach | Platforms | Pros | Cons |
|---|---|---|---|
| `react-native-iap` | both | open source, control | manage server validation yourself |
| RevenueCat | both | hosted, dashboards, A/B | vendor lock + cost |
| Adapty | both | similar to RevenueCat | competing offering |
| Native impl per platform | both | full control | most code |
| Expo IAP | Expo | clean DX | depends on Expo lifecycle |

| Aspect | StoreKit 2 (iOS) | Play Billing v6+ (Android) |
|---|---|---|
| Language | Swift, async/await | Kotlin / Java |
| Verification | JWS + Apple JWKs | Play Developer API |
| Webhook | App Store Server Notifications V2 | RTDN via Pub/Sub |
| Restore | `Transaction.currentEntitlements` | `queryPurchasesAsync` |
| Promo offers | signed JWS | offer tokens |

---

## Production Usage

- **Subscriptions**: monthly/yearly with intro offers + trials.
- **Consumables**: coins, lives — must be `consume`d after grant.
- **Non-consumables**: lifetime unlocks.
- **Auto-renewable subs**: most common; complex state machine.
- **Family sharing**: opt-in per product.

---

## Hands-On Exercise

1. **Implementation**: full subscription flow using `react-native-iap` + a mock validation endpoint.
2. **Debugging**: user reports "paid but no premium" — trace from purchase listener → server validate → entitlement record.
3. **Architecture**: design refund handling end-to-end (Apple webhook → revoke → notify user).
4. **Testing**: sandbox accounts, Apple's `transaction.test()` API, Google's license testers.

---

## Common Mistakes

- Granting entitlement client-side without server validation → instant fraud.
- Not registering purchase listener globally → missing transactions when app launched outside purchase flow.
- Calling `finishTransaction` before granting entitlement → if grant fails, no retry.
- Ignoring refund webhooks → users keep access after refund.
- Sandbox receipts treated as fraudulent in prod (handle both signatures).
- Forgetting "Restore Purchases" button (iOS App Review will reject).

---

## Production Red Flags

- **Local file flag for premium status** → trivial to bypass.
- **No webhook integration** → no refund handling.
- **Ignoring `pending` purchase state** (Android) → broken UX for slow payments.
- **No telemetry on validation failures** → silent revenue loss.

---

## Performance & Metrics (MANDATORY)

- **Purchase latency**: dominated by store + payment auth; ~seconds.
- **Validation latency**: <500ms ideal; cache JWKs.
- **Webhook lag**: typically seconds; design for eventual consistency.
- **Battery / memory**: nil.

---

## Metrics That Matter

- Purchase success rate (UI initiated → entitlement granted)
- Validation failure rate (by reason)
- Pending → completed conversion (Android)
- Refund rate
- Entitlement-active accuracy (vs store ground truth)

---

## Decision Framework

| Need | Pick |
|---|---|
| Single product, simple | `react-native-iap` direct |
| Multiple platforms + analytics | RevenueCat / Adapty |
| Custom paywall A/B testing | RevenueCat / Adapty |
| Full control + scale | Native + own server |
| Web payments parity | Stripe parallel for web; sync entitlements |

---

## Senior-Level Insight

The mature take: **server is the source of truth**. The client UI is a presentation of server state. Webhooks update server; client polls / receives push to refresh UI. Senior engineers: (1) design entitlement system as a separate microservice with its own SLA, (2) use idempotency keys for grant ops, (3) handle the four main states (active, trialing, in_grace, expired) explicitly, (4) maintain a refund / chargeback runbook.

Org-level: dedicated IAP/monetization on-call rotation; sandbox dashboards; receipt-validation alerts; quarterly Apple/Google API change review.

---

## Real-World Scenario

**Symptom:** ~3% of paid users complain "I lost premium" after force-quitting during purchase.
**Investigation:** Purchase completes on store side, but app crashed before sending receipt to server. Next launch, no entitlement.
**Root Cause:** No global transaction listener; receipt only checked in purchase-flow callback.
**Fix:** Register `Transaction.updates` listener at app start; replays unfinished transactions.
**Lesson:** Transaction listeners must be global and persistent, not per-screen.

---

## Production Failure Story

**Incident:** A productivity app's annual subscription renewals failed for ~15% of users in one billing cycle. Users charged but app showed expired.
**Impact:** $200k MRR at risk; mass refund support tickets; App Store complaint trend.
**Investigation:** Webhook handler crashed on a new `notificationType` Apple introduced (`PRICE_INCREASE_CONSENT`). Crash silently swallowed; subsequent webhooks queued behind it.
**Root Cause:** No default branch on switch; no DLQ for failed webhooks.
**Fix:** Default branch logs unknown types but acks; add DLQ; alert on unknown types so they're handled before becoming critical.
**Prevention:** Subscribe to Apple developer release notes; staging env replays sandbox webhooks.

---

## Debugging Checklist

1. Verify SKU IDs match store config.
2. Check device signed into sandbox account (iOS) / license tester (Android).
3. Server logs: validation success/fail per receipt.
4. Webhook delivery logs (Apple/Google dashboards).
5. Entitlement DB: latest record per user.
6. Test refund via App Store Connect / Play Console.

---

## Advanced / Internal Knowledge

- StoreKit 2 transaction JWS = JWS with header containing certs; validate against Apple's root.
- App Store Server API (REST): query transaction history, force renewal status, refund.
- Play RTDN delivered via Cloud Pub/Sub topic; subscribe via push or pull.
- Sandbox subs accelerate (1 mo = 5 min) for testing.
- iOS 18+ Win-Back offers signed via App Store Connect API.

---

## 2026 AI Tip

- AI is **good at**: scaffolding listener boilerplate.
- AI is **bad at**: knowing latest webhook types or signed-offer signing.
- **Hallucination risk**: outdated API names (SKProductsRequest vs Product.products).
- **Prompt pattern**: "Implement IAP with react-native-iap including global transaction listener, server-side validation flow, and refund webhook handler."

---

## Related Topics

- S10 Auth (entitlements per user)
- S22 system design (subscription service)
- S30 privacy (purchase data declaration)

---

## Interview Follow-Up Questions

- Why must the listener be global?
- When do you call `finishTransaction`?
- How do you handle a refund?
- What's the role of server-side validation?
- How does family sharing affect your data model?

---

## Memory Hook

**"Listen globally, validate server-side, webhook for truth."**

## Revision Notes

> StoreKit 2 + Play Billing v6+. Global transaction listener. Server-side validate every receipt. Webhooks are source of truth. Handle refunds, restore, family sharing. Use RevenueCat to reduce platform divergence.

---

---

### Q5. VisionCamera v3+ frame processors with worklets

---

## Difficulty
- Advanced

## Interview Frequency
- Niche but high-impact (camera/CV-heavy apps)

## Prerequisites
- Reanimated worklets, JSI, basic image processing

## TL;DR
**VisionCamera v3+** combines a Fabric camera component with a TurboModule control surface, plus a **frame processor** API that runs JS-callable code on every camera frame using **Reanimated worklets** on a dedicated thread. Plugins (ML Kit, OCR, barcode, custom C++) bind via JSI. The trick is doing **as little work as possible per frame** and pushing heavy ops to native.

---

## 30-Second Interview Answer

> "VisionCamera v3 is the modern RN camera. The architecture is a Fabric component for the preview surface and a TurboModule for control APIs (capture, focus, format). Per-frame processing uses a 'frame processor' — a worklet that runs on a dedicated frame-processor thread (not JS thread), getting each `Frame` reference. You wire ML Kit, OCR, barcode, or custom C++ plugins as Frame Processor Plugins, registered via JSI. Performance is brutal: at 30fps you have ~33ms per frame. Use `runAtTargetFps`, downscale before processing, and keep heavy work in native plugins."

---

## 2-Minute Practical Answer

VisionCamera architecture:

- **`<Camera>`** — Fabric component rendering preview surface, lifecycle on Camera HW.
- **Camera control TurboModule** — `Camera.requestPermissions()`, `useCameraDevice()`, `Camera.takePhoto()`, format selection.
- **Frame Processor** — JS-defined worklet, runs per-frame on dedicated thread.
- **Frame Processor Plugins** — native (Swift/Kotlin/C++) functions exposed to worklets via JSI.

Frame processor pattern:
```ts
const frameProcessor = useFrameProcessor((frame) => {
  'worklet';
  const codes = scanQRCodes(frame);   // plugin call (sync, on FP thread)
  if (codes.length) runOnJS(setCodes)(codes);
}, []);
```

Constraints:
- Frame processor runs on a **separate native thread** (not JS, not UI).
- All code inside the worklet must be `'worklet'` — Reanimated lifts it to the worklet runtime.
- Crossing back to JS uses `runOnJS` (cheap-ish, batched).
- Frames must not be retained (they're recycled) — copy data if you need it later.

Performance budget at 30fps: ~33ms per frame. Realistic budget: ≤10ms for processing to leave headroom for preview, encoding, and other work.

---

## 5-Minute Architecture Answer

The traditional camera integration in RN was painful: legacy bridge serialized frames or didn't expose them at all; ML inference had to happen in native modules with custom queues. VisionCamera v3+ rebuilt this on the New Architecture:

1. **Fabric preview**: native `AVCaptureVideoPreviewLayer` (iOS) / `PreviewView` (Android) wrapped as a Fabric component. Atomic prop application (zoom, format) ensures consistency.
2. **TurboModule control**: sync calls for cheap ops (get devices, get formats), async for capture (photo, video).
3. **Frame Processor runtime**: a dedicated JSI runtime running Reanimated worklets. Each camera frame is wrapped as a `Frame` JSI HostObject and handed to the worklet.
4. **Plugin system**: Swift/Kotlin/C++ functions registered via JSI under a global; worklet calls them like JS functions, returning JS-compatible results.

Why this matters:
- **Throughput**: no JSON serialization of frame data (native pixels stay native).
- **Latency**: synchronous plugin calls — worklet awaits result inline.
- **Decoupling**: JS thread free to handle UI; FP thread free to chew on frames.
- **Composability**: chain plugins (decode QR, then look up product, then overlay).

Threading model:
```
[Camera Hardware] → [FP thread: worklet + plugins] → [native callback]
                                            └─ runOnJS → [JS thread: state update]
                                            └─ runOnUI → [UI thread: animation]
```

Performance levers:
- **`runAtTargetFps(N, ...)`**: process every Nth frame (10fps for QR, 5fps for face landmarks).
- **`pixelFormat`**: `yuv` is faster than `rgb`; some plugins prefer one.
- **Resize plugin**: downscale frames before ML inference (massive speedup).
- **GPU plugins** (Skia, Metal, Vulkan): do work on GPU.
- **Sample buffers**: reuse where possible.

The 2026 specific:
- VisionCamera v4 (2025+) added Skia frame processors — draw overlays on the preview using Skia.
- Apple Vision integration for iOS 18+ live ML inference.
- Android's `CameraX` Camera2 mode preferred for low-end devices.
- visionOS camera APIs are different (mixed reality) — VisionCamera doesn't yet target.

When NOT to use frame processors:
- Static analysis (one-shot photo) → just use `takePhoto` and process on native.
- Simple recording → use `startRecording` only.

---

## The "Why"

Camera-driven UX powers: scanners (QR, barcode, OCR), AR effects, face unlock, document capture, AR shopping, AR navigation. The best implementations look magic; the worst look like a slideshow. VisionCamera with frame processors is the only mainstream RN solution that consistently hits 30fps with on-device CV. Companies care because camera UX is a competitive moat for many product categories.

---

## Mental Model

Camera frames are a firehose. You can either drink (let them all through) and choke, or sip (downsample + plugin) and stay fluid. The plumbing decides whether you can sip without losing the experience.

---

## Internal Working (2026 Context)

- iOS: `AVCaptureSession` + `AVCaptureVideoDataOutput` delivers `CMSampleBuffer`s on a serial dispatch queue.
- Android: `CameraX` `ImageAnalysis` use case delivers `ImageProxy`s on a worker thread.
- Frame Processor runtime: a separate Hermes JSI runtime; Reanimated installs worklets there.
- `Frame` is a HostObject wrapping the platform frame buffer; properties like `width`, `height`, `pixelFormat` are sync getters.
- Plugins register under `globalThis.<pluginName>` in the FP runtime; worklets call them.

---

## Modern Implementation (Code)

**Setup**:
```bash
npm i react-native-vision-camera react-native-worklets-core
```

**Permissions + simple camera**:
```tsx
import { Camera, useCameraDevice, useCameraPermission } from 'react-native-vision-camera';

function CameraScreen() {
  const device = useCameraDevice('back');
  const { hasPermission, requestPermission } = useCameraPermission();
  if (!hasPermission) return <Button title="Grant" onPress={requestPermission} />;
  if (!device) return <ActivityIndicator />;
  return <Camera style={StyleSheet.absoluteFill} device={device} isActive />;
}
```

**Frame processor with QR scanner plugin**:
```tsx
import { Camera, useCameraDevice, useFrameProcessor } from 'react-native-vision-camera';
import { useState } from 'react';
import { runOnJS } from 'react-native-worklets-core';
import { scanCodes } from 'vision-camera-code-scanner';   // hypothetical plugin

export function QRScanner() {
  const device = useCameraDevice('back');
  const [code, setCode] = useState<string | null>(null);

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    const codes = scanCodes(frame, ['qr']);   // sync plugin call on FP thread
    if (codes.length) {
      runOnJS(setCode)(codes[0].value);
    }
  }, []);

  if (!device) return null;
  return (
    <>
      <Camera style={StyleSheet.absoluteFill} device={device} isActive frameProcessor={frameProcessor} />
      {code && <Banner text={code} />}
    </>
  );
}
```

**Throttled processor**:
```ts
import { runAtTargetFps } from 'react-native-vision-camera';

const frameProcessor = useFrameProcessor((frame) => {
  'worklet';
  runAtTargetFps(5, () => {
    'worklet';
    const codes = scanCodes(frame, ['qr']);
    if (codes.length) runOnJS(setCode)(codes[0].value);
  });
}, []);
```

**Custom Frame Processor Plugin (iOS Swift)**:
```swift
import VisionCamera

@objc(MyResizePlugin)
public class MyResizePlugin: FrameProcessorPlugin {
  public override func callback(_ frame: Frame, withArguments args: [AnyHashable: Any]?) -> Any? {
    let target = args?["size"] as? CGFloat ?? 320
    // resize CMSampleBuffer to target × target...
    return ["w": target, "h": target]
  }
}

// Register in your AppDelegate / Module init:
FrameProcessorPluginRegistry.addFrameProcessorPlugin("resize") { proxy, options in
  MyResizePlugin(proxy: proxy, options: options)
}
```

**Use the plugin from JS**:
```ts
import { VisionCameraProxy } from 'react-native-vision-camera';
const plugin = VisionCameraProxy.initFrameProcessorPlugin('resize', {});

const frameProcessor = useFrameProcessor((frame) => {
  'worklet';
  const small = plugin.call(frame, { size: 320 });
  // ... feed to ML model
}, []);
```

---

## Comparison

| Library | Status | Best for |
|---|---|---|
| `react-native-vision-camera` v3+ | active, modern | new builds, frame processing |
| `expo-camera` | Expo-managed | basic capture, no per-frame access |
| Legacy `react-native-camera` | [DEPRECATED] | avoid |
| `react-native-mlkit` plugins | active | OCR, face, barcode |

| Frame work location | Pros | Cons |
|---|---|---|
| Worklet only (JS-ish) | quick prototypes | bound by JS engine speed |
| Native plugin sync | fastest path | requires native code |
| GPU (Skia, Metal) | parallel, big lifts | complex |
| Send to JS via `runOnJS` per frame | simple | drops frames easily |

---

## Production Usage

- **Document scanners** (CamScanner-like apps).
- **QR/barcode payments**.
- **Face filters / AR**.
- **OCR** for receipts, IDs.
- **Live translation** of camera input.
- **Inventory** (barcode + lookup).

---

## Hands-On Exercise

1. **Implementation**: build a QR scanner that detects, vibrates, displays the code with `runAtTargetFps(10)`.
2. **Debugging**: frame processor doesn't run — check Reanimated/worklets-core installed and `babel-plugin` configured.
3. **Architecture**: design face-effects pipeline (detect → landmarks → render via Skia overlay).
4. **Optimization**: measure FPS impact of plugin; downscale before ML; profile with Xcode Instruments.

---

## Common Mistakes

- Forgetting `'worklet'` directive → runs on JS thread, drops frames.
- Holding Frame references beyond callback → crash (frame recycled).
- `runOnJS` per frame for high-frequency events → JS thread overload.
- No fps throttling for expensive plugins → 5fps preview feels broken.
- Synchronous heavy work in worklet → blocks frame delivery.
- Wrong pixel format for plugin → conversion overhead.

---

## Production Red Flags

- **No `runAtTargetFps`** for non-trivial plugins → battery + thermal throttling.
- **Plugin allocations per frame** → GC churn.
- **JS state updated per frame** → ridiculous re-render storm.
- **No fallback when permission denied** → black screen.

---

## Performance & Metrics (MANDATORY)

- **FPS**: target 30; measure dropped frames.
- **CPU**: keep <40% sustained to avoid thermal throttling.
- **Battery**: camera + ML is one of the heaviest workloads.
- **Memory**: avoid per-frame allocations; reuse buffers.
- **Thermal**: long sessions warm device; users notice.

---

## Metrics That Matter

- Frames processed per second (vs camera FPS)
- Plugin call P95 duration
- `runOnJS` callback rate
- Permission grant rate
- Time-to-first-detect (TTFD)

---

## Decision Framework

| Need | Pick |
|---|---|
| Capture only | `expo-camera` |
| Per-frame analysis | VisionCamera v3+ |
| GPU effects | VisionCamera + Skia FP |
| ML inference | VisionCamera + ML Kit / TFLite plugin |
| AR effects | VisionCamera + ARKit/ARCore native |

---

## Senior-Level Insight

The mature take: **frame processing is a budget problem**. You have ~33ms per frame at 30fps; preview, encode, plugin, and any callback to JS all share that budget. Senior engineers profile end-to-end (Camera HW → preview → plugin → callback) and know exactly where the milliseconds go. They prefer native plugins for any non-trivial work, downscale aggressively before ML, and design product flows that tolerate lower FPS during heavy analysis.

Org-level: own a small library of internal Frame Processor Plugins (resize, color convert, face detect) shared across apps. Standardize permission/UX flows.

---

## Real-World Scenario

**Symptom:** QR scanner works but preview drops to ~10fps making it feel laggy.
**Investigation:** Frame processor calls plugin every frame; plugin downscales + decodes inline. Plugin takes ~80ms per frame.
**Root Cause:** Running a 100ms plugin at 30fps is impossible.
**Fix:** `runAtTargetFps(10, ...)` for the plugin; preview stays smooth at 30fps; QR detection still feels instant.
**Lesson:** Frame processor frequency ≠ camera frequency. Throttle.

---

## Production Failure Story

**Incident:** A receipt-scanning app caused devices to overheat and shut down camera mid-session. ASO ratings tanked.
**Impact:** Major retail chain pulled the white-label version; revenue hit.
**Investigation:** OCR plugin running at 30fps on full-resolution frames; CPU pegged at 95%; thermal throttle triggered then thermal shutdown.
**Root Cause:** No throttling, no downscale, no thermal-state monitoring.
**Fix:** `runAtTargetFps(3)`, downscale to 800×600 before OCR, monitor `ProcessInfo.thermalState` (iOS) and pause processing on `.serious`.
**Prevention:** Thermal soak tests on low-end devices; battery budget per feature.

---

## Debugging Checklist

1. `babel.config.js` includes `react-native-reanimated/plugin` (last position).
2. `react-native-worklets-core` installed and linked.
3. Permission granted (iOS Info.plist `NSCameraUsageDescription`, Android manifest).
4. `useCameraDevice('back')` returns non-null on test device.
5. Frame processor: log inside worklet (use `console.log` — works with worklets-core).
6. Profile in Xcode/Android Studio: check FP thread CPU, frame drop counters.

---

## Advanced / Internal Knowledge

- VisionCamera FP runtime is a separate Hermes runtime; plugins registered via JSI in that runtime.
- Reanimated 3+ is the worklet engine; v4 (2025+) added improved scheduler.
- Skia frame processors render into the preview overlay using shared GPU context.
- ML Kit on Android uses native NNAPI / GPU delegate when available.
- iOS Vision framework (`VNRequest`) integrates well — wrap as plugin.

---

## 2026 AI Tip

- AI is **good at**: scaffolding camera + frame processor boilerplate.
- AI is **bad at**: native plugin code (FP plugin registration syntax churns).
- **Prompt pattern**: "Implement a VisionCamera v3+ QR scanner with frame processor throttled to 10fps and `runOnJS` callback to update React state."

---

## Related Topics

- S3 Reanimated worklets
- Q1 TurboModule (control surface)
- Q2 Fabric components

---

## Interview Follow-Up Questions

- Why does the frame processor run on a separate thread?
- What's the cost of `runOnJS` per frame?
- How do you avoid thermal throttling?
- Why must you not retain `Frame` references?
- How would you integrate ML Kit?

---

## Memory Hook

**"Worklet thread, throttle FPS, downscale early, native plugins."**

## Revision Notes

> VisionCamera v3+: Fabric preview + TurboModule control + Frame Processor (Reanimated worklet). Plugins via JSI. Throttle with `runAtTargetFps`. Downscale before ML. Don't retain frames. Mind thermal.

---

> **End of S15.** Cross-refs: S4 (New Arch internals), S5 (Expo Modules API), S3 (Reanimated, Skia), S7 (perf budgets), S30 (privacy declarations). Next deep section: [S10 Auth & Security](S10-auth-security.md).
