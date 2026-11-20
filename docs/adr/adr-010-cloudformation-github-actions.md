# ADR-010 — CloudFormation templates, deployed by GitHub Actions

**Status:** Accepted — 18 Nov 2026 (decided by Kazi)

## Context

Kazi prefers native CloudFormation templates deployed through a GitHub pipeline. The deployment story must still be reviewable in the repo, repeatable, and fully deletable — and for a portfolio, a CI/CD pipeline is itself evidence.

## Decision

Infrastructure is plain CloudFormation YAML in `infra/` (one root template, `infra/main.yaml`, with the Step Functions definition written as JSON/YAML by hand). Deployment runs in GitHub Actions: on push to `main` (and on manual dispatch), the workflow builds the Lambda zips from the uv lockfile, uploads them to a deployment S3 bucket, then runs `aws cloudformation deploy`. GitHub authenticates to AWS with OIDC — no long-lived AWS access keys stored in GitHub. The OIDC trust policy allows only this repo's own branches and the named workflows — fork pull requests cannot assume the role, so a fork cannot spend the Bedrock budget. The deploy workflow runs only on push to `main` (and manual dispatch), never on fork PRs. A second workflow runs the evals and unit tests on every pull request. Nothing is deployed from the Mac; the console is for reading (logs, traces, executions), not for creating resources.

## Alternatives considered

- **CDK (Python)** — more expressive, but a second framework to learn in Phase 0 and its generated templates are harder to read in a portfolio review.
- **Terraform** — excellent, but another tool and a state file, with no advantage at this scale.
- **Manual `aws cloudformation deploy` from the Mac** — works, but unreviewable as a process and it teaches nothing about CI/CD.

## Consequences

The Lambda packaging step must be scripted explicitly (`scripts/build.sh`: `uv export` → install to target dir → zip → upload to S3). The project reuses the existing repo pipeline — OIDC role, `deploy.yml` (dev → prod) and `pr-validate.yml` (cfn-lint) in `kazinayeem-eng/aws-data-platform` — so Phase 0 adds a stack to a working pipeline instead of building one. In exchange: every deployment is a reviewed, repeatable pipeline run; the portfolio shows CI/CD, not just code; and there is no layer between the repo and AWS. Cost: GitHub Actions is free for public repos; OIDC costs nothing. Revisit if: the CloudFormation template grows past ~500 lines, at which point splitting it into nested stacks is the fix — not a move to CDK.
