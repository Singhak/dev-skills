# Backend Security — OWASP API Security Top 10 (2023) as Checks and Tests

| Risk | Check | Test idea |
|---|---|---|
| API1 Broken Object Level Authorization | Every data access scoped by owner/tenant from the auth context, never from the request body | User B fetching/updating/deleting User A's resource → 403/404 |
| API2 Broken Authentication | Strong hashing, token validation (alg, exp, aud, iss), rate-limited login, rotation | Expired/forged/`alg:none` token → 401; 20 rapid login failures → 429 |
| API3 Broken Object Property Level Authorization | Separate input/output DTOs; allow-list writable fields; hide sensitive fields | Sending `role: "admin"` or `isVerified: true` is ignored/rejected; response omits `passwordHash` |
| API4 Unrestricted Resource Consumption | Page size caps, body size limits, timeouts, rate limits, upload limits | `?limit=100000` capped; 50 MB body → 413 |
| API5 Broken Function Level Authorization | Role checks on admin/privileged routes, deny by default | Regular user hitting `/admin/*` → 403 |
| API6 Unrestricted Access to Sensitive Business Flows | Anti-automation on flows like signup, checkout, voting (rate limits, CAPTCHA, device checks) | Burst of purchases from one account throttled |
| API7 SSRF | Allow-list outbound hosts; block private ranges and cloud metadata (169.254.169.254); disable redirects or re-validate | Webhook URL `http://127.0.0.1` / metadata IP rejected |
| API8 Security Misconfiguration | Prod debug off, strict CORS, security headers, TLS, minimal error detail, patched base images | Error response contains no stack trace; CORS rejects unknown origin |
| API9 Improper Inventory Management | Documented, versioned APIs; old versions retired; no forgotten debug endpoints | Route list matches OpenAPI; no `/debug`, `/actuator` exposed publicly |
| API10 Unsafe Consumption of APIs | Validate and bound third-party responses; timeouts; TLS verification on | Malformed upstream payload handled without crash or injection |

## Also check
- Injection (SQL/NoSQL/command/template): parameterized queries; tests with payloads like `' OR 1=1 --`, `{"$ne": null}`, `; rm -rf`
- Cryptography: standard libraries only; no custom crypto; secure random for tokens; AES-GCM / libsodium for encryption
- Multi-tenancy: tenant ID enforced centrally (middleware, row-level security, or repository base class)
- Audit trail for sensitive actions (who, what, when, from where)
- Webhooks: verify signatures (HMAC) with constant-time compare and timestamp tolerance
- Containers/IaC: non-root user, read-only FS where possible, no secrets in images, scanned with Trivy/Checkov
