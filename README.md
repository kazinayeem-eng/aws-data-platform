# aws-data-platform

One repo, many projects, three AWS accounts. Each project has its own folder, its own stacks and its own deploy workflow. A pull request previews exactly what it would change in dev and prod; a merge deploys to dev, then to prod after one approval. No AWS keys are stored anywhere.

## Layout

```
projects/<project>/stacks/<NN-name>/     template.yml, dev.json, prod.json
projects/<project>/                      code, tests and docs for that project
.github/workflows/deploy-<project>.yml   one deploy workflow per project
.github/workflows/deploy-project.yml     shared deploy steps, called by the project workflows
.github/workflows/pr-validate.yml        lint, policy rules, tests and previews on every pull request
scripts/                                 the pipeline scripts
tests/pipeline-test.sh                   tests for the pipeline scripts
guard/                                   policy rules every template must pass
bootstrap/                               guardrails, budget brake and pipeline identity (deployed by hand)
docs/                                    decisions, accepted risks and runbooks
pyproject.toml, uv.lock                  the pinned Python tools; run them with uv run
```

## Names

A stack is named `<org>-<env>-<project>-<name>`, where `<name>` is the stack folder without its number: `projects/sample/stacks/00-bucket` becomes `acme-dev-sample-bucket`.

Name every resource a project creates `<org>-<env>-<project>-...` too. The pipeline's service role can only create resources whose names start with `<org>-<env>-`, so that part is required, not just tidy. IAM roles must also carry the permissions boundary `<org>-workload-boundary-<env>`.

## Add a project

1. Pick a short name: 2 to 20 lower-case letters, digits or hyphens, starting with a letter.
2. Create `projects/<project>/stacks/00-<name>/` with `template.yml`, `dev.json` and `prod.json`.
3. Copy the workflow and swap the name: `sed 's/sample/<project>/g' .github/workflows/deploy-sample.yml > .github/workflows/deploy-<project>.yml`
4. Check it: `uv run cfn-lint projects/<project>/stacks/*/template.yml` and `cfn-guard validate --rules guard/ --data <template>`.
5. Open a pull request. `Preview dev` and `Preview prod` show what will be created.
6. Merge. The new workflow deploys dev, then waits for your approval before prod.

If the project needs a resource type the service role cannot create yet, widen `bootstrap/workload/pipeline-identity.yml` in its own pull request first, then redeploy it by hand in dev and prod.

## Remove a project

1. Delete its stacks by hand with an admin profile: turn termination protection off, then delete the stack, then delete any retained buckets.
2. In a pull request, delete `projects/<project>/` and `.github/workflows/deploy-<project>.yml`.

Deleting a stack folder never deletes the stack in AWS. That is always a deliberate, manual step.

## Rules

- `main` is protected. Every change is a branch, a pull request and a squash merge.
- No keys, passwords or tokens in the repo. The pipeline signs in with OIDC.
- Never widen a role to `*`.
- Run `bash tests/pipeline-test.sh` after changing anything in `scripts/`.
- A change under `scripts/`, `bootstrap/` or `.github/` previews every project. A Markdown-only change previews and deploys nothing.
- If spend reaches the monthly budget, the budget brake freezes dev and prod until you release it. See `docs/runbooks.md`.