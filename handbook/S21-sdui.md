# S21 — Server-Driven UI

> Schema design · validation & safety · backward compat · experimentation · performance

SDUI lets you ship UI at the speed of a backend deploy. This section dives deeper than S16-Q5 — into the production-grade patterns used by Airbnb, Lyft, Flipkart.

## Topics in this section

- [Q1. SDUI schema design — versioning, types, actions](#q1-sdui-schema-design--versioning-types-actions)
- [Q2. Validation and safety boundary (Zod, fallbacks)](#q2-validation-and-safety-boundary-zod-fallbacks)
- [Q3. Backward compatibility and rollout](#q3-backward-compatibility-and-rollout)
- [Q4. SDUI + experimentation (A/B, feature flags)](#q4-sdui--experimentation-ab-feature-flags)
- [Q5. SDUI performance — preloading, caching, virtualization](#q5-sdui-performance--preloading-caching-virtualization)

---

## Q1. SDUI schema design — versioning, types, actions

### Difficulty
Advanced

### Interview Frequency
Common at platform / e-com seniors+.

### Prerequisites
JSON schema, React composition.

### TL;DR
Schema = `{ schemaVersion, layout: Node, data?, actions? }`. Nodes are typed (`type: 'card' | 'list' | ...`). Actions are a discriminated union (`{ kind: 'navigate' | 'analytics' | ... }`). The schema **never names React components** — only abstract types.

### 30-Second Interview Answer
"My SDUI schema has a `schemaVersion`, a `layout` tree of typed nodes, and an `actions` map referenced by node IDs. Each node has `type`, `id`, `props`, `children`. Actions are discriminated unions like `{ kind: 'navigate', to }`. The client maintains a typed registry mapping `type → React component`. Server is decoupled from React."

### 2-Minute Practical Answer
```ts
type Action =
  | { kind: 'navigate'; to: string; params?: Record<string, unknown> }
  | { kind: 'analytics'; event: string; params?: Record<string, unknown> }
  | { kind: 'open-url'; url: string }
  | { kind: 'submit-form'; formId: string };

type Node = {
  type: string;
  id: string;
  props?: Record<string, unknown>;
  children?: Node[];
  onPress?: string; // action ID
  accessibility?: { label?: string; hint?: string; role?: string };
};

type Page = {
  schemaVersion: 1;
  layout: Node;
  data?: Record<string, unknown>;
  actions?: Record<string, Action>;
  meta?: { ttl?: number; experiment?: string };
};
```

Renderer:
```tsx
const REGISTRY: Record<string, React.ComponentType<NodeProps>> = {
  screen: ScreenView, list: ListView, card: CardView, image: ImageView,
  text: TextView, button: ButtonView, container: ContainerView,
};
```

Design principles:
- **Flat node types** — `card`, `list`, not `MyAppHomeFeedCardComponent`.
- **Composition via `children`** — let server build trees from primitives.
- **Actions referenced by ID** — keeps trees small, allows action reuse.
- **A11y in schema** — never lose accessibility on the wire.

### 5-Minute Architecture Answer
SDUI schemas span a spectrum:
1. **Layout DSL** — `{ type: 'flex', direction: 'row', children: [...] }`. Most flexible; complex client.
2. **Component-typed** — `{ type: 'card', props: { title, subtitle } }`. Most common; balanced.
3. **Page-typed** — `{ type: 'home-feed', sections: [...] }`. Tightly coupled; least flexible.

Choose component-typed for most cases. It separates **what** (component type) from **how** (component implementation).

Schema design discipline:
- **Stable IDs** — every node has a stable ID for analytics, animations, list-key tracking.
- **Versioned at multiple levels** — `schemaVersion` (top), per-component `version` (rare, for migrations).
- **Strict types via Zod or Protocol Buffers** — single source for client + server.
- **Action vocabulary curated** — adding action kinds requires both client + server changes; don't grow recklessly.
- **A11y first-class** — required fields in node schema, lint to enforce.

For 2026 patterns:
- **TypeScript generation from schema** — schema in `proto3` or JSON Schema → both client TS types and server stubs.
- **Server-side rendering of templates** — server merges data into a template; client just renders.
- **AI-generated layouts** — design tools emit SDUI JSON; client interprets.

Don't put in schema:
- Network logic (use actions).
- Conditional rendering based on client state (server should know state via API).
- Large data blobs (use `data` keyed map; nodes reference by key).

### The "Why"
- Updating UI without app review.
- Per-region / per-segment customization without code branches.
- A/B testing UI as data not code.

### Mental Model
Schema = **typed JSON instructions**; client = **interpreter** with fixed component vocabulary; server = **author** publishing instructions.

### Internal Working (2026 Context)
- React Compiler memoizes node renders well; SDUI fits naturally.
- Reanimated layout animations work on dynamic trees if keyed by node ID.
- `react-native-skia` for SDUI animations / charts.

### Modern Implementation (Code)

```ts
// Zod schema (single source)
import { z } from 'zod';

export const ActionSchema = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('navigate'), to: z.string(), params: z.record(z.unknown()).optional() }),
  z.object({ kind: z.literal('analytics'), event: z.string(), params: z.record(z.unknown()).optional() }),
  z.object({ kind: z.literal('open-url'), url: z.string().url() }),
]);

export const NodeSchema: z.ZodType<Node> = z.lazy(() => z.object({
  type: z.string(),
  id: z.string(),
  props: z.record(z.unknown()).optional(),
  children: z.array(NodeSchema).optional(),
  onPress: z.string().optional(),
  accessibility: z.object({
    label: z.string().optional(),
    hint: z.string().optional(),
    role: z.string().optional(),
  }).optional(),
}));

export const PageSchema = z.object({
  schemaVersion: z.literal(1),
  layout: NodeSchema,
  data: z.record(z.unknown()).optional(),
  actions: z.record(ActionSchema).optional(),
});

export type Page = z.infer<typeof PageSchema>;
```

### Comparison

| Schema style | Flexibility | Coupling |
|---|---|---|
| Layout DSL | High | Low |
| Component-typed | Medium-high | Medium |
| Page-typed | Low | High |

### Production Usage
- Home / category screens are SDUI in many e-com apps.
- Onboarding flows live in SDUI for fast iteration.
- Promo banners always SDUI.

### Hands-On Exercise
1. Define a 5-component schema.
2. Build a JSON page; render it.
3. Add Zod validation; corrupt JSON; observe error path.

### Common Mistakes
- React component names leaked into schema.
- Actions inlined per node (size explosion).
- Schema lacks `schemaVersion` field.
- A11y omitted.

### Production Red Flags
- "Just add a new field" without schema versioning discussion.
- Server returning full styling (CSS-in-JSON).
- Unknown types crashing the app.

### Performance & Metrics
- Schema parse time per page.
- Render time per page.
- Cache hit rate.

### Decision Framework
- Frequent UI changes / experiments → SDUI.
- Static, animation-heavy, accessibility-critical → native code.
- Mix → hybrid.

### Senior-Level Insight
"The biggest SDUI mistake is over-flexibility." A schema that can express any layout is a schema you can't reason about. Keep components opinionated.

### Real-World Scenario
**Symptom:** Engineers can't predict how a page renders without running it.
**Root cause:** Schema allowed too many primitives; designers used arbitrary nesting.
**Fix:** Restricted vocabulary to ~10 components; consistency improved.

### Production Failure Story
**Incident:** Adding a single new prop required a backend deploy + 6-week app cycle.
**Root cause:** Strict schema rejected unknown props.
**Fix:** Permissive props (TS `Record<string, unknown>`); client logs and ignores unknowns.

### Debugging Checklist
1. Schema versioned?
2. Actions discriminated union?
3. Components opinionated, not free-form?
4. A11y in schema?

### Advanced / Internal Knowledge
- Protocol Buffers offer better wire size + version-tolerant parsing.
- GraphQL fragments can serve as SDUI schemas (typed responses).
- AI-emitted SDUI requires extra validation (LLMs hallucinate types).

### 2026 AI Tip
LLMs can generate SDUI JSON for static screens. Always validate via Zod before rendering.

### Related Topics
Q2, Q3, S16-Q5.

### Interview Follow-Up Questions
- "Why no React component names in schema?"
- "How do actions stay decoupled from navigation library?"
- "What goes in `data` vs in `props`?"

### Memory Hook
**"Typed nodes. Discriminated actions. Versioned schema. No leaked components."**

### Revision Notes
> SDUI schema = `{ schemaVersion, layout: Node, data?, actions? }`; nodes typed by abstract names; actions discriminated unions; client registry maps types → components; never leak React names; A11y required.

---

## Q2. Validation and safety boundary (Zod, fallbacks)

### Difficulty
Intermediate

### Interview Frequency
Common.

### Prerequisites
S01-Q7 (Zod).

### TL;DR
Validate every SDUI response via Zod at the boundary. On failure, render a fallback (cached version, error state, or skeleton) — **never crash**. Log failures to Sentry with the schema path.

### 30-Second Interview Answer
"Every SDUI response goes through Zod's `safeParse`. Success → render. Failure → log to Sentry with the failing path, return a cached version if available, otherwise an error state. Unknown node types render a fallback component. The renderer never throws — bad schema is a backend bug, not a user-visible crash."

### 2-Minute Practical Answer
```ts
async function fetchPage(slug: string): Promise<Page> {
  const json = await api.get(`/pages/${slug}`);
  const result = PageSchema.safeParse(json);
  if (!result.success) {
    Sentry.captureException(new SchemaError(slug, result.error.issues));
    const cached = pageCache.get(slug);
    if (cached) return cached;
    return FALLBACK_PAGE(slug);
  }
  pageCache.set(slug, result.data);
  return result.data;
}
```

Renderer fallback:
```tsx
function Renderer({ node }: { node: Node }) {
  const Comp = REGISTRY[node.type];
  if (!Comp) {
    Sentry.addBreadcrumb({ category: 'sdui', message: `unknown type ${node.type}` });
    return <FallbackNode type={node.type} />;
  }
  return <ErrorBoundary fallback={<FallbackNode type={node.type} />}><Comp {...node.props}>{...}</Comp></ErrorBoundary>;
}
```

### 5-Minute Architecture Answer
SDUI is a contract; both sides break it occasionally. The client must be **defensive**:

Validation layers:
1. **Schema validation (Zod)** — structural correctness.
2. **Type registry check** — known component types.
3. **Per-component prop validation** — each component re-validates its props (defense in depth).
4. **Error boundary per node** — runtime errors don't propagate.
5. **Fallback hierarchy** — cached → empty state → error state.

Logging strategy:
- Schema failures → Sentry with full path + sample.
- Unknown types → breadcrumb + fallback.
- Component runtime errors → ErrorBoundary report.

This catches:
- Backend regressions before they reach 100% of users.
- Stale clients seeing new types.
- Corruption / partial responses.

For 2026:
- React Compiler doesn't break ErrorBoundaries.
- Sentry can group by SDUI path for fast triage.
- Client-side schema cache (e.g., last-good-version) survives network blips.

### The "Why"
- A typo in JSON shouldn't crash an entire screen.
- Backend deploys need to be safe; client should resist drift.
- Users on flaky networks see partial responses.

### Mental Model
SDUI client is **paranoid by design**: trust nothing, fall back gracefully, alert engineers.

### Internal Working (2026 Context)
- Zod 3.x performant for nested schemas.
- React 19 ErrorBoundary behavior unchanged but plays well with Suspense.
- Sentry's breadcrumb deduplication prevents spam.

### Modern Implementation (Code)

```tsx
class SDUIErrorBoundary extends React.Component<{ children: ReactNode; nodeType: string }> {
  state = { hasError: false };
  static getDerivedStateFromError() { return { hasError: true }; }
  componentDidCatch(error: Error) {
    Sentry.captureException(error, { tags: { sdui_node: this.props.nodeType } });
  }
  render() {
    if (this.state.hasError) return <FallbackNode type={this.props.nodeType} />;
    return this.props.children;
  }
}
```

### Comparison

| Failure | Action |
|---|---|
| Schema invalid | Sentry + cached fallback |
| Unknown type | Breadcrumb + Fallback |
| Component error | ErrorBoundary fallback |
| Network failure | Cached page or error state |

### Production Usage
- Every SDUI response wrapped in `safeParse`.
- Cache last-good-version in MMKV for offline / fallback.
- Sentry alert on schema failure rate > 0.1%.

### Hands-On Exercise
1. Add Zod validation to your SDUI fetch.
2. Mock a corrupt response; confirm cached fallback renders.
3. Add ErrorBoundary; throw in a node; confirm fallback.

### Common Mistakes
- `parse` (throws) instead of `safeParse` (returns result) at boundary.
- No fallback path — schema fail = white screen.
- Logging without context (path, slug).

### Production Red Flags
- White screens after backend deploy.
- Sentry showing many SDUI errors but no fallback rendering.
- No client-side cache for SDUI pages.

### Performance & Metrics
- Schema failure rate (alert > 0.1%).
- Fallback render rate.
- Validation time per page.

### Decision Framework
- Network response → Zod safeParse.
- Component render → ErrorBoundary.
- Unknown type → registry fallback.

### Senior-Level Insight
"Schema validation is your test environment in production." Every Zod failure is a real bug surfacing safely.

### Real-World Scenario
**Symptom:** Backend renamed a field; users saw blank screens.
**Investigation:** No Zod; renderer broke deep in tree.
**Fix:** Zod + cached fallback; reverted backend; users on cached version saw old UI.

### Production Failure Story
**Incident:** SDUI deploy crashed app for users on iOS 17.4 only.
**Root cause:** Component threw on a missing prop; no boundary.
**Fix:** ErrorBoundary per node + Sentry tags.

### Debugging Checklist
1. `safeParse` (not `parse`) at boundary?
2. Fallback path tested?
3. ErrorBoundary per node?
4. Sentry alert configured?

### Advanced / Internal Knowledge
- `zod.preprocess` to coerce loosely-typed responses (legacy).
- Sentry `withScope` to add per-page tags.
- Last-good-version cache pattern: MMKV keyed by page slug.

### 2026 AI Tip
AI generates `parse` (throws). Replace with `safeParse` at boundaries.

### Related Topics
Q1, Q3, S01-Q7.

### Interview Follow-Up Questions
- "What happens if backend ships a typo?"
- "How do you alert on schema failures?"
- "Why ErrorBoundary per node?"

### Memory Hook
**"safeParse, log, fallback. Never crash on data."**

### Revision Notes
> Validate every SDUI response via Zod safeParse; fallback to cache or error state; ErrorBoundary per node; unknown types render fallback component; Sentry-alert on failure rate.

---

## Q3. Backward compatibility and rollout

### Difficulty
Advanced

### Interview Frequency
Common at senior+ rounds.

### Prerequisites
Q1, Q2.

### TL;DR
Old clients live for years. Schema changes must be **additive**: new optional fields, new types behind app-min-version gates. Removing fields requires a deprecation cycle (≥ N versions).

### 30-Second Interview Answer
"Old app versions stay in market for years; SDUI schemas must be backward compatible. Rules: never remove a field for N+ versions; new types require min-app-version gating server-side; unknown types fall back gracefully on client. For breaking changes I run dual-shape responses — server returns both old and new fields during transition."

### 2-Minute Practical Answer
Compatibility rules:
- **Add fields**: always optional; old clients ignore.
- **Remove fields**: deprecate first; remove only when oldest supported version doesn't read them.
- **Rename**: ship both old + new; remove old after deprecation window.
- **New types**: server checks `min-app-version` header before sending.
- **Schema bump (`schemaVersion: 2`)**: clients support N and N-1; older versions get fallback page.

Server-side gating:
```ts
// Server pseudo-code
if (clientVersion >= '5.2.0') return v2Response;
return v1Response;
```

Client-side defense:
- Fallback for unknown types.
- Optional chaining on missing fields.
- Default values via Zod `.default()`.

### 5-Minute Architecture Answer
The hard truth of mobile: app updates lag. App store approval, user delay, OS-version skew, locked-down enterprise users — your "supported floor" is often 12+ months back.

This makes SDUI both a **superpower and a risk**:
- Superpower: ship UI to all clients including old ones.
- Risk: each new feature has to work on old clients (or be gated).

Architectural patterns:
1. **Min-app-version gating** — server inspects user agent / app version header; sends safe response to old clients.
2. **Capability negotiation** — client sends `Accept: application/sdui; types=v1+v2` and server picks.
3. **Feature flags from the same backend** — flag controls which schema version a user sees.
4. **Deprecation tracking** — backend logs when each old field was last needed; cleanup when zero hits for 90 days.
5. **Schema test harness** — CI generates schemas of N versions; runs them against current app fixtures.

Failure modes:
- Server forgets gating → old clients crash → bad reviews.
- Schema bump without client-side fallback → app crashes on first home open.
- Engineers remove a "deprecated" field too early → old clients regress.

### The "Why"
- App-store cycle is days; user-update cycle is months; long-tail users are years behind.
- A single bad schema can crash millions of devices simultaneously.

### Mental Model
SDUI server is a **library** with API stability requirements similar to a public API.

### Internal Working (2026 Context)
- Server frameworks (Spring, Express) make version-aware responses standard.
- App version sent as a header by Expo / RN networking layer.
- LaunchDarkly + SDUI is common combo.

### Modern Implementation (Code)

```ts
// Server-side gating
function homePage(req: Request) {
  const ver = parseVersion(req.headers['x-app-version']);
  if (ver.gte('6.0.0')) return v3Response();
  if (ver.gte('5.0.0')) return v2Response();
  return v1Response(); // safest legacy
}

// Client-side renderer with fallback
function Renderer({ node }: { node: Node }) {
  const Comp = REGISTRY[node.type] ?? UnknownType;
  return <Comp {...node.props}>{...}</Comp>;
}
```

### Comparison

| Change | Safe? | How |
|---|---|---|
| Add optional field | Yes | Just ship |
| Add new type | If gated | Min-version gate |
| Remove field | After deprecation | N versions later |
| Rename field | Dual ship | Both old + new |
| Schema major bump | Risky | Gate carefully |

### Production Usage
- App version header set automatically by network layer.
- Server uses semver compare to gate.
- CI tests responses against multiple client versions.

### Hands-On Exercise
1. Add app-version header to fetches.
2. Set up server stub that returns different shapes per version.
3. Test old client against new server response.

### Common Mistakes
- Forgetting to send app version header.
- Removing fields before all clients drop.
- Hardcoding version checks in client code (server should gate).

### Production Red Flags
- "Just add a field, don't worry about old clients."
- No deprecation tracking.
- No server-side version gating.

### Performance & Metrics
- % of users on each app version.
- Schema failure rate by app version.
- Deprecated field usage trend.

### Decision Framework
- Adding feature → optional field, no gate needed.
- New component type → server-side gate by min version.
- Removing → deprecation cycle ≥ 90 days for low-uptake users.

### Senior-Level Insight
"Treat SDUI schema like you'd treat any public API: SemVer, deprecation cycles, contract tests."

### Real-World Scenario
**Symptom:** A new home-feed component crashed users on app v3.2.x.
**Investigation:** Backend sent the new type; client < 4.0 didn't know it.
**Fix:** Client-side fallback; backend gating added.

### Production Failure Story
**Incident:** Schema v2 rolled out; 5% crash spike.
**Root cause:** Old clients couldn't parse v2.
**Fix:** Rolled back; added client-side `schemaVersion` check + fallback to cached v1.

### Debugging Checklist
1. App version header sent on every request?
2. Server gating new types?
3. Client fallback for unknown types?
4. Deprecation tracking active?

### Advanced / Internal Knowledge
- Some teams adopt GraphQL for SDUI to leverage field selection (clients ask only for known fields).
- Protocol Buffers' field-tagging makes additive changes safer.
- App version as a Sentry tag aids triage.

### 2026 AI Tip
AI doesn't think about backward compat. Always ask: "Will this break clients on v3.0?"

### Related Topics
Q1, Q2, Q4, S20 (CI / release).

### Interview Follow-Up Questions
- "How do you remove a field from the schema?"
- "What if a user is on a 2-year-old app?"
- "Why version the schema if components are typed?"

### Memory Hook
**"Add safe. Remove slow. Gate new. Fallback old."**

### Revision Notes
> SDUI schemas serve apps for years; only additive changes are safe; gate new types server-side; client fallback for unknown; deprecate fields for N versions before removing; track deprecation usage.

---

## Q4. SDUI + experimentation (A/B, feature flags)

### Difficulty
Advanced

### Interview Frequency
Common at growth-driven seniors+.

### Prerequisites
Q1, basic experimentation concepts.

### TL;DR
SDUI is the **delivery layer** for UI experiments. Server picks variant per user (sticky bucketing); the variant determines which schema is returned. Analytics events carry experiment + variant tags for attribution.

### 30-Second Interview Answer
"SDUI lets product run UI experiments without app updates. Server buckets users (sticky by user ID), picks a variant, returns the corresponding schema. Each event from the variant carries `experiment_id` + `variant` tags so analytics can measure lift. I avoid client-side bucketing — server-side is consistent across surfaces and devices."

### 2-Minute Practical Answer
Architecture:
- Experiment service (LaunchDarkly, Optimizely, Statsig) holds experiment definitions.
- SDUI service queries experiments at request time; picks variant.
- Schema returned includes `meta: { experiment, variant }` so client tags events.

Client side:
```ts
function trackPress(node: Node, page: Page) {
  analytics.track('press', {
    nodeId: node.id,
    nodeType: node.type,
    experiment: page.meta?.experiment,
    variant: page.meta?.variant,
  });
}
```

Sticky bucketing:
- Hash(userId + experimentId) % 100.
- Result determines bucket; same user always sees same variant.
- Don't re-bucket on each request.

Guardrails:
- Crash rate per variant — auto-rollback if variant exceeds threshold.
- Performance metric per variant.
- Sample size + statistical significance check before declaring winner.

### 5-Minute Architecture Answer
SDUI + experimentation is the modern product velocity stack:
- Designers / PMs author variants in SDUI templates (or a CMS that emits SDUI).
- Experiment service buckets users; assigns variant.
- SDUI server picks the right template per variant.
- Analytics tags every event with experiment + variant.
- Stats engine computes lift per goal metric.

For RN 2026:
- Statsig and Vercel have first-class SDKs in RN.
- TanStack Query caches per-page response, including variant; invalidate on experiment change.
- Sticky bucketing via server eliminates client-side flicker.

Anti-patterns:
- Client-side bucketing → users see different variants on different devices.
- Variants too granular → underpowered tests, no learning.
- No guardrail metrics → bad variants ship to 100%.

Holistic flow:
1. PM defines hypothesis + goal metric.
2. Engineer creates SDUI variant in CMS / config.
3. Variants gated by experiment.
4. Run for N weeks until significance.
5. Auto-rollback on guardrail breach (crash rate, perf).
6. Winner promotes to default; loser cleaned up.

### The "Why"
- A/B testing requires UI variance without code shipping.
- Server-side bucketing avoids cross-device inconsistency.
- Tagged events enable attribution.

### Mental Model
SDUI = **render**; experimentation = **route**. The server routes users to different SDUI variants.

### Internal Working (2026 Context)
- LaunchDarkly's SDK injects flags into SDUI server context.
- Statsig integrates with TanStack Query for cache invalidation on flag change.
- Server-side bucketing via consistent hash.

### Modern Implementation (Code)

```ts
// Server (pseudo)
async function home(req: Request) {
  const userId = req.user.id;
  const variant = await experiments.getVariant('home_v3', userId);
  const layout = await sduiTemplates.render(`home_${variant}`, { user: req.user });
  return { schemaVersion: 1, layout, meta: { experiment: 'home_v3', variant } };
}

// Client analytics
useEffect(() => {
  if (page?.meta?.experiment) {
    analytics.exposure(page.meta.experiment, page.meta.variant);
  }
}, [page]);
```

### Comparison

| Bucketing | Pros | Cons |
|---|---|---|
| Server-side | Consistent across devices/surfaces | Server complexity |
| Client-side | Simple | Cross-device inconsistency |
| Edge / CDN | Fast | Personalization limited |

### Production Usage
- Statsig / LaunchDarkly common.
- Variant exposure logged on first render of each page.
- Auto-rollback on crash rate breach.

### Hands-On Exercise
1. Set up a 2-variant SDUI experiment with a feature flag service.
2. Tag analytics with `variant`.
3. Compute lift in your analytics tool.

### Common Mistakes
- Client-side bucketing.
- No exposure logging → can't measure.
- Forgot to clean up after experiment ends.
- No guardrails on crash rate.

### Production Red Flags
- Multiple experiments overlapping without orthogonality.
- Long-running experiments past significance.
- No rollback path.

### Performance & Metrics
- Variant exposure rate.
- Goal metric per variant.
- Crash + perf metrics per variant.

### Decision Framework
- Cross-device user → server-side bucketing.
- Low-stakes UI tweak → SDUI experiment.
- Major flow change → A/B with native code (more control).

### Senior-Level Insight
"SDUI + experimentation only works if every variant is monitored." Without guardrails, you're rolling out untested UI to fractions of users.

### Real-World Scenario
**Symptom:** Home conversion stagnant for months.
**Investigation:** No experiments running.
**Fix:** Set up SDUI variant infrastructure; ran 5 experiments in 6 weeks; learned which CTAs work.

### Production Failure Story
**Incident:** A variant crashed for 1% of users; crash rate alarm missed.
**Fix:** Per-variant Sentry tags; auto-rollback if variant exceeds 2× baseline.

### Debugging Checklist
1. Server-side bucketing only?
2. Exposure logged on first render?
3. Variants tagged on every event?
4. Guardrail metrics monitored?

### Advanced / Internal Knowledge
- Bayesian vs frequentist stats engines.
- CUPED variance reduction for faster significance.
- Multi-armed bandit allocation for fast winners.

### 2026 AI Tip
AI can suggest experiment hypotheses but rarely sets up infrastructure. Treat infra (bucketing, exposure, analysis) as senior eng work.

### Related Topics
Q1, S20 (release/CI), S08 (state with TanStack Query).

### Interview Follow-Up Questions
- "Why server-side bucketing?"
- "How do you measure lift?"
- "What guardrails would you put on SDUI experiments?"

### Memory Hook
**"Server buckets. Schema varies. Events attribute. Guardrails protect."**

### Revision Notes
> SDUI delivers UI variants for A/B tests; server-side sticky bucketing; meta tags carry experiment+variant; events carry tags; guardrails on crash + perf; auto-rollback on breach.

---

## Q5. SDUI performance — preloading, caching, virtualization

### Difficulty
Advanced

### Interview Frequency
Common.

### Prerequisites
Q1.

### TL;DR
Cache responses (TanStack Query / MMKV); preload likely-next pages; render lists via FlashList; memoize per-node with React Compiler. Validation is the only "free" cost — make sure schemas are compact.

### 30-Second Interview Answer
"SDUI perf is about three things: cache (TanStack Query for in-memory + MMKV for cold start), preload (prefetch likely-next pages on idle), and render efficiently (FlashList for any list > 20 items, React Compiler memoization). Schema validation is small but log P99. Largest pages should stream sections rather than render monolithically."

### 2-Minute Practical Answer
Cache layers:
- TanStack Query: in-memory + stale-while-revalidate.
- MMKV: persistent, survives cold starts.
- HTTP cache: ETag / Last-Modified for backend efficiency.

Preload:
- On home tap predictions, prefetch likely categories.
- On idle (`InteractionManager.runAfterInteractions`), prefetch profile / settings.

Rendering:
- FlashList for vertical lists (S07).
- Skeleton during fetch.
- Suspense + Error Boundary per top-level section.
- React Compiler eliminates manual memo.

Schema size:
- Compact field names (`p` vs `props`) only if size matters.
- Reference data via IDs, not duplication.
- Server can stream sections (`text/event-stream` or chunked JSON).

### 5-Minute Architecture Answer
SDUI pages can be huge (home feed = 100s of nodes). Performance budget per page:
- TTFB < 300ms.
- Schema validation < 20ms.
- First render < 16ms (one frame).
- Full render < 100ms.

Strategies:
1. **Server-side**: cache pages, gzip/Brotli compression, stream sections, lazy-load below-fold via separate calls.
2. **Network**: HTTP/2 + ETag; CDN for static templates; per-region caching.
3. **Client cache**: TanStack Query for in-memory; MMKV mirror for cold-start hydration.
4. **Validation**: precompiled Zod schemas; profile parse time; consider Valibot for hot paths.
5. **Render**: FlashList for vertical lists; Skia for charts; lazy children via Suspense.
6. **Memoization**: React Compiler handles most; manual `memo` for very deep trees.

Streaming pattern (2026):
- Server streams: `header → above-fold → below-fold → footer`.
- Client renders incrementally; Suspense boundaries between sections.
- Lower TTFB; perceived perf much better.

### The "Why"
- SDUI pages are heavier than static (more data).
- Cold start with empty cache = bad first impression.
- Long lists are common in SDUI (feeds, search results).

### Mental Model
SDUI = **content delivery + render pipeline**. Optimize at each stage.

### Internal Working (2026 Context)
- TanStack Query v5 has improved persistence APIs.
- React Compiler memoizes SDUI renderer for free.
- FlashList v2+ is mature; auto-recycles aggressively.

### Modern Implementation (Code)

```tsx
// TanStack Query with MMKV persistence
const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 60_000, gcTime: 10 * 60_000 } },
});

const persister = createSyncStoragePersister({ storage: mmkvStorage });
persistQueryClient({ queryClient, persister, maxAge: 24 * 60 * 60 * 1000 });

// Preload on idle
useEffect(() => {
  InteractionManager.runAfterInteractions(() => {
    queryClient.prefetchQuery({ queryKey: ['page', 'profile'], queryFn: () => fetchPage('profile') });
  });
}, []);

// Render with FlashList for lists
function ListNode({ node }: { node: Node }) {
  return (
    <FlashList
      data={node.children ?? []}
      keyExtractor={(c) => c.id}
      renderItem={({ item }) => <Renderer node={item} />}
      estimatedItemSize={120}
    />
  );
}
```

### Comparison

| Strategy | Win | Cost |
|---|---|---|
| TanStack Query cache | Fast warm renders | Memory |
| MMKV persistence | Fast cold start | Stale data risk |
| Streaming server | Lower TTFB | Server complexity |
| FlashList | 60fps lists | Layout estimation |
| React Compiler | Auto memoization | TS adoption |

### Production Usage
- Home / category pages cached for 60s+ in TanStack Query.
- MMKV mirror for offline / cold start.
- Streaming used for feed-style pages.

### Hands-On Exercise
1. Add TanStack Query + MMKV persistence to SDUI fetches.
2. Profile cold vs warm renders.
3. Replace ScrollView + map with FlashList; observe FPS.

### Common Mistakes
- Re-validating cached responses unnecessarily (cache the validated, not raw).
- Re-rendering all nodes on small data changes (lack of memoization or keys).
- No persistent cache → cold start always paints empty.

### Production Red Flags
- TTFP > 1s on home.
- Schema validation > 50ms.
- Long lists rendered with `map` not virtualized.

### Performance & Metrics
- TTFB, TTFP, full render time.
- Cache hit rate (in-memory + persistent).
- FPS during scroll.

### Decision Framework
- Hot path → cache + preload.
- Heavy list → FlashList.
- Many sections → streaming + Suspense.

### Senior-Level Insight
"The fastest SDUI page is the one already on disk." Persistent cache + smart preload means most navigations feel instant.

### Real-World Scenario
**Symptom:** Home open shows blank for 600ms after cold start.
**Investigation:** No persistent cache; full network round-trip.
**Fix:** MMKV persistence; cold start now hydrates last-good in 50ms.

### Production Failure Story
**Incident:** P99 home open latency spiked to 3s.
**Root cause:** Backend dropped CDN; every request hit origin.
**Fix:** Restored CDN + added client-side prefetch on app open.

### Debugging Checklist
1. Cache configured (in-memory + persistent)?
2. Lists virtualized (FlashList)?
3. Preload on idle / predicted nav?
4. Streaming for large pages?

### Advanced / Internal Knowledge
- HTTP/3 (QUIC) reduces handshake latency for SDUI fetches.
- Service-worker-style caching not in RN; MMKV is the equivalent.
- Skia surfaces for SDUI animations bypass JS thread.

### 2026 AI Tip
AI rarely sets up persistence. Add MMKV mirror manually after generating fetch logic.

### Related Topics
Q1, Q2, S07 (perf), S08 (state).

### Interview Follow-Up Questions
- "How do you handle cold-start SDUI?"
- "Why FlashList over FlatList?"
- "How do you preload likely-next pages?"

### Memory Hook
**"Cache, preload, virtualize. Stream the heavy ones."**

### Revision Notes
> SDUI perf: TanStack Query + MMKV persistence; preload on idle; FlashList for lists; React Compiler for memo; stream large pages with Suspense boundaries.

---

> Cross-refs: S07 (perf), S08 (state), S16-Q5 (basic SDUI), S20 (release).
