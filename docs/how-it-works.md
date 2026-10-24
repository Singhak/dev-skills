---
title: How it works
nav_order: 3
permalink: /how-it-works/
---

# How it works
{: .no_toc }

1. TOC
{:toc}

---

## Triggering

Agents always see only each skill's name and description. The full instructions load only when the task matches. Each description says both when to use the skill and when **not** to, so `ship-and-operate` stays out of normal feature work and `debug-production` stays out of local bugs.

`dev-core` also contains a routing table, including mid-task triggers. For example, a feature that suddenly needs a new environment variable pulls in `ship-and-operate`.

### Typical combinations

| Task | Skills loaded |
|---|---|
| New API endpoint | dev-core + backend-dev |
| New screen calling an existing API | dev-core + frontend-dev + fullstack-integration |
| Full feature, UI to DB | dev-core + backend-dev + frontend-dev + fullstack-integration |
| Add Redis, new env vars, deploy | the above + ship-and-operate |
| "Checkout is failing in prod" | dev-core + debug-production (+ layer skills once the cause is clear) |

**Combining skills:** `dev-core` owns the workflow, the common checks and the report. The other skills add only their layer-specific steps, Verify rows and stop rules. However many skills are loaded, the agent produces **one** combined evidence table and one report.

## Risk tiers

Every change is classified first. When unsure, the agent picks the higher tier.

| Tier | What qualifies | Flow |
|---|---|---|
| **Trivial** | No behaviour change: typos, wording, formatting, renaming a local variable | Make the change, run the one cheapest check that would catch a mistake, read the diff, one-line report |
| **Default** | Any behaviour change that isn't high-risk | The full workflow below |
| **High-risk** | Auth/permissions, money, personal data, file/OS/shell access, public API or event contracts, schema/migrations, concurrency, infra/deploy config, security fixes | The full workflow plus acceptance criteria, a design note, integration tests on real dependencies, the full security checklist, two break-it rounds, a flag and rollback recommendation, and a request for human review |

## The workflow every change follows

```
Classify risk
  → Understand + environment check + smallest relevant baseline
  → Plan small slices
  → TDD (red → green → refactor)
  → Five-action security pass
  → Quality gates (format, lint, types, tests, security tooling, build)
  → Break it
  → Review the diff
  → Verify with evidence and report
```

`dev-core` is kept short (about 100 lines) because it loads on every task. Depth lives in its `references/` folder and is opened only when a step needs it.

### The five-action security pass

Run on every non-trivial diff, with one result line each in the report:

1. **Inputs**: every external input the change reads, and where it's validated.
2. **Dangerous sinks**: `diff_risk_scan.sh` scans added lines for string-built SQL, shell execution, `eval`, raw HTML rendering, unsafe deserialization, disabled TLS, sensitive logging and hard-coded secrets. Each hit is reviewed.
3. **Permissions**: for each new or changed endpoint, the line that checks the caller may act on *this specific record*, plus a test proving another user is refused.
4. **Secrets and logs**: no secrets, tokens or personal data in code, tests, logs, errors or client bundles.
5. **Tooling**: the project's security tooling, or the fallback `security_scan.sh`. If nothing could run, the scan is reported as "not verified".

### Break it

The agent switches roles and attacks its own feature to make it fail, leak or misbehave, but **only its own code, locally or in a test environment it controls**. Default changes get one round on the touched inputs and permissions (malformed or oversized input, other users' IDs, double-submit). High-risk changes get a STRIDE threat list and at least two rounds, including concurrency, replay and dependency failure. Every successful attack becomes a failing test, then a fix. Critical and High findings must be fixed before the work counts as done.

## Evidence and exit conditions

**No evidence, no claim.** Every skill has a *Verify: proof required* table listing the check, example commands, and the observed output that counts as passing. Checks that couldn't run are reported as "not verified".

**Stop and hand back.** Every skill lists when the agent must stop and return control:

| Condition | Meaning |
|---|---|
| **Done** | Every check has evidence |
| **Blocked** | Missing access, credentials, environment or dependency |
| **Decision needed** | Breaking change, destructive operation, ambiguous requirement, scope change |
| **Risk line** | An unfixed Critical/High finding, or any write to a shared or production environment |
| **Loop limit** | The same failure after 3 distinct fix attempts |

The final report always includes the evidence and, if there is one, the specific decision or question for you.

## Safety defaults

The agent attacks only its own code in local or test environments. It never deploys, applies infrastructure, runs migrations or touches production data without explicit approval in the conversation. When debugging production it treats production as read-only and never pastes customer PII or secrets into chat, tickets or fixtures.
