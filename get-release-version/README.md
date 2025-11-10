# Get Release Version Action

Gets the latest release version from GitHub or validates a provided version exists.

## Usage

```yaml
- name: Get release version
  id: release
  uses: organization/b-gh-actions/get-release-version@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}

- name: Use the version
  run: echo "Deploying version ${{ steps.release.outputs.version }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `release` | Release version to use (use `<<latest>>` for latest release) | No | `<<latest>>` |
| `github-token` | GitHub token for API access | Yes | - |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The resolved release version |

## Example with specific version

```yaml
- name: Get release version
  id: release
  uses: organization/b-gh-actions/get-release-version@v1
  with:
    release: v1.2.3
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Behavior

- If `release` is `<<latest>>`, fetches the most recent release
- If `release` is a specific version, validates it exists
- Exits with error if no releases found or specified version doesn't exist
