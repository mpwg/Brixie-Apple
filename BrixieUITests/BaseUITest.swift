import XCTest
@testable import Brixie

/// Base class for UI tests with common setup and utilities
@preconcurrency
class BaseUITest: XCTestCase {
    
    nonisolated(unsafe) var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up test environment
        app.launchEnvironment["UI_TESTING"] = "true" 
        app.launchEnvironment["REBRICKABLE_API_KEY"] = "test_key_12345"
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helper Methods
    
    /// Navigate to a specific tab
    @MainActor
    func navigateToTab(_ tabName: String) {
        let tab = app.tabBars.buttons[tabName]
        if tab.exists {
            tab.tap()
        }
    }
    
    /// Wait for element to appear and be tappable
    @MainActor
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// Check if tab is currently selected
    @MainActor
    func isTabSelected(_ tabName: String) -> Bool {
        let tab = app.tabBars.buttons[tabName]
        return tab.exists && tab.isSelected
    }
}