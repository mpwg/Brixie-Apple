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
