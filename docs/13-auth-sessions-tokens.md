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

