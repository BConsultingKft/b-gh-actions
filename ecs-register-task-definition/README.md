# ECS Register Task Definition Action

Registers a new ECS task definition with an updated container image. This action fetches a task definition template from SSM Parameter Store, updates the container image, and registers a new revision.

## Usage

```yaml
- name: Register task definition
  id: register-task-def
  uses: BConsultingKft/b-gh-actions/ecs-register-task-definition@main
  with:
    ecr-image: 123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-repo:v1.0.0
    task-family: my-task-family
    task-def-ssm-param: /my-app/taskdef-template-name

- name: Use the task definition ARN
  run: echo "New task definition: ${{ steps.register-task-def.outputs.task-definition-arn }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `ecr-image` | Full ECR image URI with tag | Yes | - |
| `task-family` | ECS task definition family name | Yes | - |
| `task-def-ssm-param` | SSM parameter name containing task definition template ARN | Yes | - |
| `container-index` | Index of container to update in task definition | No | `0` |

## Outputs

| Output | Description |
|--------|-------------|
| `task-definition-arn` | ARN of the newly registered task definition |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- The SSM parameter must exist and contain a valid task definition ARN
- Required IAM permissions:
  - `ssm:GetParameter`
  - `ecs:DescribeTaskDefinition`
  - `ecs:RegisterTaskDefinition`

## How it works

1. Retrieves the task definition template ARN from SSM Parameter Store
2. Fetches the current task definition
3. Updates the container image at the specified index
4. Registers a new task definition revision
5. Outputs the new task definition ARN

## Example: Register task definition and use elsewhere

```yaml
- name: Configure AWS
  uses: BConsultingKft/b-gh-actions/aws-configure@main

- name: Register task definition
  id: register-task-def
  uses: BConsultingKft/b-gh-actions/ecs-register-task-definition@main
  with:
    ecr-image: ${{ steps.build.outputs.image }}
    task-family: bos-prod-backend
    task-def-ssm-param: /bos-prod-backend/taskdef-template-name

# Use the task definition ARN for custom deployment logic
- name: Custom deployment
  run: |
    echo "Task definition ARN: ${{ steps.register-task-def.outputs.task-definition-arn }}"
```

## Related Actions

- [ecs-update-service](../ecs-update-service) - Update an ECS service with a task definition
- [deploy-ecs](../deploy-ecs) - Combined action that registers task definition and updates service