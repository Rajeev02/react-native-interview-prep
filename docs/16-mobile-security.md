## 16. Mobile security (fintech-critical)

### OWASP MASVS L1 vs L2 (know the headlines)
- **L1**: standard hygiene — secure storage, TLS, no debug enabled in prod, no hardcoded secrets.
- **L2**: defense in depth — cert pinning, anti-tampering, jailbreak/root detection, obfuscation (R8), runtime integrity checks (RASP).

### Secure storage
- **iOS**: Keychain (`react-native-keychain`).
- **Android**: EncryptedSharedPreferences or Keystore-backed.
- Never AsyncStorage for tokens/PII.

### Cert pinning
- Pin server cert or public key.
- **Have a rotation strategy**: pin both current + next cert; expire old after rotation.
- iOS: `NSAppTransportSecurity` + URLSession delegate / `react-native-ssl-pinning`.
- Android: Network Security Config XML.

### Jailbreak / root detection
- `jail-monkey` library.
- Heuristics: known files, mounted paths, suspect packages.
- Don't hard-block — warn + degrade (e.g., disable payments).

### iOS Privacy Manifest (`PrivacyInfo.xcprivacy`)
- Required since 2024 for App Store.
- Declare data collected + reasons + tracking domains.

### Android privacy
- Play Console Data Safety form.
- Permissions justification.
- Foreground service types (Android 14+).

### Anti-patterns
- Logging tokens / PII to Sentry/console.
- Storing PII in analytics events.
- Deep links accepting unsigned intents (intent redirection).
- WebView with `javaScriptEnabled` + untrusted URL.

### PCI-DSS basics (fintech mention)
- Don't store full PAN on device.
- Use payment SDK (Razorpay/Cashfree) — they handle PCI scope.
- Tokenized cards only.

### Must-answer questions
1. Secure token storage end-to-end.
2. Cert pinning + rotation.
3. Jailbreak/root — detect + react.
4. MASVS L2 highlights.
5. PII hygiene in logs/analytics.

---



---

## Top 25 Q&A — Mobile security (fintech-critical)

### 1. OWASP Mobile Top 10 — name 5.
M1 Improper Credential Use, M2 Inadequate Supply Chain, M3 Insecure Auth, M4 Insufficient Input Validation, M5 Insecure Communication, M6 Inadequate Privacy, M7 Insufficient Binary Protection, M8 Security Misconfiguration, M9 Insecure Data Storage, M10 Insufficient Cryptography.

### 2. Secure storage — RN options.
Keychain (iOS) + EncryptedSharedPreferences/Keystore (Android) via `react-native-keychain` / `expo-secure-store`. MMKV with encryption key from Keychain for non-credential blobs.

### 3. Cert pinning — why and how?
Defends against MITM with rogue CA. Pin SPKI hashes in app; rotate via dual-pin period. Libs: `react-native-ssl-pinning`, `react-native-cert-pinner`.

### 4. Detect rooted / jailbroken device.
`jail-monkey`. Combine with Play Integrity / App Attest for hardware-backed signal. Block payments / KYC on tampered devices.

### 5. Play Integrity API / DeviceCheck / App Attest.
Hardware attestation that the app binary + device are genuine. Server-side validate token before sensitive flows.

### 6. Obfuscation — JS bundle.
Hermes bytecode is somewhat opaque; add `metro-minify-terser` with mangling. For Android, ProGuard/R8. For iOS, strip symbols in release.

### 7. RASP (Runtime App Self-Protection).
Frida / debugger detection, hook detection. Libs: `react-native-jailbreak-detection`, FreeRASP. Combine with kill-switch on detection.

### 8. Screen recording / screenshot prevention.
Android: `FLAG_SECURE` window flag. iOS: detect via `UIScreen.isCaptured`, blur on `applicationWillResignActive`.

### 9. Avoid logging PII.
Lint rule: no `console.log(card)`. Sentry `beforeSend` scrubs fields. Mask PAN to last 4, hash emails for analytics.

### 10. Webview risks.
Disable JS where not needed, validate URLs against allowlist, never inject tokens via URL params, use `originWhitelist`.

### 11. Deep link injection — risk?
Attacker app can craft `myapp://transfer?to=attacker&amount=1000`. Always require auth + confirmation; never auto-execute.

### 12. Secret management in app.
Don't ship API keys for sensitive backends in the binary. Use short-lived per-session tokens fetched after auth. Public keys (FCM, Maps) are fine.

### 13. TLS configuration.
TLS 1.2+ only, ATS enforced on iOS (`NSAllowsArbitraryLoads=false`). Android `network_security_config.xml` blocks cleartext in production.

### 14. JWT pitfalls.
Don't trust `alg: none`; verify signature; validate `iss`, `aud`, `exp`. Don't put PII in payload (anyone can decode).

### 15. Secure clipboard usage.
Copying OTPs / tokens — clear after N seconds (`Clipboard.setStringAsync('')`). iOS shows clipboard read banner; expect it.

### 16. Biometric replay attack prevention.
Use `BiometricPrompt`/`LAContext` with `evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` → ties to current biometric set; invalidates on enrollment change.

### 17. Backup exclusion.
Android: `android:allowBackup="false"` for sensitive apps. iOS: set Keychain `accessible` to `…ThisDeviceOnly` to exclude from iCloud backup.

### 18. Webview / OAuth — ASWebAuthenticationSession / Custom Tabs.
Use system browser session (shares cookies, isolated). Avoid in-app webview for OAuth (M3, fishing risk).

### 19. PCI-DSS implications for RN apps.
Don't transmit raw PAN unless your scope is reduced. Use payment SDK that tokenizes card on device → server gets token.

### 20. Anti-tamper: signature verification.
Android: check APK signing certificate hash at startup (`PackageManager.getPackageInfo`). iOS: bundle signature is OS-verified.

### 21. Frida detection.
Look for `frida-server` ports, suspicious libraries loaded, `/proc/self/maps` patterns. Imperfect; combine signals.

### 22. Secret in env file?
`.env` is bundled into JS — visible to anyone unzipping the IPA/APK. For client secrets that must exist, use Android Keystore-derived keys.

### 23. Crash report scrubbing.
Sentry: `beforeSend` strips PII, redacts headers, drops by tag. Crashlytics: custom keys only — don't put PII.

### 24. Code: detect debugger attached.
```ts
import JailMonkey from 'jail-monkey';
if (__DEV__ === false && (JailMonkey.isJailBroken() || JailMonkey.canMockLocation())) {
  // block sensitive flow, log to backend
}
```

### 25. Threat model checklist for fintech.
Auth (MFA, biometric), transport (TLS pinning), storage (Keychain), tampering (RASP, attestation), social engineering (deep-link auth, in-app warnings), supply chain (SBOM, dep audit), incident response (kill switch via remote config).
