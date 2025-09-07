//
//  RecentSearchesStorage.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@MainActor
final class RecentSearchesStorage {
    static let shared = RecentSearchesStorage()
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "recentSearches"
    private let maxSearches = 5
    
    private init() {}
    
    func loadRecentSearches() -> [String] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let searches = try JSONDecoder().decode([String].self, from: data)
            // Ensure we don't exceed the maximum number of searches
            return Array(searches.prefix(maxSearches))
        } catch {
            // If decoding fails, return empty array and clear corrupted data
            userDefaults.removeObject(forKey: storageKey)
            return []
        }
    }
    
    func saveRecentSearches(_ searches: [String]) {
        let limitedSearches = Array(searches.prefix(maxSearches))
        
        do {
            let data = try JSONEncoder().encode(limitedSearches)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            // If encoding fails, we could log this error in a real app
            // For now, we'll silently handle the failure
        }
    }
    
    func addSearch(_ search: String) {
        var searches = loadRecentSearches()
        
        // Remove existing occurrence if present
        searches.removeAll { $0 == search }
        
        // Insert at the beginning
        searches.insert(search, at: 0)
        
        // Save the updated list
        saveRecentSearches(searches)
    }
    
    func clearRecentSearches() {
        userDefaults.removeObject(forKey: storageKey)
    }
}