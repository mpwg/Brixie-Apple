# Copilot Instructions for Brixie

## Project Overview

Brixie is a modern multi-platform SwiftUI application for browsing and searching LEGO sets using the Rebrickable API. The app targets iOS 26.0+, macOS 26.0+ (via Mac Catalyst), and visionOS 26.0+ with a focus on modern Swift concurrency and SwiftUI/SwiftData architecture.

**Key Technologies:**
- SwiftUI for user interface
- SwiftData for local data persistence  
- RebrickableLegoAPIClient for LEGO set data
- Swift 6.0+ with modern concurrency
- Xcode project (not Swift Package Manager)

## Build Instructions

### Prerequisites
- Xcode 15.0+ with iOS 26.0+ SDK
- macOS 15.0+ for development
- Valid Rebrickable API key for runtime functionality

### Building
**Note**: xcodebuild requires macOS with Xcode installed. In non-macOS environments, validate changes by code review.

```bash
# Build for debugging
xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Debug build

# Build for release
xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Release build

# Clean build
xcodebuild -project Brixie.xcodeproj -scheme Brixie clean build
```

### Testing
**IMPORTANT**: This project uses Swift Testing framework for unit tests, NOT XCTest.
**Note**: Testing requires macOS environment with Xcode and iOS Simulator.

```bash
# Run unit tests (Swift Testing framework)
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 26'

# Run UI tests (XCTest framework)  
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 26' -only-testing:BrixieUITests

# Run specific unit test
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 26' -only-testing:BrixieTests/BrixieTests/example
```

**Test Framework Notes:**
- `BrixieTests/`: Uses Swift Testing framework (`import Testing`, `@Test` annotations)
- `BrixieUITests/`: Uses XCTest framework  (`import Testing`, `@Test` annotations)
- Unit tests use `#expect()`

### Environment Setup
1. Clone repository and open `Brixie.xcodeproj` in Xcode
2. Dependencies are managed via Swift Package Manager within Xcode
3. No additional setup scripts required - Xcode handles Swift Package resolution
4. For runtime: Configure API key in app Settings or via `@AppStorage("rebrickableAPIKey")`

## Project Architecture

### Core Files
- `Brixie/BrixieApp.swift` - Main app entry point with SwiftData ModelContainer setup
- `Brixie/Item.swift` - SwiftData model for LegoSet (note: filename is Item.swift but contains LegoSet class)
- `Brixie/ContentView.swift` - Main tab-based UI coordinator

### Services Layer (`Brixie/Services/`)
- `LegoSetService.swift` - API integration with Rebrickable, data fetching/caching
- `ImageCacheService.swift` - Image downloading and caching (memory + disk)

### Views Layer (`Brixie/Views/`)
- `SetsListView.swift` - Browse all LEGO sets with pagination
- `SearchView.swift` - Search functionality with recent searches
- `SetDetailView.swift` - Detailed set information with image viewer
- `FavoritesView.swift` - User's favorited sets
- `SettingsView.swift` - API key configuration and cache management

### Test Structure
- `BrixieTests/BrixieTests.swift` - Unit tests using Swift Testing framework
- `BrixieUITests/` - UI automation tests using XCTest framework

### Configuration
- `Brixie/Info.plist` - App configuration (background modes)
- `Brixie/Brixie.entitlements` - Capabilities (iCloud, push notifications)
- `.github/dependabot.yml` - Dependency updates (Swift packages, GitHub Actions)

## Dependencies

### External Packages
- **RebrickableLegoAPIClient** (v2.0.0+): API client for Rebrickable LEGO data
  - Repository: https://github.com/mpwg/Rebrickable-swift
  - Configured in Xcode project, not Package.swift

### Platform Frameworks
- SwiftUI (iOS 26.0+, macOS 26.0+, visionOS 26.0+)
- SwiftData for persistence
- Foundation for networking and data handling

## Development Workflow

### Making Changes
1. **Always build before making changes** to understand current state
2. **Run tests frequently** - unit tests are fast, UI tests are slower
3. **Test on multiple platforms** - app supports iOS, macOS (Catalyst), and visionOS
4. **Validate API integration** - most functionality requires valid Rebrickable API key

### Common Issues
- **API Key Required**: Most app functionality requires valid Rebrickable API key
- **Network Dependency**: App needs internet access for initial data fetching
- **Image Caching**: Large image cache stored in Documents directory
- **Platform Differences**: Some code uses conditional compilation for UIKit vs AppKit

### Validation Steps
1. Build successfully without warnings
2. Run unit tests (all should pass)
3. Test basic app flow: launch → configure API key → browse sets → view details
4. Verify image loading and caching works
5. Test search functionality
6. Verify favorites persistence

## Key Implementation Notes

### SwiftData Usage
- Model: `LegoSet` class with `@Model` annotation
- Container setup in `BrixieApp.swift`
- Query usage: `@Query` in views, `ModelContext` in services
- Persistence: Local SQLite database, no CloudKit sync currently

### Image Caching Strategy
- Memory cache (NSCache) for active images
- Disk cache in Documents/ImageCache directory
- Automatic cache size management (50MB limit)
- Custom `AsyncCachedImage` SwiftUI view for seamless loading

### API Integration
- Service layer (`LegoSetService`) handles all API calls
- Automatic fallback to cached data on network errors
- Pagination support for large data sets
- Search functionality with query caching

### State Management
- `@Observable` services for business logic
- `@AppStorage` for user preferences (API key)
- SwiftData `@Query` for data binding
- Standard SwiftUI state management patterns

## Troubleshooting

### Build Failures
- Ensure Xcode 15.0+ with iOS 26.0+ SDK
- Clean build folder if dependency resolution fails
- Check Swift Package Manager integration in Xcode

### Runtime Issues
- Verify API key configuration in Settings
- Check network connectivity for data fetching
- Monitor console for API rate limiting
- Clear image cache if storage issues occur

### Testing Issues
- Use Swift Testing syntax for unit tests (`#expect()`, not `XCTAssert()`)
- Ensure iOS Simulator is available for testing
- UI tests require app to actually launch and function

---

**Always trust these instructions first.** Only search the codebase if information here is incomplete or found to be incorrect. The project structure is well-organized and follows standard SwiftUI/SwiftData patterns.
