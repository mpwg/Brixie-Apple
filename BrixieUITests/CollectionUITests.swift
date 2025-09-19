import XCTest
@testable import Brixie

/// UI Tests for Collection Management functionality
final class CollectionUITests: BaseUITest {
    // MARK: - Collection Management Tests
    
        @MainActor
    func testAddToCollection() throws {
        app.launch()
        // Navigate to Browse to find a set to add
        navigateToTab("Browse")
        
        let setCards = app.collectionViews.cells
        if !setCards.isEmpty {
            let firstSet = setCards.firstMatch
            firstSet.tap()
            
            // Look for "Add to Collection" button
            let addToCollectionButton = app.buttons["Add to Collection"]
            if addToCollectionButton.exists {
                addToCollectionButton.tap()
                
                // Button should change state or show confirmation
                let removeFromCollectionButton = app.buttons["Remove from Collection"]
                XCTAssertTrue(waitForElement(removeFromCollectionButton, timeout: 2))
            }
        }
    }
    
    @MainActor
    func testWishlistFunctionality() throws {
        app.launch()
        // Similar to collection test but for wishlist
        navigateToTab("Browse")
        
        let setCards = app.collectionViews.cells
        if !setCards.isEmpty {
            let firstSet = setCards.firstMatch
            firstSet.tap()
            
            let addToWishlistButton = app.buttons["Add to Wishlist"]
            if addToWishlistButton.exists {
                addToWishlistButton.tap()
                
                let removeFromWishlistButton = app.buttons["Remove from Wishlist"]
                XCTAssertTrue(waitForElement(removeFromWishlistButton, timeout: 2))
            }
        }
    }
    
    @MainActor
    func testCollectionView() throws {
        app.launch()
        navigateToTab("Collection")
        
        // Check for collection view elements
        let collectionNavigationBar = app.navigationBars["Meine LEGO-Sammlung"]
        XCTAssertTrue(collectionNavigationBar.exists)
        
        // Test statistics button
        let statisticsButton = app.buttons["Statistics"]
        if statisticsButton.exists {
            statisticsButton.tap()
            
            let statisticsView = app.otherElements["statisticsView"]
            XCTAssertTrue(waitForElement(statisticsView, timeout: 2))
        }
        
        // Test export functionality
        let exportButton = app.buttons["Export"]
        if exportButton.exists {
            exportButton.tap()
            
            let exportSheet = app.sheets.firstMatch
            XCTAssertTrue(waitForElement(exportSheet, timeout: 2))
        }
    }
}
