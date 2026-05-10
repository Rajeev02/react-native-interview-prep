# S18 — Observability

> OpenTelemetry · RUM · crash · session replay · SLO/SLI · W3C trace context · battery/data budgets

Mobile observability lags backend by a decade. In 2026 the gap is closing: **OpenTelemetry has stable JS SDKs**, **W3C trace context propagates client→server**, **Sentry / Datadog / Bugsnag** all offer mobile RUM, **session replay** is mature (with privacy controls), and **SLOs are first-class** for mobile teams. This section covers the five rounds you'll see most.

---

### Q1. OpenTelemetry on mobile — traces from app to backend

---

## Difficulty
- Advanced

## Interview Frequency
- Common (senior + observability rounds)

## Prerequisites
- Distributed tracing basics, HTTP semantics

## TL;DR
**OpenTelemetry (OTel)** standardizes traces / metrics / logs across languages. On mobile: instrument app via `@opentelemetry/sdk-trace-web` (compatible with RN) or vendor SDKs that emit OTel-compatible spans. Propagate **W3C `traceparent`** header on every request → backend continues the same trace → end-to-end view in Tempo / Jaeger / Datadog APM. Span hierarchy: app launch → screen render → user action → HTTP call → backend handler → DB query.

---

## 30-Second Interview Answer

> "OpenTelemetry on mobile means: instrument key spans (app start, screen, user action, HTTP), inject W3C traceparent on outbound requests, and ship spans to a collector or vendor backend. The backend continues the trace using the same context. You get end-to-end views: 'login slow' shows the app fetch, the API gateway, the auth service, the DB call — one trace ID. Use vendor SDKs (Sentry, Datadog, Embrace) that emit OTel-compatible spans to skip plumbing. Sample aggressively in production (5–10%); always sample errors."

---

## 2-Minute Practical Answer

**Spans to instrument**:
- App start (cold / warm).
- Screen mount / unmount.
- User action (tap → effect).
- Outbound HTTP (`fetch`).
- Native module call.
- Background task execution.

**Setup (sketch)**:
```ts
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { trace, context, propagation } from '@opentelemetry/api';
import { W3CTraceContextPropagator } from '@opentelemetry/core';

const provider = new WebTracerProvider();
provider.addSpanProcessor(new BatchSpanProcessor(new OTLPTraceExporter({
  url: 'https://otel.example.com/v1/traces',
})));
provider.register({ propagator: new W3CTraceContextPropagator() });

export const tracer = trace.getTracer('mobile-app', '1.0.0');
```

**Span around screen + fetch**:
```ts
async function loadFeed() {
  return tracer.startActiveSpan('feed.load', async (span) => {
    try {
      const res = await fetch('/api/feed', { headers: injectTraceparent() });
      span.setAttribute('http.status_code', res.status);
      return await res.json();
    } catch (e) {
      span.recordException(e);
      span.setStatus({ code: SpanStatusCode.ERROR });
      throw e;
    } finally {
      span.end();
    }
  });
}

function injectTraceparent(): Record<string, string> {
  const headers: Record<string, string> = {};
  propagation.inject(context.active(), headers);
  return headers; // { traceparent: '00-<traceId>-<spanId>-01' }
}
```

**Backend continuation**:
```ts
// express middleware
app.use((req, res, next) => {
  const ctx = propagation.extract(context.active(), req.headers);
  context.with(ctx, () => next());
});
```

**Sampling**:
- Head sampling: decide at trace start (cheap; biased).
- Tail sampling: sample at collector after seeing full trace (catches errors).
- Recommend: head sample 10%, always-sample errors via attribute.

**Common attributes**:
- `app.version`, `app.build`, `device.model`, `os.name`, `os.version`.
- `user.id` (anonymized), `session.id`.
- `screen.name`, `route.params`.
- `http.url`, `http.method`, `http.status_code`.

---

## 5-Minute Architecture Answer

OTel architecture:
- **SDK** in app emits spans / metrics / logs.
- **Collector** (separate service) receives, processes, forwards to backend (Tempo, Jaeger, Honeycomb, Datadog, NewRelic, Grafana Cloud).
- **Backend** stores + queries traces.

Mobile-specific challenges:
- **Connectivity**: traces lost when offline → buffer + retry, or accept loss for non-critical.
- **Battery**: emit batches, not per-span.
- **Privacy**: don't emit PII; redact attributes; respect consent.
- **Clock drift**: device clock may be wrong → backend should trust server-side timestamps when possible.
- **Cold start**: must initialize OTel before first instrumented op, or buffer until ready.

Trace hierarchy:
```
app.start (cold)
└── splash.display
    └── auth.restore
        ├── storage.read (mmkv:tokens)
        └── api.refresh_token
            └── http GET /token  ← traceparent here
[backend]
http GET /token
└── auth.verify
    └── db.user.lookup
```

W3C trace context format:
```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
                ^^                              ^^               ^^
                version  trace-id (16B hex)      span-id (8B hex)  flags
```

`tracestate` for vendor-specific extensions.

The 2026 specific:
- **OTel Mobile SIG** stable (was experimental).
- **Sentry / Datadog / Embrace** export OTel-compatible spans.
- **Profile + trace correlation** (Pyroscope-style for mobile).
- **eBPF-style RUM** (via Static Hermes JS profiles attached to traces).
- **Privacy regulations**: GDPR / CPRA require consent for some telemetry → conditional initialization.

Best practices:
- Span only what matters — don't trace every console.log.
- Add semantic conventions (OTel spec has them).
- Correlate with logs via `trace_id` in log lines.
- Graceful degradation if collector unreachable.

---

## The "Why"

Without traces, mobile bugs become "user said it's slow" tickets. With traces, you see exact hop where time was lost. Companies care because MTTR collapses with end-to-end visibility.

---

## Mental Model

Trace = causal graph of operations. Each operation = span. App and backend share trace ID via traceparent header.

---

## Internal Working (2026 Context)

- Spans batched in BatchSpanProcessor, flushed periodically.
- Collector deduplicates / samples / forwards.
- Backend indexes by trace ID + service.

---

## Modern Implementation (Code)

**Auto-instrument fetch**:
```ts
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';

registerInstrumentations({
  instrumentations: [new FetchInstrumentation({
    propagateTraceHeaderCorsUrls: [/.*/],
  })],
});
```

**App start span**:
```ts
const startupSpan = tracer.startSpan('app.start', { startTime: appStartTime });
// ... after first screen rendered:
startupSpan.end();
```

---

## Comparison

| Vendor | OTel-compatible? |
|---|---|
| Sentry | yes |
| Datadog | yes |
| Embrace | yes |
| Honeycomb | native |
| Bugsnag | partial |
| Firebase Performance | proprietary |

---

## Production Usage

- All large mobile teams adopt some form of trace + RUM.
- OTel adoption growing rapidly post-2024.

---

## Hands-On Exercise

1. Wire OTel SDK in RN app.
2. Instrument a screen + fetch.
3. Inject traceparent into outbound.
4. Verify trace in vendor UI end-to-end.

---

## Common Mistakes

- No traceparent injection (broken trace).
- PII in span attributes.
- No sampling (cost explosion).
- Synchronous span flush on UI thread.

---

## Production Red Flags

- Traces but no backend continuation.
- 100% sampling in prod.
- Same trace ID across users (init bug).

---

## Performance & Metrics (MANDATORY)

- Span emission overhead: < 0.1ms.
- Network: batched every ~5–30s.

---

## Decision Framework

| Need | Pick |
|---|---|
| Vendor + trace | Sentry / Datadog / Embrace |
| Self-host | OTel collector + Tempo |
| Smallest blast | sample 5–10% + always errors |

---

## Senior-Level Insight

The mature take: **traces are the source of truth**, logs and metrics are derived. Senior teams instrument the critical journey and let everything else default. SLO dashboards point at traces.

---

## Memory Hook
**"One trace ID, app to DB, via traceparent."**

## Revision Notes
> OTel emits spans; W3C `traceparent` header propagates trace ID to backend → end-to-end trace. Sample 5–10% + always-sample errors. Vendor SDKs (Sentry, Datadog, Embrace) export OTel. Don't emit PII.

---

---

### Q2. SLOs for mobile — crash-free sessions, TTI, ANR

---

## Difficulty
- Advanced

## Interview Frequency
- Common (staff / leadership rounds)

## Prerequisites
- SRE basics

## TL;DR
Mobile SLOs: **crash-free sessions** (>99.5%), **ANR rate** Android (<0.5%), **app start TTI** P75 (<2s cold), **screen TTI** per critical screen, **API success rate** (>99.9%), **OTA update success** (>99%). Define SLI per metric, SLO per platform / cohort, error budget per release. Postmortem when burned.

---

## 30-Second Interview Answer

> "Mobile SLOs differ from backend SLOs because users feel different things. Top SLIs: crash-free sessions (target >99.5% rolling 7-day), ANR rate on Android (<0.5%), cold app start P75 (<2s), critical screen TTI, API success rate, OTA update apply success. SLOs set per platform and cohort (low-end Android often weaker). Each SLO has an error budget; if burned, slow releases. Postmortems on burn events. Track via Sentry / Crashlytics / Firebase Performance / Datadog RUM."

---

## 2-Minute Practical Answer

**Top SLIs**:

| SLI | Target | Source |
|---|---|---|
| Crash-free sessions | > 99.5% (consumer) | Sentry / Crashlytics |
| Crash-free users | > 99.0% | same |
| ANR rate (Android) | < 0.5% | Play Console / Firebase |
| Cold start TTI | P75 < 2s | RUM |
| Warm start TTI | P75 < 1s | RUM |
| Screen TTI | per-screen budget | RUM |
| API P95 latency | < 800ms | RUM + backend |
| API success rate | > 99.9% | RUM |
| OTA apply success | > 99% | EAS Update + analytics |
| Battery: foreground / hour | < X mAh | OS reports |

**Error budget**:
- 99.5% crash-free over 30 days = 0.5% × N sessions allowed.
- If burned: freeze risky releases, prioritize stability, postmortem.

**Cohort breakdown**:
- iOS vs Android.
- App version (latest vs N-1).
- Device tier (low-end Android usually worse).
- Country / network.
- Cold vs warm start.

**Definition discipline**:
- "Crash-free session" = session that didn't crash. (Not "user never crashed".)
- "ANR" = Application Not Responding (UI thread blocked > 5s on Android).
- "TTI" = time to interactive (definition matters; settle on first responsive frame after gesture).

**Reporting cadence**:
- Daily dashboard.
- Weekly review.
- Monthly retro.
- Quarterly SLO renegotiation.

---

## 5-Minute Architecture Answer

Why mobile SLOs differ:
- No "request" model — sessions are long, mixed workloads.
- Many devices, many OS versions, many network conditions.
- User-felt latency matters more than P50.
- Crashes are unpredictable in cause but predictable in rate.

SLO design steps:
1. **Identify journeys** — login, browse, purchase, share.
2. **Map SLIs** to each — TTI, success rate, crash rate.
3. **Set SLO** with stakeholders — what tier of UX you commit to.
4. **Define error budget** — how much you can burn before slowing release.
5. **Instrument** — RUM + crash + perf monitoring.
6. **Dashboards** — per SLO, per cohort.
7. **Alerting** — page when budget burning fast.

App start details:
- **Cold start**: process not in memory.
- **Warm start**: process in memory, activity destroyed.
- **Hot start**: activity exists, just resumed.
- Each has different budget (cold worst).

ANR (Android):
- UI thread blocked > 5s.
- Common causes: blocking I/O, slow JS init, native module on UI thread.
- Mitigations: move work off UI thread, lazy init, async storage.

Crash classes:
- JS errors (caught in error boundary or unhandled).
- Native crashes (NPE, EXC_BAD_ACCESS).
- OOM (separate class).
- ANR (separate; not always counted as crash).

The 2026 specific:
- **Sentry RUM** + **Performance Monitoring** unified.
- **Datadog Mobile RUM** with synthetic monitoring.
- **Firebase Performance** built-in for Android via Play Console.
- **Embrace** specialized in mobile observability.
- **Open SLO standard** (Nobl9 / OpenSLO) integration.

Postmortem on SLO burn:
- What happened?
- What metric burned?
- Root cause?
- Why missed by tests?
- Action items: prevent + detect + recover.

Release gating:
- If error budget < 25% remaining → no risky releases.
- Hot fixes still allowed.
- Feature flags to disable burning features.

---

## The "Why"

SLOs make quality measurable + negotiable. "Better quality" is fuzzy; "99.5% crash-free" is a contract. Companies care because SLOs unblock release velocity (when met) or trigger triage (when burned).

---

## Mental Model

SLI = metric. SLO = target. Error budget = (1 − SLO) × volume. Burn fast → slow down.

---

## Internal Working (2026 Context)

- Sentry / Crashlytics aggregate at session level.
- RUM tools sample.
- Play Console reports ANR / crash from real devices.

---

## Modern Implementation (Code)

**Custom RUM event**:
```ts
import { metrics } from '@opentelemetry/api';
const meter = metrics.getMeter('mobile-app');
const tti = meter.createHistogram('screen.tti', { unit: 'ms' });

function recordScreenTTI(name: string, ms: number) {
  tti.record(ms, { 'screen.name': name });
}
```

**Error budget alert (pseudo)**:
```sql
SELECT
  100.0 * (1 - SUM(crashed) * 1.0 / COUNT(*)) AS crash_free_pct
FROM sessions
WHERE ts > now() - interval '7 days';
-- alert if crash_free_pct < 99.5
```

---

## Comparison

| Tool | Strength |
|---|---|
| Sentry | crashes + RUM + traces |
| Datadog | unified APM |
| Firebase | Play integration, free tier |
| Embrace | mobile-only, deep RUM |
| Bugsnag | crash-focused |

---

## Production Usage

- Universal: crash reporting.
- Mid+: full RUM.
- Senior: SLO + error budget gating.

---

## Hands-On Exercise

1. Define 3 SLIs for an app.
2. Instrument them.
3. Build dashboard.
4. Simulate burn and run postmortem.

---

## Common Mistakes

- SLO without error budget policy.
- Metric not aligned to user journey.
- Same SLO for all cohorts (low-end gets neglected).
- No alerting.

---

## Production Red Flags

- "We track crashes but no targets".
- ANR ignored.
- No cohort breakdown.

---

## Performance & Metrics (MANDATORY)

- Crash-free: > 99.5%.
- ANR: < 0.5%.
- Cold start P75: < 2s.

---

## Decision Framework

| Burn rate | Action |
|---|---|
| < 1× | normal |
| 1–5× | investigate, slow risky |
| > 5× | freeze release, page |

---

## Senior-Level Insight

SLOs are a **cross-functional contract**. Senior teams negotiate them with PM + design + leadership; not unilateral. They drive release decisions.

---

## Memory Hook
**"Crash-free, ANR, TTI — three numbers that matter."**

## Revision Notes
> SLIs: crash-free sessions, ANR, cold start TTI, screen TTI, API success. Error budget gates releases. Per-cohort breakdown. Postmortems on burn. Tools: Sentry / Datadog / Firebase / Embrace.

---

---

### Q3. Session replay — privacy considerations

---

## Difficulty
- Advanced

## Interview Frequency
- Common (privacy / observability rounds)

## Prerequisites
- GDPR / CPRA basics

## TL;DR
Session replay records user interactions for replay during debugging. **Mask all PII by default** (text inputs, sensitive views), **opt-in/opt-out per region**, **redact at SDK level not server**, **TTL retention** (30–90 days max), and document in privacy policy. Mobile replay is sampled (not full video). Useful for: bug repro, UX research, accessibility issues. Risky for: health data, finance, regulated verticals.

---

## 30-Second Interview Answer

> "Session replay captures user interactions — taps, scrolls, screen transitions, network — for later playback. Critical: mask all text inputs and sensitive views by default at SDK level (not in transit). Honor consent per region (EU, California, etc.). Sample (1–10% sessions, 100% on errors). Retain 30–90 days max. Document in privacy policy. Use it for: 'why did this user crash here', not 'watch what users do'. Disable in regulated flows (payments, health)."

---

## 2-Minute Practical Answer

**SDK examples**: Sentry Replay, LogRocket, Datadog RUM, FullStory, Embrace.

**Default privacy**:
```ts
import * as Sentry from '@sentry/react-native';
Sentry.init({
  dsn: '...',
  replaysSessionSampleRate: 0.1,    // 10% of sessions
  replaysOnErrorSampleRate: 1.0,    // 100% on errors
  integrations: [
    Sentry.mobileReplayIntegration({
      maskAllText: true,
      maskAllImages: true,
      maskAllVectors: true,
    }),
  ],
});
```

**Mark sensitive components**:
```tsx
import { Mask } from '@sentry/react-native';
<Mask>
  <Text>{cardLastFour}</Text>
</Mask>
```

**Disable on screens**:
```tsx
useEffect(() => {
  Sentry.replayIntegration?.stop();
  return () => Sentry.replayIntegration?.start();
}, []);
```

**Consent-aware init**:
```ts
const allowed = await consentService.has('analytics');
if (allowed) Sentry.replayIntegration.start();
```

**Where masking lives**:
- SDK-level masking (preferred): pixels never leave device.
- Server-side masking (worse): raw data transits, masked later.

**Retention**:
- Default 30 days.
- Tighter for regulated industries (7 days health data).
- Auto-delete on user deletion request.

---

## 5-Minute Architecture Answer

Replay technology:
- Captures DOM-like tree on web; on mobile captures screen graph snapshots.
- Sampling: keyframes + diffs.
- Compresses (gzip / brotli).
- Uploads in batches when network available.

Privacy framework:
1. **Consent**: prompt user (where required).
2. **Default mask**: text + images + sensitive views.
3. **Allowlist over denylist** (mask by default; explicitly unmask non-sensitive).
4. **Sampling**: 1–10% session + 100% errors.
5. **Retention**: 30–90 days.
6. **Right to delete**: SDK supports user-id-keyed delete.
7. **Audit**: who accessed replays.

Regulatory landscape:
- **GDPR**: legitimate interest or consent.
- **CPRA**: opt-out for sale of data.
- **HIPAA**: replay generally not permitted in PHI flows.
- **PCI-DSS**: card numbers must never appear (mask Number entry).
- **India DPDP**: notice + consent.

Risks:
- Accidental capture of OTP / passwords (mask password fields by default).
- Card numbers in chat (mask all text).
- PHI in clinical apps (disable entirely).
- Photos / videos with PII (mask images).

When NOT to use replay:
- Healthcare diagnostic flows.
- Banking transaction confirmation.
- Children's apps without verified parental consent.
- Government / defense.

The 2026 specific:
- **Sentry Mobile Replay v2** (improved compression).
- **On-device redaction** (ML-based PII detection).
- **Privacy Sandbox** considerations (iCloud Private Relay doesn't block replay but obscures geo).

ROI:
- Bug repro time: hours → minutes.
- Worth it for product teams; risky for regulated.
- Consider lower-PII alternatives: heatmaps, event timelines.

---

## The "Why"

Replay is a superpower for debugging — and a regulatory landmine. Senior orgs invest in privacy-by-default. Companies care because mishandled replay = headline.

---

## Mental Model

Replay = video debugging tool. Mask first, sample low, delete fast.

---

## Internal Working (2026 Context)

- SDK captures view hierarchy frames + events.
- Compresses + batches.
- Uploads to vendor.
- Vendor renders web playback.

---

## Modern Implementation (Code)

**Per-screen disable**:
```tsx
function PaymentScreen() {
  useEffect(() => {
    Sentry.replayIntegration.stop();
    return () => Sentry.replayIntegration.start();
  }, []);
  // ...
}
```

**Custom mask**:
```tsx
<View testID="sensitive-section" pointerEvents="none">
  {/* SDK detects testID prefix and masks */}
</View>
```

---

## Comparison

| Vendor | Mobile replay |
|---|---|
| Sentry | yes |
| Datadog | yes |
| LogRocket | web-strong, mobile growing |
| FullStory | yes |
| Embrace | rich session timeline (not video) |

---

## Production Usage

- Common in consumer apps with consent.
- Rare in regulated.

---

## Hands-On Exercise

1. Enable replay with default masking.
2. Verify password field masked.
3. Disable for payment screen.
4. Test consent-gated init.

---

## Common Mistakes

- Default unmasked.
- Server-side masking (data already exposed).
- No retention limit.
- No consent flow.

---

## Production Red Flags

- Replay shows card numbers.
- Replay enabled for children.
- No DPA with vendor.

---

## Performance & Metrics (MANDATORY)

- Sampling: 1–10% sessions.
- Upload size: kept small via batched compression.

---

## Decision Framework

| Vertical | Use? |
|---|---|
| Consumer commerce | yes, masked |
| Fintech | yes, with extreme masking |
| Health / PHI | usually no |
| Children | only with verified consent |

---

## Senior-Level Insight

The mature take: **replay belongs to debug toolchain, not analytics**. Senior teams gate access (only on-call / specific debug roles can view).

---

## Memory Hook
**"Mask first. Sample low. Delete fast."**

## Revision Notes
> Session replay = recorded UI for debug. Mask PII at SDK. Sample 1–10%, 100% on errors. Retain 30–90 days. Consent-aware. Disable for regulated flows.

---

---

### Q4. Battery and data usage — measure and budget

---

## Difficulty
- Advanced

## Interview Frequency
- Common (perf / device-friendly rounds)

## Prerequisites
- OS power model basics

## TL;DR
Battery / data are top App Store / Play Store complaint vectors. Measure: **iOS Energy Log (Xcode + on-device)**, **Android Battery Historian / Profiler**, plus user-tier analytics (`expo-battery`). Top drains: location, networking, background tasks, frequent renders, video. Budget per feature; alert on regression. Data: track per-call sizes; compress; cache aggressively; respect Data Saver mode.

---

## 30-Second Interview Answer

> "Battery measured via Xcode Energy Log on iOS, Battery Historian / AS Profiler on Android, plus aggregate via Play Console / App Store. Top drains: GPS/location, raw networking, background tasks, frequent renders. Budget per feature; alert on regressions. Data usage: track per-API call payload size; compress (Brotli); honor `lowDataMode`/`Data Saver`; cache to skip duplicate fetches. Both surface in store reports → user-visible reputation."

---

## 2-Minute Practical Answer

**Battery measurement**:
- iOS: Xcode → Debug Navigator → Energy Impact (on-device). Or Instruments → Energy Log.
- Android: AS Profiler → Energy. Battery Historian for system-level.
- Real users: Play Console "Battery usage" report (auto-aggregated). App Store Connect doesn't expose battery directly.
- App-side: `expo-battery` for level + state, `expo-battery-optimization` for opt-out hints.

**Top drains**:
- GPS continuous location (high drain).
- Frequent network polling.
- Background tasks not deferred to charging.
- Video / camera.
- Animations on UI thread.
- Bluetooth scanning.

**Budgets**:
- Per feature: e.g., maps screen budget X% per hour active.
- Compare to baseline release-over-release.
- Alert on > 10% regression in Play Console.

**Data measurement**:
- Track per-request size (response.headers['content-length']).
- Aggregate per-screen / per-feature.
- Set per-session targets.

**Compression**:
- Always gzip / brotli at server.
- Negotiate via `Accept-Encoding`.
- Use protocol-level (HTTP/2 / HTTP/3 header compression).
- For binary: Protobuf / FlatBuffers > JSON.

**Caching**:
- HTTP cache-control respected by RN's fetch.
- TanStack Query for application cache.
- Image cache via `expo-image`.

**Data Saver mode**:
- iOS: `URLSession.allowsConstrainedNetworkAccess` / `lowDataMode`.
- Android: `ConnectivityManager.isActiveNetworkMetered` + `getRestrictBackgroundStatus`.
- React Native: `NetInfo.fetch()` returns `details.isConnectionExpensive`.

```ts
import NetInfo from '@react-native-community/netinfo';
const state = await NetInfo.fetch();
if (state.details?.isConnectionExpensive) {
  // skip image prefetch, defer non-critical sync
}
```

---

## 5-Minute Architecture Answer

Why these matter:
- Battery complaints → uninstalls.
- Data complaints → uninstalls in metered markets (India, SEA, parts of LatAm).
- Both reported in store consoles → reviewable trends.

iOS battery model:
- Energy = CPU + GPU + radio + display.
- iOS scores apps; high score → "Battery" settings shows app.
- Background activity scrutinized (BGTaskScheduler quotas).

Android battery model:
- Doze + App Standby restrict background.
- Foreground services declare type (Android 14+).
- Battery Historian shows wake locks, alarm wakeups, sync events.

Data model:
- Cellular / metered detection.
- Background data restriction.
- Data Saver propagated via NetInfo.

Mitigations:
- **Defer**: non-critical work to wifi + charging.
- **Coalesce**: batch network calls.
- **Cache**: skip repeated fetches.
- **Compress**: smaller payloads = less battery + less data.
- **Prefetch carefully**: only on wifi.
- **Image budget**: cap image cache size.

Background patterns:
- Use `WorkManager` constraints (charging, unmetered).
- Use `BGProcessingTask` (iOS) for long work when device idle.
- Avoid `setInterval` — use OS scheduler.

The 2026 specific:
- **iOS 18 Energy** stricter on background.
- **Android 15 Foreground Service Types** required.
- **Static Hermes** less CPU per call → less battery.
- **HTTP/3** more efficient → less radio drain.
- **Push 'critical' classes** restricted in iOS.

Customer-facing energy saver mode:
- Detect low battery → reduce sync frequency, downgrade quality.
- Honor system Low Power Mode.

---

## The "Why"

Battery + data = silent retention killers. Hard to detect from logs; show in store reviews + uninstalls. Companies care because device-friendliness ≈ trust.

---

## Mental Model

Energy = CPU+GPU+radio+display. Optimize biggest drain first. Measure before optimizing.

---

## Internal Working (2026 Context)

- iOS reports energy score per process.
- Play Console aggregates battery per app version.
- NetInfo abstracts platform metering.

---

## Modern Implementation (Code)

**Adaptive sync**:
```ts
import * as Battery from 'expo-battery';
import NetInfo from '@react-native-community/netinfo';

async function shouldSyncNow() {
  const battery = await Battery.getBatteryLevelAsync();
  const lowPower = await Battery.isLowPowerModeEnabledAsync();
  const net = await NetInfo.fetch();
  if (lowPower) return false;
  if (battery < 0.2) return false;
  if (net.details?.isConnectionExpensive) return false;
  return true;
}
```

**Image budget**:
```ts
import { Image } from 'expo-image';
Image.clearMemoryCache(); // when low memory
Image.clearDiskCache();   // periodic
```

---

## Comparison

| Drain | Mitigation |
|---|---|
| GPS | request permission, low-accuracy, defer |
| Network | batch + cache + compress |
| Background | OS scheduler + constraints |
| Animation | native driver, off main thread |
| Video | adaptive bitrate, limit prefetch |

---

## Production Usage

- All major apps measure energy + data.
- Quarterly review at large shops.

---

## Hands-On Exercise

1. Profile energy on a feature.
2. Measure data usage.
3. Add adaptive sync.
4. Honor Low Power Mode.

---

## Common Mistakes

- `setInterval` for sync.
- No metered detection.
- Background loops.
- Unbounded image cache.

---

## Production Red Flags

- "Why is the battery hot?" tickets.
- App in iOS Battery settings frequently.
- Play Console "Excessive wakeups" alerts.

---

## Performance & Metrics (MANDATORY)

- Battery drain per hour foreground: < 5% typical.
- Data per session: < 1MB average for content apps.

---

## Decision Framework

| Constraint | Action |
|---|---|
| Low battery | reduce sync + animation |
| Metered network | skip prefetch + image high-res |
| Background | use OS scheduler |
| Charging + wifi | flush all queues |

---

## Senior-Level Insight

Treat energy and data as features. Senior teams maintain a "device-friendliness" budget reviewed each release. Bad week → freeze battery-relevant features.

---

## Memory Hook
**"Defer, coalesce, cache, compress."**

## Revision Notes
> Battery: Xcode Energy + Battery Historian + Play Console reports. Top drains: GPS, network, background, render. Data: compress + cache + honor Data Saver. Adaptive sync based on battery + network state.

---

---

### Q5. Tying client traces to server traces (W3C trace context)

---

## Difficulty
- Advanced

## Interview Frequency
- Common (distributed systems rounds)

## Prerequisites
- HTTP, OpenTelemetry, Q1

## TL;DR
**W3C Trace Context** standardizes trace propagation via `traceparent` (and optional `tracestate`) headers. Client generates a span, sets traceparent on outbound HTTP, server extracts and continues. Result: one trace ID spans app + gateway + services + DB. Use OTel propagator. Sample consistently (head sampling at client; backends honor decision). For non-HTTP (WebSocket, push), use protocol-specific context fields.

---

## 30-Second Interview Answer

> "W3C trace context = `traceparent` header carrying version, trace ID, parent span ID, flags. Client OTel SDK injects on every outbound; backend extracts on every inbound. Sampled flag tells the backend whether to record. Result: one trace ID across app → gateway → API → database. For WebSocket, embed traceparent in message envelope. For push notifications coming back into app, server includes traceparent in payload so app continues the trace. Sample at client (head sampling); backend honors."

---

## 2-Minute Practical Answer

**`traceparent` format**:
```
00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
^^  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^  ^^
ver trace-id (16B hex)               span-id (8B hex)  flags
```

`tracestate` (optional vendor extensions):
```
tracestate: vendor1=key=value,vendor2=...
```

**Client inject**:
```ts
import { propagation, context } from '@opentelemetry/api';
function injectHeaders(headers: Record<string, string>) {
  propagation.inject(context.active(), headers);
  return headers;
}
fetch('/api/feed', { headers: injectHeaders({}) });
```

**Server extract (Node)**:
```ts
import { propagation, context } from '@opentelemetry/api';
app.use((req, res, next) => {
  const ctx = propagation.extract(context.active(), req.headers);
  context.with(ctx, () => next());
});
```

**Sampling**:
- Client decides: sampled flag = `01` if include, `00` if drop.
- Backend honors: doesn't re-sample (saves consistency).
- Tail sampling at collector for error captures.

**Beyond HTTP**:
- WebSocket: embed `traceparent` in message envelope JSON.
- gRPC: metadata field (already standardized).
- Push payload: include traceparent → app reads on tap → continues trace.

---

## 5-Minute Architecture Answer

Why standardize:
- Pre-W3C: each vendor used different header (`X-Datadog-Trace-Id`, `X-B3-TraceId`).
- Multi-vendor systems didn't trace cross-boundary.
- W3C trace context unified → vendor interop.

End-to-end flow:
1. App user taps button.
2. App span starts (trace ID generated).
3. Outbound HTTP: traceparent injected.
4. API gateway: extract, continue trace.
5. Service: extract, continue.
6. DB query span (instrumented driver).
7. Response back: trace stays in backend store.
8. Backend correlates app + server spans by trace ID.
9. Engineer searches trace ID → sees full graph.

Sampling consistency:
- Decision at trace start (client).
- Backend reads sampled flag.
- All-or-nothing: either full trace recorded or none.
- Avoid mid-trace flip (broken correlations).

Edge cases:
- Long-lived sessions: rotate trace IDs per logical operation, not per session.
- Background tasks: separate trace.
- Retries: same trace, new span (link via parent span ID).

WebSocket pattern:
```json
{ "type": "msg.send", "traceparent": "00-...", "payload": {...} }
```

Push pattern (server → client):
- Server records "notification.send" span.
- Includes traceparent in payload.
- Client on tap: extract, start new span as child.
- Can reconstruct: send → deliver → tap → action.

The 2026 specific:
- **OTel SDK 2.0** stable across JS / iOS / Android.
- **Embrace / Sentry** auto-inject traceparent.
- **gRPC-Web** mobile clients emit traces.
- **Profile traces correlated** (Pyroscope).

Pitfalls:
- CORS: traceparent allowed by default; enforce on cross-origin.
- Privacy: trace IDs not PII but link sessions.
- Server-side: don't propagate to untrusted external services.

---

## The "Why"

End-to-end traces collapse "client team vs backend team" finger-pointing. One trace = one truth. Companies care because resolution time tanks.

---

## Mental Model

`traceparent` is the baton in a relay. Each leg holds it briefly, hands off cleanly.

---

## Internal Working (2026 Context)

- Propagator interfaces (W3C, B3, Jaeger) selectable in OTel SDK.
- Auto-instrumentation packages handle inject/extract.

---

## Modern Implementation (Code)

**WebSocket envelope**:
```ts
function send(msg: any) {
  const headers: Record<string, string> = {};
  propagation.inject(context.active(), headers);
  ws.send(JSON.stringify({ ...msg, _traceparent: headers.traceparent }));
}
```

**Push payload include (server)**:
```ts
const span = tracer.startSpan('notification.send');
const ctx = trace.setSpan(context.active(), span);
const headers: Record<string, string> = {};
propagation.inject(ctx, headers);
await sendPush({ data: { traceparent: headers.traceparent, ... } });
span.end();
```

**Push handler (app)**:
```ts
function onNotificationOpen(data) {
  const ctx = propagation.extract(context.active(), { traceparent: data.traceparent });
  context.with(ctx, () => {
    tracer.startActiveSpan('notification.open', (s) => { ... });
  });
}
```

---

## Comparison

| Header | Standard? |
|---|---|
| traceparent + tracestate | W3C |
| X-B3-* | Zipkin |
| X-Datadog-* | Datadog legacy |
| jaeger-* | Jaeger legacy |

---

## Production Usage

- All major OTel deployments.
- Vendors auto-translate legacy.

---

## Hands-On Exercise

1. Inject + extract for HTTP.
2. Extend to WebSocket.
3. Extend to push payload.
4. Verify single trace ID end-to-end in vendor UI.

---

## Common Mistakes

- Forgetting to inject (broken trace).
- Sampling decision changed mid-trace.
- Trace ID logged as PII (not technically PII, but be careful).
- CORS blocks header.

---

## Production Red Flags

- App spans not connected to server.
- Different trace IDs for same user action.
- Custom headers competing with W3C.

---

## Performance & Metrics (MANDATORY)

- Header overhead: ~70 bytes/request.
- Inject/extract: < 0.1ms.

---

## Decision Framework

| Protocol | Header strategy |
|---|---|
| HTTP | traceparent header |
| gRPC | metadata |
| WebSocket | message envelope |
| Push | payload field |

---

## Senior-Level Insight

End-to-end tracing is **the** observability investment. Senior teams ensure every new service emits + propagates from day 1.

---

## Memory Hook
**"traceparent: ver-trace-span-flags."**

## Revision Notes
> W3C trace context: `traceparent` carries trace + span + sampled flag. Client injects, server extracts, trace continues. Use OTel propagator. WebSocket / push: embed in envelope/payload. Sample at client; backend honors.

---

> **End of S18.** Cross-refs: [S6 Hermes & Metro](S06-hermes-metro.md) (sourcemaps), [S17 Testing](S17-testing-debugging.md) (Sentry crashes), [S20 CI/CD](S20-cicd-release.md) (release gating), [S27 Runbooks](S27-runbooks.md). Next per priority: [S20 CI/CD](S20-cicd-release.md).
