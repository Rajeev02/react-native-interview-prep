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

