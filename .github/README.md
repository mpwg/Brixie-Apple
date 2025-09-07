# GitHub Actions CI/CD for Brixie

This directory contains GitHub Actions workflows for automated building and testing of the Brixie iOS/macOS app.

## Workflows

### `ci.yml` - Continuous Integration

Automatically runs on:
- **Push** to `main` or `docs/*` branches
- **Pull requests** to `main` branch

#### Jobs

**Build Job**
- Builds both iOS and macOS platforms in parallel
- Uses Makefile targets: `make build-ios` and `make build-macos`
- Requires `REBRICKABLE_API_KEY` secret
- Caches Swift Package Manager dependencies

**Test Job**  
- Runs after successful builds
- Tests both iOS and macOS platforms in parallel
- Uses Makefile targets: `make test-ios` and `make test-macos`
- Requires `REBRICKABLE_API_KEY` secret

#### Required Secrets

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `REBRICKABLE_API_KEY` | API key for Rebrickable LEGO service | ✅ Yes |

⚠️ **Without the API key secret, builds will fail as designed for security.**

## Setup Instructions

### 1. Add API Key Secret

1. Go to your repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `REBRICKABLE_API_KEY`
4. Value: Your Rebrickable API key from https://rebrickable.com/api/
5. Click **Add secret**

### 2. Verify Workflow

After adding the secret:
1. Push to `main` or create a PR
2. Check **Actions** tab to see builds running
3. Both iOS and macOS builds should complete successfully
4. Tests should run and pass

## Local Development

The same Makefile commands used in CI work locally:

```bash
# Set API key and build
REBRICKABLE_API_KEY="your_key_here" make build-all

# Run tests
REBRICKABLE_API_KEY="your_key_here" make test-all

# Or use .env file
echo "REBRICKABLE_API_KEY=your_key" > .env
make build-all && make test-all
```

## Security Features

- **Mandatory API Keys**: Builds fail without API key for security
- **Secret-only builds**: API keys only from GitHub secrets in CI
- **No fallback**: No insecure builds possible
- **Build isolation**: Each job runs in clean environment

## Troubleshooting

### Build Fails: "API key required"
- Check that `REBRICKABLE_API_KEY` secret is set in repository settings
- Verify secret name matches exactly (case-sensitive)
- Ensure API key is valid from Rebrickable

### Cache Issues
- Swift Package Manager dependencies are cached automatically
- Cache key based on `Package.resolved` file
- Force cache refresh by updating dependencies

### Platform-Specific Issues
- iOS builds use iPhone 16 simulator
- macOS builds use Mac Catalyst
- Both require Xcode latest-stable