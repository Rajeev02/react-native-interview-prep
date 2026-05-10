## 1. Profile positioning + numbers

**One-liner**: `Senior Mobile / RN Tech Lead, 9+ YOE, fintech depth (LetsVenture), end-to-end Android+iOS ownership, auth + payments + deep linking + observability.`

**Target roles**: Senior RN Engineer (IC4/SDE-3) → Lead RN Developer → Mobile Tech Lead → Fintech Mobile Lead.

**Comp targets (Bengaluru, 2026)**: ₹40+ LPA floor, ₹45–55 LPA target, ₹55–70 LPA stretch with competing offers. Anchor recruiter at ₹48–55 LPA fixed. Never disclose ₹23 LPA early — say *"low-20s fixed; evaluating ₹45–55 LPA band based on scope"*.

**Top-20 targets**: PhonePe, Razorpay, CRED, Groww, Zerodha, Jupiter, Slice, Freecharge / Swiggy, Zomato, Flipkart, Meesho, Dream11, PharmEasy / Microsoft, Walmart, Atlassian, Coinbase, Booking, Postman/Zeta. Full breakdown: [job-market-2026-top20-plan.md](job-market-2026-top20-plan.md).

---



---

## Top 25 Q&A — Profile positioning, comp & strategy

> Use these as **recruiter / hiring-manager screen** answers. Keep each verbal answer to 30–60 seconds.

### 1. Walk me through your background.
> "9+ years building consumer mobile apps. Last ~3 years senior IC + tech lead on React Native at LetsVenture — fintech, owned auth, KYC, payments, deep linking, observability across iOS + Android. Before that, mixed native Android + RN. Looking for Senior / Lead RN role with bigger fintech scale."

### 2. Why are you looking to switch?
> "Three things: (1) scale — want 10M+ MAU consumer surface; (2) growth — into Lead / Staff IC track with formal mentoring scope; (3) comp — current band is below market for my YOE."

### 3. What's your current CTC and expectation?
> "Current is low-20s LPA fixed. For this role and scope I'm evaluating in the ₹45–55 LPA fixed band with reasonable variable + ESOPs." **Never disclose ₹23 exact early.**

### 4. Why React Native and not native?
> "I've shipped both. RN gives 70–80% code reuse, single team, faster iteration — critical for fintech where the same KYC/payment flow ships on both stores weekly. I still drop to Swift/Kotlin for camera, biometrics, payment SDKs."

### 5. What's your strongest technical area?
> "Performance + native interop. I've cut cold start from 3.2s → 1.4s using Hermes + inline requires + native splash, and shipped 3 native modules (biometric auth, NFC reader, secure keystore wrapper)."

### 6. Tell me about your team size and structure.
> "Pod of 6 engineers (2 RN, 2 backend, 1 QA, 1 designer). I lead the mobile track — code review, architecture decisions, on-call rotation, sprint planning input."

### 7. Do you have iOS + Android release experience?
> "Yes — own both pipelines. Fastlane + EAS, signed builds, store metadata, phased rollout, TestFlight + Internal Testing, crash triage post-release."

### 8. What's the largest app you've shipped?
> "LetsVenture Wealth — ~250K MAU, ~15MB bundle, 60+ screens, end-to-end KYC + investments + portfolio + payments."

### 9. How do you measure mobile quality?
> "Crash-free users (target ≥ 99.5%), ANR rate, p95 cold start, p95 API latency, JS thread frame drops, store rating, conversion funnel drop-offs per screen."

### 10. What's your stance on Expo vs bare RN?
> "Expo for 0→1 and small-to-mid teams — config plugins now cover 90% of native needs. Bare for fintech where I need full control over native code, custom keystores, payment SDKs."

### 11. Have you led a migration?
> "Yes — RN 0.66 → 0.74 with new arch enabled (Fabric + TurboModules) for 3 of our modules. Took 6 weeks; staged behind a runtime flag."

### 12. Comp negotiation — what's your floor?
> "₹40 LPA fixed is my floor for an IC role; for Lead with people scope, ₹48+ LPA. I'm open to RSU / ESOP weighting."

### 13. Do you have competing offers?
> "I'm in active loops with 2 fintechs and 1 product company. Happy to share timelines if we can align on ranges first." (Use even if it's just early conversations.)

### 14. Why should we hire you over a native dev?
> "Because in 6 months you'll need both iOS + Android features shipped same-sprint. I can do that solo and still write the native module when RN can't reach."

### 15. What's a weakness?
> "Used to under-document architectural decisions. Fixed it last year — every non-trivial PR now has an ADR. Happy to walk you through one."

### 16. Where do you see yourself in 3 years?
> "Mobile Tech Lead / Staff IC at a fintech of scale — owning a domain (payments / wealth / lending), mentoring 4–6 engineers, setting platform direction."

### 17. How do you handle disagreement with a senior engineer?
> "Data first. I write a short doc, list trade-offs, propose a small spike. If still split, escalate to architecture review. Never fight in PR comments."

### 18. Can you work onsite / hybrid in Bengaluru?
> "Yes — 3 days hybrid is ideal. Full WFH if the team is distributed."

### 19. Notice period?
> "60 days; can negotiate to 30 with buyout if needed."

### 20. Do you code daily as a lead?
> "Yes — at least 50% IC. Lead means I unblock + raise the bar, not stop coding. I review every prod PR in our domain."

### 21. What open source / side projects do you have?
> "Two RN libraries on GitHub (small, ~100 stars combined). Active contributor to one navigation library." *(Adapt to truth.)*

### 22. How do you keep current with RN?
> "RN release notes, Discord working group, Evan Bacon / Brent Vatne on X, Software Mansion blog, conference talks (App.js, Chain React)."

### 23. What's your view on fabric / new arch in production?
> "Stable for new apps as of 0.74+. For brownfield with many native deps, I'd enable per-module and migrate incrementally. The jump in interop perf for sync calls + view flattening is real."

### 24. Have you handled a sev1 / customer-impacting incident?
> "Yes — payment success webhook race caused duplicate orders for 11 mins. I led mitigation (kill-switch via remote config), wrote post-mortem, added idempotency key on client + server. Will share full STAR in the loop."

### 25. What questions do you have for us?
> Always have 3 ready: (1) team's biggest mobile pain right now? (2) how do you measure success in the first 90 days? (3) what's the path from Senior → Lead / Staff here?
