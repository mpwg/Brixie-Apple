# Brixie Localization Workflow

## Overview

Brixie supports internationalization (i18n) with English as the base language and German as an additional supported language. All user-facing strings are externalized to `.strings` files for easy translation and maintenance.

## Supported Languages

- **English (en)**: Base language - `Brixie/en.lproj/Localizable.strings`
- **German (de)**: Secondary language - `Brixie/de.lproj/Localizable.strings`

## String Localization Guidelines

### 1. Adding New User-Facing Strings

When adding new user-facing text to the app, always use `NSLocalizedString`:

```swift
// ❌ Don't use hardcoded strings
Text("Settings")

// ✅ Use NSLocalizedString with descriptive comment
Text(NSLocalizedString("Settings", comment: "Settings navigation title"))
```

### 2. NSLocalizedString Best Practices

- **Key**: Use the English text as the key for simplicity
- **Comment**: Always provide a descriptive comment explaining the context
- **Context matters**: Same text in different contexts should have different comments

```swift
// Example for button vs. navigation title
Text(NSLocalizedString("Search", comment: "Search button"))
Text(NSLocalizedString("Search", comment: "Navigation title for search"))
```

### 3. String Formatting

For strings with variables, use proper formatting:

```swift
// For numbers
String(format: NSLocalizedString("%d results", comment: "Number of search results"), count)

// For strings  
String(format: NSLocalizedString("No sets found for '%@'", comment: "No results message"), searchQuery)

// For set numbers
String(format: NSLocalizedString("Set #%@", comment: "Set number display"), setNumber)
```

## Localization File Structure

### English (`en.lproj/Localizable.strings`)

```
/* Section Headers for Organization */

/* Tab Labels */
"Sets" = "Sets";
"Search" = "Search";

/* Navigation and Headers */
"Search Sets" = "Search Sets";

/* Error Messages */
"Network error: %@" = "Network error: %@";
```

### German (`de.lproj/Localizable.strings`)

```
/* Tab Labels */
"Sets" = "Sets";
"Search" = "Suche";

/* Navigation and Headers */  
"Search Sets" = "Sets durchsuchen";

/* Error Messages */
"Network error: %@" = "Netzwerkfehler: %@";
```

## Adding a New Language

1. **Create language folder**: `Brixie/[language-code].lproj/`
2. **Copy base strings**: Copy `en.lproj/Localizable.strings` to the new folder
3. **Translate strings**: Translate all string values (keep keys in English)
4. **Update Xcode project**: Add the new language in Project Settings > Localizations

## String Categories

The localization files are organized into the following categories:

- **Tab Labels**: Main navigation tab titles
- **Navigation and Headers**: Screen titles and section headers
- **Search**: Search-related text and prompts
- **Set Details**: LEGO set information display
- **Empty States**: Messages shown when no data is available
- **Settings**: Configuration and preference screens
- **Alerts**: Dialog and alert messages
- **UI Components**: Generic UI element text
- **Themes**: Appearance and theme options
- **Error Messages**: Network and system error descriptions
- **Recovery Suggestions**: User guidance for error resolution
- **API Configuration**: API key setup and configuration

## Development Workflow

### 1. Adding New Strings

1. **Write the code** with `NSLocalizedString`
2. **Add to English strings file** with descriptive comment
3. **Add to German strings file** with proper translation
4. **Test both languages** in simulator/device

### 2. Updating Existing Strings

1. **Update the English key** and comment if needed
2. **Update translations** in all language files
3. **Search codebase** for any hardcoded usage of the old string

### 3. String Extraction (Automated)

To find missing localizations, use the `genstrings` tool:

```bash
# From project root
find Brixie -name "*.swift" -print0 | xargs -0 genstrings -o /tmp/
# Compare with existing Localizable.strings files
```

## Testing Localization

### 1. Language Testing

Test the app in different languages:
- iOS Settings > General > Language & Region > iPhone Language
- Or use Xcode scheme arguments: `-AppleLanguages (de)`

### 2. String Length Testing

- Test with longer German translations to ensure UI layouts work
- Use "Show Language Regions" in Accessibility settings to highlight text areas

### 3. Pseudolocalization

For development, consider using pseudolocalization to identify non-localized strings:
- Use Xcode scheme argument: `-NSDoubleLocalizedStrings YES`

## Common Patterns

### Error Handling
```swift
enum BrixieError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return NSLocalizedString("Network error: \(error.localizedDescription)", comment: "Network error description")
        }
    }
}
```

### Dynamic Text
```swift
// For pluralization-sensitive text
let pieceText = String(format: NSLocalizedString("%d pieces", comment: "Number of pieces"), count)

// For conditional text
let favoriteText = isFavorite 
    ? NSLocalizedString("Remove from Favorites", comment: "Remove favorite button")
    : NSLocalizedString("Add to Favorites", comment: "Add favorite button")
```

## Quality Assurance

### Before Release
- [ ] All user-facing strings use `NSLocalizedString`
- [ ] All supported languages have complete translations
- [ ] No hardcoded strings in UI components
- [ ] Proper string formatting for variables
- [ ] Descriptive comments for all localized strings
- [ ] UI layouts work with longer translations
- [ ] Error messages and alerts are localized

### Code Review Checklist
- [ ] New strings added to all language files
- [ ] Proper comment format used
- [ ] String keys are consistent and descriptive
- [ ] No duplicate keys with different meanings
- [ ] Formatting strings use proper placeholders

## Tools and Resources

- **Xcode**: Built-in localization support
- **genstrings**: Extract strings from source code
- **String Catalogs**: Modern Xcode localization (iOS 17+)
- **Translation services**: Consider professional translation for production

## Maintenance

- **Regular audits**: Review for new hardcoded strings
- **Translation updates**: Keep translations current with UI changes
- **Performance**: Monitor localization impact on app size and startup
- **Accessibility**: Ensure localized strings work with VoiceOver

---

## Quick Reference

### Most Common Patterns

```swift
// Simple text
Text(NSLocalizedString("Settings", comment: "Settings screen title"))

// Button with action
Button(NSLocalizedString("Clear Cache", comment: "Clear cache button")) {
    clearCache()
}

// Alert with message
.alert(NSLocalizedString("Clear Cache", comment: "Clear cache alert title"), isPresented: $showingAlert) {
    Button(NSLocalizedString("Clear", comment: "Confirm clear action"), role: .destructive) {
        // Action
    }
    Button(NSLocalizedString("Cancel", comment: "Cancel action"), role: .cancel) { }
} message: {
    Text(NSLocalizedString("This will clear all cached data.", comment: "Clear cache warning"))
}

// Formatted string
let message = String(format: NSLocalizedString("Found %d sets", comment: "Search results count"), resultCount)
```

This workflow ensures consistent, maintainable localization across the Brixie app.