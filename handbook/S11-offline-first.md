# S11 — Offline-first Systems

> MMKV · op-sqlite · WatermelonDB · Realm · CRDTs · sync · conflict resolution · migrations · queues

> Status: **scaffold** — fill with content using the per-topic format from `final-prompt.md`.

## Topics

- AsyncStorage (when acceptable, when not)
- MMKV (default for hot KV)
- SQLite / op-sqlite (JSI-native SQLite)
- WatermelonDB (lazy, sync-friendly)
- Realm
- Drizzle / Kysely on mobile
- Sync engines (event sourcing, last-write-wins)
- CRDTs (Automerge, Yjs)
- Conflict resolution strategies
- Migrations & schema evolution
- Background sync (BGTaskScheduler iOS, WorkManager Android)
- Queue & retry semantics

## Q-topics (stubs)

- Q1. Storage decision tree — KV vs SQL vs document
- Q2. MMKV deep dive — JSI integration, encryption, multi-process
- Q3. op-sqlite vs WatermelonDB vs Realm — when each wins
- Q4. CRDTs for collaborative mobile apps (Automerge / Yjs)
- Q5. Sync engine design — events, vector clocks, conflict policy

> Cross-refs: S8 (state), S9 (networking), S12 (push).
