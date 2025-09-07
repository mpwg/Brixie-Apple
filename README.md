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
# Using Makefile (recommended)
make lint

# Or directly
swiftlint lint
```

## Continuous Integration

The project uses GitHub Actions for CI/CD with the following workflow:

- **Code Quality**: Runs SwiftLint for code style and quality checks
- **Build and Test**: Builds and tests the app on iOS and macOS using Makefile targets
- **Platform Support**: Matrix builds for both iOS and macOS platforms

### CI Configuration

The CI pipeline includes:

- **Lint Job**: SwiftLint code quality checks with strict mode
- **Build Job**: Matrix builds for iOS and macOS platforms using `make ci-build`
- **Test Job**: Matrix tests for iOS and macOS platforms using `make test-ios` and `make test-macos`
- Caching for Swift Package Manager and DerivedData
- Proper job dependencies (tests run after successful builds)

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
