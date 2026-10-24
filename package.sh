#!/usr/bin/env bash
# Builds one versioned .skill file per skill (a zip of the skill folder) into ./dist/
# for upload to Claude.ai / Claude Desktop. Version comes from the first "## x.y.z" heading in CHANGELOG.md.
# Usage: ./package.sh
# Zip tool: uses `zip`; falls back to Python 3, then PowerShell (Git Bash on Windows usually has no `zip`).
set -euo pipefail
cd "$(dirname "$0")"
SKILLS="dev-core backend-dev frontend-dev fullstack-integration ship-and-operate debug-production"
VERSION=$(grep -m1 -oE '^## [0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md | cut -d' ' -f2)
[ -n "$VERSION" ] || { echo "No '## x.y.z' version heading in CHANGELOG.md" >&2; exit 1; }
PY=$(command -v python3 || command -v python || true)
make_zip() { # $1 output, $2 skill folder (entries use forward slashes, evals excluded)
  if command -v zip >/dev/null; then
    zip -qr "$1" "$2" -x "$2/evals/*" "*/.DS_Store"
  elif [ -n "$PY" ]; then
    "$PY" - "$1" "$2" <<'PYEOF'
import os, sys, zipfile
out, root = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if x != "evals"]
        for f in files:
            if f != ".DS_Store":
                p = os.path.join(d, f); z.write(p, p.replace(os.sep, "/"))
PYEOF
  elif command -v powershell.exe >/dev/null; then
    echo "No zip or Python found; delegating to package.ps1" >&2
    powershell.exe -ExecutionPolicy Bypass -File package.ps1; exit $?
  else
    echo "Need zip, Python 3, or PowerShell to build packages." >&2; exit 2
  fi
}
rm -rf dist && mkdir -p dist
for s in $SKILLS; do
  head -1 "$s/SKILL.md" | grep -q '^---$' || { echo "$s/SKILL.md missing frontmatter" >&2; exit 1; }
  len=$(sed -n 's/^description: //p' "$s/SKILL.md" | head -1 | wc -c)
  [ "$len" -le 1024 ] || { echo "$s: description is $len chars (max 1024)" >&2; exit 1; }
  if sed -n 's/^description: //p' "$s/SKILL.md" | head -1 | grep -q ': '; then
    echo "$s: description contains ': ' which breaks unquoted YAML; rephrase or quote it" >&2; exit 1; fi
  make_zip "dist/$s-$VERSION.skill" "$s"
  echo "built dist/$s-$VERSION.skill (description: $((len-1)) chars)"
done
