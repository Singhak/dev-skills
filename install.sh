#!/usr/bin/env bash
# Installs the skill pack into a repository using the vendor-neutral layout.
#   Real files:  <repo>/.agents/skills/<skill>/    (Codex, Cursor, Copilot, Antigravity, others)
#   Link:        <repo>/.claude/skills -> ../.agents/skills   (Claude Code)
# Usage: ./install.sh /path/to/your-repo  [--copy]   (--copy duplicates instead of linking)
set -euo pipefail
REPO="${1:?Usage: ./install.sh /path/to/your-repo [--copy]}"
MODE="${2:-}"
SRC="$(cd "$(dirname "$0")" && pwd)"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if [ "$MODE" != "--copy" ]; then
      echo "Windows shell detected: Git Bash 'ln -s' silently copies unless Developer Mode is on."
      echo "Using --copy. For a real link, run install.ps1 in PowerShell (creates a junction, no admin needed)."
      MODE="--copy"
    fi;;
esac
SKILLS="dev-core backend-dev frontend-dev fullstack-integration ship-and-operate debug-production"

mkdir -p "$REPO/.agents/skills"
for s in $SKILLS; do
  rm -rf "$REPO/.agents/skills/$s"
  cp -R "$SRC/$s" "$REPO/.agents/skills/$s"
done
chmod +x "$REPO/.agents/skills/dev-core/scripts/security_scan.sh"
echo "Installed skills to $REPO/.agents/skills/"

if [ -e "$REPO/.claude/skills" ] && [ ! -L "$REPO/.claude/skills" ]; then
  # Existing real .claude/skills folder: add our skills alongside, don't replace it
  for s in $SKILLS; do rm -rf "$REPO/.claude/skills/$s"; cp -R "$SRC/$s" "$REPO/.claude/skills/$s"; done
  echo "Existing .claude/skills/ found: copied skills into it as well (keep both in sync when you edit)."
elif [ "$MODE" = "--copy" ]; then
  rm -rf "$REPO/.claude/skills"; mkdir -p "$REPO/.claude"; cp -R "$REPO/.agents/skills" "$REPO/.claude/skills"
  echo "Copied skills to $REPO/.claude/skills/ for Claude Code."
else
  mkdir -p "$REPO/.claude"; rm -f "$REPO/.claude/skills"
  ln -s ../.agents/skills "$REPO/.claude/skills"
  echo "Linked $REPO/.claude/skills -> ../.agents/skills for Claude Code."
fi

LINE='For every coding task, read `.agents/skills/dev-core/SKILL.md` first and follow its routing table to decide which other skills in `.agents/skills/` to read.'
if ! grep -qsF ".agents/skills/dev-core/SKILL.md" "$REPO/AGENTS.md"; then
  printf '\n## Skills\n%s\n' "$LINE" >> "$REPO/AGENTS.md"
  echo "Added skills line to $REPO/AGENTS.md"
fi
echo "Done. Commit .agents/, .claude/ and AGENTS.md so the team shares the same skills."
