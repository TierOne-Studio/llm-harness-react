---
name: repo-conventions
description: Use ALWAYS when implementing, reviewing, or refactoring executable code in this repository; pair with `tdd-workflow`. ALSO use when discussing this project's architecture or frontend conventions (feature layout, state model, routing, auth flow, forms, styling, data fetching, error handling) — even on non-code turns. Documents the conventions specific to THIS React codebase (the stack, the layering, the binding choices). NOT for generic React questions (use the stack skills) or read-only investigations of unrelated codebases.
harness:
  tier: shared
  family: process
  gist: "YOUR repo's binding facts (fill-in skeleton, both tiers + seam)"
---

# Repo Conventions (React SPA)

The grounding skill for *this* repository — a standalone React SPA. Generic advice lives in the stack skills (the `react-*` family); this skill captures the **binding decisions** of *this project* — the choices a contributor cannot infer from generic best practice and must not silently deviate from. Pair it with `tdd-workflow` and `design-review` on any code change. Diverge only with explicit reason and explicit user approval.

> **How to use this skeleton:** fill in each `<!-- FILL IN: ... -->` with what *your* project actually does. Delete sections that don't apply, add ones that do. The libraries named below (Vite, React Router, Zustand, TanStack Query, React Hook Form, Zod, Tailwind, Radix/shadcn) are *illustrations* — record the ones you actually picked. Document load-bearing decisions as ADRs and cite them here for the *why*; this skill captures the *what*. See `documentation-and-adrs` for the discipline.

## 0. Domain glossary

Project-specific terms, roles, and entities a newcomer would otherwise misread. Use these terms exactly in code, tests, commits, and PR descriptions — drift ("user vs account vs member") surfaces as bugs.

<!-- FILL IN: domain terms and their meanings, e.g. "Workspace = top-level tenant; a User belongs to 1+ Workspaces; the unit of authz scoping." -->

## 1. Project layout

This is a standalone React SPA (commonly Vite). Document the top-level layout, what each directory owns, and the rule for "where does this new code go?".

A common layout:

```
<repo>/
├── src/
│   ├── app/         — root entry, layout, route table, global styles
│   ├── features/    — domain modules (each self-contained)
│   ├── components/  — cross-feature UI primitives
│   ├── shared/      — cross-feature hooks, lib, types
│   └── test/        — test setup
├── public/          — static assets served as-is
└── e2e/             — end-to-end tests (e.g. Playwright) against the running app
```

<!-- FILL IN: your actual layout, the dev/build/test scripts at the root, and the placement rule (which directory owns a new concern). Note any import rules (e.g. features may import shared but never each other's internals). -->

**Guidance worth keeping — the API seam:** the app talks to its backend over an HTTP contract. Keep the *types* of that contract in one place (§ 11) so a breaking change is a compile error, not a runtime surprise.

## 2. Stack at a glance

The libraries and versions that define how the app is built. Be specific — version-major matters (React Router 6 vs 7, Tailwind 3 vs 4).

### Frontend

| Concern | Choice |
|---|---|
| Build tool / dev server | <!-- FILL IN: e.g. Vite --> |
| UI library | <!-- FILL IN: e.g. React 19 --> |
| Routing | <!-- FILL IN --> |
| Client state | <!-- FILL IN --> |
| Server cache | <!-- FILL IN --> |
| Forms + validation | <!-- FILL IN --> |
| Styling | <!-- FILL IN --> |
| Unit/component tests | <!-- FILL IN --> |

### Cross-cutting

- **Auth:** <!-- FILL IN: the end-to-end flow — how a session is established, where the credential lives in the browser, how it's attached to API requests, how the API verifies it. Document it once here. -->
- **API contract:** <!-- FILL IN: where the API types come from and how they're consumed (see § 11). -->

## 3. Feature / folder layout

How the source tree is organized. Most React apps converge on a **feature-folder** layout (group by domain) or a **layer** layout (group by kind). State which, and the placement rule.

```
src/
├── app/         — root entry, layout, route table, global styles
├── features/    — domain modules (each self-contained)
├── shared/      — cross-feature code (UI primitives, hooks, lib, types)
└── test/        — test setup
```

<!-- FILL IN: your actual src/ layout, the placement rule, and whether new top-level dirs need an ADR. Consumers import from a feature's index.ts, not internal sub-paths. -->

## 4. State management (local / context / client store / server cache)

The single most error-prone decision in a React app is *where state lives*. A common four-layer model:

| Layer | Where | When |
|---|---|---|
| Local | `useState`/`useReducer` | Default. Only this component cares. |
| Lifted | Common ancestor via props | 2+ siblings need the same value. |
| Context | React Context provider | App-wide, low-frequency (theme, current user). |
| Client store | e.g. Zustand/Redux | Truly app-wide, frequently-updated client state. |
| Server cache | e.g. TanStack Query | All server state — the source of truth for fetched data. |

**Guidance worth keeping:** server data belongs in the server-cache layer, not duplicated into a client store. With a selector-based store, subscribe via selectors (read one slice) to avoid over-rendering.

<!-- FILL IN: which layers you use, your store location/name, and the rule for promoting local → context → store. -->

## 5. Routing + route guards

<!-- FILL IN: where the route table lives, your guard components, the auth/RBAC pattern, code-splitting policy. -->

**Guidance worth keeping — defense in depth:** route guards are a UX affordance, **not** a security boundary. A guard keeps unauthorized users out of the UI, but **the API must still authorize every request**. Never treat a client-side guard as the only check. Centralize permission logic in the guard — don't scatter `if (user.role === ...)` across route components.

## 6. Forms + validation

<!-- FILL IN: form library, validation library, where schemas live, your field/error display pattern. -->

**Guidance worth keeping:** validate on the client for UX, but the **server re-validates** — client validation is never the trust boundary. Wire `aria-invalid` / `aria-describedby` so errors are announced to assistive tech. Prefer the form library's submit handler over hand-rolled `preventDefault` + manual validation. Where possible, derive the form schema from the API contract (§ 11) so client and server agree on shape.

## 7. Styling

<!-- FILL IN: styling approach, component primitive layer, variant strategy, dark-mode mechanism, where the class-merge helper lives. -->

**Guidance worth keeping:** wrap accessible primitives (e.g. Radix/shadcn) rather than rolling your own dialog/menu/tooltip — you get focus trap, ARIA, and keyboard handling for free. With utility classes, a class-merge helper (`clsx` + `tailwind-merge`) avoids conflicting-class bugs; a variant library (e.g. CVA) keeps variants declarative. Keep design tokens in one place.

## 8. Auth + token storage (frontend side)

<!-- FILL IN: where the token/session lives in the browser, how it's attached to API requests, where session/role helpers live. (The end-to-end auth flow is in § 2 "Cross-cutting".) -->

**Guidance worth keeping (security-critical):**
- **Never hardcode secrets in client code** — anything shipped to the browser is public. Client env vars (e.g. `VITE_*`) are visible to every user; put no secrets there.
- Token-in-`localStorage` is convenient but XSS-readable; httpOnly cookies resist XSS but require CSRF defense. State your choice and its tradeoff explicitly (cite an ADR).
- Attach the credential in **one** place (an interceptor or the auth client), not ad hoc per call.

## 9. Data fetching (talking to the API)

<!-- FILL IN: HTTP client, where service/fetch functions live, query-key conventions, mutation + invalidation pattern, the API base-URL env var (e.g. VITE_API_URL). -->

**Guidance worth keeping:**
- **Type requests and responses from the API contract** (§ 11), not hand-redeclared interfaces — the shape you send is rarely the shape you get back; model them as distinct types.
- Wrap fetches in named hooks/services, not inline calls in components, so the key, fetch fn, and caching policy live in one place.
- Namespace cache keys per feature so you can invalidate without collateral damage.
- Avoid blind client-side retry loops; only retry genuinely idempotent operations.

## 10. Error handling

<!-- FILL IN: error-boundary placement, toast/notification library, how async/fetch errors are rendered. -->

**Guidance worth keeping:** use an error boundary to contain render-time crashes and wrap route/feature trees with it. Surface async errors as visible UI state — don't catch-and-ignore. Map the API's error contract to user-facing messages in one place. Use one notification mechanism, not several in parallel.

## 11. API contract — the type seam with the backend

A standalone SPA still consumes an HTTP API. Keep the frontend's knowledge of that API in one typed place instead of redeclaring shapes by hand.

<!-- FILL IN: where the API types live — a generated client (e.g. openapi-typescript / orval), a published types package, or a hand-maintained types module under src/shared — and how they're regenerated/updated when the API changes. -->

**Guidance worth keeping:**
- Derive request/response types from the API contract — hand-redeclared shapes drift, and a breaking change becomes a runtime surprise instead of a compile error.
- Treat a contract change as a coordination event with the backend: update the contract types and every consumer in the same change.
- If this repo pairs with a sibling backend repo, see `cross-repo-workspace` for working across both.

## 12. Testing

| Layer | Common tooling | Lives in |
|---|---|---|
| unit/component | Vitest + Testing Library | co-located `*.test.tsx` |
| end-to-end | Playwright | top-level `e2e/` |

<!-- FILL IN: your runners + config locations, the unit/component/e2e split, where the Playwright suite lives, the coverage commands, and the root npm scripts. -->

**Guidance worth keeping:**
- Query by accessible attributes first (role → label → text), test-ids last; prefer user-event over low-level fire-event; wait on UI/network state, **no arbitrary sleeps**.
- **Always test the unauthorized/failure path** — guard bypass, expired session, network error, empty state.
- The `e2e/` suite proves the app works against the real API — keep at least a smoke path green.

## 13. Naming conventions

State the naming rules so the codebase stays scannable.

<!-- FILL IN: file casing (PascalCase components? kebab-case files?), hook naming, type naming, test file naming. --> Common defaults: hooks are `useX` and read like sentences (`useUserProfile`, not `useGetUser`); components are PascalCase.

Avoid `Manager`/`Helper`/`Util` as primary suffixes — they signal fuzzy responsibility (see `design-review` anti-patterns).

## 14. Anti-patterns (don't do these here)

<!-- FILL IN: your repo's real, observed anti-patterns. Common candidates worth keeping if they apply: -->

- Don't duplicate server state into a client store — let the server cache own it.
- Don't put permission/role checks inline in route components — centralize in the guard.
- Don't roll your own dialog/menu/tooltip — wrap an accessible primitive.
- Don't store secrets in client-side env vars.
- Don't hand-redeclare an API type instead of importing it from the contract source (§ 11).
- Don't adapt fetch code to a breaking API change without updating the contract types.

## 15. When to deviate

No convention is absolute. Small in-scope deviations are fine with a comment explaining why. **Structural** changes (a new top-level directory, a new state library, a new auth mechanism, a new API-contract shape) are load-bearing decisions — document them as an ADR and cite it here, rather than restating the rationale inline. State the deviation explicitly in the response, name the reason, and propose updating this skill in the same change. NEVER deviate silently.

## Cross-references

- Frontend stack skills (`react-patterns`, `react-state-management`, `react-routing`, `react-forms`, `react-data-fetching`, `react-performance`, `accessibility`, `frontend-security`, `bundle-size`, `vite`, `vitest`, `shadcn`, `tailwind-v4-shadcn`, `playwright-best-practices`) — generic advice not specific to this repo.
- `tdd-workflow`, `design-review`, `plan-mode`, `cross-repo-workspace` — process skills.
- `documentation-and-adrs` — ADR format and citation flow.
