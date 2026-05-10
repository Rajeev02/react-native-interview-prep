## Appendix E — STAR Story Bank (10 stories with worked examples)

### Story template
```
TITLE: <short memorable name>
PROMPTS IT ANSWERS: <impact / hardest tech / ownership / influence>

S — Situation (1–2 sentences): company, team, scale, constraint.
T — Task (1 sentence): YOUR specific responsibility.
A — Action (4–6 bullets): decisions + why, trade-offs rejected, buy-in, concrete moves, risk mitigated.
R — Result (2 bullets): quantified outcome + second-order impact.
L — Lesson (1 sentence): "what I'd do differently" / "what I now look for first."
```

### 10 stories (worked examples — adapt with your numbers)

#### 1. Largest impact — *"The 4-second cold start"*
- **S**: 8-engineer mobile team, 2M MAU consumer app; iOS cold start crept to 4.1s, blamed for D1 dip.
- **T**: Owned mobile perf for the quarter; goal was sub-2s + measurable retention lift.
- **A**: Profiled with Hermes + Instruments; 60% of pre-render time in eager TurboModule init + sync remote-config fetch. Lazy-loaded 14 modules; moved remote-config to async with cached defaults; trimmed Hermes bundle 38% (moment → dayjs, code-split onboarding); wrote a perf budget + CI gate.
- **R**: Cold start 4.1s → 1.6s P50; D1 retention +6.2%, D7 +3.1%. Perf budget still in use 18 months later.
- **L**: Always ship the measurement before the optimization.

#### 2. Hardest technical problem — *"The phantom crash on Android 12"*
- **S**: 0.4% crash on Android 12 only, no symbols.
- **T**: Crash-free sessions back above 99.5% within 2 weeks before board review.
- **A**: Reproduced via 14 navigations + low-memory pressure; isolated to Reanimated worklet capturing stale shared value after screen unmount race. Fixed with `cancelAnimation` in cleanup; upstreamed repro; added Detox regression.
- **R**: Crash-free 99.1% → 99.78% in 9 days.
- **L**: Concurrency bugs look like memory bugs first.

#### 3. Conflict — *"Native rewrite vs RN at the redesign"*
- **S**: New design head wanted SwiftUI/Compose during redesign; would split team + double timeline.
- **T**: Defend RN on merits, not defensively.
- **A**: 2-week spike comparing both stacks on 3 real screens. Quantified parity (FPS, dev velocity). Invited design team to drive iOS spike. Presented to CTO with data.
- **R**: Team chose RN + Reanimated 3. Redesign shipped on original timeline. Designer became RN advocate.
- **L**: When you disagree, build the smallest experiment that resolves it.

#### 4. Failure — *"The OTA that froze 4% of Android users"*
- **S**: EAS Update with Hermes-only API, broke on specific OEM keyboard.
- **T**: I owned release; on-call.
- **A**: Sentry alert in 11 min; rolled back; opened post-mortem in 24h. Root cause: weak device matrix. Fix: 12-device cloud test farm gate + forced staged OTA 10/50/100.
- **R**: Impact window 38 min; 0 lasting churn. New release-gate adopted org-wide.
- **L**: Speed of detection > prevention.

#### 5. Leadership without authority — *"The cross-team auth refactor"*
- **S**: Mobile/web/backend each had different refresh-token strategies; tokens leaked into Sentry.
- **T**: No mandate; cared because mobile bore worst UX.
- **A**: Wrote RFC for single rotation + reuse detection. 1:1s with each tech lead. Built reference impl on mobile. Shepherded rollout across 3 teams over a quarter.
- **R**: Token-leak Sentry events to zero; refresh-storm incidents eliminated; pattern adopted in 2 sister apps.
- **L**: RFC + working reference is more persuasive than either alone.

#### 6. Mentorship — *"From new-grad to feature owner in 9 months"*
- **S**: Inherited a new-grad with strong CS but no mobile experience.
- **T**: Get them owning a feature E2E by H2.
- **A**: Weekly 1:1s with growth plan tied to RN topics. Pair-debugged real prod issues. Gradually larger scope: bug → small feature → cross-cutting refactor. Introduced to design partners.
- **R**: Led notifications redesign solo (3 months, 4 engineers' worth of design touchpoints). Promoted to mid-level on schedule.
- **L**: Stretch comes from owning conversations, not just code.

#### 7. Ambiguity — *"Defining 'engagement' for the mobile team"*
- **S**: Leadership asked mobile to "improve engagement" with no metric defined.
- **T**: Pick a metric mobile could move and commit.
- **A**: Interviewed PM, data, exec stakeholders. Proposed 3 candidate metrics with trade-offs. Recommended sessions/user as most mobile-actionable; built dashboard; committed to 15% lift in Q2.
- **R**: 18% lift via push re-engagement, faster cold start, home-screen redesign. Metric became team's north star.
- **L**: When asked something vague, return with a definition before a plan.

#### 8. Trade-off — *"Picking React Query over Apollo"*
- **S**: Greenfield app; team split between Apollo (existing GraphQL backend) and React Query + REST.
- **T**: Pick within a week; commit for 18 months.
- **A**: Listed criteria (offline, bundle size, learning curve, server-state caching, mutation ergonomics). Prototyped both for 2 days. Chose React Query + thin GQL client.
- **R**: Bundle 220KB smaller; offline UX shipped in week 6 instead of "later"; 0 regrets in retro.
- **L**: Document trade-offs in an ADR the moment you decide.

#### 9. Saying no — *"Pushing back on the 'just add WebView' shortcut"*
- **S**: PM wanted partner integration as in-app WebView in 2 weeks; security concerns around token passthrough.
- **T**: Balance speed and risk.
- **A**: Mapped threat model in 1 doc. Proposed 3-week native bridge using ASWebAuthenticationSession / Custom Tabs with scoped tokens. Got security + PM in one room.
- **R**: Shipped safer version on original date by cutting an unrelated nice-to-have. Zero security findings in next audit.
- **L**: "No" lands better as "here's the smaller thing that gets you 90% safely."

#### 10. Customer obsession — *"The accessibility bug nobody filed"*
- **S**: VoiceOver users couldn't dismiss our bottom sheet; never reported because affected users churned silently.
- **T**: Self-driven; not on any roadmap.
- **A**: Audited 12 critical flows with VoiceOver + TalkBack; filed 23 issues; fixed 9; created a11y checklist in PR template; ran a brown-bag.
- **R**: VoiceOver users (opt-in analytics) up 3× over the next year. Featured in an a11y newsletter.
- **L**: The users who can't tell you they're leaving are the ones to look for hardest.

### Story-to-prompt cheat map
| Prompt | Story |
|---|---|
| Tell me about your biggest impact | 1, 5 |
| Hardest technical problem | 2, 8 |
| Conflict / disagreement | 3, 9 |
| Time you failed | 4 |
| Led without authority | 5, 7 |
| Mentored someone | 6 |
| Ambiguous problem | 7 |
| Made a trade-off | 8, 3 |
| Said no | 9 |
| Customer obsession | 10 |
| Outage / on-call | 4, 2 |
| Disagree & commit | 3, 9 |

### Common follow-up traps (rehearse)
- "What would you do differently?" — Have a real answer, not "nothing."
- "What did your manager think?" — Show alignment + your role in earning it.
- "What did the team think?" — Show empathy for dissenters.
- "How did you measure success?" — Always cite the metric + how you instrumented it.
- "What was the alternative you rejected?" — Show the trade-off explicitly.
- "What was your specific contribution vs the team's?" — "I" for your part; credit team for theirs.

### Practice protocol
1. Write each story in the template (text).
2. Record yourself telling it — strict 2-min cap.
3. Listen back; cut filler ("kind of", "basically", "so yeah").
4. Have a peer ask 3 follow-ups per story; capture the gaps.
5. Repeat weekly until natural, not memorized.

---

