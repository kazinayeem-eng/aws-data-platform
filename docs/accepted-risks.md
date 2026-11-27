# Accepted risks

Each row is a gap left open on purpose. Review the list every quarter.

| Risk | Why it is accepted | Close it when |
|---|---|---|
| You approve your own prod deployments | There is no second person | You add a reviewer and turn on Prevent self-review |
| Pull requests need no approval to merge | Only you have write access, and an author cannot approve their own pull request | Before adding a collaborator: require one approval and code-owner review, and give the admin role a bypass for pull requests only |
| One GitHub account controls both environments | The setup has one person | You add a passkey, and consider a separate repository for prod |
| Any pull request can use the plan role, which can also write to the artifacts bucket | It previews only and cannot execute changes; uploaded packages expire after 90 days | The repository gains collaborators: require code-owner review for `.github/` |
| A fork pull request might obtain an OIDC token | GitHub's documentation does not say; the plan role limits the damage, and fork runs need your approval | A test from a second GitHub account shows otherwise |
| Guardrails do not apply to the management account | AWS designs them that way; its root user relies on MFA and having no access keys | Never: the management account holds no workloads |
| The service role's permissions are the real blast radius | Anyone who can update a stack can use them. They are scoped by name, and every role a stack creates carries the boundary | A project needs real isolation: give it its own roles |
| Projects share roles, so one project's stack could change another project's resources | Projects are separated by name, not by permission | Projects get different owners |
| A pinned action or locked package can still be a bad release | You review every Dependabot pull request, but can miss one | You add a second reviewer, or hold updates for a few days |
| A tool pins a dependency with a known vulnerability | The tools run only in CI and on your Mac, never in AWS | The tool raises its pin, or you add an override |
| The audit trail lives in the management account | No more accounts, by decision | You hold regulated data |
| No GuardDuty, AWS Config or Security Hub | They bill by usage, and the ceiling is $5 a month | Real workloads or real data arrive |
| The public repository shows your account layout | Account IDs and role names are identifiers, not secrets | You hold real data: move to a private repository on a paid plan |
| The budget brake reacts hours after spend, and does not stop charges that are already running | AWS has no hard spending cap, and billing data is delayed | Never fully: keep the alerts on and delete costly resources quickly |
| Packaged code older than 90 days is deleted, so rolling back to it fails | Keeps the artifacts bucket nearly free | You need longer rollbacks: raise the lifecycle days |
| Deleting a stack destroys its data, in dev and prod, and buckets keep no old versions | Teardown takes one delete, and the data is synthetic | Real data arrives: put `DeletionPolicy: Retain` and versioning back on its buckets |
