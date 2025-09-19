import XCTest
@testable import Brixie

/// UI Tests for Accessibility features
final class AccessibilityUITests: BaseUITest {
    // MARK: - Accessibility Tests
    
    @MainActor
    func testVoiceOverSupport() throws {
        // Enable VoiceOver for testing
        app.launchArguments.append("--enable-accessibility")
        app.launch()
        
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.isAccessibilityElement)
        XCTAssertFalse(browseTab.accessibilityLabel?.isEmpty ?? true)
        
        // Test set card accessibility
        let setCards = app.collectionViews.cells
        if !setCards.isEmpty {
            let firstSet = setCards.firstMatch
            XCTAssertTrue(firstSet.isAccessibilityElement)
            XCTAssertFalse(firstSet.accessibilityLabel?.isEmpty ?? true)
        }
    }
    
    @MainActor
    func testDynamicTypeSupport() throws {
        // Test with large text sizes
        app.launchArguments.append("--dynamic-type-size-xxl")
        app.launch()
        
        navigateToTab("Browse")
        
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
}
