#!/usr/bin/env bash
# Preview or apply every stack of one project, in folder order.
#
#   scripts/cfn-project.sh preview|apply <project> <environment> [--only <folder>] [--skip <folder>]
#
# Stacks live in projects/<project>/stacks/<NN-name>/ and run in name order, so
# 00-foundation goes before 01-pipeline. A folder without a template.yml is skipped.
# Needs the same environment variables as scripts/cfn-change.sh.
set -euo pipefail

mode="${1:?usage: cfn-project.sh preview|apply <project> <environment> [--only <folder>] [--skip <folder>]}"
project="${2:?missing project}"
env_name="${3:?missing environment}"
shift 3

only=""
skip=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --only) only="${2:?--only needs a stack folder name}"; shift 2 ;;
    --skip) skip="${2:?--skip needs a stack folder name}"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

case "$mode" in
  preview|apply) ;;
  *) echo "mode must be 'preview' or 'apply'" >&2; exit 2 ;;
esac
project_pattern='^[a-z][a-z0-9-]{1,19}$'
if [[ ! "$project" =~ $project_pattern ]]; then
  echo "Invalid project name: $project (use 2 to 20 lower-case letters, digits or hyphens, starting with a letter)" >&2
  exit 2
fi

root="projects/${project}/stacks"
if [[ ! -d "$root" ]]; then
  echo "No such project: $root does not exist" >&2
  exit 1
fi

shopt -s nullglob
count=0
for dir in "$root"/*/; do
  name="$(basename "$dir")"
  if [[ ! -f "${dir}template.yml" ]]; then
    echo "skip ${dir}: no template.yml"
    continue
  fi
  if [[ -n "$only" && "$name" != "$only" ]]; then continue; fi
  if [[ -n "$skip" && "$name" == "$skip" ]]; then continue; fi
  count=$((count + 1))
  ./scripts/cfn-change.sh "$mode" "$dir" "$env_name"
done

echo "${mode}: ${count} stack(s) in project ${project}"