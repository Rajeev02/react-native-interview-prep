# S29 — Cross-Target React Native

> RN Web vs Next.js · visionOS spatial · tvOS / Android TV · platform extensions · code-sharing strategy

RN runs beyond phones: web, TV, vision, embedded. Senior engineers know when to share code and when not to.

## Topics in this section

- [Q1. RN Web vs Next.js — when to choose](#q1-rn-web-vs-nextjs--when-to-choose)
- [Q2. RN visionOS — spatial UI considerations](#q2-rn-visionos--spatial-ui-considerations)
- [Q3. tvOS / Android TV — focus management](#q3-tvos--android-tv--focus-management)
- [Q4. Platform extensions strategy (.ios.tsx / .android.tsx / .web.tsx)](#q4-platform-extensions-strategy-iostsx--androidtsx--webtsx)
- [Q5. Code-sharing — single codebase vs platform packages](#q5-code-sharing--single-codebase-vs-platform-packages)

---

## Q1. RN Web vs Next.js — when to choose

### Difficulty
Advanced

### Interview Frequency
Common at companies with web + mobile.

### Prerequisites
RN basics; web fundamentals.

### TL;DR
**RN Web** when you need a unified mobile + web codebase with mobile-first UX. **Next.js** for web-first products needing SEO, SSR, complex routing. Hybrid: Next.js for marketing, RN+RN Web for app shell.

### 30-Second Interview Answer
"RN Web for unified mobile+web codebase where mobile is primary and web is secondary (e.g., Discord, Twitter). Next.js for web-first with SEO/SSR/SSG needs (marketing, dashboards). Hybrid: Next.js for marketing/blog (SEO), RN/RN Web for the authenticated app. The pivot: 'is web a first-class product or a sibling to mobile?'"

### 2-Minute Practical Answer
RN Web strengths:
- Unified codebase (one team, one design system).
- Components reused across platforms.
- Animations via Reanimated work.
- Native primitives map to DOM.

RN Web weaknesses:
- No SSR / SSG out of the box (Expo Router has experimental).
- SEO weaker than Next.js.
- Bundle size larger than native React.
- DOM debug story not as good as native React.

Next.js strengths:
- SSR / SSG / ISR for SEO + performance.
- App Router with React Server Components.
- Better web ecosystem (Tailwind, shadcn).
- DOM-native debug.

Next.js weaknesses:
- Mobile reuse: zero (need separate RN app).
- Two codebases = two teams or split focus.

Hybrid pattern:
- Marketing site + blog: Next.js (SEO matters).
- Authenticated app: RN + RN Web (single team).
- Login/payment flows in Next.js (SSR for security).

For 2026:
- Expo Router unifies routing across iOS/Android/Web.
- React Server Components in RN (experimental).
- Choose by team size + product surface area, not religion.

### 5-Minute Architecture Answer
The decision is rarely "either/or" — it's about boundaries:
- **Brand site / marketing**: Next.js (SEO, conversion-critical).
- **Onboarding flow with deep links**: Next.js + RN universal links.
- **Authenticated dashboard / app**: depends on team + product.
  - 1 team, mobile-first → RN + RN Web.
  - Separate web team → React + Next.js.

When RN Web wins:
- Primary product is mobile; web is companion.
- Single team for product velocity.
- Heavy use of mobile-native UX (gestures, animations).
- B2C with both app + web users.

When Next.js wins:
- Web is primary product surface.
- SEO / public content is critical.
- Complex web-only features (admin dashboards, file uploads).
- Separate web team.

When hybrid wins:
- Large company with both surfaces.
- Marketing/blog → Next.js.
- Authenticated app → RN + RN Web.
- Shared component library (theme, primitives).

For 2026:
- Solito (Next.js + RN) bridges some of this.
- Expo Router for Web maturing.
- React Server Components changing the game (SSR + reactive).

Anti-patterns:
- Forcing RN Web for SEO-critical marketing.
- Forcing Next.js for mobile-first product (no mobile reuse).
- Splitting team prematurely.

### The "Why"
Unified codebase = velocity; right tool = right experience.

### Mental Model
RN Web = mobile-first universal; Next.js = web-first universal. Pick by product center.

### Internal Working (2026 Context)
- RN Web maps `<View>` to `<div>`, `<Text>` to `<span>`.
- Expo Router supports web with file-system routing.
- Next.js App Router with RSC default.

### Modern Implementation (Code)
RN Web minimal (Expo Router):
```tsx
// app/index.tsx — works on iOS, Android, Web
import { View, Text, Pressable } from 'react-native';
import { Link } from 'expo-router';

export default function Home() {
  return (
    <View style={{ padding: 16 }}>
      <Text>Welcome</Text>
      <Link href="/feed" asChild>
        <Pressable accessibilityRole="link"><Text>Open feed</Text></Pressable>
      </Link>
    </View>
  );
}
```

Next.js + RN code-sharing via Solito:
```tsx
// packages/app/features/home/screen.tsx — shared
import { Pressable, View, Text } from 'react-native';
import { Link } from 'solito/link';

export function HomeScreen() {
  return (
    <View>
      <Text>Hello</Text>
      <Link href="/feed"><Text>Feed</Text></Link>
    </View>
  );
}

// apps/next/pages/index.tsx
export { HomeScreen as default } from 'app/features/home/screen';
// apps/expo/app/index.tsx
export { HomeScreen as default } from 'app/features/home/screen';
```

### Comparison

| Need | Pick |
|---|---|
| SEO / SSG | Next.js |
| Mobile-first product | RN + RN Web |
| Both surfaces, 1 team | RN Web (or Solito) |
| Both, 2 teams | Both, share design system |
| Mostly web, light mobile | Next.js + thin RN |

### Production Usage
- Twitter, Discord, Shopify Shop: heavy RN Web.
- Vercel, Linear: Next.js dominant.
- Many startups: hybrid.

### Hands-On Exercise
Build the same simple form in both; compare DX, bundle size, perf.

### Common Mistakes
- SEO-critical content in RN Web.
- Forcing mobile-first into Next.js.
- Two separate teams with no shared design system.

### Production Red Flags
- Marketing in RN Web with poor SEO.
- Mobile app rebuilt from scratch instead of RN Web.
- No shared design tokens.

### Performance & Metrics
- LCP (Largest Contentful Paint).
- TTI (Time to Interactive).
- SEO ranks.
- Bundle size.

### Decision Framework
- Mobile-first → RN Web.
- Web-first / SEO → Next.js.
- Both → hybrid (marketing Next, app RN Web).

### Senior-Level Insight
"This decision is more about team structure + product surface than tech. Architect for the org you have, not the tech you love."

### Real-World Scenario
Startup chose RN Web for marketing site; SEO collapsed; lost 60% organic traffic; migrated marketing to Next.js.
**Lesson:** Marketing has different requirements than app.

### Production Failure Story
Team built duplicate app + web in React Native and Vue; 2× engineering cost; design drift.
**Fix:** Migrated to RN + RN Web monorepo; saved 40% effort over 18mo.

### Debugging Checklist
1. SEO requirements clear?
2. Team structure aligned with code-share?
3. Shared design tokens?
4. Bundle size budgets?

### Advanced / Internal Knowledge
- Solito bridges RN + Next.js.
- React Server Components experimental in RN.
- Expo Router web supports SSR (limited).

### 2026 AI Tip
AI helps generate platform-specific variants from shared components.

### Related Topics
Q4, Q5.

### Interview Follow-Up Questions
- "When does RN Web fail?"
- "How do you handle SEO with RN Web?"
- "Solito vs DIY?"

### Memory Hook
**"Mobile-first → RN Web. Web-first → Next.js. Both → hybrid by surface."**

### Revision Notes
> RN Web for unified mobile-first + web; Next.js for SEO + web-primary; hybrid for both surfaces; Solito or Expo Router for sharing; choose by team + product center.

---

## Q2. RN visionOS — spatial UI considerations

### Difficulty
Advanced

### Interview Frequency
Emerging.

### Prerequisites
RN; some 3D / spatial concepts.

### TL;DR
RN visionOS port (community + Meta) supports basic UI on Apple Vision Pro. Spatial considerations: depth, hover states, gaze tracking, immersive vs windowed. Don't port phone UI 1:1; design for spatial interaction.

### 30-Second Interview Answer
"RN visionOS lets you reuse RN code on Apple Vision Pro. Key considerations: spatial UI (windows in 3D space), gaze + pinch input model (no touch), hover states, depth (front vs back panes), and immersive vs windowed mode. Don't port phone UIs literally; redesign for hand + gaze. Native SwiftUI for spatial-heavy features."

### 2-Minute Practical Answer
What works in RN visionOS today (2026):
- Standard RN components (`View`, `Text`, `Image`).
- Reanimated.
- React Navigation (windowed).
- Most Expo modules.

What needs spatial-aware redesign:
- Hover states (gaze-driven).
- Depth (z-axis).
- Hand gestures (pinch, tap).
- Immersive scenes (RealityKit / SwiftUI).

Apple Vision Pro input model:
- Gaze = pointer.
- Pinch = tap.
- Voice = optional input.
- No touch screen; no keyboard (mostly).

UI patterns:
- Larger touch targets (gaze imprecision).
- Subtle hover feedback (highlights on gaze).
- Spatial audio cues.
- Shared spaces with multiple windows.

For deeply spatial features (3D, AR, immersive):
- Drop to SwiftUI / RealityKit.
- Bridge via TurboModule.
- Don't shoehorn into RN.

For 2026:
- RN visionOS port active but lagging RN core.
- Most apps: ship windowed (familiar UX) first; immersive later.
- Apple Vision Pro install base small; ROI questionable for some products.

### 5-Minute Architecture Answer
visionOS support is a strategic decision:
- Apple Vision Pro install base small (< 1M as of 2025).
- B2B + media apps see better ROI than consumer.
- RN visionOS works for basic UI; not for immersive.

Hybrid architecture:
- RN for windowed app UI (settings, lists, controls).
- SwiftUI / RealityKit for immersive 3D scenes.
- TurboModule bridge for state sync.

Design considerations:
- **Windowed mode** — familiar; reuse RN.
- **Shared space** — multiple windows; users arrange.
- **Full space** — immersive; needs RealityKit.
- **Mixed reality** — passthrough + virtual; visionOS-specific.

UI specifics:
- Material backgrounds (translucent).
- Glass effects.
- 3D animation cautious (motion sickness).
- Dynamic type matters (people resize windows + text).

Performance:
- Vision Pro M2 chip; fast but battery-constrained.
- Frame budget tighter than phone (90 Hz target).
- Heavy compute = battery drain + heat.

For 2026:
- React Native visionOS port maturing.
- Expo support partial.
- Most teams: monitor adoption before investing.

When RN visionOS makes sense:
- Existing RN app + visionOS users requested.
- B2B with corporate Vision Pro deployment.
- Media + entertainment with immersive plans.

When to skip:
- Consumer app with low Vision Pro user overlap.
- Heavy 3D requirements (use Unity / Unreal).

### The "Why"
Don't waste cycles on platforms without ROI; but be ready when one emerges.

### Mental Model
visionOS = new spatial canvas; reuse RN where possible, native where spatial-critical.

### Internal Working (2026 Context)
- React Native visionOS at https://github.com/callstack/react-native-visionos.
- Bridges to UIKit / SwiftUI as needed.
- Expo support adding gradually.

### Modern Implementation (Code)
Same RN code, runs on Vision Pro:
```tsx
import { View, Text } from 'react-native';
export default function Home() {
  return (
    <View style={{ padding: 24 }}>
      <Text style={{ fontSize: 28 }}>Welcome</Text>
    </View>
  );
}
```

Spatial-specific via native module:
```ts
// SpatialModule.ts (TurboModule)
export interface Spec extends TurboModule {
  openImmersiveScene(sceneId: string): void;
}
```

### Comparison

| Platform | Maturity (2026) | Use case |
|---|---|---|
| iOS | Mature | All RN apps |
| Android | Mature | All RN apps |
| Web | Mature | Universal app |
| visionOS | Emerging | Selective |
| tvOS / AndroidTV | Stable | Media apps |

### Production Usage
- Few RN apps in visionOS production today.
- Test deployments common.

### Hands-On Exercise
Run RN visionOS sample app on simulator; explore primitives.

### Common Mistakes
- Porting phone UI 1:1 to spatial.
- Ignoring hover states.
- Heavy animation causing motion sickness.

### Production Red Flags
- visionOS app with phone-sized buttons.
- No hover feedback.
- Forced immersive when windowed suffices.

### Performance & Metrics
- 90 Hz frame target.
- Battery use.
- Comfort (user feedback on motion).

### Decision Framework
- Existing RN app + user demand → port.
- Immersive 3D core → SwiftUI/RealityKit.
- Speculative → monitor.

### Senior-Level Insight
"Spatial computing isn't just bigger screens; it's a new interaction paradigm. Don't waste cycles unless your users are there."

### Real-World Scenario
B2B SaaS ported dashboard to visionOS for executive demos; reused 80% RN code; took 2 weeks.

### Production Failure Story
Team ported consumer app to visionOS; users found UI overwhelming; uninstalled.
**Fix:** Redesigned for windowed-first; immersive only for specific scenes.

### Debugging Checklist
1. Windowed mode working?
2. Hover states implemented?
3. Touch targets large?
4. No motion sickness in heavy animations?

### Advanced / Internal Knowledge
- RealityKit vs SceneKit for 3D.
- Persistent anchors in mixed reality.
- Shared experiences (multi-user).

### 2026 AI Tip
AI helps generate spatial UI variants but lacks visionOS depth; verify with native dev.

### Related Topics
Q3, Q4.

### Interview Follow-Up Questions
- "When would you port to visionOS?"
- "What's different about spatial UX?"
- "When do you bail to SwiftUI?"

### Memory Hook
**"Windowed first. Spatial-aware. Hover + gaze. SwiftUI for immersive."**

### Revision Notes
> RN visionOS supports windowed UI; design for gaze + pinch; hover states; depth; immersive needs RealityKit / SwiftUI; ROI selective; B2B + media first.

---

## Q3. tvOS / Android TV — focus management

### Difficulty
Advanced

### Interview Frequency
Common at media / streaming companies.

### Prerequisites
RN; remote-control input.

### TL;DR
TV UIs are remote-driven (D-pad). Focus management is the challenge: visible focus rings, predictable navigation, no orphan focusable items. RN-tvos and react-native-tv libraries help.

### 30-Second Interview Answer
"TV apps are navigated by remote (D-pad), not touch. Critical: focus rings always visible, predictable up/down/left/right movement, no focus traps, large hit targets, scaling on focus. Use react-native-tvos fork or community libraries for focus engine; design grids that work with directional nav; test on real Apple TV / Fire TV."

### 2-Minute Practical Answer
TV UI principles:
1. **Focus must be visible** — scale, glow, or border on focused item.
2. **Predictable navigation** — D-pad up/down/left/right moves to expected neighbor.
3. **No orphans** — every focusable item reachable from any starting point.
4. **Large targets** — accommodate 10-foot viewing distance.
5. **Hover-like feedback** — focused state distinct.

RN TV ecosystem:
- **react-native-tvos** — fork supporting Apple TV.
- **react-native-tv-pages** — focus management library.
- **react-native-amazon-fire-tv** — Fire TV-specific.

Components:
- `TouchableHighlight` / `Pressable` with `hasTVPreferredFocus` and `tvParallaxProperties`.
- Custom focus engine for grids (LRU memory of focus position per row).

UX patterns:
- Hero carousel + content rows.
- Focus follows D-pad; row remembers last focused column.
- Long-press for menu.
- Accessibility (large text, reduced motion).

For 2026:
- Apple TV + Fire TV biggest markets.
- Roku has its own SDK (not RN).
- Smart TVs (LG, Samsung) via Android TV.

### 5-Minute Architecture Answer
TV apps are a niche but valuable RN target:
- Streaming platforms (Netflix, Disney+) have native TV teams.
- Smaller media apps benefit from RN code reuse.

Architecture:
- Shared state / data layer with mobile.
- TV-specific UI (grids, hero, focus).
- Platform extensions (`.ios.tv.tsx`, `.android.tv.tsx`).
- Custom focus engine (or use library).

Focus engine design:
- Tree of focusable nodes.
- D-pad input → next node based on geometry + parent context.
- Memoize last focused column per row.
- Handle dynamic content (rows loading async).

Performance:
- TVs underpowered (Apple TV better than most Android TVs).
- FlashList critical for content rows.
- Image preloading for adjacent items.
- 60 fps target; fallback gracefully.

Testing:
- Real device essential (sim doesn't capture remote latency).
- Test with screen reader (VoiceOver on tvOS).
- Test with Bluetooth keyboard fallback.

For 2026:
- Smart TV market growing in India / SEA.
- RN TV less mature than mobile; expect rough edges.
- Some companies use Lottie heavily for TV animations.

### The "Why"
TV is a different input model; phone UI fails immediately.

### Mental Model
TV = remote-driven grid with focus rings; phone = touch-driven gestures.

### Internal Working (2026 Context)
- react-native-tvos fork tracks RN core.
- Focus engine handles D-pad → focusable map.

### Modern Implementation (Code)
Focus-aware Pressable:
```tsx
import { Pressable } from 'react-native';
import { useState } from 'react';

function TVCard({ title, onPress }: Props) {
  const [focused, setFocused] = useState(false);
  return (
    <Pressable
      onPress={onPress}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      hasTVPreferredFocus={false}
      style={[
        styles.card,
        focused && styles.cardFocused,
      ]}
    >
      <Text>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { padding: 16 },
  cardFocused: { transform: [{ scale: 1.1 }], borderColor: 'white', borderWidth: 2 },
});
```

### Comparison

| Platform | Engine | Notes |
|---|---|---|
| Apple TV | tvOS focus engine | Built-in via react-native-tvos |
| Fire TV | Android TV (Fire OS) | Same as Android TV |
| Android TV | Android focus | react-native-tvos |
| Roku | BrightScript | Not RN |

### Production Usage
- Disney+, HBO Max have RN-adjacent TV apps.
- Many small media RN apps work on Apple TV.

### Hands-On Exercise
Build content row + hero carousel with focus rings; test on real Apple TV.

### Common Mistakes
- Phone UI ported without focus rings.
- Orphan focusable items.
- Too small text / targets.
- No remember-last-focused-column.

### Production Red Flags
- "Use mobile UI on TV; users will figure it out."
- No focus indicator.
- Heavy gestures (TV has no swipe).

### Performance & Metrics
- Frame rate (60 target).
- Time to focus on content load.
- Remote responsiveness (< 100ms feedback).

### Decision Framework
- Streaming / media → invest in TV.
- Productivity / B2C → likely skip.
- B2B in conference room → maybe (Apple TV).

### Senior-Level Insight
"TV interfaces fail when designers think of them as 'big phones.' They're closer to console UIs: focus-driven, predictable, forgiving."

### Real-World Scenario
Media startup ported mobile RN app to Apple TV; 60% code reuse; focus engine custom-built; launched in 6 weeks.

### Production Failure Story
Team shipped TV app with mobile-style buttons; users couldn't navigate; review bombed.
**Fix:** Rebuilt with focus rings + scaled focus state; ratings recovered.

### Debugging Checklist
1. Focus rings visible on every focusable?
2. D-pad navigation predictable?
3. No focus traps?
4. Tested on real device?
5. Targets large enough?

### Advanced / Internal Knowledge
- TVPreferredFocus + screen-level focus restoration.
- Keyboard accessibility (some users use BT keyboard).
- Voice control via Siri Remote.

### 2026 AI Tip
AI weak on TV-specific patterns; rely on docs + native devs.

### Related Topics
Q4, S19.

### Interview Follow-Up Questions
- "How do you handle dynamic content with focus?"
- "What's a focus trap?"
- "When is RN not the right tool for TV?"

### Memory Hook
**"Focus rings always. D-pad predictable. No orphans. Real device test."**

### Revision Notes
> TV = remote-driven; focus rings + predictable nav critical; react-native-tvos for Apple TV / Android TV; custom focus engine for grids; performance budget tight; real-device testing essential.

---

## Q4. Platform extensions strategy (.ios.tsx / .android.tsx / .web.tsx)

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common.

### Prerequisites
RN basics.

### TL;DR
Use platform extensions when component diverges by platform > 30%. Common patterns: shared API + platform impl files, or single file with `Platform.select`. Keep test surface narrow.

### 30-Second Interview Answer
"Platform extensions like `.ios.tsx` / `.android.tsx` / `.web.tsx` resolve at bundle time. Use them when implementations diverge significantly (e.g., date picker, file picker). For minor differences, `Platform.OS` / `Platform.select` inline. Rule: extract platform file when divergence > 30% or when types differ. Tests cover the public API on each platform."

### 2-Minute Practical Answer
Three patterns:

**1. Inline Platform.select** — small differences:
```tsx
const styles = StyleSheet.create({
  shadow: Platform.select({
    ios: { shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 4 },
    android: { elevation: 4 },
    default: { boxShadow: '0 2px 4px rgba(0,0,0,0.2)' },
  }),
});
```

**2. Platform extensions** — large divergence:
```
src/components/DatePicker/
  index.ts               // re-exports
  DatePicker.types.ts    // shared types
  DatePicker.ios.tsx     // UIDatePicker wrapper
  DatePicker.android.tsx // Material picker wrapper
  DatePicker.web.tsx     // <input type="date">
```

**3. Conditional require** — rare:
```ts
const Picker = Platform.OS === 'web' ? require('./web') : require('./native');
```

When to use each:
- Style differences → inline.
- Component implementation differences → extension files.
- Native module gating → require.

For 2026:
- Expo Router auto-resolves platform extensions.
- TS + bundler resolve `.ios.tsx` first if present.
- Tests via Jest with `testEnvironment` per platform.

### 5-Minute Architecture Answer
Platform-specific code is unavoidable in RN. Strategy:
- **Shared API** — same prop interface on every platform.
- **Platform impl** — file per platform when divergence is large.
- **Single source of types** — `.types.ts` shared.
- **Re-export barrel** — `index.ts` re-exports default.

Naming convention:
```
Component/
  index.ts                      // export { default } from './Component';
  Component.types.ts            // shared types
  Component.ios.tsx             // iOS-specific
  Component.android.tsx         // Android-specific
  Component.web.tsx             // Web-specific
  Component.tsx                 // fallback (optional)
  Component.test.ts             // public API tests
```

Bundler resolution (Metro / Webpack):
- iOS build: `.ios.tsx` > `.native.tsx` > `.tsx`.
- Android: `.android.tsx` > `.native.tsx` > `.tsx`.
- Web: `.web.tsx` > `.tsx`.

When to extract:
- Implementation diverges significantly (different libraries).
- Types diverge.
- Performance-critical code path differs.

When NOT to extract:
- Style differences only → inline.
- Single conditional → `Platform.OS`.
- < 20 lines of platform code → inline.

For 2026:
- Tree-shaking works across platforms (other platforms not bundled).
- Bundle size benefits from extraction.
- Code splitting per platform increasingly automatic.

Anti-patterns:
- Same logic duplicated in every platform file.
- Excessive `if (Platform.OS === ...)` chains.
- Platform extension for minor styling.

### The "Why"
Platform code is real; manage it cleanly.

### Mental Model
Same API, different impl per platform. Bundler picks right file.

### Internal Working (2026 Context)
- Metro resolver checks `.{platform}.{ext}` before `.{ext}`.
- Webpack with RN Web has resolveExtensions order.
- TS supports via `paths` + multi-file resolution.

### Modern Implementation (Code)
Shared types + platform impls:

```ts
// DatePicker.types.ts
export interface DatePickerProps {
  value: Date;
  onChange: (date: Date) => void;
  minimum?: Date;
  maximum?: Date;
}
```

```tsx
// DatePicker.ios.tsx
import DateTimePicker from '@react-native-community/datetimepicker';
import { DatePickerProps } from './DatePicker.types';

export default function DatePicker({ value, onChange, minimum, maximum }: DatePickerProps) {
  return (
    <DateTimePicker
      value={value}
      mode="date"
      display="inline"
      minimumDate={minimum}
      maximumDate={maximum}
      onChange={(_e, d) => d && onChange(d)}
    />
  );
}
```

```tsx
// DatePicker.android.tsx — could use a different library
import { DatePickerAndroid } from 'react-native';
// ... Android-specific logic
```

```tsx
// DatePicker.web.tsx
import { DatePickerProps } from './DatePicker.types';

export default function DatePicker({ value, onChange, minimum, maximum }: DatePickerProps) {
  return (
    <input
      type="date"
      value={value.toISOString().slice(0, 10)}
      min={minimum?.toISOString().slice(0, 10)}
      max={maximum?.toISOString().slice(0, 10)}
      onChange={(e) => onChange(new Date(e.target.value))}
    />
  );
}
```

```ts
// index.ts
export { default } from './DatePicker';
export * from './DatePicker.types';
```

### Comparison

| Approach | Best for |
|---|---|
| Inline Platform.select | Style differences |
| Platform extension files | Different implementations |
| Conditional require | Native module gating |

### Production Usage
- Standard pattern in mature RN codebases.

### Hands-On Exercise
Refactor a `Platform.OS`-heavy component into platform extensions.

### Common Mistakes
- Extracting too eagerly (overkill).
- Forgetting to share types.
- Platform-specific tests instead of public API tests.

### Production Red Flags
- 5+ `Platform.OS` checks in one file.
- Type drift between platforms.
- No public API tests.

### Performance & Metrics
- Bundle size per platform.
- Test coverage of public API.

### Decision Framework
- Style only → inline.
- Implementation > 30% different → extension.
- Native module → require.

### Senior-Level Insight
"Platform extensions are about managing API contracts. The job is to keep the public API uniform; the impl can be wildly different per platform."

### Real-World Scenario
Component started inline; grew to 5 Platform.OS checks; refactored to platform extensions; bundle dropped 8KB on web.

### Production Failure Story
Type drift between iOS + Android impls caused runtime crashes.
**Fix:** Single `.types.ts` enforced; TS strict caught further drift.

### Debugging Checklist
1. Public API uniform across platforms?
2. Types shared?
3. Tests cover API contract?
4. Bundle size acceptable?

### Advanced / Internal Knowledge
- `.native.tsx` extension covers iOS + Android (excludes web).
- Metro custom resolvers for monorepo.
- Conditional types per platform via TS.

### 2026 AI Tip
AI struggles with platform extension layout; verify file structure.

### Related Topics
Q1, Q3, Q5.

### Interview Follow-Up Questions
- "When do you avoid platform extensions?"
- "How do you test them?"
- "What's `.native.tsx`?"

### Memory Hook
**"Same API, different impl. Extract when divergence > 30%."**

### Revision Notes
> Platform extensions: `.ios.tsx`, `.android.tsx`, `.web.tsx`, `.native.tsx`; shared types in `.types.ts`; Metro resolves automatically; inline `Platform.select` for small diffs; tests on public API.

---

## Q5. Code-sharing — single codebase vs platform packages

### Difficulty
Advanced

### Interview Frequency
Common at scale.

### Prerequisites
Q4, monorepo basics.

### TL;DR
Single codebase: simpler for small teams. Monorepo with platform packages (apps/ios, apps/android, apps/web): better for scale, separate teams, or independent release cycles. Tools: pnpm workspaces, Turborepo, Nx.

### 30-Second Interview Answer
"Single codebase for small teams (< 5 engineers): one Expo app, platform extensions for divergence. Monorepo with platform packages (apps/expo, apps/next, packages/shared) for larger teams or when web/mobile have separate release cycles. Tools: pnpm workspaces + Turborepo. Solito helps if Next.js + Expo share code. Choose by team size + release cadence, not religion."

### 2-Minute Practical Answer
Two architectures:

**1. Single codebase** (simple):
```
my-app/
  ├── src/
  │   ├── components/
  │   │   ├── Button.ios.tsx
  │   │   ├── Button.android.tsx
  │   │   └── Button.web.tsx
  │   └── screens/
  ├── app/  (Expo Router for all platforms)
  └── package.json
```
- Pros: simple, fast iteration, single deploy pipeline.
- Cons: web bundle size, conflicting dep versions, harder for separate teams.

**2. Monorepo with platform packages**:
```
my-monorepo/
  ├── apps/
  │   ├── expo/        (Expo app: iOS + Android)
  │   ├── next/        (Next.js web)
  │   └── tv/          (Apple TV / Android TV)
  ├── packages/
  │   ├── shared-ui/   (cross-platform components)
  │   ├── shared-data/ (TanStack Query setup)
  │   ├── shared-types/
  │   └── design-tokens/
  ├── turbo.json
  └── pnpm-workspace.yaml
```
- Pros: separate teams, separate release cycles, shared design system, tree-shake unused.
- Cons: tooling complexity, longer setup, version pinning across packages.

For 2026:
- pnpm workspaces standard for monorepos.
- Turborepo for caching + parallel builds.
- Nx for larger orgs with structured generators.
- Solito specifically for Next.js + Expo combo.

### 5-Minute Architecture Answer
This is one of the highest-leverage architectural decisions:
- Wrong choice early → migration pain later.
- Right choice → years of velocity.

When to choose single codebase:
- Team size < 5 engineers.
- Single product on iOS + Android (+ web optional).
- Single release cadence.
- Limited platform divergence.

When to choose monorepo:
- Multiple teams (mobile, web, TV).
- Independent release cycles per platform.
- Significant divergence between platforms.
- Shared design system across products.
- Need tree-shaking per platform.

Monorepo structure tiers:
- **Apps** — deployable artifacts.
- **Packages** — shared libraries (UI, data, types).
- **Tooling** — eslint configs, tsconfig presets.

Key tools (2026):
- **pnpm** — fast, strict, works with workspaces.
- **Turborepo** — task orchestration, remote caching.
- **Nx** — generators, dependency graph, plugins.
- **Solito** — Next.js + Expo bridge.
- **Changesets** — versioning + changelog.

Common pitfalls:
- Premature monorepo (overhead > benefit for small team).
- Shared package with platform-specific code (circular dep).
- No CI per package (slow builds).
- Inconsistent tooling across packages.

For 2026 AI assist:
- AI generates package boilerplate.
- AI helps with import path mapping.

### The "Why"
Architecture decides team velocity for years.

### Mental Model
Monorepo = filing cabinet for code; works only if you keep folders organized.

### Internal Working (2026 Context)
- pnpm hoists carefully (vs npm/yarn flat).
- Turborepo caches based on file hashes + env.
- Metro / Webpack support workspace resolution.

### Modern Implementation (Code)
pnpm workspace setup:
```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "lint": {},
    "test": { "dependsOn": ["^build"] }
  }
}
```

```json
// apps/expo/package.json
{
  "name": "expo-app",
  "dependencies": {
    "shared-ui": "workspace:*",
    "shared-data": "workspace:*"
  }
}
```

```ts
// packages/shared-ui/src/Button.tsx
import { Pressable, Text } from 'react-native';
export function Button({ label, onPress }: Props) { /* ... */ }
```

### Comparison

| Setup | Team size | Pros | Cons |
|---|---|---|---|
| Single codebase | 1–5 | Simple | Scale limits |
| Monorepo (pnpm + Turbo) | 5–50 | Shared code, speed | Setup overhead |
| Monorepo (Nx) | 50+ | Generators, governance | Heavier |
| Polyrepo | 50+ | Independence | Sync drift |

### Production Usage
- Most successful RN companies (Discord, Shopify, Coinbase) use monorepo.
- Small teams thrive on single codebase.

### Hands-On Exercise
Convert a single Expo app into pnpm + Turbo monorepo with `apps/expo` and `packages/shared`.

### Common Mistakes
- Monorepo for solo project.
- Shared packages with platform-specific code.
- No version pinning strategy.
- CI builds everything every commit.

### Production Red Flags
- pnpm warnings ignored.
- Circular deps between packages.
- "We have a monorepo but it's just one app."

### Performance & Metrics
- Build time per package.
- Cache hit rate (Turbo).
- Cross-package change frequency.

### Decision Framework
- < 5 engineers → single codebase.
- 5–50 with shared concerns → monorepo.
- > 50 → monorepo with structure (Nx).

### Senior-Level Insight
"Monorepo isn't a goal; it's a tool. Adopt when the pain of polyrepo (drift, duplicate code) exceeds the cost of monorepo setup."

### Real-World Scenario
Startup with 8 engineers; mobile + web growing; converted to pnpm + Turbo monorepo; cross-team velocity doubled.

### Production Failure Story
Team adopted Nx for 3-engineer team; spent 3 months on tooling instead of features.
**Fix:** Reverted to single Expo app; product velocity recovered.

### Debugging Checklist
1. Team size justifies setup?
2. Shared code identified?
3. CI parallelized?
4. Cache hit rate good?
5. Package boundaries clear?

### Advanced / Internal Knowledge
- Selective publish: only changed packages.
- Remote caching (Turbo Cloud, Nx Cloud).
- Code owners per package.

### 2026 AI Tip
AI helps generate package boilerplate; verify dependency graph.

### Related Topics
Q1, Q4, S20.

### Interview Follow-Up Questions
- "When does monorepo break down?"
- "How do you handle versioning?"
- "Single codebase vs polyrepo vs monorepo?"

### Memory Hook
**"Single codebase small teams. Monorepo for scale. pnpm + Turbo standard."**

### Revision Notes
> Single codebase for < 5 engineers; monorepo (pnpm + Turbo / Nx) for scale; apps/ + packages/ structure; Solito for Next + Expo; choose by team size + release cadence; don't over-engineer early.

---

> Cross-refs: S05 (Expo), S20 (CI), S22 (system design).
