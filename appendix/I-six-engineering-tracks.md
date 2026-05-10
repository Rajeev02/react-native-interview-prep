## Appendix I — The Six Engineering Tracks (lead-level breakdown)

> Lead/Architect roles are evaluated across six tracks, not one. Most engineers are strong in 2–3 and weak in the rest. This appendix gives you the **bar**, the **interview signals**, the **questions asked**, and the **gap-fill code/practice** for each track. Score yourself 1–5 per track. Anything ≤3 is your next 2 weeks.

---

### Track 1 — Core Engineering (JS / TS / React / RN)

**The bar at lead level**:
- Can explain JS execution model + event loop + microtasks without flinching.
- Writes type-safe APIs with discriminated unions, generics, and runtime validators (Zod).
- Knows React render model deeply enough to debug "why did this render" cold.
- Knows RN architecture (old bridge → JSI/Fabric/TurboModules) deeply enough to make migration calls.

**Interview signals you've nailed it**:
- You correct the interviewer when they conflate microtask/macrotask.
- You spot the closure bug in their code snippet in <30 sec.
- You explain a concept in 20s, 60s, 3min versions on demand.

**Questions they will ask** (covered: G.1–G.12, H.9–H.11):
- Walk me through what happens between `setState` and pixels on screen.
- Why does `useEffect` run twice in dev? What changes in prod?
- When would you write a TurboModule vs a regular native module vs JS-only?
- Type a polymorphic component (`<Button as="a">` style) — show me.
- Implement `Promise.all` and explain ordering guarantees.

**Score 5/5 if you can**:
- Recite G.1–G.12 short+deep without notes.
- Type the code from G.4, G.5, G.7, G.11, H.10, H.11 from memory.

---

### Track 2 — Product Engineering (UI / UX / Figma / Storybook / Design Systems)

**The bar**:
- Can sit with a designer in Figma, pull tokens (colors, spacing, type scale) into code, and ship pixel-faithful UI.
- Knows when a "design choice" is actually an a11y bug (contrast, target size, motion).
- Owns a component library / design system in Storybook with variants + a11y addon.
- Pushes back on PM with **user-research** language, not "I think".

**Figma → code workflow** (this is what most RN engineers fake — own it):
1. **Read tokens**: Figma Variables panel → name them by intent (`color/bg/surface`, not `gray/100`).
2. **Export to code** via Figma MCP or Tokens Studio → JSON → `theme.ts`.
3. **Component map**: each Figma component → one Storybook story with controls.
4. **Annotate**: get designer to add states (default/hover/pressed/disabled/loading/error) in Figma.

**Token file (real example)**:
```ts
// theme/tokens.ts (generated from Figma; do not hand-edit)
export const tokens = {
  color: {
    bg: { surface: '#FFFFFF', muted: '#F6F7F9', elevated: '#FFFFFF' },
    fg: { default: '#0B1220', muted: '#5B6472', onPrimary: '#FFFFFF' },
    brand: { 50: '#EEF2FF', 500: '#4F46E5', 700: '#3730A3' },
    intent: { success: '#0A7E3D', warning: '#B7791F', danger: '#C0392B' },
  },
  space: { 0: 0, 1: 4, 2: 8, 3: 12, 4: 16, 5: 24, 6: 32, 8: 48 },
  radius: { sm: 4, md: 8, lg: 16, full: 9999 },
  type: {
    body: { fontSize: 16, lineHeight: 24, fontWeight: '400' },
    h1: { fontSize: 28, lineHeight: 36, fontWeight: '700' },
  },
} as const;
```

**Themed component (light/dark, no hardcodes)**:
```tsx
import { useColorScheme } from 'react-native';
import { tokens } from '@/theme/tokens';

const palette = {
  light: { bg: tokens.color.bg.surface, fg: tokens.color.fg.default },
  dark:  { bg: '#0B1220',                fg: '#E5E7EB' },
};

export function Card({ children }: { children: React.ReactNode }) {
  const c = palette[useColorScheme() ?? 'light'];
  return (
    <View style={{ backgroundColor: c.bg, padding: tokens.space[4], borderRadius: tokens.radius.lg }}>
      <Text style={{ color: c.fg, ...tokens.type.body }}>{children}</Text>
    </View>
  );
}
```

**Storybook for RN (`.storybook/`)** — every component gets:
```tsx
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react-native';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Primitives/Button',
  component: Button,
  args: { children: 'Pay ₹2,499' },
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'ghost'] },
    size:    { control: 'select', options: ['sm', 'md', 'lg'] },
    loading: { control: 'boolean' },
  },
};
export default meta;

export const Primary:   StoryObj<typeof Button> = { args: { variant: 'primary' } };
export const Loading:   StoryObj<typeof Button> = { args: { variant: 'primary', loading: true } };
export const Disabled:  StoryObj<typeof Button> = { args: { variant: 'primary', disabled: true } };
```

**Component variants pattern (CVA-style without web deps)**:
```ts
// helpers/variants.ts
type V<T extends Record<string, Record<string, object>>> = {
  [K in keyof T]?: keyof T[K];
};

export function variants<T extends Record<string, Record<string, object>>>(base: object, map: T) {
  return (props: V<T>) => {
    const out = { ...base };
    for (const key in map) {
      const v = props[key];
      if (v) Object.assign(out, (map[key] as any)[v as string]);
    }
    return out;
  };
}

// Button.tsx
const styled = variants(
  { paddingHorizontal: 16, borderRadius: 12, alignItems: 'center' },
  {
    variant: {
      primary:   { backgroundColor: tokens.color.brand[500] },
      secondary: { backgroundColor: tokens.color.bg.muted },
      ghost:     { backgroundColor: 'transparent' },
    },
    size: { sm: { paddingVertical: 8 }, md: { paddingVertical: 12 }, lg: { paddingVertical: 16 } },
  }
);
```

**Empty / loading / error / success states — the four screens designers forget**:
Every screen must define all four. Example contract:
```tsx
type ScreenState<T> =
  | { kind: 'loading' }
  | { kind: 'empty' }
  | { kind: 'error'; retry: () => void; message: string }
  | { kind: 'ready'; data: T };

function Screen<T>({ state, render }: { state: ScreenState<T>; render: (d: T) => React.ReactNode }) {
  switch (state.kind) {
    case 'loading': return <Spinner/>;
    case 'empty':   return <EmptyState/>;
    case 'error':   return <ErrorState message={state.message} onRetry={state.retry}/>;
    case 'ready':   return <>{render(state.data)}</>;
  }
}
```

**Motion / haptics (the senior detail)**:
- Match Figma motion specs (duration + easing). Use Reanimated `withTiming(value, { duration: 200, easing: Easing.bezier(0.2, 0, 0, 1) })`.
- Haptics on commit-level actions only (`expo-haptics` `Haptics.impactAsync(Light)` on add-to-cart; never on scroll).
- Respect `AccessibilityInfo.isReduceMotionEnabled()` → skip parallax / shake.

**Common designer ↔ engineer fights (and the senior way to resolve)**:
| Tension | Junior reaction | Senior move |
|---|---|---|
| Designer ships pixel-perfect mock; doesn't include error state | "You didn't give me an error state" | Block PR until designer adds 4-state view; offer to design it together first time |
| Designer asks for shadows that wreck FPS on Android | Implement and ship laggy | Show benchmarks; propose alternative (border, bg layering); document in design system |
| PM wants animation that breaks reduce-motion | "Sure" | Add a11y note to ticket; ship with reduce-motion fallback |
| Inconsistent spacing across screens | Eyeball + ship | Build spacing tokens; lint hardcoded values via custom ESLint rule |

**Questions they will ask**:
- "How do you keep design and engineering in sync?" → Token pipeline + Storybook + design reviews.
- "Show me your Storybook for one component." → Have a public repo link.
- "How do you handle dark mode / theming?" → Token palette per scheme, no hardcoded hex outside tokens.
- "How do you ensure visual consistency across 6 engineers?" → Design system + Storybook + visual regression (Chromatic or Loki).

**Visual regression** (lead-level — most candidates miss this):
```js
// loki.config.js
module.exports = {
  configurations: {
    'ios.iphone15': { target: 'ios.simulator', deviceName: 'iPhone 15', preset: 'iPhone 15' },
  },
};
// scripts: "loki test" in CI; fails PR on diff.
```

**Score 5/5 if you can**:
- Show a working `tokens.ts` generated from Figma.
- Show a Storybook with at least one primitive (Button) + 3+ variants + dark mode.
- Show a visual regression run in CI on a PR.

---

### Track 3 — Platform Engineering (Native / Debugging / Performance / Security)

**The bar**:
- Reads native crash logs and symbolicates without help.
- Writes Swift + Kotlin TurboModules.
- Owns startup, FPS, memory, ANR — with budgets in CI.
- Owns mobile security: Keychain/Keystore, OAuth PKCE, cert pinning, MASVS L2.

**Already covered**: G.9, G.11, G.12, G.13, G.18, H.3, H.4.

**Gap-fill — Performance budgets in CI**:
```yaml
# .github/workflows/perf-gate.yml
- name: Cold start budget
  run: node scripts/perf-gate.js --metric cold_start --max 1800 --baseline main
- name: Bundle size budget
  run: node scripts/perf-gate.js --metric bundle_kb --max 2400
```
The script pulls metrics from a measurement run (e.g., `react-native-performance` + Detox run on a controlled device farm) and exits non-zero on regression > threshold.

**Gap-fill — Frame drop instrumentation (Reanimated 3)**:
```ts
import { runOnJS, useFrameCallback } from 'react-native-reanimated';

const droppedFrames = useSharedValue(0);
useFrameCallback(({ timeSincePreviousFrame }) => {
  'worklet';
  if (timeSincePreviousFrame && timeSincePreviousFrame > 18) {
    droppedFrames.value += 1;
    runOnJS(reportFrameDrop)(timeSincePreviousFrame);
  }
});
```

**Gap-fill — RASP (runtime app self-protection) for fintech**:
```ts
import JailMonkey from 'jail-monkey';
if (JailMonkey.isJailBroken() || JailMonkey.canMockLocation() || JailMonkey.isDebuggedMode()) {
  blockAndNotify();
}
```
Pair with: cert pinning (G.18), screenshot prevention (`FLAG_SECURE` Android, blur on background iOS), root/jailbreak escalation policy, anti-tamper checksum.

**Questions they will ask**:
- "Walk me through symbolicating an iOS Hermes crash." → G.13 CLI + dSYM + Hermes sourcemap.
- "How do you detect a memory leak in production, not just locally?" → Sentry release health → memory percentile alerts → reproduce via heap snapshot.
- "When would you bypass RN and write native?" → Latency-critical (camera, BLE), large-data (file processing), platform-only API.

**Score 5/5 if you can**:
- Ship the Swift + Kotlin TurboModule from G.12 to a real app.
- Show a perf budget gate in a public CI run.
- Walk through a real production crash you symbolicated.

---

### Track 4 — Architecture Engineering (System Design / Scaling / Offline-first)

**The bar**:
- Can design a mobile system end-to-end in 45 min on a whiteboard.
- Writes ADRs (H.5) before big decisions, not after.
- Knows when to modularize, when to monorepo, when to microfrontend (server-driven UI).
- Designs offline-first by default for fintech / consumer.

**Already covered**: G.15, G.22, H.5.

**Gap-fill — Modularization patterns**:
- **Feature-first**: `features/portfolio/{ui,domain,data}` — best for product apps.
- **Layer-first**: `data/`, `domain/`, `ui/` — best for libraries / shared kernels.
- **Hybrid (recommended for lead-scale RN)**:
```
apps/
  consumer/
  internal/
packages/
  ui/          # design system + primitives (Track 2)
  features/
    auth/
    payments/
    portfolio/
  data/        # api clients, schemas, react-query keys
  native/      # turbo modules
  config/      # eslint, tsconfig, metro
```

**Gap-fill — Server-Driven UI (SDUI, used at Swiggy/CRED scale)**:
```ts
// server returns:
type Component = { type: 'card' | 'list' | 'cta'; props: any; children?: Component[] };

const registry = {
  card: Card,
  list: List,
  cta: CTAButton,
} as const;

function Render({ node }: { node: Component }) {
  const C = registry[node.type] as React.ComponentType<any>;
  if (!C) return null;
  return <C {...node.props}>{node.children?.map((c, i) => <Render key={i} node={c}/>)}</C>;
}
```
**Trade-off**: ship UI without store release; cost: every component must be in registry (security boundary), can't use arbitrary code from server.

**Gap-fill — Multi-app monorepo (turbo + pnpm)**:
```json
// turbo.json
{
  "tasks": {
    "build":   { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "test":    { "dependsOn": ["^build"], "outputs": [] },
    "lint":    { "outputs": [] },
    "typecheck": { "dependsOn": ["^build"] }
  }
}
```
Real benefit: shared `packages/ui` ships to 2 apps; shared `packages/features/auth` means one team owns auth across both.

**Questions they will ask**:
- "Design WhatsApp message sync." → G.22 design 2 expanded.
- "How would you structure a 6-app monorepo for a fintech?" → Hybrid above + ADR for boundaries.
- "When would you NOT do offline-first?" → Real-time-only data (live trading book), regulatory (some KYC steps require online attestation).
- "How do you roll out a new SDK across 3 apps?" → Shared package + version pinning + canary app first.

**Score 5/5 if you can**:
- Whiteboard offline-first fintech in 45 min including outbox, conflict policy, and security boundaries.
- Show 3+ ADRs you've written.
- Explain a real modularization migration with before/after structure and what broke.

---

### Track 5 — Production Engineering (Releases / Monitoring / Incidents)

**The bar**:
- Owns the release: signing, store policy, OTA gating, rollback in <10 min.
- Owns observability: Sentry, structured logs, perf traces, alerting.
- Runs incidents calmly: detect → mitigate → communicate → post-mortem.
- Has an on-call rotation and a runbook per incident class.

**Already covered**: G.20, G.21, G.24 (S1–S12).

**Gap-fill — Release readiness checklist** (steal this for every release):
```
[ ] Crashlytics/Sentry rate baseline captured for previous release
[ ] All P0/P1 bugs from previous release closed or knowingly accepted
[ ] Native version bumped (build number = unique)
[ ] Sourcemaps + dSYMs uploaded
[ ] Privacy manifest updated (iOS PrivacyInfo.xcprivacy)
[ ] App Privacy section updated in App Store Connect (data collection)
[ ] Release notes drafted (user-facing + internal)
[ ] Feature flags set for new features (default OFF, enable post-rollout)
[ ] Backend dependencies deployed first
[ ] Staged rollout configured (10/50/100)
[ ] On-call notified, runbook linked
[ ] Rollback plan documented
```

**Gap-fill — Incident runbook template**:
```markdown
# Runbook: Payment failure spike
## Detect
- Sentry alert: `payment_failed` rate > 5% for 5 min
- Pager: payments-oncall

## Triage (≤5 min)
1. Check Sentry → which release / device / API endpoint
2. Check backend status page
3. Check FCM/APNs status

## Mitigate (≤15 min)
- If client bug → roll back OTA channel: `eas update --branch production --message "rollback to <sha>"`
- If backend → flip feature flag `payments_enabled=false`, show maintenance UI
- If 3rd party (Razorpay) → switch to Cashfree fallback

## Communicate
- #incident-payments channel: post template (severity, scope, mitigation, ETA)
- Status page update if user-visible >5 min

## Post-mortem (≤48h)
- Blameless template: timeline, root cause, contributing factors, action items with owners + dates
```

**Gap-fill — SLOs (Service Level Objectives) for mobile**:
| SLO | Target | Source |
|---|---|---|
| Crash-free sessions | ≥ 99.7% | Sentry / Crashlytics |
| ANR-free sessions (Android) | ≥ 99.5% | Play vitals |
| Cold start P95 | ≤ 2.0s | RN performance + farm |
| API success rate | ≥ 99.5% | Sentry traces |
| OTA rollout time-to-50% | ≤ 24h | EAS metrics |

When an SLO burns 50% of its monthly error budget, you stop shipping features and fix.

**Gap-fill — Feature flags (LaunchDarkly / GrowthBook / homegrown)**:
```ts
const enabled = useFlag('new_checkout_v2', { default: false });
return enabled ? <CheckoutV2/> : <CheckoutV1/>;
```
Pattern: every new feature behind a flag; default OFF; enable to internal → 1% → 10% → 50% → 100% with metric checks at each step.

**Questions they will ask**:
- "Walk me through the worst incident you handled." → STAR story #4.
- "How do you decide between OTA vs binary release for a fix?" → OTA for JS-only + low-risk; binary for native or schema migration; both with staged rollout.
- "What does your on-call week look like?" → Pager rotation, runbook usage, follow-up actions.

**Score 5/5 if you can**:
- Show a real post-mortem you wrote (sanitize names).
- Show a runbook for a real incident class.
- Quote your team's SLOs and current error budget.

---

### Track 6 — Leadership Engineering (Team / Process / Mentoring)

**The bar**:
- Grows the engineers under you (Track Mentee → Mid → Senior).
- Owns delivery without micromanaging.
- Writes RFCs, runs reviews, drives consensus.
- Says no to PMs with data, not opinions.
- Hires (designs interview loops, gives clear feedback).

**Already covered**: Section 23, Appendix E (10 STAR stories).

**Gap-fill — RFC template** (use this for any decision spanning >1 sprint or >1 engineer):
```markdown
# RFC-NNN: <Title>
Author: <name> · Reviewers: <list> · Status: Draft / Review / Accepted / Rejected
Date: YYYY-MM-DD

## Problem
What hurts today, with evidence.

## Proposal
The change in 3 sentences. Then sections:
- Scope (in / out)
- API / data model changes
- Migration plan
- Rollout plan
- Observability plan

## Alternatives considered
For each: pros, cons, why rejected.

## Open questions
List explicit Qs needing reviewer input.

## Decision log
Append after review.
```

**Gap-fill — Growth ladder (mobile)**:
| Level | Scope | Signals you look for when promoting |
|---|---|---|
| Mid (E3) | Owns features end-to-end | Reliable delivery, asks good questions, writes tests by default |
| Senior (E4) | Owns systems / domains | Reduces complexity, mentors mids, runs incident response |
| Lead (E5) | Owns multi-team outcomes | RFCs, hiring, cross-team unblocking, defines standards |
| Staff (E6) | Owns engineering strategy | Multi-quarter roadmap, sets technical direction org-wide |
| Architect / Principal (E7) | Owns multi-org technical bets | Influences without managing, depth + breadth |

**Gap-fill — 1:1 framework** (weekly, 30 min):
```
[5 min] Personal check-in (energy, blockers outside work)
[10 min] Their agenda (let them drive)
[10 min] Your agenda (feedback, context, growth)
[5 min]  Action items + owners (you write them down, send after)
```
Anti-pattern: status updates. That's what standup is for.

**Gap-fill — Code review etiquette (lead version)**:
- **Comment levels**: prefix with `nit:`, `suggestion:`, `question:`, `must-fix:`. Only `must-fix` blocks merge.
- **Praise the good parts** — esp. for juniors; reviews are 50% teaching.
- **Pull big changes into a chat or pairing session**; don't do design via PR comments.
- **Time-box**: respond within 1 working day or hand off explicitly.
- **Approve with caveats** rather than block when the author can self-correct.

**Gap-fill — Saying no to PM (script)**:
> "I want to ship this — and to ship it well, I need to flag two risks. **Risk 1**: <specific tech risk with data>. **Risk 2**: <delivery risk>. Here are 3 options:
> (a) Ship as designed in 4 weeks with risks A, B accepted.
> (b) Ship reduced scope in 2 weeks, follow-up in next sprint.
> (c) Spike for 3 days first, then commit.
> I'd recommend (b) because <reason>. What's your call?"
This gives PM agency, makes you look like a lead, and creates a written trade-off record.

**Gap-fill — Hiring loop you'd run for an RN senior**:
1. Recruiter screen (15 min).
2. Coding (60 min, easy-medium DSA + 1 RN concept).
3. RN deep-dive (60 min, JSI/Fabric, perf, native modules).
4. System design (60 min, mobile system).
5. Behavioral / leadership (45 min, STAR + scenario).
6. Hiring manager close (30 min, role + comp).
**Calibration**: every interviewer files written feedback in a shared rubric (Strong Hire / Hire / No Hire / Strong No Hire) **before** seeing others' notes. Hiring committee makes the call.

**Questions they will ask**:
- "Tell me about an engineer you grew." → STAR #6.
- "Tell me about a time you disagreed with your manager." → STAR #3 or #9 framing.
- "How do you give feedback to a senior peer who's underperforming?" → Direct, in 1:1, specific, behavior-not-character, with a check-in cadence.
- "What's your interview rubric for a senior RN hire?" → The loop above + signals per round.

**Score 5/5 if you can**:
- Show 2+ RFCs you authored.
- Show feedback you wrote for a promotion case (sanitize).
- Show 3+ engineers whose growth you owned.

---

### Self-assessment scorecard (fill this before applying)

| Track | Bar | Your score (1–5) | Top 1 gap | Action this week |
|---|---|---|---|---|
| Core | Fluent JS/TS/React/RN deep | __ | | |
| Product | Figma → tokens → Storybook → app | __ | | |
| Platform | Native + perf + security | __ | | |
| Architecture | System design + ADRs + offline | __ | | |
| Production | Releases + SLOs + incidents | __ | | |
| Leadership | RFCs + mentoring + hiring | __ | | |

**Lead-role readiness**: aim for ≥4 in Core + Platform + Architecture, ≥3 in the other three. Anything 5/5 becomes a STAR story.
**Architect readiness**: ≥4 across all six.

---

### Track ↔ company emphasis (where they probe hardest)

| Company | Heaviest tracks |
|---|---|
| PhonePe | Platform (security, perf), Architecture (offline payments), Production (reliability) |
| CRED | Product (UI/UX/motion), Core (Reanimated, Skia), Platform (FPS) |
| Razorpay | Platform (security), Architecture (idempotency), Core (TS depth) |
| Groww / Zerodha | Architecture (realtime + offline), Platform (perf), Production (zero-downtime) |
| Swiggy / Zomato | Architecture (SDUI), Production (release velocity), Platform (low-end Android) |
| Flipkart / Meesho | Platform (perf, low-end Android), Architecture (modular monorepo), Production (release scale) |
| Microsoft / Atlassian | Core (RN platform depth), Architecture (multi-app monorepo), Leadership (RFCs, process) |
| Walmart Global | Core, Architecture, Production |
| Dream11 | Platform (perf at scale), Production (incidents on match days), Architecture (realtime) |

---

This six-track model is also the structure for your **resume**: every bullet should map to one of the six tracks, and across the whole resume you should have at least 2 strong bullets per track.

---

