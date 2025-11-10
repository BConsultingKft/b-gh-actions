# Secret Scanning Action

Scans repository for secrets using TruffleHog with full git history.

## Usage

```yaml
- name: Scan for secrets
  uses: organization/b-gh-actions/secret-scanning@v1
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extra_args` | Extra arguments to pass to TruffleHog | No | `--results=verified,unknown` |

## Example with custom arguments

```yaml
- name: Scan for secrets
  uses: organization/b-gh-actions/secret-scanning@v1
  with:
    extra_args: '--results=verified'
```
