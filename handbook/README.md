# React Native 2026 — The Engineering Handbook & Interview Bible

> Built from [final-prompt.md](../final-prompt.md). This handbook is the single source of truth for React Native engineering and interviews in 2026 — beginner intuition through staff/architect-level system design.

## How this handbook is organized

Each section file contains numbered **Q-topics** (`Q1`, `Q2`, …). Every Q-topic follows the **mandatory per-topic format** defined in the master prompt:

`Difficulty → Frequency → Prerequisites → TL;DR → 30s/2min/5min answers → The Why → Mental Model → Internal Working (2026) → Code → Comparison → Production Usage → Hands-On → Common Mistakes → Red Flags → Performance & Metrics → Decision Framework → Senior Insight → Real-World Scenario → Production Failure Story → Debugging Checklist → Advanced/Internal → 2026 AI Tip → Related → Follow-Ups → Memory Hook → Revision Notes`

## Sections

| #   | Section                                                                              | Status      |
| --- | ------------------------------------------------------------------------------------ | ----------- |
| S0  | [Career Strategy](S00-career-strategy.md)                                            | scaffold    |
| S1  | [JavaScript & TypeScript](S01-javascript-typescript.md)                              | scaffold    |
| S2  | [React 19 + React Compiler](S02-react-19.md)                                         | **content** |
| S3  | [React Native Core](S03-react-native-core.md)                                        | **content** |
| S4  | [New Architecture (JSI/Fabric/TurboModules/Bridgeless)](S04-new-architecture.md)     | **content** |
| S5  | [Expo & Tooling](S05-expo-tooling.md)                                                | scaffold    |
| S6  | [Hermes & Metro](S06-hermes-metro.md)                                                | **content** |
| S7  | [Performance Optimization](S07-performance.md)                                       | **content** |
| S8  | [State Management](S08-state-management.md)                                          | **content** |
| S9  | [Networking](S09-networking.md)                                                      | **content** |
| S10 | [Auth & Security](S10-auth-security.md)                                              | scaffold    |
| S11 | [Offline-first Systems](S11-offline-first.md)                                        | scaffold    |
| S12 | [Push Notifications](S12-push-notifications.md)                                      | scaffold    |
| S13 | [Android + Kotlin](S13-android-kotlin.md)                                            | scaffold    |
| S14 | [iOS + Swift](S14-ios-swift.md)                                                      | scaffold    |
| S15 | [Native Bridging](S15-native-bridging.md)                                            | **content** |
| S16 | [Architecture & Scaling](S16-architecture-scaling.md)                                | scaffold    |
| S17 | [Testing & Debugging](S17-testing-debugging.md)                                      | scaffold    |
| S18 | [Observability](S18-observability.md)                                                | scaffold    |
| S19 | [Accessibility & i18n](S19-accessibility-i18n.md)                                    | scaffold    |
| S20 | [CI/CD & Release Engineering](S20-cicd-release.md)                                   | scaffold    |
| S21 | [Server-Driven UI](S21-sdui.md)                                                      | scaffold    |
| S22 | [System Design (Mobile)](S22-system-design.md)                                       | scaffold    |
| S23 | [Coding Rounds (Machine Coding)](S23-machine-coding.md)                              | scaffold    |
| S24 | [DSA for Mobile](S24-dsa.md)                                                         | scaffold    |
| S25 | [Behavioral Interviews](S25-behavioral.md)                                           | scaffold    |
| S26 | [AI-Assisted Engineering](S26-ai-assisted.md)                                        | scaffold    |
| S27 | [Production Runbooks](S27-runbooks.md)                                               | scaffold    |
| S28 | [Study Plans](S28-study-plans.md)                                                    | scaffold    |
| S29 | [Cross-Target RN (Web/macOS/visionOS/TV)](S29-cross-target.md)                       | scaffold    |
| S30 | [Privacy, Compliance & Trust](S30-privacy-compliance.md)                             | scaffold    |

> **scaffold** = section index + topic list + Q-topic stubs; content to be filled in next iterations.
> **content** = Q-topics fully written in the mandatory per-topic format.

## Reading order

- **Beginner → Mid:** S1 → S2 → S3 → S5 → S6 → S7 → S8 → S9 → S11 → S17
- **Senior:** add S4 → S10 → S15 → S18 → S20 → S22 → S25
- **Staff / Architect:** add S16 → S21 → S27 → S29 → S30 + deep S4 / S6
- **Last 7 days before onsite:** S22 system design + S25 behavioral + the "Revision Notes" of every Q-topic

## Conventions

- Code is **TypeScript strict, React 19+, React Compiler-aware** (no manual `useMemo`/`useCallback` unless explained).
- Deprecated patterns explicitly tagged `[DEPRECATED]` (Bridge, Animated without native driver, Headless JS, Flipper).
- 2026-only features tagged `[2026]` (Static Hermes, Privacy Manifests, visionOS, Bridgeless default).
- Every Q-topic ends with **Memory Hook** + **Revision Notes** (one-line spaced-repetition summary).

## Filling in scaffolds

To expand a scaffold into full content, ask:

> "Fill in S<NN> using the per-topic format from `final-prompt.md`."

The agent will read the section's topic list and produce one Q-topic at a time using the mandatory 25+-section template, matching the depth of S2 / S4 / S6 / S7.
