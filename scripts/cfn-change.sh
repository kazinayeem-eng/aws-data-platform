#!/usr/bin/env bash
# Preview or apply one CloudFormation stack through a change set.
#
#   scripts/cfn-change.sh preview|apply <stack-dir> <environment>
#   scripts/cfn-change.sh name <stack-dir> <environment>   (prints the stack name and stops)
#
# <stack-dir> must look like projects/<project>/stacks/<NN-name>. The stack is
# named <ORG_PREFIX>-<environment>-<project>-<name>, so two projects can both
# have a stack folder called 00-bucket without colliding.
#
# Every mode needs ORG_PREFIX (for example: acme). preview and apply also need
# AWS credentials and a Region in the environment, and CFN_ROLE_ARN, the
# CloudFormation service role that creates the resources.
set -euo pipefail

mode="${1:?usage: cfn-change.sh preview|apply|name <stack-dir> <environment>}"
stack_dir="${2:?missing stack directory}"
env_name="${3:?missing environment}"
: "${ORG_PREFIX:?ORG_PREFIX is not set}"

case "$mode" in
  preview|apply|name) ;;
  *) echo "mode must be 'preview', 'apply' or 'name'" >&2; exit 2 ;;
esac
case "$env_name" in
  dev|prod) ;;
  *) echo "environment must be 'dev' or 'prod', got: $env_name" >&2; exit 2 ;;
esac

# The folder decides the stack name: projects/<project>/stacks/<NN->name.
stack_dir="${stack_dir%/}"
folder_pattern='^(\./)?projects/([a-z][a-z0-9-]{1,19})/stacks/([0-9]+-)?([a-z][a-z0-9-]*)$'
if [[ ! "$stack_dir" =~ $folder_pattern ]]; then
  echo "Stack folder must look like projects/<project>/stacks/<NN-name>, in lower-case letters, digits and hyphens. Got: $stack_dir" >&2
  exit 2
fi
project="${BASH_REMATCH[2]}"
stack_name="${ORG_PREFIX}-${env_name}-${project}-${BASH_REMATCH[4]}"
if [[ "$mode" == name ]]; then
  echo "$stack_name"
  exit 0
fi

: "${CFN_ROLE_ARN:?CFN_ROLE_ARN is not set}"
region="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
: "${region:?AWS_REGION is not set}"
template="${stack_dir}/template.yml"
params="${stack_dir}/${env_name}.json"
change_set="${mode}-${GITHUB_SHA:-local}-$(date +%s)"
summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

if [[ ! -f "$template" || ! -f "$params" ]]; then
  echo "Missing $template or $params" >&2
  exit 1
fi

# Upload any local code the template points at (such as a Lambda function's
# CodeUri) to this account's artifacts bucket. A template without local code
# comes out unchanged.
account="$(aws sts get-caller-identity --query Account --output text)"
packaged="$(mktemp)"
trap 'rm -f "$packaged"' EXIT
aws cloudformation package \
  --template-file "$template" \
  --s3-bucket "${ORG_PREFIX}-${env_name}-artifacts-${account}-${region}" \
  --s3-prefix "$project" \
  --output-template-file "$packaged" > /dev/null

# A stack that does not exist yet, or only exists as an empty preview shell,
# needs a CREATE change set. A stuck ROLLBACK_COMPLETE stack must be deleted first.
status="$(aws cloudformation describe-stacks --stack-name "$stack_name" \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo NONE)"
case "$status" in
  NONE|REVIEW_IN_PROGRESS) cs_type=CREATE ;;
  ROLLBACK_COMPLETE)
    echo "Stack $stack_name is in ROLLBACK_COMPLETE and must be deleted first (see the runbook for a failed deployment)." >&2
    exit 1 ;;
  *) cs_type=UPDATE ;;
esac

aws cloudformation create-change-set \
  --stack-name "$stack_name" \
  --change-set-name "$change_set" \
  --change-set-type "$cs_type" \
  --template-body "file://${packaged}" \
  --parameters "file://${params}" \
  --role-arn "$CFN_ROLE_ARN" \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags "Key=Environment,Value=${env_name}" \
         "Key=Project,Value=${project}" \
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