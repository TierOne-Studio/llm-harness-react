# CSS-Variable Theming & Dark Mode

The mandatory four-step CSS variable architecture, dark mode wiring with ThemeProvider, the full critical do/don't rules, and semantic color tokens.

## The Four-Step Architecture (CRITICAL)

This pattern is **mandatory** - skipping steps will break your theme.

### Step 1: Define CSS Variables at Root Level

```css
/* src/index.css */
@import "tailwindcss";

:root {
  --background: hsl(0 0% 100%);      /* ← hsl() wrapper required */
  --foreground: hsl(222.2 84% 4.9%);
  --primary: hsl(221.2 83.2% 53.3%);
  /* ... all light mode colors */
}

.dark {
  --background: hsl(222.2 84% 4.9%);
  --foreground: hsl(210 40% 98%);
  --primary: hsl(217.2 91.2% 59.8%);
  /* ... all dark mode colors */
}
```

**Critical Rules:**
- ✅ Define at root level (NOT inside `@layer base`)
- ✅ Use `hsl()` wrapper on all color values
- ✅ Use `.dark` for dark mode (NOT `.dark { @theme { } }`)

### Step 2: Map Variables to Tailwind Utilities

```css
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  /* ... map ALL CSS variables */
}
```

**Why This Is Required:**
- Generates utility classes (`bg-background`, `text-primary`)
- Without this, `bg-primary` etc. won't exist

### Step 3: Apply Base Styles

```css
@layer base {
  body {
    background-color: var(--background);  /* NO hsl() here */
    color: var(--foreground);
  }
}
```

**Critical Rules:**
- ✅ Reference variables directly: `var(--background)`
- ❌ Never double-wrap: `hsl(var(--background))`

### Step 4: Result - Automatic Dark Mode

```tsx
<div className="bg-background text-foreground">
  {/* No dark: variants needed - theme switches automatically */}
</div>
```

---

## Dark Mode Setup

### 1. Create ThemeProvider

See `../references/dark-mode.md` for full implementation or use template:

```typescript
// Copy from: ../templates/theme-provider.tsx
```

### 2. Wrap Your App

```typescript
// src/main.tsx
import { ThemeProvider } from '@/components/theme-provider'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
      <App />
    </ThemeProvider>
  </React.StrictMode>,
)
```

### 3. Add Theme Toggle

```bash
pnpm dlx shadcn@latest add dropdown-menu
```

See `../references/dark-mode.md` for ModeToggle component code.

---

## Critical Rules (MUST FOLLOW)

### ✅ Always Do:

1. **Wrap color values with `hsl()` in `:root` and `.dark`**
   ```css
   --background: hsl(0 0% 100%);  /* ✅ Correct */
   ```

2. **Use `@theme inline` to map all CSS variables**
   ```css
   @theme inline {
     --color-background: var(--background);
   }
   ```

3. **Set `"tailwind.config": ""` in components.json**
   ```json
   { "tailwind": { "config": "" } }
   ```

4. **Delete `tailwind.config.ts` if it exists**

5. **Use `@tailwindcss/vite` plugin (NOT PostCSS)**

6. **Use `cn()` for conditional classes**
   ```typescript
   import { cn } from "@/lib/utils"
   <div className={cn("base", isActive && "active")} />
   ```

### ❌ Never Do:

1. **Put `:root` or `.dark` inside `@layer base`**
   ```css
   /* WRONG */
   @layer base {
     :root { --background: hsl(...); }
   }
   ```

2. **Use `.dark { @theme { } }` pattern**
   ```css
   /* WRONG - v4 doesn't support nested @theme */
   .dark {
     @theme {
       --color-primary: hsl(...);
     }
   }
   ```

3. **Double-wrap colors**
   ```css
   /* WRONG */
   body {
     background-color: hsl(var(--background));
   }
   ```

4. **Use `tailwind.config.ts` for theme colors**
   ```typescript
   /* WRONG - v4 ignores this */
   export default {
     theme: {
       extend: {
         colors: { primary: 'hsl(var(--primary))' }
       }
     }
   }
   ```

5. **Use `@apply` directive (deprecated in v4)**

6. **Use `dark:` variants for semantic colors**
   ```tsx
   /* WRONG */
   <div className="bg-primary dark:bg-primary-dark" />

   /* CORRECT */
   <div className="bg-primary" />
   ```

---

## Semantic Color Tokens

Always use semantic names for colors:

```css
:root {
  --destructive: hsl(0 84.2% 60.2%);        /* Red - errors, critical */
  --success: hsl(142.1 76.2% 36.3%);        /* Green - success states */
  --warning: hsl(38 92% 50%);               /* Yellow - warnings */
  --info: hsl(221.2 83.2% 53.3%);           /* Blue - info, primary */
}
```

**Usage:**
```tsx
<div className="bg-destructive text-destructive-foreground">Critical</div>
<div className="bg-success text-success-foreground">Success</div>
<div className="bg-warning text-warning-foreground">Warning</div>
<div className="bg-info text-info-foreground">Info</div>
```
