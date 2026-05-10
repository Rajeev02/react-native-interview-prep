# S14 — iOS + Swift (for React Native engineers)

> ARC · GCD · Swift Concurrency / Actors · UIViewController / SwiftUI · App lifecycle · Universal Links · Keychain · Privacy Manifests · App Thinning

This section is **iOS for the RN engineer**: enough Swift, lifecycle, and platform knowledge to ship native modules, debug iOS-only issues, and pass the "do you know iOS?" senior-loop questions. Not a Swift book — it's the slice of iOS that matters when your app is React Native.

## Topics in this section

- [Q1. ARC and memory management — strong / weak / unowned](#q1-arc-and-memory-management--strong--weak--unowned)
- [Q2. GCD vs Swift Concurrency / Actors](#q2-gcd-vs-swift-concurrency--actors)
- [Q3. App lifecycle and background modes (BGTaskScheduler)](#q3-app-lifecycle-and-background-modes-bgtaskscheduler)
- [Q4. Universal Links, Associated Domains, App Groups, Keychain](#q4-universal-links-associated-domains-app-groups-keychain)
- [Q5. Privacy Manifests, App Thinning, App Slicing in 2026](#q5-privacy-manifests-app-thinning-app-slicing-in-2026)

---

## Q1. ARC and memory management — strong / weak / unowned

### Difficulty
Intermediate

### Interview Frequency
Common when interviewer is iOS-leaning; always when writing TurboModules.

### Prerequisites
Object lifecycle basics; reference vs value types.

### TL;DR
Swift uses **Automatic Reference Counting (ARC)** — every strong reference increments a count; the object frees when count hits zero. **Retain cycles** (mutual strong refs) leak. Break with `weak` (optional) or `unowned` (non-optional, must outlive).

### 30-Second Interview Answer
"Swift uses ARC: each strong reference bumps the retain count; deallocation happens at zero. The classic leak is a retain cycle — A holds B strongly, B holds A strongly, neither ever drops to zero. The fix is `weak` (becomes nil when target deallocates, must be optional) or `unowned` (assumes target outlives, crashes if not). In closures, `[weak self]` is the standard idiom."

### 2-Minute Practical Answer
ARC rules:
- Each strong ref +1; assigning to a new variable +1; nil-ing -1; scope exit -1.
- When count = 0, `deinit` runs; memory freed.
- Closures capture variables strongly by default → cycles when stored on `self`.

The four reference types:
- **strong** (default) — owns.
- **weak** — non-owning, optional, becomes nil when target frees. Safe.
- **unowned** — non-owning, non-optional, assumes target outlives. Crash if not.
- **unowned(unsafe)** — like raw pointer; never use.

In closures stored on `self` (network completion, animation, observer), use `[weak self]` and unwrap with `guard let self else { return }`.

In RN bridging:
- Native modules **retain JS callbacks** — release them when done or risk leaks.
- TurboModules in 2026 use `std::shared_ptr` / `std::weak_ptr` semantics in C++ — same rules.

### 5-Minute Architecture Answer
ARC is compile-time inserted reference counting (not GC). Insertion happens during SIL generation. Every assignment, copy, parameter pass, and return statement gets retain/release inserted by the compiler.

Why ARC over GC:
- Deterministic frees (predictable, important on mobile).
- No GC pause times (animations stay smooth).
- Lower memory overhead.

Why ARC has retain cycles (and GC doesn't):
- ARC is local: counts only direct refs; doesn't see global graph.
- GC traces from roots; cycles unreachable from roots are collected.
- ARC's tradeoff: simpler runtime, predictable perf, but cycles must be broken by hand.

In React Native iOS (2026):
- The bridge is gone (Bridgeless mode); JSI HostObjects sit in `std::shared_ptr` containers on the C++ side.
- A JSI ref to a native object pins it; if you hand a callback to JS and JS retains it, you have an effective cycle until JS lets go.
- TurboModules' Codegen handles most of this safely; the hand-rolled cases are where leaks happen.

Detection (2026):
- Xcode → Debug Memory Graph.
- Instruments → Allocations + Leaks template.
- `deinit` print-statements during dev.
- Sentry's iOS SDK reports OOM and abandoned-memory automatically.

### The "Why"
- Mobile RAM is constrained; one leaked screen = 50MB held forever.
- iOS jetsam kills apps silently when memory pressure rises; users see crashes, devs see "OOM" with no stack.

### Mental Model
ARC = "I hold this; when I let go, count decreases." Retain cycle = two friends each promising to call the other only after the other hangs up.

### Internal Working (2026 Context)
- Swift 5.10+ ARC has improved cycle detection in debug builds.
- Swift Concurrency (`Task`) captures `self` by default (strong); use `[weak self]` in closures, but `Task` blocks don't need it (they end naturally).
- Combine subscriptions held on self need cleanup or `.store(in: &cancellables)` with proper cancel.

### Modern Implementation (Code)

```swift
class ImageDownloader {
  func fetch(url: URL, completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
      completion(data.flatMap(UIImage.init))
    }.resume()
  }
}

// Retain-cycle prone
class ProfileVC: UIViewController {
  var downloader = ImageDownloader()
  var image: UIImage?

  func loadImage() {
    downloader.fetch(url: URL(string: "...")!) { img in
      self.image = img // captures self strongly inside escaping closure
    }
  }
}

// Fixed
func loadImage() {
  downloader.fetch(url: URL(string: "...")!) { [weak self] img in
    guard let self else { return }
    self.image = img
  }
}

// Swift Concurrency — Task captures self by default
class FeedVM {
  func refresh() {
    Task { [weak self] in
      guard let self else { return }
      let posts = try await api.posts()
      await MainActor.run { self.posts = posts }
    }
  }
}
```

### Comparison

| Reference | Becomes nil? | Optional? | Use |
|---|---|---|---|
| strong | No | No (unless declared) | Default ownership |
| weak | Yes | Yes (always) | Cycles, observers, delegates |
| unowned | Crashes | No | "Always outlives" — child→parent |
| unowned(unsafe) | UB | No | Never |

### Production Usage
- Delegates declared `weak var delegate: ...?`.
- Closure captures use `[weak self]` when stored on self.
- Combine subscriptions stored in a `Set<AnyCancellable>` on the owner.
- TurboModule callbacks released after invocation.

### Hands-On Exercise
1. Create a VC that retains a closure capturing `self`. Push/pop 10 times. Watch memory grow.
2. Add `[weak self]`. Re-test. Memory returns to baseline.
3. Use Xcode's Memory Graph debugger to visualize the cycle pre-fix.

### Common Mistakes
- Forgetting `weak var delegate`.
- Using `unowned` when the lifetime guarantee is unclear → crash.
- `[weak self]` then forgetting to unwrap (using optional chaining everywhere makes code messy).
- Holding native module strong refs to JS callbacks indefinitely.

### Production Red Flags
- Memory grows monotonically during navigation cycles.
- iOS-only OOM crashes in Sentry.
- Many `deinit`s never called in profiler.

### Performance & Metrics
- App memory baseline + delta after navigation.
- iOS jetsam events (visible in Console.app from device).
- Sentry "out of memory" issues.

### Decision Framework
- Owner relationship → strong.
- Mutual reference (delegate, parent ↔ child) → weak.
- "Always outlives" (e.g., view's owning VC) → unowned (carefully).

### Senior-Level Insight
"On iOS, every `self` capture in a closure is a question." If the closure is escaping and stored, default to `[weak self]`. If it's non-escaping (like `forEach`), strong is fine. Modern Swift Concurrency mostly removes manual `Task` storage, reducing cycles.

### Real-World Scenario
**Symptom:** Profile screens leak 10MB each.
**Investigation:** Memory Graph shows VC retained by an `@objc` notification observer.
**Root cause:** `addObserver(self, selector: ...)` retains observer strongly.
**Fix:** Block-based observer with `[weak self]`, or remove in `deinit`.

### Production Failure Story
**Incident:** OOM crashes spiked after a TurboModule was added to handle haptics.
**Investigation:** Module retained the JS callback array indefinitely.
**Root cause:** Forgot to clear callbacks after invocation.
**Fix:** Released callback after `invoke`.

### Debugging Checklist
1. Memory Graph after navigation cycle: any unexpected retainers?
2. `deinit` prints firing as expected?
3. Closures capturing `self` use `[weak self]`?
4. Observers / delegates declared `weak`?

### Advanced / Internal Knowledge
- ARC inserts retain/release at SIL level; sometimes fewer than written, due to ARC optimization passes.
- `withExtendedLifetime` keeps an object alive across critical sections.
- Swift 5.9+ `~Copyable` / move semantics affect how some types interact with ARC.

### 2026 AI Tip
AI sometimes generates Swift closures without `[weak self]`. Ask explicitly for `[weak self]` and `guard let self else { return }`.

### Related Topics
Q2 (Swift Concurrency, ownership in actors), S15 (TurboModule writing), S07 (perf).

### Interview Follow-Up Questions
- "Difference between weak and unowned?"
- "What is a retain cycle? Show one and fix it."
- "How do you detect leaks on iOS?"

### Memory Hook
**"Strong owns. Weak forgets. Unowned trusts."**

### Revision Notes
> ARC = compile-inserted retain/release; cycles need `weak` (optional) or `unowned` (non-optional); `[weak self]` in escaping closures stored on self; detect via Memory Graph + Instruments.

---

## Q2. GCD vs Swift Concurrency / Actors

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common at senior+ rounds (especially for native module work).

### Prerequisites
Threading basics, async I/O.

### TL;DR
**GCD (Grand Central Dispatch)** — block-based queue API, dominant pre-2021. **Swift Concurrency** — `async/await`, `Task`, `actor`, structured concurrency, dominant since Swift 5.5+. In 2026, Swift Concurrency is the default; GCD remains for low-level needs (real-time audio, dispatch sources).

### 30-Second Interview Answer
"GCD is Apple's older C-based concurrency: serial/concurrent queues, `DispatchQueue.main.async`, semaphores. Swift Concurrency is the modern primitive: `async/await`, structured tasks, and `actor` for data isolation. In 2026 I default to Swift Concurrency for app code; GCD only for legacy interop, real-time work, or when I need fine-grained control over QoS."

### 2-Minute Practical Answer
GCD essentials:
- `DispatchQueue.main.async { ... }` — UI work.
- `DispatchQueue.global(qos: .userInitiated).async { ... }` — background work.
- `DispatchSemaphore` for sync primitives.
- `DispatchSource` for kernel events / file watching.

Swift Concurrency essentials:
- `async func foo() async throws -> T` — declares async.
- `await foo()` — suspends until result.
- `Task { ... }` — unstructured task; `Task.detached` for independence.
- `async let` — concurrent child tasks.
- `withTaskGroup` — dynamic concurrency.
- `actor` — data isolation; methods serialized.
- `@MainActor` — guarantees execution on main thread.
- `Sendable` — compile-time data-race safety.

In RN-iOS:
- TurboModules can declare methods with `async` callbacks; the C++ binding handles thread hops.
- React Native's main thread = iOS main thread; UI updates via `RCTExecuteOnMainQueue`.
- Background work in native modules: prefer `Task.detached` over `DispatchQueue.global` in new code.

### 5-Minute Architecture Answer
GCD vs Swift Concurrency tradeoffs:

**GCD** is a kernel-aware C library (libdispatch). Strengths: stable, low overhead, works everywhere (Obj-C / C++), supports QoS classes natively. Weaknesses: untyped (block in/out), no data-race protection, easy to deadlock with semaphores, no compile-time safety.

**Swift Concurrency** is a higher-level model with three innovations:
1. **Structured concurrency** — child tasks die with parent; cancellation propagates; no leaked work.
2. **Actor isolation** — compiler enforces that mutable state lives on one actor; no manual locks.
3. **Sendable** — compile-time check that values crossing actor boundaries are safe.

Under the hood, Swift Concurrency uses **cooperative threading**: a small fixed pool of threads (typically `processorCount`); tasks suspend cooperatively at `await`. No thread explosion (a common GCD pitfall). The runtime is `libswift_Concurrency.dylib`.

`@MainActor` is a special actor pinned to the main run loop. UI code annotated with `@MainActor` is guaranteed to run on the main thread; the compiler enforces it.

In 2026, the Swift 6 mode brings **strict concurrency checking** by default; old GCD code often needs `Sendable` annotations to compile.

### The "Why"
- GCD let you write data races trivially. Swift Concurrency makes them compile errors.
- Structured concurrency removes "I forgot to cancel that task" leaks.
- Actors replace manual locks with a compiler-checked model.

### Mental Model
GCD = bare metal queues. Swift Concurrency = typed coroutines + actor model. Actors = "this data has one access lane; the compiler enforces it."

### Internal Working (2026 Context)
- Swift 6 strict concurrency on by default in new projects.
- `@MainActor` pervasive in SwiftUI / UIKit code.
- React Native's iOS native module API (TurboModules + Codegen) supports `async` Swift methods that auto-marshal across threads.
- Combine still common but Swift Concurrency is preferred for new code.

### Modern Implementation (Code)

```swift
// Old (GCD)
func loadProfile(id: String, completion: @escaping (Profile?) -> Void) {
  DispatchQueue.global(qos: .userInitiated).async {
    let data = try? Data(contentsOf: URL(string: "/profile/\(id)")!)
    let profile = data.flatMap { try? JSONDecoder().decode(Profile.self, from: $0) }
    DispatchQueue.main.async { completion(profile) }
  }
}

// 2026 Swift Concurrency
func loadProfile(id: String) async throws -> Profile {
  let url = URL(string: "/profile/\(id)")!
  let (data, _) = try await URLSession.shared.data(from: url)
  return try JSONDecoder().decode(Profile.self, from: data)
}

// Concurrent fetches via async let
func loadDashboard() async throws -> Dashboard {
  async let profile = loadProfile(id: "me")
  async let posts = loadPosts()
  async let stats = loadStats()
  return try await Dashboard(profile: profile, posts: posts, stats: stats)
}

// Actor for shared mutable state
actor TokenCache {
  private var token: String?
  func get() -> String? { token }
  func set(_ t: String) { token = t }
}

// MainActor for UI
@MainActor
final class FeedVM: ObservableObject {
  @Published var posts: [Post] = []
  func refresh() async throws {
    posts = try await loadPosts()
  }
}
```

### Comparison

| Aspect | GCD | Swift Concurrency |
|---|---|---|
| Syntax | Closures | `async / await` |
| Cancellation | Manual | Built-in; propagates |
| Data races | Easy to write | Compiler-enforced via actors / Sendable |
| Thread model | Direct dispatch | Cooperative, fixed pool |
| Backpressure | Manual | Structured (TaskGroup limits) |
| Interop with C/Obj-C | Easy | Wrapped via callbacks |

### Production Usage
- New code → Swift Concurrency by default.
- Audio / real-time → GCD or Audio Unit threads.
- TurboModules with async API → expose Swift `async` methods; Codegen wraps as Promise on JS side.

### Hands-On Exercise
1. Convert a GCD-based callback API in your codebase to `async/await`. Notice cancellation now works.
2. Wrap a shared mutable state behind an `actor`. Remove existing locks.
3. Add `@MainActor` to a view-model. Watch threading bugs disappear from logs.

### Common Mistakes
- Forgetting `@MainActor` on UI-updating types → background-thread UI updates → crashes.
- Mixing GCD locks with `await` → deadlock.
- Using `Task.detached` when you wanted structured (loses cancellation propagation).
- Storing raw `Task` and forgetting to `cancel()` on dealloc.

### Production Red Flags
- "Modifying state from background thread" warnings in console.
- Random crashes on UIKit/SwiftUI updates.
- GCD semaphores in new code (almost always wrong with Swift Concurrency).

### Performance & Metrics
- Main thread idle % (Instruments).
- Task scheduling latency.
- Number of leaked Tasks (Memory Graph).

### Decision Framework
- New async work → Swift Concurrency.
- Sharing mutable state → actor.
- UI work → `@MainActor`.
- Real-time / audio → GCD or platform-specific.

### Senior-Level Insight
The deepest Swift 6 culture shift: stop manually managing threads. Annotate intent (`@MainActor`, `actor`, `Sendable`) and let the compiler enforce. Most concurrency bugs disappear at compile time.

### Real-World Scenario
**Symptom:** Random app crashes when refreshing the feed.
**Investigation:** Crash log shows UI mutation off main thread.
**Root cause:** Background async function called `view.setNeedsLayout()`.
**Fix:** Wrap call in `await MainActor.run { ... }` or annotate the type `@MainActor`.

### Production Failure Story
**Incident:** Native module that wraps a network library deadlocked on iOS 17.
**Investigation:** Module used `DispatchSemaphore.wait()` to convert async to sync; the network library used Swift Concurrency under the hood; suspending on the same cooperative thread.
**Fix:** Made the bridge async; promise-based on JS side.
**Prevention:** Never block the cooperative pool with semaphores.

### Debugging Checklist
1. Is the type updating UI annotated `@MainActor`?
2. Is shared mutable state behind an `actor`?
3. Are tasks structured (no orphaned `Task.detached`)?
4. Are GCD semaphores absent from async code paths?

### Advanced / Internal Knowledge
- Swift Concurrency uses **executor jobs**; the runtime can change executors via `withCheckedContinuation`.
- `@globalActor` lets you define your own (e.g., `@DatabaseActor`).
- `TaskLocal` propagates context (analytics, request-id) automatically across child tasks.

### 2026 AI Tip
AI mixes GCD and Swift Concurrency in the same example. Standardize on Swift Concurrency for new code; explicitly ask AI to remove GCD primitives.

### Related Topics
Q1, Q3, S15 (TurboModule writing).

### Interview Follow-Up Questions
- "Why use `actor` over a `DispatchQueue`-protected variable?"
- "What does `@MainActor` actually guarantee?"
- "How does structured concurrency change cancellation?"

### Memory Hook
**"GCD = queues. Swift = actors. MainActor for UI."**

### Revision Notes
> Swift Concurrency = async/await + actors + structured tasks; replaces GCD for new code; `@MainActor` for UI; `actor` for shared state; cooperative thread pool, no thread explosion.

---

## Q3. App lifecycle and background modes (BGTaskScheduler)

### Difficulty
Intermediate

### Interview Frequency
Common when interviewer is iOS-leaning or app does background work.

### Prerequisites
Basic iOS app structure (AppDelegate / SceneDelegate).

### TL;DR
iOS app states: **Not Running → Inactive → Active → Background → Suspended**. Background work needs **declared modes** (location, audio, VoIP, fetch) plus **BGTaskScheduler** for periodic / processing tasks. iOS aggressively suspends; design for it.

### 30-Second Interview Answer
"iOS apps move through Not Running → Inactive → Active → Background → Suspended. The system gives a few seconds in `applicationDidEnterBackground` for cleanup. For deferred work I use `BGTaskScheduler` — register `BGAppRefreshTask` (short, ~30s) and `BGProcessingTask` (longer, plug-in/Wi-Fi only). For continuous work I declare a background mode (audio, location, VoIP). RN's headless tasks are mostly Android; on iOS, pure JS background work is constrained."

### 2-Minute Practical Answer
States and transitions:
- **Not Running** — never launched or terminated.
- **Inactive** — about to enter foreground or temporary interruption (incoming call).
- **Active** — foreground, receiving events.
- **Background** — recently moved out; ~5 seconds for cleanup before suspension.
- **Suspended** — frozen in memory; no code runs.

Lifecycle hooks (SceneDelegate / AppDelegate):
- `sceneDidBecomeActive` — UI ready.
- `sceneWillResignActive` — interruption.
- `sceneDidEnterBackground` — clean up; save state.
- `sceneWillEnterForeground` — restore.

Background execution options:
1. **Background Modes (Capabilities)** — audio, location, VoIP, external accessory, NewsstandKit, BLE central/peripheral, background fetch (deprecated → BGTaskScheduler), processing, voice-over-IP, push.
2. **BGTaskScheduler** (iOS 13+) — `BGAppRefreshTask` (~30s, opportunistic), `BGProcessingTask` (longer, can require power/network).
3. **Silent push** — `content-available: 1` wakes app briefly; budget-limited.
4. **PushKit (VoIP)** — high-priority wake for calls.

In RN context:
- Most background work is delegated to native (CoreLocation for location, AVFoundation for audio).
- For "fetch latest data on wake," register a BGTask that calls a native sync; emit event to JS when app resumes.
- Avoid expecting JS to run while backgrounded on iOS — it doesn't reliably.

### 5-Minute Architecture Answer
iOS's background model is **opportunistic and budgeted**. The system runs your code only when:
- It's likely useful (user actually returns soon).
- The device is charging or on Wi-Fi (for processing).
- Battery and thermal headroom allow.

The system tracks per-app **execution budgets**; a chatty app gets less time over time. This is the opposite of Android's WorkManager which is more deterministic.

Architecture for cross-platform background sync:
- **JS → native bridge** to schedule the right OS primitive on each platform.
- **Native module** does the work in OS-allowed time; persists results.
- **App resume** reads the persisted results and updates UI.
- **Telemetry** reports actual fire times (often much less frequent than scheduled).

For new architecture in 2026:
- TurboModules expose BGTaskScheduler as Promise-based APIs.
- Expo's `expo-background-fetch` and `expo-task-manager` wrap this for you.
- Libraries like `react-native-background-fetch` (Christopher Lambacher) remain popular.

Memory considerations:
- Background-resumed apps may be partially cleared from memory; design for fast cold-warm distinction.
- Hermes is preserved on iOS for app refresh tasks; JS context may already be alive.

### The "Why"
- Mobile OSs prioritize battery and responsiveness; uncontrolled background work would devastate both.
- iOS's restrictions force engineers into correct patterns (offline-first, sync-on-resume) that are robust anyway.

### Mental Model
iOS background = **maybe-execution**. Schedule with hope; verify on resume; don't depend on a specific cadence.

### Internal Working (2026 Context)
- iOS 17+ tightened silent push budgets.
- iOS 18's "Background Assets" capability allows pre-downloading assets for new installs.
- BGTaskScheduler in 2026 supports `earliestBeginDate` and `requiresExternalPower` / `requiresNetworkConnectivity`.

### Modern Implementation (Code)

```swift
// Register tasks at launch
BGTaskScheduler.shared.register(
  forTaskWithIdentifier: "com.acme.refresh",
  using: nil
) { task in
  guard let task = task as? BGAppRefreshTask else { return }
  Task {
    do {
      try await SyncEngine.shared.syncRecent()
      task.setTaskCompleted(success: true)
    } catch {
      task.setTaskCompleted(success: false)
    }
  }
}

// Schedule when app backgrounds
func sceneDidEnterBackground(_ scene: UIScene) {
  let request = BGAppRefreshTaskRequest(identifier: "com.acme.refresh")
  request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30) // 30 min
  try? BGTaskScheduler.shared.submit(request)
}
```

```swift
// Long processing task (charging + Wi-Fi)
let processing = BGProcessingTaskRequest(identifier: "com.acme.archive")
processing.requiresExternalPower = true
processing.requiresNetworkConnectivity = true
try? BGTaskScheduler.shared.submit(processing)
```

```ts
// JS side — listen for app state to refresh data after BG sync
import { AppState } from 'react-native';

useEffect(() => {
  const sub = AppState.addEventListener('change', (state) => {
    if (state === 'active') queryClient.invalidateQueries({ queryKey: ['feed'] });
  });
  return () => sub.remove();
}, []);
```

### Comparison

| Mechanism | When fires | Duration | Reliability |
|---|---|---|---|
| Background Modes (location/audio) | Continuously when triggered | Indefinite | High (with capability) |
| BGAppRefreshTask | Opportunistic | ~30s | Medium |
| BGProcessingTask | Off-hours, plugged in | Minutes | Medium-low |
| Silent push | On push receive | ~30s | Budget-limited |
| PushKit VoIP | Immediate | Until call ends | High |

### Production Usage
- Chat apps use silent push + BGTaskScheduler combo.
- Maps/fitness use `location` background mode (with proper purpose strings).
- Music players use `audio` background mode.
- Most apps: schedule BG refresh for 30 min cadence; treat any actual fire as a bonus.

### Hands-On Exercise
1. Add BGTaskScheduler with a sync handler. Use Xcode's `_simulateLaunchForTaskWithIdentifier` to trigger.
2. Log fire times to Sentry. Compare to your expected cadence.
3. Add a silent push trigger; measure delivery rate vs sent.

### Common Mistakes
- Expecting BG tasks to run on a strict schedule.
- Not testing BG with the simulator command (`expirationHandler` rarely fires in dev otherwise).
- Long sync work without check-points → expiration kills mid-flight.
- Forgetting purpose strings in `Info.plist` → store rejection.

### Production Red Flags
- App requests location "always" without clear UX — store reject.
- BG task that takes > 30s without using BGProcessingTask.
- No `expirationHandler` to clean up if killed.

### Performance & Metrics
- Actual fire rate vs scheduled (per Sentry / analytics).
- Time-to-task-completion.
- App-resume staleness (data freshness on cold open).

### Decision Framework
- Need "always running" → declare background mode (justify in App Store review).
- Need periodic "freshen up" → BGAppRefreshTask.
- Need long-running work → BGProcessingTask (off-hours).
- Need "wake on event" → silent push or PushKit.

### Senior-Level Insight
Design for "tasks may never fire." Build offline-first sync, opportunistic refresh, and clear UX for "data may be stale." iOS users notice broken background more than missing background.

### Real-World Scenario
**Symptom:** Users complain "my data is always old when I open the app."
**Investigation:** BGAppRefreshTask was scheduled but firing 0.3× per day on average.
**Fix:** Combined with silent pushes from server when new data arrives + AppState listener for foreground refresh.
**Lesson:** Don't depend on BG; use it as a bonus.

### Production Failure Story
**Incident:** App rejected by App Store for using `location: always` to keep BG sync alive.
**Root cause:** Engineering shortcut — used location mode for non-location work.
**Fix:** Removed location mode; restructured around proper BG mechanisms.

### Debugging Checklist
1. Is the BG task identifier registered before launch finishes?
2. Are you submitting only one of each identifier at a time?
3. Are purpose strings + capabilities set?
4. Are you handling `expirationHandler` to checkpoint?

### Advanced / Internal Knowledge
- iOS predicts user's app usage; "frequently used in the morning" apps get more morning BG opportunities.
- The system enforces a per-day budget; abusing pushes lowers it.
- BGTaskScheduler can be tested only on real devices reliably.

### 2026 AI Tip
AI often suggests `applicationDidEnterBackground` long-running work — that pattern is broken on iOS. Push AI to use BGTaskScheduler instead.

### Related Topics
Q4, S12 (push), S11 (offline-first).

### Interview Follow-Up Questions
- "How would you sync data periodically on iOS?"
- "Difference between BGAppRefreshTask and BGProcessingTask?"
- "Why can't you just run a `setInterval` in JS while backgrounded?"

### Memory Hook
**"iOS BG = maybe-execution. Schedule with hope; refresh on resume."**

### Revision Notes
> iOS lifecycle: Active → Background (~5s) → Suspended; BGTaskScheduler for periodic (BGAppRefreshTask) and long (BGProcessingTask, charge/Wi-Fi); declare background modes for continuous; design for "may never fire."

---

## Q4. Universal Links, Associated Domains, App Groups, Keychain

### Difficulty
Intermediate

### Interview Frequency
Common at senior+ rounds (real-world iOS).

### Prerequisites
URL schemes, basic iOS entitlements.

### TL;DR
**Universal Links** — `https://` URLs that open in your app via Associated Domains (no custom scheme). **App Groups** — share storage (UserDefaults, Files) between app + extensions. **Keychain** — encrypted KV with biometric-gated access; the right place for secrets.

### 30-Second Interview Answer
"Universal Links use a server-hosted `apple-app-site-association` file plus the Associated Domains entitlement so HTTPS URLs open in-app instead of Safari. App Groups give you a shared container for app + extensions (widgets, share sheet). Keychain is the encrypted KV; I store auth tokens with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and biometric ACLs for sensitive items."

### 2-Minute Practical Answer
**Universal Links setup:**
1. Add `applinks:yourdomain.com` to Associated Domains capability.
2. Host `https://yourdomain.com/.well-known/apple-app-site-association` (no extension, content-type `application/json`):
   ```json
   { "applinks": {
       "details": [{
         "appIDs": ["TEAMID.com.acme.app"],
         "components": [{ "/": "/profile/*" }, { "/": "/posts/*" }]
       }]
     }
   }
   ```
3. Handle in `scene(_:continue:)` or via React Navigation / Expo Router linking config.

**App Groups:**
- Capability + container ID (`group.com.acme.shared`).
- `UserDefaults(suiteName: "group.com.acme.shared")` shared between app + widget + share extension.
- `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)` for shared files.

**Keychain:**
- `Security.framework` API; queries via `CFDictionary`.
- Use libraries: `KeychainAccess` (Swift) or `react-native-keychain` (JS).
- Always set accessibility class — `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for tokens (cleared on backup restore to a different device).
- Biometric ACL for high-value items: `SecAccessControlCreateWithFlags(... .biometryCurrentSet)`.

### 5-Minute Architecture Answer
Universal Links replaced custom URL schemes (`myapp://`) because schemes can be hijacked — any app can claim them, and the system picks unpredictably. Universal Links bind to a verified domain via the AASA file.

The verification flow:
1. App installs → iOS fetches AASA from each `applinks:` domain.
2. iOS caches the file (refresh on app update).
3. Tap a matching link → iOS opens app directly; no Safari hop.
4. Fallback: if app not installed, opens in Safari (your web page).

Common pitfalls:
- AASA must be served at `/.well-known/apple-app-site-association` over HTTPS, content-type `application/json`, no redirects.
- Apple's CDN caches; updates can take hours to propagate.
- Web fallback URL should match the deep link (not 404) for users without the app.

App Groups enable the **app + extensions** model — widgets, share sheet, action extensions, intents. Without an app group, extensions can't see the app's data. The shared container is sandbox-isolated to the group ID.

Keychain is the **only place** for secrets on iOS. Why:
- Encrypted at rest with hardware key (Secure Enclave on supported devices).
- Survives app reinstall (unless `ThisDeviceOnly` accessibility).
- Biometric ACLs make tokens require Face ID / Touch ID per use.

In RN 2026, `react-native-keychain` and `expo-secure-store` wrap this; both support biometric ACLs.

### The "Why"
- URL schemes leak; Universal Links provide identity.
- App + extensions need shared data; App Groups are the only sanctioned way.
- Tokens in `UserDefaults` are a security audit failure; Keychain is the right answer.

### Mental Model
- Universal Link = HTTPS URL with iOS's blessing to open your app.
- App Group = shared sandbox between siblings.
- Keychain = encrypted KV with hardware backing.

### Internal Working (2026 Context)
- iOS 17+ requires `Use of` purpose strings for Keychain access in some categories (background sync).
- Universal Links AASA can include `paths` (legacy) or `components` (newer, with query/fragment matching).
- Expo Router supports typed Universal Links via `linking` config; deep-link types derived from route tree.

### Modern Implementation (Code)

```swift
// SceneDelegate
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
  guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
        let url = userActivity.webpageURL else { return }
  // Hand off to RN's linking
  RCTLinkingManager.application(.shared, continue: userActivity, restorationHandler: { _ in })
}
```

```ts
// React Native side (Expo Router)
// app/_layout.tsx
import { useLinkingURL } from 'expo-router';

// app/profile/[id].tsx — automatic from URL pattern
```

```swift
// Keychain with biometric ACL
let access = SecAccessControlCreateWithFlags(
  nil,
  kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
  .biometryCurrentSet,
  nil
)
let query: [String: Any] = [
  kSecClass as String: kSecClassGenericPassword,
  kSecAttrService as String: "com.acme.token",
  kSecValueData as String: tokenData,
  kSecAttrAccessControl as String: access as Any
]
SecItemAdd(query as CFDictionary, nil)
```

```ts
// react-native-keychain (JS)
import * as Keychain from 'react-native-keychain';
await Keychain.setGenericPassword('user', token, {
  accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET,
  accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
});
```

### Comparison

| Storage | Encrypted | Shared with extensions | Biometric ACL | Backup |
|---|---|---|---|---|
| UserDefaults | No | With App Group | No | Yes |
| App Group container | No (file system) | Yes | No | Yes |
| Keychain | Yes (HW) | With group | Yes | Configurable |
| MMKV | Optional | With App Group | No | Configurable |

### Production Usage
- Auth tokens → Keychain with biometric ACL on high-value apps.
- Widgets read from App Group UserDefaults.
- Universal Links for marketing campaigns; track open rates via UTM parameters.

### Hands-On Exercise
1. Set up Universal Links for one route. Test with a Note app link tap (which honors UL).
2. Build a widget that reads shared UserDefaults; update from app.
3. Store a fake token in Keychain with biometric ACL; verify Face ID prompt on read.

### Common Mistakes
- AASA file at wrong path or wrong content-type.
- Forgetting team prefix in `appIDs` (must be `TEAMID.bundle.id`).
- Storing tokens in UserDefaults / AsyncStorage (security audit fail).
- Keychain accessibility too permissive (`AccessibleAlways` should never be used).

### Production Red Flags
- Custom URL schemes still in use as primary deep-link.
- Tokens in plain text storage.
- Widget extension reading from app's main container directly (won't work).

### Performance & Metrics
- Universal Link resolution time (instrument from tap to first render).
- Keychain access latency (rare but biometric prompts add user-perceived delay).
- Widget refresh cadence vs intent.

### Decision Framework
- Deep links → Universal Links + Expo Router.
- App + widget data sharing → App Group.
- Secrets → Keychain (with biometric ACL for high-value).

### Senior-Level Insight
"Treat Keychain as the only legitimate secret store on iOS." Even if the app stores tokens in MMKV for speed, the durable copy lives in Keychain — surviving app reinstalls and surviving migrations.

### Real-World Scenario
**Symptom:** Universal Links open Safari instead of the app for some users.
**Investigation:** AASA file changed to include a redirect.
**Root cause:** Apple's fetcher doesn't follow redirects.
**Fix:** Serve AASA directly, no redirect, no extension.

### Production Failure Story
**Incident:** Security review found tokens stored in NSUserDefaults.
**Root cause:** Engineer used the easiest API.
**Fix:** Migrated to Keychain with `WhenUnlockedThisDeviceOnly`; added biometric ACL for refresh tokens.

### Debugging Checklist
1. AASA fetched? `swcutil show` on macOS dev tool, or Console.app on device for `swcd` logs.
2. Is the App Group entitlement matching exactly across app + extension?
3. Is Keychain item being added with `kSecAttrAccessControl`?
4. Universal Link query/fragment parsing matches your routes?

### Advanced / Internal Knowledge
- AASA can specify per-component `comment` to disable in App Clips vs full app.
- Keychain's `kSecUseDataProtectionKeychain` is required on macOS; opt-in on iOS for forward compat.
- App Groups containers count toward app's size for App Store quota.

### 2026 AI Tip
AI sometimes suggests `UserDefaults` for tokens — always replace with Keychain. AI is good at generating AASA files; verify with `applinks-validator`.

### Related Topics
Q5, S10 (auth), S12 (push deep linking).

### Interview Follow-Up Questions
- "Universal Links vs custom URL schemes?"
- "Where would you store a refresh token on iOS?"
- "How do widgets share data with the host app?"

### Memory Hook
**"AASA for links. App Group for siblings. Keychain for secrets."**

### Revision Notes
> Universal Links via AASA + Associated Domains entitlement; App Groups for app+extension sharing; Keychain for secrets with biometric ACL + `WhenUnlockedThisDeviceOnly`.

---

## Q5. Privacy Manifests, App Thinning, App Slicing in 2026

### Difficulty
Intermediate

### Interview Frequency
Very Common in 2026 (App Store enforcement).

### Prerequisites
Basic Xcode build knowledge.

### TL;DR
**Privacy Manifests (`PrivacyInfo.xcprivacy`)** declare data collection + required-reason API usage; mandatory in 2026. **App Thinning** = App Slicing (per-device-arch slice) + Bitcode (deprecated) + On-Demand Resources. **App Slicing** auto-shrinks per-device installs; ODR defers asset downloads.

### 30-Second Interview Answer
"Privacy Manifests are now mandatory: a `PrivacyInfo.xcprivacy` file declares what data my app and its SDKs collect, plus reasons for using "required reason APIs" like UserDefaults timestamps, file system size, etc. App Thinning is Apple's umbrella for shrinking installs — App Slicing strips arch slices per device, On-Demand Resources defer assets, and Bitcode was deprecated in Xcode 14. In 2026, RN apps with non-compliant SDKs are getting rejected; I audit every native dep."

### 2-Minute Practical Answer
**Privacy Manifests (PrivacyInfo.xcprivacy):**
- Required for the app + every embedded SDK on Apple's "tracking SDKs" list.
- Declares:
  - Data collected (name, link to user, used for tracking).
  - "Required reason" API usage (e.g., why you call `NSUserDefaults`'s timestamp APIs).
  - Tracking domains (must match SKAdNetwork rules).
- Apple validates at submission; non-compliant submissions are blocked.

**App Thinning components:**
- **App Slicing** (default, automatic) — App Store ships only the architecture / asset variant for the user's device.
- **On-Demand Resources** — tag asset bundles; download on first use.
- **Bitcode** — deprecated since Xcode 14 (no longer required or accepted).

In RN 2026:
- Each major library publishes its `PrivacyInfo.xcprivacy`. Audit your top dependencies (Reanimated, Sentry, Firebase, RevenueCat) — most ship one in their podspecs now.
- For your app, declare collected data based on actual usage (not theoretical).
- Use Xcode's "Privacy Report" in build settings to see aggregated collection across all SDKs.

### 5-Minute Architecture Answer
The 2024–2026 privacy crackdown reshaped iOS distribution:

1. **Privacy Manifests** — Apple shifted from "trust the developer" to "declare in machine-readable format." A SDK's manifest aggregates into the app's report, which surfaces in Apple's Privacy Nutrition Labels and developer console. False declarations are policy violations.

2. **Required-reason APIs** — APIs that were historically misused for fingerprinting (file timestamps, free disk space, system uptime) now require a declared reason from a fixed allow-list. Common reasons: "DDA9.1" (file timestamps for app's own data), "C617.1" (disk space for app cache management).

3. **Tracking domains** — if you call out to `*.tracking-domain.com`, declare them; iOS will block them when ATT is denied.

4. **App Thinning** — automatic, but only effective if your app is **architecturally clean**:
   - Multiple architectures only when needed (arm64 only for modern apps).
   - Asset catalogs (xcassets) so per-density images can be sliced.
   - On-Demand Resources for game-style apps with optional content packs.

5. **Background Assets capability** (iOS 17+) — pre-download large assets (videos, levels) for new installs *before* user opens the app, improving cold start.

In 2026, the app size war has new metrics: install size (what users see in App Store), download size (compressed transfer), runtime size (after expansion). Apple Connect shows all three; aim for < 200MB compressed for general consumer apps.

### The "Why"
- Apple's stance: opaque data collection erodes trust; SDKs were the worst offenders.
- App size affects install rate (each 100MB above 200 reduces install rate measurably).
- Privacy Manifests give users transparency and Apple a lever to enforce.

### Mental Model
PrivacyInfo = labeled ingredients on a food package, but for data + APIs.

### Internal Working (2026 Context)
- Required-reason APIs published in Apple's docs; updated quarterly.
- Apple's submission validator runs `xcprivacy` parser; structural errors block upload.
- Xcode 16+ surfaces missing manifests as warnings during archive.

### Modern Implementation (Code)

```xml
<!-- ios/YourApp/PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <true/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
      </array>
    </dict>
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>CA92.1</string> <!-- access app-owned defaults -->
      </array>
    </dict>
  </array>
  <key>NSPrivacyTracking</key>
  <false/>
</dict>
</plist>
```

```ruby
# ios/Podfile — ensure libraries with manifests are included
pod 'Sentry', '~> 8.x'   # Sentry ships PrivacyInfo
pod 'react-native-mmkv', :path => '../node_modules/react-native-mmkv'
```

### Comparison

| Concern | Mechanism | Default |
|---|---|---|
| Per-device arch | App Slicing | Auto |
| Optional assets | On-Demand Resources | Opt-in |
| LLVM IR | Bitcode | Deprecated |
| Privacy declaration | xcprivacy | Required |
| Pre-download assets | Background Assets | Opt-in |

### Production Usage
- Audit `node_modules/**/PrivacyInfo.xcprivacy` quarterly; add manifests to libraries that don't ship one (PR upstream).
- Monitor app size in App Store Connect; alert on increases > 5MB per release.
- Use Background Assets for video onboarding to avoid first-launch slowdown.

### Hands-On Exercise
1. Open Xcode → Product → Archive → Validate App. Read the privacy report. Compare to your declared manifest.
2. Run `xcrun grep` over your `node_modules` for `PrivacyInfo.xcprivacy` to inventory shipped manifests.
3. Use Xcode's "App Thinning Size Report" to see per-device install sizes.

### Common Mistakes
- Copying a sample manifest without verifying actual data collection.
- Missing Required-Reason API declarations (e.g., calling `FileManager` size APIs without reason).
- Including arm64e or armv7 unnecessarily.
- Bundling 2× / 3× / 4× images outside an asset catalog (no slicing).

### Production Red Flags
- App rejected at submission with "Missing Privacy Manifest."
- App size growing > 10MB per release without explanation.
- Old SDKs (pre-2024 versions) without manifests.

### Performance & Metrics
- Install size per device class (App Store Connect → App Analytics).
- Cold start time vs install size correlation.
- Privacy report counts of collected data types.

### Decision Framework
- Heavy onboarding assets → Background Assets capability.
- Game-style optional packs → On-Demand Resources.
- Default → trust App Slicing; just keep dependencies clean.

### Senior-Level Insight
The 2026 reality: every senior iOS round asks about Privacy Manifests. Have a story about an SDK audit you led, or a size-shrink campaign with metrics.

### Real-World Scenario
**Symptom:** App rejected from Apple submission with "ITMS-91056: Invalid privacy manifest" pointing to a third-party RN library.
**Investigation:** Library at version 2.x; manifest added in 3.x.
**Fix:** Upgrade library or add manifest locally via post-install Podfile hook.

### Production Failure Story
**Incident:** Submission blocked for 48 hours during a critical release.
**Root cause:** SDK update introduced a new required-reason API call without updating manifest.
**Fix:** Added the reason; submitted with hotfix.
**Prevention:** Pre-submission CI step that runs `xcprivacy` validation.

### Debugging Checklist
1. Does every embedded SDK have a `PrivacyInfo.xcprivacy`?
2. Does the app's manifest list every collected data type?
3. Are required-reason APIs declared with valid reason codes?
4. Is install size tracked per release?

### Advanced / Internal Knowledge
- Apple's enforcement is primarily at submission; runtime enforcement is light.
- The privacy report is generated client-side at archive time; cache invalidation can hide changes.
- Background Assets requires server-side asset hosting + signed manifests.

### 2026 AI Tip
AI generates outdated privacy manifests; always cross-check against Apple's current required-reason API list (updated quarterly).

### Related Topics
Q4, S10 (security), S30 (privacy / compliance).

### Interview Follow-Up Questions
- "Why does Apple require Privacy Manifests now?"
- "How does App Slicing work?"
- "What's a 'required-reason API'?"

### Memory Hook
**"Manifest declares. Slicing thins. Background assets pre-fetch."**

### Revision Notes
> PrivacyInfo.xcprivacy mandatory in 2026; declare collected data + required-reason APIs; App Slicing is auto; ODR for optional content; Background Assets pre-downloads for new installs; audit SDKs quarterly.

---

> Cross-refs: S10 (auth + Keychain), S12 (push), S15 (TurboModules in Swift), S20 (release / signing), S30 (privacy).
