## 25. Last-mile cheatsheet

### Numbers to memorize about your own apps
- Cold start (before / after).
- Crash-free sessions %.
- DAU / MAU.
- App size (IPA / APK).
- P95 API latency.
- # of releases / month.
- Team size, mentees, RFCs authored.

### Words to use (lead-track vocab)
Architected, Authored, Migrated, Owned, Drove, Established, Mentored, Productionized, Profiled, Reduced, Scaled, Shipped, Standardized, Unblocked.

### Words to avoid
"Worked on", "Helped with", "Was involved in", "Just", "Basically", "Try to", "Sort of".

### Recruiter screen — prep these 5 cold
1. Tell me about yourself (90 sec).
2. Why looking?
3. What kind of role?
4. Notice period?
5. Expected CTC? (anchor high, deflect current.)

### Final 24-hr checklist before any loop
- [ ] Re-read company's product + recent news (30 min).
- [ ] Re-read JD; map 3 of your bullets to it.
- [ ] Have 5 questions ready to ask them.
- [ ] Test mic/camera, charge laptop, water bottle.
- [ ] Sleep 7+ hrs. No new topics night before.

---

# APPENDICES (everything inlined — no jumping)

---



---

## Top 25 Q&A — Last-mile cheatsheet (rapid-fire)

> One-line answers. Drill these the night before any onsite.

### 1. New arch components?
JSI + Fabric + TurboModules + Codegen + Hermes.

### 2. Hermes default since?
RN 0.70.

### 3. `useNativeDriver: true` supports?
Only `transform` + `opacity`.

### 4. FlatList vs FlashList?
FlashList recycles cells, needs `estimatedItemSize`.

### 5. MMKV over AsyncStorage because?
Sync, ~30x faster, encrypted.

### 6. Stale closure fix?
Functional updater `setX(prev => ...)`.

### 7. Most-asked TS utility?
`Pick`, `Omit`, `Partial`, `Record`.

### 8. Discriminated union benefit?
Exhaustive narrowing in `switch`.

### 9. JWT pitfall?
`alg: none` + missing exp/aud verify.

### 10. PKCE solves?
Auth code interception.

### 11. Cert pinning lib?
`react-native-ssl-pinning`.

### 12. Detox vs Maestro?
Detox = JS gray-box; Maestro = YAML black-box.

### 13. EAS Update vs CodePush?
CodePush deprecated; use EAS Update.

### 14. Sentry sample rates?
Errors 100%, traces 10–20%.

### 15. Optimistic mutation in RQ?
`onMutate` snapshot → revert in `onError`.

### 16. Reanimated worklet runs on?
UI thread via JSI.

### 17. KYC flow modeling?
XState state machine.

### 18. Idempotency key purpose?
Dedupe retried writes.

### 19. iOS biometry property?
`BiometryCurrentSet`.

### 20. Android secure storage?
EncryptedSharedPreferences + Keystore.

### 21. Android 13+ push permission?
`POST_NOTIFICATIONS`.

### 22. Universal Link prerequisite?
`apple-app-site-association` JSON.

### 23. App Links prerequisite?
`assetlinks.json` + `autoVerify=true`.

### 24. Mobile a11y core props?
`accessibilityRole`, `accessibilityLabel`, `accessibilityState`.

### 25. RBI / DPDP Act 2023 implications?
Consent, encryption, breach reporting.

### 26. Cold start budget for fintech?
< 2s p95.

### 27. Crash-free SLO?
≥ 99.5%.

### 28. Throttle vs debounce?
Throttle = max rate; debounce = wait until idle.

### 29. Why prefer `Pressable`?
Single API, better perf, gesture interop.

### 30. Logout cleanup checklist?
Tokens + cache + push token + analytics user + nav reset.

### 31. Most common Sentry miss?
Source maps not uploaded.

### 32. Refresh-token race fix?
Single in-flight promise + queue.

### 33. iOS background fetch budget?
~30s window, opportunistic.

### 34. Android background work?
WorkManager.

### 35. Bundle-size win #1?
Replace moment with date-fns/dayjs.

### 36. Best perf flag combo?
Hermes + inline requires + ProGuard/R8.

### 37. Start RN debug.
`Cmd+D` (iOS sim), `Cmd+M` (Android emu).

### 38. Detect RTL?
`I18nManager.isRTL`.

### 39. Validate API at boundary?
Zod (`z.object(...).parse(json)`).

### 40. Protect against deep-link auto-execute?
Always require auth + user confirmation.

### 41. Sev1 first action?
Acknowledge → kill-switch → comm → fix.

### 42. Always quantify impact in answers?
Yes — numbers (%, ms, MAU) win interviews.

### 43. STAR ratio?
20% S+T, 60% A, 20% R.

### 44. Behavioral red flag to avoid?
Blaming others; "we" without your specific role.

### 45. Closing question to ask?
"What does success look like in 90 days, and what's the path Senior → Lead here?"

### 46. Comp anchor opener?
Anchor on your **role-level band** researched on levels.fyi / AmbitionBox / Glassdoor. Never disclose current number first.

### 47. When to walk away?
After 3 lowball rounds + no movement + no comp transparency.

### 48. Number of competing offers ideal?
2–3 active for negotiation leverage.

### 49. Joining bonus ask?
1–2 months of base.

### 50. Final mindset?
Calm, specific, measurable. Show, don't tell.
