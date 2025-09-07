[![iOS CI](https://github.com/mpwg/Brixie-Apple/actions/workflows/ci.yml/badge.svg)](https://github.com/mpwg/Brixie-Apple/actions/workflows/ci.yml)
[![CodeQL](https://github.com/mpwg/Brixie-Apple/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/mpwg/Brixie-Apple/actions/workflows/github-code-scanning/codeql)

[![Dependabot Updates](https://github.com/mpwg/Brixie-Apple/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/mpwg/Brixie-Apple/actions/workflows/dependabot/dependabot-updates)

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Xcode 26](https://img.shields.io/badge/Xcode-26-orange.svg?logo=xcode&logoColor=f5f5f5)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26+-lightgrey.svg?logo=apple)](https://developer.apple.com)
[![macOS](https://img.shields.io/badge/macOS-26+-lightgrey.svg?logo=apple)](https://developer.apple.com)

# Brixie

A modern SwiftUI application for browsing and searching LEGO sets using the Rebrickable API.

## Features

- Browse LEGO sets with modern SwiftUI interface
- Search functionality for finding specific sets
- Detailed set views with cached images
- Multi-platform support (iOS, macOS, visionOS)
- Integration with Rebrickable LEGO API

## Platform Support

- iOS 26.0+
- macOS 26.0+ (Mac Catalyst)
- visionOS 26.0+

## Development

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

### Code Quality

The project uses SwiftLint for code quality checks. Install it using:

```bash
brew install swiftlint
```

Run SwiftLint:

```bash
swiftlint lint
```

## Continuous Integration

The project uses GitHub Actions for CI/CD with the following workflow:

- **Build and Test**: Builds and tests the app on iOS, macOS, and visionOS
- **Code Quality**: Runs SwiftLint and static analysis
- **Archive**: Creates release archives for distribution (main branch only)

### CI Configuration

The CI pipeline includes:

- Matrix builds for multiple platforms and configurations
- Caching for Swift Package Manager and DerivedData
- Unit and UI testing (UI tests skip visionOS due to simulator limitations)
- SwiftLint code quality checks
- Static code analysis
- Archive creation for release builds

## Architecture

- **Main App**: SwiftUI-based with SwiftData for persistence
- **External Dependencies**: RebrickableLegoAPIClient for LEGO data
- **Testing**: Swift Testing framework for unit tests, XCTest for UI tests

## Dependencies

- SwiftUI
- SwiftData
- [RebrickableLegoAPIClient](https://github.com/mpwg/Rebrickable-swift) (v2.0.0+)

## Documentation

- [Data Migration Strategy](MIGRATION.md) - Guidelines for SwiftData schema evolution
- [Build Configuration](BUILD_CONFIGURATION.md) - API key management and build setup

## License

See LICENSE file for details.
