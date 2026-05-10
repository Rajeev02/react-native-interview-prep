# S13 — Android + Kotlin

> Activity lifecycle · Coroutines & Flow · WorkManager · Compose interop · Predictive Back · R8/ProGuard · Gradle/AGP

For RN engineers in 2026, **Kotlin fluency** is table stakes for senior interviews. You won't be asked to write apps in pure Kotlin, but you must speak the Activity lifecycle, structured concurrency, WorkManager, Compose↔Fabric interop, predictive back, and R8 minification. This section gives you the five rounds.

---

### Q1. Activity lifecycle — and how RN slots into it

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Common (Android-leaning rounds)

## Prerequisites
- Activity / Fragment basics

## TL;DR
Android Activity lifecycle: **onCreate → onStart → onResume → onPause → onStop → onDestroy** (+ onRestart). RN apps run inside one **MainActivity** hosting a **ReactRootView** (or Bridgeless `ReactSurface`). RN listens to lifecycle via `ReactInstanceManager` (Old Arch) or `ReactHost` (New Arch / Bridgeless): `onHostResume / onHostPause / onHostDestroy` propagate to JS via `AppState`. Configuration changes (rotation, dark mode) recreate Activity unless `configChanges` declared. Background work survives via WorkManager + foreground services.

---

## 30-Second Interview Answer

> "Android Activity has six callbacks: onCreate, onStart, onResume, onPause, onStop, onDestroy. RN apps host a single MainActivity with a ReactSurface (Bridgeless) or ReactRootView (legacy). The host bridges Activity lifecycle to JS via `ReactHost.onHostResume/Pause/Destroy`, which surfaces in JS as `AppState`. Configuration changes recreate the Activity by default — handle via `android:configChanges` or save-state. Background work uses WorkManager for guaranteed execution and Foreground Service (Android 14+ requires declared service type)."

---

## 2-Minute Practical Answer

**Lifecycle states**:
- `onCreate`: one-time setup, inflate view, attach RN.
- `onStart`: visible (not yet interactive).
- `onResume`: foreground + interactive.
- `onPause`: losing focus (other Activity launching).
- `onStop`: no longer visible.
- `onDestroy`: removed (memory pressure or `finish()`).
- `onRestart`: from stopped → started.

**RN integration (Bridgeless / New Arch)**:
```kotlin
class MainActivity : ReactActivity() {
  override fun getMainComponentName(): String = "MyApp"
  override fun createReactActivityDelegate(): ReactActivityDelegate =
    DefaultReactActivityDelegate(
      this, mainComponentName, fabricEnabled = true
    )
}

class MainApplication : Application(), ReactApplication {
  override val reactNativeHost: ReactNativeHost by lazy {
    DefaultReactNativeHost(
      this,
      packages = PackageList(this).packages,
      fabricEnabled = true,
      bridgelessEnabled = true,
    )
  }
}
```

**JS sees lifecycle as AppState**:
```ts
import { AppState } from 'react-native';
useEffect(() => {
  const sub = AppState.addEventListener('change', (s) => {
    // 'active' | 'background' | 'inactive'
  });
  return () => sub.remove();
}, []);
```

**Config changes** (rotation, dark mode, locale):
```xml
<activity
  android:name=".MainActivity"
  android:configChanges="keyboard|keyboardHidden|orientation|screenSize|smallestScreenSize|screenLayout|uiMode" />
```
Without these, Activity recreated — RN handles internally but custom native modules may need state save.

**`onSaveInstanceState`**:
- For native UI state.
- RN apps usually rely on JS state (Redux/Zustand/MMKV) instead.

**Process death**:
- Android may kill process when backgrounded under memory pressure.
- On relaunch: cold start, JS bundle reloaded.
- Persist via MMKV / encrypted storage.

---

## 5-Minute Architecture Answer

Activity vs Application vs Process:
- **Process**: OS process (one per app usually).
- **Application**: subclass extends `Application` → singleton lifecycle.
- **Activity**: a screen / entry point.
- RN apps: 1 process, 1 Application (`MainApplication`), typically 1 Activity (`MainActivity`).

Multi-Activity in RN:
- Possible but uncommon (e.g., separate activities for Auth vs Main).
- Each Activity hosts its own ReactSurface — separate JS contexts unless sharing ReactHost.
- Brownfield apps embed RN inside specific Activities.

Fragment lifecycle:
- Modern Android prefers single Activity + Fragments / Compose Navigation.
- For RN: JS-side navigation (Expo Router / React Navigation) replaces Fragment nav.
- Brownfield: RN Fragment via `ReactFragment`.

Bridgeless mode (New Arch default 2026):
- `ReactHost` replaces `ReactInstanceManager`.
- Better lifecycle handling, no bridge.
- Multi-surface support.

Configuration changes deep dive:
- Default: Activity recreated → onSaveInstanceState → onPause → onStop → onDestroy → new Activity.
- With `configChanges`: `onConfigurationChanged` called instead.
- RN handles internally via `ReactDelegate.onConfigurationChanged`.

Process death scenario:
- User backgrounds app.
- Memory pressure → OS kills process.
- User returns to app → cold start.
- AppState skips through 'inactive' → 'active'.
- Persist critical state to disk.

Foreground services (Android 14+):
- Must declare `foregroundServiceType` in manifest.
- Types: `dataSync`, `mediaPlayback`, `location`, `phoneCall`, `connectedDevice`, `mediaProjection`, `camera`, `microphone`, `health`, `remoteMessaging`, `shortService`, `specialUse`, `systemExempted`.
- Mismatch with declared use → crashes / Play rejection.

Doze + App Standby:
- Doze: device idle for extended period → defers background work.
- App Standby: app unused → buckets (active, working_set, frequent, rare, restricted).
- WorkManager respects.

The 2026 specific:
- **Predictive Back** (Android 14+; mandatory 16+).
- **Foreground service types** strict.
- **Notification permission** runtime since 13.
- **Photo Picker** preferred over storage permission.
- **Bridgeless ReactHost** stable.

Brownfield integration:
- Existing Kotlin app embeds RN as Fragment.
- ReactRootView mounted in XML / Compose.
- Lifecycle bridged to ReactInstanceManager/ReactHost.
- Communication: emit events JS↔Kotlin via TurboModules.

---

## The "Why"

Lifecycle awareness = stability. Crashes during config change, leaks in background, ANRs in onResume — all interview red flags.

---

## Mental Model

Activity = stage. Lifecycle = curtain calls. RN listens via host, maps to AppState. Config changes = stage rotation. Process death = theater closes.

---

## Internal Working (2026 Context)

- ReactHost owns ReactInstance lifecycle.
- ReactDelegate forwards Activity callbacks.
- AppState in JS reflects host state.

---

## Modern Implementation (Code)

**Custom MainActivity hooks**:
```kotlin
class MainActivity : ReactActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(null)  // NOTE: pass null; RN handles state
    SplashScreen.setKeepOnScreenCondition { !appReady }
  }

  override fun onResume() {
    super.onResume()
    Analytics.startSession()
  }
}
```

**Detect process death**:
```ts
useEffect(() => {
  const wasColdStart = await mmkv.getBoolean('was-warm') === false;
  mmkv.set('was-warm', true);
  if (wasColdStart) Analytics.track('cold_start');
}, []);
```

---

## Comparison

| Mode | Host class | RN version |
|---|---|---|
| Old Arch | ReactInstanceManager | < 0.74 default |
| New Arch | ReactHost | 0.76+ default |

---

## Production Usage

- Single Activity standard.
- Multi-Activity rare (auth split, brownfield).

---

## Hands-On Exercise

1. Add config change handling.
2. Detect cold start vs warm.
3. Persist critical state across process death.
4. Brownfield: embed RN Fragment.

---

## Common Mistakes

- Calling super.onCreate(savedInstanceState) (RN docs prefer null).
- Missing configChanges declaration.
- Long work in onResume (ANR risk).

---

## Production Red Flags

- ANR during onResume.
- State lost on rotation.
- Process death not handled (logout on relaunch).

---

## Performance & Metrics (MANDATORY)

- onCreate to first frame: budget ~600ms cold.
- onResume to interactive: <100ms ideal.

---

## Decision Framework

| Need | Approach |
|---|---|
| Survive rotation | configChanges or saveInstanceState |
| Survive process death | persist to MMKV |
| Background work | WorkManager / Foreground Service |

---

## Senior-Level Insight

Senior teams instrument lifecycle: cold/warm/hot start counts, ANR rates, config-change frequency. Knowing distribution informs optimization priorities.

---

## Memory Hook
**"create-start-resume-pause-stop-destroy. RN listens via Host."**

## Revision Notes
> Activity lifecycle bridged to RN via ReactHost (New Arch) → AppState in JS. Config changes recreate Activity by default; declare `configChanges` to handle in place. Process death: persist state. Foreground services need declared type (Android 14+).

---

---

### Q2. Coroutines & Flow — for native modules

---

## Difficulty
- Advanced

## Interview Frequency
- Common (Kotlin / native module rounds)

## Prerequisites
- Async basics

## TL;DR
**Coroutines** = lightweight threads with structured concurrency. Launch in scope (lifecycleScope, viewModelScope). **Flow** = cold reactive streams (like Observable). **StateFlow** = hot, holds latest value (like LiveData). **SharedFlow** = hot, multi-subscriber. For RN TurboModules: use `withContext(Dispatchers.IO)` for I/O, expose via `suspend` functions or callbacks. Don't block UI thread. Cancellation cooperative — check `isActive` or use suspend points.

---

## 30-Second Interview Answer

> "Coroutines are lightweight threads with structured concurrency — child cancellation propagates, scope ties lifetime to a host. Launch in `lifecycleScope` for Activity-scoped, `viewModelScope` for ViewModel. Use `Dispatchers.IO` for blocking I/O, `Dispatchers.Default` for CPU. Flow is cold reactive streams; StateFlow holds latest value, SharedFlow for events. For TurboModules: wrap blocking native calls in `withContext(Dispatchers.IO)`, expose via Promise (callback) or async TurboModule method. Cooperative cancellation via suspend points or `ensureActive()`."

---

## 2-Minute Practical Answer

**Basic coroutine**:
```kotlin
class MyViewModel : ViewModel() {
  fun loadData() {
    viewModelScope.launch {
      val result = withContext(Dispatchers.IO) { repository.fetch() }
      _state.value = result
    }
  }
}
```

**Dispatchers**:
- `Main` — UI thread (Android main).
- `IO` — pool optimized for blocking I/O.
- `Default` — pool for CPU work.
- `Unconfined` — caller's thread (rarely useful).

**Structured concurrency**:
```kotlin
coroutineScope {
  val a = async { fetchA() }
  val b = async { fetchB() }
  process(a.await(), b.await())
}  // both cancelled if scope cancelled
```

**Flow (cold)**:
```kotlin
fun observePrices(): Flow<Price> = flow {
  while (currentCoroutineContext().isActive) {
    emit(api.getPrice())
    delay(1000)
  }
}.flowOn(Dispatchers.IO)
```

**StateFlow / SharedFlow (hot)**:
```kotlin
private val _state = MutableStateFlow(UiState.Loading)
val state: StateFlow<UiState> = _state.asStateFlow()

private val _events = MutableSharedFlow<Event>(replay = 0)
val events: SharedFlow<Event> = _events.asSharedFlow()
```

**RN TurboModule with coroutines**:
```kotlin
class CryptoModule(reactContext: ReactApplicationContext) :
  NativeCryptoSpec(reactContext) {

  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

  override fun hash(input: String, promise: Promise) {
    scope.launch {
      try {
        val result = withContext(Dispatchers.IO) {
          MessageDigest.getInstance("SHA-256")
            .digest(input.toByteArray()).toHex()
        }
        promise.resolve(result)
      } catch (e: Throwable) {
        promise.reject("CRYPTO_ERROR", e)
      }
    }
  }

  override fun invalidate() {
    scope.cancel()
    super.invalidate()
  }
}
```

**Cancellation**:
- Coroutines suspended at suspend points are cancellable.
- CPU loops should check `ensureActive()` or `yield()`.
- Don't swallow `CancellationException`.

---

## 5-Minute Architecture Answer

Why coroutines beat threads:
- Lightweight: thousands per process feasible.
- Structured: parent cancels children automatically.
- Sequential-looking async code (no callbacks).
- Flow integrates naturally.

Scope discipline:
- `viewModelScope` cancelled when ViewModel cleared.
- `lifecycleScope` cancelled when lifecycle ended.
- Custom `CoroutineScope(SupervisorJob() + Dispatchers.X)` for app-wide → cancel in `invalidate()`.

SupervisorJob:
- Child failure doesn't cancel siblings.
- Useful for independent operations.

Flow operators:
- `map`, `filter`, `take`, `debounce`, `distinctUntilChanged`, `combine`, `flatMapLatest`, `catch`, `retry`.
- `flowOn(Dispatchers.IO)` shifts upstream context.
- `collect` is suspending terminal operator.

StateFlow vs LiveData:
- StateFlow: kotlin-first, multiplatform, requires explicit lifecycle handling for collection.
- LiveData: lifecycle-aware out of the box.
- Modern preference: StateFlow + `repeatOnLifecycle(STARTED)`.

Backpressure (Flow):
- Cold flows backpressure naturally (consumer pulls).
- `buffer`, `conflate`, `collectLatest` strategies.

Channels:
- Lower-level than Flow; producer-consumer.
- Deprecated for most use cases in favor of SharedFlow.

For RN TurboModules:
- Async methods return Promise or use callback.
- Don't block JS-call thread.
- Use IO dispatcher for I/O, Default for CPU, Main for UI native calls.
- Expose Flow via event emitter:
```kotlin
viewModelScope.launch {
  repository.observePrices().collect {
    sendEvent("priceUpdate", it.toMap())
  }
}
```

The 2026 specific:
- **Kotlin 2.0+** with K2 compiler.
- **Coroutines 1.8+** stable.
- **WorkManager** built on coroutines.
- **CompositionLocal** + Compose async.

Pitfalls:
- Launching in GlobalScope (no lifecycle).
- Catching `CancellationException` silently (breaks cancellation).
- Blocking inside coroutine (use `withContext(IO)`).
- Hot flow leaks (no scope, no cancel).

Senior code review checks:
- Every `launch` has owning scope.
- Cancellation cooperative.
- Dispatchers correct.
- No GlobalScope.

---

## The "Why"

Coroutines + Flow are how modern Android does async. Native modules in RN often blocked on this idiom. Companies care because TurboModule perf depends on threading discipline.

---

## Mental Model

Coroutine = pause-able function. Scope = lifeline. Flow = stream. Dispatcher = thread pool.

---

## Internal Working (2026 Context)

- Coroutine state machine generated by compiler.
- Continuation = resume point.
- Dispatcher manages thread pool.

---

## Modern Implementation (Code)

**Concurrent fetch with timeout**:
```kotlin
suspend fun loadAll() = withTimeout(5_000) {
  coroutineScope {
    val a = async { fetchA() }
    val b = async { fetchB() }
    a.await() + b.await()
  }
}
```

**Flow with retry + catch**:
```kotlin
api.observe()
  .retry(3) { it is IOException }
  .catch { emit(Default) }
  .flowOn(Dispatchers.IO)
  .collect { handle(it) }
```

---

## Comparison

| Tool | Use |
|---|---|
| `launch` | fire-and-forget |
| `async` | parallel + await |
| `withContext` | switch dispatcher |
| Flow | stream |
| StateFlow | UI state |
| SharedFlow | events |

---

## Production Usage

- Universal in modern Kotlin Android.

---

## Hands-On Exercise

1. Write a TurboModule using coroutines.
2. Expose a Flow as RN event emitter.
3. Test cancellation propagation.
4. Replace LiveData with StateFlow.

---

## Common Mistakes

- GlobalScope.
- Blocking call in Main dispatcher.
- Swallowing CancellationException.
- Hot flow without scope.

---

## Production Red Flags

- ANRs from blocking on Main.
- Memory leaks from leaked scopes.
- Mysterious "lost updates" from missing collection.

---

## Performance & Metrics (MANDATORY)

- Coroutine creation: microseconds.
- Context switch: ~few microseconds.

---

## Decision Framework

| Work | Dispatcher |
|---|---|
| UI | Main |
| File / network | IO |
| CPU | Default |

---

## Senior-Level Insight

Senior reviewers check scope, dispatcher, cancellation discipline in every PR touching coroutines. Bad coroutine code looks fine but leaks.

---

## Memory Hook
**"Scope. Dispatcher. Cooperative cancel."**

## Revision Notes
> Coroutines = structured concurrency. Scope (viewModelScope/lifecycleScope/custom) ties lifetime. Dispatchers.IO for blocking, Default for CPU, Main for UI. Flow cold; StateFlow latest-value; SharedFlow events. TurboModule: `withContext(IO)` + Promise.

---

---

### Q3. WorkManager for RN background sync

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- Q1, S12 background

## TL;DR
**WorkManager** = Android's recommended deferred + reliable background work API. Survives process death, app close, device reboot. Constraints: network, charging, idle. For RN: trigger from JS via TurboModule, run Kotlin Worker, post results back via headless JS or push. Use for: sync, upload queues, periodic refresh. Unsuitable for: real-time work or work that must run immediately.

---

## 30-Second Interview Answer

> "WorkManager guarantees deferred background execution — survives process death, app close, reboot. Define a `Worker` (or `CoroutineWorker`), set Constraints (network, charging, idle), enqueue OneTime or Periodic. Min 15-min interval for periodic. For RN: trigger from JS via TurboModule, Worker runs Kotlin code (or invokes headless JS). Use for sync, upload queues, periodic refresh. Doze respects WorkManager. Don't use for real-time — that's Foreground Service."

---

## 2-Minute Practical Answer

**Define worker**:
```kotlin
class SyncWorker(
  ctx: Context,
  params: WorkerParameters
) : CoroutineWorker(ctx, params) {
  override suspend fun doWork(): Result = try {
    val data = api.fetchPending()
    db.save(data)
    Result.success()
  } catch (e: IOException) {
    Result.retry()
  } catch (e: Exception) {
    Result.failure()
  }
}
```

**Schedule from Kotlin**:
```kotlin
val constraints = Constraints.Builder()
  .setRequiredNetworkType(NetworkType.UNMETERED)
  .setRequiresCharging(false)
  .build()

val request = PeriodicWorkRequestBuilder<SyncWorker>(
  15, TimeUnit.MINUTES
).setConstraints(constraints).build()

WorkManager.getInstance(ctx).enqueueUniquePeriodicWork(
  "sync", ExistingPeriodicWorkPolicy.KEEP, request
)
```

**Trigger from RN via TurboModule**:
```kotlin
class BackgroundModule(reactContext: ReactApplicationContext) :
  NativeBackgroundSpec(reactContext) {

  override fun scheduleSync(intervalMin: Double) {
    val req = PeriodicWorkRequestBuilder<SyncWorker>(
      intervalMin.toLong(), TimeUnit.MINUTES
    ).setConstraints(unmeteredConstraints).build()
    WorkManager.getInstance(reactContext)
      .enqueueUniquePeriodicWork("sync", ExistingPeriodicWorkPolicy.KEEP, req)
  }

  override fun cancelSync() {
    WorkManager.getInstance(reactContext).cancelUniqueWork("sync")
  }
}
```

```ts
// JS
import { NativeModules } from 'react-native';
NativeModules.Background.scheduleSync(30);
```

**Worker invokes headless JS** (run JS in background):
```kotlin
class JsHeadlessWorker(ctx: Context, p: WorkerParameters) :
  CoroutineWorker(ctx, p) {
  override suspend fun doWork(): Result = suspendCoroutine { cont ->
    HeadlessJsTaskService.acquireWakeLockNow(applicationContext)
    val intent = Intent(applicationContext, MyHeadlessJsTaskService::class.java)
    applicationContext.startService(intent)
    cont.resume(Result.success())
  }
}
```

**Constraints**:
- Network: NONE / CONNECTED / UNMETERED / METERED.
- Battery not low.
- Charging.
- Device idle.
- Storage not low.

**Backoff policies**:
- Linear or Exponential.
- Min interval 10s.

---

## 5-Minute Architecture Answer

When to use what:
- **Foreground Service**: must run immediately, user-visible, e.g., music playback.
- **WorkManager**: deferrable, guaranteed, e.g., upload queue.
- **AlarmManager**: precise timing, sparingly used.
- **JobScheduler**: WorkManager wraps it.
- **Coroutine in app**: while app open only.

WorkManager guarantees:
- Survives process death.
- Survives app close.
- Survives reboot (if `RESCHEDULE_ON_REBOOT` permission added).
- Respects Doze + App Standby.
- Persists in SQLite locally.

Unique work:
- `enqueueUniqueWork` / `enqueueUniquePeriodicWork`.
- Policies: KEEP, REPLACE, APPEND, APPEND_OR_REPLACE.

Chained work:
```kotlin
WorkManager.getInstance(ctx)
  .beginWith(workA)
  .then(workB)
  .then(workC)
  .enqueue()
```

Headless JS pattern (for RN):
- Worker triggers HeadlessJsTaskService.
- JS runs in background, no UI.
- Used for sync that needs JS logic.
- Caveat: can't open UI; can post local notification.

For long uploads:
- Chunk at app level.
- Per-chunk Worker.
- Resume on next attempt.

Foreground Worker (for long work):
```kotlin
override suspend fun doWork(): Result {
  setForeground(createForegroundInfo("Syncing..."))
  // ... work
  return Result.success()
}
```
Required for work > 10 min.

The 2026 specific:
- **WorkManager 2.10+** with better Compose / Coroutine integration.
- **Android 14 Foreground Service Types** required for foreground workers.
- **Battery exemption** for "essential" workers.
- **Predictive caching** based on usage patterns.

iOS comparison:
- iOS: `BGTaskScheduler` + `BGProcessingTask` / `BGAppRefreshTask`.
- Different model; same RN abstraction (`expo-background-fetch`, `react-native-background-fetch`).

Cross-platform RN libs:
- `react-native-background-fetch` (popular).
- `expo-background-fetch` (Expo).
- `react-native-background-task` (older).

---

## The "Why"

Reliable background sync = better UX. Without WorkManager: fragile, dropped work, bad battery. Companies care because background sync defines offline-first quality.

---

## Mental Model

Worker = unit of work. Constraints = preconditions. WorkManager = scheduler that survives anything.

---

## Internal Working (2026 Context)

- WorkManager stores requests in Room DB.
- Schedules via JobScheduler (API 23+).
- On reboot: re-schedules.

---

## Modern Implementation (Code)

**Upload queue worker**:
```kotlin
class UploadWorker(ctx: Context, p: WorkerParameters) :
  CoroutineWorker(ctx, p) {
  override suspend fun doWork(): Result {
    val pending = db.uploads.queued()
    for (item in pending) {
      try {
        api.upload(item)
        db.uploads.markDone(item.id)
      } catch (e: IOException) {
        return Result.retry()
      }
    }
    return Result.success()
  }
}
```

**Schedule on app start**:
```ts
useEffect(() => {
  NativeModules.Background.scheduleSync(15);
}, []);
```

---

## Comparison

| API | Use |
|---|---|
| WorkManager | deferred + guaranteed |
| Foreground Service | immediate + user-visible |
| AlarmManager | exact timing (rare) |

---

## Production Usage

- Standard for offline-first apps.

---

## Hands-On Exercise

1. Build sync Worker.
2. Trigger from RN via TurboModule.
3. Add network constraint.
4. Test reboot survival.

---

## Common Mistakes

- WorkManager for real-time (use Foreground Service).
- < 15 min periodic (not allowed).
- No constraints (drains battery).
- Forgetting setForeground for long work.

---

## Production Red Flags

- Background work via setInterval.
- Sync only when app open.
- No retry / backoff.

---

## Performance & Metrics (MANDATORY)

- Min periodic interval: 15 min.
- Backoff min: 10s.

---

## Decision Framework

| Need | Choose |
|---|---|
| Sync periodically | WorkManager periodic |
| Upload retry | WorkManager one-time + retry |
| Music playback | Foreground Service |
| Exact alarm | AlarmManager |

---

## Senior-Level Insight

Senior engineers measure background work success rate, time-to-first-sync, battery impact. WorkManager dashboards reveal reliability gaps.

---

## Memory Hook
**"Worker. Constraints. Survive anything."**

## Revision Notes
> WorkManager guarantees background work; survives process death, reboot. CoroutineWorker for async. Constraints: network, charging, idle. Periodic min 15 min. Trigger from RN via TurboModule. Foreground Worker for long work.

---

---

### Q4. Predictive Back gesture (Android 14+) — RN integration

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Emerging (2026 hot topic)

## Prerequisites
- Android navigation basics

## TL;DR
**Predictive Back** lets users see a preview of what's "behind" the current screen during back swipe. Mandatory in Android 16+. RN apps need: `android:enableOnBackInvokedCallback="true"` in manifest, Reanimated 4+ for shared element transitions, navigation library that supports it (React Navigation 7+, Expo Router 4+). Without: gesture fails or flickers. Custom back handlers must use `OnBackInvokedCallback` API not deprecated `onBackPressed`.

---

## 30-Once Interview Answer

> "Predictive Back shows a peek of the previous screen during back swipe. Opt in via `android:enableOnBackInvokedCallback=\"true\"` in AndroidManifest. Custom back handling must move from deprecated `onBackPressed` to `OnBackInvokedCallback` (or `OnBackPressedCallback` for AndroidX). React Navigation 7+ / Expo Router 4+ support shared transitions via Reanimated 4. Mandatory in Android 16+. Test with developer option enabled. Without it: jarring transitions and back-handling bugs."

---

## 2-Minute Practical Answer

**Manifest opt-in**:
```xml
<application
  android:enableOnBackInvokedCallback="true"
  ...>
</application>
```

**OnBackInvokedCallback (Activity)**:
```kotlin
class MainActivity : ReactActivity() {
  private val backCallback = object : OnBackPressedCallback(false) {
    override fun handleOnBackPressed() {
      // Custom handling
    }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(null)
    onBackPressedDispatcher.addCallback(this, backCallback)
  }

  fun setBackEnabled(enabled: Boolean) {
    backCallback.isEnabled = enabled
  }
}
```

**JS-side (BackHandler)**:
```ts
import { BackHandler } from 'react-native';
useEffect(() => {
  const sub = BackHandler.addEventListener('hardwareBackPress', () => {
    if (modalOpen) { closeModal(); return true; }
    return false;
  });
  return () => sub.remove();
}, [modalOpen]);
```

**React Navigation 7+ shared transitions**:
```ts
<Stack.Screen
  name="Detail"
  component={DetailScreen}
  options={{
    animation: 'fade_from_bottom',
    presentation: 'modal',
  }}
/>
```

**Reanimated 4 for predictive transitions** (sharedElement):
```tsx
import { SharedElement } from 'react-native-shared-element';
<SharedElement id={`item.${id}`}>
  <Image source={...} />
</SharedElement>
```

---

## 5-Minute Architecture Answer

Why predictive back exists:
- Swipe back common UX (iOS has it natively).
- Old Android: opaque transition.
- Predictive Back: preview shown during swipe; commit on release.

Three states:
- Started (swipe begins).
- Progressed (swipe in progress; show preview).
- Released (commit) or Cancelled.

Old API → New API:
- **`onBackPressed()` [DEPRECATED]**: Activity callback, no progress info.
- **`OnBackInvokedCallback`**: framework-level, progressive.
- **`OnBackPressedCallback` (AndroidX)**: lifecycle-aware wrapper, supports progress.

JS bridging:
- React Native bridges via `BackHandler`.
- 2026: `BackHandler` enhanced with progress events on supporting versions.
- Custom transitions via Reanimated.

Edge cases:
- Modal open: cancel back.
- Form dirty: confirm dialog.
- Web view: pop history first.

Testing:
- Developer Options → "Predictive back animations".
- Or programmatically: `adb shell setprop persist.wm.debug.predictive_back 1`.

The 2026 specific:
- **Mandatory Android 16+** for new apps.
- **Reanimated 4** with native progress callbacks.
- **Expo Router 4** integrates predictive back.
- **Compose** adopts via `BackHandler` composable.

Predictive back + WebView:
- Need `WebView.canGoBack()` check.
- Otherwise app exits on first swipe over webview.

Predictive back + Modals:
- Modal should consume back.
- React Navigation handles by default.

Custom transitions:
- Cross-fade.
- Slide-from-right.
- Shared element (image expands/collapses).
- Reanimated 4 worklets compute frame.

Backwards compat:
- `enableOnBackInvokedCallback="true"` works on Android 13+.
- Devices < 13 fall back to `onBackPressed` path.

---

## The "Why"

UX consistency = retention. Mandatory in 16+. Companies care because Play Store quality signals include navigation polish.

---

## Mental Model

Back gesture = preview-then-commit. RN delegates to OS; JS hooks via BackHandler with progress in 2026.

---

## Internal Working (2026 Context)

- WindowManager dispatches gesture events.
- Activity's onBackInvokedDispatcher routes.
- AndroidX wraps for lifecycle awareness.

---

## Modern Implementation (Code)

**Conditional back enable**:
```ts
function FormScreen() {
  const isDirty = useFormDirty();
  useEffect(() => {
    NativeModules.Back.setEnabled(isDirty);
  }, [isDirty]);
}
```

**Reanimated 4 progress**:
```tsx
import Animated, { useAnimatedStyle } from 'react-native-reanimated';
const progress = useBackProgress();
const style = useAnimatedStyle(() => ({
  transform: [{ scale: 1 - progress.value * 0.1 }],
}));
```

---

## Comparison

| API | Use |
|---|---|
| onBackPressed [DEPRECATED] | legacy |
| OnBackPressedCallback | preferred AndroidX |
| OnBackInvokedCallback | framework |

---

## Production Usage

- Standard in 2026 apps.
- Required Android 16+.

---

## Hands-On Exercise

1. Opt in via manifest.
2. Migrate custom back to OnBackPressedCallback.
3. Add shared element transition.
4. Test in developer options.

---

## Common Mistakes

- Forgetting manifest opt-in.
- Using onBackPressed (deprecated).
- Not handling WebView.
- Modal not consuming back.

---

## Production Red Flags

- Jarring back transitions.
- Back exit when modal open.

---

## Performance & Metrics (MANDATORY)

- Frame budget for transition: 16ms.
- Reanimated worklets keep on UI thread.

---

## Decision Framework

| Screen | Behavior |
|---|---|
| Stack screen | preview previous |
| Modal | dismiss modal |
| Form dirty | confirm |
| WebView | history.back |

---

## Senior-Level Insight

Senior teams audit every screen for back behavior. Predictive back exposes existing bugs (modals not consuming back, etc.).

---

## Memory Hook
**"Opt in. OnBackPressedCallback. Reanimated 4. Mandatory 16+."**

## Revision Notes
> Predictive Back: preview previous screen during swipe. Manifest `enableOnBackInvokedCallback`. Use OnBackPressedCallback (AndroidX), not onBackPressed. React Navigation 7+ / Expo Router 4 + Reanimated 4 support transitions. Mandatory Android 16+.

---

---

### Q5. Compose interop with Fabric components

---

## Difficulty
- Advanced

## Interview Frequency
- Common (architecture / brownfield rounds)

## Prerequisites
- Compose basics, Fabric Q3/Q4 (S4)

## TL;DR
Two interop directions: **(a) Embed Compose inside RN** via `ViewManager` wrapping `ComposeView` — useful for native-only screens / widgets. **(b) Embed RN inside Compose** via `AndroidView { ReactRootView(...) }` — brownfield pattern. Fabric ViewManager (`createView` + `updateProps`) returns `ComposeView`; props mapped to Compose state. Theming + performance: Compose recomposes; ensure `mutableStateOf` for prop updates. Lifecycle: ComposeView uses ViewTreeLifecycleOwner — must be set.

---

## 30-Second Interview Answer

> "Two directions. Embed Compose in RN: write a Fabric ViewManager that returns a ComposeView; map props to mutableStateOf so Compose recomposes. Useful for native widgets like maps or charts. Embed RN in Compose: `AndroidView { ReactRootView(ctx).apply { startReactApplication(...) } }` — brownfield pattern. Lifecycle requires ViewTreeLifecycleOwner set (use the host Activity's). Performance: Compose recompositions per prop update; debounce or use derivedStateOf. Theming bridged separately (Compose theme ≠ RN theme)."

---

## 2-Minute Practical Answer

**Compose in RN — ViewManager (Fabric)**:
```kotlin
class ChartViewManager : SimpleViewManager<ComposeView>() {
  override fun getName() = "RNChartView"

  override fun createViewInstance(ctx: ThemedReactContext): ComposeView {
    val state = ChartState()
    return ComposeView(ctx).apply {
      tag = state
      setContent { ChartComposable(state) }
    }
  }

  @ReactProp(name = "data")
  fun setData(view: ComposeView, data: ReadableArray) {
    val state = view.tag as ChartState
    state.points = data.toPoints()  // mutableStateOf inside
  }
}

class ChartState {
  var points by mutableStateOf<List<Point>>(emptyList())
}

@Composable
fun ChartComposable(state: ChartState) {
  Canvas(Modifier.fillMaxSize()) {
    state.points.forEach { drawCircle(...) }
  }
}
```

**JS side**:
```tsx
import { requireNativeComponent } from 'react-native';
const ChartView = requireNativeComponent('RNChartView');
<ChartView data={[{ x: 1, y: 2 }]} style={{ height: 200 }} />
```

**RN in Compose** (brownfield):
```kotlin
@Composable
fun RNScreen(componentName: String) {
  val ctx = LocalContext.current
  val activity = ctx as ComponentActivity
  AndroidView(
    factory = {
      ReactRootView(it).apply {
        startReactApplication(
          (activity.application as ReactApplication).reactNativeHost.reactInstanceManager,
          componentName,
          null
        )
      }
    },
    modifier = Modifier.fillMaxSize()
  )
}
```

**ViewTreeLifecycleOwner**:
- ComposeView needs lifecycle owner from view tree.
- Activity sets automatically; modal/overlay may need manual.
```kotlin
view.setViewTreeLifecycleOwner(activity)
view.setViewTreeSavedStateRegistryOwner(activity)
```

---

## 5-Minute Architecture Answer

Why interop matters:
- Brownfield apps add RN incrementally.
- Greenfield RN may use Compose for performance-critical widgets.
- Cross-team boundaries.

ViewManager Fabric specifics:
- Codegen generates spec from JS.
- ShadowNode handles layout (Yoga).
- ComposeView mounted as Android view.
- Props update via state mutation.

State bridging patterns:
- `mutableStateOf` in a holder class kept on ViewManager.
- Tag the view with the holder.
- On `@ReactProp` setter: mutate state → Compose recomposes.

Recomposition control:
- Compose recomposes when state read changes.
- Use `key()` to force re-init.
- `derivedStateOf` for computed.
- `remember` for stable refs.

Theme bridging:
- RN Appearance API gives light/dark to JS.
- Compose has MaterialTheme.
- Bridge: read Appearance in JS, pass theme prop to Compose, Compose composable uses MaterialTheme override.

Performance:
- Compose recomposition cheap if state minimal.
- Avoid passing big objects as props (use IDs, lookup in Compose).
- Profile with Compose Compiler reports.

For RN-in-Compose:
- Use single ReactNativeHost across Compose tree.
- Don't recreate ReactRootView per recomposition (use `remember`).
- Fragment-style patterns better for non-trivial RN screens.

The 2026 specific:
- **Compose Multiplatform** stable — code shared with iOS Swift.
- **Compose Compiler reports** detect recomposition pitfalls.
- **Reanimated 4 + Compose** interop improving.
- **Codegen + ViewManager** standard pattern.

Common pitfalls:
- ComposeView without lifecycle owner → crash.
- Recomposition every prop update → jank.
- Missing remember on heavy objects.
- Memory leaks from observed Flow without cancellation.

When NOT to interop:
- Pure RN apps without native widgets.
- Pure Kotlin apps without RN need.
- Glue is non-trivial; only when justified.

---

## The "Why"

Compose interop = best of both worlds. Senior orgs reuse native widgets where Compose fits. Companies care because brownfield migration paths matter.

---

## Mental Model

ViewManager wraps ComposeView. Props flip mutableStateOf. Recomposition does the rest.

---

## Internal Working (2026 Context)

- Fabric ShadowNode → Android view.
- ComposeView hosts Compose runtime.
- Recomposition driven by snapshot system.

---

## Modern Implementation (Code)

**Map view with Compose** (sketch):
```kotlin
class MapViewManager : SimpleViewManager<ComposeView>() {
  override fun getName() = "RNMapView"
  override fun createViewInstance(ctx: ThemedReactContext) = ComposeView(ctx).apply {
    val state = MapState()
    tag = state
    setContent { MapComposable(state) }
  }

  @ReactProp(name = "center")
  fun setCenter(view: ComposeView, center: ReadableMap) {
    (view.tag as MapState).center = LatLng(center.getDouble("lat"), center.getDouble("lng"))
  }
}
```

---

## Comparison

| Direction | Use |
|---|---|
| Compose in RN | reuse Compose widget in RN app |
| RN in Compose | brownfield migration |

---

## Production Usage

- Brownfield: common.
- Greenfield: less, but selective for native widgets.

---

## Hands-On Exercise

1. Build a Compose-backed Fabric component.
2. Map JS props to Compose state.
3. Embed RN screen in Compose.
4. Profile recomposition.

---

## Common Mistakes

- ComposeView no lifecycle owner.
- Recreating ReactRootView per recomposition.
- Heavy props (use IDs).
- Missing remember.

---

## Production Red Flags

- Jank on prop updates.
- Memory leaks.
- Theme drift between Compose + RN.

---

## Performance & Metrics (MANDATORY)

- Recomposition: target < 1ms.
- Prop update → render: < 16ms.

---

## Decision Framework

| Need | Approach |
|---|---|
| Native widget in RN | Compose in RN |
| Brownfield migration | RN in Compose |
| Greenfield pure | skip interop |

---

## Senior-Level Insight

Senior teams pick interop direction by team / migration goals, not aesthetic. Each direction has cost; justify.

---

## Memory Hook
**"ViewManager wraps ComposeView. AndroidView wraps ReactRootView."**

## Revision Notes
> Compose in RN: Fabric ViewManager returns ComposeView; props → mutableStateOf → recomposition. RN in Compose: AndroidView { ReactRootView }; remember to avoid recreate. ViewTreeLifecycleOwner required. Theme bridged separately. Brownfield-friendly.

---

> **End of S13.** Cross-refs: [S4 New Architecture](S04-new-architecture.md), [S15 Native Bridging](S15-native-bridging.md), [S20 CI/CD](S20-cicd-release.md), [S14 iOS & Swift](S14-ios-swift.md). Next per priority: [S14 iOS & Swift](S14-ios-swift.md).
