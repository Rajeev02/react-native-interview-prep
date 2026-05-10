# S20 — CI/CD & Release Engineering

> EAS Build/Submit · GitHub Actions · Fastlane · code signing · staged rollouts · kill switches · feature flags · store review

Release engineering is where senior leverage compounds. In 2026 the stack is **EAS Build/Submit** (or self-hosted EAS) wired into **GitHub Actions / Bitrise / CircleCI**, with **EAS Update** for OTA, **staged rollouts** in stores, **kill switches via feature flags** (LaunchDarkly / Statsig / Unleash / ConfigCat), and disciplined **code-signing hygiene**. Cross-ref [S5 Expo & Tooling](S05-expo-tooling.md) for `eas.json` deep-dive; this section covers CI integration and the operational rounds.

---

### Q1. EAS Build + GitHub Actions integration — how it actually works

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Common

## Prerequisites
- S5 EAS basics, GitHub Actions YAML

## TL;DR
GitHub Actions triggers on push/PR/tag → calls `eas build --non-interactive --auto-submit` (or skip submit) with a robot token. Pre-build steps (lint/test/typecheck) run in Actions; build itself runs on EAS workers. Concurrency limit avoids parallel waste. Status posted back to PR. EAS Workflows (native) can replace Actions entirely for Expo-only repos.

---

## 30-Second Interview Answer

> "GitHub Actions runs the lightweight stuff — lint, typecheck, unit tests, Reassure perf — on its own runners. When those pass, it shells out to `eas build --non-interactive` with a robot token. EAS runs the actual build on Expo's macOS/Linux workers. Status returned to GitHub via API, posted on PR. For OTA: separate workflow `eas update --branch <env>` after merge to main. EAS Workflows (native) can replace Actions for Expo-only repos. Robot tokens scoped per workflow; concurrency capped to avoid redundant builds."

---

## 2-Minute Practical Answer

**GitHub Actions YAML**:
```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
    tags: ['v*']

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm test --ci --coverage
      - run: pnpm reassure --baseline
      - uses: callstack/reassure-danger-action@v1

  build-preview:
    if: github.event_name == 'pull_request'
    needs: [validate]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}
      - run: eas build --platform all --profile preview --non-interactive --no-wait

  build-production:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: [validate]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: expo/expo-github-action@v8
        with:
          token: ${{ secrets.EXPO_TOKEN }}
      - run: eas build --platform all --profile production --non-interactive --auto-submit
```

**Key flags**:
- `--non-interactive`: required in CI.
- `--no-wait`: returns immediately (don't tie up runner minutes); status arrives via webhook.
- `--auto-submit`: chains submit after build (production only).
- `--profile`: matches `eas.json`.

**OTA workflow**:
```yaml
name: OTA
on:
  push:
    branches: [main]
    paths-ignore: ['ios/**', 'android/**']  # skip if native changed

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: expo/expo-github-action@v8
        with: { token: ${{ secrets.EXPO_TOKEN }} }
      - run: eas update --branch production --message "${{ github.event.head_commit.message }}"
```

**Robot tokens**:
- Create in Expo dashboard with **least-privilege scope** (build only, update only, submit only — separate tokens per workflow).
- Rotate quarterly.
- Store in GitHub encrypted secrets.

---

## 5-Minute Architecture Answer

CI vs build separation:
- **CI runners** (Ubuntu) — fast, cheap, parallel: lint, typecheck, test, perf gate.
- **EAS workers** (macOS for iOS, Linux for Android) — slower, paid: actual native build.
- Don't mix: building iOS on a self-hosted Mac runner is possible but loses the EAS plugin/cert ecosystem.

Pipeline stages:
1. **Validate**: typecheck + lint + unit tests + Reassure (~3 min).
2. **Component tests**: RNTL with MSW (~3 min).
3. **Build**: EAS preview on PR, production on tag.
4. **E2E**: Maestro on built artifact (post-build).
5. **Submit**: production only, auto.
6. **OTA**: separate workflow on main merge.

Branching strategies:
- **Trunk-based**: main always shippable; feature flags gate work. PR builds preview; tag triggers prod.
- **Release branches**: cut `release/x.y` from main; cherry-pick fixes; tag from release branch.
- **Channel mapping**: `main` → `preview` channel; `release/*` → `production` channel.

Concurrency control:
- `concurrency.group` per branch → cancel stale PR builds.
- Don't cancel on main / tag (you want the artifact).
- EAS-side: limit parallel builds via plan (avoid bill shock).

Failure handling:
- Validate fail → block merge.
- Build fail → comment on PR, notify Slack.
- Submit fail (Apple/Google) → manual triage; usually metadata.

Self-hosted runners:
- For privacy / IP / cost: run EAS jobs on your own Mac mini farm via `eas-cli --runner self-hosted`.
- Same EAS API, your hardware.

The 2026 specific:
- **EAS Workflows** (YAML in repo, runs on EAS) replacing GitHub Actions for Expo-only.
- **Bun-based runners** faster install on EAS.
- **Reassure danger action** standard.
- **Sigstore-signed artifacts** for supply chain.
- **GitHub Actions OIDC → EAS** (no long-lived tokens).

OIDC pattern:
```yaml
permissions:
  id-token: write
- uses: expo/expo-github-action@v8
  with:
    use-oidc: true   # exchanges GitHub OIDC for short-lived EAS token
```

---

## The "Why"

Slow / flaky CI = slow / flaky releases = slow / flaky engineering. Senior interview lens: do you know enough to make CI fast and reliable?

---

## Mental Model

Two clouds: GitHub Actions (cheap CI) → EAS (paid builds). Triggers via robot token. OTA is a separate workflow.

---

## Internal Working (2026 Context)

- EAS-CLI auths via robot token / OIDC.
- `--no-wait` returns build ID; webhook updates GitHub.
- `eas-build-pre-install` / post-install hooks run on EAS.

---

## Modern Implementation (Code)

**Slack notification on build**:
```yaml
- if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      { "text": "Build failed on ${{ github.ref }}" }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

**Sourcemap upload to Sentry**:
```yaml
- run: npx sentry-expo-upload-sourcemaps --release ${{ github.sha }}
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH }}
```

---

## Comparison

| CI | Strength |
|---|---|
| GitHub Actions | most common, free tier |
| EAS Workflows | native Expo |
| Bitrise | mobile-specialist |
| CircleCI | flexible |
| Self-hosted Mac | full control |

---

## Production Usage

- GitHub Actions + EAS most common.
- Larger orgs add Bitrise / self-hosted for scale.

---

## Hands-On Exercise

1. Wire validate + build-preview + OTA workflows.
2. Add concurrency cancelation.
3. Add robot token with minimal scope.
4. Migrate to OIDC.

---

## Common Mistakes

- Long-lived token with admin scope.
- No concurrency cancel.
- Building all platforms on every PR.
- Mixing OTA and native builds in one workflow.

---

## Production Red Flags

- Token in plaintext.
- 30+ min CI for simple PR.
- No status check required for merge.

---

## Performance & Metrics (MANDATORY)

- Validate stage: < 5 min.
- Build PR preview: < 20 min.
- Submit lag: < 1 hr after tag.

---

## Decision Framework

| Trigger | Action |
|---|---|
| PR | validate + preview build |
| main merge | OTA |
| tag v* | production build + submit |
| hotfix branch | OTA channel preview |

---

## Senior-Level Insight

CI is product code. Senior teams version + review YAML, write tests for workflow logic (act/local runners), and treat flaky CI as a P1 bug.

---

## Memory Hook
**"Actions does cheap; EAS does heavy."**

## Revision Notes
> GitHub Actions runs lint/test/typecheck/Reassure; calls EAS Build for native. `--non-interactive --no-wait`. OIDC over robot tokens. OTA in separate workflow. Concurrency cancel on PR. Sourcemap upload post-build.

---

---

### Q2. OTA strategy — coordinating EAS Update with native releases

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- S5 Q4 (EAS Update mechanics)

## TL;DR
OTA = JS+assets only; native changes need store release. Coordinate via **runtime versions** (bump on native change) + **branches per release line** + **channels per environment**. Hot-fix flow: branch → publish → canary → 100%. Rollback = repoint channel. Always test runtime version compatibility before publish. Senior orgs gate OTA via Sentry health metrics.

---

## 30-Second Interview Answer

> "OTA delivers JS + assets within the same runtime version. Coordinate with native: bump runtime version on every native release; OTA can only update within matching runtime. Publish flow: feature merged → CI publishes to `release-x.y.z` branch → channel pointed there → canary 5% → monitor crash-free + perf → ramp to 100%. Rollback = repoint channel. Native release = new build + new runtime version + new branch. Sentry health metrics gate ramp."

---

## 2-Minute Practical Answer

**Runtime version policy** (`app.config.ts`):
```ts
export default {
  runtimeVersion: { policy: 'fingerprint' },  // hash of native deps
  // or 'appVersion', or 'sdkVersion', or fixed string
};
```

`fingerprint` is the 2026 default — auto-bumps when any native dep changes.

**Branches per release line**:
- `release-1.4.x` for v1.4.* native builds.
- New native release v1.5.0 → new branch `release-1.5.x`.

**Channels per environment**:
- `production`, `staging`, `preview`, `dev`.
- Channel → branch mapping changes for rollouts/rollbacks.

**Hot-fix flow**:
1. Fix merged to `release/1.4.x` branch.
2. CI publishes update to `release-1.4.x` EAS branch.
3. Initial rollout: 5% via `eas channel:edit production --rollout-percentage 5`.
4. Monitor 30 min: crash-free, screen TTI, error rate.
5. If healthy, ramp to 25% → 50% → 100%.
6. If unhealthy, `eas channel:edit production --branch release-1.4.x-prev` (instant rollback).

**Native release coordination**:
- Bump appVersion + native deps → fingerprint changes → new runtime version.
- New build subscribes to fresh branch (e.g., `release-1.5.x`).
- Old runtime version (1.4.x) keeps receiving updates from its branch (long tail of users on old build).

**Critical rules**:
- OTA never includes native deltas.
- OTA never changes entitlements / Info.plist / AndroidManifest.
- OTA never breaks JS↔native contract (e.g., calling a native method that doesn't exist in old build).
- Always test on a build with the target runtime version BEFORE publish.

---

## 5-Minute Architecture Answer

OTA coordination challenges:
- **Long tail**: users skip updates → multiple runtime versions live concurrently.
- **Backward compat**: JS code must guard for missing native modules.
- **Atomicity**: OTA + backend deploys must align (don't push JS expecting new API).
- **Privacy**: OTA updates must respect store policies (no surprise behavior).

Multi-runtime-version reality:
- Production might have 5+ runtime versions live (old users, slow updaters).
- Each gets updates from its branch.
- Branch maintenance: backport critical fixes; sunset after 6+ months.

API versioning to support:
- `/v1`, `/v2` API endpoints.
- Old client → old API.
- New client → new API.
- Backend supports both for transition.

OTA + backend release order:
1. Backend deploys backward-compatible change (additive).
2. Native release of client expecting new shape (with feature flag off).
3. Backend completes incompatible change (after old clients gone).
4. Or: feature-flag the new path, OTA enables when backend ready.

Health gating:
- Sentry crash-free session SLO.
- API error rate < threshold.
- Screen TTI within budget.
- If any breaches → auto-pause rollout (Statsig / LaunchDarkly + EAS API integration).

Canary cohorts:
- Internal employees first (via EAS branch dev/staging).
- Beta channel (TestFlight beta + Play Console internal testing).
- Then 5% production → ramp.

Rollback gotchas:
- Rollback applies on next launch (users mid-session keep current).
- For severe issues: flip kill switch (feature flag) immediately while OTA rollback rolls.
- Some bugs persist even after rollback (corrupted local state) — need cleanup logic.

The 2026 specific:
- **`fingerprint` runtime version policy** default — auto-detects native changes.
- **EAS Update channels with rollout %** built-in.
- **Sentry health-gated OTA** via webhook.
- **Update size budget** enforced (<50MB warning).
- **Critical update**: app forces apply if marked critical.

OTA ↔ Feature Flag synergy:
- OTA = code delivery.
- Feature flag = behavior gating.
- Pattern: ship dark via OTA, enable per-cohort via flag.
- Decouple "in the build" from "active for users".

---

## The "Why"

OTA done badly = mass crashes, support storm, store strikes. OTA done well = MTTR in minutes, faster than backend deploy. Companies care because OTA is a competitive advantage.

---

## Mental Model

Channel = subscribed track. Branch = release line. Runtime version = native compatibility key. Update = JS+assets payload.

---

## Internal Working (2026 Context)

- App on launch: query EAS Update API with channel + runtime version.
- Server: latest update for that branch + RV.
- App: download in background, apply on next launch (or immediately if critical).

---

## Modern Implementation (Code)

**Critical update enforcement**:
```ts
import * as Updates from 'expo-updates';

async function gateOnCritical() {
  const update = await Updates.checkForUpdateAsync();
  if (update.isAvailable && update.manifest?.extra?.critical) {
    await Updates.fetchUpdateAsync();
    showBlockingUpdateUI();  // forces user to relaunch
  }
}
```

**Automated rollback (script)**:
```bash
#!/bin/bash
SLO=$(curl -s "$SENTRY_API/.../crash-free" | jq .value)
if (( $(echo "$SLO < 99.0" | bc -l) )); then
  eas channel:edit production --branch release-1.4.x-prev --json
  alert "OTA rollback executed; SLO=$SLO"
fi
```

---

## Comparison

| Strategy | Use |
|---|---|
| `fingerprint` policy | recommended (auto) |
| `appVersion` policy | semantic, less precise |
| Manual RV strings | full control, error-prone |

---

## Production Usage

- All Expo apps with active development.
- Critical for B2C; less for B2B (slower release cycle).

---

## Hands-On Exercise

1. Configure `fingerprint` runtime version.
2. Set up branches per release line.
3. Implement health-gated rollout script.
4. Run full hot-fix simulation.

---

## Common Mistakes

- OTA shipping JS that calls missing native module.
- No staged rollout (full blast).
- No rollback runbook.
- Native release without bumping branch.

---

## Production Red Flags

- "We OTA'd a fix Friday night."
- No health metrics during ramp.
- Channel-branch mapping undocumented.

---

## Performance & Metrics (MANDATORY)

- Update download P95: < 5s.
- Apply success: > 99%.
- Rollback time: < 1 min channel flip.

---

## Decision Framework

| Change | Path |
|---|---|
| JS bug fix | OTA |
| Asset swap | OTA |
| New native dep | native release + new RV |
| Entitlement change | native release |

---

## Senior-Level Insight

OTA is **a feature, not a fire extinguisher**. Senior teams write an "OTA charter" with allowed change classes, gating, and accountability.

---

## Memory Hook
**"Channel + branch + runtime version. Stage. Gate. Rollback ready."**

## Revision Notes
> OTA = JS+assets only. Bump runtime version on native change. Branch per release line; channel per env. Stage rollout 5%→25%→50%→100% with SLO gate. Rollback = repoint channel. Coordinate with backend versioning + feature flags.

---

---

### Q3. Code signing — credentials, keychains, and rotation at scale

---

## Difficulty
- Advanced

## Interview Frequency
- Common (security / release rounds)

## Prerequisites
- iOS code signing model, Android keystore basics

## TL;DR
**iOS**: ASC API key (preferred) over Apple ID; provisioning profiles + distribution certs managed by EAS or by you. **Android**: keystore (jks/p12), one per app, **never lose it**, rotate via Play App Signing. Best practice: EAS-managed credentials for solo/small teams; **vault-backed** (HashiCorp Vault / AWS Secrets Manager) for enterprise. Rotate ASC keys quarterly; never rotate Android keystore (use Play App Signing for upgradeable signing).

---

## 30-Second Interview Answer

> "iOS uses ASC API keys (key ID + issuer ID + p8) — preferred over Apple ID. Provisioning profiles + dist certs managed by EAS or your own. For enterprise: vault the p8 + keystore in Secrets Manager; CI fetches at build time. Android: one keystore per app, **never lose it**. Use Play App Signing — Google holds the upload key signing; you can rotate the upload key. Rotate ASC keys quarterly (revoke old). For brownfield CI: Fastlane match still works; for Expo: `eas credentials` with `--non-interactive`."

---

## 2-Minute Practical Answer

**iOS credentials**:
- **Apple ID auth [LEGACY]**: 2FA breaks CI; avoid.
- **ASC API key (preferred)**: key ID, issuer ID, p8 file. CI-friendly.
- **Distribution cert**: per team, expires 1 year, regenerate.
- **Provisioning profile**: per app, includes cert + entitlements + devices.

**Android credentials**:
- **Upload keystore**: signs APK/AAB you upload to Play Console.
- **App signing key**: Google holds (Play App Signing), signs APKs delivered to users.
- Upload keystore can be rotated; app signing key is permanent (Google hosts).

**EAS-managed (recommended for most)**:
```bash
eas credentials  # interactive setup
# or
eas credentials --platform ios --non-interactive
```
EAS stores everything encrypted server-side; works in CI via robot token.

**Self-managed (enterprise)**:
- Store p8, dist cert, profile, keystore in Vault / Secrets Manager.
- CI fetches before build:
```yaml
- run: |
    aws secretsmanager get-secret-value --secret-id ios/p8 \
      --query SecretString --output text > AuthKey.p8
- run: eas build --platform ios --profile production --non-interactive
  env:
    APP_STORE_CONNECT_KEY_ID: ${{ secrets.ASC_KEY_ID }}
    APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
    APP_STORE_CONNECT_KEY_PATH: AuthKey.p8
```

**Fastlane match (legacy alternative)**:
- Stores certs in encrypted Git repo.
- Common in bare RN.
- Works alongside EAS for hybrid setups.

**Rotation**:
- ASC key: rotate quarterly. Generate new in App Store Connect → update CI → revoke old.
- iOS dist cert: regenerate at expiry; profiles auto-rebuild via EAS.
- Android upload keystore: rotate via Play Console "Upload key reset" if compromised.
- Android app signing key: never rotate (Google manages).

**Audit**:
- Log every credential access.
- Limit access to release engineers.
- Alert on new ASC key creation.

---

## 5-Minute Architecture Answer

iOS code signing model:
- Apple needs to verify: who built it (cert), what device (provisioning profile), what entitlements.
- Cert signed by Apple Worldwide Developer Relations CA.
- Profile = cert + bundle ID + devices + entitlements.
- Per environment: dev cert + dev profile, dist cert + dist profile.

Android code signing model:
- APK/AAB signed with private key.
- Old model: developer holds key forever (lose it = can't update app).
- **Play App Signing** (current default): you upload signed-with-upload-key; Google re-signs with permanent app key for distribution.
- Upload key separate from app key → upload key rotatable.

EAS credentials internals:
- p8, certs, profiles encrypted with KMS.
- Per project + per profile in `eas.json`.
- Build-time fetch over TLS.

Vault patterns (enterprise):
- Per-environment secrets (staging vs prod).
- Time-bound access tokens.
- Audit log of every fetch.
- Kill-switch revocation.

Rotation playbook:
1. Generate new ASC key in App Store Connect.
2. Update CI secrets (parallel with old).
3. Run a build to verify.
4. Revoke old key.
5. Document rotation in runbook.

For provisioning profiles:
- Auto-renewed by EAS / Fastlane match.
- Manual: regenerate in Apple Developer portal.

For Android keystore:
- Document in vault with **paranoid backup**: 3 locations, encrypted, accessible only to senior engineers.
- Lost keystore = create new app on Play Store (catastrophic).
- Play App Signing mitigates — you can rotate upload key.

The 2026 specific:
- **EAS credentials --non-interactive** for fully automated CI.
- **OIDC short-lived tokens** for secret fetch.
- **Sigstore** for supply-chain attestation.
- **Apple Notarization** automation via altool / EAS Submit.
- **Google Play Integrity API** for runtime attestation.

Common failures:
- Cert expired → builds fail Friday afternoon.
- Profile out of date with new bundle ID.
- Keystore mismatch (different key than Play expects).
- ASC key revoked accidentally.

Mitigations:
- Calendar alerts on cert expiry (60 / 30 / 7 days).
- Monitoring on build success rate.
- Runbook for "credentials broken at 5pm Friday".

---

## The "Why"

Code signing is the gate to release. Lost or compromised credentials = lost or hijacked app. Companies care because release engineering's quietness depends on credential hygiene.

---

## Mental Model

iOS: cert + profile (rotatable). Android: keystore (precious; back up paranoid).

---

## Internal Working (2026 Context)

- ASC API: REST + JWT-signed (p8).
- Play App Signing: Google manages master key.
- EAS: encrypted at rest, fetched per build.

---

## Modern Implementation (Code)

**ASC key rotation script**:
```bash
NEW_KEY=$(create-asc-key)
aws secretsmanager update-secret --secret-id ios/asc/key \
  --secret-string "$NEW_KEY"
eas build --platform ios --profile validation --non-interactive
revoke-asc-key "$OLD_KEY_ID"
```

**Fastlane match config (legacy, still used)**:
```ruby
match(type: 'appstore', readonly: is_ci)
```

---

## Comparison

| Approach | Best for |
|---|---|
| EAS-managed | most teams |
| Vault + EAS | enterprise |
| Fastlane match | bare RN, legacy |

---

## Production Usage

- Universal: some form of credential automation.
- Manual cert handling = team red flag.

---

## Hands-On Exercise

1. Set up ASC API key + EAS-managed credentials.
2. Practice rotation.
3. Migrate keystore to Play App Signing (if not).
4. Build runbook for credentials emergency.

---

## Common Mistakes

- Keystore on a laptop with no backup.
- Apple ID + 2FA in CI.
- Credential leak via build logs.
- No expiry monitoring.

---

## Production Red Flags

- Single point of failure (one engineer holds keys).
- No rotation in 2+ years.
- Plaintext secrets in Actions.

---

## Performance & Metrics (MANDATORY)

- Cert expiry alert: 60d before.
- Rotation time: < 1 hour.

---

## Decision Framework

| Org size | Choose |
|---|---|
| Solo / small | EAS-managed |
| Mid | EAS-managed + secret-manager backup |
| Enterprise | Vault + ephemeral fetch |

---

## Senior-Level Insight

Treat credentials as a tier-0 system. Senior teams have a release-engineering on-call, monitoring, and a "cert-expiry war game" semi-annually.

---

## Memory Hook
**"ASC + cert + profile (iOS). Keystore + Play App Signing (Android). Vault. Rotate."**

## Revision Notes
> iOS: ASC API key over Apple ID. Cert + profile via EAS or Vault. Rotate quarterly. Android: upload keystore (rotatable via Play App Signing); app signing key permanent. Back up paranoid. Audit + alert.

---

---

### Q4. Staged rollouts + kill switches in coordination

---

## Difficulty
- Advanced

## Interview Frequency
- Common (release / SRE rounds)

## Prerequisites
- Q2, feature flag basics

## TL;DR
Staged rollout = % of users get new build/update; ramp on health. Kill switch = feature flag that disables a code path instantly. Combine: ship behind flag → rollout build to 100% gradually → enable flag per cohort → if broken, flip flag (faster than rollback). Tools: LaunchDarkly / Statsig / Unleash / ConfigCat / Firebase Remote Config. SDK side: cache flags locally for offline; refresh in background.

---

## 30-Second Interview Answer

> "Staged rollout in Play Console / App Store Connect ramps the new build to a percentage of users — 1%, 5%, 10%, 50%, 100%. Kill switches via feature flag service let you disable a code path in seconds without a release. Pattern: ship feature dark in v1.5 build, roll out to 100% over a week, then flip flag on per cohort, monitor, ramp. If broken, flip flag off — much faster than store rollback. Flags cached locally with refresh; respect offline. Used together: build rollout for the binary, flag rollout for the behavior."

---

## 2-Minute Practical Answer

**Staged rollout (store)**:
- **Play Console**: production track → "Staged rollout %" — 1, 5, 10, 20, 50, 100.
- **App Store Connect**: "Phased Release for Automatic Updates" — 7 days from 1% to 100%, can pause / restart.
- Halt rollout if crash spike.

**Kill switch (feature flag)**:
- Code wraps feature in `if (flag.isOn('new-checkout')) { ... } else { /* legacy */ }`.
- Flag controlled remotely.
- Flip in seconds; takes effect on next flag-fetch.

**Tools**:

| Tool | Strength |
|---|---|
| LaunchDarkly | enterprise, feature flag standard |
| Statsig | flags + experimentation + analytics |
| Unleash | OSS, self-host |
| ConfigCat | simple, fast |
| Firebase Remote Config | free, basic |
| GrowthBook | OSS + experimentation |

**Client SDK pattern**:
```tsx
import { useFlag } from '@/feature-flags';

function Checkout() {
  const useNewFlow = useFlag('new-checkout', { default: false });
  return useNewFlow ? <NewCheckout /> : <LegacyCheckout />;
}
```

**Offline-resilient flag SDK**:
- Cache last known values in MMKV.
- Refresh on app start + every N minutes.
- Default to safe value if no cache.

**Rollout coordination**:
1. Ship build with feature behind flag (default off).
2. Stage roll out the binary 5% → 100% over a week.
3. After 100% binary, enable flag for internal users.
4. Beta cohort.
5. 1% → 5% → 25% → 100% of users with flag on.
6. Watch SLOs at each step.

**Kill switch flow**:
- Spike in crashes after flag enabled → flip flag off remotely.
- Users on next flag refresh see legacy behavior.
- No store action needed.

---

## 5-Minute Architecture Answer

Why two layers (binary + flag):
- **Binary rollout**: limited control (% bucket); slow to revert (store rollback delay).
- **Flag rollout**: granular targeting (cohorts, geos, % of users); revert in seconds.
- Together: ship code safely, control behavior precisely.

Cohort targeting:
- By user attributes (country, plan, app version, device tier).
- By context (network, time of day).
- Sticky bucketing: same user always gets same variant.

Experimentation overlay:
- Statsig / GrowthBook treat flags as experiments.
- Track conversion / KPI per variant.
- Auto-promote winning variant.

SDK design:
- **Init**: fetch all flags at app start.
- **Subscribe**: re-fetch periodically (5–60 min).
- **Local cache**: fall back to cached values if network down.
- **Default values**: in-code safe defaults.

Performance:
- Flag eval = local lookup, microseconds.
- Network only on refresh.

Pitfalls:
- Flag explosion: hundreds of stale flags. Govern with cleanup.
- Long-lived flags become tech debt; remove after stable.
- Kill switches must work offline (cache).
- Don't gate critical path on flag without fallback.

The 2026 specific:
- **Statsig dynamic config** + experimentation native.
- **LaunchDarkly Federal** for regulated.
- **Edge flag eval** (CDN-side) for lowest latency.
- **Flag-as-code** (in-repo definitions, deploy via PR).
- **AI-suggested flag cleanup** in vendor UIs.

Governance:
- Flag lifecycle: created → enabled → ramped → cleaned up.
- Owner per flag; alert if stale > N months.
- Audit log of toggles.

Coordination with EAS Update:
- OTA can ship code; flag enables it.
- Pattern: OTA the change defaulting to legacy; flag promotes to new.
- This decouples deploy from release.

---

## The "Why"

Staged + flagged = safe release at speed. Without: scary all-or-nothing pushes. Companies care because flags determine "ship daily" vs "ship monthly".

---

## Mental Model

Build rollout = vehicle delivery. Flag = key in ignition. Crash = take key away (don't recall vehicle).

---

## Internal Working (2026 Context)

- Flag SDK polls/streams config.
- Local eval against rules.
- Telemetry back to vendor.

---

## Modern Implementation (Code)

**Statsig setup**:
```ts
import { Statsig } from '@statsig/react-native';
await Statsig.initialize(SDK_KEY, { userID: user.id, custom: { plan: user.plan } });
const showNewUI = Statsig.checkGate('new-ui');
```

**Cached flags with TanStack Query**:
```ts
const { data: flags } = useQuery({
  queryKey: ['flags', userId],
  queryFn: fetchFlags,
  staleTime: 5 * 60_000,
  gcTime: 30 * 60_000,
  initialData: cachedFlags,
});
```

**Kill switch hook**:
```ts
function useKillSwitch(name: string, fallback: boolean) {
  const flags = useFlags();
  return flags?.[name] ?? cachedFlag(name) ?? fallback;
}
```

---

## Comparison

| Layer | Speed | Granularity |
|---|---|---|
| Store staged rollout | hours | % of users |
| OTA channel rollout | minutes | % of users |
| Feature flag | seconds | per cohort |

---

## Production Usage

- All consumer apps with flag service.
- Standard at scale.

---

## Hands-On Exercise

1. Wire LaunchDarkly / Statsig.
2. Wrap a feature behind a flag.
3. Stage roll out a build + ramp flag.
4. Practice kill-switch flip.

---

## Common Mistakes

- Flag check on critical path with no fallback.
- No cache → broken when offline.
- Flag explosion (no cleanup).
- Flipping prod flag without observability.

---

## Production Red Flags

- 500+ active flags.
- No flag owners.
- Flag flips without audit.

---

## Performance & Metrics (MANDATORY)

- Flag eval: < 1ms local.
- Refresh: every 5–60 min.

---

## Decision Framework

| Need | Layer |
|---|---|
| Code-level rollout | OTA + binary |
| Behavior gating | flag |
| Instant disable | kill switch flag |
| Cohort experiment | flag with experimentation |

---

## Senior-Level Insight

Senior teams treat flags like APIs: documented, versioned, owned, retired. Flag debt is real and silent.

---

## Memory Hook
**"Stage the binary; flag the behavior; flip on alarm."**

## Revision Notes
> Staged rollout = % via store / OTA. Kill switch = remote flag flip. Combine: ship dark, ramp binary, ramp flag per cohort. Cache flags offline. Govern flag lifecycle. Tools: LaunchDarkly, Statsig, Unleash, ConfigCat.

---

---

### Q5. Store rejection patterns + remediation

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Common (release engineering rounds)

## Prerequisites
- App Store + Play Store submission

## TL;DR
Top rejection causes: **broken sign-in / demo creds**, **placeholder content**, **crashes on first launch**, **misleading metadata**, **policy violations** (data, in-app purchase, child safety, payments outside store), **privacy nutrition label mismatch**, **permissions without clear use**. Have a remediation playbook: review reason → reproduce → fix or appeal → resubmit. Apple usually faster than Play's automated checks; Play's manual review can take longer for sensitive categories.

---

## 30-Second Interview Answer

> "Top rejections: broken demo account, crashes on first launch, missing privacy disclosures, in-app purchase policy violations, misleading screenshots, undeclared permission usage. Playbook: parse review notes, reproduce on a fresh install, fix or write a clear appeal with evidence, resubmit. Apple's response is usually 24–48h; Play's automated checks faster but manual review for sensitive verticals can take a week. Maintain pre-submission checklist; have demo account that always works; never ship store metadata mismatching the build's behavior."

---

## 2-Minute Practical Answer

**Most common rejection reasons** (Apple):
- **Guideline 2.1 (Performance)**: app crashes, broken UI, demo creds invalid.
- **Guideline 2.3.7 (Accurate Metadata)**: screenshots / description / category mismatch.
- **Guideline 3.1.1 (In-App Purchase)**: payment outside IAP for digital goods.
- **Guideline 4.0 (Design)**: poor UX, copies of system UI.
- **Guideline 5.1.1 (Privacy)**: missing privacy policy, data collected without disclosure.
- **Guideline 5.1.2 (Data Use & Sharing)**: undeclared SDK data sharing.

**Most common rejection reasons** (Google):
- **Crashes / ANRs** detected by Google's pre-launch tests.
- **Permissions** (location, SMS, accessibility, foreground service) without justification.
- **Family / kids policy** violations.
- **Payments** outside Play Billing for digital goods.
- **Restricted content** (financial, health) without proper certification.
- **Background location** without prominent disclosure.
- **Misleading metadata**.

**Pre-submission checklist**:
- Sign-in with stored demo account works.
- Onboarding doesn't dead-end without permissions.
- App doesn't crash on first launch.
- Screenshots match current UI.
- Privacy policy URL live.
- Privacy nutrition labels match SDK + code.
- Permissions have clear `usageDescription`.
- IAP for digital goods (no Stripe / Razorpay for digital).
- Background modes declared with reason.
- Account deletion in-app (Apple required since 2022).
- Push notif opt-in is opt-in, not auto.

**Appeals**:
- Use Resolution Center (Apple) / Play Console replies.
- Be concrete: include screenshots, screen recordings, repro steps.
- Cite guidelines you believe were misapplied.
- Don't argue; explain.

**Re-review timing**:
- Apple typically 24h.
- Play typically faster but variable.

**Pre-launch testing**:
- Apple TestFlight beta + internal review.
- Play Console pre-launch report (auto-runs across devices, surfaces crashes).
- Maestro Cloud across device matrix.

---

## 5-Minute Architecture Answer

Why review exists:
- Stores enforce platform-level quality + privacy + monetization rules.
- A rejection isn't punishment; it's gating against bad-faith and bad-quality apps.
- Senior engineers internalize the spirit (user trust) over the letter.

Privacy nutrition labels (Apple):
- App Store Connect requires declaring data types collected + purposes.
- Must match what SDKs actually do.
- Common mismatch: ad SDK collects identifiers, app didn't disclose.
- Mitigation: SDK audit per release.

Account deletion (Apple Guideline 5.1.1(v)):
- Required since 2022.
- Must be in-app (not just on website).
- Must delete account, not just data.

Sign in with Apple (Apple Guideline 4.8):
- If you offer third-party sign-in (Google/Facebook), must offer Sign in with Apple.

Background location (Apple + Google):
- Must justify; show prominent disclosure on first use.
- Apple: "Allow Once / While Using / Always".
- Android 10+: foreground required first, then background prompt.

In-app purchase:
- Digital goods (subscriptions, virtual currency) MUST go through IAP.
- Physical goods can use external payment.
- Reader apps (subscriptions for content) — Apple now allows external in some categories (post 2024 ruling).
- Cross-platform purchases acknowledged separately.

Family / kids:
- Strict ad rules.
- COPPA compliance.
- Verifiable parental consent (US).

Permissions:
- iOS: every `NS*UsageDescription` must be specific and accurate.
- Android: runtime permissions + foreground service types.

Common app metadata mistakes:
- Screenshots from old version.
- "Coming soon" features mentioned in description.
- Wrong category (health app in productivity).
- Localized metadata not localized.

Rejection patterns I see in interviews:
- Q: "Your app got rejected for 5.1.1 — what do you do?" → walk through: read full message, check what data is collected, audit SDKs, update privacy policy, update labels, re-submit with response explaining changes.

The 2026 specific:
- **Privacy Manifest** (iOS) required listing required-reason API usage.
- **DSA / EU regulations** require trader info for EU.
- **Play Data Safety** continually updated.
- **AI/LLM usage** disclosure required if app uses GenAI.
- **Sideloading** (EU iOS) doesn't reduce review obligations.

Operational hygiene:
- Maintain a "submission runbook" — checklist + responsible parties.
- Maintain stable demo account.
- Keep release notes clear (reviewers read them).
- Avoid Friday submissions (review may slip into weekend).

---

## The "Why"

Rejections delay revenue + user adoption. Repeated rejections trigger reviewer scrutiny on future submissions. Companies care because release predictability depends on rejection avoidance.

---

## Mental Model

Reviewer = first user. Make their experience easy: working demo, clear UI, accurate metadata, declared permissions.

---

## Internal Working (2026 Context)

- Apple uses both automated scans + human review.
- Google uses automated pre-launch tests + spot manual review.
- Both increasing AI assistance for first-pass triage.

---

## Modern Implementation (Code)

**Privacy manifest (iOS) — `PrivacyInfo.xcprivacy`**:
```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
  <dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>CA92.1</string></array>
  </dict>
</array>
```

**Account deletion (RN)**:
```tsx
function DeleteAccount() {
  const onConfirm = async () => {
    await api.deleteAccount();
    await session.clear();
    router.replace('/');
    Alert.alert('Account deleted');
  };
  // ... confirmation UI
}
```

---

## Comparison

| Cause | Frequency | Severity |
|---|---|---|
| Crashes | high | high |
| Privacy mismatch | high | high |
| IAP violation | medium | high |
| Metadata mismatch | medium | medium |
| Permission unclear | medium | medium |

---

## Production Usage

- Universal: pre-submit checklist.
- Mature: dedicated "release manager" role.

---

## Hands-On Exercise

1. Build pre-submit checklist from real rejection messages.
2. Audit SDKs for privacy disclosure.
3. Add account deletion flow.
4. Practice writing an appeal.

---

## Common Mistakes

- Demo account password expired.
- Privacy policy URL 404.
- Forgetting Privacy Manifest.
- IAP omitted for digital goods.

---

## Production Red Flags

- Submission "by hope".
- No checklist.
- Repeated rejections same root cause.

---

## Performance & Metrics (MANDATORY)

- First-pass approval rate: > 90% (mature team).
- Time-to-approve: < 48h Apple typical.

---

## Decision Framework

| Rejection | Path |
|---|---|
| Performance / crash | fix + resubmit |
| Metadata | update + resubmit |
| Policy interpretation | appeal with evidence |
| Permission | clarify usage + resubmit |

---

## Senior-Level Insight

Senior orgs treat reviewers as customers — clear release notes, working demo, polite appeals. The reputation accumulates: reviewers (and AI triage) note repeat-quality submitters.

---

## Memory Hook
**"Demo creds, no crashes, accurate metadata, declared permissions."**

## Revision Notes
> Rejections: crashes, demo broken, metadata mismatch, IAP violation, undeclared data. Pre-submit checklist. Privacy Manifest (iOS). Account deletion required. Appeals with evidence. Apple ~24-48h, Play variable.

---

> **End of S20.** Cross-refs: [S5 Expo & Tooling](S05-expo-tooling.md), [S6 Hermes & Metro](S06-hermes-metro.md) (sourcemaps), [S18 Observability](S18-observability.md) (SLO gates), [S27 Runbooks](S27-runbooks.md), [S30 Privacy](S30-privacy-compliance.md). Next per priority: [S30 Privacy](S30-privacy-compliance.md).
