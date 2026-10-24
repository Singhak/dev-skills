---
name: frontend-dev
description: Frontend engineering playbook for web and mobile UIs in any framework (React, Next.js, Vue, Nuxt, Angular, Svelte, SolidJS, React Native, plain JS/TS). Covers component architecture, state and data fetching, TDD with unit and component tests (Testing Library), API mocking (MSW), end-to-end tests (Playwright/Cypress), visual regression, accessibility (WCAG 2.2), frontend security (XSS, CSP, token storage), adversarial "break it" self-attacks (UI bypass, double-submit, hostile data) performance (Core Web Vitals), and product quality (design-system consistency, complete user journeys, microcopy, analytics instrumentation). Use this skill whenever the task touches UI components, pages, forms, styling, client state, routing, browser behaviour or frontend tests — always together with the dev-core skill for the base workflow.
---

# Frontend Dev

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

## 5. Break-it attacks for frontend (dev-core Step 7)
After the feature passes, attack it as described in `dev-core/references/break-it.md`. Frontend priorities:
- **XSS**: put payloads (`<img src=x onerror=alert(1)>`, `javascript:` URLs) into every field, URL param, hash, and API response the component renders (mock them with MSW)
- **Bypass the UI**: disable client validation, edit hidden fields, re-enable disabled buttons in devtools, call the API directly — the backend must still refuse (pair with a backend test)
- **Double-submit & race**: rapid double-click on submit/pay, navigate away mid-request, two tabs editing the same item
- **Hostile data**: very long text, emoji/RTL/zero-width characters, empty arrays, null fields, 10,000-item lists, slow or failed responses (`page.route` / MSW delay and 500)
- **State tampering**: edit `localStorage`/cookies/URL state; deep-link straight to a later step of a wizard; use back/forward after logout
- **Leak hunt**: inspect the built bundle, network tab, URLs, console and analytics calls for tokens, keys or PII
- **Accessibility break**: keyboard-only, 200% zoom, screen reader labels, reduced motion
Each successful attack becomes a failing component/e2e test, then a fix.

## 6. Product quality and UX
Technical correctness isn't enough; the feature must be usable and consistent. What the agent should do:
- **Design system first**: use existing components and tokens (spacing, colour, typography, radius). Don't create a one-off component when a system component fits; if a gap exists, flag it rather than inventing a new pattern silently.
- **Complete user journeys**: walk the whole flow, not just the screen — entry points, first-time (empty) experience, success confirmation, error recovery, back/refresh behaviour, deep links, and what happens next.
- **Microcopy**: clear, specific, action-oriented labels and messages. Error text says what happened and how to fix it ("Card expired — use a different card"), not "Something went wrong". Follow the product's tone; keep strings in the i18n system.
- **Feedback and affordance**: every action gets visible feedback (pending state, success toast, inline confirmation); destructive actions require confirmation or offer undo.
- **Forms**: minimal fields, correct input types and `autocomplete`, inline validation on blur, preserve input on error, sensible defaults.
- **Analytics instrumentation**: when the project tracks events, add them per the existing tracking plan/naming convention (e.g. `object_action`: `checkout_started`, `checkout_completed`), with properties that answer real product questions, and **never** PII, tokens or free-text input. Test that key events fire once (not on every render).
- **Conversion-critical paths** (signup, onboarding, checkout): minimize steps and distractions, keep primary action obvious, avoid layout shift around buttons.
- **Flag UX risks for a human** instead of guessing: confusing flows, unclear copy, missing designs for states, accessibility trade-offs. The agent can't measure usability or conversion without real users — it should say so and suggest how to validate (usability test, A/B test behind a flag, analytics funnel).

## 7. Performance
- Targets (Core Web Vitals, p75): **LCP < 2.5 s, INP < 200 ms, CLS < 0.1**.
- Code-split by route; lazy-load heavy, below-the-fold components.
- Optimize images (modern formats, responsive `srcset`, explicit width/height, lazy loading); preload the LCP image and key fonts.
- Avoid unnecessary re-renders (stable props, memoization only where profiling shows benefit); virtualize long lists.
- Watch bundle size (bundle analyzer, size-limit in CI); question every new dependency.
- Measure with Lighthouse / Lighthouse CI and real-user monitoring, not intuition.

## 8. Frontend Definition of Done (in addition to dev-core)
- [ ] Component tests cover interaction plus loading / empty / error states
- [ ] Pure logic and hooks unit-tested
- [ ] E2E test added/updated if a critical journey changed
- [ ] Keyboard-only walkthrough works; axe reports no serious/critical issues
- [ ] Responsive at mobile, tablet, desktop widths; works in supported browsers
- [ ] No raw HTML injection without sanitization; no secrets or tokens in bundle, URLs or logs
- [ ] Break-it round done: XSS, UI-bypass, double-submit, hostile data and state-tampering attacks tried; findings fixed with tests
- [ ] No new console errors/warnings; bundle size impact checked
- [ ] Uses design-system components/tokens; full journey (empty, success, error, back/refresh) handled; copy is clear
- [ ] Analytics events follow the tracking plan, fire once, contain no PII
- [ ] Strings ready for i18n if the project localizes (no hard-coded user-facing text outside the i18n system)

## Reference files
- `references/frontend-testing.md` — Testing Library, MSW, Playwright patterns and examples
- `references/frontend-security.md` — detailed browser security checks with test ideas

Related skills: `fullstack-integration` when consuming or changing an API (state, mutations, SSR, errors); `ship-and-operate` for build/deploy; `debug-production` for production UI issues.
