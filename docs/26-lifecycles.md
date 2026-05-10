# 26. Lifecycles — Android, iOS, React, React Native

> **Why this doc exists:** lifecycle questions are asked in 90%+ of senior mobile loops. You must know how a screen mounts, backgrounds, restores, and dies on **all four platforms** (Android Activity/Fragment/Service, iOS VC/App, React component, React Native).

---

## 1. Android — Activity lifecycle

### Flow (cold start → user leaves → comes back → killed)

```
                ┌──────────────┐
                │   onCreate   │  ← bundle restored here (savedInstanceState)
                └──────┬───────┘
                       ▼
                ┌──────────────┐
                │   onStart    │  ← visible (not yet interactive)
                └──────┬───────┘
                       ▼
                ┌──────────────┐
                │  onResume    │  ← interactive (foreground)
                └──────┬───────┘
                       │  user navigates away / phone call
                       ▼
                ┌──────────────┐
                │   onPause    │  ← still partly visible (e.g., dialog)
                └──────┬───────┘
                       │ activity fully obscured
                       ▼
                ┌──────────────┐
                │   onStop     │  ← not visible
                └──────┬───────┘
                       │ user returns?
            ┌──────────┴───────────┐
            ▼                      ▼
       onRestart → onStart      onDestroy   ← finishing or process killed
```

### Method-by-method

| Callback | When | Use it for |
|---|---|---|
| `onCreate(Bundle?)` | first creation, or recreation after config change | inflate UI, bind viewmodels, restore state |
| `onStart()` | becoming visible | start sensors / location updates |
| `onResume()` | becoming interactive | resume animations, register frequent listeners |
| `onPause()` | losing focus (dialog, multi-window) | persist transient state, pause video |
| `onStop()` | no longer visible | release resources, unregister broadcast receivers |
| `onRestart()` | returning from stop | re-initialize anything released in onStop |
| `onDestroy()` | being destroyed (or process killed) | final cleanup; **don't** rely on it (process can die without calling) |
| `onSaveInstanceState(Bundle)` | before stop, on config change | save small UI state (text, scroll pos) |

### Configuration changes (rotation, language, dark mode)
By default Activity is **destroyed and recreated**. Use one of:
- `ViewModel` (Jetpack) — survives config change, NOT process death.
- `onSaveInstanceState` Bundle — survives both, but small (<50KB).
- `android:configChanges="orientation|screenSize|uiMode"` — opt out (rarely advised; hard to test).

### Example
```kotlin
class HomeActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate, restored=${savedInstanceState != null}")
        setContent { HomeScreen() }
    }
    override fun onStart()   { super.onStart();   Log.d(TAG, "onStart") }
    override fun onResume()  { super.onResume();  startTracking() }
    override fun onPause()   { super.onPause();   stopTracking() }
    override fun onStop()    { super.onStop();    persistDraft() }
    override fun onDestroy() { super.onDestroy(); analytics.flush() }
    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString("draft", draftText)
    }
    companion object { const val TAG = "HomeActivity" }
}
```

### Process death vs Activity destroy
- **Activity destroy**: explicit (`finish()`) or config change. Bundle saved.
- **Process death**: OS kills entire process under memory pressure. On relaunch, system restores last activity stack with last saved bundles. `onCreate` runs; **`Application.onCreate` runs first**.

> **Test process death**: Android Studio → Logcat → "Run > Apply changes" won't reproduce. Use `adb shell am kill <pkg>` while app backgrounded, then return.

---

## 2. Android — Fragment lifecycle

```
onAttach → onCreate → onCreateView → onViewCreated → onStart → onResume
                                                                  │
                                          (user navigates away)   ▼
                          onPause → onStop → onDestroyView ← view destroyed
                                                  │
                                                  ▼
                                           onDestroy → onDetach
```

| Callback | Notes |
|---|---|
| `onAttach(ctx)` | fragment attached to host activity |
| `onCreate` | fragment instance created (no view yet) |
| `onCreateView` | inflate layout |
| `onViewCreated` | bind views + observers |
| `onDestroyView` | view destroyed but fragment kept (back stack) |
| `onDestroy` | fragment instance destroyed |

### Two lifecycles: fragment vs view
A fragment can outlive its view (back stack). Use `viewLifecycleOwner` for `LiveData`/`flow` observers — otherwise leaks happen when fragment stays but view is gone.

```kotlin
override fun onViewCreated(v: View, b: Bundle?) {
  super.onViewCreated(v, b)
  viewModel.user.observe(viewLifecycleOwner) { render(it) }   // ✅
  // viewModel.user.observe(this) { ... }                      // ❌ leak
}
```

### Common pitfalls
- Holding `binding` in fragment field → memory leak. Pattern: nullable backing field cleared in `onDestroyView`.
- Calling `findNavController()` after view destroyed → crash.
- Triggering work in `onCreate` that needs view (it doesn't exist yet).

---

## 3. Android — Service lifecycle

### Started service
```
startService() → onCreate → onStartCommand → (running) → stopService/stopSelf → onDestroy
```

### Bound service
```
bindService() → onCreate → onBind → (clients use IBinder) → unbindService → onUnbind → onDestroy
```

| Service type | Use for |
|---|---|
| `Service` (started) | background work, music playback (deprecated for new bg work post-Android 8) |
| Bound `Service` | IPC / shared client API |
| `IntentService` | one-shot bg jobs (deprecated → use `WorkManager`) |
| `JobIntentService` / `WorkManager` | guaranteed background work |
| `ForegroundService` | long-running visible work (music, navigation, fitness) |

### Foreground service requirements (Android 14)
Must declare `foregroundServiceType` + show ongoing notification within 10 s of `startForeground()`. Permission needed per type (`FOREGROUND_SERVICE_LOCATION` etc.).

```kotlin
class TrackerService : Service() {
  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val n = NotificationCompat.Builder(this, "track")
      .setSmallIcon(R.drawable.ic_run).setContentTitle("Tracking run").build()
    startForeground(1, n)
    startTracking()
    return START_STICKY  // restart if killed
  }
  override fun onDestroy() { stopTracking() }
  override fun onBind(intent: Intent?): IBinder? = null
}
```

### START_STICKY vs START_NOT_STICKY vs START_REDELIVER_INTENT
- `STICKY`: restart with null intent (continuous service like music).
- `NOT_STICKY`: don't restart (one-off jobs).
- `REDELIVER_INTENT`: restart with last intent (uploads, must finish).

---

## 4. Android — Application lifecycle

`Application.onCreate()` runs once when process starts (before any Activity). Place: DI init, crash reporting, global config.

```kotlin
class MyApp : Application() {
  override fun onCreate() {
    super.onCreate()
    SoLoader.init(this, false)
    Sentry.init(...)
    Hermes.startBackgroundBundle()
  }
}
```

`Application.ActivityLifecycleCallbacks` — observe every Activity transition app-wide (analytics, session timing).

`ProcessLifecycleOwner` — app-level foreground/background events:
```kotlin
ProcessLifecycleOwner.get().lifecycle.addObserver(object : DefaultLifecycleObserver {
  override fun onStart(owner: LifecycleOwner) { /* app foregrounded */ }
  override fun onStop(owner: LifecycleOwner)  { /* app backgrounded */ }
})
```

---

## 5. Android — Compose vs ViewModel lifecycles

- **`@Composable`** runs many times; never store state in plain locals — use `remember` / `rememberSaveable`.
- **`LaunchedEffect(key)`** = side effects tied to composition; cancels when key changes or composable leaves.
- **`DisposableEffect`** = setup + teardown.
- **`ViewModel`** survives config change; cleared in `onCleared()` when scope dies (Activity finish for `viewModels()`).

```kotlin
@Composable
fun Screen(id: String) {
  LaunchedEffect(id) { viewModel.load(id) }
  DisposableEffect(Unit) {
    val sub = sensor.subscribe()
    onDispose { sub.cancel() }
  }
}
```

---

## 6. iOS — UIApplication lifecycle (pre-iOS 13)

```
launching → didFinishLaunching → applicationDidBecomeActive
              ↑                              │
applicationWillTerminate           applicationWillResignActive
              ▲                              │
applicationDidEnterBackground ←── applicationDidEnterBackground
              │
applicationWillEnterForeground → applicationDidBecomeActive
```

| Callback | When |
|---|---|
| `application(_:didFinishLaunchingWithOptions:)` | process start; init crash reporting, RN bundle |
| `applicationWillResignActive` | interrupt (call, control center) |
| `applicationDidEnterBackground` | user pressed home / switched apps |
| `applicationWillEnterForeground` | user re-opens |
| `applicationDidBecomeActive` | back to interactive |
| `applicationWillTerminate` | rare; only if user not killed it manually |

---

## 7. iOS 13+ — UIScene / SceneDelegate

Multi-window support: each scene has its own lifecycle. App can have multiple `UIWindowScene`s (iPad split view).

```
willConnectTo → sceneWillEnterForeground → sceneDidBecomeActive
                                                  │
sceneWillResignActive ←──── (user backgrounds) ──┘
sceneDidEnterBackground
sceneWillEnterForeground (return)
sceneDidDisconnect (system reclaims)
```

> RN apps with `react-native-bootsplash`/`expo-splash-screen` typically hide splash in `sceneDidBecomeActive` after JS reports ready.

---

## 8. iOS — UIViewController lifecycle

```
init → loadView → viewDidLoad
                      │
                      ▼
viewWillAppear → viewIsAppearing (iOS 13+) → viewDidAppear
                                                   │
                                  (push another VC) │
                                                   ▼
viewWillDisappear → viewDidDisappear
                                                   │
                                  (popped / dismissed)
                                                   ▼
                                              deinit
```

| Callback | Use for |
|---|---|
| `viewDidLoad` | one-time setup (subviews, constraints) |
| `viewWillAppear` | refresh data, register observers |
| `viewDidAppear` | analytics screen-view, start animations |
| `viewWillDisappear` | persist edits, unregister observers |
| `viewDidDisappear` | stop expensive work |
| `viewWillTransition(to:with:)` | rotation / size class change |

```swift
class HomeVC: UIViewController {
  override func viewDidLoad() { super.viewDidLoad(); setupUI() }
  override func viewWillAppear(_ a: Bool) { super.viewWillAppear(a); store.subscribe(self) }
  override func viewWillDisappear(_ a: Bool) { super.viewWillDisappear(a); store.unsubscribe(self) }
}
```

### Memory warnings
`didReceiveMemoryWarning()` — release caches. Modern iOS: rare.

---

## 9. iOS — SwiftUI lifecycle

- `@StateObject` — owned by view, survives view recomputation.
- `@ObservedObject` — passed in.
- `.onAppear` / `.onDisappear` — equivalents of viewWillAppear / Disappear.
- `.task { … }` — async work tied to view lifetime; auto-cancelled.
- `@Environment(\.scenePhase)` — observe app foreground/background per scene.

```swift
struct Home: View {
  @Environment(\.scenePhase) var phase
  var body: some View {
    Text("hi")
      .onAppear { analytics.screen("home") }
      .task { await store.load() }
      .onChange(of: phase) { p in if p == .background { saveDraft() } }
  }
}
```

---

## 10. React (web + RN) — class component lifecycle

```
       constructor
            │
            ▼
   getDerivedStateFromProps
            │
            ▼
          render
            │
            ▼
   componentDidMount  ───────────────────┐
            │                              │
            ▼                              │
   props/state change                      │
            │                              │
            ▼                              │
   getDerivedStateFromProps                │
   shouldComponentUpdate (skip?)           │
   render                                  │
   getSnapshotBeforeUpdate                 │
   componentDidUpdate                      │
            │                              │
            ▼                              ▼
                          componentWillUnmount
```

### Phase mapping
- **Mounting**: constructor → render → didMount.
- **Updating**: getDerivedStateFromProps → shouldComponentUpdate → render → getSnapshotBeforeUpdate → didUpdate.
- **Unmounting**: componentWillUnmount.
- **Error**: getDerivedStateFromError + componentDidCatch (error boundaries).

### Deprecated (unsafe, prefixed `UNSAFE_`)
- `componentWillMount`, `componentWillReceiveProps`, `componentWillUpdate` — async render unsafe.

---

## 11. React — hooks lifecycle equivalents

| Class lifecycle | Hook equivalent |
|---|---|
| `componentDidMount` | `useEffect(fn, [])` |
| `componentDidUpdate` | `useEffect(fn, [deps])` |
| `componentWillUnmount` | `useEffect` cleanup (`return () => …`) |
| `getDerivedStateFromProps` | derive in render or `useMemo` |
| `shouldComponentUpdate` | `React.memo` + custom equality |
| `componentDidCatch` | error boundaries (still class-only) |

### Effect timing
1. React updates state.
2. Render commits.
3. Browser/host paints.
4. `useEffect` runs (next tick).
5. `useLayoutEffect` runs **before** paint (sync) — use sparingly.

```jsx
useEffect(() => {
  const id = setInterval(tick, 1000);
  return () => clearInterval(id);   // cleanup runs before next effect & on unmount
}, []);
```

### React 18 Strict Mode
In dev, effects mount → unmount → mount again to surface missing cleanups. Common cause of "useEffect runs twice" confusion.

---

## 12. React Native — `AppState` lifecycle

| State | Meaning |
|---|---|
| `active` | foreground, focused |
| `background` | not visible |
| `inactive` (iOS only) | transition state — call, control center, app switcher preview |
| `unknown` | initial before subscription fires |

```jsx
useEffect(() => {
  const sub = AppState.addEventListener('change', (next) => {
    if (next === 'background') flushAnalytics();
    if (next === 'active')     refreshSessionToken();
  });
  return () => sub.remove();
}, []);
```

> `inactive` fires very briefly on iOS — don't run heavy work; use it for blur overlay (security on app switcher).

---

## 13. React Navigation — screen lifecycle

```
Screen pushed → mount (useEffect [])
              ↓
        focused (useFocusEffect)
              ↓
   navigate to next screen
              ↓
        blurred (cleanup of useFocusEffect)
              ↓
   pop back → focused again (useFocusEffect re-runs)
              ↓
   pop this screen → unmount (useEffect cleanup)
```

| Hook | Fires on |
|---|---|
| `useEffect(fn, [])` | mount + unmount |
| `useFocusEffect(useCallback(fn, []))` | every focus, cleanup on every blur |
| `useIsFocused()` | boolean, re-renders on change |
| `addListener('focus' / 'blur' / 'beforeRemove' / 'state')` | imperative |

```jsx
function ChatScreen() {
  // mounts + unmounts
  useEffect(() => { socket.connect(); return () => socket.disconnect(); }, []);

  // every time screen gains focus
  useFocusEffect(useCallback(() => {
    refreshUnread();
    return () => persistScroll();
  }, []));
}
```

### `beforeRemove` — confirm-before-leave pattern
```jsx
useEffect(() => navigation.addListener('beforeRemove', (e) => {
  if (!hasUnsavedChanges) return;
  e.preventDefault();
  Alert.alert('Discard?', '', [{text:'Stay'}, {text:'Discard', onPress: () => navigation.dispatch(e.data.action)}]);
}), [navigation, hasUnsavedChanges]);
```

---

## 14. React Native — RN-specific lifecycle hooks

- `Linking.addEventListener('url', …)` — incoming deep link while app open.
- `Linking.getInitialURL()` — URL that launched cold-start.
- `messaging().getInitialNotification()` — push that opened cold.
- `messaging().onNotificationOpenedApp(...)` — push tapped while backgrounded.
- `BackHandler.addEventListener('hardwareBackPress', …)` — Android back.
- `Keyboard.addListener('keyboardDidShow' / 'keyboardDidHide', …)`.
- `NetInfo.addEventListener(state => ...)` — connectivity.
- `Dimensions.addEventListener('change', …)` — rotation / window resize.
- `Appearance.addChangeListener(({colorScheme}) => …)` — dark/light switch.

---

## 15. RN — bridge / new-arch startup sequence

```
Native main()
  ↓
AppDelegate / MainApplication.onCreate
  ↓
RN Host setup (React Native CLI / RCTRootView / ReactActivityDelegate)
  ↓
JS engine init (Hermes)
  ↓
Bundle download (dev) / load HBC (prod)
  ↓
require('index.js') → AppRegistry.registerComponent('app', () => App)
  ↓
First render → Fabric mount → first paint
  ↓
useEffect runs → data fetches start
  ↓
SplashScreen.hide()
```

### What runs on which thread
- **Main / UI**: native rendering, gestures dispatch.
- **JS thread**: React reconciler, your hooks, business logic.
- **Layout (Yoga)**: background, computes flex.
- **UI thread (Reanimated worklets)**: shared values, animation interpolation.

---

## 16. Lifecycle interaction matrix (cross-platform)

| Event | Android | iOS | RN JS |
|---|---|---|---|
| App becomes interactive | `onResume` | `applicationDidBecomeActive` / `sceneDidBecomeActive` | `AppState 'active'` |
| App backgrounded | `onStop` | `applicationDidEnterBackground` / `sceneDidEnterBackground` | `AppState 'background'` |
| Screen visible | `onResume` (Activity) / `onResume` (Fragment) | `viewDidAppear` | `useFocusEffect` |
| Screen hidden | `onPause` / `onStop` | `viewWillDisappear` | `useFocusEffect` cleanup |
| Memory pressure | `onTrimMemory` | `didReceiveMemoryWarning` | none direct (use AppState + size monitor) |
| Locale / theme change | Activity recreated | `traitCollectionDidChange` | `Appearance` listener |
| Rotation | `onConfigurationChanged` or recreate | `viewWillTransition` | `Dimensions` listener |

---

## 17. Common lifecycle bugs (and fixes)

1. **Stale closure in `setInterval` (RN)** — captured state never updates.  
   *Fix:* functional updater `setX(prev => …)` or store in ref.
2. **Subscribing in `componentWillMount`** — runs twice in StrictMode + can leak.  
   *Fix:* move to `useEffect`/`componentDidMount`.
3. **Heavy work in `onResume` (Android)** — UI freeze when returning to app.  
   *Fix:* defer to coroutine, throttle.
4. **Holding view binding in fragment field after `onDestroyView`** — leaks Activity context.  
   *Fix:* nullable backing field, clear in `onDestroyView`.
5. **Doing nav in `viewDidLoad`** — view not in window yet → broken transition.  
   *Fix:* use `viewDidAppear`.
6. **`useFocusEffect` without `useCallback`** — re-runs every render.  
   *Fix:* always wrap with `useCallback(fn, deps)`.
7. **`AppState` listener leaked across screens** — multiple subscribers fire.  
   *Fix:* subscribe at app root, expose via context.
8. **iOS `applicationWillTerminate` won't run on user kill** — don't depend on it for save.  
   *Fix:* persist on `applicationDidEnterBackground`.
9. **Android process death loses in-memory state** — only `onSaveInstanceState` Bundle survives.  
   *Fix:* persist critical state immediately (MMKV).
10. **Push tapped from killed state opens default screen** — initial notification not handled.  
    *Fix:* check `messaging().getInitialNotification()` after auth ready.

---

## Top 25 Q&A — Lifecycles

### 1. Activity recreated on rotation — why and how to keep state?
By default, config change destroys + recreates Activity. Use `ViewModel` (Jetpack) for retained data, `onSaveInstanceState` Bundle for small UI state. Both survive rotation; only Bundle survives process death.

### 2. Difference between `onPause` and `onStop`?
`onPause`: still partly visible (e.g., dialog or split-screen). `onStop`: fully obscured. Don't release UI in `onPause` — user might come back instantly.

### 3. Process death — how to detect + handle?
On launch, if `savedInstanceState != null` and you have no in-memory data, you've been process-killed. Restore from Bundle / MMKV / disk.

### 4. `Application.onCreate` — when does it run?
Once per process start, before any Activity. Init crash reporting, DI, RN bridge here. Keep it FAST — slow Application start = slow cold start everywhere.

### 5. Why is `viewLifecycleOwner` different from `this` in a Fragment?
A fragment can outlive its view (back stack pushed → view destroyed but fragment retained). Observing on `this` leaks because callbacks fire after view is gone.

### 6. When does `onDestroy` NOT run on Android?
Process death (low memory). System kills the whole process; no callbacks fire. **Never** rely on `onDestroy` for critical cleanup.

### 7. `START_STICKY` vs `START_NOT_STICKY`?
`STICKY`: system restarts service after kill (with null intent) — music players, location trackers. `NOT_STICKY`: don't restart — one-shot work.

### 8. iOS scene-based vs app-based lifecycle?
Pre-iOS 13: only `UIApplicationDelegate`. iOS 13+: multi-window, each `UIScene` has own foreground/background events. iPad supports multiple scenes simultaneously.

### 9. `viewDidLoad` vs `viewWillAppear` — when each?
`viewDidLoad`: once, after view loaded; setup that's identical every time (subviews, constraints). `viewWillAppear`: every time visible; refresh data, log screen view.

### 10. `useEffect(fn, [])` vs `componentDidMount` — equivalent?
Mostly. **Difference:** in React 18 Strict Mode dev, the effect mounts → unmounts → mounts again to test cleanup. Class `componentDidMount` runs once. Production behavior: equivalent.

### 11. Why does my `useEffect` run twice in dev only?
React 18 Strict Mode intentionally double-invokes mount to reveal missing cleanups. Disabled in production. Fix by adding proper cleanup in the returned function.

### 12. `useEffect` vs `useLayoutEffect` — when each?
`useEffect`: after paint, async — 99% of cases. `useLayoutEffect`: before paint, sync — for measuring DOM/host or preventing visual flicker. Heavy work here delays paint.

### 13. `useFocusEffect` vs `useEffect` in React Navigation?
`useEffect` runs on mount/unmount. `useFocusEffect` runs every time screen gains focus and cleans up on blur. Use focus effect for refetching when user returns to screen.

### 14. App backgrounded → server requests in flight — what happens?
RN/iOS/Android continues running for ~30s typically; longer if backgrounded with audio/location/VoIP entitlement. Otherwise OS pauses. Use `BackgroundTask` / `WorkManager` for guarantees.

### 15. How to detect cold start vs warm start in RN?
Cold: `Linking.getInitialURL()` may return URL; `messaging().getInitialNotification()` returns push. Warm: `AppState 'active'` after `'background'`. Time it via `Performance.now()` from index.

### 16. Why does my socket disconnect when app backgrounds?
iOS suspends most network after 30s. Android Doze restricts. Use silent push to wake, or maintain heartbeat with foreground service / background fetch.

### 17. How to confirm-before-leave a screen with unsaved changes?
React Navigation: `addListener('beforeRemove', e => { e.preventDefault(); Alert.alert(...) })`. Re-dispatch action on confirm.

### 18. iOS `applicationWillTerminate` — when does it actually run?
Almost never. Only when system gracefully terminates a NON-suspended app (rare). User-killed apps skip it. Persist state on background instead.

### 19. Foreground service requirements on Android 14?
Declare `foregroundServiceType` in manifest, request matching runtime permission, call `startForeground()` within 10 s of `startForegroundService()`. Ongoing notification mandatory.

### 20. `ProcessLifecycleOwner` — what does it give you?
App-level (not Activity-level) foreground/background callbacks. Useful for analytics session boundaries and global pause/resume.

### 21. What lifecycle does an RN screen go through during a push-tap cold start?
Process start → Application.onCreate → Activity onCreate → JS bundle load → AppRegistry → first render → useEffect → check `getInitialNotification()` → navigate to deep-linked screen → hide splash.

### 22. What happens to a Fragment's view when navigating to a new fragment in same activity?
Fragment moves to back stack. `onPause` → `onStop` → `onDestroyView` (view torn down) — but `onDestroy` does NOT fire. On back: `onCreateView` → `onViewCreated` → `onStart` → `onResume`. Stale `binding` references will crash.

### 23. SwiftUI `.task` vs `.onAppear` — difference?
`.onAppear`: sync callback when view appears; can launch `Task { ... }` manually. `.task`: async closure tied to view's lifetime, auto-cancelled when view disappears (preferred for async work).

### 24. RN `useEffect` cleanup vs `componentWillUnmount` — same timing?
Yes for unmount. Plus cleanup runs before each next effect when deps change — that has no class equivalent. Class needs `componentDidUpdate(prevProps)` + manual diff.

### 25. End-to-end: where do you save user input as they type to survive any lifecycle event?
Combine: in-memory state (immediate UI) → debounced `MMKV.set('draft', text)` (200 ms) → restore from MMKV in component mount. Survives backgrounding, process death, rotation, app kill, OS restart.
