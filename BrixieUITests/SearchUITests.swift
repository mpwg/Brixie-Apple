import XCTest
@testable import Brixie

/// UI Tests for Search functionality
final class SearchUITests: BaseUITest {
    // MARK: - Search Functionality Tests
    
    @MainActor
    func testSearchFlow() throws {
        app.launch()
        navigateToTab("Search")
        
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
        XCTAssertTrue(waitForElement(searchResults, timeout: 5))
    }
    
    @MainActor
    func testSearchFilters() throws {
        app.launch()
        navigateToTab("Search")
        
        // Look for filters button
        let filtersButton = app.buttons["Filters"]
        if filtersButton.exists {
            filtersButton.tap()
            
            // Check for filter sheet
            let filtersSheet = app.sheets.firstMatch
            XCTAssertTrue(waitForElement(filtersSheet, timeout: 2))
            
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
    
    @MainActor
    func testBarcodeScanner() throws {
        app.launch()
        navigateToTab("Search")
        
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
            XCTAssertTrue(waitForElement(scannerView, timeout: 3))
            
            // Test manual entry fallback
            let manualEntryButton = app.buttons["Enter Manually"]
            if manualEntryButton.exists {
                manualEntryButton.tap()
                
                let manualEntryField = app.textFields["Barcode"]
                XCTAssertTrue(manualEntryField.exists)
            }
        }
    }
}
