#!/usr/bin/env bash
# Preview or apply one CloudFormation stack through a change set.
#
#   scripts/cfn-change.sh preview|apply <stack-dir> <environment>
#
# Expects AWS credentials in the environment, plus:
#   ORG_PREFIX    short prefix used in stack names (for example: acme)
#   CFN_ROLE_ARN  CloudFormation service role that creates the resources
set -euo pipefail

mode="${1:?usage: cfn-change.sh preview|apply <stack-dir> <environment>}"
stack_dir="${2:?missing stack directory}"
env_name="${3:?missing environment}"
: "${ORG_PREFIX:?ORG_PREFIX is not set}"
: "${CFN_ROLE_ARN:?CFN_ROLE_ARN is not set}"

case "$mode" in
  preview|apply) ;;
  *) echo "mode must be 'preview' or 'apply'" >&2; exit 2 ;;
esac

stack_dir="${stack_dir%/}"
short_name="$(basename "$stack_dir" | sed -E 's/^[0-9]+-//')"
stack_name="${ORG_PREFIX}-${env_name}-${short_name}"
template="${stack_dir}/template.yml"
params="${stack_dir}/${env_name}.json"
change_set="${mode}-${GITHUB_SHA:-local}-$(date +%s)"
summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

if [[ ! -f "$template" || ! -f "$params" ]]; then
  echo "Missing $template or $params" >&2
  exit 1
fi

# A stack that does not exist yet, or only exists as an empty preview shell,
# needs a CREATE change set. A stuck ROLLBACK_COMPLETE stack must be deleted first.
status="$(aws cloudformation describe-stacks --stack-name "$stack_name" \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo NONE)"
case "$status" in
  NONE|REVIEW_IN_PROGRESS) cs_type=CREATE ;;
  ROLLBACK_COMPLETE)
    echo "Stack $stack_name is in ROLLBACK_COMPLETE and must be deleted first (see runbook 11.2)." >&2
    exit 1 ;;
  *) cs_type=UPDATE ;;
esac

aws cloudformation create-change-set \
  --stack-name "$stack_name" \
  --change-set-name "$change_set" \
  --change-set-type "$cs_type" \
  --template-body "file://${template}" \
  --parameters "file://${params}" \
  --role-arn "$CFN_ROLE_ARN" \
  --tags "Key=Environment,Value=${env_name}" \
         "Key=ManagedBy,Value=cloudformation" \
         "Key=Repository,Value=${GITHUB_REPOSITORY:-local}" \
  --query Id --output text > /dev/null

if ! aws cloudformation wait change-set-create-complete \
    --stack-name "$stack_name" --change-set-name "$change_set" 2>/dev/null; then
  reason="$(aws cloudformation describe-change-set \
    --stack-name "$stack_name" --change-set-name "$change_set" \
    --query StatusReason --output text)"
  if [[ "$reason" == *"didn't contain changes"* || "$reason" == *"No updates are to be performed"* ]]; then
    echo "### ${stack_name}: no changes" >> "$summary"
    aws cloudformation delete-change-set --stack-name "$stack_name" --change-set-name "$change_set"
    exit 0
  fi
  echo "Change set for $stack_name failed: $reason" >&2
  exit 1
fi

details="$(aws cloudformation describe-change-set \
  --stack-name "$stack_name" --change-set-name "$change_set" --output json)"

{
  echo "### ${stack_name} (${cs_type})"
  echo
  echo "| Action | Logical ID | Type | Replacement |"
  echo "|---|---|---|---|"
  jq -r '.Changes[].ResourceChange
         | "| \(.Action) | \(.LogicalResourceId) | \(.ResourceType) | \(.Replacement // "-") |"' <<< "$details"
  echo
  if jq -e '[.Changes[].ResourceChange
             | select(.Action == "Remove" or .Replacement == "True" or .Replacement == "Conditional")]
            | length > 0' <<< "$details" > /dev/null; then
    echo "> **Warning:** this change removes or replaces at least one resource. Check DeletionPolicy and data impact before merging."
    echo
  fi
} >> "$summary"

if [[ "$mode" == preview ]]; then
  aws cloudformation delete-change-set --stack-name "$stack_name" --change-set-name "$change_set"
  exit 0
fi

aws cloudformation execute-change-set --stack-name "$stack_name" --change-set-name "$change_set"

if [[ "$cs_type" == CREATE ]]; then waiter=stack-create-complete; else waiter=stack-update-complete; fi
if ! aws cloudformation wait "$waiter" --stack-name "$stack_name"; then
  echo "Deployment of $stack_name failed. Failed events:" >&2
  aws cloudformation describe-stack-events --stack-name "$stack_name" --max-items 50 \
    --query "StackEvents[?contains(ResourceStatus, 'FAILED')].[LogicalResourceId,ResourceStatus,ResourceStatusReason]" \
    --output table >&2
  exit 1
fi

aws cloudformation update-termination-protection --stack-name "$stack_name" \
  --enable-termination-protection > /dev/null
echo "Deployed ${stack_name}"
