//
//  APIKeyManager.swift
//  Brixie
//
//  Created by Claude on 05.09.25.
//

import Foundation

final class APIKeyManager {
    static let shared = APIKeyManager()
    
    private(set) var apiKey: String
    
    var hasValidAPIKey: Bool {
        !apiKey.isEmpty
    }
    
    private init() {
        if GeneratedConfiguration.hasEmbeddedAPIKey, let embeddedKey = GeneratedConfiguration.rebrickableAPIKey {
            self.apiKey = embeddedKey
        } else {
            self.apiKey = ""
        }
    }
    
    var isConfigured: Bool {
        hasValidAPIKey
    }
}
