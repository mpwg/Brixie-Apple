//
//  ThemeService.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftData
import SwiftUI
import RebrickableLegoAPIClient
import OSLog

/// Service for managing LEGO theme data from Rebrickable API and local cache
/// Extracted from LegoSetService to follow single responsibility principle
@MainActor
final class ThemeService {
    /// Singleton instance
    static let shared = ThemeService()
    
    /// SwiftData model context for database operations
    private var modelContext: ModelContext?
    
    /// API configuration manager
    private let apiConfig = APIConfiguration.shared
    
    /// Current loading state
    var isLoading: Bool = false
    
    /// Current error state
    var currentError: (any Error)?
    
    /// Last theme sync date
    var lastThemeSyncDate: Date?
    
    // MARK: - Initialization
    
    init() {
        loadLastThemeSyncDate()
    }
    
    /// Configure with SwiftData model context
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Theme Operations
    
    /// Clear all cached themes (for debugging)
    func clearCachedThemes() throws {
        Logger.themeService.entering()
        
        guard let modelContext = modelContext else {
            Logger.themeService.error("No model context configured")
            throw ThemeServiceError.notConfigured
        }
        
        let descriptor = FetchDescriptor<Theme>()
        let allThemes = try modelContext.fetch(descriptor)
        
        for theme in allThemes {
            modelContext.delete(theme)
        }
        
        try modelContext.save()
        Logger.themeService.info("Cleared \(allThemes.count) cached themes")
        
        // Reset sync date to force fresh fetch
        lastThemeSyncDate = nil
        saveLastThemeSyncDate()
        
        Logger.themeService.exitWith()
    }
    
    /// Force refresh all themes from API (clears cache first)
    func forceRefreshThemes() async throws -> [Theme] {
        Logger.themeService.entering()
        
        // Log cache state before clearing
        if let cacheAge = getCacheAgeHours() {
            Logger.themeService.info("Force refresh requested. Current cache age: \(cacheAge, format: .fixed(precision: 2))h")
        } else {
            Logger.themeService.info("Force refresh requested. No existing cache.")
        }
        
        // Clear existing cache
        try clearCachedThemes()
        Logger.themeService.info("Cache cleared, forcing API fetch...")
        
        // Fetch fresh data from API
        let freshThemes = try await fetchThemes()
        
        Logger.themeService.exitWith(result: "\(freshThemes.count) themes refreshed from API")
        return freshThemes
    }
    
    /// Fetch all themes from API or local cache
    func fetchThemes() async throws -> [Theme] {
        Logger.themeService.entering()
        
        guard modelContext != nil else {
            Logger.themeService.error("No model context configured")
            throw ThemeServiceError.notConfigured
        }
        
        guard apiConfig.isConfigured else {
            Logger.themeService.error("API not configured")
            throw ThemeServiceError.apiNotConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Try to get cached themes first
        let cachedThemes = try fetchCachedThemes()
        Logger.database.info("Found \(cachedThemes.count) cached themes")
        
        // Log cache freshness status
        let isFresh = isThemeDataFresh()
        if let lastSync = lastThemeSyncDate {
            Logger.themeService.debug("Theme cache age: \(Date().timeIntervalSince(lastSync) / 3600.0, format: .fixed(precision: 1))h, fresh: \(isFresh)")
        } else {
            Logger.themeService.debug("No previous theme sync recorded, cache not fresh")
        }
        
        // If we have fresh data, return it
        if isFresh && !cachedThemes.isEmpty {
            Logger.themeService.info("Using fresh cached data (\(cachedThemes.count) themes)")
            Logger.themeService.exitWith(result: "\(cachedThemes.count) themes")
            return cachedThemes
        }
        
        // Otherwise fetch from API
        Logger.network.info("Fetching themes from API (cache miss or stale)...")
        do {
            let startTime = Date()
            let apiThemes = try await fetchThemesFromAPI()
            let duration = Date().timeIntervalSince(startTime)
            
            Logger.network.apiCall("themes", duration: duration)
            Logger.themeService.info("Fetched \(apiThemes.count) themes from API in \(duration, format: .fixed(precision: 2))s")
            
            lastThemeSyncDate = Date()
            saveLastThemeSyncDate()
            
            Logger.themeService.exitWith(result: "\(apiThemes.count) themes from API")
            return apiThemes
        } catch {
            Logger.error.error("API fetch failed: \(error.localizedDescription, privacy: .public)")
            currentError = error
            // Return cached data if API fails
            if !cachedThemes.isEmpty {
                Logger.themeService.info("Returning \(cachedThemes.count) cached themes as fallback")
                return cachedThemes
            }
            throw error
        }
    }
    
    /// Get specific theme by ID
    func getTheme(byId id: Int) async throws -> Theme? {
        guard let modelContext = modelContext else {
            throw ThemeServiceError.notConfigured
        }
        
        // First try local cache
        let descriptor = FetchDescriptor<Theme>(
            predicate: #Predicate { $0.id == id }
        )
        
        let cachedThemes = try modelContext.fetch(descriptor)
        if let theme = cachedThemes.first {
            return theme
        }
        
        // If not in cache and API is configured, try to fetch
        guard apiConfig.isConfigured else {
            return nil
        }
        
        do {
            guard let apiClientConfig = apiConfig.apiClient else {
                throw ThemeServiceError.apiNotConfigured
            }
            
            let apiTheme = try await LegoAPI.legoThemesRead(
                id: id,
                apiConfiguration: apiClientConfig
            )
            
            // Convert and save to cache
            let localTheme = convertToTheme(apiTheme)
            modelContext.insert(localTheme)
            try modelContext.save()
            
            return localTheme
        } catch {
            currentError = error
            throw error
        }
    }
    
    /// Get root themes (themes with no parent)
    func getRootThemes() async throws -> [Theme] {
        let allThemes = try await fetchThemes()
        return allThemes.filter { $0.parentId == nil }
    }
    
    /// Get child themes for a parent theme
    func getChildThemes(for parentId: Int) async throws -> [Theme] {
        let allThemes = try await fetchThemes()
        return allThemes.filter { $0.parentId == parentId }
    }
    
    /// Search themes by name
    func searchThemes(query: String) async throws -> [Theme] {
        let allThemes = try await fetchThemes()
        if query.isEmpty {
            return allThemes
        }
        
        return allThemes.filter { theme in
            theme.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Get theme statistics for debugging/monitoring
    func getThemeStatistics() throws -> ThemeStatistics {
        guard let modelContext = modelContext else {
            throw ThemeServiceError.notConfigured
        }
        
        let descriptor = FetchDescriptor<Theme>()
        let allThemes = try modelContext.fetch(descriptor)
        let rootThemes = allThemes.filter { $0.parentId == nil }
        
        return ThemeStatistics(
            totalThemes: allThemes.count,
            rootThemes: rootThemes.count,
            lastSyncDate: lastThemeSyncDate,
            isDataFresh: isThemeDataFresh()
        )
    }
    
    // MARK: - Private Methods
    
    /// Fetch themes from local cache
    private func fetchCachedThemes() throws -> [Theme] {
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<Theme>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch themes from Rebrickable API
    private func fetchThemesFromAPI() async throws -> [Theme] {
        guard let modelContext = modelContext else {
            throw ThemeServiceError.notConfigured
        }
        
        guard let apiClientConfig = apiConfig.apiClient else {
            throw ThemeServiceError.apiNotConfigured
        }
        
        // Fetch all themes from API using pagination
        var allApiThemes: [RebrickableLegoAPIClient.Theme] = []
        var currentPage = 1
        let pageSize = 1000 // Use large page size to minimize API calls
        
        Logger.network.info("Starting theme fetch with pagination")
        
        while true {
            Logger.network.debug("Fetching themes page \(currentPage)")
            
            let themesResponse = try await LegoAPI.legoThemesList(
                page: currentPage,
                pageSize: pageSize,
                ordering: nil,
                apiConfiguration: apiClientConfig
            )
            
            let pageThemes = themesResponse.results
            allApiThemes.append(contentsOf: pageThemes)
            
            Logger.network.debug("Page \(currentPage): got \(pageThemes.count) themes (total so far: \(allApiThemes.count))")
            
            // If we got fewer themes than the page size, we've reached the end
            if pageThemes.count < pageSize {
                Logger.network.info("Completed theme fetch: \(allApiThemes.count) themes across \(currentPage) pages")
                break
            }
            
            currentPage += 1
        }
        
        let apiThemes = allApiThemes
        
        // Convert API themes to local themes
        var localThemes: [Theme] = []
        
        for apiTheme in apiThemes {
            let localTheme = convertToTheme(apiTheme)
            
            // Check if theme already exists
            let themeId = localTheme.id
            let descriptor = FetchDescriptor<Theme>(
                predicate: #Predicate<Theme> { $0.id == themeId }
            )
            
            let existingThemes = try modelContext.fetch(descriptor)
            
            if let existingTheme = existingThemes.first {
                // Update existing theme
                existingTheme.name = localTheme.name
                existingTheme.parentId = localTheme.parentId
                existingTheme.lastModified = localTheme.lastModified
                existingTheme.sortOrder = localTheme.sortOrder
                localThemes.append(existingTheme)
            } else {
                // Insert new theme
                modelContext.insert(localTheme)
                localThemes.append(localTheme)
            }
        }
        
        // Save changes to get stable IDs
        try modelContext.save()
        
        // Now establish parent-child relationships
        Logger.themeService.info("Establishing theme relationships...")
        try establishThemeRelationships()
        
        // Establish set-theme relationships
        Logger.themeService.info("Establishing set-theme relationships...")
        try establishSetThemeRelationships()
        
        // Final save after establishing relationships
        try modelContext.save()
        
        Logger.themeService.info("All relationships established successfully")
        
        return localThemes
    }
    
    /// Check if theme data is fresh (less than 24 hours old)
    private func isThemeDataFresh() -> Bool {
        guard let lastSync = lastThemeSyncDate else { return false }
        let ageHours = Date().timeIntervalSince(lastSync) / 3600.0
        return ageHours < 24.0
    }
    
    /// Get the age of cached theme data in hours
    func getCacheAgeHours() -> Double? {
        guard let lastSync = lastThemeSyncDate else { return nil }
        return Date().timeIntervalSince(lastSync) / 3600.0
    }
    
    /// Load last theme sync date from UserDefaults
    private func loadLastThemeSyncDate() {
        if let date = UserDefaults.standard.object(forKey: "lastThemeSyncDate") as? Date {
            lastThemeSyncDate = date
        }
    }
    
    /// Save last theme sync date to UserDefaults
    private func saveLastThemeSyncDate() {
        if let date = lastThemeSyncDate {
            UserDefaults.standard.set(date, forKey: "lastThemeSyncDate")
        }
    }
    
    /// Convert API Theme to local Theme model
    private func convertToTheme(_ apiTheme: RebrickableLegoAPIClient.Theme) -> Theme {
        return Theme(
            id: apiTheme.id,
            name: apiTheme.name,
            parentId: apiTheme.parentId,
            lastModified: Date(),
            sortOrder: nil // Could be enhanced with ordering logic
        )
    }
    
    /// Establish parent-child relationships between themes
    private func establishThemeRelationships() throws {
        guard let modelContext = modelContext else {
            throw ThemeServiceError.notConfigured
        }
        
        // Fetch all themes
        let allThemes = try modelContext.fetch(FetchDescriptor<Theme>())
        
        // Create lookup dictionary for efficient access
        var themeById: [Int: Theme] = [:]
        for theme in allThemes {
            themeById[theme.id] = theme
        }
        
        Logger.themeService.info("Establishing relationships for \(allThemes.count) themes")
        
        // Establish relationships
        for theme in allThemes {
            if let parentId = theme.parentId, let parentTheme = themeById[parentId] {
                // Set parent-child relationship
                theme.parentTheme = parentTheme
                if !parentTheme.subthemes.contains(theme) {
                    parentTheme.subthemes.append(theme)
                }
            }
        }
        
        Logger.themeService.info("Theme relationships established")
    }
    
    /// Establish relationships between sets and themes
    private func establishSetThemeRelationships() throws {
        guard let modelContext = modelContext else {
            throw ThemeServiceError.notConfigured
        }
        
        // Fetch all themes and sets
        let allThemes = try modelContext.fetch(FetchDescriptor<Theme>())
        let allSets = try modelContext.fetch(FetchDescriptor<LegoSet>())
        
        // Create lookup dictionary for efficient theme access
        var themeById: [Int: Theme] = [:]
        for theme in allThemes {
            themeById[theme.id] = theme
        }
        
        Logger.themeService.info("Establishing set-theme relationships for \(allSets.count) sets")
        
        // Establish set-theme relationships
        var relationshipsEstablished = 0
        for set in allSets {
            if let theme = themeById[set.themeId] {
                // Set the theme relationship if not already set
                if set.theme != theme {
                    set.theme = theme
                    relationshipsEstablished += 1
                }
                
                // Add set to theme's sets if not already there
                if !theme.sets.contains(set) {
                    theme.sets.append(set)
                }
            }
        }
        
        Logger.themeService.info("Established \(relationshipsEstablished) set-theme relationships")
    }
}

// MARK: - ThemeService Errors

enum ThemeServiceError: LocalizedError {
    case notConfigured
    case apiNotConfigured
    case networkError
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return NSLocalizedString("Theme service not configured with model context", comment: "Theme service error")
        case .apiNotConfigured:
            return NSLocalizedString("API not configured. Please add your Rebrickable API key.", comment: "API error")
        case .networkError:
            return NSLocalizedString("Network error occurred while fetching themes", comment: "Network error")
        case .parseError:
            return NSLocalizedString("Failed to parse theme data", comment: "Parse error")
        }
    }
}

// MARK: - Theme Statistics

struct ThemeStatistics {
    let totalThemes: Int
    let rootThemes: Int
    let lastSyncDate: Date?
    let isDataFresh: Bool
}