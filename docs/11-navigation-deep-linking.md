## 11. Navigation + deep linking

### React Navigation
- **Native Stack** (`@react-navigation/native-stack`) — uses iOS/Android native nav, fast.
- **JS Stack** (`@react-navigation/stack`) — fully JS; more customizable, slightly slower.
- **Tab**, **Drawer**, **Material Top Tabs**.
- **Nested navigators** for tabs-inside-stack patterns.

### Expo Router
- File-based routing on top of React Navigation.
- Typed routes via `expo-router/typed-routes`.

### Deep linking
- **URL scheme**: `myapp://order/123` (universal but weak — no domain ownership).
- **iOS Universal Links**: `apple-app-site-association` file on `https://yourdomain/.well-known/`.
- **Android App Links**: `assetlinks.json` + verified domain in manifest.
- **Branch.io**: deferred deep linking (works even pre-install — attribution chain).
- **Firebase Dynamic Links** — deprecated 2025; migrate to Branch or self-host.

### Auth-gated navigation
```js
function Root() {
  const user = useAuth(s => s.user);
  return user ? <AppStack /> : <AuthStack />;
}
```
Avoid imperatively pushing/replacing — let conditional rendering swap navigators.

### Typed params (TS)
```ts
type Stack = { Order: { id: string } };
const Nav = createNativeStackNavigator<Stack>();
function Order({ route }: NativeStackScreenProps<Stack, 'Order'>) {
  route.params.id; // typed
}
```

### Must-answer questions
1. Native Stack vs JS Stack.
2. Universal Links + App Links setup.
3. How Branch deferred deep links work.
4. Auth-gate routing pattern.
5. Type-safe params end-to-end.

---

