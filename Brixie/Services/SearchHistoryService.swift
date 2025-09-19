//
//  SearchHistoryService.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftUI
import OSLog

/// Service for managing search history and suggestions
final class SearchHistoryService {
    static let shared = SearchHistoryService()
    
    /// Logger for search history operations
    private let logger = Logger.search
    
    private let maxHistoryItems = AppConstants.Search.maxHistoryItems
    private let userDefaultsKey = AppConstants.UserDefaultsKeys.searchHistory
    
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
        logger.debug("🎯 SearchHistoryService initialized")
        loadRecentSearches()
    }
    
    /// Add a search query to the history
    func addToHistory(_ query: String) {
        logger.entering(parameters: ["query": query])
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count > AppConstants.Search.minQueryLength else {
            logger.debug("⚠️ Skipping empty or too short query")
            logger.exitWith(result: "skipped - invalid query")
            return
        }
        
        let existingIndex = recentSearches.firstIndex { $0.lowercased() == trimmed.lowercased() }
        
        // Remove existing instance if present
        if let index = existingIndex {
            recentSearches.remove(at: index)
            logger.debug("🔄 Moved existing query '\(trimmed)' to top of history")
        } else {
            logger.debug("➕ Added new query '\(trimmed)' to search history")
        }
        
        // Add to beginning
        recentSearches.insert(trimmed, at: 0)
        
        // Limit to max items
        if recentSearches.count > maxHistoryItems {
            let removedCount = recentSearches.count - maxHistoryItems
            recentSearches = Array(recentSearches.prefix(maxHistoryItems))
            logger.debug("🧹 Trimmed search history, removed \(removedCount) old items")
        }
        
        saveRecentSearches()
        logger.userAction("added_search_to_history", context: ["query": trimmed, "historyCount": recentSearches.count])
        logger.exitWith(result: "added to history (\(recentSearches.count) total)")
    }
    
    /// Clear all search history
    func clearHistory() {
        logger.entering()
        let previousCount = recentSearches.count
        recentSearches.removeAll()
        saveRecentSearches()
        logger.info("🗑️ Cleared all search history (\(previousCount) items removed)")
        logger.userAction("cleared_search_history", context: ["itemsRemoved": previousCount])
        logger.exitWith(result: "cleared \(previousCount) items")
    }
    
    /// Get filtered suggestions based on current query
    func getSuggestions(for query: String) -> [String] {
        logger.entering(parameters: ["query": query])
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            let suggestions = Array(recentSearches.prefix(AppConstants.Search.recentSuggestionsCount)) + Array(self.suggestions.prefix(AppConstants.Search.popularSuggestionsCount))
            logger.debug("📝 Returning default suggestions: \(suggestions.count) items")
            logger.exitWith(result: "\(suggestions.count) default suggestions")
            return suggestions
        }
        
        var filteredSuggestions: [String] = []
        
        // Add matching recent searches
        let matchingRecent = recentSearches.filter { 
            $0.lowercased().contains(trimmed)
        }
        filteredSuggestions.append(contentsOf: Array(matchingRecent.prefix(AppConstants.Search.matchingRecentCount)))
        
        // Add matching default suggestions
        let matchingDefault = suggestions.filter { 
            $0.lowercased().contains(trimmed) && 
            !filteredSuggestions.contains($0)
        }
        filteredSuggestions.append(contentsOf: Array(matchingDefault.prefix(AppConstants.Search.matchingDefaultCount)))
        
        logger.debug("🔍 Generated \(filteredSuggestions.count) suggestions for '\(trimmed)' (\(matchingRecent.count) recent, \(matchingDefault.count) default)")
        logger.exitWith(result: "\(filteredSuggestions.count) filtered suggestions")
        
        return filteredSuggestions
    }
    
    // MARK: - Private Methods
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
        logger.debug("📚 Loaded \(self.recentSearches.count) search history items from UserDefaults")
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: userDefaultsKey)
        logger.debug("💾 Saved \(self.recentSearches.count) search history items to UserDefaults")
    }
}
