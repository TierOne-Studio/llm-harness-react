---
name: react-design-patterns
description: Use when choosing or applying a React/JavaScript design pattern — custom hooks (extracting stateful logic, subscriptions, or side effects into a reusable use* function), Higher-Order Components (reading or modernizing a legacy HOC; HOC vs hook vs render props for a new cross-cutting concern), render props (headless/unstyled components exposing state to a caller-controlled render), context providers (sharing data across component trees when prop drilling becomes unwieldy), compound components (tabs, accordions, dropdowns coordinating through shared implicit state), the presentational/container split (separating data fetching and business logic from UI rendering), JavaScript module design (exports, file-private internals, tree-shaking, testability), mixins (judging legacy class-based multi-source composition), or the Proxy API (intercepting property access for instrumentation, immutability wrappers, validation). Each pattern's depth lives in patterns/<name>.md — load only the one that matches. NOT for component-shape decisions (use react-patterns), state placement (use react-state-management), or modern composition idioms (use react-2026).
harness:
  tier: frontend
  family: react-core
  gist: "Nine classic patterns — hooks, HOC, render props, provider, compound, presentational/container, module, mixin, proxy (index + patterns)"
---

# React & JS Design Patterns

Nine patterns, one entry point. Identify the pattern from the table, then read ONLY
`patterns/<name>.md` — each file is self-contained (the original full skill, frontmatter
included).

## Routing table

| You are… | Pattern | File |
|---|---|---|
| Extracting stateful logic / subscriptions / effects into a reusable `use*` function | Custom hooks | `patterns/hooks.md` |
| Reading or modernizing a legacy HOC; weighing HOC vs hook vs render props | Higher-Order Component | `patterns/hoc.md` |
| Building a headless component that hands render-time state to the caller | Render props | `patterns/render-props.md` |
| Sharing data across a tree where prop drilling got unwieldy | Provider (context) | `patterns/provider.md` |
| Building tabs / accordion / dropdown parts that coordinate implicitly | Compound components | `patterns/compound.md` |
| Separating data fetching + business logic from UI rendering | Presentational/container | `patterns/presentational-container.md` |
| Designing a non-React JS module (exports, file-private, tree-shaking) | Module | `patterns/module.md` |
| Judging legacy class-based multi-source composition | Mixin | `patterns/mixin.md` |
| Intercepting property access/assignment/calls (instrumentation, immutability, validation) | Proxy | `patterns/proxy.md` |

## Cross-cutting defaults

- **Hooks beat HOCs and render props for new code** — reach for `patterns/hoc.md` /
  `patterns/render-props.md` mainly to read, refactor, or deliberately keep existing ones.
- **Mixins and Proxy are "recognize and justify" patterns**: modern React/TS prefers
  composition; most application code never needs a Proxy.
- Pattern choice ≠ state placement — where the data lives is `react-state-management`'s
  call; the pattern only shapes how behavior is shared.

## Cross-references

- `react-patterns` — component-shape fundamentals (lifting state, refs, lists).
- `react-2026` — modern composition idioms that often replace these patterns outright.
- `react-state-management` — the four-layer model the provider pattern must respect.
