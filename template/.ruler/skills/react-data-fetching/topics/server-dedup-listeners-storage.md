# Server-Side Dedup, Event Listeners, and Client Storage

Supporting patterns: `React.cache()` for per-request server deduplication, shared/passive event listeners, and schema-versioned localStorage.

## 1. Use `React.cache()` for Server-Side Deduplication

**Impact: MEDIUM** — Deduplicates expensive operations within a single server render.

In server components (RSC), `React.cache()` ensures the same async call made by multiple components only executes once per request.

```typescript
import { cache } from 'react'

export const getSession = cache(async () => {
  const session = await auth()
  if (!session?.user?.id) return null
  return session
})

export const getUser = cache(async (userId: string) => {
  return await db.user.findUnique({ where: { id: userId } })
})
```

Multiple components calling `getSession()` in the same render share one execution.

**Important:** Use primitive arguments (strings, numbers) for cache keys. Inline objects create new references and cause cache misses:

```typescript
// Cache miss every time — new object reference
getUser({ id: '123' })
getUser({ id: '123' }) // miss

// Cache hit — same string value
getUser('123')
getUser('123') // hit
```

---

## 2. Deduplicate Global Event Listeners

**Impact: MEDIUM** — Prevents N listeners for N component instances.

When multiple component instances need the same global event (resize, scroll, online), share a single listener.

```typescript
// hooks/useOnlineStatus.ts
import { useSyncExternalStore } from 'react'

function subscribe(callback: () => void) {
  window.addEventListener('online', callback)
  window.addEventListener('offline', callback)
  return () => {
    window.removeEventListener('online', callback)
    window.removeEventListener('offline', callback)
  }
}

function getSnapshot() {
  return navigator.onLine
}

export function useOnlineStatus() {
  return useSyncExternalStore(subscribe, getSnapshot, () => true)
}
```

`useSyncExternalStore` automatically deduplicates subscriptions and ensures consistent state across concurrent renders.

---

## 3. Use Passive Event Listeners for Scroll and Touch

**Impact: LOW-MEDIUM** — Prevents scroll jank from blocking listeners.

Non-passive scroll/touch listeners block the browser's compositor thread. Mark them passive when you don't call `preventDefault()`.

**Avoid — blocks scrolling:**

```tsx
useEffect(() => {
  const handler = () => trackScroll(window.scrollY)
  window.addEventListener('scroll', handler)
  return () => window.removeEventListener('scroll', handler)
}, [])
```

**Prefer — non-blocking:**

```tsx
useEffect(() => {
  const handler = () => trackScroll(window.scrollY)
  window.addEventListener('scroll', handler, { passive: true })
  return () => window.removeEventListener('scroll', handler)
}, [])
```

---

## 4. Schema-Version Your Client Storage

**Impact: LOW-MEDIUM** — Prevents crashes from stale localStorage data.

When reading from localStorage or sessionStorage, stale data from a previous app version can crash your app. Add a schema version and validate.

**Avoid — crashes on schema change:**

```tsx
const [prefs, setPrefs] = useState(() => {
  return JSON.parse(localStorage.getItem('prefs') || '{}')
})
```

**Prefer — versioned with fallback:**

```tsx
const PREFS_VERSION = 2

const [prefs, setPrefs] = useState<Prefs>(() => {
  try {
    const raw = localStorage.getItem('prefs')
    if (!raw) return DEFAULT_PREFS
    const parsed = JSON.parse(raw)
    if (parsed._v !== PREFS_VERSION) return DEFAULT_PREFS
    return parsed
  } catch {
    return DEFAULT_PREFS
  }
})

// On save, include version
useEffect(() => {
  localStorage.setItem('prefs', JSON.stringify({ ...prefs, _v: PREFS_VERSION }))
}, [prefs])
```
