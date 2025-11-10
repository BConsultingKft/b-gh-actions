# Upload Lambda Package to S3 Action

Uploads a Lambda deployment package to S3 with versioning and version tagging.

## Usage

```yaml
- name: Upload Lambda package
  id: upload
  uses: organization/b-gh-actions/upload-lambda-package-s3@v1
  with:
    package-file: package.zip
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    version-tag: v1.0.0
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `package-file` | Path to the Lambda package zip file | Yes |
| `s3-bucket` | S3 bucket name | Yes |
| `s3-key` | S3 object key (path within bucket) | Yes |
| `version-tag` | Version tag to apply to the S3 object | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `version-id` | S3 object version ID |
| `s3-uri` | Full S3 URI (s3://bucket/key) |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- S3 bucket must have versioning enabled
- Required IAM permissions:
  - `s3:PutObject`
  - `s3:PutObjectTagging`

## What it does

1. Uploads the package file to S3
2. Applies a version tag to the S3 object
3. Returns the S3 version ID for precise version tracking
4. Outputs the S3 URI for reference

## Example: Complete workflow

```yaml
- name: Checkout code
  uses: actions/checkout@v4

- name: Create Lambda package
  id: package
  uses: organization/b-gh-actions/lambda-package-python@v1
  with:
    version-tag: v1.0.0

- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1

- name: Upload to S3
  id: upload
  uses: organization/b-gh-actions/upload-lambda-package-s3@v1
  with:
    package-file: ${{ steps.package.outputs.package-path }}
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    version-tag: v1.0.0

- name: Use outputs
  run: |
    echo "Uploaded to: ${{ steps.upload.outputs.s3-uri }}"
    echo "Version ID: ${{ steps.upload.outputs.version-id }}"
```

## Example: Snapshot deployment

```yaml
- name: Get commit hash
  id: commit
  run: echo "hash=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT

- name: Upload snapshot to S3
  uses: organization/b-gh-actions/upload-lambda-package-s3@v1
  with:
    package-file: package.zip
    s3-bucket: my-lambda-packages
    s3-key: my-app/dev/package.zip
    version-tag: snapshot-${{ steps.commit.outputs.hash }}
```

## S3 Version Tracking

The action uses S3 versioning to maintain a history of all package uploads. Each upload:
- Creates a new S3 object version
- Tags that version with your specified version tag
- Returns the unique version ID for precise deployments

This allows you to:
- Deploy specific versions of your Lambda function
- Roll back to previous versions
- Track deployment history
