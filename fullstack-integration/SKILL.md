---
name: fullstack-integration
description: Discipline for connecting frontend and backend correctly. Covers contract-first APIs (OpenAPI/GraphQL/tRPC/protobuf) with generated client types, domain modeling across the client/server boundary, shared validation, mapping server errors to UI states, data fetching and caching across SSR/CSR/RSC, mutations, optimistic updates with rollback, cache invalidation, pagination, real-time updates, and contract/e2e tests that span both sides. Use this skill when a task touches BOTH sides of an API, when the UI consumes a new or changed endpoint, when adding or changing an API contract, or when fixing bugs like stale data, wrong types, unhandled errors, hydration mismatches or lost updates. Do NOT use for purely server-internal or purely visual work; use backend-dev or frontend-dev alone for those. Always together with dev-core.
---

# Fullstack Integration

> **Default**: contract updated first, client types regenerated, every error class mapped to UI behaviour, cache invalidation covered, component tests for success/empty/error/slow.
> **High-risk** (breaking contract change, money/irreversible mutations, SSR with per-user data, real-time/async flows): add the breaking-change check and expand/contract plan, idempotency keys, leak checks on SSR output, contract verification (Pact/Schemathesis), and the full seam attacks in section 8.

Most fullstack bugs live at the boundary, not inside either side: the UI and API disagree on shape, errors aren't surfaced, caches go stale, optimistic updates never roll back. This skill makes the boundary explicit, typed, tested and attacked. Follow the `dev-core` workflow; this adds what is specific to the seam.

## 1. Contract first
1. **Define or update the contract before writing either side**: OpenAPI, GraphQL schema, tRPC router, or `.proto`. In a monorepo with TypeScript on both sides, a shared schema package (Zod) is acceptable as the contract.
2. **Generate, don't hand-write, client types and clients** (openapi-typescript, orval, openapi-generator, GraphQL Codegen, tRPC inference, buf). Hand-written duplicate types drift.
3. **Server must be verified against the contract** in tests (response validation, Schemathesis, Pact provider verification). The client is compiled against generated types.
4. **Changes are additive.** Adding optional fields is safe. Renaming, removing, changing types or making optional → required is a breaking change: version it or expand/contract (add new field, migrate clients, remove old later). Remember mobile clients and cached old frontends may still call the old shape.
5. Add a CI check that fails when generated types are out of date or a breaking change is introduced (e.g. `oasdiff breaking`, GraphQL Inspector, `buf breaking`).

Details: `references/contracts-and-types.md`.

## 2. Domain modeling across the boundary
Decide explicitly for each concept:
- **Source of truth**: the server owns business rules and persisted state; the client owns ephemeral UI state (open panels, draft input, selection).
- **Where validation runs**: client validation is for UX speed; server validation is the authority. Share the schema when possible so messages and rules match — but never rely on the client copy for security.
- **Shapes per use case**: API DTOs are designed for consumers (screens/use cases), not mirrors of DB tables. Don't leak internal fields, foreign keys the UI doesn't need, or computed fields the UI recomputes differently.
- **Money, time, IDs**: money as integer minor units or decimal strings with currency; timestamps in UTC ISO-8601, formatted to local time only in the UI; IDs opaque strings.
- **Enums and states**: one definition shared via the contract; the UI handles unknown future enum values gracefully.
- **Permissions**: server returns what the user may do (e.g. `allowedActions: ["edit","delete"]`) so the UI doesn't reimplement authorization rules — and the server still enforces them.

## 3. Errors: server → UI mapping
- Server returns one consistent error format (RFC 9457 Problem Details with field-level `errors[]`).
- Client maps every class of failure to a defined UI behaviour:

| Server outcome | UI behaviour |
|---|---|
| 400/422 field errors | Show inline at the right field; keep user input |
| 401 | Refresh token once; otherwise redirect to login, preserving return path |
| 403 | Explain no permission; don't retry |
| 404 | Not-found state; don't crash |
| 409 conflict / version mismatch | Show "changed by someone else", offer reload/merge |
| 429 | Back off; show "try again shortly" |
| 5xx / network / timeout | Retry idempotent reads with backoff; show error + retry action; never lose unsaved input |

- Propagate a **correlation/request ID** from server responses into client error reports, so a UI bug report can be traced to backend logs.

## 4. Data fetching, caching and rendering mode
Use one server-state library per app (TanStack Query, SWR, RTK Query, Apollo/urql, Angular resources/signals) rather than ad-hoc `fetch` in components.
- **Query keys** describe the data exactly (`["orders", {userId, status, page}]`) so invalidation is precise.
- Choose `staleTime`/revalidation per data type: reference data long; user data short; money/inventory always fresh before commit.
- **SSR / RSC / CSR**:
  - Fetch on the server for first paint and SEO; hydrate the client cache with the same data (dehydrate/hydrate, `initialData`, framework loaders) to avoid double fetching.
  - Server and client must render identical markup for the same data — no `Date.now()`, random values, `window` access, or locale-dependent formatting during render (causes hydration mismatches).
  - Never send secrets or other users' data into serialized page props/state.
  - Per-user data must not be cached in shared CDN/server caches; set `Cache-Control: private` or `no-store` accordingly.
- Pagination: cursor-based infinite queries; dedupe items by ID across pages.

## 5. Mutations and optimistic updates
Default pattern:
1. Disable the trigger or dedupe while a mutation is in flight; send an **idempotency key** for create/charge operations.
2. **Optimistic update** only when success is very likely and the change is easily reversible (toggle, rename, reorder). Snapshot previous cache → apply optimistic change → on error **roll back** to the snapshot and show an error → on settle **invalidate/refetch** affected queries.
3. Prefer **server response as truth**: update the cache from the mutation's returned entity.
4. Invalidate every query that shows the changed data (lists, counts, detail views, other users' dashboards via real-time if needed).
5. Concurrency: use version/ETag fields; send `If-Match`; handle 409 as in section 3.
6. Don't use optimistic UI for payments, irreversible deletes, or anything with server-side side effects the user must confirm.

Examples: `references/state-and-mutations.md`.

## 6. Real-time and eventual consistency
- When the server processes asynchronously (queues, events), the API returns `202 Accepted` with a status resource; the UI shows a pending state and polls or subscribes (SSE/WebSocket) until done.
- Real-time messages carry entity ID + version; the client ignores messages older than its cached version.
- Reconnect logic: on reconnect, refetch to resync — don't assume no events were missed.
- Tell users when data may be briefly behind ("Updating…") instead of showing contradictory numbers.

## 7. Testing across the boundary
| Test | Purpose |
|---|---|
| Contract (Pact or schema validation) | Server and client agree on shapes, status codes and error format |
| Client component tests with MSW handlers **generated from or validated against the contract** | UI handles every response class (success, empty, 4xx, 5xx, slow) |
| Server API tests against the contract | Implementation matches spec |
| E2E (Playwright) on real stack | Critical journeys work end to end, incl. one error path and one refresh-after-mutation check |
| Breaking-change check in CI | Prevents shipping incompatible changes |

## 8. Break-it attacks at the seam (dev-core Step 7)
- Change the server response shape (missing field, extra field, null, unknown enum) — does the UI degrade gracefully or crash?
- Slow network, timeout, offline mid-mutation, server 500 after optimistic update — does it roll back and keep user input?
- Two tabs/users edit the same entity — lost update? 409 handled?
- Double-click submit, browser back after submit, refresh mid-flow — duplicates?
- Old frontend build against new API (and new frontend against old API during rollout).
- Inspect SSR HTML and serialized state for secrets or another user's data; log in as user B in the same browser and look for user A's cached data.
- Logout: are caches, storage and in-memory state cleared?

## 9. Definition of Done (in addition to dev-core, backend-dev, frontend-dev)
- [ ] Contract updated first; client types generated; CI checks for drift and breaking changes
- [ ] Every server error class mapped to a defined UI behaviour; user input preserved on failure
- [ ] Query keys and invalidation cover every view showing changed data
- [ ] Optimistic updates roll back on failure; idempotency keys on create/charge
- [ ] SSR/CSR render consistently; no per-user data in shared caches or serialized props of others
- [ ] Contract + component + e2e tests cover success, empty, error and slow responses
- [ ] Break-it seam attacks run; findings fixed with tests

## 10. Verify — proof required (in addition to dev-core)
| Check | Example commands | Pass evidence |
|---|---|---|
| Generated types are current | regenerate (`npx openapi-typescript …`, `graphql-codegen`, `buf generate`) then `git diff --exit-code` on generated files | No diff after regeneration |
| No unintended breaking change | `oasdiff breaking base.yaml head.yaml`, `graphql-inspector diff`, `buf breaking --against .git#branch=main` | No breaking changes, or each one approved by the user |
| Server matches contract | Pact provider verification, or `schemathesis run openapi.yaml --base-url …` against a local server | All interactions verified; no 500s or schema violations |
| Client handles every response class | component tests with MSW handlers for success, empty, 4xx, 5xx, slow | All pass; optimistic rollback test included where used |
| End-to-end smoke | `npx playwright test --grep @smoke` against the local full stack | Exit 0; includes one error path and one refresh-after-mutation check |
| Hydration and leaks | SSR page load in e2e with console listener; inspect serialized state | 0 hydration warnings; no secrets or other users' data in HTML/state |

## 11. Stop and hand back (in addition to dev-core)
- The contract needs a breaking change → present the expand/contract plan and wait for approval.
- The other side of the API is owned by another team or repo → deliver the proposed contract change and stop; don't implement against an unagreed contract.
- The contract is ambiguous (unclear field meaning, error format, pagination) → ask before generating clients.

## Reference files
- `references/contracts-and-types.md` — tooling per stack, versioning, breaking-change rules
- `references/state-and-mutations.md` — code patterns for queries, optimistic updates, SSR hydration
