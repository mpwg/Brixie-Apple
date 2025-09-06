//
//  APIKeyManager.swift
//  Brixie
//
//  Created by Claude on 05.09.25.
//

import SwiftUI
import Foundation

@Observable
@MainActor
final class APIKeyManager {
    static let shared = APIKeyManager()
    
    private static let apiKeyStorageKey = "rebrickableAPIKey"
    
    var apiKey: String = "" {
        didSet {
            hasValidAPIKey = !apiKey.isEmpty
            if isInitialized {
                storeAPIKey(apiKey)
            }
        }
    }
    
    var hasValidAPIKey: Bool = false
    
    private var isInitialized = false
    
    private init() {
        let loadedKey = KeychainManager.shared.retrieve(for: Self.apiKeyStorageKey) ?? ""
        self.apiKey = loadedKey
        self.hasValidAPIKey = !loadedKey.isEmpty
        self.isInitialized = true
    }
    
    private func storeAPIKey(_ key: String) {
        guard isInitialized else { return }
        
        if key.isEmpty {
            _ = KeychainManager.shared.delete(for: Self.apiKeyStorageKey)
        } else {
            _ = KeychainManager.shared.store(key, for: Self.apiKeyStorageKey)
        }
    }
    
    func updateAPIKey(_ newKey: String) {
        apiKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func clearAPIKey() {
        apiKey = ""
    }
    
    var isConfigured: Bool {
        hasValidAPIKey
    }
}
