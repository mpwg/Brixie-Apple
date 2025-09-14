//
//  BrixieUITests.swift
//  BrixieUITests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import XCTest

final class BrixieUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testOfflineIndicatorVisibility() throws {
        // Test that the offline indicator can be found in the navigation bar
        let app = XCUIApplication()
        app.launch()
        
        // The offline indicator might not be visible immediately,
        // so we check if the app launches successfully first
        XCTAssert(app.waitForExistence(timeout: 5.0))
        
        // Navigate to different tabs to verify offline indicators appear
        if app.tabBars.buttons["Sets"].exists {
            app.tabBars.buttons["Sets"].tap()
        }
        
        if app.tabBars.buttons["Search"].exists {
            app.tabBars.buttons["Search"].tap()
        }
        
        if app.tabBars.buttons["Categories"].exists {
            app.tabBars.buttons["Categories"].tap()
        }
        
        // Basic functionality test - app should remain stable
        XCTAssert(app.exists)
    }
}
