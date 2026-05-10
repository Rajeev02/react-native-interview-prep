## 3. TypeScript for senior RN

### Must-know
- `type` vs `interface`: interface is extendable + merge-able; type does unions/intersections/mapped. Use interface for object shapes, type for unions.
- **Generics**: `function identity<T>(x: T): T`. Constraints: `<T extends { id: string }>`.
- **Utility types**: `Partial`, `Required`, `Pick<T,K>`, `Omit<T,K>`, `Record<K,V>`, `Readonly`, `ReturnType<typeof f>`, `Parameters<typeof f>`, `Awaited<P>`, `NonNullable`.
- **Discriminated unions** (the most useful pattern):
  ```ts
  type Result<T> = { ok: true; data: T } | { ok: false; error: string };
  if (r.ok) r.data; else r.error; // narrowed
  ```
- **Type guards**: `typeof`, `instanceof`, `in`, custom `function isUser(x): x is User`.
- **`as const`**: `const tabs = ['home','profile'] as const;` → readonly tuple of literals.
- **`unknown` > `any`**: `unknown` forces narrowing; `any` disables checks. Use `never` for exhaustiveness.

### Typing RN navigation (asked often)
```ts
type RootStackParamList = {
  Home: undefined;
  Profile: { userId: string };
  Payment: { orderId: string; amount: number };
};
type Props = NativeStackScreenProps<RootStackParamList, 'Payment'>;
```

### Typing API responses with Zod (runtime + compile)
```ts
const User = z.object({ id: z.string(), name: z.string() });
type User = z.infer<typeof User>;
const data = User.parse(await res.json()); // throws on shape mismatch
```

### Must-answer questions
1. `type` vs `interface` — when to use which.
2. Write a generic `useFetch<T>` hook.
3. Discriminated union for API result.
4. `unknown` vs `any` vs `never`.
5. End-to-end typed React Navigation.

---

