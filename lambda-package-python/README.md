# Lambda Package (Python) Action

Creates a deployment package for Python Lambda functions by bundling source code and dependencies.

## Usage

```yaml
- name: Create Lambda package
  id: package
  uses: organization/b-gh-actions/lambda-package-python@v1
  with:
    version-tag: v1.0.0
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `source-dir` | Source directory to package | No | `src` |
| `requirements-file` | Path to requirements.txt file | No | `requirements.txt` |
| `python-version` | Python version to use | No | `3.12` |
| `output-file` | Output zip file name | No | `package.zip` |
| `version-tag` | Version tag to include in version.txt | Yes | - |
| `include-version-file` | Include version.txt file with metadata | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `package-path` | Path to the created package zip file |

## What it does

1. Sets up Python with specified version
2. Creates a package directory
3. Copies source code from source directory
4. Installs dependencies from requirements.txt using `pip install --target`
5. Creates version.txt with metadata (version, build time, commit, branch)
6. Zips everything into a deployment package

## Example: Basic usage

```yaml
- name: Checkout code
  uses: actions/checkout@v4

- name: Create Lambda package
  id: package
  uses: organization/b-gh-actions/lambda-package-python@v1
  with:
    version-tag: v1.0.0

- name: Use package
  run: |
    echo "Package created at: ${{ steps.package.outputs.package-path }}"
```

## Example: Custom configuration

```yaml
- name: Create Lambda package
  id: package
  uses: organization/b-gh-actions/lambda-package-python@v1
  with:
    source-dir: lambda/
    requirements-file: lambda/requirements.txt
    python-version: '3.11'
    output-file: my-lambda.zip
    version-tag: snapshot-${{ github.sha }}
```

## Example: Without version file

```yaml
- name: Create Lambda package
  uses: organization/b-gh-actions/lambda-package-python@v1
  with:
    version-tag: v1.0.0
    include-version-file: 'false'
```

## Package Structure

The created package will have:
```
package.zip
├── src/              # Your source code
├── dependency/       # Installed pip packages
├── version.txt       # Version metadata (if enabled)
└── ...
```

## Notes

- Dependencies are installed directly into the package root for Lambda compatibility
- The action handles missing source directories or requirements files gracefully
- Version file includes git commit and branch information automatically
- Package is created with quiet zip mode to reduce output noise
