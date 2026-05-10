# S30 — Privacy, Compliance & Trust

> Privacy Manifests · ATT · Privacy Sandbox · GDPR/CPRA/DPDP · CMP · data minimization · COPPA · DSA

Privacy is now a release-blocker, not a checkbox. In 2026: **iOS requires Privacy Manifests + Required-Reason API declarations**, **ATT enforced**, **Android Privacy Sandbox** rolling out, **GDPR/CPRA/DPDP** define defaults, **DSA** adds EU obligations, **CMPs** govern consent. This section covers the five rounds you'll see most.

---

### Q1. iOS Privacy Manifests — end-to-end (your code + SDK chain)

---

## Difficulty
- Advanced

## Interview Frequency
- Common (privacy / release rounds)

## Prerequisites
- iOS app review basics

## TL;DR
Apple requires a `PrivacyInfo.xcprivacy` file in your app **and every third-party SDK** declaring: (1) data types collected + purposes, (2) tracking domains, (3) usage of Required-Reason APIs (UserDefaults, fileTimestamps, systemBootTime, diskSpace). Mismatch with privacy nutrition labels = rejection. SDKs without manifests fail App Store submission since 2024. Audit SDK chain per release.

---

## 30-Second Interview Answer

> "Privacy Manifest is `PrivacyInfo.xcprivacy` declaring (a) data types collected + purposes, (b) tracking domains for ATT enforcement, (c) Required-Reason API usage with approved reason codes — UserDefaults, fileTimestamps, systemBootTime, diskSpace. Each third-party SDK must ship its own manifest; Xcode aggregates into the app. Apple validates against privacy nutrition labels at submission. Mismatch = rejection. The signed manifest hash is also enforced for popular SDKs. Audit SDK chain per release; remove unused SDKs."

---

## 2-Minute Practical Answer

**App `PrivacyInfo.xcprivacy`** (XML plist):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyTrackingDomains</key>
  <array/>
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
      <array><string>CA92.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

**Required-Reason APIs** (must declare reason):
- `UserDefaults` (CA92.1 = app functionality, etc.)
- `File timestamp APIs` (C617.1 = inside app container)
- `System boot time` (35F9.1 = measure time elapsed)
- `Disk space` (E174.1 = display low-storage UI)
- `Active keyboard` (54BD.1 = customize keyboard)

If you use these without declaring → rejection.

**Tracking domains**:
- Domains used for cross-app/site tracking.
- Apple blocks fetches to these unless ATT permission granted.
- Lists must match what your app does.

**Data types + purposes**:
- Apple categories: contact info, location, identifiers, usage, diagnostics, etc.
- Purposes: app functionality, analytics, personalization, third-party advertising, etc.
- Must match privacy nutrition labels in App Store Connect.

**SDK chain**:
- Each SDK ships its `PrivacyInfo.xcprivacy` inside its bundle.
- Xcode merges at build time.
- 80+ commonly used SDKs **require signature** (Apple's list since 2024).
- RN ecosystem: Expo modules, Reanimated, Skia, Sentry, Firebase, Statsig — all ship manifests.

**Audit workflow**:
1. List all SDKs (`pod list` / `npm ls`).
2. Verify each ships manifest.
3. Aggregate declared data + APIs.
4. Cross-check with App Store Connect labels.
5. Update labels if drift.
6. Block release if SDK without manifest.

---

## 5-Minute Architecture Answer

Why this exists:
- Pre-manifest era: SDKs collected data invisibly to app developers.
- Apple shifted accountability to apps: you are responsible for what your SDKs do.
- Manifest = enforced disclosure + compile-time check.

What's enforced (2026):
- Manifest required for app submission.
- Tracking domains list enforced (network blocked if not declared + ATT denied).
- Required-Reason APIs validated at submission.
- SDK list (Apple-published) requires signature.

Privacy nutrition labels:
- Set in App Store Connect.
- Must match Privacy Manifest disclosure.
- Mismatch detected by Apple's automated check at submit.

Tracking semantics:
- "Tracking" = linking with data from other companies for ad targeting / measurement / data brokers.
- ATT applies if you track.
- Manifest declares whether each data type is used for tracking.

Common rejections:
- App declares no tracking; SDK does → mismatch.
- Required-Reason API used without reason code.
- Tracking domain present in code but not declared.

Tooling:
- Xcode 16+ has manifest validator.
- `swift package dump-pif` / build logs show merged manifest.
- 3rd-party tools (DataDome Privacy Checker, App Privacy Insights) audit SDK manifests.

For RN / Expo specifically:
- Expo modules ship manifests since SDK 50.
- React Native core ships from 0.74.
- Most major libs caught up by 2024–2025.
- `expo-build-properties` config plugin can extend manifest from JS config.

App-side aggregation in `app.json` (Expo):
```json
{
  "ios": {
    "privacyManifests": {
      "NSPrivacyAccessedAPITypes": [
        { "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
          "NSPrivacyAccessedAPITypeReasons": ["CA92.1"] }
      ]
    }
  }
}
```

The 2026 specific:
- **Signed Privacy Manifest** for top-100 SDKs.
- **App Store metadata API** allows automated label sync.
- **EU DSA + DMA** require additional disclosures (trader info).
- **AI/ML SDKs** need disclosure if training on user data.

Operational hygiene:
- Privacy review in PR template.
- SDK addition gated on manifest verification.
- Quarterly SDK audit.

---

## The "Why"

Without manifest discipline → rejected releases + brand risk + regulator action. Companies care because privacy is reputational tier-0.

---

## Mental Model

Manifest = ingredients label for your app + every SDK. Apple enforces ingredient honesty.

---

## Internal Working (2026 Context)

- Xcode merges manifests from app + SDKs.
- App Store Connect validates against labels.
- Runtime: tracking domain blocking enforced by OS network stack.

---

## Modern Implementation (Code)

**Validate SDK manifests (CI script)**:
```bash
#!/bin/bash
missing=()
for pod in $(ls Pods); do
  if [ ! -f "Pods/$pod/PrivacyInfo.xcprivacy" ] && \
     ! grep -l "PrivacyInfo.xcprivacy" "Pods/$pod"/*.bundle 2>/dev/null; then
    missing+=("$pod")
  fi
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing privacy manifests: ${missing[@]}"
  exit 1
fi
```

---

## Comparison

| Era | Disclosure |
|---|---|
| Pre-2024 | privacy labels only |
| 2024+ | manifest + signed SDKs |
| 2026 | manifest + label parity enforced |

---

## Production Usage

- All App Store apps mandatory.
- Most major SDKs compliant.

---

## Hands-On Exercise

1. Generate `PrivacyInfo.xcprivacy` for your app.
2. Audit Pods for manifests.
3. Sync App Store Connect labels.
4. Add CI check.

---

## Common Mistakes

- Declared "no tracking" while using analytics SDK that tracks.
- Required-Reason API without reason.
- Manifest in app but SDKs missing theirs.

---

## Production Red Flags

- "We'll add manifest before release."
- No quarterly SDK audit.
- Drift between app + Connect labels.

---

## Performance & Metrics (MANDATORY)

- Manifest size: < few KB.
- No runtime cost.

---

## Decision Framework

| Step | When |
|---|---|
| App manifest | always |
| Verify SDK manifests | every dep add/upgrade |
| Sync labels | every release |
| Audit | quarterly |

---

## Senior-Level Insight

Senior teams build manifest checks into the dependency PR template. They treat manifest mismatch as a P1 release blocker.

---

## Memory Hook
**"App + SDKs each declare. Apple cross-checks labels."**

## Revision Notes
> `PrivacyInfo.xcprivacy` declares data types, tracking domains, Required-Reason API usage. App + every SDK must ship one. Apple validates vs nutrition labels at submission. Top-100 SDKs require signature. Audit SDK chain per release.

---

---

### Q2. App Tracking Transparency (ATT) — patterns + consent gating

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- IDFA basics, ad attribution

## TL;DR
ATT = iOS prompt requiring user permission before tracking across apps/websites (i.e., before reading IDFA, before sending data to third parties for cross-app linking). **Show prompt only when you have a clear, justifiable reason**; pre-prompt with custom screen explaining value. Without ATT permission: IDFA returns zeros, attribution SDKs degrade. Use **SKAdNetwork (SKAN 4)** for privacy-preserving attribution. Don't init tracking SDKs before ATT decision.

---

## 30-Second Interview Answer

> "ATT requires user permission before tracking across apps/websites. Show a custom pre-prompt explaining why permission helps, then trigger system prompt via `requestTrackingAuthorization`. Without permission: IDFA = zeros, attribution SDKs work in privacy-preserving mode (SKAdNetwork 4). Critical: don't initialize tracking SDKs before ATT result; gate via consent. UX: prompt at high-value moment, not first launch. Honor opt-out across user IDs. Manifest must declare tracking + tracking domains."

---

## 2-Minute Practical Answer

**System prompt** (RN via expo-tracking-transparency):
```ts
import {
  getTrackingPermissionsAsync,
  requestTrackingPermissionsAsync,
} from 'expo-tracking-transparency';

async function ensureATT() {
  const { status: existing } = await getTrackingPermissionsAsync();
  if (existing !== 'undetermined') return existing;
  const { status } = await requestTrackingPermissionsAsync();
  return status; // 'granted' | 'denied' | 'restricted'
}
```

**Pre-prompt pattern**:
```tsx
function ATTPrePrompt() {
  return (
    <Modal>
      <Text>Allow personalized ads?</Text>
      <Text>Helps us keep the app free with ads relevant to you.</Text>
      <Button title="Continue" onPress={async () => {
        await requestTrackingPermissionsAsync();
        onClose();
      }} />
      <Button title="Not now" onPress={onSkip} />
    </Modal>
  );
}
```

**`Info.plist`** (`NSUserTrackingUsageDescription`):
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use this to show you personalized ads and measure their performance.</string>
```

**Privacy Manifest tracking declaration**:
```xml
<key>NSPrivacyTracking</key>
<true/>
<key>NSPrivacyTrackingDomains</key>
<array>
  <string>graph.facebook.com</string>
  <string>app-measurement.com</string>
</array>
```

**Gate SDK init on consent**:
```ts
import { Settings as FBSettings } from 'react-native-fbsdk-next';

async function initTracking() {
  const status = await ensureATT();
  if (status === 'granted') {
    await FBSettings.setAdvertiserIDCollectionEnabled(true);
    await FBSettings.setAdvertiserTrackingEnabled(true);
  } else {
    await FBSettings.setAdvertiserIDCollectionEnabled(false);
    await FBSettings.setAdvertiserTrackingEnabled(false);
  }
}
```

**SKAdNetwork (SKAN 4)** as privacy-preserving fallback:
- Apple-managed attribution; no user-level ID.
- Ad networks register; conversions aggregated by Apple.
- Configure conversion values (`updatePostback`).

---

## 5-Minute Architecture Answer

What "tracking" means under ATT:
- Linking data from your app with data from other companies' apps/websites for advertising or data brokering.
- Examples: passing IDFA to ad networks, server-to-server attribution with email hashes.
- Doesn't apply to first-party analytics (within your app).

UX timing:
- **Don't ask on first launch** (no context → high denial rate).
- Ask at moment user understands value (after onboarding, before ad-supported feature).
- Once denied, can't re-prompt (user must enable in Settings).

Pre-prompt:
- Custom screen before system prompt.
- Explain why permission benefits user.
- "Continue" → triggers system prompt.
- "Not now" → defer (no system prompt yet).
- Lifts grant rate from ~20% to ~40%+.

Without ATT permission:
- IDFA = `00000000-0000-0000-0000-000000000000`.
- IDFV (vendor) still works (per-vendor identifier).
- Attribution SDKs (AppsFlyer, Adjust, Branch) fall back to SKAdNetwork.

SKAdNetwork (SKAN 4):
- Conversion postbacks aggregated by Apple.
- Coarse + fine conversion values.
- Multi-conversion windows.
- Privacy threshold: aggregated only when N+ users.
- No user-level data.

Server-side:
- Use SKAdNetwork postbacks for attribution.
- Don't use email hashes / IP for cross-context tracking (still tracking under ATT).

Cross-platform UX:
- Android equivalent: Privacy Sandbox + Topics API + Protected Audience.
- Different model; same goal.

The 2026 specific:
- ATT enforcement strict (5+ years in).
- SKAN 5 details.
- Apple Ads Attribution API (first-party).
- AdAttributionKit replacing parts of SKAN.
- Server-side conversion API for first-party attribution.

Common mistakes:
- Initializing SDK with tracking before ATT decision (data sent before consent).
- Pre-prompt that pre-empts system (Apple guideline 5.1.2; rejection risk).
- Not honoring opt-out server-side.

Senior approach:
- Treat IDFA as nice-to-have; design measurement around SKAN.
- Server-to-server measurement via first-party events.
- Continuous A/B test on prompt placement.

---

## The "Why"

Get-tracking right = revenue + compliance. Wrong = rejection or regulator fines. Companies care because mobile ad revenue depends on attribution + privacy posture.

---

## Mental Model

ATT = "ask before tracking across companies". Tracking = cross-context data linking. Without permission → privacy-preserving mode.

---

## Internal Working (2026 Context)

- IDFA accessible only after `granted`.
- ATT decision persisted (can re-trigger only via Settings).
- SKAdNetwork postbacks via Apple.

---

## Modern Implementation (Code)

**Conditional event sending**:
```ts
function trackEvent(name: string, props: object) {
  if (attStatus === 'granted') {
    sendToAdNetwork(name, { ...props, idfa });
  }
  sendToOwnAnalytics(name, props); // first-party always
}
```

**Server-side opt-out**:
```ts
app.post('/event', (req, res) => {
  const { userId, attOptIn } = req.body;
  if (!attOptIn) {
    forwardOnlyAggregate(req.body);
  } else {
    forwardWithIdentifiers(req.body);
  }
});
```

---

## Comparison

| Method | Identifier | Privacy |
|---|---|---|
| IDFA + ATT | per-user | requires consent |
| IDFV | per-vendor | first-party |
| SKAdNetwork | aggregate | Apple-mediated |

---

## Production Usage

- Universal in ad-monetized apps.
- Subscription apps may skip.

---

## Hands-On Exercise

1. Add ATT prompt at moment of value.
2. Pre-prompt custom screen.
3. Wire SKAdNetwork conversion values.
4. Honor opt-out throughout.

---

## Common Mistakes

- Init tracking SDK before ATT.
- Prompt on first launch.
- Pre-prompt mimicking system UI (rejection).

---

## Production Red Flags

- IDFA accessed without ATT.
- Tracking domain not declared.
- SKAN ignored.

---

## Performance & Metrics (MANDATORY)

- Grant rate target: > 30% with pre-prompt.
- SKAN conversion windows: align with funnel.

---

## Decision Framework

| Need | Use |
|---|---|
| Cross-app attribution | ATT + IDFA |
| Privacy-preserving | SKAdNetwork |
| First-party | IDFV |

---

## Senior-Level Insight

Senior teams build SKAN-first measurement and treat IDFA as upside. Reduces dependency on consent rate.

---

## Memory Hook
**"Pre-prompt → system prompt → SKAN if denied."**

## Revision Notes
> ATT prompts before cross-context tracking. Pre-prompt lifts grant rate. Without permission: IDFA zeros; use SKAdNetwork. Don't init tracking SDKs before consent. Declare tracking + domains in Privacy Manifest.

---

---

### Q3. Android Privacy Sandbox — what changed and what to do

---

## Difficulty
- Advanced

## Interview Frequency
- Emerging (2026)

## Prerequisites
- Android advertising ID basics

## TL;DR
**Android Privacy Sandbox** removes cross-app identifiers (AdID deprecation in progress) and replaces with **Topics API** (interest categories), **Protected Audience** (on-device ad auctions), **Attribution Reporting API** (privacy-preserving conversion). For app developers: stop relying on AdID; integrate Topics + Attribution APIs; expect IDFA-equivalent loss on Android too. Privacy Sandbox SDK runtime isolates ad SDKs.

---

## 30-Second Interview Answer

> "Privacy Sandbox is Android's answer to ATT. AdID being deprecated; replaced by Topics API (broad interest categories computed on-device), Protected Audience (on-device ad auctions), Attribution Reporting (privacy-preserving conversion measurement). Ad SDKs run in isolated SDK Runtime process. For RN apps: stop relying on AdID; integrate Topics + Attribution; expect on-device measurement, not user-level. Rollout in stages through 2026."

---

## 2-Minute Practical Answer

**Components**:

| API | Purpose |
|---|---|
| Topics | broad interest categories (~few hundred) computed on-device |
| Protected Audience | on-device retargeting / custom audiences |
| Attribution Reporting | privacy-preserving conversion measurement |
| SDK Runtime | isolated process for ad SDKs |
| Privacy Preserving APIs | aggregation services |

**Topics API**:
- On-device classifier maps app usage → broad topics.
- Topics shared with limited callers.
- User can see + opt out per topic.
- App calls API; doesn't choose topics.

**Attribution Reporting**:
- Source events (ad views/clicks) registered.
- Trigger events (conversions) registered.
- Reports aggregated, delayed, noised.
- No cross-app user IDs.

**For app developers**:
- Stop treating AdID as identifier.
- Use SDK Runtime for ad / measurement SDKs.
- Integrate with major networks (Google Ads, Meta) using new APIs.
- Test in Privacy Sandbox developer preview.

**Coordination with Play Store**:
- Data Safety section updated for sandbox usage.
- Disclose new APIs.

**Timeline**:
- Originally 2024 → revised; gradual rollout 2024–2026.
- Some markets rolling first; expect global by 2026–2027.

---

## 5-Minute Architecture Answer

Goals:
- Reduce cross-app tracking.
- Preserve ad ecosystem viability.
- Provide privacy-preserving measurement.

vs Apple ATT:
- ATT = consent gate; user opts in to existing identifier.
- Sandbox = replace identifier with new privacy-preserving APIs.
- Different philosophy: Apple deters tracking; Google replaces it.

SDK Runtime:
- Ad SDKs (and others) run in separate process.
- Limited access to host app data.
- Sandboxed network egress.
- Reduces app-level liability for SDK behavior.

Topics API in detail:
- Topics taxonomy ~few hundred categories.
- Computed weekly from app usage.
- App declares "I want a topic for this user".
- Returns up to 3 topics from past 3 weeks.
- User-visible in Settings; opt-out per topic.

Protected Audience:
- Custom audience joined on-device.
- Ad auction runs on-device.
- Winning ad rendered.
- Outcome reported via Attribution Reporting.

Attribution Reporting:
- Source: registered when ad shown/clicked (with metadata).
- Trigger: registered when conversion happens.
- Joins on-device; reports sent with delay + noise.
- Aggregate API for cross-publisher.

What changes for RN app:
- If you embed ads → use SDK Runtime version of network SDK.
- If you measure ads → use Attribution Reporting.
- AdID still works but increasingly less reliable; plan migration.

The 2026 specific:
- Topics API stable in production.
- Attribution Reporting general availability.
- Major ad networks (Google, Meta, AppLovin) integrated.
- Some EU regulatory friction; rollout regional.

For testing:
- `adb shell` enable sandbox.
- Developer preview emulator images.
- Test with feature flag fallback to AdID.

Privacy + Compliance:
- Disclose sandbox API usage in Play Data Safety.
- Update privacy policy.
- DPDP / GDPR still apply for first-party data.

---

## The "Why"

Privacy Sandbox is Google reshaping mobile ads. Apps that adapt early gain measurement quality + compliance posture.

---

## Mental Model

Topics + Protected Audience + Attribution Reporting = ad ecosystem without cross-app identifiers. SDK Runtime isolates SDKs.

---

## Internal Working (2026 Context)

- On-device classifier for Topics.
- On-device auction for Protected Audience.
- Server-side aggregation with noise for reports.

---

## Modern Implementation (Code)

**Topics API (Kotlin)**:
```kotlin
val topicsManager = context.getSystemService(TopicsManager::class.java)
val request = GetTopicsRequest.Builder()
    .setAdsSdkName("my-sdk")
    .setShouldRecordObservation(true)
    .build()
topicsManager.getTopics(request, executor, callback)
```

**Bridged to RN via TurboModule** (skeleton).

---

## Comparison

| Platform | Approach |
|---|---|
| iOS ATT | consent gate |
| Android Sandbox | API replacement |
| Web Privacy Sandbox | similar set of APIs |

---

## Production Usage

- Major ad networks integrated.
- App developers in transition.

---

## Hands-On Exercise

1. Test Topics API in dev preview.
2. Migrate ad SDK to Sandbox version.
3. Add Attribution Reporting.
4. Update Data Safety.

---

## Common Mistakes

- Continuing AdID-only measurement.
- Not isolating ad SDK in Sandbox runtime.
- Missing disclosure.

---

## Production Red Flags

- "We'll wait until forced."
- No measurement strategy beyond AdID.

---

## Performance & Metrics (MANDATORY)

- Topics API call: < 50ms.
- Attribution reports: delayed (hours/days).

---

## Decision Framework

| Use case | API |
|---|---|
| Interest targeting | Topics |
| Retargeting | Protected Audience |
| Conversion measurement | Attribution Reporting |

---

## Senior-Level Insight

Senior orgs treat Sandbox as cross-discipline migration: ads, measurement, legal, product. Plan multi-quarter transition.

---

## Memory Hook
**"Topics + Protected Audience + Attribution Reporting + SDK Runtime."**

## Revision Notes
> Privacy Sandbox replaces AdID with on-device APIs. Topics for interests, Protected Audience for auctions, Attribution Reporting for conversions. SDK Runtime isolates ad SDKs. Migrate, don't wait.

---

---

### Q4. GDPR / CPRA / DPDP — engineering implications for mobile

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- Privacy basics

## TL;DR
GDPR (EU), CPRA (California), DPDP (India 2023): require **lawful basis (consent/legitimate interest/contract)**, **data minimization**, **subject rights (access/delete/portability/correct)**, **breach notification**, **DPO or grievance officer**. Engineering work: consent gates, deletion APIs, data export, audit logs, encryption, regional residency, vendor DPAs, child-data protections. Not lawyer talk — concrete code obligations.

---

## 30-Second Interview Answer

> "GDPR/CPRA/DPDP define obligations: lawful basis for processing, data minimization, subject rights (access, delete, correct, portability), breach notification, and accountability. Engineering side: consent gating before SDK init, in-app account deletion, data export endpoint, audit logs of access, regional residency where required (DPDP-India), child consent flows (COPPA/GDPR-K), vendor DPAs. Implement once, expose per-region UI. Test deletion path end-to-end."

---

## 2-Minute Practical Answer

**Lawful basis** (GDPR Article 6):
- Consent.
- Contract necessity.
- Legal obligation.
- Vital interests.
- Public task.
- Legitimate interests.

For most apps: contract (account creation) + consent (analytics, marketing).

**Subject rights**:

| Right | Engineering work |
|---|---|
| Access | export endpoint returning all PII |
| Delete (right to be forgotten) | cascading delete + tombstone |
| Rectify | edit profile, with audit |
| Portability | export in machine-readable format (JSON) |
| Restrict | flag account, halt processing |
| Object | opt-out per purpose |

**Deletion architecture**:
- App: "Delete account" button.
- API: enqueue deletion job.
- Job: cascade across services (auth, profile, payments, analytics, vendor SDKs).
- Tombstone: keep minimal record (deletion timestamp, hashed user ID) for legal/audit.
- Vendor coordination: webhook to Sentry / Statsig / etc.
- SLA: typically 30 days (GDPR), 45 days (CPRA).

**Data export**:
```ts
GET /me/export
→ JSON with profile, posts, messages, settings, etc.
```

**Audit logs**:
- Who accessed user data, when.
- Required for breach investigation + accountability.
- Retain 1+ year.

**Regional residency**:
- DPDP (India): government can mandate residency.
- Russia: mandatory in-country storage.
- EU: data can leave with adequate safeguards (SCCs).
- Architecture: per-region DBs / data routing.

**Breach notification**:
- GDPR: 72 hours to regulator.
- CPRA: "without unreasonable delay".
- Have incident-response runbook.

**Children**:
- COPPA (US <13).
- GDPR-K (EU 13–16, varies).
- DPDP (India <18!).
- Verifiable parental consent before processing.
- DPDP's <18 age is unusually high → impactful for India market.

**Consent gating**:
- Don't init analytics SDK until consent.
- Per-purpose granularity (analytics, marketing, personalization).
- Re-prompt on policy change.

---

## 5-Minute Architecture Answer

GDPR (EU):
- Most stringent global baseline.
- Affects any app serving EU users.
- Penalties: up to 4% global revenue.

CPRA (California, replaced CCPA):
- "Do Not Sell or Share My Personal Information".
- Sensitive Personal Information category.
- Right to limit sensitive use.

DPDP (India, 2023):
- Recent law, rules being finalized 2024–2026.
- Stricter on cross-border: government may notify whitelist.
- Significant Data Fiduciary obligations for large processors.
- Children: <18 needs verifiable parental consent.
- Penalties high.

Other notable:
- LGPD (Brazil) — similar to GDPR.
- PIPL (China) — strict + government access.
- POPIA (South Africa).

Engineering patterns:
- **Consent record**: store (user, purpose, version, timestamp).
- **Re-consent**: when policy changes.
- **Per-region UI**: GDPR banner for EU; CPRA opt-out for CA.
- **Vendor DPA**: data processing agreement for every SDK.
- **Data map**: catalog what data flows where.
- **Encryption at rest + in transit**: required (or strongly expected).

Right to deletion at scale:
- Cascade is hard: many services hold copy.
- Pattern: event bus broadcasts user.deleted; consumers process.
- Idempotent + eventually consistent.
- Track completion; report to regulator if requested.

Vendor compliance:
- DPA signed.
- DPIA (data protection impact assessment) for high-risk.
- Sub-processor list public.
- Webhook for deletion propagation.

Children's data:
- Age-gating at signup.
- COPPA-safe analytics SDKs (no IDFA, no ads).
- Parental consent verification (credit card, ID, knowledge-based).
- DPDP especially strict (<18 default).

Breach response runbook:
- Detect → contain → assess scope → notify (regulator + users) → remediate → postmortem.
- Practice tabletop quarterly.

The 2026 specific:
- **DPDP rules finalized** in India.
- **Privacy Manifest sync** with regulatory disclosures.
- **Universal opt-out signals** (Global Privacy Control).
- **AI Act (EU)** for AI-using apps.
- **State-level US privacy laws** proliferating (TX, FL, CO, etc.).

App-side implementation cheat sheet:
- Consent banner (region-aware).
- "Privacy Choices" screen with per-purpose toggles.
- "Delete my account" button → confirms → enqueues.
- "Download my data" → email or in-app download.
- "Privacy Policy" link in onboarding + settings.
- Age gate at signup.

---

## The "Why"

Privacy laws are global and growing. Engineering is on the hook to make them real. Companies care because non-compliance = fines + reputation damage.

---

## Mental Model

Lawful basis to collect → minimize → enable subject rights → audit → delete. Region-aware UI, single backend implementation.

---

## Internal Working (2026 Context)

- Consent record table.
- Deletion event bus.
- Data export job queue.
- Audit log append-only.

---

## Modern Implementation (Code)

**Consent state machine**:
```ts
type Purpose = 'analytics' | 'marketing' | 'personalization';
type ConsentRecord = { purpose: Purpose; granted: boolean; version: string; ts: number };

const consent = createStore<ConsentRecord[]>([]);

function record(purpose: Purpose, granted: boolean) {
  const rec = { purpose, granted, version: POLICY_VERSION, ts: Date.now() };
  consent.set([...consent.get(), rec]);
  api.post('/consent', rec);
}

function gateInit() {
  if (consent.get().some(c => c.purpose === 'analytics' && c.granted)) {
    initAnalytics();
  }
}
```

**Deletion endpoint**:
```ts
app.delete('/me', authenticate, async (req, res) => {
  const userId = req.user.id;
  await db.transaction(async (tx) => {
    await tx.profile.delete({ where: { userId } });
    await tx.post.deleteMany({ where: { userId } });
    await tx.event.publish({ type: 'user.deleted', userId });
  });
  await tombstone.add({ userId, deletedAt: new Date() });
  res.json({ ok: true });
});
```

---

## Comparison

| Law | Region | Notable |
|---|---|---|
| GDPR | EU | global baseline |
| CPRA | California | "do not sell" |
| DPDP | India | <18 = child |
| LGPD | Brazil | GDPR-like |
| PIPL | China | state access |

---

## Production Usage

- All consumer apps.
- B2B has DPA chains.

---

## Hands-On Exercise

1. Add consent banner.
2. Implement deletion + export.
3. Map data flows.
4. Run breach tabletop.

---

## Common Mistakes

- Consent UI without backend record.
- Deletion not cascading to vendors.
- No audit logs.
- Children's data not isolated.

---

## Production Red Flags

- "We'll handle requests manually."
- No data map.
- Vendor DPA missing.

---

## Performance & Metrics (MANDATORY)

- Deletion SLA: < 30 days.
- Export response: < 7 days typical.

---

## Decision Framework

| Region | Priority |
|---|---|
| EU | GDPR + DSA |
| California | CPRA |
| India | DPDP (esp. children) |
| Global | implement union |

---

## Senior-Level Insight

Senior engineering treats privacy as core architecture, not a UX bolt-on. Consent + deletion + audit are tier-1 systems.

---

## Memory Hook
**"Lawful basis. Minimize. Subject rights. Audit. Delete."**

## Revision Notes
> GDPR/CPRA/DPDP require lawful basis, data minimization, subject rights (access/delete/correct/portability), breach notification. Engineering: consent gates, deletion API (cascade + tombstone), export, audit, regional UI. DPDP: <18 = child. Practice breach runbook.

---

---

### Q5. Consent before SDK init — pattern for analytics, push, attribution

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- Q1, Q2, Q4

## TL;DR
**Init no SDK that collects PII before consent**. Bootstrap order: minimal core → consent UI → record consent → init SDKs gated per purpose. Use a Consent Management Platform (CMP) or custom for region-aware UI. Re-consent when policy / SDKs change. SDKs that violate this rule are tech debt. Engineering pattern: lazy SDK wrapper waiting for `ready(purpose)` event.

---

## 30-Second Interview Answer

> "Bootstrap minimal first — no analytics, no push register, no attribution. Show region-aware consent UI (GDPR banner in EU, CPRA opt-out in CA). On grant: emit `ready(purpose)` event; SDKs subscribe and init themselves. On revoke: SDKs flush + uninit (or no-op going forward). Persist consent record per purpose + policy version; re-prompt when version bumps. CMPs (OneTrust, Didomi, Sourcepoint) provide pre-built UI + audit. Without this discipline you've already broken privacy laws in EU."

---

## 2-Minute Practical Answer

**Bootstrap order**:
1. App start → init router, error boundary, MMKV (no PII).
2. Read consent record from MMKV.
3. If undecided + region requires consent → show consent UI.
4. On grant per purpose → init relevant SDKs.
5. On revoke → tear down + flush.

**Region detection**:
- Locale + IP geo.
- EU → GDPR-style banner with granular choices.
- California → "Do Not Sell or Share" link.
- India → notice + grievance officer info.
- Default → reasonable global baseline.

**SDK wrapper pattern**:
```ts
class LazyAnalytics {
  private inited = false;
  async ready() {
    if (this.inited) return;
    if (!consentService.granted('analytics')) return;
    await Sentry.init({ dsn: '...' });
    this.inited = true;
  }
  track(name: string, props: object) {
    if (!this.inited) return;
    Sentry.addBreadcrumb({ category: name, data: props });
  }
}
```

**Consent change subscription**:
```ts
consentService.subscribe((record) => {
  if (record.purpose === 'analytics' && record.granted) {
    lazyAnalytics.ready();
  }
  if (record.purpose === 'analytics' && !record.granted) {
    lazyAnalytics.shutdown();
  }
});
```

**CMP integration**:
- OneTrust / Didomi / Sourcepoint provide IAB TCF v2.2 compliant CMP.
- SDK exposes `tcString` to downstream SDKs.
- Standardized purpose IDs (1–11 + special features).

**IAB Transparency & Consent Framework** (TCF):
- EU standard for ad/analytics consent.
- TC string encodes consent per vendor + purpose.
- Most ad/analytics SDKs read it natively.

**Push notifications consent**:
- Don't ask on first launch.
- Defer to moment of value.
- iOS: `requestPermissionsAsync`.
- Android 13+: `POST_NOTIFICATIONS` runtime perm.

**Attribution SDKs (AppsFlyer/Adjust/Branch)**:
- Init in privacy-preserving mode by default.
- Enable IDFA / device-graph features only after consent.
- SKAdNetwork / Privacy Sandbox always allowed.

---

## 5-Minute Architecture Answer

Why "consent first":
- GDPR requires consent before non-essential cookies / SDKs.
- Recital 32: clear affirmative action; pre-checked boxes invalid.
- ePrivacy Directive (EU) governs SDK loading.
- Loading SDK = processing personal data → needs lawful basis.

CMP role:
- Centralized consent UI.
- Records consent + version.
- Provides TC string to vendors.
- Audit log.
- Multi-region templates.

Build vs buy:
- Buy CMP if multi-region + ad-monetized.
- Build for simple cases.
- Buy includes legal updates as laws evolve.

Consent storage:
- Local (MMKV) for fast read at startup.
- Backend mirror for cross-device + audit.
- Versioned with policy version.

Re-consent triggers:
- Policy version bump.
- New SDK added.
- Region change (user moved).
- Time-based (some jurisdictions require periodic).

Coordination with Privacy Manifest:
- Manifest declares SDKs + data types.
- Consent UI explains those purposes.
- Should match.

Push notification consent:
- Separate from data consent.
- iOS: Apple's permission system.
- Android 13+: runtime permission.
- Pattern: ask after user does something showing intent (e.g., follows topic).

Attribution / SDK considerations:
- AppsFlyer / Adjust / Branch all support consent-aware modes.
- Set tracking on/off based on ATT + GDPR consent.

The 2026 specific:
- **TCF v2.2** stable.
- **Global Privacy Control (GPC)** signal honored.
- **Consent receipts** (proof of consent) for audit.
- **AI Act (EU)** adds disclosure for AI features.

Common architecture mistakes:
- Single global consent flag (no purpose granularity).
- SDK init in `index.ts` before consent.
- Push prompt in `App.tsx` mount.
- Not respecting "denied" — SDK still sends data.

Senior approach:
- Boundary discipline: SDK calls behind a wrapper that checks consent.
- Tests: consent matrix tests verify SDK init only when expected.
- Monitoring: alert if PII-collecting SDK initialized with no consent record.

---

## The "Why"

Pre-consent SDK init = automatic GDPR violation. Companies care because regulators audit + competitors weaponize.

---

## Mental Model

Bootstrap → consent → gated SDK init. Each SDK behind a `ready(purpose)` gate.

---

## Internal Working (2026 Context)

- Consent record persisted MMKV + backend.
- Pub/sub fires init / shutdown per SDK.
- TC string passed to downstream SDKs.

---

## Modern Implementation (Code)

**Consent service**:
```ts
type Purpose = 'analytics' | 'advertising' | 'personalization' | 'functional';
type Record = { purpose: Purpose; granted: boolean; version: string; ts: number };

class ConsentService {
  private records = new Map<Purpose, Record>();
  private listeners = new Set<(r: Record) => void>();

  init() {
    const stored = mmkv.getString('consent');
    if (stored) JSON.parse(stored).forEach((r: Record) => this.records.set(r.purpose, r));
  }

  granted(p: Purpose): boolean {
    const r = this.records.get(p);
    return r?.granted === true && r.version === POLICY_VERSION;
  }

  set(p: Purpose, granted: boolean) {
    const r = { purpose: p, granted, version: POLICY_VERSION, ts: Date.now() };
    this.records.set(p, r);
    mmkv.set('consent', JSON.stringify([...this.records.values()]));
    api.post('/consent', r);
    this.listeners.forEach((cb) => cb(r));
  }

  subscribe(cb: (r: Record) => void) {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }
}

export const consentService = new ConsentService();
```

**Region-aware UI**:
```tsx
function ConsentGate({ children }) {
  const [decided, setDecided] = useState(consentService.hasDecided());
  const region = useRegion();
  if (!decided && requiresConsent(region)) {
    return <ConsentBanner onDone={() => setDecided(true)} />;
  }
  return children;
}
```

---

## Comparison

| Approach | Pros | Cons |
|---|---|---|
| CMP (OneTrust etc.) | legal updates, audit | cost |
| Custom | control, fit | maintenance |
| Single toggle | simple | not GDPR-valid |

---

## Production Usage

- All EU-serving consumer apps.
- B2B often skip (legitimate interest basis).

---

## Hands-On Exercise

1. Bootstrap minimal app.
2. Build consent service.
3. Wrap analytics + push behind gates.
4. Re-consent on version bump.

---

## Common Mistakes

- SDK init in module top-level.
- Consent UI without backend record.
- Single purpose consent.
- Not honoring revoke.

---

## Production Red Flags

- Sentry calls before consent.
- Push prompt on launch.
- No region detection.

---

## Performance & Metrics (MANDATORY)

- Consent UI cold-start cost: < 100ms.
- SDK init deferred to post-consent.

---

## Decision Framework

| Region | UI |
|---|---|
| EU | granular banner |
| California | DNSS link + opt-out |
| India | notice + grievance |
| Global | reasonable union |

---

## Senior-Level Insight

Senior teams build consent into the bootstrap, not retrofit. They run tests asserting no SDK initialized without record.

---

## Memory Hook
**"Bootstrap → consent → gated init. Per-purpose. Per-region. Versioned."**

## Revision Notes
> Don't init PII-collecting SDKs before consent. Bootstrap minimal → consent UI → init gated per purpose. Region-aware UI. CMP (OneTrust/Didomi/Sourcepoint) for ad-monetized. TCF v2.2 standard. Re-consent on policy bump. Honor revoke.

---

> **End of S30.** Cross-refs: [S10 Auth & Security](S10-auth-security.md), [S12 Push & Background](S12-push-background.md), [S18 Observability](S18-observability.md), [S20 CI/CD](S20-cicd-release.md). Next per priority: [S13 Android & Kotlin](S13-android-kotlin.md).
