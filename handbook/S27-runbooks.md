# S27 — Production Runbooks

> Crash spike triage · OTA vs binary rollback · ANR triage · store rejection patterns · postmortem template

Runbooks turn 2am incidents from heroics into procedures. These are the five you'll be asked about most.

## Topics in this section

- [Q1. Crash spike — first 30 minutes](#q1-crash-spike--first-30-minutes)
- [Q2. OTA vs binary rollback decision](#q2-ota-vs-binary-rollback-decision)
- [Q3. ANR spike on Android — triage](#q3-anr-spike-on-android--triage)
- [Q4. Store rejection patterns and recovery](#q4-store-rejection-patterns-and-recovery)
- [Q5. Blameless postmortem template](#q5-blameless-postmortem-template)

---

## Q1. Crash spike — first 30 minutes

### Difficulty
Advanced

### Interview Frequency
Universal at senior+ rounds.

### Prerequisites
S18 (observability).

### TL;DR
1) Confirm spike (Sentry/Crashlytics + custom alerting). 2) Identify scope (version, OS, device, region). 3) Check recent deploys (binary, OTA, server). 4) Rollback if causal. 5) Communicate (#incidents). 6) Add monitor for next time.

### 30-Second Interview Answer
"First 30 min: confirm via Sentry + Crashlytics; scope by version/OS/region; correlate with recent deploys (binary, OTA, backend, feature flag); decide rollback (OTA = minutes; binary = days); post in #incidents with current state + ETA; once stable, schedule blameless postmortem. Goal: stop bleeding, not find blame."

### 2-Minute Practical Answer
The 30-min runbook:

| Min | Step | Goal |
|---|---|---|
| 0–2 | Acknowledge alert; declare incident | Single owner |
| 2–5 | Check Sentry top issues; confirm rate spike | Real or noise? |
| 5–10 | Scope: filter by version, OS, device, region | Audience size |
| 10–15 | Correlate: any deploy in last 24h (binary, OTA, server, flag)? | Suspect |
| 15–20 | Decide: rollback OTA (Expo Updates) / disable flag / revert backend | Action |
| 20–25 | Verify: crash rate dropping in real-time | Confirmation |
| 25–30 | Communicate: #incidents update; status page | Trust |

Tools:
- Sentry / Crashlytics for client crashes.
- Datadog / Grafana for backend.
- LaunchDarkly / Statsig for flag kill switch.
- Expo EAS Update for OTA rollback.
- Status page (Statuspage / Instatus) for users.

### 5-Minute Architecture Answer
Incidents test the boundary between observability + release engineering + organizational composure.

Incident roles (ICS-style):
- **Incident Commander** — single decision-maker; not necessarily senior but in charge.
- **Communications Lead** — updates #incidents + status page.
- **Subject Matter Expert(s)** — engineers debugging.
- **Scribe** — keeps timeline.

For mobile specifically:
- App-store rollback is **not** a real option (review takes days).
- OTA rollback for JS-only fixes (minutes via EAS Update).
- Native code regressions = no quick rollback; must mitigate via flag or server-side change.
- Enforce **OTA-friendly architecture** (don't put critical logic in native).

Communication template:
```
[INCIDENT] crash spike on iOS 17.4
Started: 14:32 UTC
Impact: 3% of iOS sessions (vs 0.1% baseline)
Suspected: PR #1234 OTA push at 14:20
Action: rolling back OTA now
Owner: @rajeev | Comms: @sara
Next update: 15:00 UTC
```

For 2026:
- Sentry has Issue Owners + AI suggestions for likely root cause.
- LaunchDarkly's "kill switch" pattern: every risky feature flag-gated.
- Custom alerting beyond just Sentry (e.g., Datadog Mobile RUM with synthetic checks).

### The "Why"
Slow incident response damages users + revenue + trust.

### Mental Model
Incident = **stop bleeding first**, **understand later**, **prevent always**.

### Internal Working (2026 Context)
- EAS Update can target previous bundle by version code.
- LaunchDarkly evaluates client-side; flag flip = seconds to take effect.
- Sentry filters in-place (no waiting for new SDK build).

### Modern Implementation (Code)
EAS Update rollback:
```bash
# List recent updates
eas update:list --branch production
# Republish older update
eas update --branch production --republish --group <good-update-id>
```

Feature flag kill:
```ts
// Check before risky code path
if (await flags.get('checkout_v3_enabled', { defaultValue: false })) {
  // new path
} else {
  // safe path
}
```

### Comparison

| Mitigation | Time | Risk |
|---|---|---|
| Feature flag flip | seconds | low |
| OTA rollback (JS) | minutes | low |
| Backend revert | minutes | medium |
| Binary rollback | days | not viable |
| Force update | days | bad UX |

### Production Usage
- Risky features always flag-gated.
- OTA rollback as muscle memory; tested quarterly.
- Status page updated in real-time.

### Hands-On Exercise
Run an incident drill: declare fake incident; practice rollback + comms; time it.

### Common Mistakes
- No incident commander (everyone debugs, no one decides).
- Forgetting to rollback before debugging.
- No comms; users panic.
- Native code regression with no fallback.

### Production Red Flags
- "Native push went bad; we'll wait for next release."
- No flag to kill the bad path.
- Engineers joining call asking what's going on.

### Performance & Metrics
- MTTD (Mean Time To Detect).
- MTTM (Mean Time To Mitigate).
- MTTR (Mean Time To Resolve).

### Decision Framework
- JS bug + OTA available → OTA rollback.
- Native bug + flag-gated → flag flip.
- Backend bug → backend revert.
- Native bug, no flag → emergency build + ask users to update (worst case).

### Senior-Level Insight
"The incident is not the time to learn how to rollback. Practice rollbacks quarterly; document the runbook in the wiki; assign on-call rotation."

### Real-World Scenario
2am crash spike from OTA push. On-call engineer rolled back via memorized command in 4 minutes; crash returned to baseline before users woke up.

### Production Failure Story
Native bug shipped via binary; no flag; users couldn't checkout for 3 days waiting for store review.
**Fix:** All risky features flag-gated henceforth; emergency binary submission process documented.

### Debugging Checklist
1. Incident declared + commander assigned?
2. Scope identified (version, OS, region)?
3. Recent deploys correlated?
4. Rollback executed before deep-debugging?
5. #incidents updated?

### Advanced / Internal Knowledge
- ICS (Incident Command System) for large incidents.
- "Severity levels" (SEV1–SEV5) drive escalation.
- Game days for incident practice.

### 2026 AI Tip
Sentry AI suggests likely PR / commit. Use as hypothesis, verify in code.

### Related Topics
Q2, Q3, Q5, S18, S20.

### Interview Follow-Up Questions
- "How do you decide rollback vs forward-fix?"
- "What if rollback isn't possible?"
- "How do you communicate with users?"

### Memory Hook
**"Confirm. Scope. Correlate. Rollback. Communicate."**

### Revision Notes
> Crash spike: confirm via Sentry; scope by version/OS/region; correlate with deploys; rollback first (OTA/flag); communicate in #incidents; postmortem after; practice rollbacks quarterly.

---

## Q2. OTA vs binary rollback decision

### Difficulty
Advanced

### Interview Frequency
Common.

### Prerequisites
Q1, S20 (CI/CD).

### TL;DR
**OTA** rollback for JS-only changes (Expo Updates / CodePush) — minutes. **Binary** rollback for native code is impossible via stores; must emergency-build a fixed version (days). Architect for OTA-rollback capability.

### 30-Second Interview Answer
"OTA rollback works for JS bundles via Expo Updates / CodePush — takes minutes. Binary rollback is **not possible** through app stores; you'd have to ship a fixed binary (review days). So architecture rule: keep critical logic in JS where possible; flag-gate native features. If a native bug ships, only options are: server-side mitigation, force-update (bad), or wait."

### 2-Minute Practical Answer
Decision tree:
1. Is the bug in JS? → OTA rollback.
2. Is the bug in native? → can the trigger be flag-gated server-side? → flip flag.
3. Native + no flag? → emergency binary build + expedited store review.
4. Backend? → revert deploy.

OTA mechanics:
- Expo EAS Update tracks bundles by branch + ID.
- Republish older bundle: `eas update --branch production --republish --group <id>`.
- Users get rollback on next app launch (Wi-Fi).
- New install gets latest binary's fallback bundle, then OTA on first launch.

OTA constraints:
- Apple: JS-only updates allowed; no new native modules; no significant feature changes.
- Google: more lenient.
- App store policies evolve — read latest annually.

Binary rollback alternatives:
- **Force update** — push notification + in-app banner asking users to update. Bad UX; only for critical security.
- **Wait for next release** — disable feature server-side; ship fix in next planned release.
- **Hot-fix release** — emergency binary; expedited review; 1–3 days.

### 5-Minute Architecture Answer
Mobile rollback is fundamentally different from web:
- Web: revert + redeploy = seconds.
- Mobile: store gatekeeping + user-controlled installs = days/weeks lag.

Architectural implications:
- **OTA-first design** — keep critical logic in JS; minimize native features.
- **Flag everything risky** — every new feature behind a remote flag.
- **Version skew tolerance** — server / SDUI / API tolerate old clients (S21-Q3).
- **Crash budget per release** — if release exceeds budget, gradual rollout halts.

OTA tools comparison:
- **Expo EAS Update** — official Expo, best DX, native to managed workflow.
- **Microsoft CodePush** — sunset 2024; legacy projects only.
- **Custom OTA** — large companies (Discord, Shopify) maintain their own.

For 2026:
- EAS Update with branch-based deployments.
- Hermes bytecode in OTA bundles for fast load.
- Channel-based rollouts (canary → 10% → 100%).

Risks of OTA:
- Crashes in OTA bundle = users on new bundle until next launch.
- Native + JS API mismatch (OTA shipped JS expects native that's not there) → crashes.
- Cache poisoning if rollout is interrupted.

### The "Why"
Mobile users live with bugs longer than web users. Architecture decides how long.

### Mental Model
OTA = **fast lane** for JS; binary = **slow lane** for native; flag = **express override**.

### Internal Working (2026 Context)
- EAS Update has branch + channel concepts.
- Hermes bytecode bundled for performance.
- Update applied on next cold start + Wi-Fi.

### Modern Implementation (Code)
Expo Updates check at startup:
```ts
import * as Updates from 'expo-updates';

useEffect(() => {
  (async () => {
    try {
      const update = await Updates.checkForUpdateAsync();
      if (update.isAvailable) {
        await Updates.fetchUpdateAsync();
        await Updates.reloadAsync(); // applies new bundle
      }
    } catch (e) {
      // silent fail; user uses cached bundle
    }
  })();
}, []);
```

Channel-based rollout via app config:
```json
{
  "expo": {
    "updates": { "url": "https://u.expo.dev/<project>" },
    "runtimeVersion": "1.0.0"
  }
}
```

### Comparison

| Method | Speed | Scope |
|---|---|---|
| Flag flip | seconds | flag-gated code |
| OTA rollback | minutes | JS-only |
| Backend revert | minutes | server-driven |
| Binary hot-fix | days | native bugs |
| Force update | days | last resort |

### Production Usage
- Every senior team has OTA + flag infrastructure.
- Native features audited for "rollback-ability" pre-release.
- Quarterly drills.

### Hands-On Exercise
1. Set up Expo EAS Update.
2. Push a bundle; revert.
3. Time the rollback.

### Common Mistakes
- Putting critical logic in native (no rollback).
- No flags on new features.
- OTA bundle assuming native that's not in user's binary.

### Production Red Flags
- "We'll fix it in the next release" for a P0 bug.
- No rollback drill in last year.
- No channel-based rollout.

### Performance & Metrics
- Rollback time (minutes).
- % of features behind flags.
- Crash budget adherence.

### Decision Framework
- JS bug → OTA.
- Native + flag → flag flip.
- Native, no flag → mitigate server-side or hot-fix binary.

### Senior-Level Insight
"The bug you can't roll back is the bug you can't ship safely. Architect for rollback before architecting for features."

### Real-World Scenario
JS-only bug in checkout shipped Friday afternoon. OTA rollback in 4 minutes; weekend saved.

### Production Failure Story
Native crash from a TurboModule shipped binary; no flag; couldn't roll back; users stuck for 5 days.
**Fix:** Mandatory flag-gating on all native features; documented in code review checklist.

### Debugging Checklist
1. Bug location: JS vs native vs backend?
2. Flag available?
3. Channel rollback path tested?
4. Comms drafted?

### Advanced / Internal Knowledge
- Apple's policy on OTA changed in 2023; check current rules.
- Bytecode (Hermes) bundled OTA reduces parse time.
- Some teams pre-build emergency hot-fix binaries on every release.

### 2026 AI Tip
AI helps draft incident comms but never decides rollback strategy.

### Related Topics
Q1, Q3, S20.

### Interview Follow-Up Questions
- "What's the longest you've waited for a binary fix?"
- "Apple's stance on OTA — what's allowed?"
- "Architect a mobile system for max rollback-ability."

### Memory Hook
**"OTA fast for JS. Binary slow for native. Flag everything risky."**

### Revision Notes
> OTA rollback (Expo EAS Update) for JS-only in minutes; binary rollback impossible via store (emergency build = days); flag-gate risky native features; channel rollouts; quarterly drills.

---

## Q3. ANR spike on Android — triage

### Difficulty
Advanced

### Interview Frequency
Common at Android-heavy / Indian markets.

### Prerequisites
S07, S13.

### TL;DR
ANR = main thread blocked > 5s. Causes: synchronous storage (AsyncStorage), heavy computations, native bridge calls, image decode, lock contention. Triage: check Crashlytics ANR cluster → identify stack trace pattern → fix offender (move off main thread).

### 30-Second Interview Answer
"ANR (Application Not Responding) fires when Android's main thread is blocked > 5s. Common RN causes: AsyncStorage on main thread, heavy JS work in `useLayoutEffect`, native bridge contention, synchronous image decode. Triage: Crashlytics ANR cluster → top stack frames → find offender → move work off main thread (worker, async, JSI)."

### 2-Minute Practical Answer
Top ANR causes in RN:
1. **Synchronous storage** — AsyncStorage on main thread (use MMKV or async wrappers).
2. **Heavy JS work** in startup or layout passes.
3. **Native bridge contention** — too many bridge calls per frame.
4. **Image decode** — large images blocking main thread (use expo-image, off-main).
5. **Database queries** — sync SQLite on main thread.
6. **WebView heavy load** — blocks app process.
7. **Reanimated worklet errors** — unhandled exceptions can stall.

Triage workflow:
1. Crashlytics ANR section; cluster by trace.
2. Identify top frame (often library code, but trace back to your call).
3. Reproduce on slow Android device (low memory class).
4. Profile via Android Studio CPU profiler (enable for that build).
5. Fix: move to background, async, or rewrite.

For 2026:
- Bridgeless mode reduces bridge-contention ANRs.
- TurboModules on dedicated threads.
- Hermes startup faster.

Quick wins:
- Replace AsyncStorage with MMKV (sync but fast).
- Lazy-load heavy modules.
- Use `InteractionManager.runAfterInteractions` for non-critical work.
- Use `ImageBackground` cautiously; prefer `expo-image`.

### 5-Minute Architecture Answer
ANRs are an Android-specific signal but RN engineers see them across platforms. Architecturally:
- **Main thread is precious** — anything blocking should be moved off.
- **JS thread vs UI thread** — RN traditionally has both; Bridgeless blends but main UI thread still rules.
- **Native modules block UI** if synchronous; TurboModules can dispatch off-main.
- **Reanimated worklets run on UI thread** — keep them lightweight.

Diagnosing:
- Crashlytics ANR clusters by stack trace.
- `traces.txt` from device (developer mode).
- Android Studio profiler with `--profileable` apps.
- Custom monitors (ANR-Watchdog) for proactive detection.

Architecture patterns to prevent ANRs:
- All storage async or MMKV.
- All network async (default).
- Heavy compute in worker threads (`react-native-multithreading`, JSI workers).
- Lazy-load screens (Expo Router code-splits).
- Image: expo-image with priority + cachePolicy.

For 2026:
- Bridgeless reduces some classes of ANRs.
- New Architecture exposes thread model better.
- React Compiler doesn't introduce ANRs but doesn't prevent them either.

### The "Why"
ANRs hurt Play Store ratings + retention; Google Play vitals tracks them.

### Mental Model
Main thread = on-stage performer. Anything taking > 16ms is a stall; > 5s is an ANR.

### Internal Working (2026 Context)
- ANR detector built into Android system; reports to Play Vitals.
- Crashlytics aggregates ANRs separately from crashes.

### Modern Implementation (Code)
Async wrapper for AsyncStorage migration:
```ts
import { MMKV } from 'react-native-mmkv';
const storage = new MMKV();

// Was: await AsyncStorage.getItem('key')
// Now: synchronous + fast
const value = storage.getString('key');
```

Off-main heavy work:
```ts
import { InteractionManager } from 'react-native';
useEffect(() => {
  InteractionManager.runAfterInteractions(() => {
    // heavy compute or analytics
  });
}, []);
```

### Comparison

| Cause | Fix |
|---|---|
| AsyncStorage | MMKV |
| Image decode | expo-image |
| Sync SQLite | WatermelonDB or async |
| Native bridge | TurboModules |
| Layout calculation | Defer to next frame |

### Production Usage
- Google Play Vitals dashboard checked weekly.
- ANR threshold: < 0.47% per Google's "bad behavior" line.
- Vitals regression triggers release halt.

### Hands-On Exercise
1. Find an ANR in Crashlytics (or simulate via `Thread.sleep(6000)`).
2. Trace to source.
3. Refactor.

### Common Mistakes
- Ignoring ANRs (only watching crashes).
- Treating ANR as "minor" when Vitals downgrades app visibility.
- Sync storage on app start.

### Production Red Flags
- AsyncStorage at app boot.
- Heavy JS in `useLayoutEffect`.
- Synchronous file I/O.

### Performance & Metrics
- ANR rate (target < 0.1%).
- Play Vitals "bad behavior" status.
- App start time.

### Decision Framework
- Heavy work → off main thread.
- Storage → MMKV or async.
- Native call → TurboModule.

### Senior-Level Insight
"ANRs are silent killers. Users uninstall without complaining; Play Store demotes; you only see lagging revenue."

### Real-World Scenario
ANR rate spiked after new analytics SDK; SDK initialized synchronously on main thread; moved to deferred init; ANR rate dropped 60%.

### Production Failure Story
App boot took 8s on cold start due to AsyncStorage migration on main thread.
**Fix:** Migrated to MMKV; boot dropped to 1.2s; ANRs near zero.

### Debugging Checklist
1. Crashlytics ANR cluster reviewed?
2. Stack trace traced to your code?
3. Off-main alternative implemented?
4. Slow-device test passes?

### Advanced / Internal Knowledge
- Strict mode in dev catches some ANRs.
- ANR-Watchdog libraries provide stack at moment of stall.
- Vitals affect store ranking; > 0.47% gets you flagged.

### 2026 AI Tip
AI rarely flags ANR risks in code. Add a manual checklist for storage / heavy compute.

### Related Topics
Q1, S07, S13.

### Interview Follow-Up Questions
- "How does ANR differ from crash?"
- "What's MMKV's advantage over AsyncStorage?"
- "How do you detect ANRs in dev?"

### Memory Hook
**"Main thread is sacred. Storage async. Compute deferred. Decode off-main."**

### Revision Notes
> ANR = Android main thread blocked > 5s; common causes: AsyncStorage, image decode, heavy JS, sync DB; triage via Crashlytics; fix via MMKV, expo-image, InteractionManager, TurboModules; Play Vitals threshold 0.47%.

---

## Q4. Store rejection patterns and recovery

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common.

### Prerequisites
App store basics.

### TL;DR
Common rejections: privacy/IDFA missing, broken sign-in (esp. Apple Sign-In requirement), background usage, payments outside IAP, metadata mismatches, crashes during review. Recovery: respond fast (< 24h), provide test credentials, document compliance.

### 30-Second Interview Answer
"Top rejections: missing privacy disclosures (App Tracking Transparency on iOS, Data Safety on Play), missing Apple Sign-In when other social logins exist, IAP bypass for digital goods, broken test account, background usage justification missing, crashes during review. Recovery: respond in app review within 24h; provide test creds; cite specific compliance; iterate."

### 2-Minute Practical Answer
Apple-specific rejections:
- **Guideline 5.1.1** — privacy: no consent flow for tracking; missing privacy manifest (2024+).
- **Guideline 4.8** — Sign in with Apple required when other social logins offered.
- **Guideline 3.1.1** — IAP required for digital goods.
- **Guideline 2.1** — bugs/crashes during review.
- **Guideline 4.0** — design quality (vague; usually metadata or screenshot mismatch).

Google Play rejections:
- **Data Safety form** missing or inaccurate.
- **Sensitive permissions** without justification (SMS, Call Log).
- **Foreground service** abuse.
- **Account deletion** missing (required since 2023).
- **Target SDK** outdated.

Recovery checklist:
1. Read rejection carefully; don't assume.
2. Respond in App Review (Apple) / Play Console (Google) within 24h.
3. Provide test credentials.
4. Cite specific guideline + how you comply.
5. Re-submit only after fix verified internally.

For 2026:
- iOS Privacy Manifest (`.privacy.json`) required for many SDKs.
- Google's account-deletion endpoint required for accounts.
- Both stores enforcing target SDK levels aggressively.

### 5-Minute Architecture Answer
Store reviews are the **last gate**; senior engineers prevent rejections proactively:

Pre-submission checklist:
- [ ] Privacy Manifest (iOS) for all SDKs in use.
- [ ] App Tracking Transparency consent flow (iOS).
- [ ] Data Safety form (Play) — accurate.
- [ ] Sign in with Apple if any social login.
- [ ] Account deletion endpoint (both).
- [ ] Test account that works (no expired codes).
- [ ] Screenshots match current app.
- [ ] Demo video for complex features.
- [ ] All permissions justified in description.

Architecture for compliance:
- Privacy gates around analytics SDKs.
- Single source of truth for "what data we collect" (auto-generates Data Safety entries).
- Background tasks audited; remove unnecessary ones.

For mobile teams, dedicated **release engineering** owns store relationships:
- Pre-flight checklist.
- Test account hygiene.
- Rejection response playbook.
- Reviewer comm template.

For 2026:
- Apple requires manifest declarations for "required reason APIs" (UserDefaults, FileManager date, etc.).
- Some SDKs (analytics, ads) require explicit signed manifest entries.
- Pre-submission CI validates manifest completeness.

### The "Why"
Each rejection delays release by 2–7 days; revenue / launches / fixes blocked.

### Mental Model
Reviewer = customer with a checklist. Make checklist easy to pass.

### Internal Working (2026 Context)
- Apple App Review Guidelines updated quarterly.
- Privacy Manifest enforcement turned on early 2024; expanding.
- Google's pre-launch reports flag some issues automatically.

### Modern Implementation (Code)
Privacy manifest example (`PrivacyInfo.xcprivacy`):
```xml
<dict>
  <key>NSPrivacyTrackingDomains</key>
  <array>
    <string>analytics.example.com</string>
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
  </array>
</dict>
```

Account deletion endpoint:
```ts
// Required by both stores
app.delete('/account', authenticate, async (req, res) => {
  await deleteUserAccount(req.user.id);
  res.json({ deleted: true });
});
```

### Comparison

| Rejection | Recovery time | Prevention |
|---|---|---|
| Missing test creds | < 24h | Pre-flight checklist |
| Privacy missing | 1–3 days | Manifest review |
| IAP bypass | 3–7 days | Architecture decision |
| Crash during review | 2–5 days | Real-device QA pre-submit |

### Production Usage
- Senior teams have a Release Captain rotating role.
- Pre-flight checklist in PR template.
- Rejection responses templated.

### Hands-On Exercise
Audit your app against Apple + Google checklists; fix gaps before next release.

### Common Mistakes
- Test account with expired phone OTP.
- Missing demo video for complex flows.
- Permissions declared but not used.
- Dismissive responses to reviewer.

### Production Red Flags
- No Release Captain.
- Pre-flight checklist absent.
- Frequent rejections.

### Performance & Metrics
- First-pass approval rate (target > 90%).
- Mean time to recovery from rejection.

### Decision Framework
- Privacy / data → align before submit.
- Test creds → fresh per submission.
- Reviewer comm → prompt + specific.

### Senior-Level Insight
"Most rejections are preventable. The teams that get rejected often skip the boring parts: privacy manifest, test creds, screenshot updates."

### Real-World Scenario
App rejected for missing Sign in with Apple; team scrambled to add it; lost 2 weeks before launch.
**Fix:** Built compliance checklist; never repeated.

### Production Failure Story
Rejected for crash during review; couldn't reproduce internally; turned out reviewer used iPad with iOS beta; added device matrix to QA.

### Debugging Checklist
1. Pre-flight checklist passed?
2. Test creds verified < 7 days old?
3. Screenshots current?
4. Permissions match usage?
5. Privacy manifest complete (iOS)?
6. Data Safety form accurate (Play)?

### Advanced / Internal Knowledge
- Apple Developer Forums for grey-area guidelines.
- Reviewer can request video for complex features.
- Expedited review available 1–2x per year (don't waste).

### 2026 AI Tip
AI helps draft reviewer responses (cite specific guideline + how you comply).

### Related Topics
Q1, S20.

### Interview Follow-Up Questions
- "How do you reduce rejection rate?"
- "What's Privacy Manifest?"
- "How do you handle a 'crash during review'?"

### Memory Hook
**"Pre-flight checklist. Fresh test creds. Privacy first. Respond < 24h."**

### Revision Notes
> Top rejections: privacy, Sign in with Apple, IAP, crashes during review, missing account deletion; Release Captain owns submission; pre-flight checklist; respond < 24h; cite guidelines.

---

## Q5. Blameless postmortem template

### Difficulty
Advanced

### Interview Frequency
Common at senior+ rounds.

### Prerequisites
Q1.

### TL;DR
Blameless = focus on systems, not people. Template: timeline, impact, root cause (5-whys or causal tree), what went well, what went wrong, action items with owners + due dates. Distribute widely; review in retro.

### 30-Second Interview Answer
"Blameless postmortems focus on systems: timeline of events, user/business impact, contributing factors via 5-whys or causal analysis, what went well, what went wrong, action items with owners + due dates. We distribute widely (whole eng) and review in monthly retros to make sure action items land. The goal is learning + prevention, never blame."

### 2-Minute Practical Answer
Template structure:

```md
# [Incident] [Date] — [Title]

## Summary
[2 sentences: what + impact]

## Timeline (UTC)
- 14:32 — alert fired
- 14:35 — IC assigned
- 14:40 — root cause hypothesis
- 14:50 — rollback initiated
- 15:02 — crash rate normalized
- 15:30 — incident closed

## Impact
- Users: 12k affected
- Duration: 30 min
- Revenue: estimated $4k
- Trust: 1 status page entry; 12 customer support tickets

## What went well
- Alerting fired correctly
- Rollback drill paid off; OTA in 4 min
- Comms clear in #incidents

## What went wrong
- PR wasn't tested on iOS 17.4 (regression edge)
- Flag was off; couldn't kill faster
- Root cause not understood until 30 min after rollback

## Root cause (5-whys)
- Crash on iOS 17.4
- Why? Used a deprecated NSURLSession API
- Why? Library hadn't been updated
- Why? No automated alert for outdated dependencies
- Why? Renovate disabled to reduce noise
- Why? Process change made 6 months ago without follow-up

## Action items
| Action | Owner | Due | Status |
|---|---|---|---|
| Re-enable Renovate with grouping | @ana | 2025-02-15 | open |
| Add iOS 17.4 to device matrix | @priya | 2025-02-20 | open |
| Document OTA rollback runbook v2 | @raj | 2025-02-15 | open |
| Add flag-gating to risky PRs (process) | @em | 2025-02-28 | open |

## Lessons learned
- Dependency hygiene matters even if "it works."
- Device matrix must include latest minor OS versions.
```

### 5-Minute Architecture Answer
Postmortems are an organizational learning tool. Done well:
- **Blameless** — names of people only as roles ("on-call," "IC"), not blamed.
- **Specific** — exact timestamps, exact actions.
- **Action-oriented** — every "we should" becomes an action with owner + date.
- **Distributed widely** — whole eng learns.
- **Reviewed** — monthly retro tracks action items to completion.

Common postmortem failures:
- Blame ("X engineer made the bad commit").
- Vague actions ("be more careful").
- No follow-up; action items rot.
- Hidden in a doc no one reads.

For 2026:
- AI-assisted draft generation (paste timeline → first draft).
- Postmortem registry with searchable patterns.
- Action item tracker integrated with project management.

Cultural foundations:
- Leadership models blameless behavior.
- Engineers volunteer to be IC (not punished).
- Action items prioritized like other work.
- Annual "incidents trends" review.

For senior+ engineers:
- Run postmortems for major incidents.
- Identify systemic patterns across multiple incidents.
- Drive process changes (release engineering, observability investments).

### The "Why"
Without postmortems, organizations relive the same incidents.

### Mental Model
Postmortem = **organizational debug session**: find the systems issue, fix the system.

### Internal Working (2026 Context)
- Many companies (Google, Etsy) public-shared their postmortem templates.
- Tools (Jeli, Blameless.com) productize the workflow.

### Modern Implementation (Code)
Use the template above as a markdown file in `docs/incidents/`.

Action item tracking:
```ts
// Often in Linear / Jira
// Tag: incident:INC-2025-001
// Owner + due date enforced
```

### Comparison

| Approach | Pros | Cons |
|---|---|---|
| Blameless | Learning culture | Requires leadership |
| Blame culture | "Accountability" | Hides real causes |
| No postmortem | Fast move-on | Repeats incidents |

### Production Usage
- All SEV1/SEV2 get postmortems.
- Smaller incidents get a summary in #incidents.
- Quarterly trends review.

### Hands-On Exercise
For a recent issue you've been part of, draft a blameless postmortem in the template.

### Common Mistakes
- Naming individuals as fault.
- Vague action items.
- No owner / no due date.
- Buried doc.

### Production Red Flags
- "Engineer X needs more training."
- "Action items: 'be more careful.'"
- Same incident type recurring.

### Performance & Metrics
- Action item completion rate (target > 80% within due date).
- Recurring incident type rate.
- Time-to-postmortem-published (target < 5 business days).

### Decision Framework
- SEV1/2 → full postmortem.
- SEV3 → light writeup.
- SEV4/5 → log in #incidents.

### Senior-Level Insight
"Postmortems are how teams compound learning. Skip them, and every incident teaches one engineer; embrace them, and every incident teaches the org."

### Real-World Scenario
Same crash type repeated 3 times in 6 months because postmortems weren't reviewed; action items never landed. Fixed by quarterly trends review + dedicated action-item tracker.

### Production Failure Story
Engineer named in postmortem as "responsible"; quit 3 months later. Org switched to blameless; retention improved.

### Debugging Checklist
1. No names blamed?
2. Timeline specific?
3. Root cause via 5-whys or causal tree?
4. Action items: owner + due date?
5. Distributed widely?

### Advanced / Internal Knowledge
- Causal trees (more rigorous than 5-whys).
- Just Culture (accountability without blame).
- Pre-mortems (imagine failure before launch).

### 2026 AI Tip
AI drafts timeline + summary from raw chat logs; human writes root cause + actions.

### Related Topics
Q1, Q2, Q3, S25.

### Interview Follow-Up Questions
- "Walk me through a postmortem you led."
- "How do you ensure action items land?"
- "What's blameless about?"

### Memory Hook
**"Timeline. Impact. Root cause. Actions. No blame. Distribute widely."**

### Revision Notes
> Blameless postmortem: timeline, impact, root cause (5-whys), what worked, what didn't, action items (owner + due); SEV1/2 always; review quarterly trends; never name individuals as faults; distribute widely.

---

> Cross-refs: S18 (observability), S20 (CI/CD), S25 (behavioral).
