# S12 — Push Notifications & Background

> APNs · FCM · Expo Notifications · token lifecycle · silent push · BGTask · WorkManager · deliverability

Push is the highest-leverage retention channel and the most fragile pipeline in mobile. Senior interviews probe **lifecycle** (registration, rotation, dedup), **payload classes** (alert/data/silent), **deep linking** (cold vs warm), and **deliverability measurement**. 2026 specifics: **Live Activities / Dynamic Island**, **Android 13+ POST_NOTIFICATIONS runtime permission**, **iOS Focus modes**, **Notification Service Extensions** for rich + decryption.

---

### Q1. APNs vs FCM vs Expo Notifications — pick what

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Very Common

## Prerequisites
- HTTP/2, JWT, certificate vs token auth basics

## TL;DR
**APNs** = Apple's push for iOS, native HTTP/2 + JWT (token-based auth, p8 key). **FCM** = Google's push for Android (and a relay to APNs). **Expo Notifications** = cross-platform abstraction over both, with Expo's push service as an optional relay (no shared secrets to your app). For 2026: most production teams send **directly** to APNs + FCM from their backend with token-based auth; Expo push service is great for prototypes and small teams. Use Expo's client SDK regardless for permission + token + handler ergonomics.

---

## 30-Second Interview Answer

> "APNs and FCM are the OS-level push services. APNs uses HTTP/2 with JWT; FCM uses HTTP v1 with OAuth. They have different payload shapes, different priority models, different deliverability rules. Expo Notifications gives you one client API (`getDevicePushTokenAsync`, notification handlers, channels) and an optional cloud relay. In production, large apps send straight to APNs/FCM from their backend for control, latency, and audit; smaller apps use Expo's relay. The client SDK is universally useful — permission flow, handler, channel registration, deep-link parsing."

---

## 2-Minute Practical Answer

**APNs basics**:
- HTTP/2, persistent connection.
- Auth: **token-based** (`p8` key, JWT signed every <1h) — preferred over legacy certificate auth.
- Payload: 4KB max (5KB for VoIP / Critical).
- Topic = bundle ID; environment = sandbox vs production.
- Priority: `5` (background) or `10` (immediate alert).
- Push types: `alert`, `background` (`content-available: 1`), `voip`, `complication`, `liveactivity`.

**FCM basics**:
- HTTP v1 API (legacy server keys [DEPRECATED 2024]).
- Auth: OAuth2 via service account JSON.
- Payload: ~4KB (notification + data).
- `notification` payload → system tray automatically.
- `data` payload → app handles.
- `priority: high` / `normal`.
- Topics, conditions, registration tokens.

**Expo Notifications**:
- Client API for both (`expo-notifications`).
- Server option: `POST https://exp.host/--/api/v2/push/send` with Expo push tokens.
- Expo translates to APNs/FCM internally.
- Don't ship Expo push tokens long-term in regulated environments — prefer device push tokens (`getDevicePushTokenAsync`) and your own backend.

**Decision matrix**:

| Need | Pick |
|---|---|
| Prototype / small app | Expo push relay |
| Large app, audit / latency | direct APNs + FCM |
| Cross-platform abstraction | Expo client + your backend |
| Live Activities / Dynamic Island | direct APNs (special path) |
| VoIP push | direct APNs (PushKit) |

**Token types**:
- **Expo push token**: `ExponentPushToken[xxx]` — opaque, routed via Expo.
- **Device push token**: raw APNs/FCM token — you send directly.

```ts
import * as Notifications from 'expo-notifications';
const expo = (await Notifications.getExpoPushTokenAsync({ projectId })).data;
const device = (await Notifications.getDevicePushTokenAsync()).data;
```

---

## 5-Minute Architecture Answer

End-to-end flow:
1. App requests permission (iOS: `requestPermissionsAsync`; Android 13+: runtime POST_NOTIFICATIONS permission).
2. App registers with APNs/FCM, gets push token.
3. App sends token + user/device metadata to your backend.
4. Backend stores token in token store keyed by user + device.
5. Server event fires → backend selects tokens → sends to APNs/FCM (or Expo relay).
6. APNs/FCM delivers to device → OS shows notification or wakes app.
7. User taps → app handles deep link (cold start vs background).
8. Failed deliveries → backend marks token invalid → removes.

Architecture decisions:
- **Direct APNs/FCM** vs **Expo relay**: direct = full control, ~100ms lower latency, audit logs; relay = simpler, batch optimizations.
- **One token per device per user** vs **one per user**: per-device-per-user is correct (multi-device).
- **Token rotation**: APNs/FCM may rotate tokens; client must re-register. Backend dedup on (user, device).
- **Deliverability monitoring**: track tokens sent vs delivered (APNs success ≠ user saw it); add per-message receipts via Expo or analytics ping when notification opens.

iOS-specific:
- **Notification Service Extension (NSE)**: separate target for modifying/decrypting payload before display.
- **Notification Content Extension**: custom UI.
- **Communication Notifications**: avatars + intents.
- **Live Activities** (2026): `liveactivity` push type updates Dynamic Island.
- **Focus modes / Time-Sensitive**: `interruption-level: time-sensitive` to bypass Focus.

Android-specific:
- **Notification channels** (Android 8+): mandatory; user controls importance per channel.
- **POST_NOTIFICATIONS** (Android 13+): runtime permission, ask explicitly.
- **WorkManager** for guaranteed background work post-notification.
- **Doze / App Standby**: high-priority push wakes briefly; respect quotas.

The 2026 specific:
- **Expo Notifications v0.30+** with Live Activities support.
- **Direct VoIP via PushKit** when needed.
- **APNs HTTP/3** rolling out.
- **Web Push** support in Expo for universal apps.
- **Apple Wallet push updates** via separate endpoints.

---

## The "Why"

Push is retention. A 1% delivery improvement = measurable DAU lift. A 1% delivery regression = silent user churn. Companies care because the gap between "we sent it" and "user saw it" is huge.

---

## Mental Model

Push = three-leg pipeline: client (token) → backend (router) → OS service (APNs/FCM). Every leg has failure modes; you must measure each.

---

## Internal Working (2026 Context)

- APNs maintains persistent HTTP/2 connection per app (one socket on device).
- FCM uses XMPP / HTTP/2 with similar persistence.
- Tokens scoped per (app, install). Reinstall = new token.
- Backend should TTL tokens (delete after 90 days inactive).

---

## Modern Implementation (Code)

**Permission + token registration**:
```ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

export async function registerForPush(userId: string) {
  if (!Device.isDevice) return;
  const { status: existing } = await Notifications.getPermissionsAsync();
  let status = existing;
  if (status !== 'granted') {
    const r = await Notifications.requestPermissionsAsync();
    status = r.status;
  }
  if (status !== 'granted') return;

  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'Default',
      importance: Notifications.AndroidImportance.DEFAULT,
    });
  }

  const token = (await Notifications.getDevicePushTokenAsync()).data;
  await api.registerPushToken({ userId, token, platform: Platform.OS });
}
```

**Server send (APNs, Node)**:
```ts
import http2 from 'node:http2';
import jwt from 'jsonwebtoken';

const token = jwt.sign(
  { iss: TEAM_ID, iat: Math.floor(Date.now() / 1000) },
  P8_PEM,
  { algorithm: 'ES256', header: { kid: KEY_ID } }
);

const client = http2.connect('https://api.push.apple.com');
const req = client.request({
  ':method': 'POST',
  ':path': `/3/device/${deviceToken}`,
  authorization: `bearer ${token}`,
  'apns-topic': 'com.acme.app',
  'apns-push-type': 'alert',
  'apns-priority': '10',
});
req.write(JSON.stringify({
  aps: { alert: { title: 'Hi', body: 'Hello' }, sound: 'default' },
  deepLink: '/order/123',
}));
req.end();
```

**Server send (FCM v1)**:
```ts
const accessToken = await getServiceAccountAccessToken();
await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
  method: 'POST',
  headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: {
      token: fcmToken,
      notification: { title: 'Hi', body: 'Hello' },
      data: { deepLink: '/order/123' },
      android: { priority: 'HIGH', notification: { channel_id: 'default' } },
    },
  }),
});
```

---

## Comparison

| | APNs | FCM | Expo Push |
|---|---|---|---|
| Platform | iOS | Android (+ relay iOS) | both |
| Auth | JWT (p8) | OAuth2 (svc acct) | Expo access token |
| Latency | lowest | lowest | +1 hop |
| Audit | full | full | partial |
| Best for | enterprise direct | enterprise direct | small/mid teams |

---

## Production Usage

- Most large apps: direct APNs + FCM, with internal "notification service".
- Smaller / faster-moving: Expo relay until scale demands direct.

---

## Hands-On Exercise

1. Register tokens on both platforms.
2. Send a notification via APNs JWT auth.
3. Send via FCM v1 OAuth.
4. Compare delivery latency.

---

## Common Mistakes

- Using legacy FCM server keys (deprecated; broken 2024+).
- Treating Expo push token as device push token in backend.
- Not handling token rotation.
- Not asking POST_NOTIFICATIONS on Android 13+.

---

## Production Red Flags

- Tokens stored without user/device key.
- No invalid-token cleanup.
- One channel for all categories on Android.

---

## Performance & Metrics (MANDATORY)

- APNs HTTP/2 send latency: < 100ms.
- Delivery rate (sent → opened) target: > 30% for marketing, > 70% for transactional.

---

## Decision Framework

| Scenario | Pick |
|---|---|
| iOS-only, audit-heavy | APNs direct |
| Cross-platform | direct + per-platform |
| Prototype | Expo relay |
| Live Activities | APNs liveactivity |

---

## Senior-Level Insight

Treat the notification service as a **first-class internal product** — own SLA, deliverability dashboards, retry policies. Senior teams have a "notification council" reviewing payload schemas and quotas.

---

## Memory Hook
**"APNs JWT, FCM OAuth, Expo wraps both."**

## Revision Notes
> APNs HTTP/2 + p8 JWT; FCM v1 OAuth. Expo Notifications for client ergonomics. Direct send for control; Expo relay for speed. Per-device-per-user tokens. Live Activities = APNs liveactivity push type.

---

---

### Q2. Token lifecycle — registration, rotation, server dedup

---

## Difficulty
- Mid

## Interview Frequency
- Very Common

## Prerequisites
- Q1, basic backend / DB design

## TL;DR
Tokens rotate (uninstall, reinstall, OS reset, transfer). Backend must **dedup by (user, device)**, **mark invalid on bounce**, **TTL inactive**, and **never trust client-only state**. Idempotent registration: send token + user every app launch (cheap upsert). Use APNs/FCM bounce responses (`Unregistered`, `BadDeviceToken`) to clean up.

---

## 30-Second Interview Answer

> "Push tokens are unstable. The contract is: client registers token + user + device on every launch (idempotent upsert). Backend stores by (user, device) so multi-device works. APNs/FCM responses include token-invalidity codes — `Unregistered`, `BadDeviceToken`, `MismatchSenderId` — backend immediately deletes. TTL anything inactive 90+ days. Never assume `getToken()` is stable; rotation happens silently."

---

## 2-Minute Practical Answer

**Client side**:
- Re-register on every app launch (and after permission change).
- Cheap: backend dedups; cost is single upsert.
- Listen for token rotation events:
```ts
const sub = Notifications.addPushTokenListener((t) => {
  api.registerPushToken({ userId, token: t.data, platform });
});
```

**Server side schema**:
```sql
CREATE TABLE push_tokens (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL,
  device_id text NOT NULL,           -- stable per install
  platform text NOT NULL,            -- 'ios' | 'android'
  token text NOT NULL UNIQUE,
  app_version text,
  created_at timestamptz NOT NULL,
  last_seen_at timestamptz NOT NULL,
  invalid_at timestamptz
);
CREATE UNIQUE INDEX ON push_tokens(user_id, device_id, platform);
```

Upsert:
```sql
INSERT INTO push_tokens (id, user_id, device_id, platform, token, last_seen_at)
VALUES (...)
ON CONFLICT (user_id, device_id, platform)
DO UPDATE SET token = EXCLUDED.token, last_seen_at = now(), invalid_at = NULL;
```

**Bounce handling**:
- APNs `:status 410 Unregistered` → mark invalid.
- FCM `UNREGISTERED` / `INVALID_ARGUMENT` → mark invalid.
- Don't delete row immediately — set `invalid_at`; cron purges after grace period.

**Cleanup**:
- Cron daily: delete tokens with `invalid_at < now() - 7 days`.
- Cron weekly: delete tokens with `last_seen_at < now() - 90 days`.

**Multi-device**:
- One user → many tokens.
- Send to all active tokens for user.
- Optionally dedupe by content hash to avoid double-notification on same device family.

**Logout**:
- Unregister token from this user (don't delete — token may be valid for next user on shared device).
- Best practice: set `user_id = NULL` and let next login claim.

---

## 5-Minute Architecture Answer

Why dedup is hard:
- Same device may produce different tokens after reinstall.
- Same token may move between users (rare; logout on shared device).
- Token is unique on APNs/FCM side, but not on your DB unless you enforce.

Token-rotation triggers:
- Reinstall.
- OS restore from backup.
- App data clear (Android).
- APNs/FCM key rotation (rare).
- Sandbox ↔ production environment switch (iOS).

Idempotency design:
- Client always sends `{ user_id, device_id, token, platform, app_version }`.
- Backend upsert on `(user_id, device_id, platform)`.
- Conflict on `token` (unique) — happens when token reused across users → handle by reassigning.

Server-side dedup at send time:
- Group by user → one push per device.
- Within device family (e.g., iPad + iPhone), still send to each — they're different "devices".
- Avoid sending duplicate content (idempotency key per notification).

Bounce-response design:
- Each APNs/FCM response includes per-token status.
- Pipeline: send → collect responses → batch update DB.
- Retries: only for transient errors (5xx); never for `Unregistered`.

Observability:
- Counters: tokens stored, sent, delivered (per provider), bounced.
- Bounce rate alarms (sudden spike = key rotation, env mismatch, expiry).
- Dead tokens dashboard for support.

The 2026 specific:
- **Apple Push Notification Service receipts** for delivery confirmation (paid tier).
- **FCM batch endpoint** for high throughput.
- **Token-binding to device-check** for fraud prevention.
- **Privacy Sandbox / iCloud Private Relay** doesn't affect tokens but does affect downstream telemetry.

---

## The "Why"

Bad token hygiene = sending to dead tokens = hidden spend + crashed quotas + missed users on real devices. Companies care because clean token store correlates with delivery reliability.

---

## Mental Model

Token = mutable handle to a (device, app install). Treat it as cache. Always re-register. Always honor bounces.

---

## Internal Working (2026 Context)

- APNs returns `apns-id` for tracing.
- FCM v1 returns message ID + per-token error.
- Bounces sometimes async; track over 24h window.

---

## Modern Implementation (Code)

**Bounce handler (Node, FCM)**:
```ts
async function sendBatch(messages) {
  const res = await admin.messaging().sendEach(messages);
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error?.code;
      if (code === 'messaging/registration-token-not-registered'
       || code === 'messaging/invalid-registration-token') {
        markInvalid(messages[i].token);
      }
    }
  });
}
```

**APNs status handler**:
```ts
req.on('response', (headers) => {
  const status = headers[':status'];
  if (status === 410) markInvalid(deviceToken);
  else if (status === 400) {
    let body = '';
    req.on('data', (d) => body += d);
    req.on('end', () => {
      const reason = JSON.parse(body).reason;
      if (reason === 'BadDeviceToken') markInvalid(deviceToken);
    });
  }
});
```

---

## Comparison

| Strategy | Notes |
|---|---|
| Client re-registers on launch | preferred |
| Client re-registers only on change | misses rotations |
| Server polls APNs | not supported |

---

## Production Usage

- Universal: re-register every launch.
- Backend: separate "token service" microservice common.

---

## Hands-On Exercise

1. Build idempotent register endpoint.
2. Wire bounce handlers for APNs + FCM.
3. Write cron for cleanup.
4. Dashboard token health.

---

## Common Mistakes

- Trusting `getToken()` to be stable.
- Deleting on first bounce (transient errors).
- Not unregistering on logout.
- Storing tokens in user table (no multi-device).

---

## Production Red Flags

- Token table without unique constraint.
- No cleanup cron.
- No bounce handling.

---

## Performance & Metrics (MANDATORY)

- Token bounce rate: < 5%.
- Token table size growth: linear with active users.

---

## Decision Framework

| Scenario | Action |
|---|---|
| App launch | re-register |
| Permission granted | re-register |
| Logout | unregister this user only |
| Bounce | mark invalid, schedule purge |

---

## Senior-Level Insight

The mature take: a separate **token lifecycle service** with its own SLO. Senior teams treat token store as canonical user-device map for many features (presence, multi-device sync).

---

## Memory Hook
**"Idempotent register, honor bounces, TTL the dead."**

## Revision Notes
> Re-register on every launch (idempotent). Dedup by (user, device, platform). Honor APNs `410 Unregistered`, FCM `UNREGISTERED`. Cron cleanup. Logout unregisters this user only.

---

---

### Q3. Deep linking from notifications — cold / warm / hot

---

## Difficulty
- Mid

## Interview Frequency
- Common

## Prerequisites
- Q1, deep linking basics, navigation libraries

## TL;DR
Three states matter: **cold start** (app killed → tap notif → app launches with notif data), **warm** (app backgrounded), **hot** (app foreground). Each requires different handlers. Use Expo Notifications: `Notifications.getLastNotificationResponseAsync()` for cold, `addNotificationResponseReceivedListener` for warm/hot. Pair with router (Expo Router → `router.push(deepLink)`). Always validate the deep link payload server-trustlessly.

---

## 30-Second Interview Answer

> "Three lifecycle states: cold (app killed → relaunches), warm (backgrounded), hot (foreground). For cold: read `getLastNotificationResponseAsync()` after navigation initialized. For warm/hot: subscribe to `addNotificationResponseReceivedListener`. Parse the deep link from data payload, validate it (don't trust arbitrary URLs), and `router.push()`. Handle race: navigation must be ready before pushing — use a queued effect. Don't navigate from foreground notifications unless user explicitly taps."

---

## 2-Minute Practical Answer

**Three states**:

| State | App | Trigger |
|---|---|---|
| Cold | killed | OS launches app |
| Warm | backgrounded | OS brings to foreground |
| Hot | foregrounded | already running |

**Handler setup**:
```tsx
// app/_layout.tsx
import * as Notifications from 'expo-notifications';
import { router } from 'expo-router';
import { useEffect } from 'react';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export default function RootLayout() {
  useEffect(() => {
    // cold start
    Notifications.getLastNotificationResponseAsync().then((resp) => {
      if (resp) handleNotification(resp);
    });
    // warm + hot
    const sub = Notifications.addNotificationResponseReceivedListener(handleNotification);
    return () => sub.remove();
  }, []);

  return <Stack />;
}

function handleNotification(resp: Notifications.NotificationResponse) {
  const data = resp.notification.request.content.data as { deepLink?: string };
  if (!data?.deepLink) return;
  if (!isAllowedDeepLink(data.deepLink)) return;
  router.push(data.deepLink as any);
}

function isAllowedDeepLink(link: string) {
  return /^\/[a-z0-9/_-]+$/i.test(link); // allowlist
}
```

**Cold-start race**:
- Navigation may not be ready when handler runs.
- Solution: queue the deep link, flush on `useEffect` after first render.
```ts
const pendingLinkRef = useRef<string | null>(null);
// ...
function handleNotification(resp) {
  const link = resp.notification.request.content.data.deepLink;
  if (!isReady) { pendingLinkRef.current = link; return; }
  router.push(link);
}
useEffect(() => {
  if (isReady && pendingLinkRef.current) {
    router.push(pendingLinkRef.current);
    pendingLinkRef.current = null;
  }
}, [isReady]);
```

**Foreground behavior**:
- iOS: shows banner if `shouldShowBanner: true` (iOS 14+).
- Android: shows in tray; controlled by channel importance.
- Don't auto-navigate on hot — user is mid-task.

---

## 5-Minute Architecture Answer

Deep-link payload design:
- Server sends `{ aps: {...}, deepLink: '/order/123' }`.
- Path-based (relative) > URL-based (absolute) — easier to migrate domains.
- Include version: `deepLinkV: 2` if schema evolves.
- Sign / encrypt for sensitive routes (don't embed PII in path).

Validation:
- Allowlist routes: regex or known prefixes.
- Reject external URLs unless universal-link verified.
- Sanitize params before passing to router.

Cold-start considerations:
- App init order: native splash → JS bundle → root layout mount → router ready.
- Notification data available before router; queue.
- Show splash longer if cold-start deep link to avoid flash of home.

Universal Links / App Links:
- Open via OS, not via push payload.
- Use `Linking.getInitialURL()` for cold; `Linking.addEventListener('url', ...)` for warm.
- Same queue pattern.

Auth-gated deep links:
- If unauthenticated, redirect to `/login?next=<encoded>`.
- After login, restore.

Multi-tab / multi-stack:
- Push may need to switch tab before opening detail.
- Use Expo Router's `router.replace` with full path.

The 2026 specific:
- **Live Activities tap**: opens to activity-specific route via `lifeActivityId`.
- **Communication Notifications** can include intent → opens chat.
- **Notification categories** with action buttons → handle each action.

Action buttons:
```ts
Notifications.setNotificationCategoryAsync('order_actions', [
  { identifier: 'mark_read', buttonTitle: 'Mark Read' },
  { identifier: 'reply', buttonTitle: 'Reply', textInput: { submitButtonTitle: 'Send' } },
]);
// in handler: resp.actionIdentifier === 'mark_read'
```

---

## The "Why"

A broken deep link = wasted notification = lower retention. Race conditions on cold-start are the most common bug. Companies care because click-through-to-target conversion is a top metric.

---

## Mental Model

Notification handler runs at unpredictable lifecycle moments. Always queue the intent; navigate when navigator is ready.

---

## Internal Working (2026 Context)

- iOS: `UNNotificationResponse` delivered to `AppDelegate` then JS via `expo-notifications`.
- Android: `RemoteMessage` handled by `FirebaseMessagingService` (or Expo's), launched activity.
- Cold-start data persisted in launch options.

---

## Modern Implementation (Code)

**Auth-gated deep link**:
```tsx
function handleNotification(resp) {
  const link = resp.notification.request.content.data.deepLink;
  if (!isAllowedDeepLink(link)) return;
  if (!user) {
    router.push({ pathname: '/login', params: { next: link } });
  } else {
    router.push(link);
  }
}
```

**Queued navigation**:
```tsx
const [navReady, setNavReady] = useState(false);
const pending = useRef<string | null>(null);
useEffect(() => { setNavReady(true); }, []);
useEffect(() => {
  if (navReady && pending.current) {
    router.push(pending.current as any);
    pending.current = null;
  }
}, [navReady]);
```

---

## Comparison

| State | Handler |
|---|---|
| Cold | `getLastNotificationResponseAsync` |
| Warm | `addNotificationResponseReceivedListener` |
| Hot | same as warm |
| In-app banner | `addNotificationReceivedListener` (don't navigate) |

---

## Production Usage

- All consumer apps.
- Common bug area; usually owned by growth team.

---

## Hands-On Exercise

1. Wire all three states.
2. Add queue for cold-start race.
3. Add auth-gated redirect.
4. Add notification action buttons.

---

## Common Mistakes

- Navigating before navigator ready (no-op or crash).
- Trusting arbitrary deep-link strings (open redirect).
- Auto-navigating on foreground (interrupts user).
- Ignoring action identifiers.

---

## Production Red Flags

- Deep links accept arbitrary URLs.
- No queue → cold-start lost.
- No analytics on tap-through.

---

## Performance & Metrics (MANDATORY)

- Cold-start to deep link target: < 1.5s.
- Tap-through navigation: < 200ms.

---

## Decision Framework

| State | Action |
|---|---|
| Cold | queue + navigate when ready |
| Warm | navigate immediately |
| Hot | banner only; navigate on tap |

---

## Senior-Level Insight

Centralize all deep-link parsing in one module — push, universal links, in-app, share-extension all funnel through one validator + router. Senior teams add an audit log per deep-link tap.

---

## Memory Hook
**"Cold = pull, warm/hot = subscribe, queue if not ready."**

## Revision Notes
> Cold: `getLastNotificationResponseAsync`. Warm/hot: `addNotificationResponseReceivedListener`. Queue link until navigator ready. Validate via allowlist. Auth-gate via `next` param. Handle action identifiers.

---

---

### Q4. Silent push for background sync (iOS BGTask, Android WorkManager)

---

## Difficulty
- Advanced

## Interview Frequency
- Common

## Prerequisites
- iOS background modes, Android Doze, WorkManager basics

## TL;DR
**Silent push** wakes the app briefly to do work without user UI. iOS: `content-available: 1`, no alert; OS budgets ~30s wake. Pair with **BGTaskScheduler** for scheduled work and **PushKit/VoIP** if true real-time required. Android: data-only FCM with high priority + **WorkManager** to enqueue durable work. Both OSes throttle if app misbehaves; respect quotas. Use silent push only for sync triggers — don't expect guaranteed delivery.

---

## 30-Second Interview Answer

> "Silent push lets the server tell the app 'sync now' without showing UI. On iOS: APNs `content-available: 1`, `apns-push-type: background`, priority 5; OS wakes the app for ~30s. On Android: data-only FCM with priority HIGH wakes briefly; for guaranteed work, enqueue WorkManager from the receiver. Critical: neither platform guarantees silent push delivery — Doze on Android, throttling on iOS. Use silent push as a hint, not a contract; pair with periodic BGTaskScheduler / PeriodicWorkRequest as fallback."

---

## 2-Minute Practical Answer

**iOS silent push payload**:
```json
{
  "aps": {
    "content-available": 1
  },
  "syncReason": "messages"
}
```
Headers:
- `apns-push-type: background`
- `apns-priority: 5`
- No `alert`, `sound`, `badge`.

In app:
- iOS calls `application:didReceiveRemoteNotification:fetchCompletionHandler:`.
- Expo handles via `BackgroundNotification` task.
- Must call completion handler within ~30s.

```ts
import * as Notifications from 'expo-notifications';
import * as TaskManager from 'expo-task-manager';

const TASK = 'BG_NOTIF_TASK';

TaskManager.defineTask(TASK, async ({ data, error }) => {
  if (error) return;
  // do work
  await syncQueue.flush();
});

Notifications.registerTaskAsync(TASK);
```

**Android data-only FCM**:
```json
{
  "message": {
    "token": "...",
    "data": { "syncReason": "messages" },
    "android": { "priority": "HIGH" }
  }
}
```
- No `notification` field → app handles.
- High priority → wakes from Doze briefly.
- Use receiver to enqueue WorkManager:

```kt
class FcmService : FirebaseMessagingService() {
  override fun onMessageReceived(msg: RemoteMessage) {
    val req = OneTimeWorkRequestBuilder<SyncWorker>()
      .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
      .build()
    WorkManager.getInstance(this).enqueue(req)
  }
}
```

**Background fetch (no push)**:
- iOS: `BGTaskScheduler` with `BGAppRefreshTask` (periodic) + `BGProcessingTask` (longer).
- Android: `PeriodicWorkRequest` ≥15min interval.

```ts
// expo-background-fetch
await BackgroundFetch.registerTaskAsync(TASK, {
  minimumInterval: 60 * 15, // 15 min
  stopOnTerminate: false,
  startOnBoot: true,
});
```

---

## 5-Minute Architecture Answer

Why silent push is unreliable:
- **iOS throttling**: OS budgets background wakes; silent pushes throttled if app drains battery.
- **Android Doze / App Standby**: app may not wake until maintenance window unless high priority.
- **User force-quit (iOS)**: app cannot wake until user reopens.
- **Battery saver / Data saver**: blocks background.

So: **silent push is a hint**. Treat as opportunistic.

Architecture:
- **Push as trigger**, not as data carrier.
- App receives push → enqueues work in WorkManager / BGTask.
- Worker fetches latest from server — always pull-based for consistency.
- If push dropped, periodic background fetch catches up.

iOS specifics:
- **`apns-push-type: background`** required for silent (iOS 13+).
- Priority 5 (not 10).
- Completion handler must be called within ~30s.
- Apps with `Background Modes > Remote notifications` only.
- BGTaskScheduler runs when device is "ready" (charging / wifi / idle).

Android specifics:
- Data-only message → `onMessageReceived` even in background.
- High priority quota: limited per app per hour (FCM enforces).
- WorkManager respects Doze and constraints.
- Foreground service for long work (visible notification required Android 14+).

VoIP / Critical:
- iOS: PushKit (separate token, separate cert/key) for VoIP — wakes reliably, no UI required.
- Android: high-priority FCM + foreground service.
- Critical alerts (iOS): need entitlement + user opts in.

The 2026 specific:
- **iOS 18+**: tighter background limits; expect more throttling.
- **Android 14+**: foreground service types must be declared.
- **Live Activity updates** via push — separate path.
- **Background Push for AI inference / sync** — Apple discouraging via private API checks.

Common patterns:
- **Inbox sync**: silent push triggers fetch; periodic fetch as fallback.
- **Token refresh**: pre-emptive token refresh via background.
- **Geofence wake**: separate API; not push.
- **Live data sync** (chat): silent push as nudge; WebSocket when foreground.

---

## The "Why"

Background sync is what makes apps feel "fresh" without burning battery. Bad implementation = either stale data or battery drain reports. Companies care because both tank App Store ratings.

---

## Mental Model

Silent push = "wake up, check in" tap. Don't trust delivery. Always pull from server. Queue work in OS scheduler.

---

## Internal Working (2026 Context)

- iOS: APNs delivers; SpringBoard wakes app via launch services; up to ~30s execution.
- Android: FCM via Google Play Services; wakes via JobScheduler/WorkManager.
- Both honor system-level battery state.

---

## Modern Implementation (Code)

**Expo background notification task**:
```ts
import * as TaskManager from 'expo-task-manager';
import * as Notifications from 'expo-notifications';

TaskManager.defineTask('BG_PUSH', async ({ data, error }) => {
  if (error) return;
  try {
    await Promise.race([
      sync.run(),
      new Promise((_, r) => setTimeout(() => r(new Error('timeout')), 25000)),
    ]);
  } catch (e) {
    log.warn('bg.push.failed', e);
  }
});

Notifications.registerTaskAsync('BG_PUSH');
```

**iOS BGTaskScheduler (via expo-background-fetch)**:
```ts
import * as BackgroundFetch from 'expo-background-fetch';
await BackgroundFetch.registerTaskAsync('BG_FETCH', {
  minimumInterval: 60 * 15,
  stopOnTerminate: false,
  startOnBoot: true,
});
```

**Android WorkManager constraint**:
```kt
val req = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
  .setConstraints(Constraints.Builder()
    .setRequiredNetworkType(NetworkType.UNMETERED)
    .setRequiresBatteryNotLow(true)
    .build())
  .build()
WorkManager.getInstance(ctx).enqueueUniquePeriodicWork(
  "sync", ExistingPeriodicWorkPolicy.KEEP, req)
```

---

## Comparison

| Mechanism | Reliability | Use |
|---|---|---|
| Silent push | low (hint) | nudge sync |
| BGTaskScheduler / WorkManager | medium | periodic |
| Foreground service (Android) | high | active work |
| PushKit (iOS VoIP) | high | calls only |

---

## Production Usage

- Chat apps: silent push + WebSocket fallback.
- Newsfeed: periodic fetch.
- E-commerce: order status via silent push + retry.

---

## Hands-On Exercise

1. Send silent push and verify wake on both platforms.
2. Implement WorkManager fallback.
3. Measure delivery rate over 24h.
4. Add backoff for failures.

---

## Common Mistakes

- Including alert payload in silent push (then it's not silent).
- Doing > 30s work on iOS (terminated).
- Not declaring background mode in Info.plist.
- Heavy work on FCM thread (blocks).

---

## Production Red Flags

- Silent push relied on as guaranteed.
- No periodic fallback.
- Battery complaints in App Store.

---

## Performance & Metrics (MANDATORY)

- Silent push delivery rate: 60–90% (varies wildly).
- Wake-to-completion: < 30s iOS; < 10min WorkManager.

---

## Decision Framework

| Need | Pick |
|---|---|
| Real-time | WebSocket + silent push nudge |
| Periodic sync | BGTask / WorkManager |
| Calls | PushKit / foreground service |
| Critical alerts | Critical Alert entitlement |

---

## Senior-Level Insight

The mature take: **silent push is ad-tier reliability**; design for the dropped case. Senior teams instrument silent-push delivery rate as a SLO and trigger fallback aggressively.

---

## Memory Hook
**"Silent push hints; WorkManager / BGTask delivers."**

## Revision Notes
> iOS silent: `content-available:1` + `apns-push-type:background` + priority 5. Android silent: data-only + HIGH priority. Both unreliable → pair with BGTaskScheduler / WorkManager. Never assume delivery.

---

---

### Q5. Deliverability + analytics — measuring real delivery

---

## Difficulty
- Advanced

## Interview Frequency
- Common (growth / retention rounds)

## Prerequisites
- Q1–Q4

## TL;DR
"Sent" ≠ "Delivered" ≠ "Shown" ≠ "Opened". Instrument every layer: backend send success, APNs/FCM acceptance, OS delivery (NSE on iOS), UI presentation (`addNotificationReceivedListener`), tap (`addNotificationResponseReceivedListener`). Compute funnel per campaign. Watch silent throttling, channel disabled, OS revoked permissions. Senior orgs treat push deliverability as a top SLO.

---

## 30-Second Interview Answer

> "The funnel: backend send → APNs/FCM accept → OS delivery → UI shown → tap. Each stage measurable: backend logs (sent), provider response (accepted), Notification Service Extension on iOS (delivered to device), `addNotificationReceivedListener` (presented to user), `addNotificationResponseReceivedListener` (opened). Compute per-stage drop-off per campaign. Watch revoked permissions, disabled channels (Android), Focus modes (iOS). Push delivered-rate is a top SLO."

---

## 2-Minute Practical Answer

**The funnel**:

| Stage | Measurement |
|---|---|
| Sent | backend log per `notification_id` |
| Accepted | APNs `apns-id` / FCM message ID |
| Delivered to device | NSE on iOS, OS callback Android |
| Presented | client `addNotificationReceivedListener` |
| Opened | client `addNotificationResponseReceivedListener` |
| Action taken | analytics event after deep-link nav |

**Backend instrumentation**:
- Every send: `notification_id`, user, device, campaign, sent_at.
- Every accept/reject: provider id, status code, error.

**Client instrumentation**:
- On `addNotificationReceivedListener`: ping `/notif/presented` with id.
- On `addNotificationResponseReceivedListener`: ping `/notif/opened` with id + action.
- Use a queue (offline-resilient, S11) for these pings.

**iOS NSE for delivered confirmation**:
```swift
import UserNotifications
class NotificationService: UNNotificationServiceExtension {
  override func didReceive(_ req: UNNotificationRequest, withContentHandler done: @escaping (UNNotificationContent) -> Void) {
    if let id = req.content.userInfo["nid"] as? String {
      // fire-and-forget POST to /notif/delivered
      DeliveryReporter.report(id: id)
    }
    done(req.content)
  }
}
```

**Permission state**:
```ts
const perm = await Notifications.getPermissionsAsync();
if (perm.status !== 'granted') analytics.track('push.permission.denied');
```

**Android channel state**:
```kt
val channel = nm.getNotificationChannel(channelId)
if (channel?.importance == NotificationManager.IMPORTANCE_NONE) {
  // user disabled this channel
}
```

---

## 5-Minute Architecture Answer

Why this matters:
- Push deliverability degrades silently — quotas, permissions revoked, channels disabled.
- "Sent" metric is meaningless without funnel.
- Marketing reports based on "sent" → wrong CPM, wrong attribution.

Funnel design:
- One `notification_id` (UUID) generated server-side, attached to payload.
- Every event references that id.
- Backend joins events into funnel.

Stage-level dropoff signals:
- **Sent → Accepted**: provider issue (auth, payload size, token invalid).
- **Accepted → Delivered**: silent throttling, network, user offline.
- **Delivered → Presented**: app force-quit (iOS), channel disabled (Android), Focus mode.
- **Presented → Opened**: content not engaging.
- **Opened → Action**: deep-link broken, bad UX.

Per-platform measurement:
- iOS NSE = best signal for "delivered".
- Android: receiver fires on delivery (data-only); for notification-only, no client signal until presentation.
- Web push: service worker can ping.

Cohort analysis:
- Per OS version (iOS 18+ stricter).
- Per device (low-end Android Doze hits harder).
- Per channel (marketing vs transactional).
- Per geography (locale-specific quiet hours).

The 2026 specific:
- **iOS 18 Focus modes**: notifications may be silently filtered → still "delivered" but not "presented".
- **Android 14+ POST_NOTIFICATIONS** denied rates higher.
- **Live Activity updates**: separate funnel.
- **Web Push**: opt-in rates ~5–10%.

Tooling:
- **Custom**: backend logs + client pings → warehouse → BI dashboards.
- **Third-party**: OneSignal, Braze, Customer.io provide funnel out of box.
- **Hybrid**: send via your backend, log to third-party for analytics.

---

## The "Why"

Without measurement, push is a black box. Senior orgs treat push as a measurable, optimizable channel. Companies care because attribution to retention metrics depends on accurate per-stage data.

---

## Mental Model

Push = funnel. Every stage measurable. Without per-stage data, you can't optimize.

---

## Internal Working (2026 Context)

- NSE runs in separate process; ~30s budget.
- Client pings via offline queue.
- Backend joins via `notification_id`.

---

## Modern Implementation (Code)

**Client ping queue**:
```ts
function reportNotificationEvent(stage: 'presented' | 'opened', id: string) {
  outbox.enqueue({ url: '/notif/' + stage, body: { id, ts: Date.now() } });
}

Notifications.addNotificationReceivedListener((n) => {
  const id = n.request.content.data.nid;
  if (id) reportNotificationEvent('presented', id);
});

Notifications.addNotificationResponseReceivedListener((r) => {
  const id = r.notification.request.content.data.nid;
  if (id) reportNotificationEvent('opened', id);
});
```

**Funnel SQL**:
```sql
SELECT campaign,
  COUNT(*)                                   AS sent,
  SUM(accepted::int)                         AS accepted,
  SUM(delivered::int)                        AS delivered,
  SUM(presented::int)                        AS presented,
  SUM(opened::int)                           AS opened
FROM notification_events
GROUP BY campaign;
```

---

## Comparison

| Layer | Source | Reliability |
|---|---|---|
| Sent | backend | 100% |
| Accepted | provider | 100% |
| Delivered | NSE (iOS), receiver (Android) | high |
| Presented | client listener | medium |
| Opened | client listener | medium |

---

## Production Usage

- All large consumer apps measure full funnel.
- Marketing teams report on opened (not sent).

---

## Hands-On Exercise

1. Add `notification_id` end-to-end.
2. Implement NSE for delivered.
3. Wire client pings.
4. Build funnel dashboard.

---

## Common Mistakes

- Reporting "sent" as primary KPI.
- No NSE — missing delivered signal.
- Pings without offline queue (lost when offline).
- No per-cohort breakdown.

---

## Production Red Flags

- KPI = "sent volume".
- No NSE shipped.
- No permission state in analytics.

---

## Performance & Metrics (MANDATORY)

- Sent → Opened: 5–30% typical.
- Permission grant: 50–80% iOS, varies Android.

---

## Decision Framework

| Question | Look at |
|---|---|
| Bad delivery? | Sent → Accepted → Delivered drops |
| Bad UX? | Presented → Opened drops |
| Bad targeting? | Opened → Action drops |

---

## Senior-Level Insight

The mature take: every push has an SLO and a postmortem if delivery drops > 5% week-over-week. Senior teams instrument permission grant + Focus mode + channel state to disambiguate "OS dropped it" vs "user disabled".

---

## Memory Hook
**"Sent ≠ Delivered ≠ Shown ≠ Opened."**

## Revision Notes
> Funnel: sent → accepted → delivered → presented → opened. NSE for iOS delivered; receiver for Android. Client pings via offline queue. Permission + channel state matters. Per-cohort breakdown.

---

> **End of S12.** Cross-refs: [S11 Offline-First](S11-offline-first.md) (queue), [S15 Native Bridging](S15-native-bridging.md) (NSE target), [S30 Privacy](S30-privacy-compliance.md) (consent). Next per priority: [S17 Testing](S17-testing.md).
