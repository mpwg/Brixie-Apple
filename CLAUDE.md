# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Brixie is a multi-platform iOS/macOS SwiftUI application that integrates with the Rebrickable LEGO API. The app supports iOS, macOS, and visionOS platforms with SwiftUI for the user interface and SwiftData for persistent data storage.

## Architecture

- **Main App**: `BrixieApp.swift` - Entry point with SwiftData ModelContainer setup for the `Item` model
- **UI**: SwiftUI-based with `ContentView.swift` as the main view (currently incomplete)
- **Data Model**: `Item.swift` - SwiftData model with timestamp property
- **External Dependencies**: Uses `RebrickableLegoAPIClient` package from https://github.com/mpwg/Rebrickable-swift (v2.0.0+)

## Development Commands

This project uses Fastlane for build automation and testing. All commands require the `REBRICKABLE_API_KEY` environment variable.

### Fastlane Lanes

#### Building
```bash
# Build iOS app for simulator
REBRICKABLE_API_KEY="your_key" fastlane ios build_ios

# Build macOS app (Mac Catalyst)
REBRICKABLE_API_KEY="your_key" fastlane ios build_macos

# Build both platforms
REBRICKABLE_API_KEY="your_key" fastlane ios build_all
```

#### Testing
```bash
# Run iOS tests
REBRICKABLE_API_KEY="your_key" fastlane ios test_ios

# Run macOS tests
REBRICKABLE_API_KEY="your_key" fastlane ios test_macos

# Run tests on both platforms
REBRICKABLE_API_KEY="your_key" fastlane ios test_all
```

#### Utilities
```bash
# Sync code signing certificates and profiles
REBRICKABLE_API_KEY="your_key" fastlane ios certificates

# Clean build artifacts and generated files
REBRICKABLE_API_KEY="your_key" fastlane ios clean

# Show available lanes and help
fastlane ios show_help
```

### Direct xcodebuild (legacy)
If needed, you can still use direct xcodebuild commands:

```bash
# Generate config and build iOS app
REBRICKABLE_API_KEY="your_key" ./Scripts/generate-api-config.sh
xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build

# Generate config and build macOS app
REBRICKABLE_API_KEY="your_key" ./Scripts/generate-api-config.sh
xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' build
```

## Platform Support

- iOS 26.0+
- macOS 26.0+ 
- visionOS 26.0+
- Uses Swift 5.0 with modern concurrency features enabled
- App Sandbox and Hardened Runtime enabled for macOS

## Testing Framework

- **Unit Tests**: Uses Swift Testing framework (not XCTest) in `BrixieTests`
- **UI Tests**: Uses XCTest framework in `BrixieUITests`

## Key Dependencies

- SwiftUI for UI
- SwiftData for data persistence
- RebrickableLegoAPIClient for LEGO data integration
- I want to build an App that uses Rebrickable-swift to show and search for Lego Sets
- This App should offer a List of all Sets
- This App should offer a Search mode
- It should be possible to have an detailed view of a Set
- It should download and cache the Images of a Set and view it
- The App is called "Brixie", the website is brixie.net
- It targets the most modern Version of iOS (iOS Version 26 beta) and macOS (macOS 26 Beta)
- It has a modern, cool, easy to use and elegant user interface
- please ensure that the project compiles
- do not create a macOS Target, only use mac (Mac Catalyst)
- always test both the ios and macos build