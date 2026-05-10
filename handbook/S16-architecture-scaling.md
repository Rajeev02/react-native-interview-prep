# S16 — Architecture & Scaling

> Feature-first vs layered · monorepo (pnpm + Turborepo) · white-label apps · brownfield integration · SDUI schema design

How a senior engineer organizes a React Native codebase for 5+ years and 5+ engineers.

## Topics in this section

- [Q1. Feature-first vs layered architecture](#q1-feature-first-vs-layered-architecture)
- [Q2. Monorepo (pnpm + Turborepo) for RN apps](#q2-monorepo-pnpm--turborepo-for-rn-apps)
- [Q3. White-label apps — one codebase, many brands](#q3-white-label-apps--one-codebase-many-brands)
- [Q4. Brownfield integration — embedding RN in native apps](#q4-brownfield-integration--embedding-rn-in-native-apps)
- [Q5. SDUI schema design at scale](#q5-sdui-schema-design-at-scale)

---

## Q1. Feature-first vs layered architecture

### Difficulty
Intermediate

### Interview Frequency
Very Common at senior+ rounds.

### Prerequisites
React component basics, navigation.

### TL;DR
**Layered** = group by tech (`/components`, `/hooks`, `/screens`, `/services`). **Feature-first** = group by domain (`/features/auth`, `/features/feed`). Feature-first scales better past ~30 screens; layered is fine for small apps.

### 30-Second Interview Answer
"Layered groups by technical concern; works for tiny apps, breaks at scale because changing 'feed' touches every folder. Feature-first co-locates everything for a feature — components, hooks, services, types — under `/features/feed`. Cross-feature concerns live in `/shared`. Past ~30 screens, feature-first is the only sustainable choice; it enables code-ownership boundaries and parallel team work."

### 2-Minute Practical Answer
Feature-first layout:
```
src/
  features/
    auth/
      api/
      components/
      hooks/
      screens/
      types.ts
      index.ts          // public surface
    feed/
      api/
      components/
      hooks/
      screens/
      index.ts
  shared/
    components/         // truly shared (Button, Card)
    hooks/
    api/                // base client, interceptors
    theme/
    utils/
  app/                  // expo-router or RN navigation entry
```

Rules:
- Features can import from `shared` only; never from each other (or use a thin contract).
- `index.ts` defines the public API; everything else is internal.
- Shared = "used by 3+ features" (otherwise keep local).

### 5-Minute Architecture Answer
Layered architecture (`/components`, `/screens`) is the React tutorial pattern; it stops scaling because:
- Cross-cutting changes touch many folders.
- New engineers don't know where things live.
- Feature ownership becomes impossible.

Feature-first solves this with **vertical slices**. Each feature is an island with internal organization that suits it. Cross-feature communication goes through:
- `/shared` for truly shared concerns.
- A pub/sub bus (events) for loose coupling.
- A typed RPC pattern (function calls between features) when tighter coupling is needed.

At scale (50+ screens, 10+ engineers), elevate features to **packages** in a monorepo (Q2). Each feature becomes `@app/feature-feed`, with its own tests, types, and version.

Cross-feature dependencies should be **directional** — auth → feed → comments, not cyclic. A linter (`eslint-plugin-boundaries`) enforces import rules.

For very large apps, evolve toward **module federation patterns** with Re.Pack (webpack-based RN bundler) — features become independently deployable.

### The "Why"
- Cohesion (everything for a feature in one place) reduces cognitive load.
- Coupling (between features) is the bug source; feature-first makes it explicit.
- Ownership boundaries map to code boundaries.

### Mental Model
Layered = library by author. Feature-first = library by genre. At small scale either works; at large scale only genre scales.

### Internal Working (2026 Context)
- Expo Router 4+ supports nested `_layout.tsx` per feature folder.
- React Compiler doesn't care about folder structure but benefits from clear feature boundaries (less cross-feature memo invalidation).
- `eslint-plugin-boundaries` and `dependency-cruiser` enforce architecture in CI.

### Modern Implementation (Code)

```ts
// features/feed/index.ts — public surface
export { FeedScreen } from './screens/FeedScreen';
export { useFeed } from './hooks/useFeed';
export type { Post } from './types';

// features/feed/screens/FeedScreen.tsx — internal
import { useFeed } from '../hooks/useFeed';
import { PostCard } from '../components/PostCard';
import { Button } from '@app/shared/components';
// not from features/auth — cross-feature import would be banned

// .eslintrc — enforce boundaries
module.exports = {
  plugins: ['boundaries'],
  rules: {
    'boundaries/element-types': ['error', {
      default: 'disallow',
      rules: [
        { from: 'feature', allow: ['shared', 'feature-self'] },
        { from: 'shared', allow: ['shared'] },
        { from: 'app', allow: ['feature', 'shared'] },
      ],
    }],
  },
};
```

### Comparison

| Pattern | Best for | Pain at scale |
|---|---|---|
| Layered (`/components`, etc.) | < 20 screens | Cross-cutting edits, ownership |
| Feature-first | 20–200 screens | Need clear cross-feature contracts |
| Monorepo packages | 100+ screens, multi-team | Tooling overhead |
| Module federation | Very large, multi-app | Bundler complexity |

### Production Usage
- Most senior RN codebases past 1 year are feature-first.
- Linter rules enforce cross-feature import bans.
- New features start with a folder template (yeoman or simple cp script).

### Hands-On Exercise
1. Refactor a small layered app to feature-first. Note the deletes / moves.
2. Add `eslint-plugin-boundaries`. Watch existing violations surface.
3. Extract one feature to a separate package; observe what was secretly coupled.

### Common Mistakes
- "Shared utils dump" that grows unboundedly.
- Cross-feature imports masked by `index.ts` re-exports.
- `screens/` folder holding business logic instead of feature folders.

### Production Red Flags
- Multi-feature changes for any new feature.
- Test files far from source.
- Single `redux/store.ts` listing every feature's slices (ownership unclear).

### Performance & Metrics
- Time to add a new screen (proxy for organization quality).
- Cross-feature import count (linter metric).
- Bundle splits per feature (with dynamic imports).

### Decision Framework
- New app, < 10 screens → layered is fine.
- 10–30 screens → switch to feature-first.
- 30+ screens or 5+ engineers → feature-first + monorepo.

### Senior-Level Insight
"Code organization is mostly a social problem." Feature-first works because it matches how teams actually own code. The structure is a forcing function for product → team → code alignment.

### Real-World Scenario
**Symptom:** New "checkout" feature took 3 weeks instead of 1.
**Investigation:** Touched 14 files across `/components`, `/hooks`, `/services`, `/screens`.
**Root cause:** Layered architecture; checkout state leaked into shared hooks.
**Fix:** Refactored `/features/checkout` as a vertical slice; subsequent features shipped in days.

### Production Failure Story
**Incident:** Removing legacy "promotions" feature took 2 sprints.
**Root cause:** Promotions code scattered across 9 folders; many shared utils only used by it.
**Fix:** Feature-first refactor before next big change; deletions become a folder rm.

### Debugging Checklist
1. Can a new engineer find feature X's code in < 30 seconds?
2. Does deleting feature X = deleting one folder?
3. Does the linter enforce import boundaries?
4. Are tests co-located with source?

### Advanced / Internal Knowledge
- Module federation with Re.Pack enables runtime-loaded features.
- Code-splitting per feature requires Hermes' inline-requires + Metro tweaks.
- Storybook scopes per-feature for isolated dev.

### 2026 AI Tip
AI defaults to layered; explicitly prompt "feature-first under `/features`" when scaffolding.

### Related Topics
Q2, Q3, S05 (Expo tooling), S08 (state).

### Interview Follow-Up Questions
- "How do you decide when to extract a shared component?"
- "How do you handle cross-feature state?"
- "When would you reach for a monorepo?"

### Memory Hook
**"Group by feature, not by file type. `index.ts` is the contract."**

### Revision Notes
> Feature-first scales past ~30 screens; co-locate components/hooks/api/types per feature; `/shared` for truly shared; enforce boundaries with linter; evolve to monorepo packages for very large apps.

---

## Q2. Monorepo (pnpm + Turborepo) for RN apps

### Difficulty
Advanced

### Interview Frequency
Common at senior+ rounds.

### Prerequisites
Workspaces, npm/yarn/pnpm.

### TL;DR
**pnpm workspaces** + **Turborepo** = fast, cached, parallel monorepo. Apps in `apps/`, libs in `packages/`. Turbo caches per-package builds; CI is order-of-magnitude faster than naive multi-repo.

### 30-Second Interview Answer
"For RN at scale I use pnpm workspaces (fast, strict, deduped) with Turborepo for the task graph. Apps under `apps/` (mobile, web), shared libs under `packages/` (ui, api-client, design-system). Turbo caches per-package, so CI runs only what changed; `--filter` lets devs work on slices. Metro needs `extraNodeModules` config to resolve symlinks correctly."

### 2-Minute Practical Answer
Layout:
```
.
├── apps/
│   ├── mobile/          # React Native / Expo app
│   └── web/             # Next.js (optional)
├── packages/
│   ├── ui/              # shared design system
│   ├── api-client/      # TanStack Query + Zod schemas
│   └── tsconfig/        # shared tsconfigs
├── pnpm-workspace.yaml
└── turbo.json
```

Key configs:
- `pnpm-workspace.yaml` lists `apps/*` and `packages/*`.
- `turbo.json` defines pipeline (`build`, `lint`, `test`) with dependency graph.
- Metro's `metro.config.js` needs `watchFolders` pointing at `packages/` and a custom resolver for symlinks (or use Expo, which handles this).

Why pnpm:
- Hard-linked node_modules saves disk + speeds installs.
- Strict — packages can only import what they declare.
- Workspace protocol (`workspace:*`) for in-monorepo deps.

Why Turborepo:
- Incremental builds with content-addressed cache (local + remote).
- Parallel task execution per dependency graph.
- `--filter=mobile...` runs mobile + its dep tree.

### 5-Minute Architecture Answer
Monorepos solve **shared code** problems that multi-repo creates: version drift, duplicate work, cross-team breaking changes.

But monorepos add complexity: build orchestration, package resolution (especially RN's Metro), CI complexity. Turborepo + pnpm minimize this:
- Turbo's task graph mirrors package dependency graph; only changed packages rebuild.
- Remote cache (Vercel or self-hosted) shares artifacts across CI runs and team members.
- pnpm's strictness catches phantom dependencies (using a package without declaring it).

For RN specifically:
- Metro doesn't follow symlinks by default. Either:
  - Use Expo (handles it).
  - Add `watchFolders: [path.resolve(__dirname, '../../packages')]` and `nodeModulesPaths`.
- Native modules in shared packages need autolinking config (most libraries handle it).
- Per-app native code stays in `apps/mobile/ios` and `apps/mobile/android`.

CI pattern:
- Cache restore → `turbo run lint test build --filter=...[origin/main]` → artifacts.
- EAS Build (Expo) integrates with Turborepo for prebuild.
- App Center / Bitrise / GitHub Actions all support Turbo's remote cache.

### The "Why"
- Shared code is critical for cross-platform (mobile + web + admin) consistency.
- Versioning hell across multiple repos slows teams.
- Caching makes monorepo CI fast despite size.

### Mental Model
Monorepo = one workspace, many packages, one task graph. Turbo = "redo only what changed."

### Internal Working (2026 Context)
- Turborepo 2.x has improved Watch Mode and Boundaries (typed package boundaries).
- pnpm 9.x default; corepack manages versions.
- Expo SDK 50+ has first-class monorepo support; no custom Metro config needed.
- Remote cache (Vercel, self-hosted via `turbo-remote-cache`) shared across team.

### Modern Implementation (Code)

```yaml
# pnpm-workspace.yaml
packages:
  - apps/*
  - packages/*
```

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "lint":  { "dependsOn": ["^build"] },
    "test":  { "dependsOn": ["^build"], "cache": true },
    "dev":   { "persistent": true, "cache": false }
  }
}
```

```js
// apps/mobile/metro.config.js (without Expo)
const path = require('path');
const { getDefaultConfig } = require('@react-native/metro-config');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);
config.watchFolders = [workspaceRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];
config.resolver.disableHierarchicalLookup = true;
module.exports = config;
```

```json
// packages/ui/package.json
{
  "name": "@app/ui",
  "version": "0.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "peerDependencies": { "react": "*", "react-native": "*" }
}
```

### Comparison

| Tool | Strength | Use case |
|---|---|---|
| Lerna | Mature, simple | Legacy / simple monorepos |
| Nx | Powerful, opinionated | Large enterprise, plugins |
| Turborepo | Fast cache, simple | Most modern teams |
| pnpm workspaces | Strict, dedupe | Always pair with Turbo/Nx |

### Production Usage
- Mobile + web sharing UI library, types, and API client.
- Per-feature packages for very large apps.
- Remote cache shared across CI + dev machines.

### Hands-On Exercise
1. Set up pnpm + Turbo skeleton; add `@app/ui` package; consume from `apps/mobile`.
2. Configure Metro for symlinks (or use Expo).
3. Run `turbo run build --filter=mobile`; observe cache hits on second run.

### Common Mistakes
- Forgetting `watchFolders` in Metro → "module not found" for shared packages.
- Native dependencies in shared packages without autolinking config.
- Mixing yarn/npm/pnpm lockfiles.
- Hot-reload broken because shared package `main` points to `dist` not `src`.

### Production Red Flags
- Per-package `node_modules` exploding (pnpm should hard-link).
- Turbo cache misses on every run (config issue).
- Shared package versions drifting via `^` ranges.

### Performance & Metrics
- CI duration before / after Turbo (typically 3–5× faster).
- Cache hit rate (target > 70% for mature codebase).
- Cold install time.

### Decision Framework
- 1 app, 1 team → no monorepo needed.
- 2+ apps sharing code → monorepo immediately.
- 5+ apps or many libs → monorepo + remote cache.

### Senior-Level Insight
"Monorepos win when you have shared code. Don't adopt one to be fancy." If your "shared" package is one Button, just copy it. Monorepo is for substantive sharing.

### Real-World Scenario
**Symptom:** Web team's `/auth` API change broke mobile silently.
**Root cause:** API client duplicated in two repos; only web updated.
**Fix:** Extract to `@app/api-client` in monorepo; both apps use the same version.

### Production Failure Story
**Incident:** Metro couldn't find `@app/ui` after setup; week-long debugging.
**Root cause:** Default Metro doesn't follow symlinks.
**Fix:** Custom resolver + `watchFolders`. Documented in repo README.

### Debugging Checklist
1. Are all apps and packages in `pnpm-workspace.yaml`?
2. Does `pnpm install` produce a single root lockfile?
3. Is Metro configured for symlinks?
4. Is `turbo run` showing cache hits?

### Advanced / Internal Knowledge
- `pnpm patch` lets you fork a dep without forking the repo.
- Turbo's `globalDependencies` invalidates cache on env var change.
- Expo's `expo-monorepo` example is the canonical reference.

### 2026 AI Tip
AI often forgets monorepo Metro config. After scaffolding, manually verify `watchFolders` and `nodeModulesPaths`.

### Related Topics
Q1, Q3, S05 (Expo / EAS), S20 (CI).

### Interview Follow-Up Questions
- "Why pnpm over yarn?"
- "How does Turbo know what to rebuild?"
- "How does Metro handle monorepo symlinks?"

### Memory Hook
**"pnpm dedupes. Turbo caches. Metro needs configuring."**

### Revision Notes
> pnpm workspaces + Turborepo for RN monorepos; apps/ + packages/; configure Metro `watchFolders` for symlinks (or use Expo); remote cache for CI; only adopt when you have real shared code.

---

## Q3. White-label apps — one codebase, many brands

### Difficulty
Advanced

### Interview Frequency
Common at agencies, fintech, platforms.

### Prerequisites
Theming, build configurations.

### TL;DR
A **white-label** app produces N branded binaries from one codebase. Diverge on **theme + assets + config**, share **code + screens**. Use product flavors (Android), schemes / xcconfig (iOS), and EAS profiles or `react-native-config` for env.

### 30-Second Interview Answer
"White-label means N apps from one codebase — different bundle IDs, names, assets, themes, and feature flags per brand. I separate variant data (`brands/acme.json`, `brands/beta.json`) from code; build scripts swap assets, plist values, and Android resources at build time. EAS Build profiles or Fastlane orchestrate per-brand builds; CI matrix produces all binaries in parallel."

### 2-Minute Practical Answer
The variant surface area:
- **Identity**: bundle ID, app name, app icon, splash screen.
- **Theming**: colors, fonts, logos.
- **Config**: API base URL, feature flags, analytics keys.
- **Native config**: GoogleService-Info.plist (Firebase), URL schemes, signing.

Implementation patterns:
- **Brand config file**: `brands/${BRAND}.json` describes colors, IDs, URLs.
- **Asset swap**: pre-build script copies `brands/${BRAND}/assets/*` over `assets/`.
- **Native config swap**: Expo config plugins (preferred) or shell scripts edit Info.plist / strings.xml at build.
- **Theme provider**: reads brand config, exposes via React context.
- **Feature flags**: per-brand JSON, optionally fetched remotely.

EAS Build profile per brand:
```json
// eas.json
{ "build": {
    "production-acme": { "env": { "BRAND": "acme" } },
    "production-beta": { "env": { "BRAND": "beta" } }
}}
```

### 5-Minute Architecture Answer
White-label is **packaging discipline**. The app is one product; brands are configurations.

Architecture levels:
1. **Build-time variance** — bundle ID, name, icons, splash. Done via plugins/scripts.
2. **Runtime theming** — colors, fonts, copy. Done via context/provider.
3. **Feature flags** — per-brand enabled features. Done via remote config (LaunchDarkly, Firebase Remote Config) or static.
4. **A/B and experiments** — rare per-brand divergence beyond config.

Anti-patterns to avoid:
- `if (brand === 'acme')` scattered in screens — config drives behavior, not branching.
- Per-brand forks of components — pull differences into props/theme.
- Manual brand swap before each build — automate.

For iOS, **xcconfig files** + **schemes** (one scheme per brand) are the clean way. For Android, **product flavors** in `app/build.gradle` give per-flavor `applicationId`, resources, and signing.

Expo path is simpler:
- `app.config.ts` reads `process.env.BRAND` and returns brand-specific config.
- EAS Build profile sets `BRAND`; everything else flows from config.
- Config plugins inject native edits (Info.plist, strings.xml).

### The "Why"
- Agencies ship N apps from one team; can't justify N codebases.
- Platforms (banking, telecom) license a white-label to enterprise customers.
- Cost: 1 codebase ≠ 10× engineering; closer to 1.5×.

### Mental Model
The codebase is a **factory**; brands are **recipes**; build scripts are **assembly lines**.

### Internal Working (2026 Context)
- Expo Config Plugins (2026) handle most native edits without ejecting.
- EAS Build profiles + secrets per brand.
- Codepush / EAS Update channels per brand for OTA.

### Modern Implementation (Code)

```ts
// app.config.ts (Expo)
const brand = process.env.BRAND ?? 'acme';
const brands = require(`./brands/${brand}.json`);

export default {
  name: brands.displayName,
  slug: `myapp-${brand}`,
  ios: { bundleIdentifier: brands.ios.bundleId },
  android: { package: brands.android.applicationId },
  icon: `./brands/${brand}/icon.png`,
  splash: { image: `./brands/${brand}/splash.png` },
  extra: { ...brands.runtime, brand },
};
```

```json
// brands/acme.json
{
  "displayName": "Acme",
  "ios": { "bundleId": "com.acme.app" },
  "android": { "applicationId": "com.acme.app" },
  "runtime": {
    "primaryColor": "#0066FF",
    "apiBaseUrl": "https://api.acme.com",
    "features": { "premium": true }
  }
}
```

```ts
// theme provider
import Constants from 'expo-constants';
const { primaryColor } = Constants.expoConfig?.extra ?? {};
export const theme = { colors: { primary: primaryColor } } satisfies Theme;
```

### Comparison

| Approach | Best for |
|---|---|
| Expo config + plugins | Modern, RN 2026 default |
| Android flavors + iOS schemes | Bare RN, full control |
| Single-binary multi-tenant | Enterprise SaaS where users login |

### Production Usage
- Brand JSON checked in; secrets in EAS / CI vault.
- One CI matrix produces all brand binaries on tag.
- Per-brand release notes and store listings.

### Hands-On Exercise
1. Add 2 brands to a sample app via `app.config.ts`.
2. Add a config plugin to swap Info.plist `CFBundleDisplayName`.
3. EAS Build both; install side-by-side on simulator.

### Common Mistakes
- Hard-coded brand strings inside components.
- Forgetting per-brand GoogleService-Info.plist (Firebase analytics goes to wrong project).
- Not isolating native build artifacts per brand → cross-pollution.
- One scheme building all brands manually.

### Production Red Flags
- `if (brand === ...)` outside of theme/config layer.
- Manual asset copy steps.
- Brand-specific bug fixes that should have been config.

### Performance & Metrics
- Build time per brand (parallel matrix duration).
- Bundle size variance across brands (should be minimal — same code).
- Brand switch QA matrix coverage.

### Decision Framework
- 2 brands → simple config swap.
- 5+ brands → automated CI matrix + remote config.
- Per-tenant runtime (one binary, many tenants) → multi-tenant in-app, not white-label.

### Senior-Level Insight
"White-label is mostly a tooling problem, not a code problem." Invest 2 weeks in clean build automation; reap years of fast brand additions.

### Real-World Scenario
**Symptom:** Adding a new brand took 5 days.
**Investigation:** Manual Xcode scheme setup, manual asset placement, manual Firebase project linking.
**Fix:** Single `pnpm add-brand` script + config-plugin pipeline; new brands take 1 hour.

### Production Failure Story
**Incident:** Brand A's analytics events appeared in Brand B's dashboard for 2 weeks.
**Root cause:** Wrong GoogleService-Info.plist embedded; not swapped per brand.
**Fix:** EAS Build secret per brand; config plugin places correct file.

### Debugging Checklist
1. Does each brand build use its own bundle ID + signing?
2. Are assets, Firebase configs, and analytics keys per-brand?
3. Are theme tokens read from config, not hard-coded?
4. Is the build pipeline reproducible (no manual steps)?

### Advanced / Internal Knowledge
- Expo config plugins can splice into Info.plist, strings.xml, AndroidManifest.
- EAS supports per-profile environment files and secrets.
- React Native's `react-native-config` (env-based) still works for non-Expo projects.

### 2026 AI Tip
AI often suggests `if (brand === 'x')` inside components. Refactor to config-driven theme/feature flag.

### Related Topics
Q1, Q2, S05 (Expo), S20 (CI).

### Interview Follow-Up Questions
- "How do you keep brands from diverging into custom code?"
- "How do you handle per-brand Firebase / push tokens?"
- "Build matrix or sequential builds for 10 brands?"

### Memory Hook
**"Variance lives in config. Code stays brand-blind."**

### Revision Notes
> White-label = N binaries from 1 codebase via per-brand JSON + Expo config plugins; theme+feature flags driven by config; EAS profiles per brand; never branch on brand in component code.

---

## Q4. Brownfield integration — embedding RN in native apps

### Difficulty
Advanced

### Interview Frequency
Common at enterprises with legacy native apps.

### Prerequisites
RN basics; native iOS/Android project structure.

### TL;DR
**Brownfield** = existing native app, add RN screens. Use `RCTRootView` (iOS) / `ReactRootView` (Android) inside native VC/Activity; share data via TurboModules; Bridgeless mode + Codegen make this much cleaner in 2026.

### 30-Second Interview Answer
"Brownfield is the inverse of greenfield: a native app exists; we add RN screens. I integrate via `RCTRootView` on iOS and `ReactRootView` on Android, hosted in a native UIViewController/Activity. Bridgeless mode in 2026 simplifies this — no more bridge teardown gotchas. Communication uses TurboModules for native-to-RN and `RCTDeviceEventEmitter` for the reverse. Initialization cost is real; warm-start the RN host before user taps."

### 2-Minute Practical Answer
Integration steps:
1. Add RN as a CocoaPod / Gradle dep (or use `expo-modules-core`'s brownfield path).
2. Initialize `RCTBridge` (Bridgeless: `RCTHost`) once at app launch.
3. Create `RCTRootView(bridge:, moduleName:, initialProperties:)` and embed in native VC.
4. Pass data via `initialProperties` and TurboModules.
5. Handle navigation handoff: native nav → RN screen → native nav.

iOS skeleton:
```swift
class ReactScreenVC: UIViewController {
  override func viewDidLoad() {
    let host = AppRNHost.shared
    let view = RCTRootView(host: host, moduleName: "ProfileScreen", initialProperties: ["userId": userId])
    view.frame = self.view.bounds
    self.view.addSubview(view)
  }
}
```

Android skeleton:
```kotlin
class ReactScreenActivity : AppCompatActivity(), DefaultHardwareBackBtnHandler {
  private lateinit var reactRootView: ReactRootView
  override fun onCreate(s: Bundle?) {
    super.onCreate(s)
    reactRootView = ReactRootView(this)
    reactRootView.startReactApplication(reactInstanceManager, "ProfileScreen", Bundle().apply { putString("userId", userId) })
    setContentView(reactRootView)
  }
}
```

### 5-Minute Architecture Answer
Brownfield is the **most production-realistic** integration scenario for big companies — Walmart, Microsoft, Salesforce all run RN this way.

Key architectural concerns:
1. **Single instance** — one `RCTHost` (Bridgeless) for the app process; never per-screen (shared JS context = cheap navigation, but isolation tradeoffs).
2. **Cold start** — first RN screen pays ~500ms–1s init. Warm-start at app launch (after critical native screens load).
3. **Memory footprint** — Hermes adds ~30MB; budget for it.
4. **Crash isolation** — RN red boxes shouldn't kill the app; wrap in error boundaries; surface via Sentry.
5. **Navigation** — native pushes RN; RN can push back to native via a TurboModule that calls native nav APIs.
6. **Data sharing** — `initialProperties` for one-shot, TurboModules for bidirectional, `RCTDeviceEventEmitter` for native-to-RN events.

In 2026 with Bridgeless:
- `RCTHost` replaces `RCTBridge`; simpler lifecycle.
- TurboModule Codegen produces both Swift and JS bindings — no manual bridge methods.
- Fabric handles the view hierarchy; native parent VC is unaware of internal RN renderer.

Brownfield pitfalls:
- Two analytics SDKs (native + JS) if not unified — expose one via a TurboModule.
- Two crash reporters (Crashlytics native + Sentry JS) — pick one orchestration story.
- Style/theme drift between native and RN — share design tokens (Q3 patterns).

### The "Why"
- Big native apps can't rewrite overnight; RN lets teams move incrementally.
- New screens / features in RN = faster iteration than native.
- Cross-platform reuse for the new RN parts.

### Mental Model
RN is a **guest** in a native house. The host owns lifecycle; RN owns its rooms.

### Internal Working (2026 Context)
- Bridgeless mode (`RCTHost`) makes brownfield init ~30% faster than legacy bridge.
- Hermes shared between RN screens; warm cache survives.
- Expo Modules' brownfield support added in SDK 50.

### Modern Implementation (Code)

```swift
// AppRNHost — singleton RN host
final class AppRNHost {
  static let shared = makeHost()
  private static func makeHost() -> RCTHost {
    let bundleURL = Bundle.main.url(forResource: "main", withExtension: "jsbundle")!
    return RCTHost(bundleURL: bundleURL, hostDelegate: nil, turboModuleManagerDelegate: nil)
  }
}
```

```ts
// RN side — listen for native events
import { NativeEventEmitter, NativeModules } from 'react-native';
const emitter = new NativeEventEmitter(NativeModules.NativeBridge);
useEffect(() => {
  const sub = emitter.addListener('userUpdated', handle);
  return () => sub.remove();
}, []);
```

### Comparison

| Approach | Use |
|---|---|
| Greenfield (RN-only) | New apps |
| Brownfield with shared host | Most enterprise |
| Brownfield with per-screen host | Strict isolation, rare |
| Hybrid web (WebView) | Lower complexity, worse UX |

### Production Usage
- Native app shells navigation; RN handles "feature islands" (profile, feed, checkout).
- Warm-start RN host on app launch (not at first navigation).
- Shared Sentry config; native crashes + JS errors land in same project.

### Hands-On Exercise
1. Take a sample iOS Swift app; add a single RN screen via `RCTRootView`.
2. Pass props from Swift to RN.
3. Add a TurboModule callable from RN that triggers native navigation.

### Common Mistakes
- Multiple `RCTBridge` instances → memory bloat + lost JS state.
- Cold-starting RN at first tap (visible delay).
- Forgetting to handle native back button on Android (`DefaultHardwareBackBtnHandler`).
- Mixing Cocoapods for RN and SwiftPM for native incorrectly.

### Production Red Flags
- > 1s delay to first RN paint after native nav.
- Memory grows on every native ↔ RN transition (host recreated).
- JS errors crashing the host app (no error boundary).

### Performance & Metrics
- Time-to-RN-first-frame after native push.
- RN host memory baseline.
- Crash rate split (native vs JS).

### Decision Framework
- New feature in legacy native app → RN screen via brownfield.
- Whole new app → greenfield RN/Expo.
- Tiny addition with no JS team → maybe just native.

### Senior-Level Insight
"The biggest brownfield mistake is treating RN like a microservice." It's not — it's a guest sharing the host's process. Initialization, memory, and crash handling are shared concerns.

### Real-World Scenario
**Symptom:** Native app crash rate jumped after adding RN screens.
**Investigation:** JS exceptions killed the host app.
**Root cause:** No error boundary around RN root.
**Fix:** Top-level error boundary that reports + falls back to native screen.

### Production Failure Story
**Incident:** First RN screen took 2.4s to render; users dropped off.
**Root cause:** Cold-started bridge on tap.
**Fix:** Warm-started at app launch (after splash); first paint dropped to ~150ms.

### Debugging Checklist
1. Single shared `RCTHost`?
2. Warm-started before first user-visible RN nav?
3. Error boundary at RN root?
4. Native back button handled on Android?

### Advanced / Internal Knowledge
- `RCTHost` supports preloaded JS bundles for faster cold start.
- Hermes' bytecode pre-compile in the bundle eliminates parse cost.
- Expo Modules can be added to brownfield via `expo install` + `pod install`.

### 2026 AI Tip
AI often gives outdated `RCTBridge` patterns. Push for `RCTHost` (Bridgeless) for new integrations.

### Related Topics
Q1, Q5, S15 (TurboModules), S04 (architecture).

### Interview Follow-Up Questions
- "How do you share state between RN and native screens?"
- "When would you NOT use RN brownfield?"
- "What's the cold-start cost? How do you mitigate?"

### Memory Hook
**"One host, many rooms. Warm before tap."**

### Revision Notes
> Brownfield = RN screens in native app via `RCTRootView` / `ReactRootView`; one shared `RCTHost`; warm-start to avoid cold delay; data via TurboModules + initialProperties; error boundary protects host.

---

## Q5. SDUI schema design at scale

### Difficulty
Advanced

### Interview Frequency
Common at senior+ rounds (especially platform / e-com).

### Prerequisites
JSON schema, component composition.

### TL;DR
**Server-Driven UI** = the server returns a structured description of components + data; the client renders a registry. The schema must be **versioned, validated (Zod), backward-compatible**, and **componentless** (server doesn't know about React).

### 30-Second Interview Answer
"SDUI lets the backend ship UI changes without an app update. The server returns a tree of `{ type, props, children }`; the client has a typed component registry and a renderer. Schema is versioned (`schemaVersion` field), validated with Zod at the boundary, and **never** references React component names directly — just abstract types like `card`, `list`, `image`. Backward compat: clients ignore unknown types and render a fallback."

### 2-Minute Practical Answer
Schema shape:
```ts
type Node = { type: string; id: string; props?: Record<string, unknown>; children?: Node[] };
type Page = { schemaVersion: 1; layout: Node; data?: Record<string, unknown> };
```

Renderer:
```tsx
const REGISTRY: Record<string, React.ComponentType<any>> = {
  card: Card, list: List, image: Image, text: Text, button: Button,
};

function Renderer({ node }: { node: Node }) {
  const Comp = REGISTRY[node.type] ?? Fallback;
  return <Comp {...node.props}>{node.children?.map((c) => <Renderer key={c.id} node={c} />)}</Comp>;
}
```

Validation at boundary:
```ts
const NodeSchema: z.ZodType<Node> = z.lazy(() => z.object({
  type: z.string(), id: z.string(),
  props: z.record(z.unknown()).optional(),
  children: z.array(NodeSchema).optional(),
}));
const PageSchema = z.object({ schemaVersion: z.literal(1), layout: NodeSchema, data: z.record(z.unknown()).optional() });
```

### 5-Minute Architecture Answer
SDUI tradeoffs:
- **Win**: ship UI without app updates (offers, layouts, A/B tests, regional copy).
- **Cost**: harder to test (server + client coupling), accessibility easy to break, animations harder to design declaratively.

Architectural rules:
1. **Versioned schema** — every page declares `schemaVersion`. Clients support N and N-1; older versions get a fallback.
2. **Validation at boundary** — every response goes through Zod (S01-Q7). Invalid → log + fallback UI.
3. **No leaked component names** — server says `card`, client maps to `<Card>`. Renaming the component doesn't break the API.
4. **Side effects via actions** — `{ type: 'button', action: { kind: 'navigate', to: '/profile/123' } }`. Client interprets actions; server doesn't know about navigation libraries.
5. **Performance** — Renderer must be cheap; list virtualization (`FlashList`) is key when nodes are large.
6. **Caching** — pages cached locally; stale-while-revalidate flow.

Common architectures:
- **Pure SDUI** — entire screens are SDUI (Airbnb's Lottie-style approach for promo screens).
- **Hybrid** — shell is native React, content slots are SDUI (most production apps).
- **Component DSL** — server returns a more abstract DSL (e.g., a flexbox tree) and client interprets (more flexible, harder to type).

Backward compatibility patterns:
- Add new field → optional; old clients ignore.
- Remove field → leave it for N versions, then remove.
- Rename → ship both old + new for transition period.
- New `type` → fallback if unknown; ship client first, then server.

### The "Why"
- Slow app store reviews + slow user updates make UI changes weeks-long.
- A/B testing UI requires server flexibility.
- Marketing / merchandising teams want self-serve layout edits.

### Mental Model
SDUI = **JSON layout instructions**; client = **interpreter** with a fixed vocabulary; server is the author who can publish without rebuilds.

### Internal Working (2026 Context)
- 2026 patterns lean on **typed contracts**: server schema generated from a shared TS package; both sides validate.
- React Compiler memoizes the renderer tree well; SDUI is React-Compiler-friendly.
- AI-assisted layout generation tools produce SDUI JSON from designs.

### Modern Implementation (Code)

```ts
// Action handler (client-side)
type Action =
  | { kind: 'navigate'; to: string }
  | { kind: 'analytics'; event: string; params?: Record<string, unknown> }
  | { kind: 'open-url'; url: string };

function useActionHandler() {
  const router = useRouter();
  const analytics = useAnalytics();
  return useCallback((a: Action) => {
    switch (a.kind) {
      case 'navigate': router.push(a.to); return;
      case 'analytics': analytics.track(a.event, a.params); return;
      case 'open-url': Linking.openURL(a.url); return;
      default: { const _: never = a; }
    }
  }, [router, analytics]);
}
```

### Comparison

| Approach | Flexibility | Type safety |
|---|---|---|
| Static screens | Low | High |
| SDUI (typed registry) | Medium-high | High (with Zod) |
| WebView | High | Low |
| HTML render in RN | High | Low |

### Production Usage
- Home feeds (offers, banners) are SDUI.
- Onboarding flows can be A/B tested via SDUI.
- Settings menus that change frequently.

### Hands-On Exercise
1. Build a 4-component registry (`card`, `list`, `image`, `button`).
2. Hard-code a JSON page; render it.
3. Add Zod validation; intentionally corrupt the JSON; observe fallback.

### Common Mistakes
- Server returning React-specific names (couples server to client framework).
- No schema validation → silent renders of bad data.
- Unknown type crashing the app instead of fallback.
- Accessibility props not in schema → screen-reader broken.

### Production Red Flags
- Schema lacks `schemaVersion`.
- Renderer doesn't handle unknown types.
- Action handlers untyped.

### Performance & Metrics
- Renderer time per page (P50/P99).
- Schema validation cost at boundary.
- Cache hit rate for SDUI pages.

### Decision Framework
- Frequent UI iteration → SDUI for that surface.
- Static, animated, or accessibility-critical → native screens.
- Mix → hybrid.

### Senior-Level Insight
"SDUI is a contract more than a feature." Invest in schema versioning, validation, and a typed action protocol. Get those wrong and SDUI becomes a constant source of regressions.

### Real-World Scenario
**Symptom:** A schema deploy crashed the app for users on old binaries.
**Investigation:** New `type: 'carousel-v2'` introduced; old clients didn't know it.
**Fix:** Renderer falls back gracefully; backend gates new types via min app version.

### Production Failure Story
**Incident:** Home feed accessibility regressed after switching to SDUI.
**Root cause:** Schema didn't carry `accessibilityLabel`; old hand-written components had it.
**Fix:** Required a11y fields in schema; lint to enforce.

### Debugging Checklist
1. Is `schemaVersion` present and validated?
2. Does unknown `type` render a fallback?
3. Are actions typed (discriminated union)?
4. Is Zod at the boundary?

### Advanced / Internal Knowledge
- Use `z.discriminatedUnion('type', [...])` for typed nodes (one schema per type).
- Cache normalized pages in TanStack Query; renderer reads from cache.
- Server-side type generation from one source: TS → JSON schema → backend types.

### 2026 AI Tip
AI tools (v0, Magic Patterns) increasingly emit SDUI-shaped JSON. Validate before rendering.

### Related Topics
Q1, S08 (state), S21 (more SDUI patterns).

### Interview Follow-Up Questions
- "How do you handle unknown component types?"
- "Schema versioning strategy?"
- "How do you avoid coupling server to React?"

### Memory Hook
**"Server speaks JSON. Client interprets. Versioned, validated, fallback-ready."**

### Revision Notes
> SDUI = server returns typed component tree; client has registry + renderer; validate with Zod; version schema; unknown types fall back; actions are discriminated unions.

---

> Cross-refs: S01 (Zod), S05 (Expo), S08 (state), S15 (TurboModules), S20 (CI), S21 (SDUI deep dive).
