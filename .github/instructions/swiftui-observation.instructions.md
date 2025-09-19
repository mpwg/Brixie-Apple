---
description: "Instructions for AI agents on proper use of SwiftUI's Observation framework"
applyTo: "**/*.swift"
---

# SwiftUI Observation Framework Instructions

## Overview

Starting with iOS 17, iPadOS 17, macOS 14, tvOS 17, and watchOS 10, SwiftUI provides the `@Observable` macro as a replacement for `ObservableObject`. This document provides comprehensive instructions for AI agents on how to properly migrate from `ObservableObject` to `@Observable` and use Observation correctly.

## Key Benefits of Observation

1. **Better tracking**: Supports tracking optionals and collections of objects
2. **Simplified data flow**: Use `@State` and `@Environment` instead of `@StateObject` and `@EnvironmentObject`
3. **Performance improvements**: Updates views only when observable properties that the view reads actually change
4. **More precise updates**: Views update only based on properties their `body` directly accesses

## Migration Rules

### 1. Replace ObservableObject with @Observable

**BEFORE:**
```swift
import SwiftUI

class DataModel: ObservableObject {
    // properties
}
```

**AFTER:**
```swift
import SwiftUI

@Observable class DataModel {
    // properties
}
```

**AI Agent Rules:**
- Always replace `class ClassName: ObservableObject` with `@Observable class ClassName`
- Remove `: ObservableObject` from class declaration
- Add `@Observable` macro before `class` keyword
- Keep other protocol conformances (e.g., `Identifiable`)

### 2. Remove @Published Property Wrapper

**BEFORE:**
```swift
@Observable class DataModel {
    @Published var items: [Item] = []
    @Published var selectedItem: Item?
}
```

**AFTER:**
```swift
@Observable class DataModel {
    var items: [Item] = []
    var selectedItem: Item?
}
```

**AI Agent Rules:**
- Remove `@Published` from ALL properties in `@Observable` classes
- Properties are automatically observable if accessible to observers
- Use `@ObservationIgnored` for properties that should NOT be tracked

### 3. Use @ObservationIgnored for Non-Observable Properties

**Example:**
```swift
@Observable class DataModel {
    var observedProperty: String = ""
    
    @ObservationIgnored
    private var internalCache: [String: Any] = [:]
    
    @ObservationIgnored
    let configuration: Config = Config()
}
```

**AI Agent Rules:**
- Apply `@ObservationIgnored` to properties that should not trigger view updates
- Use for internal caches, configuration objects, or computed properties that don't need observation

### 4. Replace @StateObject with @State

**BEFORE:**
```swift
struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        // view content
    }
}
```

**AFTER:**
```swift
struct ContentView: View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        // view content
    }
}
```

**AI Agent Rules:**
- Replace `@StateObject` with `@State` when the type uses `@Observable`
- Keep the same access level (`private`, `internal`, etc.)
- Keep the same initialization pattern

### 5. Replace @EnvironmentObject with @Environment

**BEFORE:**
```swift
// Setting environment
ContentView()
    .environmentObject(dataModel)

// Reading environment
struct ContentView: View {
    @EnvironmentObject var dataModel: DataModel
}
```

**AFTER:**
```swift
// Setting environment
ContentView()
    .environment(dataModel)

// Reading environment  
struct ContentView: View {
    @Environment(DataModel.self) private var dataModel
}
```

**AI Agent Rules:**
- Replace `.environmentObject(instance)` with `.environment(instance)`
- Replace `@EnvironmentObject var name: Type` with `@Environment(Type.self) private var name`
- Use the type itself in `@Environment(Type.self)`, not an instance
- Always make environment variables `private` unless there's a specific reason not to

### 6. Remove @ObservedObject (Most Cases)

**BEFORE:**
```swift
struct DetailView: View {
    @ObservedObject var item: Item
    
    var body: some View {
        Text(item.title)
    }
}
```

**AFTER:**
```swift
struct DetailView: View {
    var item: Item
    
    var body: some View {
        Text(item.title)
    }
}
```

**AI Agent Rules:**
- Remove `@ObservedObject` and make it a regular property
- SwiftUI automatically tracks observable properties read by the view's `body`
- Only use `@Bindable` when you need to create bindings (see next rule)

### 7. Use @Bindable When You Need Bindings

**BEFORE:**
```swift
struct EditView: View {
    @ObservedObject var item: Item
    
    var body: some View {
        TextField("Title", text: $item.title)
    }
}
```

**AFTER:**
```swift
struct EditView: View {
    @Bindable var item: Item
    
    var body: some View {
        TextField("Title", text: $item.title)
    }
}
```

**AI Agent Rules:**
- Use `@Bindable` ONLY when you need to create bindings with `$` syntax
- If the view only reads properties (no `$` usage), use a regular property instead
- `@Bindable` is for editing/binding scenarios, not just observation

## Decision Tree for AI Agents

When encountering observable objects, follow this decision tree:

1. **Is this a class that manages state?**
   - YES → Apply `@Observable` macro, remove `ObservableObject`

2. **Are there @Published properties?**
   - YES → Remove `@Published` from all properties

3. **Are there properties that shouldn't trigger updates?**
   - YES → Add `@ObservationIgnored` to those properties

4. **Is this a @StateObject in a view?**
   - YES → Change to `@State`

5. **Is this an @EnvironmentObject?**
   - YES → Change to `@Environment(Type.self) private var name`
   - Also change `.environmentObject(instance)` to `.environment(instance)`

6. **Is this an @ObservedObject in a view?**
   - Does the view use `$property` syntax? → YES: Use `@Bindable`
   - Does the view only read properties? → YES: Use regular property `var item: Item`

## Common Patterns

### Parent-Child Data Flow

**BEFORE:**
```swift
struct ParentView: View {
    @StateObject private var dataModel = DataModel()
    
    var body: some View {
        ChildView(dataModel: dataModel)
    }
}

struct ChildView: View {
    @ObservedObject var dataModel: DataModel
    
    var body: some View {
        Text(dataModel.title)
    }
}
```

**AFTER:**
```swift
struct ParentView: View {
    @State private var dataModel = DataModel()
    
    var body: some View {
        ChildView(dataModel: dataModel)
    }
}

struct ChildView: View {
    var dataModel: DataModel
    
    var body: some View {
        Text(dataModel.title)
    }
}
```

### Environment Usage

**BEFORE:**
```swift
@main
struct App: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Text(appState.currentUser.name)
    }
}
```

**AFTER:**
```swift
@main  
struct App: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Text(appState.currentUser.name)
    }
}
```

### Editing with Bindings

**BEFORE:**
```swift
struct ProfileEditView: View {
    @ObservedObject var user: User
    
    var body: some View {
        Form {
            TextField("Name", text: $user.name)
            TextField("Email", text: $user.email)
            Toggle("Notifications", isOn: $user.notificationsEnabled)
        }
    }
}
```

**AFTER:**
```swift
struct ProfileEditView: View {
    @Bindable var user: User
    
    var body: some View {
        Form {
            TextField("Name", text: $user.name)
            TextField("Email", text: $user.email)
            Toggle("Notifications", isOn: $user.notificationsEnabled)
        }
    }
}
```

## Critical AI Agent Reminders

1. **Incremental Migration**: You don't have to migrate everything at once. Mix `@Observable` and `ObservableObject` types during transition.

2. **Performance Difference**: `@Observable` types only update views when properties the view's `body` directly reads change. This is more efficient than `ObservableObject` which updates for any published property change.

3. **Binding Creation**: Only use `@Bindable` when you need `$` syntax. For read-only access, use regular properties.

4. **Environment Pattern**: Always use `@Environment(Type.self) private var name`, not `@Environment(Type.self) var name` or other variations.

5. **Compatibility**: `@StateObject` and `@EnvironmentObject` still work with `@Observable` types, but prefer the new patterns for full benefits.

6. **Import Requirements**: Ensure `import SwiftUI` is present when using `@Observable`.

## Validation Checklist

Before completing migration of any file, verify:

- [ ] All `@Observable` classes have no `@Published` properties
- [ ] All `@StateObject` changed to `@State` for `@Observable` types  
- [ ] All `@EnvironmentObject` changed to `@Environment(Type.self)` pattern
- [ ] All `.environmentObject()` changed to `.environment()`
- [ ] `@ObservedObject` only used where `@Bindable` is now appropriate
- [ ] Regular properties used for read-only `@Observable` access
- [ ] `@ObservationIgnored` applied where appropriate
- [ ] Code compiles without warnings