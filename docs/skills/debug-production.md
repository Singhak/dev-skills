---
title: debug-production
parent: Skills
nav_order: 6
permalink: /skills/debug-production/
---

# debug-production
{: .no_toc }

A systematic workflow for bugs and incidents in deployed environments, from triage to a post-incident review.
{: .fs-5 .fw-300 }

[View SKILL.md](https://github.com/Singhak/dev-skills/blob/master/debug-production/SKILL.md){: .btn .btn-outline }

1. TOC
{:toc}

---

In fullstack systems, the place a bug *shows* is rarely where it *lives*: a blank screen can be an API 500, which can be a slow query, which can be a missing index after a migration. This skill finds the real cause methodically and makes sure it can't silently return.

## Loads when

You report something broken, slow or erroring in a deployed environment (production or staging), or share an error report, stack trace, alert, dashboard link or customer complaint. It doesn't load for bugs found while coding locally. Once the cause is found, the fix follows `dev-core` plus the layer skill where the bug lives.

{: .warning }
Production is treated as read-only. The agent queries logs, metrics, traces and read replicas, but doesn't run writes, migrations, restarts or data fixes without your explicit approval. It never pastes customer PII or secrets into chat, tickets or test fixtures.

## Default vs high-risk

| Level | Adds |
|---|---|
| **Default** (SEV3–SEV4, contained impact) | Gather evidence, trace one request, confirm the root cause, reproduce as a test, fix through the normal workflow |
| **High-risk** (SEV1–SEV2, data loss, security signs) | Recommend mitigation first and hand the decision to you, escalate security signs immediately, verify recovery in production signals, write the post-incident review |

## The process

1. **Triage**: impact, severity (SEV1–4), and what changed (deploys, flags, migrations, dependencies, traffic, third parties). For SEV1/SEV2, recommend mitigation such as rollback or flag-off before investigating.
2. **Gather evidence**: follow one request ID from the browser through the edge, API, database, queues and infra. Record UTC timestamps, release SHAs and example request IDs. Separate facts from assumptions.
3. **Hypothesize and test**: 2–4 ranked candidate causes, cheapest read-only checks first. The confirmed cause must explain **all** symptoms.
4. **Reproduce as a test**: at the lowest level that captures it. If it can't be reproduced, add targeted instrumentation instead of guessing a fix.
5. **Fix, verify, prevent**: fix the root cause, search for the same pattern elsewhere, ship through the normal pipeline, confirm recovery in production signals, and add the alert that should have caught it.
6. **Post-incident review**: blameless, with timeline, root cause, detection time and owned action items.

## Verify: proof required

| Check | Pass evidence |
|---|---|
| Evidence collected | UTC times, release SHAs and 2–3 example request IDs recorded |
| Request traced across layers | Same ID found in each layer; failing layer identified |
| Release comparison | Difference lines up with the suspected change, or the change is ruled out |
| Root cause explains everything | Every symptom accounted for |
| Reproduction test | Fails on the buggy code for the same reason seen in production |
| Fix works | Test passes; suite exit 0 |
| Production recovered | Error rate/latency back to baseline for an agreed window |

## Stops and hands back when

- Any write to production is needed: data fix, migration, config/flag change, restart, scaling or rollback.
- SEV1/SEV2: it recommends mitigation first and hands you the decision.
- There are signs of a security incident: it tells you immediately and points to your security incident process.
- It has no access to logs, metrics or traces: it lists exactly what evidence it needs.
- It can't reproduce the problem: it reports the hypotheses ruled in and out and proposes instrumentation.

## Anti-patterns it avoids

- Changing several things at once in production "to see if it helps"
- Restarting repeatedly before capturing evidence
- Declaring a fix without checking production signals
- Blaming frontend or backend without tracing the request across both
- Fixing data by hand with no script, backup or review

## References

`triage-playbook.md`: symptom → likely cause map and the post-incident review template.
