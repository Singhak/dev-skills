---
title: Testing the pack
nav_order: 5
permalink: /testing/
---

# Testing the pack
{: .no_toc }

1. TOC
{:toc}

---

{: .warning }
The trigger and task evals are written but **not yet run**. Run them before relying on the pack in your team.

## Run order, cheapest first

| # | What | Command | Cost |
|---|---|---|---|
| 1 | Scanner regression tests | `bash dev-core/tests/run_scan_tests.sh` | No model, seconds |
| 2 | Cross-skill routing | `python evals/run_trigger_evals.py --model <id>` | 96 cases × `--repeats` (default 3 = 288 short API calls) |
| 3 | Description tuning per skill | skill-creator `run_loop` | Several API calls per iteration |
| 4 | Task evals | `claude plugin eval` | Full agent runs, most expensive |

## Trigger evals: does the right skill load?

`evals/triggers/<skill>.json` holds 16 queries per skill: 8 that should trigger it and 8 that shouldn't. The negatives are near-misses that belong to a sibling skill or need no skill at all.

`run_trigger_evals.py` uses only the Python standard library and reads `ANTHROPIC_API_KEY`. It retries rate limits, 5xx and network errors with backoff, and saves results to `evals/trigger_results.json` after every case so an interrupted run isn't lost.

The same files work with the skill-creator description optimizer:

```bash
# from the skill-creator skill directory, in Claude Code
python -m scripts.run_loop --eval-set <pack>/evals/triggers/ship-and-operate.json \
  --skill-path <pack>/ship-and-operate --model <your-model-id> --max-iterations 5
```

## Task evals: does the agent follow the workflow?

Each `<skill>/evals/<case>/` folder uses the `claude plugin eval` format: `prompt.md`, `case.yaml`, `graders/` and, for cases with starting code, `files/` plus a `place-files.sh` scaffold script.

| Case | Checks |
|---|---|
| dev-core/trivial-typo-fast-path | Trivial tier: small change, one cheap check, short report, no full process |
| dev-core/idor-endpoint-high-risk | High-risk classification, ownership check, forbidden-access test, evidence table |
| dev-core/contradictory-tests-stop | Stop rule: finds contradictory tests, doesn't weaken them, hands back with options |
| backend-dev/coupon-double-redeem-race | High-risk handling, atomic limit enforcement, concurrency test, break-it round reported |
| frontend-dev/bio-rendering-xss | Sanitized rich text, safe link schemes, XSS payload tests, security pass reported |
| fullstack-integration/optimistic-update-rollback | Rollback on failure, test with a failing response, cache invalidation |
| ship-and-operate/no-apply-without-approval | Writes Terraform, runs only fmt/validate/plan, asks before apply |
| debug-production/prod-read-only | Recommends mitigation, refuses a prod migration without approval, asks for evidence |

Run from a skill directory with Claude Code (real, billed model runs):

```bash
claude plugin eval . --allow-tools Write,Edit,Bash --scaffold
```

{: .note }
The `coupon-double-redeem-race` fixture uses the built-in `node:sqlite` module and needs Node 22.13 or later.
