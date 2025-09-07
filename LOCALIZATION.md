# Type-Safe Localization API

Brixie uses a type-safe localization system based on Swift enums that provides compile-time safety and better developer experience compared to string-based localization keys.

## Overview

The `Strings` enum in `Brixie/Core/Strings.swift` centralizes all localized strings and provides type-safe access to them. This approach eliminates runtime errors from typos in localization keys and provides better code completion support.

## Basic Usage

### Simple Strings

```swift
// Instead of:
let title = NSLocalizedString("Settings", comment: "Settings title")

// Use:
let title = Strings.settings.localized
```

### In SwiftUI Views

```swift
struct MyView: View {
    var body: some View {
        VStack {
            Text(Strings.favorites.localized)
            Button(Strings.done.localized) {
                // Action
            }
        }
    }
}
```

### With String Interpolation

The localization system supports Swift's string interpolation:

```swift
let message = "Welcome to \(Strings.settings)"
// Automatically uses Strings.settings.localized
```

## Formatted Strings

For strings that require parameters, use the appropriate enum cases:

```swift
// Piece count
let pieces = Strings.piecesCount(42).localized
// Result: "42 pieces"

// Set number
let setNum = Strings.setNumber("10234").localized
// Result: "Set #10234"

// Search results
let noResults = Strings.noSetsFoundFormat("castle").localized
// Result: "No sets found for 'castle'. Try a different search term."

// Error messages
let error = Strings.networkError("Connection timeout").localized
// Result: "Network error: Connection timeout"
```

## Available String Categories

### Navigation & Tabs
- `Strings.categories`
- `Strings.sets`
- `Strings.search`
- `Strings.favorites`
- `Strings.settings`

### Common Actions
- `Strings.done`
- `Strings.reset`
- `Strings.configure`
- `Strings.loadMore`
- `Strings.visitWebsite`

### Search
- `Strings.searchSets`
- `Strings.recentSearches`
- `Strings.noResults`
- `Strings.noSetsFoundFormat(query)`
- `Strings.searching`

### Set Details
- `Strings.setInformation`
- `Strings.statistics`
- `Strings.setNumber(number)`
- `Strings.piecesCount(count)`
- `Strings.addToFavorites`
- `Strings.removeFromFavorites`

### Error Handling
- `Strings.networkError(description)`
- `Strings.apiKeyMissing`
- `Strings.parsingError`
- `Strings.serverError(statusCode)`

### Empty States
- `Strings.noSetsFound`
- `Strings.noFavoritesYet`

## Adding New Strings

### 1. Add to Strings Enum

Add a new case to the appropriate section in `Strings.swift`:

```swift
enum Strings {
    // ... existing cases
    case myNewString
    case myNewFormattedString(String)
    
    var localized: String {
        switch self {
        // ... existing cases
        case .myNewString:
            return NSLocalizedString("My New String", comment: "Description of usage")
        case .myNewFormattedString(let parameter):
            return String(format: NSLocalizedString("Format: %@", comment: "Formatted string"), parameter)
        }
    }
}
```

### 2. Add to Localizable.strings

Add the corresponding entries to all localization files:

**English (Base localization):**
```
"My New String" = "My New String";
"Format: %@" = "Format: %@";
```

**German (de.lproj/Localizable.strings):**
```
"My New String" = "Meine neue Zeichenkette";
"Format: %@" = "Format: %@";
```

### 3. Write Tests

Add test cases to validate your new strings:

```swift
@Test("New string localization works")
func newStringLocalizationWorks() async throws {
    #expect(!Strings.myNewString.localized.isEmpty)
    
    let formatted = Strings.myNewFormattedString("test").localized
    #expect(formatted.contains("test"))
}
```

## Migration Guide

### From NSLocalizedString

**Before:**
```swift
let title = NSLocalizedString("Settings", comment: "Settings screen title")
```

**After:**
```swift
let title = Strings.settings.localized
```

### From String Format

**Before:**
```swift
let pieces = String(format: NSLocalizedString("%d pieces", comment: "Number of pieces"), count)
```

**After:**
```swift
let pieces = Strings.piecesCount(count).localized
```

## Best Practices

### 1. Use Descriptive Case Names
Choose enum case names that clearly describe the string's purpose:

```swift
// Good
case addToFavorites
case removeFromFavorites

// Avoid
case button1
case text2
```

### 2. Group Related Strings
Organize strings into logical sections with comments:

```swift
// MARK: - Settings
case apiConfiguration
case clearCache
case appVersion

// MARK: - Error Messages
case networkError(String)
case apiKeyMissing
```

### 3. Provide Meaningful Comments
Include descriptive comments for the NSLocalizedString calls:

```swift
case .settings:
    return NSLocalizedString("Settings", comment: "Main settings screen title")
```

### 4. Use Consistent Formatting
For formatted strings, prefer enum cases over manual string formatting:

```swift
// Preferred
case .piecesCount(42)

// Avoid
String(format: NSLocalizedString("pieces_format", comment: ""), 42)
```

## Testing

The localization system includes comprehensive tests in `BrixieTests/BrixieTests.swift`:

- Basic string localization
- Formatted string functionality
- String interpolation support
- Non-empty string validation

Run tests with:
```bash
make test-ios
```

## Backward Compatibility

The new system is fully backward compatible with existing `NSLocalizedString` usage. You can migrate strings gradually without breaking existing functionality.

## Performance

The enum-based approach has minimal performance impact:
- Compile-time safety eliminates runtime string key validation
- Lazy evaluation through computed properties
- Efficient string interpolation support
- Memory efficient compared to string constants