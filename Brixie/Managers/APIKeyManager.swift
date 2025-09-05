//
//  APIKeyManager.swift
//  Brixie
//
//  Created by Claude on 05.09.25.
//

import SwiftUI
import Combine

@MainActor
final class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()
    
    private static let apiKeyStorageKey = "rebrickableAPIKey"
    
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: Self.apiKeyStorageKey)
        }
    }
    
    @Published var hasValidAPIKey: Bool = false
    
    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: Self.apiKeyStorageKey) ?? ""
        self.hasValidAPIKey = !apiKey.isEmpty
        
        $apiKey
            .map { !$0.isEmpty }
            .assign(to: &$hasValidAPIKey)
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