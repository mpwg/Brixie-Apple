//
//  BrixieError.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation

/// Centralized error handling for Brixie app
enum BrixieError: LocalizedError, Equatable {
    case networkUnavailable
    case apiKeyMissing
    case apiKeyInvalid
    case dataCorrupted
    case unknown(String)
    case service(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection is not available. Please check your internet connection."
        case .apiKeyMissing:
            return "Rebrickable API key is missing. Please configure it in Settings."
        case .apiKeyInvalid:
            return "The provided API key is invalid. Please check your Rebrickable API key in Settings."
        case .dataCorrupted:
            return "The data appears to be corrupted. Please try refreshing."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        case .service(let message):
            return "Service error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .apiKeyMissing, .apiKeyInvalid:
            return "Go to Settings to configure your Rebrickable API key."
        case .dataCorrupted:
            return "Pull to refresh to reload the data."
        case .unknown, .service:
            return "Try again later or contact support if the problem persists."
        }
    }
    
    /// Convert any Error to BrixieError
    static func from(_ error: any Error) -> BrixieError {
        if let brixieError = error as? BrixieError {
            return brixieError
        }
        
        // Map specific errors to BrixieError cases
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("network") || errorString.contains("internet") {
            return .networkUnavailable
        }
        
        if errorString.contains("api key") {
            return .apiKeyInvalid
        }
        
        if errorString.contains("corrupted") || errorString.contains("invalid data") {
            return .dataCorrupted
        }
        
        return .unknown(error.localizedDescription)
    }
}