# Build and Push to ECR Action

Builds a Docker image and pushes it to Amazon ECR.

## Usage

```yaml
- name: Build and push to ECR
  id: build
  uses: organization/b-gh-actions/build-push-ecr@v1
  with:
    ecr-registry: 123456789012.dkr.ecr.eu-central-1.amazonaws.com
    ecr-repository: my-app
    image-tag: v1.0.0
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `ecr-registry` | ECR registry URL | Yes | - |
| `ecr-repository` | ECR repository name | Yes | - |
| `image-tag` | Docker image tag | Yes | - |
| `dockerfile` | Path to Dockerfile | No | `Dockerfile` |
| `build-args` | Docker build arguments (space-separated) | No | - |
| `context` | Docker build context | No | `.` |

## Outputs

| Output | Description |
|--------|-------------|
| `image` | Full Docker image URI with tag |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- ECR repository must exist
- Required IAM permissions:
  - `ecr:GetAuthorizationToken`
  - `ecr:BatchCheckLayerAvailability`
  - `ecr:PutImage`
  - `ecr:InitiateLayerUpload`
  - `ecr:UploadLayerPart`
  - `ecr:CompleteLayerUpload`

## Example: Build with build args

```yaml
- name: Build and push
  id: build
  uses: organization/b-gh-actions/build-push-ecr@v1
  with:
    ecr-registry: 123456789012.dkr.ecr.eu-central-1.amazonaws.com
    ecr-repository: my-app
    image-tag: v1.0.0
    build-args: VERSION=v1.0.0 ENVIRONMENT=production

- name: Use image URI
  run: echo "Built image: ${{ steps.build.outputs.image }}"
```

## Example: Complete release workflow

```yaml
- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1

- name: Extract version
  id: version
  run: echo "version=v1.0.0" >> $GITHUB_OUTPUT

- name: Build and push Docker image
  id: build
  uses: organization/b-gh-actions/build-push-ecr@v1
  with:
    ecr-registry: 123456789012.dkr.ecr.eu-central-1.amazonaws.com
    ecr-repository: my-app
    image-tag: ${{ steps.version.outputs.version }}
    build-args: VERSION=${{ steps.version.outputs.version }}

- name: Deploy to ECS
  uses: organization/b-gh-actions/deploy-ecs@v1
  with:
    ecr-image: ${{ steps.build.outputs.image }}
    task-family: my-app
    cluster-name: my-cluster
    service-name: my-service
    task-def-ssm-param: /my-app/taskdef-template-name
```
