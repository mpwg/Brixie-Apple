# Copilot Instructions for Brixie

## Brixie AI Coding Agent Guide

Brixie is a multi-platform SwiftUI app for browsing LEGO sets via the Rebrickable API. It targets iOS 26+, macOS 26+ (Catalyst), and visionOS, using Swift 6+ concurrency and SwiftData for persistence. The codebase is organized for clarity and maintainability.

### Architecture Overview

- **Entry Point:** `BrixieApp.swift` sets up SwiftData ModelContainer and app state.
- **Data Model:** `Item.swift` defines the main LegoSet model (`@Model`), used throughout.
- **UI:** SwiftUI views in `Views/` and `UI/` folders. Main navigation is in `ContentView.swift`.
- **Services:** API/data logic in `Services/` (e.g., `LegoSetService.swift`, `ImageCacheService.swift`).
- **Repositories:** Abstraction for data access in `Repositories/` (protocols and implementations).
- **Managers:** App-wide state/configuration (e.g., `ThemeManager.swift`).
- **ViewModels:** MVVM pattern for UI logic and state.

### Developer Workflow

- **Build:**
  - Use Xcode 15+ on macOS 15+.
  - Build with:
    `xcodebuild -project Brixie.xcodeproj -scheme Brixie -configuration Debug build`
- **Test:**
  - Unit tests use Swift Testing (`#expect()`), not XCTest.
  - Run with:
    `xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 26'`
  - UI tests in `BrixieUITests/` use XCTest.
- **Fastlane:**
  - Build/release automation via Fastlane (`fastlane/`).
  - Requires `REBRICKABLE_API_KEY` env var for all builds/tests.
  - Example: `REBRICKABLE_API_KEY="your_key" fastlane ios create_release version:1.0.0`

### Key Conventions & Patterns

- **API Key:** Must be set in Settings or via `@AppStorage("rebrickableAPIKey")` for runtime and CI.
- **SwiftData:** Use `@Model` for persistence, `@Query` in views, `ModelContext` in services.
- **Image Caching:**
  - Memory: NSCache
  - Disk: Documents/ImageCache (auto-managed, 50MB limit)
  - Use `AsyncCachedImage` for loading images in UI.
- **MVVM:** ViewModels in `ViewModels/`, views in `Views/`, business logic in services.
- **Testing:**
  - Unit: `BrixieTests/` (Swift Testing)
  - UI: `BrixieUITests/` (XCTest)
- **Platform Differences:** Conditional compilation for UIKit vs AppKit as needed.

### Integration Points

- **External:**
  - `RebrickableLegoAPIClient` (v2.0.0+) from https://github.com/mpwg/Rebrickable-swift
  - Managed in Xcode project, not Package.swift
- **CI/CD:**
  - GitHub Actions workflows in `.github/` (see `.github/README.md`)
  - API key must be set as secret `REBRICKABLE_API_KEY` for CI builds

### Troubleshooting

- **Common Issues:**
  - API key missing: most features will fail
  - Network required for initial data
  - Image cache can grow large; clear if needed
  - Platform-specific bugs: check conditional code
- **Validation:**
  - Build cleanly, run all tests, verify basic app flow (launch, API key, browse, view details)

---

**Reference these instructions first. For missing details, check `CLAUDE.md`, `.github/README.md`, and source files.**
