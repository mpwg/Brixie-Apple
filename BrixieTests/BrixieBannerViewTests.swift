//
//  BrixieBannerViewTests.swift
//  BrixieTests
//
//  Created by Claude on 06.09.25.
//

import Testing
@testable import Brixie

struct BrixieBannerViewTests {
    
    @Test("Banner view should call action when retry button is tapped")
    func bannerViewCallsActionOnRetry() async throws {
        var actionCalled = false
        
        let banner = BrixieBannerView(
            title: "Test Error",
            message: "Test message",
            onAction: {
                actionCalled = true
            }
        )
        
        // The banner is created successfully
        #expect(banner.title == "Test Error")
        #expect(banner.message == "Test message")
        #expect(banner.actionTitle == "Retry")
        
        // Simulate action call
        banner.onAction()
        #expect(actionCalled == true)
    }
    
    @Test("Banner view should call dismiss when dismiss button is tapped")
    func bannerViewCallsDismissOnDismiss() async throws {
        var dismissCalled = false
        
        let banner = BrixieBannerView(
            title: "Test Error",
            message: "Test message",
            onAction: {},
            onDismiss: {
                dismissCalled = true
            }
        )
        
        // Simulate dismiss call
        banner.onDismiss?()
        #expect(dismissCalled == true)
    }
    
    @Test("Network error banner should have correct default messaging")
    func networkErrorBannerHasCorrectDefaults() async throws {
        var retryWasCalled = false
        
        let banner = BrixieBannerView.networkError(onRetry: {
            retryWasCalled = true
        })
        
        #expect(banner.title == "Connection Issue")
        #expect(banner.message == "Check your internet connection and try again")
        #expect(banner.actionTitle == "Retry")
        
        // Test retry action
        banner.onAction()
        #expect(retryWasCalled == true)
    }
    
    @Test("API key error banner should have correct default messaging")
    func apiKeyErrorBannerHasCorrectDefaults() async throws {
        var actionWasCalled = false
        
        let banner = BrixieBannerView.apiKeyError(onRetry: {
            actionWasCalled = true
        })
        
        #expect(banner.title == "API Key Required")
        #expect(banner.message == "Please enter a valid API key in settings")
        #expect(banner.actionTitle == "Settings")
        
        // Test action
        banner.onAction()
        #expect(actionWasCalled == true)
    }
    
    @Test("General error banner should use error description and recovery suggestion")
    func generalErrorBannerUsesErrorDescriptionAndRecovery() async throws {
        let testError = BrixieError.networkError(underlying: NSError(domain: "test", code: 1))
        var retryWasCalled = false
        
        let banner = BrixieBannerView.generalError(testError, onRetry: {
            retryWasCalled = true
        })
        
        #expect(banner.title == "Something Went Wrong")
        #expect(banner.message == testError.recoverySuggestion)
        #expect(banner.actionTitle == "Retry")
        
        // Test retry action
        banner.onAction()
        #expect(retryWasCalled == true)
    }
    
    @Test("Banner without dismiss should not have dismiss callback")
    func bannerWithoutDismissShouldNotHaveDismissCallback() async throws {
        let banner = BrixieBannerView(
            title: "Test",
            message: "Test message",
            onAction: {}
        )
        
        #expect(banner.onDismiss == nil)
    }
    
    @Test("Banner with custom action title should use provided title")
    func bannerWithCustomActionTitleShouldUseProvidedTitle() async throws {
        let banner = BrixieBannerView(
            title: "Test",
            message: "Test message",
            actionTitle: "Custom Action",
            onAction: {}
        )
        
        #expect(banner.actionTitle == "Custom Action")
    }
}