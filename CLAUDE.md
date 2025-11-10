# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a collection of reusable GitHub Actions that can be referenced by other projects within the organization. Each action should be self-contained and designed for reuse across multiple repositories.

## Repository Structure

Actions are organized in separate directories within the repository. Each action directory should contain:
- `action.yml` or `action.yaml` - The action definition file
- `README.md` - Documentation for the action, including usage examples
- Any supporting scripts or files needed by the action

## Common Development Commands

### Validating Action YAML
```bash
# Install actionlint for GitHub Actions validation
# On Linux:
curl -s https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash

# Validate all action files
actionlint action.yml

# Or validate specific action
actionlint path/to/action/action.yml
```

### Testing Actions Locally
```bash
# Use act to test actions locally (requires Docker)
# Install: https://github.com/nektos/act
act -l  # List available actions
act     # Run actions locally
```

### YAML Linting
```bash
# Install yamllint
pip install yamllint

# Lint YAML files
yamllint .
yamllint path/to/action.yml
```

## Available Actions

This repository contains the following reusable actions:

### Security
- **secret-scanning**: TruffleHog secret scanning with full git history

### AWS Infrastructure
- **aws-configure**: Configure AWS credentials using OIDC (default: bos-common-shared_infra-gha-trust role)
- **build-push-ecr**: Build Docker image and push to ECR
- **deploy-ecs**: Deploy to ECS by updating task definition and service
- **deploy-frontend-s3-cloudfront**: Deploy frontend to S3 and invalidate CloudFront

### AWS Lambda
- **lambda-package-python**: Create Lambda deployment package for Python with dependencies
- **upload-lambda-package-s3**: Upload Lambda package to S3 with versioning and tagging
- **get-s3-version-by-tag**: Find S3 object version ID by searching for version tag
- **update-lambda-functions**: Update multiple Lambda functions with S3 package

### Release Management
- **get-release-version**: Get latest release or validate specific version

### Pull Request Workflow
- **pr-comment-handler**: Get PR details and checkout PR branch from issue comment
- **pr-comment**: Post comment on pull request

## Architecture Notes

### Action Referencing
Other repositories reference actions from this repo using:
```yaml
- uses: organization/b-gh-actions/action-name@v1
```

### Common Patterns

#### Backend API Deployment (ECS)
1. Configure AWS credentials (`aws-configure`)
2. Build and push Docker image (`build-push-ecr`)
3. Deploy to ECS (`deploy-ecs`)

#### Frontend Deployment (S3 + CloudFront)
1. Build frontend application (npm/vite/etc)
2. Configure AWS credentials (`aws-configure`)
3. Deploy to S3 and invalidate CloudFront (`deploy-frontend-s3-cloudfront`)

#### Lambda Deployment (Production)
1. Get release version (`get-release-version`)
2. Configure AWS credentials (`aws-configure`)
3. Find S3 package version by tag (`get-s3-version-by-tag`)
4. Update Lambda functions (`update-lambda-functions`)

#### Lambda Release Pipeline
1. Create release (release-please)
2. Create Lambda package (`lambda-package-python`)
3. Configure AWS credentials (`aws-configure`)
4. Upload package to S3 (`upload-lambda-package-s3`)

#### Lambda Dev Deployment on PR Comment
1. Handle PR comment and checkout (`pr-comment-handler`)
2. Create Lambda package (`lambda-package-python`)
3. Configure AWS (`aws-configure`)
4. Upload to S3 (`upload-lambda-package-s3`)
5. Update Lambda functions (`update-lambda-functions`)
6. Comment back with status (`pr-comment`)

#### Dev Deployment on PR Comment (ECS/Docker)
1. Handle PR comment and checkout (`pr-comment-handler`)
2. Build and deploy
3. Comment back with status (`pr-comment`)

#### Production Release Deployment
1. Get release version (`get-release-version`)
2. Configure AWS (`aws-configure`)
3. Deploy using appropriate action (ECS, S3+CloudFront, or Lambda)

### AWS Resources Convention
- IAM Role: `arn:aws:iam::736766805372:role/bos-common-shared_infra-gha-trust`
- Region: `eu-central-1`
- ECR Registry: `736766805372.dkr.ecr.eu-central-1.amazonaws.com`
- Task definition templates stored in SSM Parameter Store
- Lambda packages bucket: `bos-common-shared-infra-lambda-packages` (S3 versioning enabled)
- Lambda function naming: `bos-{env}-{app-name}-*` (e.g., `bos-prod-sync-api-function1`)
- Lambda package S3 keys: `{app-name}/{env}/package.zip`

### Versioning
- Actions use semantic versioning tags (v1, v1.0.0, etc.)
- Major version tags (v1, v2) should be moved forward to point to latest minor/patch
- Breaking changes require major version bump

### Action Types
All actions in this repository are **Composite Actions** (YAML-based) that orchestrate existing actions and shell scripts.

### Input/Output Best Practices
- All inputs have clear descriptions
- Required inputs are marked explicitly
- Sensible defaults provided where possible (especially for b-onsite specific values)
- All outputs documented with descriptions
- Consistent naming: kebab-case for input/output names

### Security Considerations
- Third-party actions pinned to major versions (some to specific commits where needed)
- Secrets never exposed in logs
- Minimal necessary permissions documented in each action's README
- All inputs validated by underlying actions/tools
