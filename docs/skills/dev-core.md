---
title: dev-core
parent: Skills
nav_order: 1
permalink: /skills/dev-core/
---

# dev-core
{: .no_toc }

The default engineering flow, used on every coding task. It owns the workflow, the common checks, the routing table and the single combined report.
{: .fs-5 .fw-300 }

[View SKILL.md](https://github.com/Singhak/dev-skills/blob/master/dev-core/SKILL.md){: .btn .btn-outline }

1. TOC
{:toc}

---

## Loads when

You ask the agent to write, change, fix, refactor or review code, add a feature, fix a bug, add tests or harden security, even if you don't mention testing.

## Routing table

| Load | When the task… | Not when… |
|---|---|---|
| `backend-dev` | touches server code, APIs, DB, migrations, jobs, CLIs | UI-only |
| `frontend-dev` | touches UI components, pages, forms, client state | server-only |
| `fullstack-integration` | touches both sides of an API, consumes a new or changed endpoint, changes a contract, or fixes stale-data / type-mismatch / unhandled-error bugs | one side only, contract unchanged |
| `ship-and-operate` | changes CI/CD, Docker, IaC, env vars/secrets, health checks, monitoring, flags, or prepares a release | ordinary feature work |
| `debug-production` | investigates a problem in a **deployed** environment | a bug found while coding locally |

Native mobile UI, data/ML pipelines, embedded and game engines are out of scope for stack-specific guidance. For those, the agent applies the dev-core workflow, follows the project's own conventions and tells you the layer skills don't cover that stack.

## Steps

| Step | What happens |
|---|---|
| 0. Classify | Trivial, default or high-risk (see [risk tiers]({{ '/how-it-works/#risk-tiers' | relative_url }})) |
| 1. Understand | Restate the task, write Given/When/Then criteria, read build/CI/lint config, check the environment, run the smallest relevant baseline suite |
| 2. Plan | Small slices that each end green |
| 3. TDD | Red → green → refactor; bug fixes start with a failing reproduction |
| 4. Security pass | Five actions on the diff: inputs, dangerous sinks, permissions, secrets and logs, tooling |
| 5. Quality gates | Format → lint → type-check → tests → security tooling → build |
| 6. Break it | Attack your own feature; every successful attack → failing test → fix |
| 7. Review | Read the diff as a strict reviewer |
| 8. Verify and report | Evidence table with commands and observed results |

## Verify: proof required

| Check | Pass evidence |
|---|---|
| Baseline | Scope and result recorded |
| New test fails first | Fails on an assertion, not an import or syntax error |
| Format / lint / types | Exit 0 |
| Relevant tests after change | Exit 0; test count increased |
| Security pass | Five result lines; scanner ran or "not verified" |
| Break it | Attacks tried, findings fixed with tests |
| Build | Exit 0 |

## Scripts

- `scripts/diff_risk_scan.sh`: scans only the **added lines** of your diff for string-built SQL, shell execution, `eval`, raw HTML rendering, unsafe deserialization, disabled TLS, sensitive logging and hard-coded secrets. Exit 0 = clean, 1 = hits to review. Regression tests: `tests/run_scan_tests.sh`.
- `scripts/security_scan.sh`: fallback runner for installed audit, secret and SAST tools. Exit 0 = passed, 1 = findings, 2 = no scanner available.

## References

| File | Contents |
|---|---|
| `workflow-details.md` | Test levels and rules, design principles, git/PR template, full Definition of Done, special task types (dependency upgrade, refactor-only, merge conflict, performance, release notes) |
| `report-example.md` | Complete final reports for a default and a trivial change |
| `tdd.md` | TDD depth, test doubles, test data, legacy code |
| `security-checklist.md` | Full OWASP-aligned checklist for high-risk changes |
| `break-it.md` | Attack playbook, payloads, Break-It Report template |
| `code-review.md` | Self-review checklist |
| `project-discovery.md` | Commands and conventions per ecosystem |
