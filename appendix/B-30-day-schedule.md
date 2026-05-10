## Appendix B — 30-Day Study Schedule (basics → advanced)

> Cadence: 6–8 hrs/day, 6 days/week, 1 day rest.
> Daily template (8 hrs): 90 min theory + 90 min hands-on + 60 min Qs + 60 min DSA + 60 min recall + 30 min review + 30 min buffer.

### Week 1 — JS/TS + React fundamentals (the screen-out filter)
- **Day 1 — JS core**: execution context, hoisting, scope, closures, `this` binding. *Hands-on*: 5 closure puzzles + 5 `this` puzzles. → Section 2.
- **Day 2 — JS async**: event loop, microtasks/macrotasks, Promises, `async/await`, `Promise.all/allSettled/race/any`. *Hands-on*: implement `pLimit` + `retry` + `Promise.all` from scratch. → Section 2.
- **Day 3 — TypeScript**: type vs interface, generics, utility types, discriminated unions, type guards, narrowing. *Hands-on*: typed `useFetch<T>`, typed navigation, Zod for one API. → Section 3.
- **Day 4 — React + hooks**: render cycle, `useState/Effect/Ref/Memo/Callback/Context/Reducer`, dependency arrays. *Hands-on*: build `useDebounce`, `usePrevious`, `useToggle`, `useInterval`, `useAsync`. → Section 4.
- **Day 5 — React advanced + perf**: reconciliation, keys, `React.memo`, Context perf, Suspense, error boundaries, `useTransition`. *Hands-on*: profile sample app, fix 3 unnecessary re-renders. → Section 4.
- **Day 6 — DSA + mock**: 5 LeetCode mediums (arrays, hashmap, two-pointer) + 1 mock JS/React interview (45 min, recorded).
- **Day 7 — Rest**.

### Week 2 — RN core + new architecture + debugging
- **Day 8 — RN architecture basics**: threading, old bridge, Metro, Hermes vs JSC, project structure. *Hands-on*: fresh RN app, toggle Hermes, measure startup. → Section 5.
- **Day 9 — New Architecture**: JSI, Fabric, TurboModules, Codegen, migration. *Hands-on*: enable new arch, write a tiny TurboModule for battery level. → Section 5.
- **Day 10 — Hermes + bundle + cold start**: bytecode, `inlineRequires`, lazy loading, cold start anatomy. *Hands-on*: profile cold start, reduce 30%. → Section 6.
- **Day 11 — Performance: lists/animations/images**: FlatList → FlashList, Reanimated 3, expo-image. *Hands-on*: 1000-row feed FlatList → FlashList, measure FPS gain. → Section 7.
- **Day 12 — Native modules**: Swift + Kotlin authoring, threading, return patterns. *Hands-on*: write Swift + Kotlin battery module emitting charging state. → Section 8.
- **Day 13 — Debugging deep day**: RN DevTools, Hermes Inspector, Reactotron, Instruments, Android Profiler, Charles, symbolication, ANR. *Hands-on*: plant a memory leak (uncleaned listener), find via Allocations + Android Profiler, fix; symbolicate a crash. → Section 9.
- **Day 14 — DSA + mock**: 5 LeetCode mediums (linked list, tree, BFS/DFS) + 1 mock RN deep-dive (45 min).

### Week 3 — State, navigation, offline, testing, CI/CD, security
- **Day 15 — State management**: 3-bucket model, RTK, Zustand, React Query, optimistic updates. *Hands-on*: screen using all three. → Section 10.
- **Day 16 — Navigation + deep links**: Native Stack vs JS Stack, Universal Links, App Links, Branch, auth gating, typed params. *Hands-on*: typed RN project with auth gate + deep links. → Section 11.
- **Day 17 — Offline-first**: MMKV, WatermelonDB, outbox pattern, sync, conflicts. *Hands-on*: offline todo with MMKV + outbox + sync on reconnect. → Section 14.
- **Day 18 — Testing**: Jest, RNTL, Detox, Maestro, mocking native modules. *Hands-on*: 5 RNTL tests + 1 Maestro flow. → Section 18.
- **Day 19 — CI/CD + release**: Fastlane, GitHub Actions, EAS Build/Update, code signing, OTA policy. *Hands-on*: GH Actions for sample app: lint → test → EAS build preview. → Section 19.
- **Day 20 — Mobile security**: Keychain/Keystore, OAuth PKCE, single-flight refresh, cert pinning, MASVS L2, Privacy Manifest, biometric gating. *Hands-on*: secure token store wrapper. → Section 16.
- **Day 21 — DSA + mock**: 5 LeetCode mediums (DP-easy, sliding window) + 1 mixed mock.

### Week 4 — System design, behavioral, DSA, conversion
- **Day 22 — Mobile system design (basics)**: framework, layering, modularization, monorepo. *Practice*: Insta feed, WhatsApp messaging. → Section 21.
- **Day 23 — Mobile system design (fintech)**: Zerodha order placement, neobank account, payments. *Hands-on*: 1 written design doc. → Section 21.
- **Day 24 — DSA focused day**: 8 LeetCode mediums covering all patterns + LRU cache from scratch. → Section 22.
- **Day 25 — Behavioral + STAR**: prepare 10 stories in 45-sec + 3-min versions. Record. → Section 23 + Appendix E.
- **Day 26 — Resume, LinkedIn, applications**: rewrite resume per Appendix C, update LinkedIn per Appendix D, set Open-to-Work, apply to **Tier S top 8** with referrals, send 10 referral DMs.
- **Day 27 — Apply Tier A + recruiter screen prep**: apply to **Tier A 6 cos**, prep 5 recruiter answers cold (TMAY, why looking, notice, expected CTC, current CTC deflection).
- **Day 28 — Full mock day**: recruiter (15 min) → DSA (1 medium) → RN deep dive → System design (45 min) → Behavioral (5 STAR) → Retro.
- **Day 29 — Weak-area repair**: pick top 3 gaps from Day 28, re-read those sections, rehearse 5x. Apply to **Tier A− globals**.
- **Day 30 — Cheatsheet review + go live**: skim Section 25, refresh top-50 Qs, rest. **Day 31 onwards: interview season.**

### Topic-by-topic question count
| Topic | Qs | Hands-on |
|---|---|---|
| JS core + async | 25 | 5 puzzles, `pLimit`, custom `Promise.all` |
| TypeScript | 15 | Typed `useFetch`, navigation types |
| React + hooks | 20 | 5 custom hooks, profiler fix |
| RN architecture + new arch | 25 | TurboModule for battery |
| Hermes + perf + lists | 20 | Cold start −30%, FlashList migration |
| Native modules | 15 | Swift + Kotlin battery module |
| Debugging | 20 | Memory leak find+fix, sourcemap symbolication |
| State management | 15 | RTK + Zustand + React Query screen |
| Navigation + deep links | 12 | Typed RN with auth gate + deep links |
| Offline-first | 12 | MMKV + outbox + sync demo |
| Testing | 12 | RNTL + Maestro suite |
| CI/CD | 10 | GH Actions + EAS pipeline |
| Security | 15 | Secure token store wrapper |
| System design | 5 problems | 1 written design doc |
| Behavioral | 10 STAR | Recorded 45s + 3min versions |
| DSA | 30 mediums | LRU cache, common patterns |
| **Total** | **~250** | **15 artifacts** |

### Rules to not break
1. **Speak answers aloud** every day. Reading is not preparing.
2. **Build the hands-on artifact** for each day. Have a repo to show.
3. **Quote numbers** from your own work.
4. **Don't disclose your current number** to recruiters early. Anchor on the role-level band you researched.
5. **Run 3+ processes in parallel** in week 5.
6. **Sleep 7+ hrs**.

### If you fall behind
- Skip DSA day, not a topic day.
- Always do the hands-on, even if you cut theory short.
- Re-do mock days if scores are low.

### After Day 30
- Week 5: interview-driven prep. Each interview tells you the next gap.
- Week 6: offer optimization (see Section 24 negotiation).
- Target: **first offer by Day 45**; sign once you've reached your researched role-level band with at least one competing offer for leverage.

---

