# Brixie App Test Implementation Guidelines

## Overview

This document provides specific implementation guidelines for testing UI data loading, caching behavior, error handling, and performance aspects of the Brixie LEGO set browser app. These guidelines complement the AI Agent Test Instructions and ensure consistent, comprehensive test coverage.

## Testing Framework Setup

### Swift Testing Configuration

```swift
// Import required modules for all test files
import Testing
import SwiftData
import SwiftUI
@testable import Brixie

// Standard test suite structure
@Suite("Component Name Tests")
struct ComponentTests {
    // Test setup and configuration
}
```

### Mock Data Environment Setup

```swift
// Standard setup for tests requiring mock data
private func setupMockEnvironment() async throws -> (ModelContext, MockableLegoSetService) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: LegoSet.self, Theme.self, UserCollection.self,
        configurations: config
    )
    let context = ModelContext(container)
    
    let service = MockableLegoSetService.shared
    service.toggleMockData(true)
    service.configure(with: context)
    
    return (context, service)
}
```

## UI Data Loading Test Guidelines

### Core Requirements

1. **Verify Data Fetching**: Confirm service methods are called
2. **Verify Data Display**: Confirm data appears in UI elements
3. **Verify Data Quality**: Confirm data is realistic, not placeholders
4. **Verify Large Datasets**: Test with 200-1000+ items

### Implementation Pattern

```swift
@Test("UI component loads and displays actual data")
func uiComponentLoadsData() async throws {
    let (context, service) = try await setupMockEnvironment()
    
    // Step 1: Trigger data loading through UI interaction
    // (Use XCUITest or direct service calls)
    let data = try await service.fetchThemes()
    
    // Step 2: Verify data was actually loaded
    #expect(data.count >= 50) // Minimum data requirement
    #expect(data.allSatisfy { !$0.name.isEmpty }) // No empty data
    
    // Step 3: Verify data characteristics are realistic
    let starWarsTheme = data.first { $0.name.contains("Star Wars") }
    #expect(starWarsTheme != nil) // Should contain recognizable themes
    
    // Step 4: Verify performance is acceptable
    #expect(service.lastRequestDuration < 2.0) // Max 2 seconds
}
```

### UI Element Verification

```swift
// Verify UI elements contain actual data, not placeholders
private func verifyUIElementsContainRealData(_ element: XCUIElement) {
    let text = element.label
    
    // Common placeholder patterns to avoid
    let placeholders = [
        "Loading...",
        "Placeholder",
        "Sample",
        "Test",
        "Lorem ipsum",
        "",
        "N/A",
        "Unknown"
    ]
    
    for placeholder in placeholders {
        #expect(!text.localizedCaseInsensitiveContains(placeholder))
    }
    
    // Verify minimum realistic content length
    #expect(text.count >= 3)
}
```

## Caching Behavior Test Guidelines

### Core Requirements

1. **Cache Storage**: Verify data is stored in cache
2. **Cache Retrieval**: Verify cache improves performance
3. **Cache Persistence**: Verify cache survives app restarts
4. **Cache Invalidation**: Verify stale data is refreshed

### Cache Performance Testing

```swift
@Test("Cache improves data loading performance")
func cacheImprovesPerformance() async throws {
    let service = MockableLegoSetService.shared
    service.resetMetrics()
    
    // First load (cache miss)
    let startTime1 = CFAbsoluteTimeGetCurrent()
    let themes1 = try await service.fetchThemes()
    let duration1 = CFAbsoluteTimeGetCurrent() - startTime1
    
    // Verify data loaded
    #expect(themes1.count >= 50)
    #expect(service.cacheHitRate == 0.0) // No cache hits yet
    
    // Second load (cache hit)
    let startTime2 = CFAbsoluteTimeGetCurrent()
    let themes2 = try await service.fetchThemes()
    let duration2 = CFAbsoluteTimeGetCurrent() - startTime2
    
    // Verify cache improved performance
    #expect(themes2.count == themes1.count)
    #expect(duration2 < duration1 * 0.8) // At least 20% faster
    #expect(service.cacheHitRate > 0.5) // At least 50% cache hits
}
```

### Cache Persistence Testing

```swift
@Test("Cache persists across sessions")
func cachePersistsAcrossSessions() async throws {
    let imageCache = ImageCacheService.shared
    let testURL = URL(string: "https://cdn.rebrickable.com/media/sets/75192/1.jpg")!
    let testImage = UIImage(systemName: "building.2")!
    
    // Store image in cache
    imageCache.setImage(testImage, for: testURL)
    
    // Verify immediate retrieval
    let cachedImage1 = imageCache.image(for: testURL)
    #expect(cachedImage1 != nil)
    
    // Clear memory cache (simulating app restart)
    imageCache.clearMemoryCache()
    
    // Should still retrieve from disk cache
    let cachedImage2 = imageCache.image(for: testURL)
    #expect(cachedImage2 != nil)
    
    // Verify statistics
    let stats = imageCache.getCacheStatistics()
    #expect(stats.totalImages >= 1)
    #expect(stats.diskCacheSize > 0)
}
```

### Cache Invalidation Testing

```swift
@Test("Cache invalidation works correctly")
func cacheInvalidationWorksCorrectly() async throws {
    let service = MockableLegoSetService.shared
    service.resetMetrics()
    
    // Load initial data
    let themes1 = try await service.fetchThemes()
    #expect(themes1.count >= 50)
    
    // Simulate cache invalidation (e.g., data updated)
    // This would typically happen through a service method
    service.invalidateCache()
    
    // Subsequent load should refresh data
    let themes2 = try await service.fetchThemes()
    #expect(themes2.count >= 50)
    
    // Verify fresh data was fetched
    #expect(service.cacheHitRate < 1.0) // Not all from cache
}
```

## Error Handling Test Guidelines

### Core Requirements

1. **Network Errors**: Test offline and connection failures
2. **Data Errors**: Test invalid or corrupted data
3. **Cache Errors**: Test cache storage and retrieval failures
4. **UI Error States**: Test error display and recovery

### Network Error Testing

```swift
@Test("App handles network errors gracefully")
func appHandlesNetworkErrors() async throws {
    let service = MockableLegoSetService.shared
    
    // Simulate network error
    service.simulateError(.networkTimeout)
    
    // Attempt to load data
    await #expect(throws: NSError.self) {
        try await service.fetchThemes()
    }
    
    // Verify error state
    #expect(service.currentError != nil)
    #expect(service.isLoading == false)
    
    // Verify error contains useful information
    if let error = service.currentError {
        let description = error.localizedDescription
        #expect(!description.isEmpty)
        #expect(description.count > 10) // Should be descriptive
    }
}
```

### UI Error State Testing

```swift
@Test("UI displays error states appropriately")
func uiDisplaysErrorStates() async throws {
    let app = XCUIApplication()
    app.launchEnvironment["BRIXIE_NETWORK_ERRORS"] = "true"
    app.launchArguments = ["--use-mock-data", "--network-errors"]
    app.launch()
    
    // Wait for either data load or error
    let themesList = app.collectionViews["ThemesList"]
    let errorView = app.staticTexts["ErrorMessage"]
    
    let dataLoaded = themesList.waitForExistence(timeout: 5.0)
    let errorShown = errorView.waitForExistence(timeout: 5.0)
    
    if errorShown {
        // Verify error message is helpful
        let errorText = errorView.label
        #expect(!errorText.isEmpty)
        #expect(errorText.count > 10)
        
        // Verify retry functionality exists
        let retryButton = app.buttons["RetryButton"]
        #expect(retryButton.exists)
        
        // Test retry functionality
        retryButton.tap()
        #expect(themesList.waitForExistence(timeout: 10.0))
    } else {
        // If no error, verify data loaded successfully
        #expect(dataLoaded)
        #expect(themesList.cells.count > 0)
    }
}
```

### Error Recovery Testing

```swift
@Test("App recovers from errors appropriately")
func appRecoversFromErrors() async throws {
    let service = MockableLegoSetService.shared
    service.resetMetrics()
    
    // Simulate initial error
    service.simulateError(.serverError)
    
    await #expect(throws: NSError.self) {
        try await service.fetchThemes()
    }
    
    // Clear error condition
    service.currentError = nil
    
    // Subsequent call should succeed
    let themes = try await service.fetchThemes()
    #expect(themes.count >= 50)
    #expect(service.currentError == nil)
}
```

## Performance Test Guidelines

### Core Requirements

1. **Large Dataset Performance**: Test with 1000+ items
2. **Memory Usage**: Monitor memory consumption
3. **Scrolling Performance**: Test UI responsiveness
4. **Loading Time Benchmarks**: Establish performance baselines

### Large Dataset Performance Testing

```swift
@Test("App handles large datasets efficiently")
func appHandlesLargeDatasets() async throws {
    let config = TestConfiguration.shared
    config.mockDataSize = .large
    config.applyToServices()
    
    let service = MockableLegoSetService.shared
    service.resetMetrics()
    
    // Load large dataset
    let startTime = CFAbsoluteTimeGetCurrent()
    let themes = try await service.fetchThemes()
    let themeDuration = CFAbsoluteTimeGetCurrent() - startTime
    
    // Verify large dataset loaded
    #expect(themes.count >= 50)
    
    // Load sets for theme with many items
    let largeTheme = themes.max(by: { $0.totalSetCount < $1.totalSetCount })!
    let setsResult = try await service.fetchSetsWithPagination(
        forThemeId: largeTheme.id,
        limit: 100,
        offset: 0
    )
    
    // Verify performance benchmarks
    #expect(setsResult.sets.count >= 50)
    #expect(setsResult.totalCount >= 100)
    #expect(themeDuration < 3.0) // Max 3 seconds for themes
    #expect(service.lastRequestDuration < 2.0) // Max 2 seconds for sets
}
```

### Memory Usage Testing

```swift
@Test("Memory usage remains reasonable with large datasets")
func memoryUsageRemainsReasonable() async throws {
    let service = MockableLegoSetService.shared
    let imageCache = ImageCacheService.shared
    
    // Clear caches to start fresh
    imageCache.clearCache()
    service.resetMetrics()
    
    // Load substantial amount of data
    let themes = try await service.fetchThemes()
    
    for i in 0..<min(10, themes.count) {
        _ = try await service.fetchSets(forThemeId: themes[i].id, limit: 50)
    }
    
    // Check cache statistics
    let cacheStats = imageCache.getCacheStatistics()
    let memoryCacheSize = cacheStats.memoryCacheSize
    let diskCacheSize = cacheStats.diskCacheSize
    
    // Verify reasonable memory usage
    #expect(memoryCacheSize < 100_000_000) // Less than 100MB in memory
    #expect(diskCacheSize < 500_000_000) // Less than 500MB on disk
    #expect(cacheStats.totalImages > 0) // Some images should be cached
}
```

### UI Performance Testing

```swift
@Test("UI remains responsive during data operations")
func uiRemainsResponsiveDuringDataOperations() async throws {
    let app = XCUIApplication()
    app.launchEnvironment["BRIXIE_MOCK_DATA_SIZE"] = "large"
    app.launchArguments = ["--use-mock-data", "--ui-testing"]
    app.launch()
    
    // Navigate to list with many items
    let themesList = app.collectionViews["ThemesList"]
    #expect(themesList.waitForExistence(timeout: 10.0))
    
    let firstTheme = themesList.cells.firstMatch
    firstTheme.tap()
    
    let setsView = app.collectionViews["SetsListView"]
    #expect(setsView.waitForExistence(timeout: 5.0))
    
    // Test scrolling performance
    let startTime = CFAbsoluteTimeGetCurrent()
    
    for _ in 0..<10 {
        setsView.swipeUp()
        // Small delay to allow for rendering
        usleep(100_000) // 0.1 seconds
    }
    
    let scrollDuration = CFAbsoluteTimeGetCurrent() - startTime
    
    // Scrolling should be smooth and responsive
    #expect(scrollDuration < 5.0) // 10 swipes in under 5 seconds
    
    // UI should still be responsive
    let setCells = setsView.cells
    #expect(setCells.count > 0)
    
    // Should be able to tap on items
    if setCells.count > 0 {
        let randomCell = setCells.element(boundBy: setCells.count / 2)
        #expect(randomCell.exists)
        randomCell.tap()
        
        // Should navigate to detail view
        let detailView = app.scrollViews["SetDetailView"]
        #expect(detailView.waitForExistence(timeout: 3.0))
    }
}
```

## Test Data Validation Guidelines

### Core Requirements

1. **Data Completeness**: Verify all required fields are populated
2. **Data Relationships**: Verify foreign key relationships
3. **Data Realism**: Verify data appears authentic
4. **Data Consistency**: Verify data is internally consistent

### Data Completeness Testing

```swift
@Test("Mock data has complete required fields")
func mockDataHasCompleteRequiredFields() async throws {
    let service = MockableLegoSetService.shared
    let themes = try await service.fetchThemes()
    
    // Verify all themes have required fields
    for theme in themes {
        #expect(!theme.name.isEmpty)
        #expect(theme.id > 0)
        #expect(theme.totalSetCount >= 0)
    }
    
    // Test sets data completeness
    if let firstTheme = themes.first {
        let setsResult = try await service.fetchSetsWithPagination(
            forThemeId: firstTheme.id,
            limit: 20,
            offset: 0
        )
        
        for set in setsResult.sets {
            #expect(!set.setNumber.isEmpty)
            #expect(!set.name.isEmpty)
            #expect(set.year >= 1958) // LEGO company founded
            #expect(set.year <= 2030) // Reasonable future limit
            #expect(set.numParts > 0)
            #expect(set.themeId == firstTheme.id)
        }
    }
}
```

### Data Realism Testing

```swift
@Test("Mock data appears realistic")
func mockDataAppearsRealistic() async throws {
    let stats = MockDataService.shared.getStatistics()
    
    // Verify realistic data distribution
    #expect(stats.totalThemes >= 50) // Sufficient variety
    #expect(stats.totalSets >= 1000) // Large dataset
    #expect(stats.averageSetsPerTheme > 10) // Reasonable theme sizes
    
    // Verify realistic optional data percentages
    #expect(stats.imagePercentage > 80.0) // Most sets should have images
    #expect(stats.pricePercentage > 60.0) // Many sets should have prices
    #expect(stats.instructionsPercentage > 50.0) // Many should have instructions
    
    // Test specific data characteristics
    let service = MockableLegoSetService.shared
    let searchResult = try await service.searchSets(query: "Star Wars", limit: 10)
    
    #expect(searchResult.sets.count > 0) // Should find Star Wars sets
    
    // Verify Star Wars sets have realistic characteristics
    for set in searchResult.sets.prefix(3) {
        #expect(set.name.localizedCaseInsensitiveContains("star") || 
                set.name.localizedCaseInsensitiveContains("wars"))
        #expect(set.numParts >= 25) // Minimum realistic part count
        #expect(set.numParts <= 8000) // Maximum realistic part count
    }
}
```

## Test Execution Guidelines

### Test Organization

1. **Group Related Tests**: Use `@Suite` to organize related tests
2. **Clear Test Names**: Use descriptive test function names
3. **Independent Tests**: Ensure tests don't depend on each other
4. **Cleanup**: Clean up resources after tests complete

### Test Performance

1. **Fast Unit Tests**: Unit tests should complete in <100ms
2. **Reasonable Integration Tests**: Integration tests should complete in <5s
3. **UI Test Timeouts**: Use appropriate timeouts for UI elements
4. **Parallel Execution**: Design tests to run safely in parallel

### Test Maintenance

1. **Update Mock Data**: Keep mock data current and realistic
2. **Update Performance Benchmarks**: Adjust thresholds as hardware improves
3. **Monitor Test Reliability**: Address flaky tests promptly
4. **Documentation**: Keep test documentation current

## Summary

These implementation guidelines ensure comprehensive, reliable, and maintainable tests for the Brixie app. Key principles:

1. **Test Real Functionality**: Verify actual data loading and display
2. **Test Cache Behavior**: Ensure caching provides performance benefits
3. **Test Error Scenarios**: Verify graceful error handling
4. **Test Performance**: Ensure app scales with large datasets
5. **Use Realistic Data**: Test with data that resembles real-world usage
6. **Maintain Test Quality**: Keep tests fast, reliable, and well-documented

Following these guidelines will result in a robust test suite that provides confidence in the app's functionality, performance, and reliability.