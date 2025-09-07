//
//  BrixieError.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

enum BrixieError: LocalizedError, Sendable, Equatable {
    case networkError(underlying: Error)
    case apiKeyMissing
    case parsingError
    case cacheError(underlying: Error)
    case invalidURL(String)
    case dataNotFound
    case persistenceError(underlying: Error)
    case rateLimitExceeded
    case unauthorized
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return NSLocalizedString("Network error: \(error.localizedDescription)", comment: "Network error description")
        case .apiKeyMissing:
            return NSLocalizedString("API key is required to fetch data", comment: "API key missing error")
        case .parsingError:
            return NSLocalizedString("Failed to parse response", comment: "Parsing error description")
        case .cacheError(let error):
            return NSLocalizedString("Cache operation failed: \(error.localizedDescription)", comment: "Cache error description")
        case .invalidURL(let url):
            return NSLocalizedString("Invalid URL: \(url)", comment: "Invalid URL error")
        case .dataNotFound:
            return NSLocalizedString("Requested data not found", comment: "Data not found error")
        case .persistenceError(let error):
            return NSLocalizedString("Data persistence failed: \(error.localizedDescription)", comment: "Persistence error description")
        case .rateLimitExceeded:
            return NSLocalizedString("API rate limit exceeded. Please try again later", comment: "Rate limit error")
        case .unauthorized:
            return NSLocalizedString("Unauthorized. Please check your API key", comment: "Unauthorized error")
        case .serverError(let statusCode):
            return NSLocalizedString("Server error (status: \(statusCode))", comment: "Server error description")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return NSLocalizedString("Check your internet connection and try again", comment: "Network error recovery")
        case .apiKeyMissing, .unauthorized:
            return NSLocalizedString("Please enter a valid API key in settings", comment: "API key recovery")
        case .rateLimitExceeded:
            return NSLocalizedString("Wait a few minutes before making more requests", comment: "Rate limit recovery")
        case .cacheError:
            return NSLocalizedString("Try clearing the app cache in settings", comment: "Cache error recovery")
        default:
            return NSLocalizedString("Please try again later", comment: "Generic recovery suggestion")
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: BrixieError, rhs: BrixieError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError, .networkError):
            return true
        case (.apiKeyMissing, .apiKeyMissing):
            return true
        case (.parsingError, .parsingError):
            return true
        case (.cacheError, .cacheError):
            return true
        case (.invalidURL(let lhsURL), .invalidURL(let rhsURL)):
            return lhsURL == rhsURL
        case (.dataNotFound, .dataNotFound):
            return true
        case (.persistenceError, .persistenceError):
            return true
        case (.rateLimitExceeded, .rateLimitExceeded):
            return true
        case (.unauthorized, .unauthorized):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}

// MARK: - Result Extensions

extension Result where Failure == BrixieError {
    static func networkError(_ error: Error) -> Result {
        .failure(.networkError(underlying: error))
    }
    
    static func parsingError() -> Result {
        .failure(.parsingError)
    }
    
    static func apiKeyMissing() -> Result {
        .failure(.apiKeyMissing)
    }
}

// MARK: - Error Recovery

@MainActor
@Observable
final class ErrorReporter: @unchecked Sendable {
    static let shared = ErrorReporter()
    
    private(set) var currentError: BrixieError?
    private(set) var isShowingError = false
    
    private init() {}
    
    func report(_ error: Error) {
        let brixieError = mapToBrixieError(error)
        currentError = brixieError
        isShowingError = true
    }
    
    func report(_ error: BrixieError) {
        currentError = error
        isShowingError = true
    }
    
    func clearError() {
        currentError = nil
        isShowingError = false
    }
    
    func handle(_ error: BrixieError) -> ErrorRecoveryAction {
        switch error {
        case .networkError:
            return .retry
        case .apiKeyMissing, .unauthorized:
            return .requestAPIKey
        case .rateLimitExceeded:
            return .showMessage(error.errorDescription ?? "Unknown error")
        case .cacheError:
            return .clearCache
        default:
            return .showMessage(error.errorDescription ?? "Unknown error")
        }
    }
    
    private func mapToBrixieError(_ error: Error) -> BrixieError {
        if let brixieError = error as? BrixieError {
            return brixieError
        }
        
        // Map common error types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(underlying: error)
            case .timedOut:
                return .networkError(underlying: error)
            case .badURL:
                return .invalidURL(urlError.localizedDescription)
            default:
                return .networkError(underlying: error)
            }
        }
        
        // Default mapping
        return .networkError(underlying: error)
    }
}

enum ErrorRecoveryAction: Sendable, Equatable {
    case retry
    case requestAPIKey
    case clearCache
    case showMessage(String)
}

// MARK: - Legacy Support

@MainActor
final class ErrorHandler: @unchecked Sendable {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(_ error: BrixieError) -> ErrorRecoveryAction {
        return ErrorReporter.shared.handle(error)
    }
}