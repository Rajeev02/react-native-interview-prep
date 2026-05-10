# S23 — Machine Coding (60–90 min builds)

> Infinite scroll · OTP autofill · debounced search · offline-first form · chat optimistic UI

Machine-coding rounds test you can build, debug, and explain a working RN feature under time pressure. Each task here includes the brief, the rubric, and a reference solution.

## Topics in this section

- [Q1. Infinite-scroll feed (TanStack Query + FlashList)](#q1-infinite-scroll-feed-tanstack-query--flashlist)
- [Q2. OTP entry with autofill (iOS + Android)](#q2-otp-entry-with-autofill-ios--android)
- [Q3. Debounced search with cancellation](#q3-debounced-search-with-cancellation)
- [Q4. Offline-first form with mutation queue](#q4-offline-first-form-with-mutation-queue)
- [Q5. Chat UI with optimistic send + retry](#q5-chat-ui-with-optimistic-send--retry)

---

## Q1. Infinite-scroll feed (TanStack Query + FlashList)

### Difficulty
Intermediate → Advanced

### Interview Frequency
Very common.

### Prerequisites
S07 (perf), S08 (state).

### TL;DR
`useInfiniteQuery` with cursor-based pagination + FlashList with `onEndReached` + skeletons. Handle empty / error / refetch states. Performance: stable keys, memoized item renderers, image preloading.

### 30-Second Interview Answer
"`useInfiniteQuery` from TanStack Query for cursor pagination; FlashList renders items and `onEndReached` triggers `fetchNextPage`. I handle loading skeletons, error retry, pull-to-refresh, and empty states. For perf: stable `keyExtractor`, memoized renderItem, `estimatedItemSize`, and image preloading via expo-image."

### 2-Minute Practical Answer

```tsx
function Feed() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, refetch, isRefetching, status } =
    useInfiniteQuery({
      queryKey: ['feed'],
      queryFn: ({ pageParam }) => api.feed.list({ cursor: pageParam }),
      initialPageParam: undefined as string | undefined,
      getNextPageParam: (last) => last.nextCursor ?? undefined,
    });

  const items = useMemo(() => data?.pages.flatMap((p) => p.items) ?? [], [data]);
  const renderItem = useCallback(({ item }: { item: Item }) => <Card item={item} />, []);

  if (status === 'pending') return <FeedSkeleton />;
  if (status === 'error') return <RetryView onRetry={refetch} />;
  if (items.length === 0) return <EmptyView />;

  return (
    <FlashList
      data={items}
      keyExtractor={(it) => it.id}
      renderItem={renderItem}
      estimatedItemSize={280}
      onEndReached={() => hasNextPage && !isFetchingNextPage && fetchNextPage()}
      onEndReachedThreshold={0.5}
      refreshing={isRefetching}
      onRefresh={refetch}
      ListFooterComponent={isFetchingNextPage ? <FooterSpinner /> : null}
    />
  );
}
```

### 5-Minute Architecture Answer
Production infinite scroll has a dozen edge cases:
- **Cursor stability** — server must guarantee no duplicates / no skips when items shift.
- **Pagination errors** — partial-failure UX (don't blank the list; show inline retry).
- **Stale-while-revalidate** — refetch on focus without losing scroll position.
- **Image perf** — preload next page's images on `onEndReached`.
- **List perf** — FlashList with stable IDs; `removeClippedSubviews`; memoized cards.
- **Pull-to-refresh** — refetch first page only; preserve subsequent pages or clear?
- **Optimistic deletes** — remove from `queryClient.setQueryData` before request resolves.

In 2026:
- React Compiler memoizes `renderItem` automatically.
- expo-image with `cachePolicy="memory-disk"` preloads.
- TanStack Query v5 has improved infinite-query types.

### The "Why"
Tests RN performance fundamentals + state management + UX edge cases in one task.

### Mental Model
Feed = **stream of pages**; client cache = **list of pages**; FlashList = **viewport over flattened items**.

### Internal Working (2026 Context)
- `useInfiniteQuery` stores pages in cache; flattening is your job.
- FlashList recycles item views; renderItem must be cheap + memoized.

### Modern Implementation (Code)
See above.

### Comparison

| Pagination | Pros | Cons |
|---|---|---|
| Cursor | Stable across mutations | Server complexity |
| Offset | Simple | Skips/dupes when list changes |
| Time-based | Simple | Same as offset |

### Production Usage
- Twitter / Instagram / LinkedIn-style feeds.
- Always cursor-based at scale.

### Hands-On Exercise
Build a 200-item feed with cursor pagination, FlashList, refresh, retry, empty state. Aim for 60fps scroll.

### Common Mistakes
- `useState` accumulator instead of cache (loses on remount).
- Inline `renderItem` (re-creates each render).
- Missing `keyExtractor` → re-renders all.
- `onEndReached` firing repeatedly during fetch.

### Production Red Flags
- ScrollView+map for long lists.
- `data={[...prevData, ...newData]}` patterns (use cache).
- No skeleton / no empty state.

### Performance & Metrics
- FPS during scroll (target 60).
- Time to first render.
- Memory growth across pages.

### Decision Framework
- Long list → FlashList.
- Pagination → cursor.
- State → TanStack Query (don't reinvent).

### Senior-Level Insight
"The hard part isn't fetching; it's the cache invalidation, the optimistic mutations, and the scroll position."

### Real-World Scenario
**Symptom:** Pull-to-refresh resets scroll to top mid-scroll.
**Fix:** Refetch only first page; preserve subsequent pages.

### Production Failure Story
**Incident:** Memory crashes after 50 pages.
**Root cause:** Inline image URIs caused expo-image to never release.
**Fix:** Stable URIs + `cachePolicy="memory-disk"`; bounded LRU.

### Debugging Checklist
1. Stable keys?
2. Memoized renderItem?
3. `onEndReached` debounced by `hasNextPage` + `isFetchingNextPage`?
4. Error / empty / loading states?

### Advanced / Internal Knowledge
- `select` option in `useInfiniteQuery` for derived flat data.
- `placeholderData: keepPreviousData` for stable transitions.
- `removeClippedSubviews` is a Fabric perf knob.

### 2026 AI Tip
AI scaffolds infinite scroll well; verify cursor handling + edge states.

### Related Topics
Q3, S07, S08.

### Interview Follow-Up Questions
- "Why cursor over offset?"
- "How do you handle deletes mid-list?"
- "FlashList vs FlatList — what's the perf gain and why?"

### Memory Hook
**"useInfiniteQuery + FlashList. Cursor in. Stable keys out."**

### Revision Notes
> `useInfiniteQuery` (cursor) + FlashList; stable keys; memoized renderItem; pull-to-refresh refetches first page; preload next-page images; handle empty / error / loading.

---

## Q2. OTP entry with autofill (iOS + Android)

### Difficulty
Intermediate

### Interview Frequency
Very common (auth flows).

### Prerequisites
RN inputs, refs.

### TL;DR
6-digit pin field; iOS uses `textContentType="oneTimeCode"` for SMS autofill; Android uses Google's SMS Retriever or User Consent API. Single hidden TextInput with visual cells, or 6 separate inputs with cascading focus.

### 30-Second Interview Answer
"For OTP I render 6 visual cells but use a single hidden TextInput with `textContentType='oneTimeCode'` (iOS) and Android SMS Retriever for autofill. The hidden input drives all cells; on each char, focus advances; on full input I auto-submit. Backspace shifts focus back. Paste fills all cells."

### 2-Minute Practical Answer

```tsx
function OtpInput({ length = 6, onComplete }: Props) {
  const [code, setCode] = useState('');
  const inputRef = useRef<TextInput>(null);

  const handleChange = (text: string) => {
    const sanitized = text.replace(/[^0-9]/g, '').slice(0, length);
    setCode(sanitized);
    if (sanitized.length === length) onComplete(sanitized);
  };

  return (
    <Pressable onPress={() => inputRef.current?.focus()}>
      <View style={styles.cells}>
        {Array.from({ length }).map((_, i) => (
          <View key={i} style={[styles.cell, code.length === i && styles.cellActive]}>
            <Text style={styles.cellText}>{code[i] ?? ''}</Text>
          </View>
        ))}
      </View>
      <TextInput
        ref={inputRef}
        style={styles.hidden}
        value={code}
        onChangeText={handleChange}
        keyboardType="number-pad"
        textContentType="oneTimeCode"
        autoComplete="sms-otp"
        maxLength={length}
        autoFocus
      />
    </Pressable>
  );
}
```

For Android SMS Retriever: use `react-native-otp-verify` or implement via TurboModule that calls `SmsRetriever.startSmsRetriever()`. Server SMS must include the app hash.

### 5-Minute Architecture Answer
OTP UX is deceptively complex:
- **Autofill source of truth** — iOS auto-suggests from messages app; `textContentType="oneTimeCode"` is required.
- **Android requires server cooperation** — SMS Retriever needs an 11-char hash in the SMS; User Consent API is fallback (user taps to allow).
- **Visual cells vs single input** — single hidden input is simpler + more accessible (one focus target); separate inputs feel native but require careful focus management.
- **Paste handling** — 6-digit clipboard paste should fill all cells.
- **Resend cooldown** — 30-second timer before resend button enables.
- **Error states** — wrong code clears input + shakes cells.
- **Auto-submit** — on length === N, call onComplete; show loading; don't allow re-edit while submitting.

For 2026:
- expo modules wrap autofill APIs cleanly.
- Reanimated handles cell animations on entry / error.
- A11y: `accessibilityLabel="One-time code, 6 digits"`.

### The "Why"
Universal in modern auth; tests input handling + platform APIs + UX polish.

### Mental Model
Hidden TextInput = data; visual cells = view of that data; autofill = OS injecting into hidden input.

### Internal Working (2026 Context)
- iOS QuickType bar surfaces SMS codes automatically with `textContentType="oneTimeCode"`.
- Android SMS Retriever requires app hash in SMS.
- `autoComplete="sms-otp"` standardized in RN 0.71+.

### Modern Implementation (Code)
See above; add resend cooldown:

```tsx
function ResendButton({ onResend }: { onResend: () => void }) {
  const [countdown, setCountdown] = useState(30);
  useEffect(() => {
    if (countdown <= 0) return;
    const id = setTimeout(() => setCountdown((c) => c - 1), 1000);
    return () => clearTimeout(id);
  }, [countdown]);
  return (
    <Pressable disabled={countdown > 0} onPress={() => { onResend(); setCountdown(30); }}>
      <Text>{countdown > 0 ? `Resend in ${countdown}s` : 'Resend code'}</Text>
    </Pressable>
  );
}
```

### Comparison

| Approach | Pros | Cons |
|---|---|---|
| Single hidden input | Simple, accessible, autofill works | Custom render |
| 6 separate inputs | Native feel | Focus mgmt complex; autofill harder |

### Production Usage
- Banking, fintech, social all use OTP.
- 6-digit numeric most common; some 4-digit; alphanumeric rare.

### Hands-On Exercise
Build OTP with: hidden input, 6 cells, autofill props, paste support, error shake, resend cooldown.

### Common Mistakes
- Forgetting `textContentType="oneTimeCode"` (no autofill).
- Allowing non-numeric characters.
- Not handling backspace.
- No resend cooldown.

### Production Red Flags
- 6 separate `TextInput`s without focus mgmt.
- No paste support.
- No error UX.

### Performance & Metrics
- Autofill success rate.
- Time to complete OTP.
- Wrong-code rate.

### Decision Framework
- New flow → single hidden input + visual cells.
- A11y critical → single input.

### Senior-Level Insight
"OTP is a litmus test: does your team know iOS autofill props, Android SMS Retriever, paste handling, and a11y?"

### Real-World Scenario
**Symptom:** iOS users see autofill banner but tapping it does nothing.
**Fix:** Missing `textContentType="oneTimeCode"`.

### Production Failure Story
**Incident:** Android autofill never worked.
**Root cause:** SMS lacked the app hash; SMS Retriever silently failed.
**Fix:** Backend updated to inject hash from a config table.

### Debugging Checklist
1. iOS autofill props set?
2. Android hash in SMS?
3. Paste fills all cells?
4. Backspace + auto-focus working?

### Advanced / Internal Knowledge
- App hash generation: `appsigner.jar` or hash util in `react-native-otp-verify`.
- iOS only autofills from messages received in last 3 minutes.
- WebOTP API for RN web (S29).

### 2026 AI Tip
AI knows the autofill props but rarely the Android SMS Retriever flow. Verify on device.

### Related Topics
Q4, S10 (auth).

### Interview Follow-Up Questions
- "What's `textContentType='oneTimeCode'`?"
- "How does Android SMS Retriever work?"
- "Why one hidden input over 6 separate?"

### Memory Hook
**"Hidden input drives cells. iOS autofill prop. Android hash in SMS."**

### Revision Notes
> Single hidden TextInput + visual cells; iOS `textContentType="oneTimeCode"` + `autoComplete="sms-otp"`; Android SMS Retriever (server SMS includes hash); paste fills all; resend cooldown; auto-submit on length.

---

## Q3. Debounced search with cancellation

### Difficulty
Intermediate

### Interview Frequency
Very common.

### Prerequisites
useEffect, AbortController.

### TL;DR
Debounce input (300ms); on each search, abort previous request via AbortController; show loading state; cache results in TanStack Query keyed by query string. Empty state for no results.

### 30-Second Interview Answer
"Debounce the input by 300ms; the debounced value becomes a TanStack Query key. The query function uses AbortController so that older in-flight requests cancel when the user types more. UI shows skeleton during fetch, results on success, empty state if zero, error state with retry."

### 2-Minute Practical Answer

```tsx
function useDebounced<T>(value: T, delay = 300): T {
  const [v, setV] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setV(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return v;
}

function Search() {
  const [query, setQuery] = useState('');
  const debounced = useDebounced(query, 300);

  const { data, status, fetchStatus } = useQuery({
    queryKey: ['search', debounced],
    queryFn: ({ signal }) => api.search(debounced, { signal }),
    enabled: debounced.length >= 2,
    staleTime: 60_000,
  });

  return (
    <>
      <TextInput value={query} onChangeText={setQuery} placeholder="Search" returnKeyType="search" />
      {fetchStatus === 'fetching' ? <Skeleton /> :
       status === 'error' ? <Error /> :
       data?.length === 0 ? <Empty /> :
       <FlashList data={data} renderItem={({ item }) => <Result item={item} />} keyExtractor={(i) => i.id} estimatedItemSize={60} />}
    </>
  );
}
```

### 5-Minute Architecture Answer
Search has classic concurrency hazards:
- **Race conditions** — fast typer triggers `a → ab → abc` requests; without cancellation, slow `ab` response could overwrite fast `abc`.
- **Wasted bandwidth** — every keystroke firing a request.
- **Stale state** — cleared input shows stale results.
- **No-result state** — visually distinct from "loading" or "error."

Solutions:
- **Debounce** — wait 300ms after last keystroke.
- **AbortController** — cancel previous request.
- **TanStack Query** — caches by key; deduplicates; provides `signal`.
- **`enabled`** — disable query for short inputs.
- **Recent searches** — show on focus when query is empty (good UX).

For 2026:
- TanStack Query v5 passes `AbortSignal` to queryFn natively.
- `placeholderData: keepPreviousData` smooths transitions.
- React 19's `useDeferredValue` is an alternative to debounce for client-only filtering.

### The "Why"
Tests concurrency, debouncing, cancellation, UX states — all in one.

### Mental Model
Search = **derived query from latest debounced input**; cancellation = **don't let yesterday overwrite today**.

### Internal Working (2026 Context)
- TanStack Query passes `signal` to queryFn; pass it to `fetch`.
- `useDeferredValue` is React 19 alternative for sync filtering.

### Modern Implementation (Code)
See above. `api.search` example:

```ts
async function search(q: string, { signal }: { signal?: AbortSignal }) {
  const res = await fetch(`/search?q=${encodeURIComponent(q)}`, { signal });
  if (!res.ok) throw new Error('Search failed');
  return res.json() as Promise<SearchHit[]>;
}
```

### Comparison

| Strategy | Use case |
|---|---|
| Debounce + cancel | Network search |
| Throttle | Live charts |
| `useDeferredValue` | In-memory filtering |

### Production Usage
- Universal pattern; every search box.
- Recent / suggested searches stored locally (MMKV).

### Hands-On Exercise
Build search with debounce, AbortController, TanStack Query, all UX states. Test fast typing race conditions.

### Common Mistakes
- No debounce (request per keystroke).
- No AbortController (race condition bugs).
- `enabled` not set → empty query fires.
- No empty state (looks like a bug).

### Production Red Flags
- Search box that triggers a fetch per keystroke.
- Fast typing shows wrong results.
- "Loading…" stuck because old request resolves last.

### Performance & Metrics
- P95 search latency.
- Cancellation rate (high = many fast typers; expected).
- No-result rate.

### Decision Framework
- Network search → debounce + AbortController.
- Local search (already-loaded data) → `useDeferredValue` or `useMemo`.
- Both → composed.

### Senior-Level Insight
"The bug a junior misses: typing fast can render stale results because they don't cancel. AbortController is the answer."

### Real-World Scenario
**Symptom:** Users report wrong results randomly.
**Investigation:** Race condition; old slow request finished after new fast one.
**Fix:** Add AbortController; add `keepPreviousData` to smooth transitions.

### Production Failure Story
**Incident:** Server overload during a campaign.
**Root cause:** No debounce; every keystroke spammed search endpoint.
**Fix:** 300ms debounce; cut traffic 80%.

### Debugging Checklist
1. Debounced 250–400ms?
2. AbortController wired?
3. Empty / loading / error states?
4. `enabled` for short queries?

### Advanced / Internal Knowledge
- `useTransition` to mark search updates as low-priority.
- Server-Sent Events for streaming results (rare in mobile).
- IDF/local cache for "as-you-type" suggestions.

### 2026 AI Tip
AI scaffolds debounce + fetch but often forgets AbortController. Add it explicitly.

### Related Topics
Q1, S08, S09.

### Interview Follow-Up Questions
- "What if the user types faster than your debounce?"
- "Why AbortController over a flag?"
- "When would you use `useDeferredValue` instead?"

### Memory Hook
**"Debounce, cancel, cache, state. Don't let yesterday overwrite today."**

### Revision Notes
> Debounce ~300ms; AbortController for cancellation; TanStack Query with `signal`; `enabled` for short input; loading/empty/error/success states; `keepPreviousData` smooths.

---

## Q4. Offline-first form with mutation queue

### Difficulty
Advanced

### Interview Frequency
Common at senior+ rounds.

### Prerequisites
S11 (offline), S08 (state).

### TL;DR
Form submits to a local queue (MMKV) immediately; queue drains when online via TanStack Query mutations with retry. Optimistic UI shows the new state; rollback on permanent failure.

### 30-Second Interview Answer
"Form submit writes to a local queue (MMKV) and updates UI optimistically. A background drainer reads queued items, fires mutations with TanStack Query (with exponential backoff), and removes successful entries. NetInfo triggers drains on reconnect. On permanent failure (4xx) we surface an error and offer manual retry; transient failures (5xx, network) auto-retry."

### 2-Minute Practical Answer
```ts
type QueuedMutation = { id: string; type: string; payload: unknown; createdAt: number; attempts: number };

const queueStore = new MMKV({ id: 'mutation-queue' });

function enqueue(m: Omit<QueuedMutation, 'id' | 'createdAt' | 'attempts'>) {
  const item: QueuedMutation = { id: nanoid(), createdAt: Date.now(), attempts: 0, ...m };
  const all = JSON.parse(queueStore.getString('items') ?? '[]') as QueuedMutation[];
  queueStore.set('items', JSON.stringify([...all, item]));
  return item;
}

function useDrainer() {
  const isOnline = useNetInfo().isConnected;
  useEffect(() => {
    if (!isOnline) return;
    let cancelled = false;
    (async () => {
      const items: QueuedMutation[] = JSON.parse(queueStore.getString('items') ?? '[]');
      for (const item of items) {
        if (cancelled) return;
        try {
          await api[item.type](item.payload);
          remove(item.id);
        } catch (e) {
          if (isPermanent(e)) { remove(item.id); reportError(item, e); }
          else { incrementAttempts(item.id); }
        }
      }
    })();
    return () => { cancelled = true; };
  }, [isOnline]);
}
```

### 5-Minute Architecture Answer
Offline-first means **the user shouldn't notice they're offline**:
- Writes go into a local queue + optimistic cache update.
- Reads come from cache first (TanStack Query persisted to MMKV).
- Reconciliation on reconnect.

Queue design:
- **Atomic writes** — append-only; no race conditions on partial writes.
- **Idempotency keys** — server uses queue item ID to dedupe (so retries are safe).
- **Ordering** — FIFO; some apps prefer dependency-aware (a depends on b).
- **Retry policy** — exponential backoff; max attempts; permanent vs transient distinction.
- **User feedback** — pending badge per item; "saving…" indicator; error surface for permanent failures.

For 2026:
- TanStack Query has `useMutation` with `onMutate` for optimistic updates + `onError` rollback.
- MMKV faster than AsyncStorage for queue persistence.
- Reanimated for "saving..." pulses.

Hardening:
- Encrypt queue if it contains sensitive data (S10).
- Cap queue size; oldest items rejected if quota hit.
- Background sync via Headless JS / iOS background tasks.

### The "Why"
Real-world apps need to work on subway / flights / poor connectivity. Optimistic UI = perceived performance.

### Mental Model
Local queue = **outbox**; UI = **eventual consistency view**.

### Internal Working (2026 Context)
- MMKV for sync writes (no async overhead).
- NetInfo for connectivity events.
- TanStack Query optimistic mutations.

### Modern Implementation (Code)
See above. With TanStack Query optimistic:

```ts
const mutation = useMutation({
  mutationFn: api.createPost,
  onMutate: async (newPost) => {
    await queryClient.cancelQueries({ queryKey: ['posts'] });
    const previous = queryClient.getQueryData(['posts']);
    queryClient.setQueryData(['posts'], (old: Post[] = []) => [{ ...newPost, id: 'temp-' + nanoid() }, ...old]);
    return { previous };
  },
  onError: (_err, _vars, ctx) => ctx?.previous && queryClient.setQueryData(['posts'], ctx.previous),
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['posts'] }),
});
```

### Comparison

| Approach | Pros | Cons |
|---|---|---|
| Manual queue + drainer | Full control | More code |
| TanStack Query persistor | Built-in mutation persistence | Less custom |
| WatermelonDB sync | Full DB sync | Heavyweight |

### Production Usage
- Notes apps, todo apps, social posting flows.
- Banking transactions usually NOT optimistic (server confirms first).

### Hands-On Exercise
Build offline-form: queue writes, drainer on reconnect, optimistic UI, error rollback.

### Common Mistakes
- No idempotency keys → server creates duplicates on retry.
- Optimistic update without rollback path.
- Queue grows unbounded.
- No user feedback for pending items.

### Production Red Flags
- Submit button works offline but shows error 30s later with no recovery.
- Server gets duplicates after retry.
- Lost mutations on app force-quit.

### Performance & Metrics
- Queue latency P95.
- Failure rate per mutation type.
- User-visible error rate.

### Decision Framework
- Non-critical writes → optimistic + queue.
- Critical writes (payments) → server confirms first.
- High-volume offline → DB sync (Watermelon).

### Senior-Level Insight
"Idempotency keys are not optional. Without them, retries silently corrupt your data."

### Real-World Scenario
**Symptom:** Users report duplicate posts after they went offline.
**Root cause:** No idempotency; server received same POST twice.
**Fix:** Send `Idempotency-Key` header; server dedupes 24h.

### Production Failure Story
**Incident:** App crash during offline editing lost all queued items.
**Root cause:** Queue was in memory only.
**Fix:** Persist on every enqueue (MMKV sync).

### Debugging Checklist
1. Idempotency keys?
2. Persisted queue?
3. Optimistic + rollback?
4. Drainer on reconnect?
5. Permanent vs transient error handling?

### Advanced / Internal Knowledge
- Conflict resolution for concurrent edits (Last-Write-Wins, CRDT, OT).
- Background sync via WorkManager (Android) / BGTaskScheduler (iOS).
- WatermelonDB for full DB-level offline sync.

### 2026 AI Tip
AI scaffolds optimistic mutations but rarely the persistent queue. Add MMKV persistence + idempotency keys manually.

### Related Topics
Q5, S08, S11.

### Interview Follow-Up Questions
- "What's an idempotency key?"
- "How do you reconcile after long offline period?"
- "What if the queue grows during prolonged offline?"

### Memory Hook
**"Optimistic UI. Persistent queue. Idempotent retries. Drain on reconnect."**

### Revision Notes
> Form submit → MMKV queue + optimistic cache update; drainer on reconnect; TanStack Query mutation with retry; idempotency keys; rollback on permanent failure; bounded queue.

---

## Q5. Chat UI with optimistic send + retry

### Difficulty
Advanced

### Interview Frequency
Common at messaging companies.

### Prerequisites
Q4, S08.

### TL;DR
Inverted FlashList; messages stored in TanStack Query cache; new messages appended optimistically with `status: 'sending'`; on success, status becomes `'sent'`; on failure, `'failed'` with retry. WebSocket / SSE for incoming.

### 30-Second Interview Answer
"Chat UI uses an inverted FlashList for natural bottom-to-top reading; messages live in TanStack Query cache; sending appends optimistically with `status: 'sending'`; on response, status flips to `'sent'`; on failure, `'failed'` with a retry tap. Incoming messages arrive via WebSocket and are inserted by ID. Read receipts and typing indicators are separate streams."

### 2-Minute Practical Answer

```tsx
type Message = { id: string; text: string; status: 'sending' | 'sent' | 'failed'; createdAt: number };

function ChatScreen({ chatId }: Props) {
  const { data: messages } = useQuery({ queryKey: ['messages', chatId], queryFn: () => api.messages(chatId) });
  const queryClient = useQueryClient();

  const send = useMutation({
    mutationFn: (text: string) => api.send(chatId, text),
    onMutate: async (text) => {
      const tempId = 'temp-' + nanoid();
      const optimistic: Message = { id: tempId, text, status: 'sending', createdAt: Date.now() };
      queryClient.setQueryData(['messages', chatId], (old: Message[] = []) => [optimistic, ...old]);
      return { tempId };
    },
    onSuccess: (saved, _text, ctx) => {
      queryClient.setQueryData(['messages', chatId], (old: Message[] = []) =>
        old.map((m) => (m.id === ctx?.tempId ? { ...saved, status: 'sent' as const } : m))
      );
    },
    onError: (_err, _text, ctx) => {
      queryClient.setQueryData(['messages', chatId], (old: Message[] = []) =>
        old.map((m) => (m.id === ctx?.tempId ? { ...m, status: 'failed' as const } : m))
      );
    },
  });

  // Incoming via WebSocket
  useEffect(() => {
    const sock = ws.subscribe(chatId, (msg: Message) => {
      queryClient.setQueryData(['messages', chatId], (old: Message[] = []) => {
        if (old.find((m) => m.id === msg.id)) return old;
        return [msg, ...old];
      });
    });
    return () => sock.close();
  }, [chatId, queryClient]);

  return (
    <FlashList
      data={messages ?? []}
      inverted
      keyExtractor={(m) => m.id}
      renderItem={({ item }) => <MessageBubble message={item} onRetry={() => send.mutate(item.text)} />}
      estimatedItemSize={60}
    />
  );
}
```

### 5-Minute Architecture Answer
Chat is a perf + concurrency challenge:
- **Inverted list** — bottom is the "newest" anchor; FlashList's `inverted`.
- **Optimistic + status** — sender sees instant feedback; status transitions guide UX.
- **Incoming pipeline** — WebSocket / SSE for real-time; deduplicate by ID.
- **Pagination** — older messages load on scroll up (use `onEndReached` with `inverted`).
- **Read receipts / typing** — separate ephemeral streams; don't pollute message cache.
- **Media messages** — upload progress UI; chunked uploads; retry per chunk.
- **Scroll position** — preserve when new message arrives if user is scrolled up.

For 2026:
- React Compiler memoizes message bubbles.
- Reanimated for entry animations / typing dots.
- WatermelonDB for full message DB if offline-heavy.

Edge cases:
- Out-of-order arrival (sequence numbers help).
- Duplicate IDs from retry (server idempotency).
- Network reconnect: replay missed messages via `?since=lastId`.
- Multi-device: presence + sync via server fanout.

### The "Why"
Chat is one of the most-tested machine-coding tasks; covers state, perf, real-time, optimistic UX.

### Mental Model
Chat = **append-only timeline**; UI = **inverted view**; cache = **single source of truth** for message state.

### Internal Working (2026 Context)
- TanStack Query setQueryData with mapping for status transitions.
- FlashList inverted leverages native list inversion.
- WebSocket via `ws` lib or socket.io.

### Modern Implementation (Code)
See above. Bubble:

```tsx
function MessageBubble({ message, onRetry }: Props) {
  return (
    <View style={[styles.bubble, message.status === 'failed' && styles.failed]}>
      <Text>{message.text}</Text>
      <View style={styles.statusRow}>
        {message.status === 'sending' && <ActivityIndicator size="small" />}
        {message.status === 'sent' && <Check />}
        {message.status === 'failed' && (
          <Pressable onPress={onRetry} accessibilityRole="button" accessibilityLabel="Retry">
            <Text style={styles.retry}>Retry</Text>
          </Pressable>
        )}
      </View>
    </View>
  );
}
```

### Comparison

| Transport | Pros | Cons |
|---|---|---|
| WebSocket | Bi-directional, low latency | Connection mgmt |
| SSE | Simple, HTTP | One-way (server → client) |
| Polling | Trivial | High latency / cost |

### Production Usage
- WhatsApp, Slack, Telegram all use WebSocket variants.
- iMessage uses Apple Push for delivery + custom protocol.

### Hands-On Exercise
Build chat with inverted list, optimistic send, status icons, retry, WebSocket incoming.

### Common Mistakes
- Non-inverted list (latest at top, hard to read).
- No optimistic update (UI feels laggy).
- Duplicate messages after WebSocket reconnect.
- Re-rendering full list on every new message.

### Production Red Flags
- 6 layers of state (Redux + local + cache).
- Send button works but no status feedback.
- WebSocket reconnect storms.

### Performance & Metrics
- Time-to-send-feedback (target < 100ms via optimistic).
- Message delivery latency (P95).
- Scroll FPS.

### Decision Framework
- 1:1 chat → cache + WebSocket.
- Group chat at scale → consider DB sync.
- Real-time priority → WebSocket; polling as fallback.

### Senior-Level Insight
"Optimistic UI is what makes chat feel like chat. Without it, users tap send and wait for the bubble — feels broken."

### Real-World Scenario
**Symptom:** Messages occasionally appear twice.
**Investigation:** Server pushed a message that was also in optimistic cache; mismatched IDs.
**Fix:** Reconcile by `clientId` (sent in payload) so server-echoed messages match.

### Production Failure Story
**Incident:** App froze when chat had 10k messages.
**Root cause:** Used FlatList without virtualization tuning + non-memoized bubble.
**Fix:** FlashList + memo + `getItemLayout` equivalent.

### Debugging Checklist
1. Inverted FlashList?
2. Optimistic update with status?
3. WebSocket dedup by ID?
4. Memoized message bubble?

### Advanced / Internal Knowledge
- E2E encryption layer (Signal Protocol) for secure chat.
- Lazy-loading older messages on scroll.
- Sync protocol: send `lastSyncTimestamp` to receive missed messages.

### 2026 AI Tip
AI scaffolds chat shape but often forgets WebSocket dedup and inverted list. Verify both.

### Related Topics
Q1, Q4, S08, S11.

### Interview Follow-Up Questions
- "How do you handle WebSocket reconnect?"
- "How do you prevent duplicate messages?"
- "Why inverted list?"

### Memory Hook
**"Inverted list. Optimistic with status. Dedup incoming. Retry on tap."**

### Revision Notes
> Inverted FlashList; cache via TanStack Query; optimistic send with `status: sending → sent | failed`; WebSocket for incoming with ID dedup; retry on tap; pagination via `onEndReached`.

---

> Cross-refs: S07 (perf), S08 (state), S11 (offline).
