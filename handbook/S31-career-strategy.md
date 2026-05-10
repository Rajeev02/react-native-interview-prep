# S31 — Career Strategy

> Resume · LinkedIn / Naukri · negotiation · recruiter comms · portfolio · staff-level positioning · promotion packets

In 2026, mobile-engineer hiring is an **artifact-driven** process: recruiters skim, hiring managers scan for scope, panels look for evidence. Your resume, LinkedIn headline, and the first 60 seconds of every behavioral round are the leverage. This section is the playbook.

## Topics in this section

- [Q1. The senior RN resume that gets to onsite](#q1-the-senior-rn-resume-that-gets-to-onsite)
- [Q2. LinkedIn / Naukri headline + About for senior RN engineers](#q2-linkedin--naukri-headline--about-for-senior-rn-engineers)
- [Q3. Negotiating a senior RN offer (multi-offer playbook)](#q3-negotiating-a-senior-rn-offer-multi-offer-playbook)
- [Q4. From senior to staff — what changes in the narrative](#q4-from-senior-to-staff--what-changes-in-the-narrative)
- [Q5. Building a public engineering brand (blog / talks / OSS)](#q5-building-a-public-engineering-brand-blog--talks--oss)

---

## Q1. The senior RN resume that gets to onsite

### Difficulty
Intermediate

### Interview Frequency
Always (this is the gate to every loop).

### Prerequisites
2–4 production projects you can write about with specifics.

### TL;DR
One page, **STAR-formatted bullets with metrics**, top-loaded with mobile-specific impact (cold start, crash-free, conversion, scale). Drop framework lists; show outcomes.

### 30-Second Interview Answer
"My resume is one page, scannable in 20 seconds. Each bullet is `Action → Tech → Outcome` with a number — cold start −38%, crash-free 99.94%, OTA rollback < 4 minutes. Tech keywords sit in a small skills strip; the body proves seniority through scope and metrics, not adjectives."

### 2-Minute Practical Answer
What recruiters scan for in 20 seconds:
1. Current company + title (proxy for level).
2. Tenure (>1 year preferred per role).
3. Tech keywords matching JD (RN, TypeScript, Reanimated, Hermes, Fabric, EAS).
4. **One number per bullet.**

What hiring managers look for in 90 seconds:
- **Scope** ("led", "owned", "designed" vs "worked on").
- **Mobile-native depth** (anyone can ship a screen; few can ship a 60fps screen on a 4-year-old Android).
- **Cross-functional outcome** (PM/design/backend partnership).

Anti-patterns:
- "Familiar with X, Y, Z, A, B, C..." (signals junior).
- "Used React Native to build mobile apps" (no info).
- Three pages with college projects.

### 5-Minute Architecture Answer
Treat the resume as a **conversion funnel**: Recruiter screen (20s) → HM review (90s) → recruiter call (15min) → tech screen → onsite → offer. Each stage has a different reader; your single page must serve all of them via **layered scanning**:

- Headline + skills strip → recruiter passes the keyword filter.
- Top 3 bullets per role → HM sees scope and impact.
- Sub-bullets → tech screener finds the talking points.

For senior+ roles, **lead with one "headline impact" project per role** (the one you'll talk about in the behavioral). Everything else supports it.

### The "Why"
- Hiring is asymmetric: 200+ resumes per req. Yours has < 30 seconds of attention before a yes/no.
- Metrics are the only universal proof of seniority — every reader, regardless of background, parses "−38% cold start" the same way.

### Mental Model
Resume = **landing page** for one product (you). Headline + 3 hero bullets + social proof. Optimize for skim, not depth.

### Internal Working (2026 Context)
- ATS systems (Greenhouse, Lever, Workday) parse PDFs reliably in 2026; text-based PDF wins over fancy designs.
- Many companies run **AI pre-screens** (resume → JD match score). Plain language + JD keywords scores higher than designed graphics.
- LinkedIn Easy Apply pulls structured data — keep titles canonical ("Senior Software Engineer, Mobile" not "Mobile Wizard").

### Modern Implementation (Resume Skeleton)

```
NAME · City, Country · email · github · linkedin · portfolio
SUMMARY (2 lines, optional)
  Senior React Native engineer with 7y building consumer mobile apps at scale (10M+ MAU).
  Specialize in performance, New Architecture migrations, and offline-first systems.

SKILLS (one line each)
  Mobile: React Native (New Arch / Bridgeless), Reanimated 3, Skia, Expo, EAS
  Languages: TypeScript, Kotlin (intermediate), Swift (intermediate), Java
  Native: TurboModules, Fabric, JSI, Codegen
  Tooling: Hermes, Metro, Sentry, OpenTelemetry, GitHub Actions, Fastlane

EXPERIENCE
  Senior Software Engineer · Acme Mobile · Jan 2023 – Present · Bangalore
    • Migrated 1.2M-user app to RN New Arch in 6 weeks; cold start −38%, crash-free
      99.94% (was 99.71%). Owned migration plan, interop layer adoption, rollout gating.
    • Designed offline-first ledger sync (op-sqlite + custom CRDT layer) across 3 markets;
      reduced support tickets for "missing transactions" by 71% YoY.
    • Led a 4-engineer team to ship payments revamp (Razorpay + Apple Pay + Google Pay);
      checkout completion +9.2% on Android, +5.1% on iOS.

  Software Engineer · BetaApp · 2020 – 2022
    • ...

PROJECTS / OSS (only if material)
EDUCATION (one line)
```

### Comparison

| Bullet style | Signal |
|---|---|
| "Worked on the home feed" | Junior, no scope |
| "Built the home feed using React Native and Redux" | Mid, no outcome |
| "Owned home-feed redesign across 4 squads; FlashList migration cut frame drops 62% on P50 Android" | Senior |

### Production Usage
- Use the **same resume for every role** in a target band; do not customize the body. Customize **only** the summary line and skills order.
- Keep an **achievements file** (running log of metrics, dates, postmortems) — pull from it quarterly.

### Hands-On Exercise
1. Take your current resume. Count bullets without numbers. Rewrite each to include one.
2. Print at 100% — can a stranger find your current title and 3 most impressive things in 30 seconds?
3. Run it through an AI ATS scorer against 3 target JDs. Iterate keywords.

### Common Mistakes
- "Tech soup" skills list (everything you've ever touched).
- No metrics; passive verbs ("involved in", "helped with", "responsible for").
- Two-column designs that ATS parses incorrectly.
- Dating projects in months ("Aug'23–Sep'23"); use years.

### Production Red Flags (recruiter view)
- Job hopping with < 1y tenures and no apparent reason.
- Senior title with no scope language.
- "Architected" used for trivial systems.

### Performance & Metrics
For a senior IC, target ≥ 5 quantified bullets across all roles, ≥ 1 "led/owned" bullet per role above mid-level, ≥ 1 cross-functional outcome.

### Decision Framework
- If you have ≥ 3 mobile-specific metrics → mobile resume. If not → fix the metrics gap first; ask your manager for analytics access.

### Senior-Level Insight
The strongest senior resumes feel **boring but inevitable**: scope grew every year, technical decisions had business outcomes, ambiguity shrank around the candidate. Drama and "I single-handedly..." reads junior.

### Real-World Scenario
**Symptom:** You apply to 30 roles, get 2 callbacks.
**Investigation:** Resume has 14 bullets, 0 with numbers, 3-page format.
**Root cause:** Optimized for completeness, not skim.
**Fix:** One page, 8 bullets, every bullet quantified, top role front-loaded.
**Result:** 30 → 11 callbacks in next batch.

### Production Failure Story
**Incident:** Strong engineer rejected at recruiter screen at a top product company.
**Investigation:** Resume listed "React Native" only in a sub-bullet under "frontend work"; recruiter keyword search filtered them out.
**Root cause:** Tech kept implicit; ATS couldn't see it.
**Fix:** Explicit skills strip with the JD's exact terms.
**Prevention:** Mirror the JD's vocabulary in the skills line — never paraphrase.

### Debugging Checklist
1. Does the top third have your current title + one quantified hero bullet?
2. Are all bullets `Action → Tech → Outcome`?
3. Do skills mirror the target JD's vocabulary?
4. Does it parse cleanly when you paste the PDF text into a notepad?

### Advanced / Internal Knowledge
- Most ATSs index titles + years + skills line heaviest. Body bullets matter to humans.
- Recruiters search by title + years + locations + 2–3 skills tokens; missing any is a hard filter.

### 2026 AI Tip
Use AI to (a) compress wordy bullets, (b) identify weak verbs, (c) generate ATS-style match scores against JDs. **Do not** let AI invent metrics — fabricated numbers come up in references.

### Related Topics
Q2 (LinkedIn), Q3 (negotiation), `appendix/C-resume-template.md`, `docs/24-resume-linkedin-negotiation.md`.

### Interview Follow-Up Questions
- "Walk me through your most impactful project." (Pick the hero bullet.)
- "How did you measure that?" (Have the dashboard story ready.)
- "What would you have done differently?" (Show retrospective maturity.)

### Memory Hook
**"One page, one number per bullet, one hero project per role."**

### Revision Notes
> Senior RN resume: top-load metrics; STAR bullets; mirror JD vocabulary; no tech soup; one page; one hero per role.

---

## Q2. LinkedIn / Naukri headline + About for senior RN engineers

### Difficulty
Beginner → Intermediate

### Interview Frequency
Always (this is how recruiters find you).

### Prerequisites
A resume that's already strong (LinkedIn mirrors it).

### TL;DR
Headline = **role + specialty + scale**. About = 3 short paragraphs (story, what I build, what I'm looking for). Open to Work + correct location + JD keywords drive inbound.

### 30-Second Interview Answer
"My LinkedIn headline is `Senior React Native Engineer · New Architecture · 10M+ MAU apps`. The About is three short paragraphs: who I am, what I've shipped (with numbers), what I'm looking for. Skills section has the top 10 endorsed; recommendations are from skip-level managers. Open to Work is on but invisible to my employer."

### 2-Minute Practical Answer
**Headline (220 chars):** Role title (matches what recruiters search) + specialty (RN New Arch, performance, offline-first) + scale signal (MAU, downloads, geography).

**About (3 paragraphs):** Story (2 lines: who, where) → Proof (3–5 bullets with numbers) → Ask (what kinds of roles, what you're not interested in, politely).

**Featured section:** pin 1 talk, 1 blog, 1 OSS link if you have them. **Activity:** comment thoughtfully on RN/mobile posts weekly.

### 5-Minute Architecture Answer
LinkedIn (and Naukri in India) are **search engines** for talent. Recruiters run boolean searches like:

```
("react native" OR RN) AND (senior OR staff) AND (bangalore OR remote) AND payments
```

Your profile must hit those tokens **in canonical, indexed fields**: headline, current title, skills, About. Tokens hidden in posts don't count for search.

The funnel: Recruiter searches → you appear → they click → first impression is photo + headline + current role → they scan About + recent role + skills + recommendations → they InMail → response time + tone determine pipeline velocity.

### The "Why"
- ~60% of senior RN roles in 2026 in India / SEA still close via LinkedIn / Naukri inbound.
- Open to Work alone doubles inbound volume; correct headline triples it.

### Mental Model
LinkedIn profile = **resume that recruiters search for**. SEO it.

### Internal Working (2026 Context)
- LinkedIn Recruiter ranks profiles by "Open to Work" + headline match + activity recency.
- Naukri ranks by "Active in last 15 days" heavily; log in weekly even if not job-hunting.
- AI-suggested headlines on LinkedIn are generic; write your own.

### Modern Implementation (Templates)

```
HEADLINE (pick one)
  Senior React Native Engineer · Performance + New Architecture · ex-Acme
  Staff Mobile Engineer · React Native · Offline-first systems · 12M+ MAU
  Senior RN Engineer (Hiring 2026) · Reanimated + Skia · Payments + Fintech

ABOUT
  I'm a Senior React Native engineer with 7 years shipping consumer mobile
  apps at 10M+ MAU scale. I specialize in the New Architecture, performance,
  and offline-first systems.

  Recent impact:
  • Migrated Acme's 1.2M-user app to RN New Arch; cold start −38%, crash-free 99.94%.
  • Designed offline-first ledger sync; support tickets for missing data −71% YoY.
  • Led 4-eng team to ship payments revamp; checkout completion +9% on Android.

  Open to Senior / Staff IC roles in India (Bangalore preferred) or remote.
  Especially interested in fintech, super-apps, and platform/infra teams.
```

### Comparison

| Headline | Inbound rate (relative) |
|---|---|
| "Software Engineer at Acme" | 1× (baseline) |
| "React Native Developer" | 2.1× |
| "Senior React Native Engineer · New Architecture · 10M+ MAU" | 4.5× |

### Production Usage
- **Update headline** the day you start a job hunt; recruiters notice.
- Pin 1–3 **Featured** items (talk, blog, OSS).
- Skills: top 3 are most visible; put RN, TS, Mobile Architecture there.

### Hands-On Exercise
1. Search for yourself on LinkedIn using a recruiter's likely query. Are you on page 1?
2. Ask 3 peers to read your About in 15 seconds and tell you what you do.
3. Send 2 InMail-style messages to your own LinkedIn from a friend's account; iterate the headline.

### Common Mistakes
- Headline = "passionate about technology" (says nothing).
- About in first person past-tense, list of every job (this is what Experience is for).
- Listing 50 skills (dilutes signal).

### Production Red Flags
- "Open to Work" globe but headline says "Hiring at..."
- Recommendations only from peers, none from managers.
- Inactive for 6+ months.

### Performance & Metrics
- Profile views per week.
- Search-appearance count (LinkedIn shows it weekly).
- InMail response rate.

### Decision Framework
- Naukri-first if India market + non-FAANG; LinkedIn-first for product / FAANG / global. Both — same content, profile mirrors resume.

### Senior-Level Insight
The strongest profiles feel like **a portfolio, not a CV**. Featured section, posts, and recommendations tell a story your bullets can't.

### Real-World Scenario
A senior engineer with strong skills had < 1 InMail/month. Adding "React Native" to headline (was "Mobile Engineer at Acme") tripled inbound in 2 weeks.

### Production Failure Story
**Incident:** Engineer rejected from a referral pipeline because LinkedIn title didn't match resume title (resume said "Senior", LinkedIn said "Software Engineer").
**Root cause:** Forgot to update LinkedIn after promotion.
**Fix:** Sync LinkedIn the same day you update your resume.

### Debugging Checklist
1. Does the headline contain "React Native" + a level word (Senior / Staff)?
2. Is location set correctly + Open to Remote toggled if true?
3. Top 3 skills include RN, TS, mobile architecture?
4. Activity within last 30 days?

### Advanced / Internal Knowledge
- LinkedIn's "easy apply" pulls headline as default cover line — make it standalone-readable.
- Naukri's "key skills" field is heavily weighted; put your top 5 there even if redundant.

### 2026 AI Tip
Use AI to A/B-test headlines against a target JD; pick the one with higher keyword overlap. Avoid AI-written About sections — they read generic and recruiters notice.

### Related Topics
Q1, Q3, `appendix/D-linkedin-naukri.md`.

### Interview Follow-Up Questions
- "Why are you looking right now?" (Match LinkedIn About's "ask" paragraph.)
- "What kind of role are you targeting?" (Same answer; consistency builds trust.)

### Memory Hook
**"Headline = role + specialty + scale. About = story + proof + ask."**

### Revision Notes
> LinkedIn = search engine for talent; SEO the headline; mirror resume; weekly activity; Open to Work invisible to employer; one polished About paragraph per: story, proof, ask.

---

## Q3. Negotiating a senior RN offer (multi-offer playbook)

### Difficulty
Intermediate → Advanced

### Interview Frequency
Always (every offer is a negotiation).

### Prerequisites
At least one written offer; ideally a competing one or a strong BATNA.

### TL;DR
**Always negotiate.** Anchor with a competing offer (real or honest market data); negotiate **all four levers** (base, equity / RSU, sign-on, joining/notice timeline); never accept verbally on the spot.

### 30-Second Interview Answer
"I never accept on the call. I thank them, ask for the offer in writing, and request 3–5 working days. I respond with a single counter that anchors on a competing offer or market data, and I negotiate all levers at once — base, equity, sign-on, joining bonus, level. I'm respectful, never adversarial, and I confirm everything in writing."

### 2-Minute Practical Answer
The four levers (in order of usual flexibility):
1. **Sign-on bonus** — most flexible; one-time cost; often used to bridge gaps.
2. **Equity / RSUs** — second-most flexible at FAANG / late-stage.
3. **Base salary** — band-bound; movable but slower.
4. **Level** — hardest to move post-offer; **negotiate before the loop ends if signals were strong**.

The script:
1. Receive offer verbally → "Thank you, very excited. Can you send the written offer? I'd like a few days to review."
2. Read the written offer (vesting schedule, refresher policy, joining date, claw-backs).
3. Counter once, with a clear ask and a justification.
4. Confirm everything in writing before resigning current role.

### 5-Minute Architecture Answer
Negotiation is a **two-sided information game**. The frame to keep is: "I want to join. Help me get to a number I can say yes to." Adversarial framing rarely beats collaborative framing.

**BATNA:** competing offer (strongest), honest market data (Levels.fyi, AmbitionBox, peer references), staying in current role with promo path.

The deal value isn't just total comp:
- **Vesting schedule** (1y cliff, 4y vest, monthly after; some companies do back-loaded 5/15/40/40).
- **Refresher policy** (RSU top-ups year 2+).
- **Sign-on claw-back** (12–24 months pro-rated).
- **Notice period support** (buyout, calendared joining bonus).
- **Level + scope** (level affects future promo speed and pay growth more than +5% base today).

### The "Why"
- Companies budget a **negotiation buffer** (typically 5–15% of initial offer); not asking is a guaranteed loss.
- Sign-on and equity are easiest to move because they don't permanently inflate the band.

### Mental Model
Negotiation = **collaborative price discovery**, not a fight.

### Internal Working (2026 Context)
- Many top companies use **comp committees**; recruiter negotiates internally for you. Help them by giving clear, justified asks.
- AI-driven leveling tools (Levels.fyi, Layered, AmbitionBox in India) give better data than ever.
- Indian markets in 2026: senior RN base bands at top product companies range widely; equity is increasingly meaningful at unicorns + listed firms.

### Modern Implementation (Counter-offer Email)

```
Subject: Offer at <Company> — quick follow-up

Hi <Recruiter>,

Thank you again for the offer — I'm genuinely excited about the team and
the New Architecture / payments work.

I have a competing offer at <similar tier> at $X TC (base $A, RSUs $B/yr,
sign-on $C). I'd like to join <Company> over them, but to make the math work
I'd need to get closer in TC.

Could we explore:
  • Base: from $a to $a' (closer to band midpoint)
  • RSUs: from $b to $b' (matching competing)
  • Sign-on: $C bridging notice-period gap
  • Joining date: 8 weeks (matching my notice)

Happy to sign within 24 hours of an updated offer. Let me know what's possible.

Thanks,
<Name>
```

### Comparison

| Lever | Flexibility | Long-term value |
|---|---|---|
| Sign-on | High | Low (one-time) |
| Equity (RSU) | Medium-High | High (compounds with refreshers) |
| Base | Medium | High (compounds via % increments) |
| Level | Low post-offer | Highest (governs trajectory) |

### Production Usage
- **Use a real competing offer when possible.** Honest market data otherwise.
- Never lie about competing offers — recruiters cross-check.
- Get **everything in writing before resigning**.

### Hands-On Exercise
1. Look up your target band on Levels.fyi / AmbitionBox. Write down P50, P75, P90.
2. Draft your counter email **before** the offer arrives so you're not negotiating under emotion.
3. Practice the 30-second "thank you, send it in writing, I need a few days" response out loud.

### Common Mistakes
- Accepting verbally before reading the contract.
- Negotiating one lever at a time.
- Bringing up comp **before** the offer.
- Threatening to walk without a real BATNA.

### Production Red Flags
- "Exploding" offers with < 48 hours — push back politely.
- "We don't negotiate" — sometimes true at FAANG entry levels, almost never at senior+.
- Refusal to put anything in writing.

### Performance & Metrics
- Average uplift on a clean negotiation: 8–15% TC.
- Sign-on bonus often movable by 50–100% from initial.
- Level upgrade post-offer: < 10% success rate; do it pre-offer.

### Decision Framework
- Strong competing offer → push hard on equity + base.
- No competing offer, but high market signal → push moderately on sign-on + equity.
- Single offer, weak market → push only on sign-on (least risky).

### Senior-Level Insight
At staff+, negotiate **scope and team** as fiercely as comp. Joining a stagnant team at $X is worse than a growing team at $X − 10%. Ask: "What does success look like in 12 months?" "Who would I report to?" "What's the team's roadmap?"

### Real-World Scenario
Engineer received initial offer of ₹52L TC. Counter with competing ₹58L brought it to ₹60L. Engineer almost accepted ₹52L without asking — would have lost ₹8L/year and compounding effect.

### Production Failure Story
**Incident:** Engineer accepted offer verbally on call; written offer arrived with lower equity than discussed.
**Root cause:** No paper trail; recruiter "misremembered."
**Fix:** Got verbal commitment redocumented in email.
**Prevention:** Never agree verbally; always wait for writing.

### Debugging Checklist
1. Did I read the full offer including vesting / refresher / claw-back?
2. Did I check market data for my band / city?
3. Did I bundle my counter into one email with all levers?
4. Did I get the final terms in writing before resigning?

### Advanced / Internal Knowledge
- Many companies have a **per-recruiter approval limit**; if your ask exceeds it, they go to the comp committee.
- Joining bonuses often have **claw-back** (full repay if you leave < 12 months).
- ESOPs at unlisted Indian startups: ask for **liquidity history** before valuing them.

### 2026 AI Tip
Use AI to draft and tighten your counter-offer email. Do not use AI to fabricate competing offer numbers — these get verified.

### Related Topics
Q1, Q4, `docs/24-resume-linkedin-negotiation.md`.

### Interview Follow-Up Questions
- "What are your comp expectations?" — defer until offer stage.
- "Do you have other offers?" — be honest but vague.

### Memory Hook
**"Always counter. Bundle the levers. Get it in writing."**

### Revision Notes
> Negotiate all four levers (base, equity, sign-on, level); use BATNA; never accept verbally; collaborate, don't fight; get everything in writing before resigning.

---

## Q4. From senior to staff — what changes in the narrative

### Difficulty
Advanced

### Interview Frequency
Common at staff+ loops.

### Prerequisites
Senior IC experience with at least one cross-team / multi-quarter project.

### TL;DR
Senior = ships features well. Staff = **changes how the org ships**. The narrative shifts from "I built X" to "I unblocked N teams / set the technical strategy / reduced ambiguity at the seam between Y and Z."

### 30-Second Interview Answer
"At senior, the bar is shipping high-quality features end-to-end with autonomy. At staff, the bar is **multiplier impact** — I'm measured by what other teams ship because of decisions I made. My narrative reframes around technical strategy, paved roads, ambiguity reduction, and teaching. A staff story has 3+ teams, a 6+ month horizon, and a measurable change in how the org operates."

### 2-Minute Practical Answer
Senior signals (table stakes for staff): owns large features end-to-end, makes good local technical decisions, mentors juniors.

Staff-specific signals:
- **Multipliers** — paved-road tools, frameworks, design systems used by 5+ engineers daily.
- **Technical strategy** — written docs that change the team's roadmap.
- **Ambiguity** — picks up undefined problems and produces clear plans.
- **Influence without authority** — gets cross-team buy-in via clarity, not titles.
- **Production sensibility** — designs systems that survive on-call.

The narrative for each story: **Scope** (N teams, M engineers, $K business impact, T quarters) → **What you decided** (the pivotal call only you could make) → **What changed in the org** (a process, doc, system, paved road).

### 5-Minute Architecture Answer
The senior → staff transition is mostly a **scope and influence shift**. The hardest parts:

1. **Scope expansion** — staff problems are ambiguous. Senior IC often gets a JIRA; staff IC writes the JIRA. Practice: take an undefined problem and write the strategy doc.
2. **Multipliers vs ICs** — your individual contribution stops being the metric. A staff IC who unblocks 6 engineers via paved road outperforms one who codes alone.
3. **Technical influence** — you influence engineers who don't report to you. Influence comes from being right consistently, clear written communication (RFCs, postmortems), and listening.
4. **Production maturity** — anticipate failure modes (capacity, blast radius, rollback, observability) at design time.
5. **Calibration awareness** — every panel asks "tell me about a time you influenced an outcome you didn't own." Have 3 stories ready, scoped, with metrics.

### The "Why"
- Companies create staff roles to **scale technical decision-making**.
- The org can pay 1 staff + 4 seniors more than 5 seniors **only if the staff multiplies the four**.

### Mental Model
Senior = **player**. Staff = **player-coach**. Principal = **coach**.

### Internal Working (2026 Context)
- Most product companies in 2026 distinguish "tech-lead staff" (single team's tech) from "platform staff" (cross-team paved roads).
- Pragmatic Engineer publishes staff archetypes (Tech Lead, Architect, Solver, Right Hand) — useful framing.
- Promotion packets at top companies require **3–5 artifacts**: design docs, postmortems, mentee growth, OKR contributions.

### Modern Implementation (Story Structure)

```
SITUATION (Scope)
  Org had 4 product teams shipping mobile apps with diverging arch.
  Cold start regressed 22% YoY across the portfolio.

TASK (My role)
  No formal owner of mobile platform. I picked it up.

ACTION (Multiplier work)
  • Wrote a 12-page mobile platform strategy doc; aligned 3 EMs + CTO.
  • Built a startup-perf paved road (lazy bundles + warmed JS context)
    and onboarded 4 teams in 6 weeks.
  • Established a mobile-perf weekly review with all 4 teams; metrics in Datadog.
  • Mentored 3 senior engineers to operate the paved road.

RESULT
  Cold start −31% portfolio-wide; my team −38%.
  Crash-free +0.4pp.
  4 teams now ship perf changes without my involvement.
  Promoted to Staff six months later.
```

### Comparison

| Dimension | Senior | Staff |
|---|---|---|
| Scope | One feature | One area / multi-team |
| Horizon | Sprint–quarter | Quarter–year |
| Output | Code + reviews | Code + RFCs + influence |
| Metric | Velocity, quality | Multiplier (other teams' velocity) |
| Ambiguity | Reduces own | Reduces team's / org's |

### Production Usage
- Keep a **brag doc** updated quarterly. Staff promo cycles need 4–6 quarters of evidence.
- Pair every "I did X" with "and N teams now do Y because of it."
- Volunteer for cross-team initiatives early.

### Hands-On Exercise
1. List your top 3 projects from the last year. Rewrite each in the staff frame: scope (teams), decision (the call only you could make), org change.
2. Identify one ambiguous problem in your org. Write a 2-page strategy doc. Share it with your manager.
3. Find one engineer outside your team you could mentor. Set a recurring 30-min slot.

### Common Mistakes
- "I'll get promoted by coding more" — at staff, more code can be **negative** signal.
- Hoarding architecture decisions; being the bottleneck.
- Talking impact in lines-of-code terms instead of business / org terms.

### Production Red Flags
- Senior engineer with 4 years in role and no cross-team artifact.
- "Staff candidate" whose stories all start with "I built…" never "the team built… and I…"
- No written artifacts.

### Performance & Metrics
**Staff promo packets typically need:**
- 3+ cross-team projects with measurable outcomes.
- 2+ written artifacts (RFC, strategy, postmortem).
- 2+ engineers visibly grown (mentees promoted or scope-expanded).
- 1+ instance of changing org-level direction.

### Decision Framework
- Aim for staff at **current company** if there's a clear scope-expanding opportunity. Internal promo is faster than external level-up.
- Switch externally if your current company **doesn't have staff scope** for your area.
- External staff offers usually require existing staff title or unambiguous staff-equivalent scope.

### Senior-Level Insight
The staff promo cliff isn't usually a skill problem; it's a **visibility and framing problem**. The work was done; the narrative wasn't built. Spend 2 hours per quarter on your brag doc and 1 hour per month on a written artifact.

### Real-World Scenario
A senior IC built a perf paved road used by 4 teams but didn't document it; promo committee rated it "individual contribution." A second senior, with similar scope, wrote a 1-page architecture doc + measured adoption — promoted to staff.

### Production Failure Story
**Incident:** Engineer in promo committee for 3 cycles, never promoted.
**Root cause:** Strong work, no cross-team narrative; manager couldn't articulate scope to committee.
**Fix:** Engineer wrote a self-review with explicit "teams I unblocked" section + linked artifacts. Manager used it verbatim. Promoted next cycle.

### Debugging Checklist
1. Can I name 3+ teams whose velocity I changed?
2. Do I have written artifacts (RFCs, strategy docs, postmortems)?
3. Have I grown other engineers visibly?
4. Have I changed an org-level direction in the last year?

### Advanced / Internal Knowledge
- "Staff" is not one thing — read Will Larson's *Staff Engineer* archetypes and find yours.
- Internal staff promos depend heavily on **manager advocacy**.

### 2026 AI Tip
Use AI to organize your brag doc, summarize artifacts into 1-page versions for promo packets, rehearse staff-level behavioral answers (focus on multiplier framing).

### Related Topics
Q1, Q5, S25 (behavioral), `appendix/E-star-story-bank.md`.

### Interview Follow-Up Questions
- "Tell me about a technical decision you made that other teams adopted."
- "Tell me about an ambiguous problem you took on."
- "How do you influence engineers who don't report to you?"

### Memory Hook
**"Senior ships. Staff multiplies. Principal sets direction."**

### Revision Notes
> Staff = multiplier impact (3+ teams), 6+ month horizon, written artifacts, influence without authority, production maturity. Brag doc + manager advocacy unlocks promo.

---

## Q5. Building a public engineering brand (blog / talks / OSS)

### Difficulty
Intermediate

### Interview Frequency
Common at senior+ loops, especially DevRel / platform teams.

### Prerequisites
Real production experience worth writing about.

### TL;DR
Pick **one channel** (blog, talks, or OSS). Ship something every month for 12 months. Optimize for **depth** (one strong post > 10 weak ones).

### 30-Second Interview Answer
"I picked a single channel — a technical blog — and committed to one deep post per month. I write about real problems we solved (RN New Arch migration, perf wins, debugging stories). Posts get cited internally and externally; recruiters cite them in InMails; I've been invited to two conferences. The compounding effect started at month 6."

### 2-Minute Practical Answer
The three channels:
1. **Blog** — best ROI for ICs. Long-tail SEO, citable, async.
2. **Talks** — high signal but episodic. One conference talk = 6 months of LinkedIn fuel.
3. **OSS** — highest credibility, highest cost. A single well-maintained library beats 20 abandoned ones.

What to write / talk about: real problems you solved at work (with permission / no PII), migration stories with metrics, debugging walkthroughs, comparison posts (X vs Y, with tradeoffs).

What **not**: "Top 10 React Native tips" (commodity), tutorial walkthroughs of docs (no value-add), hot takes without depth.

### 5-Minute Architecture Answer
A public brand is a **slow compounding asset**. The first 6 months feel like shouting into the void. After 12+ months: recruiters open with "I read your post on…", conference invites land in DMs, internal/external referrals come unsolicited, promotion packets cite external evidence.

The mistake most engineers make: trying all three channels at once and quitting all of them. **Pick one. Commit to a cadence. Keep going past the dip.**

For ICs in 2026, the highest-ROI move is a **technical blog with 6–12 deep posts on one topic**. Niche depth beats breadth. Krzysztof Magiera (Reanimated / Software Mansion), Evan Bacon (Expo), Nicola Corti (Meta RN) — all built audience by going deep on one area.

### The "Why"
- Hiring at senior+ is increasingly **inbound and warm**. A brand inverts the funnel.
- A public artifact is **proof of engineering judgment** that no resume bullet can match.

### Mental Model
Brand = **compounding equity in your career**. Skip the "viral post" fantasy; aim for the slow build.

### Internal Working (2026 Context)
- LinkedIn carousels and short-form posts: 24–48 hour half-life.
- Long-form blog posts: 12+ month tails via Google.
- GitHub OSS contributions show up in recruiter screens via GitHub stats / Sourcegraph.

### Modern Implementation (Cadence)

```
MONTH 1
  • Set up blog (Hashnode or Astro on Cloudflare).
  • Write post 1: a concrete problem you solved this quarter. ~1500 words.
  • Cross-post to dev.to and r/reactnative.

MONTHS 2–6
  • One post per month. Same topic area.
  • Each post: real problem, code, metrics, lessons.

MONTH 6+
  • Submit to react-native-newsletter / This Week in React.
  • Pitch a meetup talk based on best post.
  • Update LinkedIn Featured + headline ("writes about RN performance").

MONTH 12+
  • Pitch a conference (App.js Conf, React India, React Summit).
  • Open-source one tool you've built repeatedly internally.
```

### Comparison

| Channel | Effort | Half-life | Best for |
|---|---|---|---|
| LinkedIn post | Low | 48h | Top-of-mind |
| Twitter/X thread | Low | 24h | Community |
| Blog post | Medium | 12+ months | Compounding, SEO |
| Conference talk | High | 6–12 months | Authority, network |
| OSS library | Very high | Years | Credibility, recruiting |

### Production Usage
- **One channel, one topic, 12 months.** Then expand.
- Publish on your own domain (not Medium); own the URL.
- Add a small "Hire me / Available for senior RN roles" line to every post.

### Hands-On Exercise
1. List 5 problems you've solved at work in the last year. Pick the most interesting. Write it as a 1500-word post in 2 hours.
2. Publish it. Share on LinkedIn + dev.to + r/reactnative.
3. Track: views, comments, InMails referencing it. After 5 posts, evaluate ROI.

### Common Mistakes
- Trying all channels at once; burning out by month 3.
- Writing tutorials that duplicate docs.
- Optimizing for virality (clickbait) instead of depth.
- Posting on someone else's platform without owning the URL.

### Production Red Flags (for your own brand)
- 3+ months of no output → reset cadence or pause publicly.
- Only meta-content (posts about writing, not engineering).
- Posts without code or metrics.

### Performance & Metrics
- Inbound InMails per month referencing content.
- Conference / podcast invites per year.
- Internal citation (your post linked in PR descriptions or design docs).

### Decision Framework
- Strong writing skill → blog first.
- Strong communicator / extrovert → talks first.
- Strong systems builder → OSS first.

### Senior-Level Insight
Brand without substance evaporates fast. The strongest public brands in mobile are people who **shipped real things at real scale and wrote honestly about it**. Substance compounds; performance theater doesn't.

### Real-World Scenario
A senior RN engineer wrote one deep post per month on Reanimated internals for 9 months. Got a referral to Software Mansion via the posts. Switched companies at 30% comp uplift, no traditional interview loop.

### Production Failure Story
**Incident:** Engineer wrote 40 short posts in 3 months, burned out, deleted blog.
**Root cause:** Cadence too aggressive; topic too broad; no depth per post.
**Fix:** Restarted at 1 deep post per month on a single topic; sustainable for 18+ months.

### Debugging Checklist
1. Am I posting on a cadence I can sustain for 12 months?
2. Is each post tied to a real problem I solved (not a tutorial)?
3. Do I own the URL?
4. Am I cross-posting to where my audience lives?

### Advanced / Internal Knowledge
- The best blog discoverability channel for RN in 2026 is the **React Native Newsletter** + **This Week in React**.
- OSS maintenance is a **multi-year commitment**; only start if you can sustain. Otherwise contribute upstream.

### 2026 AI Tip
Use AI to outline posts from your raw notes, suggest titles, edit for clarity. Do **not** let AI write the body — readers and recruiters can tell within a paragraph.

### Related Topics
Q1, Q2, Q4, S26 (AI-assisted engineering).

### Interview Follow-Up Questions
- "Walk me through the post you're most proud of."
- "What's the hardest engineering problem you've written about?"
- "How do you decide what to share publicly vs keep internal?"

### Memory Hook
**"One channel. One topic. Twelve months. Then evaluate."**

### Revision Notes
> Public brand = compounding career equity; pick one channel; commit 12 months; depth > breadth; own your URL; expect dip before payoff at month 6+.

---

> Cross-refs: `appendix/C-resume-template.md`, `appendix/D-linkedin-naukri.md`, `appendix/E-star-story-bank.md`, `docs/24-resume-linkedin-negotiation.md`, S25 (behavioral), S04/S22 (technical depth that fuels staff narratives).
