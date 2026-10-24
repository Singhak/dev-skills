---
name: frontend-dev
description: Frontend engineering playbook for web and mobile UIs in any framework (React, Next.js, Vue, Nuxt, Angular, Svelte, SolidJS, React Native, plain JS/TS). Covers component architecture, state and data fetching, TDD with unit and component tests (Testing Library), API mocking (MSW), end-to-end tests (Playwright/Cypress), visual regression, accessibility (WCAG 2.2), frontend security (XSS, CSP, token storage), adversarial "break it" self-attacks (UI bypass, double-submit, hostile data) performance (Core Web Vitals), and product quality (design-system consistency, complete user journeys, microcopy, analytics instrumentation). Use this skill whenever the task touches UI components, pages, forms, styling, client state, routing, browser behaviour or frontend tests — always together with the dev-core skill for the base workflow.
---

# Frontend Dev

**How this combines**: dev-core owns the workflow, common checks and report; this skill adds UI-specific steps, Verify rows and stop rules only. If the change consumes or changes an API, also load `fullstack-integration`.

> **Default**: component tests for interaction plus loading/empty/error states, axe check, quick XSS/secrets pass, one break-it round.
> **High-risk** (auth flows, payments, rich-HTML rendering, token handling, conversion-critical journeys): add e2e tests across browsers, the full checks in `references/frontend-security.md`, UI-bypass and double-submit attacks, and flag UX trade-offs for human review.

Apply the `dev-core` workflow (understand → plan → TDD → security → gates → break it → report). This skill adds what is specific to UI work. Use the project's existing framework, styling approach, component library and test runner first; the patterns below are defaults when nothing exists.

## 1. Architecture

Organize by **feature**, keep components small, and separate concerns:

```
src/
  app/ or pages/ or routes/      # route-level screens: compose features, handle layout
  features/<feature>/
    components/                  # presentational + container components for this feature
    hooks/ or composables/       # stateful logic, data fetching
    api/                         # typed API client calls for this feature
    model/                       # types, schemas, pure helpers (easy unit tests)
    <feature>.test.tsx
  shared/
    ui/                          # design-system primitives (Button, Input, Modal)
    lib/                         # utilities, formatters
  tests/e2e/                     # Playwright/Cypress journeys
```

Rules:
- **Presentational components** render props and emit events; **container/hook** layers own data and side effects. Business rules live in pure functions (`model/`) — unit-test those directly.
- State: keep it as local as possible. Server data belongs in a server-state cache (TanStack Query, SWR, RTK Query, Apollo, Angular services + signals/RxJS) — don't copy it into global stores. Global client state (Zustand, Redux, Pinia, NgRx, signals) only for truly cross-cutting UI state.
- Derive, don't duplicate: compute values from state rather than syncing copies.
- Validate API responses at the boundary (Zod/Valibot/io-ts) so bad data fails loudly, not deep in the UI.
- Every async view handles four states: **loading, empty, error, success**.
- Forms: schema-driven validation shared with the backend contract where possible (React Hook Form + Zod, VeeValidate, Angular reactive forms).
- Styling follows the existing system (design tokens, CSS modules, Tailwind, styled-components). No magic numbers when a token exists.

## 2. TDD for frontend — what to test where

Test **what the user sees and does**, not implementation details (no asserting on internal state, private methods, or CSS class names).

| Level | Scope | Tools (use what the project has) |
|---|---|---|
| Unit | pure functions, hooks/composables, reducers, formatters, schemas | Vitest / Jest / Jasmine-Karma, `renderHook` |
| Component | one component or feature with mocked network | Testing Library (React/Vue/Angular/Svelte), `@testing-library/user-event`, MSW for API mocking, Angular TestBed |
| Visual / story | states rendered in isolation, visual diffs | Storybook + interaction tests, Chromatic / Playwright screenshots / Percy |
| Accessibility | automated a11y rules | jest-axe / vitest-axe, `@axe-core/playwright` |
| E2E | real browser, real (or staging) backend, critical journeys | Playwright (preferred), Cypress; Detox/Maestro for React Native |

TDD loop for a component:
1. Write a failing component test from the user's perspective: render, interact with `user-event`, assert on accessible output (`getByRole`, `getByLabelText`, `findByText`).
2. Implement the minimum markup/logic to pass.
3. Add tests for loading, empty, error states (MSW returns delay / empty / 500), validation messages, and keyboard interaction.
4. Refactor (extract hooks, pure helpers) while green.

Query priority (Testing Library): `getByRole` → `getByLabelText` → `getByPlaceholderText` → `getByText` → `getByTestId` (last resort). If you can't find an element by role or label, that's often an accessibility bug — fix the markup.

E2E rules:
- Cover only critical journeys (sign-up/login, checkout, core create/edit flow) plus smoke tests.
- Use Page Object or fixture patterns; stable selectors (roles, labels, `data-testid`) — never brittle CSS/XPath chains.
- Rely on auto-waiting assertions (`await expect(locator).toBeVisible()`); never `waitForTimeout`.
- Seed data via API, not through the UI; authenticate once and reuse storage state.
- Run across the browsers/viewports the product supports (at least Chromium + one mobile viewport).

Examples and setup: `references/frontend-testing.md`.

## 3. Accessibility (WCAG 2.2 AA baseline)
- Semantic HTML first: `<button>` for actions, `<a href>` for navigation, real `<label>`s, headings in order, landmarks (`<main>`, `<nav>`).
- Everything usable by keyboard; visible focus indicator; logical tab order; focus managed on route change and in modals (trap + restore).
- ARIA only when native semantics can't express it; follow WAI-ARIA Authoring Practices for widgets.
- Text contrast ≥ 4.5:1 (3:1 for large text and UI components); don't convey meaning by colour alone.
- Images have meaningful `alt` (or `alt=""` if decorative); form errors announced and linked via `aria-describedby`.
- Respect `prefers-reduced-motion`; touch targets ≥ 24×24 CSS px.
- Run axe in component and e2e tests; fail the build on serious/critical violations.

## 4. Frontend security (on top of dev-core checklist)
Full list: `references/frontend-security.md`. Must-haves:
- **XSS**: rely on framework auto-escaping; avoid `dangerouslySetInnerHTML`, `v-html`, `[innerHTML]`, `innerHTML`, `document.write`. If rich HTML is unavoidable, sanitize with DOMPurify and test it with a malicious payload.
- Never build URLs/`href`s from user input without validating the scheme (block `javascript:`).
- **No secrets in the client bundle** — anything in frontend code or `NEXT_PUBLIC_`/`VITE_`/`REACT_APP_` env vars is public. API keys with privileges belong on the server.
- **Tokens**: prefer `HttpOnly; Secure; SameSite` cookies set by the server over `localStorage`. With cookies, protect state-changing requests against CSRF (SameSite + CSRF token).
- Authorization is enforced by the backend; hiding a button is UX, not security.
- Content Security Policy without `unsafe-inline`/`unsafe-eval` where feasible (nonces/hashes); `frame-ancestors` to prevent clickjacking.
- Third-party scripts: minimize, load with Subresource Integrity when from CDNs, audit dependencies (`npm audit`, lockfile committed).
- `postMessage`: always check `event.origin`; specify target origin when sending.
- Don't put PII or tokens in URLs, analytics events, or console logs.

## 5. Break-it attacks for frontend (dev-core Step 6)
Run the generic playbook in `dev-core/references/break-it.md`, plus these UI-specific attacks:
- **XSS through every render path**: put payloads into fields, URL params/hash and mocked API responses (MSW).
- **Bypass the UI**: re-enable disabled buttons, edit hidden fields, call the API directly — the backend must still refuse (pair with a backend test).
- **Tamper with client state**: edit storage/cookies/URL state, deep-link into a later wizard step, use back/forward after logout.
- **Leak hunt**: built bundle, network tab, URLs, console and analytics payloads for tokens, keys or personal data.

## 6. Product quality and UX
Use design-system components and tokens; handle the whole journey (empty, success, error, back/refresh); write clear, specific error text; follow the tracking plan for analytics with no personal data; flag UX risks for a human instead of guessing. Details and checklist: `references/product-quality.md`.

## 7. Performance
Targets (p75): LCP < 2.5 s, INP < 200 ms, CLS < 0.1. Check bundle-size impact of every new dependency. Techniques and measurement: `references/product-quality.md` §Performance.

## 8. Verify — proof required (in addition to dev-core)
| Check | Example commands | Pass evidence |
|---|---|---|
| Component and unit tests | `npx vitest run`, `npx jest`, `ng test --watch=false` | Exit 0; tests cover loading, empty, error and success |
| Accessibility | axe in component tests; `@axe-core/playwright` in e2e | 0 serious/critical violations |
| E2E for touched journeys | `npx playwright test <spec>` (Chromium + one mobile project) | Exit 0; no retries needed |
| Build and bundle | `npm run build`; size-limit or bundle analyzer if configured | Build exit 0; bundle growth stated |
| Console clean | e2e or manual run with console listener | No new errors/warnings (incl. hydration warnings) |
| Responsive & journey | e2e or screenshots at mobile and desktop widths; walk the full journey | Empty, success, error, back/refresh handled; design-system components and tokens used |
| Analytics & i18n (if the project uses them) | test that key events fire; search diff for hard-coded user-facing strings | Each event fires once, follows the tracking plan, carries no PII; strings in the i18n system |
| Break it (frontend) | attacks in §5 | XSS, UI-bypass, double-submit, hostile-data and state-tampering attempts recorded; each finding has a test |

## 9. Stop and hand back (in addition to dev-core)
- Designs are missing for required states (empty, error, mobile), or the design system lacks a needed component → ask rather than invent a new pattern.
- The UI needs an API change → stop and pull in `backend-dev` and `fullstack-integration`, or ask if the API is owned by another team.
- A UX trade-off would affect conversion or accessibility → flag it for a human decision.

## Reference files
- `references/product-quality.md` — design-system use, journeys, microcopy, analytics, performance techniques
- `references/frontend-testing.md` — Testing Library, MSW, Playwright patterns and examples
- `references/frontend-security.md` — detailed browser security checks with test ideas

Related skills: `fullstack-integration` when consuming or changing an API (state, mutations, SSR, errors); `ship-and-operate` for build/deploy; `debug-production` for production UI issues.
