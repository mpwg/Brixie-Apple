import XCTest
@testable import Brixie

/// UI Tests for Missing Parts functionality
final class MissingPartsUITests: BaseUITest {
    
    // MARK: - Missing Parts Tests
    
        @MainActor
    func testMissingPartsFlow() throws {
        app.launch()
        // Navigate to Collection first to access a set with missing parts
        navigateToTab("Collection")
        
        let setCards = app.collectionViews.cells
        if setCards.count > 0 {
            let firstSet = setCards.firstMatch
            firstSet.tap()
            
            let missingPartsButton = app.buttons["Missing Parts"]
            if missingPartsButton.exists {
                missingPartsButton.tap()
                
                let missingPartsView = app.otherElements["missingPartsView"]
                XCTAssertTrue(waitForElement(missingPartsView, timeout: 2))
                
                // Test adding a missing part
                let addPartButton = app.buttons["Add Missing Part"]
                if addPartButton.exists {
                    addPartButton.tap()
                    
                    let addPartSheet = app.sheets.firstMatch
                    XCTAssertTrue(waitForElement(addPartSheet, timeout: 2))
                    
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
}