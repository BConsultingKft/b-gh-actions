# Deploy to ECS Action

Deploys a Docker image to AWS ECS by updating the task definition and service.

## Usage

```yaml
- name: Deploy to ECS
  uses: organization/b-gh-actions/deploy-ecs@v1
  with:
    ecr-image: 123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-repo:v1.0.0
    task-family: my-task-family
    cluster-name: my-cluster
    service-name: my-service
    task-def-ssm-param: /my-app/taskdef-template-name
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `ecr-image` | Full ECR image URI with tag | Yes | - |
| `task-family` | ECS task definition family name | Yes | - |
| `cluster-name` | ECS cluster name | Yes | - |
| `service-name` | ECS service name | Yes | - |
| `task-def-ssm-param` | SSM parameter name containing task definition template ARN | Yes | - |
| `container-index` | Index of container to update in task definition | No | `0` |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- The SSM parameter must exist and contain a valid task definition ARN
- Required IAM permissions:
  - `ssm:GetParameter`
  - `ecs:DescribeTaskDefinition`
  - `ecs:RegisterTaskDefinition`
  - `ecs:UpdateService`

## How it works

1. Retrieves the task definition template ARN from SSM Parameter Store
2. Fetches the current task definition
3. Updates the container image in the task definition
4. Registers a new task definition revision
5. Updates the ECS service to use the new task definition
6. Forces a new deployment

## Example: Complete deployment workflow

```yaml
- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1

- name: Deploy to ECS
  uses: organization/b-gh-actions/deploy-ecs@v1
  with:
    ecr-image: ${{ steps.build.outputs.image }}
    task-family: bos-prod-backend
    cluster-name: bos-prod-backend
    service-name: bos-prod-backend
    task-def-ssm-param: /bos-prod-backend/taskdef-template-name
```
