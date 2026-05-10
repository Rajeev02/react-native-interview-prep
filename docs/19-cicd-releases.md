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

