## 17. Accessibility (a11y), color, fonts, i18n

> Heavily asked at Microsoft, Walmart, Atlassian, Booking. Differentiator at fintechs.

### Accessibility (a11y)
- **Roles**: `accessibilityRole="button"` (also `link`, `header`, `image`, `text`, `summary`, `adjustable`).
- **Labels**: `accessibilityLabel` (screen reader reads this), `accessibilityHint` (extra context).
- **State**: `accessibilityState={{ disabled, selected, checked, busy, expanded }}`.
- **Live regions**: `accessibilityLiveRegion="polite" | "assertive"` (Android) and `AccessibilityInfo.announceForAccessibility(msg)` (cross-platform).
- **Focus management**: `findNodeHandle` + `AccessibilityInfo.setAccessibilityFocus(handle)` after navigation.
- **Touch target**: min **44×44pt** (iOS HIG) / **48×48dp** (Android Material). Use `hitSlop` for small icons.
- **Group decorative children**: `accessible={true}` on parent, `accessibilityElementsHidden={true}` on iOS for decorative; `importantForAccessibility="no-hide-descendants"` on Android.
- **Reduce motion**: respect `AccessibilityInfo.isReduceMotionEnabled()` — disable parallax/large transitions.
- **Screen readers**: VoiceOver (iOS), TalkBack (Android). Test with both.

### Color + contrast
- **WCAG 2.2 AA**: contrast **≥ 4.5:1** for normal text, **≥ 3:1** for large text (≥18pt or 14pt bold) and UI components.
- **WCAG AAA**: 7:1 normal, 4.5:1 large.
- Tools: Stark, Figma plugins, browser DevTools contrast checker.
- **Never use color alone** to convey meaning (red=bad, green=good fails for ~8% of men with red-green color blindness).

### Color blindness (deuteranopia, protanopia, tritanopia)
- ~8% of men, ~0.5% of women.
- Pair color with **icon + label + pattern**.
  - ✅ Error: red border + ❌ icon + "Error" text
  - ❌ Just red border
- Test with simulators: Sim Daltonism (macOS), Color Oracle (cross-platform), iOS accessibility filters (Settings → Accessibility → Display & Text Size → Color Filters).
- Avoid problem combos: red/green, green/brown, blue/purple, light blue/pink.
- Charts: use distinct hues + patterns + labels.

### Dark mode
- `useColorScheme()` from RN.
- Define color tokens (semantic: `text.primary`, `bg.surface`) not raw hex.
- Test both modes for contrast.
- Status bar: switch `barStyle` per scheme.

### Fonts + typography
- **System fonts** load instantly; custom fonts add startup cost.
- **Custom fonts**:
  - iOS: add to bundle, list in `Info.plist` (`UIAppFonts`).
  - Android: place in `android/app/src/main/assets/fonts/`.
  - Or Expo Font: `useFonts({ Inter: require('./Inter.ttf') })` — async, gate render.
- **Variable fonts** (Inter, Roboto Flex) — single file, multiple weights, smaller total size.
- **Font scaling (Dynamic Type)**:
  - iOS respects user font size by default.
  - Cap with `allowFontScaling={false}` ONLY if it breaks layout — better to make layout flexible.
  - `maxFontSizeMultiplier={1.5}` is a sane cap.
- **Line height**: 1.4–1.6× font size for body text.
- **Letter spacing**: tighter for headings (-0.5px), looser for ALL CAPS (+1px).
- **Hierarchy**: limit to 4–5 sizes (e.g., 32 / 24 / 18 / 16 / 14 / 12).

### Internationalization (i18n)
- **`i18next` + `react-i18next`** is the de-facto stack.
- `expo-localization` for device locale + timezone.
- **RTL** (Arabic, Hebrew): `I18nManager.forceRTL(true)` requires app reload; design with logical properties (`marginStart` not `marginLeft`).
- **Pluralization**: ICU MessageFormat (`{count, plural, one {# item} other {# items}}`).
- **Number/date/currency**: `Intl.NumberFormat`, `Intl.DateTimeFormat` (Hermes 0.74+ supports full Intl).
- Don't concatenate strings — use placeholders. Word order varies per language.

### Must-answer questions
1. How do you make a button accessible to screen readers?
2. WCAG AA contrast minimums.
3. Designing for color blindness — examples.
4. Dynamic Type / font scaling — when to cap.
5. RTL support — what changes in code.
6. Loading custom fonts in RN — iOS + Android steps.

---

