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

