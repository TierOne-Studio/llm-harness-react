# Transitions & Update Scheduling

Patterns for marking updates as non-urgent so React keeps typing, clicking, and the current page responsive while expensive work happens in the background. (Patterns 8, 17, 25 from the catalog.)

---

## 8. Use `startTransition` for Non-Urgent Updates

**Impact: MEDIUM** — Keeps high-priority updates (typing, clicking) responsive.

Wrap non-urgent state updates in `startTransition` so React can interrupt them for urgent work. This is especially useful for search filtering, tab switching, and list re-sorting.

**Avoid — typing blocks while list filters:**

```tsx
function Search({ items }: { items: Item[] }) {
  const [query, setQuery] = useState('')
  const [filtered, setFiltered] = useState(items)

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value)
    setFiltered(items.filter(i => i.name.includes(e.target.value)))
  }

  return (
    <>
      <input value={query} onChange={handleChange} />
      <List items={filtered} />
    </>
  )
}
```

**Prefer — input stays responsive:**

```tsx
import { useState, useTransition } from 'react'

function Search({ items }: { items: Item[] }) {
  const [query, setQuery] = useState('')
  const [filtered, setFiltered] = useState(items)
  const [isPending, startTransition] = useTransition()

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value)
    startTransition(() => {
      setFiltered(items.filter(i => i.name.includes(e.target.value)))
    })
  }

  return (
    <>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <List items={filtered} />
    </>
  )
}
```

---

## 17. Use `useDeferredValue` for Expensive Derived Renders

**Impact: HIGH** — Keeps the UI responsive while expensive subtrees re-render in the background.

`useDeferredValue` tells React to defer re-rendering components that depend on a fast-changing value. Unlike `useTransition` (which wraps the state update), `useDeferredValue` wraps the consumption — useful when you don't control the state setter.

**Avoid — every keystroke blocks the UI:**

```tsx
function SearchPage({ query }: { query: string }) {
  // Expensive: filters and renders 10,000 items on every keystroke
  const results = filterItems(query)
  return <ResultsList items={results} />
}
```

**Prefer — input stays responsive, results update in background:**

```tsx
import { useDeferredValue, useMemo } from 'react'

function SearchPage({ query }: { query: string }) {
  const deferredQuery = useDeferredValue(query)
  const isStale = query !== deferredQuery

  const results = useMemo(() => filterItems(deferredQuery), [deferredQuery])

  return (
    <div style={{ opacity: isStale ? 0.7 : 1 }}>
      <ResultsList items={results} />
    </div>
  )
}
```

**When to use `useDeferredValue` vs `useTransition`:**
- `useTransition` — you control the state setter and can wrap it in `startTransition`
- `useDeferredValue` — the value comes from props, a parent, or a library you don't control

---

## 25. Use `useTransition` for Route Navigation

**Impact: MEDIUM** — Keeps the current page interactive while the next route loads.

In Vite SPAs with `React.lazy()` routes, clicking a navigation link can freeze the UI while the chunk loads and the component renders. Wrapping navigation in `startTransition` lets React show the old page until the new one is ready.

```tsx
import { useTransition } from 'react'
import { useNavigate } from 'react-router-dom'

function NavLink({ to, children }: { to: string; children: React.ReactNode }) {
  const navigate = useNavigate()
  const [isPending, startTransition] = useTransition()

  const handleClick = (e: React.MouseEvent) => {
    e.preventDefault()
    startTransition(() => {
      navigate(to)
    })
  }

  return (
    <a
      href={to}
      onClick={handleClick}
      style={{ opacity: isPending ? 0.7 : 1 }}
    >
      {children}
    </a>
  )
}
```

This prevents the blank-screen flash between lazy-loaded routes and gives you `isPending` to show a subtle loading indicator on the current page.
