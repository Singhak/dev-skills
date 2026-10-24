#!/usr/bin/env bash
# Regression test for diff_risk_scan.sh: true positives must be flagged, known false positives must not.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; SCAN="$HERE/../scripts/diff_risk_scan.sh"
fail=0
run_case() { # $1 expect(flag|clean) $2 filename $3 content
  local d; d=$(mktemp -d); (cd "$d" && git init -q && printf '%s\n' "$3" > "$2" && bash "$SCAN" >/tmp/scan_out 2>&1); local rc=$?
  if { [ "$1" = flag ] && [ $rc -ne 1 ]; } || { [ "$1" = clean ] && [ $rc -ne 0 ]; }; then
    echo "FAIL ($1): $2 :: $3"; sed 's/^/    /' /tmp/scan_out; fail=1
  else echo "ok   ($1): $3"; fi
  rm -rf "$d"
}
# ---- must flag ----
run_case flag a.py 'q = "SELECT * FROM users WHERE id = " + user_id'
run_case flag a.py 'cur.execute(f"DELETE FROM orders WHERE id = {oid}")'
run_case flag a.js 'db.query(`UPDATE users SET name = ${name} WHERE id = 1`)'
run_case flag a.go 'q := fmt.Sprintf("SELECT * FROM t WHERE id = %s", id)'
run_case flag a.py 'subprocess.run(cmd, shell=True)'
run_case flag a.js 'const { exec } = require("child_process")'
run_case flag a.py 'exec(user_code)'
run_case flag a.js 'eval(input)'
run_case flag a.js 'el.innerHTML = name'
run_case flag a.jsx '<div dangerouslySetInnerHTML={{ __html: bio }} />'
run_case flag a.py 'data = pickle.loads(body)'
run_case flag a.py 'requests.get(url, verify=False)'
run_case flag a.js 'logger.info("login", { password })'
run_case flag a.py 'API_KEY = "sk_live_abcdefghijklmnop"'
run_case flag a.ts 'const clientSecret = "9f8e7d6c5b4a39281706"'
# ---- must stay clean (known false positives) ----
run_case clean a.js 'const m = /a(b)/.exec(s)'
run_case clean a.js '// update the total + count'
run_case clean a.py '# select the best item from the list + extra'
run_case clean a.js 'const label = "Update " + count + " items"'
run_case clean a.py 'print("%s items" % n)'
run_case clean a.js 'const msg = `Selected ${n} from list`'
run_case clean a.js 'retval = cursor.exec(stmt, params)'
run_case clean a.py 'q = "SELECT * FROM users WHERE id = %s"; cur.execute(q, (uid,))'
run_case clean a.js 'const evaluate = (x) => x * 2'
run_case clean a.ts 'const apiKey = process.env.API_KEY'
run_case clean a.env.example 'API_KEY="your-api-key-here-placeholder"'
run_case clean a.js 'console.log("token refreshed")'
echo; [ $fail -eq 0 ] && echo "All scanner cases passed." || { echo "Scanner regression failures."; exit 1; }
