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



---

## Top 25 Q&A — Accessibility, color, fonts, i18n

### 1. Why does a11y matter beyond compliance?
Bigger TAM, App Store ratings, India RBI / WCAG mandates for fintech, better UX for everyone (one-handed use, low light, etc.).

### 2. Core RN a11y props.
`accessible`, `accessibilityLabel`, `accessibilityHint`, `accessibilityRole`, `accessibilityState`, `accessibilityValue`, `accessibilityActions`.

### 3. Make a custom button accessible.
```jsx
<Pressable accessible accessibilityRole="button" accessibilityLabel="Pay 1000 rupees"
  accessibilityHint="Initiates UPI payment" onPress={pay} />
```

### 4. Common a11y bugs.
Image-only buttons without label, color-only state (red/green), low contrast (<4.5:1), missing focus order, untranslated labels.

### 5. Test screen reader on iOS / Android.
iOS VoiceOver: Settings → Accessibility → VoiceOver, swipe right/left. Android TalkBack: similar. Triple-click home for shortcut.

### 6. Color contrast rules.
WCAG AA: 4.5:1 for normal text, 3:1 for large (≥18pt or 14pt bold). AAA: 7:1 / 4.5:1. Test with Stark / WebAIM contrast checker.

### 7. Dark mode.
`useColorScheme()` hook. Define semantic tokens (bg, fg, surface) mapped to light/dark. Avoid hardcoded `#fff`.

### 8. Dynamic type / font scaling.
RN respects user font size by default. Test at largest accessibility size. Cap with `maxFontSizeMultiplier` for layout-critical text.

### 9. RTL languages (Hindi/Arabic).
`I18nManager.allowRTL(true)` + `forceRTL` based on locale. Layouts mirror; check icons (chevrons), use `start/end` instead of `left/right`.

### 10. i18n libs in RN.
`i18next` + `react-i18next`, `react-intl`, or `lingui`. Pluralization, interpolation, lazy-load namespaces.

### 11. Lazy load translations.
Split JSON per route; load on navigation. Reduces bundle ~30% for multi-language apps.

### 12. Detect device language.
`Intl.getCanonicalLocales()`, `expo-localization`, `react-native-localize`. Fallback chain: device → user pref → app default.

### 13. Date/time/number formatting.
Use `Intl.DateTimeFormat`, `Intl.NumberFormat` (Hermes 0.74+ has full Intl). Avoid moment for size; date-fns/dayjs with locales.

### 14. Currency formatting.
```ts
new Intl.NumberFormat('en-IN', { style:'currency', currency:'INR' }).format(125000); // ₹1,25,000.00
```

### 15. Pluralization.
i18next `count` param + `_one`/`_other`/etc. keys. Avoid string concat.

### 16. Accessible forms.
Group label + input with `accessibilityLabel`. Show error via `accessibilityLiveRegion="polite"` and tied to input.

### 17. Tab order / focus management.
RN doesn't auto-manage focus across screens. Use `AccessibilityInfo.setAccessibilityFocus(reactTag)` after navigation to set focus to header/title.

### 18. Animation + reduced motion.
`AccessibilityInfo.isReduceMotionEnabled()` → skip non-essential animations or use cross-fade only.

### 19. Touch target size.
Min 44×44pt iOS / 48dp Android. Wrap small icons with `hitSlop`.

### 20. Custom fonts.
iOS: add to `Info.plist` `UIAppFonts`. Android: place in `assets/fonts` + `react-native.config.js` `assets`. Use `expo-font` for Expo.

### 21. Variable fonts.
Supported (RN 0.74+). Use `fontVariationSettings` style prop for weight/width.

### 22. Right-to-left mirroring exceptions.
Numbers, brand logos, media controls — don't mirror. Use `I18nManager.isRTL` to conditionally style.

### 23. Test a11y in CI.
`@react-native-community/eslint-plugin-a11y`, manual TalkBack/VoiceOver passes per release. Storybook a11y addon for components.

### 24. Color-blind friendly palette.
Avoid red/green only signals; pair with icons or patterns. Use tools like Sim Daltonism. Status colors = red + ✕ icon, green + ✓.

### 25. End-to-end example: accessible OTP input.
```jsx
<View accessibilityLabel="Enter 6-digit OTP">
  {digits.map((d,i)=> (
    <TextInput key={i}
      value={d}
      keyboardType="number-pad"
      textContentType="oneTimeCode"
      autoComplete="sms-otp"
      maxLength={1}
      accessibilityLabel={`Digit ${i+1}`}
      onChangeText={v=>setDigit(i,v)}
    />
  ))}
</View>
```
