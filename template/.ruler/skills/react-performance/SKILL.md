---
name: react-performance
description: Use when investigating actual rerender cost, slow lists, oversized effects, code-splitting decisions, or Core Web Vitals issues — when judging whether a memoization change (`React.memo`, `useMemo`, `useCallback`) is justified — and when reducing unnecessary re-renders (or rerenders), improving state design to avoid keystroke-driven cascades, or diagnosing React performance issues. Carries the 25-pattern deep render-mechanics catalog in topics/ (memoization & derived state, subscriptions & effects, transitions & scheduling, DOM/lists, SSR & resource loading). NOT for general bundle-size concerns (use `bundle-size`), routing-level code splits (use `react-routing`), or server-state caching (use `react-data-fetching`).
harness:
  tier: frontend
  family: react-core
  gist: "Measurement discipline + the 25-pattern deep render-mechanics catalog (index + topics)"
---

# React Performance

Performance work in React is a measurement game, not a memoization game. Premature `useMemo` everywhere is **negative** value — it adds work, costs memory, and obscures the real bottleneck. This skill encodes the discipline.

The systematic MEASURE → IDENTIFY → FIX → VERIFY → GUARD workflow is canonical in `js-performance-patterns` § The 5-step optimization workflow; this skill applies it to React.

## When this fires

- A component is measurably slow (Profiler, DevTools, user-reported jank).
- A list has hundreds+ items and feels laggy.
- An effect is firing far more than expected.
- A bundle audit shows a too-large initial chunk.
- A code review proposes adding `useMemo`/`useCallback`/`React.memo`.

## When this does NOT fire

- "Looks fine, but I want to be safe" — that's premature optimization. Measure first.
- Bundle-tree decisions like which package to import (use `bundle-size`).
- Server-state cache settings (use `react-data-fetching`).

## Hard rules

1. **Measure first.** Profiler, `console.time`, `performance.mark`, the DevTools "Components" tab, Lighthouse for Core Web Vitals. Without a number, you can't tell whether your change helped.

2. **Default: NO `useMemo`/`useCallback`/`React.memo`.** Add only when (a) the wrapped value is genuinely expensive to compute or recreate, AND (b) the downstream dep array or memoized component depends on identity stability. Both must be true.

3. **`React.memo` doesn't compound.** Wrapping every leaf doesn't speed things up — referential equality at the leaf is irrelevant if the parent is rerendering and passing fresh props.

4. **Effect dependency arrays are not a place to be sloppy.** A missing dep is a bug. An over-included dep causes excess reruns. Both manifest as "performance" but are correctness issues.

## Patterns

### Virtualize long lists

Lists over ~100 visible items benefit from virtualization. Use `@tanstack/react-virtual` (lightweight, no extra dep tree) — render only the slice in view. Existing `react-table` integrations can wrap virtualization too.

### Code-split heavy routes

Use `React.lazy` + `<Suspense>` for routes that pull in large dependency trees (charts, editors, AI playgrounds). Pair with the route-level boundary so the rest of the app stays fast. See `react-routing` § Code splitting. Canonical splitting strategy (what to split, when) lives in `bundle-size`; this section covers the React mechanics only.

### Lazy-load on interaction or visibility

Heavy widgets (charts, video, third-party embeds) that aren't in the initial viewport can wait. Strategies: import on first interaction, import on `IntersectionObserver` visibility, prefetch during idle. (Patterns previously broken into separate skills are now folded here.)

### Stable identity for memoized children

If you're going to `React.memo` a list item, the item props must be referentially stable. That means stable callbacks (`useCallback`), stable data (don't reconstruct objects in the parent's render), and stable list keys (no index keys). Skipping any of these voids `React.memo`.

### Resource hints (preload, prefetch, preconnect)

For known-next-route assets, hint to the browser. Vite supports preload/prefetch via plugin or manual `<link>` tags. Use sparingly; over-prefetching hurts more than it helps.

### Image optimization

Use modern formats (WebP / AVIF). Set explicit `width`/`height` to avoid layout shift. Use `loading="lazy"` for below-the-fold. Vite handles asset hashing; cache-bust correctly.

### Avoid wide context for frequently-changing values

A theme context updated once per session is fine. A mouse-position context rerenders the whole subtree on every move. Move it to a ref + observer, or to a Zustand selector subscription.

## Anti-patterns

- **Memoizing values that aren't expensive.** `useMemo(() => x + 1, [x])` is slower than recomputing.
- **`useCallback` without a downstream consumer that needs identity stability.** Wasted work.
- **`React.memo` on components whose props change every render anyway.** Equality check runs, fails, component rerenders. Net loss.
- **Unmeasured optimization.** "I added `useMemo` and it feels faster." No. Profile.
- **Wide context.** Triggers cascading rerenders across the tree.
- **Hidden side effects in renders.** A `console.log` at module-top is fine; an `analytics.track()` at module-top runs on every import. Be intentional.
- **`Promise.race` for timeout** — see `async-error-handling`.

## Deep render mechanics — the 25-pattern catalog (topics/)

Patterns numbered 1–25 (from [patterns.dev](https://www.patterns.dev/), MIT), grouped by
theme. Read only the topic file(s) matching the situation:

| Situation | Patterns | Read |
|---|---|---|
| Deciding what to memoize vs derive; `useMemo`/`useCallback`/`React.memo`; redundant state; lazy `useState` init; unstable default props; components defined inside components; hoisting static JSX; splitting combined hooks | 1, 3, 4, 10, 12, 16, 20 | `topics/memoization-and-derived-state.md` |
| Re-renders from over-broad subscriptions; unstable callbacks; side effects modeled as state+effect; high-frequency values (`useRef`); effect dependency hygiene; one-time app init; stable event subscriptions | 2, 5, 6, 7, 9, 13, 14, 19 | `topics/subscriptions-and-effects.md` |
| Typing/clicking blocked by expensive updates; `startTransition`, `useDeferredValue`, transition-wrapped route navigation | 8, 17, 25 | `topics/transitions-and-scheduling.md` |
| Long lists (`content-visibility`, virtualization); layout thrashing (batched DOM reads/writes); SVG animation repaints; `&&` rendering `0`/`NaN`/`""` | 11, 18, 21, 22 | `topics/dom-rendering-and-lists.md` |
| SSR hydration flicker, `suppressHydrationWarning`, `preload()`/`preinit()` resource hints for Vite SPAs | 15, 23, 24 | `topics/ssr-and-resource-loading.md` |

Catalog rules of thumb:

- **`useMemo` vs plain `const`:** primitives and single property accesses are free — skip `useMemo`; wrap only iteration/transformation (filter/sort, building data structures, `JSON.parse`).
- **Derive, don't store:** values computable from existing state/props are computed during render, never mirrored into `useState` + `useEffect` (pattern 1 — the highest-impact fix).
- **Never define components inside components** (including inside `useMemo`/`useCallback`) — remounts the subtree and loses state every render (pattern 16).
- **Subscribe coarsely:** consume the derived boolean (`isMobile`, `isLoggedIn`), not the raw fast-changing value (pattern 2).
- **`useTransition` vs `useDeferredValue`:** wrap the update when you control the setter; wrap the consumption when the value comes from props or a library (patterns 8, 17).
- **React Compiler note:** with the compiler enabled, manual `useMemo`/`memo()`/hoisting becomes less necessary; extracting components for early returns is still valuable.

## Cross-references

- `react-state-management` — derived-state and context discipline.
- `bundle-size` — code-split, tree-shake, third-party audit.
- `js-performance-patterns` — JS-runtime-level loop and data-structure patterns.
- `react-routing` — route-level code splitting.
