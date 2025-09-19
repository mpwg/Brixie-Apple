import XCTest
@testable import Brixie

/// UI Tests for Error Handling and Performance
final class ErrorHandlingPerformanceUITests: BaseUITest {
    // MARK: - Error Handling Tests
    
        @MainActor
    func testNetworkErrorHandling() throws {
        app.launch()
        // Simulate network error conditions
        // For now, we'll test that error states don't crash the app
        
        navigateToTab("Search")
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("NetworkErrorTest")
            searchField.typeText("\n")
            
            // App should handle network errors gracefully
            // Look for error messages or empty states
            let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'Error'"))
            let emptyState = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'No results' OR label CONTAINS 'empty'"))
            
            // Either an error message or empty state should appear
            let errorExists = errorMessage.firstMatch.waitForExistence(timeout: 5)
            let emptyExists = emptyState.firstMatch.waitForExistence(timeout: 1)
            
            XCTAssertTrue(errorExists || emptyExists, "App should show error message or empty state for network errors")
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
        @MainActor
    func testPerformanceUnderHighLoad() {
        let measuringOptions = XCTMeasureOptions()
        measuringOptions.iterationCount = 3
        
        self.measure(options: measuringOptions) {
            app.launch()
            
            // Simulate heavy UI interaction load
            for _ in 0..<10 {
                let browseTab = app.tabBars.buttons["Browse"]
                if browseTab.exists {
                    browseTab.tap()
                }
                
                let collectionTab = app.tabBars.buttons["Collection"] 
                if collectionTab.exists {
                    collectionTab.tap()
                }
            }
        }
    }
}
