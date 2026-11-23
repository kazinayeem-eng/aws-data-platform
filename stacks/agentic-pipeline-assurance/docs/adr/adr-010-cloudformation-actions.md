# ADR-010: CloudFormation deployed by GitHub Actions

**Status:** Accepted — 18 Nov 2026

## Context

Infrastructure should use native CloudFormation, be reviewable and repeatable, and be fully deletable. The CI/CD pipeline is also portfolio evidence.

## Decision

Use plain CloudFormation YAML in the existing repository. The plan organizes resources into per-phase stack folders, each with a template and dev/prod parameter files. Use the existing GitHub Actions pipeline: pull requests lint, scan, and preview change sets for dev and prod using read-only OIDC roles; merging deploys dev, then prod after manual approval. GitHub authenticates to AWS with OIDC. The CloudFormation service role starts with S3 permissions and is widened through reviewed pull requests. Nothing else is deployed from the Mac, except documented identity-stack redeploys, a one-time CloudWatch setting, and final teardown.

## Alternatives

- **CDK:** More expressive, but adds a framework and makes generated templates harder to review.
- **Terraform:** Excellent, but adds another tool and state file without benefit at this scale.
- **Manual CloudFormation deployment from the Mac:** Works, but is not a reviewable deployment process.

## Consequences

Every deployment is reviewed and repeatable. CI must package Lambda code from the lockfile before credentials are assumed, upload the zip, and provide its S3 location to CloudFormation. Inline templates must stay below 51,200 bytes. CloudFormation does not detect changed Lambda code under an unchanged S3 key, so deployments need a code-version parameter. Preview does not validate the service role's permissions, so missing permissions appear during deployment.

**Guide deviation:** The guide uses a separate stack folder per phase, with `template.yml`, `dev.json`, and `prod.json`, rather than the plan's single `template.yaml` layout.
