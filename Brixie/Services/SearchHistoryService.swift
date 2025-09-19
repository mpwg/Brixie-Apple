//
//  SearchHistoryService.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftUI

/// Service for managing search history and suggestions
final class SearchHistoryService {
    static let shared = SearchHistoryService()
    
    private let maxHistoryItems = 20
    private let userDefaultsKey = "SearchHistory"
    
    /// Recent search queries
    private(set) var recentSearches: [String] = []
    
    /// Search suggestions based on popular searches
    private(set) var suggestions: [String] = [
        "Star Wars",
        "Creator",
        "Technic",
        "Architecture",
        "Harry Potter",
        "Friends",
        "City",
        "Ninjago",
        "Speed Champions",
        "Ideas"
    ]
    
    private init() {
        loadRecentSearches()
    }
    
    /// Add a search query to the history
    func addToHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count > 1 else { return }
        
        // Remove existing instance if present
        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }
        
        // Add to beginning
        recentSearches.insert(trimmed, at: 0)
        
        // Limit to max items
        if recentSearches.count > maxHistoryItems {
            recentSearches = Array(recentSearches.prefix(maxHistoryItems))
        }
        
        saveRecentSearches()
    }
    
    /// Clear all search history
    func clearHistory() {
        recentSearches.removeAll()
        saveRecentSearches()
    }
    
    /// Get filtered suggestions based on current query
    func getSuggestions(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            return Array(recentSearches.prefix(5)) + Array(suggestions.prefix(5))
        }
        
        var filteredSuggestions: [String] = []
        
        // Add matching recent searches
        let matchingRecent = recentSearches.filter { 
            $0.lowercased().contains(trimmed)
        }
        filteredSuggestions.append(contentsOf: Array(matchingRecent.prefix(3)))
        
        // Add matching default suggestions
        let matchingDefault = suggestions.filter { 
            $0.lowercased().contains(trimmed) && 
            !filteredSuggestions.contains($0)
        }
        filteredSuggestions.append(contentsOf: Array(matchingDefault.prefix(7)))
        
        return filteredSuggestions
    }
    
    // MARK: - Private Methods
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: userDefaultsKey)
    }
}