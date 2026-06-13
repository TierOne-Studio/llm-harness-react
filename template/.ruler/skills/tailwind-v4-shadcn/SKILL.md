---
name: tailwind-v4-shadcn
description: |
  Production-tested setup for Tailwind CSS v4 with shadcn/ui, Vite, and React.

  Use when: initializing React projects with Tailwind v4, setting up shadcn/ui,
  implementing dark mode, debugging CSS variable issues, fixing theme switching,
  migrating from Tailwind v3, or encountering color/theming problems.

  Covers: @theme inline pattern, CSS variable architecture, dark mode with
  ThemeProvider, component composition, vite.config setup, common v4 gotchas,
  and production-tested patterns.

  Keywords: Tailwind v4, shadcn/ui, @tailwindcss/vite, @theme inline, dark mode,
  CSS variables, hsl() wrapper, components.json, React theming, theme switching,
  colors not working, variables broken, theme not applying, @plugin directive,
  typography plugin, forms plugin, prose class, @tailwindcss/typography,
  @tailwindcss/forms
license: MIT
harness:
  tier: frontend
  family: frontend-platform
  gist: "Tailwind v4 + shadcn setup, theming, dark mode (index + topics)"
---

# Tailwind v4 + shadcn/ui Production Stack

**Production-tested**: WordPress Auditor (https://wordpress-auditor.webfonts.workers.dev)
**Last Updated**: 2025-12-04
**Status**: Production Ready ✅

Index skill for the Tailwind v4 + shadcn/ui + Vite + React stack. The full guidance lives in `topics/` — read this SKILL.md to identify which topic applies, then read that topic file for the depth. Deeper material (gotchas, dark-mode code, migration, plugins, advanced patterns) lives in `references/`, and copy-paste starting files live in `templates/`; the topic files tell you when to load each.

## Topics (index)

| Situation | Read |
|---|---|
| Initializing a project, installing deps, vite.config / components.json setup, setup checklist, which packages to (never) install, `@plugin` directive for Typography/Forms | [topics/setup-and-config.md](topics/setup-and-config.md) |
| CSS variable architecture (`@theme inline` four-step pattern), dark mode with ThemeProvider, the full ✅/❌ critical rules, semantic color tokens | [topics/theming-and-dark-mode.md](topics/theming-and-dark-mode.md) |
| "Colors not working" / theme not switching / build fails, file templates, advanced custom colors, v3 migration, when to load each `references/*.md`, official docs links | [topics/troubleshooting-and-reference.md](topics/troubleshooting-and-reference.md) |

## Quick decision tree

```
Setting up a new project or adding plugins?        → topics/setup-and-config.md
Wiring CSS variables, theming, or dark mode?       → topics/theming-and-dark-mode.md
Something broken, or need deeper reference docs?   → topics/troubleshooting-and-reference.md
```

## Cross-cutting rules of thumb (the load-bearing essentials)

The four-step architecture is **mandatory** — skipping steps breaks the theme:

1. Define CSS variables in `:root` / `.dark` **at root level** (never inside `@layer base`), with `hsl()` wrapper: `--background: hsl(0 0% 100%);`
2. Map every variable in `@theme inline`: `--color-background: var(--background);` — without this, `bg-background` etc. won't exist.
3. In `@layer base`, reference variables **unwrapped**: `var(--background)`, never `hsl(var(--background))` (double-wrap = colors all black/white).
4. Use semantic utilities (`bg-background text-foreground`) — no `dark:` variants needed; the theme switches automatically.

Config essentials:

- Use the `@tailwindcss/vite` plugin (NOT PostCSS); `components.json` must have `"tailwind": { "config": "" }`; **delete `tailwind.config.ts`** — v4 ignores it and its presence breaks the build.
- Never install `tailwindcss-animate` or `tw-animate-css` (deprecated/nonexistent in v4).
- Plugins use the `@plugin` directive in CSS (`@plugin "@tailwindcss/typography";`), not `@import` or `require()`.
- `@apply` is deprecated in v4; use `cn()` from `@/lib/utils` for conditional classes.

**For AI agents**: explicitly state you're using this skill, follow its patterns over general knowledge, and check `references/common-gotchas.md` before guessing — full activation notes in `topics/setup-and-config.md`.
