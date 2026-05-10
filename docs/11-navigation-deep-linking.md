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



---

## Top 25 Q&A — Navigation + deep linking

### 1. React Navigation vs Expo Router vs Native Navigation?
- **React Navigation**: most-used, JS-heavy, flexible.
- **Expo Router**: file-based on top of React Navigation, simpler URLs.
- **react-native-navigation (Wix)**: native stacks, less common now.

### 2. Stack vs Native Stack vs Bottom Tabs vs Drawer.
- `createStackNavigator` (JS).
- `createNativeStackNavigator` (uses native UINavigationController / Fragment) — preferred for perf.
- `createBottomTabNavigator` for tabs.
- `createDrawerNavigator` for side menus.

### 3. Type-safe routes.
```ts
type RootStackParamList = { Home: undefined; Profile: { id: string } };
type Props = NativeStackScreenProps<RootStackParamList, 'Profile'>;
```

### 4. How does deep linking work in RN?
Configure URL scheme (iOS Info.plist / Android intent-filter) + Universal Links / App Links → React Navigation `linking` config maps URLs to screens.

### 5. `linking` config example.
```ts
const linking = {
  prefixes: ['myapp://', 'https://app.com'],
  config: { screens: { Profile: 'user/:id', Home: '' } },
};
<NavigationContainer linking={linking} />
```

### 6. iOS Universal Links vs URL scheme.
URL scheme (myapp://): app-only, spoofable. Universal Links: HTTPS, requires apple-app-site-association on server, secure, opens app if installed else web.

### 7. Android App Links vs intent-filter.
App Links: HTTPS verified via assetlinks.json. Plain intent-filter for custom scheme (less secure, shows chooser).

### 8. Deferred deep link — what?
Open a URL → install app from store → on first launch, route to original URL. Use Branch.io / Adjust / Firebase Dynamic Links (deprecated 2025) or roll your own via clipboard + IP fingerprint.

### 9. `useNavigation` vs prop drilling navigation.
`useNavigation` hook works anywhere inside `NavigationContainer`. Type with `NavigationProp<RootStackParamList>`.

### 10. `useFocusEffect` vs `useEffect`.
`useFocusEffect` runs when screen focuses (and cleanup on blur). Useful for pausing timers / refetching.

### 11. Pass params + types.
```ts
navigation.navigate('Profile', { id: '123' });
const { id } = route.params; // typed
```

### 12. Reset stack — when?
After login/logout to remove sensitive screens.
```ts
navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
```

### 13. Modal vs screen — how?
`presentation: 'modal'` on screen options or use `Group` with `screenOptions={{presentation:'modal'}}`.

### 14. Prevent back navigation.
```ts
useFocusEffect(useCallback(() => {
  const sub = BackHandler.addEventListener('hardwareBackPress', () => true);
  return () => sub.remove();
}, []));
```

### 15. Authentication flow pattern.
Two stacks (Auth / App) switched by auth state.
```jsx
{user ? <AppStack/> : <AuthStack/>}
```
Avoids leaking screens; resets nav state on auth change.

### 16. Nested navigators — gotchas.
Params don't auto-pass — use `navigate('Parent', { screen: 'Child', params: {...} })`. Header overlap, gestures interaction.

### 17. Drawer + Tabs + Stack — typical layout.
Drawer at root → contains Tabs → each Tab is a Stack. Use `getFocusedRouteNameFromRoute` to hide tab bar on inner screens.

### 18. Persist navigation state across launches.
`onStateChange` saves to MMKV. On launch, pass `initialState`. Be careful with deep-linked params.

### 19. Deep link to screen requiring auth — pattern.
Capture intended URL pre-auth, navigate to login, after success replay deep link via `Linking.openURL` or `navigation.navigate`.

### 20. Handle URL when app is killed vs background.
Killed: `Linking.getInitialURL()`. Background: `Linking.addEventListener('url', handler)`.

### 21. Universal Links on iOS — checklist.
(1) Apple Developer associated domains entitlement. (2) `apple-app-site-association` JSON at `https://app.com/.well-known/`. (3) `applinks:app.com` in entitlements.

### 22. App Links on Android — checklist.
(1) `intent-filter` with `android:autoVerify="true"`. (2) `assetlinks.json` at `https://app.com/.well-known/`. (3) Test: `adb shell pm get-app-links com.app`.

### 23. Stack memory issue when many screens pushed.
Use `react-native-screens` (default in RN Nav v6+) — wraps native containers, frees inactive screens. Set `enableScreens(true)`.

### 24. Cross-platform back behavior.
iOS: swipe-to-go-back default in NativeStack. Android: hardware back. Test both.

### 25. Code: deep-linked OTP screen with prefilled code.
```ts
const linking = {
  prefixes: ['myapp://'],
  config: { screens: { Otp: { path: 'otp/:code', parse: { code: c => c } } } },
};
// URL: myapp://otp/123456 → OtpScreen receives params.code = '123456'
```
