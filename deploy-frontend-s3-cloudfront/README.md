# Deploy Frontend to S3 and CloudFront Action

Deploys frontend build files to S3 and invalidates CloudFront cache.

## Usage

```yaml
- name: Deploy frontend
  uses: organization/b-gh-actions/deploy-frontend-s3-cloudfront@v1
  with:
    s3-bucket: my-frontend-bucket
    cloudfront-distribution-id: E1234567890ABC
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `build-dir` | Directory containing the build files | No | `build/` |
| `s3-bucket` | S3 bucket name | Yes | - |
| `cloudfront-distribution-id` | CloudFront distribution ID | Yes | - |
| `cloudfront-paths` | Paths to invalidate in CloudFront | No | `/*` |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- Build directory must exist and contain the frontend build files
- Required IAM permissions:
  - `s3:PutObject`
  - `s3:DeleteObject`
  - `s3:ListBucket`
  - `cloudfront:CreateInvalidation`

## Example: Complete deployment workflow

```yaml
- name: Build application
  run: npm run build

- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1

- name: Deploy to S3 and CloudFront
  uses: organization/b-gh-actions/deploy-frontend-s3-cloudfront@v1
  with:
    build-dir: dist/
    s3-bucket: my-prod-frontend-bucket
    cloudfront-distribution-id: E1234567890ABC
```

## Behavior

- Syncs build directory to S3 with `--delete` flag (removes files not in source)
- Creates CloudFront invalidation for specified paths
- Default invalidation path `/*` clears entire distribution cache
