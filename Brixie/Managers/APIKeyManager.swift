//
//  APIKeyManager.swift
//  Brixie
//
//  Created by Claude on 05.09.25.
//

import SwiftUI
import Combine
import Foundation

@MainActor
final class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()
    
    private static let apiKeyStorageKey = "rebrickableAPIKey"
    
    @Published var apiKey: String = ""
    @Published var hasValidAPIKey: Bool = false
    
    private var isInitialized = false
    
    private init() {
        // Load the API key from secure Keychain storage
        let loadedKey = KeychainManager.shared.retrieve(for: Self.apiKeyStorageKey) ?? ""
        self.apiKey = loadedKey
        self.hasValidAPIKey = !loadedKey.isEmpty
        self.isInitialized = true
        
        $apiKey
            .map { !$0.isEmpty }
            .assign(to: &$hasValidAPIKey)
        
        // Set up the observer for future changes
        $apiKey
            .dropFirst() // Skip the initial value
            .sink { [weak self] newValue in
                self?.storeAPIKey(newValue)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
