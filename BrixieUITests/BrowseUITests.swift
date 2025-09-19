import XCTest
@testable import Brixie

/// UI Tests for Browse view functionality
final class BrowseUITests: BaseUITest {
    
    // MARK: - Browse View Tests
    
    @MainActor
    func testBrowseViewElements() throws {
        app.launch()
        navigateToTab("Browse")
        
        // Check for main browse elements
        let browseNavigationBar = app.navigationBars["Browse"]
        XCTAssertTrue(browseNavigationBar.exists)
        
        // Check for refresh button
        let refreshButton = app.buttons["Refresh sets"]
        XCTAssertTrue(refreshButton.exists)
        
        // Test refresh functionality
        refreshButton.tap()
        
        // Should show loading or updated content
        // This would depend on the actual implementation
    }
    
    @MainActor
    func testSetListInteraction() throws {
        app.launch()
        navigateToTab("Browse")
        
        // Look for set cards or list items
        let setCards = app.collectionViews.cells
        
        if setCards.count > 0 {
            let firstSet = setCards.firstMatch
            XCTAssertTrue(firstSet.exists)
            
            // Test tapping on a set card
            firstSet.tap()
            
            // Should navigate to set detail view
            let setDetailView = app.otherElements["setDetailView"]
            XCTAssertTrue(waitForElement(setDetailView, timeout: 3))
        }
    }
}