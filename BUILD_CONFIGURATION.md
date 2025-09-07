# Build Configuration for API Keys

This project supports secure API key injection at build time using environment variables and a Makefile-based build system.

## Quick Start

**⚠️ IMPORTANT**: API key is now REQUIRED for all builds. Builds will fail without it.

The simplest way to build:

```bash
REBRICKABLE_API_KEY="your_api_key_here" make build-ios
```

Or for development, create a `.env` file:
```bash
echo "REBRICKABLE_API_KEY=your_api_key_here" > .env
make build-all
```

Get your API key from: https://rebrickable.com/api/

## Available Make Targets

### Building
- `make build-ios` - Build iOS app with API key injection
- `make build-macos` - Build macOS app with API key injection  
- `make build-all` - Build both iOS and macOS platforms

### Testing
- `make test-ios` - Run iOS tests
- `make test-macos` - Run macOS tests
- `make test-all` - Run tests on both platforms

### Configuration Management
- `make generate-config` - Generate API configuration (REQUIRES API key)
- `make generate-config-dev` - Generate config without API key (development only)
- `make clean-config` - Remove generated configuration files
- `make clean` - Full clean (config + build artifacts)

### Help
- `make help` - Show all available targets and usage examples

## Build Methods

**Method 1: Environment Variable (Recommended for CI/CD)**
```bash
REBRICKABLE_API_KEY="your_api_key_here" make build-ios
```

**Method 2: Local Environment File (Recommended for Development)**
```bash
# Create .env file with your API key
echo "REBRICKABLE_API_KEY=your_api_key_here" > .env

# Build using Makefile
make build-all
```

**Method 3: Direct Xcode Integration**
```bash
# Generate config first, then use Xcode
make generate-config
# Then build in Xcode as normal
```

## How It Works

1. **Makefile**: `make generate-config` creates configuration before compilation
2. **Generated File**: Creates `Brixie/Configuration/Generated/GeneratedConfiguration.swift`
3. **Integration**: `APIConfiguration` reads embedded key from build-time generation
4. **Security**: Generated files and .env are in .gitignore

## API Key Behavior

**SECURE BY DEFAULT**: All builds now require an API key at build time.

The app uses build-time embedded keys exclusively:
1. **Build-time embedded key** (from environment variable) - **REQUIRED**
2. **No fallback** - builds fail without API key for security

## CI/CD Integration

### GitHub Actions
```yaml
- name: Build with API Key
  env:
    REBRICKABLE_API_KEY: ${{ secrets.REBRICKABLE_API_KEY }}
  run: make build-all
```

### Xcode Cloud
```yaml
- name: Generate Configuration
  env:
    REBRICKABLE_API_KEY: ${{ secrets.REBRICKABLE_API_KEY }}
  run: make generate-config
- name: Build
  run: xcodebuild -project Brixie.xcodeproj -scheme Brixie build
```

## Security Notes

- Generated configuration files are excluded from git
- API keys are only embedded in the binary during build
- Keys are not stored in source code or project files
- Users can still override with their own keys via Settings