# SSR Hydration & Resource Loading

Patterns for hydration-safe rendering and getting critical resources loading earlier — especially in Vite SPAs without framework-level prefetching. (Patterns 15, 23, 24 from the catalog.)

---

## 15. Prevent Hydration Flicker for Client-Only Data

**Impact: MEDIUM** — Eliminates flash of wrong content during SSR hydration.

When rendering depends on client-only data (localStorage, cookies), an inline script can set the correct value before React hydrates — avoiding both SSR errors and a visible flash.

```tsx
function ThemeRoot({ children }: { children: React.ReactNode }) {
  return (
    <>
      <div id="app-root">{children}</div>
      <script
        dangerouslySetInnerHTML={{
          __html: `(function(){
            try {
              var t = localStorage.getItem('theme') || 'light';
              document.getElementById('app-root').dataset.theme = t;
            } catch(e) {}
          })();`,
        }}
      />
    </>
  )
}
```

This approach works in any SSR setup — Next.js, Remix, or a custom Vite SSR pipeline.

---

## 23. Suppress Expected Hydration Mismatches

**Impact: LOW-MEDIUM** — Silences known-safe warnings without hiding real bugs.

Some content is intentionally different between server and client — timestamps, random IDs, user-agent-specific rendering. Use `suppressHydrationWarning` on those specific elements.

```tsx
function Comment({ createdAt }: { createdAt: Date }) {
  return (
    <article>
      <p>{comment.body}</p>
      <time suppressHydrationWarning>
        {formatRelativeTime(createdAt)} {/* "2 minutes ago" differs server vs client */}
      </time>
    </article>
  )
}
```

Apply sparingly and only on leaf elements. Never suppress warnings on container elements — it masks real mismatches in children.

---

## 24. React DOM Resource Hints for Vite SPAs

**Impact: HIGH** — Lets the browser start loading critical resources earlier without framework support.

React 19 adds `preload()` and `preinit()` from `react-dom` — imperative resource hints that work in any React app. In Vite SPAs (which don't get framework-level prefetching), these are especially valuable.

```tsx
import { preload, preinit } from 'react-dom'

function App() {
  // Preload a font before it's needed
  preload('/fonts/inter-var.woff2', { as: 'font', type: 'font/woff2', crossOrigin: 'anonymous' })

  // Preinit a critical CSS file (loads + applies it)
  preinit('/critical.css', { as: 'style' })

  return <RouterProvider router={router} />
}
```

**On navigation — preload the next page's data and code:**

```tsx
function ProductLink({ id }: { id: string }) {
  const handleHover = () => {
    // Preload the image the next page will need
    preload(`/api/products/${id}/image.webp`, { as: 'image' })
    // Prefetch the route code
    import('./pages/ProductDetail')
  }

  return <Link to={`/products/${id}`} onMouseEnter={handleHover}>View</Link>
}
```

These are no-ops if the resource is already loaded, so calling them eagerly is safe. For Vite apps without a meta-framework, this is the primary mechanism for resource prioritization.
