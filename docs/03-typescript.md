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



---

## Top 25 Q&A — TypeScript

### 1. `type` vs `interface`?
`interface` — extendable, declaration merging, best for object shapes. `type` — unions, intersections, mapped, conditional.
```ts
interface User { id: string }
interface User { name: string } // merges
type Result = { ok: true } | { ok: false; err: string };
```

### 2. `unknown` vs `any` vs `never`.
- `any` — disables checks.
- `unknown` — must narrow before use.
- `never` — value that can't exist; used for exhaustiveness.
```ts
function assertNever(x: never): never { throw new Error(String(x)); }
```

### 3. What are generics?
Type parameters for reusable, type-safe code.
```ts
function first<T>(arr: T[]): T | undefined { return arr[0]; }
first([1,2]);      // T = number
first(['a','b']);  // T = string
```

### 4. Explain utility types: `Partial`, `Required`, `Pick`, `Omit`, `Record`.
```ts
type U = { id: string; name: string; age: number };
Partial<U>;             // all optional
Required<U>;            // all required
Pick<U, 'id'|'name'>;   // subset
Omit<U, 'age'>;         // remove
Record<'a'|'b', U>;     // {a:U; b:U}
```

### 5. Discriminated unions — when?
Modeling state with a tag field; enables exhaustive narrowing.
```ts
type Net = {s:'idle'} | {s:'load'} | {s:'ok'; data:string} | {s:'err'; e:Error};
function r(n: Net){ switch(n.s){ case 'ok': return n.data; case 'err': return n.e.message; } }
```

### 6. Type guards.
Functions returning `x is T` to narrow types.
```ts
function isStr(x: unknown): x is string { return typeof x === 'string'; }
```

### 7. `as const` — what does it do?
Makes literal types readonly.
```ts
const tabs = ['home','profile'] as const; // readonly ['home','profile']
type Tab = typeof tabs[number]; // 'home' | 'profile'
```

### 8. `keyof` and `typeof` operators.
```ts
const cfg = { url: '', timeout: 0 };
type Cfg = typeof cfg;          // {url:string; timeout:number}
type Key = keyof Cfg;           // 'url' | 'timeout'
```

### 9. Mapped types.
```ts
type Nullable<T> = { [K in keyof T]: T[K] | null };
type ReadonlyDeep<T> = { readonly [K in keyof T]: T[K] };
```

### 10. Conditional types.
```ts
type IsArr<T> = T extends any[] ? true : false;
type A = IsArr<string[]>;  // true
type B = IsArr<number>;    // false
```

### 11. `infer` keyword.
```ts
type ReturnT<F> = F extends (...a:any[]) => infer R ? R : never;
type X = ReturnT<() => string>; // string
```

### 12. Type a generic React Native hook `useFetch<T>`.
```ts
function useFetch<T>(url: string){
  const [d,setD]=useState<T|null>(null); const [e,setE]=useState<Error|null>(null);
  useEffect(()=>{ fetch(url).then(r=>r.json()).then(setD).catch(setE); },[url]);
  return { data:d, error:e } as const;
}
```

### 13. Type React Navigation routes end-to-end.
```ts
type RootStackParamList = { Home: undefined; Profile: { id: string } };
type Props = NativeStackScreenProps<RootStackParamList, 'Profile'>;
function Profile({route}: Props){ return route.params.id; }
```

### 14. What is `satisfies`?
Validates a value against a type without widening.
```ts
const colors = { primary: '#000', danger: '#f00' } satisfies Record<string, string>;
colors.primary; // still '#000', not generic string
```

### 15. Strict mode flags worth enabling?
`strict`, `noImplicitAny`, `strictNullChecks`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noFallthroughCasesInSwitch`.

### 16. `interface` extension vs `type` intersection.
```ts
interface A { x:number } interface B extends A { y:number }
type AT = { x:number }; type BT = AT & { y:number };
```
Behavior similar; interface gives clearer error messages.

### 17. Index signatures.
```ts
type Dict<T> = { [k: string]: T };
const cache: Dict<number> = { a:1 };
```

### 18. Function overloads.
```ts
function fmt(x: string): string;
function fmt(x: number): string;
function fmt(x: any){ return String(x); }
```

### 19. Template literal types.
```ts
type Lang = 'en'|'hi'; type Key = `welcome.${Lang}`; // 'welcome.en' | 'welcome.hi'
```

### 20. Branded / nominal types.
```ts
type UserId = string & { readonly _brand: 'UserId' };
function makeUserId(s: string): UserId { return s as UserId; }
```

### 21. Type a Redux slice.
```ts
interface AuthState { user: User | null; status: 'idle'|'loading' }
const slice = createSlice<AuthState, ...>({ name:'auth', initialState, reducers:{ ... } });
```

### 22. Validate API at runtime — Zod.
```ts
const U = z.object({ id: z.string(), email: z.string().email() });
type U = z.infer<typeof U>;
const u = U.parse(json); // throws if shape wrong
```

### 23. `enum` vs union of literals — which to use?
Prefer union of literals (no runtime cost, tree-shakeable). `const enum` is OK in apps but breaks with `isolatedModules`.

### 24. Declaration merging — when useful?
Augmenting third-party module types.
```ts
declare module '@react-navigation/native' {
  interface RootParamList extends RootStackParamList {}
}
```

### 25. How to type `useReducer`?
```ts
type Action = { type: 'inc' } | { type: 'set'; n: number };
const reducer = (s: number, a: Action): number => a.type==='inc' ? s+1 : a.n;
const [n, dispatch] = useReducer(reducer, 0);
```
