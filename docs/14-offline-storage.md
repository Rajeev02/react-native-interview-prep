## 14. Offline-first + storage

### Storage choices
| Tool | Use |
|---|---|
| **MMKV** | Fast key-value, sync, encrypted. AsyncStorage replacement. |
| **SQLite** (`react-native-quick-sqlite`) | Relational, queryable. |
| **WatermelonDB** | Lazy-loaded reactive DB on top of SQLite. |
| **Realm** | Object DB with sync (paid). |
| **expo-secure-store** | Tiny secure values (tokens). |

### Outbox pattern (offline writes)
1. User action → write to local DB + enqueue in outbox table.
2. UI reads from local DB (optimistic).
3. Background sync drains outbox to server.
4. On success → mark synced; on failure → retry with backoff.
5. Conflict → last-write-wins or server-side merge.

### Sync strategies
- **Pull** (poll on foreground/interval).
- **Push** (server pushes via WebSocket/SSE).
- **Hybrid** (push for live + pull on resume).

### Conflict resolution
- LWW (last-write-wins) — simple, lossy.
- Vector clocks / CRDT — advanced (mention only if asked).
- Server-side merge with version field.

### NetInfo
- `@react-native-community/netinfo` for connectivity changes.
- Don't trust "online" — try the actual request.

### Must-answer questions
1. Design offline-first transaction list.
2. Outbox pattern walkthrough.
3. MMKV vs AsyncStorage — why switch.
4. Conflict resolution options.
5. App killed mid-sync — recovery.

---



---

## Top 25 Q&A — Offline-first + storage

### 1. AsyncStorage vs MMKV — which?
**MMKV**: 30x faster, sync API, encrypted, smaller. Use for everything except very large blobs. AsyncStorage is async, slow, deprecated for hot paths.

### 2. WatermelonDB vs Realm vs SQLite — when?
- **SQLite (op-sqlite / expo-sqlite)**: full SQL control, offline-first.
- **WatermelonDB**: lazy-loaded models, sync-friendly, large datasets (10k+).
- **Realm**: object DB + reactive queries; MongoDB Atlas Device Sync option.

### 3. Offline-first architecture pattern.
Read from local DB, queue writes, sync to server with retries; conflict resolution at sync. UI is always served by local cache.

### 4. Sync engine — components.
Outbox (pending mutations), inbox (incoming changes), conflict resolver, last-sync cursor, idempotency keys, exponential backoff.

### 5. Conflict resolution strategies.
Last-write-wins (timestamp), CRDTs (auto-merge), operational transforms, server-authoritative with client patches. LWW is most common; CRDT for collaborative.

### 6. MMKV usage.
```ts
import { MMKV } from 'react-native-mmkv';
const storage = new MMKV({ id: 'user', encryptionKey: key });
storage.set('lang', 'en');
storage.getString('lang');
```

### 7. Encrypt MMKV / AsyncStorage.
MMKV: `encryptionKey` option (AES). For AsyncStorage, encrypt blobs with key from Keychain/Keystore before write.

### 8. SQLite migrations.
Versioned schema; on open compare `user_version` PRAGMA, run sequential migrations. Wrap in transaction.

### 9. Background sync triggers.
On app foreground, on network reconnect (`NetInfo`), periodic via WorkManager / BGTaskScheduler, on user action.

### 10. Handle file storage.
`react-native-fs` / `expo-file-system`. Use `cachesDirectory` for transient (auto-purged), `documentDirectory` for user data, `tmpDirectory` for very short-term.

### 11. Image cache eviction.
FastImage uses LRU disk cache. Bound size; clear via `FastImage.clearDiskCache()` on low memory or logout.

### 12. Offline mutation queue — example.
```ts
type Mutation = { id: string; type: string; payload: any; tries: number };
const queue = new MMKV({ id: 'queue' });
function enqueue(m: Mutation) { queue.set(m.id, JSON.stringify(m)); }
async function drain() {
  for (const id of queue.getAllKeys()) {
    const m: Mutation = JSON.parse(queue.getString(id)!);
    try { await api.execute(m); queue.delete(id); }
    catch { /* increment tries, backoff */ }
  }
}
```

### 13. Optimistic UI for offline writes.
Write to local DB immediately; render from local; mark as "pending"; on sync success, mark synced; on failure, allow retry/cancel.

### 14. Detect storage quota issues.
Catch `ENOSPC`. Pre-check `FileSystem.getFreeDiskStorageAsync()`. Compress images before save.

### 15. Logout — what to wipe?
Tokens (Keychain), MMKV user store, SQLite DB (drop or delete file), React Query cache, push subscriptions, analytics user.

### 16. Cache invalidation strategies.
TTL per resource (`staleTime`), tag-based invalidation (RTK Query/React Query `invalidateQueries`), version stamp on app upgrade.

### 17. Multi-user on same device.
Namespace storage by `userId`: `MMKV({ id: \`user-\${userId}\` })`. Switch on logout.

### 18. Background fetch on iOS limits.
~30s window, opportunistic schedule. Use `expo-background-fetch` / `react-native-background-fetch`. Don't rely for time-critical sync.

### 19. WorkManager (Android) for guaranteed work.
Persists across reboots; constraints (network, charging). Use for upload retries, sync.

### 20. Schema validation on read.
Wrap DB rows with Zod parse to catch corrupted data; fail-soft → log + skip row.

### 21. Encrypt SQLite — options.
SQLCipher (`react-native-quick-sqlite` with cipher build), or app-layer encrypt sensitive columns with key from Keychain.

### 22. Pagination + offline.
Store full ordered list locally; sync new pages; maintain `nextCursor` per query. Show cached even when offline; trigger refresh when online.

### 23. Realm vs Core Data / Room?
Realm wraps native object stores; cross-platform JS API. Core Data/Room are platform-specific — use only via native modules.

### 24. Storage size monitoring.
Periodically log `FileSystem.getInfoAsync(dir).size`. Set thresholds; cleanup oldest files.

### 25. Code: simple offline-aware fetch.
```ts
async function getCached<T>(key: string, fetcher: ()=>Promise<T>, ttl = 60_000): Promise<T> {
  const raw = mmkv.getString(key);
  if (raw) {
    const { t, data } = JSON.parse(raw);
    if (Date.now() - t < ttl) return data;
  }
  try {
    const fresh = await fetcher();
    mmkv.set(key, JSON.stringify({ t: Date.now(), data: fresh }));
    return fresh;
  } catch (e) {
    if (raw) return JSON.parse(raw).data; // stale fallback
    throw e;
  }
}
```
