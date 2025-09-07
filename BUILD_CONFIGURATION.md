# Build Configuration for API Keys

This project supports secure API key injection at build time using environment variables and build scripts.

## Setup Required

**⚠️ IMPORTANT**: You must first add the build script to Xcode before using this system.

### 1. Add Build Script to Xcode (One-time setup)

1. Open `Brixie.xcodeproj` in Xcode
2. Select the "Brixie" project in the navigator
3. Select the "Brixie" target 
4. Go to "Build Phases" tab
5. Click "+" and select "New Run Script Phase"
6. Drag the new phase to be **first** (before "Sources")
7. In the script box, enter:
   ```bash
   "${SRCROOT}/Scripts/generate-api-config.sh"
   ```
8. Set "Shell" to `/bin/bash`

### 2. Build with API Key

**Method 1: Environment Variable (Recommended for CI/CD)**
```bash
export REBRICKABLE_API_KEY="your_api_key_here"
xcodebuild -project Brixie.xcodeproj -scheme Brixie build
```

**Method 2: Local Environment File (Recommended for Development)**
```bash
# Copy template and edit with your API key
cp .env.template .env
# Edit .env with your actual API key

# Build in Xcode or command line
xcodebuild -project Brixie.xcodeproj -scheme Brixie build
```

**Method 3: Inline with Build Command**
```bash
REBRICKABLE_API_KEY="your_api_key_here" xcodebuild -project Brixie.xcodeproj -scheme Brixie build
```

## How It Works

1. **Build Script**: `Scripts/generate-api-config.sh` runs before compilation (via Run Script Phase)
2. **Generated File**: Creates `Brixie/Configuration/Generated/GeneratedConfiguration.swift`
3. **Integration**: `APIKeyManager` uses embedded key exclusively
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