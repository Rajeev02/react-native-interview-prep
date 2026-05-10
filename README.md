# React Native Senior / Lead Interview Study Plan — 2026

> **Audience:** React Native engineers preparing for **Senior / Staff / Lead / Architect** loops at product companies and fintechs (PhonePe, CRED, Razorpay, Groww, Zerodha, Swiggy, Flipkart, Microsoft, Walmart, Atlassian, Coinbase, Booking…).
> **Goal:** Role-level progression — **Mid → Senior → Staff/Lead → Principal/Architect**. The depth here targets Senior+ loops; juniors can use it as a roadmap.

This repo is the single source of truth for the prep. The original monolithic plan lives in [MasterPlan.md](MasterPlan.md); this README is the **navigable index** split by topic.

> 📍 **Follow ONE plan, not many.** The unified 45-day learning path is **[THE-PLAN.md](THE-PLAN.md)** — open it now and follow it day-by-day. Appendix B (30-day) and Appendix N (14-day sprint) still exist as detailed references but are folded into THE-PLAN.

---

## ⭐ NEW: The 2026 Engineering Handbook (`handbook/`)

> **Primary source of truth for 2026 onward.** Built from [final-prompt.md](final-prompt.md) — 31 sections covering React Native engineering from beginner intuition through staff/architect-level system design. Every Q-topic follows the mandatory 25+ subsection format (TL;DR → 30s/2min/5min answers → Internal Working → Production Failure Story → Memory Hook → Revision Notes).

**Start here:** [handbook/README.md](handbook/README.md)

| Layer | Sections |
|---|---|
| **Career & foundations** | [S00 Career Strategy](handbook/S00-career-strategy.md) · [S01 JS/TS](handbook/S01-javascript-typescript.md) · [S02 React 19](handbook/S02-react-19.md) |
| **RN core + architecture** | [S03 RN Core](handbook/S03-react-native-core.md) · [S04 New Architecture](handbook/S04-new-architecture.md) · [S05 Expo](handbook/S05-expo-tooling.md) · [S06 Hermes/Metro](handbook/S06-hermes-metro.md) |
| **Performance + state** | [S07 Performance](handbook/S07-performance.md) · [S08 State](handbook/S08-state-management.md) · [S09 Networking](handbook/S09-networking.md) |
| **Auth, offline, push** | [S10 Auth/Security](handbook/S10-auth-security.md) · [S11 Offline-first](handbook/S11-offline-first.md) · [S12 Push](handbook/S12-push-notifications.md) |
| **Native + bridging** | [S13 Android/Kotlin](handbook/S13-android-kotlin.md) · [S14 iOS/Swift](handbook/S14-ios-swift.md) · [S15 Native Bridging](handbook/S15-native-bridging.md) |
| **Architecture + ops** | [S16 Scaling](handbook/S16-architecture-scaling.md) · [S17 Testing](handbook/S17-testing-debugging.md) · [S18 Observability](handbook/S18-observability.md) · [S19 a11y/i18n](handbook/S19-accessibility-i18n.md) · [S20 CI/CD](handbook/S20-cicd-release.md) |
| **System design + interviews** | [S21 SDUI](handbook/S21-sdui.md) · [S22 System Design](handbook/S22-system-design.md) · [S23 Machine Coding](handbook/S23-machine-coding.md) · [S24 DSA](handbook/S24-dsa.md) · [S25 Behavioral](handbook/S25-behavioral.md) |
| **Modern + cross-target** | [S26 AI-Assisted](handbook/S26-ai-assisted.md) · [S27 Runbooks](handbook/S27-runbooks.md) · [S28 Study Plans](handbook/S28-study-plans.md) · [S29 Cross-Target](handbook/S29-cross-target.md) · [S30 Privacy/Compliance](handbook/S30-privacy-compliance.md) |

**Relationship to legacy `docs/`:** The `docs/` chapters and appendices remain as a curated 45-day day-by-day plan ([THE-PLAN.md](THE-PLAN.md)). The `handbook/` is the deeper reference book — use the day-by-day plan to schedule your prep, and dive into the matching `handbook/SXX-*.md` for full depth on each topic.

---

## How to use this repo

1. **Open [THE-PLAN.md](THE-PLAN.md)** and follow Days 1 → 45 in order.
2. **Each day** points you to the exact `docs/` chapter, [Appendix L](appendix/L-50q-drill-bank.md) drill section, [Appendix M](appendix/M-architecture-diagrams.md) diagram, and DSA problems to do that day.
3. **Mock prep:** for each topic, you must answer the **"Must-answer questions"** at the bottom of every doc out loud in 60 seconds.
4. **Last 3 days before any onsite:** read [25 — Last-mile cheatsheet](docs/25-cheatsheet.md) + the relevant company section in [Appendix A](appendix/A-top-20-companies.md).

---

## Table of contents

### Core curriculum (`docs/`)

| # | Topic | File |
|---|---|---|
| 1 | Profile positioning + numbers | [01-profile-positioning.md](docs/01-profile-positioning.md) |
| 2 | JavaScript core | [02-javascript-core.md](docs/02-javascript-core.md) |
| 3 | TypeScript for senior RN | [03-typescript.md](docs/03-typescript.md) |
| 4 | React deep dive | [04-react-deep-dive.md](docs/04-react-deep-dive.md) |
| 5 | React Native architecture (old + new) | [05-rn-architecture.md](docs/05-rn-architecture.md) |
| 6 | Hermes, Metro, bundle, startup | [06-hermes-metro-bundle.md](docs/06-hermes-metro-bundle.md) |
| 7 | Performance: lists, animations, images, memory | [07-performance.md](docs/07-performance.md) |
| 8 | Native modules (Swift + Kotlin) | [08-native-modules.md](docs/08-native-modules.md) |
| 9 | Debugging toolkit | [09-debugging.md](docs/09-debugging.md) |
| 10 | State management | [10-state-management.md](docs/10-state-management.md) |
| 11 | Navigation + deep linking | [11-navigation-deep-linking.md](docs/11-navigation-deep-linking.md) |
| 12 | Networking, REST, GraphQL, WebSockets | [12-networking.md](docs/12-networking.md) |
| 13 | Auth, sessions, tokens | [13-auth-sessions-tokens.md](docs/13-auth-sessions-tokens.md) |
| 14 | Offline-first + storage | [14-offline-storage.md](docs/14-offline-storage.md) |
| 15 | Push notifications | [15-push-notifications.md](docs/15-push-notifications.md) |
| 16 | Mobile security (fintech-critical) | [16-mobile-security.md](docs/16-mobile-security.md) |
| 17 | Accessibility, color, fonts, i18n | [17-accessibility-i18n.md](docs/17-accessibility-i18n.md) |
| 18 | Testing strategy | [18-testing.md](docs/18-testing.md) |
| 19 | CI/CD, EAS, Fastlane, releases | [19-cicd-releases.md](docs/19-cicd-releases.md) |
| 20 | Observability: Sentry, Crashlytics, analytics | [20-observability.md](docs/20-observability.md) |
| 21 | Mobile system design | [21-system-design.md](docs/21-system-design.md) |
| 22 | DSA must-knows | [22-dsa.md](docs/22-dsa.md) |
| 23 | Behavioral + leadership (STAR) | [23-behavioral-star.md](docs/23-behavioral-star.md) |
| 24 | Resume, LinkedIn, applications, negotiation | [24-resume-linkedin-negotiation.md](docs/24-resume-linkedin-negotiation.md) |
| 25 | Last-mile cheatsheet | [25-cheatsheet.md](docs/25-cheatsheet.md) |
| 26 | Lifecycles — Android / iOS / React / RN | [26-lifecycles.md](docs/26-lifecycles.md) |

### Appendices (`appendix/`)

| ID | Topic | File |
|---|---|---|
| A | Top-20 target companies + market signals | [A-top-20-companies.md](appendix/A-top-20-companies.md) |
| B | **30-day study schedule (daily plan)** | [B-30-day-schedule.md](appendix/B-30-day-schedule.md) |
| C | Resume template (1 page) | [C-resume-template.md](appendix/C-resume-template.md) |
| D | LinkedIn + Naukri positioning | [D-linkedin-naukri.md](appendix/D-linkedin-naukri.md) |
| E | STAR story bank (10 stories) | [E-star-story-bank.md](appendix/E-star-story-bank.md) |
| F | Extended Q&A bank (short + deep) | [F-qa-bank-extended.md](appendix/F-qa-bank-extended.md) |
| G | Deep Q&A bank with code + production scenarios | [G-qa-bank-deep.md](appendix/G-qa-bank-deep.md) |
| H | Gap-fill: handbook topics missing earlier | [H-gap-fill.md](appendix/H-gap-fill.md) |
| I | The six engineering tracks (lead-level breakdown) | [I-six-engineering-tracks.md](appendix/I-six-engineering-tracks.md) |
| J | Expo Router, Config Plugins, AI-assisted eng, Top-50 Q index | [J-expo-router-config-plugins.md](appendix/J-expo-router-config-plugins.md) |
| K | **YouTube references (personal collection)** | [K-youtube-references.md](appendix/K-youtube-references.md) |
| L | **50-Q drill bank per section** (~1,150 Qs) | [L-50q-drill-bank.md](appendix/L-50q-drill-bank.md) |
| M | **Architecture & threading diagrams (Mermaid)** | [M-architecture-diagrams.md](appendix/M-architecture-diagrams.md) |
| N | **14-day final sprint checklist** | [N-14-day-sprint.md](appendix/N-14-day-sprint.md) |
| Z | Final coverage verification | [Z-final-verification.md](appendix/Z-final-verification.md) |

---

## 45-day unified plan (high level)

Full per-day breakdown in **[THE-PLAN.md](THE-PLAN.md)**. Old schedules ([Appendix B](appendix/B-30-day-schedule.md), [Appendix N](appendix/N-14-day-sprint.md)) are kept for cross-reference only.

| Phase | Days | Theme |
|---|---|---|
| 1 — Foundations | 1–7 | JS / TS / React fundamentals |
| 2 — RN core + perf | 8–14 | Architecture, Hermes, perf, native modules, debugging |
| 3 — Production stack | 15–21 | State, nav, networking, auth, offline, push, security |
| 4 — Quality + ops | 22–27 | a11y, testing, CI/CD, observability, system design, DSA |
| 5 — Career mechanics | 28–31 | Behavioral, resume, LinkedIn, applications |
| 6 — Final sprint | 32–45 | Re-grounding + drilling + mocks + diagrams |
| 7 — Loops | 46+ | Active interviews + per-loop prep |

---

## Conventions

- Every `docs/NN-*.md` ends with a **Must-answer questions** block — drill those out loud.
- Code blocks are interview-ready snippets, not production-grade — adapt before shipping.
- Targets are **role-level** (Senior / Staff / Lead / Architect), not compensation-based — applicable across markets.

---

## Source

- [MasterPlan.md](MasterPlan.md) — the original single-file plan, kept verbatim for diffs and search.
