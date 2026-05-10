# S26 — AI-Assisted Development for RN

> Prompt patterns · debugging with AI · trust & verify · hallucination danger zones · codemods

In 2026, AI is embedded in every senior workflow. Interviewers expect you to use it well — not blindly. This section covers patterns, pitfalls, and verification.

## Topics in this section

- [Q1. Prompt patterns for RN code generation](#q1-prompt-patterns-for-rn-code-generation)
- [Q2. AI for debugging — "why did this break?"](#q2-ai-for-debugging--why-did-this-break)
- [Q3. AI-generated tests — trust and verify](#q3-ai-generated-tests--trust-and-verify)
- [Q4. AI hallucinations — RN danger zones](#q4-ai-hallucinations--rn-danger-zones)
- [Q5. AI for migration codemods (RN upgrades, deprecations)](#q5-ai-for-migration-codemods-rn-upgrades-deprecations)

---

## Q1. Prompt patterns for RN code generation

### Difficulty
Intermediate

### Interview Frequency
Common.

### Prerequisites
RN basics; familiarity with Copilot / Cursor / Claude.

### TL;DR
Effective AI prompts include: **target framework versions** (RN 0.74, React 19), **constraints** (TS strict, no any), **non-functional requirements** (a11y, perf), **fixture inputs/outputs**, and **what NOT to do**. Iterate via diff-style asks.

### 30-Second Interview Answer
"My prompts always specify versions (RN 0.74+, React 19), constraints (TypeScript strict, no `any`), non-functional requirements (accessibility roles, FlashList for lists), and an explicit 'do not' list (no ScrollView+map, no Redux). I provide a sample input/output. Iteration is diff-based: 'change X to Y; keep everything else.' Generated code goes through the same review as human code."

### 2-Minute Practical Answer
Anatomy of a good prompt:
```
Context:
- RN 0.74, React 19, TS strict, Expo SDK 50, Expo Router.
- We use TanStack Query for server state, Zustand for client state.
- Theme tokens in src/theme.

Task:
Build a `<Feed/>` component that:
- Renders an infinite list of posts via TanStack Query.
- Uses FlashList (estimatedItemSize 280).
- Handles pull-to-refresh, error retry, empty state.
- All Pressables have accessibilityRole + accessibilityLabel.

Constraints:
- No inline styles; use StyleSheet or theme tokens.
- No useEffect for data fetching (use TanStack Query).
- Memoize renderItem.
- No `any` types.

Sample API response shape:
{ items: [{ id, author, body, createdAt }], nextCursor: string | null }

Do NOT:
- Use ScrollView with .map.
- Use AsyncStorage; we use MMKV.
- Add Redux.
```

Iteration:
- Run + read.
- "The renderItem isn't memoized. Add useCallback. Keep everything else."
- "Add Reanimated entry animation for new items, respecting useReducedMotion."

### 5-Minute Architecture Answer
AI is a junior pair programmer with photographic memory and zero context. Your job is **context engineering**:
1. **Repo context** — share file conventions, theme, libraries used.
2. **Quality bar** — TS strict, lint rules, a11y requirements.
3. **Examples** — 1–2 reference files in the same style.
4. **Negative examples** — what to avoid.
5. **Acceptance criteria** — how you'll verify.

For RN specifically, the **danger of vague prompts** is high:
- "Make it accessible" → AI adds nothing.
- "Make it performant" → may add wrong optimizations.
- "Use modern React" → may use outdated patterns.

Tools:
- **GitHub Copilot Chat** — ambient, fast.
- **Cursor / Codeium** — file-aware, multi-file edits.
- **Claude / GPT** — long context, design docs + code.
- **Aider / Continue** — terminal-based, repo-wide.

For senior+ workflow:
- AI for boilerplate scaffolding.
- AI for test stubs.
- AI for codemod generation.
- Human judgment for architecture, perf, a11y.

### The "Why"
AI literacy is now table-stakes. Bad prompts waste time + ship bugs.

### Mental Model
Prompt = **executable spec** for the AI. Vague spec → vague output.

### Internal Working (2026 Context)
- Copilot Chat understands open editors as context.
- Cursor allows `@file` and `@symbol` references.
- Claude Sonnet has 200k context; load multiple files.

### Modern Implementation (Code)
Saved prompt template (e.g., `prompts/component.md`):

```md
# RN Component Prompt

[paste this with task-specific bits]

## Stack
- RN 0.74+, React 19, TS strict.
- Expo Router, TanStack Query, Zustand.
- expo-image, FlashList, Reanimated 3.

## Quality bar
- A11y on every Pressable.
- FlashList for any list > 20 items.
- No `any`; prefer Zod for boundary validation.

## Style
- Matches src/components/ existing patterns.
- Theme tokens from src/theme.

## Task
{TASK}

## Inputs
{INPUTS}

## Acceptance
{HOW_VERIFY}

## Don't
{NEGATIVES}
```

### Comparison

| Tool | Strength |
|---|---|
| Copilot | Fast inline |
| Cursor | Multi-file edits |
| Claude | Long context, design docs |
| Aider | Repo-wide refactors |

### Production Usage
- Save prompt templates per project.
- AI for first 60–80% of scaffolding; human for last 20–40%.

### Hands-On Exercise
Take a real ticket; write a prompt; generate; review; refine prompt for next time.

### Common Mistakes
- "Build a component" with no constraints.
- Trusting first output without review.
- Pasting AI code into prod without lint/test.

### Production Red Flags
- AI-generated `any` everywhere.
- Inline styles ignoring theme.
- Wrong library (Redux when team uses Zustand).

### Performance & Metrics
- Time saved per ticket.
- AI-introduced bug rate.
- Prompt reuse rate.

### Decision Framework
- Repetitive scaffolding → AI.
- Architecture decisions → human.
- Performance-critical → human review of AI output.

### Senior-Level Insight
"Prompt engineering is a real skill. Engineers who prompt well ship 2–3× faster on commodity work; engineers who don't ship subtly broken code."

### Real-World Scenario
Engineer prompted "build login form"; AI used class component, AsyncStorage, no validation. Re-prompted with full context; second output was production-ready.

### Production Failure Story
PR merged with AI-generated `useEffect` data fetching that fired on every render; production OOM.
**Fix:** Mandatory PR template asks "is this AI-generated? Reviewed for correctness?"

### Debugging Checklist
1. Prompt include version, constraints, examples?
2. Output reviewed for hallucinated APIs?
3. Tests added?
4. Lint + type-check pass?

### Advanced / Internal Knowledge
- Project-level rules files (`.cursorrules`, `.github/copilot-instructions.md`).
- Few-shot prompting with 2–3 in-repo examples.
- Constrained generation via JSON schema (for SDUI gen).

### 2026 AI Tip
Save prompts that work. They're as valuable as code.

### Related Topics
Q4, Q5.

### Interview Follow-Up Questions
- "Show me a prompt you've reused."
- "How do you stop the AI from hallucinating APIs?"
- "When do you not use AI?"

### Memory Hook
**"Context, constraints, examples, anti-examples. Iterate as diff."**

### Revision Notes
> Prompts include version+constraints+examples+anti-examples; save templates; AI for scaffolding (60–80%), human for last mile; review like human PRs; lint + test always.

---

## Q2. AI for debugging — "why did this break?"

### Difficulty
Intermediate

### Interview Frequency
Common.

### Prerequisites
Q1, debugging basics.

### TL;DR
Feed AI: stack trace, recent diff, relevant file, error reproduction. Ask for hypotheses (not just fixes). Verify each hypothesis with the actual code path. AI accelerates triage; human confirms.

### 30-Second Interview Answer
"For a bug, I give the AI: the stack trace, the recent diff, the relevant file, and steps to reproduce. I ask for 3 hypotheses, ranked by likelihood, with reasoning. Then I verify each in the code. AI doesn't replace bisecting or reading the source — it accelerates hypothesis generation."

### 2-Minute Practical Answer
Effective debug prompt:
```
A user-reported crash:
- App: RN 0.74, iOS 17.4 only.
- Error: 'undefined is not an object (evaluating x.profile.id)'
- Stack: [paste]
- Recent diff (PR #1234): [paste]
- File: [paste]

Hypothesize 3 root causes ranked by likelihood. For each:
- Why it could cause this error.
- How to verify.
- Suggested fix.
```

AI returns hypotheses; you investigate top one first.

Workflow integration:
- Sentry has "Sentry AI" that drafts root cause hypotheses.
- Cursor / Copilot can read stack traces and suggest patches.
- Don't let AI write the fix without you reading it.

### 5-Minute Architecture Answer
Debugging is hypothesis-driven; AI is good at hypothesis generation:
- **Pattern recognition** — AI has seen many "undefined is not an object" patterns.
- **Code context** — given the file + diff, AI can spot likely culprits.
- **Limitations** — AI can't run your code; can't see runtime state; can't reproduce.

The 4-step AI debug loop:
1. **Gather** — stack, diff, repro, relevant code.
2. **Hypothesize** — AI generates 3–5 candidates.
3. **Verify** — you check each in code or via reproduction.
4. **Fix + test** — write test that exposes the bug; fix; verify test passes.

Common AI debug failures:
- AI confidently invents a bug path that doesn't exist.
- AI misses subtle async / race condition.
- AI suggests fix that "looks right" but masks symptom.

For 2026:
- AI integrated into Sentry, Datadog, Bugsnag for auto-RCA suggestions.
- "AI-assisted bisect" — describes commits between known-good and known-bad.

### The "Why"
Debugging is the #1 time sink for senior engineers; AI as accelerator changes the cost/benefit.

### Mental Model
AI = brainstorm partner; you = verifier + fixer.

### Internal Working (2026 Context)
- Sentry AI uses your stack traces + Slack messages for context.
- Cursor reads imports + types for accurate suggestions.

### Modern Implementation (Code)
Triage prompt:

```
Context:
- RN 0.74, Expo 50, iOS 17.4.
- Crash rate spiked from 0.1% to 1.8% after PR #1234 (yesterday).
- Sentry top issue: Cannot read property 'id' of undefined; src/screens/Profile.tsx:42.

Files:
- [Profile.tsx 60 lines]
- [PR diff: changed useUser hook]

Task:
1. List 3 hypotheses for the regression, ranked by likelihood.
2. For each, cite the line(s) of evidence and a quick verification.
3. Recommend a minimal patch for the most likely.
```

### Comparison

| Approach | Speed | Reliability |
|---|---|---|
| Pure manual | Slow | High (you're 100% in code) |
| AI-assisted | Fast | Medium (verify always) |
| AI-only | Fastest | Risky (false fixes) |

### Production Usage
- Sentry AI suggestions in alert flow.
- Engineers paste stack into Cursor / Claude for first hypothesis.
- AI-suggested fixes still require PR + review.

### Hands-On Exercise
Take a recent bug; redo investigation with AI; compare time + accuracy.

### Common Mistakes
- Trusting first AI hypothesis.
- Not feeding the diff (AI guesses).
- Letting AI write fix without reading.

### Production Red Flags
- "AI says it's fixed" without test added.
- Bug reappears because root cause unaddressed.

### Performance & Metrics
- Mean time to first hypothesis (MTTH).
- Mean time to verified RCA.

### Decision Framework
- Familiar bug → manual likely faster.
- Unfamiliar codebase → AI helps orient.
- Critical incident → AI for hypotheses; human for decision.

### Senior-Level Insight
"AI shortens triage; it doesn't replace bisecting or reading the source. The good engineer uses both."

### Real-World Scenario
Crash spike at midnight; engineer pasted stack + diff into Claude; got correct hypothesis in 2 minutes; fixed in 15. Without AI, would have taken 1+ hour.

### Production Failure Story
Engineer applied AI-suggested fix; symptom went away; root cause was deeper (race condition); bug reappeared a week later worse.
**Lesson:** Verify with a test that exposes the bug.

### Debugging Checklist
1. Stack trace + diff fed to AI?
2. Multiple hypotheses requested?
3. Hypothesis verified in code?
4. Test added before fix?

### Advanced / Internal Knowledge
- Sentry's "Issue Owners" + AI suggestions auto-tag.
- LangChain agents that read codebase + bisect (experimental).
- AI-assisted git bisect.

### 2026 AI Tip
Always ask for "3 hypotheses ranked," not "the answer." Forces variety.

### Related Topics
Q1, Q4.

### Interview Follow-Up Questions
- "How do you avoid AI-suggested fake fixes?"
- "Show me a debug prompt you've used."
- "When does AI hurt more than help?"

### Memory Hook
**"Stack + diff in. 3 hypotheses out. Verify each."**

### Revision Notes
> AI debug = hypothesis acceleration; feed stack+diff+code+repro; ask for 3 ranked hypotheses; verify each in code; add test before fix; never trust first answer.

---

## Q3. AI-generated tests — trust and verify

### Difficulty
Intermediate

### Interview Frequency
Common.

### Prerequisites
Q1, S17 (testing).

### TL;DR
AI writes good test stubs but bad assertions. Use AI for: scaffolding describe/it, generating edge case lists, mocking boilerplate. Always **read assertions** carefully — they often test the wrong invariant.

### 30-Second Interview Answer
"I use AI for test scaffolding (describe/it skeletons, mock setup, edge case lists) but always review assertions carefully. AI tends to test what code does, not what code should do — so it can encode bugs as 'expected' behavior. I verify by mutation testing: change the implementation; do the AI-generated tests fail?"

### 2-Minute Practical Answer
What AI does well:
- Describe/it block scaffolding.
- Mock setup boilerplate.
- Edge case enumeration ("what could break here?").
- Snapshot test stubs.

What AI does poorly:
- Asserting the **right** behavior (often asserts the current behavior, even if buggy).
- Async test ordering.
- Cleanup (open handles, fake timers).
- Realistic test data.

Verification techniques:
- **Mutation testing** — flip a `>` to `<`; do tests still pass? If yes, tests are weak.
- **Manual review** — read each assertion; ask "does this confirm the requirement or just the implementation?"
- **Code coverage** — necessary not sufficient.

Prompt pattern:
```
Generate Vitest tests for src/auth/refreshToken.ts.
Cover:
- Happy path: returns new token.
- Expired refresh token: throws specific error.
- Network error: retries 3 times then throws.
- Concurrent calls: dedupe (only one network request).

Use:
- Vitest + @testing-library/react-native.
- Mock fetch via msw.
- No snapshot tests for logic; only describe/it.
```

### 5-Minute Architecture Answer
Test generation is one of AI's strongest use cases — and one of its most subtle pitfalls:
- **Strong**: AI knows test framework conventions, mock patterns.
- **Pitfall**: AI tests current behavior, not specified behavior. If your code has a bug, AI tests assume the bug is the contract.

The discipline:
1. Write the requirement.
2. AI generates tests from the requirement (not from the implementation).
3. Run tests; expect failures (TDD).
4. Implement; iterate until tests pass.
5. Mutation test to verify.

For 2026:
- Stryker for mutation testing on JS/TS.
- AI test generation tools (Diffblue, Tabnine Tests) emerging.
- Snapshot tests are anti-pattern in many cases (encode UI flakiness as spec).

Test pyramid revisited:
- Unit (lots, AI-good).
- Integration (few, AI-medium).
- E2E (very few, AI-poor — needs real app context).

### The "Why"
Tests catch regressions; weak tests catch nothing.

### Mental Model
AI tests the code; human tests the requirement. Combine both.

### Internal Working (2026 Context)
- Vitest 1.x with workspace support.
- Jest still common; Vitest faster for new projects.
- Maestro for E2E in RN; AI weak there.

### Modern Implementation (Code)
Sample human-reviewed AI test:

```ts
// AI generated; human reviewed for assertions
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { refreshToken } from './refreshToken';
import { server } from '../mocks/server';
import { http, HttpResponse } from 'msw';

describe('refreshToken', () => {
  beforeEach(() => server.resetHandlers());

  it('returns new token on success', async () => {
    server.use(http.post('/refresh', () => HttpResponse.json({ token: 'new' })));
    const token = await refreshToken('old');
    expect(token).toBe('new'); // human-verified: matches contract
  });

  it('throws TokenExpiredError on 401', async () => {
    server.use(http.post('/refresh', () => HttpResponse.json({}, { status: 401 })));
    await expect(refreshToken('old')).rejects.toThrow(TokenExpiredError); // human-verified specific class
  });

  it('retries 3 times then throws on network error', async () => {
    let calls = 0;
    server.use(http.post('/refresh', () => { calls++; return HttpResponse.error(); }));
    await expect(refreshToken('old')).rejects.toThrow();
    expect(calls).toBe(3); // human-verified: matches retry policy
  });

  it('dedupes concurrent calls', async () => {
    let calls = 0;
    server.use(http.post('/refresh', async () => { calls++; await new Promise(r => setTimeout(r, 50)); return HttpResponse.json({ token: 't' }); }));
    await Promise.all([refreshToken('old'), refreshToken('old')]);
    expect(calls).toBe(1); // human-verified: matches dedupe spec
  });
});
```

### Comparison

| Test layer | AI fit |
|---|---|
| Unit | High |
| Integration | Medium |
| E2E | Low |
| Snapshot | Low (anti-pattern often) |

### Production Usage
- AI generates test stubs in PR; engineer reviews assertions.
- Mutation testing in CI for critical modules.

### Hands-On Exercise
Take a function; have AI generate tests; mutation-test; refine.

### Common Mistakes
- Merging AI tests without reading assertions.
- Snapshot tests encoded as spec.
- Async tests with no `await`.

### Production Red Flags
- 100% coverage but bugs ship.
- Snapshot churn.
- Tests change every PR.

### Performance & Metrics
- Mutation score (% of mutations caught).
- Test runtime.
- Real-bug catch rate post-merge.

### Decision Framework
- Pure logic → AI tests great.
- React UI → AI mid; verify.
- E2E → human + Maestro.

### Senior-Level Insight
"AI tests are like code reviews: trust them less when you understand the domain less."

### Real-World Scenario
AI-generated tests for a billing function asserted current (buggy) behavior. Bug shipped; tests passed. Mutation testing flagged it.

### Production Failure Story
Team had 90% test coverage but production crashes increased.
**Root cause:** Snapshot tests + AI-generated assertions tested implementation, not behavior.
**Fix:** Mutation testing + manual assertion review.

### Debugging Checklist
1. Assertions test requirement, not impl?
2. Async tests `await`ed?
3. Mocks reset between tests?
4. Mutation score > 70%?

### Advanced / Internal Knowledge
- Property-based testing (fast-check) catches what example-based misses.
- Contract tests for API boundaries.
- Visual regression for critical screens (Chromatic, Percy).

### 2026 AI Tip
Generate tests from spec, not from impl. Paste the requirement, not the function.

### Related Topics
Q1, S17.

### Interview Follow-Up Questions
- "How do you verify AI tests aren't tautological?"
- "When do you use snapshot tests?"
- "What's mutation testing?"

### Memory Hook
**"AI tests the code. You test the requirement. Mutation tests verify."**

### Revision Notes
> AI good for test scaffolding/edge case lists; bad for assertions; mutation-test to verify; generate from requirement not impl; review every assertion; snapshots sparingly.

---

## Q4. AI hallucinations — RN danger zones

### Difficulty
Advanced

### Interview Frequency
Common.

### Prerequisites
Q1.

### TL;DR
AI hallucinates: outdated APIs (TurboModule signatures), invented props, wrong package names, deprecated patterns (componentWillMount), misremembered Reanimated v2 vs v3 syntax. Verify against current docs and types.

### 30-Second Interview Answer
"AI's training cutoff and library churn cause RN-specific hallucinations: invented props on FlashList, wrong Reanimated syntax (v1 vs v3), deprecated lifecycle methods, fake Expo modules. Mitigation: check official docs, run TypeScript strict, run before merging. Anything platform-specific (TurboModule, native config) deserves extra scrutiny."

### 2-Minute Practical Answer
Common hallucination patterns:

| Hallucination | Example |
|---|---|
| Invented props | `<FlashList prefetchEnabled />` (doesn't exist) |
| Wrong API version | `Animated.event` for Reanimated 3 (it's v1 syntax) |
| Deprecated patterns | `componentWillMount`, `UNSAFE_componentWillReceiveProps` |
| Fake packages | `react-native-easy-otp-input` (made up) |
| Wrong native config | `extra.googleMapsApiKey` placement in app.json |
| Old hook names | `useNativeDriver` as a hook |

Verification:
- TS strict catches invented props on typed components.
- ESLint with deprecated-api plugin catches old lifecycles.
- `pnpm why <pkg>` confirms package exists in lockfile.
- Read the README before installing AI-suggested packages.

For RN 2026 specifically:
- Bridgeless mode introduced new APIs; AI often uses bridge-era ones.
- Fabric replaced Paper renderer; old measure / setNativeProps APIs deprecated.
- Reanimated 3 worklet syntax very different from v1/v2.

### 5-Minute Architecture Answer
Why RN is especially prone to AI hallucinations:
- **Fast-evolving ecosystem** — RN, Reanimated, Expo all release frequently.
- **Multiple coexisting versions** in training data (v1, v2, v3 of Reanimated).
- **Platform-specific code** (iOS/Android/web) confuses scope.
- **Naming overlap** — `react-navigation` v5/v6/v7 have different APIs.

Mitigation strategies:
- **Pin AI to versions in prompt** — "Use Reanimated 3 syntax (`useSharedValue`, worklets via 'worklet' directive)."
- **TS strict** — invented props caught immediately.
- **Lint deprecated** — `eslint-plugin-react-native` catches old patterns.
- **Run + see** — never merge without running.
- **Verify package exists** — search npm before installing.

The cost of unchecked hallucinations:
- Invented packages → security risk if attacker publishes them later.
- Deprecated APIs → app compiles but breaks at runtime.
- Wrong reanimated syntax → silent bugs (animation runs on JS thread instead of UI).

For 2026 workflow:
- IDE auto-completion grounds AI suggestions in real types.
- Cursor / Copilot have improved at type-aware suggestions but still hallucinate.
- "AI then human" is the only safe pipeline.

### The "Why"
Wasted time + production bugs from blindly trusting AI.

### Mental Model
AI's training data is a snapshot; the world moved on. Verify everything against current sources.

### Internal Working (2026 Context)
- Most AIs trained through 2024–early 2025; RN 0.74+ partial.
- Cursor / Copilot pull live docs in some cases; not all.

### Modern Implementation (Code)
Verification workflow:

```bash
# After AI generates code:
pnpm tsc --noEmit          # TS strict catches invented APIs
pnpm lint                  # deprecated lifecycle catches
pnpm why <suggested-pkg>   # confirm package in registry
pnpm test                  # behavior verification
```

Prompt that reduces hallucinations:

```
Use ONLY these libraries (versions in package.json):
- react-native@0.74
- react@19
- @shopify/flash-list@1.7
- react-native-reanimated@3.10 (worklet directive syntax)
- @tanstack/react-query@5

If a feature requires a different library, ask before assuming it exists.
```

### Comparison

| Hallucination type | Detection |
|---|---|
| Invented prop | TS strict |
| Deprecated API | ESLint plugin |
| Fake package | npm registry check |
| Wrong version syntax | Run + see |
| Misnamed hook | TS strict |

### Production Usage
- TS strict + ESLint + lockfile verification in PR pipeline.
- AI use noted in PR description.

### Hands-On Exercise
Generate something with AI; intentionally don't review; run TS + lint; count caught issues.

### Common Mistakes
- Installing AI-suggested package without verifying.
- Disabling TS strict to make AI code compile.
- Trusting AI for native config (Info.plist, AndroidManifest).

### Production Red Flags
- New deps without lockfile verification.
- TS errors disabled to ship.
- Mixed Reanimated v1/v3 syntax in same file.

### Performance & Metrics
- AI-introduced bug rate.
- TS error frequency in AI-generated code.

### Decision Framework
- Stable, well-documented API → AI safe.
- Recently changed API → verify against docs.
- Native config → manual.

### Senior-Level Insight
"AI is a confident liar. Treat its output like StackOverflow — useful, often wrong, always verify."

### Real-World Scenario
AI suggested `react-native-otp-textinput` for OTP. Engineer installed; package was abandoned + had a CVE. Switched to verified library.

### Production Failure Story
AI generated Reanimated v1 `Animated.event` syntax in a v3 codebase; animations silently fell back to JS thread; FPS tanked.
**Fix:** Lint rule banning v1 imports; mandatory test on real device.

### Debugging Checklist
1. TS strict pass?
2. Lint pass?
3. Suggested packages exist + maintained?
4. Native config reviewed manually?
5. API matches current major version?

### Advanced / Internal Knowledge
- Supply chain attacks via typosquatted packages (rare but real).
- Lockfile-only installs (`--frozen-lockfile`) catch surprises.
- IDE plugins that surface deprecation.

### 2026 AI Tip
Pin versions in prompt; ask AI to flag uncertainties.

### Related Topics
Q1, Q3.

### Interview Follow-Up Questions
- "How do you stop hallucinations?"
- "Show a hallucination you caught."
- "What's risky to delegate to AI?"

### Memory Hook
**"AI confident, often wrong. TS strict, lint, lockfile, run."**

### Revision Notes
> AI hallucinates RN APIs, libraries, syntax versions; mitigate via version-pinned prompts, TS strict, ESLint deprecated, npm verification, real-device run; native config + Reanimated v3 deserve extra scrutiny.

---

## Q5. AI for migration codemods (RN upgrades, deprecations)

### Difficulty
Advanced

### Interview Frequency
Common at platform/staff rounds.

### Prerequisites
Q1, Q4.

### TL;DR
For repetitive migrations (RN 0.69 → 0.74, deprecated → new APIs), AI generates jscodeshift / ts-morph codemods. Test on a sample first; run with diff review; verify with TS + tests.

### 30-Second Interview Answer
"For repetitive migrations across hundreds of files, I write codemods. AI generates the jscodeshift or ts-morph script from a few before/after examples. I run it on a sample dir first; verify the diff; expand to repo. TS + tests catch regressions. Rollback per-file via git if needed."

### 2-Minute Practical Answer
Codemod use cases in RN migrations:
- `componentWillMount` → `useEffect` / `componentDidMount`.
- Reanimated v1 `Animated.event` → v3 `Gesture.Pan().onUpdate`.
- `AsyncStorage` → `MMKV`.
- React Navigation v5 → v6.
- Class components → function components.
- Redux → TanStack Query (partial — needs human).

Workflow:
1. Identify pattern with 2–3 examples.
2. Prompt AI: "Write a jscodeshift codemod that replaces X with Y. Here are examples."
3. Run on a single file; verify diff.
4. Expand to a directory; verify.
5. Run on full repo; review diff in PR.
6. TS + tests as final gate.

Tools:
- **jscodeshift** — venerable; works on AST.
- **ts-morph** — TypeScript-aware; better for typed transforms.
- **Codemod CLI** (from Codemod.com) — newer; AI-assisted.

### 5-Minute Architecture Answer
Migrations are where AI shines and engineers underuse it:
- Manual migration of 500 files = days; codemod = hours.
- AI generation of the codemod itself = minutes.

Codemod structure (jscodeshift):
```ts
export default function transformer(file, api) {
  const j = api.jscodeshift;
  const root = j(file.source);
  root.find(j.CallExpression, { callee: { name: 'oldFn' } })
      .forEach(p => { p.node.callee.name = 'newFn'; });
  return root.toSource();
}
```

Generation prompt:
```
Write a jscodeshift transformer that:
- Finds all `componentWillMount` lifecycle methods in class components.
- Renames them to `componentDidMount` (acceptable in this app).

Examples (before/after):
[paste 2 examples]
```

Hardening:
- Run on `--dry` first.
- Process 10 files; spot-check.
- Run on a directory; spot-check.
- TS + tests.
- Per-PR scope (avoid mega-PRs).

For 2026:
- AI tools like Codemod.com host AI-assisted codemod generation + review.
- Continue / Cursor can generate + apply codemods directly.

### The "Why"
Repetitive transforms × hundreds of files = perfect AI use case.

### Mental Model
Codemod = automated diff over the codebase, generated by AI from before/after examples.

### Internal Working (2026 Context)
- jscodeshift / ts-morph mature.
- Codemod.com offers AI + curated codemods for common migrations.

### Modern Implementation (Code)
ts-morph example (typed):

```ts
import { Project } from 'ts-morph';
const project = new Project({ tsConfigFilePath: 'tsconfig.json' });
const sources = project.getSourceFiles('src/**/*.tsx');
for (const file of sources) {
  file.getDescendantsOfKind(SyntaxKind.CallExpression).forEach(call => {
    const expr = call.getExpression();
    if (expr.getText() === 'AsyncStorage.getItem') {
      expr.replaceWithText('storage.getString');
    }
  });
  file.saveSync();
}
```

### Comparison

| Tool | Strength |
|---|---|
| jscodeshift | Battle-tested, large ecosystem |
| ts-morph | Type-aware |
| Codemod.com | AI + curated catalog |
| Manual | Smallest scope |

### Production Usage
- React Native upgrade helper uses codemods internally.
- Large monorepos (Meta, Airbnb) maintain codemod registries.

### Hands-On Exercise
Find a repetitive migration; have AI generate a codemod; test; apply.

### Common Mistakes
- Running codemod on full repo immediately (mega-PR).
- No type check after.
- Codemod handles 90% but breaks edge cases.

### Production Red Flags
- 1000-file PR with no review.
- Tests skipped.
- "Codemod handled it" without diff review.

### Performance & Metrics
- Files migrated per hour.
- Post-migration bug rate.

### Decision Framework
- Repeating pattern across many files → codemod.
- One-off transform → manual.
- Semantic change (not syntactic) → human.

### Senior-Level Insight
"Codemods are how staff engineers move mountains. AI lowers the cost of writing them by 10×."

### Real-World Scenario
RN 0.69 → 0.74 upgrade affected 500+ files. AI-generated codemods handled 80%; rest manual. Cycle: 1 day vs estimated 2 weeks.

### Production Failure Story
Codemod converted `useEffect` deps in a way that introduced an infinite loop in 3 files; merged without test.
**Fix:** Mandatory CI run before codemod PR merges.

### Debugging Checklist
1. Tested on sample first?
2. Diff reviewed?
3. TS + tests pass?
4. PR scope reasonable?

### Advanced / Internal Knowledge
- AST manipulation pitfalls (TypeScript types, comments preservation).
- Codemod versioning + rollback strategy.
- Continuous codemod CI (catches new instances of old patterns).

### 2026 AI Tip
For complex codemods, generate iteratively: "Handle case X first; then add case Y; then Z."

### Related Topics
Q1, Q4, S20 (CI).

### Interview Follow-Up Questions
- "Have you written a codemod?"
- "How do you verify a 500-file migration?"
- "When does codemod fail you?"

### Memory Hook
**"Examples in. Codemod out. Diff review. TS + tests."**

### Revision Notes
> Codemods automate repetitive migrations; AI generates from before/after examples; jscodeshift / ts-morph; run on sample → directory → repo; TS + tests gate; PR scope manageable.

---

> Cross-refs: S01 (TS), S17 (testing), S20 (CI).
