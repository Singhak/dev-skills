#!/usr/bin/env bash
# Builds one .skill file per skill (a zip of the skill folder) into ./dist/ for upload to Claude.ai / Claude Desktop.
# Usage: ./package.sh
set -euo pipefail
cd "$(dirname "$0")"
SKILLS="dev-core backend-dev frontend-dev fullstack-integration ship-and-operate debug-production"
command -v zip >/dev/null || { echo "zip not found. Install zip, or on Windows run package.ps1." >&2; exit 2; }
rm -rf dist && mkdir -p dist
for s in $SKILLS; do
  head -1 "$s/SKILL.md" | grep -q '^---$' || { echo "$s/SKILL.md missing frontmatter" >&2; exit 1; }
  len=$(sed -n 's/^description: //p' "$s/SKILL.md" | head -1 | wc -c)
  [ "$len" -le 1024 ] || { echo "$s: description is $len chars (max 1024)" >&2; exit 1; }
  if sed -n 's/^description: //p' "$s/SKILL.md" | head -1 | grep -q ': '; then
    echo "$s: description contains ': ' which breaks unquoted YAML; rephrase or quote it" >&2; exit 1; fi
  (zip -qr "dist/$s.skill" "$s" -x "$s/evals/*" "*/.DS_Store")
  echo "built dist/$s.skill (description: $((len-1)) chars)"
done
