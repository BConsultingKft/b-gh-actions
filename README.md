# B-Onsite GitHub Actions

A collection of reusable GitHub Actions for the B-Onsite project family. These actions encapsulate common CI/CD patterns used across multiple projects.

## Available Actions

### 🔐 Security

#### [secret-scanning](./secret-scanning)
Scans repository for secrets using TruffleHog with full git history.

```yaml
- uses: organization/b-gh-actions/secret-scanning@v1
```

---

### ☁️ AWS Infrastructure

#### [aws-configure](./aws-configure)
Configures AWS credentials using OIDC with sensible defaults for b-onsite projects.

```yaml
- uses: organization/b-gh-actions/aws-configure@v1
```

#### [build-push-ecr](./build-push-ecr)
Builds Docker image and pushes to Amazon ECR.

```yaml
- uses: organization/b-gh-actions/build-push-ecr@v1
  with:
    ecr-registry: 123456789012.dkr.ecr.eu-central-1.amazonaws.com
    ecr-repository: my-app
    image-tag: v1.0.0
```

#### [deploy-ecs](./deploy-ecs)
Deploys Docker image to AWS ECS by updating task definition and service.

```yaml
- uses: organization/b-gh-actions/deploy-ecs@v1
  with:
    ecr-image: 123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-app:v1.0.0
    task-family: my-task-family
    cluster-name: my-cluster
    service-name: my-service
    task-def-ssm-param: /my-app/taskdef-template-name
```

#### [deploy-frontend-s3-cloudfront](./deploy-frontend-s3-cloudfront)
Deploys frontend build files to S3 and invalidates CloudFront cache.

```yaml
- uses: organization/b-gh-actions/deploy-frontend-s3-cloudfront@v1
  with:
    s3-bucket: my-frontend-bucket
    cloudfront-distribution-id: E1234567890ABC
```

---

### ⚡ AWS Lambda

#### [lambda-package-python](./lambda-package-python)
Creates a deployment package for Python Lambda functions with dependencies.

```yaml
- uses: organization/b-gh-actions/lambda-package-python@v1
  with:
    version-tag: v1.0.0
```

#### [upload-lambda-package-s3](./upload-lambda-package-s3)
Uploads Lambda deployment package to S3 with versioning and tagging.

```yaml
- uses: organization/b-gh-actions/upload-lambda-package-s3@v1
  with:
    package-file: package.zip
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    version-tag: v1.0.0
```

#### [get-s3-version-by-tag](./get-s3-version-by-tag)
Finds S3 object version ID by searching for a specific version tag.

```yaml
- uses: organization/b-gh-actions/get-s3-version-by-tag@v1
  with:
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    version-tag: v1.0.0
```

#### [update-lambda-functions](./update-lambda-functions)
Updates multiple Lambda functions with a package from S3.

```yaml
- uses: organization/b-gh-actions/update-lambda-functions@v1
  with:
    function-prefix: my-app-prod
    s3-bucket: my-lambda-packages
    s3-key: my-app/prod/package.zip
    s3-version-id: abc123xyz
```

---

### 🏷️ Release Management

#### [get-release-version](./get-release-version)
Gets the latest release version or validates a provided version exists.

```yaml
- uses: organization/b-gh-actions/get-release-version@v1
  id: release
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

---

### 🔄 Pull Request Workflow

#### [pr-comment-handler](./pr-comment-handler)
Gets PR details from issue comment and checks out PR branch.

```yaml
- uses: organization/b-gh-actions/pr-comment-handler@v1
  id: pr
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

#### [pr-comment](./pr-comment)
Posts a comment on a pull request.

```yaml
- uses: organization/b-gh-actions/pr-comment@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ github.event.issue.number }}
    message: '✅ Deployment completed!'
```

---

## Usage Examples

### Complete Backend Deployment Workflow

```yaml
name: Deploy Backend to Production

on:
  workflow_dispatch:
    inputs:
      release:
        description: 'Release version (use <<latest>> for latest)'
        default: '<<latest>>'

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Get release version
        id: release
        uses: organization/b-gh-actions/get-release-version@v1
        with:
          release: ${{ github.event.inputs.release }}
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Configure AWS
        uses: organization/b-gh-actions/aws-configure@v1

      - name: Deploy to ECS
        uses: organization/b-gh-actions/deploy-ecs@v1
        with:
          ecr-image: 123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-api:${{ steps.release.outputs.version }}
          task-family: my-api
          cluster-name: prod-cluster
          service-name: my-api-service
          task-def-ssm-param: /prod/api/taskdef-template-name
```

### Complete Frontend Deployment Workflow

```yaml
name: Deploy Frontend to Production

on:
  workflow_dispatch:
    inputs:
      release:
        description: 'Release version'
        default: '<<latest>>'

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - run: npm install
      - run: npm run build
        env:
          VITE_API_PATH: https://api.example.com/

      - name: Configure AWS
        uses: organization/b-gh-actions/aws-configure@v1

      - name: Deploy to S3 and CloudFront
        uses: organization/b-gh-actions/deploy-frontend-s3-cloudfront@v1
        with:
          build-dir: dist/
          s3-bucket: my-prod-frontend-bucket
          cloudfront-distribution-id: E1234567890ABC
```

### Dev Deployment on PR Comment

```yaml
name: Dev Deploy on Comment

on:
  issue_comment:
    types: [created]

jobs:
  deploy:
    if: github.event.issue.pull_request && contains(github.event.comment.body, 'Dev deploy!')
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    steps:
      - name: Handle PR comment
        id: pr
        uses: organization/b-gh-actions/pr-comment-handler@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Configure AWS
        uses: organization/b-gh-actions/aws-configure@v1

      - name: Build and push Docker image
        id: build
        uses: organization/b-gh-actions/build-push-ecr@v1
        with:
          ecr-registry: 123456789012.dkr.ecr.eu-central-1.amazonaws.com
          ecr-repository: my-app
          image-tag: snapshot-${{ steps.pr.outputs.pr-sha }}

      - name: Deploy to ECS
        uses: organization/b-gh-actions/deploy-ecs@v1
        with:
          ecr-image: ${{ steps.build.outputs.image }}
          task-family: dev-app
          cluster-name: dev-cluster
          service-name: dev-app-service
          task-def-ssm-param: /dev/app/taskdef-template-name

      - name: Comment on success
        if: success()
        uses: organization/b-gh-actions/pr-comment@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ steps.pr.outputs.pr-number }}
          message: |
            ✅ Deployment completed successfully!
            - Image: ${{ steps.build.outputs.image }}
            - Environment: dev

      - name: Comment on failure
        if: failure()
        uses: organization/b-gh-actions/pr-comment@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ steps.pr.outputs.pr-number }}
          message: '❌ Deployment failed! Check workflow logs.'
```

### Lambda Deployment (Production)

```yaml
name: Deploy Lambda to Production

on:
  workflow_dispatch:
    inputs:
      release:
        description: 'Release version (use <<latest>> for latest)'
        default: '<<latest>>'

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Get release version
        id: release
        uses: organization/b-gh-actions/get-release-version@v1
        with:
          release: ${{ github.event.inputs.release }}
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Configure AWS
        uses: organization/b-gh-actions/aws-configure@v1

      - name: Find S3 package version
        id: s3-version
        uses: organization/b-gh-actions/get-s3-version-by-tag@v1
        with:
          s3-bucket: my-lambda-packages
          s3-key: my-app/prod/package.zip
          version-tag: ${{ steps.release.outputs.version }}

      - name: Update Lambda functions
        uses: organization/b-gh-actions/update-lambda-functions@v1
        with:
          function-prefix: my-prod-app
          s3-bucket: my-lambda-packages
          s3-key: my-app/prod/package.zip
          s3-version-id: ${{ steps.s3-version.outputs.version-id }}
```

### Lambda Release Pipeline

```yaml
name: Release Lambda Package

on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

  publish:
    needs: release
    if: startsWith(github.event.commits[0].message, 'chore(main):')
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Extract version
        id: version
        run: |
          VERSION=$(echo "${{ github.event.commits[0].message }}" | sed -n 's/.*release \([0-9\.]*\).*/\1/p')
          echo "version=v$VERSION" >> $GITHUB_OUTPUT

      - name: Create Lambda package
        id: package
        uses: organization/b-gh-actions/lambda-package-python@v1
        with:
          version-tag: ${{ steps.version.outputs.version }}

      - name: Configure AWS
        uses: organization/b-gh-actions/aws-configure@v1

      - name: Upload to S3
        uses: organization/b-gh-actions/upload-lambda-package-s3@v1
        with:
          package-file: ${{ steps.package.outputs.package-path }}
          s3-bucket: my-lambda-packages
          s3-key: my-app/prod/package.zip
          version-tag: ${{ steps.version.outputs.version }}
```

### Lambda Dev Deployment on PR Comment

```yaml
name: Lambda Dev Deploy on Comment

on:
  issue_comment:
    types: [created]

jobs:
  deploy:
    if: github.event.issue.pull_request && contains(github.event.comment.body, 'Dev deploy!')
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    steps:
      - name: Handle PR comment
        id: pr
        uses: organization/b-gh-actions/pr-comment-handler@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Create Lambda package
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

      - name: Update Lambda functions
        uses: organization/b-gh-actions/update-lambda-functions@v1
        with:
          function-prefix: my-dev-app
          s3-bucket: my-lambda-packages
          s3-key: my-app/dev/package.zip
          s3-version-id: ${{ steps.upload.outputs.version-id }}

      - name: Comment on success
        if: success()
        uses: organization/b-gh-actions/pr-comment@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ steps.pr.outputs.pr-number }}
          message: '✅ Lambda deployment completed!'

      - name: Comment on failure
        if: failure()
        uses: organization/b-gh-actions/pr-comment@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ steps.pr.outputs.pr-number }}
          message: '❌ Lambda deployment failed!'
```

### CI Pipeline with Secret Scanning

```yaml
name: CI

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Scan for secrets
        uses: organization/b-gh-actions/secret-scanning@v1

      - name: Run tests
        run: |
          # Your test commands here
```

## Development

### Adding New Actions

1. Create a new directory for your action: `mkdir action-name`
2. Add `action.yml` with action definition
3. Add `README.md` with documentation and usage examples
4. Update this main README with the new action
5. Test the action in a project before tagging

### Versioning

- Use semantic versioning tags: `v1`, `v1.0.0`, `v1.0.1`
- Move major version tags (`v1`, `v2`) forward to point to latest minor/patch
- Create new major version for breaking changes

### Testing Actions Locally

Use [act](https://github.com/nektos/act) to test actions locally:

```bash
act -l                    # List available actions
act push                  # Test push event
act workflow_dispatch     # Test workflow dispatch
```

## Contributing

When updating actions:
1. Update the action's `action.yml` and `README.md`
2. Test in a non-production environment first
3. Update version tags after validation
4. Document any breaking changes
