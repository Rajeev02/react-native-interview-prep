# S28 — Study Plans

> 14-day sprint · 30-day senior loop · 90-day staff prep · mock cadence · spaced repetition

Pick the plan that matches your timeline. All plans assume 2–4 hours/day on weekdays + 4–6 hours weekends.

## Topics in this section

- [Q1. 14-day sprint — daily schedule](#q1-14-day-sprint--daily-schedule)
- [Q2. 30-day senior loop](#q2-30-day-senior-loop)
- [Q3. 90-day staff plan including system design](#q3-90-day-staff-plan-including-system-design)
- [Q4. Mock interview cadence](#q4-mock-interview-cadence)
- [Q5. Spaced repetition for RN concepts](#q5-spaced-repetition-for-rn-concepts)

---

## Q1. 14-day sprint — daily schedule

### Difficulty
N/A

### Interview Frequency
N/A — meta topic.

### Prerequisites
2 yrs RN; can build CRUD.

### TL;DR
Days 1–4: core RN+TS+RN architecture. Days 5–8: perf+state+navigation+offline. Days 9–11: 1 system design + 1 machine coding/day + behavioral. Days 12–13: mocks + revision. Day 14: rest + final review.

### 30-Second Interview Answer
"For a 14-day sprint: front-load architecture (RN bridgeless, Fabric, TurboModules, Hermes) + state mgmt + perf in week 1. Week 2 is system design + machine coding + behavioral STAR + mocks. Day 14 is light review and rest. I do 30 min spaced repetition on memory hooks every morning."

### 2-Minute Practical Answer
The 14-day plan:

| Day | Morning (2h) | Evening (2h) |
|---|---|---|
| 1 | S03 RN core | S04 New Architecture |
| 2 | S06 Hermes/Metro | S01 JS/TS deep |
| 3 | S07 Performance | S08 State management |
| 4 | S09 Networking | S05 Expo tooling |
| 5 | S10 Auth/Security | S11 Offline-first |
| 6 | S12 Push notifications | S15 Native bridging |
| 7 | S22 System design Q1–Q2 | S22 Q3 |
| 8 | S22 Q4–Q5 + diagrams | S23 Machine coding 1 |
| 9 | S23 Machine coding 2 | S25 Behavioral STAR |
| 10 | S24 DSA | S17 Testing/debugging |
| 11 | S19 a11y / S20 CI | Mock 1 (recorded) |
| 12 | Mock 2 | Review weak topics |
| 13 | Mock 3 + STAR practice | Review memory hooks |
| 14 | Rest, light review | Pre-loop sleep early |

Daily ritual:
- 30 min spaced repetition (Anki / handbook memory hooks).
- Targeted reading.
- Hands-on coding (pick 1 topic; build).
- Verbalize answers out loud.

### 5-Minute Architecture Answer
The 14-day sprint forces prioritization. Skip:
- Web RN unless target requires.
- Visionary topics (Q26 AI-assist) unless target uses.
- Deep DSA grinding (rely on basics + RN-specific patterns).

Focus:
- **Architecture fluency** — Bridgeless, Fabric, TurboModules, Hermes (interview-asked daily).
- **Performance** — FlashList, Reanimated, startup, profiling.
- **State + data** — TanStack Query, Zustand, MMKV.
- **Navigation** — Expo Router, deep links.
- **System design** — 5 representative problems.
- **Machine coding** — 2–3 recent problems coded end-to-end.
- **Behavioral** — 5 STAR stories ready.

Mock cadence (Q4):
- Mock 1 (Day 11): record yourself; identify gaps.
- Mock 2 (Day 12): friend / interview platform.
- Mock 3 (Day 13): focus on weak area.

Sleep + nutrition matter; don't burn out. Day 14 is rest, not cramming.

### The "Why"
Time-boxed prep prevents endless drift; forces focus.

### Mental Model
Sprint = breadth pass + depth on weak areas + 3 mocks.

### Internal Working (2026 Context)
- Most companies' loops: 1 phone screen, 4–6 onsite rounds.
- Staff loops add system design + leadership panels.

### Modern Implementation (Code)
Sample daily checklist (`docs/study-plan-day-N.md`):
```md
- [ ] 30m: Anki review (RN architecture cards)
- [ ] 60m: Read S04 Q1–Q3
- [ ] 60m: Build sample TurboModule
- [ ] 30m: STAR rehearse story #2
- [ ] 30m: Mock prep (write 5 likely Qs)
```

### Comparison

| Plan | Hours total | Coverage |
|---|---|---|
| 14-day | ~60h | RN + system design surface |
| 30-day | ~120h | RN deep + system design |
| 90-day | ~360h | Staff-level + leadership |

### Production Usage
- Used by candidates with notice period or active loops.

### Hands-On Exercise
Print this table; check off each day.

### Common Mistakes
- Skipping sleep.
- All reading, no coding.
- No mocks.
- Too many resources (handbook is enough).

### Production Red Flags
- Day 13 cramming.
- No spaced repetition.
- No verbalization.

### Performance & Metrics
- Coverage % (handbook sections complete).
- Mock score trajectory.
- Memory hook recall.

### Decision Framework
- < 14 days → S28 Q1.
- 14–60 days → Q2.
- > 60 days → Q3.

### Senior-Level Insight
"The 14-day plan works only if you've already built RN apps for 2+ years. Otherwise, you're cramming, not preparing."

### Real-World Scenario
Engineer with 3yr RN experience used this plan for an 11-day notice; cleared 4/5 onsites.

### Production Failure Story
Engineer crammed all 14 days; skipped mocks; failed onsite due to communication / nervousness.
**Fix:** Always include 3 mocks.

### Debugging Checklist
1. Daily ritual followed?
2. Mocks done?
3. Spaced repetition?
4. Sleep > 7h?

### Advanced / Internal Knowledge
- Pomodoro (25/5) for deep work.
- Standing while doing mocks (energy + posture).
- Recording self for review.

### 2026 AI Tip
AI for mock interviewer (paste rubric; have it grill you).

### Related Topics
Q2, Q3, Q4, Q5.

### Interview Follow-Up Questions
N/A — internal planning.

### Memory Hook
**"Week 1 architecture + perf. Week 2 system design + mocks. Day 14 rest."**

### Revision Notes
> 14-day: front-load core (S03/S04/S06/S07/S08); week 2 system design + machine coding + behavioral; 3 mocks (days 11–13); spaced repetition daily; rest day 14.

---

## Q2. 30-day senior loop

### Difficulty
N/A

### Interview Frequency
N/A.

### Prerequisites
3+ years RN.

### TL;DR
Week 1: core + state. Week 2: perf + offline + push + native. Week 3: system design + machine coding + behavioral. Week 4: mocks + leadership stories + final revision.

### 30-Second Interview Answer
"30-day plan: weeks 1–2 cover all technical sections (S01–S20); week 3 covers system design + machine coding + behavioral; week 4 is mocks + leadership stories + revision. I rotate topics daily for spaced learning, code something every day, and run 1 mock per week ramping to 2/week in week 4."

### 2-Minute Practical Answer
30-day breakdown:

| Week | Focus |
|---|---|
| 1 | S01–S07 (JS/TS, RN core, architecture, perf basics) |
| 2 | S08–S15 (state, network, auth, offline, push, native) |
| 3 | S16–S22 (architecture scaling, testing, observability, CI, system design) |
| 4 | S23–S26 (machine coding, behavioral, AI-assist), mocks, revision |

Daily ritual (90–180 min):
- 30 min spaced repetition.
- 60 min reading + verbalize.
- 60 min coding / hands-on.
- 30 min behavioral / STAR rehearsal.

Weekly mocks:
- Week 1: self-recorded.
- Week 2: peer mock (technical).
- Week 3: peer mock (system design).
- Week 4: 2 mocks (full loop simulation).

### 5-Minute Architecture Answer
30 days lets you:
- Cover the entire handbook with depth.
- Build 2–3 small projects (offline-first todo, chat, OTP form).
- Run 5–6 mocks.
- Internalize 8–10 STAR stories.
- Polish resume + LinkedIn (S31).

Risks:
- Burnout — pace yourself; take 1 day off per week.
- Tunnel vision — interleave reading + coding + behavioral.
- Over-confidence — first mock often humbling.

For senior loops specifically:
- Expect 1 system design round.
- Expect deep RN architecture (Bridgeless, TurboModules, Hermes).
- Expect production scenarios (S07 perf, S18 observability).
- Expect behavioral with situational depth.

For 2026:
- React 19 + RN 0.74+ specific questions.
- AI-assist usage questions ("how do you use Copilot?").
- Privacy/compliance (S30) emerging.

### The "Why"
30 days is the sweet spot for senior preparation: enough for depth, not so much that motivation dies.

### Mental Model
30 days = 4 sprints + 1 polish week.

### Internal Working (2026 Context)
N/A — meta.

### Modern Implementation (Code)
Build a real project for portfolio:
```
offline-first-todo/
  ├── App.tsx (Expo Router)
  ├── src/
  │   ├── db/ (MMKV + watermelon)
  │   ├── api/ (TanStack Query)
  │   ├── components/ (FlashList, Pressable a11y)
  │   └── theme/
  ├── e2e/ (Maestro)
  └── README.md (architecture decisions)
```
Discuss in interviews.

### Comparison
See Q1.

### Production Usage
- Most candidates use 30–45 days for senior prep.

### Hands-On Exercise
Map your calendar; allocate slots; commit.

### Common Mistakes
- Procrastinating week 1; cramming week 4.
- No mocks.
- Reading-only; no coding.
- Skipping behavioral.

### Production Red Flags
- 0 STAR stories at week 3.
- No mocks done.
- Skipping observability + CI sections.

### Performance & Metrics
- Sections complete.
- Mock score progression.
- STAR stories rehearsed (target 8–10).

### Decision Framework
- 30 days available + senior target → this plan.
- Less time → Q1.
- More time → Q3.

### Senior-Level Insight
"30 days makes a competent senior into a confident senior. The difference shows in the system design round."

### Real-World Scenario
Engineer with 4yr RN used this plan; cleared loops at 2 of 3 target companies.

### Production Failure Story
Engineer skipped behavioral prep; nailed tech rounds; failed at the bar-raiser.
**Fix:** Always allocate ≥ 4 days to behavioral.

### Debugging Checklist
1. All sections covered?
2. ≥ 4 mocks done?
3. ≥ 8 STAR stories ready?
4. Portfolio project built?

### Advanced / Internal Knowledge
- Calibration: ask peer mockers to rate against rubric.
- Time-box each topic; don't perfectionism.
- Sleep is part of the plan, not a luxury.

### 2026 AI Tip
AI for STAR story refinement; paste draft, ask "make this STAR + measurable + 3 minutes."

### Related Topics
Q1, Q3, Q4.

### Interview Follow-Up Questions
N/A.

### Memory Hook
**"4 weeks. 4 sprints. Mocks every week. Polish week 4."**

### Revision Notes
> 30-day senior plan: weeks 1–2 technical sections; week 3 system design + machine coding; week 4 mocks + behavioral; daily ritual 90–180 min; weekly mocks; portfolio project alongside.

---

## Q3. 90-day staff plan including system design

### Difficulty
N/A

### Interview Frequency
N/A.

### Prerequisites
5+ years; previous senior loop experience.

### TL;DR
Month 1: technical depth across all sections. Month 2: system design (5–10 deep designs) + leadership scenarios. Month 3: mocks + portfolio + executive presence + comp negotiation.

### 30-Second Interview Answer
"90-day staff plan: month 1 is full technical mastery (handbook end-to-end + projects); month 2 is system design depth (5–10 mock designs) + leadership scenarios (cross-team conflicts, ambiguity) + portfolio building; month 3 is mocks weekly, executive presence practice, and comp negotiation prep. I track progress in a spreadsheet; weekly retro adjusts focus."

### 2-Minute Practical Answer
90-day breakdown:

| Month | Focus |
|---|---|
| 1 | All technical sections (S01–S20) + 1 portfolio project |
| 2 | System design (S22) + leadership behavioral (S25) + visibility (talks, blog) |
| 3 | Mocks (4–6) + onsite simulation + comp negotiation prep |

Month 2 deep dive — system design:
- Design 1: offline-first chat at scale.
- Design 2: SDUI platform.
- Design 3: feed with personalization.
- Design 4: payment flow.
- Design 5: live commerce/auctions.
- Design 6: video upload pipeline.
- Design 7: real-time collaboration.
- Design 8: notifications platform.
- Design 9: search + recommendations.
- Design 10: A/B testing platform.

For each: 90-min design + 30-min retro + write-up.

Month 2 leadership scenarios:
- Cross-team architecture disagreement.
- Underperforming team member.
- Pivot in roadmap.
- Hiring loop owner.
- Cross-functional incident response.

Month 3:
- 1 mock/week (full loop).
- 1 system design mock/week.
- 1 behavioral panel/week.
- Negotiation script + practice.

### 5-Minute Architecture Answer
Staff loops are different. Expect:
- 2–3 system design rounds (not 1).
- Behavioral panel with 3+ leaders.
- Strategic / "vision" questions ("where is RN going?").
- Cross-functional scenarios (PM, Design, Backend collaboration).
- Hiring + mentorship questions.
- Sometimes: technical writing exercise / RFC review.

90-day plan unique elements:
- **Visibility** — write 2–3 technical blog posts during prep; speak at meetup.
- **Portfolio** — at least 1 OSS contribution to a recognized RN library.
- **References** — line up 3–5 references including cross-functional partners.
- **Comp research** — Levels.fyi + Blind + recruiters; know the bands cold.

Avoid:
- Going dark on current work (interviewers ask about recent impact).
- Burning out (3 months is long; plan rest weekends).
- Skipping the visibility work (staff candidates have visible footprints).

For 2026:
- AI fluency (S26) is required at staff level.
- Cross-platform (S29) increasingly relevant for staff.
- Privacy/compliance (S30) for senior+ in EU/India markets.

### The "Why"
Staff loops test breadth + leadership + technical depth + presence — needs time.

### Mental Model
Staff prep = senior prep × 2 + leadership polish + visibility.

### Internal Working (2026 Context)
N/A — meta.

### Modern Implementation (Code)
Track via project management tool:
- Linear / Notion board.
- Weekly retro entries.
- Mock score sheet.

### Comparison

| Plan | Best for |
|---|---|
| 14-day | Notice period, recent prep |
| 30-day | Senior loop |
| 90-day | Staff/principal target |

### Production Usage
- Common path for engineers eyeing FAANG-ish staff roles.

### Hands-On Exercise
Build a 90-day calendar; share with accountability partner.

### Common Mistakes
- Treating it like 30-day plan × 3 (no leadership / visibility work).
- No real-world feedback loop (no mocks).
- Burnout in month 2.

### Production Red Flags
- Disengaged from current job (interviewers notice).
- No public footprint.
- Comp expectations unrealistic.

### Performance & Metrics
- Mock pass rate.
- Blog posts published.
- OSS PRs merged.
- Network referrals secured.

### Decision Framework
- < 30 days notice → Q1/Q2.
- 30–90 days → Q2 or this.
- > 90 days → this + extension.

### Senior-Level Insight
"Staff prep isn't just more technical depth; it's leadership presence, visibility, and strategic thinking. Allocate explicit time to all three."

### Real-World Scenario
Engineer used 12-week plan; published 3 blog posts; spoke at React India; got referrals to 5 staff loops; cleared 2.

### Production Failure Story
Engineer prepared 90 days technically but skipped visibility / behavioral; failed bar-raiser at every loop.
**Fix:** Always allocate ≥ 4 weeks to leadership + presence.

### Debugging Checklist
1. Tech sections complete?
2. ≥ 5 system designs done?
3. ≥ 8 mocks done?
4. ≥ 2 blog posts?
5. References lined up?
6. Comp data current?

### Advanced / Internal Knowledge
- Engagement signals during prep matter (LinkedIn activity).
- Recruiters value referrals 5–10× over cold apps.
- Negotiation: don't share current comp; share expectations.

### 2026 AI Tip
AI for design draft generation; verify with senior peer.

### Related Topics
Q1, Q2, Q4, S31, S22.

### Interview Follow-Up Questions
N/A.

### Memory Hook
**"Tech depth + leadership + visibility + comp prep. 12 weeks, 1 plan."**

### Revision Notes
> 90-day staff plan: month 1 technical mastery; month 2 system design (5–10) + leadership + visibility; month 3 mocks + presence + negotiation; track via sheet; retros weekly.

---

## Q4. Mock interview cadence

### Difficulty
N/A

### Interview Frequency
N/A.

### Prerequisites
Plan in motion.

### TL;DR
1 mock/week in week 1; 2/week in last weeks. Mix: technical, system design, behavioral. Record + review. Use platforms (Pramp, Interviewing.io) + peers + AI mock interviewer.

### 30-Second Interview Answer
"Cadence: 1 mock in first week to baseline; 2/week in last 2 weeks. Mix of technical, system design, behavioral. Always record (audio at least). Review for: clarity, structure, time management, signals missed. Use Pramp / Interviewing.io for free / paid; peer mocks for accountability; AI for low-pressure first-pass."

### 2-Minute Practical Answer
Mock types:
- **Technical deep dive** — concept + code.
- **Machine coding** — 60-min build something.
- **System design** — 60-min design + Q&A.
- **Behavioral panel** — 45 min STAR + situational.
- **Bar-raiser sim** — 60 min mixed; harder.

Cadence by plan:
- 14-day: 3 mocks total (days 11, 12, 13).
- 30-day: 5 mocks (1/week, 2 in week 4).
- 90-day: 12+ mocks (weekly + extras in month 3).

Sources:
- **Free**: Pramp (peer-to-peer), local meetup buddies.
- **Paid**: Interviewing.io ($), Karat (companies use), exponent.com.
- **AI**: Claude / GPT as mock interviewer (give it the rubric).
- **Self**: record yourself answering questions; review next day.

Review framework:
- Did I structure (TL;DR → 5 min → trade-offs)?
- Time management (not over-elaborate)?
- Communication (clear, no jargon spam)?
- Signals shown (depth, ownership, calibration)?
- What would I do differently?

### 5-Minute Architecture Answer
Mocks are the highest-leverage prep activity. Reading the handbook ≠ performing under pressure.

What mocks reveal that reading hides:
- Time pressure makes you skip steps.
- Verbalization exposes shaky understanding.
- Interviewer follow-ups expose depth gaps.
- Behavioral anxiety affects pacing.

Mock review template:
```md
# Mock #N — [Date] — [Topic]
## Interviewer / Source: [name / platform]
## Self-rating: [1–5]

## What went well
- ...

## What didn't
- ...

## Action items
- [ ] Re-read S07 Q3
- [ ] Practice STAR story #4 with metric
- [ ] Time-box system design intro to 5 min
```

For 2026:
- AI mock interviewers (Claude with rubric) good for low-stakes first pass.
- Real human mocks irreplaceable for behavioral.
- Recording yourself is free + powerful.

Pacing tips:
- First 5 mocks: focus on structure.
- Mocks 6–10: focus on depth + edge cases.
- Last 3 mocks: full simulation.

### The "Why"
Performance ≠ knowledge. Mocks bridge the gap.

### Mental Model
Mock = lab experiment. Hypothesize → run → review → adjust.

### Internal Working (2026 Context)
- Pramp pairs you with peer.
- Interviewing.io has anonymous interviewers from FAANG.
- AI mocks scale infinitely.

### Modern Implementation (Code)
Mock prompt for AI:
```
You are a senior engineering interviewer at a Series B fintech.
Conduct a 45-minute system design round on:
"Design an offline-first money transfer feature."

Your style: ask probing follow-ups; challenge trade-offs;
push on scale, security, observability. Don't reveal answers;
push me to think.

After 45 min, give detailed feedback with rubric:
- Clarity (1–5)
- Trade-off discussion (1–5)
- Edge cases (1–5)
- Communication (1–5)
- Senior signal (1–5)

Start by asking my opening question.
```

### Comparison

| Source | Cost | Quality |
|---|---|---|
| Pramp | Free | Variable (peer-dep) |
| Interviewing.io | $ | High (FAANG mockers) |
| Karat | Free if company uses | Calibrated |
| AI | Free | Good for first pass |
| Self-recording | Free | Reveals communication |

### Production Usage
- Most prepared candidates do 5–10 mocks.

### Hands-On Exercise
Schedule next mock now.

### Common Mistakes
- No mocks (read-only prep).
- Mocks without review.
- Same mocker every time (echo chamber).
- Skipping the painful behavioral mocks.

### Production Red Flags
- "I'll start mocks closer to the loop."
- 0 mocks 1 week before loop.
- All mocks technical, none behavioral.

### Performance & Metrics
- Mock score progression.
- Time-management trend.
- Action items closed.

### Decision Framework
- New to interviews → start with AI / self-recording.
- Mid-prep → peer mocks (Pramp).
- Final week → paid (Interviewing.io) for calibration.

### Senior-Level Insight
"The candidates who consistently get offers are not the smartest; they're the ones who've practiced answering out loud the most."

### Real-World Scenario
Engineer did 8 mocks; aced loops because pacing + clarity were trained. Friend did 2; nailed tech but rambled in behavioral; lost.

### Production Failure Story
Engineer skipped recording mocks; thought they were great; reviewed for first time after rejection; obvious communication issues.
**Fix:** Always record + review next day.

### Debugging Checklist
1. Mock scheduled?
2. Recorded?
3. Reviewed within 24h?
4. Action items in writing?

### Advanced / Internal Knowledge
- Cross-company calibration: mock with engineers from target companies.
- Comp negotiation simulation (separate mock).
- Recording = legal in most places, but ask first.

### 2026 AI Tip
AI as 24/7 mock interviewer; use it daily during prep.

### Related Topics
Q1, Q2, Q3.

### Interview Follow-Up Questions
N/A.

### Memory Hook
**"Mock weekly. Record always. Review in 24h. Adjust."**

### Revision Notes
> Mocks: 1/week ramping to 2/week; technical + system design + behavioral mix; record + review; AI for first pass; paid for calibration; peer for accountability; ≥ 5 mocks before any senior loop.

---

## Q5. Spaced repetition for RN concepts

### Difficulty
N/A

### Interview Frequency
N/A.

### Prerequisites
Concept list.

### TL;DR
Use Anki / handbook memory hooks. Daily 15–30 min review. Cards: question + 1–2 sentence answer + cross-ref. Review schedule: 1d, 3d, 1w, 2w, 1mo. Card creation as you study; never copy en masse.

### 30-Second Interview Answer
"I create Anki cards for RN concepts as I study — question on front, 1–2 sentence answer + cross-ref on back. Daily 15–30 min review uses spaced repetition (1d, 3d, 1w, 2w, 1mo). Memory hooks at the end of each handbook section seed the cards. By interview day, I have 200–300 cards reliably recalled."

### 2-Minute Practical Answer
Card design rules:
- One concept per card.
- Question on front (e.g., "Why does Bridgeless mode reduce ANRs?").
- 1–2 sentence answer on back.
- Cross-ref to handbook section.
- Tag by section (S03, S07, etc.).

Examples:
```
Front: What replaces the bridge in RN's New Architecture?
Back: JSI (JavaScript Interface) lets JS hold direct
references to native methods, eliminating async serialized
bridge. → S04
```

```
Front: When does FlashList outperform FlatList?
Back: Lists > 20 items; especially with varied heights and
images. Recycles views like RecyclerView; estimatedItemSize
required. → S07
```

Daily ritual (15–30 min):
- Morning: review due cards.
- Mark known / hard / unknown.
- Re-read source for unknown.
- Add new cards as you learn.

Spacing intervals (default Anki):
- New card: 1d.
- Learning: 1d → 3d.
- Review: 3d → 1w → 2w → 1mo → 2mo.

For 2026:
- Anki + AnkiMobile (sync via AnkiWeb).
- Mochi.cards (modern alt).
- Use handbook's "Memory Hook" / "Revision Notes" as starter cards.

### 5-Minute Architecture Answer
Spaced repetition is the highest-leverage memory tool. Why it works:
- Forgetting curve: without review, you lose 70% in 1 day.
- Active recall (vs re-reading) doubles retention.
- Spacing strengthens memory more than mass practice.

Card creation discipline:
- **Atomic** — one concept per card.
- **Specific** — "What" + "Why" / "When".
- **Calibrated** — too easy = wasted; too hard = unmotivating.
- **Personal** — write in your words.

What to put on cards:
- ✅ Definitions (Bridgeless, JSI, Fabric).
- ✅ Comparisons (FlatList vs FlashList).
- ✅ Trade-offs (when to use Zustand vs TanStack Query).
- ✅ Common mistakes.
- ❌ Long code snippets (review them in IDE).
- ❌ Multi-paragraph answers (split).

For interviews specifically:
- Cards = quick recall under pressure.
- Mental model questions = handbook deep reads.
- Combine both.

For 2026:
- AI generates cards from notes ("turn these notes into 10 Anki cards").
- Verify AI cards before adding.
- Don't dump 1000 cards; quality > quantity.

### The "Why"
Forgetting is the enemy. Spaced repetition is the antidote.

### Mental Model
Brain = leaky bucket. Spaced reviews patch the leaks.

### Internal Working (2026 Context)
- Anki uses SM-2 algorithm.
- New tools (Mochi, RemNote) use FSRS (newer, calibrated).

### Modern Implementation (Code)
Sample card pack structure:
```
Anki/
  ├── RN-Architecture.apkg (50 cards)
  ├── RN-Performance.apkg (40 cards)
  ├── State-Mgmt.apkg (30 cards)
  ├── System-Design.apkg (40 cards)
  └── Behavioral-STAR.apkg (20 cards)
```

Generate cards from handbook:
```
Prompt for AI:
"From this handbook section, generate 8 Anki cards.
Each: question on front, 1–2 sentence answer on back.
Format: 'Q: ... ; A: ...'."
```

### Comparison

| Method | Retention |
|---|---|
| Re-reading | Low |
| Highlighting | Low |
| Active recall | Medium |
| Spaced repetition | High |
| SR + teaching | Highest |

### Production Usage
- Standard for med students; adopted by senior engineers.

### Hands-On Exercise
Create 20 cards from S07 (performance); review for 7 days.

### Common Mistakes
- 1000+ cards on day 1 (unmaintainable).
- Long answers (split).
- Skipping daily review.
- No tags.

### Production Red Flags
- "I'll review when I have time."
- Card pack untouched for weeks.

### Performance & Metrics
- Daily review streak.
- Retention rate (Anki shows).
- Cards added vs reviewed ratio.

### Decision Framework
- Concept memorizable in 1–2 sentences → card.
- Concept needs full read → handbook.
- Both → card + handbook ref.

### Senior-Level Insight
"Spaced repetition isn't for cramming; it's for keeping concepts fresh between job hops. Senior+ engineers who do this consistently outperform on whiteboard recall."

### Real-World Scenario
Engineer maintained 250 RN-architecture Anki cards for 2 years; aced architecture rounds at every loop without re-prep.

### Production Failure Story
Engineer made 800 cards in week 1; never reviewed; useless.
**Fix:** Cap card creation at 10–20/day; review > create.

### Debugging Checklist
1. Daily review done?
2. Cards atomic (one concept)?
3. Tagged by section?
4. Memory hooks integrated?

### Advanced / Internal Knowledge
- FSRS algorithm (newer, more accurate than SM-2).
- "Cloze deletion" cards for partial recall.
- Image occlusion for diagrams.

### 2026 AI Tip
AI generates draft cards from notes; you review + edit before adding.

### Related Topics
Q1, Q2, Q3.

### Interview Follow-Up Questions
N/A.

### Memory Hook
**"Atomic cards. Daily review. Quality > quantity. Memory hooks seed."**

### Revision Notes
> Spaced repetition: Anki / FSRS; atomic cards; daily 15–30 min review; cards from handbook memory hooks; tag by section; cap creation; quality > quantity; AI generates drafts.

---

> Cross-refs: S31 (career), all sections (memory hooks), S25 (behavioral).
