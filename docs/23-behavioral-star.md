## 23. Behavioral + leadership (STAR)

### 10 stories to prepare (45-sec + 3-min versions)
1. LetsVenture flagship app — end-to-end ownership.
2. RN → Capacitor migration trade-off.
3. Auth0 / Cognito design decision.
4. Cashfree / Razorpay payment flow.
5. Branch deep linking rollout.
6. Biggest production incident — your role + fix.
7. Performance win (with before/after numbers).
8. Conflict with PM / designer / engineer — how resolved.
9. Mentoring a junior who struggled.
10. Deadline vs quality trade-off.

### STAR template
- **Situation** (1 sentence context)
- **Task** (your specific responsibility)
- **Action** (what YOU did, not "we")
- **Result** (numbers: %, ms, $, users, crash-free)

### Top behavioral questions
1. Tell me about yourself (90 sec polished).
2. Why are you leaving? (forward-looking, never bash current employer).
3. Time you disagreed with a senior.
4. Biggest mistake in production.
5. How do you give feedback?
6. Why this company? (research per company).
7. Where in 3 years?
8. Manager-track vs IC-track preference.

### Lead-track signals to drop in answers
- "I wrote the RFC and got buy-in from..."
- "I mentored 3 juniors through their first..."
- "I owned the on-call rotation for..."
- "I drove the decision to..." (own it).
- "The trade-off was X vs Y; we chose X because..."

---



---

## Top 25 Q&A — Behavioral + leadership (STAR)

> Format every answer in **STAR**: Situation, Task, Action, Result. Keep to ~90 seconds. Always include a measurable result.

### 1. Tell me about a time you led a project.
S: RN 0.66 → 0.74 + new arch migration. T: 6-week deadline, zero regressions. A: Wrote ADR, set up runtime flag, migrated 3 modules, ran shadow tests. R: 28% startup improvement, no rollback.

### 2. Conflict with a senior engineer.
S: Native dev wanted full rewrite in Kotlin. T: Convince team RN was viable. A: Built proof in 1 week showing same screen perf parity. R: Adopted RN, saved 4 dev-months.

### 3. Tough deadline you missed.
S: Promised KYC v2 in sprint. T: Slipped by 1 week due to vendor SDK bug. A: Communicated daily, descoped non-essential animations, shipped MVP. R: Released w+1 with same conversion. Lesson: 20% buffer for vendor deps.

### 4. Mentored a junior dev.
S: Junior struggling with Hooks. T: Get them productive in 4 weeks. A: Pairing 2x/week, code review with explanations, gave owned feature. R: Owned login screen end-to-end by week 5; promoted in 6 months.

### 5. Tradeoff between quality and speed.
S: Festive launch, 2 weeks instead of 4. T: Ship payments UI safely. A: Skipped automation tests, added monitoring + kill switches, intense manual QA. R: Zero P0 incident; tests added in next sprint.

### 6. Disagreement with PM.
S: PM wanted modal everywhere. T: Push back. A: Showed analytics — 12% drop on modal screens vs full screens. R: Reverted to inline; conversion +8%.

### 7. Production incident you led.
S: Payment dup webhook race, 11min, 200 orders affected. T: Mitigate < 15 min. A: Kill-switch via remote config, paged backend, refunded duplicates. R: 14 min mitigation, post-mortem with idempotency key fix.

### 8. Cross-team collaboration win.
S: Onboarding drop-off. T: Improve. A: Workshop with PM, design, backend; redesigned 3 screens, parallel API. R: D1 retention +14%.

### 9. Improved developer productivity.
S: Build times 25 min. T: Cut to <10. A: Gradle cache, modular build, ccache for native, EAS remote build. R: 8 min, ~40 dev-hours/week saved.

### 10. Made a wrong technical call.
S: Picked Realm over SQLite. T: Migrate after 6 months. A: Owned the call, drove migration with backwards compat. R: 3-week migration, no data loss. Lesson: validate at scale, not just demos.

### 11. Hired or interviewed.
S: 6 interviews, found 2 hires for senior RN. T: Improve panel. A: Wrote rubric, codified 3 question buckets (RN core, design, behavioral). R: Onboarded 2 engineers in 5 months.

### 12. Influenced without authority.
S: Wanted Sentry across all teams. T: Convince 4 mobile pods. A: ROI doc, 1-week pilot in our pod showing 5 production bugs caught. R: Adopted org-wide.

### 13. Customer-impacting bug.
S: 0.5% users couldn't login on Android 14. T: Find + fix. A: Sentry filter by OS, repro, found WebView cookie change. R: Hotfix in 24h, regression test added.

### 14. Improved code quality.
S: 22 production bugs/month. T: <10. A: Mandated PR template, ADRs for non-trivial, added Detox smoke. R: 8/month average over Q3.

### 15. Tech debt cleanup.
S: Auth flow had 4 components, 1200 LOC, no tests. T: Refactor without breaking. A: Tests first, extracted hooks, state machine via XState. R: 600 LOC, 92% coverage, 0 regressions in 3 months.

### 16. Took ownership of something not yours.
S: Crash-free % was 96%. T: Reach 99.5%. A: Volunteered as mobile reliability lead, fixed top 10 crashes. R: 99.6% in 2 months, retained.

### 17. Failed in delivery.
S: A/B test for new home screen lost. T: Roll back, learn. A: Retro with team, data showed nav change confused users. R: Made 2 hypotheses for next test, won that one.

### 18. Tough feedback you received.
S: 360 said I was sometimes blunt in PRs. T: Improve. A: Templates ("here's what I'd consider..."), focus on intent. R: 360 next cycle showed reversal; adopted as team norm.

### 19. Saying no.
S: Stakeholder asked for new payment provider in 2 weeks. T: Push back. A: Showed scope — 6 weeks min. R: Phased: tokenization week 4, full integration week 8. Met both deadlines.

### 20. Multi-quarter project.
S: Mobile-first redesign, 6 months. T: Lead. A: Broke into 4 phases, weekly demos, beta channel + real user feedback. R: NPS +9, conversion +6%.

### 21. Technical decision document.
S: Picking storage (MMKV vs AsyncStorage). T: Convince team. A: ADR with benchmarks (30x faster reads), security analysis. R: Adopted MMKV + migration plan.

### 22. Worked with remote / distributed team.
S: Backend in EU, mobile in IN. T: Tight feedback loop. A: Daily 30-min sync, written async updates, contract tests on PR. R: Cycle time cut from 4 days → 1.

### 23. Trade-off: RN feature vs native module.
S: Camera feature. T: Pick approach. A: Tried `react-native-vision-camera`; for our QR + barcode use case it covered 100%. R: Saved 3 weeks vs custom native.

### 24. Defining what success looks like.
S: New observability charter. T: Define success. A: SLOs (crash-free 99.5%, p95 cold start <2s), measurement, alerting, owners. R: Doc adopted; team had clear targets.

### 25. Why you, vs other candidates?
"9+ YOE shipping fintech mobile end-to-end. Native + RN. Owned migrations, incidents, hiring. I bring leadership credibility plus IC capability — I'll write the TurboModule and lead the OKR."
