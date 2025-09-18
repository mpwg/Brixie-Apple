//
//  LegoSetService.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftData
import SwiftUI

/// Service for managing LEGO set data from Rebrickable API and local cache
@Observable @MainActor
final class LegoSetService {
    /// Singleton instance
    static let shared = LegoSetService()
    
    /// SwiftData model context for database operations
    private var modelContext: ModelContext?
    
    /// API configuration manager
    private let apiConfig = APIConfiguration.shared
    
    /// Current loading state
    var isLoading: Bool = false
    
    /// Current error state
    var currentError: Error?
    
    /// Last sync date
    var lastSyncDate: Date?
    
    // MARK: - Initialization
    
    init() {
        loadLastSyncDate()
    }
    
    /// Configure with SwiftData model context
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Set Operations
    
    /// Fetch sets from API or local cache
    func fetchSets(limit: Int = 20, offset: Int = 0) async throws -> [LegoSet] {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // First try to load from local cache
        let cachedSets = try fetchCachedSets(limit: limit, offset: offset)
        
        // If we have cached data and it's recent, return it
        if !cachedSets.isEmpty && isDataFresh() {
            return cachedSets
        }
        
        // Otherwise, fetch from API
        return try await fetchSetsFromAPI(limit: limit, offset: offset)
    }
    
    /// Fetch sets by theme
    func fetchSets(forThemeId themeId: Int, limit: Int = 20, offset: Int = 0) async throws -> [LegoSet] {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        // Try local cache first
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: #Predicate { $0.themeId == themeId },
            sortBy: [SortDescriptor(\.year, order: .reverse), SortDescriptor(\.name)]
        )
        
        let cachedSets = try context.fetch(descriptor)
        
        if !cachedSets.isEmpty && isDataFresh() {
            return Array(cachedSets.prefix(limit))
        }
        
        // Fetch from API (implementation would go here when RebrickableAPI is available)
        return cachedSets
    }
    
    /// Search sets by various criteria
    func searchSets(
        query: String,
        searchType: SearchType = .name,
        limit: Int = 20
    ) async throws -> [LegoSet] {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        let predicate: Predicate<LegoSet>
        
        switch searchType {
        case .name:
            predicate = #Predicate { set in
                set.name.localizedStandardContains(query)
            }
        case .setNumber:
            predicate = #Predicate { set in
                set.setNumber.localizedStandardContains(query)
            }
        case .theme:
            // This would need to join with Theme table
            predicate = #Predicate { set in
                set.name.localizedStandardContains(query)
            }
        case .barcode:
            // Barcode search would need special handling
            predicate = #Predicate { set in
                set.setNumber == query
            }
        }
        
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        
        let results = try context.fetch(descriptor)
        return Array(results.prefix(limit))
    }
    
    /// Get set by set number
    func getSet(byNumber setNumber: String) async throws -> LegoSet? {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: #Predicate { $0.setNumber == setNumber }
        )
        
        return try context.fetch(descriptor).first
    }
    
    // MARK: - Private Methods
    
    /// Fetch sets from local cache
    private func fetchCachedSets(limit: Int, offset: Int) throws -> [LegoSet] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<LegoSet>(
            sortBy: [SortDescriptor(\.year, order: .reverse), SortDescriptor(\.name)]
        )
        
        let allSets = try context.fetch(descriptor)
        let startIndex = min(offset, allSets.count)
        let endIndex = min(offset + limit, allSets.count)
        
        return Array(allSets[startIndex..<endIndex])
    }
    
    /// Fetch sets from API and cache them
    private func fetchSetsFromAPI(limit: Int, offset: Int) async throws -> [LegoSet] {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        guard apiConfig.isConfigured else {
            throw ServiceError.apiNotConfigured
        }
        
        // TODO: Implement actual API calls when RebrickableAPI is available
        // For now, return empty array
        
        // This is where we would:
        // 1. Call apiConfig.apiClient.getSets(limit: limit, offset: offset)
        // 2. Convert API response to LegoSet models
        // 3. Save to context
        // 4. Update lastSyncDate
        
        lastSyncDate = Date()
        saveLastSyncDate()
        
        return []
    }
    
    /// Check if cached data is fresh (less than 1 hour old)
    private func isDataFresh() -> Bool {
        guard let lastSync = lastSyncDate else { return false }
        return Date().timeIntervalSince(lastSync) < 3600 // 1 hour
    }
    
    /// Load last sync date from UserDefaults
    private func loadLastSyncDate() {
        if let date = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date {
            lastSyncDate = date
        }
    }
    
    /// Save last sync date to UserDefaults
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: "LastSyncDate")
        }
    }
}

// MARK: - Supporting Types

extension LegoSetService {
    /// Types of search that can be performed
    enum SearchType: CaseIterable {
        case name
        case setNumber
        case theme
        case barcode
        
        var localizedTitle: String {
            switch self {
            case .name:
                return NSLocalizedString("Set Name", comment: "Search by set name")
            case .setNumber:
                return NSLocalizedString("Set Number", comment: "Search by set number")
            case .theme:
                return NSLocalizedString("Theme", comment: "Search by theme")
            case .barcode:
                return NSLocalizedString("Barcode", comment: "Search by barcode")
            }
        }
    }
    
    /// Service errors
    enum ServiceError: LocalizedError {
        case notConfigured
        case apiNotConfigured
        case networkError
        case parseError
        
        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return NSLocalizedString("Service not configured with model context", comment: "Service error")
            case .apiNotConfigured:
                return NSLocalizedString("API not configured. Please add your Rebrickable API key.", comment: "API error")
            case .networkError:
                return NSLocalizedString("Network error occurred", comment: "Network error")
            case .parseError:
                return NSLocalizedString("Failed to parse API response", comment: "Parse error")
            }
        }
    }
}

// MARK: - Theme Operations

extension LegoSetService {
    /// Fetch all themes from API or cache
    func fetchThemes() async throws -> [Theme] {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        // Try cache first
        let descriptor = FetchDescriptor<Theme>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        let cachedThemes = try context.fetch(descriptor)
        
        if !cachedThemes.isEmpty && isDataFresh() {
            return cachedThemes
        }
        
        // TODO: Fetch from API when available
        return cachedThemes
    }
    
    /// Get theme by ID
    func getTheme(byId id: Int) async throws -> Theme? {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        let descriptor = FetchDescriptor<Theme>(
            predicate: #Predicate { $0.id == id }
        )
        
        return try context.fetch(descriptor).first
    }
}