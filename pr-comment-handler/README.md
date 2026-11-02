# PR Comment Handler Action

Gets PR details from an issue comment event, refuses untrusted requests, and checks out the PR head commit.

## Guard

Before anything is checked out, the action refuses (fails the step and sets the `refused` output) when:

- the PR comes from a fork (`head.repo.full_name` is not this repository), or
- the commenter (`comment.user.login`) does not have `admin`, `maintain` or `write` permission on the repository.

The `pr-*` outputs are set **before** the guard runs, so the caller's failure-comment steps can still use them.

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
| `refused` | Reason the request was refused (fork, or commenter without write access); empty when allowed |

## Prerequisites

This action is designed to work with the `issue_comment` event:
```yaml
on:
  issue_comment:
    types: [created]
```

Required workflow permissions (enough for the PR and collaborator-permission APIs with `GITHUB_TOKEN`):
```yaml
permissions:
  pull-requests: read
  contents: read
```

## What it does

1. Fetches PR details using the GitHub API
2. Outputs PR metadata (number, ref, SHA, repo)
3. Refuses PRs from forks and commenters without write access (sets `refused`, fails)
4. Checks out the PR head **SHA** (not the branch name, so a push after the comment cannot change what is built) from this repository, with `persist-credentials: false` so the token is not left in `.git/config`

Because credentials are not persisted, later steps that need to `git push` or `git fetch` with auth must set up credentials themselves.

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

      - name: Comment the refusal
        if: failure() && steps.pr.outputs.refused
        uses: organization/b-gh-actions/pr-comment@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ github.event.issue.number }}
          message: "Dev deploy refused: ${{ steps.pr.outputs.refused }}"
```
