---
title: backend-dev
parent: Skills
nav_order: 2
permalink: /skills/backend-dev/
---

# backend-dev
{: .no_toc }

Server-side playbook for APIs, services, databases, background jobs, queues/events and CLIs in any language.
{: .fs-5 .fw-300 }

[View SKILL.md](https://github.com/Singhak/dev-skills/blob/master/backend-dev/SKILL.md){: .btn .btn-outline }

1. TOC
{:toc}

---

## Loads when

The task touches server code, endpoints, controllers, services, repositories, SQL/ORM, migrations, auth, workers or infrastructure config. Always together with `dev-core`; add `fullstack-integration` when a UI consumes the API.

## Default vs high-risk

| Level | Adds |
|---|---|
| **Default** | Layered structure, unit tests for logic, API tests for happy path + validation + 401/403, quick security pass, one break-it round |
| **High-risk** (auth, money, PII, schema/migration, public contract, concurrency) | A design note, integration tests on a real DB, the full authorization matrix and OWASP API checks, race/replay attacks, an expand/contract migration plan |

## What it covers

- **Architecture**: layered / hexagonal (ports and adapters). Dependencies point inward; controllers are thin; domain code has no framework imports; config is validated at startup.
- **API design**: correct verbs and status codes, RFC 9457 Problem Details errors, contract-first (OpenAPI / GraphQL / proto), cursor pagination, idempotency keys, additive versioning, DTOs separate from persistence entities.
- **TDD, outside-in**: failing API test → unit tests for domain rules → integration tests on real dependencies → wire controller → negative paths (400/422, 401, 403/404, 409, 429).
- **Data**: versioned migrations, expand → migrate → contract for zero downtime, short transactions, N+1 checks, optimistic locking, the transactional outbox for events.
- **Security**: object-level authorization in every query, schema validation, parameterized queries, pinned JWT checks, rate limits, SSRF protection, least-privilege DB user.
- **Observability and resilience**: structured logs with correlation IDs, metrics for new endpoints, timeouts on every outbound call.

## Break-it attacks

- Swap every ID for another user's or tenant's; send `role`, `ownerId` or `price` fields the client shouldn't set.
- Fire 20 parallel identical create/charge/redeem requests; resend the same webhook twice.
- Kill the DB or broker mid-test; make upstream stubs slow or return garbage.
- Schema-fuzz the API against its OpenAPI spec (Schemathesis).

## Verify: proof required

| Check | Pass evidence |
|---|---|
| Migrations | Up from empty, down, up again all exit 0; app starts against the migrated schema |
| Integration tests on a real DB | Exit 0 with Testcontainers/compose, not an in-memory substitute |
| Authorization matrix | Every new resource endpoint has 401 / 403 / other-owner / valid cases passing |
| API spec | Lint exit 0; responses validate against the spec |
| New queries | Uses the intended index; no N+1 |
| Observability and resilience | Structured, secret-free logs; metrics/traces; timeouts and retry policy |
| Break it | IDOR, privilege escalation, injection, race and dependency-failure attempts recorded, each finding has a test |

## Stops and hands back when

- A breaking API or schema change or a destructive migration is needed: it proposes the expand/contract plan and waits.
- There's no container runtime for integration tests: it reports this instead of switching to SQLite or an in-memory DB.
- The design note has open questions about domain rules.

## References

`observability-performance.md` · `backend-testing.md` · `backend-security.md` · `data-design.md` (domain modeling, schema, caching, events, sagas, design note template)
