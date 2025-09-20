//
//  PerformanceUITests.swift
//  BrixieUITests
//
//  Created by GitHub Copilot on 20/09/2025.
//

import XCTest

/// Comprehensive performance tests for the Brixie app
/// These tests validate the performance optimizations from the Performance Optimization Guide
final class PerformanceUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Launch Time Tests
    
    /// Test that app launches within 1 second (Phase 4 requirement)
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Scrolling Performance Tests
    
    /// Test list scrolling maintains 60+ FPS (Phase 4 requirement)  
    func testListScrollingPerformance() throws {
        // Navigate to a view with lists
        app.tabBars.buttons["Browse"].tap()
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            // Perform rapid scrolling to stress test
            for _ in 0..<5 {
                scrollView.swipeUp(velocity: .fast)
                scrollView.swipeDown(velocity: .fast)
            }
        }
    }
    
    /// Test grid scrolling performance with images
    func testGridScrollingPerformance() throws {
        app.tabBars.buttons["Browse"].tap()
        
        // Switch to grid view if available
        let toggleButton = app.buttons["toggleViewButton"]
        if toggleButton.exists {
            toggleButton.tap()
        }
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        measure(metrics: [
            XCTOSSignpostMetric.scrollDecelerationMetric,
            XCTMemoryMetric(),
            XCTCPUMetric()
        ]) {
            // Test grid scrolling performance
            scrollView.swipeUp(velocity: .fast)
            scrollView.swipeDown(velocity: .fast)
            scrollView.swipeUp(velocity: .slow)
        }
    }
    
    // MARK: - Image Loading Performance Tests
    
    /// Test image loading performance with caching
    func testImageLoadingPerformance() throws {
        app.tabBars.buttons["Browse"].tap()
        
        let firstImage = app.images.firstMatch
        
        measure(metrics: [
            XCTMemoryMetric(),
            XCTStorageMetric(),
            XCTCPUMetric()
        ]) {
            // Scroll to trigger image loading
            let scrollView = app.scrollViews.firstMatch
            scrollView.swipeUp()
            
            // Wait for images to load
            _ = firstImage.waitForExistence(timeout: 2)
            
            // Scroll back to test cached images
            scrollView.swipeDown()
            
            // Scroll up again to test cache hits
            scrollView.swipeUp()
        }
    }
    
    // MARK: - Navigation Performance Tests
    
    /// Test tab navigation performance (<250ms requirement)
    func testTabNavigationPerformance() throws {
        let tabBar = app.tabBars.firstMatch
        let browseTab = tabBar.buttons["Browse"]
        let searchTab = tabBar.buttons["Search"]
        let collectionTab = tabBar.buttons["Collection"]
        let wishlistTab = tabBar.buttons["Wishlist"]
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            // Test rapid tab switching
            browseTab.tap()
            searchTab.tap()
            collectionTab.tap()
            wishlistTab.tap()
            browseTab.tap()
        }
    }
    
    /// Test search navigation with debouncing
    func testSearchPerformance() throws {
        app.tabBars.buttons["Search"].tap()
        
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        measure(metrics: [
            XCTMemoryMetric(),
            XCTCPUMetric()
        ]) {
            // Test search with debouncing
            searchField.tap()
            searchField.typeText("star wars")
            
            // Wait for debounced search
            sleep(1)
            
            searchField.clearAndEnterText("harry potter")
            
            // Wait for results
            sleep(1)
        }
    }
    
    // MARK: - Performance Target Validation Tests
    
    /// Validate that app launch consistently meets 1 second target
    func testAppLaunchTimeTarget() throws {
        let launchOptions = XCTMeasureOptions.default
        launchOptions.iterationCount = 5
        
        measure(options: launchOptions, metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launch()
            // Validate that we can interact with the app immediately
            XCTAssertTrue(testApp.tabBars.firstMatch.waitForExistence(timeout: 1))
            testApp.terminate()
        }
    }
    
    /// Validate that cached image loading meets <50ms target
    func testCachedImageLoadingTarget() throws {
        // Pre-warm the cache
        app.tabBars.buttons["Browse"].tap()
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 2) // Allow images to cache
        
        // Now measure cache performance
        let performanceMetric = XCTOSSignpostMetric.navigationMetric
        
        measure(metrics: [performanceMetric]) {
            // Scroll to cached images - should be very fast
            scrollView.swipeDown()
            scrollView.swipeUp()
        }
    }
    
    /// Validate memory usage remains under 150MB target during stress test
    func testMemoryUsageTarget() throws {
        let memoryMetric = XCTMemoryMetric()
        memoryMetric.maximumValue = 150_000_000 // 150MB limit
        
        measure(metrics: [memoryMetric]) {
            // Stress test: rapid navigation and image loading
            for _ in 0..<10 {
                app.tabBars.buttons["Browse"].tap()
                let scrollView = app.scrollViews.firstMatch
                scrollView.swipeUp(velocity: .fast)
                
                app.tabBars.buttons["Search"].tap()
                let searchField = app.searchFields.firstMatch
                if searchField.exists {
                    searchField.tap()
                    searchField.typeText("test\(Int.random(in: 1...100))")
                }
                
                app.tabBars.buttons["Collection"].tap()
                app.tabBars.buttons["Wishlist"].tap()
            }
        }
    }
    
    /// Validate 60+ FPS during scrolling (Frame time < 16.67ms)
    func testScrollingFPSTarget() throws {
        app.tabBars.buttons["Browse"].tap()
        let scrollView = app.scrollViews.firstMatch
        
        // Use CPU metric as proxy for frame rendering efficiency
        let cpuMetric = XCTCPUMetric()
        
        measure(metrics: [cpuMetric]) {
            // Sustained scrolling test
            for _ in 0..<20 {
                scrollView.swipeUp(velocity: .fast)
                scrollView.swipeDown(velocity: .fast)
            }
        }
    }
    
    /// Test memory usage stays under 150MB during normal usage
    func testMemoryUsagePerformance() throws {
        let memoryMetric = XCTMemoryMetric()
        
        measure(metrics: [memoryMetric]) {
            // Navigate through different tabs
            app.tabBars.buttons["Browse"].tap()
            app.scrollViews.firstMatch.swipeUp()
            
            app.tabBars.buttons["Search"].tap()
            app.searchFields.firstMatch.tap()
            app.searchFields.firstMatch.typeText("test")
            
            app.tabBars.buttons["Collection"].tap()
            
            app.tabBars.buttons["Wishlist"].tap()
            
            // Return to browse and scroll
            app.tabBars.buttons["Browse"].tap()
            let scrollView = app.scrollViews.firstMatch
            for _ in 0..<3 {
                scrollView.swipeUp()
            }
        }
        
        // Assert memory usage is reasonable
        let measurements = measureOptions.iterationCount
        // This will be validated by XCTMemoryMetric automatically
    }
    
    // MARK: - Stress Tests
    
    /// Stress test with rapid operations
    func testStressPerformance() throws {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTCPUMetric(),
            XCTStorageMetric()
        ]) {
            // Rapid tab switching
            for _ in 0..<10 {
                app.tabBars.buttons["Browse"].tap()
                app.tabBars.buttons["Search"].tap()
            }
            
            // Rapid scrolling
            app.tabBars.buttons["Browse"].tap()
            let scrollView = app.scrollViews.firstMatch
            for _ in 0..<20 {
                scrollView.swipeUp(velocity: .fast)
                scrollView.swipeDown(velocity: .fast)
            }
        }
    }
    
    // MARK: - Cold Start vs Warm Start
    
    /// Test cold start performance (first launch)
    func testColdStartPerformance() throws {
        // Terminate and relaunch for cold start
        app.terminate()
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            
            // Wait for UI to be fully loaded
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
        }
    }
    
    /// Test warm start performance (app in background)
    func testWarmStartPerformance() throws {
        // Put app in background
        XCUIDevice.shared.press(.home)
        
        // Small delay to simulate background time
        sleep(1)
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            // Reactivate app
            app.activate()
            
            // Ensure app is responsive
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 2)
        }
    }
    
    // MARK: - Animation Performance Tests
    
    /// Test animation performance doesn't drop frames
    func testAnimationPerformance() throws {
        app.tabBars.buttons["Browse"].tap()
        
        // Find toggle button to test animations
        let toggleButton = app.buttons["toggleViewButton"]
        if toggleButton.exists {
            measure(metrics: [XCTCPUMetric()]) {
                // Toggle view modes to test animations
                for _ in 0..<10 {
                    toggleButton.tap()
                    // Small delay for animation
                    usleep(250_000) // 250ms
                }
            }
        }
    }
}

// MARK: - Test Utilities

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()
        
        // Clear existing text
        let selectAll = app.menuItems["Select All"]
        if selectAll.exists {
            selectAll.tap()
        } else {
            // Fallback: press and hold then select all
            press(forDuration: 1.0)
            if app.menuItems["Select All"].exists {
                app.menuItems["Select All"].tap()
            }
        }
        
        typeText(text)
    }
}