# Brixie Architecture

This document defines the app-wide conventions for MVVM + async/await used throughout Brixie.

## SwiftUI-Only Architecture

**CRITICAL REQUIREMENT**: Brixie is a pure SwiftUI application that does NOT use UIKit or AppKit.

- **No platform-specific imports**: Only `SwiftUI`, `Foundation`, `SwiftData`, and the `RebrickableLegoAPIClient` are allowed
- **Device detection**: Use `@Environment(\.horizontalSizeClass)` instead of `UIDevice`
- **Sharing**: Use SwiftUI's `ShareLink` instead of `UIActivityViewController`/`NSSharingServicePicker`
- **Image loading**: Custom SwiftUI-based solutions or `AsyncImage`, no UIKit/AppKit image types
- **Platform differences**: Handle via SwiftUI modifiers and environment values, not conditional compilation

## Layers

- View (SwiftUI)
  - Owns no business logic.
  - Holds a single Observable ViewModel via `@State` (iOS 17+/Swift 6).
  - Triggers async work using `.task { await vm.load() }` or `Button { Task { await vm.action() } }`.
  - Displays state from the ViewModel and routes user actions back to it.

- ViewModel (Observable, `@MainActor`)
  - Exposes state for the View: `isLoading`, `error: BrixieError?`, and immutable data models for rendering.
  - Coordinates with repositories using async/await.
  - Performs pagination and input debouncing where applicable.
  - Converts thrown errors to `BrixieError` and updates `error` on the main actor.

- Repository (protocol + implementation, `@MainActor`)
  - Provides app-level use cases as async functions.
  - Orchestrates Remote and Local data sources and sync timestamps.
  - Hides networking and persistence details from ViewModels.

- Data Sources
  - Remote: calls RebrickableLegoAPIClient via async/await and maps to domain models.
  - Local: wraps SwiftData sync operations.

- Services
  - Cross-cutting utilities only (e.g., `ImageCacheService`, `APIConfigurationService`, `NetworkMonitorService`).
  - Must not duplicate repository responsibilities. No direct use from Views.

## Concurrency

- All networking and disk I/O is async/await based; no callbacks or Combine.
- ViewModels and Repositories are annotated `@MainActor` to ensure UI-safe state updates.
- Use `Task { await ... }` in Views when invoking async VM methods from synchronous closures.
- Use `actor`s only for shared mutable state that crosses isolation boundaries. Most app types are `@MainActor` or value types.

## Observation and State Management

**Observable Pattern**: ViewModels MUST use `@Observable` macro (iOS 17+) for automatic change tracking:

```swift
@Observable
@MainActor
final class LegoSetViewModel {
    var sets: [LegoSet] = []
    var isLoading = false
    var error: BrixieError?
    
    func loadSets() async { /* ... */ }
}
```

**State Management**: Views MUST use `@State` for ViewModel instances:

```swift
struct BrowseView: View {
    @State private var viewModel = LegoSetViewModel()
    
    var body: some View {
        NavigationView {
            // View automatically observes viewModel changes
        }
        .task {
            await viewModel.loadSets()
        }
    }
}
```

**Key Benefits**:

- Automatic UI updates when ViewModel properties change
- No manual `@Published` or `@StateObject` boilerplate
- Native Swift 6 concurrency support
- Thread-safe with `@MainActor` annotation

**Migration Note**: Legacy `@ObservableObject`/`@StateObject` patterns should be migrated to `@Observable`/`@State` during refactoring.

## Error Handling

- Bubble up thrown errors as `BrixieError` from repositories where possible.
- ViewModels capture errors, map them to `BrixieError`, and expose `error` for the View.
- Common UI handling provided by `ErrorUIComponents`.

## Testing Notes

- Prefer unit tests targeting ViewModels with repository test doubles.
- Repositories can be tested with in-memory `LocalDataSource` and stubbed `RemoteDataSource`.
