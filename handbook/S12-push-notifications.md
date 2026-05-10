# S12 — Push Notifications

> APNs · FCM · Expo Notifications · token rotation · deep links · silent · channels · grouping

> Status: **scaffold** — fill with content using the per-topic format from `final-prompt.md`.

## Topics

- APNs (iOS) — token-based auth, payload limits
- FCM (Android) — topics, conditions, data vs notification
- Expo Notifications (cross-platform abstraction)
- Token lifecycle & rotation (server-side dedup, idempotency)
- Deep links from notifications (cold start vs background)
- Silent / data-only notifications
- Rich notifications (images, actions, categories)
- Notification channels (Android 8+)
- Notification grouping & summaries
- Analytics & deliverability monitoring

## Q-topics (stubs)

- Q1. APNs vs FCM vs Expo Notifications — when to pick what
- Q2. Token lifecycle — registration, rotation, server dedup
- Q3. Deep linking from notifications — cold/warm/hot
- Q4. Silent push for background sync (iOS BGTask, Android WorkManager)
- Q5. Deliverability + analytics — measuring real delivery

> Cross-refs: S15 (background tasks), S30 (privacy / consent).
