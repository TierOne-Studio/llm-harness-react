---
name: react-data-fetching
description: Teaches modern React data fetching patterns with TanStack Query, SWR, and Suspense. Use when implementing caching, deduplication, optimistic updates, or parallel loading in React applications.
context: fork
allowed-tools: Read, Grep, Glob
paths:
  - "**/*.tsx"
  - "**/*.jsx"
license: MIT
metadata:
  author: patterns.dev
  version: "1.1"
related_skills:
  - "react-design-patterns"
harness:
  tier: frontend
  family: react-core
  gist: "Server data: caching, invalidation, optimistic updates — 11 patterns (index + topics)"
---

# React Data Fetching Patterns

Index skill for production-ready patterns for fetching, caching, and synchronizing server data in React applications. These patterns are framework-agnostic — they work whether you're using Vite + React Router, Next.js, Remix, or a custom setup. Each theme has its own file in [topics/](topics/) with full explanations and code examples.

Read this SKILL.md to identify which topic applies; then read the specific topic file for the depth.

## When to Use

Reference these patterns when:
- Adding data fetching to components
- Replacing `useEffect` + `fetch` with a proper data layer
- Implementing caching, deduplication, or optimistic updates
- Debugging waterfall loading patterns
- Choosing between data fetching libraries

## Instructions

- Apply these patterns during code generation, review, and refactoring. When you see fetch-in-effect without caching or deduplication, suggest the appropriate pattern.

## Overview

The most common performance problem in React apps is **request waterfalls** — sequential fetches that could run in parallel. The second most common problem is **redundant fetches** — multiple components fetching the same data independently. The topics below address both, starting with the highest-impact fixes.

## Topics (index)

| Situation | Depth |
|---|---|
| Sequential fetches that could run concurrently (`Promise.all`, defer-await), parent-then-child fetch waterfalls in component trees | [topics/parallel-fetching-and-waterfalls.md](topics/parallel-fetching-and-waterfalls.md) |
| Replacing `useEffect` + `fetch` with TanStack Query (or SWR), QueryClient setup, optimistic updates for mutations | [topics/tanstack-query-and-mutations.md](topics/tanstack-query-and-mutations.md) |
| Declarative loading states with `<Suspense>` / `useSuspenseQuery`, prefetching on hover/focus or via route loaders | [topics/suspense-and-prefetching.md](topics/suspense-and-prefetching.md) |
| Server-side dedup with `React.cache()`, shared global event listeners (`useSyncExternalStore`), passive scroll/touch listeners, schema-versioned localStorage | [topics/server-dedup-listeners-storage.md](topics/server-dedup-listeners-storage.md) |

## Cross-Cutting Rules

1. **Never fetch sequentially what can run in parallel** — waterfalls (in `async` functions or component trees) are the #1 performance problem. Fetch sibling data at the same level or in a route loader.
2. **Never ship raw `useEffect` + `fetch` for server state** — use TanStack Query (recommended for Vite apps) or SWR to get deduplication, stale-while-revalidate caching, retries, and background refresh. Server state lives in the query cache, never mirrored into `useState` or Zustand — canonical in `react-state-management` § Hard rules.
3. **Start promises early, await late** — kick off independent fetches immediately; `await` only at the point where the value is read.
4. **Prefer Suspense boundaries over per-component `isLoading` flags** — use separate boundaries for independent sections so they load independently.
5. **Optimistic updates need rollback** — snapshot previous cache state in `onMutate`, restore it in `onError`, and invalidate in `onSettled`.
6. **Use primitive arguments for `React.cache()` keys** — inline objects create new references and cause cache misses on every call.
7. **Validate anything read from client storage** — schema-version localStorage data and fall back to defaults on mismatch or parse failure.

## Source

Patterns from [patterns.dev](https://www.patterns.dev/) — framework-agnostic React data fetching guidance for the broader web engineering community.
