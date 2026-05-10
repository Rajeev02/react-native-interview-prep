# THE PLAN — Single Unified Learning Path

> **One plan. One path. No more juggling.** This file replaces the multiple schedules scattered across [Appendix B](appendix/B-30-day-schedule.md) (30-day basics→advanced) and [Appendix N](appendix/N-14-day-sprint.md) (14-day final sprint). Those still exist as detailed references, but this is the **single track to follow**.
>
> **Total:** 45 days study + ongoing loops.
> **Cadence:** 6–8 hrs/day, 6 days/week, 1 rest day per week.
> **Goal:** ₹40+ LPA floor → ₹45–55 LPA target (Senior/Lead RN, India Tier S/A).

---

## How this plan is structured

| Phase | Days | Theme | Mode |
|---|---|---|---|
| **Phase 1 — Foundations** | 1–7 | JS / TS / React fundamentals | Read + code |
| **Phase 2 — RN core + perf** | 8–14 | Architecture, Hermes, perf, native modules, debugging | Read + code + profile |
| **Phase 3 — Production stack** | 15–21 | State, nav, networking, auth, offline, push, security | Read + build |
| **Phase 4 — Quality + ops** | 22–27 | a11y, testing, CI/CD, observability, system design, DSA | Read + practice |
| **Phase 5 — Career mechanics** | 28–31 | Behavioral, resume, LinkedIn, applications | Polish + outreach |
| **Phase 6 — Final sprint** | 32–45 | Re-grounding + drilling + mocks + diagrams | Synthesis only |
| **Phase 7 — Loops** | 46+ | Active interviews | Per-loop prep + post-mortem |

---

## Daily template (every day, 8 hrs)

| Block | Min | What |
|---|---|---|
| Theory read | 90 | Today's `docs/` chapter(s) |
| Hands-on | 90 | Build / profile / debug today's artifact |
| Q&A drill | 60 | Today's section in [Appendix L](appendix/L-50q-drill-bank.md) — speak aloud ≤60s/Q |
| DSA | 60 | 1–2 problems from [docs/22](docs/22-dsa.md) / [Appendix L.22](appendix/L-50q-drill-bank.md#l22--dsa-50) |
| Recall | 60 | Whiteboard a diagram from [Appendix M](appendix/M-architecture-diagrams.md) or recite Must-answer Qs |
| Review | 30 | Update tracker, mark fluent Qs |
| Buffer | 30 | Slack |

If short on time, drop in this order: DSA → Theory → Recall → Drill (drill is non-negotiable).

---

## Tracker (set up Day 0)

Create one spreadsheet with columns:
- `day` `phase` `topic` `theory_done` `hands_on_done` `drill_count` `dsa_count` `mock_score` `notes`
- Separate sheet for L-bank: `section` `q_num` `fluent_y_n` `last_drilled`
- Separate sheet for STAR: `story` `45s_recorded` `120s_recorded` `last_rehearsed`

---

# PHASE 1 — Foundations (Days 1–7)

> Goal: pass the JS/TS/React screen-out filter cold. ~40% of loops die here.

### Day 1 — JavaScript core
- **Read:** [docs/02](docs/02-javascript-core.md)
- **Drill:** [L.2 Q1–25](appendix/L-50q-drill-bank.md#l2--javascript-core-50)
- **Hands-on:** 5 closure puzzles + 5 `this` puzzles. Implement `pLimit(n)` from scratch.
- **DSA:** L.22 #1, #2 (reverse string, two-sum)
- **Verify:** Stale closure in `useEffect` — show + fix in 60s ☐

### Day 2 — JS async + event loop
- **Read:** [docs/02 §async](docs/02-javascript-core.md)
- **Drill:** [L.2 Q26–50](appendix/L-50q-drill-bank.md#l2--javascript-core-50)
- **Hands-on:** Implement `retry(fn,n,delay)`, `debounce`, `throttle`, `memoize`, `Promise.all` polyfill.
- **DSA:** L.22 #5, #6 (Kadane, move zeroes)
- **Verify:** Output of `console.log + setTimeout + Promise.then` interleave ☐

### Day 3 — TypeScript
- **Read:** [docs/03](docs/03-typescript.md)
- **Drill:** [L.3 Q1–50](appendix/L-50q-drill-bank.md#l3--typescript-50)
- **Hands-on:** Generic `useFetch<T>`, typed `RootStackParamList`, Zod schema for one API.
- **DSA:** L.22 #11 (longest substring without repeat)
- **Verify:** `type` vs `interface` decision — when each ☐

### Day 4 — React + hooks
- **Read:** [docs/04 §1–§4](docs/04-react-deep-dive.md)
- **Drill:** [L.4 Q1–25](appendix/L-50q-drill-bank.md#l4--react-deep-dive-50)
- **Hands-on:** Build `useDebounce`, `usePrevious`, `useToggle`, `useInterval`, `useAsync`.
- **DSA:** L.22 #18, #19 (linked list reverse, cycle)
- **Verify:** When does `React.memo` NOT help? ☐

### Day 5 — React advanced + perf
- **Read:** [docs/04 rest](docs/04-react-deep-dive.md), [docs/26](docs/26-lifecycles.md)
- **Drill:** [L.4 Q26–50](appendix/L-50q-drill-bank.md#l4--react-deep-dive-50)
- **Hands-on:** Profile sample app with React DevTools, fix 3 unnecessary re-renders.
- **DSA:** L.22 #25, #26 (BFS, inorder iterative)
- **Whiteboard:** [M.3 (render→commit)](appendix/M-architecture-diagrams.md#m3--render--reconcile--commit-fabric)
- **Verify:** Top 5 React anti-patterns ☐

### Day 6 — Mock + DSA day
- **Mock 1 (45 min, recorded):** 8 Qs random from L.2, L.3, L.4. Self-grade.
- **DSA:** 5 mediums covering arrays, hashmap, two-pointer.
- **Polish:** rerecord weakest answer.

### Day 7 — Rest
- Light skim of week's notes only. No new content.

---

# PHASE 2 — RN Core + Performance (Days 8–14)

### Day 8 — RN architecture (old + new)
- **Read:** [docs/05](docs/05-rn-architecture.md)
- **Drill:** [L.5 Q1–50](appendix/L-50q-drill-bank.md#l5--rn-architecture-50)
- **Hands-on:** Fresh RN app, toggle Hermes on/off, measure cold start.
- **Whiteboard:** [M.1 + M.2](appendix/M-architecture-diagrams.md#m1--rn-old-architecture-bridge--paper) from memory.
- **DSA:** L.22 #15, #16 (min stack, daily temps)
- **Verify:** JSI vs Bridge in 90s ☐

### Day 9 — Hermes + Metro + bundle
- **Read:** [docs/06](docs/06-hermes-metro-bundle.md)
- **Drill:** [L.6 Q1–50](appendix/L-50q-drill-bank.md#l6--hermes-metro-bundle-startup-50)
- **Hands-on:** Profile cold start with Hermes profiler. Apply `inlineRequires`. Reduce 30%.
- **Whiteboard:** [M.4 (startup)](appendix/M-architecture-diagrams.md#m4--app-startup-sequence-cold-start)
- **DSA:** L.22 #23 (LRU cache from scratch)
- **Verify:** Hermes vs JSC tradeoffs ☐

### Day 10 — Performance: lists, animations, images
- **Read:** [docs/07](docs/07-performance.md)
- **Drill:** [L.7 Q1–50](appendix/L-50q-drill-bank.md#l7--performance-50)
- **Hands-on:** Migrate 1000-row FlatList → FlashList. Measure FPS gain.
- **Whiteboard:** [M.5 (Reanimated worklet)](appendix/M-architecture-diagrams.md#m5--reanimated-worklet-threading)
- **DSA:** L.22 #17 (sliding window max)
- **Verify:** 5 list-perf knobs ☐

### Day 11 — Native modules
- **Read:** [docs/08](docs/08-native-modules.md)
- **Drill:** [L.8 Q1–50](appendix/L-50q-drill-bank.md#l8--native-modules-swift--kotlin-50)
- **Hands-on:** Write Swift + Kotlin "battery level + charging state" module. Emit events.
- **Whiteboard:** [M.15 (TM migration)](appendix/M-architecture-diagrams.md#m15--native-module-bridge--turbomodule-migration)
- **DSA:** L.22 #20, #21 (merge two/K sorted)
- **Verify:** TurboModule vs old NativeModule in 60s ☐

### Day 12 — Debugging deep day
- **Read:** [docs/09](docs/09-debugging.md)
- **Drill:** [L.9 Q1–50](appendix/L-50q-drill-bank.md#l9--debugging-50)
- **Hands-on:** Plant a memory leak (uncleaned listener). Find via Instruments + Android Profiler. Fix. Symbolicate one crash.
- **DSA:** L.22 #14 (valid parentheses)
- **Verify:** 5 debug tools, when each shines ☐

### Day 13 — Mock + DSA day
- **Mock 2 (60 min):** RN deep-dive — 8 Qs from L.5–L.9.
- **DSA:** 5 mediums (linked list, tree, BFS/DFS).
- **Polish:** redo M.1, M.2 whiteboards under 2 min each.

### Day 14 — Rest
- Light skim. Confirm Phase 2 sample-app artifacts pushed to GitHub.

---

# PHASE 3 — Production Stack (Days 15–21)

### Day 15 — State management
- **Read:** [docs/10](docs/10-state-management.md)
- **Drill:** [L.10 Q1–50](appendix/L-50q-drill-bank.md#l10--state-management-50)
- **Hands-on:** Build 1 screen using RTK + Zustand + React Query (each for the right job).
- **Whiteboard:** [M.14 (state decision tree)](appendix/M-architecture-diagrams.md#m14--state-management-decision-tree)
- **DSA:** L.22 #36, #37 (climbing stairs, house robber)
- **Verify:** RQ vs Redux decision in 30s ☐

### Day 16 — Navigation + deep linking
- **Read:** [docs/11](docs/11-navigation-deep-linking.md)
- **Drill:** [L.11 Q1–50](appendix/L-50q-drill-bank.md#l11--navigation--deep-linking-50)
- **Hands-on:** Typed RN project with auth gate + universal link + custom-scheme fallback. Test with `xcrun simctl openurl` + `adb shell am start`.
- **Whiteboard:** [M.6, M.7](appendix/M-architecture-diagrams.md#m6--navigation-stack-native-stack)
- **DSA:** L.22 #31, #32 (islands, course schedule)
- **Verify:** AASA + assetlinks verification flow ☐

### Day 17 — Networking
- **Read:** [docs/12](docs/12-networking.md)
- **Drill:** [L.12 Q1–50](appendix/L-50q-drill-bank.md#l12--networking-rest-graphql-websockets-50)
- **Hands-on:** Axios with interceptor + AbortController + retry-with-backoff. WS reconnect demo.
- **Whiteboard:** [M.18 (request lifecycle)](appendix/M-architecture-diagrams.md#m18--end-to-end-request-lifecycle-rn--backend--telemetry)
- **DSA:** L.22 #10 (top-K frequent)
- **Verify:** Idempotency + circuit breaker explained ☐

### Day 18 — Auth, sessions, tokens
- **Read:** [docs/13](docs/13-auth-sessions-tokens.md)
- **Drill:** [L.13 Q1–50](appendix/L-50q-drill-bank.md#l13--auth-sessions-tokens-50)
- **Hands-on:** OAuth + PKCE flow with `expo-auth-session` or equivalent. Single-flight refresh wrapper.
- **Whiteboard:** [M.8, M.9](appendix/M-architecture-diagrams.md#m8--auth-oauth-20--pkce-flow)
- **DSA:** L.22 #43 (subsets backtracking)
- **Verify:** Draw OAuth + PKCE end-to-end ☐

### Day 19 — Offline-first + storage
- **Read:** [docs/14](docs/14-offline-storage.md)
- **Drill:** [L.14 Q1–50](appendix/L-50q-drill-bank.md#l14--offline-first--storage-50)
- **Hands-on:** Offline todo with MMKV + outbox + sync on reconnect. Conflict reconciliation (LWW).
- **Whiteboard:** [M.10 (offline sync)](appendix/M-architecture-diagrams.md#m10--offline-first-sync-engine)
- **DSA:** L.22 #38 (LIS)
- **Verify:** Conflict strategies (LWW vs CRDT) ☐

### Day 20 — Push notifications + Security
- **Read:** [docs/15](docs/15-push-notifications.md), [docs/16](docs/16-mobile-security.md)
- **Drill:** [L.15](appendix/L-50q-drill-bank.md#l15--push-notifications-50), [L.16](appendix/L-50q-drill-bank.md#l16--mobile-security-50) (50 each)
- **Hands-on:** Secure token store wrapper (Keychain/Keystore). Cert-pinning config. Push handler with deep link.
- **Whiteboard:** [M.11 (push)](appendix/M-architecture-diagrams.md#m11--push-notification-architecture)
- **DSA:** L.22 #49 (trie)
- **Verify:** OWASP Mobile Top 10 + 1 mitigation each ☐

### Day 21 — Mock + DSA day
- **Mock 3 (60 min):** Production stack — 8 Qs from L.10–L.16.
- **DSA:** 5 mediums (DP-easy, sliding window).
- **Confirm:** Phase 3 artifacts (3 sample apps minimum) pushed to GitHub per [appendix/H](appendix/H-gap-fill.md).

---

# PHASE 4 — Quality + Ops (Days 22–27)

### Day 22 — a11y + i18n
- **Read:** [docs/17](docs/17-accessibility-i18n.md)
- **Drill:** [L.17 Q1–50](appendix/L-50q-drill-bank.md#l17--a11y-color-fonts-i18n-50)
- **Hands-on:** Add a11y labels + roles + RTL support to one sample app. Test with VoiceOver + TalkBack.
- **Verify:** Touch targets, contrast, font scaling ☐

### Day 23 — Testing
- **Read:** [docs/18](docs/18-testing.md)
- **Drill:** [L.18 Q1–50](appendix/L-50q-drill-bank.md#l18--testing-50)
- **Hands-on:** 5 RNTL component tests + 1 Maestro/Detox e2e flow + 1 hook test with `renderHook`.
- **DSA:** L.22 #28 (LCA)
- **Verify:** Mock pyramid ratios ☐

### Day 24 — CI/CD + releases
- **Read:** [docs/19](docs/19-cicd-releases.md), [appendix/J](appendix/J-expo-router-config-plugins.md)
- **Drill:** [L.19 Q1–50](appendix/L-50q-drill-bank.md#l19--cicd-eas-fastlane-releases-50)
- **Hands-on:** GitHub Actions: lint → test → EAS build preview → EAS submit. Add Sentry sourcemap upload.
- **Whiteboard:** [M.12 (CI/CD)](appendix/M-architecture-diagrams.md#m12--cicd-pipeline-eas--fastlane)
- **Verify:** Phased iOS vs staged Android rollout ☐

### Day 25 — Observability
- **Read:** [docs/20](docs/20-observability.md)
- **Drill:** [L.20 Q1–50](appendix/L-50q-drill-bank.md#l20--observability-50)
- **Hands-on:** Sentry + Crashlytics integrated. Custom transactions. PII scrub in `beforeSend`.
- **Whiteboard:** [M.13 (observability)](appendix/M-architecture-diagrams.md#m13--observability-data-flow)
- **DSA:** L.22 #30 (serialize/deserialize tree)
- **Verify:** Crash-free user rate target + measurement ☐

### Day 26 — Mobile system design Round 1
- **Read:** [docs/21](docs/21-system-design.md)
- **Memorize:** [M.16 (10-step skeleton)](appendix/M-architecture-diagrams.md#m16--mobile-system-design-template)
- **Drill (timed, 45 min each):** WhatsApp chat sync, Razorpay payment SDK.
- **Self-record one** and listen back.
- **Verify:** All 10 boxes covered + telemetry mentioned ☐

### Day 27 — DSA focused day + System design Round 2
- **DSA:** 8 mediums covering all patterns + LRU cache from scratch.
- **System design (45 min each):** Instagram feed, Uber rider tracking, Notification system at scale.

---

# PHASE 5 — Career Mechanics (Days 28–31)

### Day 28 — Behavioral + STAR
- **Read:** [docs/23](docs/23-behavioral-star.md), [appendix/E](appendix/E-star-story-bank.md)
- **Hands-on:** Voice-record all 10 STAR stories, 90–120s each. Listen back. Re-record any >120s.
- **Drill:** [L.23 Q1–50](appendix/L-50q-drill-bank.md#l23--behavioral--star-50) — mental answer ≤45s each.
- **Verify:** Each story has metric in Result ☐

### Day 29 — Resume + LinkedIn + Naukri
- **Read:** [docs/24](docs/24-resume-linkedin-negotiation.md), [appendix/C](appendix/C-resume-template.md), [appendix/D](appendix/D-linkedin-naukri.md)
- **Hands-on:** Final resume `Rajeev_Joshi_RN_Lead_2026.pdf`. Every bullet has Action + Tech + Metric.
- **LinkedIn:** About in 3 paras, Featured pinned, banner, top-3 skills, Open-to-Work recruiters-only.
- **Naukri:** 100% completeness.

### Day 30 — Outreach blitz (Tier S top-8)
- **Read:** [appendix/A](appendix/A-top-20-companies.md)
- **Apply:** Tier S top-8 with referral DMs (10 referral DMs sent today).
- **Drill:** [L.24 Q1–50](appendix/L-50q-drill-bank.md#l24--resume--linkedin--negotiation-50) recruiter answers — TMAY, why looking, notice, expected/current CTC deflection.

### Day 31 — Outreach Tier A + recruiter screen prep
- **Apply:** Tier A 6 cos.
- **Drill:** Cold-deliver 5 recruiter answers in mirror or recording.
- **Verify:** No filler words, ≤60s each ☐

---

# PHASE 6 — Final Sprint (Days 32–45)

> **No new content from here.** Synthesis only. This phase is the old [Appendix N](appendix/N-14-day-sprint.md) realigned.

### Day 32 — JS + TS re-grounding
- Re-read [docs/02](docs/02-javascript-core.md), [docs/03](docs/03-typescript.md)
- Speed-pass [L.2 + L.3](appendix/L-50q-drill-bank.md#l2--javascript-core-50) — mark unfluent
- Whiteboard `pLimit`, generic `useFetch`

### Day 33 — React + RN architecture re-grounding
- Re-read [docs/04](docs/04-react-deep-dive.md), [docs/05](docs/05-rn-architecture.md), [docs/26](docs/26-lifecycles.md)
- Speed-pass [L.4 + L.5](appendix/L-50q-drill-bank.md#l4--react-deep-dive-50)
- Whiteboard [M.1, M.2, M.3, M.5](appendix/M-architecture-diagrams.md) from memory

### Day 34 — Hermes + Performance re-grounding
- Re-read [docs/06](docs/06-hermes-metro-bundle.md), [docs/07](docs/07-performance.md)
- Speed-pass [L.6 + L.7](appendix/L-50q-drill-bank.md#l6--hermes-metro-bundle-startup-50)
- Capture Hermes profiler on sample app, fix one re-render

### Day 35 — Native modules + Debugging re-grounding
- Re-read [docs/08](docs/08-native-modules.md), [docs/09](docs/09-debugging.md)
- Speed-pass [L.8 + L.9](appendix/L-50q-drill-bank.md#l8--native-modules-swift--kotlin-50)
- Symbolicate one stack trace

### Day 36 — State + Nav + Networking speed-pass
- Re-read [docs/10](docs/10-state-management.md), [docs/11](docs/11-navigation-deep-linking.md), [docs/12](docs/12-networking.md)
- Speed-pass [L.10 + L.11 + L.12](appendix/L-50q-drill-bank.md) (≤30s/Q)
- Whiteboard [M.6, M.7, M.18](appendix/M-architecture-diagrams.md)

### Day 37 — Auth + Offline + Push + Security speed-pass
- Re-read [docs/13–16](docs/13-auth-sessions-tokens.md)
- Speed-pass [L.13 + L.14 + L.15 + L.16](appendix/L-50q-drill-bank.md)
- Whiteboard [M.8, M.9, M.10, M.11](appendix/M-architecture-diagrams.md)

### Day 38 — a11y + Testing + CI/CD + Observability speed-pass
- Re-read [docs/17–20](docs/17-accessibility-i18n.md)
- Speed-pass [L.17 + L.18 + L.19 + L.20](appendix/L-50q-drill-bank.md)
- Whiteboard [M.12, M.13](appendix/M-architecture-diagrams.md)
- **Mock 4 (30 min, self-recorded):** 10 random Qs from L.4–L.20

### Day 39 — System design Round 3
- Re-read [docs/21](docs/21-system-design.md)
- 2 fresh designs, 45 min each (timed): pick from L.21 list not done in Phase 4
- Convert each to 3-min spoken summary

### Day 40 — System design Round 4
- 3 more designs, 45 min each
- Self-record one, listen back

### Day 41 — DSA refresh
- Re-read [docs/22](docs/22-dsa.md)
- Solve 10 mid-difficulty L.22 Qs (#7, #11, #14, #17, #21, #23, #25, #31, #36, #43), 25 min each
- Speak approach for remaining 40

### Day 42 — Behavioral re-rehearsal
- Re-read [docs/23](docs/23-behavioral-star.md)
- Voice-record all 10 STAR again. Listen back. Tighten.
- Speed-pass [L.23](appendix/L-50q-drill-bank.md#l23--behavioral--star-50)

### Day 43 — **Full mock loop simulation #1** (4 hrs with peer)
- Round 1 (60 min): RN deep-dive — 8 Qs from L.4 + L.5 + L.7 + L.8
- Round 2 (60 min): system design — fresh problem
- Round 3 (45 min): coding — 1 medium DSA + 1 RN-flavored (e.g., `useDebouncedQuery` with cancellation)
- Round 4 (45 min): behavioral — interviewer picks 5 from L.23
- **Debrief (1 hr):** self-grade red/yellow/green. Write 3 specific weaknesses.

### Day 44 — Targeted weakness drill + outreach refresh
- Hit only the 3 weaknesses from Day 43. Re-read source docs + redo relevant L Qs.
- Re-do worst round with fresh question.
- Reach out to 5 more recruiters. Apply to 5 more roles.

### Day 45 — **Final mock + cheatsheet + rest**
- **Full mock loop simulation #2** (3 hrs, peer if possible) — fresh design + DSA + STAR
- Read [docs/25 cheatsheet](docs/25-cheatsheet.md) + [appendix/Z](appendix/Z-final-verification.md) end-to-end
- Test webcam, mic, lighting, screen share, whiteboard tool (Excalidraw / tldraw)
- Stable internet + backup tether
- **No new content after 6pm. Sleep 8h.**

### Final go/no-go (Day 45 evening)
- [ ] Both mocks (Day 43 + 45) majority green?
- [ ] All 10 STAR stories ≤120s?
- [ ] 5 system designs deliverable in 25 min?
- [ ] L bank: ≥80% Qs marked fluent?
- [ ] 5+ active conversations with recruiters?

If 4/5 green → start scheduling loops Day 46. If <4 → repeat Days 43–45 for one week.

---

# PHASE 7 — Active Loops (Day 46+)

### Per-interview prep (night before)
- Re-skim [docs/25 cheatsheet](docs/25-cheatsheet.md)
- Re-read company row in [appendix/A](appendix/A-top-20-companies.md)
- Pick 2 STAR stories most relevant to that company
- Sleep 8h. No code after 9pm.

### Per-interview post-mortem (within 1h after)
- What went well? (3 bullets)
- What to fix? (3 bullets)
- Add new Q to L bank if asked
- Update STAR stories if new strong moment came up

### Weekly during loops
- **Mon morning:** review last week's debriefs, pick top-3 fixes
- **Wed:** 1 mock with peer
- **Fri:** pipeline review — apps in flight, offers, decisions

### When you get an offer
- Per [docs/24](docs/24-resume-linkedin-negotiation.md): never accept on first call
- Ask for written breakdown
- Anchor counter at top of band per [docs/01](docs/01-profile-positioning.md)
- Use competing offers as leverage, never bluff
- Get to ≥2 offers in same window before deciding

---

## Hands-on artifacts checklist (must exist by Day 27)

Pushed to your GitHub:

- [ ] App 1 — perf playground: 1000-row FlashList + Reanimated worklet animations + Hermes profiling notes
- [ ] App 2 — auth + deep links: OAuth+PKCE + universal link + auth-gated routes
- [ ] App 3 — offline-first: MMKV + outbox + sync + conflict reconciliation
- [ ] (Optional) App 4 — payment SDK skeleton with idempotency + retry
- [ ] (Optional) App 5 — chat with WebSocket + offline queue
- [ ] At least one custom Native Module (Swift + Kotlin) shipped in App 1 or its own repo
- [ ] CI/CD pipeline (GH Actions + EAS) on at least one app
- [ ] Sentry + analytics integrated on at least one app

---

## Anti-patterns to avoid

- ❌ Reading new docs after Day 31 — synthesis only from there
- ❌ Skipping voice recording — interviews are spoken, not read
- ❌ Solo prep for system design — get peer mocks in Phase 6
- ❌ Cramming DSA after Day 41 — reinforce patterns, no new tricks
- ❌ Disclosing current CTC early — defer per [docs/24](docs/24-resume-linkedin-negotiation.md)
- ❌ Negotiating without ≥2 competing offers
- ❌ All-nighters before any loop — sleep beats one extra topic

---

## End-state success criteria

By Day 45 you should be able to:

1. Whiteboard [M.1, M.2, M.4, M.8, M.16](appendix/M-architecture-diagrams.md) from memory in ≤2 min each
2. Speak any L-bank Q in ≤60s with example or code
3. Deliver any of 5 system designs in 25 min covering all 10 boxes
4. Tell any of 10 STAR stories in 90–120s with metric in Result
5. Solve a medium DSA in ≤25 min, brute → optimized articulated
6. Negotiate to ≥₹45 LPA fixed with 1 competing-offer leverage

When all 6 hold → loops are routine, not stressful. **You're ready.**

---

## Reference index (everything else)

- Old detailed schedule (kept for cross-reference): [appendix/B](appendix/B-30-day-schedule.md)
- Old final-sprint detail (now folded into Phase 6): [appendix/N](appendix/N-14-day-sprint.md)
- Q&A drill bank: [appendix/L](appendix/L-50q-drill-bank.md)
- Diagrams: [appendix/M](appendix/M-architecture-diagrams.md)
- Q&A short+deep: [appendix/F](appendix/F-qa-bank-extended.md), [appendix/G](appendix/G-qa-bank-deep.md)
- Gap-fill (sample apps + ADRs + scripts): [appendix/H](appendix/H-gap-fill.md)
- Six engineering tracks (rubric): [appendix/I](appendix/I-six-engineering-tracks.md)
- Top-20 companies: [appendix/A](appendix/A-top-20-companies.md)
- STAR bank: [appendix/E](appendix/E-star-story-bank.md)
- YouTube refs: [appendix/K](appendix/K-youtube-references.md)
- Final coverage verification: [appendix/Z](appendix/Z-final-verification.md)

End of THE PLAN.
