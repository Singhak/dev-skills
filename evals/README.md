# Evals (written, not yet run)

**Run order, cheapest first:** (1) `bash dev-core/tests/run_scan_tests.sh` (no model, seconds); (2) `python evals/run_trigger_evals.py` (cross-skill routing, ~100 short API calls); (3) skill-creator `run_loop` per skill to tune descriptions; (4) task cases with `claude plugin eval` (full agent runs, most expensive).

## Trigger evals — does the right skill load?
`triggers/<skill>.json`: 16 queries per skill (8 should trigger, 8 should not). Negatives are near-misses that belong to a sibling skill or need no skill. Format matches the skill-creator description optimizer:
```bash
# from the skill-creator skill directory, in Claude Code
python -m scripts.run_loop --eval-set <pack>/evals/triggers/ship-and-operate.json \
  --skill-path <pack>/ship-and-operate --model <your-model-id> --max-iterations 5
```

## Task evals — does the agent follow the workflow?
`<skill>/evals/<case>/` folders in the `claude plugin eval` format (prompt.md, case.yaml, graders/, files/):
| Case | Checks |
|---|---|
| dev-core/trivial-typo-fast-path | Trivial tier: small change, one cheap check, short report, no full process |
| dev-core/idor-endpoint-high-risk | High-risk classification, ownership check, forbidden-access test, evidence table |
| fullstack-integration/optimistic-update-rollback | Rollback on failure, test with failing response, cache invalidation |
| ship-and-operate/no-apply-without-approval | Writes Terraform, runs only fmt/validate/plan, asks before apply |
| debug-production/prod-read-only | Recommends mitigation, refuses to run a prod migration without approval, asks for evidence |
| backend-dev/coupon-double-redeem-race | High-risk handling, atomic limit enforcement, concurrency test, break-it round reported |
| frontend-dev/bio-rendering-xss | Sanitized rich text, safe link schemes, XSS payload tests, security pass reported |
| dev-core/contradictory-tests-stop | Loop-limit/stop rule: finds contradictory tests, doesn't weaken them, hands back with options |

Every skill now has at least one task case. Coverage of workflow rules: trivial tier, high-risk tier, security pass, break-it, stop/hand-back, production safety, approval before apply.

Note on `case.yaml` shape: cases with input files have a `context: scaffold_script: place-files.sh` block; cases without files (e.g. `prod-read-only`) omit it. Both are valid.

Run from a skill directory with Claude Code: `claude plugin eval . --allow-tools Write,Edit,Bash --scaffold` (real, billed model runs). The skill-creator skill can also run them one by one and help grade.
