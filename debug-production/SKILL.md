---
name: debug-production
description: Systematic workflow for diagnosing and fixing bugs and incidents that happen in deployed environments (production or staging) across frontend, API, services, database, queues and infrastructure. Covers triage and severity, mitigation first, tracing a request from browser to database using correlation IDs, logs, metrics and traces, forming and testing hypotheses, reproducing the failure as an automated test, fixing, verifying, adding alerts, and writing a short post-incident review. Use this skill when the user reports something broken, slow, erroring or behaving differently in a deployed environment, shares an error report, stack trace, Sentry/Datadog/Grafana link, alert or customer complaint, or asks "why is X failing in prod". Do NOT use for bugs found while writing new code locally; dev-core already covers those. Treats production as read-only and hands back to the user before any production write, restart, rollback or data fix. Always together with dev-core.
---

# Debug Production

> **Default** (SEV3–SEV4, contained impact): gather evidence, trace one request, confirm the root cause, reproduce as a test, fix through the normal workflow.
> **High-risk** (SEV1–SEV2, data loss, security signs): recommend mitigation first and hand the decision to the user, escalate security signs immediately, verify recovery in production signals, and write the post-incident review.

In fullstack systems, the place a bug *shows* is rarely where it *lives*: a blank screen can be an API 500, which can be a slow query, which can be a missing index after a migration. This skill finds the real cause methodically and makes sure it can't silently return. Follow the `dev-core` workflow for the fix itself.

**Safety rules:** treat production as read-only. Query logs, metrics, traces and read replicas; don't run writes, migrations, restarts, or data fixes in production unless the user explicitly asks and confirms. Never paste customer PII or secrets into chat, tickets or test fixtures — anonymize.

## 1. Triage (first minutes)
1. **What is the impact?** Who is affected (all users, a region, a tenant, a browser, one feature), since when, how badly.
2. **Severity**: SEV1 (outage/data loss/security), SEV2 (major feature broken, many users), SEV3 (degraded/workaround exists), SEV4 (minor).
3. **What changed?** Recent deploys (frontend and backend), config/flag changes, migrations, dependency or infra changes, traffic spikes, third-party incidents. Most incidents correlate with a change.
4. **Mitigate before you fix** for SEV1/SEV2: roll back the last deploy, turn off the feature flag, scale up, fail over, or disable the broken feature — then investigate calmly. Recommend the mitigation to the user; don't execute it without approval.

## 2. Gather evidence (follow the request)
Work from the symptom inward, using the correlation/request ID wherever possible:

| Layer | Look at |
|---|---|
| Browser | Error tracker events (Sentry etc.) by release, console errors, failed network requests (status, response body, request ID), RUM metrics, browser/OS/version distribution |
| Edge / CDN / gateway | Status codes, cache hits serving stale or wrong content, WAF blocks, TLS/CORS errors |
| API / service | Structured logs filtered by request ID, error rate and latency by endpoint (RED), traces showing the slow/failing span |
| Database | Slow query log, locks/deadlocks, connection pool exhaustion, replication lag, recent migrations, `EXPLAIN` on the suspected query |
| Queues / async | Queue depth/lag, dead-letter queue, consumer errors, retry storms, duplicate processing |
| Infra | Pod restarts/OOM kills, CPU/memory saturation, disk, node events, DNS, certificate expiry |
| Third parties | Status pages, timeouts and error codes from upstream APIs |

Capture exact timestamps (UTC), release versions/SHAs, and a few example request IDs. Separate **facts** (observed) from **assumptions**.

Detailed symptom → likely cause map: `references/triage-playbook.md`.

## 3. Hypothesize and test
1. List 2–4 candidate causes ranked by likelihood and evidence.
2. For each, state what evidence would confirm or rule it out, then check it. Prefer cheap, read-only checks first.
3. Don't stop at the first plausible story — confirm it explains **all** the symptoms (timing, scope, error messages). If it explains only some, keep going.
4. Use bisection when unclear: which release introduced it, which tenant/region/browser, which code path.

## 4. Reproduce as a test
- Reproduce locally or in staging with anonymized data shaped like the failing case.
- Encode the reproduction as an **automated failing test** at the lowest level that captures it (unit for logic, integration for query/DB behaviour, contract for shape mismatch, e2e for cross-layer flows). This is the dev-core bug-fix rule.
- If it can't be reproduced, add targeted logging/metrics (no PII) behind a flag, deploy via the normal pipeline, and gather more evidence — say so explicitly rather than guessing a fix.

## 5. Fix, verify, prevent
1. Fix the **root cause**, not just the symptom (a try/catch that hides the error is not a fix). If a quick mitigation is shipped first, track the real fix.
2. Search for the same pattern elsewhere (sibling endpoints, other consumers).
3. Run the full dev-core flow: tests, security pass, break-it round on the fix.
4. Ship via the normal pipeline (ship-and-operate rules); verify in production with the same signals that showed the problem (error rate back to baseline, trace healthy, user confirmation).
5. **Prevent recurrence**: add or tune the alert/SLO burn-rate signal that should have caught it earlier; improve logs/traces where evidence was missing; add a runbook entry.
6. Data repair (if records were corrupted): write an idempotent, reviewed script, dry-run first, back up affected rows, run only with explicit user approval.

## 6. Post-incident review (SEV1–SEV2, or anything recurring)
Blameless, short, factual — template in `references/triage-playbook.md`: summary, impact, timeline (UTC), root cause and contributing factors, detection (how found, how long it took), what went well/badly, action items with owners.

## 7. Report to the user
- Current status (mitigated? fixed? monitoring?)
- Root cause in plain language, with the evidence that confirms it
- Fix and tests added; how it was verified
- Prevention: alerts, logging, runbook changes
- Open questions and recommended follow-ups

## 8. Verify — proof required
| Check | How | Pass evidence |
|---|---|---|
| Evidence collected | logs, traces and error-tracker queries for the incident window (read-only) | Exact UTC times, affected release SHAs, and 2–3 example request IDs recorded |
| Request traced across layers | search one request ID in browser error tracker, gateway, API logs and trace | Same ID found in each layer it passed through, and the failing layer identified |
| Release comparison | error rate / latency grouped by version, before vs after the suspected change | Clear difference that lines up with the change in time, or the change ruled out |
| Root cause explains everything | compare hypothesis against timing, scope (who/where) and error messages | Every symptom accounted for; leftover symptoms listed if not |
| Reproduction test | run the new test on the current (buggy) code | Fails for the same reason seen in production |
| Fix works | run the test and the full suite on the fixed code | Test passes; suite exit 0 |
| Production recovered | after the normal-pipeline deploy, watch the same signals for an agreed window | Error rate / latency back to baseline; no new errors for that release |

## 9. Stop and hand back
- **Any write to production** (data fix, migration, config/flag change, restart, scaling, rollback) → recommend it with the exact steps and wait for explicit approval. Reading logs, metrics and traces is fine.
- SEV1/SEV2 → recommend mitigation (rollback or flag off) **first** and hand the decision to the user before deep investigation.
- Signs of a security incident (one user seeing another's data, leaked credentials, unexpected access) → stop, tell the user immediately, and recommend their security incident process.
- No access to logs, metrics or traces → list exactly what evidence is needed and how to get it; don't guess a root cause.
- Can't reproduce after reasonable attempts → report the evidence, hypotheses ruled in/out, and propose targeted instrumentation instead of a speculative fix.

## Anti-patterns
- Changing several things at once in production "to see if it helps"
- Restarting services repeatedly without capturing evidence first (destroys memory/thread state)
- Declaring fixed without checking production signals after deploy
- Blaming the frontend or backend without tracing the request across both
- Fixing data by hand in production with no script, backup or review
