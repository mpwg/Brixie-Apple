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
            return Strings.networkError(error.localizedDescription).localized
        case .apiKeyMissing:
            return Strings.apiKeyMissing.localized
        case .parsingError:
            return Strings.parsingError.localized
        case .cacheError(let error):
            return Strings.cacheError(error.localizedDescription).localized
        case .invalidURL(let url):
            return Strings.invalidURL(url).localized
        case .dataNotFound:
            return Strings.dataNotFound.localized
        case .persistenceError(let error):
            return Strings.persistenceError(error.localizedDescription).localized
        case .rateLimitExceeded:
            return Strings.rateLimitExceeded.localized
        case .unauthorized:
            return Strings.unauthorized.localized
        case .serverError(let statusCode):
            return Strings.serverError(statusCode).localized
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return Strings.checkConnection.localized
        case .apiKeyMissing, .unauthorized:
            return Strings.enterValidApiKey.localized
        case .rateLimitExceeded:
            return Strings.waitBeforeRetry.localized
        case .cacheError:
            return Strings.clearAppCache.localized
        default:
            return Strings.tryAgainLater.localized
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