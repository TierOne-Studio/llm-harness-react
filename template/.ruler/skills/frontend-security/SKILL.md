---
name: frontend-security
description: Use when reviewing or implementing anything on a React SPA's security surface — XSS sinks (`dangerouslySetInnerHTML`, raw `react-markdown`, third-party HTML), token storage, env-var leakage (`VITE_*`), CSP, dependency audit, postMessage origin checks, URL parameter handling that affects auth state, file upload/download flows, and OAuth/redirect flows. Force-fire on diffs touching auth, tokens, user-supplied HTML, or env vars. NOT for pure visual styling changes with no DOM-injection or auth surface, pure data-shape refactors that don't cross a trust boundary, or backend-only audits.
harness:
  tier: frontend
  family: frontend-platform
  gist: "XSS sinks, `VITE_*` leakage, token storage"
---

# Frontend Security

A SPA's attack surface is small but unforgiving. The big risks are XSS (any user-supplied HTML can pwn the session if dangerously rendered), token leakage (every `VITE_*` is shipped to every browser), and weakened guards (a route guard such as `<ProtectedRoute>` removed in a refactor). This skill encodes the patterns and the audit checklist.

## When this fires

- A diff touches auth code, sign-in/up flows, token storage, or an auth hook (e.g. `useAuth`).
- A diff renders user-supplied content (markdown, HTML, embeds).
- A diff adds or modifies a `VITE_*` env var.
- A diff adds an external `<iframe>`, `postMessage` listener, or third-party SDK.
- A diff weakens or rewrites a route guard.
- A code review on a PR touching the auth client or auth context.

## Hard rules

1. **Never put secrets in `VITE_*` vars.** Anything prefixed `VITE_` is bundled into client JS and shipped publicly. Allowed: API base URLs, public anon keys (Supabase, Firebase config), feature flags. Forbidden: API keys, JWT secrets, OAuth client secrets, third-party admin tokens.

2. **Pick a token-storage model deliberately and document it.** A common choice is a bearer token in `localStorage` (e.g. via a library like better-auth) — this trades XSS exposure for cross-origin simplicity. Document YOUR token-storage decision in `repo-conventions` and don't introduce a parallel/competing store. Token rotation, sign-out across tabs, and expiry handling should all flow through one source of truth (your auth library's built-in events).

3. **No raw HTML injection.** `dangerouslySetInnerHTML` is allowed only with an explicit sanitization step (DOMPurify, or `react-markdown` with the default sanitizer plugin). Document the sanitizer choice inline.

4. **Don't log credentials, tokens, or PII.** Console errors visible to the user/devtools must redact these. `JSON.stringify(formData)` with a password field in dev is still a leak in production logs.

5. **Route guards are security boundaries.** A change to a route guard (e.g. `<ProtectedRoute>` or an RBAC guard) MUST trigger `security-reviewer`. Removing a guard "because the API enforces it server-side" is correct in spirit but wrong in practice — defense in depth.

6. **External iframes / postMessage need origin checks.** A `window.addEventListener('message', ...)` MUST validate `event.origin` against a whitelist. Without that, any page can send your handler messages.

7. **`npm audit` is informational, not actionable in isolation.** A high-severity advisory in a transitive devDep that runs in CI only is not the same as a runtime advisory in `react-router-dom`. Triage by reach.

## Audit checklist (run on diffs flagged as high-risk)

Read the diff with each of these in mind:

```
[ ] Any new VITE_* env var? Is it actually safe to ship to every browser?
[ ] Any new dangerouslySetInnerHTML? Sanitization step explicit?
[ ] Any new third-party script tag? Domain trusted? Subresource Integrity?
[ ] Any change to auth-token read/write paths?
[ ] Any change to a route guard (e.g. `<ProtectedRoute>`, an RBAC guard, auth-hook gates)?
[ ] Any postMessage listener? Origin check present?
[ ] Any URL parameter that affects session state (e.g., `?org=...` switching org without re-auth)?
[ ] Any console.log of an object that contains a token, password, or PII?
[ ] Any new dependency? Bundle size justified, advisories checked?
[ ] Any iframe with user-controllable src? `sandbox` attribute correct?
```

## Patterns

### Sanitize markdown via `react-markdown`

`react-markdown` with the default plugin set sanitizes by default. Don't add `rehype-raw` (which allows arbitrary HTML) without an additional `rehype-sanitize` step. If a feature genuinely needs raw HTML rendering (e.g., a docs page authored by trusted internal users), make it a documented, reviewed decision in `repo-conventions`.

### Token storage

Threat model the tradeoff before choosing. A common model is an auth client (e.g. better-auth) that stores the bearer token in `localStorage`: this trades XSS exposure (a stolen token is a session takeover until expiry) for cross-origin compatibility. The alternative — an `HttpOnly` cookie — removes the XSS read but reintroduces CSRF concerns and same-origin constraints. Whichever you pick, mitigations apply: short token lifetime, refresh on access, server-side audit log on suspicious activity. Record YOUR decision in `repo-conventions` and don't quietly switch storage models — that's an architecture change.

### Env vars in code

Reference via `import.meta.env.VITE_API_URL`. Default sensibly. Never log the full env object. The `.env.example` file documents required vars; secrets are NOT in it.

### CSP

If you add a CSP, `unsafe-inline` for scripts is a regression. Vite supports nonced or hashed inline styles via plugins; same for scripts. CSP work is its own change, and a load-bearing one — document it in `repo-conventions`.

## Anti-patterns

- **`localStorage.setItem('apiKey', '...')`.** Anything in localStorage is XSS-readable. Don't store secrets that aren't already on the bearer-token risk profile.
- **`const token = window.location.search.match(...)`** to read OAuth-state from URL without validation. State must be validated against the original request.
- **`dangerouslySetInnerHTML={{__html: userInput}}`.** Without sanitization, this is a remote-code-execution channel.
- **A page that displays an error including the full URL or query string.** Tokens leak into errors.
- **`fetch` calls with `mode: 'no-cors'` to "fix" a CORS error.** Almost certainly the wrong fix.
- **`target="_blank"` without `rel="noopener noreferrer"`.** The new tab can manipulate `window.opener`.
- **Validating user input only on the client.** Always assume the client is hostile.
- **Disabling React's escaping with `{` raw `}`.** React escapes by default; that's the point.

## Cross-references

- `react-routing` — guards as security boundaries.
- `accessibility` — `target="_blank"` rel attributes (also a UX concern).
- `repo-conventions` — your project's auth + route-guard contract, token-storage decision.
- `decision-rules` — quick fix on sensitive surface.
