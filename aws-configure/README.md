# AWS Configure Action

Configures AWS credentials using OIDC for b-onsite projects with sensible defaults.

## Usage

```yaml
- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `role-to-assume` | AWS IAM role ARN to assume | No | `arn:aws:iam::736766805372:role/bos-common-shared_infra-gha-trust` |
| `aws-region` | AWS region | No | `eu-central-1` |

## Example with custom role

```yaml
- name: Configure AWS
  uses: organization/b-gh-actions/aws-configure@v1
  with:
    role-to-assume: arn:aws:iam::123456789012:role/my-custom-role
    aws-region: us-east-1
```

## Required Permissions

The workflow must have the following permissions:
```yaml
permissions:
  id-token: write
  contents: read
```
