---
title: fullstack-integration
parent: Skills
nav_order: 4
permalink: /skills/fullstack-integration/
---

# fullstack-integration
{: .no_toc }

Covers the seam between frontend and backend: the contract, generated types, error mapping, client caching and mutations, SSR data flow, and tests that span both sides.
{: .fs-5 .fw-300 }

[View SKILL.md](https://github.com/Singhak/dev-skills/blob/master/fullstack-integration/SKILL.md){: .btn .btn-outline }

1. TOC
{:toc}

---

Most fullstack bugs live at the boundary, not inside either side: the UI and API disagree on shape, errors aren't surfaced, caches go stale, optimistic updates never roll back. This skill makes the boundary explicit, typed, tested and attacked.

## Loads when

A task touches **both** sides of an API, the UI consumes a new or changed endpoint, a contract changes, or you're fixing stale data, wrong types, unhandled errors, hydration mismatches or lost updates. It doesn't load for purely server-internal or purely visual work.

## Default vs high-risk

| Level | Adds |
|---|---|
| **Default** | Contract updated first, client types regenerated, every error class mapped to UI behaviour, cache invalidation covered, component tests for success/empty/error/slow |
| **High-risk** (breaking contract change, money/irreversible mutations, SSR with per-user data, real-time/async) | Breaking-change check and expand/contract plan, idempotency keys, SSR leak checks, contract verification (Pact/Schemathesis), the full seam attacks |

## What it covers

- **Contract first**: update OpenAPI / GraphQL / tRPC / proto before either side; generate client types instead of hand-writing them; changes are additive; CI fails on stale types or breaking changes.
- **Error mapping**: one server error format, and a defined UI behaviour for each class:

| Server outcome | UI behaviour |
|---|---|
| 400/422 field errors | Inline at the field; keep user input |
| 401 | Refresh token once, otherwise login with return path |
| 403 | Explain no permission; don't retry |
| 404 | Not-found state |
| 409 | "Changed by someone else", offer reload/merge |
| 429 | Back off, "try again shortly" |
| 5xx / network / timeout | Retry idempotent reads; show error + retry; never lose unsaved input |

- **Fetching and rendering**: one server-state library, precise query keys, per-data staleness, SSR hydration without double fetching or markup mismatches, no secrets or other users' data in serialized state, `Cache-Control: private` for per-user data.
- **Mutations**: dedupe in-flight requests, idempotency keys, optimistic updates only when reversible (snapshot → apply → roll back on error → refetch on settle), ETag/`If-Match` for concurrency.
- **Real-time**: 202 + status resource for async work, versioned messages, resync on reconnect.

## Break-it attacks

- Change the response shape: missing, extra or null fields, unknown enums.
- Fail after the optimistic update (500, timeout, offline).
- Two tabs or users editing the same entity.
- Version skew: old frontend against the new API, and the reverse.
- Cross-user leaks in SSR HTML, serialized state and client caches after logout.

## Verify: proof required

| Check | Pass evidence |
|---|---|
| Generated types current | No diff after regeneration |
| No unintended breaking change | `oasdiff` / GraphQL Inspector / `buf breaking` clean, or each break approved |
| Server matches contract | Pact or Schemathesis: no 500s or schema violations |
| Client handles every response class | MSW tests for success, empty, 4xx, 5xx, slow; rollback test where used |
| End-to-end smoke | Includes one error path and one refresh-after-mutation check |
| Hydration and leaks | 0 hydration warnings; no secrets or other users' data in HTML/state |

## Stops and hands back when

- The contract needs a breaking change: it presents the expand/contract plan and waits.
- Another team or repo owns the other side: it delivers the proposed contract change and stops.
- The contract is ambiguous.

## References

`boundary-modeling.md` · `contracts-and-types.md` · `state-and-mutations.md`
