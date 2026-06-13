# Memoization & Derived State

Patterns for deciding what to memoize, what to derive during render, and how to keep component identity and references stable so memoization actually works. (Patterns 1, 3, 4, 10, 12, 16, 20 from the catalog.)

---

## 1. Compute Derived Values During Render — Don't Store Them

**Impact: HIGH** — Eliminates an entire category of bugs and unnecessary state.

Storing values that can be computed from existing state or props creates synchronization problems and extra re-renders. Compute them inline instead.

**Avoid — redundant state that drifts:**

```tsx
function ProductList({ products }: { products: Product[] }) {
  const [search, setSearch] = useState('')
  const [filtered, setFiltered] = useState(products)

  useEffect(() => {
    setFiltered(products.filter(p =>
      p.name.toLowerCase().includes(search.toLowerCase())
    ))
  }, [products, search])

  return (
    <>
      <input value={search} onChange={e => setSearch(e.target.value)} />
      {filtered.map(p => <ProductCard key={p.id} product={p} />)}
    </>
  )
}
```

**Prefer — derive during render (cheap derivations use plain `const`):**

```tsx
function ProductList({ products }: { products: Product[] }) {
  const [search, setSearch] = useState('')

  // Cheap derivation — plain const, no useMemo needed
  const hasSearch = search.length > 0
  const normalizedSearch = search.toLowerCase()

  // Expensive derivation — useMemo is justified when iterating large arrays
  const filtered = useMemo(
    () => products.filter(p =>
      p.name.toLowerCase().includes(normalizedSearch)
    ),
    [products, normalizedSearch]
  )

  return (
    <>
      <input value={search} onChange={e => setSearch(e.target.value)} />
      {hasSearch && <ClearButton />}
      {filtered.map(p => <ProductCard key={p.id} product={p} />)}
    </>
  )
}
```

**When to use `useMemo` vs a plain `const`:**
- **Plain `const`** — boolean flags, string formatting, simple arithmetic, object property access, `.length` checks. These are essentially free and `useMemo` overhead is not worth it.
- **`useMemo`** — filtering/sorting arrays, building data structures, `JSON.parse`, expensive transformations, anything that iterates collections or involves O(n) work.

The rule: if the expression returns a primitive or is a single property access, skip `useMemo`. If it iterates or transforms data, wrap it.

> **React Compiler note:** If React Compiler is enabled, it auto-memoizes expressions and you can skip manual `useMemo` calls.

---

## 3. Extract Expensive Subtrees into Memoized Components

**Impact: HIGH** — Enables early returns and skip-rendering.

When a parent has fast paths (loading, error, empty), expensive children still compute if they live in the same component. Extract them so React can skip their render entirely.

**Avoid — avatar computation runs even during loading:**

```tsx
function Profile({ user, loading }: Props) {
  const avatar = useMemo(() => processAvatar(user), [user])

  if (loading) return <Skeleton />
  return <div><img src={avatar} /></div>
}
```

**Prefer — computation skipped when loading:**

```tsx
const UserAvatar = memo(function UserAvatar({ user }: { user: User }) {
  const avatar = useMemo(() => processAvatar(user), [user])
  return <img src={avatar} />
})

function Profile({ user, loading }: Props) {
  if (loading) return <Skeleton />
  return <div><UserAvatar user={user} /></div>
}
```

> **React Compiler note:** The compiler auto-memoizes, making manual `memo()` wrapping less necessary. But extracting components for early returns is still valuable.

---

## 4. Use Lazy State Initialization

**Impact: MEDIUM** — Avoids wasted computation on every render.

When `useState` receives a function call as its initial value, that call executes on every render even though the result is only used once. Pass a function reference instead.

**Avoid — `buildIndex()` runs every render:**

```tsx
const [index, setIndex] = useState(buildSearchIndex(items))
```

**Prefer — runs only on mount:**

```tsx
const [index, setIndex] = useState(() => buildSearchIndex(items))
```

Use lazy init for: `JSON.parse`, `localStorage` reads, building data structures, heavy transformations. Skip it for simple primitives like `useState(0)` or `useState(false)`.

---

## 10. Use Stable References for Default Props

**Impact: MEDIUM** — Prevents `memo()` from being defeated by new object/array literals.

Passing `[]` or `{}` as default prop values creates new references every render, defeating memoization on child components.

**Avoid — new array each render:**

```tsx
function Dashboard({ tabs = [] }: { tabs?: Tab[] }) {
  return <TabBar tabs={tabs} /> {/* TabBar re-renders every time */}
}
```

**Prefer — stable reference:**

```tsx
const EMPTY_TABS: Tab[] = []

function Dashboard({ tabs = EMPTY_TABS }: { tabs?: Tab[] }) {
  return <TabBar tabs={tabs} />
}
```

---

## 12. Hoist Static JSX Outside Components

**Impact: LOW** — Avoids re-creating identical elements.

JSX elements that never change can be lifted to module scope. React reuses the same object reference across renders.

**Avoid — recreated every render:**

```tsx
function Page() {
  return (
    <main>
      <footer>
        <p>Copyright 2026 Acme Inc.</p>
      </footer>
    </main>
  )
}
```

**Prefer — created once:**

```tsx
const footer = (
  <footer>
    <p>Copyright 2026 Acme Inc.</p>
  </footer>
)

function Page() {
  return <main>{footer}</main>
}
```

Most impactful for large SVG elements which are expensive to recreate.

> **React Compiler note:** The compiler auto-hoists static JSX, making this manual optimization unnecessary.

---

## 16. Never Define Components Inside Components

**Impact: HIGH** — Causes remounting, state loss, and wasted DOM work every render.

When you define a component inside another component's render, React creates a new component type on every render. This means the entire subtree unmounts and remounts — losing all state, DOM nodes, and effect cleanup/setup.

**Avoid — `Row` is a new type every render:**

```tsx
function Table({ data }: { data: Item[] }) {
  // This creates a NEW component type on every render
  function Row({ item }: { item: Item }) {
    const [selected, setSelected] = useState(false)
    return <tr onClick={() => setSelected(!selected)}>{item.name}</tr>
  }

  return <table>{data.map(item => <Row key={item.id} item={item} />)}</table>
}
```

**Prefer — `Row` defined at module scope:**

```tsx
function Row({ item }: { item: Item }) {
  const [selected, setSelected] = useState(false)
  return <tr onClick={() => setSelected(!selected)}>{item.name}</tr>
}

function Table({ data }: { data: Item[] }) {
  return <table>{data.map(item => <Row key={item.id} item={item} />)}</table>
}
```

This also applies to components defined inside `useMemo`, `useCallback`, or any other hook. Always define components at module scope or as static properties.

---

## 20. Split Combined Hook Computations

**Impact: MEDIUM** — Prevents re-renders for consumers that only need part of a hook's output.

When a custom hook computes multiple unrelated values, a change in one forces re-renders in all consumers — even those that only read the unchanged value.

**Avoid — changing `total` re-renders components that only need `average`:**

```tsx
function useStats(items: number[]) {
  return useMemo(() => ({
    total: items.reduce((a, b) => a + b, 0),
    average: items.reduce((a, b) => a + b, 0) / items.length,
    max: Math.max(...items),
  }), [items])
}
```

**Prefer — split into focused hooks:**

```tsx
function useTotal(items: number[]) {
  return useMemo(() => items.reduce((a, b) => a + b, 0), [items])
}

function useAverage(items: number[]) {
  return useMemo(() => items.reduce((a, b) => a + b, 0) / items.length, [items])
}

function useMax(items: number[]) {
  return useMemo(() => Math.max(...items), [items])
}
```

Components call only the hook they need. If a single component needs all three, combining them there is fine — the split prevents unnecessary coupling at the hook level.
