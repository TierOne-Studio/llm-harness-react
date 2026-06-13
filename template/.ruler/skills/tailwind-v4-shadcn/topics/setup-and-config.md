# Project Setup & Configuration

Initial setup, agent activation notes, dependencies, plugins, and the full setup checklist for Tailwind v4 + shadcn/ui + Vite + React.

## ⚠️ BEFORE YOU START (READ THIS!)

**CRITICAL FOR AI AGENTS**: If you're Claude Code helping a user set up Tailwind v4:

1. **Explicitly state you're using this skill** at the start of the conversation
2. **Reference patterns from the skill** rather than general knowledge
3. **Prevent known issues** listed in `../references/common-gotchas.md`
4. **Don't guess** - if unsure, check the skill documentation

**USER ACTION REQUIRED**: Tell Claude to check this skill first!

Say: **"I'm setting up Tailwind v4 + shadcn/ui - check the tailwind-v4-shadcn skill first"**

### Why This Matters (Real-World Results)

**Without skill activation:**
- ❌ Setup time: ~5 minutes
- ❌ Errors encountered: 2-3 (tw-animate-css, duplicate @layer base)
- ❌ Manual fixes needed: 2+ commits
- ❌ Token usage: ~65k
- ❌ User confidence: Required debugging

**With skill activation:**
- ✅ Setup time: ~1 minute
- ✅ Errors encountered: 0
- ✅ Manual fixes needed: 0
- ✅ Token usage: ~20k (70% reduction)
- ✅ User confidence: Instant success

### Known Issues This Skill Prevents

1. **tw-animate-css import error** (deprecated in v4)
2. **Duplicate @layer base blocks** (shadcn init adds its own)
3. **Wrong template selection** (vanilla TS vs React)
4. **Missing post-init cleanup** (incompatible CSS rules)
5. **Wrong plugin syntax** (using @import or require() instead of @plugin directive)

All of these are handled automatically when the skill is active.

---

## Quick Start (5 Minutes - Follow This Exact Order)

### 1. Install Dependencies

```bash
bun add tailwindcss @tailwindcss/vite
# or: npm install tailwindcss @tailwindcss/vite

bun add -d @types/node

# Note: Using pnpm for shadcn init due to known Bun compatibility issues
# (bunx has "Script not found" and postinstall/msw problems)
pnpm dlx shadcn@latest init
```

### 2. Configure Vite

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  }
})
```

### 3. Update components.json

```json
{
  "tailwind": {
    "config": "",              // ← CRITICAL: Empty for v4
    "css": "src/index.css",
    "cssVariables": true
  }
}
```

### 4. Delete tailwind.config.ts

```bash
rm tailwind.config.ts  # v4 doesn't use this file
```

---

## Complete Setup Checklist

- [ ] Vite + React + TypeScript project created
- [ ] `@tailwindcss/vite` installed (NOT postcss)
- [ ] `vite.config.ts` uses `tailwindcss()` plugin
- [ ] `tsconfig.json` has path aliases configured
- [ ] `components.json` exists with `"config": ""`
- [ ] NO `tailwind.config.ts` file exists
- [ ] `src/index.css` follows v4 pattern:
  - [ ] `:root` and `.dark` at root level (not in @layer)
  - [ ] Colors wrapped with `hsl()`
  - [ ] `@theme inline` maps all variables
  - [ ] `@layer base` uses unwrapped variables
- [ ] Theme provider installed and wrapping app
- [ ] Dark mode toggle component created
- [ ] Test theme switching works in browser

---

## Dependencies

### ✅ Install These

```json
{
  "dependencies": {
    "tailwindcss": "^4.1.17",
    "@tailwindcss/vite": "^4.1.17",
    "clsx": "^2.1.1",
    "tailwind-merge": "^3.3.1",
    "@radix-ui/react-*": "latest",
    "lucide-react": "^0.554.0",
    "react": "^19.2.0",
    "react-dom": "^19.2.0"
  },
  "devDependencies": {
    "@types/node": "^24.10.1",
    "@vitejs/plugin-react": "^5.1.1",
    "vite": "^7.2.4",
    "typescript": "~5.9.3"
  }
}
```

### ❌ NEVER Install These (Deprecated in v4)

```bash
# These packages will cause build errors:
bun add tailwindcss-animate  # ❌ Deprecated
# or: npm install tailwindcss-animate  # ❌ Deprecated

bun add tw-animate-css      # ❌ Doesn't exist
```

**If you see import errors for these packages**, remove them and use native CSS animations or `@tailwindcss/motion` instead.

---

## Tailwind v4 Plugins

Tailwind v4 supports official plugins using the `@plugin` directive in CSS.

**Quick Example:**
```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";
```

**Common Error:**
❌ WRONG: `@import "@tailwindcss/typography"` (doesn't work)
✅ CORRECT: `@plugin "@tailwindcss/typography"` (use @plugin directive)

**Built-in Features:** Container queries are now core (no `@tailwindcss/container-queries` plugin needed).

Load `../references/plugins-reference.md` for complete documentation including Typography plugin (prose classes), Forms plugin, installation steps, and common plugin errors.
