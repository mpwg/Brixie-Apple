import XCTest
@testable import Brixie

/// UI Tests for main navigation flows and functionality
final class NavigationUITests: BaseUITest {
    // MARK: - Navigation Tests
    
        @MainActor
    func testTabNavigationFlow() throws {
        app.launch()
        
        // Test tab bar exists and has expected tabs
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test Browse tab is available and functional
        let browseTab = tabBar.buttons["Browse"]
        XCTAssertTrue(browseTab.exists, "Browse tab should exist")
        browseTab.tap()
        
        // Test Collection tab is available
        let collectionTab = tabBar.buttons["Collection"]
        XCTAssertTrue(collectionTab.exists, "Collection tab should exist")
        collectionTab.tap()
        
        // Test Settings tab is available
        let settingsTab = tabBar.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()
        
        // Test Search tab is available
        let searchTab = tabBar.buttons["Search"]
        XCTAssertTrue(searchTab.exists, "Search tab should exist")
        searchTab.tap()
    }
    
    @MainActor
    func testSettingsNavigation() throws {
        app.launch()
        
        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should be available")
        settingsTab.tap()
        
        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5.0), "Settings navigation bar should appear")
        
        // Test API key configuration section
        let apiKeySection = app.staticTexts["API Configuration"]
        XCTAssertTrue(apiKeySection.exists, "API Configuration section should be visible")
    }
}
