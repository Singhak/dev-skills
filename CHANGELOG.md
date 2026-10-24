# Changelog

## 1.1.0 — 2026-10-24
### Added
- Task evals for backend-dev (coupon double-redeem race), frontend-dev (rich-text XSS) and the stop rule (contradictory tests); every skill now has at least one case.
- `evals/run_trigger_evals.py`: cross-skill routing eval (stdlib only, uses ANTHROPIC_API_KEY); recommended eval run order.
- Version-stamped package filenames; Python and PowerShell fallbacks in `package.sh` when `zip` is missing.
- Explicit out-of-scope note (native mobile, data/ML, embedded, games) in dev-core routing.
### Changed
- Layer skills' break-it lists reduced to layer-specific attacks; generic attacks live only in `break-it.md`.
- Specialist sections moved to references (backend observability/performance, frontend product quality/performance, fullstack domain modeling/real-time). Full-stack load ≈ 11.0k tokens (was ≈ 12.0k).
- Execution-policy instructions for `install.ps1` / `package.ps1`.
### Fixed
- `package.ps1` failed outside Windows (`$env:TEMP`) and used `Compress-Archive`, whose Windows PowerShell 5.1 version can write backslash paths; now writes forward-slash zip entries directly. Tested under PowerShell 7.

## 1.0.0 — 2026-10-24
### Added
- Six skills: dev-core, backend-dev, frontend-dev, fullstack-integration, ship-and-operate, debug-production.
- Trivial / default / high-risk tiers in dev-core; environment check; smallest-relevant baseline.
- Five-action security pass; `diff_risk_scan.sh` with regression tests (`dev-core/tests/run_scan_tests.sh`).
- Break-it (adversarial self-test) step with playbook and report template.
- Verify tables (evidence required) and stop/hand-back rules in every skill.
- Special task guides: dependency upgrades, refactor-only, merge conflicts, performance, release notes.
- Worked report example; Python and Go API authorization test examples.
- `install.sh` / `install.ps1`, `package.sh` / `package.ps1`; trigger and task evals (not yet run).
### Changed
- dev-core trimmed to a short default flow; detail moved to `references/`.
- Layer-skill Definition of Done sections folded into their Verify tables; one combined report.
### Fixed
- `diff_risk_scan.sh` false positives (`.exec(` on regexes, SQL keywords in comments/strings); no-commit repos.
- `security_scan.sh` now exits 1 on findings and 2 when no scanner ran.
