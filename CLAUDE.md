# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **public** collection of reusable GitHub Actions that can be referenced by other projects within the organization. Each action should be self-contained and designed for reuse across multiple repositories.

**Repository visibility**: Public (required for GitHub Actions to reference these actions from other repositories)

**Current consumers**: b-onsite-sync-api, and other b-onsite projects

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
- **deploy-ecs**: Deploy to ECS by updating task definition and service (uses ecs-register-task-definition + ecs-update-service)
- **ecs-register-task-definition**: Register a new ECS task definition with updated container image
- **ecs-update-service**: Update an ECS service with a task definition ARN
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

## Making Changes to Actions

### Impact of Changes
⚠️ **IMPORTANT**: Changes to actions affect ALL projects using them. Always consider:
- Backward compatibility
- Testing in a non-production project first
- Communicating breaking changes to teams

### Testing Workflow
1. Make changes to action(s) in a feature branch
2. Update README.md if inputs/outputs changed
3. Test in a consuming project by temporarily referencing the branch:
   ```yaml
   uses: BConsultingKft/b-gh-actions/action-name@your-branch-name
   ```
4. Validate the action works as expected
5. Merge to main branch
6. Update consuming projects to use `@main` or create version tags

### Creating New Actions
1. Create directory: `mkdir action-name`
2. Create `action.yml`:
   ```yaml
   name: 'Action Name'
   description: 'What it does'
   branding:
     icon: 'icon-name'
     color: 'color-name'

   inputs:
     input-name:
       description: 'Input description'
       required: true/false
       default: 'optional-default'

   outputs:
     output-name:
       description: 'Output description'
       value: ${{ steps.step-id.outputs.output-name }}

   runs:
     using: 'composite'
     steps:
       - name: Step name
         shell: bash
         run: |
           # Your script here
   ```
3. Create `README.md` with:
   - Description
   - Usage examples
   - Input/output table
   - Prerequisites
   - Complete workflow examples
4. Test locally if possible with `act`
5. Test in a consuming project
6. Update main `README.md` with the new action
7. Update this `CLAUDE.md` with the new action

### Versioning Strategy
For now, all projects reference `@main` for rapid iteration. In the future:
- Create version tags when actions stabilize: `v1.0.0`
- Move major version tags: `git tag -f v1` and `git push -f origin v1`
- Projects can reference `@v1` for stability
- Document breaking changes in GitHub releases

## Real-World Usage Examples

### Example: b-onsite-sync-api

The b-onsite-sync-api project demonstrates typical usage patterns:

**CI Workflow** (`ci.yml`):
```yaml
- name: Secret Scanning
  uses: BConsultingKft/b-gh-actions/secret-scanning@main
```

**Dev Deployment** (`dev-deploy-on-comment.yml`):
```yaml
- name: Handle PR comment
  id: pr
  uses: BConsultingKft/b-gh-actions/pr-comment-handler@main
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}

- name: Create Lambda package
  id: package
  uses: BConsultingKft/b-gh-actions/lambda-package-python@main
  with:
    version-tag: snapshot-${{ steps.pr.outputs.pr-sha }}
    python-version: '3.11'

- name: Configure AWS
  uses: BConsultingKft/b-gh-actions/aws-configure@main

- name: Upload to S3
  id: upload
  uses: BConsultingKft/b-gh-actions/upload-lambda-package-s3@main
  with:
    package-file: ${{ steps.package.outputs.package-path }}
    s3-bucket: bos-common-shared-infra-lambda-packages
    s3-key: sync-api/dev/package.zip
    version-tag: snapshot-${{ steps.pr.outputs.pr-sha }}

- name: Update Lambda functions
  uses: BConsultingKft/b-gh-actions/update-lambda-functions@main
  with:
    function-prefix: bos-dev-sync-api
    s3-bucket: bos-common-shared-infra-lambda-packages
    s3-key: sync-api/dev/package.zip
    s3-version-id: ${{ steps.upload.outputs.version-id }}

- name: Comment on success
  if: success()
  uses: BConsultingKft/b-gh-actions/pr-comment@main
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ steps.pr.outputs.pr-number }}
    message: '✅ Lambda deployment completed!'
```

**Production Deployment** (`deploy-to-prod.yml`):
```yaml
- name: Get release version
  id: get-version
  uses: BConsultingKft/b-gh-actions/get-release-version@main
  with:
    release: ${{ github.event.inputs.release }}
    github-token: ${{ github.token }}

- name: Configure AWS
  uses: BConsultingKft/b-gh-actions/aws-configure@main

- name: Get S3 package version
  id: get-object-version
  uses: BConsultingKft/b-gh-actions/get-s3-version-by-tag@main
  with:
    s3-bucket: bos-common-shared-infra-lambda-packages
    s3-key: sync-api/prod/package.zip
    version-tag: ${{ steps.get-version.outputs.version }}

- name: Update Lambda functions
  uses: BConsultingKft/b-gh-actions/update-lambda-functions@main
  with:
    function-prefix: bos-prod-sync-api
    s3-bucket: bos-common-shared-infra-lambda-packages
    s3-key: sync-api/prod/package.zip
    s3-version-id: ${{ steps.get-object-version.outputs.version-id }}
```

## Troubleshooting

### Common Issues

**"Unable to resolve action" error**
- Ensure repository is public
- Check action path is correct: `BConsultingKft/b-gh-actions/action-name@main`
- Verify the action directory exists in the repository

**Action not found in subdirectory**
- Each action must have an `action.yml` file in its directory
- Path format: `owner/repo/subdirectory@ref`

**Workflow fails with "Required input not provided"**
- Check the action's README for required inputs
- Ensure all required inputs have values in the workflow

**AWS authentication fails**
- Verify workflow has `id-token: write` permission
- Check IAM role ARN is correct
- Ensure OIDC trust relationship is configured in AWS

**S3 version not found**
- Verify S3 versioning is enabled on the bucket
- Check the version tag matches exactly (case-sensitive)
- Ensure the package was uploaded with the correct tag

### Debugging Actions

To debug an action in a consuming project:
1. Add debugging output in the action's shell scripts:
   ```bash
   echo "Debug: variable value is $VARIABLE"
   ```
2. Check the workflow run logs in GitHub Actions
3. Use `act` locally to test if possible
4. Reference a feature branch to test changes:
   ```yaml
   uses: BConsultingKft/b-gh-actions/action-name@debug-branch
   ```

## Benefits of This Approach

- **Code Reduction**: Projects using these actions see 70-80% reduction in workflow code
- **Consistency**: Same patterns across all b-onsite projects
- **Maintainability**: Update once, apply everywhere
- **Testing**: Actions can be tested independently
- **Documentation**: Centralized documentation in action READMEs
- **Reusability**: Easy to adopt in new projects
