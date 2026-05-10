## 8. Native modules (Swift + Kotlin)

### When to write your own
- No community module exists.
- Existing one is unmaintained or missing platform.
- Need access to a private/new platform API.
- Performance-sensitive bridge crossing.

### Old NativeModule pattern (still asked)
**iOS (Swift)**:
```swift
@objc(BatteryModule)
class BatteryModule: NSObject {
  @objc func getLevel(_ resolve: @escaping RCTPromiseResolveBlock,
                      reject: @escaping RCTPromiseRejectBlock) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    resolve(UIDevice.current.batteryLevel)
  }
  @objc static func requiresMainQueueSetup() -> Bool { return false }
}
```
Plus an `.m` file with `RCT_EXTERN_MODULE` + `RCT_EXTERN_METHOD`.

**Android (Kotlin)**:
```kotlin
class BatteryModule(ctx: ReactApplicationContext): ReactContextBaseJavaModule(ctx) {
  override fun getName() = "BatteryModule"
  @ReactMethod
  fun getLevel(promise: Promise) {
    val bm = reactApplicationContext.getSystemService(BATTERY_SERVICE) as BatteryManager
    promise.resolve(bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY))
  }
}
```
Register in a `ReactPackage`.

### TurboModule (new arch)
- Define TS spec → Codegen produces C++/ObjC/Java interfaces.
- Implement the generated protocol/interface.
- Lazy-loaded via JSI on first JS access.

### Threading
- iOS: by default runs on a serial background queue; override `methodQueue` for main thread.
- Android: runs on the native modules thread; use `UiThreadUtil.runOnUiThread` for UI work.

### Return patterns
- **Promise**: `resolve(...)` / `reject(...)`.
- **Callback**: legacy; one-shot.
- **Event Emitter** (`RCTEventEmitter` / `DeviceEventManagerModule`): for streams/subscriptions.

### Must-answer questions
1. When to write a native module instead of using a community one.
2. Walk through writing a battery module on both platforms.
3. How to emit events native → JS.
4. Threading — what runs where, by default.
5. Promise vs callback vs event emitter — when each.

---



---

## Top 25 Q&A — Native modules (Swift + Kotlin)

### 1. When do you reach for a native module?
When RN doesn't expose the API: biometrics, NFC, secure enclave, BLE, custom camera, payment SDK, native UI kit.

### 2. Old vs new arch native module?
Old: `RCTBridgeModule` (iOS), `ReactContextBaseJavaModule` (Android), reflective + async bridge. New: TurboModule via JSI + codegen from TS spec.

### 3. Steps to write a TurboModule.
(1) Author TS spec `NativeFoo.ts`. (2) Codegen via `react-native codegen`. (3) Implement Spec class in Swift/Kotlin. (4) Register in package. (5) Consume from JS.

### 4. Swift module skeleton.
```swift
@objc(Biometric)
class Biometric: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool { false }
  @objc func authenticate(_ reason: String,
                          resolver resolve: @escaping RCTPromiseResolveBlock,
                          rejecter reject: @escaping RCTPromiseRejectBlock) {
    // LAContext().evaluatePolicy ...
  }
}
```
Plus `Biometric.m` bridge file for old arch.

### 5. Kotlin module skeleton.
```kotlin
class BiometricModule(reactContext: ReactApplicationContext)
  : ReactContextBaseJavaModule(reactContext) {
  override fun getName() = "Biometric"
  @ReactMethod
  fun authenticate(reason: String, promise: Promise) { /* BiometricPrompt */ }
}
```

### 6. Threading rules?
Native modules run on a dedicated module queue by default. UI code → main thread. Long work → background queue. Don't block JS thread response.

### 7. Promise vs callback?
Promise (resolve/reject) — preferred, integrates with `await`. Callbacks legacy + can only be invoked once.

### 8. Sending events to JS.
Old arch: `RCTEventEmitter` (iOS) / `DeviceEventEmitter` (Android). New arch: TurboModule events spec.

### 9. View component (native UI) vs module?
Module = pure functions. View = native UI rendered in tree (`RCTViewManager` / `SimpleViewManager`). Use Fabric component for new arch.

### 10. Interop with existing native screen.
Wrap `UIViewController`/`Activity` and embed via `react-native-screens` or expose as a Fabric component.

### 11. Codegen TS spec example.
```ts
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
export interface Spec extends TurboModule {
  readonly getConstants: () => { version: string };
  multiply(a: number, b: number): number; // sync via JSI
}
export default TurboModuleRegistry.getEnforcing<Spec>('Calc');
```

### 12. Sync vs async TurboModule call?
JSI allows sync return for primitives. Use sync only for fast ops; promises for I/O.

### 13. iOS: `requiresMainQueueSetup` — when true?
When module needs to access UIKit APIs at init time. Otherwise return `false` (perf).

### 14. Android: how to expose constants?
`override fun getConstants(): Map<String, Any> = mapOf("version" to "1.0")`.

### 15. Permissions handling — pattern.
Request via `react-native-permissions` (Android `Manifest.permission.*`, iOS `Info.plist` keys). Always check + request before native API.

### 16. Crash from native module to JS — how surfaced?
Reject promise with `code` + `message`. JS gets `Error` with `code` property. Add to Sentry/Crashlytics native side too.

### 17. How to test native modules?
JS-side: mock module via `jest.mock('react-native', ...)`. Native-side: XCTest / JUnit on the impl, integration with Detox.

### 18. Common pitfall: module not registering.
Forgot `RCT_EXPORT_MODULE()` (iOS), forgot `Package.createNativeModules` registration (Android), or new-arch codegen not regenerated.

### 19. Local development workflow.
Use `react-native-create-library` or `bob` for scaffolding. Symlink with `npm link` / `yarn link` or use `react-native-local-libraries`.

### 20. Publishing to npm.
Build with `bob` (compiles TS + types). Include `ios/`, `android/`, `cpp/`, `*.podspec`, `package.json` `react-native` field.

### 21. Podspec key fields.
`name`, `version`, `source`, `source_files`, `dependency 'React-Core'`, swift_version, codegen config.

### 22. Android `build.gradle` essentials for module.
`android { compileSdkVersion ...; }`, `dependencies { implementation 'com.facebook.react:react-native:+' }`, kotlin plugin if Kotlin.

### 23. Bridging Swift class to RN.
Swift class must inherit `NSObject` + `@objc` exposed methods. Include `-Bridging-Header.h` if mixing.

### 24. Worklets calling native module?
Reanimated worklets can call selected functions via `runOnJS` for normal modules; for true UI-thread native call, use Fabric component or JSI host object.

### 25. Real example: secure storage TurboModule (signature).
```ts
export interface Spec extends TurboModule {
  setItem(key: string, value: string, accessGroup?: string): Promise<void>;
  getItem(key: string): Promise<string | null>;
  deleteItem(key: string): Promise<void>;
}
```
iOS uses Keychain Services; Android uses EncryptedSharedPreferences + Keystore.
