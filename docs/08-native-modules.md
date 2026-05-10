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

