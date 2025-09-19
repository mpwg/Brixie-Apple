# Copilot Instructions for Brixie

## Brixie AI Coding Agent Guide

Brixie is a **pure SwiftUI** multi-platform app for browsing LEGO sets via the Rebrickable API. It targets iOS 26+, macOS 26+ (Catalyst), and visionOS 26+, using Swift 6+ concurrency and SwiftData for persistence. The codebase is organized for clarity and maintainability.

**CRITICAL: SwiftUI-Only Architecture**

- **NO UIKit or AppKit dependencies** - Use only SwiftUI primitives and cross-platform APIs
- Use `@Environment(\.horizontalSizeClass)` instead of `UIDevice` for device detection
- Use SwiftUI's native sharing via `ShareLink` instead of `UIActivityViewController`
- All UI components must be pure SwiftUI - no platform-specific wrappers
- Image loading uses SwiftUI's `AsyncImage` or custom SwiftUI-based solutions

### Architecture Overview

- **Entry Point:** `BrixieApp.swift` sets up SwiftData ModelContainer for three models: `LegoSet`, `Theme`, `UserCollection`.
- **Data Models:**
  - `LegoSet.swift`: Main LEGO set model with `@Attribute(.unique)` setNumber
  - `Theme.swift`: LEGO themes (e.g., Star Wars, Creator)
  - `UserCollection.swift`: User's saved/favorite sets
- **UI:** SwiftUI views in `Views/` folder. Main navigation in `ContentView.swift`.
- **Services:** API/data logic in `Services/` (`LegoSetService.swift`, `ImageCacheService.swift`).
- **Components:** Reusable UI components in `Components/` (`AsyncCachedImage.swift`).
- **Configuration:** API key management in `Configuration/` with build-time generation.

### Developer Workflow

- **Prerequisites:** Xcode 15+ on macOS 15+, `REBRICKABLE_API_KEY` environment variable required.
- **Build Script:** `./Scripts/generate-api-config.sh` generates `Configuration/Generated/GeneratedConfiguration.swift` with embedded API key.
- **Build:**
  - Fastlane (recommended): `REBRICKABLE_API_KEY="key" bundle exec fastlane ios build_all`
  - Direct xcodebuild: Run script first, then build normally
- **Test:**
  - Test targets exist in Xcode project (`BrixieTests`, `BrixieUITests`) but directories not yet created
  - Fastlane: `REBRICKABLE_API_KEY="key" bundle exec fastlane ios test_all`
- **Branch-Based Config:** Debug for feature/develop branches, Release for main/release/hotfix branches.

### Key Conventions & Patterns

- **SwiftUI-Only Architecture:**

  - NO UIKit/AppKit imports or dependencies
  - Use SwiftUI's environment values for device detection
  - Platform-specific behavior via SwiftUI modifiers and environment
  - Pure SwiftUI image loading and caching solutions

- **API Key Management:**
  - Build-time: `REBRICKABLE_API_KEY` env var → `Scripts/generate-api-config.sh` → `Configuration/Generated/GeneratedConfiguration.swift`
  - Runtime: `APIConfiguration.shared` manages user-set keys via `@AppStorage("rebrickableAPIKey")`
  - Both mechanisms supported for flexibility (CI vs user settings)
- **SwiftData:** Use `@Model` for persistence, `@Query` in views, `ModelContext` in services.
- **Image Caching:**
  - Memory: NSCache in `ImageCacheService`
  - Disk: Documents/ImageCache (auto-managed, 50MB limit)
  - Use `AsyncCachedImage` component for UI image loading
- **MVVM Pattern:** Services handle business logic, Views use `@Observable` classes
- **Platform Support:** Conditional compilation for UIKit vs AppKit differences

### Integration Points

- **External Dependencies:**
  - `RebrickableLegoAPIClient` (v2.0.0+) from https://github.com/mpwg/Rebrickable-swift
  - Managed in Xcode project dependencies, not Package.swift
- **CI/CD:**
  - GitHub Actions workflows in `.github/workflows/` (see `.github/README.md`)
  - API key must be set as repository secret `REBRICKABLE_API_KEY` for CI builds
  - Makefile-based build commands via Fastlane lanes

### Troubleshooting

- **Common Issues:**
  - Missing API key: Run `./Scripts/generate-api-config.sh` first or set in app Settings
  - Network connectivity required for initial data fetching from Rebrickable
  - Image cache can grow large; managed automatically but clearable if needed
  - Platform-specific bugs: Check conditional compilation blocks
- **Validation Steps:**
  - Build succeeds without errors on both iOS/macOS targets
  - Run available tests via Fastlane
  - Verify basic app flow: launch → API key setup → browse sets → view details

### Project-Specific Instructions

**IMPORTANT:** Always follow ALL instruction files in `.github/instructions/` before making any changes:

- `swift.instructions.md` - Swift coding standards and patterns
- `swiftui-observation.instructions.md` - Proper use of SwiftUI's @Observable framework and migration from ObservableObject
- `spec-driven-workflow-v1.instructions.md` - Development workflow and documentation requirements
- `conventional-commit.instructions.md` - Commit message formatting
- `github-actions-ci-cd-best-practices.instructions.md` - CI/CD workflow guidelines
- `a11y.instructions.md` - Accessibility compliance requirements
- `markdown.instructions.md` - Documentation standards
- `localization.instructions.md` - Internationalization guidelines

These instruction files contain critical project requirements and must be consulted before any code modifications.

---

**Reference these instructions first. For missing details, check `CLAUDE.md`, `.github/README.md`, and source files.**
