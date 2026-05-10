## 20. Observability: Sentry, Crashlytics, analytics

### Sentry
- **Crashes** + **performance traces** + **release health**.
- Source maps upload per release.
- Breadcrumbs (auto + manual).
- User context (without PII): hashed user id only.
- Sample rates: errors 100%, perf traces 10–25%.

### Crashlytics
- Native crash focus.
- Pair with Sentry for JS — many teams do both.

### Analytics
- **PostHog** (your stack), Mixpanel, Amplitude, Firebase Analytics.
- Event taxonomy: `noun_verb` (`payment_succeeded`).
- Event versioning when payload changes.
- PII-free properties.

### Performance metrics to track
- **Cold start ms** (TTID, TTFD).
- **Crash-free sessions %** (target 99.5%+).
- **JS frame rate / UI frame rate**.
- **API latency P50/P95/P99**.
- **Bundle size**.

### Must-answer questions
1. Source maps + release flow with Sentry.
2. Sample rate strategy.
3. PII-safe event design.
4. KPIs you track on a mobile app.
5. Crashlytics vs Sentry — when each / both.

---



---

## Top 25 Q&A — Observability: Sentry, Crashlytics, analytics

### 1. Three pillars.
**Logs, metrics, traces.** For mobile add **crashes** and **session replay** as first-class.

### 2. Sentry vs Crashlytics?
- **Crashlytics**: free, native + JS crash, basic. Owned by Google.
- **Sentry**: richer (breadcrumbs, performance, release health, replays), paid above quota. Most senior teams use both — Crashlytics for native, Sentry for JS + perf.

### 3. Setup Sentry RN.
```ts
Sentry.init({
  dsn,
  enableNative: true,
  tracesSampleRate: 0.2,
  profilesSampleRate: 0.1,
  release: `${pkg.version}+${buildNumber}`,
  environment: __DEV__ ? 'dev' : 'prod',
});
```

### 4. Source map symbolication.
Upload via `@sentry/cli sourcemaps upload --release ...` post-bundle. Without it, JS stack traces are minified noise.

### 5. Native crash symbolication.
Upload dSYM (iOS) and ProGuard mapping (Android) to crash reporter as part of CI.

### 6. Breadcrumbs — what to capture.
Navigation transitions, network requests (URL + status, never body), key user actions, lifecycle events. Avoid PII.

### 7. Release health metrics.
Crash-free users %, crash-free sessions %, ANR rate, foreground time. Define SLO per release (e.g. 99.5% crash-free users).

### 8. ANR (Application Not Responding) detection.
Crashlytics + Play Console Vitals report ANRs. Sentry now supports ANR tracking (Android 11+).

### 9. Performance traces — what to instrument?
App start, navigation transitions (`react-navigation` integration), HTTP requests, key flows (login, checkout). Use spans for sub-steps.

### 10. Custom tags / context.
```ts
Sentry.setTag('feature_flag.new_payments', 'true');
Sentry.setUser({ id: hashedId, segment: 'premium' });
Sentry.setContext('checkout', { sku: 'pro', amount: 999 });
```

### 11. Scrub PII before send.
`beforeSend(event, hint)` — strip `request.cookies`, mask emails, drop sensitive tags.

### 12. Sampling strategy.
100% errors. 10–20% transactions. Higher sampling on critical screens via `tracesSampler`. Always sample crashes (Crashlytics handles).

### 13. Analytics — purpose vs crash reporting.
Crash reporting = engineering health. Analytics (Amplitude, Mixpanel, GA4) = product behavior. Separate funnels; different retention rules.

### 14. Event taxonomy.
Standard naming: `area.action_object` (`checkout.tap_pay`). Versioned schema; PR review for new events. Publish to data team.

### 15. Funnel example.
`onboarding.viewed` → `onboarding.signup_submit` → `onboarding.kyc_started` → `onboarding.kyc_completed` → `home.first_view`.

### 16. Identify user pre/post login.
Anonymous distinct ID at install; on login `identify(userId)` aliases; persist between launches.

### 17. Server-side analytics ingestion?
Yes. Server emits source-of-truth events for purchases (avoids client tampering). Client emits UX events.

### 18. RUM (real user monitoring) vs synthetic?
RUM: real user network, device, region. Synthetic: scripted runs in CI for SLA. Mobile mostly RUM via Sentry/Datadog Mobile.

### 19. Logging in production — where to?
Sentry breadcrumbs for context. Server-side `console` only when explicitly opted-in (verbose mode). Avoid spamming.

### 20. Custom error boundary + Sentry.
```tsx
class Boundary extends React.Component {
  componentDidCatch(err: Error, info: any) { Sentry.captureException(err, { contexts: { react: info } }); }
  render() { return this.state.err ? <Fallback/> : this.props.children; }
}
```

### 21. Release deployment notifications.
Sentry releases auto-detect regressions; configure Slack/Email alerts on spike. Set deploy markers via CI.

### 22. Trace HTTP in RN.
`@sentry/react-native` provides `ReactNativeTracing` with `routingInstrumentation` for navigation and fetch/XHR instrumentation auto-installed.

### 23. Watching key SLIs day-to-day.
Daily dashboard: crash-free %, p95 cold start, p95 API latency, Sentry new-issue count, Top 5 errors.

### 24. Privacy compliance.
GDPR / DPDP Act 2023 (India): consent banner where required, IP anonymization in analytics, right-to-erasure pipelines.

### 25. Code: app-start trace + breadcrumb.
```ts
const tx = Sentry.startTransaction({ name: 'app.start', op: 'app.start' });
const span = tx.startChild({ op: 'bootstrap', description: 'initStores' });
await initStores();
span.finish();
Sentry.addBreadcrumb({ category: 'lifecycle', message: 'bootstrapped' });
tx.finish();
```
