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

Since this is an Xcode project, use the following commands:

### Building
```bash
xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Debug build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BrixieUITests
```

### Running a Single Test
```bash
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BrixieTests/BrixieTests/example
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