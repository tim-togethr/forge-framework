---
name: tailwind:utility-patterns
description: Tailwind CSS utility patterns — mobile-first, component extraction, design tokens, dark mode
trigger: |
  - Adding or modifying Tailwind CSS classes
  - Extracting repeated utility combinations
  - Implementing responsive layouts
  - Adding dark mode support
  - Configuring design tokens
skip_when: |
  - Component already uses consistent Tailwind classes and is not repeated
---

# Tailwind Utility Patterns

## Mobile-First Responsive Design

Always start with the mobile layout, then layer larger breakpoints.

```tsx
// BAD — desktop-first (overrides required for mobile)
<div className="w-1/3 md:w-full lg:w-1/3">

// GOOD — mobile-first
<div className="w-full md:w-1/2 lg:w-1/3">

// Breakpoints (min-width):
// sm: 640px   md: 768px   lg: 1024px   xl: 1280px   2xl: 1536px
```

## Component Extraction Over @apply

Extract JSX components, not CSS classes.

```tsx
// BAD — @apply couples Tailwind to CSS, loses JIT tree-shaking
// .btn-primary { @apply bg-blue-600 text-white px-4 py-2 rounded; }

// GOOD — extract to a reusable component
function Button({ variant = 'primary', children, ...props }: ButtonProps) {
  const variants = {
    primary: 'bg-blue-600 hover:bg-blue-700 text-white',
    secondary: 'bg-gray-100 hover:bg-gray-200 text-gray-900',
    ghost: 'bg-transparent hover:bg-gray-100 text-gray-700',
  };
  return (
    <button
      className={`px-4 py-2 rounded font-medium transition-colors ${variants[variant]}`}
      {...props}
    >
      {children}
    </button>
  );
}
```

## Design Tokens in tailwind.config

Define your system in the config, not as one-off arbitrary values.

```javascript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

export default {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eff6ff',
          500: '#3b82f6',
          900: '#1e3a8a',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      spacing: {
        18: '4.5rem',
        88: '22rem',
      },
    },
  },
} satisfies Config;
```

## Dark Mode

Use the `dark:` variant with CSS variable tokens.

```css
/* globals.css */
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
}
```

```javascript
// tailwind.config.ts
export default {
  darkMode: 'class', // toggled by adding 'dark' class to <html>
  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
      },
    },
  },
};
```

```tsx
// Usage — works in both modes automatically
<div className="bg-background text-foreground">
  <p className="text-foreground/70">Muted text</p>
</div>
```

## Avoiding Arbitrary Values

Prefer config tokens over one-off `[value]` syntax.

```tsx
// BAD — arbitrary values bypass the design system
<div className="w-[347px] text-[#3b4c6e] mt-[13px]">

// GOOD — use or extend config tokens
<div className="w-88 text-brand-700 mt-3">
```

## Checklist

- [ ] Classes ordered: layout → spacing → typography → color → interactive states
- [ ] Mobile-first breakpoints (`sm:`, `md:`, etc.)
- [ ] No `@apply` — extract React components instead
- [ ] Brand colors and fonts defined in `tailwind.config.ts` `extend`
- [ ] Dark mode via CSS variables + `dark:` variant
- [ ] No arbitrary `[value]` syntax for values that should be in the design system
- [ ] `content` array covers all component file paths
