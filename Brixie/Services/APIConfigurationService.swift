//
//  APIConfigurationService.swift
//  Brixie
//
//  Created by Copilot on 06.09.25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class APIConfigurationService: @unchecked Sendable {
    @AppStorage("rebrickableAPIKey") @ObservationIgnored private var userAPIKey: String = ""
    
    // Read from generated configuration for embedded keys
    private var embeddedAPIKey: String? {
        GeneratedConfiguration.rebrickableAPIKey
    }
    
    private var hasEmbeddedAPIKey: Bool {
        GeneratedConfiguration.hasEmbeddedAPIKey
    }
    
    // Current active API key (user override takes precedence)
    var currentAPIKey: String? {
        if !userAPIKey.isEmpty {
            return userAPIKey
        }
        return embeddedAPIKey
    }
    
    // Whether we have any valid API key
    var hasValidAPIKey: Bool {
        currentAPIKey != nil && !currentAPIKey!.isEmpty
    }
    
    // Whether user has overridden the embedded key
    var hasUserOverride: Bool {
        !userAPIKey.isEmpty
    }
    
    // User-facing API key for settings UI
    var userApiKey: String {
        get { userAPIKey }
        set { userAPIKey = newValue }
    }
    
    // Status information for settings UI
    var configurationStatus: String {
        if hasUserOverride {
            return "Using custom API key"
        } else if hasEmbeddedAPIKey {
            return "Using embedded API key"
        } else {
            return "No API key configured"
        }
    }
    
    // Clear user override to fall back to embedded key
    func clearUserOverride() {
        userAPIKey = ""
    }
    
    // Test if API key is valid format (basic validation)
    func isValidAPIKeyFormat(_ key: String) -> Bool {
        // Rebrickable API keys are typically 32-40 character alphanumeric strings
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 32 && trimmed.allSatisfy { $0.isLetter || $0.isNumber }
    }
}