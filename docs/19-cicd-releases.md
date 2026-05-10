## 19. CI/CD, EAS, Fastlane, releases

### Fastlane
- `fastlane match` for cert/profile sync (encrypted git repo).
- Lanes: `build`, `beta`, `release`.
- Plugins: changelog, slack, sentry-cli upload.

### GitHub Actions / Bitrise
- macOS runners for iOS builds.
- Cache `node_modules`, Pods, Gradle.
- Parallel jobs: lint, test, build per platform.

### EAS (Expo Application Services)
- **EAS Build**: cloud builds for iOS/Android, no local Xcode/Android Studio needed.
- **EAS Update**: OTA JS updates per channel (preview/production).
- **EAS Submit**: uploads to stores.
- **Config plugins**: modify native config without ejecting (`app.json` extras).

### OTA (over-the-air) policy
- **Safe**: JS/asset changes, bug fixes, copy edits, feature flags.
- **NOT safe**: native module changes, permissions, native deps. Requires store build.
- **Apple rules**: OTA must not alter app's primary purpose / bypass review.

### Release strategy
- **Staged rollout**: Play Console (1/5/10/25/50/100%), TestFlight groups, then App Store phased.
- **Sentry release health gate**: halt rollout if crash-free sessions < 99.5%.
- **Feature flags** (Statsig/LaunchDarkly/GrowthBook) decouple release from launch.

### Code signing
- **iOS**: cert + provisioning profile per env (dev/adhoc/appstore). Match handles rotation.
- **Android**: keystore (`.jks` or `.keystore`) — back up offline. Play App Signing recommended.

### Must-answer questions
1. End-to-end release pipeline walkthrough.
2. What's safe vs not safe via OTA.
3. Bad release rollback.
4. Manage secrets in CI.
5. EAS vs Fastlane — when each.

---



---

## Top 25 Q&A — CI/CD, EAS, Fastlane, releases

### 1. EAS vs Fastlane vs in-house?
- **EAS Build/Submit**: managed, great for Expo + bare. Fast, no infra.
- **Fastlane**: full control, runs on your CI, scriptable.
- In-house Bitrise/CircleCI/GH Actions: most control, more maintenance.

### 2. Typical mobile CI pipeline.
Lint → typecheck → unit + RNTL → bundle JS → build iOS + Android → upload artifacts → run Detox/Maestro → submit to TestFlight/Play Internal.

### 3. Code signing — iOS (cert + profile).
Apple Developer cert + provisioning profile. Use Fastlane Match (encrypted git repo) or EAS automatic credentials.

### 4. Android signing.
Generate upload keystore (one per app), keep encrypted in CI. Play App Signing manages release keys after upload.

### 5. Versioning strategy.
`marketingVersion` (1.4.2) + `buildNumber` (auto-incremented). Sync between iOS + Android via single source (e.g. `package.json` or `version.json`).

### 6. Release branches?
Trunk-based + release tags is common. For complex apps, short-lived `release/x.y` branches with hotfix flow.

### 7. Phased / staged rollout.
Play: 1% → 5% → 20% → 50% → 100% over days, monitor crash rate. App Store Connect: phased release option (7 days).

### 8. Hot updates / OTA — when allowed?
**JS-only** changes via EAS Update / CodePush. Cannot change native code, native config, or alter purpose materially. App Store Guideline 4.2.6 / Play allow with caveats.

### 9. CodePush vs EAS Update?
CodePush (Microsoft AppCenter) — being sunset. EAS Update is the modern replacement; works on bare RN too.

### 10. Rollback strategy.
EAS Update: republish previous bundle, or use channel rollback. Always keep last 2 builds in TestFlight/Internal for emergency revert.

### 11. Secrets in CI.
Encrypted env vars (GH Actions Secrets, EAS Secrets). Never commit `.env`. Pass to build via `EXPO_PUBLIC_*` for safe-to-expose.

### 12. iOS build numbers — strategy.
`buildNumber = CI build counter` to guarantee monotonic. Apple rejects same buildNumber for given marketing version.

### 13. Android `versionCode` strategy.
Integer, monotonically increasing. Common: `major*10000 + minor*100 + patch`. Or CI build number directly.

### 14. EAS Build profiles.
`development` (dev client), `preview` (internal distribution), `production`. Different env vars + signing per profile.

### 15. Fastlane lane example.
```ruby
lane :beta do
  match(type: 'appstore')
  build_app(scheme: 'MyApp')
  upload_to_testflight(skip_waiting_for_build_processing: true)
end
```

### 16. Build cache strategy.
Cache `node_modules`, `~/.gradle`, CocoaPods. iOS: Xcode derived data harder to cache (uses paths). EAS handles automatically.

### 17. Crash on first install but not in TestFlight build?
Likely missing release-only ProGuard rule, missing Hermes config diff, or signing/keychain ACL. Compare debug vs release build configs.

### 18. App Store / Play submission metadata in CI?
Fastlane `deliver` (App Store), `supply` (Play). Manage screenshots, description in repo as source of truth.

### 19. Preview builds for PRs.
EAS Update channel per PR + QR code. Reviewers test on real device without building.

### 20. Mac runners cost?
Expensive. Alternatives: self-hosted Mac mini (Tart), MacStadium, EAS (managed cost). Run iOS only on PRs that need it.

### 21. Android build performance.
Enable Gradle daemon, parallel, configure-on-demand, use Gradle build cache, increase heap. Use R8 over ProGuard (default modern).

### 22. iOS `pod install` slow on CI.
Cache `Pods/` + `Podfile.lock` based on lockfile hash. Use `cocoapods --repo-update` only when needed.

### 23. Source maps upload.
After bundling JS, upload source maps to Sentry/Crashlytics. Then strip from binary to reduce size.

### 24. Beta testing channels.
TestFlight (iOS, up to 10K external users, 90-day builds). Play Internal/Closed/Open Tracks (Android, instant). Firebase App Distribution as alternative.

### 25. Code: GitHub Actions matrix.
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'yarn' }
      - run: yarn
      - run: yarn lint && yarn typecheck && yarn test --coverage
  build-android:
    runs-on: ubuntu-latest
    steps: [ ... gradle build ... ]
  build-ios:
    runs-on: macos-14
    steps: [ ... pod install + xcodebuild ... ]
```
