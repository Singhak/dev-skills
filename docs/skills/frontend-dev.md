---
title: frontend-dev
parent: Skills
nav_order: 3
permalink: /skills/frontend-dev/
---

# frontend-dev
{: .no_toc }

UI playbook for web and mobile frontends in any framework: React, Next.js, Vue, Nuxt, Angular, Svelte, SolidJS, React Native and plain JS/TS.
{: .fs-5 .fw-300 }

[View SKILL.md](https://github.com/Singhak/dev-skills/blob/master/frontend-dev/SKILL.md){: .btn .btn-outline }

1. TOC
{:toc}

---

## Loads when

The task touches UI components, pages, forms, styling, client state, routing, browser behaviour or frontend tests. Always together with `dev-core`; add `fullstack-integration` when the change consumes or changes an API.

## Default vs high-risk

| Level | Adds |
|---|---|
| **Default** | Component tests for interaction plus loading/empty/error states, an axe check, a quick XSS/secrets pass, one break-it round |
| **High-risk** (auth flows, payments, rich-HTML rendering, token handling, conversion-critical journeys) | Cross-browser e2e tests, the full frontend security checks, UI-bypass and double-submit attacks, UX trade-offs flagged for human review |

## What it covers

- **Architecture**: organized by feature; presentational components separate from data hooks; server data in a server-state cache, not global stores; responses validated at the boundary; every async view handles loading, empty, error and success.
- **Testing what the user sees**: Testing Library queries by role and label, `user-event`, MSW for API mocking, Playwright for critical journeys with auto-waiting assertions and no `waitForTimeout`.
- **Accessibility (WCAG 2.2 AA)**: semantic HTML, keyboard access and focus management, contrast, announced form errors, `prefers-reduced-motion`, axe in component and e2e tests.
- **Security**: framework auto-escaping, DOMPurify if rich HTML is unavoidable, scheme checks on user-supplied URLs, no secrets in the bundle, `HttpOnly` cookies over `localStorage`, CSP, `postMessage` origin checks.
- **Product quality**: design-system components and tokens, complete journeys, clear error text, analytics without personal data.
- **Performance**: p75 targets of LCP < 2.5 s, INP < 200 ms, CLS < 0.1; bundle-size impact of every new dependency.

## Break-it attacks

- XSS payloads through every render path: fields, URL params and hash, mocked API responses.
- Bypass the UI: re-enable disabled buttons, edit hidden fields, call the API directly. The backend must still refuse.
- Tamper with client state: storage, cookies, deep links into later wizard steps, back/forward after logout.
- Leak hunt in the built bundle, network tab, URLs, console and analytics payloads.

## Verify: proof required

| Check | Pass evidence |
|---|---|
| Component and unit tests | Exit 0; loading, empty, error and success covered |
| Accessibility | 0 serious/critical axe violations |
| E2E for touched journeys | Exit 0 on Chromium + one mobile project, no retries needed |
| Build and bundle | Exit 0; bundle growth stated |
| Console | No new errors or warnings, including hydration warnings |
| Responsive and journey | Empty, success, error, back/refresh handled at mobile and desktop widths |
| Analytics and i18n | Events fire once with no PII; strings in the i18n system |
| Break it | XSS, UI-bypass, double-submit, hostile-data and state-tampering attempts recorded, each finding has a test |

## Stops and hands back when

- Designs are missing for required states, or the design system lacks a needed component.
- The UI needs an API change (it pulls in `backend-dev` and `fullstack-integration`, or asks if another team owns the API).
- A UX trade-off would affect conversion or accessibility.

## References

`product-quality.md` · `frontend-testing.md` · `frontend-security.md`
