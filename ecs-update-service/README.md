# ECS Update Service Action

Updates an ECS service with a new task definition ARN. This action is useful when you need to update a service independently from task definition registration.

## Usage

```yaml
- name: Update ECS service
  uses: BConsultingKft/b-gh-actions/ecs-update-service@main
  with:
    cluster-name: my-cluster
    service-name: my-service
    task-definition-arn: arn:aws:ecs:eu-central-1:123456789012:task-definition/my-task:5
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `cluster-name` | ECS cluster name | Yes | - |
| `service-name` | ECS service name | Yes | - |
| `task-definition-arn` | ARN of the task definition to deploy | Yes | - |
| `force-new-deployment` | Force a new deployment even if task definition has not changed | No | `true` |

## Prerequisites

- AWS credentials must be configured (use `aws-configure` action)
- Required IAM permissions:
  - `ecs:UpdateService`

## How it works

1. Calls `aws ecs update-service` with the provided task definition ARN
2. Optionally forces a new deployment (default behavior)
3. ECS will gradually replace running tasks with new ones

## Example: Combined with register task definition

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

- name: Update ECS service
  uses: BConsultingKft/b-gh-actions/ecs-update-service@main
  with:
    cluster-name: bos-prod-backend
    service-name: bos-prod-backend
    task-definition-arn: ${{ steps.register-task-def.outputs.task-definition-arn }}
```

## Example: Update multiple services with the same task definition

```yaml
- name: Register task definition
  id: register-task-def
  uses: BConsultingKft/b-gh-actions/ecs-register-task-definition@main
  with:
    ecr-image: ${{ steps.build.outputs.image }}
    task-family: bos-prod-api
    task-def-ssm-param: /bos-prod-api/taskdef-template-name

- name: Update primary service
  uses: BConsultingKft/b-gh-actions/ecs-update-service@main
  with:
    cluster-name: bos-prod-cluster
    service-name: bos-prod-api-primary
    task-definition-arn: ${{ steps.register-task-def.outputs.task-definition-arn }}

- name: Update secondary service
  uses: BConsultingKft/b-gh-actions/ecs-update-service@main
  with:
    cluster-name: bos-prod-cluster
    service-name: bos-prod-api-secondary
    task-definition-arn: ${{ steps.register-task-def.outputs.task-definition-arn }}
```

## Related Actions

- [ecs-register-task-definition](../ecs-register-task-definition) - Register a new task definition
- [deploy-ecs](../deploy-ecs) - Combined action that registers task definition and updates service