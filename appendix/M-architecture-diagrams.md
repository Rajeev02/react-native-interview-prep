# Appendix M — Architecture & Threading Diagrams (Mermaid)

> All diagrams are GitHub-flavored Mermaid. They render natively in GitHub, VS Code preview, and Obsidian. Use them in interviews — sketch from memory on a whiteboard.

---

## M.1 — RN Old Architecture (Bridge / Paper)

```mermaid
flowchart LR
    subgraph JSThread["JS Thread (JSC/Hermes)"]
        JS[JavaScript Code<br/>React + business logic]
        REACT[React Reconciler]
    end

    subgraph Bridge["Bridge (async, batched, JSON-serialized)"]
        QUEUE[(MessageQueue<br/>JS ⇄ Native)]
    end

    subgraph ShadowThread["Shadow Thread"]
        YOGA[Yoga Layout Engine<br/>Flexbox calc]
    end

    subgraph UIThread["UI / Main Thread"]
        VIEWS[Native Views<br/>UIView / Android View]
        PAPER[Paper Renderer]
    end

    JS --> REACT
    REACT -->|setState diff| QUEUE
    QUEUE -->|batched JSON| YOGA
    YOGA -->|computed layout| PAPER
    PAPER --> VIEWS
    VIEWS -->|touch / gesture| QUEUE
    QUEUE -->|events| JS
```

**Key pain points:** JSON serialization on every cross-thread call; async bridge → can't read native synchronously; startup cost loading all NativeModules eagerly.

---

## M.2 — RN New Architecture (JSI / Fabric / TurboModules)

```mermaid
flowchart LR
    subgraph JSThread["JS Thread"]
        JS[JavaScript Code]
        REACT[React 18 Reconciler<br/>Concurrent]
    end

    subgraph JSI["JSI (C++ binding layer)"]
        JSIAPI[Direct refs to<br/>Host Objects/Functions]
    end

    subgraph Native["Native (C++/Swift/Kotlin)"]
        TM[TurboModules<br/>lazy-loaded]
        FABRIC[Fabric Renderer<br/>C++ shadow tree]
        YOGA[Yoga]
    end

    subgraph UIThread["UI Thread"]
        VIEWS[Native Views<br/>view flattening]
    end

    JS --> REACT
    REACT --> JSIAPI
    JSIAPI -->|sync or async<br/>no JSON| TM
    JSIAPI --> FABRIC
    FABRIC --> YOGA
    YOGA --> VIEWS
    VIEWS -.->|events via JSI| JSIAPI
    JSIAPI -.-> JS
```

**Wins:** no JSON serialization, sync native calls possible, lazy module init, concurrent React, view flattening.

---

## M.3 — Render → Reconcile → Commit (Fabric)

```mermaid
sequenceDiagram
    participant JS as JS Thread
    participant React as React Reconciler
    participant Fabric as Fabric (C++)
    participant Yoga as Yoga
    participant UI as UI Thread

    JS->>React: setState
    React->>React: render() → new fiber tree
    React->>Fabric: commit shadow nodes (JSI)
    Fabric->>Yoga: calculate layout
    Yoga-->>Fabric: layout metrics
    Fabric->>UI: mount/update native views
    UI-->>JS: events (touch, scroll) via JSI
```

---

## M.4 — App Startup Sequence (Cold Start)

```mermaid
sequenceDiagram
    participant OS
    participant Native as Native App Init
    participant Hermes
    participant Bundle as JS Bundle
    participant React
    participant UI

    OS->>Native: process fork + dyld
    Native->>Native: AppDelegate / MainActivity
    Native->>Hermes: init JS engine
    Hermes->>Bundle: load index.bundle (.hbc)
    Bundle->>React: require('App')
    React->>React: first render
    React->>UI: mount native views
    UI-->>OS: first frame painted (TTI)
```

**Optimization levers:** Hermes precompiled bytecode, inline requires, lazy TurboModules, splash screen, `react-native-bootsplash`.

---

## M.5 — Reanimated Worklet Threading

```mermaid
flowchart TB
    subgraph JS["JS Thread"]
        JSCODE[Component<br/>useSharedValue]
    end

    subgraph UI["UI Thread (Worklet runtime)"]
        WORKLET[Worklet fn]
        SHARED[(SharedValue)]
        STYLE[useAnimatedStyle]
    end

    subgraph NATIVE["Native View"]
        VIEW[Animated.View props]
    end

    JSCODE -->|runOnUI| WORKLET
    WORKLET --> SHARED
    SHARED --> STYLE
    STYLE -->|direct prop write| VIEW
    WORKLET -.->|runOnJS| JSCODE
```

**Why fast:** animations stay on UI thread; JS thread blocking does NOT drop frames.

---

## M.6 — Navigation Stack (Native Stack)

```mermaid
flowchart TB
    NAV[NavigationContainer]
    ROOT[RootStack]
    AUTH{Auth State}
    LOGIN[LoginStack]
    MAIN[MainTabs]
    HOME[HomeTab]
    PROF[ProfileTab]
    DETAIL[DetailScreen]
    PAY[PaymentScreen]

    NAV --> ROOT
    ROOT --> AUTH
    AUTH -->|not signed| LOGIN
    AUTH -->|signed| MAIN
    MAIN --> HOME
    MAIN --> PROF
    HOME --> DETAIL
    DETAIL --> PAY
```

---

## M.7 — Deep Link Resolution Flow

```mermaid
flowchart TB
    URL[Incoming URL<br/>https://app.com/order/123]
    OS{OS routes}
    UL[Universal Link iOS<br/>AASA verified]
    AL[App Link Android<br/>assetlinks.json]
    SCHEME[Custom Scheme<br/>fallback]
    LINKING[React Navigation<br/>Linking config]
    AUTH{Auth required?}
    LOGIN[Redirect Login<br/>store pending route]
    SCREEN[Target Screen]

    URL --> OS
    OS --> UL
    OS --> AL
    OS --> SCHEME
    UL --> LINKING
    AL --> LINKING
    SCHEME --> LINKING
    LINKING --> AUTH
    AUTH -->|no| LOGIN
    AUTH -->|yes| SCREEN
    LOGIN -->|after sign-in| SCREEN
```

---

## M.8 — Auth: OAuth 2.0 + PKCE Flow

```mermaid
sequenceDiagram
    participant App
    participant Browser as System Browser<br/>(ASWebAuth/CustomTabs)
    participant Auth as Auth Server
    participant API as Resource API

    App->>App: generate code_verifier + code_challenge
    App->>Browser: open /authorize?challenge=...
    Browser->>Auth: user signs in
    Auth-->>App: redirect (universal link)<br/>+ authorization_code
    App->>Auth: POST /token<br/>code + code_verifier
    Auth-->>App: access_token + refresh_token
    App->>App: store tokens in Keychain/Keystore
    App->>API: GET /resource (Bearer)
    API-->>App: 200 OK
    Note over App,Auth: 401 → refresh flow
    App->>Auth: POST /token (refresh_token)
    Auth-->>App: new access_token (rotated refresh)
```

---

## M.9 — Token Refresh Single-Flight Pattern

```mermaid
sequenceDiagram
    participant R1 as Request 1
    participant R2 as Request 2
    participant R3 as Request 3
    participant Lock as RefreshLock
    participant Auth

    R1->>Lock: acquire (refreshing=true)
    R2->>Lock: refreshing? wait
    R3->>Lock: refreshing? wait
    Lock->>Auth: POST /token (refresh)
    Auth-->>Lock: new access_token
    Lock-->>R1: token
    Lock-->>R2: token
    Lock-->>R3: token
    R1->>R1: retry original
    R2->>R2: retry original
    R3->>R3: retry original
```

---

## M.10 — Offline-First Sync Engine

```mermaid
flowchart LR
    subgraph Client
        UI[UI mutation]
        QUEUE[(Mutation Queue<br/>local DB)]
        STORE[(Local Cache<br/>SQLite/MMKV)]
        SYNC[Sync Worker]
    end

    subgraph Network
        NET{Online?}
    end

    subgraph Server
        API[API]
        DB[(Server DB)]
    end

    UI -->|optimistic write| STORE
    UI -->|enqueue| QUEUE
    QUEUE --> SYNC
    SYNC --> NET
    NET -->|yes| API
    NET -->|no| QUEUE
    API --> DB
    API -->|ack + canonical| STORE
    API -->|conflict| SYNC
    SYNC -->|reconcile LWW/CRDT| STORE
```

---

## M.11 — Push Notification Architecture

```mermaid
flowchart LR
    subgraph Backend
        SVC[Notification Service]
        TPL[Template Engine]
    end

    subgraph Apple
        APNS[APNs]
    end

    subgraph Google
        FCM[FCM]
    end

    subgraph Device
        IOS[iOS App]
        AND[Android App]
        EXT[Notif Service Extension]
        ROUTER[Deep Link Router]
        SCREEN[Target Screen]
    end

    SVC --> TPL
    TPL --> APNS
    TPL --> FCM
    APNS --> IOS
    FCM --> AND
    IOS --> EXT
    EXT --> ROUTER
    AND --> ROUTER
    ROUTER --> SCREEN
```

---

## M.12 — CI/CD Pipeline (EAS + Fastlane)

```mermaid
flowchart LR
    PR[PR opened]
    LINT[Lint + Type]
    UNIT[Unit Tests]
    BUILD[EAS Build<br/>preview]
    E2E[Detox/Maestro]
    PREVIEW[EAS Update<br/>preview channel]
    MERGE[Merge to main]
    PROD[EAS Build<br/>production]
    SUBMIT[EAS Submit<br/>TestFlight + Play Internal]
    SENTRY[Upload sourcemaps<br/>Sentry/Crashlytics]
    OTA[EAS Update<br/>production channel]
    ROLLOUT[Phased / Staged rollout]

    PR --> LINT --> UNIT --> BUILD --> E2E --> PREVIEW
    PREVIEW --> MERGE --> PROD --> SUBMIT --> SENTRY --> ROLLOUT
    MERGE --> OTA
```

---

## M.13 — Observability Data Flow

```mermaid
flowchart LR
    subgraph App
        JS[JS errors]
        NATIVE[Native crashes]
        ANR[ANR / Watchdog]
        PERF[Slow renders]
        CUSTOM[Custom events]
    end

    subgraph Sentry
        SENTRY[(Sentry)]
        SOURCEMAP[Source maps]
        DSYM[dSYMs / mapping.txt]
    end

    subgraph Analytics
        AMP[(Amplitude/GA4)]
    end

    subgraph Backend
        BE[Backend traces]
    end

    JS --> SENTRY
    NATIVE --> SENTRY
    ANR --> SENTRY
    PERF --> SENTRY
    CUSTOM --> AMP
    SENTRY <--> BE
    SOURCEMAP --> SENTRY
    DSYM --> SENTRY
```

---

## M.14 — State Management Decision Tree

```mermaid
flowchart TB
    START{What kind of state?}
    SERVER[Server state]
    LOCAL[Local UI state]
    GLOBAL[Global client state]
    FORM[Form state]

    START --> SERVER
    START --> LOCAL
    START --> GLOBAL
    START --> FORM

    SERVER --> RQ[React Query / RTK Query]
    LOCAL --> USESTATE[useState / useReducer]
    GLOBAL --> SIZE{Complexity?}
    SIZE -->|small| ZUSTAND[Zustand]
    SIZE -->|medium| JOTAI[Jotai / Zustand]
    SIZE -->|large + middleware| RTK[Redux Toolkit]
    FORM --> RHF[React Hook Form + Zod]
```

---

## M.15 — Native Module Bridge → TurboModule Migration

```mermaid
flowchart TB
    OLD[Existing NativeModule<br/>RCT_EXPORT_MODULE / @ReactMethod]
    SPEC[Write TS spec<br/>NativeMyModule.ts]
    GEN[Run codegen<br/>generates C++ glue]
    IMPL[Implement spec<br/>iOS Obj-C++ / Android JNI]
    REGISTER[Register TurboModule<br/>Provider]
    INTEROP[Interop layer covers old consumers]
    VERIFY[Verify with new arch flag]

    OLD --> SPEC --> GEN --> IMPL --> REGISTER --> INTEROP --> VERIFY
```

---

## M.16 — Mobile System Design Template

```mermaid
flowchart TB
    REQ[1. Requirements<br/>functional + NFR]
    SCALE[2. Scale<br/>DAU, RPS, payload]
    API[3. API contract<br/>REST/GraphQL/WS]
    DATA[4. Data model<br/>local + server]
    SYNC[5. Sync strategy<br/>online + offline]
    AUTH[6. Auth + security]
    PUSH[7. Push / realtime]
    CACHE[8. Caching layers]
    FAIL[9. Failure modes<br/>retry, circuit, fallback]
    TELE[10. Telemetry<br/>logs, metrics, traces]

    REQ --> SCALE --> API --> DATA --> SYNC --> AUTH --> PUSH --> CACHE --> FAIL --> TELE
```

Use this exact 10-step skeleton for any mobile design round. Spend ~2 min per box, ~25 min total.

---

## M.17 — Render Storm Diagnosis

```mermaid
flowchart TB
    SLOW[Slow / janky UI]
    PROFILER[React DevTools Profiler]
    Q1{Many re-renders?}
    Q2{Same component re-renders?}
    Q3{Why did this render?}

    PROP[Props changed<br/>inline object/fn]
    STATE[State changed]
    CTX[Context value changed]
    PARENT[Parent re-rendered]

    FIX1[Memo + stable refs<br/>useMemo/useCallback]
    FIX2[Split context<br/>state vs dispatch]
    FIX3[Selector pattern]
    FIX4[React.memo + props equality]

    SLOW --> PROFILER --> Q1
    Q1 -->|yes| Q2
    Q2 -->|yes| Q3
    Q3 --> PROP --> FIX1
    Q3 --> STATE --> FIX3
    Q3 --> CTX --> FIX2
    Q3 --> PARENT --> FIX4
```

---

## M.18 — End-to-End Request Lifecycle (RN → Backend → Telemetry)

```mermaid
sequenceDiagram
    participant UI
    participant Hook as useQuery
    participant Cache as RQ Cache
    participant Axios
    participant Auth as Token Store
    participant API
    participant Sentry

    UI->>Hook: render
    Hook->>Cache: lookup key
    alt cache hit (fresh)
        Cache-->>UI: data
    else miss / stale
        Hook->>Axios: GET /resource
        Axios->>Auth: get access token
        Auth-->>Axios: Bearer
        Axios->>API: HTTPS request
        alt 200
            API-->>Axios: data
            Axios-->>Cache: populate
            Cache-->>UI: data
        else 401
            Axios->>Auth: refresh (single-flight)
            Auth-->>Axios: new token
            Axios->>API: retry
        else 5xx
            Axios->>Axios: backoff retry
            Axios->>Sentry: capture if exhausted
        end
    end
```

---

## How to use these diagrams in interviews

1. **Memorize 5 anchor diagrams**: M.1, M.2, M.4, M.8, M.16. Whiteboard them in 2 min each.
2. **Always start with boxes + arrows**, label thread per box.
3. **Call out tradeoffs at every arrow** (sync vs async, JSON cost, blocking).
4. **End with telemetry box** — interviewers love production thinking.

End of Appendix M.
