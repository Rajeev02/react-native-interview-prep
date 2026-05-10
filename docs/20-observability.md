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

