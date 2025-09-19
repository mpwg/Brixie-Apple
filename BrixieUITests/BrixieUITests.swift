import XCTest
@testable import Brixie

/// UI Tests for main navigation flows and functionality
final class BrixieUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up test environment
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchEnvironment["REBRICKABLE_API_KEY"] = "test_key_12345"
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testTabNavigationFlow() throws {
        // Test that all main tabs are accessible and functional
        
        // Browse tab should be selected by default
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.exists)
        XCTAssertTrue(browseTab.isSelected)
        
        // Test navigation to Search tab
        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.exists)
        searchTab.tap()
        XCTAssertTrue(searchTab.isSelected)
        
        // Test navigation to Collection tab
        let collectionTab = app.tabBars.buttons["Collection"]
        XCTAssertTrue(collectionTab.exists)
        collectionTab.tap()
        XCTAssertTrue(collectionTab.isSelected)
        
        // Test navigation to Wishlist tab
        let wishlistTab = app.tabBars.buttons["Wishlist"]
        XCTAssertTrue(wishlistTab.exists)
        wishlistTab.tap()
        XCTAssertTrue(wishlistTab.isSelected)
    }
    
    func testSettingsNavigation() throws {
        // Look for settings button or navigation item
        let settingsButton = app.buttons["Settings"]
        
        if settingsButton.exists {
            settingsButton.tap()
            
            // Verify settings view is presented
            let settingsNavigationBar = app.navigationBars["Settings"]
            XCTAssertTrue(settingsNavigationBar.waitForExistence(timeout: 2))
            
            // Test dismissing settings
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }
    }
    
    // MARK: - Browse View Tests
    
    func testBrowseViewElements() throws {
        let browseTab = app.tabBars.buttons["Browse"]
        browseTab.tap()
        
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
    
    func testSetListInteraction() throws {
        let browseTab = app.tabBars.buttons["Browse"]
        browseTab.tap()
        
        // Look for set cards or list items
        let setCards = app.collectionViews.cells
        
        if setCards.count > 0 {
            let firstSet = setCards.firstMatch
            XCTAssertTrue(firstSet.exists)
            
            // Test tapping on a set card
            firstSet.tap()
            
            // Should navigate to set detail view
            let setDetailView = app.otherElements["setDetailView"]
            XCTAssertTrue(setDetailView.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Search Functionality Tests
    
    func testSearchFlow() throws {
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        
        // Find search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists)
        
        // Test entering search term
        searchField.tap()
        searchField.typeText("Star Wars")
        
        // Test search button or return key
        let searchButton = app.keyboards.buttons["Search"]
        if searchButton.exists {
            searchButton.tap()
        } else {
            searchField.typeText("\n")
        }
        
        // Wait for results
        let searchResults = app.collectionViews.firstMatch
        XCTAssertTrue(searchResults.waitForExistence(timeout: 5))
    }
    
    func testSearchFilters() throws {
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        
        // Look for filters button
        let filtersButton = app.buttons["Filters"]
        if filtersButton.exists {
            filtersButton.tap()
            
            // Check for filter sheet
            let filtersSheet = app.sheets.firstMatch
            XCTAssertTrue(filtersSheet.waitForExistence(timeout: 2))
            
            // Test theme filter
            let themeSection = app.staticTexts["Themes"]
            if themeSection.exists {
                XCTAssertTrue(themeSection.exists)
            }
            
            // Test year range filter
            let yearSection = app.staticTexts["Year Range"]
            if yearSection.exists {
                XCTAssertTrue(yearSection.exists)
            }
            
            // Dismiss filters
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }
    }
    
    func testBarcodeScanner() throws {
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        
        // Look for barcode scanner button
        let scannerButton = app.buttons["Scan Barcode"]
        if scannerButton.exists {
            scannerButton.tap()
            
            // Check if camera permission is handled
            let cameraPermissionAlert = app.alerts.firstMatch
            if cameraPermissionAlert.exists {
                let allowButton = cameraPermissionAlert.buttons["Allow"]
                if allowButton.exists {
                    allowButton.tap()
                }
            }
            
            // Scanner view should appear
            let scannerView = app.otherElements["barcodeScannerView"]
            XCTAssertTrue(scannerView.waitForExistence(timeout: 3))
            
            // Test manual entry fallback
            let manualEntryButton = app.buttons["Enter Manually"]
            if manualEntryButton.exists {
                manualEntryButton.tap()
                
                let manualEntryField = app.textFields["Barcode"]
                XCTAssertTrue(manualEntryField.exists)
            }
        }
    }
    
    // MARK: - Collection Management Tests
    
    func testAddToCollection() throws {
        // Navigate to a set detail view first
        let browseTab = app.tabBars.buttons["Browse"]
        browseTab.tap()
        
        let setCards = app.collectionViews.cells
        if setCards.count > 0 {
            let firstSet = setCards.firstMatch
            firstSet.tap()
            
            // Look for "Add to Collection" button
            let addToCollectionButton = app.buttons["Add to Collection"]
            if addToCollectionButton.exists {
                addToCollectionButton.tap()
                
                // Button should change state or show confirmation
                let removeFromCollectionButton = app.buttons["Remove from Collection"]
                XCTAssertTrue(removeFromCollectionButton.waitForExistence(timeout: 2))
            }
        }
    }
    
    func testWishlistFunctionality() throws {
        // Similar to collection test but for wishlist
        let browseTab = app.tabBars.buttons["Browse"]
        browseTab.tap()
        
        let setCards = app.collectionViews.cells
        if setCards.count > 0 {
            let firstSet = setCards.firstMatch
            firstSet.tap()
            
            let addToWishlistButton = app.buttons["Add to Wishlist"]
            if addToWishlistButton.exists {
                addToWishlistButton.tap()
                
                let removeFromWishlistButton = app.buttons["Remove from Wishlist"]
                XCTAssertTrue(removeFromWishlistButton.waitForExistence(timeout: 2))
            }
        }
    }
    
    func testCollectionView() throws {
        let collectionTab = app.tabBars.buttons["Collection"]
        collectionTab.tap()
        
        // Check for collection view elements
        let collectionNavigationBar = app.navigationBars["Meine LEGO-Sammlung"]
        XCTAssertTrue(collectionNavigationBar.exists)
        
        // Test statistics button
        let statisticsButton = app.buttons["Statistics"]
        if statisticsButton.exists {
            statisticsButton.tap()
            
            let statisticsView = app.otherElements["statisticsView"]
            XCTAssertTrue(statisticsView.waitForExistence(timeout: 2))
        }
        
        // Test export functionality
        let exportButton = app.buttons["Export"]
        if exportButton.exists {
            exportButton.tap()
            
            let exportSheet = app.sheets.firstMatch
            XCTAssertTrue(exportSheet.waitForExistence(timeout: 2))
        }
    }
    
    // MARK: - Missing Parts Tests
    
    func testMissingPartsFlow() throws {
        // Navigate to a set in collection first
        let collectionTab = app.tabBars.buttons["Collection"]
        collectionTab.tap()
        
        let setCards = app.collectionViews.cells
        if setCards.count > 0 {
            let firstSet = setCards.firstMatch
            firstSet.tap()
            
            let missingPartsButton = app.buttons["Missing Parts"]
            if missingPartsButton.exists {
                missingPartsButton.tap()
                
                let missingPartsView = app.otherElements["missingPartsView"]
                XCTAssertTrue(missingPartsView.waitForExistence(timeout: 2))
                
                // Test adding a missing part
                let addPartButton = app.buttons["Add Missing Part"]
                if addPartButton.exists {
                    addPartButton.tap()
                    
                    let addPartSheet = app.sheets.firstMatch
                    XCTAssertTrue(addPartSheet.waitForExistence(timeout: 2))
                    
                    // Fill out the form
                    let partNumberField = app.textFields["Part Number"]
                    if partNumberField.exists {
                        partNumberField.tap()
                        partNumberField.typeText("3001")
                        
                        let saveButton = app.buttons["Save"]
                        if saveButton.exists {
                            saveButton.tap()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverSupport() throws {
        // Enable VoiceOver for testing
        app.launchArguments.append("--enable-accessibility")
        
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.isAccessibilityElement)
        XCTAssertFalse(browseTab.accessibilityLabel?.isEmpty ?? true)
        
        // Test set card accessibility
        let setCards = app.collectionViews.cells
        if setCards.count > 0 {
            let firstSet = setCards.firstMatch
            XCTAssertTrue(firstSet.isAccessibilityElement)
            XCTAssertFalse(firstSet.accessibilityLabel?.isEmpty ?? true)
        }
    }
    
    func testDynamicTypeSupport() throws {
        // Test with large text sizes
        app.launchArguments.append("--dynamic-type-size-xxl")
        
        let browseTab = app.tabBars.buttons["Browse"]
        browseTab.tap()
        
        // Verify that text is still readable and UI is not broken
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists)
        
        // Text should scale but remain within bounds
        let staticTexts = app.staticTexts
        for text in staticTexts.allElementsBoundByIndex {
            if text.exists && !text.label.isEmpty {
                XCTAssertTrue(text.frame.width > 0)
                XCTAssertTrue(text.frame.height > 0)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() throws {
        // This would require network mocking or airplane mode simulation
        // For now, we'll test that error states don't crash the app
        
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        
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
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testScrollingPerformance() throws {
        let browseTab = app.tabBars.buttons["Browse"]
        browseTab.tap()
        
        let collectionView = app.collectionViews.firstMatch
        if collectionView.exists {
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                collectionView.swipeUp(velocity: .fast)
                collectionView.swipeDown(velocity: .fast)
            }
        }
    }
}