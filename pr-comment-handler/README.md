# PR Comment Handler Action

Gets PR details from an issue comment event and checks out the PR branch.

## Usage

```yaml
name: Deploy on Comment
on:
  issue_comment:
    types: [created]

jobs:
  deploy:
    if: github.event.issue.pull_request && contains(github.event.comment.body, 'Deploy!')
    runs-on: ubuntu-latest
    steps:
      - name: Handle PR comment
        id: pr
        uses: organization/b-gh-actions/pr-comment-handler@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Use PR info
        run: |
          echo "PR Number: ${{ steps.pr.outputs.pr-number }}"
          echo "PR SHA: ${{ steps.pr.outputs.pr-sha }}"
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `github-token` | GitHub token for API access | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `pr-number` | Pull request number |
| `pr-ref` | Pull request branch ref |
| `pr-sha` | Pull request HEAD SHA |
| `pr-repo` | Pull request repository full name |

## Prerequisites

This action is designed to work with the `issue_comment` event:
```yaml
on:
  issue_comment:
    types: [created]
```

Required workflow permissions:
```yaml
permissions:
  pull-requests: read
  contents: read
```

## What it does

1. Fetches PR details using the GitHub API
2. Extracts and outputs PR metadata (number, ref, SHA, repo)
3. Checks out the PR branch

## Example: Deploy on comment

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
      pull-requests: write
      contents: read
    steps:
      - name: Handle PR comment
        id: pr
        uses: organization/b-gh-actions/pr-comment-handler@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and deploy
        run: |
          echo "Building PR ${{ steps.pr.outputs.pr-number }}"
          # Your build and deploy steps here
```
