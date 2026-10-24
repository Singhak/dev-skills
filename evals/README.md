# Evals (written, not yet run)

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

Run from a skill directory with Claude Code: `claude plugin eval . --allow-tools Write,Edit,Bash --scaffold` (real, billed model runs). The skill-creator skill can also run them one by one and help grade.
