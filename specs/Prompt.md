# Brixie Implementation Prompt

## Agent Instructions

You are tasked with implementing **Brixie**, a multi-platform SwiftUI application for browsing and managing LEGO set collections using the Rebrickable API. This document provides the complete context and instructions for implementation.

## Project Context

Brixie is inspired by the Brick Collector app and targets:
- **iOS 26+** (iPhone and iPad)
- **macOS 26+** (Mac Catalyst)
- **visionOS 26+**

The app uses:
- **SwiftUI** for the user interface
- **SwiftData** for persistence
- **RebrickableLegoAPIClient** v2.0.0+ for API integration
- **Swift 6+** with modern concurrency

## Implementation Workflow

Follow the **Spec-Driven Workflow v1** (see `.github/instructions/spec-driven-workflow-v1.instructions.md`):

1. **ANALYZE** - Review requirements and existing code
2. **DESIGN** - Create technical design and plan
3. **IMPLEMENT** - Write production-quality code
4. **VALIDATE** - Test and verify implementation
5. **REFLECT** - Refactor and document
6. **HANDOFF** - Package for review

## Core Features to Implement

### Phase 1: Foundation (Tasks 1.1-1.4)
```swift
// 1. Configure SwiftData Models
@Model final class LegoSet
@Model final class Theme  
@Model final class UserCollection

// 2. Set up API Configuration
// 3. Create Navigation Structure
// 4. Implement Image Cache Service
```

### Phase 2: Browse & Display (Tasks 2.1-2.4)
- Set list view with grid/list toggle
- Theme navigation with hierarchy
- Set detail view with all properties
- Loading and empty states

### Phase 3: Search & Filter (Tasks 3.1-3.4)
- Search by set number, name, theme
- Barcode scanning capability
- Advanced filtering options
- Search history and suggestions

### Phase 4: Collection Management (Tasks 4.1-4.4)
- User collection tracking ("Meine LEGO-Sammlung")
- Wishlist management ("LEGO-Wunschliste")
- Missing parts tracking ("Fehlende Teile")
- Collection statistics dashboard

### Phase 5: Polish (Tasks 5.1-5.4)
- Animations and transitions
- Offline support with queue
- Performance optimization
- Full accessibility support

## Key Requirements

### User Interface
- **German localization** as shown in screenshots ("Meine LEGO-Sammlung", "Ich verstehe", etc.)
- **Modern, elegant design** following Apple HIG
- **Platform-specific navigation**: Tab bar (iOS), Sidebar (macOS/iPadOS)
- **Empty states** with helpful messages and action buttons
- **Dark mode support**

### Data Management
```swift
// Image caching with 50MB limit
class ImageCacheService {
    // NSCache for memory
    // Documents/ImageCache for disk
}

// API Integration
@AppStorage("rebrickableAPIKey") var apiKey: String = ""
```

### Testing Requirements
- **Unit tests** using Swift Testing framework (`#expect()`)
- **UI tests** using XCTest framework
- **Build validation**: `REBRICKABLE_API_KEY="key" fastlane ios test_all`

## Important Instructions to Follow

### From `.github/instructions/`:

1. **Swift Guidelines** (`swift.instructions.md`):
   - Use structured concurrency (async/await)
   - Implement proper error handling
   - Follow Swift naming conventions
   - Use value types where appropriate

2. **Accessibility** (`a11y.instructions.md`):
   - WCAG 2.2 Level AA compliance
   - VoiceOver support
   - Dynamic Type support
   - Keyboard navigation
   - High contrast support

3. **Localization** (`localization.instructions.md`):
   - Support German as primary language
   - Use Localizable.strings
   - Format dates/numbers appropriately

4. **Conventional Commits** (`conventional-commit.instructions.md`):
   ```
   feat: add set list view with grid layout
   fix: resolve image caching memory leak
   docs: update API integration guide
   ```

## File Structure

```
Brixie/
├── Models/
│   ├── LegoSet.swift
│   ├── Theme.swift
│   └── UserCollection.swift
├── Views/
│   ├── ContentView.swift
│   ├── SetListView.swift
│   ├── SetDetailView.swift
│   ├── SearchView.swift
│   └── CollectionView.swift
├── ViewModels/
│   ├── SetListViewModel.swift
│   ├── SearchViewModel.swift
│   └── CollectionViewModel.swift
├── Services/
│   ├── LegoSetService.swift
│   ├── ImageCacheService.swift
│   └── ThemeManager.swift
├── Components/
│   ├── AsyncCachedImage.swift
│   ├── SetCardView.swift
│   └── EmptyStateView.swift
└── Resources/
    └── Localizable.strings
```

## Implementation Checklist

Before starting each task:
- [ ] Read the task description in `tasks.md`
- [ ] Review related requirements in `requirements.md`
- [ ] Check technical design in `design.md`
- [ ] Set up proper test coverage

During implementation:
- [ ] Follow Swift best practices
- [ ] Implement accessibility features
- [ ] Add German localization
- [ ] Write unit tests
- [ ] Document complex logic

After completing each task:
- [ ] Run tests: `REBRICKABLE_API_KEY="key" fastlane ios test_all`
- [ ] Verify iOS build: `fastlane ios build_ios`
- [ ] Verify macOS build: `fastlane ios build_macos`
- [ ] Update task status in `tasks.md`

## API Key Configuration

```swift
// In Settings or via environment
@AppStorage("rebrickableAPIKey") private var apiKey = ""

// For CI/CD
// Set REBRICKABLE_API_KEY environment variable
```

## Example Implementation Pattern

```swift
// Follow MVVM pattern
import SwiftUI
import SwiftData

// View
struct SetListView: View {
    @StateObject private var viewModel = SetListViewModel()
    @Query private var cachedSets: [LegoSet]
    
    var body: some View {
        NavigationStack {
            // Implementation with accessibility
        }
        .task {
            await viewModel.loadSets()
        }
    }
}

// ViewModel
@MainActor
final class SetListViewModel: ObservableObject {
    @Published var sets: [LegoSet] = []
    @Published var isLoading = false
    
    private let service = LegoSetService()
    
    func loadSets() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            sets = try await service.fetchSets()
        } catch {
            // Handle error with user feedback
        }
    }
}
```

## Success Criteria

The implementation is complete when:
1. All features from Brick Collector screenshots are implemented
2. App runs on iOS, macOS (Catalyst), and visionOS
3. All tests pass (`fastlane ios test_all`)
4. German localization is complete
5. Accessibility requirements are met
6. Image caching works with 50MB limit
7. Offline support is functional
8. Search and filtering work as specified
9. Collection management features are complete
10. Documentation is up to date

## Getting Started

1. **Review existing code** in the repository
2. **Read all instruction files** in `.github/instructions/`
3. **Start with Phase 1** tasks in `tasks.md`
4. **Follow the 6-phase workflow** for each implementation
5. **Test continuously** with Fastlane commands
6. **Document decisions** in Decision Records

## Questions to Consider

Before implementing each feature, ask:
- Does this match the Brick Collector screenshots?
- Is it accessible to all users?
- Will it work offline with cached data?
- Is the German translation accurate?
- Does it follow Swift best practices?
- Is it tested adequately?

---

**Remember**: The goal is to create a production-quality app that is elegant, accessible, and fully functional. Follow the structured workflow, maintain documentation, and ensure all code is tested and validated.