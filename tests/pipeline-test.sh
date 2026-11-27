#!/usr/bin/env bash
# Tests for the pipeline scripts. They never call AWS: a stand-in aws command
# records what the scripts ask for. Needs bash, git and jq.
#
#   bash tests/pipeline-test.sh
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fails=0
check() { # check "what" "expected" "actual"
  if [[ "$2" == "$3" ]]; then
    echo "ok    $1"
  else
    echo "FAIL  $1"
    echo "      expected: $2"
    echo "      got:      $3"
    fails=$((fails + 1))
  fi
}

echo "Stack names"
cd "$root" || exit 1
check "folder gives the name" "acme-dev-data-bucket" \
  "$(ORG_PREFIX=acme scripts/cfn-change.sh name projects/data/stacks/00-bucket dev)"
check "same folder in another project gives another name" "acme-dev-probe-bucket" \
  "$(ORG_PREFIX=acme scripts/cfn-change.sh name projects/probe/stacks/00-bucket dev)"
check "number prefix is dropped" "acme-prod-apa-pipeline" \
  "$(ORG_PREFIX=acme scripts/cfn-change.sh name projects/apa/stacks/01-pipeline prod)"
check "folder outside projects/ is refused" "2" \
  "$(ORG_PREFIX=acme scripts/cfn-change.sh name stacks/data-bucket dev 2>/dev/null; echo $?)"
check "capitals and underscores are refused" "2" \
  "$(ORG_PREFIX=acme scripts/cfn-change.sh name projects/data/stacks/00-My_Bucket dev 2>/dev/null; echo $?)"
check "unknown environment is refused" "2" \
  "$(ORG_PREFIX=acme scripts/cfn-change.sh name projects/data/stacks/00-bucket staging 2>/dev/null; echo $?)"
check "bad project name is refused" "2" \
  "$(scripts/cfn-project.sh preview Bad_Name dev 2>/dev/null; echo $?)"
check "missing project is refused" "1" \
  "$(scripts/cfn-project.sh preview no-such-project dev 2>/dev/null; echo $?)"

echo
echo "Which projects a change previews"
repo="$work/repo"
mkdir -p "$repo/scripts" "$repo/projects/data/stacks/00-bucket" "$repo/projects/probe/stacks/00-bucket"
cp "$root/scripts/changed-projects.sh" "$repo/scripts/"
cd "$repo" || exit 1
git init -q
git config user.email test@example.com
git config user.name test
touch README.md projects/data/stacks/00-bucket/template.yml projects/probe/stacks/00-bucket/template.yml
git add -A && git commit -qm base
changed() { git add -A && git commit -qm change && scripts/changed-projects.sh HEAD~1 | tr '\n' ' '; }
echo x >> projects/data/stacks/00-bucket/template.yml
check "a template change previews its project" "data " "$(changed)"
echo x > projects/data/README.md
check "a Markdown-only change previews nothing" "" "$(changed)"
mkdir -p .github && echo x > .github/settings.yml
check "a shared pipeline change previews every project" "data probe " "$(changed)"
echo x >> README.md
check "the root README previews nothing" "" "$(changed)"
git rm -rq projects/probe
check "a deleted project is not previewed" "" "$(changed)"
check "a missing base ref fails instead of reporting nothing" "128" \
  "$(scripts/changed-projects.sh no-such-ref >/dev/null 2>&1; echo $?)"

echo
echo "Preview and apply"
bin="$work/bin"
log="$work/aws.log"
mkdir -p "$bin"
cat > "$bin/aws" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$AWS_LOG"
case "$1 $2" in
  "sts get-caller-identity") echo 111111111111 ;;
  "cloudformation package")
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --template-file) in="$2" ;;
        --output-template-file) out="$2" ;;
      esac
      shift
    done
    cp "$in" "$out" ;;
  "cloudformation describe-stacks") exit 254 ;;
  "cloudformation create-change-set") echo arn:aws:cloudformation:test ;;
  "cloudformation describe-change-set")
    echo '{"Changes":[{"ResourceChange":{"Action":"Add","LogicalResourceId":"Bucket","ResourceType":"AWS::S3::Bucket"}}]}' ;;
  "cloudformation wait"|"cloudformation delete-change-set"|"cloudformation execute-change-set") ;;
  *) echo "unexpected aws call: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$bin/aws"
proj="$work/proj"
mkdir -p "$proj/projects/data/stacks/00-bucket" "$proj/projects/data/stacks/01-later"
cp -R "$root/scripts" "$proj/"
printf 'Resources: {}\n' > "$proj/projects/data/stacks/00-bucket/template.yml"
printf '[]\n' > "$proj/projects/data/stacks/00-bucket/dev.json"
cd "$proj" || exit 1
run() {
  # Empty GITHUB_STEP_SUMMARY so the change table goes to stdout in CI too.
  GITHUB_STEP_SUMMARY='' PATH="$bin:$PATH" AWS_LOG="$log" AWS_REGION=ap-southeast-2 ORG_PREFIX=acme \
    CFN_ROLE_ARN=arn:aws:iam::111111111111:role/acme-cfn-service-dev scripts/cfn-project.sh "$@"
}
out="$(run preview data dev)"
check "preview writes the change table" "| Add | Bucket | AWS::S3::Bucket | - |" "$(grep '^| Add' <<< "$out")"
check "a folder without a template is skipped" "preview: 1 stack(s) in project data" "$(tail -1 <<< "$out")"
check "code is packaged to the artifacts bucket" "1" \
  "$(grep -c -- '--s3-bucket acme-dev-artifacts-111111111111-ap-southeast-2' "$log")"
check "the stack gets a Project tag and may create named IAM roles" "1 1" \
  "$(grep -c 'Key=Project,Value=data' "$log") $(grep -c -- '--capabilities CAPABILITY_NAMED_IAM' "$log")"
check "preview deletes its change set and never executes it" "1 0" \
  "$(grep -c 'delete-change-set' "$log") $(grep -c 'execute-change-set' "$log")"
: > "$log"
out="$(run apply data dev)"
check "apply executes the change set and leaves the stack deletable" "1 0" \
  "$(grep -c 'execute-change-set' "$log") $(grep -c 'termination-protection' "$log")"
check "apply reports the deployed stack" "Deployed acme-dev-data-bucket" "$(grep '^Deployed' <<< "$out")"

echo
if [[ "$fails" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "$fails check(s) failed."
  exit 1
fi