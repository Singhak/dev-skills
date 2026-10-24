#!/usr/bin/env bash
# Scans ONLY the lines your change added (plus new untracked files) for high-signal dangerous patterns.
# Read-only. A hit is a lead to review, not proof of a vulnerability. Comment-only lines are skipped
# (except for the secrets check, since secrets in comments still leak).
#
# Usage:  bash diff_risk_scan.sh [base_ref]
#   default base: HEAD (uncommitted + staged changes). Use e.g. origin/main to scan a whole branch.
# Exit:   0 = no hits, 1 = hits to review, 2 = usage/environment error
set -uo pipefail
BASE="${1:-HEAD}"
git rev-parse --git-dir >/dev/null 2>&1 || { echo "diff_risk_scan: not a git repository." >&2; exit 2; }

EXCLUDES=(':(exclude)*.lock' ':(exclude)*lock.json' ':(exclude)*lock.yaml' ':(exclude)*.min.js' ':(exclude)*.snap')
ADDED=""
if git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; then
  ADDED=$(git diff "$BASE" --unified=0 --no-color -- . "${EXCLUDES[@]}" \
    | awk '/^\+\+\+ /{f=substr($0,7); next} /^@@/{split($3,a,","); n=substr(a[1],2); next} /^\+/{print f":"n": "substr($0,2); n++}')
elif [ "$BASE" != "HEAD" ]; then
  echo "diff_risk_scan: base '$BASE' not found." >&2; exit 2
fi
# New untracked files: every line counts as added (also covers repos with no commits yet)
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in *.lock|*lock.json|*lock.yaml|*.min.js|*.snap|*.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.woff*) continue;; esac
  grep -Iq . "$f" 2>/dev/null || continue   # skip binary
  ADDED+=$'\n'$(awk -v f="$f" '{print f":"NR": "$0}' "$f")
done < <(git ls-files --others --exclude-standard)
ADDED=$(printf '%s\n' "$ADDED" | sed '/^$/d')
[ -z "$ADDED" ] && { echo "diff_risk_scan: no added lines to scan (base: $BASE)."; exit 0; }

# Code lines only: drop lines whose content starts with a comment marker
CODE=$(printf '%s\n' "$ADDED" | grep -vE '^[^:]+:[0-9]+: *(//|#|\*|/\*|--|<!--|;)')

HITS=0
report() { # $1 label, $2 matching lines
  [ -z "$2" ] && return
  echo; echo "== $1 =="; printf '%s\n' "$2" | head -20; HITS=1
}
# match: lines in $1 matching ERE $2 (case-insensitive)
match() { printf '%s\n' "$1" | grep -Ei -- "$2" || true; }

# SQL: needs a real statement shape AND string building on the same line
SQL_SHAPE='\bselect\b.+\bfrom\b|\binsert\s+into\b|\bupdate\s+[a-z_."`]+\s+set\b|\bdelete\s+from\b'
SQL_BUILD='"\s*\+\s*[a-z_$]|'"'"'\s*\+\s*[a-z_$]|\$\{[^}]+\}|\.format\(|\bf"|\bf'"'"'|"\s*%\s*[a-z(]|%s.*%\s*\(|fmt\.Sprintf\(|String\.format\('
report "SQL built from strings (use parameterized queries)" "$(match "$(match "$CODE" "$SQL_SHAPE")" "$SQL_BUILD")"

# Shell execution: specific APIs only; '.exec(' (e.g. RegExp.exec, cursor.exec) is NOT matched
report "Shell / command execution (avoid shell strings built from input)" "$(match "$CODE" \
  'shell\s*=\s*True|shell\s*:\s*true|\bos\.system\(|\bos\.popen\(|\bchild_process\b|\bexecSync\(|(^|[^.a-z0-9_])exec\(|Runtime\.getRuntime\(\)\.exec|\bProcessBuilder\(|\bexec\.Command\(|\bpassthru\(|\bshell_exec\(|\bproc_open\(|Process\.Start\(')"

# Dynamic evaluation: bare eval( / new Function( only
report "Dynamic code evaluation" "$(match "$CODE" '(^|[^.a-z0-9_])eval\(|\bnew\s+Function\(')"

report "Raw HTML rendering (XSS risk; sanitize or avoid)" "$(match "$CODE" \
  'dangerouslySetInnerHTML|\bv-html\b|\[innerHTML\]|\.innerHTML\s*=|\.outerHTML\s*=|document\.write\(|\|\s*safe\b|\bmark_safe\(|\.html_safe\b|Html\.Raw\(|\{\{\{')"

report "Unsafe deserialization" "$(match "$CODE" \
  '\bpickle\.loads?\(|\byaml\.unsafe_load\(|\byaml\.load\([^)]*\)$|\bObjectInputStream\b|\bBinaryFormatter\b|\bMarshal\.load\b|\bunserialize\(')"

report "TLS verification disabled / weak randomness for secrets" "$(match "$CODE" \
  'verify\s*=\s*False|rejectUnauthorized\s*:\s*false|InsecureSkipVerify\s*:\s*true|NODE_TLS_REJECT_UNAUTHORIZED|Math\.random\(\).*(token|secret|password|otp)')"

# Logging: check variables passed to loggers, not words inside string literals
CODE_NOSTR=$(printf '%s\n' "$CODE" | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g; s/\`[^\`]*\`//g")
report "Logging possibly sensitive values" "$(match "$CODE_NOSTR" \
  '\b(log|logger|logging|console|print|println|fmt\.Print)[a-z.]*\(.*\b(password|passwd|token|secret|authorization|api_?key|cookie|ssn|card_?number)\b')"

# Secrets: scan ALL added lines (comments included); require a quoted value of 12+ chars or a known key format
report "Possible hard-coded secret" "$(match "$ADDED" \
  '(api[_-]?key|secret|passw(or)?d|access[_-]?token|auth[_-]?token|private[_-]?key|client[_-]?secret)["'"'"']?\s*[:=]\s*["'"'"'][^"'"'"' ]{12,}["'"'"']|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|sk_live_[A-Za-z0-9]{10,}|xox[baprs]-[A-Za-z0-9-]{10,}' \
  | grep -viE 'example|placeholder|changeme|your[_-]|<[a-z_]+>|\*\*\*|xxx' || true)"

echo
if [ "$HITS" -eq 0 ]; then echo "diff_risk_scan: no risky patterns in added lines (base: $BASE)."; exit 0
else echo "diff_risk_scan: review each hit. Fix true issues; list false positives in your report."; exit 1; fi
