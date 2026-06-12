---
name: react-2026
description: The modern React 2026 stack and its composition idioms. Use when starting a new React project or modernizing an existing one (current frameworks, build tools, routing, state management, AI integration) — and when designing component APIs, building shared UI libraries, or refactoring prop-heavy components with modern composition patterns. Depth lives in topics/ — load only the matching file. NOT for individual design-pattern depth (use react-design-patterns) or rerender cost (use react-performance).
license: MIT
metadata:
  author: patterns.dev
  version: "1.1"
harness:
  tier: frontend
  family: react-core
  gist: "The modern stack tour + composition idioms (index + topics)"
---

# React 2026 — Stack & Composition

Two complementary halves, each a self-contained topic file (original full content
preserved, frontmatter included):

| You are… | Read |
|---|---|
| Starting/modernizing a project — framework choice, build tooling, routing, state, data, AI integration: the full stack tour | `topics/stack-tour.md` |
| Designing component APIs, shared UI libraries, or refactoring prop-heavy components — modern composition idioms | `topics/composition-patterns.md` |

## Cross-cutting defaults

- **Composition before configuration:** reach for `children` and slots before adding
  another prop; a component with 10+ props is usually three components.
- The stack tour describes 2026 *defaults*, not mandates — `repo-conventions` wins on
  any conflict (P3.5).

## Cross-references

- `react-design-patterns` — the classic pattern catalog (hooks / HOC / render props / provider / compound / …).
- `react-patterns` — component fundamentals.
- `react-performance` — when composition choices show up as rerender cost.

## Source

Both topic files originate from [patterns.dev](https://www.patterns.dev/) (MIT).
