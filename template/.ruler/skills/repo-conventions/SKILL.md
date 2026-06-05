---
name: repo-conventions
description: Use ALWAYS when implementing, reviewing, or refactoring executable code in this repository; pair with `tdd-workflow`. ALSO use when discussing this project's architecture, feature/folder layout, state model, routing, auth flow, forms, styling, data fetching, error handling, or any repo-specific decision — even on non-code turns. Documents the conventions specific to THIS React codebase (the stack, the layering, the binding choices). NOT for generic React questions (use the React-stack skills) or read-only investigations of unrelated codebases.
---

# Repo Conventions

The grounding skill for *this* codebase. Generic React advice lives in the React-stack skills; this skill captures the **binding decisions** of *this project* — the choices a contributor cannot infer from generic best practice and must not silently deviate from.

> **How to use this skeleton:** fill in each `<!-- FILL IN: ... -->` with what *your* project actually does. Delete sections that don't apply, add ones that do. The examples below name common libraries (React Router, Zustand, TanStack Query, React Hook Form, Zod, Tailwind, Radix, CVA, better-auth, Vite, Vitest, Testing Library, Playwright) only as *illustrations* — record the ones you actually picked. Document load-bearing decisions as ADRs and cite them here for the *why*; this skill captures the *what*.

## 0. Domain glossary

Project-specific terms, roles, and entities a newcomer would otherwise misread. Define them once here so they're not re-explained per file.

<!-- FILL IN: domain terms and their meanings, e.g. "Workspace = top-level tenant; a User belongs to 1+ Workspaces" -->

## 1. Stack at a glance

The libraries and versions that define how this app is built. Be specific — version-major matters (React Router 6 vs 7, Tailwind 3 vs 4).

<!-- FILL IN: build tool (e.g. Vite), React version, router, state libs, data-fetching, forms, validation, styling, component primitives, auth, test stack -->

| Concern | Choice |
|---|---|
| Build tool / dev server | <!-- FILL IN: e.g. Vite --> |
| UI library | <!-- FILL IN: e.g. React 19 --> |
| Routing | <!-- FILL IN --> |
| Client state | <!-- FILL IN --> |
| Server cache | <!-- FILL IN --> |
| Forms + validation | <!-- FILL IN --> |
| Styling | <!-- FILL IN --> |
| Auth | <!-- FILL IN --> |
| Unit/component tests | <!-- FILL IN --> |
| E2E tests | <!-- FILL IN --> |

## 2. Feature / folder layout

How the source tree is organized and where new code goes. Most React apps converge on either a **feature-folder** layout (group by domain) or a **layer** layout (group by kind). State which one, and the rule for "where does this new file go?"

<!-- FILL IN: your top-level src/ layout and the placement rule -->

Generic example of a feature-folder layout:

```
src/
├── app/         — root entry, layout, route table, global styles
├── features/    — domain modules (each self-contained)
├── shared/      — cross-feature code (UI primitives, hooks, lib, types)
└── test/        — test setup
```

```
features/<Feature>/
├── components/  — feature-private components
├── hooks/       — feature-private hooks
├── views/       — page/route-level components
├── services/    — API clients / data transformers (non-UI)
├── schemas/     — validation schemas (when forms exist)
└── index.ts     — public surface (re-exports)
```

**Placement rule (example):** new code goes in a feature folder unless genuinely shared by 2+ features (then `shared/`). Consumers import from the feature's `index.ts`, not internal sub-paths — keeps the public surface explicit.

<!-- FILL IN: your actual placement and import rules; whether new top-level dirs need an ADR -->

## 3. State management (local / context / client store / server cache)

The single most error-prone decision in a React app is *where state lives*. Document your layering so contributors don't reach for a global store when local state suffices, or cache server data in a client store.

A common four-layer model:

| Layer | Where | When |
|---|---|---|
| Local | `useState`/`useReducer` in the component | Default. Only this component cares. |
| Lifted | Common ancestor via props/callbacks | 2+ siblings need the same value. |
| Context | React Context provider | App-wide, low-frequency (theme, current user). |
| Client store | e.g. Zustand/Redux | Truly app-wide, frequently-updated client state. |
| Server cache | e.g. TanStack Query | All server state — the source of truth for fetched data. |

**Guidance worth keeping:** server data belongs in the server-cache layer, not duplicated into a client store. If using a selector-based store, subscribe via selectors (read one slice) rather than the whole store, to avoid over-rendering.

<!-- FILL IN: which layers you use, your store location/name, and the rule for promoting local → context → store -->

## 4. Routing + route guards

Where routes are defined and how access control is enforced at the routing layer.

<!-- FILL IN: where the route table lives, your guard components, the auth/RBAC pattern, code-splitting policy -->

**Guidance worth keeping — defense in depth:** route guards are a UX affordance, not a security boundary. A guard component (call it whatever you like, e.g. `<ProtectedRoute>` for auth or `<AdminRoute>` for role-gated routes) keeps unauthorized users out of the UI, but the **server must still authorize every request**. Never treat a client-side guard as the only check. Centralize permission logic in the guard — don't scatter `if (user.role === ...)` checks inside individual route components.

Generic example:

```tsx
<Route element={<ProtectedRoute />}>
  <Route path="/dashboard" element={<Dashboard />} />
  <Route element={<AdminRoute requiredPermission="admin:read" />}>
    <Route path="/admin" element={<AdminPanel />} />
  </Route>
</Route>
```

## 5. Forms + validation

How forms are built and validated. Pick a validation source of truth (a schema library is recommended) and a form-state approach, then make them consistent across the app.

<!-- FILL IN: form library, validation library, where schemas live, your field/error display pattern -->

Generic example with a schema + form-state library:

```tsx
const schema = z.object({ email: z.string().email() });
const form = useForm({ resolver: zodResolver(schema), mode: 'onSubmit' });
```

**Guidance worth keeping:** validate on the client for UX, but the server re-validates — client validation is never the trust boundary. Wire `aria-invalid` / `aria-describedby` so errors are announced to assistive tech. Use the library's submit handler rather than hand-rolling `preventDefault` + manual validation.

## 6. Styling

The styling system and the rules that keep it consistent (utility classes, CSS modules, CSS-in-JS, a component library, design tokens).

<!-- FILL IN: styling approach, component primitive layer, variant strategy, dark-mode mechanism, where the class-merge helper lives (if any) -->

**Guidance worth keeping:** wrap accessible primitives (e.g. Radix) rather than rolling your own dialog/menu/tooltip — you get focus trap, ARIA, and keyboard handling for free. If you use utility classes with conditional composition, a class-merge helper (e.g. `clsx` + `tailwind-merge`) avoids conflicting-class bugs. A variant library (e.g. CVA) keeps component variants declarative. Keep design tokens in one place.

## 7. Auth + token storage

How a session is established and where the credential lives. This is a security-critical surface — be explicit.

<!-- FILL IN: auth library/flow, where the token/session is stored, how it's attached to requests, where session/role helpers live -->

**Guidance worth keeping (security-critical):**
- **Never hardcode secrets in client code** — anything shipped to the browser is public. Client env vars (e.g. `VITE_*`) are visible to every user; put no secrets there.
- Token-in-`localStorage` is convenient but XSS-readable; httpOnly cookies resist XSS but require CSRF defense. State your choice and its tradeoff explicitly (cite an ADR).
- Attach the credential in one place (an interceptor or the auth client), not ad hoc per call.

## 8. Data fetching

How the app talks to the backend and where that code lives.

<!-- FILL IN: HTTP client, where service/fetch functions live, query-key conventions, mutation + invalidation pattern, base URL env var -->

**Guidance worth keeping:**
- **Separate request and response types.** The shape you send is rarely the shape you get back — model them as distinct types rather than one bidirectional interface.
- Wrap fetches in named hooks/services rather than inline calls in components, so the key, fetch fn, and caching policy live in one place.
- Namespace cache keys per feature so you can invalidate a feature's data without collateral damage.
- Avoid blind client-side retry loops; only retry genuinely idempotent operations.

## 9. Error handling

How errors surface to the user and how they're contained.

<!-- FILL IN: error-boundary placement, toast/notification library, how async/fetch errors are rendered -->

**Guidance worth keeping:** use an error boundary to contain render-time crashes (React requires a class component or a library wrapper for this) and wrap route/feature trees with it. Surface async errors as visible UI state — don't catch-and-ignore. Use one notification mechanism, not several in parallel.

## 10. Testing

The test stack and the unit / component / e2e split.

<!-- FILL IN: test runner, component-testing library, e2e tool, where tests live, coverage command, the npm scripts -->

**Guidance worth keeping:**
- Query by accessible attributes first (role → label → text), test-ids last — tests then mirror how users and assistive tech find elements.
- Prefer user-event simulation over low-level fire-event.
- Use stable selectors and wait on UI/network state; **no arbitrary sleeps**.
- **Test the unauthorized/failure path**, not just the happy path — guard bypass, expired session, network error, empty state.

## 11. Naming conventions

The naming rules that keep the codebase scannable.

<!-- FILL IN: file casing (PascalCase components? kebab-case files?), hook naming, type naming, test file naming -->

Common defaults: hooks are `useX` (camelCase) and read like sentences (`useUserProfile`, not `useGetUser`); components are PascalCase; one export convention per file (don't mix default and named haphazardly).

## 12. Anti-patterns (don't do these here)

Project-specific traps. Be concrete — "don't do X, do Y instead."

<!-- FILL IN: your repo's specific anti-patterns -->

Common ones worth keeping:
- Don't duplicate server state into a client store — let the server cache own it.
- Don't put permission/role checks inline in route components — centralize in the guard.
- Don't roll your own dialog/menu/tooltip — wrap an accessible primitive.
- Don't store secrets in client-side env vars.
- Don't add a parallel library for a concern that already has one (toasts, date utils, etc.).

## 13. When to deviate

No convention is absolute. State the process for going off-pattern so deviations are deliberate, not accidental.

<!-- FILL IN: your deviation process -->

Default: small in-scope deviations are fine with a comment explaining why. **Structural** changes (a new top-level dir, a new state library, a new auth mechanism, a new routing approach) are load-bearing decisions — document them as an ADR and cite the ADR here, rather than restating the rationale inline.

## Cross-references

- The generic React-stack skills (patterns, state management, routing, forms, testing, performance) — for advice not specific to this repo.
- The quality-bar skills (accessibility, frontend-security, bundle-size) — for the cross-cutting bar.
- `tdd-workflow`, `design-review`, `plan-mode` — process skills.
- `documentation-and-adrs` — ADR format and citation flow.
