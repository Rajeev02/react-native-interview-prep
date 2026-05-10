## Appendix F — Extended Q&A Bank (rehearse short + deep versions)

> For every important answer, prepare **20-sec / 60-sec / 3-min** versions. That is how you sound senior and controlled.

### F.1 — Why React Native?
**Short**: RN lets teams build iOS + Android with shared TS codebase rendering native UI — faster iteration, shared logic, lower cost without giving up near-native UX.
**Deep**: Best when product needs fast feature velocity across both platforms with mostly standard mobile UX. Weaker when graphics-heavy, deeply platform-specific, or extremely native-API-dependent. I frame RN as a trade-off between velocity, native depth, team composition, long-term maintainability.

### F.2 — Old bridge vs JSI
**Short**: Bridge serialized messages async between JS and native, adding overhead. JSI lets JS interact directly with native objects/functions, cutting serialization cost and improving performance.
**Deep**: In bridge model, every cross-boundary call required marshalling JSON, sending across, reconstructing — latency + expense for high-frequency calls. JSI exposes native via JS interfaces without that bottleneck. Especially valuable for animations, large data transfers, custom modules. Reanimated 3 worklets use JSI to run on UI thread.

### F.3 — Fabric and TurboModules
**Short**: Fabric is the new renderer; TurboModules are the new way to build native modules with better startup + invocation perf.
**Deep**: Fabric modernizes UI rendering with efficient scheduling + mounting. TurboModules modernize loading + access — often lazy-loaded, work with JSI + Codegen. The new arch improves perf, startup, and native interop.

### F.4 — Designing a scalable RN app for fintech
**Short**: Modular feature-based architecture with clear separation of UI, domain, API, storage, analytics, security. Optimized for release safety, observability, secure auth + payments.
**Deep**: Feature modules (onboarding, portfolio, transactions, KYC, payments, notifications). Shared layers: navigation, API client, auth/session, secure storage, analytics, error reporting, design system. Separate client state from server state. Typed contracts. Route guards. Centralized error handling. Sentry + analytics first-class. Goal: predictable delivery with low regression risk.

### F.5 — RTK vs Zustand vs React Query
**Short**: RTK for large shared app state + team consistency; Zustand for lightweight client state; React Query for server state (cache, retry, invalidation).
**Deep**: Not mutually exclusive. React Query: caching, stale data, retry, background refresh, mutations. RTK: structured global state, traceability, middleware, conventions. Zustand: localized global state with low ceremony. Lead-level maturity = choose by state category, not preference.

### F.6 — Debug performance issues in RN
**Short**: Identify whether bottleneck is JS thread, UI thread, network, image, or memory. Profile, reproduce with instrumentation, optimize highest-cost path.
**Deep**: Workflow: reproduce consistently → define user symptom → check JS thread load, re-renders, list virtualization, image sizes, network waterfall, startup path, native resources. Tools: Hermes profiler, Instruments, Android Profiler, Sentry traces. Common fixes: memoize rows, reduce re-renders, batch work, defer SDK init, optimize images, reduce bridge overhead.

### F.7 — FlatList vs ScrollView vs FlashList
**Short**: ScrollView for small content. FlatList virtualizes — default for larger. FlashList for perf-critical, complex rows.
**Deep**: Choose by data size, row complexity, scroll expectations. ScrollView risky for long/media-heavy lists. FlatList: virtualization + config. FlashList: consistency for complex feeds at scale. Always: stable keys, `getItemLayout` when possible, tuned batch settings, lightweight rows, image strategy.

### F.8 — Secure auth tokens
**Short**: Access + refresh tokens in Keychain (iOS) / Keystore-backed (Android), not AsyncStorage.
**Deep**: Storage + lifecycle + transport. Short-lived access tokens with refresh flow. Single-flight refresh logic. Clear sensitive caches on logout. Avoid logging tokens. Guard sensitive screens with re-auth/biometrics. Fintech: session timeout, compromised device risk, secure deep links, minimum PII in analytics/crashes.

### F.9 — Multiple concurrent 401s
**Short**: Single-flight refresh — only one token refresh happens; pending requests wait for new token.
**Deep**: Without single-flight, concurrent 401s create refresh storms, token invalidation, inconsistent session. Approach: queue/pause failed requests, refresh once, replay after success, fail cleanly if refresh fails. Important for background fetches, parallel dashboards, real-time reconnection.

### F.10 — Safe payment flow design
**Short**: Backend is source of truth. App handles initiation, status polling/callbacks, retry UX, idempotent submission.
**Deep**: Server-generated payment intent/order, idempotency keys, SDK integration, webhook reconciliation, clear retry states. Assume crash/connectivity loss mid-payment — on next open, reconcile from backend. Lead-level: analytics, failure categorization, user trust, support tooling.

### F.11 — RN → Capacitor migration narrative
**Short**: Business + engineering trade-off, not framework religion. Decision depends on product needs, team strengths, web reuse, perf, release speed.
**Deep**: Honest framing — what RN gave you, what it cost, why Capacitor improved some areas, trade-offs that remained. Cover architecture, dev velocity, native plugin model, UI feel, perf, migration risk, QA cost, user-impact mitigation during rollout.

### F.12 — Senior testing approach
**Short**: Pyramid: unit (Jest) for logic, component (RNTL) for UI, integration for important flows, selective E2E (Detox/Maestro) for release confidence.
**Deep**: Optimize for confidence per dollar of maintenance. Unit: pure utilities, state, edge cases. Component: screen behavior + contracts. Integration: login, payment, critical nav. E2E: minimum path protecting release. Care about mocking, flake reduction, suite speed.

### F.13 — RN CI/CD pipeline contents
**Short**: Lint, type-check, unit tests, build validation, versioning, signed release, source map / symbol upload, staged rollout.
**Deep**: Dependency caching, env separation, secrets handling, Android + iOS build jobs, build-number strategy, store-ready artifacts, crash symbol uploads, release notes automation. Reduce human error; make hotfixes safe.

### F.14 — Secure deep linking
**Short**: Validate route params, enforce auth guards, never trust arbitrary link data, sensitive destinations require session state.
**Deep**: Deep linking is an input surface. Validate route shape, restrict unsupported actions, handle deferred install links carefully, route protected destinations through auth + state checks. Avoid leaking sensitive values via URLs, notifications, analytics.

### F.15 — Mobile tech lead leadership
**Short**: Sound technical decisions, improved delivery quality, mentoring, alignment with product, ownership of production outcomes.
**Deep**: Lead is hands-on but operates wider. Set engineering standards, guide architecture, do high-leverage code reviews, unblock cross-team dependencies, improve release reliability, help team make better independent decisions. Strong examples: improved velocity, code quality, incident prevention.

### DSA topics to prioritize
1. Arrays + hashing
2. Two pointers
3. Sliding window
4. Stack + queue
5. Binary search
6. Linked list
7. Trees + BFS/DFS
8. Heaps + top K
9. Backtracking
10. DP basics
11. Graph traversal
12. LRU cache

### DSA questions worth practicing first
1. Two Sum
2. Longest Substring Without Repeating Characters
3. Valid Parentheses
4. Merge Intervals
5. Binary Search
6. Search in Rotated Sorted Array
7. Reverse Linked List
8. Detect Cycle in Linked List
9. Level Order Traversal
10. Lowest Common Ancestor
11. Number of Islands
12. Top K Frequent Elements
13. Course Schedule
14. Coin Change
15. LRU Cache

### First behavioral questions to prepare cold
1. Tell me about yourself.
2. Why are you looking for a change now?
3. Tell me about a difficult production issue you handled.
4. Tell me about a technical disagreement with product or management.
5. Tell me about mentoring a junior engineer.
6. Tell me about a project where you made an architecture trade-off.
7. Tell me about a release that went wrong.
8. Why should we hire you for a mobile lead role?

---

