## Appendix H — Gap-fill: topics promised by the handbook but missing earlier

> Theory + code + real-world problem + solution. Read after Appendix G.

---

### H.1 — Push Notifications (FCM + APNs + Expo)

**Theory**: FCM delivers to Android, APNs to iOS. Expo Notifications wraps both. Three message kinds:
- **Notification message** — system shows alert; OS handles when app killed.
- **Data-only / silent push** — app code runs on receipt; budget-limited on iOS, throttled on Android Doze.
- **Notification + data** — alert + custom payload (recommended for routing).

**Setup (Expo)**:
```ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true, shouldPlaySound: true, shouldSetBadge: true,
  }),
});

export async function registerForPush() {
  if (!Device.isDevice) return null;
  const { status: existing } = await Notifications.getPermissionsAsync();
  let status = existing;
  if (status !== 'granted') ({ status } = await Notifications.requestPermissionsAsync());
  if (status !== 'granted') return null;
  const token = (await Notifications.getExpoPushTokenAsync({ projectId: '...' })).data;
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'default', importance: Notifications.AndroidImportance.HIGH,
      vibrationPattern: [0, 250, 250, 250], lightColor: '#FF231F7C',
    });
  }
  return token;
}
```

**Routing on tap (deep link via notification)**:
```ts
useEffect(() => {
  const sub = Notifications.addNotificationResponseReceivedListener((resp) => {
    const data = resp.notification.request.content.data as { route?: string; params?: any };
    if (data.route) navigationRef.navigate(data.route, data.params);
  });
  return () => sub.remove();
}, []);
```

**Real production problems & solutions**:
| Problem | Cause | Fix |
|---|---|---|
| Notifications delayed 10+ min on Xiaomi/Oppo | OEM kills background services | Send as `priority: high` FCM, prompt user to disable battery optimization, fall back to sync-on-open |
| Duplicate notifications | Multiple FCM tokens registered for same device | Server-side dedupe by `installation_id`; clean tokens on app reinstall |
| Notification opens wrong screen on cold start | Initial notification not handled | Use `getLastNotificationResponseAsync()` on launch + buffer until navigator ready |
| iOS silent push not delivered | Wrong `content-available: 1` or low system priority | Use `apns-priority: 5`, payload size ≤4KB, no UI keys |
| Notifications on Android 13+ never appear | `POST_NOTIFICATIONS` permission required | Request runtime permission post-install, gracefully degrade |

---

### H.2 — Accessibility (a11y) + Internationalization (i18n)

**Theory**: WCAG 2.2 AA is the baseline. RN exposes `accessibilityLabel`, `accessibilityHint`, `accessibilityRole`, `accessibilityState`. Screen readers: VoiceOver (iOS), TalkBack (Android). 4.5:1 contrast for body text, 3:1 for large text. Min touch target 44×44 pt (iOS) / 48×48 dp (Android).

**Code — accessible button**:
```jsx
<Pressable
  onPress={onSubmit}
  accessible
  accessibilityRole="button"
  accessibilityLabel="Confirm payment of ₹2,499"
  accessibilityHint="Double-tap to charge your card"
  accessibilityState={{ disabled: loading, busy: loading }}
  style={({ pressed }) => [styles.btn, pressed && styles.btnPressed]}
>
  <Text style={styles.btnText}>Pay ₹2,499</Text>
</Pressable>
```

**Color-blind safe palette** — never use color alone. Pair with icon/text.
```jsx
<View style={{ flexDirection: 'row', alignItems: 'center' }}>
  <Icon name={ok ? 'check' : 'alert'} color={ok ? '#0a7' : '#c33'} />
  <Text>{ok ? 'Verified' : 'Failed — retry'}</Text>
</View>
```

**Dynamic type / font scaling**:
```jsx
<Text allowFontScaling style={{ fontSize: 16 }} maxFontSizeMultiplier={1.6}>
  Body
</Text>
```
Cap multiplier (1.4–1.6) to prevent layout breakage on max accessibility font.

**i18n with `i18next`**:
```ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
i18n.use(initReactI18next).init({
  resources: { en: { tr: { hello: 'Hello {{name}}' } }, hi: { tr: { hello: 'नमस्ते {{name}}' } } },
  lng: 'en', fallbackLng: 'en', interpolation: { escapeValue: false },
});

// component
const { t, i18n } = useTranslation('tr');
<Text>{t('hello', { name: 'Rajeev' })}</Text>
```

**RTL handling**:
```ts
import { I18nManager } from 'react-native';
I18nManager.allowRTL(true);
I18nManager.forceRTL(lang === 'ar');
// requires app reload (RNRestart) to take effect
```

**Real problems**:
| Problem | Solution |
|---|---|
| VoiceOver reads "image" for an icon button | Add `accessibilityLabel` + `accessibilityRole="button"` |
| Modal blocks screen reader from reaching content behind | Use `accessibilityViewIsModal` on iOS, `importantForAccessibility="yes-hide-descendants"` on siblings |
| RTL flips icons that shouldn't flip (e.g., logo) | Wrap with `style={{ transform: [{ scaleX: I18nManager.isRTL ? -1 : 1 }] }}` only on directional icons |
| Large fonts break button width | Use `numberOfLines`, `adjustsFontSizeToFit` (iOS), `flexShrink: 1` |

---

### H.3 — Android platform deep (lifecycle, Gradle, R8/Proguard)

**Activity lifecycle (RN single-activity)**:
`onCreate` → `onStart` → `onResume` → (running) → `onPause` → `onStop` → `onDestroy`. RN entry point `MainActivity` extends `ReactActivity`.

**ANR debugging**:
```sh
adb shell ps | grep com.app
adb pull /data/anr/traces.txt   # main-thread stack snapshots
adb logcat -s ActivityManager:I  # ANR markers
```

**Gradle build variants** (`android/app/build.gradle`):
```groovy
android {
  flavorDimensions "env"
  productFlavors {
    dev      { applicationIdSuffix ".dev"; resValue "string", "app_name", "App Dev" }
    staging  { applicationIdSuffix ".staging" }
    prod     { /* default */ }
  }
  buildTypes {
    release {
      minifyEnabled true
      shrinkResources true
      proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
    }
  }
}
```

**R8/Proguard rules — keep RN Hermes intact**:
```
-keep class com.facebook.hermes.unicode.** { *; }
-keep class com.facebook.jni.** { *; }
-keepattributes *Annotation*,SourceFile,LineNumberTable
```

**APK size reduction**:
- Enable Hermes + R8.
- ABI splits: `splits { abi { enable true; reset(); include "armeabi-v7a", "arm64-v8a"; universalApk false } }`.
- Compress PNGs → WebP.
- Drop unused locales: `resConfigs "en", "hi"`.

**Real problem — APK 78MB → 22MB on Flipkart-style app**:
1. Enable Hermes (+ shrink JS).
2. ABI splits (drop x86, x86_64).
3. Convert PNG → WebP (saved 12MB).
4. Lottie → Rive for complex anim.
5. Strip unused fonts.
6. Use App Bundle (.aab) so Play delivers per-device.

---

### H.4 — iOS platform deep (lifecycle, signing, Universal Links)

**App lifecycle** (SceneDelegate-based):
`willConnectToScene` → `sceneDidBecomeActive` → `sceneWillResignActive` → `sceneDidEnterBackground` → `sceneWillEnterForeground`.

**RN handle background blur for sensitive screens**:
```jsx
useEffect(() => {
  const sub = AppState.addEventListener('change', (s) => {
    setBlurred(s === 'inactive' || s === 'background'); // hide PII in app switcher
  });
  return () => sub.remove();
}, []);
```

**Code signing — Fastlane match**:
```ruby
# Fastfile
lane :beta do
  setup_ci
  match(type: 'appstore', readonly: true)
  build_app(scheme: 'App', export_method: 'app-store')
  upload_to_testflight
end
```

**Universal Links setup**:
1. Host AASA at `https://yourdomain/.well-known/apple-app-site-association` (no extension, `Content-Type: application/json`):
```json
{
  "applinks": {
    "apps": [],
    "details": [{ "appID": "TEAMID.com.app", "paths": ["/order/*", "/profile/*"] }]
  }
}
```
2. Xcode → Signing & Capabilities → Associated Domains → `applinks:yourdomain`.
3. Validate with Apple's [validator](https://search.developer.apple.com/appsearch-validation-tool/).

**Common signing failures + fixes**:
| Error | Cause | Fix |
|---|---|---|
| "No matching provisioning profile" | Cert/profile mismatch | `match nuke development && match development` |
| "Failed to register bundle id" | Capability changed | Update App ID in dev portal, regenerate |
| Build OK locally, fails CI | Keychain locked | `setup_ci` lane unlocks temp keychain |
| Push not working in TestFlight | APNs cert/key not set | Upload `.p8` AuthKey to App Store Connect |

---

### H.5 — Architecture Decision Records (ADRs) — 3 worked examples

**ADR template**:
```markdown
# ADR-NNN: <decision title>
Date: YYYY-MM-DD | Status: Accepted | Owner: <name>

## Context
<problem, constraints>

## Decision
<chosen approach>

## Alternatives considered
- A: <pros/cons>
- B: <pros/cons>

## Consequences
- Positive: ...
- Negative: ...
- Mitigations: ...
```

#### ADR-001: Use FlashList over FlatList for product feed
**Context**: Catalog of 5k+ items; FlatList drops to 28 FPS on Pixel 6a.
**Decision**: Migrate to `@shopify/flash-list`.
**Alternatives**: (a) Optimize FlatList (`getItemLayout`, memo, `removeClippedSubviews`) — got us to 42 FPS, not enough. (b) Native RecyclerView bridge — too much maintenance.
**Consequences**: +memory savings, +stable 58 FPS; −requires `estimatedItemSize` tuning per row variant; −one third-party dep added.

#### ADR-002: Keychain + biometric gate for refresh tokens
**Context**: Fintech compliance, MASVS L2.
**Decision**: Store access token in memory (lifetime ≤15min); refresh token in Keychain with `BIOMETRY_CURRENT_SET`.
**Alternatives**: Encrypted MMKV (rejected: weaker than secure enclave). Plain MMKV (rejected: fails audit).
**Consequences**: +regulator-friendly; −user must re-auth biometrics on app cold start; mitigated with grace period (5 min in foreground).

#### ADR-003: React Query over Redux for server state
**Context**: 60% of Redux store was server cache copies.
**Decision**: React Query for server state; keep Redux for auth + feature flags.
**Alternatives**: SWR (similar; ecosystem smaller); RTK Query (good but team uses Redux only for global UI now).
**Consequences**: +-220KB bundle; +stale/refetch built in; −two state libs to teach new hires.

---

### H.6 — Mock Interview format (weak / good / lead-level answers)

**Q: "Walk me through how you'd debug a 4-second cold start on Android Go."**

**Weak answer** (junior signal):
> "I'd check the code and remove unused stuff. Maybe enable Hermes."

**Good answer** (mid signal):
> "I'd profile cold start using Android Studio CPU Profiler and the Hermes profiler. I'd look at what runs before first paint — usually eager imports, sync remote config, font loading. Then I'd lazy-load heavy modules and defer SDK init."

**Lead-level answer** (target):
> "Three steps: measure, hypothesize, gate.
> **Measure**: instrument app start with `react-native-performance` markers — TTI, JS bundle parse, first useful paint. Capture P50/P95 from a beta cohort, not just my Pixel.
> **Hypothesize from data**: typical cold-start budget on Android Go is 2.5s. If we're at 4s, the top three suspects are eager TurboModule init, sync remote config / feature flags, and large bundle parse. Hermes profiler tells me which.
> **Gate**: I don't ship optimizations without a CI gate that fails the PR if cold-start P95 regresses >10%. Last time I did this we got 4.1s → 1.6s P50 with measurable D1 retention lift of +6.2%, and the budget kept holding 18 months later because of the gate, not the fix."

**Follow-up traps** the interviewer will throw:
- "What if the regression came from a dependency, not your code?" → Answer: bundle-size diff per PR, dependency review CODEOWNERS.
- "How would you convince PM to delay a feature for perf work?" → Show retention/D1 graph correlated with cold start.

Use this 3-tier structure to rehearse for: lists perf, memory leaks, payment design, RN→Capacitor migration, OTA rollback, native module decision.

---

### H.7 — Sample app skeletons (just enough to ship a demo repo)

> Build at least 3 of these. Push to GitHub. Link from resume.

#### App 1 — Auth demo (PKCE + Keychain + biometric)
Files:
- `auth/oauth.ts` — PKCE generator (`expo-auth-session`).
- `auth/storage.ts` — Keychain wrapper.
- `auth/refresh.ts` — single-flight (see G.17).
- `screens/Login.tsx` + `screens/Home.tsx` + auth gate from G.16.
Demo: login → store tokens → 401 → silent refresh → biometric gate after 5min idle.

#### App 2 — Realtime chat demo
- WS reconnect (G.17), heartbeat, optimistic send + rollback, local SQLite for messages, push notification routing (H.1), typing indicator throttled at 200ms.

#### App 3 — Offline-first fintech (portfolio)
- WatermelonDB tables: `holdings`, `orders`, `outbox`.
- Sync engine: pull on foreground + WS for live prices.
- Order placement = optimistic + outbox (G.15).
- Biometric gate before order submit (H.4).
- Sentry + perf marks for `placeOrder`.

#### App 4 — Offline todo
- MMKV-backed list + outbox + reconnect-flush. Smallest demo, easiest to finish first.

#### App 5 — Performance playground
- 5000-row FlatList vs FlashList toggle. Show on-screen FPS counter (`react-native-performance`). Profile screen with Hermes recordings checked in.

---

### H.8 — Recruiter round scripts (the first 15 min that often filter you out)

**"Tell me about yourself" (60 sec)**:
> "I'm a senior mobile engineer with 9+ years shipping React Native and native apps, currently leading mobile at LetsVenture — a fintech where I own the LVX and LVXQ apps across React Native, Capacitor, and native pieces. I've owned auth with Auth0 + Cognito, payment integrations with Razorpay and Cashfree, deep linking with Branch, and the EAS / Play / App Store release pipeline. The work I'm proudest of recently is **<one number — e.g., cutting cold start 4s → 1.6s and lifting D1 retention 6%>**. I'm now looking for a senior or lead role at a product company — ideally fintech — where I can own mobile platform decisions end-to-end."

**"Why are you looking for a change?"**:
> "I've taken LVX and LVXQ from feature-light to a production fintech platform, and I'm at the point where the next leap for me is leading mobile at a larger product org — owning architecture decisions across multiple apps and engineers. LetsVenture is a great team; this move is about scope, not dissatisfaction."

**"What's your current CTC?" (deflect)**:
> "I'd rather we align on the band the role is open to first — I want to make sure we're in the same range before we get into specifics. My target is the **role-level band** I've researched on levels.fyi / AmbitionBox for this seniority and scope. Happy to share details once we have a mutual fit."

**"What's your notice period?"**:
> "Officially 60 days, but I've had similar moves negotiated down to 30–45 days with a clean handover plan. I can commit a date once an offer is concrete."

**"Why should we hire you?"**:
> "Three reasons: (1) I've shipped fintech mobile end-to-end including auth, payments, releases — not just one slice; (2) I optimize for production reliability, with measurable wins like **<crash-free 99.78%, cold start 1.6s>**; (3) I work as a tech lead — I write RFCs, mentor, and run incident reviews — so I add value beyond IC."

---

### H.9 — Suspense + Error Boundaries (with code)

**Suspense for code-split screens**:
```jsx
const Profile = React.lazy(() => import('./screens/Profile'));
function App() {
  return (
    <Suspense fallback={<Splash/>}>
      <Profile/>
    </Suspense>
  );
}
```

**Error Boundary (class component — only way today)**:
```tsx
class ErrorBoundary extends React.Component<{ fallback: React.ReactNode; children: React.ReactNode }, { err: Error | null }> {
  state = { err: null as Error | null };
  static getDerivedStateFromError(err: Error) { return { err }; }
  componentDidCatch(err: Error, info: React.ErrorInfo) {
    Sentry.captureException(err, { extra: { componentStack: info.componentStack } });
  }
  render() {
    if (this.state.err) return this.props.fallback;
    return this.props.children;
  }
}
// usage
<ErrorBoundary fallback={<ErrorScreen onRetry={() => RNRestart.restart()}/>}>
  <App/>
</ErrorBoundary>
```

**Real problem**: A bad WebSocket payload crashed the chat screen and took the whole app down. Fix: wrap each screen in an `ErrorBoundary`, so only that screen shows the fallback. Bonus: log + auto-recover on retry.

---

### H.10 — Functional patterns: pure functions, currying, composition

**Pure function** — same input → same output, no side effects. Easy to test, memoize, parallelize.

**Currying**:
```ts
const curry = <A, B, C>(f: (a: A, b: B) => C) => (a: A) => (b: B) => f(a, b);
const add = curry((a: number, b: number) => a + b);
add(2)(3); // 5
const add10 = add(10);
[1,2,3].map(add10); // [11,12,13]
```

**Composition**:
```ts
const pipe = <T,>(...fns: Array<(x: T) => T>) => (x: T) => fns.reduce((v, f) => f(v), x);
const slug = pipe<string>(
  (s) => s.toLowerCase(),
  (s) => s.trim(),
  (s) => s.replace(/\s+/g, '-')
);
slug(' Hello World '); // "hello-world"
```

**Real-world usage**: data normalization pipelines (API → UI), reducer composition in Redux, validation chains.

---

### H.11 — Polyfills (interview classic)

**Implement `Array.prototype.map`**:
```ts
Array.prototype.myMap = function<T, U>(this: T[], cb: (v: T, i: number, a: T[]) => U): U[] {
  const out: U[] = [];
  for (let i = 0; i < this.length; i++) {
    if (i in this) out[i] = cb(this[i], i, this);
  }
  return out;
};
```

**`reduce`**:
```ts
Array.prototype.myReduce = function<T, U>(this: T[], cb: (acc: U, v: T, i: number, a: T[]) => U, init?: U): U {
  let acc = init as U; let start = 0;
  if (init === undefined) { acc = this[0] as unknown as U; start = 1; }
  for (let i = start; i < this.length; i++) acc = cb(acc, this[i], i, this);
  return acc;
};
```

**`bind`**:
```ts
Function.prototype.myBind = function (ctx: any, ...preset: any[]) {
  const fn = this;
  return function (this: any, ...later: any[]) {
    return fn.apply(ctx, [...preset, ...later]);
  };
};
```

---

### H.12 — Coverage checklist (so nothing's missed)

| Handbook section | Where covered |
|---|---|
| §1 JS Fundamentals | G.1–G.4, H.10, H.11 |
| §2 Advanced JS | G.2, G.4, H.10, H.11 |
| §3 TypeScript | G.5 |
| §4 React Deep Dive | G.6–G.8, H.9 |
| §5 RN Fundamentals | G.9, G.10 |
| §6 New Architecture | G.9, G.12 |
| §7 Performance | G.10, G.11, G.13, S1, S8 |
| §8 Native (Android) | H.3, S9 |
| §8 Native (iOS) | H.4, S10 |
| §9 Native Modules | G.12 |
| §10 State Management | G.14 |
| §11 Navigation + Deep Linking | G.16, S6 |
| §12 Networking + Realtime | G.17, S11, S12 |
| §13 Auth + Security | G.18 |
| §14 Offline-first | G.15 |
| §15 Push Notifications | H.1, S4 |
| §16 a11y + i18n | H.2 |
| §17 Testing | G.19 |
| §18 CI/CD | G.20, H.4 |
| §19 Debugging + Observability | G.13, G.21 |
| §20 System Design | G.22, ADRs in H.5 |
| §21 DSA | G.23 |
| §22 Leadership + Behavioral | Appendix E (10 STAR) |
| §23 Recruiter + Comp | Appendix C, D, H.8 |
| Production scenarios library | G.24 (12 walkthroughs) + S-prefix above |
| Mock interview format | H.6 |
| ADRs | H.5 |
| Sample apps | H.7 |
| Suspense + Error Boundaries | H.9 |
| Functional / Polyfills | H.10, H.11 |

If you can:
- Recite the **short and deep** version of every Q in Appendix G.
- Write the code in G.4, G.7, G.11, G.12, G.15, G.17, G.23 from memory.
- Tell every story in Appendix E in 2 minutes with numbers.
- Walk through the 3 system designs in G.22.
- Handle the recruiter scripts in H.8 cold.
- Build at least 3 sample apps from H.7 and link them on your resume.

…then you are ready for Senior / Staff / Lead RN loops at top product companies. Go land them.

---

