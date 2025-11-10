# Update Lambda Functions Action

Updates multiple Lambda functions with a deployment package from S3. Finds all functions matching a prefix and updates them with a specific S3 package version.

## Usage

```yaml
- name: Update Lambda functions
  uses: organization/b-gh-actions/update-lambda-functions@v1
  with:
    function-prefix: my-app-prod
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    s3-version-id: abc123xyz
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `function-prefix` | Prefix to filter Lambda functions | Yes |
| `s3-bucket` | S3 bucket containing the Lambda package | Yes |
| `s3-key` | S3 object key for the Lambda package | Yes |
| `s3-version-id` | S3 object version ID to deploy | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `updated-functions` | Comma-separated list of updated function names |
| `function-count` | Number of functions updated |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- Lambda functions must exist with the specified prefix
- Required IAM permissions:
  - `lambda:ListFunctions`
  - `lambda:UpdateFunctionCode`
  - `s3:GetObject`

## What it does

1. Lists all Lambda functions matching the prefix
2. Updates each function's code to use the specified S3 package version
3. Returns the list of updated functions and count

## Example: Complete Lambda deployment

```yaml
- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1

- name: Get release version
  id: release
  uses: organization/b-gh-actions/get-release-version@v1
  with:
    release: <<latest>>
    github-token: ${{ secrets.GITHUB_TOKEN }}

- name: Find S3 package version
  id: s3-version
  uses: organization/b-gh-actions/get-s3-version-by-tag@v1
  with:
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    version-tag: ${{ steps.release.outputs.version }}

- name: Update Lambda functions
  id: update
  uses: organization/b-gh-actions/update-lambda-functions@v1
  with:
    function-prefix: my-prod-app
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    s3-version-id: ${{ steps.s3-version.outputs.version-id }}

- name: Show results
  run: |
    echo "Updated ${{ steps.update.outputs.function-count }} functions"
    echo "Functions: ${{ steps.update.outputs.updated-functions }}"
```

## Example: Dev deployment

```yaml
- name: Checkout PR
  id: pr
  uses: organization/b-gh-actions/pr-comment-handler@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}

- name: Create package
  id: package
  uses: organization/b-gh-actions/lambda-package-python@v1
  with:
    version-tag: snapshot-${{ steps.pr.outputs.pr-sha }}

- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1

- name: Upload to S3
  id: upload
  uses: organization/b-gh-actions/upload-lambda-package-s3@v1
  with:
    package-file: ${{ steps.package.outputs.package-path }}
    s3-bucket: my-lambda-packages
    s3-key: my-app/dev/package.zip
    version-tag: snapshot-${{ steps.pr.outputs.pr-sha }}

- name: Update functions
  uses: organization/b-gh-actions/update-lambda-functions@v1
  with:
    function-prefix: my-dev-app
    s3-bucket: my-lambda-packages
    s3-key: my-app/dev/package.zip
    s3-version-id: ${{ steps.upload.outputs.version-id }}
```

## Function Naming Convention

This action works best when your Lambda functions follow a naming pattern:
- Production: `my-app-prod-function1`, `my-app-prod-function2`, etc.
- Development: `my-app-dev-function1`, `my-app-dev-function2`, etc.

Using a consistent prefix allows the action to update all related functions in one step.

## Error Handling

The action will:
- Exit successfully with count=0 if no functions match the prefix
- Fail if any function update fails
- Report which function failed in the error output

## S3 Versioning

Using `s3-version-id` ensures:
- Precise version control (not just "latest")
- Safe rollbacks (can specify any previous version)
- Atomic deployments (all functions get the exact same code version)
