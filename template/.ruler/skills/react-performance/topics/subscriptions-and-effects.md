# State Subscriptions, Callbacks & Effects

Patterns for subscribing to the right granularity of state, keeping callbacks stable, and keeping side effects out of the render/effect cycle when they belong elsewhere. (Patterns 2, 5, 6, 7, 9, 13, 14, 19 from the catalog.)

---

## 2. Subscribe to Coarse-Grained State, Not Raw Values

**Impact: HIGH** — Prevents re-renders on irrelevant changes.

If your component only cares about a derived boolean (e.g., "is mobile?"), don't subscribe to the raw value that changes continuously.

**Avoid — re-renders on every pixel:**

```tsx
function Sidebar() {
  const width = useWindowWidth() // fires on every resize
  const isMobile = width < 768
  return <nav className={isMobile ? 'mobile' : 'desktop'}>...</nav>
}
```

**Prefer — re-renders only when the boolean flips:**

```tsx
function Sidebar() {
  const isMobile = useMediaQuery('(max-width: 767px)')
  return <nav className={isMobile ? 'mobile' : 'desktop'}>...</nav>
}
```

This applies broadly: subscribe to `isLoggedIn` rather than the entire user object, `hasItems` rather than the full cart array, etc.

---

## 5. Use Functional setState for Stable Callbacks

**Impact: MEDIUM** — Removes state variables from dependency arrays.

When a callback only needs the previous state to compute the next state, use the functional form. This eliminates the state variable from the dependency array and produces a stable callback identity.

**Avoid — callback changes when `count` changes:**

```tsx
const [count, setCount] = useState(0)
const increment = useCallback(() => setCount(count + 1), [count])
```

**Prefer — callback is always stable:**

```tsx
const [count, setCount] = useState(0)
const increment = useCallback(() => setCount(c => c + 1), [])
```

---

## 6. Put Interaction Logic in Event Handlers, Not Effects

**Impact: MEDIUM** — Avoids re-running side effects on dependency changes.

If a side effect is triggered by a user action (click, submit, drag), run it in the event handler. Modeling it as state + effect causes re-runs when unrelated dependencies change.

**Avoid — effect re-runs when `theme` changes:**

```tsx
function Form() {
  const [submitted, setSubmitted] = useState(false)
  const theme = useContext(ThemeContext)

  useEffect(() => {
    if (submitted) {
      post('/api/register')
      showToast('Registered', theme)
    }
  }, [submitted, theme])

  return <button onClick={() => setSubmitted(true)}>Submit</button>
}
```

**Prefer — logic in the handler:**

```tsx
function Form() {
  const theme = useContext(ThemeContext)

  function handleSubmit() {
    post('/api/register')
    showToast('Registered', theme)
  }

  return <button onClick={handleSubmit}>Submit</button>
}
```

---

## 7. Use `useRef` for Transient, High-Frequency Values

**Impact: MEDIUM** — Prevents re-renders on rapid updates.

Values that change very frequently (mouse position, scroll offset, interval ticks) but don't need to drive re-renders should live in a ref. Update the DOM directly when needed.

**Avoid — re-renders on every mouse move:**

```tsx
function Cursor() {
  const [x, setX] = useState(0)

  useEffect(() => {
    const handler = (e: MouseEvent) => setX(e.clientX)
    window.addEventListener('mousemove', handler)
    return () => window.removeEventListener('mousemove', handler)
  }, [])

  return <div style={{ transform: `translateX(${x}px)` }} />
}
```

**Prefer — zero re-renders:**

```tsx
function Cursor() {
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current) {
        ref.current.style.transform = `translateX(${e.clientX}px)`
      }
    }
    window.addEventListener('mousemove', handler)
    return () => window.removeEventListener('mousemove', handler)
  }, [])

  return <div ref={ref} />
}
```

---

## 9. Defer State Reads to the Point of Use

**Impact: MEDIUM** — Avoids subscriptions to state you only read in callbacks.

Don't call hooks like `useSearchParams()` if you only read the value inside an event handler. Read it on demand instead.

**Avoid — component re-renders on every URL change:**

```tsx
function ShareButton({ id }: { id: string }) {
  const [searchParams] = useSearchParams()

  const handleShare = () => {
    const ref = searchParams.get('ref')
    share(id, { ref })
  }

  return <button onClick={handleShare}>Share</button>
}
```

**Prefer — reads on demand, no subscription:**

```tsx
function ShareButton({ id }: { id: string }) {
  const handleShare = () => {
    const params = new URLSearchParams(window.location.search)
    share(id, { ref: params.get('ref') })
  }

  return <button onClick={handleShare}>Share</button>
}
```

---

## 13. Initialize Expensive Operations Once Per App

**Impact: LOW-MEDIUM** — Avoids duplicate init in Strict Mode and remounts.

App-wide initialization (analytics, auth checks, service workers) should not live in `useEffect` — components remount in development and in concurrent features. Use a module-level guard.

**Avoid — runs twice in dev, again on remount:**

```tsx
function App() {
  useEffect(() => {
    initAnalytics()
    checkAuth()
  }, [])
  return <Router />
}
```

**Prefer — once per app load:**

```tsx
let initialized = false

function App() {
  useEffect(() => {
    if (initialized) return
    initialized = true
    initAnalytics()
    checkAuth()
  }, [])
  return <Router />
}
```

Or initialize at the module level in your entry file (`main.tsx`), outside any component.

---

## 14. Store Event Handlers in Refs for Stable Subscriptions

**Impact: LOW** — Prevents effect re-subscriptions.

When a custom hook subscribes to an event and accepts a callback, store the callback in a ref so the subscription doesn't tear down and recreate on every render.

**Avoid — re-subscribes when handler changes:**

```tsx
function useWindowEvent(event: string, handler: (e: Event) => void) {
  useEffect(() => {
    window.addEventListener(event, handler)
    return () => window.removeEventListener(event, handler)
  }, [event, handler])
}
```

**Prefer — stable subscription:**

```tsx
function useWindowEvent(event: string, handler: (e: Event) => void) {
  const saved = useRef(handler)
  useEffect(() => { saved.current = handler }, [handler])

  useEffect(() => {
    const listener = (e: Event) => saved.current(e)
    window.addEventListener(event, listener)
    return () => window.removeEventListener(event, listener)
  }, [event])
}
```

If using React 19.2+, `useEffectEvent` provides this pattern as a built-in:

```tsx
import { useEffectEvent } from 'react'

function useWindowEvent(event: string, handler: (e: Event) => void) {
  const onEvent = useEffectEvent(handler)
  useEffect(() => {
    window.addEventListener(event, onEvent)
    return () => window.removeEventListener(event, onEvent)
  }, [event])
}
```

---

## 19. Narrow Effect Dependencies to Primitives

**Impact: MEDIUM** — Prevents effects from re-running when unrelated object properties change.

When an effect only needs one property from an object, extract it before the dependency array. Passing the whole object causes re-runs whenever any property changes.

**Avoid — effect re-runs when `user.name` or `user.avatar` changes:**

```tsx
function UserStatus({ user }: { user: User }) {
  useEffect(() => {
    updatePresence(user.id)
  }, [user]) // re-runs on ANY user property change
}
```

**Prefer — only re-runs when the ID changes:**

```tsx
function UserStatus({ user }: { user: User }) {
  const { id } = user
  useEffect(() => {
    updatePresence(id)
  }, [id])
}
```

This also applies to hook return values. If `useQuery` returns `{ data, status, fetchStatus }` and your effect only cares about `status`, destructure first.
