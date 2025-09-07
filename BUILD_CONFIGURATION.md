# Build Configuration for API Keys

This project supports secure API key injection at build time using environment variables and build scripts.

## Quick Setup

1. **Get your Rebrickable API key** from [https://rebrickable.com/api/](https://rebrickable.com/api/)

2. **Choose one of these methods:**

### Method 1: Environment Variable (Recommended for CI/CD)
```bash
export REBRICKABLE_API_KEY="your_api_key_here"
xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Debug build
```

### Method 2: Local Environment File (Recommended for Development)
```bash
# Copy template and edit with your API key
cp .env.template .env
# Edit .env with your actual API key

# Build will automatically use .env file
xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Debug build
```

### Method 3: Inline with Build Command
```bash
REBRICKABLE_API_KEY="your_api_key_here" xcodebuild -project Brixie.xcodeproj -scheme Brixie build
```

## How It Works

1. **Build Script**: `Scripts/generate-api-config.sh` runs before compilation
2. **Generated File**: Creates `Brixie/Configuration/Generated/GeneratedConfiguration.swift`
3. **Integration**: `APIKeyManager` uses embedded key as fallback when no keychain key exists
4. **Security**: Generated files and .env are in .gitignore

## Fallback Behavior

The app uses this priority order for API keys:
1. **User-provided key** (stored in keychain via Settings)
2. **Build-time embedded key** (from environment variable)
3. **No key** (user must provide one in Settings)

## CI/CD Integration

### GitHub Actions
```yaml
- name: Build with API Key
  env:
    REBRICKABLE_API_KEY: ${{ secrets.REBRICKABLE_API_KEY }}
  run: xcodebuild -project Brixie.xcodeproj -scheme Brixie build
```

### Xcode Cloud
Add `REBRICKABLE_API_KEY` as an environment variable in your Xcode Cloud workflow.

## Security Notes

- Generated configuration files are excluded from git
- API keys are only embedded in the binary during build
- Keys are not stored in source code or project files
- Users can still override with their own keys via Settings