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



---

## Top 25 Q&A — Performance: lists, animations, images, memory

### 1. Why is `FlatList` better than `ScrollView` for long lists?
`ScrollView` renders all children upfront. `FlatList` virtualizes — only renders items in viewport + buffer.

### 2. Critical FlatList props for perf.
`keyExtractor`, `getItemLayout`, `initialNumToRender`, `maxToRenderPerBatch`, `windowSize`, `removeClippedSubviews`, `updateCellsBatchingPeriod`.

### 3. When is `getItemLayout` huge?
Fixed-height rows. Lets FlatList skip measuring → smooth scroll, scrollToIndex works instantly.

### 4. `FlashList` vs `FlatList`?
Shopify's `@shopify/flash-list` recycles cells (RecyclerView-style) — far better for heterogeneous large lists. Requires `estimatedItemSize`.

### 5. Common list jank causes.
Inline functions + objects in `renderItem`, unmemoized rows, large images without resize, JS-thread animations during scroll.

### 6. Image perf best practices.
`react-native-fast-image` (caching), prefer remote thumbnails, `resizeMode="cover"`, prefetch above-the-fold, use WebP/AVIF, never load 2000px image into 100px slot.

### 7. Animated vs Reanimated — when each?
`Animated` with `useNativeDriver` for simple transform/opacity. Reanimated for gesture-driven, interpolation, layout animations, complex worklets.

### 8. Why does `useNativeDriver: true` matter?
Animation runs on UI thread; frees JS thread for state/input. Caveat: only transform + opacity.

### 9. Detect frame drops — how?
RN Perf Monitor (Cmd+D), Systrace, Flipper React DevTools profiler, Hermes Profiler, native tools (Xcode Instruments, Android Studio Profiler).

### 10. How to debug "JS thread blocked"?
Enable Perf Monitor → JS FPS. Use `console.time` / Flipper. Look for sync work in render, big loops, JSON.parse on huge payloads.

### 11. What is `InteractionManager`?
Defer non-critical work until animations/gestures finish.
```js
InteractionManager.runAfterInteractions(() => loadHeavyData());
```

### 12. Memoize a row — pattern.
```jsx
const Row = React.memo(({item}) => <Text>{item.title}</Text>);
const renderItem = useCallback(({item}) => <Row item={item} />, []);
```

### 13. Avoid re-renders in long lists — checklist.
Stable `keyExtractor`, `React.memo` rows, `useCallback` handlers, hoist styles, `removeClippedSubviews` on Android.

### 14. Image cache strategy.
Two-tier: memory LRU + disk LRU. FastImage handles both. Prefetch on idle: `FastImage.preload([{uri}])`.

### 15. Animation jank on Android only — likely cause?
JSC vs Hermes, GPU profiler shows overdraw, `removeClippedSubviews` interacting with shadows, RN <0.70 Yoga issues. Test with `--variant=release`.

### 16. Reduce bundle parse time?
Hermes + inline requires + ProGuard + lazy screens. Measure with `--profile-hermes`.

### 17. Profile React renders — how?
React DevTools Profiler (Flipper plugin). Look for components that re-render unexpectedly; check why-did-you-render.

### 18. Heavy JSON parsing — what to do?
Move off main render. Stream parsing (JSONStream) for big payloads. Consider native JSON via TurboModule. Or paginate API.

### 19. Flatlist + KeyboardAvoidingView jank?
KAV re-layouts on every keystroke. Use `react-native-keyboard-controller` or fix height with `KeyboardAwareScrollView` with `extraScrollHeight`.

### 20. Detect memory leaks.
Xcode Instruments → Allocations + Leaks. Android Studio Profiler. Check growing heap on repeated nav. Common: navigation refs, event subscriptions, image cache without bound.

### 21. Reduce re-renders from context.
Split state vs dispatch contexts. Use `use-context-selector`. Or move to Zustand/Jotai with selector subscriptions.

### 22. Pressable vs TouchableOpacity perf?
Pressable is preferred — single component, better gesture interop, less re-render than legacy TouchableX.

### 23. Animation frame budget?
60fps = 16.67ms / frame. Reanimated worklets target this on UI thread. JS-driven animations contend with React work.

### 24. SectionList vs FlatList?
SectionList renders headers between groups but is heavier; for grouped data with frequent scroll, FlashList with `getItemType` often beats it.

### 25. Code: optimized FlashList.
```jsx
<FlashList
  data={items}
  estimatedItemSize={72}
  keyExtractor={i => i.id}
  renderItem={renderItem}
  getItemType={i => i.kind}
  drawDistance={250}
/>
```
