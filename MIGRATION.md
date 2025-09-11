# SwiftData Migration Strategy

This document outlines the data migration strategy for Brixie's SwiftData schema evolution, providing guidelines for safely evolving the data models while preserving user data.

## Table of Contents

- [Current Schema](#current-schema)
- [Migration Strategy Overview](#migration-strategy-overview)
- [Versioning Guidelines](#versioning-guidelines)
- [Migration Implementation](#migration-implementation)
- [Common Migration Scenarios](#common-migration-scenarios)
- [Testing Migrations](#testing-migrations)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Current Schema

### Schema Version 1.0 (Current)

The initial schema includes two core models:

**LegoSet Model** (`Item.swift`)
```swift
@Model
final class LegoSet {
    var setNum: String           // Primary identifier
    var name: String            // Set name
    var year: Int               // Release year
    var themeId: Int            // Theme identifier
    var themeName: String?      // Optional theme name
    var numParts: Int           // Number of parts
    var imageURL: String?       // Optional image URL
    var isFavorite: Bool        // User favorite flag
    var lastViewed: Date?       // Last viewed timestamp
    var cachedImageData: Data?  // Cached image data
}
```

**LegoTheme Model**
```swift
@Model
final class LegoTheme {
    var id: Int                 // Primary identifier
    var name: String           // Theme name
    var parentId: Int?         // Optional parent theme
    var setCount: Int          // Number of sets in theme
}
```

**Schema Definition** (in `BrixieApp.swift` and `DIContainer.swift`)
```swift
let schema = Schema([
    LegoSet.self,
    LegoTheme.self,
])
```

## Migration Strategy Overview

### Core Principles

1. **Data Preservation**: Never lose existing user data during migrations
2. **Backward Compatibility**: Ensure app can gracefully handle older data formats
3. **Performance**: Minimize migration time and impact on app startup
4. **Testability**: All migrations must be thoroughly tested
5. **Rollback Safety**: Provide mechanisms to handle migration failures

### Migration Types

1. **Automatic Migrations**: SwiftData handles simple changes automatically
2. **Custom Migrations**: Manual migration code for complex schema changes
3. **Data-Only Migrations**: Updates to existing data without schema changes

## Versioning Guidelines

### Schema Version Numbering

Use semantic versioning for schema changes:

- **Major Version** (X.0.0): Breaking changes requiring custom migration
- **Minor Version** (X.Y.0): Additive changes that may use automatic migration
- **Patch Version** (X.Y.Z): Data-only changes or fixes

### Examples

- `1.0.0` → `1.1.0`: Add new optional property (automatic migration)
- `1.0.0` → `1.2.0`: Add new model (automatic migration)
- `1.0.0` → `2.0.0`: Remove property or change data types (custom migration)

### Version Documentation

Document each schema version change:

```swift
// Schema Version History
// 1.0.0 - Initial release with LegoSet and LegoTheme models
// 1.1.0 - Added LegoSet.userNotes (String?) property
// 2.0.0 - Changed LegoSet.year from Int to Date for better date handling
```

## Migration Implementation

### Setting Up Versioned Schema

```swift
// In BrixieApp.swift
import SwiftData

@main
struct BrixieApp: App {
    private let container: ModelContainer
    
    init() {
        do {
            // Define schema versions
            let schemaV1 = Schema([
                LegoSet.self,
                LegoTheme.self
            ], version: .init(1, 0, 0))
            
            let schemaV2 = Schema([
                LegoSetV2.self,  // Updated model
                LegoTheme.self
            ], version: .init(2, 0, 0))
            
            // Set up migration plan
            let migrationPlan = SchemaMigrationPlan([
                .init(fromVersion: .init(1, 0, 0), toVersion: .init(2, 0, 0), 
                      willMigrate: nil, didMigrate: migrateV1ToV2)
            ])
            
            container = try ModelContainer(
                for: schemaV2,
                migrationPlan: migrationPlan
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### Custom Migration Example

```swift
func migrateV1ToV2(context: ModelContext) throws {
    // Example: Convert Int year to Date releaseDate
    let oldSets = try context.fetch(FetchDescriptor<LegoSetV1>())
    
    for oldSet in oldSets {
        let newSet = LegoSetV2(
            setNum: oldSet.setNum,
            name: oldSet.name,
            releaseDate: Calendar.current.date(from: DateComponents(year: oldSet.year)) ?? Date(),
            themeId: oldSet.themeId,
            themeName: oldSet.themeName,
            numParts: oldSet.numParts,
            imageURL: oldSet.imageURL,
            isFavorite: oldSet.isFavorite,
            lastViewed: oldSet.lastViewed,
            cachedImageData: oldSet.cachedImageData
        )
        
        context.insert(newSet)
        context.delete(oldSet)
    }
    
    try context.save()
}
```

## Common Migration Scenarios

### 1. Adding Optional Properties

**Scenario**: Add `userNotes: String?` to LegoSet

**Migration Type**: Automatic (SwiftData handles this)

```swift
@Model
final class LegoSet {
    // Existing properties...
    var userNotes: String?  // New optional property
    
    init(setNum: String, name: String, year: Int, themeId: Int, numParts: Int, 
         imageURL: String? = nil, userNotes: String? = nil) {
        // Initialize all properties...
        self.userNotes = userNotes
    }
}
```

### 2. Adding Required Properties with Default Values

**Scenario**: Add `createdAt: Date` to LegoSet

**Migration Type**: Custom migration to set default values

```swift
// Migration function
func addCreatedAtToLegoSet(context: ModelContext) throws {
    let sets = try context.fetch(FetchDescriptor<LegoSet>())
    let defaultDate = Date()
    
    for set in sets {
        if set.createdAt == nil {
            set.createdAt = defaultDate
        }
    }
    
    try context.save()
}
```

### 3. Renaming Properties

**Scenario**: Rename `numParts` to `pieceCount` in LegoSet

**Migration Type**: Custom migration

```swift
// Create new model version
@Model
final class LegoSetV2 {
    var setNum: String
    var name: String
    var year: Int
    var themeId: Int
    var themeName: String?
    var pieceCount: Int  // Renamed from numParts
    // ... other properties
}

// Migration function
func renamePieceCountProperty(context: ModelContext) throws {
    let oldSets = try context.fetch(FetchDescriptor<LegoSetV1>())
    
    for oldSet in oldSets {
        let newSet = LegoSetV2(
            setNum: oldSet.setNum,
            name: oldSet.name,
            year: oldSet.year,
            themeId: oldSet.themeId,
            themeName: oldSet.themeName,
            pieceCount: oldSet.numParts  // Copy old value to new property
            // ... copy other properties
        )
        
        context.insert(newSet)
        context.delete(oldSet)
    }
    
    try context.save()
}
```

### 4. Adding New Models

**Scenario**: Add `LegoMinifigure` model

**Migration Type**: Automatic (for new models)

```swift
@Model
final class LegoMinifigure {
    var id: String
    var name: String
    var setNum: String  // Reference to LegoSet
    var imageURL: String?
    
    init(id: String, name: String, setNum: String, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.setNum = setNum
        self.imageURL = imageURL
    }
}

// Update schema to include new model
let schema = Schema([
    LegoSet.self,
    LegoTheme.self,
    LegoMinifigure.self  // New model
])
```

### 5. Changing Data Types

**Scenario**: Change `year: Int` to `releaseDate: Date` in LegoSet

**Migration Type**: Custom migration

```swift
@Model
final class LegoSetV2 {
    var setNum: String
    var name: String
    var releaseDate: Date  // Changed from Int year
    // ... other properties
}

func convertYearToDate(context: ModelContext) throws {
    let oldSets = try context.fetch(FetchDescriptor<LegoSetV1>())
    
    for oldSet in oldSets {
        // Convert year to Date
        let releaseDate = Calendar.current.date(from: DateComponents(year: oldSet.year)) ?? Date()
        
        let newSet = LegoSetV2(
            setNum: oldSet.setNum,
            name: oldSet.name,
            releaseDate: releaseDate,
            // ... copy other properties
        )
        
        context.insert(newSet)
        context.delete(oldSet)
    }
    
    try context.save()
}
```

## Testing Migrations

### Unit Testing Strategy

```swift
import Testing
import SwiftData

@Test func testMigrationV1ToV2() async throws {
    // Create in-memory container with old schema
    let oldSchema = Schema([LegoSetV1.self], version: .init(1, 0, 0))
    let oldContainer = try ModelContainer(for: oldSchema, configurations: [
        ModelConfiguration(isStoredInMemoryOnly: true)
    ])
    
    // Insert test data with old model
    let oldContext = ModelContext(oldContainer)
    let testSet = LegoSetV1(setNum: "123", name: "Test Set", year: 2020, 
                            themeId: 1, numParts: 100)
    oldContext.insert(testSet)
    try oldContext.save()
    
    // Create new container with migration
    let newSchema = Schema([LegoSetV2.self], version: .init(2, 0, 0))
    let migrationPlan = SchemaMigrationPlan([
        .init(fromVersion: .init(1, 0, 0), toVersion: .init(2, 0, 0),
              willMigrate: nil, didMigrate: migrateV1ToV2)
    ])
    
    let newContainer = try ModelContainer(for: newSchema, 
                                         migrationPlan: migrationPlan,
                                         configurations: [
                                            ModelConfiguration(isStoredInMemoryOnly: true)
                                         ])
    
    // Verify migration
    let newContext = ModelContext(newContainer)
    let migratedSets = try newContext.fetch(FetchDescriptor<LegoSetV2>())
    
    #expect(migratedSets.count == 1)
    #expect(migratedSets.first?.setNum == "123")
    #expect(migratedSets.first?.name == "Test Set")
    
    // Verify date conversion
    let expectedDate = Calendar.current.date(from: DateComponents(year: 2020))
    #expect(migratedSets.first?.releaseDate == expectedDate)
}
```

### Integration Testing

```swift
@Test func testMigrationPerformance() async throws {
    // Test migration with large dataset
    let startTime = Date()
    
    // Run migration with 10,000 records
    // ... migration code
    
    let migrationTime = Date().timeIntervalSince(startTime)
    #expect(migrationTime < 10.0) // Should complete within 10 seconds
}
```

### Manual Testing Checklist

- [ ] Create test database with old schema version
- [ ] Populate with representative data (favorites, cached images, etc.)
- [ ] Deploy app with new schema
- [ ] Verify all data migrated correctly
- [ ] Test app functionality with migrated data
- [ ] Verify performance is acceptable
- [ ] Test edge cases (empty database, corrupted data)

## Best Practices

### 1. Always Use Optional Properties for New Fields

When adding new properties, make them optional to enable automatic migration:

```swift
// Good: Optional property enables automatic migration
var userRating: Double?

// Avoid: Required property needs custom migration
var userRating: Double // This requires custom migration
```

### 2. Provide Default Values in Initializers

```swift
init(setNum: String, name: String, year: Int, themeId: Int, numParts: Int, 
     imageURL: String? = nil, userRating: Double? = nil) {
    // Initialize properties with sensible defaults
    self.userRating = userRating ?? 0.0
}
```

### 3. Version Control Your Models

Keep old model versions for reference:

```swift
// Keep old versions commented or in separate files
/*
// LegoSet v1.0.0
@Model
final class LegoSetV1 {
    var setNum: String
    var name: String
    var year: Int  // Changed to Date in v2.0.0
    // ...
}
*/
```

### 4. Use Gradual Rollout

- Test migrations thoroughly in development
- Use TestFlight for beta testing with real user data
- Monitor crash reports and performance metrics
- Have rollback plan ready

### 5. Document Breaking Changes

```swift
// BREAKING CHANGE in v2.0.0
// - LegoSet.year (Int) changed to LegoSet.releaseDate (Date)
// - Custom migration required for existing data
// - See MIGRATION.md for details
```

## Troubleshooting

### Common Issues

**1. Migration Fails with "Model Not Found" Error**

*Cause*: Model class name changed between versions
*Solution*: Use `@Attribute(.originalName)` to map old property names

```swift
@Model
final class LegoSet {
    @Attribute(.originalName("numParts"))
    var pieceCount: Int
}
```

**2. App Crashes on Launch After Migration**

*Cause*: Migration threw an exception
*Solution*: Implement proper error handling and logging

```swift
func safeMigration(context: ModelContext) throws {
    do {
        // Migration code
    } catch {
        print("Migration failed: \(error)")
        // Log error and potentially reset database
        throw error
    }
}
```

**3. Slow Migration Performance**

*Cause*: Processing too much data at once
*Solution*: Batch processing

```swift
func batchMigration(context: ModelContext) throws {
    let batchSize = 1000
    var offset = 0
    
    while true {
        var fetchDescriptor = FetchDescriptor<LegoSet>()
        fetchDescriptor.fetchLimit = batchSize
        fetchDescriptor.fetchOffset = offset
        
        let batch = try context.fetch(fetchDescriptor)
        if batch.isEmpty { break }
        
        // Process batch
        for item in batch {
            // Migrate item
        }
        
        try context.save()
        offset += batchSize
    }
}
```

### Recovery Strategies

**1. Database Reset**

For critical migration failures, provide option to reset database:

```swift
func resetDatabase() throws {
    // Clear all data and start fresh
    // Only use as last resort with user consent
    try modelContainer.mainContext.delete(model: LegoSet.self)
    try modelContainer.mainContext.delete(model: LegoTheme.self)
    try modelContainer.mainContext.save()
}
```

**2. Data Export/Import**

Before major migrations, consider exporting user data:

```swift
func exportUserData() throws -> Data {
    // Export favorites, user notes, etc.
    let favorites = try modelContainer.mainContext.fetch(
        FetchDescriptor<LegoSet>(predicate: #Predicate { $0.isFavorite })
    )
    return try JSONEncoder().encode(favorites)
}
```

## Conclusion

This migration strategy ensures that Brixie can evolve its data schema while preserving user data and maintaining a smooth user experience. Always test migrations thoroughly and have contingency plans for edge cases.

For questions or issues with migrations, refer to the SwiftData documentation or create an issue in the project repository.