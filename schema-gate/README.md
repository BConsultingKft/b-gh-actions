# Schema Gate Action

Deploy gate for consumers of the shared `b-onsite` MySQL schema (`BConsultingKft/b-onsite-database`, checked out as a
git submodule). Fails the job if the schema version the build needs is not applied on the target environment yet.

How it decides:
1. Required version = highest Flyway version among `<submodule-path>/migrations/V*.sql`
   (the part between `V` and `__`, e.g. `V20261029143000__BO-970_x.sql` → `20261029143000`).
2. Applied versions = SSM parameter `/bos-<env>-database/schema-versions`, written by the b-onsite-database
   deploy pipelines (StringList, e.g. `1,20261029143000`).
3. Passes only if the required version is in the applied list. This is a membership check, not "≤ latest applied",
   because dev runs Flyway with `outOfOrder=true`.

Versions are compared the way Flyway does: `_` and `.` are equivalent, leading zeros and trailing `.0` segments are
ignored, segments are compared numerically (`V1_1` == `1.1`, `V001` == `1`, `1.10` > `1.9`). `R__` and `U__` files
are ignored.

## Usage

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: actions/create-github-app-token@v1
    id: app-token
    with:
      app-id: ${{ secrets.DB_APP_ID }}
      private-key: ${{ secrets.DB_APP_PRIVATE_KEY }}
      owner: BConsultingKft
      repositories: b-onsite-database

  - uses: actions/checkout@v4
    with:
      submodules: true
      token: ${{ steps.app-token.outputs.token }}

  - name: Configure AWS
    uses: BConsultingKft/b-gh-actions/aws-configure@main

  - name: Schema gate
    uses: BConsultingKft/b-gh-actions/schema-gate@main
    with:
      env: dev   # or prod in deploy-to-prod
```

Run the gate before any deploy step. Reference `@main` until a version tag is cut.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `env` | Target environment: `dev` or `prod` (anything else fails) | Yes | - |
| `submodule-path` | Path of the b-onsite-database submodule | No | `db` |

## Outputs

| Output | Description |
|--------|-------------|
| `required-version` | Highest migration version found in the submodule (normalised) |
| `env-max-version` | Highest schema version applied on the environment (normalised) |

## Prerequisites

- AWS credentials configured first (`aws-configure`). The role needs `ssm:GetParameter` on
  `arn:aws:ssm:eu-central-1:736766805372:parameter/bos-<env>-database/schema-versions`
  (`bos-common-shared_infra-gha-trust` has it via its `parameter/bos-<env>-*` grant).
- The submodule checked out (`submodules: true` with a token that can read b-onsite-database).

## Failure messages

| Message | Meaning / fix |
|---------|---------------|
| `<env> is behind. This build needs schema version X …` | Deploy b-onsite-database to `<env>` first (prod: release + deploy-to-prod), or move the submodule back to a schema `<env>` has |
| `no migrations directory …` / `no V*.sql migrations found …` | Submodule not checked out, or wrong `submodule-path` |
| `could not read SSM parameter …` | AWS not configured, missing `ssm:GetParameter`, or the DB pipeline has not written the parameter yet |
| `invalid migration filename/version …` | A file in `migrations/` doesn't follow `V<version>__<desc>.sql` |
| `the <env> schema-versions list is empty` | The parameter exists but holds no versions |

There is deliberately no bypass input; skipping the gate means removing the step from the workflow.

## Testing

```bash
bash schema-gate/tests/test.sh
```

`check.sh` holds all the logic and makes no AWS calls; `tests/test.sh` runs it against generated migration folders
and sample SSM values. `.github/workflows/test-schema-gate.yml` runs those tests, actionlint, and a smoke test of
`action.yml` with a fake `aws` CLI on every PR that touches `schema-gate/`.
