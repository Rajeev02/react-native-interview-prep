## 18. Testing strategy

### Test pyramid (mobile)
```
       ▲ E2E (Detox / Maestro) — few, critical flows
      ▲▲ Integration / component (RNTL)
     ▲▲▲ Unit (Jest) — pure logic, hooks
```

### Jest
- Snapshot tests sparingly — high churn.
- Mock native modules: `jest.mock('react-native-keychain', () => ({...}))`.
- Use `jest.useFakeTimers()` for async.

### React Native Testing Library (RNTL)
- Query by accessibility role/label (forces a11y too).
- `userEvent` for realistic interactions.
- Wrap in `QueryClientProvider`, `NavigationContainer`, theme provider.

### Detox
- Gray-box E2E (knows app internals).
- Synchronization: waits for animations/network automatically.
- Flake reduction: avoid `waitFor(timeout)`; use idle sync.

### Maestro (newer, simpler)
- YAML flows, no code needed.
- Cloud runs, easier CI.

### Coverage targets (sane)
- 70–80% on business logic / reducers / utils.
- 50–60% on components.
- E2E: 5–10 critical paths only.

### Must-answer questions
1. Test pyramid for RN.
2. Reduce E2E flakiness.
3. Mock a native module.
4. Test a hook using React Query.
5. Why RNTL over Enzyme.

---

