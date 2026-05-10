## 7. Performance: lists, animations, images, memory

### Lists
| Tool | When |
|---|---|
| `ScrollView` | Small fixed content (<10 items) |
| `FlatList` | Default for any list |
| `SectionList` | Grouped lists |
| `FlashList` (Shopify) | Heavy rows, infinite feeds, perf-critical |

**FlatList tuning**:
- Stable `keyExtractor` (id, never index).
- `getItemLayout` if rows are fixed-height (skips measurement).
- `removeClippedSubviews` (Android wins).
- `initialNumToRender`, `maxToRenderPerBatch`, `windowSize` tuned to row size.
- Memoized row component (`React.memo` + stable callbacks).

**FlashList wins**:
- Recycles views like RecyclerView/UITableView.
- Predictable FPS for complex rows.
- `estimatedItemSize` is required.

### Animations
- **Reanimated 3 worklets**: run on UI thread via JSI; 60 FPS even when JS is busy.
- **Gesture Handler**: native gestures, no bridge round-trip.
- **`useAnimatedStyle`, `useSharedValue`, `withTiming`, `withSpring`**.
- `runOnJS` to call back into JS thread; `runOnUI` to enter worklet.
- Avoid `Animated` (legacy) for new perf-critical work.

### Images
- `expo-image` (default in 2026) or `FastImage`.
- Right-size on server, not client.
- Cache aggressively, prefetch above-the-fold.
- WebP/AVIF for size; PNG only for transparency cases.

### Memory leaks (top causes)
1. `setInterval`/`setTimeout` not cleared.
2. Event listeners not removed (`AppState`, `Keyboard`, sockets).
3. Navigation refs held in module scope.
4. Large arrays/blobs in closures.
5. Subscriptions to streams without cleanup.

**Detect**: Xcode Allocations + Leaks instrument; Android Studio Memory Profiler; React DevTools Profiler.

### Frame drops debug flow
1. Reproduce consistently.
2. Identify thread: JS jank vs UI jank vs render jank.
3. Hermes sampling profiler → JS hot spots.
4. Systrace/Perfetto (Android) or Time Profiler (iOS) → native side.
5. Fix highest-cost path; re-measure.

### Must-answer questions
1. FlatList → FlashList — when and why.
2. Fix scroll jank in a feed — your steps.
3. Why Reanimated worklets are faster than `Animated`.
4. Memory leak — find + fix flow.
5. Image pipeline best practices.

---

