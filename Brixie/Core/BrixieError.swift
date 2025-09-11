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
            return String(
                format: NSLocalizedString("Network error: %@", comment: "Network error description"),
                error.localizedDescription
            )
        case .apiKeyMissing:
            return NSLocalizedString("API key is required to fetch data", comment: "API key missing error")
        case .parsingError:
            return NSLocalizedString("Failed to parse response", comment: "Parsing error description")
        case .cacheError(let error):
            return String(
                format: NSLocalizedString("Cache operation failed: %@", comment: "Cache error description"),
                error.localizedDescription
            )
        case .invalidURL(let url):
            return String(
                format: NSLocalizedString("Invalid URL: %@", comment: "Invalid URL error"),
                url
            )
        case .dataNotFound:
            return NSLocalizedString("Requested data not found", comment: "Data not found error")
        case .persistenceError(let error):
            return String(
                format: NSLocalizedString("Data persistence failed: %@", comment: "Persistence error description"),
                error.localizedDescription
            )
        case .rateLimitExceeded:
            return NSLocalizedString("API rate limit exceeded. Please try again later", comment: "Rate limit error")
        case .unauthorized:
            return NSLocalizedString("Unauthorized. Please check your API key", comment: "Unauthorized error")
        case .serverError(let statusCode):
            return String(
                format: NSLocalizedString("Server error (status: %d)", comment: "Server error description"),
                statusCode
            )
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
    
    // MARK: Equatable
    
    // swiftlint:disable:next cyclomatic_complexity
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
        case let (.invalidURL(lhsURL), .invalidURL(rhsURL)):
            return lhsURL == rhsURL
        case (.dataNotFound, .dataNotFound):
            return true
        case (.persistenceError, .persistenceError):
            return true
        case (.rateLimitExceeded, .rateLimitExceeded):
            return true
        case (.unauthorized, .unauthorized):
            return true
        case let (.serverError(lhsCode), .serverError(rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}

// MARK: Result Extensions

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

// MARK: Error Recovery

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

// MARK: Legacy Support

@MainActor
final class ErrorHandler: @unchecked Sendable {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(_ error: BrixieError) -> ErrorRecoveryAction {
        return ErrorReporter.shared.handle(error)
    }
}
