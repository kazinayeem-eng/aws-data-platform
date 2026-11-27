# Decisions

Each entry records one choice, why it was made, and when to look at it again.

## D1. Three AWS accounts in one organization

**Decision.** A management account, a dev account and a prod account. Dev and prod each sit in their own organizational unit, with guardrails (service control policies) attached.

**Why.** An account is a hard boundary, so a mistake in dev has no route into prod, and guardrails limit even administrators.

**Revisit when.** Never for the split. More accounts were considered and declined; add one only for a clear, lasting need.

## D2. People sign in with IAM Identity Center

**Decision.** Single sign-on with MFA for every person, with session lengths of 1 hour (admin) and 4 hours (read-only). No IAM users and no access keys.

**Why.** Sessions expire on their own, and there is nothing long-lived to leak.

## D3. GitHub signs in with OIDC, one role per purpose

**Decision.** In each workload account, a plan role for pull requests (preview only), a deploy role reachable only through a GitHub Environment, and a CloudFormation service role that alone creates resources. Each GitHub role trusts one exact token subject that includes the repository's numeric IDs.

**Why.** No stored secret, and a stolen or forged workflow cannot reach more than its one job allows.

## D4. CloudFormation with change sets, run by a script in the repository

**Decision.** Plain CloudFormation templates. `scripts/cfn-change.sh` previews and applies one stack through a change set.

**Why.** AWS-native, no state file to protect, and every change is previewed by AWS itself. A script you can read beats a third-party action that handles credentials.

**Revisit when.** Learning Terraform becomes the goal.

## D5. One repository, many projects

**Decision.** Each project lives in `projects/<project>/`, with stacks in `projects/<project>/stacks/<NN-name>/`, named `<org>-<env>-<project>-<name>`. Each project has its own deploy workflow; pull requests preview only the projects they touch.

**Why.** A change to one project never redeploys another, and a failed deploy in one project never blocks the others.

**Revisit when.** Projects need different owners or different permissions: then give them their own roles, or their own repository.

## D6. Roles created by stacks must carry a permissions boundary

**Decision.** The service role may create IAM roles only if they are named `<org>-<env>-*` and carry the boundary `<org>-workload-boundary-<env>`, which denies any change to identities, the organization or the account.

**Why.** Without it, any template could create an administrator role, and the pipeline would be administrator in all but name.

## D7. Code is packaged into an artifacts bucket in each account

**Decision.** `scripts/cfn-change.sh` runs `aws cloudformation package` before every change set, uploading local code to `<org>-<env>-artifacts-<account>-<region>`.

**Why.** A project with Lambda code deploys exactly like a project without it, with no special upload steps.

**Trade-off.** The plan role can write to that one bucket during pull request previews. Uploaded packages expire after 90 days.

## D8. Policy rules with cfn-guard, not checkov

**Decision.** Rules in `guard/` that every template must pass, enforced in CI from the first pull request.

**Why.** One small binary instead of about a hundred Python packages, and rules you wrote yourself and understand.

**Revisit when.** You want broad off-the-shelf checks: AWS publishes Guard rule sets that can be added to `guard/`.

## D9. Python tools pinned with uv

**Decision.** `pyproject.toml` and `uv.lock` pin cfn-lint and zizmor; CI installs them with `uv sync --locked`.

**Why.** Your Mac and the pipeline run exactly the same versions.

## D10. A $5 monthly cost ceiling with an automatic brake

**Decision.** A $5 budget alerts at 50%, 80% and 100% of actual spend and at 100% of forecast spend. At $5 of actual spend, a budget action attaches a guardrail that freezes the dev and prod accounts, except for people signed in through Identity Center and the CloudFormation service role.

**Why.** AWS has no hard spending cap. Alerts plus a brake make a surprise bill unlikely.

**Limits.** Billing data arrives with a delay of hours, and charges for resources that are already running continue until you delete them.

## D11. Not now: GuardDuty, AWS Config, Security Hub, a log archive account

**Why.** They add cost or accounts that a one-person learning platform does not need yet. They are recorded as accepted risks.

**Revisit when.** Real data or other people arrive.

## D12. A public repository with solo approvals

**Decision.** A public repository on GitHub Free, where you approve your own prod deployments.

**Why.** GitHub Free offers branch rulesets and required reviewers only on public repositories.

**Revisit when.** Before you add any collaborator.

## D13. Deleting a stack removes everything in it

**Decision.** Stacks have no termination protection, and buckets use `DeletionPolicy: Delete` and need no versioning. Deleting a stack, in the console or with the CLI, removes all of its resources once its buckets are empty. Buckets still use `UpdateReplacePolicy: Retain`, and the Guard rules check that.

**Why.** Teardown should be one deliberate delete, not a hunt for resources that were kept behind. You empty a bucket yourself first; a delete that meets a full bucket stops at `DELETE_FAILED`, and you retry it.

**Trade-off.** A deleted stack, or a bucket removed from a merged template, cannot be recovered, and there are no old object versions to restore. A change that replaces a bucket still keeps the old one.

**Revisit when.** A project holds data you cannot recreate.
