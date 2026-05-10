# S5 — Expo & Tooling

> Expo SDK 53+ · Expo Router v4 · Expo Modules API · Config Plugins · EAS Build/Update/Submit · CNG · Development Builds

In 2026, **Expo is the default React Native stack**, not "an alternative". Even Meta's official docs lead with `npx create-expo-app`. The bare workflow still exists for brownfield, but the modern decisions are about **how** you use Expo, not **whether** you use it. This section covers the six rounds you'll see most.

---

### Q1. Expo Router — file-based routing, layouts, typed routes

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Very Common (any new Expo app)

## Prerequisites
- React Navigation, file-based routing concepts (Next.js helpful)

## TL;DR
**Expo Router** is React Navigation under the hood with **file-based routing**, **typed routes** (TypeScript codegen), **layouts** (`_layout.tsx`), **route groups** `(group)`, **dynamic segments** `[id].tsx`, **shared routes**, and **deep linking out of the box**. v4+ supports **server components** and **typed search params**. Migration from React Navigation is mostly mechanical; the win is convention + deep linking + universal links + web parity.

---

## 30-Second Interview Answer

> "Expo Router is a file-based routing layer over React Navigation. The `app/` directory mirrors URLs: `app/profile/[id].tsx` becomes `/profile/123`. Layouts (`_layout.tsx`) wrap nested routes with a Stack/Tabs/Drawer navigator. Route groups `(tabs)` organize files without affecting URL. Dynamic segments and search params are typed when `experiments.typedRoutes` is on. Deep linking and universal links work without manual config. v4 added Server Components on supported platforms. Migration from React Navigation is mostly moving screens into files; the navigators stay the same conceptually."

---

## 2-Minute Practical Answer

**Folder layout**:
```
app/
  _layout.tsx              # root Stack
  index.tsx                # /
  (tabs)/
    _layout.tsx            # Tabs navigator
    home.tsx               # /home
    feed.tsx               # /feed
    profile/
      [id].tsx             # /profile/:id
      [id]/
        edit.tsx           # /profile/:id/edit
  (modal)/
    settings.tsx           # /settings (modal-presented)
  +not-found.tsx
```

**Layouts**:
```tsx
// app/_layout.tsx
import { Stack } from 'expo-router';
export default function RootLayout() {
  return <Stack screenOptions={{ headerStyle: { backgroundColor: '#111' } }} />;
}

// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
export default function TabsLayout() {
  return (
    <Tabs>
      <Tabs.Screen name="home" options={{ title: 'Home' }} />
      <Tabs.Screen name="feed" options={{ title: 'Feed' }} />
      <Tabs.Screen name="profile/[id]" options={{ href: null }} />
    </Tabs>
  );
}
```

**Typed routes** (in `app.json`):
```json
{ "expo": { "experiments": { "typedRoutes": true } } }
```
Then:
```tsx
import { Link, router } from 'expo-router';
<Link href={{ pathname: '/profile/[id]', params: { id: '42' } }}>Open</Link>
router.push({ pathname: '/profile/[id]', params: { id: '42' } });
// invalid path or wrong param → TS error
```

**Dynamic + search params**:
```tsx
// app/profile/[id].tsx
import { useLocalSearchParams } from 'expo-router';
export default function Profile() {
  const { id, tab } = useLocalSearchParams<{ id: string; tab?: string }>();
  return <Text>Profile {id} {tab}</Text>;
}
```

**Deep linking**:
- Set `scheme: 'myapp'` in `app.json`.
- Universal Links: `expo-router/web` config; iOS associated domains + Android assetlinks via Config Plugins.
- Test: `npx uri-scheme open myapp://profile/42 --ios`.

**Modal & route groups**:
- `(group)` parens = grouping, no URL effect.
- `app/(modal)/settings.tsx` + `_layout.tsx` with `presentation: 'modal'`.

**Shared routes** (one screen, multiple paths):
- `app/(tabs)/feed/[postId].tsx` and a re-export elsewhere — handy for tab persistence.

---

## 5-Minute Architecture Answer

Expo Router solved long-standing pain points:
- **Convention over config** — no more giant navigator tree files.
- **Deep linking by default** — every screen has a URL.
- **Universal apps** — same routes work on web (`expo-router/web`).
- **Typed navigation** — codegen produces `Href` union for autocomplete + safety.
- **Code splitting** (web) — per-route bundles.
- **Server Components support** (v4+, on supported platforms).

Under the hood:
- File system scanned at build time → route map generated.
- Each `_layout.tsx` defines a navigator (Stack/Tabs/Drawer/Slot).
- Renders into React Navigation; you can drop down to navigation imperatives if needed.
- Linking config auto-generated.

What it doesn't do:
- Not a state manager — pair with Zustand / Redux / TanStack Query.
- Not a server framework on native — server components are limited.
- Doesn't replace native nav primitives like iOS sheets — use platform-aware libs (`@gorhom/bottom-sheet`, `react-native-screens` v4 + sheet presentation).

The 2026 specific:
- **typed routes default-on** in new Expo apps.
- **`expo-router/build`** improved tree-shaking → smaller bundles.
- **Server Components in expo-router v4** (web first, RN preview).
- **Native Tabs / Native Stack** via `react-native-screens` v4 — fully native nav with Expo Router screens.
- **`Link` prefetch** (web) for hover / focus.
- **Static rendering** for web SEO.

Migration from React Navigation:
1. Install `expo-router`.
2. Move screens into `app/`.
3. Replace `<NavigationContainer>` + navigators with `_layout.tsx` files.
4. Replace `navigation.navigate('Profile', { id })` with `router.push('/profile/' + id)`.
5. Update deep-link handling: drop manual `Linking` parsing.

---

## The "Why"

Routing chaos kills feature velocity. File-based routing is convention; deep linking by default unlocks growth (links from web/email/share); typed routes catch broken paths at compile time. Companies care because it's **the** velocity multiplier for feature teams.

---

## Mental Model

`app/` is a URL tree on disk. Files = leaves (screens). Folders + `_layout.tsx` = navigators. Square brackets = dynamic. Parens = invisible grouping.

---

## Internal Working (2026 Context)

- Babel / Metro plugin scans `app/` → emits route manifest.
- TS codegen → `.expo/types/router.d.ts` declares `Href` union.
- React Navigation primitives wrap each layout.
- `expo-router/build/static` for web pre-render.

---

## Modern Implementation (Code)

**Auth-protected route group**:
```tsx
// app/(auth)/_layout.tsx
import { Redirect, Stack } from 'expo-router';
import { useAuth } from '@/auth';

export default function AuthLayout() {
  const { user } = useAuth();
  if (!user) return <Redirect href="/login" />;
  return <Stack />;
}
```

**Tabs with badge**:
```tsx
<Tabs.Screen name="inbox" options={{
  tabBarBadge: unread > 0 ? unread : undefined,
}} />
```

**Programmatic nav with typed params**:
```tsx
router.push({ pathname: '/checkout/[orderId]', params: { orderId } });
router.replace('/');
router.back();
```

**Modal presentation**:
```tsx
// app/_layout.tsx
<Stack>
  <Stack.Screen name="(tabs)" />
  <Stack.Screen name="settings" options={{ presentation: 'modal' }} />
</Stack>
```

---

## Comparison

| | Expo Router | React Navigation (manual) |
|---|---|---|
| Convention | file-based | code-based |
| Deep links | automatic | manual |
| Web | first-class | via react-native-web |
| Typed routes | yes | manual |
| Migration | small steps | n/a |

---

## Production Usage

- Default for new Expo apps.
- Works for tabs / drawers / nested stacks identically.
- Scales to 100+ screens without `RootNavigator.tsx` becoming a 2000-line file.

---

## Hands-On Exercise

1. Convert a 5-screen React Navigation app to Expo Router.
2. Add a dynamic `[id]` route.
3. Add an auth-gated `(auth)` group.
4. Configure universal links.

---

## Common Mistakes

- Putting state in `_layout.tsx` that should be in a context.
- Misusing `(group)` (forgetting parens are URL-invisible).
- Naming files with reserved chars.
- Not enabling `typedRoutes` (loses safety).

---

## Production Red Flags

- `useLocalSearchParams` without typing.
- Deep links not tested per platform.
- Custom linking config that conflicts with auto-generated.

---

## Performance & Metrics (MANDATORY)

- Cold-route nav: < 50ms.
- Bundle (web) per route: lazy-loaded.

---

## Decision Framework

| Need | Pick |
|---|---|
| New app | Expo Router |
| Brownfield small | React Navigation |
| Web + native shared | Expo Router (universal) |
| Heavy custom transitions | React Navigation imperative |

---

## Senior-Level Insight

Treat `app/` as your sitemap. Document URL structure in a single ADR. Senior teams add lint rules to prevent ad-hoc route strings (only typed `Href` allowed).

---

## Memory Hook
**"Files = URLs. Layouts = navigators."**

## Revision Notes
> Expo Router v4 = file-based routing on top of React Navigation. `[id]` dynamic, `(group)` invisible, `_layout.tsx` navigator. Typed routes for safety. Deep linking auto. Universal app support.

---

---

### Q2. Config Plugins — when, why, dangerous mods

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- iOS Info.plist / entitlements, Android manifest / Gradle basics

## TL;DR
**Config Plugins** mutate native project files during `prebuild` (CNG). Use them to inject Info.plist keys, entitlements, AndroidManifest entries, Gradle config, or copy files. They keep your repo "managed" — no need to commit `ios/` and `android/` folders. **Dangerous mods** (`withDangerousMod`) write arbitrary files; powerful but bypass Expo's parsing — use only when no typed mod exists.

---

## 30-Second Interview Answer

> "Config plugins are functions that take an Expo config and return modified versions of the underlying native projects. They run during `expo prebuild`. There are typed mods like `withInfoPlist`, `withAndroidManifest`, `withGradleProperties` that parse and re-emit native config; and `withDangerousMod` that lets you do raw filesystem writes. Use typed mods whenever possible — they're idempotent and merge-safe. Use dangerous mods only when no typed mod exists, like copying a `GoogleService-Info.plist` or patching a non-standard file. Most third-party libs ship their own plugin; you write one only when integrating a native lib that doesn't or when adding entitlements."

---

## 2-Minute Practical Answer

**When to write a plugin**:
- Library doesn't ship one (you have a native dependency that needs Info.plist or AndroidManifest changes).
- You need entitlements (Push, App Groups, HealthKit, Sign in with Apple).
- You ship a Notification Service Extension (NSE).
- You need custom Gradle / xcconfig changes.
- You need to copy a native file into the project.

**Plugin anatomy**:
```ts
// plugins/withMyConfig.ts
import { ConfigPlugin, withInfoPlist, withAndroidManifest } from '@expo/config-plugins';

const withMyConfig: ConfigPlugin<{ apiKey: string }> = (config, { apiKey }) => {
  config = withInfoPlist(config, (cfg) => {
    cfg.modResults.MY_API_KEY = apiKey;
    return cfg;
  });
  config = withAndroidManifest(config, (cfg) => {
    const app = cfg.modResults.manifest.application?.[0];
    app?.['meta-data']?.push({
      $: { 'android:name': 'MY_API_KEY', 'android:value': apiKey },
    });
    return cfg;
  });
  return config;
};

export default withMyConfig;
```

In `app.json`:
```json
{ "expo": { "plugins": [["./plugins/withMyConfig", { "apiKey": "abc" }]] } }
```

**Common typed mods**:
- `withInfoPlist`, `withEntitlementsPlist`, `withXcodeProject`, `withPodfile`, `withPodfileProperties`.
- `withAndroidManifest`, `withGradleProperties`, `withProjectBuildGradle`, `withAppBuildGradle`, `withStringsXml`, `withColors`.
- `withPlugins` (compose).

**Dangerous mods** (`withDangerousMod`):
```ts
import { withDangerousMod } from '@expo/config-plugins';
import fs from 'fs';
import path from 'path';

config = withDangerousMod(config, ['ios', async (cfg) => {
  const dest = path.join(cfg.modRequest.platformProjectRoot, 'GoogleService-Info.plist');
  await fs.promises.copyFile('./assets/GoogleService-Info.plist', dest);
  return cfg;
}]);
```
Use sparingly — they bypass merge logic.

**Idempotency**: typed mods are idempotent (re-running prebuild doesn't duplicate). Dangerous mods aren't unless you write them that way.

---

## 5-Minute Architecture Answer

Why CNG + plugins exist:
- Old Expo: managed (no native code, but limited) vs bare (full control, but you maintain `ios/`/`android/`).
- New Expo (CNG): you don't commit `ios/`/`android/`; they're regenerated from `app.json` + plugins on `prebuild`. Best of both — you have full native control via plugins, but the source of truth is your TypeScript config.

Plugin lifecycle:
1. `expo prebuild` reads `app.json`.
2. Walks plugin chain (each receives + returns config).
3. Writes resolved config back to native files.
4. Build proceeds (locally or on EAS).

Plugin patterns:
- **Library plugin**: ships with the npm package (e.g., `react-native-firebase` includes one).
- **App plugin**: in your repo's `plugins/` folder.
- **Plugin factory**: parameterized via options.

Dangerous mod risks:
- Not idempotent → reruns may corrupt.
- Bypass parsing → easier to write malformed XML/plist.
- Hard to compose with other plugins.
- Use only when no typed mod exists.

The 2026 specific:
- **Expo SDK 53+** added typed mods for previously-dangerous-only paths (e.g., AppDelegate Swift hooks).
- **`expo-modules-autolinking`** integrates plugins with the autolinking step.
- **EAS Build hooks** (`eas-build-pre-install`, etc.) supplement plugins for build-time-only ops.
- **CNG default** for new projects → committing `ios/`/`android/` is now the exception.

When NOT to write a plugin:
- Library has its own plugin → use it.
- Change is build-time only → use EAS Build hook.
- You're prototyping → eject to bare for one-off experimentation.

---

## The "Why"

Plugins keep teams managed-mode while still allowing arbitrary native config. Without them, every native dependency forces ejection. Companies care because plugins enable the "no ios/ android/ folder in repo" policy that scales to many engineers without merge conflicts.

---

## Mental Model

Plugin = pure function `(config) => modifiedConfig` that runs at prebuild. Typed = parsed + reserialized. Dangerous = raw fs.

---

## Internal Working (2026 Context)

- `@expo/config-plugins` provides parsers for each native file format.
- Mods are stacked; final config materialized at end.
- AsyncMods run with platform context (`modRequest.platformProjectRoot`, `projectRoot`).

---

## Modern Implementation (Code)

**Push notifications entitlement**:
```ts
import { ConfigPlugin, withEntitlementsPlist, withInfoPlist } from '@expo/config-plugins';

const withPush: ConfigPlugin = (config) => {
  config = withEntitlementsPlist(config, (cfg) => {
    cfg.modResults['aps-environment'] = 'production';
    return cfg;
  });
  config = withInfoPlist(config, (cfg) => {
    cfg.modResults.UIBackgroundModes = Array.from(new Set([
      ...(cfg.modResults.UIBackgroundModes ?? []), 'remote-notification',
    ]));
    return cfg;
  });
  return config;
};
```

**App Group (for shared MMKV)**:
```ts
config = withEntitlementsPlist(config, (cfg) => {
  cfg.modResults['com.apple.security.application-groups'] = ['group.com.example.app'];
  return cfg;
});
```

**Custom AppDelegate hook (Swift)**:
```ts
import { withAppDelegate } from '@expo/config-plugins';

config = withAppDelegate(config, (cfg) => {
  if (!cfg.modResults.contents.includes('MyAnalytics.start()')) {
    cfg.modResults.contents = cfg.modResults.contents.replace(
      'didFinishLaunchingWithOptions launchOptions: [',
      'didFinishLaunchingWithOptions launchOptions: [\n    MyAnalytics.start()'
    );
  }
  return cfg;
});
```

---

## Comparison

| Approach | Use |
|---|---|
| Typed mod | preferred |
| Dangerous mod | last resort |
| EAS Build hook | build-time scripts |
| Bare workflow | only for brownfield |

---

## Production Usage

- All major libs (RN-firebase, Sentry, RevenueCat, OneSignal, MMKV) ship plugins.
- Internal SDKs at large companies usually expose plugins to consuming apps.

---

## Hands-On Exercise

1. Write a plugin to add an iOS associated domain.
2. Add a Gradle property via plugin.
3. Migrate a manual `ios/` patch to a typed mod.
4. Compose multiple plugins safely.

---

## Common Mistakes

- Using dangerous mod where typed exists.
- Plugin not idempotent (duplicate keys on re-prebuild).
- Forgetting to handle both platforms.
- Not declaring plugin options TypeScript types.

---

## Production Red Flags

- 500-line `withDangerousMod`.
- Plugin that calls `exec()` of arbitrary scripts.
- No plugin tests.

---

## Performance & Metrics (MANDATORY)

- Plugin cost: prebuild time bump (usually < 1s per plugin).

---

## Decision Framework

| Native change needed | Way |
|---|---|
| Info.plist key | typed |
| Entitlement | typed |
| Copy file | dangerous mod |
| Patch arbitrary file | dangerous mod |
| Build-time only env | EAS hook |

---

## Senior-Level Insight

The mature take: **make plugins the only way native config changes**. Audit: any change to `ios/`/`android/` outside a plugin is a code-review red flag. Senior orgs publish internal plugins via npm package for shared SDK config.

---

## Memory Hook
**"Plugin = pure native config function."**

## Revision Notes
> Plugins mutate native config at prebuild. Typed mods preferred (idempotent, merge-safe). Dangerous mods only when needed. Most libs ship plugins. CNG = no committed `ios/`/`android/`.

---

---

### Q3. EAS Build profiles + credentials at scale

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- iOS code signing, Android keystore basics

## TL;DR
**EAS Build** runs builds on Expo's cloud (or self-hosted runners). **`eas.json` profiles** define environments (dev / preview / production / staging). **Credentials** managed by EAS or fetched from your secret store. **Custom workflows** (YAML) chain build/test/deploy steps. **Build hooks** run before/after install/build. Match each app version to a runtime version for OTA compatibility. **Cache strategy**: workspace cache for node_modules + Pods + Gradle for fast builds.

---

## 30-Second Interview Answer

> "EAS Build replaces local Xcode / Gradle for CI builds. `eas.json` declares profiles per environment with distribution channels, env vars, and credentials. Credentials are either managed by EAS (recommended for small teams) or pulled from your secret store. For multiple apps or white-label, parameterize via env vars and switch app.json fields at build time. Custom workflows (YAML) compose builds with tests/deploys. Cache node_modules, Pods, Gradle to keep builds fast. Pin Expo SDK + Node version per profile so reproducibility holds. EAS Submit pushes built artifacts to TestFlight / Play Console internal."

---

## 2-Minute Practical Answer

**`eas.json` example**:
```json
{
  "cli": { "version": ">= 12.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "channel": "development",
      "ios": { "simulator": true }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview",
      "env": { "API_URL": "https://staging.api.example.com" }
    },
    "production": {
      "channel": "production",
      "env": { "API_URL": "https://api.example.com" },
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {
      "ios": { "appleId": "ci@example.com", "ascAppId": "1234567890" },
      "android": { "track": "internal" }
    }
  }
}
```

**Profiles**:
- **development**: dev client + simulator builds + dev channel.
- **preview**: internal distribution (TestFlight or AdHoc) for QA.
- **staging / production**: store-bound; signed with prod credentials.

**Credentials**:
- iOS: Apple ID + ASC API key (best); managed certs by EAS or your own.
- Android: keystore stored in EAS or in your secret manager.
- For production: rotate ASC API keys; pin Apple team ID.

**Env vars / secrets**:
- `eas secret:create` for sensitive values.
- App-time env via `expo-constants` or `process.env` (with `dotenv` plugin).

**Custom build workflow** (YAML, EAS Workflows):
```yaml
name: Production
on: { push: { branches: [main] } }
jobs:
  test:
    type: npm
    command: pnpm test --ci
  build:
    needs: [test]
    type: build
    params: { profile: production, platform: all }
  submit:
    needs: [build]
    type: submit
    params: { profile: production, platform: all }
```

**Build hooks**:
- `eas-build-pre-install`, `eas-build-post-install`, `eas-build-pre-upload-artifacts`.
- Useful for fetching files from S3, generating sourcemaps, uploading to Sentry.

**Multi-app / white-label**:
- One repo, multiple `app.config.ts` flavors switched via env var.
- `EAS_BUILD_PROFILE` available at build time.

---

## 5-Minute Architecture Answer

EAS Build internals:
- Cloud builders: macOS (M-series for iOS) + Linux (Android).
- Job queue with priority tiers.
- Builders run `prebuild` → `pod install` / Gradle → archive → upload artifact + (optional) submit.
- Artifacts retained per plan tier.
- Workspace cache (node_modules, Pods, Gradle) speeds incremental builds.

Credentials flow:
- iOS: EAS-managed certs + provisioning profiles, or your own via .p12 + .mobileprovision.
- Android: keystore stored encrypted in EAS or fetched at build time.
- Best practice: ASC API keys (App Store Connect) over Apple ID for automation.

Multi-environment patterns:
- **Channels**: OTA channel (production/preview/dev) decoupled from build profile.
- **Branches** (EAS Update): runtime-version-bound; rollback by re-pointing channel to a branch.
- **Runtime versions**: bump on native change; OTA updates only flow within same runtime.

Self-hosted runners (2026):
- For regulated companies: run EAS jobs on your own macOS / Linux infra; same EAS API.
- Useful for IP / compliance / cost.

CI integration:
- GitHub Actions / GitLab CI invokes `eas build` via service account token.
- EAS Workflows = native EAS-side orchestration; no external CI needed.

The 2026 specific:
- **EAS Workflows v2** with reusable jobs.
- **Self-hosted runners** for enterprise.
- **macOS M-series builders** default; ARM-native faster.
- **`eas update --auto`** for fully-automated OTA flow.
- **Sentry / Datadog plugins** for sourcemap upload during build.

What goes wrong at scale:
- Credential drift across teams → centralize.
- Profile sprawl → 10+ profiles unmanageable; consolidate by env, parameterize the rest.
- Slow builds → enable workspace cache, prune deps, profile install times.

---

## The "Why"

Build infrastructure is invisible until it's broken. Bad EAS config = release-blocked teams. Companies care because mobile release cadence is bottlenecked by build/credential hygiene.

---

## Mental Model

EAS Build = managed CI for Expo. Profiles = configurations. Channels = OTA delivery. Workflows = the orchestration layer.

---

## Internal Working (2026 Context)

- Builders run in clean VMs per job.
- Caching keyed on lockfile + Podfile.lock + Gradle wrapper.
- Artifacts uploaded to Expo CDN + retained per plan.
- Submission uses ASC API for iOS, Play Developer API for Android.

---

## Modern Implementation (Code)

**Dynamic app config (multi-flavor)**:
```ts
// app.config.ts
import 'dotenv/config';
const flavor = process.env.APP_FLAVOR ?? 'production';
export default ({ config }) => ({
  ...config,
  name: flavor === 'staging' ? 'Acme Staging' : 'Acme',
  ios: { ...config.ios, bundleIdentifier:
    flavor === 'staging' ? 'com.acme.staging' : 'com.acme.app' },
  android: { ...config.android, package:
    flavor === 'staging' ? 'com.acme.staging' : 'com.acme.app' },
});
```

**Pre-install hook (`package.json`)**:
```json
{ "scripts": {
  "eas-build-pre-install": "node ./scripts/fetch-secrets.js"
} }
```

**Sentry sourcemap upload (post-build)**:
```yaml
- name: upload-sourcemaps
  type: shell
  command: npx sentry-expo upload-sourcemaps
```

---

## Comparison

| Build platform | Pros |
|---|---|
| EAS Build | turnkey, plugins-aware |
| GitHub Actions self-hosted Mac | cheap at scale, full control |
| Bitrise | mature mobile CI |
| Codemagic | similar |

---

## Production Usage

- Most Expo apps use EAS Build.
- Larger orgs run self-hosted runners.
- Even bare apps can use EAS Build via `--non-interactive`.

---

## Hands-On Exercise

1. Write `eas.json` for dev/preview/production with channel mapping.
2. Add an iOS App Store Connect API key.
3. Implement multi-flavor `app.config.ts`.
4. Compose an EAS Workflow with test → build → submit.

---

## Common Mistakes

- Storing certs in repo.
- Not pinning Node / Expo SDK per profile (drift).
- Forgetting `autoIncrement` for production.
- Mismatching channel and runtimeVersion.

---

## Production Red Flags

- Credentials in plaintext env vars.
- Same profile for staging + prod.
- Manual builds after CI broken.

---

## Performance & Metrics (MANDATORY)

- iOS build: ~10–25 min cold; ~5–10 min cached.
- Android build: ~8–15 min.

---

## Decision Framework

| Need | Pick |
|---|---|
| Small team | EAS Cloud + managed creds |
| Enterprise | EAS Self-hosted |
| Multi-flavor | dynamic app.config.ts |
| Reproducibility | pin SDK + Node + Pod versions |

---

## Senior-Level Insight

Treat builds as code: version-control `eas.json`, lock SDK + Node + Pod versions, automate cred rotation. Senior teams maintain a release-engineering on-call rotation.

---

## Memory Hook
**"Profiles + channels + credentials, all in eas.json."**

## Revision Notes
> EAS Build runs cloud (or self-hosted) builds. Profiles per env; channels for OTA; credentials managed/synced. Workflows orchestrate. Build hooks for sourcemaps / secrets. Pin SDK + Node for repro.

---

---

### Q4. EAS Update — channels, branches, runtime versions, rollback

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- App store rules around OTA, runtime versions

## TL;DR
**EAS Update** ships JS + assets OTA without app store review. Each build subscribes to a **channel** (e.g., production); a channel points to a **branch** (e.g., `release-2.3.x`); branch holds **updates** keyed by **runtime version**. Update only delivers when runtime version matches. **Rollback** = re-point channel to previous branch (instant). Compliance: only JS + assets; native changes still need a store release. Always staged: percentage rollout → canary → full.

---

## 30-Second Interview Answer

> "EAS Update is OTA delivery for JS + assets. A build is bound to a channel; a channel points to a branch; a branch publishes updates keyed by runtime version. Runtime version usually matches a native build; bump it when native changes. Rollback = repoint the channel to the prior branch — instant, no rebuild. Always staged with percentage rollouts and canary checks; integrate with Sentry/Datadog to gate. Apple/Google rules require updates to be 'consistent with the original purpose' — no behavior changes that violate review."

---

## 2-Minute Practical Answer

**Concepts**:
- **Build**: native binary + JS bundle.
- **Runtime version**: a string identifying native compatibility (e.g., `1.0.0`, `exposdk:53.0.0`, or `appVersion`). Bump when native changes.
- **Channel**: like a "release track" the app subscribes to (e.g., `production`).
- **Branch**: a stream of updates (e.g., `release-2.3.x`). Channel → branch mapping.
- **Update**: a published JS+assets bundle.

**Flow**:
```
Build (channel=production, runtimeVersion=1.0.0)
   │
   │ subscribes
   ▼
Channel: production ──points─▶ Branch: release-1.0.x
                                 │
                                 ▼
                              Update v1.0.4 (runtimeVersion 1.0.0)
                              Update v1.0.5 (runtimeVersion 1.0.0)
```

**Publish**:
```bash
eas update --branch release-1.0.x --message "fix login bug"
```

**Rollback**:
```bash
eas channel:edit production --branch release-1.0.x-previous
```

**Runtime version policy**:
- `appVersion`: bumps every app version.
- `sdkVersion`: bumps with Expo SDK.
- `nativeVersion`: manual; you bump on native change.
- Custom string: full control.

**Staged rollout**:
- EAS Update supports % rollout per branch.
- Canary build → 1% → 10% → 50% → 100% with metric gates.

**Compliance**:
- Apple: updates must be "consistent with metadata" — no surprise behaviors.
- Google: similar (Play Policy).
- No native changes; no entitlements changes.
- For React Native: avoid changing visible IAP / login flows mid-cycle.

**Integration**:
- Sentry sourcemap upload at update time.
- Telemetry to verify download success rate.
- Update success metrics to gate rollout.

---

## 5-Minute Architecture Answer

How OTA actually works:
1. App starts, contacts EAS Update server with channel + runtime version.
2. Server checks: does branch have a newer update for this runtime version?
3. If yes: app downloads bundle in background; applies on next launch.
4. If `expo-updates.checkAutomatically: ON_LOAD`, may apply same launch.

Why runtime version matters:
- JS bundle assumes specific native modules + APIs.
- Mismatch → crash. Runtime version is the contract.
- Bump on any native change (new lib, new entitlement, new module).

Branch / channel design:
- **One branch per release line**: `release-1.0.x`, `release-1.1.x`. New native release = new branch.
- **Channels stable**: `production`, `staging`, `preview`. Map to branches.
- **Atomic flip** for rollback: change channel→branch mapping.

Rollout strategy:
1. Publish update to a "canary" channel first.
2. Internal QA validates.
3. Promote to small % of production.
4. Monitor crash-free, telemetry, support volume.
5. Ramp to 100% over hours/days.

Failure modes:
- **Bundle download fails**: app keeps using cached bundle. No regression.
- **Bundle parses but crashes on launch**: `expo-updates` reverts to last working bundle (rollback-on-launch).
- **Native mismatch (runtime version)**: bundle skipped; app uses embedded.

The 2026 specific:
- **EAS Update** with **branch promotion API** for granular rollout.
- **`expo-updates` v5+** with built-in rollback-on-error.
- **Auto-rollback** on crash spike (with Sentry/Datadog integration).
- **Update size limits** enforced (apps >50MB JS get warned).

What OTA can't do:
- Add/remove native modules.
- Change entitlements.
- Change Info.plist.
- Update assets that natives consume (icons, splash).

---

## The "Why"

OTA fixes hot bugs in hours, not days. Without it, every JS bug = full store cycle. Companies care because mean-time-to-recovery for mobile crashes drops from days to hours.

---

## Mental Model

OTA = JS hot-swap. Channel + branch + runtime version is the routing table.

---

## Internal Working (2026 Context)

- Updates served via CDN (Expo or your origin).
- App caches latest + previous bundle.
- Rollback-on-error: if launch crashes within N seconds, revert to previous.
- Sourcemaps uploaded to Sentry per update for symbolication.

---

## Modern Implementation (Code)

**Update check at launch**:
```ts
import * as Updates from 'expo-updates';

async function checkForUpdate() {
  if (__DEV__) return;
  try {
    const r = await Updates.checkForUpdateAsync();
    if (r.isAvailable) {
      await Updates.fetchUpdateAsync();
      await Updates.reloadAsync();
    }
  } catch (e) {
    log.error('update.check.failed', e);
  }
}
```

**Manual rollback (CLI)**:
```bash
eas channel:edit production --branch release-1.0.x-rollback
```

**Staged rollout (CLI)**:
```bash
eas update --branch release-1.0.x --rollout-percentage 5
# verify metrics, then bump
eas channel:edit production --rollout-percentage 25
```

---

## Comparison

| OTA tool | Notes |
|---|---|
| EAS Update | first-class for Expo |
| CodePush [DEPRECATED 2024] | retired |
| Custom (S3+Updates protocol) | possible; reinventing |

---

## Production Usage

- Almost universal in Expo apps.
- Bare RN apps can also use `expo-updates` standalone.

---

## Hands-On Exercise

1. Publish an update to a branch.
2. Promote canary → production with rollout.
3. Roll back via channel edit.
4. Wire Sentry sourcemap upload.

---

## Common Mistakes

- Bumping runtime version every release (defeats purpose).
- Not bumping when native changes (crashes).
- Pushing native-touching JS in OTA (can crash).
- No staged rollout (full blast).

---

## Production Red Flags

- No telemetry on update apply.
- No rollback runbook.
- Sourcemaps not uploaded.

---

## Performance & Metrics (MANDATORY)

- Update download P95: < 5s.
- Update apply: < 1s on next launch.
- Update success rate: > 99%.

---

## Decision Framework

| Change | OTA? |
|---|---|
| JS bug fix | yes |
| Asset swap | yes |
| New native lib | no — store release |
| Entitlement change | no |
| Major behavior | borderline; review compliance |

---

## Senior-Level Insight

Treat OTA as "deployment", not "feature toggle". Use feature flags for behavior gating. OTA for code; flags for behavior. Senior teams have an "OTA charter" with rules.

---

## Memory Hook
**"Channel → branch → runtime version → update."**

## Revision Notes
> EAS Update ships JS+assets OTA. Build subscribes to channel; channel→branch; branch publishes updates keyed by runtime version. Bump runtime version on native change. Rollback = re-point channel. Stage rollouts; gate on telemetry.

---

---

### Q5. CNG / prebuild and brownfield integration

---

## Difficulty
- Advanced

## Interview Frequency
- Common (any team migrating)

## Prerequisites
- Native iOS/Android project structure

## TL;DR
**CNG (Continuous Native Generation)** = `ios/` and `android/` are not in the repo; they're regenerated from `app.json` + plugins via `expo prebuild`. Source of truth is your TS config. **Brownfield** (embedding RN in an existing native app) is supported via **`react-native-brownfield`** patterns; full Expo CNG isn't always feasible — you may need bare workflow with selective Expo modules. Key migration paths: bare RN → Expo CNG; brownfield → RN library.

---

## 30-Second Interview Answer

> "CNG means native projects are generated, not committed. `expo prebuild` reads `app.json` + plugins → emits `ios/` + `android/`. You delete those folders from git. Benefits: SDK upgrades are non-events, plugin-based native config, no merge conflicts. Brownfield is the opposite case — existing native app with embedded RN. There you keep native projects, install RN as a dependency, integrate via `RCTRootView` / `ReactInstanceManager`, and use bare workflow. Mixing CNG with brownfield isn't supported — pick one."

---

## 2-Minute Practical Answer

**CNG (greenfield Expo)**:
```bash
npx create-expo-app
# ios/ and android/ are NOT created
# add to .gitignore: ios/, android/
expo prebuild  # regenerate when needed (rare)
```
Native config flows through plugins. Upgrades:
```bash
expo install expo@latest
expo prebuild --clean
```

**Brownfield (existing native app + RN)**:
- Native project owns top-level lifecycle.
- RN is a library, embedded as `RCTRootView` (iOS) or `ReactRootView` (Android).
- Manage RN bundles via Metro server (dev) or pre-bundled JS (prod).
- Use `react-native-brownfield` helpers + manual Pod / Gradle integration.
- Avoid Expo SDK assumptions; selectively use Expo modules that work standalone.

**Migration paths**:
- **Bare RN → Expo CNG**: install `expo`, run `expo prebuild`, move config to `app.json`, delete old native projects, regenerate.
- **Brownfield → standalone RN app**: usually wrap with Expo over time.
- **CNG → Bare** (escape hatch): `expo prebuild` once, commit `ios/`/`android/`, work bare.

**When CNG breaks down**:
- Highly customized native code (custom Xcode targets, Gradle modules).
- Brownfield (multiple RN instances in one app).
- Apps with pre-existing native infra.

In those cases: bare workflow + selective Expo modules.

---

## 5-Minute Architecture Answer

CNG philosophy: **declarative native config**. Your repo contains:
- `app.json` / `app.config.ts` — manifest.
- `plugins/` — native modifications.
- `package.json` — JS deps.
- Source code.

What's NOT in repo: `ios/`, `android/`, lock files for those.

Benefits:
- SDK upgrades = bump version, run prebuild.
- No merge conflicts in Xcode project files.
- Plugins are reusable across apps.
- `eas build` regenerates fresh per build.

Tradeoffs:
- Local debugging requires `prebuild` to materialize natives.
- Some advanced native customizations need plugin work upfront.
- Less obvious "where" to add native code — answer: a plugin.

Brownfield architecture:
- Existing app (Swift/Obj-C/Kotlin/Java) embeds RN as feature.
- RN bundle loaded for specific screens/flows.
- Communication: native ↔ RN via TurboModules / Native Events.
- Multiple RN instances: possible but expensive (one JS runtime per).
- 2026 advances: **Bridgeless mode** + **Interop Layer** make brownfield embedding cleaner.

When brownfield is right:
- Existing big native app, gradually migrating.
- Compliance / IP requires native ownership.
- Specific perf-critical screens stay native.

When brownfield is wrong:
- Greenfield → just use Expo.
- Small app → full RN simpler.

The 2026 specific:
- **Bridgeless RN** simplifies brownfield: cleaner module boundaries.
- **Expo SDK 53+** supports brownfield via dedicated docs path.
- **`expo prebuild --clean`** safer than ever (idempotent under typed mods).
- **`expo-modules-core`** can be embedded in brownfield apps.

Migration playbook (bare → CNG):
1. `npm i expo`.
2. Run `expo prebuild` → diff against current `ios/`/`android/`.
3. Capture diffs as plugins.
4. Iterate until prebuild output matches current.
5. Delete `ios/`/`android/` from repo; rely on `prebuild`.
6. Update CI to run `prebuild` before native build.

---

## The "Why"

CNG is the velocity multiplier — SDK upgrades go from "week-long ordeal" to "afternoon". Brownfield matters because not every company can rewrite — Expo's commitment to brownfield keeps RN viable for big enterprises. Companies care because integration model = team velocity.

---

## Mental Model

CNG: native is a build artifact. Brownfield: RN is a guest in a native house.

---

## Internal Working (2026 Context)

- `expo prebuild` invokes `@expo/cli` which composes plugins → writes natives.
- Plugins resolved from `app.json` `plugins` array (and from each installed package's `app.plugin.js`).
- For brownfield: RN is initialized via `RCTBridge` (legacy) or `RCTHost` (Bridgeless).

---

## Modern Implementation (Code)

**Brownfield iOS embed**:
```swift
let host = RCTHost(
  bundleURLProvider: { Bundle.main.url(forResource: "main", withExtension: "jsbundle")! },
  moduleProvider: nil,
  launchOptions: nil
)
let view = RCTHost.surface(forModuleName: "MyFeature", initialProps: nil)
viewController.view = view
```

**Brownfield Android embed**:
```kt
val rootView = ReactRootView(this)
val host = ReactHost.create(application)
host.start()
rootView.startReactApplication(host, "MyFeature", launchOptions)
setContentView(rootView)
```

**Plugin replacing manual Xcode change**:
```ts
import { withXcodeProject } from '@expo/config-plugins';
config = withXcodeProject(config, (cfg) => {
  cfg.modResults.addBuildPhase([], 'PBXShellScriptBuildPhase', 'Sentry', null, {
    shellScript: '"${SRCROOT}/../node_modules/sentry-expo/upload-sourcemaps.sh"',
  });
  return cfg;
});
```

---

## Comparison

| Approach | When |
|---|---|
| CNG | greenfield, small/mid native customization |
| Bare workflow | heavy native customization |
| Brownfield | existing big native app |

---

## Production Usage

- **Most new apps**: CNG.
- **Banks / large enterprises**: brownfield often.
- **Migration in progress**: bare workflow as transition.

---

## Hands-On Exercise

1. Convert a bare RN app to CNG.
2. Embed an RN screen into a Swift app via `RCTHost`.
3. Write a plugin to replicate a manual Xcode tweak.

---

## Common Mistakes

- Committing `ios/`/`android/` while using CNG (state drift).
- Editing generated files (lost on next prebuild).
- Brownfield with two RN instances accidentally (memory bloat).
- Not running `prebuild --clean` after big changes.

---

## Production Red Flags

- `ios/`/`android/` in `.gitattributes` for both CNG and bare.
- Manual Xcode edits not captured as plugin.
- Brownfield with > 1 RN instance per process.

---

## Performance & Metrics (MANDATORY)

- `prebuild` time: ~10–60s.
- Brownfield RN init: ~200–500ms (Bridgeless faster).

---

## Decision Framework

| Situation | Pick |
|---|---|
| New consumer app | CNG |
| Heavy native bespoke | Bare |
| Existing big native | Brownfield |
| White-label many apps | CNG + dynamic config |

---

## Senior-Level Insight

CNG matures organizations: it forces native config to be declarative + reviewable. Senior teams treat "we manually edited Xcode" as a bug.

---

## Memory Hook
**"CNG = native is generated. Brownfield = RN is guest."**

## Revision Notes
> CNG: `ios/`/`android/` not in repo; `expo prebuild` regenerates. Plugins capture native config. Brownfield: existing native app embeds RN via `RCTHost` / `ReactHost`. Bridgeless makes brownfield cleaner. Don't mix.

---

---

### Q6. Expo Modules API vs writing a TurboModule

---

## Difficulty
- Advanced

## Interview Frequency
- Common (any custom native work)

## Prerequisites
- TurboModules (S15), Swift / Kotlin basics

## TL;DR
**Expo Modules API** is a Swift/Kotlin DSL for writing native modules — concise, type-safe, autolinking, plugin-aware. **TurboModules** are the lower-level RN primitive — more boilerplate, but full control. Pick **Expo Modules** for almost everything new in 2026; pick **TurboModules** when you need the absolute lowest level (e.g., custom JSI bindings, performance-critical paths). Expo Modules compile to TurboModules under the hood in modern versions.

---

## 30-Second Interview Answer

> "Expo Modules API is the high-level Swift/Kotlin DSL — you write a `Module` class with `Function` / `AsyncFunction` / `Property` / `View` declarations, and Expo wires it to JS automatically. TurboModules are the underlying RN primitive — you write a Codegen spec, then implement the protocol per platform. Expo Modules compile to TurboModules underneath in 2026, so you get TurboModule perf with much less code. Pick Expo Modules for anything new; drop to TurboModules only when you need raw JSI access or are integrating an existing native lib that has a Codegen spec."

---

## 2-Minute Practical Answer

**Expo Module example (Swift)**:
```swift
import ExpoModulesCore

public class HapticsModule: Module {
  public func definition() -> ModuleDefinition {
    Name("Haptics")

    Function("notify") { (kind: String) in
      let g = UINotificationFeedbackGenerator()
      switch kind {
        case "success": g.notificationOccurred(.success)
        case "error":   g.notificationOccurred(.error)
        default:        g.notificationOccurred(.warning)
      }
    }

    AsyncFunction("getDeviceCheckToken") { () -> String in
      return try await DeviceCheckHelper.token()
    }

    Property("isSupported") {
      UIDevice.current.userInterfaceIdiom == .phone
    }
  }
}
```

JS side:
```ts
import { requireNativeModule } from 'expo-modules-core';
const Haptics = requireNativeModule('Haptics');
Haptics.notify('success');
const token = await Haptics.getDeviceCheckToken();
```

**TurboModule equivalent**: ~3× more code (Codegen TS spec, ObjC protocol, Swift impl, registration).

**When to pick TurboModule**:
- Need direct JSI host object (custom raw bindings).
- Wrapping an existing native lib that ships with TurboModule already.
- Extreme perf path where every overhead matters.

**When to pick Expo Module**:
- Almost everything else.
- Need plugin (config-plugin integration is built in).
- Want to ship as npm package easily.

---

## 5-Minute Architecture Answer

Expo Modules API design:
- DSL inspired by SwiftUI / Compose.
- Reflects on declarations to generate bindings.
- Compiles to TurboModule (Bridgeless-compatible) underneath.
- Built-in:
  - **Functions**: sync.
  - **AsyncFunctions**: returns Promise.
  - **Properties**: getter for constants.
  - **Events**: native → JS event emitter.
  - **Views**: native UI components with prop bindings.
  - **OnCreate / OnDestroy lifecycle**.
- Type-safe across platforms (records map to TS types).
- Autolinking via `expo-modules-autolinking`.

TurboModule API:
- Codegen TS spec → C++ headers.
- Per-platform implementation (ObjC protocol, Java/Kotlin interface).
- Manual JNI for Android C++ bridges.
- Wired in via `RCTHost` (Bridgeless).
- Lower level → more flexibility but more boilerplate.

When to write either:
- New custom feature: Expo Module.
- Wrapping existing OSS lib: depends — if lib ships TurboModule spec, use that; if not, Expo Module.
- Performance-critical custom path: profile both; usually no difference.

The 2026 specific:
- **Expo Modules v3+** fully Bridgeless-native.
- **View component DSL** matured — Fabric component generation built in.
- **Cross-platform records** (Swift / Kotlin / TS) auto-mapped.
- **`requireNativeView`** for Fabric components.
- **Static Hermes** + Expo Modules = sub-ms native call overhead.

Migration:
- Old RN bridge module → Expo Module: rewrite `Module` definition, drop bridge boilerplate.
- TurboModule → Expo Module: usually a clean rewrite, simpler.

---

## The "Why"

Native modules are where many bugs and slow features hide. Expo Modules' DSL cuts code by 3–5×, which means fewer bugs, faster reviews, easier maintenance. Companies care because native module velocity is an under-discussed engineering bottleneck.

---

## Mental Model

Expo Modules = high-level declarative DSL. TurboModule = low-level imperative primitive. Both end up running through TurboModule infrastructure.

---

## Internal Working (2026 Context)

- Expo Modules generates Codegen-equivalent bindings at build time.
- View modules participate in Fabric.
- Async functions execute on a worker queue; results delivered to JS via JSI.
- Events bridged via `EventEmitter` infrastructure.

---

## Modern Implementation (Code)

**Native View (iOS)**:
```swift
import ExpoModulesCore

public class MyMapModule: Module {
  public func definition() -> ModuleDefinition {
    Name("MyMap")

    View(MyMapView.self) {
      Prop("region") { (view: MyMapView, region: Region) in
        view.set(region: region)
      }

      Events("onRegionChange")

      AsyncFunction("zoomTo") { (view: MyMapView, level: Double) in
        view.zoom(to: level)
      }
    }
  }
}

class MyMapView: ExpoView {
  let onRegionChange = EventDispatcher()
  // ... map impl
}

struct Region: Record {
  @Field var lat: Double
  @Field var lng: Double
  @Field var zoom: Double
}
```

JS:
```tsx
import { requireNativeView } from 'expo-modules-core';
const MyMap = requireNativeView('MyMap');

<MyMap region={{ lat, lng, zoom }} onRegionChange={(e) => ...} />
```

**Plugin alongside module**:
```ts
const withMyMap: ConfigPlugin = (config) => {
  config = withInfoPlist(config, (cfg) => {
    cfg.modResults.NSLocationWhenInUseUsageDescription = 'Show your location.';
    return cfg;
  });
  return config;
};
```

---

## Comparison

| | Expo Modules API | TurboModule |
|---|---|---|
| Boilerplate | low | high |
| Type safety | yes | yes |
| Plugin integration | seamless | manual |
| Bridgeless | yes | yes |
| Best for | most cases | low-level / perf-critical |

---

## Production Usage

- Most modern Expo native modules.
- Bare RN apps can use Expo Modules too (via `expo-modules-core`).
- Many libs have switched (RN-firebase migrating, RevenueCat, Sentry, etc.).

---

## Hands-On Exercise

1. Write an Expo Module for haptics.
2. Add a Fabric view component.
3. Convert a TurboModule example to Expo Module.

---

## Common Mistakes

- Async function on UI thread (slows app).
- Returning non-Record types (won't serialize).
- Forgetting `OnDestroy` cleanup.
- Skipping platform parity (iOS only).

---

## Production Red Flags

- Module without tests.
- No plugin for required config.
- Sync function doing heavy work.

---

## Performance & Metrics (MANDATORY)

- Native call overhead: < 1ms.
- View prop update: < 1 frame.

---

## Decision Framework

| Need | Pick |
|---|---|
| Standard native feature | Expo Module |
| Custom JSI binding | TurboModule |
| Existing TM-based lib | TurboModule |
| Cross-platform parity | Expo Module |

---

## Senior-Level Insight

The mature take: **standardize on Expo Modules** unless a strong reason otherwise. Senior teams maintain an internal Expo Module pack for company-specific SDKs.

---

## Memory Hook
**"DSL above, TurboModule below."**

## Revision Notes
> Expo Modules = Swift/Kotlin DSL; compiles to TurboModule. TurboModule = lower-level RN primitive. Pick Expo Modules for almost all new work; TurboModule only for raw JSI / performance edge cases. Both work in Bridgeless.

---

> **End of S5.** Cross-refs: [appendix J](../appendix/J-expo-router-config-plugins.md), [S20 CI/CD](S20-cicd-releases.md), [S15 native bridging](S15-native-bridging.md), [S04 New Architecture](S04-new-architecture.md). Next deep section per priority: [S12 Push & Background](S12-push-background.md).
