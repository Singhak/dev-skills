# Changelog

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
