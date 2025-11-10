# Get S3 Version by Tag Action

Finds an S3 object version ID by searching for a specific version tag. Useful for deploying specific versions of Lambda functions.

## Usage

```yaml
- name: Get S3 version
  id: s3-version
  uses: organization/b-gh-actions/get-s3-version-by-tag@v1
  with:
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    version-tag: v1.0.0
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `s3-bucket` | S3 bucket name | Yes |
| `s3-key` | S3 object key (path within bucket) | Yes |
| `version-tag` | Version tag to search for | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `version-id` | S3 object version ID matching the tag |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- S3 bucket must have versioning enabled
- Objects must be tagged with version tags during upload
- Required IAM permissions:
  - `s3:ListBucketVersions`
  - `s3:GetObjectTagging`

## What it does

1. Lists all versions of the specified S3 object
2. Iterates through each version checking its tags
3. Finds the version with a matching `version` tag
4. Returns the version ID for precise deployment

## Example: Deploy specific release

```yaml
- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1

- name: Get release package version
  id: s3-version
  uses: organization/b-gh-actions/get-s3-version-by-tag@v1
  with:
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    version-tag: v1.0.0

- name: Update Lambda functions
  uses: organization/b-gh-actions/update-lambda-functions@v1
  with:
    function-prefix: my-prod-app
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    s3-version-id: ${{ steps.s3-version.outputs.version-id }}
```

## Example: With get-release-version

```yaml
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
```

## Error Handling

The action will fail if:
- The S3 object doesn't exist
- No versions of the object are found
- No version has a matching tag
- AWS permissions are insufficient

## Tag Format

This action looks for S3 object tags in the format:
- Key: `version`
- Value: Your version tag (e.g., `v1.0.0`, `snapshot-abc123`)

Tags should be set during upload using `upload-lambda-package-s3` action.
