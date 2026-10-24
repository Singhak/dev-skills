# Triage Playbook

## Symptom → likely causes → first checks
| Symptom | Likely causes | First checks |
|---|---|---|
| Blank/white screen | JS exception on render, chunk load failure after deploy (old HTML, new assets), API returned unexpected shape | Error tracker by release; network tab for 404 on JS chunks; CDN cache of HTML; API response vs contract |
| Works locally, fails in prod | Missing/different env var, CORS, CSP blocking, prod-only data shape, feature flag state, build-time env baked wrong | Config diff between envs; console CSP/CORS errors; flag values; build logs |
| Intermittent 500s | One bad instance, connection pool exhaustion, timeouts to upstream, race condition, memory pressure | Errors grouped by host/pod; pool metrics; upstream latency; restarts/OOM |
| Slow page | Slow API (N+1, missing index, lock), large bundle, no caching, third-party script | Trace waterfall; slow query log + EXPLAIN; RUM LCP/INP breakdown; bundle size by release |
| Stale or wrong data shown | Client cache not invalidated, CDN/server cache of per-user data, read replica lag, eventual consistency | Cache-Control headers; query keys/invalidation; replica lag metric; event processing lag |
| Another user's data visible | Shared cache keyed without user, SSR singleton store, missing tenant filter | **SEV1 security incident** — mitigate immediately; check caching layers and queries |
| Duplicate records/charges | Double-submit, retries without idempotency, at-least-once consumers not deduping | Idempotency keys present? consumer dedupe? request logs for repeated IDs |
| Logouts/401 loops | Token expiry/refresh bug, clock skew, cookie domain/SameSite change, secret rotation | Auth logs; cookie attributes; server time; recent auth config change |
| Spike after deploy | Regression in the release | Compare error rate by version; roll back first if SEV1/2 |
| Queue backlog growing | Consumer crash loop, poison message, downstream slow, under-scaled | DLQ contents; consumer logs; downstream latency; consumer count |
| Gradual degradation over days | Memory leak, unbounded table/log growth, cache eviction, certificate nearing expiry | Memory trend per instance; table sizes; cert expiry dates |

## Useful queries (adapt to your tools)
- Logs: filter `request_id=<id>` across services; group errors by `error.type` and `release`
- Metrics: `error_rate by (endpoint, version)`; `p95 latency by endpoint`; DB pool `in_use / max`
- Traces: find slowest spans for the endpoint in the incident window; compare with a healthy window
- DB (Postgres): `pg_stat_activity` for long-running/locked queries; `pg_stat_statements` for top time consumers; `EXPLAIN (ANALYZE, BUFFERS)` on a replica

## Post-incident review template
```
# Incident: <title>   Severity: SEV<n>   Date: <UTC>
## Summary
<2–3 sentences: what happened, impact, resolution>
## Impact
Users affected, duration, data affected, revenue/SLO budget consumed
## Timeline (UTC)
- hh:mm  change deployed / first error
- hh:mm  alert fired / reported by <source>
- hh:mm  mitigation applied
- hh:mm  root cause identified
- hh:mm  fix deployed; verified
## Root cause and contributing factors
## Detection
How it was detected; time to detect; what should have alerted earlier
## What went well / what didn't
## Action items
| Action | Owner | Due | Type (prevent/detect/mitigate) |
```
