# S10 — Authentication & Security

> OAuth2 + PKCE · token storage · biometrics + secure enclave · app attestation · MASVS 2026

Five Q-topics in the mandatory per-topic format. Mobile auth in 2026 is **OAuth 2.1 + PKCE** with rotating refresh tokens, **hardware-backed key storage** (Secure Enclave / StrongBox), **biometric unlock** gating sensitive operations, and **server-verified app attestation** (App Attest / Play Integrity) to defend backends from tampered clients. Certificate pinning is covered in [S9 Q5](S09-networking.md).

---

### Q1. OAuth 2.1 + PKCE on mobile — full flow with refresh-token rotation

---

## Difficulty
- Advanced

## Interview Frequency
- Very Common (every consumer/enterprise app)

## Prerequisites
- HTTP, JWT basics, basic crypto (SHA-256, base64url)

## TL;DR
Use **Authorization Code + PKCE** (no client secret on mobile). Open the auth screen in **`SFAuthenticationSession` / `Custom Tabs`** (not WebView). Store **refresh token in Secure Enclave-backed Keychain / StrongBox-backed Keystore**. **Rotate refresh tokens** on every use; reject reuse (replay = compromise). Refresh **proactively** ~60s before access-token expiry. Sign out = revoke refresh token server-side.

---

## 30-Second Interview Answer

> "Mobile OAuth in 2026 means OAuth 2.1 + PKCE — no client secret, code-challenge generated per request, exchanged for tokens on the auth server. Use the platform's secure browser (`ASWebAuthenticationSession` on iOS, Custom Tabs on Android), never an embedded WebView — that's a phishing surface and Google blocks it. Refresh tokens must rotate on every refresh; the server detects reuse and revokes the family. Store refresh tokens in Keychain (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) or Keystore-backed EncryptedSharedPreferences. Refresh proactively before expiry; coalesce concurrent refresh attempts to avoid token-family breakage."

---

## 2-Minute Practical Answer

The flow:

```
1. Client generates: code_verifier (random 43-128 chars)
                     code_challenge = base64url(SHA256(verifier))
2. Client opens: <AuthServer>/authorize?
     response_type=code&client_id=...&redirect_uri=app://cb
     &code_challenge=...&code_challenge_method=S256
     &state=<random>&scope=openid profile email
3. User authenticates in the system browser (SFAuthenticationSession / Custom Tabs).
4. Auth server redirects to app://cb?code=...&state=...
5. App verifies state, exchanges code:
     POST /token
     { grant_type: 'authorization_code', code, code_verifier, redirect_uri, client_id }
6. Server returns: { access_token, refresh_token, id_token, expires_in }
7. Store refresh_token securely; cache access_token in memory.
8. On expiry: POST /token { grant_type: 'refresh_token', refresh_token, client_id }
   → server returns NEW refresh_token (rotated) + new access_token.
```

Critical rules:
- **No client secret** in the app (extract-able). Public clients only.
- **PKCE mandatory** (mitigates auth-code interception).
- **System browser**, not WebView (phishing protection + SSO).
- **Refresh-token rotation**: every refresh issues a new refresh token; old one invalidated. Reuse = entire token family revoked.
- **Coalesce refreshes**: if two requests need refresh simultaneously, share one refresh call (or you'll burn a refresh token and trigger reuse detection).
- **Custom URL scheme** redirect: `app://cb` or universal/app links (better — verified domain ownership).

Library landscape:
- `react-native-app-auth` (RNApp) — wraps AppAuth iOS/Android; mature, OIDC-compliant.
- `expo-auth-session` — Expo-native equivalent; great DX.
- Vendor SDKs (Auth0, Okta, Cognito, Firebase Auth) — wrap the flow with their own conveniences.

---

## 5-Minute Architecture Answer

OAuth was retrofitted to mobile after being designed for server-side web apps. The original "implicit flow" (token in URL fragment) was the early mobile choice and has been **deprecated** because of leakage. The modern correct flow is:

**Authorization Code + PKCE** — designed for public clients (mobile, SPA) that cannot keep a secret. PKCE works by:
1. Client generates a random `code_verifier` (43–128 chars).
2. Sends `code_challenge = base64url(SHA256(verifier))` with the auth request.
3. Auth server stores challenge.
4. When client exchanges the code, sends the original `code_verifier`.
5. Server hashes verifier, compares to stored challenge — if mismatch, reject.

This stops an attacker who intercepts the redirect (e.g., via a malicious app claiming the same custom scheme) from completing the exchange — they don't have the verifier.

**Why system browser, not WebView**:
- WebView gives the app full access to credentials typed by the user → phishing surface.
- WebView doesn't share cookies with browser → no SSO.
- Google's OAuth servers refuse WebView since 2017 (`disallowed_useragent`).
- iOS `ASWebAuthenticationSession` and Android `CustomTabs` provide an isolated browser that shares the system cookie jar (enabling SSO) but isolates the app.

**Refresh-token rotation** (RFC 6749bis / OAuth 2.1):
- Every refresh issues a new refresh token; old one immediately invalid.
- If old one is presented again → **reuse detected** → revoke entire token family (treat as compromise).
- This means clients must serialize refresh attempts: if a screen needs token, in-flight refresh must be awaited, not redone.

**Token lifetimes** (typical):
- Access token: 5–15 min (JWT, short-lived, validated locally).
- Refresh token: 30 days (rotated every use), or session-bound.
- ID token: 1 hour (used once for profile).

**ID token vs access token**:
- ID token (OIDC) = identity proof for *your app* about *the user*. JWT, signed by issuer.
- Access token = authorization for *your app* to call APIs on user's behalf. Opaque or JWT.
- Don't send ID token to APIs as auth — it's not for that.

**Edge cases**:
- **Concurrent refresh**: 5 API calls all 401 simultaneously. Without coalescing, 5 refresh requests → 4 token-family revocations. Solution: single in-flight refresh promise.
- **Clock skew**: device clock wrong → access token "expired" or "not yet valid" client-side. Trust server time when possible.
- **App backgrounded mid-flow**: auth session may be killed. Retry from scratch (verifier was lost).
- **Account linking**: OAuth gives user identity per provider; link via stable identifier (`sub` claim).

The 2026 specific:
- **OAuth 2.1** (BCP-style consolidation) is the de-facto standard; deprecates implicit + password grants.
- **Demonstration of Proof-of-Possession (DPoP)** rising in adoption — binds tokens to a key the client holds, prevents stolen-token replay.
- **FAPI 2.0** for high-assurance use cases (banking) — adds mTLS / DPoP requirements.
- **Passkeys** (WebAuthn) replacing passwords for first-factor auth in many apps.

---

## The "Why"

Authentication is **the** security boundary. Bad auth = account takeover, data theft, regulatory liability. The OAuth ecosystem has 15 years of attacks documented; doing it correctly means using the modern flow with the modern protections. Companies care because (1) ATO is the most common breach vector, (2) auth bugs are existential — one zero-day in your refresh path can compromise every user.

---

## Mental Model

OAuth = "I'll go to a separate room (system browser), prove who I am, come back with a paper slip (code), trade it (with a secret only I generated, the verifier) for a real key (token). The key wears out (access token expires). I have a renewable key (refresh token) but every renewal swaps it for a new one, so a stolen one is detected fast."

---

## Internal Working (2026 Context)

- iOS `ASWebAuthenticationSession`: presents Safari-backed view, returns redirect URL; cookies isolated to session unless `prefersEphemeralWebBrowserSession=false`.
- Android Custom Tabs: launches Chrome/browser with custom UI; redirect captured via deep link.
- Custom scheme vs Universal/App Links: scheme can be hijacked by another app; app links are domain-verified — prefer.
- AppAuth libraries handle PKCE generation, state validation, token persistence (configurable storage).
- JWT signature validation: client should validate ID token signature; access tokens often validated server-side (introspection or JWT validation at API gateway).

---

## Modern Implementation (Code)

**`react-native-app-auth`** setup:

```ts
import { authorize, refresh, revoke } from 'react-native-app-auth';

const config = {
  issuer: 'https://auth.example.com',
  clientId: 'mobile-app',
  redirectUrl: 'com.example.app:/oauthredirect',
  scopes: ['openid', 'profile', 'email', 'offline_access'],
  // PKCE is enabled by default; usePKCE: true
  serviceConfiguration: undefined,  // or set explicitly to skip discovery
};

export async function signIn() {
  const result = await authorize(config);
  // result: { accessToken, refreshToken, idToken, accessTokenExpirationDate, ... }
  await secureStore.setItem('refresh_token', result.refreshToken!);
  return result;
}

export async function refreshTokens() {
  const oldRefresh = await secureStore.getItem('refresh_token');
  if (!oldRefresh) throw new Error('no refresh token');
  const result = await refresh(config, { refreshToken: oldRefresh });
  await secureStore.setItem('refresh_token', result.refreshToken ?? oldRefresh);
  return result;
}

export async function signOut(refreshToken: string) {
  await revoke(config, { tokenToRevoke: refreshToken, sendClientId: true });
  await secureStore.removeItem('refresh_token');
}
```

**Coalescing concurrent refreshes** (critical for rotation safety):

```ts
let inflight: Promise<TokenResult> | null = null;

export async function getValidAccessToken(): Promise<string> {
  if (accessToken && Date.now() < expiresAt - 60_000) return accessToken;
  if (inflight) return (await inflight).accessToken;

  inflight = refreshTokens()
    .then((r) => {
      accessToken = r.accessToken;
      expiresAt = new Date(r.accessTokenExpirationDate).getTime();
      return { accessToken: r.accessToken } as TokenResult;
    })
    .finally(() => { inflight = null; });

  return (await inflight).accessToken;
}
```

**Wiring into fetch**:

```ts
async function authedFetch(url: string, init: RequestInit = {}): Promise<Response> {
  const token = await getValidAccessToken();
  const res = await fetch(url, {
    ...init,
    headers: { ...init.headers, Authorization: `Bearer ${token}` },
  });
  if (res.status === 401) {
    accessToken = null; expiresAt = 0;
    const fresh = await getValidAccessToken();
    return fetch(url, { ...init, headers: { ...init.headers, Authorization: `Bearer ${fresh}` } });
  }
  return res;
}
```

---

## Comparison

| Flow | Use case |
|---|---|
| Authorization Code + PKCE | **mobile (default)** |
| Implicit | [DEPRECATED] — never |
| Resource Owner Password | [DEPRECATED] — only for legacy migration |
| Client Credentials | server-to-server |
| Device Code | TVs, CLIs, no input |

| Library | Pros | Cons |
|---|---|---|
| `react-native-app-auth` | mature, RFC-compliant, both platforms | extra setup |
| `expo-auth-session` | clean DX, Expo-managed | tied to Expo |
| Auth0 / Okta SDK | hosted, lots of features | vendor lock |
| Firebase Auth | easy, free tier | limited customization |
| Manual `fetch` flow | full control | reinventing PKCE / state mgmt |

---

## Production Usage

- **Consumer apps**: usually social login (Google, Apple, etc.) via OAuth + your backend.
- **Enterprise**: corporate IdP (Okta, AzureAD) via OIDC.
- **Banking**: OAuth 2.1 + FAPI + DPoP + biometric step-up.
- **Multi-tenant SaaS**: per-tenant OIDC config; discovery via `.well-known/openid-configuration`.
- **Sign in with Apple**: required if you offer other social logins on iOS.

---

## Hands-On Exercise

1. **Implementation**: implement signIn / refresh / signOut with `react-native-app-auth` + coalesced refresh.
2. **Debugging**: refresh starts failing intermittently — likely token-family revoked due to non-coalesced refreshes.
3. **Architecture**: design OIDC integration for an app supporting multiple identity providers.
4. **Security**: audit your flow for: WebView use, embedded credentials, missing PKCE, unsafe storage, logging tokens.

---

## Common Mistakes

- Embedded WebView for auth → phishing surface, Google rejects.
- Storing refresh token in AsyncStorage (unencrypted) → trivially extracted on rooted device.
- Hardcoding client secret in app → recoverable via reverse engineering.
- Not coalescing refreshes → token-family revocations, sudden sign-outs.
- Using ID token as API auth → wrong token type.
- Logging tokens in crash reports / Sentry → leak risk.
- Not validating `state` on callback → CSRF.

---

## Production Red Flags

- **No PKCE** in code → vulnerable to code interception.
- **`AsyncStorage.setItem('access_token', ...)`** → wrong storage tier.
- **Multiple refresh calls in flight** → token-family corruption.
- **No automatic re-auth on refresh failure** → confused users.
- **Custom URL scheme without app-link verification** → hijack risk.

---

## Performance & Metrics (MANDATORY)

- **Auth round-trip**: ~1–3s typical (browser launch, user input, token exchange).
- **Refresh latency**: ~100–500ms; should be invisible to user.
- **Bundle**: AppAuth ~200KB compiled.
- **Memory**: tokens are tiny; SDK ~MB.
- **Battery**: nil.

---

## Metrics That Matter

- Sign-in success rate
- Sign-in P95 latency
- Refresh success rate (should be >99.9%)
- Token-reuse detections (should approach 0)
- Forced sign-out rate (refresh failure → user re-login)

---

## Decision Framework

| Need | Pick |
|---|---|
| New mobile app, custom backend | OAuth 2.1 + PKCE via AppAuth |
| Expo workflow | `expo-auth-session` |
| Enterprise SSO | OIDC + corporate IdP |
| Highest assurance (banking) | FAPI 2.0 + DPoP + biometric step-up |
| Passwordless | Passkeys (WebAuthn) |
| Quick prototype | Firebase Auth / Auth0 |

---

## Senior-Level Insight

The mature take: **OAuth correctness is mostly about edge cases**. The happy path is well-documented. The bugs live in: clock skew, concurrent refresh, token-family revocations, sign-out propagation, account-linking conflicts, deep-link hijacks. Senior engineers write integration tests covering all of these. They also ensure backend and client agree on token rotation policy and reuse-detection behavior.

Org-level: own a single auth client wrapper across all apps; lint rule against raw `fetch` to authed endpoints; centralized token-storage abstraction; telemetry on every auth state transition.

The 2026 specific: budget for **passkeys**. They reduce password-related attacks dramatically and are now supported across iOS 16+ and Android 14+. Combine with OAuth: passkey replaces password as first factor, OAuth still issues tokens.

---

## Real-World Scenario

**Symptom:** Random users get signed out at unpredictable intervals.
**Investigation:** Server logs show `refresh_token reuse detected` for those accounts; typically when app makes parallel API calls after backgrounding.
**Root Cause:** No refresh coalescing; multiple 401-driven refreshes ran simultaneously, second one used the now-rotated old token, server treated it as compromise.
**Fix:** Single-flight refresh with promise caching.
**Lesson:** Refresh-token rotation requires single-flight discipline.

---

## Production Failure Story

**Incident:** A health app used a custom URL scheme (`healthapp://oauth`) for OAuth redirect. A malicious app on the Play Store registered the same scheme. Some users' OAuth codes were intercepted.
**Impact:** ~5,000 accounts compromised before detection; PII exposure; regulatory disclosure required.
**Investigation:** Custom schemes have no domain ownership verification; multiple apps can claim the same scheme. PKCE limited damage (code alone insufficient without verifier) but redirect-binding attacks succeeded.
**Root Cause:** Custom scheme instead of App/Universal Links.
**Fix:** Migrate to verified Android App Links + iOS Universal Links (`https://app.example.com/oauth`).
**Prevention:** Audit checklist requires verified deep-link domains for any auth redirect; PKCE plus domain-verified return URI.

---

## Debugging Checklist

1. Inspect auth request URL: confirm `code_challenge`, `state`, `redirect_uri`, `scope`.
2. Verify `state` echoed back and validated.
3. Confirm `code_verifier` sent in token exchange.
4. Server logs: token issuance, rotation, reuse detections.
5. Verify refresh coalescing with concurrent test calls.
6. Test sign-out → verify next call gets 401 (token revoked).

---

## Advanced / Internal Knowledge

- PKCE RFC 7636; OAuth 2.1 BCP draft formalizes.
- DPoP (RFC 9449): bind token to a per-request signature with a held key.
- FAPI 2.0: profile for financial APIs — mandates DPoP or mTLS.
- `prompt=login` forces re-auth; `prompt=none` for silent SSO.
- ID token claims: `iss`, `aud`, `sub`, `exp`, `iat`, `nonce` — validate all.
- `sub` is the stable identifier; `email` can change.

---

## 2026 AI Tip

- AI is **good at**: generating PKCE / AppAuth boilerplate.
- AI is **bad at**: refresh-coalescing patterns; check carefully.
- **Hallucination risk**: AI may suggest `prompt: 'consent'` semantics inconsistently; verify with IdP docs.
- **Prompt pattern**: "Implement OAuth 2.1 + PKCE in RN with `react-native-app-auth`, single-flight refresh, secure storage, and 401 retry."

---

## Related Topics

- Q2 token storage
- Q3 biometric step-up
- Q4 attestation
- S9 Q5 cert pinning
- S30 privacy disclosure

---

## Interview Follow-Up Questions

- Why is PKCE required on mobile?
- Why never WebView for auth?
- What is refresh-token rotation and what attack does it stop?
- Why coalesce refresh calls?
- How do passkeys fit alongside OAuth?

---

## Memory Hook

**"PKCE, system browser, rotate, coalesce."**

## Revision Notes

> OAuth 2.1 + PKCE on mobile. System browser, not WebView. Rotate refresh tokens; reuse = revoke family. Coalesce concurrent refreshes. App Links over custom schemes. Passkeys are 2026 first-factor of choice.

---

---

### Q2. Token storage — Keychain, Keystore, MMKV-encrypted, AsyncStorage

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- Basic crypto, iOS Keychain / Android Keystore concepts

## TL;DR
Pick storage by **sensitivity tier**: refresh tokens / cryptographic keys → **Keychain (iOS) / Keystore-backed EncryptedSharedPreferences or DataStore (Android)** with `AfterFirstUnlockThisDeviceOnly` / `setUserAuthenticationRequired`. App state → **MMKV** (encrypted optional). Cache / non-secrets → MMKV unencrypted. **AsyncStorage is plaintext** — never for secrets. Bind sensitive keys to **biometrics + Secure Enclave / StrongBox** for highest tier.

---

## 30-Second Interview Answer

> "Three tiers. Tier 1 — secrets like refresh tokens: iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and access control if needed; Android EncryptedSharedPreferences or DataStore + EncryptedFile, key wrapped by Keystore (StrongBox if available). Tier 2 — sensitive but non-credential state: MMKV with encryption key from Keychain/Keystore. Tier 3 — caches, prefs: MMKV unencrypted. AsyncStorage is plaintext SQLite/files — never for secrets, period. Library landscape: `react-native-keychain` for tier 1, `react-native-mmkv` for tier 2/3."

---

## 2-Minute Practical Answer

Storage tiers and what goes where:

| Tier | Storage | Examples | Why |
|---|---|---|---|
| 1: Secrets | iOS Keychain / Android Keystore-wrapped | refresh tokens, encryption keys, biometric-bound keys | hardware-backed, OS-protected |
| 2: Sensitive | MMKV-encrypted (key in Tier 1) | user profile cache, encrypted PII | encryption at rest, fast reads |
| 3: App state | MMKV plain | UI prefs, feature flags, last screen | speed; not sensitive |
| 4: Caches | TanStack Query cache, file cache | API responses, images | rebuildable from network |
| Never | AsyncStorage for secrets | — | plaintext file/SQLite |

iOS Keychain access classes:
- `kSecAttrAccessibleWhenUnlocked` — accessible only when device unlocked.
- `kSecAttrAccessibleAfterFirstUnlock` — accessible after first unlock since boot (allows background tasks).
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — same + does NOT migrate via iCloud Backup. **Default for tokens**.
- `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` — requires passcode set; gone on passcode removal.
- Add `SecAccessControl` with `.biometryAny` / `.biometryCurrentSet` / `.userPresence` for biometric gating.

Android Keystore tiers:
- **Software Keystore** — keys in app sandbox; OK baseline.
- **TEE (Trusted Execution Environment)** — hardware-backed; default on most modern devices.
- **StrongBox** — dedicated security chip (Pixel 3+, some flagships); best class.
- `setUserAuthenticationRequired(true)` — biometric/PIN required to use key.

EncryptedSharedPreferences (AndroidX Security) wraps SharedPreferences with AES-256-GCM keys held by Keystore — easiest correct option.

MMKV encryption: `new MMKV({ id, encryptionKey })`; key itself must come from Keychain/Keystore. ~10× faster than AsyncStorage; supports concurrent processes.

---

## 5-Minute Architecture Answer

Storage isn't a single decision; it's a per-data-type decision driven by:
1. **Sensitivity** — what's the impact if leaked?
2. **Access pattern** — sync vs async; how often?
3. **Performance** — sub-ms reads needed?
4. **Backup behavior** — should it survive device transfer / restore?
5. **Threat model** — which attackers do you defend against?

Threat model layers:
- **Casual access** (lost unlocked phone): defended by lock screen.
- **Forensic extraction** (jailbroken/rooted device): defended by Keychain/Keystore.
- **Backup/iCloud extraction**: defended by `ThisDeviceOnly` access classes + non-backed-up file paths.
- **Malware on device with root**: nearly nothing defends fully; Secure Enclave / StrongBox raises the bar.
- **Compromised app process** (memory inspection): minimize time secrets sit in memory.

iOS specifics:
- Keychain entries can have access groups (share across apps with same team ID).
- `kSecAttrSynchronizable` enables iCloud sync — usually disable for app secrets.
- File-system protection classes parallel Keychain: `NSFileProtectionComplete` (only when unlocked) etc.
- Documents folder backed up by default; use `URLResourceKey.isExcludedFromBackupKey` to opt out.

Android specifics:
- App sandbox: other apps can't read your files (without root).
- EncryptedSharedPreferences uses two keys: master key (Keystore) and value key (derived).
- DataStore (modern replacement for SharedPreferences) supports `EncryptedFile` wrappers.
- `Context.MODE_PRIVATE` is enforced by Linux UID isolation — robust on non-rooted.
- Backup: `android:allowBackup="false"` to prevent ADB backups; `android:backupRules` for selective.

MMKV details:
- C++ engine; mmap-based; single-file per instance.
- Encryption: AES-128 CFB; key passed to constructor.
- Multi-process safe (separate instances OK).
- Performance: ~10ns reads for hot keys.

The 2026 specific:
- iOS 17+ `kSecUseDataProtectionKeychain` recommended for all new code.
- Android 14+ Health Connect / Credential Manager APIs introduce passkey storage primitives.
- **Hardware attestation** (App Attest, Play Integrity, Q4) increasingly tied to Keystore-bound keys.
- **Privacy Manifests** require declaring storage usage (`NSPrivacyAccessedAPIType`) for some categories.

When AsyncStorage is OK:
- UI preferences (last selected tab).
- Feature flags (cached).
- Anything you'd be comfortable printing in a log.

When AsyncStorage is not OK:
- Auth tokens (any).
- API keys.
- PII (names, emails, addresses, health data).
- Biometric template data.
- Encryption keys.

---

## The "Why"

A leaked refresh token = silent account takeover. A leaked encryption key = decrypted local data. Storage decisions made early are hard to walk back — migration paths require careful coordination. Companies care because mobile apps are the lowest-friction extraction target: jailbreak/root tools are off-the-shelf; if your secrets are in a flat file, attackers walk in. Hardware-backed storage raises the cost dramatically.

---

## Mental Model

Three safes:
- **Keychain/Keystore** = bank vault — slow but very hard to crack.
- **MMKV-encrypted** = locked desk drawer — fast, decent protection.
- **MMKV/AsyncStorage** = open drawer — fast, no protection.
Pick the safe by what's inside.

---

## Internal Working (2026 Context)

- **iOS Keychain** lives in `/var/Keychains/keychain-2.db`, encrypted by per-device hardware key. Apps access via Security framework; entitlement-based access control.
- **Android Keystore** keys live in TEE / StrongBox HW; never extractable from secure HW. App can use keys (sign, encrypt) but never sees raw key bytes.
- **EncryptedSharedPreferences** uses Tink (Google crypto lib) with AES-256-GCM keys derived from Keystore-stored master key.
- **MMKV** uses mmap for direct file→memory mapping; writes are appended (LSM-style) and periodically compacted.
- **AsyncStorage** is SQLite-backed (Android) / serialized files (iOS); plaintext on disk.

Threading: Keychain ops can be slow (synchronous syscalls); avoid on JS thread for hot paths. MMKV is sync but extremely fast.

---

## Modern Implementation (Code)

**Tier 1 — refresh token in Keychain** (`react-native-keychain`):

```ts
import * as Keychain from 'react-native-keychain';

export async function saveRefreshToken(token: string) {
  await Keychain.setGenericPassword('user', token, {
    service: 'com.example.app.refresh',
    accessible: Keychain.ACCESSIBLE.AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY,
    accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET, // optional, for biometric gating
    securityLevel: Keychain.SECURITY_LEVEL.SECURE_HARDWARE,       // Android: TEE/StrongBox
  });
}

export async function getRefreshToken(): Promise<string | null> {
  const creds = await Keychain.getGenericPassword({ service: 'com.example.app.refresh' });
  return creds ? creds.password : null;
}

export async function clearRefreshToken() {
  await Keychain.resetGenericPassword({ service: 'com.example.app.refresh' });
}
```

**Tier 2 — encrypted MMKV** with key from Keychain:

```ts
import { MMKV } from 'react-native-mmkv';
import { v4 as uuid } from 'uuid';
import * as Keychain from 'react-native-keychain';

let storage: MMKV | null = null;

export async function getEncryptedStorage(): Promise<MMKV> {
  if (storage) return storage;
  let key = await Keychain.getInternetCredentials('mmkv-key');
  let encryptionKey: string;
  if (!key) {
    encryptionKey = uuid().replace(/-/g, ''); // 32 hex chars
    await Keychain.setInternetCredentials('mmkv-key', 'mmkv', encryptionKey, {
      accessible: Keychain.ACCESSIBLE.AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY,
    });
  } else {
    encryptionKey = (key as Keychain.UserCredentials).password;
  }
  storage = new MMKV({ id: 'secure', encryptionKey });
  return storage;
}
```

**Tier 3 — plain MMKV for prefs**:

```ts
import { MMKV } from 'react-native-mmkv';

export const prefs = new MMKV({ id: 'prefs' });

prefs.set('lastTab', 'home');
const tab = prefs.getString('lastTab');
```

**Excluding files from iOS backup**:

```ts
import RNFS from 'react-native-fs';
await RNFS.setExcludedFromBackup(`${RNFS.DocumentDirectoryPath}/cache.bin`);
```

---

## Comparison

| Storage | Tier | Speed | Encryption | Backup | Best for |
|---|---|---|---|---|---|
| Keychain / Keystore | 1 | slow (ms) | HW-backed | configurable | secrets |
| EncryptedSharedPreferences | 1 | fast | Keystore-derived | configurable | Android secrets bulk |
| MMKV-encrypted | 2 | very fast | AES-128 CFB | configurable | sensitive cache |
| MMKV plain | 3 | very fast | none | configurable | prefs, flags |
| TanStack Query persistedClient | 4 | fast | optional | yes | API cache |
| AsyncStorage | 3/never | slow | **none** | yes | legacy / tiny prefs |
| op-sqlite encrypted | 1/2 | fast | SQLCipher | configurable | structured PII |

---

## Production Usage

- **Refresh token**: Keychain / Keystore.
- **Biometric-bound encryption key**: Keychain w/ `accessControl: BIOMETRY_CURRENT_SET` / Keystore `setUserAuthenticationRequired`.
- **Last user / quick-resume identifier**: MMKV-encrypted or plain depending on sensitivity.
- **Feature flags**: MMKV plain.
- **Drafts** (e.g., unsent messages): MMKV-encrypted if contains user content.
- **Health data**: Keystore-bound encrypted SQLite (op-sqlite + SQLCipher).

---

## Hands-On Exercise

1. **Implementation**: build storage helpers for the three tiers above; migrate from AsyncStorage to MMKV with versioned keys.
2. **Debugging**: refresh token disappears across reinstall — that's expected for `ThisDeviceOnly`; design re-login flow.
3. **Architecture**: design key-rotation strategy for the encryption key (reEncrypt MMKV under new key).
4. **Audit**: scan code for `AsyncStorage.setItem` and classify each by tier.

---

## Common Mistakes

- Using AsyncStorage for tokens.
- Hardcoded encryption key in source code.
- Not setting `ThisDeviceOnly` → tokens migrate via iCloud Backup.
- Forgetting to clear secrets on sign-out.
- Storing biometric template ourselves (always wrong; OS handles it).
- Storing PII in MMKV plain.
- Allowing Android backup of secrets directory.

---

## Production Red Flags

- **`AsyncStorage.setItem('token', ...)`** anywhere.
- **`Keychain.ACCESSIBLE.ALWAYS`** — accessible even when device locked.
- **Encryption key in env-loaded constant** → in Hermes bundle.
- **No way to wipe storage on sign-out**.

---

## Performance & Metrics (MANDATORY)

- **Keychain read**: ~ms; not for hot paths.
- **MMKV read**: ~ns–µs; fine for hot paths.
- **EncryptedSharedPreferences**: ~ms first read, faster subsequent.
- **AsyncStorage**: ~ms each, async — avoid in render path.
- **Bundle**: keychain ~30KB, mmkv ~50KB.

---

## Metrics That Matter

- Sign-out completeness (no leftover secrets)
- Storage migration completion rate
- Encrypted-storage init failure rate
- Backup exclusion verified

---

## Decision Framework

| Data | Tier |
|---|---|
| Refresh token | 1 (Keychain/Keystore) |
| Access token | memory only (or 1 if persisted across restarts) |
| Biometric-bound encryption key | 1 with accessControl |
| User profile cache | 2 (MMKV-encrypted) |
| Last screen / nav state | 3 (MMKV plain) |
| Feature flags | 3 (MMKV plain) |
| API responses | TanStack Query cache |
| Image cache | expo-image / FastImage |
| Health / financial PII | 1 + SQLCipher |

---

## Senior-Level Insight

The mature take: **storage is policy, not code**. A senior engineer writes a `secureStore` / `prefStore` / `cacheStore` API and bans direct access to underlying libraries. New devs cannot accidentally use the wrong tier because they never touch Keychain or AsyncStorage directly. Lint rule + code review enforce.

Senior engineers also: (1) plan for key rotation upfront, (2) include "wipe on sign-out" in test matrix, (3) test on rooted/jailbroken devices, (4) document threat model so future contributors understand "why this tier".

---

## Real-World Scenario

**Symptom:** After uninstall + reinstall, app remembers user (skips login).
**Investigation:** Refresh token saved with default Keychain access (no `ThisDeviceOnly`); persists across reinstalls (Keychain survives uninstall by design on iOS).
**Root Cause:** Expected mobile mental model "uninstall = wipe" doesn't apply to Keychain.
**Fix:** Use `ThisDeviceOnly` if cross-reinstall persistence is unwanted; OR clear Keychain on first launch (tracked via UserDefaults).
**Lesson:** Keychain ≠ NSUserDefaults — different lifecycle.

---

## Production Failure Story

**Incident:** A finance app was found to store its database encryption key in AsyncStorage. Researchers extracted keys + DB from non-jailbroken iOS via iTunes backup → decrypted account history of researchers' own accounts.
**Impact:** Disclosure to regulator (under PSD2-style rules); patch within 48h; PR damage.
**Investigation:** Encryption key was generated correctly but stored "for simplicity" in AsyncStorage; backup contained both files.
**Root Cause:** Wrong storage tier for highest-sensitivity data.
**Fix:** Move key to Keychain `ThisDeviceOnly`; rotate keys; force re-sync from server; exclude DB from backup.
**Prevention:** Static analysis rule banning AsyncStorage near "key" / "token" symbols; security review checklist for any storage decision.

---

## Debugging Checklist

1. Verify `accessible` and `securityLevel` set correctly.
2. Inspect device backup (Mac Finder → Device → Show in Finder Backup) — confirm secrets absent.
3. Test on rooted Android device with adb pull — confirm files encrypted/missing.
4. Test reinstall behavior matches expectation.
5. Test biometric-bound keys: enrolling new biometric should invalidate `BIOMETRY_CURRENT_SET`.
6. Telemetry: secret-read failure rate.

---

## Advanced / Internal Knowledge

- iOS Data Protection: per-file class; default Documents = `Complete` since iOS 7.
- Android Keystore key attestation: server can verify key was generated in TEE/StrongBox.
- MMKV file format: append-only with periodic compaction; CRC for integrity.
- SQLCipher (used by op-sqlite, expo-sqlite-encrypted): page-level AES-256.
- EncryptedSharedPreferences uses Tink AEAD; key alias `_androidx_security_master_key_`.

---

## 2026 AI Tip

- AI is **good at**: scaffolding storage helpers per tier.
- AI is **bad at**: knowing which tier your data belongs in — you classify.
- **Hallucination risk**: AI sometimes suggests `AsyncStorage` for tokens citing "simplicity".
- **Prompt pattern**: "Generate a `secureStore` wrapper using react-native-keychain with `AfterFirstUnlockThisDeviceOnly` and biometric access control, plus an MMKV-encrypted store with key derived from Keychain."

---

## Related Topics

- Q1 OAuth (refresh token storage)
- Q3 biometrics
- S11 offline storage / SQLite
- S30 privacy manifests

---

## Interview Follow-Up Questions

- Why not AsyncStorage for tokens?
- Difference between `WhenUnlocked` and `AfterFirstUnlock`?
- What does StrongBox add vs TEE?
- How would you migrate from AsyncStorage to MMKV without losing data?
- How do you rotate the MMKV encryption key?

---

## Memory Hook

**"Three tiers, hardware below."**

## Revision Notes

> Tier secrets in Keychain/Keystore (HW-backed). Tier sensitive in MMKV-encrypted. Tier prefs in MMKV plain. Never AsyncStorage for secrets. Use `ThisDeviceOnly` to block iCloud leak. Wrap in app-wide `secureStore` API.

---

---

### Q3. Biometric authentication + Secure Enclave / StrongBox-bound keys

---

## Difficulty
- Advanced

## Interview Frequency
- Common (banking, healthcare, any sensitive ops)

## Prerequisites
- Q2 storage tiers, basic asymmetric crypto

## TL;DR
Use **`react-native-biometrics` / `expo-local-authentication`** for biometric unlock. For real security, **bind a key to biometrics** in Secure Enclave (iOS) or StrongBox/TEE (Android) — verifying biometrics doesn't just check a flag, it **unlocks the key** to sign or decrypt. Re-enrollment of biometrics invalidates the binding (good — detects added attacker faces).

---

## 30-Second Interview Answer

> "Biometric auth has two flavors. **Naive**: check `LocalAuthentication.authenticate()`, get a boolean, gate code on it — trivially bypassed by hooking the function. **Correct**: store an asymmetric private key in Secure Enclave / Keystore, marked `userPresence` / `setUserAuthenticationRequired(true)`. To use the key (sign a challenge, decrypt a token), the OS prompts biometrics and only releases key access on success. The signature reaching your server *proves* biometric auth happened on a real device. For step-up auth on sensitive operations (transfers, profile changes), this is the bar."

---

## 2-Minute Practical Answer

Two patterns, two security postures:

**Pattern A — boolean check (low security)**:
```ts
const result = await LocalAuthentication.authenticateAsync({ promptMessage: 'Confirm' });
if (result.success) doSensitiveThing();
```
Easy to bypass: hook the function, force `success=true`. OK for unlocking app UI as convenience; **not** OK for cryptographic / financial ops.

**Pattern B — biometric-bound key (high security)**:
```
1. Enrollment:
   - Generate keypair in Secure Enclave / StrongBox.
   - Mark private key as requiring biometric auth.
   - Send public key to server, associate with user.

2. Verify operation:
   - Server sends challenge (random nonce).
   - App requests private key to sign challenge → OS prompts biometrics.
   - On success, key signs nonce.
   - App sends signature to server.
   - Server verifies signature with stored public key.

Result: signature == cryptographic proof that biometric auth occurred
on the user's actual enrolled device.
```

Re-enrollment behavior:
- iOS `.biometryCurrentSet` → adding/removing Face ID / Touch ID invalidates key.
- Android `setInvalidatedByBiometricEnrollment(true)` → same.
- Use `.biometryAny` / `false` if you want to survive re-enrollment (less secure).

When to require step-up:
- Money movement / transfers.
- Profile / email / phone changes.
- Adding payment methods.
- High-risk reads (full account export).
- After session age threshold (e.g., 30 days).

Library landscape:
- `react-native-biometrics` — direct biometric + signature API.
- `expo-local-authentication` — biometric prompt only (no key binding API).
- For full key binding: native module with Keychain `LAContext` (iOS) / KeyStore Cipher with `BiometricPrompt.CryptoObject` (Android).

---

## 5-Minute Architecture Answer

Biometric APIs solve two problems with very different trust profiles:

1. **UX convenience** ("don't make user type password every time").
2. **Cryptographic step-up** ("prove this user, on this device, authorized this exact operation").

Most apps need (1); high-stakes flows need (2).

The "boolean" pattern fails because the truth resides in JS — anything in JS is rewriteable on a rooted device. The biometric-bound key pattern moves the truth to hardware: the key cannot be extracted, cannot be used without biometric unlock, and cannot be replayed (server's challenge is unique per request).

iOS architecture:
- **Secure Enclave** is a separate processor co-resident with the SoC.
- Keys generated with `kSecAttrTokenIDSecureEnclave` never leave SE.
- Operations (sign, ECDH) happen inside SE; only the result emerges.
- Access controls: `.userPresence`, `.biometryAny`, `.biometryCurrentSet`, `.devicePasscode`.
- `LAContext` controls re-prompt behavior (cached auth duration, fallback to passcode).

Android architecture:
- **TEE (Trusted Execution Environment)** ARM TrustZone — common.
- **StrongBox Keymaster** — dedicated security HW; Pixel 3+, some Samsung.
- `KeyGenParameterSpec.Builder().setUserAuthenticationRequired(true)` ties key use to biometric/PIN.
- `BiometricPrompt.CryptoObject(cipher)` — biometric unlocks the cipher object.
- `setUserAuthenticationParameters(timeout, type)` — Android 11+ for fine control.

Cross-platform pitfalls:
- **No biometrics enrolled**: must handle gracefully (PIN fallback or password).
- **Lock-out**: too many failures → temporary biometric disable; system PIN fallback.
- **iOS Class 3 vs Class 2 biometrics** equivalents on Android — UX differs.
- **Spoofing**: face spoofing via masks; vendors mitigate but ATT (anti-spoof) varies.
- **Accessibility**: never *only* offer biometric; always provide an alternative.

The 2026 specific:
- **Passkeys** (WebAuthn on mobile) are biometric-bound by default and replace passwords. Most new auth flows should layer passkeys + OAuth.
- **Apple Vision Pro** introduced Optic ID — same `LAContext` API, new class.
- Android 14+ stricter `BiometricManager.Authenticators.BIOMETRIC_STRONG` requirement for crypto.
- App Store / Play guidelines now expect biometrics for any "private vault" feature.

---

## The "Why"

Sensitive operations need stronger proof than "the user once logged in". Biometric step-up provides that proof at the moment of action, with a UX users accept (a quick Face ID prompt vs typing a password). Done correctly with hardware-bound keys, it's the strongest mobile-only auth available. Companies care because customer-initiated fraud (account takeover via stolen device) is a major loss vector; step-up auth materially reduces it.

---

## Mental Model

Biometric-bound key = a sealed envelope inside a vault. The vault opens only with biometrics. You can ask for the envelope, OS opens vault, gives you the envelope, you use it once to sign a thing, then it's locked back up. The envelope never leaves the vault as a whole — only the signed paper comes out.

---

## Internal Working (2026 Context)

- iOS: SE generates EC P-256 keypair; private key never extractable. Public key returned to app. Operations via `SecKeyCreateSignature`.
- iOS `LAContext.evaluateAccessControl` triggers biometric prompt; on success, key access cached for context's lifetime.
- Android: `KeyStore` generates key with `setUserAuthenticationRequired`; `BiometricPrompt.authenticate(cryptoObject)` unlocks Cipher.
- Server side: store public key per user; verify ECDSA signature.

Threading: biometric prompts must run on UI thread. Crypto ops on background queue.

---

## Modern Implementation (Code)

**`react-native-biometrics` for biometric-bound signing**:

```ts
import ReactNativeBiometrics, { BiometryTypes } from 'react-native-biometrics';

const rnBiometrics = new ReactNativeBiometrics({ allowDeviceCredentials: false });

export async function setupBiometricKey(userId: string) {
  const { available, biometryType } = await rnBiometrics.isSensorAvailable();
  if (!available) throw new Error('biometrics unavailable');
  // generate keypair (Secure Enclave on iOS, Keystore on Android)
  const { publicKey } = await rnBiometrics.createKeys();
  // send public key to server, bind to user
  await api.registerBiometricKey({ userId, publicKey, biometryType });
}

export async function biometricStepUp(operationId: string): Promise<boolean> {
  // 1. fetch challenge from server
  const { challenge } = await api.getBiometricChallenge({ operationId });
  // 2. sign with biometric prompt
  const { success, signature } = await rnBiometrics.createSignature({
    promptMessage: 'Confirm transaction',
    payload: challenge,
    cancelButtonText: 'Cancel',
  });
  if (!success || !signature) return false;
  // 3. server verifies signature with stored public key
  const { ok } = await api.verifyBiometricSignature({ operationId, signature });
  return ok;
}
```

**Server verification (Node, EC P-256)**:

```ts
import crypto from 'node:crypto';

export function verifyBiometricSignature(publicKeyPem: string, challenge: string, sigB64: string) {
  const verifier = crypto.createVerify('SHA256');
  verifier.update(challenge);
  verifier.end();
  return verifier.verify(publicKeyPem, Buffer.from(sigB64, 'base64'));
}
```

**Native iOS — full SE-bound key (custom module)**:

```swift
let access = SecAccessControlCreateWithFlags(
  nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
  [.privateKeyUsage, .biometryCurrentSet], nil)!

let attributes: [String: Any] = [
  kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
  kSecAttrKeySizeInBits as String: 256,
  kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
  kSecPrivateKeyAttrs as String: [
    kSecAttrIsPermanent as String: true,
    kSecAttrApplicationTag as String: "com.app.biometric.key",
    kSecAttrAccessControl as String: access,
  ],
]
var error: Unmanaged<CFError>?
let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)!
```

**Native Android — Keystore biometric key**:

```kotlin
val keyGen = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
val spec = KeyGenParameterSpec.Builder("biometric_key", KeyProperties.PURPOSE_SIGN)
  .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
  .setDigests(KeyProperties.DIGEST_SHA256)
  .setUserAuthenticationRequired(true)
  .setInvalidatedByBiometricEnrollment(true)
  .setIsStrongBoxBacked(true)        // throws if no StrongBox; fallback in catch
  .build()
keyGen.initialize(spec); keyGen.generateKeyPair()

// signing with BiometricPrompt
val sig = Signature.getInstance("SHA256withECDSA").apply {
  initSign((KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    .getKey("biometric_key", null)) as PrivateKey)
}
val cryptoObject = BiometricPrompt.CryptoObject(sig)
biometricPrompt.authenticate(promptInfo, cryptoObject)
// on success callback: cryptoObject.signature.update(challenge); val signature = cryptoObject.signature.sign()
```

---

## Comparison

| Pattern | Security | UX | When |
|---|---|---|---|
| Boolean check | low (bypass-able) | simple | unlock UI only |
| Biometric-bound key | high | one prompt per op | step-up auth |
| Passkey (WebAuthn) | very high | one prompt | first-factor login |
| PIN / passcode fallback | medium | typing | accessibility |

| Library | Capability |
|---|---|
| `expo-local-authentication` | boolean + simple prompt |
| `react-native-biometrics` | + key binding + signature |
| `react-native-passkey` | passkey enroll/auth |
| Native module | full control |

---

## Production Usage

- **Banking transfers**: biometric step-up per transaction.
- **Password manager unlock**: bound key decrypts vault.
- **Crypto wallet sign**: SE/StrongBox key signs tx.
- **Profile changes**: step-up before email/phone update.
- **Re-auth after long idle**: biometric replaces password.

---

## Hands-On Exercise

1. **Implementation**: enroll biometric-bound key with server; verify step-up flow.
2. **Debugging**: signature verification fails server-side — check key encoding (DER vs raw, PEM vs base64).
3. **Architecture**: design biometric-step-up policy: which operations, what session age threshold.
4. **UX**: handle "no biometrics enrolled" / "lockout" / "user cancelled" gracefully.

---

## Common Mistakes

- Boolean-only check for sensitive ops.
- Allowing biometric without server-side challenge → replay possible.
- Not invalidating on re-enrollment → adversary adds their face, retains access.
- Storing the "biometric was just verified" flag in JS state.
- Ignoring fallback (no biometrics enrolled, broken sensor).
- Locking critical functions behind biometrics with no PIN fallback → support nightmare.

---

## Production Red Flags

- **`if (await biometric.authenticate()) { transferMoney() }`** without server verification.
- **Same biometric prompt for unlock and step-up** — should be distinct UX.
- **No telemetry on biometric failures** → blind to attacks.
- **Custom biometric UI** mimicking system → App Store rejection.

---

## Performance & Metrics (MANDATORY)

- **Key gen**: ~tens of ms.
- **Sign op**: ~ms inside SE/Keystore.
- **Biometric prompt**: dominated by user; ~1–2s with success.
- **Server verify**: ~ms.
- **Bundle**: biometrics lib ~50KB.

---

## Metrics That Matter

- Step-up success rate
- Biometric availability rate (per OS version)
- Re-enrollment-driven key invalidations
- Fallback-to-PIN rate
- Time from prompt to completion

---

## Decision Framework

| Operation | Auth |
|---|---|
| App launch | session token; biometric optional |
| View account | session token |
| Transfer money | biometric step-up (key-bound) |
| Add payment method | biometric step-up |
| Change email/password | biometric step-up + email confirmation |
| Export PII | biometric + server re-auth |

---

## Senior-Level Insight

The mature take: **biometric step-up is part of an authorization architecture**, not just a UI prompt. The server defines which operations require step-up, the client requests challenges, signs, and submits. The OS biometric prompt is the *enforcement point* — but the decision is server-side. This makes the security policy auditable and updatable without app releases.

Senior engineers also: (1) test against rooted/jailbroken devices, (2) have a kill switch for biometric step-up if a vendor SDK breaks, (3) document biometric strength requirements per operation, (4) support hardware-attested keys for highest tiers (combine with Q4 attestation).

---

## Real-World Scenario

**Symptom:** Family member can authorize transfers on victim's phone using their own face.
**Investigation:** App used `.biometryAny` access control; victim had added family member to Face ID.
**Root Cause:** Wrong access control level allowed any enrolled biometric.
**Fix:** Use `.biometryCurrentSet`; key invalidated on any enrollment change; victim must re-enroll key.
**Lesson:** `CurrentSet` is the right default for high-security flows.

---

## Production Failure Story

**Incident:** A trading app's "Touch ID to confirm trade" was a JS-layer boolean. Researchers at a security conference demonstrated bypass via Frida hooking — completed unauthorized trades on test accounts in seconds.
**Impact:** Public disclosure; emergency hotfix; customer trust hit.
**Investigation:** Code path: `if (await touchId()) submitTrade()`. No server-side proof.
**Root Cause:** Naive biometric pattern instead of bound-key signing.
**Fix:** Server-issued challenge; biometric-unlocked key signs; server verifies. Bypass infeasible without device + biometric.
**Prevention:** Security review checklist requires bound-key pattern for any money/data movement.

---

## Debugging Checklist

1. Verify key generation succeeded (catch StrongBox unavailability).
2. Public key registered server-side and associated with user.
3. Challenge is per-request (no replay).
4. Signature format matches server expectation (DER vs raw, hash inside or outside).
5. Re-enrollment behavior matches policy.
6. Fallback path tested: no biometric, lockout, cancel.

---

## Advanced / Internal Knowledge

- iOS Secure Enclave uses ECDSA P-256; cannot use RSA in SE.
- Android key attestation: `KeyStore.getCertificateChain` returns chain provable against Google root → can prove key is in StrongBox.
- `LAContext.touchIDAuthenticationAllowableReuseDuration` (iOS) — cache auth for N seconds.
- `BiometricPrompt.PromptInfo.Builder().setAllowedAuthenticators(BIOMETRIC_STRONG)` — Android Class 3 only.
- WebAuthn passkeys use the same SE/Keystore underneath.

---

## 2026 AI Tip

- AI is **good at**: scaffolding `react-native-biometrics` flows.
- AI is **bad at**: native key attestation specifics.
- **Prompt pattern**: "Implement biometric step-up: server challenge → biometric-bound key signature → server verify. Use react-native-biometrics on client and Node EC verification on server."

---

## Related Topics

- Q1 OAuth (combine with biometric step-up)
- Q2 Keychain/Keystore
- Q4 attestation
- S30 privacy

---

## Interview Follow-Up Questions

- Why is "boolean biometric check" insecure?
- What invalidates a biometric-bound key?
- How does a server verify biometric occurred?
- What's the difference between SE and StrongBox?
- How do passkeys relate to biometric-bound keys?

---

## Memory Hook

**"Bind key to biometric, sign server challenge, never trust the boolean."**

## Revision Notes

> Biometric boolean = bypass-able. Biometric-bound key in SE/StrongBox = strong. Server issues challenge; OS unlocks key on biometric; signature is proof. Use `CurrentSet` / `InvalidatedByBiometricEnrollment` for high security. Always provide fallback.

---

---

### Q4. App attestation — Apple App Attest + Google Play Integrity

---

## Difficulty
- Advanced

## Interview Frequency
- Niche but rising (fintech, gaming, anti-abuse)

## Prerequisites
- Asymmetric crypto, JWT, server-side verification

## TL;DR
**App Attest (iOS) + Play Integrity (Android)** prove that a request came from your **genuine, unmodified app on a non-tampered device**. The OS issues a hardware-backed signed assertion; your server verifies with Apple/Google APIs. Use it to gate **server-side** mutations from clients you can't trust (account creation, abuse-prone endpoints, IAP grants).

---

## 30-Second Interview Answer

> "Attestation answers: 'Is this request from my real app on a real device?' iOS App Attest uses a Secure Enclave key registered with Apple's attestation service; client signs each request payload, server verifies via Apple. Android Play Integrity returns a JWT from Google with verdicts (`MEETS_DEVICE_INTEGRITY`, `MEETS_BASIC_INTEGRITY`, `MEETS_STRONG_INTEGRITY`); server verifies the JWT signature and inspects verdicts. Apply it on high-abuse endpoints (signup, redemption, leaderboard submit). It's not a silver bullet — sophisticated attackers bypass — but it raises the cost dramatically and filters most low-effort fraud."

---

## 2-Minute Practical Answer

iOS App Attest flow:
```
1. App generates key in Secure Enclave (DCAppAttestService.generateKey).
2. App requests challenge from server.
3. App calls attestKey(keyId, clientDataHash) — Apple returns attestation object.
4. Server validates attestation (cert chain, app ID, challenge match).
5. Server stores keyId + public key for this install.
6. Per request: app signs request data with key (DCAppAttestService.generateAssertion).
7. Server verifies assertion against stored public key.
```

Android Play Integrity flow:
```
1. App requests integrity token from Play (IntegrityManager.requestIntegrityToken).
2. Play returns signed JWT.
3. App sends token + request to server.
4. Server decrypts/verifies JWT via Google API.
5. Server checks verdicts:
   - deviceIntegrity: MEETS_DEVICE_INTEGRITY (genuine device)
   - appIntegrity: PLAY_RECOGNIZED (your app, signed properly)
   - accountDetails: LICENSED (Play Store account)
6. Server allows/blocks based on policy.
```

What it catches:
- Reverse-engineered repackaged apps.
- Emulators / rooted devices (configurable).
- Frida / Xposed hooks (signal varies).
- Replays (challenge-bound).

What it doesn't catch:
- Sophisticated attackers with custom HW.
- MitM attacks (use TLS pinning).
- Server-side abuse (e.g., compromised credentials).
- Slow attackers patient enough to mine bypasses.

Cost / complexity:
- iOS: ~free, requires Secure Enclave (iOS 14+, A10+).
- Android: free up to 10k req/day; $$$ for higher; rate-limit on client.
- Server-side adds latency (~100s of ms for Play Integrity).
- Don't run on every request — pick high-value endpoints.

---

## 5-Minute Architecture Answer

App attestation moves trust from "you said you're my app" to "Apple/Google's hardware confirms you're my app". The threat addressed: **botnets running modified versions of your app, hitting your endpoints to commit fraud**. Examples: fake account creation, scraping at scale, gaming leaderboards, IAP receipt forgery, points/coupon redemption abuse.

Architecture:
1. **Enrollment** (one-time per install):
   - Client generates attestation key.
   - Client + server complete attestation handshake.
   - Server persists `(installId, publicKey, deviceClass)`.

2. **Per-request assertion**:
   - Server issues challenge (or client uses request hash).
   - Client signs request payload + challenge.
   - Server verifies signature against stored public key.

3. **Risk policy**:
   - Different endpoints have different attestation requirements.
   - Account creation: strict (require attestation).
   - Read-only feed: skip (overhead not worth it).
   - High-value mutation: require + biometric.

iOS App Attest specifics:
- Hardware-backed via Secure Enclave (A10 / iOS 14+).
- Attestation cert chain rooted at Apple.
- Can be revoked by Apple if abused.
- `DCAppAttestService.isSupported` — check first.

Android Play Integrity specifics:
- JWT contains: `requestDetails`, `appIntegrity`, `deviceIntegrity`, `accountDetails`.
- `MEETS_DEVICE_INTEGRITY` — passes basic + bootloader/SafetyNet checks.
- `MEETS_BASIC_INTEGRITY` — Android device but might be rooted.
- `MEETS_STRONG_INTEGRITY` — hardware-backed key attestation.
- Cloud Project Number must match Play Console.
- Token includes `nonce` you provide — bind to your request.

Server-side verification — must be done **server-side**, never trust client to self-report:
- iOS: validate cert chain against Apple root, check app ID, signature.
- Android: send token to Play Integrity API; Google returns decoded payload with signature already verified.

The 2026 specific:
- **iOS 17+ Privacy Manifests** require declaring App Attest usage in some categories.
- **Play Integrity standard tier vs classic** — standard recommended; classic deprecated.
- **DeviceCheck** (older iOS API) is still useful for `setBits` (per-install flags); App Attest is the newer general-purpose tool.
- **WebAuthn / FIDO2** + attestation overlap — passkeys carry attestation natively.
- **Anti-fraud vendors** (Sift, Forter) integrate attestation signals.

When NOT to use:
- Apps with no abuse-prone endpoints (rare).
- Low-volume internal apps.
- Endpoints already protected by other means (auth + rate limits).

---

## The "Why"

Without attestation, every API endpoint is reachable by `curl` once an attacker reverse-engineers your auth. Some attacks scale linearly with cost-per-request; attestation makes the unit cost (computing on real devices) much higher than scripting. Companies care because abuse → cost (servers, free credits, support, fraud loss) and trust damage. Attestation is the most effective single control against scripted abuse.

---

## Mental Model

Attestation = a notary on your phone. Every important request gets a notarized signature saying "this came from a real app on a real device." Your server only accepts notarized requests for high-risk operations.

---

## Internal Working (2026 Context)

- **iOS App Attest**: SE generates EC P-256 key; Apple attests its presence in genuine SE via signed cert. Apple's attestation service issues a per-key cert chain; server validates.
- **Android Play Integrity**: Google Play Services queries device hardware (StrongBox if available), assembles verdicts, signs JWT with Google's key.
- Both use challenge-response to prevent replay.
- Both can be invalidated/revoked by platform vendor.

---

## Modern Implementation (Code)

**iOS — App Attest enrollment** (Swift, native module):

```swift
import DeviceCheck

let service = DCAppAttestService.shared
guard service.isSupported else { /* fallback or block */ return }

service.generateKey { keyId, error in
  guard let keyId = keyId else { return }
  // store keyId locally
  fetchChallenge { challenge in
    let clientDataHash = Data(SHA256.hash(data: challenge))
    service.attestKey(keyId, clientDataHash: clientDataHash) { attestation, error in
      guard let attestation = attestation else { return }
      // POST to your server with keyId + attestation + challenge
    }
  }
}
```

**iOS — per-request assertion**:
```swift
let payload = "{\"op\":\"transfer\",\"amt\":100}".data(using: .utf8)!
let clientDataHash = Data(SHA256.hash(data: payload + challenge))
service.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
  // send (payload, assertion, challenge) to server
}
```

**Android — Play Integrity** (Kotlin):
```kotlin
val integrityManager = IntegrityManagerFactory.create(context)
val nonce = randomNonce()  // your server-issued challenge

integrityManager.requestIntegrityToken(
  IntegrityTokenRequest.builder()
    .setNonce(nonce)
    .setCloudProjectNumber(YOUR_GCP_PROJECT_NUMBER)
    .build()
)
.addOnSuccessListener { response ->
  val token: String = response.token()
  // POST token + request to server
}
.addOnFailureListener { /* handle / fallback */ }
```

**RN cross-platform via `react-native-attestation`** (or vendor SDK):
```ts
import { Attestation } from 'react-native-attestation';

const ready = await Attestation.isSupported();
if (!ready) return; // fallback path

await Attestation.enroll();   // one-time
const challenge = await api.getChallenge();
const assertion = await Attestation.assert({ challenge, payload: JSON.stringify(body) });

await api.submitTransfer({ ...body, attestation: assertion });
```

**Server-side verification (Node, Play Integrity)**:
```ts
import { google } from 'googleapis';

const playintegrity = google.playintegrity('v1');

export async function verifyAndroidIntegrity(token: string, expectedNonce: string) {
  const auth = await google.auth.getClient({
    scopes: ['https://www.googleapis.com/auth/playintegrity'],
  });
  const res = await playintegrity.v1.decodeIntegrityToken({
    auth,
    packageName: 'com.example.app',
    requestBody: { integrityToken: token },
  });
  const payload = res.data.tokenPayloadExternal!;
  if (payload.requestDetails?.nonce !== expectedNonce) throw new Error('nonce mismatch');
  const verdicts = payload.deviceIntegrity?.deviceRecognitionVerdict ?? [];
  if (!verdicts.includes('MEETS_DEVICE_INTEGRITY')) throw new Error('device verdict failed');
  if (payload.appIntegrity?.appRecognitionVerdict !== 'PLAY_RECOGNIZED') throw new Error('app verdict failed');
  return payload;
}
```

---

## Comparison

| API | Platform | Hardware-backed | Latency |
|---|---|---|---|
| App Attest | iOS 14+ A10+ | yes (SE) | low (local sign) |
| DeviceCheck | iOS 11+ | partial | low |
| Play Integrity Standard | Android | yes (StrongBox where available) | ~100ms+ (cloud) |
| SafetyNet [DEPRECATED] | Android (legacy) | partial | medium |
| Firebase App Check | both | wraps the above | medium |

| Vendor | Pros |
|---|---|
| Native (App Attest + Play Integrity) | direct, no vendor cost |
| Firebase App Check | unified API, ties into Firebase |
| Sift / Forter / Castle | bundled fraud signals |

---

## Production Usage

- **Account creation** (vs bot signups).
- **Coupon redemption / referral bonuses**.
- **Leaderboard submissions** (anti-cheat).
- **IAP receipt validation** (extra layer alongside server-side validation).
- **Critical mutations** in fintech.
- **Anti-scraping** for proprietary feeds.

---

## Hands-On Exercise

1. **Implementation**: enroll + assert via App Attest on iOS, Play Integrity on Android.
2. **Debugging**: verdicts come back as `UNKNOWN_DEVICE_INTEGRITY` — investigate emulator / project number.
3. **Architecture**: design endpoint-by-endpoint attestation policy.
4. **Cost**: estimate Play Integrity cost at projected request volume; design per-session caching.

---

## Common Mistakes

- Not binding nonce to actual request → replay possible.
- Trusting client-reported verdicts → meaningless.
- Running attestation on every request → cost + latency.
- No fallback for old devices → legitimate users blocked.
- Storing attestation public keys per user instead of per install.
- Forgetting to handle attestation revocation → app suddenly broken.

---

## Production Red Flags

- **Client checks integrity itself and skips on failure** → trivially bypassed.
- **No server-side verdict policy** → attestation is theater.
- **No telemetry on verdict distribution** → blind to attack patterns.
- **Same attestation token reused across requests** → cached replay.

---

## Performance & Metrics (MANDATORY)

- **iOS assertion**: ~ms (local SE op).
- **Android integrity**: ~100ms+ (cloud roundtrip).
- **Server verify**: ~tens of ms (Apple) / Google API call.
- **Bundle**: small SDK size.
- **Cost**: Play Integrity quotas — design caching.

---

## Metrics That Matter

- Verdict distribution (per platform, per region)
- Attestation-failure rate (catches abuse + legit issues)
- Per-endpoint enforcement rate
- Cost per million requests

---

## Decision Framework

| Endpoint | Attestation? |
|---|---|
| Read public feed | no |
| Sign in | maybe (after several failures) |
| Create account | yes (strict) |
| Transfer money | yes + biometric |
| Submit leaderboard | yes |
| Redeem coupon | yes |
| Fetch profile | no |

---

## Senior-Level Insight

The mature take: **attestation is one signal in a fraud stack**. Combine with: rate limiting, device fingerprinting, behavioral signals, velocity checks, IP reputation. Don't make pass/fail decisions on attestation alone — score it. Senior engineers design the fraud system as a Bayesian risk model where attestation contributes weight, not a gate.

Org-level: own a fraud-signals library; standardize verdict shapes; integrate with anti-fraud vendor if scale warrants. Document expected verdict baselines per region (some regions have many genuine non-Play devices).

---

## Real-World Scenario

**Symptom:** Referral bonus program flooded with fake redemptions; thousands of new accounts in 24h.
**Investigation:** Endpoint had no attestation; attackers spun up emulators with auto-signup script.
**Root Cause:** No proof requests came from genuine app.
**Fix:** Enable Play Integrity + App Attest on signup + redemption endpoints; require `MEETS_STRONG_INTEGRITY` for redemption.
**Lesson:** High-value endpoints must require attestation.

---

## Production Failure Story

**Incident:** A new app's Day-1 launch saw legitimate iOS users blocked because App Attest enrollment failed silently for ~8% of installs (older devices without SE).
**Impact:** Negative reviews, support flood, partial rollback.
**Investigation:** `DCAppAttestService.isSupported` was checked, but failure cascaded to "block user" instead of "graceful fallback to other signals".
**Root Cause:** Hard fail vs soft fail policy not defined.
**Fix:** Treat attestation as one signal; for unsupported devices, rely on rate limiting + behavioral.
**Prevention:** Define fallback matrix: device class × verdict → action.

---

## Debugging Checklist

1. Verify project number / app ID matches Play Console / Apple Developer.
2. Confirm nonce/challenge round-trip correct.
3. Inspect verdict payload server-side.
4. Test on emulator (should fail) vs real device (should pass).
5. Verify SE / StrongBox availability check before enroll.
6. Telemetry: per-endpoint verdict distribution.

---

## Advanced / Internal Knowledge

- App Attest cert chain: Apple App Attest CA → device cert → key cert.
- Play Integrity uses Google's Tink JWS internally.
- iOS DCDevice (DeviceCheck) supports persistent per-install bits — pair with App Attest.
- Firebase App Check uses these under the hood with caching.
- Hardware key attestation on Android via `KeyStore` cert chain — provable StrongBox.

---

## 2026 AI Tip

- AI is **good at**: scaffolding integration code.
- AI is **bad at**: nuanced verdict-policy design.
- **Prompt pattern**: "Implement App Attest on iOS + Play Integrity on Android with server verification in Node, including nonce binding and verdict policy."

---

## Related Topics

- Q3 biometrics
- S15 Q4 IAP (attestation alongside receipt validation)
- S22 anti-fraud system design

---

## Interview Follow-Up Questions

- What does App Attest prove that TLS doesn't?
- Difference between `BASIC_INTEGRITY` and `STRONG_INTEGRITY`?
- When would attestation pass but the request still be fraud?
- How do you handle devices without SE/StrongBox?
- What's the cost model for Play Integrity at scale?

---

## Memory Hook

**"Hardware-attest the request, server-verdict the response."**

## Revision Notes

> App Attest (iOS) + Play Integrity (Android). Bind nonce per request. Verify server-side. Use on high-value endpoints. Combine with other fraud signals. Fallback for unsupported devices. Standard tier > classic.

---

---

### Q5. OWASP MASVS 2026 — what changed, top controls

---

## Difficulty
- Advanced

## Interview Frequency
- Common (security-focused roles)

## Prerequisites
- Auth, storage, transport basics

## TL;DR
**MASVS** (Mobile Application Security Verification Standard) defines the security requirements; **MASTG** is the testing guide. The 2026 model is organized into **8 control groups** (storage, crypto, auth, network, platform, code, resilience, privacy). Top RN focus areas: **secure storage tiers**, **cert pinning + dynamic rotation**, **biometric step-up with bound keys**, **app attestation**, **privacy manifests**.

---

## 30-Second Interview Answer

> "MASVS is OWASP's mobile security verification standard. The current model has eight control groups: Storage, Crypto, Auth, Network, Platform, Code, Resilience, Privacy. The top five RN-impacting controls in 2026 are: (1) hardware-backed secure storage for secrets, (2) modern TLS + cert pinning with rotation, (3) OAuth 2.1 + PKCE + biometric step-up, (4) app attestation for high-value endpoints, (5) privacy manifests + ATT compliance. MASTG provides test cases per control. For RN apps, also enforce: no JS-layer secrets, no debug code in release, ProGuard/Hermes obfuscation, and a documented threat model."

---

## 2-Minute Practical Answer

MASVS control groups (2026):

| Group | Focus |
|---|---|
| **MASVS-STORAGE** | secure storage tiers; no secrets in plaintext |
| **MASVS-CRYPTO** | modern algorithms (AES-GCM, ECDSA P-256); HW-backed where possible |
| **MASVS-AUTH** | OAuth 2.1 + PKCE; MFA / step-up; session mgmt |
| **MASVS-NETWORK** | TLS 1.2+ (1.3 preferred); pinning; reject weak ciphers |
| **MASVS-PLATFORM** | proper IPC; deep link validation; permission scopes |
| **MASVS-CODE** | obfuscation; no debug in release; safe deps |
| **MASVS-RESILIENCE** | tamper detection; root/jailbreak; emulator detection; attestation |
| **MASVS-PRIVACY** | minimization; manifests; consent; transparency |

Verification levels:
- **L1** — baseline; all apps.
- **L2** — sensitive data; finance, health, gov.
- **L3** (resilience) — additional anti-tamper for high-value targets.

RN-specific concerns:
- **JS bundle is reverse-engineerable** — Hermes bytecode obfuscates but doesn't encrypt; assume readable.
- **Debug builds**: `__DEV__` checks must not gate security paths.
- **Source maps**: never ship in release.
- **Universal/App Links**: must verify domain ownership.
- **WebView in app**: huge attack surface; sanitize URLs, disable JS where possible.
- **Native modules**: third-party packages with native code are supply-chain risk.
- **Codepush / EAS Update**: signed updates only; don't allow JS-only RCE.

The top 10 audit items I check on any RN app:

1. No secrets in `AsyncStorage`.
2. Refresh token in Keychain/Keystore w/ `ThisDeviceOnly`.
3. PKCE used; no embedded WebView for OAuth.
4. TLS 1.2+; cert pinning enabled with rotation plan.
5. Biometric step-up uses bound keys (not boolean).
6. No `console.log` of tokens / PII in production.
7. ProGuard/R8 + Hermes; source maps stripped.
8. No `__DEV__` security bypasses in release.
9. Privacy Manifests / ATT prompts correct.
10. App attestation on high-value endpoints.

---

## 5-Minute Architecture Answer

MASVS gives a checklist; MASTG gives the tests; together they're an industry-shared baseline for "what does 'secure mobile app' mean". They're also the framework auditors and bug-bounty programs use, so aligning saves time during external review.

How I'd structure security work for an RN app:

1. **Threat model first** (per feature):
   - Who attacks?
   - What can they reach?
   - What's the impact?
   - What controls mitigate?

2. **Map to MASVS controls**:
   - Storage tier per data type (Q2).
   - Auth flow per access level (Q1, Q3).
   - Transport per endpoint (TLS, pinning, attestation).

3. **Implement** with libraries that hide gotchas:
   - `react-native-keychain`, `react-native-mmkv`, `react-native-app-auth`, `react-native-biometrics`.
   - Vendor SDKs where appropriate.

4. **Verify** with MASTG-aligned tests:
   - Static analysis (ESLint, SonarQube, MobSF).
   - Dynamic (Frida hooks, Burp/mitmproxy).
   - Manual (jailbroken/rooted device tests).

5. **Operate**:
   - Telemetry on auth failures, attestation verdicts, pin failures.
   - SBOM (Software Bill of Materials) for supply-chain awareness.
   - Vulnerability triage process.

The 2026 specific:
- **Privacy Sandbox** (Android) and **Privacy Manifests** (iOS) shifted privacy from "do the right thing" to "declare what you do" — auditable, enforceable.
- **DSA** (EU) introduced transparency and consent requirements for many app categories.
- **PCI Mobile Payment 5.0** mandates HW-backed key + attestation for card data on device.
- **NIST 800-218 (SSDF)** is increasingly cited in RFPs — covers secure development lifecycle.
- **SBOM mandates** (CISA / EU) — generate and ship with releases.

What MASVS doesn't cover:
- Server-side security (use OWASP ASVS for backend).
- Network security at the org level (zero-trust networks etc.).
- Social engineering / phishing.

---

## The "Why"

Security has no finish line; a checklist forces breadth. MASVS prevents you from over-investing in one area (e.g., crypto) while leaving another wide open (e.g., deep-link validation). Companies care because audits, certifications (ISO 27001, SOC 2), enterprise procurement, and bug-bounty triage all reference MASVS.

---

## Mental Model

MASVS = a building inspector's checklist. You don't get to skip the wiring inspection because you nailed the foundation. Every category must clear baseline; sensitive apps clear higher.

---

## Internal Working (2026 Context)

- MASVS is maintained by OWASP MASTG team; control groups stable since v2; v2026 refines wording, adds privacy items.
- MASTG provides test methodology + tools (Frida, MobSF, Drozer, Objection).
- Vendor scanners (NowSecure, Veracode, Checkmarx) implement MASTG checks.
- Hermes bundles can be inspected with `hbcdump`; ProGuard/R8 mappings reverse with `retrace`.

---

## Modern Implementation (Code)

**Security review checklist (CI-enforced examples)**:

```ts
// eslint custom rule pseudo-code
'no-asyncstorage-secrets': {
  patterns: [
    { pattern: /AsyncStorage\.setItem\(['"]token/, message: 'secrets must use Keychain' },
    { pattern: /AsyncStorage\.setItem\(['"](refresh|password|secret)/, message: 'secrets must use Keychain' },
  ],
},
'no-console-log-tokens': {
  patterns: [
    { pattern: /console\.log.*token/i, message: 'never log tokens' },
  ],
},
```

**`metro.config.js`** — strip `console.log` in release:

```js
module.exports = {
  transformer: {
    minifierConfig: {
      compress: { drop_console: true },  // production only
    },
  },
};
```

**Babel plugin to strip `__DEV__` blocks** (for release):
```js
plugins: [
  process.env.NODE_ENV === 'production' && 'babel-plugin-transform-remove-console',
].filter(Boolean),
```

**Privacy Manifest** (iOS `PrivacyInfo.xcprivacy`):
```xml
<plist version="1.0">
  <dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
      <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array><string>CA92.1</string></array>
      </dict>
    </array>
    <key>NSPrivacyTracking</key><false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
      <dict>
        <key>NSPrivacyCollectedDataType</key>
        <string>NSPrivacyCollectedDataTypeEmailAddress</string>
        <key>NSPrivacyCollectedDataTypeLinked</key><true/>
        <key>NSPrivacyCollectedDataTypeTracking</key><false/>
        <key>NSPrivacyCollectedDataTypePurposes</key>
        <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
      </dict>
    </array>
  </dict>
</plist>
```

**SBOM generation** (`@cyclonedx/cyclonedx-npm`):
```bash
npx @cyclonedx/cyclonedx-npm --output-file bom.json
```

---

## Comparison

| Standard | Scope |
|---|---|
| **MASVS** | mobile app controls |
| **MASTG** | mobile testing guide |
| OWASP ASVS | server-side / web |
| OWASP Top 10 | web vulnerabilities (overlaps mobile) |
| NIST 800-218 (SSDF) | secure dev lifecycle |
| ISO 27001 | org infosec |
| SOC 2 | service controls |
| PCI DSS / PCI Mobile | payment cards |

| Verification level | Use |
|---|---|
| L1 | baseline (all apps) |
| L2 | sensitive (finance, health) |
| L3 (resilience) | high-value targets (banking, gov) |

---

## Production Usage

- **Compliance audits**: SOC 2 / ISO 27001 reviewers cite MASVS.
- **Bug bounty programs**: scope often references MASVS controls.
- **Vendor due-diligence**: enterprise customers ask for MASVS conformance.
- **Internal security gates**: "must meet L1 to release; L2 for finance features".
- **App store reviews**: Apple/Google reference MASVS-aligned items (e.g., privacy, ATS).

---

## Hands-On Exercise

1. **Implementation**: run MobSF on a test build; triage findings against MASVS L1.
2. **Debugging**: a Frida hook bypasses your biometric check — refactor to bound-key pattern (Q3).
3. **Architecture**: design a security review process: gates per feature, sign-off owners.
4. **Documentation**: produce a MASVS L1 self-assessment for your app.

---

## Common Mistakes

- Treating MASVS as one-time checklist instead of continuous.
- Skipping Privacy / Resilience groups because they "don't apply".
- No threat model → controls misaligned with risk.
- Assuming third-party libraries are secure — vet them.
- Ignoring supply chain (postinstall scripts, malicious packages).
- Forgetting the platform changes (annual iOS / Android security updates).

---

## Production Red Flags

- **No security owner / RACI** → drift inevitable.
- **No SBOM** → can't respond to CVEs in deps quickly.
- **`adbBackupAllowed=true`** in production manifest.
- **Source maps shipped in release** → easy reverse engineering.
- **Privacy Manifest missing** → App Store rejection (since 2024).

---

## Performance & Metrics (MANDATORY)

- Most controls are zero-runtime (compile-time / config).
- Pinning, attestation add latency (covered in their Q-topics).
- Obfuscation may slow build but not runtime materially.

---

## Metrics That Matter

- MASVS controls met (per level)
- Bug-bounty findings per release
- Time-to-patch on disclosed vulnerabilities
- Coverage of MASTG test cases
- SBOM-tracked CVE exposure

---

## Decision Framework

| Risk profile | Target |
|---|---|
| Consumer app, low data sensitivity | MASVS L1 |
| Healthcare, finance | L2 |
| Banking, defense | L2 + Resilience |
| Internal employee app | L1 baseline + corp policy |
| White-label SDK | L2 (your customers depend on you) |

---

## Senior-Level Insight

The mature take: **MASVS is a contract between security and engineering**. Engineering implements; security verifies; both align on level per feature. Senior engineers also embrace it as a learning tool — every junior who ships a feature should be able to map their work to MASVS controls. This builds organizational security literacy.

Org-level: maintain a security-champion program (one champion per team); review MASVS L1 quarterly for drift; budget for annual external pentest aligned to L2/L3.

---

## Real-World Scenario

**Symptom:** Bug bounty researcher found refresh token in `AsyncStorage` and submitted as P1.
**Investigation:** Rapid rewrite to Keychain; turned into broader audit.
**Root Cause:** No MASVS-aligned review at feature ship.
**Fix:** Migrate, plus add CI rule preventing recurrence.
**Lesson:** Without explicit checks, easy mistakes ship.

---

## Production Failure Story

**Incident:** A consumer app shipped Hermes bundle with source maps included. A researcher reverse-engineered an internal endpoint URL pattern and probed it, finding an IDOR (Insecure Direct Object Reference) on the backend.
**Impact:** PII leak across thousands of accounts; mandatory disclosure.
**Investigation:** Source maps in release; backend lacked authorization check on a particular path.
**Root Cause:** Multiple MASVS failures (Code group: ship maps; backend not in MASVS scope but the chain hurt).
**Fix:** Strip source maps; backend authorization audit; adopt MASVS L2.
**Prevention:** Release pipeline gate strips maps; MASVS audit per release.

---

## Debugging Checklist

1. Run MobSF / NowSecure on release build.
2. Inspect Hermes bundle (`hbcdump`) — verify no secrets in source.
3. Test rooted Android device — observe what's exfiltrable.
4. Test jailbroken iOS — Keychain access patterns.
5. Verify Privacy Manifest matches actual data collected.
6. Verify SBOM includes all transitive deps.

---

## Advanced / Internal Knowledge

- MASVS-RESILIENCE includes: root detection, debugger detection, hooking detection, integrity monitoring, anti-tamper. Nothing is foolproof; raise cost.
- Hermes bytecode (`hbcdump`) reveals function names + string literals; minify identifiers via Metro config.
- iOS App Transport Security (`NSAppTransportSecurity`) defaults block insecure HTTP since iOS 9; only allow exceptions deliberately.
- Android `usesCleartextTraffic="false"` in manifest blocks plain HTTP.
- Supply-chain: prefer locked deps (`package-lock.json`), audit `postinstall` scripts.

---

## 2026 AI Tip

- AI is **good at**: generating policy docs and CI checks aligned to MASVS.
- AI is **bad at**: organization-specific risk decisions.
- **Prompt pattern**: "Generate a MASVS L2 self-assessment template for an RN app handling financial data, with concrete RN-specific implementation notes per control."

---

## Related Topics

- Q1–Q4 of S10
- S9 Q5 cert pinning
- S30 privacy compliance
- S20 release pipelines

---

## Interview Follow-Up Questions

- What's the difference between MASVS L1, L2, L3?
- Which RN-specific risks does MASVS surface?
- How do you operationalize MASVS in CI?
- What's MASTG and how do you use it?
- How do Privacy Manifests fit MASVS-PRIVACY?

---

## Memory Hook

**"Eight groups, three levels, audit every release."**

## Revision Notes

> MASVS = mobile checklist; MASTG = tests. 8 control groups: Storage, Crypto, Auth, Network, Platform, Code, Resilience, Privacy. Levels L1–L3 by sensitivity. Top RN priorities: storage tiers, pinning, OAuth+biometric+attestation, privacy manifests. Operationalize via CI rules + SBOM + periodic audits.

---

> **End of S10.** Cross-refs: S9 (TLS, pinning), S15 (native bridging for biometric/attestation), S11 (offline storage encryption), S30 (privacy manifests, ATT). Next deep section: [S11 Offline-First](S11-offline-first.md).
