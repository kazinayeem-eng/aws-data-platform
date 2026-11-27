# Runbooks

Follow these steps instead of improvising under stress. Improvising is how permissions get widened "just this once".

## Regular upkeep

| Task | How often | How |
|---|---|---|
| Merge Dependabot pull requests | Weekly | Read the preview, merge, approve. After a Python update, run `git pull && uv sync` |
| Read Dependabot alerts | Weekly | GitHub: **Security → Dependabot** |
| Review IAM Access Analyzer findings | Weekly | Console, management account |
| Check spend against the budget | Monthly | Billing and Cost Management, or the budget emails |
| Check the budget brake is armed | Monthly | The brake status command below prints `STANDBY` |
| Detect drift on every stack | Monthly | The drift commands below |
| Update your local tools | Monthly | `uv self update` |
| Review Identity Center users and these documents | Quarterly | Remove anything unused |
| Confirm both root MFA devices work | Twice a year | Sign in as the management root user |

## A failed deployment

Read the failing events first:

```sh
aws cloudformation describe-stack-events --stack-name <org>-<env>-<project>-<name> --query "StackEvents[?contains(ResourceStatus,'FAILED')].[LogicalResourceId,ResourceStatusReason]" --output table --profile <org>-<env>-readonly
```

| Status | What it means | What to do |
|---|---|---|
| `UPDATE_ROLLBACK_COMPLETE` | An update failed and was undone | The stack is healthy. Fix the cause in a new pull request |
| `ROLLBACK_COMPLETE` | The first creation failed, and the stack cannot be updated | Fix the cause, delete the stack with an admin profile, then use **Run workflow** on the project's workflow |
| `UPDATE_ROLLBACK_FAILED` | The rollback itself failed | Fix the cause, then run `aws cloudformation continue-update-rollback --stack-name <stack>` with an admin profile |
| `DELETE_FAILED` | A resource could not be deleted, often a bucket that is not empty | Empty or keep the resource, then retry |
| `REVIEW_IN_PROGRESS` | An empty shell left by a preview of a new stack | Harmless. The next deploy uses it |

A bucket that holds objects cannot be deleted, so a stack delete, or the rollback of a failed first deployment, can stop at `DELETE_FAILED`. Empty the bucket (S3 console → the bucket → **Empty**), then delete again.

## The budget brake fired

You get an email saying the budget action ran. Dev and prod are now frozen: previews, deploys and your workloads' own AWS calls fail with `explicit deny in a service control policy`. You can still sign in through Identity Center and clean up.

1. Find what costs money. In the management account, open **Billing and Cost Management → Cost Explorer**, group by **Service**, and look at the last 7 days.
2. Stop it. Delete or scale down the resource. To delete a whole stack, use the console or an admin profile: CloudFormation does the work with the service role, which the brake leaves alone. Empty its buckets first.

    ```sh
    aws cloudformation delete-stack --stack-name <stack> --profile <org>-<env>-admin
    ```

3. Release the brake from the management account. The first command prints the action ID and `EXECUTION_SUCCESS`; the second releases it:

    ```sh
    aws budgets describe-budget-actions-for-budget --account-id <mgmt-account-id> --budget-name <org>-monthly --query 'Actions[].[ActionId,Status]' --output text --region us-east-1 --profile <org>-mgmt-admin
    aws budgets execute-budget-action --account-id <mgmt-account-id> --budget-name <org>-monthly --action-id <action-id> --execution-type REVERSE_BUDGET_ACTION --region us-east-1 --profile <org>-mgmt-admin
    ```

4. A released brake stays off for the rest of the month. On the first day of the next month, run the first command again. It should print `STANDBY`; if it does not, re-arm the brake with `--execution-type RESET_BUDGET_ACTION`.

## Drift

Drift means something in AWS no longer matches its template, usually because someone changed it by hand.

```sh
aws cloudformation detect-stack-drift --stack-name <stack> --query StackDriftDetectionId --output text --profile <org>-<env>-admin
aws cloudformation describe-stack-resource-drifts --stack-name <stack> --stack-resource-drift-status-filters MODIFIED DELETED --profile <org>-<env>-admin
```

Wait about a minute between the two commands. Resolve every difference: put the real change into the template, or put the resource back.

## Break-glass: when the normal route is unavailable

Escalate only as far as you must, and clean up afterwards.

**Level 1: the pipeline is down or too slow.**

1. Sign in with `aws sso login --sso-session <org>`.
2. Make the smallest change that stops the harm.
3. Write down what, why and when.
4. Put the same change into code the same day.
5. Run drift detection, and review your session in CloudTrail.

**Level 2: Identity Center is down, or you are locked out.** A last resort. Read it now; do not rehearse it.

1. Sign in at `https://console.aws.amazon.com/` as the management root user, with its password and one MFA device from Bitwarden.
2. In IAM, create a temporary user named `breakglass-temp` with the `AdministratorAccess` policy and a console password.
3. Sign out, then sign in as `breakglass-temp`.
4. Switch role into the target account: from the account menu choose **Switch role**, and enter the account ID and the role name `OrganizationAccountAccessRole`.
5. Make the smallest fix.
6. Delete `breakglass-temp`, and write down what you did.

## Rolling back

Prefer rolling forward: run `git revert <commit>` on a new branch, open a pull request, read the preview, merge and approve. A revert does not bring deleted data back. A change that replaces a bucket keeps the old one (`UpdateReplacePolicy: Retain`); a deleted stack or bucket is gone for good.

## Removing a project

1. Empty each of its buckets: S3 console → the bucket → **Empty** (this removes old versions too).
2. Delete its stacks in dev and prod, in the console or with the command from "The budget brake fired", step 2. If one stops at `DELETE_FAILED`, a bucket was not empty yet: empty it and delete again.
3. In a pull request, delete `projects/<project>/` and `.github/workflows/deploy-<project>.yml`.

## Adding and removing people

Before adding anyone, close the accepted risks that say "before adding a collaborator". To add an engineer, create an Identity Center user with only the permission sets they need, and add them to GitHub, `CODEOWNERS` and the `prod` reviewers. To remove one, disable the Identity Center user and remove them from GitHub.

If you suspect GitHub is compromised, change the plan and deploy roles' trust policies to deny all, or delete the OIDC provider, in each workload account. Then rotate your GitHub credentials, and search CloudTrail for sessions named `plan-<run id>` or `deploy-<project>-<run id>`.

## A Dependabot alert names a package you never installed

`uv.lock` pins every package your tools depend on, so Dependabot can alert on any of them. They run only in CI and on your Mac, never in AWS: treat an alert as real but not urgent.

1. See which tool brings the package in: `uv tree --invert --package <name>`.
2. Try a normal upgrade: `uv lock --upgrade-package <name>`. If `uv.lock` changes, open a pull request.
3. If nothing changes, the tool pins that exact version. Wait for the tool's next release, or force a fixed version with `override-dependencies = ["<name>==<version>"]` under `[tool.uv]` in `pyproject.toml`, with a comment saying when to remove it.

## What you can rebuild

A lost workload account can be rebuilt from code. The data cannot. Decide how you would recover data before putting anything valuable in a bucket.
