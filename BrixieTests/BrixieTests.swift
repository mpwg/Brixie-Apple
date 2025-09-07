//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
@testable import Brixie

struct BrixieTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func errorReporter_mapsURLErrorToNetworkError() async throws {
        let errorReporter = ErrorReporter.shared
        let urlError = URLError(.notConnectedToInternet)
        
        errorReporter.report(urlError)
        
        #expect(errorReporter.currentError != nil)
        
        if case .networkError = errorReporter.currentError {
            // Success - error was mapped correctly
        } else {
            #expect(Bool(false), "Expected networkError but got different error type")
        }
    }
    
    @Test func errorReporter_preservesBrixieError() async throws {
        let errorReporter = ErrorReporter.shared
        let brixieError = BrixieError.apiKeyMissing
        
        errorReporter.report(brixieError)
        
        #expect(errorReporter.currentError == .apiKeyMissing)
    }
    
    @Test func errorReporter_handlesRecoveryActions() async throws {
        let errorReporter = ErrorReporter.shared
        
        let networkErrorAction = errorReporter.handle(.networkError(underlying: URLError(.notConnectedToInternet)))
        #expect(networkErrorAction == .retry)
        
        let apiKeyAction = errorReporter.handle(.apiKeyMissing)
        #expect(apiKeyAction == .requestAPIKey)
        
        let rateLimitAction = errorReporter.handle(.rateLimitExceeded)
        if case .showMessage = rateLimitAction {
            // Success
        } else {
            #expect(Bool(false), "Expected showMessage action for rate limit error")
        }
    }

}
