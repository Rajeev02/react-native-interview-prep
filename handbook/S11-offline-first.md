# S11 — Offline-First Systems

> MMKV · op-sqlite · WatermelonDB · Realm · CRDTs · sync engines · conflict resolution · migrations · background sync

Five Q-topics in the mandatory per-topic format. "Offline-first" in 2026 isn't *if you lose connection*, it's *the network is one optional input among many*. The default UX assumes data is local and writes are queued; the network is the slow path that eventually catches up. Mobile apps that get this right feel instant; ones that don't feel broken on a flaky train. Token storage choices are in [S10 Q2](S10-auth-security.md); networking semantics in [S9](S09-networking.md).

---

### Q1. Storage decision tree — KV vs SQL vs document vs sync-engine

---

## Difficulty
- Advanced

## Interview Frequency
- Very Common (every offline-capable app)

## Prerequisites
- Basic SQL, JSON, async storage concepts

## TL;DR
Pick by **shape of the data + access patterns**, not by hype. **Hot KV / prefs → MMKV.** **Relational + queries → op-sqlite (Drizzle/Kysely).** **Document + observable + lazy → WatermelonDB.** **Realtime collaborative → CRDT (Yjs/Automerge).** **Encrypted PII → SQLCipher.** AsyncStorage is for tiny non-secrets only. Never one DB for everything; combine them per data domain.

---

## 30-Second Interview Answer

> "I match storage to data shape. Single-key hot prefs and small caches go in MMKV — synchronous, ~ns reads, multi-process safe. Anything relational with joins or queries goes in op-sqlite (JSI-native SQLite) with Drizzle for the schema. For lazy-loaded list-heavy domains with reactive observability, WatermelonDB. For collaborative real-time, CRDTs like Yjs. For encrypted PII, SQLCipher under op-sqlite or Realm-encrypted. AsyncStorage is plaintext SQLite/files — only for tiny non-secrets. Each domain in the app picks its own; trying to use one DB for everything always fails."

---

## 2-Minute Practical Answer

Storage taxonomy:

| Need | Pick | Why |
|---|---|---|
| App prefs, feature flags, last-screen | **MMKV** | sync, ns-µs reads, multi-process |
| Relational queries, joins, transactions | **op-sqlite + Drizzle/Kysely** | JSI-native SQLite, full SQL |
| Reactive lists, lazy load 100K+ rows | **WatermelonDB** | observers, lazy reads, sync built-in |
| Object graph, encryption, simple schema | **Realm** | mature, encryption, sync |
| Collaborative real-time editing | **Yjs / Automerge** (CRDT) | conflict-free merging |
| Caches that rebuild from network | **TanStack Query persistedClient** | cache invalidation built-in |
| File/blob storage | **expo-file-system / RNFS** | filesystem |
| Tiny non-secret prefs (legacy) | AsyncStorage | only if you must |
| Secrets / tokens | **Keychain / Keystore** | see [S10 Q2](S10-auth-security.md) |

Decision questions:
1. Does it need queries (filter, sort, join)? → SQL.
2. Is it a single value retrieved by key? → MMKV.
3. Will it have 10K+ rows with reactive UI? → WatermelonDB.
4. Multi-user concurrent edits? → CRDT.
5. Is it derived from a server cache? → Query cache (TanStack).
6. Is it sensitive (PII, credentials)? → Encrypted tier.

Anti-patterns:
- AsyncStorage as the app's main DB → slow, unindexed, plaintext.
- One giant Realm holding all unrelated domains → migration nightmare.
- Storing API responses in MMKV indefinitely → stale data, no invalidation.
- WatermelonDB for non-list data → overkill.
- CRDT for non-collaborative data → unnecessary complexity.

Real apps usually run **2–4 storages** simultaneously:
- MMKV for prefs + small caches.
- op-sqlite (or WatermelonDB) for domain entities (transactions, messages, products).
- Keychain for secrets.
- TanStack Query cache for ephemeral server state.

---

## 5-Minute Architecture Answer

Storage in mobile is constrained by:
- **Disk I/O variance** (~1ms SSD; >100ms slow flash).
- **Battery** (frequent writes wake disk + flush buffers).
- **App-process suspension** (iOS / Android can kill mid-write).
- **Migrations across app versions** (years of schema drift).
- **Encryption overhead** (~2× write latency under SQLCipher).
- **Multi-process** (Share Extension, widgets read same data).

A storage **layer** decision should be made per **data domain**, with these axes:

1. **Schema rigor**:
   - Strict schema → SQL (op-sqlite) or Realm.
   - Loose JSON-shaped → MMKV / SQLite JSON columns.

2. **Query complexity**:
   - Get by key only → MMKV.
   - Filter + sort + join → SQL.
   - Reactive subscriptions → Realm / WatermelonDB / SQLite + observers.

3. **Volume**:
   - <1k rows → any.
   - 1k–100k → SQL with indexes; WatermelonDB lazy reads.
   - 100k–1M → SQL + careful indexing + pagination.
   - >1M → reconsider mobile storage; sync subset.

4. **Sync model**:
   - One-way (server pushes) → cache + invalidation.
   - Two-way mutable → sync engine (Replicache / WatermelonDB sync / Realm Sync / custom).
   - Multi-user collaborative → CRDT (Yjs/Automerge) + transport.

5. **Sensitivity**:
   - PII → SQLCipher / Realm-encrypted; key in Keychain.
   - Public/derived → no encryption needed.

6. **Failure tolerance**:
   - Ephemeral OK → in-memory + TanStack Query.
   - Must survive crash mid-write → DB with WAL (SQLite WAL mode).

The 2026 specific:
- **Static Hermes** + JSI-native libraries (op-sqlite, MMKV, RN-skia) make synchronous storage viable on render path — no async penalty.
- **Sync engines** (Replicache, Linear sync, Triplit, Liveblocks, ElectricSQL) commercialize what used to be DIY; consider before rolling your own.
- **WAL mode** + **incremental vacuum** are now defaults in op-sqlite.
- **Encryption-at-rest** is increasingly required by privacy regulations; budget for it from day one.
- **Vector storage** for on-device LLM RAG is emerging — sqlite-vss, Couchbase Lite vector index.

What "offline-first" actually means architecturally:
- Reads always serve from local; UI never blocks on network for primary data.
- Writes go to local first, then enqueue for sync; UI reflects optimistically.
- Network is the *eventual consistency* path, not the *source of truth*.
- Conflict resolution is **explicit policy**, not implicit "last write wins by accident".
- Sync state (in-flight, succeeded, failed) is observable to UI.

---

## The "Why"

Wrong storage = wrong app feel. AsyncStorage everywhere = laggy app. SQLite for prefs = overkill complexity. CRDT for non-collab = unmaintainable. Companies care because storage decisions are **the** hardest to walk back — you have years of user data in production format; migrations are risky and expensive.

---

## Mental Model

Storage is plumbing — you wouldn't run your hot water through the same pipe as your sewage. Each data type gets its own pipe sized to its flow.

---

## Internal Working (2026 Context)

- **MMKV**: mmap-based; appends to file; periodic compaction; CRC integrity; AES-128 CFB optional; multi-process via separate instances.
- **op-sqlite**: JSI bindings to SQLite C API; sync from JS; WAL mode default; supports SQLCipher; column-binding zero-copy where possible.
- **WatermelonDB**: SQLite under the hood + lazy observable layer + built-in sync protocol; query language compiled to SQL.
- **Realm**: native object store with embedded persistence layer; reactive change notifications; encryption built-in; Atlas Device Sync for backend.
- **TanStack Query persistor**: serializes query cache to MMKV/AsyncStorage; rehydrates on app start.
- **Yjs/Automerge**: CRDTs serialized to compact binary; can be persisted to any storage.

Threading: MMKV sync; SQLite via op-sqlite sync (fast) or async; Realm has its own queue; WatermelonDB serializes writes.

---

## Modern Implementation (Code)

**MMKV — prefs**:

```ts
import { MMKV } from 'react-native-mmkv';

export const prefs = new MMKV({ id: 'prefs' });

prefs.set('theme', 'dark');
prefs.set('lastTab', 'home');
const theme = prefs.getString('theme');
```

**op-sqlite + Drizzle — relational entities**:

```ts
// schema.ts
import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';

export const transactions = sqliteTable('transactions', {
  id: text('id').primaryKey(),
  amount: real('amount').notNull(),
  currency: text('currency').notNull(),
  status: text('status').$type<'pending' | 'sent' | 'failed'>().notNull(),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});

// db.ts
import { open } from '@op-engineering/op-sqlite';
import { drizzle } from 'drizzle-orm/op-sqlite';

const sqlite = open({ name: 'app.db', encryptionKey: await getEncryptionKey() });
export const db = drizzle(sqlite, { schema: { transactions } });

// usage
import { eq, desc } from 'drizzle-orm';

const pending = await db.select()
  .from(transactions)
  .where(eq(transactions.status, 'pending'))
  .orderBy(desc(transactions.createdAt))
  .limit(50);

await db.insert(transactions).values({
  id: uuid(),
  amount: 99.5,
  currency: 'USD',
  status: 'pending',
  createdAt: new Date(),
});
```

**WatermelonDB — reactive list**:

```ts
import { Database } from '@nozbe/watermelondb';
import SQLiteAdapter from '@nozbe/watermelondb/adapters/sqlite';
import { schema } from './schema';
import Message from './models/Message';

const adapter = new SQLiteAdapter({ schema, jsi: true });
export const database = new Database({ adapter, modelClasses: [Message] });

// reactive query (re-renders on change)
const messagesObservable = database.collections
  .get<Message>('messages')
  .query(Q.where('thread_id', threadId), Q.sortBy('created_at', Q.desc))
  .observe();

// in component (RN with @nozbe/watermelondb/react)
import { withObservables } from '@nozbe/watermelondb/react';
const enhance = withObservables(['threadId'], ({ threadId }) => ({
  messages: database.collections.get<Message>('messages')
    .query(Q.where('thread_id', threadId)).observe(),
}));
```

**TanStack Query persistor**:

```ts
import { QueryClient } from '@tanstack/react-query';
import { persistQueryClient } from '@tanstack/query-persist-client-core';
import { createSyncStoragePersister } from '@tanstack/query-sync-storage-persister';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV({ id: 'rq-cache' });
const persister = createSyncStoragePersister({
  storage: {
    getItem: (k) => storage.getString(k) ?? null,
    setItem: (k, v) => storage.set(k, v),
    removeItem: (k) => storage.delete(k),
  },
});

export const queryClient = new QueryClient({
  defaultOptions: { queries: { gcTime: 1000 * 60 * 60 * 24 } },
});

persistQueryClient({ queryClient, persister, maxAge: 1000 * 60 * 60 * 24 });
```

---

## Comparison

| Lib | Type | Sync API | Reactive | Encryption | Best for |
|---|---|---|---|---|---|
| MMKV | KV | yes | no (poll) | AES | hot prefs, caches |
| op-sqlite | SQL | yes (JSI) | no (manual triggers) | SQLCipher | relational |
| WatermelonDB | doc/SQL | mostly | **yes** | wrap in SQLCipher | lazy lists |
| Realm | object | mostly | **yes** | built-in | quick start |
| AsyncStorage | KV | no | no | none | tiny non-secrets |
| Yjs | CRDT | yes | yes | wrap | collaborative |

---

## Production Usage

- **Banking app**: MMKV (prefs) + op-sqlite (transactions, accounts) + Keychain (tokens).
- **Chat app**: MMKV (settings) + WatermelonDB (messages, threads) + CRDT (drafts shared across devices).
- **E-commerce**: MMKV (cart) + TanStack Query cache (products) + op-sqlite (orders).
- **Notes/Docs (collaborative)**: Yjs document + indexedDB-style persister + MMKV (last-opened doc id).
- **Fitness tracker**: op-sqlite (activity rows) + MMKV (preferences) + file system (GPX exports).

---

## Hands-On Exercise

1. **Implementation**: build a transactions list — pending writes queued locally; reactive list updates as sync completes.
2. **Debugging**: queries slow at 50K rows — add indexes, batch reads, paginate.
3. **Architecture**: split a single Realm DB into MMKV + op-sqlite per domain.
4. **Migration**: write a migration from AsyncStorage → MMKV preserving keys with versioning.

---

## Common Mistakes

- One DB for all data domains.
- Storing big blobs (images, videos) in DB rows → balloon size, slow queries.
- No indexes on WHERE/ORDER BY columns.
- Synchronous SQLite ops on render path with large queries (use pagination).
- AsyncStorage for persistent cache of API responses.
- No schema versioning → painful migrations.
- Forgetting to handle DB-corruption recovery.

---

## Production Red Flags

- **`AsyncStorage.setItem(JSON.stringify(hugeArray))`** → quadratic memory.
- **No `WAL` mode** on SQLite → write blocking under contention.
- **Synchronous full-table scans** on UI thread.
- **Realm objects passed across threads** without freezing → crashes.
- **No telemetry on storage size** → users hit OS quota.

---

## Performance & Metrics (MANDATORY)

- **MMKV read**: ~ns–µs.
- **op-sqlite simple SELECT**: ~ms (indexed); ~tens of ms (full scan small table).
- **WatermelonDB query**: ms; observer notification ~ms.
- **AsyncStorage read**: ms (each call); async overhead.
- **Storage footprint**: monitor; iOS/Android may evict app data when low.

---

## Metrics That Matter

- DB size per user
- Query P95 latency
- Migration success rate
- Sync queue depth + drain time
- Cache hit rate (TanStack Query)
- Storage-quota errors

---

## Decision Framework

| Use case | Stack |
|---|---|
| Banking | MMKV + op-sqlite (SQLCipher) + Keychain |
| Chat | MMKV + WatermelonDB |
| Collab editor | Yjs + IndexedDB-like persister |
| Read-mostly content app | TanStack Query cache + MMKV prefs |
| Notes | Realm or op-sqlite |

---

## Senior-Level Insight

The mature take: **storage architecture deserves its own ADR** (Architecture Decision Record). Document why each domain picked its DB; record migration plans; record limits (max rows, sync cadence). Senior engineers also write **storage adapter interfaces** so swapping engines later is feasible (rare but happens — Realm → op-sqlite migration is a classic 2024–2026 story).

Org-level: maintain a "storage cookbook" — when a new feature lands, the doc tells engineers which engine to pick and why. Avoid letting each team invent their own.

The 2026 specific: with **Static Hermes** + **JSI-native** storage libs, the old async-only constraints are gone. Engineers must consciously decide async vs sync (sync is fine for fast ops; async still useful for I/O-heavy batch).

---

## Real-World Scenario

**Symptom:** App startup time grew from 1.2s → 3.5s over 6 months.
**Investigation:** AsyncStorage backing rehydrating Redux store; size grew with user activity history.
**Root Cause:** AsyncStorage used as primary persistent store; serialize/deserialize cost ballooned.
**Fix:** Move history to op-sqlite with pagination; MMKV for hot prefs; rehydrate only essential prefs synchronously.
**Lesson:** AsyncStorage cost scales with size; not for "real" persistence.

---

## Production Failure Story

**Incident:** A messaging app stored chat messages in AsyncStorage. After 18 months, top users had 100MB+ AsyncStorage; app crashed at launch on low-RAM Android due to OOM during rehydration.
**Impact:** ~3% of users locked out; emergency hotfix.
**Investigation:** AsyncStorage rehydrated entire blob into JS heap synchronously.
**Root Cause:** Wrong storage for high-volume relational data.
**Fix:** Migrate messages to WatermelonDB (lazy load, observer-based); ship migration that drains AsyncStorage in batches.
**Prevention:** Storage policy doc; new domains require decision review.

---

## Debugging Checklist

1. Inspect DB size: `du -h` the file; iOS DB Browser, Android `adb pull`.
2. SQLite `EXPLAIN QUERY PLAN` to verify index usage.
3. Profile slow query: `PRAGMA compile_options;` confirm WAL.
4. Check fragmentation: `PRAGMA freelist_count;` → vacuum if high.
5. Reactive query firing too often → narrow observer.
6. Telemetry: per-query duration, per-write success.

---

## Advanced / Internal Knowledge

- SQLite WAL mode allows concurrent readers + one writer; default in op-sqlite.
- `PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;` typical mobile config.
- MMKV file format: append-only with periodic compact.
- WatermelonDB sync protocol: `pulled changes + push pending` per table.
- Realm's MVCC under the hood; transactions snapshot reads.
- CRDT internals (Yjs): each op carries a `(clientId, clock)` ID; merging is a structural fold.

---

## 2026 AI Tip

- AI is **good at**: scaffolding schema + query code; suggesting indexes.
- AI is **bad at**: migration planning; sync-conflict policies.
- **Hallucination risk**: AI may suggest `LIKE '%term%'` queries which can't use indexes; specify FTS5 if full-text needed.
- **Prompt pattern**: "Design a storage layer for an offline-first messaging app: entities, indexes, MMKV prefs, sync queue table, migration script."

---

## Related Topics

- Q2 MMKV deep
- Q3 SQLite vs Watermelon vs Realm
- Q4 CRDTs
- Q5 sync engines
- S8 state mgmt
- S10 Q2 secure storage

---

## Interview Follow-Up Questions

- Why would you ever pick MMKV over AsyncStorage if both are KV?
- When does WatermelonDB's reactive layer beat raw SQLite?
- What does WAL give you?
- How do you migrate a schema across app versions safely?
- When is a CRDT actually justified?

---

## Memory Hook

**"Right pipe per data type."**

## Revision Notes

> MMKV = hot KV. op-sqlite = relational. WatermelonDB = reactive lazy lists. Realm = object DB. CRDT = collab. TanStack Query = ephemeral cache. AsyncStorage = legacy/tiny. Combine them; one DB never fits all.

---

---

### Q2. MMKV deep dive — JSI integration, encryption, multi-process

---

## Difficulty
- Mid–Advanced

## Interview Frequency
- Common

## Prerequisites
- KV storage basics, mmap concept

## TL;DR
**MMKV is mmap-backed, append-only, JSI-synchronous KV** — ~10–100× faster than AsyncStorage. Single instance per process is fine; **multi-process** (Share Extension, widget) needs separate instances writing to the same path with proper coordination. **AES-128 CFB encryption** with key from Keychain/Keystore for sensitive data. Auto-compacted; CRC-protected; survives crashes mid-write.

---

## 30-Second Interview Answer

> "MMKV uses mmap, so writes go to memory and the OS flushes to disk lazily — that's why it's so fast. JSI bindings make reads/writes synchronous from JS, no bridge round-trips. For encryption, pass an `encryptionKey` to the constructor; AES-128 CFB. The key itself goes in Keychain/Keystore — never hardcoded. Multi-process (e.g., Share Extension) needs the underlying file to live in an app group container; MMKV handles cross-process locking. It's append-only with periodic auto-compact, so writes are O(1) until compaction. CRC on every value catches corruption."

---

## 2-Minute Practical Answer

Why MMKV is fast:
1. **mmap** — file mapped to memory; reads = memory reads.
2. **Append-only** — writes append to end; no in-place mutation; no blocking.
3. **JSI** — direct C++ ↔ JS calls; no async bridge.
4. **Optimized binary format** — protobuf-derived compact encoding.
5. **No JSON parse/stringify** — primitives stored natively (string, number, bool, bytes).

Encryption:
```ts
import { MMKV } from 'react-native-mmkv';
const storage = new MMKV({ id: 'secure', encryptionKey: 'key-from-keychain' });
```
- AES-128 CFB.
- Key must be ≥16 bytes; pass as string (treated as UTF-8).
- Encrypt entire instance; not per-key.
- To rotate key: read all → create new instance with new key → write all → delete old file. Or use `encryption_setEncryptionKey()` if supported.

Multi-process:
- Each process creates its own MMKV instance pointing to same `id` + `path`.
- MMKV uses inter-process locks (POSIX fcntl) for writes.
- iOS App Groups: pass `path` to shared container.
- Android: shared file location; both processes have same UID.

Crash resilience:
- Append-only + CRC means partial writes are detected and skipped on next read.
- Compaction is atomic via temp file + rename.

Limits:
- Single value: typically <4KB efficient; larger works but slower.
- File size: practical ~tens of MB; if you're storing more, wrong tool.
- No queries; key-by-key only.

---

## 5-Minute Architecture Answer

MMKV (Tencent open-source, ported to RN) emerged because the standard mobile KV stores are slow:
- iOS NSUserDefaults: plist, full rewrite on each save.
- Android SharedPreferences: XML, sync on commit.
- AsyncStorage: file (iOS) / SQLite (Android) with async marshaling overhead.

MMKV's design:
- One file per **MMKV ID**; multiple IDs = multiple files (good for isolation).
- File contains: header (size, CRC) + sequence of `(keyLen, key, valueLen, value)` records.
- New write = append record; reads = walk records (cached in memory map).
- On open, MMKV scans the file and builds an in-memory index `(key → latest record offset)`.
- Background compaction rewrites file with only latest values when size exceeds threshold.

JSI integration:
- C++ `MMKV` class exposed as JS object via JSI HostObject.
- `set('k', 'v')` → C++ call → memcpy into mmap region.
- `getString('k')` → C++ call → returns reference to mapped memory (zero-copy where possible).
- No async, no serialization through bridge.

Encryption:
- AES-128 CFB chosen for streaming friendliness (block-aligned writes).
- Key kept in C++ instance; not exposed to JS.
- Each value record encrypted independently.
- Performance overhead: small (~10–20%).

Multi-process safety:
- POSIX `fcntl(F_OFD_SETLKW)` advisory locks on file region.
- Reader doesn't block reader; writer takes exclusive lock.
- iOS App Group containers (`group.com.example.app`) allow Share Extension / widget to share MMKV.
- Android: shared internal storage; same UID.

Failure modes handled:
- App killed mid-write: half-record CRC fails; ignored on next read.
- Disk full: write fails; subsequent reads still work.
- File corruption (bad sectors): CRC detects; instance can self-recover by truncating to last valid offset.

The 2026 specific:
- **JSI Host Objects** + **Static Hermes** make MMKV near-zero-overhead from JS.
- **react-native-mmkv v3+** supports per-key TTL and JSI-native observers (changed-key callbacks).
- **App Clips / iOS Widgets** explicitly designed around shared MMKV.
- **Encrypted SQLite (op-sqlite + SQLCipher)** is the structured peer; MMKV stays the right answer for KV.

When MMKV is the wrong tool:
- More than ~50MB total → use SQLite.
- Need queries → use SQLite.
- Need transactions across multiple keys → use SQLite (MMKV writes are atomic per-key only).
- Need server sync — pair MMKV with a sync layer or pick a sync-aware DB.

---

## The "Why"

Storage performance is invisible until it isn't. AsyncStorage at 100µs/read × hundreds of reads on app start = visible jank. MMKV at sub-µs reads = no impact. Companies care because perceived performance drives retention; cold-start time directly correlates with conversion.

---

## Mental Model

MMKV = a notebook where you only ever append. The latest entry for a key wins. Every so often, you rewrite the notebook keeping only the latest of each key. That's why it's fast and crash-safe.

---

## Internal Working (2026 Context)

- C++ `MMKV` class; mmap with `MAP_SHARED`; OS handles flushing.
- File path: `<app-data>/mmkv/<id>` (configurable).
- Default mmap size grows in 4KB pages.
- Compaction trigger: when free space (overwritten/old records) > threshold.
- iOS: file protection class default `NSFileProtectionCompleteUntilFirstUserAuthentication`.
- Android: `MODE_PRIVATE` files in app sandbox.

---

## Modern Implementation (Code)

**Basic setup**:
```ts
import { MMKV } from 'react-native-mmkv';

export const prefs = new MMKV({ id: 'prefs' });
prefs.set('theme', 'dark');
prefs.set('debug', true);
prefs.set('count', 42);
const theme = prefs.getString('theme');
```

**Encrypted instance with key from Keychain**:
```ts
import * as Keychain from 'react-native-keychain';
import { MMKV } from 'react-native-mmkv';

async function getEncryptedStorage(): Promise<MMKV> {
  let creds = await Keychain.getInternetCredentials('mmkv-key');
  let key: string;
  if (!creds) {
    key = generateRandomBase64(32);
    await Keychain.setInternetCredentials('mmkv-key', 'mmkv', key, {
      accessible: Keychain.ACCESSIBLE.AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY,
    });
  } else {
    key = (creds as Keychain.UserCredentials).password;
  }
  return new MMKV({ id: 'secure', encryptionKey: key });
}
```

**Multi-process (iOS App Group)**:
```ts
const widgetStorage = new MMKV({
  id: 'widget-shared',
  path: '/var/mobile/Containers/Shared/AppGroup/<group-id>/mmkv',
});
```
For iOS, also configure `App Groups` capability + entitlements; resolve path via `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`.

**Reactive use with React** (`useMMKVString`):
```tsx
import { useMMKVString } from 'react-native-mmkv';

function ThemeToggle() {
  const [theme, setTheme] = useMMKVString('theme', prefs);
  return (
    <Switch value={theme === 'dark'}
            onValueChange={(v) => setTheme(v ? 'dark' : 'light')} />
  );
}
```

**Subscribe to changes**:
```ts
const listener = prefs.addOnValueChangedListener((changedKey) => {
  if (changedKey === 'theme') applyTheme(prefs.getString('theme'));
});
// cleanup: listener.remove()
```

**Migration from AsyncStorage**:
```ts
import AsyncStorage from '@react-native-async-storage/async-storage';

const MIGRATION_KEY = '__mmkv_migrated_v1';

export async function migrateAsyncStorageToMMKV() {
  if (prefs.getBoolean(MIGRATION_KEY)) return;
  const keys = await AsyncStorage.getAllKeys();
  const items = await AsyncStorage.multiGet(keys);
  for (const [k, v] of items) {
    if (v == null) continue;
    prefs.set(k, v);   // string-only; parse if you stored JSON
  }
  prefs.set(MIGRATION_KEY, true);
  await AsyncStorage.multiRemove(keys);
}
```

---

## Comparison

| Op | MMKV | AsyncStorage | NSUserDefaults / SharedPrefs |
|---|---|---|---|
| Read | sync, ns–µs | async, ms | async, ms |
| Write | sync, µs | async, ms | async, ms |
| Encryption | built-in (AES-128) | none | none (Android: EncryptedSharedPrefs) |
| Multi-process | yes | no (RN) | yes (with care) |
| TTL | yes (v3+) | no | no |
| Observers | yes | no | yes |

---

## Production Usage

- **Hot prefs**: theme, locale, last-tab, feature flags, AB-test buckets.
- **Cache headers**: ETag store, last-fetched timestamps.
- **Onboarding state**: which screens user saw.
- **Lightweight encryption-key wrapping** (per-domain key wrapped by Keychain master key).
- **Widgets / Share Extension shared state**.
- **Quick-resume tokens** (non-sensitive).

---

## Hands-On Exercise

1. **Implementation**: replace AsyncStorage with MMKV across an app; measure cold-start delta.
2. **Debugging**: app crashes on startup after upgrade — likely DB format change; provide migration path.
3. **Architecture**: design a multi-process MMKV layout for App + Share Extension on iOS.
4. **Encryption**: rotate the encryption key without losing data.

---

## Common Mistakes

- Storing huge JSON blobs in one MMKV key (>1MB) — slow reads, defeats purpose.
- Using same MMKV id across unrelated domains — operational risk on bugs.
- Not encrypting when storing PII.
- Hardcoding encryption key.
- Forgetting App Group config when sharing across processes.
- Using MMKV as a queue (no FIFO support; use SQLite).

---

## Production Red Flags

- **`new MMKV()` called in render** → repeated init; cache the instance.
- **`prefs.set('user', JSON.stringify(huge))`** → wrong tool.
- **Encryption key in env constant** → in bundle.
- **No migration plan** when bumping app major version.

---

## Performance & Metrics (MANDATORY)

- **Read**: ~50–500ns hot; ~µs cold (after open).
- **Write**: ~µs.
- **Open**: ~ms (scans file).
- **Memory**: instance ~KB + mapped file size.
- **Bundle**: ~50KB.

---

## Metrics That Matter

- File size per instance (alert if growing unexpectedly)
- Compaction frequency
- Open-time on cold start
- Encryption-init failure rate

---

## Decision Framework

| Need | MMKV? |
|---|---|
| Single value by key | yes |
| Tiny structured (preferences) | yes |
| Large blob (>1MB) | no — file system |
| Relational | no — SQLite |
| Multi-process shared | yes (with App Group) |
| TTL cache | yes (v3+) |
| Sensitive data | yes + encryption + Keychain key |

---

## Senior-Level Insight

The mature take: MMKV is *the* default for fast KV, but it's not a database. Senior engineers wrap it in a typed `prefs` API (`getTheme()`, `setTheme(t)`) so the rest of the app doesn't see raw `MMKV` calls — that lets you swap backends if needed and validates types at one place. Also: pre-load critical prefs synchronously in `App.tsx` to cut cold-start jank.

---

## Real-World Scenario

**Symptom:** Widget shows stale data after main app update.
**Investigation:** Main app and widget had separate MMKV instances at different paths.
**Root Cause:** Path not pointed at App Group shared container.
**Fix:** Configure App Group entitlement + use shared container path; both processes see same data.
**Lesson:** Multi-process MMKV requires explicit shared-container path on iOS.

---

## Production Failure Story

**Incident:** Encryption key rotation script ran on a subset of users; instance failed to open with "wrong key".
**Impact:** Those users got fresh launch state; no data loss but reset preferences.
**Investigation:** Rotation logic forgot to handle case where new key write succeeded but old data wasn't re-encrypted.
**Root Cause:** Key rotation isn't atomic for entire instance content.
**Fix:** New rotation: open with old key → snapshot data → wipe → reopen with new key → restore.
**Prevention:** Rotation script wrapped in test + canary + rollback path.

---

## Debugging Checklist

1. Verify file exists at expected path.
2. Check size growth pattern: large write spike?
3. Compaction running? Force `prefs.trim()` if available.
4. Multi-process: confirm shared container path + App Group entitlement.
5. Encryption: test instance creation + key from Keychain.
6. Telemetry: instance-init failures, value-read CRC failures.

---

## Advanced / Internal Knowledge

- MMKV uses Tencent's open-source library; RN binding is JSI-based.
- File format: little-endian, length-prefixed records.
- CRC32 per record.
- iOS file protection class: configurable via init.
- Android: `Context.NO_BACKUP_FILES_DIR` to exclude from auto-backup.

---

## 2026 AI Tip

- AI is **good at**: typed wrapper generation.
- AI is **bad at**: multi-process / App Group config nuances.
- **Prompt pattern**: "Wrap MMKV with a typed `prefs` API exposing `get/set` for each key with default values; also implement migration from AsyncStorage."

---

## Related Topics

- Q1 storage decision tree
- S10 Q2 secure storage
- S8 state mgmt (zustand persistence to MMKV)

---

## Interview Follow-Up Questions

- Why is MMKV faster than AsyncStorage?
- How does MMKV survive app crash mid-write?
- Multi-process: how do you share MMKV across app + widget?
- How do you rotate the encryption key?
- When would you NOT use MMKV?

---

## Memory Hook

**"mmap, append, JSI."**

## Revision Notes

> MMKV: mmap + append-only + JSI = sync ns–µs reads. AES-128 CFB encryption; key in Keychain. Multi-process via App Group / shared dir. Compaction auto. CRC for crash safety. Wrong for >50MB or queries. Wrap in typed prefs API.

---

---

### Q3. op-sqlite vs WatermelonDB vs Realm — when each wins

---

## Difficulty
- Advanced

## Interview Frequency
- Common (any app with structured local data)

## Prerequisites
- SQL basics, JSI concept

## TL;DR
**op-sqlite** for raw SQL power and minimal magic — pair with Drizzle/Kysely for type safety. **WatermelonDB** when you need reactive lazy-loaded lists with built-in sync protocol. **Realm** for fast time-to-first-feature with object syntax + encryption + Atlas Sync — but expect lock-in and migration friction. Pick op-sqlite by default in 2026 unless you specifically need WatermelonDB's reactive sync layer or Realm's object simplicity.

---

## 30-Second Interview Answer

> "Three different positions. op-sqlite is JSI-native SQLite — sync API, full SQL, you bring your own ORM (Drizzle is the modern pick) or query layer. Watermelon is built around lazy reactive observers + a sync protocol — great for chat / feeds with thousands of items. Realm is the highest-level: object-graph, reactive, encryption built-in, optional Atlas sync — fastest to MVP but more lock-in. In 2026 I default to op-sqlite + Drizzle for new apps because it composes best with the rest of the ecosystem; I pick Watermelon if I need its reactive sync, Realm only for legacy or when the team explicitly wants Atlas."

---

## 2-Minute Practical Answer

Side-by-side:

| | op-sqlite | WatermelonDB | Realm |
|---|---|---|---|
| **Engine** | SQLite via JSI | SQLite + reactive layer | proprietary native store |
| **Query** | SQL (or Drizzle/Kysely) | Watermelon Q.* DSL → SQL | Realm query language |
| **Reactive** | manual (subscribe to triggers) | **built-in observers** | **built-in observers** |
| **Sync** | bring your own | **built-in protocol** | **Atlas Device Sync** (paid) |
| **Encryption** | SQLCipher (build flag) | wrap with SQLCipher | **built-in AES-256** |
| **Migrations** | raw SQL or Drizzle migrator | declarative schema versioning | declarative migrations |
| **TS support** | excellent (Drizzle) | good | good |
| **Bundle size** | ~MB (with SQLCipher) | ~MB | larger |
| **Lock-in** | low | medium | high |
| **Learning curve** | low (SQL) | medium | medium |

When each wins:
- **op-sqlite + Drizzle**: relational data, complex queries, custom sync logic, you want SQL fluency.
- **WatermelonDB**: chat / feed / list-heavy app where reactivity + lazy load + sync matter; you accept its DSL.
- **Realm**: small team, MVP speed, simple object graph, willing to pay for Atlas Sync, less SQL skill on team.

In 2026, my default: **op-sqlite + Drizzle**. Reasons:
- JSI-native sync API works on render path.
- Drizzle gives end-to-end TS types from schema.
- Plain SQL is portable; future migration is easy.
- Full ecosystem (FTS5, JSON columns, sqlite-vss for vector search).

I'd reach for **WatermelonDB** if I'm building a chat app from scratch and want reactive observers + sync without inventing them.

I'd reach for **Realm** mostly if the team already uses it or specifically wants Atlas Sync's bidirectional handling and is OK with vendor coupling.

---

## 5-Minute Architecture Answer

Each library reflects different design philosophies:

**op-sqlite** — "give me SQLite, fast":
- JSI bindings to system SQLite.
- Synchronous API; no bridge overhead.
- Pairs with any query builder (Drizzle, Kysely, raw).
- WAL mode default.
- SQLCipher as compile flag.
- Statement caching, batched inserts via `executeBatch`.
- Best for: structured relational data, where you want to control the schema and queries explicitly.

**WatermelonDB** — "reactive offline-first":
- Layered on SQLite under the hood.
- ORM-like models with `@field`, `@relation`, `@children`.
- Lazy: queries return Observables; rows hydrate only when accessed.
- Built-in sync protocol: `synchronize({ pullChanges, pushChanges })`.
- Conflict resolution: last-write-wins by default; customizable.
- Migrations: declarative table/column add; drop is intentional (forces thinking).
- Best for: chat / messaging / large lists with frequent updates.

**Realm** — "object graph with batteries":
- Native binary format; not SQLite.
- Object-oriented API; live objects update automatically.
- Strong typing via schemas.
- Encryption-at-rest built-in; pass key.
- Atlas Device Sync (paid) for backend sync — handles conflicts via OT-like mechanism.
- Migrations declarative; type changes can require migration block.
- Best for: rapid prototyping; teams comfortable with object-graph mental model.

The 2026 specific:
- op-sqlite v8+ has Drizzle integration baked in; Drizzle adds zero-cost type inference.
- WatermelonDB stable around v0.27+ with JSI adapter.
- Realm v12+ supports React 19 patterns and Atlas Sync improvements.
- **Static Hermes** + JSI sync libs make sync APIs first-class on render paths.
- **Replicache / Triplit / Linear-style sync engines** are eating Realm-Sync mindshare; consider as alternatives if Atlas-style sync is the actual driver.
- **Vector storage** (sqlite-vss) only available via op-sqlite path.

Migration paths:
- Realm → op-sqlite: straightforward but laborious (write export script, transform schema).
- WatermelonDB → op-sqlite: easier (already SQLite under the hood).
- AsyncStorage → any: write batched migration with a version flag in MMKV.

---

## The "Why"

Picking the right one saves years of friction. Wrong choice = endless migration debt. Companies care because data layer choices outlive the engineers who made them; whatever you pick today is likely what you'll be on in 5 years.

---

## Mental Model

- **op-sqlite** = a sharp scalpel — does exactly what you tell it.
- **WatermelonDB** = a power tool with safety guards — opinionated, optimized for one workflow.
- **Realm** = a Swiss Army knife — convenient for many things, hard to swap once embedded.

---

## Internal Working (2026 Context)

- op-sqlite: JSI HostObject wraps `sqlite3*`; calls go straight to C API.
- WatermelonDB: SQLite adapter + in-memory observer registry; queries compiled to SQL; observers fire after writes.
- Realm: Realm Core (C++) + native bindings + Bindings Generator; reactive notifications via change tokens.

---

## Modern Implementation (Code)

**op-sqlite + Drizzle migration**:

```ts
// drizzle/0001_init.sql (auto-generated)
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  thread_id TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE INDEX messages_thread_idx ON messages(thread_id, created_at);

// runtime
import { open } from '@op-engineering/op-sqlite';
import { drizzle } from 'drizzle-orm/op-sqlite';
import { migrate } from 'drizzle-orm/op-sqlite/migrator';

const sqlite = open({ name: 'app.db' });
export const db = drizzle(sqlite, { schema });
await migrate(db, { migrationsFolder: './drizzle' });
```

**WatermelonDB model + reactive query**:
```ts
// model
export default class Message extends Model {
  static table = 'messages';
  @field('thread_id') threadId!: string;
  @field('body') body!: string;
  @date('created_at') createdAt!: Date;
}

// reactive query
const enhance = withObservables(['threadId'], ({ threadId }) => ({
  messages: database.collections.get<Message>('messages')
    .query(Q.where('thread_id', threadId), Q.sortBy('created_at', Q.asc))
    .observe(),
}));

const MessageList = enhance(({ messages }: { messages: Message[] }) => (
  <FlashList data={messages} renderItem={({ item }) => <Bubble m={item} />} />
));

// sync
import { synchronize } from '@nozbe/watermelondb/sync';

await synchronize({
  database,
  pullChanges: async ({ lastPulledAt }) => {
    const r = await api.pull({ since: lastPulledAt });
    return { changes: r.changes, timestamp: r.timestamp };
  },
  pushChanges: async ({ changes, lastPulledAt }) => {
    await api.push({ changes, lastPulledAt });
  },
});
```

**Realm schema + observer**:
```ts
import Realm from 'realm';

class Message extends Realm.Object<Message> {
  _id!: Realm.BSON.ObjectId;
  body!: string;
  threadId!: string;
  createdAt!: Date;
  static schema: Realm.ObjectSchema = {
    name: 'Message',
    primaryKey: '_id',
    properties: {
      _id: 'objectId',
      body: 'string',
      threadId: { type: 'string', indexed: true },
      createdAt: 'date',
    },
  };
}

const realm = await Realm.open({
  schema: [Message],
  encryptionKey: await getRealmKey(),
});

const messages = realm.objects(Message)
  .filtered('threadId == $0', threadId)
  .sorted('createdAt');

messages.addListener((collection, changes) => {
  // re-render with collection
});
```

---

## Comparison

| Scenario | Best pick |
|---|---|
| Banking transactions (relational, audit) | op-sqlite + Drizzle |
| Chat / messaging | WatermelonDB |
| Personal notes (object graph, fast MVP) | Realm |
| Fitness tracker (time series) | op-sqlite |
| Collaborative doc | Yjs (CRDT) + op-sqlite for persistence |
| Local-first SaaS (Linear-style) | Triplit / Replicache + op-sqlite |
| Read-only catalog | TanStack Query cache + MMKV |

---

## Production Usage

- **Big consumer apps with chat**: WatermelonDB (Trello, several messaging apps historically).
- **Fintech**: op-sqlite for transactions; MMKV for prefs.
- **Notes apps**: Realm or op-sqlite + custom sync.
- **Local-first 2026 apps**: trending toward op-sqlite + Triplit / Replicache.

---

## Hands-On Exercise

1. **Implementation**: rewrite the same chat schema in all three libs; compare line count, query ergonomics, perf.
2. **Debugging**: WatermelonDB sync conflict — observe its conflict callback and design custom resolution.
3. **Architecture**: design a migration from Realm to op-sqlite for a 100K-row dataset.
4. **Performance**: benchmark 10K-row insert + indexed query across all three.

---

## Common Mistakes

- Choosing Realm "because it's easy" then hitting Atlas Sync limits or pricing.
- Choosing op-sqlite without indexes → slow.
- WatermelonDB without understanding the sync protocol → data loss on conflicts.
- Mixing two heavy DBs in one app for no reason.
- Not benchmarking on low-end Android device.

---

## Production Red Flags

- **Realm files >100MB** without size monitoring.
- **WatermelonDB sync without conflict policy** → silent overwrites.
- **op-sqlite raw SQL without prepared statements** → injection risk + perf.
- **No DB error handling** → silent corruption.

---

## Performance & Metrics (MANDATORY)

- **op-sqlite**: 10–50µs simple SELECT, 100µs–ms write.
- **WatermelonDB**: similar to SQLite + observer notify ms.
- **Realm**: comparable; encryption ~10–30% overhead.
- **All**: avoid >1k row sync queries; paginate.

---

## Metrics That Matter

- DB file size growth
- Query P95 per table
- Sync queue depth (Watermelon/Realm Sync)
- Observer-fire frequency (avoid storms)
- Migration success rate

---

## Decision Framework

| Tie-breaker | Lean toward |
|---|---|
| Team strong in SQL | op-sqlite + Drizzle |
| Need built-in sync | WatermelonDB or Realm Sync |
| Fastest MVP | Realm |
| Want to swap later | op-sqlite |
| Vector / FTS / full SQLite ecosystem | op-sqlite |

---

## Senior-Level Insight

The mature take: **don't pick a DB based on demos**. Build a 200-row prototype of your real schema in the candidate libs, run real queries on a low-end device, see what migrations look like for v2 of the schema. Senior engineers also invest in a thin **repository abstraction** — UI talks to repositories, repositories talk to the DB. That makes engine swaps painful but feasible later.

Org-level: avoid ad-hoc DB choices per team — pick one or two and standardize.

---

## Real-World Scenario

**Symptom:** Realm Sync bills exploding at 5M users.
**Investigation:** Free tier exceeded; per-user sync cost grew with active devices.
**Root Cause:** Atlas Sync pricing model didn't fit consumer scale.
**Fix:** Migrate to op-sqlite + custom REST sync; project took 6 months.
**Lesson:** Consider sync cost at scale before adopting hosted sync solutions.

---

## Production Failure Story

**Incident:** A note-taking app on WatermelonDB shipped a release that changed a column from `string` to `number` without a proper migration. App crashed at start for existing users.
**Impact:** Emergency rollback; reputation hit.
**Investigation:** Schema version was bumped but migration script lacked `addColumns`; existing users had wrong-typed data.
**Root Cause:** Migration not tested against real existing schema.
**Fix:** Always test migrations against snapshots from production data.
**Prevention:** Migration test harness with snapshots from each released version.

---

## Debugging Checklist

1. Enable SQLite query log; identify slow queries.
2. `EXPLAIN QUERY PLAN` for any SELECT in hot path.
3. Add indexes; re-measure.
4. Realm: check schema version mismatch on open.
5. WatermelonDB: log sync push/pull payloads + conflict events.
6. Telemetry: per-DB error rate.

---

## Advanced / Internal Knowledge

- op-sqlite supports `EXTENSION_LOAD` for sqlite-vss / FTS5.
- Drizzle generates TS types from schema; zero runtime cost.
- WatermelonDB uses `_status` column for sync state.
- Realm uses MVCC; readers don't block writers.
- All three benefit from batching writes inside a single transaction.

---

## 2026 AI Tip

- AI is **good at**: scaffolding schemas + queries.
- AI is **bad at**: choosing between libraries — depends on context.
- **Prompt pattern**: "Implement a `messages` repository with op-sqlite + Drizzle, schema with thread_id index, paginated query, and a sync queue table for outbound writes."

---

## Related Topics

- Q1 storage decision tree
- Q5 sync engines
- S8 state mgmt
- S22 system design

---

## Interview Follow-Up Questions

- When does WatermelonDB beat op-sqlite?
- What's the migration story from Realm to op-sqlite?
- Why would you avoid Atlas Device Sync?
- How do you benchmark mobile DBs honestly?
- What does Drizzle add over raw SQL?

---

## Memory Hook

**"SQL sharp, Watermelon reactive, Realm convenient."**

## Revision Notes

> op-sqlite + Drizzle = default in 2026. WatermelonDB for reactive lazy lists with sync. Realm for MVP / Atlas Sync. Always benchmark on low-end Android. Wrap in repository to keep swap option. Migrations are the silent killer — test against snapshots.

---

---

### Q4. CRDTs for collaborative mobile apps (Yjs / Automerge)

---

## Difficulty
- Expert

## Interview Frequency
- Niche but rising (collab, local-first, multi-device sync)

## Prerequisites
- Distributed systems basics, eventual consistency

## TL;DR
**CRDTs** (Conflict-free Replicated Data Types) let multiple clients edit the same data offline and merge **deterministically** without a central server arbiter. **Yjs** is fast, compact, JS-native — best for text/rich-text/structured docs. **Automerge** is more general (any JSON-like) with stronger formal foundation. Use them for **collaborative editors**, **multi-device user data**, **local-first SaaS**. Persistence: serialize CRDT bytes to MMKV/SQLite. Transport: any (WebSocket, WebRTC, REST polling).

---

## 30-Second Interview Answer

> "A CRDT is a data structure where any two replicas eventually converge no matter what order operations arrive in. Yjs and Automerge are the two production-grade JS implementations. Yjs is faster and smaller — perfect for text editors, collaborative docs, multi-device sync of structured data. Automerge is more general-purpose, with stronger formal grounding. The tradeoff vs traditional sync: no server-side conflict logic; clients merge themselves. Cost: data structure overhead (each op carries metadata), and you have to pick the right CRDT type per data shape. For mobile, persist the CRDT binary blob in MMKV or SQLite, transport over WebSocket/WebRTC/whatever."

---

## 2-Minute Practical Answer

Why CRDT vs traditional sync:
- Traditional: server resolves conflicts; clients trust server; offline edits must reconcile against current server state.
- CRDT: every op carries causal metadata `(replicaId, clock)`; merging is associative + commutative; offline edits "just work" when reconnected.

What CRDTs solve well:
- Collaborative text editing (Google Docs-like).
- Multi-device personal data sync (notes, todos, settings).
- Real-time presence + state.
- Offline-first SaaS.

What they don't:
- Strong consistency / serializability (e.g., bank balance).
- Authorization / access control (need server layer).
- Dedup at semantic level (CRDT preserves intent, not invariants).

Yjs basics:
```ts
import * as Y from 'yjs';

const doc = new Y.Doc();
const text = doc.getText('content');
text.insert(0, 'Hello');     // Y.Text
const map = doc.getMap('meta');
map.set('title', 'My Doc');  // Y.Map
const arr = doc.getArray('items');
arr.push([{ id: 1 }]);       // Y.Array

// serialize for storage / transport
const bytes = Y.encodeStateAsUpdate(doc);

// apply remote update
const remoteBytes: Uint8Array = await fetchUpdate();
Y.applyUpdate(doc, remoteBytes);

// observe
text.observe((event) => { /* re-render */ });
```

Automerge basics:
```ts
import * as Automerge from '@automerge/automerge';

let doc = Automerge.init<{ title: string; items: any[] }>();
doc = Automerge.change(doc, (d) => {
  d.title = 'My Doc';
  d.items = [];
  d.items.push({ id: 1 });
});

const bytes = Automerge.save(doc);
const merged = Automerge.merge(doc, otherDoc);
```

Persistence on mobile:
- Yjs: write `Y.encodeStateAsUpdate(doc)` (incremental updates) to MMKV / SQLite blob column.
- Automerge: `Automerge.save(doc)` snapshot or incremental changes.
- Often: store base snapshot + append incremental updates; periodically compact.

Transport:
- WebSocket: y-websocket / Automerge-Repo.
- WebRTC: peer-to-peer, no server (yjs-webrtc).
- REST polling: simpler but higher latency.
- IPFS/libp2p for fully P2P.

---

## 5-Minute Architecture Answer

CRDTs evolved from CS research (Shapiro et al., Inria). Two families:
- **State-based (CvRDT)**: replicas exchange full state; merge function is deterministic join.
- **Op-based (CmRDT)**: replicas exchange operations; ops are commutative.

Yjs is op-based with state-based fallback (encode-as-update). Automerge is op-based.

Common CRDT types:
- **G-Counter** (grow-only counter).
- **PN-Counter** (positive/negative).
- **LWW-Register** (last-write-wins by clock).
- **OR-Set** (observed-remove set).
- **RGA / Logoot / Treedoc** (sequence — basis for collaborative text).
- **Yjs custom YATA** algorithm for sequences.

Yjs internals:
- Each insert is an `Item(id, originLeft, originRight, content)`.
- Concurrent inserts at same position resolved deterministically using IDs.
- Tree structure + array index for fast access.
- Compact binary encoding (varint).
- Garbage collection of tombstones.

Automerge internals:
- Operation log (every change is a hash-chained op).
- Causal ordering via "actor + sequence".
- JSON-like document API.
- Versioning + history (can git-like branch & merge).

Mobile considerations:
- **Memory**: long history grows; periodic snapshot + truncate or use Yjs's GC.
- **Storage**: bytes are compact but accumulate; budget per-doc size.
- **CPU**: insert/delete are usually µs; merge is O(operations).
- **Battery**: continuous sync needs awareness — debounce uploads.
- **Battery sync triggers**: only sync on significant change or timed interval.

The 2026 specific:
- **Yjs v14+** improvements in encoding + GC.
- **Automerge 2.x** Rust core via WASM — meaningful speed boost.
- **Liveblocks / PartyKit / Yjs Cloud** offer hosted backends.
- **Local-first** community (inkandswitch.com, etc.) maturing tooling.
- **Static Hermes**: WASM (Automerge) + JSI synchronicity make CRDT hot paths fast.

When CRDTs are the right call:
- Multi-user concurrent editing with offline support.
- Cross-device sync where one user has 3+ devices.
- "Local-first" architecture where server is optional.

When they're overkill:
- Single-user, single-device app — use a regular DB.
- Server-authoritative data (financial balances, inventory) — use traditional locking.
- Simple "last write wins" is fine — use timestamps + manual resolution.

---

## The "Why"

Mobile apps that work offline + sync seamlessly create the strongest UX. CRDTs are the cleanest way to achieve "edit anywhere, merge later, never lose data". Companies care because for collab products this is competitive moat — the alternative (server-mediated locking + manual conflict resolution) is fragile and frustrating.

---

## Mental Model

CRDT = a math-shaped data structure where **(merge(a, b) == merge(b, a)) and (merge(merge(a,b),c) == merge(a, merge(b,c)))**. That property is what lets independent replicas converge regardless of ordering.

Picture: two friends writing in the same Google Doc offline. When they reconnect, the doc has all both edits, in a deterministic order. Nobody had to decide whose change "won".

---

## Internal Working (2026 Context)

- Yjs Doc: `Y.Map`/`Y.Array`/`Y.Text`/`Y.XmlElement` are the shared types.
- Each op has clock `(clientId, clock)`.
- Y.encodeStateAsUpdate(doc) → binary; applies cleanly idempotent.
- Automerge: each change is a hash-linked op; full history preserved (compactable).

---

## Modern Implementation (Code)

**Collaborative text editor (Yjs + RN)**:
```tsx
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';

const doc = new Y.Doc();
const provider = new WebsocketProvider('wss://yjs.example.com', `doc-${docId}`, doc);
const ytext = doc.getText('content');

// Local persistence with MMKV
import { MMKV } from 'react-native-mmkv';
const storage = new MMKV({ id: 'yjs-docs' });

// Save snapshots periodically
let saveTimer: any;
doc.on('update', () => {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    storage.set(`doc-${docId}`, base64encode(Y.encodeStateAsUpdate(doc)));
  }, 500);
});

// Restore on open
const saved = storage.getString(`doc-${docId}`);
if (saved) Y.applyUpdate(doc, base64decode(saved));

function Editor() {
  const [text, setText] = useState(ytext.toString());
  useEffect(() => {
    const handler = () => setText(ytext.toString());
    ytext.observe(handler);
    return () => ytext.unobserve(handler);
  }, []);
  return (
    <TextInput
      value={text}
      onChangeText={(newText) => {
        // diff-and-apply (very simplified)
        ytext.delete(0, ytext.length);
        ytext.insert(0, newText);
      }}
    />
  );
}
```

**Multi-device user data (Automerge)**:
```ts
import * as Automerge from '@automerge/automerge';

type Notes = { items: { id: string; body: string }[] };

// load or init
const stored = storage.getString('notes-doc');
let doc = stored
  ? Automerge.load<Notes>(base64decode(stored))
  : Automerge.from<Notes>({ items: [] });

function addNote(body: string) {
  doc = Automerge.change(doc, (d) => {
    d.items.push({ id: uuid(), body });
  });
  storage.set('notes-doc', base64encode(Automerge.save(doc)));
  uploadToServer(Automerge.getChanges(prevDoc, doc));
}

function applyRemote(changes: Uint8Array[]) {
  doc = Automerge.applyChanges(doc, changes)[0];
  storage.set('notes-doc', base64encode(Automerge.save(doc)));
}
```

**Custom Yjs awareness for presence**:
```ts
const awareness = provider.awareness;
awareness.setLocalState({ user: 'Rajeev', cursor: { row: 3, col: 10 } });

awareness.on('change', () => {
  const states = Array.from(awareness.getStates().values());
  renderCursors(states);
});
```

---

## Comparison

| | Yjs | Automerge | Custom op log |
|---|---|---|---|
| Maturity | very high | high (v2 stable) | DIY |
| Speed | fastest | fast (WASM) | depends |
| Doc size | smallest | moderate | depends |
| Text/RGA | excellent | good | hard |
| JSON-like | OK | excellent | flexible |
| History | partial (with optional history extension) | full | DIY |
| Bundle | ~50–100KB | larger (WASM) | small |

| Transport | Pros |
|---|---|
| y-websocket / Automerge-Repo | turnkey |
| WebRTC (yjs-webrtc) | P2P, no server |
| REST polling | simplest |
| Liveblocks / PartyKit | hosted |

---

## Production Usage

- **Notion / Linear-like SaaS** (local-first variants).
- **Collaborative whiteboards / FigJam-likes** (Yjs underpins many).
- **Multi-device note apps**.
- **In-game shared state** (turn-based, low-frequency).
- **Drafts shared across user's devices** (chat, email composer).

---

## Hands-On Exercise

1. **Implementation**: build a 2-device synced todo list with Yjs + WebSocket.
2. **Debugging**: occasional duplicates after offline edits — usually transport bug, not CRDT bug; verify.
3. **Architecture**: design history compaction for a Yjs doc with 1M+ ops.
4. **Persistence**: combine Yjs + SQLite to store update log + periodic snapshot.

---

## Common Mistakes

- Treating CRDT as a database — it's a data structure; pair with persistence.
- Not handling tombstone growth → docs balloon.
- Sending every op as separate message → bandwidth spike; batch.
- No auth/authz layer → CRDTs preserve intent but anyone can write.
- Using CRDT for non-collab data → unnecessary complexity.

---

## Production Red Flags

- **Doc state size growing unbounded** → no GC / snapshot strategy.
- **No reconnection / catch-up logic** → ops lost.
- **Server stores raw CRDT without auth gate** → anyone can poison doc.
- **Concurrent local writes with race** in your wrapper → reapply ordering issues.

---

## Performance & Metrics (MANDATORY)

- **Yjs insert**: ~µs.
- **Yjs apply update**: ~ms for 1k ops.
- **Doc size**: ~bytes/op.
- **WASM cost (Automerge)**: load ~tens of ms once.
- **Transport**: depends; debounce.

---

## Metrics That Matter

- Doc size per user
- Sync round-trip P95
- Conflict-merge frequency
- Tombstone ratio
- Failed-merge rate (should be 0)

---

## Decision Framework

| Need | Pick |
|---|---|
| Collab text | Yjs (Y.Text) |
| Structured shared state | Yjs (Y.Map/Array) or Automerge |
| Strong history (audit) | Automerge |
| P2P-only | Yjs + yjs-webrtc |
| Hosted backend | Liveblocks / PartyKit / Y-Cloud |
| Simple cross-device sync | Automerge |

---

## Senior-Level Insight

The mature take: **CRDTs are a tool, not a paradigm** — most data still belongs in a regular DB. Carve out the **collaborative subsurface** (the doc body, the shared state) and put it in CRDT; everything else (auth, auditing, billing) stays in your normal stack.

Senior engineers also: (1) plan for snapshots + history compaction from day one, (2) build observability (doc size, ops/sec, conflict rate), (3) test concurrent edit scenarios in CI.

---

## Real-World Scenario

**Symptom:** App memory bloat after long collaborative session.
**Investigation:** Yjs doc accumulated 100k tombstones with no GC.
**Root Cause:** Custom Yjs setup disabled GC; never re-enabled.
**Fix:** Enable Yjs GC; periodic snapshot + truncation; alert on doc size threshold.
**Lesson:** Tombstone growth is real; budget GC.

---

## Production Failure Story

**Incident:** Notes app multi-device sync started losing edits after user roamed networks frequently.
**Impact:** User trust hit; data partially recoverable from local replicas.
**Investigation:** Transport (WebSocket) layer dropped messages on reconnect; client didn't re-sync deltas missed.
**Root Cause:** Sync layer assumed reliable transport; CRDT was correct, transport wasn't.
**Fix:** On reconnect, request `state vector` from server; server sends missing updates.
**Prevention:** Always implement catch-up handshake on reconnect.

---

## Debugging Checklist

1. Verify `state vector` exchange on reconnect.
2. Inspect doc size; alert on growth.
3. Test concurrent offline edits in dev → verify deterministic merge.
4. Profile insert/merge cost on low-end Android.
5. Check tombstone accumulation; enable GC.
6. Telemetry: ops/sec, sync latency, doc-byte-size.

---

## Advanced / Internal Knowledge

- Yjs YATA algorithm: avoids interleaving for concurrent inserts.
- Automerge column-oriented binary format (Bandersnatch).
- Liveblocks open-sourced parts of presence layer.
- ElectricSQL combines CRDT-like sync with Postgres backend.
- Linear's "Sync Engine" is custom but CRDT-inspired.

---

## 2026 AI Tip

- AI is **good at**: scaffolding Yjs editors and Automerge boilerplate.
- AI is **bad at**: tombstone GC strategies and transport debugging.
- **Prompt pattern**: "Implement a multi-device synced note app with Automerge: persistence in MMKV, WebSocket transport, reconnect catch-up, periodic compaction."

---

## Related Topics

- Q5 sync engines
- S9 WebSockets
- S22 system design

---

## Interview Follow-Up Questions

- Why does CRDT merge always converge?
- When is CRDT the wrong choice?
- How do you handle tombstone growth?
- What does Yjs's awareness API give you?
- How do you authorize CRDT writes?

---

## Memory Hook

**"Math-merging math, no central referee."**

## Revision Notes

> CRDT = data structure that converges across replicas. Yjs = fast, text-strong. Automerge = general, with history. Persist binary to MMKV/SQLite. Plan GC/snapshot. Pair with auth layer. Right for collab, wrong for server-authoritative data.

---

---

### Q5. Sync engine design — events, vector clocks, conflict policy

---

## Difficulty
- Expert

## Interview Frequency
- Common (system design rounds)

## Prerequisites
- Q1–Q4, distributed systems basics, idempotency

## TL;DR
Design a **bidirectional sync** as: **local mutation log + server change log + version tokens**. Client buffers writes in a queue table with idempotency keys; periodically pushes; pulls server changes since last cursor. Conflict policy is **explicit**: LWW per-field, server-wins, client-wins, manual merge, or CRDT for shared types. Surface sync state to UI (pending / synced / failed). Handle reordering, retries, partial failures, schema migrations.

---

## 30-Second Interview Answer

> "A sync engine has four pieces: a local outbox of mutations with idempotency keys, a server inbox endpoint that accepts batches, a server change feed clients pull from with a cursor, and a conflict policy. Mutations are journaled before going optimistic in UI. Pulls give the client server-time-ordered changes since `since=cursor`. Conflicts are resolved by the policy you declared per data type — LWW for prefs, server-wins for inventory, CRDT merge for collab docs. UI subscribes to sync state. The hard parts are: idempotency on retry, ordering across multi-device edits, schema migrations across app versions, and clear UX for unresolvable conflicts."

---

## 2-Minute Practical Answer

Architecture:

```
Client                                     Server
+-----------------+                        +-----------------+
| App state       |                        |                 |
| (local DB)      | <----- pulls ----------|  Change feed    |
|                 |                        |  (since cursor) |
+--------+--------+                        +-----------------+
         |                                          |
   write |                                          | write
         v                                          v
+-----------------+    push (batch with         +-----------------+
| Outbox table    |--- idempotency keys) ------>| Inbox/process   |
| (pending writes)|                              | + persist + emit|
+-----------------+                              | change events    |
                                                 +-----------------+
```

Outbox schema (client):
```sql
CREATE TABLE sync_outbox (
  id TEXT PRIMARY KEY,           -- UUID = idempotency key
  entity TEXT NOT NULL,          -- 'transaction', 'message', etc.
  op TEXT NOT NULL,              -- 'create' | 'update' | 'delete'
  payload TEXT NOT NULL,         -- JSON
  base_version INTEGER,          -- for OCC
  created_at INTEGER NOT NULL,
  attempts INTEGER DEFAULT 0,
  last_error TEXT
);
```

Sync loop:
```ts
async function syncCycle() {
  // 1. Pull
  const since = prefs.getNumber('sync_cursor') ?? 0;
  const { changes, cursor } = await api.pull({ since });
  await applyServerChanges(changes);
  prefs.set('sync_cursor', cursor);

  // 2. Push
  const pending = await db.select().from(sync_outbox)
    .orderBy(sync_outbox.created_at).limit(100);
  if (pending.length === 0) return;
  const result = await api.push({ ops: pending });
  for (const r of result.results) {
    if (r.ok) {
      await db.delete(sync_outbox).where(eq(sync_outbox.id, r.id));
    } else if (r.conflict) {
      await resolveConflict(r);
    } else {
      await db.update(sync_outbox).set({ attempts: ... }).where(...);
    }
  }
}
```

Conflict policy types:
- **LWW (last-write-wins)** by timestamp or version — simple, lossy.
- **Server-wins** — client edits dropped.
- **Client-wins** — server overwritten (rare, dangerous).
- **OCC (optimistic concurrency control)** — `base_version` + server rejects on mismatch; client merges and retries.
- **CRDT** — auto-merge for collab types.
- **Manual** — surface to user (rare; only for genuinely ambiguous).

Sync state UI:
```ts
type SyncState = 'idle' | 'syncing' | 'pending' | 'failed' | 'conflict';
```
Show as small indicator. On `failed`, allow manual retry. On `conflict`, show resolution UI.

---

## 5-Minute Architecture Answer

Sync engines are deceptively complex. The naive design is:
1. Save locally.
2. Send to server.
3. Save server response.

Each step has failure modes. Real sync engines must handle:

**Idempotency**:
- Every mutation has client-generated UUID.
- Server records UUIDs; duplicate retries are no-ops.
- Without this: retries cause duplicates.

**Ordering**:
- Client must respect causal order (e.g., create then update).
- Server applies in receive order; clients pull in server-time order.
- Per-entity ordering matters more than global.

**Cursors / version tokens**:
- Server emits monotonically increasing change cursor (DB sequence, hybrid logical clock, or vector clock).
- Client persists cursor; pulls `since=cursor`.
- Multi-device: each device tracks its own cursor.

**Conflict detection**:
- OCC: client sends `base_version` with each update; server rejects mismatch with current version.
- CRDT: merge semantics built in.
- LWW: latest timestamp wins.

**Conflict resolution**:
- Per-field merge (e.g., status from server, notes from client).
- 3-way merge (base, mine, theirs) — like git.
- Manual UI for the rare unresolvable case.

**Backpressure**:
- Outbox grows offline; cap size or paginate uploads.
- Long-offline reconciliation may take minutes; show progress.

**Schema migrations**:
- Server publishes schema versions; clients accept what they understand and store unknown fields opaque.
- Or: forward-compatible payloads (additive only, ignore unknown).
- Or: server adapts to client version (versioned API).

**Multi-device**:
- Each device gets a unique `actorId` / `deviceId`.
- Pulls include changes from other devices.
- Local optimistic ops flagged; reconciled when server echoes them back.

**Networking realities**:
- Battery-aware sync (poll every X minutes; push immediately on changes; coalesce; respect Doze).
- Background sync via BGTaskScheduler (iOS) / WorkManager (Android).
- Push notification triggers sync (silent push).

The 2026 specific:
- **Hosted sync engines** (Replicache, Triplit, ElectricSQL, Liveblocks, Linear-style) commodify what used to be DIY. Strongly consider before building.
- **Local-first ethos**: server is optional infra; clients are first-class.
- **Hybrid Logical Clocks (HLC)** are popular for cursor — combine wall-clock + counter to handle clock skew.
- **Static Hermes** + JSI sync libs make sync paths sub-ms.

When to build vs buy:
- **Buy / use**: standard CRUD entities, no special semantics → use Replicache / WatermelonDB sync / Realm Sync / Triplit.
- **Build**: custom domain semantics, regulatory needs, special conflict handling.

---

## The "Why"

Sync is the integration point where everything fails. Bad sync = lost data, ghost duplicates, app corruption. Good sync = silent reliability — users don't think about it. Companies care because sync bugs are user-visible, hard to reproduce, and brand-damaging.

---

## Mental Model

Sync = mail system. Outbox holds your pending letters. Postman picks them up periodically, possibly retrying. Inbox is what arrived. Conflicts are like two people writing letters about the same topic; you decide which to keep or how to merge.

---

## Internal Working (2026 Context)

- HLC: 48-bit wall-clock ms + 16-bit counter; monotonic per-node; convergent across nodes.
- Vector clocks: `Map<actorId, counter>`; precise causality; size grows with actors.
- Server change feed often via DB CDC (Debezium, Postgres logical replication) or app-level event log.
- Idempotency at server: dedup by UUID with TTL.

---

## Modern Implementation (Code)

**Outbox + sync loop with Drizzle + op-sqlite**:

```ts
// schema
export const syncOutbox = sqliteTable('sync_outbox', {
  id: text('id').primaryKey(),
  entity: text('entity').notNull(),
  op: text('op').$type<'create' | 'update' | 'delete'>().notNull(),
  payload: text('payload').notNull(),         // JSON string
  baseVersion: integer('base_version'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  attempts: integer('attempts').default(0).notNull(),
  lastError: text('last_error'),
});

// enqueue local mutation atomically with the entity write
export async function localUpdate(entity: string, id: string, patch: any) {
  await db.transaction(async (tx) => {
    const current = await tx.select().from(transactions).where(eq(transactions.id, id)).get();
    await tx.update(transactions).set({ ...patch }).where(eq(transactions.id, id));
    await tx.insert(syncOutbox).values({
      id: uuid(),
      entity,
      op: 'update',
      payload: JSON.stringify({ id, patch }),
      baseVersion: current.version,
      createdAt: new Date(),
    });
  });
}

// sync cycle
export async function syncCycle() {
  // pull
  const cursor = prefs.getString('sync_cursor');
  const pulled = await api.pull({ since: cursor });
  for (const change of pulled.changes) {
    await applyChange(change);
  }
  prefs.set('sync_cursor', pulled.cursor);

  // push
  const pending = await db.select().from(syncOutbox)
    .orderBy(syncOutbox.createdAt).limit(100);
  if (!pending.length) return;
  const res = await api.push({ ops: pending });
  for (const r of res.results) {
    if (r.ok) {
      await db.delete(syncOutbox).where(eq(syncOutbox.id, r.id));
    } else if (r.conflict) {
      await onConflict(r);
    } else {
      await db.update(syncOutbox)
        .set({ attempts: r.attempts + 1, lastError: r.error })
        .where(eq(syncOutbox.id, r.id));
    }
  }
}
```

**Background sync (Expo)**:

```ts
import * as TaskManager from 'expo-task-manager';
import * as BackgroundFetch from 'expo-background-fetch';

const TASK = 'sync-cycle';
TaskManager.defineTask(TASK, async () => {
  try { await syncCycle(); return BackgroundFetch.BackgroundFetchResult.NewData; }
  catch { return BackgroundFetch.BackgroundFetchResult.Failed; }
});

await BackgroundFetch.registerTaskAsync(TASK, {
  minimumInterval: 15 * 60,   // seconds
  stopOnTerminate: false,
  startOnBoot: true,
});
```

**OCC server check (Node)**:
```ts
async function applyUpdate(req: { id, patch, baseVersion }) {
  const row = await db.tx(async (t) => {
    const cur = await t.transaction(req.id);
    if (cur.version !== req.baseVersion) {
      throw { conflict: true, current: cur };
    }
    await t.update(req.id, { ...req.patch, version: cur.version + 1 });
    return await t.transaction(req.id);
  });
  return { ok: true, row };
}
```

---

## Comparison

| Sync engine | Conflict | Backend |
|---|---|---|
| WatermelonDB sync | per-record LWW | bring your own |
| Realm / Atlas Device Sync | OT-like | MongoDB Atlas |
| Replicache | server-authoritative diff | bring your own |
| Triplit | CRDT under the hood | hosted or self-host |
| ElectricSQL | active-active CRDT | Postgres |
| Linear sync | custom | proprietary |
| Custom | yours | yours |

---

## Production Usage

- **Linear**: famously fast custom sync engine; influenced industry.
- **Replicache**: powers many local-first SaaS.
- **Notion / Figma**: hybrid (CRDT for shared docs, traditional for entities).
- **Slack / Teams**: traditional sync with extensive optimistic UI.
- **Banking apps**: server-authoritative; minimal client-side conflict handling.

---

## Hands-On Exercise

1. **Implementation**: build outbox + push/pull for one entity; add idempotency + retry.
2. **Debugging**: duplicate records after offline burst — likely missing dedup; add idempotency.
3. **Architecture**: design conflict policy table for an app with 5 entity types.
4. **Migration**: introduce schema v2 with backward compatibility.

---

## Common Mistakes

- No idempotency keys → retries duplicate.
- Pulling everything on each sync → bandwidth + battery.
- Resolving conflicts implicitly (whoever wrote last "wins") without telling user.
- No backoff on push failures → server hammered.
- Sync in foreground only → user wonders why offline edits never arrive.
- Missing schema-version handshake → breakage on app upgrades.

---

## Production Red Flags

- **Outbox table with thousands of rows** → users with pending data forever.
- **No telemetry on sync errors** → blind to systematic failures.
- **Push triggered on every keystroke** → battery + cost.
- **Pull request without `since` cursor** → server stress.

---

## Performance & Metrics (MANDATORY)

- **Sync RTT**: <500ms typical.
- **Push batch size**: 50–200.
- **Pull batch size**: 100–500.
- **Background interval**: 15min foreground / OS-driven background.
- **Outbox depth alert**: >100 stale items.

---

## Metrics That Matter

- Sync success rate
- Outbox depth distribution
- Conflict rate per entity
- Per-entity sync latency
- Background sync wakeups granted by OS

---

## Decision Framework

| Need | Sync approach |
|---|---|
| Server-authoritative (banking) | server-wins + OCC |
| User prefs cross-device | LWW |
| Collab doc | CRDT (Yjs) |
| Notes / personal data | Replicache or custom + LWW |
| Strong correctness | OCC + manual conflict UI |

---

## Senior-Level Insight

The mature take: **sync engines are products in themselves**. They deserve their own roadmap, telemetry, and on-call. Treating sync as an afterthought is how you get unfixable corruption.

Senior engineers also: (1) write a "sync charter" doc — what's the conflict policy per entity, what's the SLO, what's the error UX; (2) build a sync admin tool to inspect outbox/inbox per user during incident response; (3) add chaos tests (lossy network, slow push, duplicate delivery) to CI.

The 2026 specific: **prefer hosted sync engines** unless your domain demands custom. The engineering cost of doing it right is enormous.

---

## Real-World Scenario

**Symptom:** A subset of users intermittently lose recent edits.
**Investigation:** Server timestamp drift caused LWW to choose older edits.
**Root Cause:** Wall-clock sync between client and server was off by minutes; LWW used wall-clock.
**Fix:** Switch to HLC; server-anchored timestamps; trust server clock for ordering.
**Lesson:** Wall-clock LWW is fragile across devices.

---

## Production Failure Story

**Incident:** A SaaS app had a sync bug causing duplicated tasks for offline-heavy users (sales reps).
**Impact:** Hundreds of duplicate tasks; recovery required manual support.
**Investigation:** Network retried POST after client thought it failed; server processed both.
**Root Cause:** No idempotency key on the request.
**Fix:** Client UUID per mutation; server dedup table with 7-day TTL.
**Prevention:** Sync charter mandates idempotency for every write endpoint.

---

## Debugging Checklist

1. Inspect outbox depth per user.
2. Replay sync cycle in dry-run mode.
3. Verify cursor advances correctly.
4. Test concurrent multi-device edits.
5. Inject network failures (lossy, slow) — does sync recover?
6. Telemetry: push success rate, conflict rate, retry counts.

---

## Advanced / Internal Knowledge

- HLC paper (Kulkarni et al., 2014).
- CRDTs (Shapiro et al., 2011).
- Replicache uses "server pulls + client pushes diffs" model.
- Linear's sync engine: optimistic mutations + server reconciliation + schema-versioned changes.
- Postgres logical replication / Debezium for CDC-driven server change feeds.

---

## 2026 AI Tip

- AI is **good at**: scaffolding outbox + sync loop boilerplate.
- AI is **bad at**: conflict policy design — needs domain reasoning.
- **Prompt pattern**: "Design a sync engine for an offline-first task manager: outbox schema, idempotency, OCC for updates, LWW for completed flag, conflict UI for assignee changes."

---

## Related Topics

- Q1 storage decision tree
- Q4 CRDTs
- S9 networking
- S22 system design

---

## Interview Follow-Up Questions

- Why is idempotency essential for sync?
- HLC vs vector clock — when each?
- How do you migrate sync schema across app versions?
- When is OCC the right conflict model?
- What does Replicache do that's unique?

---

## Memory Hook

**"Outbox + cursor + policy."**

## Revision Notes

> Sync = local outbox + idempotent push + cursor-based pull + explicit conflict policy. HLC for cursor; OCC for safety; LWW for simple; CRDT for collab. Background sync via OS scheduler. Surface state to UI. Buy hosted sync engines unless you must build.

---

> **End of S11.** Cross-refs: S8 (state), S9 (networking, retries), S10 (encryption-at-rest, biometric step-up for sensitive sync), S22 (system design). Next deep section: [S12 Push & Background](S12-push-background.md).
