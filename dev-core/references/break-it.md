# Break-It Playbook — Attack Your Own Feature

## Contents
1. Mindset and rules of engagement
2. Universal attack checklist
3. Attack payload library (for your own tests)
4. Tools that help
5. From finding to fix
6. Break-It Report template

## 1. Mindset and rules of engagement
- Assume every input is hostile, every user is trying to see someone else's data, every request may arrive twice, out of order, or never finish.
- Ask "what did I assume?" for each line of the feature — then violate the assumption.
- Rules: only your own code, locally or in a test environment you control. No production, no third-party targets, no real user data, no destructive commands outside disposable test data.

## 2. Universal attack checklist
Work through every category that applies to the feature.

**Input abuse**
- Empty, null, missing field, wrong type (`"5"` vs `5`, array instead of object), extra unexpected fields
- Boundaries: 0, -1, max int, max+1, very long strings (10k–1M chars), deeply nested JSON
- Unicode: emoji, RTL characters, zero-width characters, homoglyphs, NUL byte, mixed normalization (`é` composed vs decomposed)
- Whitespace-only, leading/trailing spaces, case variations (`Admin` vs `admin`) in unique fields

**Injection**
- SQL/NoSQL, command, template, header (CRLF), log, CSV/formula, path traversal, XSS — see payload library

**Authentication & authorization**
- Call without a token, with an expired token, with a token for another user, with a tampered token
- Change IDs in URL/body to another user's or tenant's resource (IDOR)
- Perform an admin action as a normal user; change your own role via request body
- Skip a step in a multi-step flow (go straight to step 3)

**Business logic**
- Negative quantity/price, zero-amount payments, applying a coupon twice, reusing a one-time link
- Changing price/total on the client side and submitting
- Exceeding limits (quota, inventory) via parallel requests

**Concurrency & state**
- Double-submit (click twice / send same request in parallel 20×) — duplicates? double charge?
- Race between update and delete; two users editing the same record
- Replay an old request; retry after a timeout — is it idempotent?

**Resource exhaustion**
- Huge payloads, huge file uploads, `limit=1000000`, expensive search terms, regex catastrophic backtracking
- Many requests quickly — is there rate limiting?

**Failure of dependencies**
- DB down, slow upstream API (timeout), upstream returns 500 / malformed JSON / huge body
- Disk full, network drop mid-request — is state left consistent? Is the error message safe?

**Information disclosure**
- Do errors reveal stack traces, SQL, file paths, internal IDs, or whether an email exists?
- Do logs, URLs, analytics, or client bundles contain secrets, tokens or PII?

## 3. Attack payload library (use in your own tests)
| Target | Sample payloads |
|---|---|
| SQL | `' OR '1'='1`, `'; DROP TABLE users;--`, `1 UNION SELECT null--` |
| NoSQL | `{"$ne": null}`, `{"$gt": ""}`, `{"$where": "sleep(1000)"}` |
| Command | `; ls`, `&& whoami`, `` `id` ``, `$(id)` |
| Path traversal | `../../etc/passwd`, `..%2f..%2f`, `....//` |
| XSS | `<script>alert(1)</script>`, `<img src=x onerror=alert(1)>`, `javascript:alert(1)`, `"><svg onload=alert(1)>` |
| Template | `{{7*7}}`, `${7*7}`, `<%= 7*7 %>` |
| Header / log | `value\r\nX-Injected: 1`, `user\nFAKE LOG LINE` |
| CSV / formula | `=1+1`, `@SUM(1)`, `+cmd` |
| SSRF | `http://127.0.0.1`, `http://169.254.169.254/latest/meta-data/`, `http://[::1]` |
| JWT | `alg: none`, signature stripped, `exp` in the past, swapped `sub` |
| ReDoS | `"a" * 50000 + "!"` against your regexes |

Expected result in every case: rejected or safely handled (escaped/treated as data), no crash, no leak, correct status code.

## 4. Tools that help (use what is available)
- Fuzzing/property tests: Hypothesis, fast-check, jqwik, Go native fuzzing (`go test -fuzz`), cargo-fuzz
- API fuzzing against schema: Schemathesis, RESTler
- Concurrency: send N parallel requests (k6, `xargs -P`, `Promise.all`, `asyncio.gather`); Go `-race`
- Dynamic scanning (local/staging only): OWASP ZAP baseline
- SAST/secrets: Semgrep, CodeQL, gitleaks (see `scripts/security_scan.sh`)
- Mutation testing (do tests catch broken code?): Stryker (JS/TS/.NET), mutmut (Python), PIT (Java)
- Frontend: Playwright with tampered requests (`page.route`), devtools to edit DOM/local storage

## 5. From finding to fix
For each finding:
1. Write a test that reproduces the attack and fails.
2. Fix at the right layer (validate at boundary, authorize in the use case/query, escape at output).
3. Search for the same pattern elsewhere in your change — bugs come in families.
4. Rerun the full suite and the attack round.

## 6. Break-It Report template
```
## Break-It Report — <feature>
Attack surface: <inputs, endpoints, components, permissions>
Rounds run: <n>

| # | Attack | Result | Severity | Fix | Regression test |
|---|--------|--------|----------|-----|-----------------|
| 1 | Other user's order ID in GET /orders/{id} | Returned data | Critical | Scoped query by owner | test_returns_404_for_other_users_order |
| 2 | Double-click "Pay" | Two charges | High | Idempotency key + disabled button | test_duplicate_payment_is_ignored |
| 3 | 1 MB name field | Accepted | Medium | Max length 200 | test_rejects_overlong_name |

Not tested / open risks: <what and why>
```
