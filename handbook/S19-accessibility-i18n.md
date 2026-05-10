# S19 — Accessibility & Internationalization

> Accessible RN components · focus management · dynamic type · RTL + bidi · ICU MessageFormat

A11y and i18n are the **two areas where senior engineers separate from mid-level** in modern interviews. RN 2026 has dramatically improved primitives; you're expected to use them.

## Topics in this section

- [Q1. Accessible RN components — labels, roles, traits](#q1-accessible-rn-components--labels-roles-traits)
- [Q2. Focus management and keyboard / external input](#q2-focus-management-and-keyboard--external-input)
- [Q3. Dynamic type and respecting OS settings](#q3-dynamic-type-and-respecting-os-settings)
- [Q4. RTL layouts and bidirectional text](#q4-rtl-layouts-and-bidirectional-text)
- [Q5. ICU MessageFormat with FormatJS / i18next](#q5-icu-messageformat-with-formatjs--i18next)

---

## Q1. Accessible RN components — labels, roles, traits

### Difficulty
Intermediate

### Interview Frequency
Common at mid–senior+ rounds.

### Prerequisites
RN basics; some screen-reader familiarity.

### TL;DR
Every interactive element needs `accessible={true}`, `accessibilityLabel`, `accessibilityRole`, `accessibilityState`, and `accessibilityHint`. Test with VoiceOver (iOS) and TalkBack (Android). RN 2026 has unified `accessibilityRole` enums across both.

### 30-Second Interview Answer
"Accessibility in RN means every Touchable / Pressable has an `accessibilityRole` like `'button'`, an `accessibilityLabel` for screen readers, `accessibilityState` for `disabled`/`selected`/`checked`, and `accessibilityHint` for non-obvious actions. Lists need `accessibilityRole='list'` with items `'listitem'`. I test every PR with VoiceOver and TalkBack on real devices."

### 2-Minute Practical Answer
Core props (RN 0.74+):
- `accessible: boolean` — group children into one accessibility node.
- `accessibilityLabel: string` — what the screen reader announces.
- `accessibilityRole: 'button' | 'link' | 'header' | ...` — semantic.
- `accessibilityState: { disabled?, selected?, checked?, busy?, expanded? }`.
- `accessibilityHint: string` — additional context ("Double-tap to open").
- `accessibilityValue: { min, max, now, text }` — for sliders/progress.
- `accessibilityLiveRegion` (Android) / `accessibilityAnnouncement` — dynamic updates.
- `importantForAccessibility` — control focus traversal.

Patterns:
- Wrap touchable items: `<Pressable accessibilityRole="button" accessibilityLabel="Like post">...</Pressable>`.
- Decorative images: `accessible={false}` (don't announce).
- Form errors: announce via `AccessibilityInfo.announceForAccessibility(msg)`.

### 5-Minute Architecture Answer
RN 2026 maps `accessibilityRole` to:
- iOS UIAccessibility traits.
- Android `AccessibilityNodeInfo` roles.

The unified API hides the platform diff but **doesn't fix design problems**:
- Tap targets must be ≥ 44×44pt (Apple) / 48dp (Material).
- Color contrast WCAG AA (4.5:1 for normal text).
- Don't rely on color alone to convey state.
- Animations should respect `prefersReducedMotion`.

Production patterns:
1. **Accessibility audit per PR** — eslint-plugin-react-native-a11y catches missing labels.
2. **Snapshot testing with accessibility props** — don't lose them in refactors.
3. **Real-device testing** — simulators don't show all bugs.
4. **Component library hygiene** — design system components ship with sensible defaults.

The 2026 shift: a11y compliance is **legal** in many jurisdictions (ADA in US, EAA in EU); senior engineers are expected to know this.

### The "Why"
- 15% of users worldwide have a disability.
- Legal exposure (lawsuits, regulator fines).
- A11y improvements help everyone (clearer copy, larger tap targets).

### Mental Model
Every visual element needs a **non-visual equivalent**: label = text alternative, role = function, state = current condition.

### Internal Working (2026 Context)
- RN 0.74+ has cross-platform `accessibilityRole` parity.
- Reanimated 3 supports `prefersReducedMotion` — wrap entrance animations.
- React Compiler doesn't affect a11y semantics.

### Modern Implementation (Code)

```tsx
function LikeButton({ liked, onPress, count }: Props) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={liked ? `Unlike. ${count} likes` : `Like. ${count} likes`}
      accessibilityState={{ selected: liked }}
      accessibilityHint="Double-tap to toggle"
      hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }} // expand tap area
    >
      <Heart filled={liked} />
      <Text>{count}</Text>
    </Pressable>
  );
}

// Announcing dynamic changes
import { AccessibilityInfo } from 'react-native';
function showSuccess() {
  AccessibilityInfo.announceForAccessibility('Saved successfully');
}
```

### Comparison

| Concern | RN prop | iOS analog | Android analog |
|---|---|---|---|
| Label | `accessibilityLabel` | `accessibilityLabel` | `contentDescription` |
| Role | `accessibilityRole` | `UIAccessibilityTraits` | `roleDescription` |
| Hint | `accessibilityHint` | `accessibilityHint` | (concatenated) |
| Live | `accessibilityLiveRegion` | `UIAccessibilityNotification` | `accessibilityLiveRegion` |

### Production Usage
- Design system components own a11y defaults; apps inherit.
- Dynamic content (toasts, snackbars) uses `announceForAccessibility`.
- Forms wire field errors to inputs via `accessibilityLabelledBy` (RN 0.71+).

### Hands-On Exercise
1. Enable VoiceOver on iPhone; navigate your app. Note unannounced or wrongly-announced elements.
2. Enable TalkBack on Android; do the same.
3. Add eslint-plugin-react-native-a11y; fix violations.

### Common Mistakes
- Touchable on a `<View>` without role.
- Image-only buttons without label.
- Wrong role (using `'button'` for a link, etc.).
- Forgetting `accessibilityState.disabled` syncs with visual disabled.

### Production Red Flags
- "Image, image, image" announcements (unlabeled icons).
- Tap targets < 44pt.
- Color-only error indicators.

### Performance & Metrics
- A11y audit pass rate (axe / accessibility scanner).
- Issues filed by VoiceOver/TalkBack users.
- Tap-target compliance % across PRs.

### Decision Framework
- Interactive element → role + label + state.
- Decorative → `accessible={false}`.
- Dynamic update → live region or `announceForAccessibility`.

### Senior-Level Insight
"A11y is shipped or not — there's no partial credit." Every interactive element needs proper props; design system primitives carry defaults; CI catches regressions.

### Real-World Scenario
**Symptom:** App scored 60% on accessibility audit before legal release.
**Fix:** Audit + remediate top 20 screens; add eslint plugin; add to PR template.

### Production Failure Story
**Incident:** Lawsuit filed for inaccessible checkout flow.
**Root cause:** Form errors weren't announced; users with screen readers couldn't tell why submit failed.
**Fix:** Announce errors; wire field-error linkage; full a11y audit.

### Debugging Checklist
1. Every Touchable has `accessibilityRole` + `accessibilityLabel`?
2. State props sync with visual state?
3. Tap targets ≥ 44pt?
4. Tested with VoiceOver + TalkBack?

### Advanced / Internal Knowledge
- `accessibilityElementsHidden` (iOS) / `importantForAccessibility="no-hide-descendants"` (Android) hide children from a11y tree.
- `UIAccessibilityCustomAction` for custom gestures (rare in RN).
- Reanimated worklet animations should branch on `useReducedMotion()`.

### 2026 AI Tip
AI rarely adds a11y props. After scaffolding, lint and add labels.

### Related Topics
Q2, Q3, S04 (Fabric).

### Interview Follow-Up Questions
- "What's the difference between `accessibilityLabel` and `accessibilityHint`?"
- "How do you announce a toast?"
- "What roles map to native traits?"

### Memory Hook
**"Role + label + state + hint. VoiceOver and TalkBack tell the truth."**

### Revision Notes
> Every interactive element: `accessible`, `accessibilityRole`, `accessibilityLabel`, `accessibilityState`, optional `accessibilityHint`; tap targets ≥ 44pt; test on real devices with screen readers; lint in CI.

---

## Q2. Focus management and keyboard / external input

### Difficulty
Advanced

### Interview Frequency
Common at senior rounds (especially tablet / TV / accessibility).

### Prerequisites
Q1.

### TL;DR
Focus is for keyboard users (accessibility, hardware keyboards, tvOS, Vision Pro). Use `findNodeHandle` + `AccessibilityInfo.setAccessibilityFocus` (legacy) or `focus()` on refs (modern). Manage focus on screen change, modal open, and error states.

### 30-Second Interview Answer
"Focus management means controlling where the screen reader / keyboard cursor lands. After navigation, focus the page heading. After modal open, focus the modal title; trap focus inside until close. After validation error, focus the first errored field. RN 2026 supports `ref.focus()` on most elements; modal libraries like `react-native-modal` need explicit focus calls."

### 2-Minute Practical Answer
Trigger focus manually:
```ts
const ref = useRef<View>(null);
useEffect(() => {
  const node = findNodeHandle(ref.current);
  if (node) AccessibilityInfo.setAccessibilityFocus(node);
}, []);
```

Focus traps for modals — RN doesn't have built-in; use `react-native-focus-trap` or implement:
- Listen for focus loss → re-focus first focusable in modal.
- Restore focus to trigger on close.

External keyboard / tvOS / Vision Pro:
- `Pressable` accepts `onFocus`/`onBlur` for hardware focus rings.
- TV-style nav uses `nextFocusUp`/`nextFocusDown`/etc. (Android TV).
- Vision Pro relies on hover/gaze — `Pressable` handles `onHoverIn`/`onHoverOut`.

### 5-Minute Architecture Answer
Focus on mobile is mostly ignored — touch users don't see it. But:
- **Screen readers** use focus to track current node.
- **Hardware keyboards** (iPad with Magic Keyboard, Android tablets) need it.
- **tvOS / Android TV** depend on it entirely (no touch).
- **visionOS** uses gaze + tap; focus is a UI affordance.

Architectural rules:
1. **Initial focus** — on screen mount, focus the first meaningful element (heading or first input). Without this, screen-reader users hear "Untitled, button" sequence.
2. **Modal focus trap** — focus enters modal on open, doesn't escape until close, returns to trigger.
3. **Error focus** — invalid form: focus the first errored field + announce reason.
4. **Live changes** — adding new content: optionally `announceForAccessibility`; don't steal focus.

For tvOS / TV apps:
- `react-native-tvos` ships hardware focus support.
- `Pressable` with `onFocus` shows highlight ring.
- Custom navigation: use `nextFocusDown` etc.

For Vision Pro (S29):
- `Pressable` and `View` support `onHoverIn`/`onHoverOut`.
- Spatial focus is gaze-driven; visual feedback is essential.

### The "Why"
- A11y users can't navigate without managed focus.
- Hardware-keyboard users (iPad pros) get a broken experience without it.
- TV/Vision Pro require it functionally.

### Mental Model
Focus is a **cursor for the non-touch world**. Keep it where the user expects.

### Internal Working (2026 Context)
- RN 0.74+ deprecates `findNodeHandle` slowly; many components have direct `focus()` methods.
- Reanimated worklets can react to focus events for smooth highlights.
- visionOS support added to RN core in 2026.

### Modern Implementation (Code)

```tsx
function ScreenWithHeading() {
  const headingRef = useRef<Text>(null);
  useFocusEffect(
    useCallback(() => {
      headingRef.current && AccessibilityInfo.setAccessibilityFocus(findNodeHandle(headingRef.current)!);
    }, [])
  );
  return <Text ref={headingRef} accessibilityRole="header">Profile</Text>;
}

function ErrorFirstField({ errors }: { errors: Record<string, string> }) {
  const firstError = Object.keys(errors)[0];
  const refs = useFieldRefs();
  useEffect(() => {
    if (firstError) refs[firstError].current?.focus();
  }, [firstError]);
  // ...
}
```

### Comparison

| Surface | Focus driver |
|---|---|
| Mobile touch | Implicit |
| Screen reader | Managed |
| Hardware keyboard | Tab order |
| tvOS / TV | Remote |
| visionOS | Gaze |

### Production Usage
- Modals trap focus; restore on close.
- Forms focus first error.
- Screens focus heading on mount.

### Hands-On Exercise
1. Open a modal; check VoiceOver doesn't escape.
2. Submit an invalid form; verify focus lands on first error.
3. Pair an iPad with a keyboard; navigate via Tab.

### Common Mistakes
- Modal opens but VoiceOver stays on background.
- Form errors render but focus stays on submit.
- Lists with no focus on first item after refresh.

### Production Red Flags
- A11y bug reports about "lost in the app."
- iPad+keyboard users can't reach all elements.
- TV testers report "stuck on first card."

### Performance & Metrics
- A11y user retention.
- Hardware-keyboard test suite coverage.
- Cross-device focus test passes.

### Decision Framework
- Modal/route change → explicit focus call.
- Validation error → focus first field.
- Live region update → announce, don't refocus.

### Senior-Level Insight
"Focus is invisible UX. Until you test with a screen reader, you can't see the bugs you're shipping."

### Real-World Scenario
**Symptom:** Customer support reports VoiceOver users can't complete checkout.
**Investigation:** After payment error, focus stayed on the page; users didn't hear the error.
**Fix:** Focus + announce on error; auto-scroll to errored field.

### Production Failure Story
**Incident:** TV app failed customer review for accessibility.
**Root cause:** No focus rings on items; remote arrow keys had no visible response.
**Fix:** Wired `Pressable` `onFocus` to a highlight style.

### Debugging Checklist
1. Modal open → focus inside?
2. Modal close → focus returns to trigger?
3. Validation → focus first error?
4. New screen → focus heading?

### Advanced / Internal Knowledge
- `AccessibilityInfo.isReduceMotionEnabled()` to skip animations.
- `accessibilityElementsHidden` to manage what gets focus.
- visionOS uses `accessibilityResponseReader` for gaze.

### 2026 AI Tip
AI rarely scaffolds focus management. Add it manually after generating modals or forms.

### Related Topics
Q1, Q3, S29 (cross-target).

### Interview Follow-Up Questions
- "How do you trap focus in a modal?"
- "What happens to focus on screen change?"
- "How do you handle hardware keyboard navigation?"

### Memory Hook
**"Focus on mount. Trap in modals. Restore on close."**

### Revision Notes
> Focus = cursor for non-touch world; manage on screen change, modal open/close, validation error; trap inside modals; restore to trigger; tvOS/visionOS depend on it.

---

## Q3. Dynamic type and respecting OS settings

### Difficulty
Intermediate

### Interview Frequency
Common.

### Prerequisites
RN text styling.

### TL;DR
Users can change OS text size; your app must scale. Use `allowFontScaling` (default true) thoughtfully — scale body text but cap large display text. Read `PixelRatio.getFontScale()` for layout decisions.

### 30-Second Interview Answer
"Dynamic type respects OS-level text size settings (Apple's Larger Text accessibility setting, Android's Display Size). RN's `<Text>` scales by default. I cap with `maxFontSizeMultiplier` for headers (visual hierarchy) but never disable scaling globally. Test at 200%+ scale for layout breakage."

### 2-Minute Practical Answer
Props:
- `allowFontScaling: boolean` (default true).
- `maxFontSizeMultiplier: number` (default null = unlimited).
- `minimumFontScale: number` (iOS) for `numberOfLines={1}` truncation.

Read settings:
```ts
import { PixelRatio } from 'react-native';
const scale = PixelRatio.getFontScale(); // 1.0 = default; 2.0 = max
```

Strategy:
- Body text: full scaling.
- Headings: cap at 1.5× to maintain hierarchy.
- Buttons / nav: cap at 1.3× to avoid layout breakage.
- Use scrollable layouts; don't fix heights based on text.

### 5-Minute Architecture Answer
Dynamic type's challenge: large text breaks fixed-width designs. The architectural fix is **fluid layouts**:
- ScrollView for screens that might overflow.
- Wrap text + don't truncate critical info.
- Tap targets stay ≥ 44pt regardless of font scale.
- Icons next to text scale via `PixelRatio.getFontScale()`.

iOS Dynamic Type semantic styles (RN 0.71+):
```tsx
<Text style={{ fontFamily: 'System', fontSize: 17 }} dynamicTypeRamp="body" />
```
This integrates with iOS's text styles for native feel.

Android: read `Settings.System.FONT_SCALE` (RN handles internally); test at 1.3× and 2.0× scales.

For 2026 AI codebases: tools generate fixed-pixel sizes; convert to scalable via theme tokens.

### The "Why"
- Vision-impaired users rely on large text.
- Lawsuits cite ignored Dynamic Type.
- Older user base (banking, healthcare) skews toward larger text.

### Mental Model
Treat OS text scale as a **first-class breakpoint** alongside device width.

### Internal Working (2026 Context)
- RN passes scale to native text system; iOS/Android handle final sizing.
- React Compiler doesn't affect this.
- Expo's `expo-system-ui` exposes additional system style hooks.

### Modern Implementation (Code)

```tsx
function Heading({ children }: { children: ReactNode }) {
  return (
    <Text
      style={{ fontSize: 28, fontWeight: '700' }}
      maxFontSizeMultiplier={1.5}
      accessibilityRole="header"
    >
      {children}
    </Text>
  );
}

function Body({ children }: { children: ReactNode }) {
  return <Text style={{ fontSize: 16 }}>{children}</Text>; // unrestricted scaling
}
```

### Comparison

| Element | Cap |
|---|---|
| Body text | Unlimited |
| Headings | 1.3–1.5× |
| Buttons | 1.3× |
| Tab labels | 1.2× |

### Production Usage
- Design system Text components carry sensible caps.
- Snapshot tests at 1.3× and 2.0× scales.
- Real-device QA at max scale.

### Hands-On Exercise
1. Enable iOS Larger Text; max it. Open your app. Note breakage.
2. Add `maxFontSizeMultiplier` to non-body text.
3. Test ScrollView screens for overflow.

### Common Mistakes
- `allowFontScaling={false}` everywhere.
- Fixed-height containers based on default text size.
- Icons not scaling proportionally.

### Production Red Flags
- Fixed `<View>` heights with text inside.
- Text truncated on default scale.
- Buttons that don't fit at large scale.

### Performance & Metrics
- A11y reports about unreadable text.
- Layout-breakage screenshots from QA at large scales.

### Decision Framework
- Body / paragraph → full scale.
- Headings / nav → capped scale.
- Numeric display (price, time) → moderate cap.

### Senior-Level Insight
"Designs are made at 1.0× but lived at 1.3×+." Average iPhone user runs slightly larger; banking app users much larger.

### Real-World Scenario
**Symptom:** App store reviews mention "buttons cut off."
**Investigation:** Reviewer ran at 200% text scale.
**Fix:** Cap button labels; allow wrapping; expand layout.

### Production Failure Story
**Incident:** Critical "Pay" button became invisible at large scale.
**Root cause:** Fixed-width container clipped text.
**Fix:** Flexible width; cap multiplier; QA at scale.

### Debugging Checklist
1. Test at OS max font scale.
2. Are heights flexible (no fixed text containers)?
3. Are icons sized via font scale ratio?
4. Are caps on display text, not body?

### Advanced / Internal Knowledge
- `dynamicTypeRamp` (iOS) for semantic text styles.
- `PixelRatio.getFontScale` differs from device pixel density (`PixelRatio.get()`).
- Sentry custom tag for OS font scale aids triage.

### 2026 AI Tip
AI defaults to fixed `fontSize`. Convert to theme-token + cap for non-body.

### Related Topics
Q1, Q4.

### Interview Follow-Up Questions
- "What does `PixelRatio.getFontScale` return?"
- "When should you disable font scaling?"
- "How do you test at large text sizes?"

### Memory Hook
**"Body scales free. Headings cap. Layouts flex."**

### Revision Notes
> Respect OS text scale; `allowFontScaling=true` (default); cap with `maxFontSizeMultiplier` on headings/nav; flexible layouts; test at 200% scale.

---

## Q4. RTL layouts and bidirectional text

### Difficulty
Intermediate → Advanced

### Interview Frequency
Common at senior+ rounds (esp. for global apps).

### Prerequisites
Flexbox basics.

### TL;DR
RN supports RTL out of the box: enable via `I18nManager.forceRTL(true)` (requires reload). Use `start`/`end` instead of `left`/`right`. Test both directions; mirror icons that imply direction (back arrow).

### 30-Second Interview Answer
"For RTL languages (Arabic, Hebrew, Persian, Urdu) RN's I18nManager auto-mirrors layouts when device locale is RTL. I use logical properties — `marginStart` instead of `marginLeft`, `start` instead of `left`. Icons that imply direction (back, next) need conditional mirroring. Bidirectional text within strings works automatically; test embedded LTR (e.g., URLs) inside RTL paragraphs."

### 2-Minute Practical Answer
Setup:
```ts
import { I18nManager } from 'react-native';
// At app start, if user picked Arabic:
if (I18nManager.isRTL !== shouldBeRTL) {
  I18nManager.allowRTL(shouldBeRTL);
  I18nManager.forceRTL(shouldBeRTL);
  RNRestart.Restart(); // requires native restart
}
```

Logical styles:
- `marginStart` / `marginEnd` (not `marginLeft` / `marginRight`).
- `paddingStart` / `paddingEnd`.
- `start` / `end` (in absolute positioning).
- `textAlign: 'left'` becomes "start of paragraph."

Icon mirroring:
```tsx
<BackArrow style={{ transform: [{ scaleX: I18nManager.isRTL ? -1 : 1 }] }} />
```

Don't mirror: clocks, music play buttons, numbers, photos.

### 5-Minute Architecture Answer
RTL is more than mirroring; it's a **directional re-think**:
- Layout direction (LTR vs RTL).
- Text direction (within strings; usually auto via Unicode bidi).
- Icon direction (back/next mirror; logos don't).
- Animation direction (slide-in from "start" not "left").
- Number formatting (Arabic digits vs Western).

Architecture:
- Use logical (start/end) styles everywhere.
- Theme-aware components handle mirroring.
- Reanimated supports `I18nManager.isRTL` in worklets.
- Layout testing: snapshot in both directions.

Bidi (bidirectional) text:
- Mixed scripts in one string need Unicode markers.
- Rare to handle manually; modern engines do well.
- Edge case: URLs / phone numbers in RTL paragraphs need `‎` (LRM) or `‏` (RLM) wrapping.

In 2026:
- Expo handles RTL toggling without native restart in some cases.
- React Compiler doesn't affect RTL.
- Reanimated 3+ has `I18nManager.isRTL` worklet support.

### The "Why"
- 700M+ Arabic / Hebrew / Persian / Urdu users.
- Naive LTR-only apps look broken.
- App Store ratings drop for RTL bugs.

### Mental Model
LTR/RTL = **mirror image of the screen** for layout; text follows Unicode rules.

### Internal Working (2026 Context)
- iOS auto-RTLs based on system language; Android too.
- Yoga (RN's layout engine) supports `direction: rtl`.
- React Native's StyleSheet auto-converts `marginLeft` → `marginStart` *only if* `I18nManager.allowRTL(true)` and you opt in.

### Modern Implementation (Code)

```tsx
const styles = StyleSheet.create({
  card: {
    paddingStart: 16, // works in both LTR (left) and RTL (right)
    paddingEnd: 8,
    flexDirection: 'row', // becomes row-reverse in RTL automatically
  },
});

function BackButton() {
  return (
    <Pressable accessibilityRole="button" accessibilityLabel="Back">
      <Ionicons
        name="arrow-back"
        size={24}
        style={{ transform: [{ scaleX: I18nManager.isRTL ? -1 : 1 }] }}
      />
    </Pressable>
  );
}
```

### Comparison

| Direction | LTR style | RTL style |
|---|---|---|
| Logical | `paddingStart` | `paddingStart` |
| Physical (avoid) | `paddingLeft` | `paddingLeft` |
| Mirrored icon | normal | `scaleX: -1` |
| Photo | normal | normal |

### Production Usage
- All design system primitives use logical styles.
- Snapshot tests in both directions.
- Locale switcher in dev menu for fast testing.

### Hands-On Exercise
1. Add `I18nManager.forceRTL(true)`; reload; check screens.
2. Find `marginLeft` violations; convert to `marginStart`.
3. Add an Arabic translation; verify text rendering.

### Common Mistakes
- Using `left`/`right` in styles.
- Mirroring icons that shouldn't (logos).
- Hardcoding text directionality (`textAlign: 'left'` instead of `'start'`).
- Forgetting to test animations in RTL (slide direction).

### Production Red Flags
- Visual artifacts in RTL screenshots.
- Icons pointing wrong way.
- Mixed-direction text not rendering.

### Performance & Metrics
- A11y / international user retention.
- App store ratings in RTL markets.
- QA pass rate in both directions.

### Decision Framework
- All styles → logical (start/end).
- Icons → conditional mirror if directional.
- Animations → use logical direction.

### Senior-Level Insight
"RTL bugs are typically caught only when an Arabic-speaking QA tester sees them." Build it into CI by snapshotting in both directions.

### Real-World Scenario
**Symptom:** Arabic users report broken navigation.
**Investigation:** Back arrow pointed wrong way; tab bar order wrong.
**Fix:** Mirror back arrow; tab bar uses logical start/end ordering.

### Production Failure Story
**Incident:** RTL launch postponed; 30% of new screens used `marginLeft`.
**Fix:** Lint rule banning physical properties; codemod to convert.

### Debugging Checklist
1. Are styles using `start`/`end` instead of `left`/`right`?
2. Are directional icons mirrored?
3. Snapshot tests in both directions?
4. Are animations using logical direction?

### Advanced / Internal Knowledge
- Unicode LRM/RLM characters force directional embedding.
- Yoga's `direction` enum: `inherit | ltr | rtl`.
- Some Reanimated worklets need explicit `I18nManager.isRTL` capture.

### 2026 AI Tip
AI uses physical properties by default. Lint to catch; convert to logical.

### Related Topics
Q5, S29.

### Interview Follow-Up Questions
- "When do you mirror icons?"
- "How does `marginStart` differ from `marginLeft`?"
- "Why does `forceRTL` require app restart?"

### Memory Hook
**"Logical styles. Mirror directional icons. Test both ways."**

### Revision Notes
> RN auto-RTLs via I18nManager; use `start`/`end`/`marginStart`/`paddingEnd`; mirror back arrows; never mirror logos/photos; snapshot tests both directions; bidi text mostly automatic.

---

## Q5. ICU MessageFormat with FormatJS / i18next

### Difficulty
Intermediate

### Interview Frequency
Common at senior rounds.

### Prerequisites
Translation basics.

### TL;DR
**ICU MessageFormat** is the standard for plurals, gender, and selectors in translations. **FormatJS** (`react-intl`) and **i18next** both support it. ICU avoids string concatenation that breaks in many languages.

### 30-Second Interview Answer
"ICU MessageFormat handles plurals (`{count, plural, one {# item} other {# items}}`), gender (`{gender, select, male {His} female {Her}}`), and dates/numbers consistently across languages. I use FormatJS (react-intl) for ICU; it parses at compile time via babel plugin so runtime is fast. Translations live in JSON per locale; missing keys fall back to default."

### 2-Minute Practical Answer
ICU syntax basics:
- Plural: `{count, plural, =0 {no items} one {# item} other {# items}}`.
- Select: `{gender, select, male {Mr.} female {Ms.} other {Mx.}}`.
- Number / date: `{price, number, ::currency/USD}`, `{when, date, ::yMd}`.

With FormatJS:
```tsx
import { FormattedMessage } from 'react-intl';

<FormattedMessage
  id="cart.items"
  defaultMessage="{count, plural, one {# item} other {# items}}"
  values={{ count }}
/>
```

Translations file:
```json
{ "cart.items": "{count, plural, one {# article} other {# articles}}" }
```

Workflow:
- Engineers write `defaultMessage` in source.
- Extract via `formatjs-extract` to a JSON.
- Translators fill JSON per locale.
- Compile to optimized format via `formatjs-compile`.
- Bundle with app or load remotely.

### 5-Minute Architecture Answer
Why ICU over template strings:
- **Pluralization rules differ wildly** — Russian has `one`, `few`, `many`, `other`; Arabic has 6 forms.
- **Word order changes** — `${name} updated ${count} files` may become `${count} files were updated by ${name}` in another language.
- **Gendered grammar** — French verbs change with gender.
- **Currency / date** — built-in formatting per locale.

ICU + FormatJS architecture:
- Single source: `defaultMessage` in code.
- Extraction CLI generates IDs and JSON.
- Translators use a TMS (Crowdin, Lokalise, Phrase).
- TMS exports JSON back; CI bundles it.
- Compile transforms ICU into runtime-optimized format (much faster than parsing at runtime).

For RN 2026:
- `react-intl` works; `expo-localization` reads device locale.
- Lazy-load locale bundles for code-splitting.
- Pseudo-localization in dev catches hardcoded strings.

i18next vs FormatJS:
- i18next: simpler API, plugin ecosystem, bigger community in 2026.
- FormatJS: stricter ICU support, better tooling for extraction, used by larger apps.

### The "Why"
- Concatenated strings break in 80% of non-English languages.
- ICU is a 20-year-old standard; tools are mature.
- Bad translations are worse than no translations.

### Mental Model
ICU = mini-language for choosing the right phrase based on values.

### Internal Working (2026 Context)
- FormatJS uses `Intl.PluralRules`, `Intl.NumberFormat`, `Intl.DateTimeFormat` (all in Hermes).
- Hermes 2026 ships full Intl support.
- `expo-localization` v15+ handles 2026 OS APIs.

### Modern Implementation (Code)

```tsx
import { IntlProvider, FormattedMessage, FormattedNumber, FormattedDate } from 'react-intl';
import * as Localization from 'expo-localization';

const messages = {
  en: enMessages,
  ar: arMessages,
  fr: frMessages,
};

function App() {
  const locale = Localization.locale.split('-')[0]; // 'en', 'ar', ...
  return (
    <IntlProvider locale={locale} messages={messages[locale] ?? messages.en}>
      <Root />
    </IntlProvider>
  );
}

// Usage
<FormattedMessage
  id="profile.followers"
  defaultMessage="{count, plural, =0 {No followers} one {# follower} other {# followers}}"
  values={{ count }}
/>

<FormattedNumber value={4990} style="currency" currency="USD" /> // $49.90 / ٤٩٫٩٠ $
```

### Comparison

| Tool | Strength | Weakness |
|---|---|---|
| FormatJS / react-intl | ICU strict, tooling | Slightly heavier API |
| i18next | Plugins, community | ICU support optional |
| Lingui | Macros, type-safe | Smaller ecosystem |
| Plain template strings | Trivial | Breaks i18n |

### Production Usage
- TMS (Crowdin / Lokalise) integrated with CI.
- Pseudo-localization (`Ŀõçàĺïżéď`) in dev to catch hardcoded strings.
- Per-locale code splitting (lazy-load bundles).

### Hands-On Exercise
1. Add FormatJS; translate one screen to French + Arabic.
2. Use ICU plural for a "X notifications" string.
3. Extract messages with `formatjs extract`; round-trip via TMS.

### Common Mistakes
- Hardcoded strings (no translation key).
- String concatenation in JSX (`Hello, ${name}!` instead of `{name}`).
- Wrong plural categories per language.
- Inline currency formatting (`$${price}`) ignoring locale.

### Production Red Flags
- "Translation files" with English text.
- `t('key')` calls without `defaultMessage`.
- No pseudo-localization in dev.

### Performance & Metrics
- Locale bundle size.
- Load time per locale.
- Translation coverage % per locale.

### Decision Framework
- Plurals → ICU.
- Number/currency/date → `Intl` APIs (FormatJS handles).
- Simple substitutions → ICU still works fine.

### Senior-Level Insight
"i18n is a process, not a feature." Set up extraction + TMS round-trip on day one; engineers shouldn't manually edit JSON files.

### Real-World Scenario
**Symptom:** Russian users see "1 items" / "5 items" with broken grammar.
**Root cause:** Plain template; only handled `n === 1` vs `n !== 1`.
**Fix:** ICU plural with all categories.

### Production Failure Story
**Incident:** Launch in Japan delayed; date format hardcoded as `MM/DD/YYYY`.
**Fix:** `FormattedDate` everywhere; respects locale.

### Debugging Checklist
1. Hardcoded strings caught by lint?
2. ICU plurals for any count-based phrase?
3. Number / date formatted via Intl?
4. Pseudo-localization tested?

### Advanced / Internal Knowledge
- ICU handles relative time (`{when, relative}`); newer APIs ship in 2026.
- `Intl.Segmenter` for locale-aware text segmentation (Chinese / Japanese line breaking).
- Hermes' Intl is mostly compliant; double-check edge cases.

### 2026 AI Tip
AI generates plain-string translations. Replace with ICU for plurals and selects.

### Related Topics
Q4, S30 (privacy across regions).

### Interview Follow-Up Questions
- "Show ICU plural for Russian."
- "How do you format currency by locale?"
- "Why not just `${name}, you have ${count} items`?"

### Memory Hook
**"ICU for plurals and selects. Intl for numbers and dates."**

### Revision Notes
> ICU MessageFormat handles plurals/select/number/date across locales; use FormatJS or i18next; extract from code → TMS → JSON → bundle; pseudo-localize in dev; never concatenate translatable strings.

---

> Cross-refs: S04 (Fabric a11y), S29 (cross-target including TV/visionOS), S05 (Expo).
