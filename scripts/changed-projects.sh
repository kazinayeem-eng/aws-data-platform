#!/usr/bin/env bash
# Print the projects a pull request needs to preview, one per line.
#
#   scripts/changed-projects.sh <base-ref>        (for example: origin/main)
#
# A change to shared pipeline files (scripts/, bootstrap/, .github/) means every
# project. Markdown files are ignored. A project without a stacks/ folder (for
# example one you have just deleted) is never listed.
set -euo pipefail

base="${1:?usage: changed-projects.sh <base-ref>}"
# Kept on its own line so a missing base ref stops the script instead of
# quietly reporting "no changes".
diff="$(git diff --name-only "${base}...HEAD")"
changed="$(printf '%s\n' "$diff" | grep -vE '\.md$' || true)"

if printf '%s\n' "$changed" | grep -qE '^(scripts/|bootstrap/|\.github/)'; then
  names="$(find projects -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || true)"
else
  names="$(printf '%s\n' "$changed" | sed -nE 's#^projects/([^/]+)/.*#\1#p')"
fi

printf '%s\n' "$names" | sort -u | while IFS= read -r name; do
  if [[ -n "$name" && -d "projects/${name}/stacks" ]]; then
    echo "$name"
  fi
done