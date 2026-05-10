## 13. Auth, sessions, tokens

### OAuth 2.0 + PKCE (mobile-correct flow)
1. App generates `code_verifier` + `code_challenge`.
2. Open browser/AuthSession → user logs in → redirect with `code`.
3. Exchange `code` + `code_verifier` for tokens.
4. Store tokens in Keychain/Keystore.

### Tokens
- **Access token**: short-lived (5–60 min), JWT, sent as `Authorization: Bearer`.
- **Refresh token**: longer-lived, opaque, **rotate on every use** (refresh rotation).
- Never put refresh in JS memory longer than needed; never log.

### Auth0 / Cognito (your stack)
- Auth0: hosted login, social, MFA, rules/actions.
- Cognito: AWS-native, integrates with API Gateway, has user pools + identity pools.

### Biometric gating
- `expo-local-authentication` or `react-native-keychain` with biometric prompt.
- Gate on app foreground after timeout, before sensitive screens.

### Must-answer questions
1. OAuth PKCE flow on mobile.
2. Refresh token rotation — why.
3. Where to store tokens (Keychain/Keystore, not AsyncStorage).
4. Biometric session timeout pattern.
5. Logout — what to clear.

---



---

## Top 25 Q&A — Auth, sessions, tokens

### 1. Where do you store auth tokens in RN?
iOS Keychain + Android EncryptedSharedPreferences via `react-native-keychain` or `expo-secure-store`. **Never** plain AsyncStorage.

### 2. Access token vs refresh token?
Access: short-lived (5–15 min), sent on every request. Refresh: long-lived, used only to get new access token. Stored separately if possible.

### 3. JWT structure.
`header.payload.signature` — base64url-encoded. Signature uses HMAC-SHA256 (HS256) or RSA/ECDSA (RS256). Don't trust without verifying signature.

### 4. Why not just rely on JWT expiration?
Can't revoke before expiry. Mitigations: short access TTL + refresh rotation, server-side denylist, opaque tokens with introspection.

### 5. Refresh-token rotation.
Each refresh issues new pair, invalidates old. Detects token theft (reuse of old refresh = compromise → logout all sessions).

### 6. Handling 401 — refresh + retry pattern.
Single in-flight refresh promise; queue concurrent 401s; on refresh success replay; on failure logout.

### 7. Biometric auth flow.
After password login, ask "enable biometrics?". Store refresh token in Keychain with `accessControl: BIOMETRY_CURRENT_SET`. Next launch: biometric → unlock → silent refresh.

### 8. iOS Keychain accessibility levels.
`whenUnlocked`, `afterFirstUnlock`, `whenPasscodeSet` (most restrictive). Use `accessGroup` for sharing across apps.

### 9. Android Keystore — what does it solve?
Stores keys in TEE/StrongBox; can require user auth (biometric) per use. Use AES-GCM keys to encrypt token blob in EncryptedSharedPreferences.

### 10. OAuth 2.0 flows for mobile.
**PKCE** (Proof Key for Code Exchange) is required. Authorization Code + PKCE — `react-native-app-auth`.

### 11. PKCE — what & why?
Client generates `code_verifier`, sends `code_challenge = SHA256(verifier)`. On token exchange, sends verifier. Prevents code interception attacks.

### 12. Social login (Google / Apple) — libs.
`@react-native-google-signin/google-signin`, `@invertase/react-native-apple-authentication`. Apple Sign-in mandatory if you offer any third-party login (App Store rule).

### 13. Logout — what to clear?
Tokens (Keychain), persisted state, React Query cache (`qc.clear()`), navigation reset, push token unregister, analytics user reset.

### 14. Session timeout / inactivity logout.
Track last interaction; on app foreground, if `now - last > N min`, force re-auth. PIN/biometric for quick unlock.

### 15. Device binding — what?
Bind tokens to a device fingerprint (installation ID + attestation). Server rejects token used from another device.

### 16. Multi-device session management.
Server keeps sessions list; show active devices in UI; allow remote logout. Refresh tokens are per-session.

### 17. Show secure token store usage.
```ts
import * as Keychain from 'react-native-keychain';
await Keychain.setGenericPassword('access', token, {
  service: 'app.tokens',
  accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED,
  accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET,
});
const creds = await Keychain.getGenericPassword({ service: 'app.tokens' });
```

### 18. OTP / OTP autofill.
iOS: `textContentType="oneTimeCode"`. Android: `autoComplete="sms-otp"` + SMS Retriever / SMS User Consent API.

### 19. Magic link / passwordless?
Email/SMS link → universal link opens app → exchange one-time code for tokens. Watch out for replay; one-use codes.

### 20. CSRF in mobile?
Less common (no cookies usually). If using cookie auth, send `X-CSRF` header from client; server verifies.

### 21. Anti-pattern: storing JWT in AsyncStorage.
Plain AsyncStorage = unencrypted. Anyone with device access (rooted/jailbroken) can read. Use Keychain/Keystore.

### 22. SSO across apps from same vendor.
iOS: shared Keychain `accessGroup`. Android: Account Manager / shared FileProvider. Both: server-side SSO with short-lived tokens.

### 23. Detect rooted/jailbroken device.
`jail-monkey` / `react-native-device-info`. Block sensitive flows or warn. Pair with Play Integrity / DeviceCheck/AppAttest.

### 24. App Attest / Play Integrity.
Hardware-backed attestation that requests come from genuine app + device. Pin auth & payment APIs behind it.

### 25. Code: refresh-with-queue pattern.
```ts
let pending: Promise<string> | null = null;
async function getValidToken(): Promise<string> {
  const t = readAccess();
  if (!isExpired(t)) return t;
  pending ??= refresh().finally(() => { pending = null; });
  return pending;
}
```
