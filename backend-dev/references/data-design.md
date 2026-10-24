# Data and System Design

Read this before writing code when the task involves a new domain area, a new service, a significant schema change, caching, events, or cross-service data flow.

## Contents
1. Domain modeling
2. Schema design
3. Caching strategy
4. Synchronous vs event-driven
5. Eventual consistency and sagas
6. Idempotency and ordering
7. Design note template

## 1. Domain modeling
- Start from use cases and language: list the nouns (entities), the rules (invariants) and the verbs (commands/events) using the business's own terms.
- **Entities** have identity (Order); **value objects** are defined by their values (Money, Address) and are immutable.
- **Aggregates**: a cluster updated together in one transaction with one root (Order + OrderLines). Keep aggregates small; reference other aggregates by ID. Invariants are enforced inside the aggregate.
- **Bounded contexts**: the same word can mean different things (a "customer" in billing vs support). Separate models and map at the boundary instead of one giant shared model.
- Model state machines explicitly (`DRAFT → SUBMITTED → PAID → SHIPPED | CANCELLED`) with allowed transitions enforced in code and tested.

## 2. Schema design
- Normalize to 3NF by default; denormalize deliberately for proven read hot spots (and document how it is kept in sync).
- Constraints in the database, not only in code: `NOT NULL`, `UNIQUE`, foreign keys, `CHECK` (e.g. `quantity > 0`), enums or lookup tables.
- Keys: surrogate IDs (UUIDv7/ULID for sortable, non-guessable public IDs; bigint internally if preferred). Never expose sequential IDs where enumeration is a risk.
- Money as `numeric(19,4)` or integer minor units + currency column. Timestamps as `timestamptz` in UTC. Store `created_at`, `updated_at`, and `version` for optimistic locking.
- Soft delete only when there's a real need (audit/restore); otherwise hard delete plus audit log. If soft-deleting, ensure unique indexes and queries account for it.
- Multi-tenancy: tenant ID on every tenant-owned row, in every index that's queried per tenant, enforced centrally (repository base, row-level security).
- Indexes follow query patterns: composite index column order matches filters then sort; verify with `EXPLAIN`; avoid indexing everything (write cost).
- JSON columns for genuinely schemaless, rarely-queried attributes — not to avoid modeling.
- Large/time-series data: partitioning and retention policies decided upfront.

## 3. Caching strategy
Cache only with evidence of need (measured latency/load) and decide all of these:
| Decision | Options |
|---|---|
| What | computed results, reference data, rendered fragments, HTTP responses |
| Where | HTTP/CDN (`Cache-Control`, `ETag`), application cache (Redis/Memcached), in-process (small, per-instance), DB materialized views |
| Pattern | cache-aside (default), read-through, write-through, write-behind (risky) |
| Freshness | TTL per data type; explicit invalidation on write; versioned keys (`product:v3:123`) |
| Scope | public vs per-user — per-user data must include user/tenant in the key and never be in shared HTTP caches |
| Failure | cache down → fall back to source with timeouts; protect source from stampede (request coalescing, jittered TTLs, locking) |

Always test: stale-after-write behaviour, key collision between users/tenants, cache-down fallback.

## 4. Synchronous vs event-driven
Use **synchronous calls (HTTP/gRPC)** when the caller needs the answer now to continue, and the dependency is reliable and fast.
Use **events/messages** when: other parts react to something that happened (OrderPlaced → email, analytics, inventory), work is slow or can be retried later, or you need to decouple teams/services.
Rules:
- Events are facts in past tense (`OrderPlaced`), versioned, with a schema (Avro/Protobuf/JSON Schema) and a registry or contract tests.
- Include event ID, type, version, occurred-at, aggregate ID and version, correlation ID.
- Publish reliably with the **transactional outbox** (write event row in the same DB transaction, relay publishes).
- Prefer thin events + fetch-on-demand, or fat events carrying needed data — choose deliberately; don't leak internal-only fields.
- Don't build distributed monolith chains (A calls B calls C synchronously for one user request) — each hop multiplies latency and failure.

## 5. Eventual consistency and sagas
- Accept that cross-service data is eventually consistent; design the UX for it (pending states, "processing" messages; see fullstack-integration).
- Multi-step business transactions across services use a **saga**: a sequence of local transactions with **compensating actions** on failure (reserve stock → charge card → if charge fails, release stock). Orchestration (a coordinator) is easier to reason about; choreography (services react to events) is looser but harder to trace.
- Read models/projections built from events can lag; expose freshness where it matters.
- Reconciliation jobs detect and repair drift between systems (e.g. payments vs orders) and alert on mismatches.

## 6. Idempotency and ordering
- Every consumer is idempotent: store processed message IDs or use natural idempotency (upsert by key, version checks).
- Assume at-least-once delivery and possible reordering; use aggregate version numbers to ignore stale events.
- Partition by aggregate ID when per-entity ordering matters (Kafka key).
- Poison messages → dead-letter queue with alerting and a replay tool.

## 7. Design note template (write before building non-trivial features)
```
# Design: <feature>
Context & goal: <why, which use cases>
Domain model: <entities, aggregates, state machine, invariants>
Schema changes: <tables/columns/indexes/constraints; migration plan (expand/contract)>
API/contract changes: <endpoints/events; breaking?>
Consistency: <sync vs async; transactions; saga & compensations>
Caching: <what/where/TTL/invalidation>
Security: <authz rules, PII, tenant isolation>
Failure modes: <what if X is down/slow/duplicated>
Observability: <metrics, logs, alerts>
Alternatives considered: <and why not>
Open questions: <for the user/team>
```
