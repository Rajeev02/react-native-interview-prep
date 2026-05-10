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



---

## Top 25 Q&A — Testing strategy

### 1. Pyramid for RN.
Unit (Jest) > Component (React Native Testing Library) > Integration (RNTL + MSW) > E2E (Detox / Maestro). Spend ~70/20/10.

### 2. Unit test a hook.
```ts
import { renderHook, act } from '@testing-library/react-native';
const { result } = renderHook(() => useCounter());
act(() => result.current.inc());
expect(result.current.count).toBe(1);
```

### 3. RNTL — query priority.
`getByRole` > `getByLabelText` > `getByText` > `getByTestId`. Mirror what users perceive.

### 4. Mock fetch in tests.
**MSW (mock service worker)** for realistic API mocks. Avoid `jest.fn()` per test.
```ts
server.use(rest.get('/u/:id', (req,res,ctx) => res(ctx.json({id:'1'}))));
```

### 5. Async assertion pattern.
```ts
expect(await screen.findByText('Welcome')).toBeOnTheScreen();
```
`findBy*` waits + retries.

### 6. Snapshot tests — when?
Use sparingly: stable presentational components. Avoid for data-driven views — they're noisy and ignored.

### 7. Detox vs Maestro?
- **Detox**: gray-box, JS test code, fast, complex setup.
- **Maestro**: black-box YAML flows, simple, runs anywhere, slower CI.
Many teams use Maestro for smoke tests + Detox for critical flows.

### 8. Detox basic flow.
```js
await element(by.id('login-email')).typeText('a@b.com');
await element(by.id('login-submit')).tap();
await expect(element(by.text('Home'))).toBeVisible();
```

### 9. Tests for navigation.
Mock `@react-navigation/native` and assert `navigate` called with right args. Or use `NavigationContainer` in test with in-memory state.

### 10. Test Redux/Zustand integration.
Wrap render with provider; trigger interactions; assert store state via selector. Don't dispatch in tests directly when possible.

### 11. Time-based code.
`jest.useFakeTimers()`, `jest.advanceTimersByTime(1000)`. For React Query, configure shorter `staleTime` in tests.

### 12. Mocking native modules.
```ts
jest.mock('react-native-keychain', () => ({
  setGenericPassword: jest.fn(), getGenericPassword: jest.fn().mockResolvedValue({password:'tok'}),
}));
```

### 13. Coverage targets.
80% statements/branches for business logic, 60% for screens. Don't chase 100%; cover edge cases instead.

### 14. Accessibility tests in unit.
RNTL queries `getByRole('button', {name:'Pay'})` — fails if a11y label missing → accessibility regression caught.

### 15. Visual regression.
Storybook + Chromatic, or `jest-image-snapshot` with screenshots from Detox. Run on a fixed device profile.

### 16. Mock timers + animations.
React Native animations need `jest.useFakeTimers('legacy')` or skip via `Animated.timing` mocks.

### 17. CI config (GitHub Actions).
Cache `node_modules`, run `tsc`, `eslint`, `jest --coverage`. For Detox/Maestro use mac-os runner with simulator.

### 18. Flaky tests strategy.
Identify (track failures), quarantine, fix root (timing assumptions, network mocks). Never blanket retry.

### 19. Contract tests with backend.
Pact or shared OpenAPI/zod schemas. Mobile fails CI when API contract changes.

### 20. Code: testing async screen with API.
```ts
render(<UserScreen id="1" />);
expect(await screen.findByText('Loading...')).toBeOnTheScreen();
expect(await screen.findByText('Hello, Asha')).toBeOnTheScreen();
```

### 21. Detox iOS sim + Android emu in CI.
Use macOS runner with iPhone 15 sim; Android emulator via reactivecircus/android-emulator-runner. Slow but reliable.

### 22. Jest setup essentials.
`setupFiles`/`setupFilesAfterEach`, transform via `babel-jest`, `transformIgnorePatterns` for ESM RN libs, `moduleNameMapper` for assets.

### 23. Handling `ReanimatedLogger` warnings.
Add `jest.mock('react-native-reanimated', () => require('react-native-reanimated/mock'))`.

### 24. Testing dark mode / themes.
Wrap renderer with theme provider, parametrize `[light, dark]`. RNTL `rerender` with different value.

### 25. End-to-end flow: login → buy → confirm in Maestro.
```yaml
appId: com.app
---
- launchApp
- tapOn: 'Login'
- inputText: 'asha@x.com'
- tapOn: 'Submit'
- assertVisible: 'Welcome'
- tapOn: 'Buy'
- assertVisible: 'Order placed'
```
