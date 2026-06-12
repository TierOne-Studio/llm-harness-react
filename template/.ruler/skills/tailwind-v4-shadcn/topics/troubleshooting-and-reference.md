# Troubleshooting, Templates & Reference Map

Quick fixes for common symptoms, the file templates shipped with this skill, advanced patterns, and when to load each file in `../references/`.

## Common Issues & Quick Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `bg-primary` doesn't work | Missing `@theme inline` mapping | Add `@theme inline` block |
| Colors all black/white | Double `hsl()` wrapping | Use `var(--color)` not `hsl(var(--color))` |
| Dark mode not switching | Missing ThemeProvider | Wrap app in `<ThemeProvider>` |
| Build fails | `tailwind.config.ts` exists | Delete the file |
| Text invisible | Wrong contrast colors | Check color definitions in `:root`/`.dark` |

See `../references/common-gotchas.md` for complete troubleshooting guide.

---

## File Templates

All templates are available in the `../templates/` directory:

- **index.css** - Complete CSS setup with all color variables
- **components.json** - shadcn/ui v4 configuration
- **vite.config.ts** - Vite + Tailwind plugin setup
- **tsconfig.app.json** - TypeScript with path aliases
- **theme-provider.tsx** - Dark mode provider with localStorage
- **utils.ts** - `cn()` utility for class merging

Copy these files to your project and customize as needed.

---

## Advanced Topics

Load `../references/advanced-usage.md` for advanced patterns including:

- **Custom Colors**: Add semantic colors beyond default palette
- **v3 Migration**: See `../references/migration-guide.md` for complete guide
- **Component Best Practices**: Semantic tokens, cn() utility, composition patterns

**Quick Example:**
```css
:root { --brand: hsl(280 65% 60%); }
@theme inline { --color-brand: var(--brand); }
```
Usage: `<div className="bg-brand">Branded</div>`

For detailed patterns and component composition examples, load `../references/advanced-usage.md`.

---

## Reference Documentation

For deeper understanding, see:

- **common-gotchas.md** - All the ways it can break (and fixes)
- **dark-mode.md** - Complete dark mode implementation
- **migration-guide.md** - Migrating hardcoded colors to CSS variables
- **plugins-reference.md** - Official Tailwind v4 plugins (Typography, Forms)
- **advanced-usage.md** - Custom colors and advanced patterns

---

## When to Load References

Load reference files based on user's specific needs:

### Load `../references/common-gotchas.md` when:
- User reports "colors not working" or "bg-primary doesn't exist"
- Dark mode not switching properly
- Build fails with Tailwind errors
- User encounters any CSS/configuration issue
- Debugging theme problems

### Load `../references/dark-mode.md` when:
- User asks to implement dark mode
- Theme switching not working
- Need ThemeProvider component code
- Questions about system theme detection

### Load `../references/migration-guide.md` when:
- Migrating from Tailwind v3 to v4
- User has hardcoded colors to migrate
- Questions about v3 → v4 changes
- Need migration checklist

### Load `../references/plugins-reference.md` when:
- User needs Typography plugin (prose class)
- User needs Forms plugin
- Questions about @plugin directive
- Plugin installation errors

### Load `../references/advanced-usage.md` when:
- User asks about custom colors beyond defaults
- Need advanced component patterns
- Questions about component best practices
- Component composition questions

---

## Official Documentation

- **shadcn/ui Vite Setup**: https://ui.shadcn.com/docs/installation/vite
- **shadcn/ui Tailwind v4 Guide**: https://ui.shadcn.com/docs/tailwind-v4
- **shadcn/ui Dark Mode (Vite)**: https://ui.shadcn.com/docs/dark-mode/vite
- **Tailwind v4 Docs**: https://tailwindcss.com/docs
- **shadcn/ui Theming**: https://ui.shadcn.com/docs/theming

---

## Production Example

This skill is based on the WordPress Auditor project:
- **Live**: https://wordpress-auditor.webfonts.workers.dev
- **Stack**: Vite + React 19 + Tailwind v4 + shadcn/ui + Cloudflare Workers
- **Dark Mode**: Full system/light/dark support
- **Version**: Tailwind v4.1.17 + shadcn/ui latest (Nov 2025)

All patterns in this skill have been validated in production.

---

**Questions? Issues?**

1. Check `../references/common-gotchas.md` first
2. Verify all steps in the 4-step architecture
3. Ensure `components.json` has `"config": ""`
4. Delete `tailwind.config.ts` if it exists
5. Check official docs: https://ui.shadcn.com/docs/tailwind-v4
