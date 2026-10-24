# Frontend Security — Checks and Test Ideas

| Area | Check | Test idea |
|---|---|---|
| XSS (reflected/stored/DOM) | Framework escaping; no raw HTML sinks; DOMPurify when HTML required; no `eval`/`new Function` | Render a name `<img src=x onerror=alert(1)>` → appears as literal text, no element created |
| URL injection | Validate scheme of user-supplied links (`http`, `https`, `mailto` allow-list) | `javascript:alert(1)` link is not rendered as clickable |
| Secrets in bundle | No private keys/tokens in code or public env vars | Grep built bundle for key patterns; run gitleaks |
| Token storage | HttpOnly Secure SameSite cookies preferred; short-lived tokens; no tokens in URLs | Token absent from `localStorage`, URL, logs |
| CSRF | SameSite cookies + anti-CSRF token for state-changing requests when cookie auth is used | Cross-origin POST without token rejected (backend test) |
| CSP | Strict policy with nonces/hashes; no `unsafe-eval`; `object-src 'none'`; `frame-ancestors` set | Response headers asserted in e2e; inline script injection blocked |
| Clickjacking | `frame-ancestors 'none'` or allowed list | Page refuses to load in foreign iframe |
| Open redirect | Redirect targets after login validated against same-origin allow-list | `?next=https://evil.com` redirects home instead |
| postMessage | Verify `event.origin`; explicit `targetOrigin` | Message from unexpected origin ignored |
| Third-party code | Minimal scripts; SRI on CDN assets; dependency audit; lockfile committed | `npm audit --audit-level=high` clean |
| Sensitive data | No PII in analytics, error trackers, console; masked inputs where appropriate; `autocomplete` attributes correct | Inspect analytics payload in tests for absence of email/token |
| Client-side authorization | UI hides actions by role, but backend enforces | Backend test proves forbidden action → 403 even if UI bypassed |
| File handling | Validate size/type client-side for UX; server is authority; `rel="noopener noreferrer"` on `target="_blank"` | Oversized upload shows error; external links have rel attributes |

Recommended headers (usually configured server/edge side): `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`.
