---
name: dev-core
description: Core engineering workflow for any software change, backend or frontend, in any language. Covers understanding the task, planning, test-driven development (red-green-refactor), the test pyramid (unit, integration, e2e), security checks, an adversarial "break it" phase where the agent attacks its own feature like a hacker and fixes what it finds, code quality, and a definition of done. Use this skill whenever you are asked to write, change, fix, refactor or review code, add a feature, fix a bug, add tests, or harden security, even if the user doesn't mention testing or TDD. For server/API/database work also load backend-dev; for UI/browser work also load frontend-dev.
---

# Dev Core — Default Engineering Flow

Used on every coding task. Keep this flow short for small changes; open the reference files only when a step needs more depth. Goal: every change is **tested first, attacked by its author, secure, small, and proven with evidence**.

## Which other skills to load
| Load | When the task… | Not when… |
|---|---|---|
| `backend-dev` | touches server code, APIs, DB, migrations, jobs, CLIs | UI-only |
| `frontend-dev` | touches UI components, pages, forms, client state | server-only |
| `fullstack-integration` | touches both sides of an API, consumes a new/changed endpoint, changes a contract, or fixes stale-data / type-mismatch / unhandled-error bugs | one side only, contract unchanged |
| `ship-and-operate` | changes CI/CD, Docker, IaC, env vars/secrets, health checks, monitoring, flags, or prepares a release | ordinary feature work |
| `debug-production` | investigates a problem in a **deployed** environment | bug found while coding locally |

Out of scope for stack-specific guidance: native mobile UI (Swift/Kotlin), data/ML pipelines, embedded and game engines. For those, apply this skill's workflow, follow the project's own conventions, and tell the user the layer skills don't cover that stack.

Pull skills in mid-task when the work turns out to need them (e.g. a feature needs a new env var → `ship-and-operate`).

**Combining skills:** this skill owns the workflow, the common checks and the report. Other skills add only their layer-specific steps, Verify rows and stop rules — don't repeat dev-core checks for each skill. Produce **one** combined evidence table and one report, however many skills are loaded.

## Step 0 — Classify the change
| Tier | What qualifies | Flow |
|---|---|---|
| **Trivial** | No behaviour change: typo or wording in docs/comments/UI copy, formatting, renaming a local variable, a dependency-free config value with no logic impact | Make the change → run the **one cheapest check** that would catch a mistake (lint, type-check, the nearest test file, or build) → read your diff → one-line report with that check's result. Skip baseline, TDD, security pass and break-it. |
| **Default** | Any behaviour change that isn't high-risk | Steps 1–8 below |
| **High-risk** | Touches auth/permissions, money, personal data, file/OS/shell access, a public API or event contract, a DB schema/migration, concurrency/background jobs, infra/deploy config, or fixes a security bug | Steps 1–8 plus the high-risk additions below |

Rules: if a "trivial" edit touches logic, user input, permissions or data, it isn't trivial. When unsure between tiers, pick the higher one. Special task types (dependency upgrade, refactor-only, merge conflict, performance work, release notes) have short guides in `references/workflow-details.md` §5.

High-risk adds: explicit acceptance criteria, a design note for new domain/schema/events (`backend-dev/references/data-design.md`), integration tests on real dependencies, the full security checklist, two break-it rounds with a threat list, a feature-flag and rollback recommendation, and a request for human review.

## Step 1 — Understand and check the environment
1. Restate the task in 1–2 sentences; write acceptance criteria as Given/When/Then if missing.
2. Read build files, CI config, lint config and nearby tests. **Use the project's tools and conventions**; don't introduce new ones.
3. Environment check: repo size (single project or monorepo), available commands (CI config is the best source; see `references/project-discovery.md`), installed tools, Docker, network, CI/cloud access. Installing dependencies the project already declares is fine; adding new tools needs the user's OK. If a check can't run, use the closest weaker check and report the original as "not verified".
4. **Baseline: run the smallest relevant existing suite for the affected area** (the package/module or test files covering the code you'll change). Broaden only when justified: you're changing shared/core code, a public interface, or build config — then include dependents (`nx affected`, `turbo --filter=...[HEAD]`, `pnpm --filter "...<pkg>"`, Bazel `rdeps`, Pants `--changed-dependents`, `gradle :module:test`). Record the scope. Note pre-existing failures; don't fix them silently.
5. Ask only when a decision is ambiguous and expensive to reverse; otherwise state the assumption and proceed.

## Step 2 — Plan small
Slices that each end green. For each: behaviour, test that proves it, files touched.

## Step 3 — TDD
**Red** (one failing test; confirm it fails on the assertion) → **Green** (minimum code) → **Refactor** (stay green). Bug fix: reproduce it in a failing test first. If TDD is impractical (spike, legacy without seams), say so and add characterization tests before changing code. Test behaviour through public interfaces; mock only what you don't own or what's non-deterministic; no sleeps. Test levels and rules: `references/workflow-details.md` §1; TDD depth: `references/tdd.md`.

## Step 4 — Quick security pass (every change)
Do these five actions on **your diff** and write one result line for each in the report:
1. **Inputs**: list every external input your change reads (body, params, headers, files, env, messages, third-party responses). For each, point to where it's validated (type, length, format). Missing → add validation + a test.
2. **Dangerous sinks**: run `bash <dev-core skill folder>/scripts/diff_risk_scan.sh` (exit 0 = clean, 1 = hits to review). It scans only your added lines for string-built SQL, shell execution, eval, raw HTML rendering, unsafe deserialization, disabled TLS, sensitive logging and hard-coded secrets. Review each hit: fix true issues, list false positives in the report. Then look for the same risks in your diff yourself — the scanner catches common patterns, not all of them.
3. **Permissions**: for each new or changed endpoint/action, name the line that checks the caller may act on **this specific record**. Write one test proving another user is refused (403/404).
4. **Secrets and logs**: confirm no secrets, tokens or personal data are added to code, tests, logs, error messages or client bundles.
5. **Tooling**: run the project's security tooling (CI security job, audit script). If none, run `scripts/security_scan.sh` (exit 0 = passed, 1 = findings, 2 = no scanner available). Exit 2 or no tooling at all → report the scan as "not verified". New dependency added → run the ecosystem audit.

High-risk: also go through `references/security-checklist.md` in full.

## Step 5 — Quality gates
Format → lint → type-check → relevant tests (same scope as baseline, widened if you touched more) → security tooling → build. Never claim a gate passed that didn't run.

## Step 6 — Break it
Switch roles: attack your own feature to make it fail, leak or misbehave — **only your code, locally or in a test environment you control**. Default: one round on the inputs and permissions you touched (malformed/oversized input, other user's IDs, double-submit). High-risk: threat list (STRIDE) and at least two rounds, including concurrency, replay and dependency failure. Every successful attack → failing test → fix → green. Playbook and report template: `references/break-it.md`. Critical/High findings must be fixed before done.

## Step 7 — Review your diff
Read it as a strict reviewer (`references/code-review.md`): no debug code, unrelated changes, or TODOs without a ticket; docs updated if behaviour changed. PR description template: `references/workflow-details.md` §3.

## Step 8 — Verify and report
**No evidence, no claim.** Report each check with its command and observed result; anything not run is "not verified".

| Check | Pass evidence |
|---|---|
| Baseline | Scope and result recorded |
| New test fails first | Fails on an assertion, not an import/syntax error |
| Format / lint / types | Exit 0 |
| Relevant tests after change | Exit 0; test count increased |
| Security pass | Five result lines (Step 4); scanner ran or "not verified" |
| Break it | Attacks tried, findings fixed with tests |
| Build | Exit 0 |

Report: what changed and why · evidence table · tests added · security and break-it results · assumptions, unverified checks, follow-ups. Worked example: `references/report-example.md`.

## Stop and hand back
- **Done**: every check above has evidence. Don't add unrequested features.
- **Blocked**: missing access, credentials, environment or dependency. Report what couldn't be verified; don't silently substitute a weaker setup.
- **Decision needed**: ambiguous requirement, breaking API/schema change, deleting behaviour or data, new major dependency or platform, scope creep.
- **Risk line**: unfixed Critical/High finding, or any step that would write to a shared or production environment.
- **Loop limit**: same failure after **3** distinct fix attempts — stop, summarize what you tried, propose options.

## Reference files
- `references/workflow-details.md` — test levels and rules, design principles, git/PR template, full Definition of Done, special task types
- `references/report-example.md` — a complete final report for a default and a trivial change
- `references/tdd.md` — TDD depth, test doubles, test data, legacy code
- `references/security-checklist.md` — full OWASP-aligned checklist (high-risk changes)
- `references/break-it.md` — attack playbook, payloads, Break-It Report template
- `references/code-review.md` — self-review checklist
- `references/project-discovery.md` — commands and conventions per ecosystem
- `scripts/diff_risk_scan.sh` — scans added lines of your diff for dangerous patterns (regression tests: `tests/run_scan_tests.sh`)
- `scripts/security_scan.sh` — fallback runner for installed audit / secret / SAST tools
