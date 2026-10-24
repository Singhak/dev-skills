# Security Checklist (OWASP-aligned)

Use on every change; go deep on items touching the risk surface. Treat any "no" as a finding to fix or explicitly report.

## Input & output
- [ ] All external input (body, query, headers, cookies, files, env, messages, third-party responses) validated at the boundary with schema/allow-lists (type, length, range, format, enum)
- [ ] Output encoded for its context (HTML, attribute, URL, JS, SQL, shell, CSV/formula, log)
- [ ] File uploads: size limit, type checked by content not extension, stored outside web root, random names, scanned if possible
- [ ] Path inputs canonicalized; no path traversal (`../`)
- [ ] Deserialization only of trusted formats; no native object deserialization of untrusted data (pickle, Java serialization, YAML `load`)

## Injection
- [ ] SQL/NoSQL: parameterized queries or ORM bindings only; no string concatenation with input
- [ ] OS commands: avoid; if needed, use argument arrays, never a shell string with input
- [ ] Templates: auto-escaping on; no raw/unsafe rendering of user content
- [ ] No `eval`, `Function()`, dynamic `import` of user-controlled strings
- [ ] LDAP, XPath, regex (ReDoS) inputs bounded or escaped

## Authentication
- [ ] Passwords hashed with Argon2id / bcrypt / scrypt (never plain hash, never reversible)
- [ ] MFA supported for privileged accounts where in scope
- [ ] Rate limiting / lockout on login, OTP, reset endpoints
- [ ] Session tokens random, rotated on login, invalidated on logout; JWTs: algorithm pinned, signature verified, short expiry, audience/issuer checked
- [ ] Generic auth failure messages (no user enumeration)

## Authorization
- [ ] Deny by default; every route/action/query enforces authorization server-side
- [ ] Object-level checks: the caller may access *this* record (prevents IDOR/BOLA)
- [ ] Function-level checks: role/permission for admin operations
- [ ] Field-level: clients can't set fields they shouldn't (mass assignment protection)
- [ ] Tests prove a forbidden user gets 403/404

## Secrets & configuration
- [ ] No secrets in code, tests, fixtures, logs, error messages, or client bundles
- [ ] Secrets from env/secret manager; `.env` git-ignored; example file has placeholders only
- [ ] Debug mode, stack traces, admin consoles disabled in production
- [ ] Security headers / TLS configured; CORS restricted to known origins (no `*` with credentials)

## Data protection
- [ ] Minimum PII collected and retained; sensitive fields encrypted at rest where required
- [ ] PII and tokens masked in logs
- [ ] Least-privilege DB/service credentials

## Dependencies & supply chain
- [ ] New dependency justified, maintained, licence-compatible, version pinned via lockfile
- [ ] Audit run (`npm audit`/`pnpm audit`, `pip-audit`, `mvn dependency-check`/`gradle dependencyCheck`, `govulncheck`, `cargo audit`, `dotnet list package --vulnerable`, `bundle audit`)
- [ ] No high/critical vulnerabilities introduced

## Error handling, logging, monitoring
- [ ] Errors fail closed; no sensitive detail returned to clients
- [ ] Security events logged (auth failures, permission denials, admin actions) with correlation IDs
- [ ] Logs protected from injection (newlines/control chars stripped)

## Resource abuse
- [ ] Pagination with max page size; request size limits; timeouts on outbound calls
- [ ] Rate limits on expensive or abusable endpoints
- [ ] SSRF: outbound URLs from input validated against an allow-list; internal/metadata IPs blocked

## Tooling (use what exists)
- SAST: Semgrep, CodeQL, Bandit (Python), gosec (Go), SpotBugs/FindSecBugs (Java), ESLint security plugins
- Secrets: gitleaks, trufflehog
- Dependencies: ecosystem audit tools, OSV-Scanner, Trivy (also containers/IaC)
- DAST (when an app is running): OWASP ZAP baseline scan
