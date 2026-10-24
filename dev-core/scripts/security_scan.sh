#!/usr/bin/env bash
# Runs whichever security tools are installed locally. Read-only: never modifies code.
# Usage: bash security_scan.sh [project_dir]
set -uo pipefail
DIR="${1:-.}"
cd "$DIR" || exit 1
FOUND=0
run() { echo; echo "=== $1 ==="; shift; "$@"; echo "(exit code: $?)"; FOUND=1; }
has() { command -v "$1" >/dev/null 2>&1; }

# Secret scanning
has gitleaks   && run "gitleaks (secrets)" gitleaks detect --no-banner --redact -s .
has trufflehog && run "trufflehog (secrets)" trufflehog filesystem . --no-update --only-verified

# Dependency audits by ecosystem
if [ -f package-lock.json ] && has npm; then run "npm audit" npm audit --audit-level=high; fi
if [ -f pnpm-lock.yaml ] && has pnpm; then run "pnpm audit" pnpm audit --audit-level high; fi
if [ -f yarn.lock ] && has yarn; then run "yarn audit" yarn npm audit 2>/dev/null || yarn audit; fi
if { [ -f requirements.txt ] || [ -f pyproject.toml ]; } && has pip-audit; then run "pip-audit" pip-audit; fi
if [ -f go.mod ] && has govulncheck; then run "govulncheck" govulncheck ./...; fi
if [ -f Cargo.toml ] && has cargo-audit; then run "cargo audit" cargo audit; fi
if ls ./*.sln ./*.csproj >/dev/null 2>&1 && has dotnet; then run "dotnet vulnerable packages" dotnet list package --vulnerable --include-transitive; fi
if [ -f Gemfile.lock ] && has bundle-audit; then run "bundle-audit" bundle-audit check --update; fi

# Multi-ecosystem / SAST
has osv-scanner && run "osv-scanner" osv-scanner -r .
has trivy       && run "trivy fs" trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL .
has semgrep     && run "semgrep (SAST)" semgrep scan --config auto --error --quiet
if has bandit && ls ./*.py ./**/*.py >/dev/null 2>&1; then run "bandit (Python SAST)" bandit -r . -q -x ./node_modules,./.venv,./venv; fi
has gosec && [ -f go.mod ] && run "gosec (Go SAST)" gosec ./...

if [ "$FOUND" -eq 0 ]; then
  echo "No security scanners found. Suggest installing: gitleaks, semgrep, osv-scanner or trivy, plus the ecosystem audit tool."
  echo "Fall back to the manual checklist in references/security-checklist.md."
fi
