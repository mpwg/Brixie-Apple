//
//  BrixieError.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

enum BrixieError: LocalizedError, Sendable {
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
final class ErrorHandler: @unchecked Sendable {
    static let shared = ErrorHandler()
    
    private init() {}
    
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
}

enum ErrorRecoveryAction: Sendable {
    case retry
    case requestAPIKey
    case clearCache
    case showMessage(String)
}