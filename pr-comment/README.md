# PR Comment Action

Posts a comment on a pull request.

## Usage

```yaml
- name: Comment on success
  if: success()
  uses: organization/b-gh-actions/pr-comment@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ github.event.issue.number }}
    message: '✅ Deployment completed successfully!'
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `github-token` | GitHub token for API access | Yes |
| `pr-number` | Pull request number | Yes |
| `message` | Comment message to post | Yes |

## Prerequisites

Required workflow permissions:
```yaml
permissions:
  pull-requests: write
```

## Example: Success and failure comments

```yaml
- name: Deploy
  id: deploy
  run: ./deploy.sh

- name: Comment on success
  if: success()
  uses: organization/b-gh-actions/pr-comment@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ github.event.issue.number }}
    message: |
      ✅ Deployment completed successfully!
      - Environment: production
      - Version: ${{ steps.deploy.outputs.version }}

- name: Comment on failure
  if: failure()
  uses: organization/b-gh-actions/pr-comment@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ github.event.issue.number }}
    message: '❌ Deployment failed! Please check the workflow logs for details.'
```

## Example: With PR comment handler

```yaml
- name: Handle PR comment
  id: pr
  uses: organization/b-gh-actions/pr-comment-handler@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}

- name: Deploy
  run: ./deploy.sh

- name: Comment on success
  if: success()
  uses: organization/b-gh-actions/pr-comment@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ steps.pr.outputs.pr-number }}
    message: '✅ Build and deployment completed!'
```
