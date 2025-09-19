# Brixie

[![iOS CI](https://github.com/mpwg/Brixie-Apple/actions/workflows/ci.yml/badge.svg)](https://github.com/mpwg/Brixie-Apple/actions/workflows/ci.yml)
[![CodeQL](https://github.com/mpwg/Brixie-Apple/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/mpwg/Brixie-Apple/actions/workflows/github-code-scanning/codeql)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

[![Swift](https://img.shields.io/badge/Swift-6+-orange.svg?logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-blue.svg?logo=swift&logoColor=white)](https://developer.apple.com/swiftui)
[![iOS](https://img.shields.io/badge/iOS-26+-lightgrey.svg?logo=apple)](https://developer.apple.com)
[![macOS](https://img.shields.io/badge/macOS-26+-lightgrey.svg?logo=apple)](https://developer.apple.com)
[![visionOS](https://img.shields.io/badge/visionOS-26+-purple.svg?logo=apple)](https://developer.apple.com)

> A modern, multi-platform SwiftUI app for exploring the LEGO universe

[Features](#features) • [Getting Started](#getting-started) • [Documentation](#documentation) • [Contributing](#contributing)

Brixie brings the complete LEGO catalog to your fingertips with an elegant, native iOS, macOS, and visionOS experience. Browse over 20,000 LEGO sets, manage your collection, track missing parts, and discover new builds—all powered by the comprehensive Rebrickable API.

## Features

🧩 **Comprehensive LEGO Database**

- Browse 20,000+ LEGO sets from all themes and years
- Detailed set information including parts count, release year, and retail pricing
- High-quality set images with intelligent caching

🔍 **Advanced Search & Discovery**

- Search by set number, name, theme, or year
- Barcode scanning for quick set lookup
- Theme-based navigation with hierarchical browsing
- Advanced filtering options

📦 **Personal Collection Management**

- Track owned sets and wishlist items
- Missing parts tracking for incomplete sets
- Collection statistics and insights
- Export collection data

✨ **Modern Native Experience**

- Pure SwiftUI interface optimized for each platform
- Dark mode support with elegant visual design
- Accessibility-first approach (WCAG 2.2 Level AA compliant)
- Offline browsing with intelligent data caching

🌐 **Multi-Platform Support**

- Native iOS app (iPhone & iPad)
- macOS support via Mac Catalyst
- visionOS support for immersive experiences

## Platform Support

- **iOS 26.0+** - iPhone and iPad
- **macOS 26.0+** - Mac Catalyst
- **visionOS 26.0+** - Apple Vision Pro

## Getting Started

### Prerequisites

- Xcode 16+ with Swift 6+ support
- macOS 15+ for development
- [Rebrickable API key](https://rebrickable.com/api/) (free registration required)

### Quick Start

1. **Clone the repository**

   ```bash
   git clone https://github.com/mpwg/Brixie-Apple.git
   cd Brixie-Apple
   ```

2. **Set up your API key**

   ```bash
   export REBRICKABLE_API_KEY="your_api_key_here"
   ./Scripts/generate-api-config.sh
   ```

3. **Build and run**

   ```bash
   # Install dependencies
   bundle install
   
   # Using Fastlane (recommended)
   REBRICKABLE_API_KEY="your_key" bundle exec fastlane dev
   
   # Or use Xcode directly
   open Brixie.xcodeproj
   ```

> [!TIP]
> You can also configure your API key directly in the app's Settings after first launch.

### Development Workflow

**Build the project:**

```bash
# Development build (for local testing)
bundle exec fastlane dev

# Validation build (for CI/testing)
bundle exec fastlane build

# Show all available commands
bundle exec fastlane show_help
```

**Run tests:**

```bash
# Run unit tests using xcodebuild
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests  
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BrixieUITests

# Run macOS tests
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=macOS'
```

**Deployment:**

```bash
# TestFlight beta build
bundle exec fastlane beta

# App Store release build
bundle exec fastlane release
```

## Architecture

Brixie follows a clean, modular architecture optimized for SwiftUI and modern iOS development:

```text
┌─────────────────────────────────────────────┐
│                Views (SwiftUI)               │
│  ┌─────────────┐ ┌─────────────┐ ┌────────┐ │
│  │Browse Views │ │Search Views │ │Settings│ │
│  └─────────────┘ └─────────────┘ └────────┘ │
└─────────────────────┬───────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│            ViewModels (@Observable)          │
│  ┌─────────────┐ ┌─────────────┐ ┌────────┐ │
│  │BrowseVM     │ │SearchVM     │ │Others  │ │
│  └─────────────┘ └─────────────┘ └────────┘ │
└─────────────────────┬───────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│              Services Layer                  │
│  ┌─────────────┐ ┌─────────────┐ ┌────────┐ │
│  │LegoSetSvc   │ │ImageCache   │ │Others  │ │
│  └─────────────┘ └─────────────┘ └────────┘ │
└─────────────────────┬───────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│           Data Layer (SwiftData)             │
│  ┌─────────────┐ ┌─────────────┐ ┌────────┐ │
│  │LegoSet      │ │Theme        │ │UserCol │ │
│  └─────────────┘ └─────────────┘ └────────┘ │
└─────────────────────┬───────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│        External (RebrickableLegoAPIClient)   │
└─────────────────────────────────────────────┘
```

### Key Components

- **SwiftUI Views**: Pure SwiftUI interface with platform-optimized layouts
- **ViewModels**: `@Observable` classes following MVVM pattern
- **Services**: Business logic and API integration
- **SwiftData Models**: Core data models with relationships
- **External API**: Rebrickable API integration via dedicated Swift package

## Dependencies

- **SwiftUI & SwiftData** - Native Apple frameworks for UI and data persistence
- **[RebrickableLegoAPIClient](https://github.com/mpwg/Rebrickable-swift)** (v2.0.0+) - Official Swift client for Rebrickable API
- **Swift 6+** - Modern concurrency and performance features

## Documentation

- **[Build Configuration Guide](BUILD_CONFIGURATION.md)** - API key setup and build process
- **[Data Migration Strategy](MIGRATION.md)** - SwiftData schema evolution
- **[Architecture Guide](ARCHITECTURE.md)** - Detailed technical architecture
- **[API Integration](API_INTEGRATION_SUMMARY.md)** - Rebrickable API usage patterns

## Contributing

We welcome contributions! Please read our contributing guidelines and follow our code of conduct.

### Development Standards

- **Swift 6+ with strict concurrency checking**
- **SwiftUI-only architecture** (no UIKit/AppKit dependencies)
- **Accessibility-first design** (WCAG 2.2 Level AA)
- **Comprehensive test coverage** with Swift Testing framework
- **Modern iOS patterns** using latest Apple frameworks

### Code Quality

This project maintains high code quality standards:

- **SwiftLint** for consistent code style
- **Comprehensive unit and UI tests**
- **Accessibility testing and validation**  
- **Performance monitoring and optimization**
- **Security-focused API key management**

## License

See LICENSE file for details.
