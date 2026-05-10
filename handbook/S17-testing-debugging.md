# S17 — Testing & Debugging

> Jest · React Native Testing Library · Maestro · Detox · Reassure · Storybook · React Native DevTools · Instruments / Android Studio Profiler

In 2026, **Maestro is the default E2E** for new RN projects (yaml flows, fast, stable), Detox holds the gray-box ground for complex apps, **React Native DevTools** replaced Flipper, and **Reassure** is the standard for catching render-cost regressions in CI. This section covers the five rounds you'll see most.

---

### Q1. Test pyramid for RN — what to unit / component / E2E

---

## Difficulty
- Mid

## Interview Frequency
- Very Common

## Prerequisites
- Jest basics, RTL philosophy

## TL;DR
The pyramid: **most unit + component tests**, **few E2E**. Unit = pure logic (utils, reducers, selectors). Component = render + interaction via React Native Testing Library. E2E = critical user journeys via Maestro. Snapshot tests sparingly (only stable, opaque output). Contract tests for API. Reassure for render perf. Aim ~70% unit, ~25% component, ~5% E2E (by count, not coverage).

---

## 30-Second Interview Answer

> "Pyramid: thousands of unit tests for pure logic — utils, reducers, selectors, hooks; hundreds of component tests via React Native Testing Library asserting on user-visible behavior, not implementation; a few dozen E2E flows for critical journeys (login, checkout, key tabs) via Maestro. Snapshot tests only for stable serializers, never UI components. Contract tests pin API shapes. Reassure runs in CI to catch render-cost regressions. Coverage is a guide, not a goal — focus on confidence per critical path."

---

## 2-Minute Practical Answer

**Layer breakdown**:

| Layer | Tool | Target | Speed |
|---|---|---|---|
| Unit | Jest | pure functions, hooks | ms |
| Component | RNTL | interaction, accessibility | tens of ms |
| Integration | RNTL + MSW | screens with mocked network | hundreds of ms |
| Contract | MSW / Pact | API schema | ms |
| E2E | Maestro | full app on simulator | seconds |
| Visual | Storybook + Chromatic / Loki | UI regressions | seconds |
| Perf | Reassure | render cost CI | seconds |

**Unit example**:
```ts
import { formatCurrency } from '@/utils/money';
test('formats USD', () => {
  expect(formatCurrency(1234.5, 'USD')).toBe('$1,234.50');
});
```

**Component example (RNTL)**:
```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';
import { LoginScreen } from './LoginScreen';

test('shows error on bad password', async () => {
  render(<LoginScreen />);
  fireEvent.changeText(screen.getByLabelText('Email'), 'a@b.com');
  fireEvent.changeText(screen.getByLabelText('Password'), 'short');
  fireEvent.press(screen.getByRole('button', { name: 'Sign in' }));
  expect(await screen.findByText(/at least 8 characters/i)).toBeOnTheScreen();
});
```

**E2E example (Maestro)**:
```yaml
appId: com.acme.app
---
- launchApp
- tapOn: "Sign in"
- inputText: "user@example.com"
- tapOn: "Password"
- inputText: "correct horse"
- tapOn: "Continue"
- assertVisible: "Welcome back"
```

**Coverage discipline**:
- Don't chase 100% — chase confidence on critical journeys.
- Any `if`-branch in money / auth / sync = mandatory test.
- Snapshot only for stable, opaque output (e.g., reducer state shapes), never JSX.

---

## 5-Minute Architecture Answer

Why this shape:
- Unit = fast, focused, regression-safe; refactoring shouldn't break.
- Component = behavior contract from user POV; resilient to internals.
- E2E = "does it actually work end to end" — slow, flaky, expensive; keep small.

What to **not** test:
- Library internals (trust them).
- Generated code (codegen, types).
- Trivial getters / setters.
- Implementation details (what state hook returns; test what user sees).

What to **definitely** test:
- Money math.
- Auth flows.
- Permissions / role gates.
- Offline queue behavior.
- Deep linking.
- Critical onboarding.
- Payment.

CI strategy:
- Unit + component: every PR, < 2 min total.
- Reassure: every PR, posts perf delta as comment.
- E2E (Maestro): on main + nightly; PR for critical-path subset.
- Storybook visual: nightly + on Storybook changes.

Test data:
- Factory functions over fixtures (`makeUser({ name: 'X' })`).
- Faker for randomized data.
- Deterministic seed in CI.

Mocks:
- MSW (Mock Service Worker) for HTTP — works in unit + component + E2E (against local Maestro).
- Native modules: jest setup files mock native bridges (`jest.mock('react-native-mmkv', ...)`).
- Avoid mocking your own code unless behind a port (DI).

The 2026 specific:
- **React 19 testing**: `act()` improvements; concurrent renderer compatibility.
- **React Compiler**: stable test suite; tests pass identically pre/post compilation.
- **Maestro Cloud**: parallel device runs.
- **Detox v20+**: Bridgeless support.
- **Storybook RN v8**: Compiler-aware.

Anti-patterns:
- Snapshot tests on JSX (they break on every refactor).
- Testing library internals (`useState` calls).
- Asserting on CSS / pixel values.
- E2E for every screen (slow, flaky, expensive).

---

## The "Why"

Tests are insurance against regressions. Bad pyramid = slow CI + flaky E2E + low confidence. Companies care because release velocity correlates with test quality.

---

## Mental Model

Pyramid: many cheap tests at base (unit), few expensive at top (E2E). Trust user-visible behavior over implementation.

---

## Internal Working (2026 Context)

- Jest = node-based, parallel workers.
- RNTL = renders to JSDOM-like RN host (`react-test-renderer` or new test host).
- Maestro = orchestrates simulator/device via UIAutomation/UIAutomator.

---

## Modern Implementation (Code)

**Hook test (with renderHook)**:
```ts
import { renderHook, act } from '@testing-library/react-native';
import { useCounter } from './useCounter';

test('increments', () => {
  const { result } = renderHook(() => useCounter());
  act(() => result.current.inc());
  expect(result.current.value).toBe(1);
});
```

**MSW network mock**:
```ts
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

const server = setupServer(
  http.get('/api/me', () => HttpResponse.json({ id: '1', name: 'Ada' }))
);
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**Reassure perf test**:
```ts
import { measureRenders } from 'reassure';
import { Feed } from './Feed';

test('Feed renders', async () => {
  await measureRenders(<Feed items={items100} />, { runs: 20 });
});
```

---

## Comparison

| Tool | Layer | Speed |
|---|---|---|
| Jest | unit/component | fastest |
| RNTL | component | fast |
| Maestro | E2E | medium |
| Detox | E2E gray-box | slower |
| Reassure | perf | medium |

---

## Production Usage

- Universal: Jest + RNTL.
- Modern: Maestro (replacing Detox in many shops).
- Scale: Reassure in CI.

---

## Hands-On Exercise

1. Write 10 unit tests for utils.
2. Write 5 component tests using RNTL.
3. Write 3 Maestro flows for critical journeys.
4. Add Reassure to CI.

---

## Common Mistakes

- Snapshotting JSX.
- Testing internals not behavior.
- E2E for everything.
- No MSW; coupling tests to staging API.

---

## Production Red Flags

- Coverage as the only quality metric.
- Skip tests with `xit`/`skip` left in main.
- Flaky E2E muted instead of fixed.

---

## Performance & Metrics (MANDATORY)

- Unit suite: < 2 min in CI.
- Component suite: < 5 min.
- E2E (critical path): < 10 min.

---

## Decision Framework

| Confidence need | Test type |
|---|---|
| Logic correct | unit |
| User flow | component |
| End-to-end | E2E |
| No render regression | Reassure |
| No visual regression | Storybook+Chromatic |

---

## Senior-Level Insight

Quality > coverage. Senior teams have a **test review** ritual: every PR's tests reviewed for value, not just count. Flaky tests treated as bugs (top of backlog).

---

## Memory Hook
**"Many unit, some component, few E2E."**

## Revision Notes
> Pyramid: unit > component > E2E. RNTL for behavior, not internals. Maestro modern E2E. Reassure for perf regressions in CI. MSW for network mocks. Snapshot only for opaque stable output.

---

---

### Q2. Maestro vs Detox — modern E2E choice

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Common

## Prerequisites
- E2E basics, simulator/emulator workflows

## TL;DR
**Maestro** = YAML flows, black-box, fast onboarding, stable, runs on simulators / devices / Maestro Cloud. **Detox** = JS-based, gray-box (knows about app internals via sync mechanism), more powerful but more setup, fragile across upgrades. 2026 default: **start with Maestro**; switch to Detox only when you need gray-box features (waiting on internal app idle states, complex synchronization).

---

## 30-Second Interview Answer

> "Maestro is the new default — YAML flows, black-box, sub-minute onboarding, stable across RN upgrades. Detox is gray-box: it hooks into the app's idle state for synchronization, which makes complex flows reliable but adds setup cost and breaks on RN upgrades. For most apps, Maestro is enough; pick Detox if you need to wait on specific async operations the OS can't observe. Maestro Cloud parallelizes across devices for fast CI; Detox runs locally or on EAS / Bitrise farms."

---

## 2-Minute Practical Answer

**Maestro**:
- YAML-based flows.
- Auto-waits on UI elements.
- Black-box: no app integration.
- Tests work across React Native versions.
- Fast iteration, hot reload of flow.
- Maestro Cloud for parallel device runs.

```yaml
# .maestro/login.yaml
appId: com.acme.app
---
- launchApp:
    clearState: true
- assertVisible: "Welcome"
- tapOn: "Sign in"
- inputText:
    text: ${EMAIL}
- tapOn: "Password"
- inputText: ${PASSWORD}
- tapOn: "Continue"
- assertVisible:
    text: "Home"
    timeout: 10000
```

**Detox**:
- JS API.
- Gray-box: hooks into app's React Native runtime for sync.
- Requires app build with detox helper module.
- More expressive but more brittle.

```ts
describe('login', () => {
  beforeAll(async () => { await device.launchApp(); });
  it('signs in', async () => {
    await element(by.id('email')).typeText('a@b.com');
    await element(by.id('password')).typeText('correct');
    await element(by.id('continue')).tap();
    await expect(element(by.id('home'))).toBeVisible();
  });
});
```

**When Maestro**:
- New project.
- Most apps.
- Need fast CI (Maestro Cloud parallel).
- Black-box is acceptable.

**When Detox**:
- Existing Detox investment.
- Need gray-box sync (specific async waits the OS can't observe).
- Heavy native interop.

**Both — common patterns**:
- Use accessibility labels / testID for selectors.
- Reset state between tests (clear app data / login fresh).
- Use deep links to skip onboarding when not under test.
- Run on real devices for periodic validation; simulators for PR.

---

## 5-Minute Architecture Answer

E2E philosophy:
- E2E catches integration bugs invisible to unit/component.
- Cost: slow + flaky + expensive infra.
- Goal: small set of high-value flows that catch journey regressions.

Maestro internals:
- Drives via UIAutomation (iOS) / UIAutomator (Android) — same as Apple's / Google's UI test frameworks.
- Auto-wait: polls for visibility / interactability before action.
- Black-box: doesn't need app code modification.
- YAML flows + Maestro Studio for recording.

Detox internals:
- Embeds a sync mechanism in the app.
- Knows when JS thread idle, when network requests pending, when animations running.
- Synchronizes test commands to app state → less flake.
- Cost: app changes + breaks on RN architecture changes.

Selector strategy:
- **testID** (RN prop) — explicit, stable.
- **accessibility label** — also useful for a11y testing.
- **text** — fragile across i18n; use sparingly.

CI strategy:
- PR: smoke flows (login + 1–2 happy paths).
- Main: full E2E suite.
- Nightly: device matrix + edge cases.
- Maestro Cloud: parallel across iOS/Android device farm.

Flake reduction:
- No `sleep()` — use auto-wait.
- Reset state explicitly.
- Avoid timing-dependent assertions.
- Use deep links to skip non-tested-path navigation.

The 2026 specific:
- **Maestro Studio** has live record + AI-assisted flow generation.
- **Detox v20+** Bridgeless-compatible.
- **Maestro Cloud** integrated with EAS Build.
- **Visual diffs** in Maestro for UI regressions.
- **Maestro AI** can auto-fix selector drift.

Migration (Detox → Maestro):
1. Audit existing flows.
2. Rewrite top 10 critical flows in Maestro.
3. Run both in parallel for 1–2 weeks.
4. Sunset Detox once parity confirmed.

---

## The "Why"

E2E reliability = release confidence. Flaky E2E = ignored E2E = no value. Companies care because Maestro's stability advantage means E2E suites are actually run.

---

## Mental Model

Maestro: YAML, black-box, simple. Detox: JS, gray-box, powerful. Default Maestro.

---

## Internal Working (2026 Context)

- Maestro: gRPC server + native UI automation.
- Detox: WebSocket between test runner and app sync mechanism.
- Maestro Cloud: device farm + parallel sharding.

---

## Modern Implementation (Code)

**Maestro deep-link flow**:
```yaml
appId: com.acme.app
---
- openLink: "myapp://order/123"
- assertVisible: "Order #123"
- tapOn: "Pay"
- assertVisible: "Payment successful"
```

**Maestro with env vars**:
```bash
maestro test --env EMAIL=test@example.com --env PASSWORD=secret .maestro/
```

**Detox sync override**:
```ts
await device.disableSynchronization();
// do something timing-sensitive
await device.enableSynchronization();
```

---

## Comparison

| | Maestro | Detox |
|---|---|---|
| Style | YAML | JS |
| Box | black | gray |
| Setup | minutes | hours |
| Stability | high | medium |
| Power | medium | high |
| Cloud | Maestro Cloud | EAS / Bitrise |

---

## Production Usage

- New apps: Maestro.
- Existing Detox: many migrating to Maestro.
- Some keep Detox for gray-box-required suites.

---

## Hands-On Exercise

1. Write 5 Maestro flows for an app.
2. Run on iOS + Android.
3. Add to CI.
4. Compare with Detox setup.

---

## Common Mistakes

- Using `sleep()` (defeats auto-wait).
- Selectors by text only (i18n breakage).
- No state reset between tests.
- Running every PR through 50-flow E2E.

---

## Production Red Flags

- Flaky E2E muted with `--fail-fast=false`.
- No baseline run (can't tell what's broken).
- Same flows in unit + E2E (waste).

---

## Performance & Metrics (MANDATORY)

- Maestro PR smoke: < 5 min.
- Full suite: 15–30 min.
- Detox suite: usually 30+ min.

---

## Decision Framework

| Need | Pick |
|---|---|
| New project | Maestro |
| Gray-box sync | Detox |
| Cloud parallel | Maestro Cloud |
| Tightest control | Detox |

---

## Senior-Level Insight

E2E suite is a product. Owner, SLO (flake rate < 2%), runbook for failures. Senior teams measure "time to actionable signal" from a failed E2E run.

---

## Memory Hook
**"Maestro: YAML black-box. Detox: JS gray-box."**

## Revision Notes
> Maestro = new default (YAML, black-box, stable). Detox = gray-box (sync into app, more power). Maestro Cloud parallel runs. Use testID; reset state; deep links to skip onboarding.

---

---

### Q3. Reassure for performance regressions in CI

---

## Difficulty
- Advanced

## Interview Frequency
- Common (perf-conscious teams)

## Prerequisites
- React render cycle, RNTL basics

## TL;DR
**Reassure** measures component render counts + durations in CI, comparing PR vs base. Catches "this PR doubled `Feed` render time" before merge. Comment on PR with delta. Pair with React Compiler (most memoization issues vanish), Hermes profiler (runtime), Reassure (CI gate).

---

## 30-Second Interview Answer

> "Reassure runs in CI as part of the test suite. It renders components N times, measures duration + render count, and compares to base branch. If a PR causes >X% regression, it fails or comments on the PR. Catches the class of regressions that escape unit tests — 'someone added a hook that re-renders the parent on every keystroke'. Pair with Hermes profiler for runtime measurement and React Compiler to eliminate manual-memo bugs."

---

## 2-Minute Practical Answer

**Setup**:
```bash
npm i -D reassure
# in jest.config.js:
testRegex: ['.*\\.(perf|test)\\.tsx?$']
```

**Example**:
```ts
// Feed.perf.tsx
import { measureRenders } from 'reassure';
import { Feed } from './Feed';
import { items } from './fixtures';

test('Feed - 100 items', async () => {
  await measureRenders(<Feed items={items(100)} />, { runs: 20 });
});

test('Feed - empty', async () => {
  await measureRenders(<Feed items={[]} />, { runs: 20 });
});
```

**CI flow**:
1. Run `reassure --baseline` on base branch.
2. Run `reassure` on PR branch.
3. `reassure --output-file` produces JSON.
4. Tool comments on PR with deltas.

```yaml
# .github/workflows/perf.yml
- run: git checkout main && yarn reassure --baseline
- run: git checkout - && yarn reassure
- uses: callstack/reassure-danger-action@v1
```

**Output**:
```
Feed - 100 items: 12.4 ms (count 1)  vs  18.2 ms (count 3) 🚨 +47%
```

**What to test**:
- High-frequency components (lists, headers, navigation roots).
- Components on hot paths (chat input, scrolling).
- Anything you've optimized — guard with Reassure.

**What not**:
- Trivial leaf components.
- Components that change rarely.

---

## 5-Minute Architecture Answer

Why Reassure exists:
- Manual perf testing doesn't scale.
- Hermes profiler great for runtime, but doesn't gate CI.
- Render count regressions silently kill perf over months.

How it works:
- Mocks `performance.now()` for determinism.
- Runs N renders, computes mean + stdev.
- Compares to baseline JSON.
- Calls regression if delta > threshold (default 5–10%).

CI design:
- **PR check**: blocks merge on regression > X%.
- **Comment**: posts per-component delta on PR.
- **Baseline refresh**: on main merge, recompute baseline.

What it doesn't catch:
- Memory regressions.
- Actual device-time regressions (CI is deterministic but not device-realistic).
- Initial bundle size (use `bundlesize` / `@expo/bundle-analyzer`).

Pair with:
- **Hermes profiler** for runtime.
- **React Compiler** to eliminate manual memo bugs.
- **Bundle analyzer** for size.
- **Storybook** visual regression.

The 2026 specific:
- **Reassure 1.0+** with React Compiler awareness.
- **Reassure Cloud** integration for cross-device baselines.
- **AI-suggested fixes** for regressions in PR comments.
- **JSI module call counts** as additional metric.

Best practices:
- Don't fail on absolute time (CI noisy) — use **relative** delta.
- Run on stable CI runners (no shared with other jobs).
- Re-baseline on dependency updates.
- Track both render count and duration.

---

## The "Why"

Perf regressions silently accumulate. Reassure makes them visible at PR time. Companies care because P50/P99 user-experienced perf doesn't degrade between releases.

---

## Mental Model

Reassure = unit test for render cost. Compare PR vs base, fail on regression.

---

## Internal Working (2026 Context)

- Hooks into React profiler API.
- Mocks timers for determinism.
- Aggregates over N runs.

---

## Modern Implementation (Code)

**With React Compiler enabled**:
```ts
test('Item with Compiler', async () => {
  await measureRenders(<Item data={data} />, { runs: 30 });
});
// Compiler-applied auto-memo means render count should be 1 even on parent change
```

**Custom scenario**:
```ts
import { measureRenders } from 'reassure';
import { fireEvent } from '@testing-library/react-native';

test('Feed scroll', async () => {
  await measureRenders(<Feed items={items} />, {
    runs: 10,
    scenario: async (screen) => {
      fireEvent.scroll(screen.getByTestId('list'), {
        nativeEvent: { contentOffset: { y: 1000 } },
      });
    },
  });
});
```

---

## Comparison

| Tool | Layer | When |
|---|---|---|
| Reassure | render-count CI | every PR |
| Hermes profiler | runtime | manual / devices |
| React DevTools profiler | dev | local debug |
| Bundle analyzer | size | every PR |

---

## Production Usage

- Adopted at perf-sensitive shops (chat, social, fintech).
- Especially valuable post-React-Compiler migration.

---

## Hands-On Exercise

1. Add Reassure to a project.
2. Write 5 perf tests on critical components.
3. Wire to GitHub Actions with PR comments.
4. Trigger an intentional regression and observe.

---

## Common Mistakes

- Asserting on absolute time (flaky).
- Too few runs (noise).
- Including network in scenarios (non-deterministic).
- Not re-baselining on lib updates.

---

## Production Red Flags

- Reassure failures muted.
- No baseline refresh policy.
- Tests only on trivial components.

---

## Performance & Metrics (MANDATORY)

- Threshold: 10% delta typical.
- Runs: 20–30 for stable mean.

---

## Decision Framework

| Need | Tool |
|---|---|
| CI regression gate | Reassure |
| Runtime profile | Hermes profiler |
| Visual regression | Storybook+Chromatic |
| Bundle size | bundle-analyzer |

---

## Senior-Level Insight

Treat render count as a public contract for hot components. Senior teams write Reassure tests **before** the optimization, then verify the optimization moves the number.

---

## Memory Hook
**"Reassure = render-cost CI gate."**

## Revision Notes
> Reassure measures render count + duration vs baseline; gates PRs. Pair with Hermes profiler (runtime) + React Compiler. Use relative deltas. Re-baseline on dep updates.

---

---

### Q4. React Native DevTools — what replaced Flipper

---

## Difficulty
- Mid

## Interview Frequency
- Common

## Prerequisites
- Basic debugging

## TL;DR
**Flipper is deprecated**. **React Native DevTools** (Chrome DevTools-based, frontend reusing Chrome's protocol) is the official replacement, integrated with Hermes / Static Hermes via the **Inspector Proxy**. You get **Network, Sources (debugger), Console, React DevTools, Memory, Performance** — all in one. For Bridgeless, it's first-class. Plus **Sentry** (crashes), **Reactotron** (still useful for state), and platform tools (Xcode Instruments, Android Studio Profiler) for native.

---

## 30-Second Interview Answer

> "Flipper deprecated in 2024. React Native DevTools is the official replacement — Chrome DevTools UI talking to the Hermes inspector via a proxy. Open it via `j` in `npx expo start` or Metro. You get Network, Sources for breakpoints, Console, React DevTools, Memory snapshots, Performance trace. For native: Xcode Instruments, Android Studio Profiler. Crashes: Sentry / Crashlytics with sourcemaps. Reactotron still useful for state inspection. Layout: React DevTools' component tree."

---

## 2-Minute Practical Answer

**Open RN DevTools**:
```bash
npx expo start
# press `j` to open DevTools
# or `m` then `Open DevTools`
```

**Panels**:
- **Console**: JS logs.
- **Sources**: breakpoints, step debugging via Hermes inspector.
- **Network**: fetch/XHR — works for any RN >= 0.74.
- **React DevTools**: integrated component tree + profiler.
- **Memory**: heap snapshots, allocation profiler.
- **Performance**: JS execution + profile.

**Native debugging**:
- **iOS**: Xcode Instruments (Time Profiler, Allocations, Leaks, Animation Hitches).
- **Android**: Android Studio Profiler (CPU, Memory, Energy).

**Crashes**:
- Sentry / Crashlytics with sourcemaps uploaded at build time.
- `expo-updates` symbolication via runtime version.

**Network capture (for HTTPS)**:
- Proxyman / Charles / mitmproxy — install root cert via simulator/device.
- For pinned apps, need to disable pinning for debug builds.

**State inspection**:
- React DevTools (component state).
- Reactotron (Redux / MobX / TanStack Query timeline) — still actively maintained.
- Zustand devtools middleware.
- TanStack Query DevTools.

**Layout**:
- React DevTools' component tree + style inspector.
- Element inspector (`Toggle Inspector` in dev menu).

---

## 5-Minute Architecture Answer

Why Flipper went away:
- Java-based desktop app, hard to maintain.
- Plugin system fragmented (custom plugins broke per RN version).
- Bridgeless RN didn't fit Flipper's bridge-centric model.
- Chrome DevTools is far more polished + standard.

RN DevTools architecture:
- Hermes implements Chrome DevTools Protocol (CDP).
- Metro proxies CDP between Chrome and Hermes runtime.
- Single tab, multiple panels, same UX as web debugging.
- Works for both Old + New Architecture.

What's lost (vs Flipper):
- Custom plugins ecosystem (smaller now).
- Some database inspectors (use third-party tools instead).

What's gained:
- React DevTools integrated.
- Standard debugger (no more "remote debugger" eval bug class).
- Better perf profiling.
- Memory snapshots that actually work.

The 2026 specific:
- **Static Hermes** debugging support.
- **React Compiler** profiling shows compiler-applied memos.
- **Network** captures fetch with full body inspection.
- **Mobile DevTools shortcut** in Expo CLI (`j`).

Workflow patterns:
- **Bug repro**: enable Sources breakpoint, reproduce, inspect call stack.
- **Perf**: Performance tab → record → analyze long tasks.
- **Render churn**: React DevTools profiler → flame chart.
- **Memory leak**: take heap snapshot at baseline + after suspect action → diff.
- **Network**: filter by URL, inspect headers + body.

Production debugging:
- Cannot attach RN DevTools to prod builds.
- Use Sentry breadcrumbs + crash reports.
- Use feature flags to enable verbose logging on demand.
- Use OTA to ship debug-instrumented builds to specific cohorts.

---

## The "Why"

Debugging is 80% of senior engineering. RN DevTools makes debugging ergonomic again — Flipper's fragmentation was a real productivity drag. Companies care because debug velocity = bug-fix velocity.

---

## Mental Model

RN DevTools = Chrome DevTools for RN. Same panels, same workflow.

---

## Internal Working (2026 Context)

- Hermes exposes CDP endpoint.
- Metro/Expo CLI runs Inspector Proxy.
- Chrome connects via WebSocket.

---

## Modern Implementation (Code)

**Add `debugger` statement**:
```ts
function suspect(input) {
  debugger; // breaks in Sources
  return process(input);
}
```

**Sentry breadcrumbs**:
```ts
import * as Sentry from '@sentry/react-native';
Sentry.addBreadcrumb({ category: 'auth', message: 'login.attempt' });
Sentry.captureException(err, { tags: { screen: 'login' } });
```

**Reactotron setup**:
```ts
import Reactotron from 'reactotron-react-native';
if (__DEV__) Reactotron.configure().useReactNative().connect();
```

---

## Comparison

| Tool | Use |
|---|---|
| RN DevTools | dev debug |
| Sentry | prod crash + perf |
| Reactotron | state timeline |
| Xcode Instruments | iOS native |
| Android Studio Profiler | Android native |
| Proxyman | network |

---

## Production Usage

- Universal: RN DevTools + Sentry.
- Many shops: Reactotron for state.
- Native-heavy: Instruments + AS Profiler frequently.

---

## Hands-On Exercise

1. Set a breakpoint and step through.
2. Take a heap snapshot.
3. Profile a slow screen.
4. Inspect a network request.

---

## Common Mistakes

- Using `console.log` instead of breakpoints.
- Not uploading sourcemaps (crashes unreadable).
- Pinned app + Proxyman → cert error misread as bug.
- Not filtering by package in Sentry (noise).

---

## Production Red Flags

- No sourcemap upload.
- No Sentry / Crashlytics.
- Logs as primary debug.

---

## Performance & Metrics (MANDATORY)

- Crash-free sessions: > 99.5%.
- ANR rate (Android): < 0.5%.

---

## Decision Framework

| Issue | Tool |
|---|---|
| Logic bug | RN DevTools Sources |
| Render churn | React DevTools profiler |
| Memory | Heap snapshots + Instruments |
| Native crash | Sentry + Xcode/AS |
| Network | RN DevTools Network / Proxyman |

---

## Senior-Level Insight

The mature take: **debug observability lives end-to-end**. Senior teams correlate Sentry + analytics + logs by `trace_id` so a single user complaint resolves to one trace.

---

## Memory Hook
**"DevTools = Chrome panels for RN."**

## Revision Notes
> Flipper deprecated. RN DevTools = Chrome DevTools UI + Hermes CDP. Network, Sources, React DevTools, Memory, Performance. Sentry for prod. Reactotron for state. Xcode Instruments + AS Profiler for native.

---

---

### Q5. Memory leak debugging on iOS + Android

---

## Difficulty
- Advanced

## Interview Frequency
- Common (senior + native rounds)

## Prerequisites
- ARC / GC fundamentals

## TL;DR
**JS leaks**: closures retaining listeners, intervals not cleared, large objects pinned in module scope, event emitters not unsubscribed. **Native leaks**: iOS retain cycles (block captures self), Android Activity leaks (long-running task holding Context). Tools: **RN DevTools Memory snapshots** for JS, **Xcode Instruments → Leaks/Allocations** for iOS, **Android Studio Profiler → Memory** for Android. Workflow: baseline → action → snapshot → diff → identify retained graph → fix.

---

## 30-Second Interview Answer

> "JS leaks: subscriptions not unsubscribed, intervals not cleared, refs to large objects in module scope, retained closures. Native leaks: iOS retain cycles where blocks capture `self` strongly, Android Activity references held by long-running tasks. Diagnostic flow: take baseline heap snapshot, perform suspect action, snapshot again, diff. On iOS, Instruments → Leaks/Allocations shows retain cycles. On Android, AS Profiler → Memory shows allocations + leaked Activities via LeakCanary. Fix: weak refs, remove subscriptions in cleanup, close native resources."

---

## 2-Minute Practical Answer

**JS leak patterns**:

1. Forgotten subscription:
```tsx
useEffect(() => {
  const sub = emitter.addListener('x', handler);
  return () => sub.remove(); // ← required
}, []);
```

2. Forgotten interval / timeout:
```tsx
useEffect(() => {
  const t = setInterval(tick, 1000);
  return () => clearInterval(t);
}, []);
```

3. Module-scope large objects:
```ts
// BAD: lives forever
const cache = new Map<string, HugeObject>();
// BETTER: bound + LRU
const cache = new LRU<string, HugeObject>({ max: 100 });
```

4. Animated listeners not stopped:
```tsx
useEffect(() => {
  const id = animatedValue.addListener(handler);
  return () => animatedValue.removeListener(id);
}, []);
```

**iOS leak patterns** (Swift):

```swift
// BAD: retain cycle
self.callback = {
  self.update() // strong capture
}

// GOOD
self.callback = { [weak self] in
  self?.update()
}
```

Closed delegates, NSTimer not invalidated, KVO not removed.

**Android leak patterns** (Kotlin):

```kt
// BAD: holds Activity context
class MyManager(private val context: Context) {
  companion object { private var instance: MyManager? = null }
  // singleton + Activity context = leak
}

// GOOD: applicationContext or weak ref
class MyManager(context: Context) {
  private val appContext = context.applicationContext
}
```

Long-running coroutines not cancelled with Activity scope; static handlers holding Activity.

**Tooling workflow (iOS)**:
1. Build for profiling: `Product → Profile`.
2. Choose **Leaks** (or **Allocations**).
3. Drive app through suspect flow repeatedly.
4. Look at growing retained sizes / leak markers.
5. Inspect retain tree → identify cycle.

**Tooling workflow (Android)**:
1. AS → Profile App.
2. Memory tab → take snapshot baseline.
3. Drive app, take another snapshot.
4. Diff.
5. **LeakCanary** — auto-detects Activity / Fragment leaks; integrate in dev builds.

**Tooling workflow (JS)**:
1. RN DevTools → Memory.
2. Take heap snapshot.
3. Drive app.
4. Take snapshot.
5. Compare → look for growing retained types.

---

## 5-Minute Architecture Answer

Memory in RN — three heaps:
- **JS heap** (Hermes) — managed by Hades GC.
- **Native heap (iOS)** — ARC.
- **Native heap (Android)** — JVM GC + native (NDK) heap.

Bridges:
- Old Architecture: bridge can leak across boundaries.
- Bridgeless / JSI: cleaner but still possible if native modules retain JS refs.

JS leak categories:
- **Subscriptions**: emitters, NetInfo, AppState, Linking, Animated.
- **Timers**: `setInterval`, `setTimeout` chained.
- **Closures**: callbacks captured by long-lived state.
- **Module scope**: caches that grow unbounded.
- **Image cache**: misuse of FastImage / Expo Image.

Native leak categories:
- **iOS retain cycles**: blocks capturing `self`, delegates not weak.
- **Android Context leaks**: static refs, long-running tasks.
- **Bitmap leaks**: large bitmaps not recycled (less common in modern Android with bitmap pool).

Bridgeless-specific:
- Native modules holding JS Function refs.
- Solution: detach refs on `invalidate()` / module destruction.

Fabric-specific:
- Component cleanup must release shadow + view refs.
- Custom Fabric components: implement `componentWillUnmount` correctly.

JSI host objects:
- C++ objects held by JS. If JS GC doesn't reclaim → C++ leaks.
- Conversely, JS holding native ref → native can't release.

The 2026 specific:
- **Hades GC** in Hermes — concurrent collector; less GC pause but still leaks possible.
- **Static Hermes** — fewer allocations from typed code.
- **LeakCanary 3** for Android.
- **Xcode 16+ Instruments** — improved leak attribution.

Senior debugging mindset:
- Reproduce reliably first (script the suspect flow).
- Baseline memory → drive flow → re-measure.
- Look for retained Activity (Android), retained NSObject classes (iOS), retained large JS objects.
- Bisect via git for "when did it start".

---

## The "Why"

Leaks → OOM crashes → bad reviews. Senior interview question because root-causing requires deep platform knowledge. Companies care because OOM is a top crash class on low-end devices.

---

## Mental Model

Three heaps, two GCs (Hermes + Android JVM), one ARC (iOS). Leaks = unintended retention across cleanup events.

---

## Internal Working (2026 Context)

- Hermes Hades GC: concurrent mark-and-sweep.
- iOS ARC: compile-time refcount.
- Android JVM: generational GC; native heap separate (manual).

---

## Modern Implementation (Code)

**Listener with cleanup**:
```tsx
useEffect(() => {
  const sub = AppState.addEventListener('change', handle);
  return () => sub.remove();
}, []);
```

**Animated value cleanup**:
```tsx
useEffect(() => {
  const id = scrollY.addListener(() => {});
  return () => scrollY.removeListener(id);
}, []);
```

**iOS weak self**:
```swift
NotificationCenter.default.addObserver(forName: .x, object: nil, queue: .main) { [weak self] note in
  self?.handle(note)
}
```

**Android scoped coroutine**:
```kt
class MyVM : ViewModel() {
  fun load() = viewModelScope.launch { repo.fetch() }
  // auto-cancelled on VM clear
}
```

---

## Comparison

| Layer | Tool |
|---|---|
| JS | RN DevTools Memory |
| iOS | Instruments Leaks/Allocations |
| Android | AS Profiler + LeakCanary |
| Bridge | inspect native module refs |

---

## Production Usage

- Sentry / Crashlytics report OOM crashes.
- LeakCanary in dev builds.
- Quarterly memory review at large shops.

---

## Hands-On Exercise

1. Plant a deliberate leak in a screen.
2. Detect with each tool (RN DevTools, Instruments, AS).
3. Fix and verify.
4. Add a regression test.

---

## Common Mistakes

- No cleanup in `useEffect`.
- Singletons holding Activity.
- Strong block captures.
- Caches without bounds.
- Animated listeners forgotten.

---

## Production Red Flags

- OOM crashes ignored.
- LeakCanary disabled in dev.
- No memory budget per screen.

---

## Performance & Metrics (MANDATORY)

- iOS RSS budget per screen: stable (no growth).
- Android heap budget: < 200MB typical.
- OOM rate: < 0.1% sessions.

---

## Decision Framework

| Symptom | Tool |
|---|---|
| Steady growth | snapshot diff |
| iOS crash | Instruments Leaks |
| Activity not released | LeakCanary |
| Image bloat | image cache audit |

---

## Senior-Level Insight

Senior engineers think about memory the way they think about money: budget per screen, alert on growth, periodic profiling. Treat OOM as a P0 bug class.

---

## Memory Hook
**"Subscribe → cleanup. Capture → weak. Cache → bounded."**

## Revision Notes
> JS leaks: subscriptions, timers, module-scope caches, animated listeners. iOS: retain cycles via blocks. Android: Activity/Context leaks. Tools: RN DevTools Memory, Instruments Leaks, AS Profiler, LeakCanary. Hades GC, ARC, JVM GC.

---

> **End of S17.** Cross-refs: [S6 Hermes & Metro](S06-hermes-metro.md), [S7 Performance](S07-performance.md), [S18 Observability](S18-observability.md), [S20 CI/CD](S20-cicd-release.md). Next per priority: [S18 Observability](S18-observability.md).
