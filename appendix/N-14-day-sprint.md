# Appendix N — 14-Day Final Sprint Checklist

> **For:** the last 2 weeks before active interview loops. Assumes you've read `docs/02–24` at least once and have built ≥1 sample app.
>
> **Daily budget:** 3–4 hrs (weekday) / 6–8 hrs (weekend). If you can't hit this, stretch the sprint to 21 days but keep the order.
>
> **Tracking:** check off boxes literally — do not skip "verify" rows.

---

## Pre-flight (Day 0, evening before Day 1)

- [ ] Print or open [Appendix L](L-50q-drill-bank.md) in a side window.
- [ ] Open [Appendix M](M-architecture-diagrams.md) — bookmark M.1, M.2, M.4, M.8, M.16.
- [ ] Resume final version saved as `Rajeev_Joshi_RN_Lead_2026.pdf` per [C](C-resume-template.md).
- [ ] LinkedIn "Open to Work" set to recruiters-only per [D](D-linkedin-naukri.md).
- [ ] Calendar blocks: 7–10am study, 10–11am drill, evening 1hr mock or build.
- [ ] STAR tracker spreadsheet with 10 stories from [E](E-star-story-bank.md).
- [ ] Recording app installed (Voice Memos / Otter) for self-mock.

---

## Week 1 — Re-grounding + Drill (Days 1–7)

### Day 1 — JS + TS fundamentals
**Morning study (2h)**
- [ ] Re-read [02-javascript-core.md](../docs/02-javascript-core.md) end-to-end.
- [ ] Re-read [03-typescript.md](../docs/03-typescript.md).

**Drill (1h)**
- [ ] Speak L.2 Q1–50 out loud (≤60s each).
- [ ] Speak L.3 Q1–50.
- [ ] Mark unfluent Qs `[ ]` for revisit.

**Code (1h)**
- [ ] Implement on whiteboard / paper: `pLimit`, `retry`, `debounce`, `deepClone`.
- [ ] Type a generic `useFetch<T>` hook from scratch.

**Verify**
- [ ] Can answer "stale closure in useEffect" in 60s with code? ☐

---

### Day 2 — React + RN architecture
**Morning (2h)**
- [ ] Re-read [04-react-deep-dive.md](../docs/04-react-deep-dive.md).
- [ ] Re-read [05-rn-architecture.md](../docs/05-rn-architecture.md).
- [ ] Re-read [26-lifecycles.md](../docs/26-lifecycles.md).

**Drill (1h)**
- [ ] L.4 Q1–50, L.5 Q1–50.

**Diagram (1h)**
- [ ] Whiteboard M.1 (old arch) and M.2 (new arch) from memory. Compare.
- [ ] Whiteboard M.3 (render→commit) and M.5 (Reanimated worklet).

**Verify**
- [ ] Can explain JSI vs Bridge in 90s? ☐
- [ ] Can name 5 things Fabric changes vs Paper? ☐

---

### Day 3 — Hermes + Performance
**Morning (2h)**
- [ ] Re-read [06-hermes-metro-bundle.md](../docs/06-hermes-metro-bundle.md).
- [ ] Re-read [07-performance.md](../docs/07-performance.md).

**Drill (1h)**
- [ ] L.6 Q1–50, L.7 Q1–50.

**Hands-on (1h)**
- [ ] Open one of your sample apps. Run Hermes profiler. Capture `.cpuprofile`.
- [ ] Identify slowest component re-render via React DevTools Profiler.
- [ ] Reduce one FlatList re-render with `React.memo` + `useCallback`.

**Verify**
- [ ] Can list 5 list-perf knobs (initialNumToRender, windowSize, etc.)? ☐
- [ ] Can compare Hermes vs JSC in 60s? ☐

---

### Day 4 — Native modules + Debugging
**Morning (2h)**
- [ ] Re-read [08-native-modules.md](../docs/08-native-modules.md).
- [ ] Re-read [09-debugging.md](../docs/09-debugging.md).

**Drill (1h)**
- [ ] L.8 Q1–50, L.9 Q1–50.

**Hands-on (1h)**
- [ ] Write a tiny TurboModule spec (TS) for `getDeviceTemperature(): Promise<number>`. Don't implement — just spec + codegen mental model.
- [ ] Symbolicate one stack trace from a Sentry / dev red-box.

**Verify**
- [ ] Can explain TM vs old NativeModule in 60s? ☐
- [ ] Can list 5 debug tools and when each shines? ☐

---

### Day 5 — State + Navigation + Networking
**Morning (2h)**
- [ ] Re-read [10-state-management.md](../docs/10-state-management.md), [11-navigation-deep-linking.md](../docs/11-navigation-deep-linking.md).
- [ ] Re-read [12-networking.md](../docs/12-networking.md).

**Drill (1h)**
- [ ] L.10, L.11, L.12 (50 each = 150 Qs; speed-pass at ≤30s).

**Diagram (1h)**
- [ ] Whiteboard M.6 (nav stack), M.7 (deep link), M.18 (request lifecycle).

**Verify**
- [ ] Can decide RQ vs Redux in 30s with criteria? ☐
- [ ] Can describe universal link verification (AASA + assetlinks)? ☐

---

### Day 6 — Auth + Offline + Push + Security
**Morning (3h)**
- [ ] Re-read [13](../docs/13-auth-sessions-tokens.md), [14](../docs/14-offline-storage.md), [15](../docs/15-push-notifications.md), [16](../docs/16-mobile-security.md).

**Drill (1.5h)**
- [ ] L.13, L.14, L.15, L.16 (200 Qs speed-pass).

**Diagram (1h)**
- [ ] Whiteboard M.8 (PKCE), M.9 (single-flight), M.10 (offline sync), M.11 (push).

**Verify**
- [ ] Can draw OAuth + PKCE end-to-end? ☐
- [ ] Can name top 5 OWASP Mobile risks + 1 mitigation each? ☐

---

### Day 7 — a11y, i18n, Testing, CI/CD, Observability
**Morning (3h)**
- [ ] Re-read [17](../docs/17-accessibility-i18n.md), [18](../docs/18-testing.md), [19](../docs/19-cicd-releases.md), [20](../docs/20-observability.md).

**Drill (1.5h)**
- [ ] L.17, L.18, L.19, L.20 (200 Qs).

**Diagram (1h)**
- [ ] Whiteboard M.12 (CI/CD), M.13 (observability).

**Mock (1h)**
- [ ] Self-record 30-min mock: pick 10 random Qs from L.4–L.20. Listen back, mark filler words.

**Verify**
- [ ] Crash-free user rate target + how to measure? ☐
- [ ] Can describe phased rollout iOS vs staged Android? ☐

---

## Week 2 — Synthesis + Mocks + Polish (Days 8–14)

### Day 8 — System Design Round 1
**Study (2h)**
- [ ] Re-read [21-system-design.md](../docs/21-system-design.md).
- [ ] Memorize M.16 (10-step skeleton).

**Drill (2h)**
- [ ] Whiteboard 2 designs end-to-end (45 min each, timed):
  - [ ] Design WhatsApp chat sync (offline + WS + ordering).
  - [ ] Design Razorpay payment SDK (idempotency + retry + PCI).
- [ ] Self-record one. Listen back.

**Verify**
- [ ] Did you cover all 10 boxes of M.16? ☐
- [ ] Did you mention telemetry + failure modes? ☐

---

### Day 9 — System Design Round 2
**Drill (3h)**
- [ ] Whiteboard 3 more designs (45 min each):
  - [ ] Instagram feed (pagination + image CDN).
  - [ ] Uber rider live tracking (location + WS/MQTT).
  - [ ] Notification system at scale (fan-out + token mgmt).

**Polish (1h)**
- [ ] Convert each design into a 3-minute spoken summary.

**Verify**
- [ ] Can deliver any of the 5 in 25 min cleanly? ☐

---

### Day 10 — DSA refresh
**Morning (3h)**
- [ ] Re-read [22-dsa.md](../docs/22-dsa.md).
- [ ] Solve from L.22: pick 10 mid-difficulty Qs (#7, #11, #14, #17, #21, #23, #25, #31, #36, #43).
- [ ] Time-box: 25 min/problem.

**Drill (1h)**
- [ ] Speak through the approach for the remaining 40 L.22 Qs (no coding, just plan + complexity).

**Verify**
- [ ] LRU cache from scratch in 20 min? ☐
- [ ] Two-pointer + sliding window pattern fluent? ☐

---

### Day 11 — Behavioral + STAR
**Morning (2h)**
- [ ] Re-read [23-behavioral-star.md](../docs/23-behavioral-star.md).
- [ ] Open [E-star-story-bank.md](E-star-story-bank.md). Confirm 10 stories cover: leadership, conflict, failure, ambiguity, scale, mentorship, prod incident, tech choice, deadline pressure, cross-team.

**Drill (2h)**
- [ ] Voice-record each of 10 stories at 90–120s. Listen back. Re-record any >120s.
- [ ] Speed-pass L.23 Q1–50 (mental answer ≤45s each).

**Verify**
- [ ] Each story has S/T/A/R clearly delineated? ☐
- [ ] Do you have a metric in every Action and Result? ☐

---

### Day 12 — Mock loop full simulation #1 (find a peer or self)
**Schedule (4h block)**
- [ ] Round 1 (60 min): RN deep-dive. Pick 8 Qs from L.4 + L.5 + L.7 + L.8.
- [ ] 10-min break.
- [ ] Round 2 (60 min): system design. Pick 1 from Day 8/9 list, but a fresh variant.
- [ ] 10-min break.
- [ ] Round 3 (45 min): coding. 1 medium DSA + 1 RN-flavored (e.g., type a `useDebouncedQuery` hook with cancellation).
- [ ] 10-min break.
- [ ] Round 4 (45 min): behavioral. Interviewer picks 5 Qs from L.23.

**Debrief (1h)**
- [ ] Self-grade each round red/yellow/green.
- [ ] Write 3 specific weaknesses to fix Day 13.

---

### Day 13 — Targeted weakness drill + Resume polish
**Morning (3h)**
- [ ] Hit only the 3 weaknesses from Day 12. Re-read source docs + redo relevant L Qs.
- [ ] Re-do worst round of Day 12 with a fresh question.

**Resume + LinkedIn polish (1h)**
- [ ] Re-read [24-resume-linkedin-negotiation.md](../docs/24-resume-linkedin-negotiation.md).
- [ ] Verify resume bullets: every bullet has Action + Tech + Metric.
- [ ] LinkedIn About: 3 paras per [D](D-linkedin-naukri.md).
- [ ] Naukri profile completeness: 100%.

**Outreach (1h)**
- [ ] Reach out to 5 recruiters from [A-top-20-companies.md](A-top-20-companies.md).
- [ ] Apply to 5 specific Senior/Lead RN roles.

**Verify**
- [ ] All 3 weaknesses now feel green? ☐

---

### Day 14 — Final mock + cheatsheet + rest
**Morning mock (3h)**
- [ ] Full loop simulation #2 with a peer if possible. Different design + different DSA + different STAR Qs.

**Cheatsheet pass (1h)**
- [ ] Read [25-cheatsheet.md](../docs/25-cheatsheet.md) end-to-end.
- [ ] Read [Z-final-verification.md](Z-final-verification.md).

**Logistics (1h)**
- [ ] Test webcam, mic, lighting, IDE share screen, whiteboard tool (Excalidraw / tldraw).
- [ ] Stable internet. Backup tether.
- [ ] Quiet room booked for next 4 weeks of loops.
- [ ] Charged laptop. Water. Pen + 5 sheets paper for diagrams.

**Rest**
- [ ] No new content after 6pm. Sleep 8h.

**Verify (final go/no-go)**
- [ ] All green on Day 12+14 mocks? ☐
- [ ] All 10 STAR stories ≤120s? ☐
- [ ] 5 system designs deliverable in 25 min? ☐
- [ ] L bank: ≥80% Qs marked fluent? ☐
- [ ] 5 active conversations with recruiters? ☐

If 4/5 green → start scheduling loops Day 15. If <4 → extend by 7 days, do Days 12–14 again.

---

## Beyond Day 14 — During active loops

### Per-interview prep (night before)
- [ ] Re-skim cheatsheet [25-cheatsheet.md](../docs/25-cheatsheet.md).
- [ ] Re-read company row in [A-top-20-companies.md](A-top-20-companies.md).
- [ ] Pick 2 STAR stories most relevant to company.
- [ ] Sleep 8h. No code after 9pm.

### Per-interview post-mortem (within 1h)
- [ ] What went well? (3 bullets)
- [ ] What to fix? (3 bullets)
- [ ] Add any new Q to L bank.
- [ ] Update STAR stories if a new strong moment came up.

### Weekly during loops
- [ ] Mon morning: review last week's debriefs, top 3 fixes.
- [ ] Wed: 1 mock with peer.
- [ ] Fri: pipeline review — apps in flight, offers, decisions.

### When you get an offer
- [ ] Per [24-resume-linkedin-negotiation.md](../docs/24-resume-linkedin-negotiation.md): never accept on first call.
- [ ] Ask for written breakdown.
- [ ] Anchor counter at top of band per [01-profile-positioning.md](../docs/01-profile-positioning.md).
- [ ] Use competing offers as leverage, never bluff.

---

## Anti-patterns to avoid in this sprint

- ❌ Reading new docs after Day 7 — synthesis only.
- ❌ Cramming DSA after Day 10 — diminishing returns; reinforce patterns.
- ❌ Skipping voice recording — interviews are spoken, not read.
- ❌ Solo prep for system design — get one peer mock minimum.
- ❌ Negotiating without a competing offer — get to ≥2 offers in same window.
- ❌ Disclosing current CTC early — defer per [24](../docs/24-resume-linkedin-negotiation.md).
- ❌ Pulling all-nighters before a loop — sleep beats one extra topic.

---

## End-state success criteria

By end of Day 14, you should be able to:

1. Whiteboard M.1, M.2, M.4, M.8, M.16 from memory in under 2 min each.
2. Speak any L bank Q in ≤60s with example or code.
3. Deliver any of 5 system designs in 25 min with all 10 boxes covered.
4. Tell any of 10 STAR stories in 90–120s with metric in Result.
5. Solve a medium DSA in ≤25 min, articulating brute → optimized.
6. Negotiate using **role-level band research** (levels.fyi / AmbitionBox / Glassdoor) with at least one competing-offer leverage.

When all 6 hold → loops are routine, not stressful. You're ready.

End of Appendix N.
