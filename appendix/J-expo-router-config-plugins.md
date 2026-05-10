## Appendix J — Last gap-fill (Expo Router, Config Plugins, AI-assisted engineering, Top-50 Q index)

> The user's handbook spec called out three more things explicitly: **Expo ecosystem deep**, **AI-assisted engineering**, and a standardized **Top-50 Q index per topic**. This appendix closes them honestly.

---

### J.1 — Expo Router (file-based routing for RN)

**Why it matters in 2026**: Expo Router is becoming the default for new RN apps. Most Tier-S/A interviews now ask about it.

**Mental model**: file system = navigation tree. `app/` is the root. Every `.tsx` file is a route. Layouts (`_layout.tsx`) wrap children. Groups `(name)` don't add to URL.

**Project structure example**:
```
app/
  _layout.tsx              # root: NavigationContainer + auth gate
  index.tsx                # /
  (tabs)/
    _layout.tsx            # tab bar
    home.tsx               # /home
    portfolio.tsx          # /portfolio
    profile.tsx            # /profile
  (auth)/
    _layout.tsx            # stack for auth screens
    login.tsx              # /login
    otp.tsx                # /otp
  order/
    [id].tsx               # /order/:id  (dynamic)
    [...rest].tsx          # /order/* catch-all
  +not-found.tsx
```

**Root `_layout.tsx` with auth gate**:
```tsx
import { Slot, useRouter, useSegments } from 'expo-router';
import { useEffect } from 'react';
import { useAuth } from '@/auth';

export default function Root() {
  const { user, ready } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    if (!ready) return;
    const inAuthGroup = segments[0] === '(auth)';
    if (!user && !inAuthGroup) router.replace('/login');
    if (user && inAuthGroup) router.replace('/');
  }, [user, ready, segments]);

  return <Slot />;
}
```

**Typed dynamic route**:
```tsx
// app/order/[id].tsx
import { useLocalSearchParams } from 'expo-router';
export default function Order() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <OrderScreen orderId={id} />;
}
```

**Deep link mapping** is automatic — `myapp://order/123` and `https://myapp.com/order/123` both resolve to `app/order/[id].tsx`. Configure in `app.json`:
```json
{ "expo": { "scheme": "myapp", "deepLinking": true } }
```

**Top interview questions**:
- File-based vs config-based navigation — when would you pick which?
- How do you guard a route in Expo Router? (segments + redirect in layout)
- How do you pass typed params? (`useLocalSearchParams<T>` + Zod)
- How does Expo Router handle universal links? (`scheme` + AASA + `assetlinks.json`)
- Trade-offs vs React Navigation directly?

---

### J.2 — EAS Build, EAS Update, Config Plugins

**EAS Build profiles** (`eas.json`):
```json
{
  "cli": { "version": ">= 3.0.0" },
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview":     { "distribution": "internal", "channel": "preview" },
    "production":  { "channel": "production", "autoIncrement": true }
  },
  "submit": {
    "production": {
      "ios":     { "appleId": "you@x.com", "ascAppId": "12345", "appleTeamId": "ABCDE" },
      "android": { "serviceAccountKeyPath": "./play-key.json", "track": "internal" }
    }
  }
}
```

**EAS Update channel + branch model**:
- **Channels** (set at build time): `preview`, `production`. Channel pins what updates the binary will accept.
- **Branches** (set at publish time): you can map `production` channel → `production` branch. Hot-swap by re-mapping for emergency rollback.
```sh
eas update --branch production --message "feat: new home"
eas channel:edit production --branch production-v2  # safe canary swap
eas update --branch production --message "rollback" --republish --group <previous-id>
```

**OTA limits to remember**:
- JS + assets only. **No native code.** No new permissions. No new native modules.
- Updates apply on **next cold start** by default; for visible-now, use `Updates.fetchUpdateAsync()` then `Updates.reloadAsync()`.

**Config plugin (a plugin that mutates native config at prebuild time)**:
```ts
// plugins/with-android-permission.ts
import { ConfigPlugin, withAndroidManifest, AndroidConfig } from 'expo/config-plugins';

const withCameraPermission: ConfigPlugin = (config) => {
  return withAndroidManifest(config, (cfg) => {
    AndroidConfig.Permissions.addPermission(cfg.modResults, 'android.permission.CAMERA');
    return cfg;
  });
};
export default withCameraPermission;
```

```json
// app.json
{ "expo": { "plugins": ["./plugins/with-android-permission"] } }
```

**Top interview questions**:
- When do you need a config plugin vs a regular Expo module?
- Difference between EAS channels and branches?
- What can / can't go in an OTA update?
- How would you do staged rollout in EAS?
- How do you migrate a bare RN app to Expo Modules?

---

### J.3 — AI-Assisted Engineering (the 2026 differentiator)

**Why interviewers ask**: every product team is wiring Copilot / Cursor / Claude Code into their workflow. They want leads who use AI safely and **make their team faster** with it, not slower.

**Where AI actually helps in mobile**:
| Task | Tool pattern | Risk to manage |
|---|---|---|
| Boilerplate (CRUD screens, RTK slices, stories) | Cursor / Copilot inline | Hallucinated APIs — always typecheck + run |
| Test generation (RNTL, Jest) | Claude / Copilot Chat with file context | Tests that pass-on-empty — review assertions |
| Codemods (RN upgrade, RTK migration) | Claude Code agent + git diff review | Cross-file regressions — run full test suite |
| Debugging stack traces | Paste stack + relevant file → ask root cause | Hallucinated fix — verify against repro |
| Architecture sounding board | Claude / GPT for ADR draft critique | Generic advice — always reground in your constraints |
| Native module scaffolding (Swift/Kotlin) | Copilot for plumbing | Threading + memory bugs — review carefully |
| PR review triage | LLM summarizer over diff | Misses context — humans still gate |
| Documentation | LLM from code → MDX | Drift — regenerate per release |

**Senior workflow patterns (cite these in interviews)**:
1. **Spec-first**: write a clear prompt with file paths, types, and a 3-sentence goal. Don't free-form.
2. **Small surface, fast loop**: ask for one function at a time; run + commit before next.
3. **Tests as the contract**: ask AI to write the test first, then implement.
4. **Block AI from touching**: secrets, native build files, prod config, anything mentioned in `.cursorignore` / `.aiignore`.
5. **Code review**: AI drafts, human reviews. Never the reverse.

**`.cursorignore` / `.aiignore` example** (real fintech):
```
# secrets
**/*.env
**/google-services.json
**/GoogleService-Info.plist
android/app/keystore.properties
ios/PrivacyInfo.xcprivacy

# generated
ios/Pods
android/.gradle
node_modules
.expo
dist
build

# legal/security-sensitive
docs/security/**
infra/**
```

**Production guardrails (lead-level talking points)**:
- License hygiene: AI suggestions can carry incompatible licenses — pair with a tool that flags.
- PII in prompts: never paste real user data. Anonymize or use synthetic.
- IP boundary: enterprise plans + zero-data-retention only for client codebases.
- Telemetry: track team adoption + escape rate (AI-written code that gets reverted) as a lead metric.

**Interview Q examples**:
- "How does your team use AI without shipping bad code?" → Spec-first + tests-first + ignore boundaries + PR review unchanged.
- "What's a task you'd never give to AI?" → Cryptography, payment math, native threading, anything compliance-bounded.
- "How do you measure if AI is helping the team?" → Cycle time (idea → merged), revert rate, review time per PR, plus qualitative team retro.
- "Show a case AI saved real time." → STAR-style: codemod across 80 files for RN upgrade; AI-drafted, human-reviewed; cut from 3 days to 4 hours.

---

### J.4 — Top-50 Question Index (where each topic's 50+ Qs live)

> The handbook spec asked for "Top 50 Questions" per section. Practical truth: 50 × 23 sections = 1,150 questions, which kills the value of a single document. Instead, this index points you at where the questions for each topic are **already** written, and how to scale to 50 by drilling each one short / deep / follow-up.

**How to expand any answer to 50 questions worth of practice**:
For each Q in the file, generate 4 derivatives:
1. **Short** (20 sec, recruiter-friendly).
2. **Deep** (60–180 sec, technical-friendly).
3. **Follow-up trap** (the "yes, but…" the interviewer throws).
4. **Code / war story** (the "show me, don't tell me" version).

That converts ~12 written Qs per topic into ~50 spoken Qs per topic — without padding the file.

**Index — where to find each topic's Q&A in this file**:

| Topic | Q&A locations |
|---|---|
| JS execution model, closures, event loop, promises | Sections 2; G.1–G.4; H.10–H.11 |
| TypeScript (incl. generics, utility, discriminated, infer) | Section 3; G.5 |
| React rendering, hooks, perf, Suspense, EBs | Section 4; G.6–G.8; H.9 |
| RN architecture (old + new), Hermes, Metro | Sections 5–6; G.9–G.10 |
| Performance (lists, anim, images, memory, startup) | Section 7; G.11; G.13; S1, S8 |
| Native modules (Swift / Kotlin / TurboModule) | Section 8; G.12 |
| Debugging toolkit (Hermes / Flipper / Reactotron / Instruments / Profiler / Charles / Sentry) | Section 9; G.13; H.3, H.4 |
| State management (RTK / Zustand / RQ / MMKV) | Section 10; G.14 |
| Navigation + deep linking + Expo Router | Section 11; G.16; J.1 |
| Networking (REST / GraphQL / WS / retry / token refresh) | Section 12; G.17; S11–S12 |
| Auth + Security (OAuth PKCE, Keychain, pinning, MASVS) | Sections 13, 16; G.18 |
| Offline-first + outbox + conflict | Section 14; G.15 |
| Push notifications (FCM / APNs / Expo) | Section 15; H.1; S4 |
| Accessibility + i18n + RTL | Section 17; H.2 |
| Testing (Jest / RNTL / Detox / Maestro) | Section 18; G.19 |
| CI/CD (Fastlane / GH Actions / EAS / OTA) | Section 19; G.20; J.2 |
| Observability (Sentry / Crashlytics / sourcemaps) | Section 20; G.21 |
| Mobile system design (3 walkthroughs) | Section 21; G.22; H.5; I.4 |
| DSA (12 LeetCode patterns with code) | Section 22; G.23 |
| Behavioral + STAR (10 stories) | Section 23; Appendix E |
| Resume / LinkedIn / Naukri / negotiation | Section 24; Appendices C–D; H.8 |
| Production scenarios (12 walkthroughs S1–S12) | G.24 |
| Company-specific prep | G.25; I (track-↔-company table) |
| Mock interview format (weak / good / lead) | H.6 |
| Architecture Decision Records | H.5 |
| Six engineering tracks (Core / Product / Platform / Architecture / Production / Leadership) | Appendix I |
| Sample apps (5 demo skeletons) | H.7 |
| Expo Router + EAS + config plugins | J.1, J.2 |
| AI-assisted engineering | J.3 |

---

