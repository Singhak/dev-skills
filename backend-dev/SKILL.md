---
name: backend-dev
description: Backend engineering playbook for APIs, microservices, databases, background jobs, queues/events and CLIs in any language (Node, Python, Java/Spring, Go, .NET, Rust, PHP, Ruby). Covers layered/hexagonal architecture, REST/GraphQL/gRPC API design, TDD with unit, integration (real DB via containers), contract and API end-to-end tests, database migrations, data modeling, caching strategy, event-driven design and eventual consistency, OWASP API security, adversarial "break it" self-attacks (IDOR, injection, race conditions), observability and performance. Use this skill whenever the task touches server-side code, endpoints, controllers, services, repositories, SQL/ORM, migrations, auth, workers, or infrastructure config — always together with the dev-core skill for the base workflow.
---

# Backend Dev

Apply the `dev-core` workflow (understand → plan → TDD → security → gates → break it → report). This skill adds what is specific to server-side work. Always follow the project's existing framework and structure first; the patterns below are defaults when nothing exists.

## 1. Architecture

Default to a **layered / hexagonal (ports & adapters)** structure so business logic is testable without I/O:

```
src/
  api/ (or web/, controllers/)   # HTTP/gRPC/GraphQL adapters: parse, validate, map DTOs, call use cases
  application/ (or services/)    # use cases; orchestration; transactions; authorization decisions
  domain/                        # entities, value objects, domain rules — pure, no framework imports
  infrastructure/                # DB repositories, external API clients, queues, cache, email
  config/                        # settings loaded from env, validated at startup
tests/
  unit/  integration/  contract/  e2e/
```

Rules:
- Dependencies point **inward**: api → application → domain; infrastructure implements interfaces (ports) defined in application/domain.
- Controllers are thin: no business logic, no SQL.
- Domain code has no framework, ORM, or HTTP imports — this is what makes it cheap to unit-test.
- Validate configuration at startup and fail fast on missing/invalid env vars.
- Keep services stateless; state lives in DB/cache/queue.

## 2. API design
- **REST**: resource nouns (`/orders/{id}`), correct verbs and status codes (200, 201 + `Location`, 204, 400, 401, 403, 404, 409, 422, 429, 500). Consistent error body, e.g. RFC 9457 Problem Details: `{type, title, status, detail, instance, errors[]}`.
- Contract-first where possible: OpenAPI / GraphQL schema / `.proto` is the source of truth; generate or validate against it.
- Pagination (cursor preferred) with a max page size; filtering and sorting via allow-listed fields.
- **Idempotency** for retries: PUT/DELETE idempotent by design; POST that creates or charges accepts an `Idempotency-Key`.
- Versioning strategy agreed (URL `/v1` or header); changes are additive; deprecate before removal.
- Request/response DTOs separate from persistence entities — never expose ORM entities directly (prevents mass assignment and data leaks).
- Timeouts, retries with exponential backoff + jitter, and circuit breakers on outbound calls.

## 3. TDD for backend — what to test where

Write tests in this order for a new endpoint/feature (outside-in double loop):
1. **Failing API-level test** (acceptance) for the main scenario — stays red.
2. **Unit tests** driving domain rules and use cases (fast, no I/O; repositories faked).
3. **Integration tests** for repositories/adapters against real dependencies.
4. Wire the controller; the acceptance test turns green.
5. Add negative-path API tests: validation (400/422), unauthenticated (401), forbidden/other-user (403/404), not found, conflict (409), rate limit if applicable.

| Level | Scope | Tools (pick what the project uses) |
|---|---|---|
| Unit | domain + use cases, fakes for ports | Jest/Vitest, pytest, JUnit 5 + AssertJ + Mockito, Go `testing` + testify, xUnit/NUnit, RSpec |
| Integration | repositories with real DB, message broker, cache; HTTP clients against stubs | Testcontainers (Java, Node, Python, Go, .NET), docker-compose, WireMock / MSW / respx / httptest |
| API / component | the service over HTTP in-process with real DB | Supertest, FastAPI/Django test client, Spring `MockMvc`/`WebTestClient`/RestAssured, `httptest`, `WebApplicationFactory` |
| Contract | consumer-driven contracts between services | Pact, Spring Cloud Contract; schema validation against OpenAPI (e.g. Schemathesis for fuzzing) |
| E2E | deployed stack, critical journeys only | Playwright API testing, k6/Postman/Newman, REST-assured against a staging env |

Details and examples: `references/backend-testing.md`.

Key practices:
- **Use a real database engine in integration tests** (Testcontainers), not an in-memory substitute with different SQL semantics.
- Each test owns its data: transaction rollback per test, or truncate between tests, or unique IDs. Never depend on seed order.
- Freeze time and inject ID generators for deterministic assertions.
- Test migrations: apply from empty to latest in CI; test that the app starts against the migrated schema.
- For async/event flows: assert outcomes with polling-until-timeout (e.g. Awaitility), never sleep.
- Test retry/timeout behaviour of outbound clients with a stub that delays or fails.

## 4. Data & persistence
For a new domain area, significant schema change, caching, events or cross-service data flow, **read `references/data-design.md` first and write a short design note** (template inside) before coding.

- Schema changes only through versioned **migrations** (Flyway, Liquibase, Alembic, Prisma/Drizzle migrate, EF Core, golang-migrate, Rails/Django migrations). Never edit an applied migration.
- **Zero-downtime changes**: expand → migrate data → contract. Add nullable column / new table first, backfill, switch reads/writes, then drop the old in a later release.
- Transactions at the use-case level; keep them short; no remote calls inside a DB transaction.
- Avoid N+1: eager-load/join deliberately; check query counts in tests for hot paths.
- Index for real query patterns; check `EXPLAIN` for slow queries.
- Concurrency: optimistic locking (version column) or explicit row locks for contended updates; unique constraints as the last line of defence against duplicates.
- Events: use the **transactional outbox** pattern when a DB write and an event publish must both happen. Consumers are idempotent (dedupe by message ID).

## 5. Backend security (on top of dev-core checklist)
Full list: `references/backend-security.md` (OWASP API Security Top 10 mapped to concrete checks and tests). Must-haves:
- **Object-level authorization in every query** — scope by tenant/owner (`WHERE id = ? AND owner_id = ?`), and test cross-user access returns 403/404.
- Schema validation on every request (Zod, Pydantic, Bean Validation, FluentValidation, go-playground/validator); reject unknown fields for write operations.
- Parameterized queries only; ORM raw-query escape hatches reviewed.
- Auth: verified JWT (alg pinned, `exp`/`aud`/`iss` checked) or server sessions; short-lived access tokens; refresh rotation.
- Rate limiting on auth and expensive endpoints; request body size limits; pagination caps.
- SSRF protection for any URL fetched from input.
- Secrets from env/secret manager; least-privilege DB user (no DDL rights for the app at runtime if possible).
- Security headers and strict CORS (explicit origins).
- Don't leak stack traces, SQL errors, or internal IDs in error responses.

## 6. Break-it attacks for backend (dev-core Step 7)
After the feature passes, attack it as described in `dev-core/references/break-it.md`. Backend priorities:
- **IDOR / tenant hopping**: swap every ID in path, query and body for another user's or tenant's
- **Privilege escalation**: send `role`, `isAdmin`, `ownerId`, `price` fields in the body; call admin routes as a normal user
- **Token abuse**: missing, expired, `alg:none`, tampered signature, token for a deleted user
- **Injection** in every parameter, including sort/filter fields and headers
- **Race conditions**: 20 parallel identical requests for create/charge/redeem/withdraw — check for duplicates and negative balances; run with `-race` in Go
- **Replay & idempotency**: resend the same request and the same webhook/event twice
- **Resource abuse**: giant bodies, `limit=10^6`, deep JSON, slow regex input, zip bombs on upload
- **Dependency failure**: stop the DB/broker container mid-test, make upstream stubs slow or return garbage — verify safe errors, no partial writes, retries bounded
- **Schema fuzzing**: run Schemathesis (or similar) against the OpenAPI spec to hunt for 500s
Each successful attack becomes a failing test, then a fix.

## 7. Observability
- **Structured logs** (JSON) with level, timestamp, request/correlation ID, user/tenant ID (not PII), and event name. Never log secrets, tokens, passwords, full card numbers.
- **Metrics**: RED (rate, errors, duration) per endpoint; queue depth/lag; DB pool usage.
- **Tracing**: OpenTelemetry propagation across services and queues.
- Health endpoints: liveness (process alive) and readiness (dependencies reachable).

## 8. Performance & resilience
- Measure before optimizing; add a benchmark or load test (k6, Gatling, Locust, JMeter) for performance-sensitive changes.
- Cache with explicit TTL and invalidation strategy; never cache per-user data under shared keys.
- Bound everything: thread/connection pools, queue sizes, payload sizes, timeouts.
- Graceful shutdown: stop accepting work, drain in-flight requests/jobs.

## 9. Backend Definition of Done (in addition to dev-core)
- [ ] API contract (OpenAPI/schema) updated and matches implementation
- [ ] Unit tests for domain/use-case rules; integration tests against real DB/broker
- [ ] API tests for happy path + 400/401/403/404/409 cases
- [ ] Cross-user/tenant authorization test exists for every new resource endpoint
- [ ] Migration is reversible or has a documented rollback; expand/contract followed
- [ ] No N+1 on new queries; indexes added where needed
- [ ] Logs structured and secret-free; metrics/traces for new endpoints
- [ ] Outbound calls have timeouts and retry policy
- [ ] Break-it round done: IDOR, privilege escalation, injection, race and dependency-failure attacks tried; findings fixed with tests

## Reference files
- `references/backend-testing.md` — per-stack test setup patterns and examples
- `references/backend-security.md` — OWASP API Top 10 checks with test ideas
- `references/data-design.md` — domain modeling, schema design, caching strategy, events, eventual consistency, sagas, design note template

Related skills: `fullstack-integration` when a UI consumes the API; `ship-and-operate` for deploy/CI/infra changes; `debug-production` for incidents.
