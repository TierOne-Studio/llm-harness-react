# DOM Rendering, Lists & Paint Cost

Patterns for reducing browser-side rendering cost: long lists, layout thrashing, SVG repaints, and conditional-rendering output. (Patterns 11, 18, 21, 22 from the catalog.)

---

## 11. CSS `content-visibility` for Long Lists

**Impact: HIGH** — 5-10x faster initial render for long scrollable content.

Apply `content-visibility: auto` to off-screen items so the browser skips their layout and paint until they scroll into view.

```css
.list-item {
  content-visibility: auto;
  contain-intrinsic-size: 0 80px; /* estimated height */
}
```

```tsx
function MessageList({ messages }: { messages: Message[] }) {
  return (
    <div style={{ overflowY: 'auto', height: '100vh' }}>
      {messages.map(msg => (
        <div key={msg.id} className="list-item">
          <MessageCard message={msg} />
        </div>
      ))}
    </div>
  )
}
```

For 1,000 items, the browser skips layout and paint for ~990 off-screen items. Combine with virtualization (e.g., `react-window`, `@tanstack/react-virtual`) for truly massive lists.

---

## 18. Use Explicit Checks in Conditional Rendering

**Impact: MEDIUM** — Prevents rendering `0`, `NaN`, or empty strings to the DOM.

The `&&` operator in JSX short-circuits on falsy values — but `0`, `NaN`, and `""` are falsy yet still render as visible text nodes.

**Avoid — renders `0` to the DOM when count is zero:**

```tsx
function NotificationBadge({ count }: { count: number }) {
  return <div>{count && <Badge>{count}</Badge>}</div>
  // When count is 0, renders: <div>0</div>
}
```

**Prefer — explicit boolean check:**

```tsx
function NotificationBadge({ count }: { count: number }) {
  return <div>{count > 0 && <Badge>{count}</Badge>}</div>
}

// Or use a ternary for clarity
function NotificationBadge({ count }: { count: number }) {
  return <div>{count > 0 ? <Badge>{count}</Badge> : null}</div>
}
```

This applies to any value that might be `0`, `NaN`, or `""` — array lengths, string values, numeric props. Always use an explicit boolean expression (`> 0`, `!== ''`, `!= null`) rather than relying on truthiness.

---

## 21. Avoid Layout Thrashing with Batched DOM Reads/Writes

> Canonical home of the batching principle: `js-performance-patterns` § DOM and rendering (Pattern 2). This pattern is the React-side application — keep the two in sync.

**Impact: HIGH** — Prevents forced synchronous layouts that block the main thread.

Reading a layout property (e.g., `offsetHeight`, `getBoundingClientRect()`) after writing to the DOM forces the browser to recalculate layout synchronously. In a loop, this creates layout thrashing.

**Avoid — forces layout recalculation on every iteration:**

```tsx
function resizeCards(cards: HTMLElement[]) {
  cards.forEach(card => {
    const height = card.offsetHeight          // READ (forces layout)
    card.style.minHeight = `${height + 20}px` // WRITE (invalidates layout)
  })
}
```

**Prefer — batch all reads, then all writes:**

```tsx
function resizeCards(cards: HTMLElement[]) {
  // Read phase
  const heights = cards.map(card => card.offsetHeight)

  // Write phase
  cards.forEach((card, i) => {
    card.style.minHeight = `${heights[i] + 20}px`
  })
}
```

In React, this most commonly occurs in `useLayoutEffect` or `useEffect` callbacks that measure and mutate DOM elements. When you need to read layout inside an animation frame, use `requestAnimationFrame` to batch:

```tsx
useLayoutEffect(() => {
  const measurements = items.map(el => el.getBoundingClientRect())

  requestAnimationFrame(() => {
    items.forEach((el, i) => {
      el.style.transform = `translateY(${measurements[i].top}px)`
    })
  })
}, [items])
```

---

## 22. Animate SVG Wrappers, Not SVG Elements Directly

**Impact: MEDIUM** — Avoids repainting the entire SVG on every animation frame.

Animating properties on an SVG element itself (e.g., `<svg>` or `<path>`) triggers a full SVG repaint. Wrap the SVG in a `<div>` and animate the wrapper instead.

**Avoid — repaints entire SVG tree:**

```tsx
<motion.svg animate={{ rotate: 360 }} style={{ width: 200, height: 200 }}>
  <ComplexChart />
</motion.svg>
```

**Prefer — only the wrapper repaints:**

```tsx
<motion.div animate={{ rotate: 360 }} style={{ width: 200, height: 200 }}>
  <svg viewBox="0 0 200 200">
    <ComplexChart />
  </svg>
</motion.div>
```

This also applies to CSS animations. Use `transform` on a wrapper element rather than animating SVG attributes like `cx`, `cy`, or `d` directly.
