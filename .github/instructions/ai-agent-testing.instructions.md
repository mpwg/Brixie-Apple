---
description: "AI agent test implementation guidelines for Brixie LEGO set browser app"
applyTo: "**/*Tests.swift"
---

# AI Agent Test Implementation Instructions for Brixie App

## Overview

This document provides detailed instructions for AI agents to implement comprehensive tests for the Brixie LEGO set browser app. The tests must verify UI interactions actually load and display data correctly, with particular focus on caching mechanisms.

## Prerequisites

Before implementing tests, ensure the following setup is complete:

### Required Imports

```swift
import Testing
import SwiftData
import SwiftUI
@testable import Brixie
```

### Test Environment Setup

```swift
// Enable mock data for consistent testing
let config = TestConfiguration.shared
config.configureForUITesting()
config.applyToServices()
```

## Core Testing Patterns

### Pattern 1: Service-Level Data Loading Tests

**Objective**: Verify that clicking UI elements triggers actual data loading

**Implementation Pattern**:

```swift
@Suite("Data Loading Verification Tests")
struct DataLoadingTests {
    var legoSetService: MockableLegoSetService
    var themeService: MockableThemeService
    
    init() async throws {
        // Setup mock services with large datasets
        legoSetService = MockableLegoSetService.shared
        themeService = MockableThemeService.shared
        
        // Enable mock data with large dataset
        legoSetService.toggleMockData(true)
        themeService.toggleMockData(true)
        
        // Configure in-memory persistence
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LegoSet.self, Theme.self, UserCollection.self, 
            configurations: config
        )
        let context = ModelContext(container)
        
        legoSetService.configure(with: context)
        themeService.configure(with: context)
    }
}
```

### Pattern 2: UI Interaction with Data Verification

**Objective**: Verify UI interactions load and display actual data

**Critical Testing Requirements**:

1. **Verify Data Loading Occurs**: Confirm that UI interactions trigger service calls
2. **Verify Data Display**: Confirm that loaded data appears in UI
3. **Verify Cache Behavior**: Confirm caching works as expected
4. **Verify Large Dataset Handling**: Test with 200-1000+ items

**Implementation Pattern**:

```swift
@Test("Theme selection loads and displays sets")
func themeSelectionLoadsActualData() async throws {
    let app = XCUIApplication()
    app.launchArguments = ["--use-mock-data", "--ui-testing"]
    app.launch()
    
    // Wait for themes to load
    let themesList = app.collectionViews["ThemesList"]
    #expect(themesList.waitForExistence(timeout: 10.0))
    
    // Verify themes are actually loaded (not just placeholders)
    let firstThemeCell = themesList.cells.firstMatch
    #expect(firstThemeCell.exists)
    
    // Get theme name to verify it's real data
    let themeLabel = firstThemeCell.staticTexts.firstMatch
    let themeName = themeLabel.label
    #expect(!themeName.isEmpty)
    #expect(themeName != "Loading...")
    #expect(themeName != "Placeholder")
    
    // Tap theme to load sets
    firstThemeCell.tap()
    
    // Verify sets view appears with actual data
    let setsView = app.collectionViews["SetsListView"]
    #expect(setsView.waitForExistence(timeout: 5.0))
    
    // Verify sets are loaded (check for multiple cells)
    let setCells = setsView.cells
    #expect(setCells.count > 0)
    
    // Verify first set has actual data
    let firstSetCell = setCells.firstMatch
    #expect(firstSetCell.exists)
    
    let setNameLabel = firstSetCell.staticTexts.firstMatch
    let setName = setNameLabel.label
    #expect(!setName.isEmpty)
    #expect(setName != "Loading...")
    #expect(setName.count > 3) // Realistic set names are longer
    
    // Verify set number exists
    let setNumberLabels = firstSetCell.staticTexts.allElementsBoundByIndex
    let hasSetNumber = setNumberLabels.contains { $0.label.contains("-") }
    #expect(hasSetNumber) // LEGO set numbers contain hyphens
}
```

### Pattern 3: Cache Verification Tests

**Critical Requirement**: Test that caching actually works and affects performance

**Implementation Pattern**:

```swift
@Test("Cache improves subsequent data loading performance")
func cacheImprovesPerformance() async throws {
    let service = MockableLegoSetService.shared
    service.resetMetrics()
    
    // First load - should be slow (cache miss)
    let startTime1 = CFAbsoluteTimeGetCurrent()
    let themes1 = try await service.fetchThemes()
    let duration1 = CFAbsoluteTimeGetCurrent() - startTime1
    
    #expect(themes1.count >= 50) // Verify large dataset
    #expect(service.cacheHitRate == 0) // No cache hits yet
    
    // Second load - should be faster (cache hit)
    let startTime2 = CFAbsoluteTimeGetCurrent()
    let themes2 = try await service.fetchThemes()
    let duration2 = CFAbsoluteTimeGetCurrent() - startTime2
    
    #expect(themes2.count == themes1.count) // Same data
    #expect(duration2 < duration1) // Should be faster due to cache
    #expect(service.cacheHitRate > 0) // Should have cache hits now
    
    // Verify cache contains expected data
    #expect(service.totalRequests >= 2)
    #expect(service.cacheHits >= 1)
}
```

### Pattern 4: Large Dataset Handling Tests

**Objective**: Verify app handles 200-1000+ items correctly

**Implementation Pattern**:

```swift
@Test("Handle large dataset scrolling and loading")
func handleLargeDatasetScrolling() async throws {
    let app = XCUIApplication()
    app.launchEnvironment["BRIXIE_MOCK_DATA_SIZE"] = "large"
    app.launchArguments = ["--use-mock-data", "--ui-testing"]
    app.launch()
    
    // Navigate to theme with many sets
    let themesList = app.collectionViews["ThemesList"]
    #expect(themesList.waitForExistence(timeout: 10.0))
    
    // Find a theme with many sets (look for high set count)
    let themeCells = themesList.cells.allElementsBoundByIndex
    var selectedTheme: XCUIElement?
    
    for cell in themeCells {
        let labels = cell.staticTexts.allElementsBoundByIndex
        for label in labels {
            if label.label.contains("sets") && label.label.contains("100") {
                selectedTheme = cell
                break
            }
        }
        if selectedTheme != nil { break }
    }
    
    // Tap theme with many sets
    if let theme = selectedTheme {
        theme.tap()
    } else {
        // Fallback to first theme
        themeCells.first?.tap()
    }
    
    // Verify sets list loads
    let setsView = app.collectionViews["SetsListView"]
    #expect(setsView.waitForExistence(timeout: 10.0))
    
    // Verify many sets are loaded
    let setCells = setsView.cells
    #expect(setCells.count >= 20) // Should have many sets visible
    
    // Test scrolling through large list
    setsView.swipeUp()
    setsView.swipeUp()
    setsView.swipeUp()
    
    // Verify more sets loaded during scrolling (pagination)
    let newSetCells = setsView.cells
    #expect(newSetCells.count >= setCells.count) // Should have same or more
    
    // Verify sets still have actual data after scrolling
    let randomCell = newSetCells.element(boundBy: min(10, newSetCells.count - 1))
    let randomSetName = randomCell.staticTexts.firstMatch.label
    #expect(!randomSetName.isEmpty)
    #expect(randomSetName != "Loading...")
}
```

### Pattern 5: End-to-End Data Flow Tests

**Objective**: Verify complete data flow from UI interaction to display

**Implementation Pattern**:

```swift
@Test("Complete data flow: Theme → Sets → Details")
func completeDataFlow() async throws {
    let app = XCUIApplication()
    app.launchArguments = ["--use-mock-data", "--ui-testing"]
    app.launch()
    
    // Step 1: Load themes
    let themesList = app.collectionViews["ThemesList"]
    #expect(themesList.waitForExistence(timeout: 10.0))
    
    let firstTheme = themesList.cells.firstMatch
    let themeName = firstTheme.staticTexts.firstMatch.label
    firstTheme.tap()
    
    // Step 2: Verify sets loaded for theme
    let setsView = app.collectionViews["SetsListView"]
    #expect(setsView.waitForExistence(timeout: 5.0))
    
    let firstSet = setsView.cells.firstMatch
    #expect(firstSet.exists)
    
    let setName = firstSet.staticTexts.firstMatch.label
    firstSet.tap()
    
    // Step 3: Verify set details loaded
    let detailView = app.scrollViews["SetDetailView"]
    #expect(detailView.waitForExistence(timeout: 5.0))
    
    // Verify detail view shows actual set data
    let detailTitle = app.navigationBars.firstMatch.identifier
    #expect(detailTitle.contains(setName) || !detailTitle.isEmpty)
    
    // Verify key details are present
    let partCountLabel = detailView.staticTexts.matching(identifier: "PartCount").firstMatch
    if partCountLabel.exists {
        let partCount = partCountLabel.label
        #expect(partCount.contains("parts") || partCount.contains("pieces"))
    }
    
    // Verify image loading
    let setImage = detailView.images.firstMatch
    if setImage.exists {
        #expect(setImage.waitForExistence(timeout: 10.0))
    }
}
```

## Specific Test Implementation Requirements

### 1. Mock Data Configuration Tests

**Required Tests:**

```swift
@Test("Mock data provides sufficient test coverage")
func mockDataCoverage() async throws {
    let stats = MockDataService.shared.getStatistics()
    
    // Verify minimum data requirements
    #expect(stats.totalThemes >= 50)
    #expect(stats.totalSets >= 1000)
    #expect(stats.averageSetsPerTheme >= 10)
    #expect(stats.maxSetsPerTheme >= 50) // Some themes should have many sets
    
    // Verify data quality
    #expect(stats.imagePercentage > 80.0) // Most sets should have images
    #expect(stats.pricePercentage > 60.0) // Many sets should have prices
    #expect(stats.instructionsPercentage > 50.0) // Many should have instructions
}
```

### 2. Cache Persistence Tests

**Required Tests:**

```swift
@Test("Cache persists across app sessions")
func cachePersistsAcrossSession() async throws {
    let imageCache = ImageCacheService.shared
    let testURL = URL(string: "https://example.com/test-image.jpg")!
    let testImage = UIImage(systemName: "star.fill")!
    
    // Store image in cache
    imageCache.setImage(testImage, for: testURL)
    
    // Verify immediate retrieval
    let cachedImage1 = imageCache.image(for: testURL)
    #expect(cachedImage1 != nil)
    
    // Simulate app restart by clearing memory cache only
    imageCache.clearMemoryCache()
    
    // Should still retrieve from disk cache
    let cachedImage2 = imageCache.image(for: testURL)
    #expect(cachedImage2 != nil)
}
```

### 3. Error Handling Tests

**Required Tests:**

```swift
@Test("UI handles loading errors gracefully")
func uiHandlesLoadingErrors() async throws {
    let app = XCUIApplication()
    app.launchEnvironment["BRIXIE_NETWORK_ERRORS"] = "true"
    app.launchArguments = ["--use-mock-data", "--network-errors"]
    app.launch()
    
    // Attempt to load themes (may fail due to simulated errors)
    let themesList = app.collectionViews["ThemesList"]
    
    // Either themes load successfully or error view appears
    let themesLoaded = themesList.waitForExistence(timeout: 5.0)
    let errorView = app.staticTexts["ErrorMessage"].waitForExistence(timeout: 5.0)
    
    #expect(themesLoaded || errorView) // One of these should be true
    
    if errorView {
        // Verify retry functionality if error occurred
        let retryButton = app.buttons["RetryButton"]
        if retryButton.exists {
            retryButton.tap()
            #expect(themesList.waitForExistence(timeout: 10.0))
        }
    }
}
```

### 4. Performance Benchmark Tests

**Required Tests:**

```swift
@Test("App meets performance benchmarks with large datasets")
func performanceBenchmarks() async throws {
    let service = MockableLegoSetService.shared
    service.resetMetrics()
    
    // Configure large dataset
    let config = TestConfiguration.shared
    config.mockDataSize = .large
    
    // Benchmark theme loading
    let themeStartTime = CFAbsoluteTimeGetCurrent()
    let themes = try await service.fetchThemes()
    let themeDuration = CFAbsoluteTimeGetCurrent() - themeStartTime
    
    #expect(themes.count >= 50)
    #expect(themeDuration < 2.0) // Should load within 2 seconds
    
    // Benchmark set loading
    let setStartTime = CFAbsoluteTimeGetCurrent()
    let result = try await service.fetchSetsWithPagination(
        forThemeId: themes.first!.id, 
        limit: 100, 
        offset: 0
    )
    let setDuration = CFAbsoluteTimeGetCurrent() - setStartTime
    
    #expect(result.sets.count >= 50)
    #expect(result.totalCount >= 100)
    #expect(setDuration < 3.0) // Should load within 3 seconds
    
    // Benchmark search
    let searchStartTime = CFAbsoluteTimeGetCurrent()
    let searchResult = try await service.searchSets(query: "Star", limit: 50)
    let searchDuration = CFAbsoluteTimeGetCurrent() - searchStartTime
    
    #expect(searchResult.sets.count > 0)
    #expect(searchDuration < 1.0) // Search should be fast
}
```

## Critical Testing Guidelines

### 1. Always Verify Actual Data Loading

**DO NOT** just test that UI elements exist. **DO** verify that:

- Data loading methods are called
- Real data (not placeholders) is displayed
- Data has realistic characteristics
- Data quantities match expectations (200-1000+ items)

### 2. Always Test Cache Behavior

**MUST** include tests that verify:

- Cache improves performance on subsequent loads
- Cache hit ratios are reasonable (>50% for repeated operations)
- Cache persists across app sessions
- Cache handles memory pressure appropriately

### 3. Always Test Large Datasets

**MUST** test with datasets containing:

- Minimum 200 items for performance testing
- 1000+ items for stress testing
- Various data sizes (small, medium, large, huge)
- Realistic data distribution and characteristics

### 4. Always Verify UI Responsiveness

**MUST** ensure that:

- UI remains responsive during data loading
- Loading states are shown appropriately
- Scrolling performance is acceptable with large lists
- Images load progressively without blocking UI

### 5. Test Error Recovery

**MUST** test scenarios where:

- Network requests fail
- Cache operations fail
- Invalid data is received
- Memory pressure occurs

## Test File Structure

### Directory Organization

```
BrixieTests/
├── Models/
│   ├── LegoSetTests.swift
│   ├── ThemeTests.swift
│   └── UserCollectionTests.swift
├── Services/
│   ├── MockDataServiceTests.swift
│   ├── LegoSetServiceTests.swift
│   ├── ThemeServiceTests.swift
│   ├── ImageCacheServiceTests.swift
│   └── CollectionServiceTests.swift
├── ViewModels/
│   ├── BrowseViewModelTests.swift
│   ├── SetDetailViewModelTests.swift
│   └── SearchViewModelTests.swift
├── Integration/
│   ├── DataFlowTests.swift
│   ├── CachingIntegrationTests.swift
│   └── PerformanceIntegrationTests.swift
└── UI/
    ├── NavigationTests.swift
    ├── DataLoadingUITests.swift
    ├── SearchUITests.swift
    └── CollectionUITests.swift
```

### File Naming Convention

- Unit tests: `[ComponentName]Tests.swift`
- Integration tests: `[Feature]IntegrationTests.swift`
- UI tests: `[Screen/Feature]UITests.swift`
- Performance tests: `[Component]PerformanceTests.swift`

## Summary

When implementing tests for the Brixie app, AI agents MUST:

1. **Use Swift Testing framework** with `@Test`, `#expect`, and `#require`
2. **Test actual data loading** - verify UI interactions trigger real data operations
3. **Test caching mechanisms** - verify cache improves performance and persists data
4. **Test large datasets** - use 200-1000+ items to ensure scalability
5. **Test error handling** - verify graceful degradation when things go wrong
6. **Test performance** - ensure app remains responsive under load
7. **Use mock data services** - leverage the comprehensive mock infrastructure
8. **Follow testing patterns** - use the established patterns for consistency

8. **Follow testing patterns** - use the established patterns for consistency

These instructions ensure comprehensive test coverage that verifies the app's core functionality: that clicking on UI elements actually loads and displays real data efficiently through proper caching mechanisms.