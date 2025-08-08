### Frontend Standards: Rails + Hotwire (Turbo + Stimulus + ViewComponent)

This project uses Rails-rendered HTML enhanced with Hotwire. Turbo drives navigation/partial updates, Stimulus provides lightweight behavior, and ViewComponent encapsulates reusable UI. React is allowed only as approved islands.

## 0) Project Decision (Mode)

- Server renders HTML; Turbo drives navigation and partial updates; Stimulus for interactions; ViewComponent for reusable UI.
- React is allowed only as islands with explicit approval.

## 1) Design System & Tokens

- All design tokens live as CSS variables and, optionally, Tailwind theme values.
- Components use tokens only via CSS variables. No hardcoded hex in components.

File layout:

```
app/assets/stylesheets/
  tokens.css        # CSS variables: colors, spacing, radii, shadows, typography
  utilities.css     # small project-specific utilities
```

Example tokens (see `app/assets/stylesheets/tokens.css`):

```css
:root {
  /* Colors */
  --color-bg: #0e0c16;
  --color-primary: #f26419;
  --color-accent: #00c2ff;
  --color-muted: #f5f1ea;
  --color-creative: #bb79fc;
  --color-highlight: #ffc857;

  /* Spacing */
  --space-1: 4px;  --space-2: 8px;  --space-3: 12px;  --space-4: 16px;  --space-6: 24px;  --space-8: 32px;

  /* Radius */
  --radius-sm: 8px; --radius-md: 12px; --radius-lg: 16px; --radius-2xl: 24px;

  /* Typography */
  --font-sans: ui-sans-serif, system-ui, -apple-system, "Inter", "Segoe UI", Roboto, Helvetica, Arial, "Apple Color Emoji", "Segoe UI Emoji";
}
```

Tailwind mapping (optional): map theme tokens to CSS variables in `tailwind.config.js`.

## 2) Components over Partials (ViewComponent)

- Use ViewComponent for reusable UI. Each component ships with a preview and spec.
- Location:

```
app/components/
  ui/
    button_component.rb
    button_component.html.erb
    button_component_preview.rb
```

Enable previews in development (mounted at `/rails/view_components`).

## 3) Layouts & Slots

- Provide an application layout with slots for `page_title`, `breadcrumbs`, and `primary_actions`.
- Complex headers/footers are components.

## 4) Accessibility (a11y) as a Gate

- Semantic HTML elements, keyboard navigation, visible focus states, and WCAG 2.1 AA contrast.
- CI runs `erb-lint` and a minimal pa11y check for key pages.

## 5) Forms with Progressive Enhancement

- Server-validated; Turbo drives redirects/updates.
- Stimulus provides optional niceties; forms must submit without JS.

## 6) Performance Budgets & Metrics

- HTML per page < 200KB gzipped
- Initial JS per route < 150KB gzipped
- CSS < 150KB gzipped
- CI runs Lighthouse or equivalent (future enhancement).

## 7) Caching Strategy (HTML-first)

- Use fragment caching (Russian-doll) around components.
- Keys include locale, role, and feature flags.

## 8) JavaScript Organization (Hotwire)

Stimulus controllers:

```
app/javascript/controllers/
  form/autosave_controller.js
  modal/dialog_controller.js
```

- Small, single-responsibility controllers.
- No global state; use `data-controller` and `data-action`.

### React islands

- Keep under `app/frontend/components/` with Vite; mount via a Stimulus wrapper.
- List any islands here with purpose, owner, and fallback.

#### React islands registry

Currently none.

## 9) Testing UI That Ships

- ViewComponent previews are canonical docs.
- System specs (Capybara + Turbo) for core flows.
- React islands (if any): unit test with Jest and route-level checks with Playwright.

## 10) Security

- Strict CSP (no inline scripts); Stimulus/ES modules only.
- Sanitize any rich text input (allowlist attributes).

## 11) Observability & Flags

- Instrument Turbo stream errors and JS exceptions (Sentry recommended).
- Use Flipper (or similar) for feature flags; components read flags rather than branching in views.

## 12) Folder Map (Reference)

```
app/
  components/
    ui/
  views/
    pages/
      home/
        index.html.erb
  javascript/
    controllers/
      form/
      modal/
  assets/stylesheets/
    tokens.css
    utilities.css
```

## 13) What to change now (Tasks)

1. Create this document and keep it current.
2. Reference this doc from `CONTRIBUTING.md`.
3. Add `app/assets/stylesheets/tokens.css` and migrate hardcoded colors to tokens.
4. Introduce ViewComponent and create `Ui::ButtonComponent` (+ preview + spec).
5. Add ERB linting and a minimal a11y check to CI.
6. Document any React island in the section above.

## 14) Acceptance Criteria

- This doc exists with the standards above.
- `CONTRIBUTING.md` references this doc under “Frontend Mode”.
- At least one ViewComponent with preview and spec is present.
- Tokens file exists and components reference CSS variables only.
- CI runs ERB lint + basic a11y check.

## 15) Notes

- Starting point; refine budgets, token names, and component taxonomy as the design system evolves.
- If heavy client interactivity is required, document decision and boundaries before introducing more React.

