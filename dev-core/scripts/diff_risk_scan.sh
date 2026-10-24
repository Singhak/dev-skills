#!/usr/bin/env bash
# Scans ONLY the lines added by your change for common dangerous patterns.
# Read-only. Hits are leads to review, not proof of a vulnerability.
# Usage: bash diff_risk_scan.sh [base_ref]   (default: compares working tree + staged against HEAD;
#        pass e.g. origin/main to scan a whole branch)
set -uo pipefail
BASE="${1:-HEAD}"
if ! git rev-parse --git-dir >/dev/null 2>&1; then echo "Not a git repository."; exit 2; fi

ADDED=$(git diff "$BASE" --unified=0 --no-color -- . ':(exclude)*.lock' ':(exclude)*lock.json' ':(exclude)*.min.js' \
  | awk '/^\+\+\+ /{f=substr($0,7); next} /^@@/{split($3,a,","); n=substr(a[1],2); next} /^\+/{print f":"n": "substr($0,2); n++}')
# Include new files not yet tracked by git (every line counts as added)
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in *.lock|*lock.json|*.min.js|*.png|*.jpg|*.gif|*.pdf|*.zip) continue;; esac
  ADDED+=$'\n'$(awk -v f="$f" '{print f":"NR": "$0}' "$f" 2>/dev/null)
done < <(git ls-files --others --exclude-standard)
ADDED=$(printf '%s\n' "$ADDED" | sed '/^$/d')
[ -z "$ADDED" ] && { echo "No added lines to scan (base: $BASE)."; exit 0; }

HITS=0
check() { # $1 label, $2 extended regex
  local out; out=$(printf '%s\n' "$ADDED" | grep -nEi -- "$2" | cut -d: -f2-)
  if [ -n "$out" ]; then echo; echo "== $1 =="; printf '%s\n' "$out" | head -20; HITS=1; fi
}

check "SQL built from strings (use parameterized queries)" \
  '(select|insert|update|delete)\b.*(\+ *[a-z_]|\$\{|%s|" *%|f"|\.format\()'
check "Shell / command execution (avoid shell strings with input)" \
  '(shell *= *true|os\.system\(|subprocess\.(call|run|popen)\(.*shell|child_process|exec\(|execSync\(|Runtime\.getRuntime\(\)\.exec|ProcessBuilder\(|`[^`]*\$\{)'
check "Dynamic code evaluation" \
  '(\beval\(|new Function\(|setTimeout\( *["'"'"']|\bexec\( *compile)'
check "Raw HTML rendering (XSS risk; sanitize or avoid)" \
  '(dangerouslySetInnerHTML|v-html|\[innerHTML\]|\.innerHTML *=|outerHTML *=|document\.write\(|\|safe\b|mark_safe\(|html_safe|Html\.Raw\()'
check "Unsafe deserialization" \
  '(pickle\.loads?\(|yaml\.(unsafe_)?load\(|ObjectInputStream|BinaryFormatter|Marshal\.load|unserialize\()'
check "Possible hard-coded secret" \
  '((api[_-]?key|secret|passw(or)?d|token|private[_-]?key|client[_-]?secret)["'"'"' ]*[:=] *["'"'"'][^"'"'"' ]{8,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC )?PRIVATE KEY|ghp_[A-Za-z0-9]{30,}|sk_live_[A-Za-z0-9]{10,})'
check "TLS verification disabled / weak crypto" \
  '(verify *= *false|rejectUnauthorized *: *false|InsecureSkipVerify *: *true|\bmd5\(|\bsha1\(|Math\.random\(\).*(token|id|secret))'
check "Logging possibly sensitive values" \
  '(log|logger|console)\.[a-z]+\(.*(password|token|secret|authorization|cookie|ssn|card)'

echo
if [ "$HITS" -eq 0 ]; then echo "diff_risk_scan: no risky patterns in added lines (base: $BASE)."
else echo "diff_risk_scan: review each hit above. Fix true issues; note false positives in your report."; fi
