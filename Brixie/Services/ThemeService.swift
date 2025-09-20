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
    
    /// Logger for theme service operations
    private let logger = Logger.themeService
    
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
        logger.debug("🎯 ThemeService initialized")
        loadLastThemeSyncDate()
    }
    
    /// Configure with SwiftData model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        logger.info("⚙️ ThemeService configured with ModelContext")
    }
    
    // MARK: - Theme Operations
    
    /// Clear all cached themes (for debugging)
    func clearCachedThemes() throws {
        logger.entering()
        
        guard let modelContext = modelContext else {
            logger.error("❌ ModelContext not configured")
            logger.exitWith(result: "error: not configured")
            throw ThemeServiceError.notConfigured
        }
        
        let descriptor = FetchDescriptor<Theme>()
        let allThemes = try modelContext.fetch(descriptor)
        let themeCount = allThemes.count
        
        for theme in allThemes {
            modelContext.delete(theme)
        }
        
        try modelContext.save()
        logger.info("🗑️ Cleared \(themeCount) cached themes")
        logger.userAction("cleared_theme_cache", context: ["themesCleared": themeCount])
        
        // Reset sync date to force fresh fetch
        lastThemeSyncDate = nil
        saveLastThemeSyncDate()
        
        logger.exitWith(result: "\(themeCount) themes cleared")
    }
    
    /// Force refresh all themes from API (clears cache first)
    func forceRefreshThemes() async throws -> [Theme] {
        logger.entering()
        
        // Log cache state before clearing
        if let cacheAge = getCacheAgeHours() {
            logger.info("🔄 Force refresh requested. Current cache age: \(cacheAge, format: .fixed(precision: 2))h")
        } else {
            logger.info("🔄 Force refresh requested. No existing cache.")
        }
        logger.userAction("force_refresh_themes")
        
        // Clear existing cache
        try clearCachedThemes()
        logger.info("🧹 Cache cleared, forcing API fetch...")
        
        // Fetch fresh data from API
        let freshThemes = try await fetchThemes()
        
        logger.exitWith(result: "\(freshThemes.count) themes refreshed from API")
        return freshThemes
    }
    
    /// Fetch all themes from API or local cache
    func fetchThemes() async throws -> [Theme] {
        logger.entering()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard modelContext != nil else {
            logger.error("❌ No model context configured")
            logger.exitWith(result: "error: not configured")
            throw ThemeServiceError.notConfigured
        }
        
        guard apiConfig.isConfigured else {
            logger.error("❌ API not configured")
            logger.exitWith(result: "error: API not configured")
            throw ThemeServiceError.apiNotConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try to get cached themes first
            let cachedThemes = try fetchCachedThemes()
            
            // If we have cached data and it's recent, return it
            if !cachedThemes.isEmpty && isThemeDataFresh() {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                logger.info("📱 Using cached themes: \(cachedThemes.count) items (data is fresh)")
                logger.debug("⏱️ Cache fetch completed in \(duration, format: .fixed(precision: 3))s")
                logger.exitWith(result: "\(cachedThemes.count) cached themes")
                return cachedThemes
            }
            
            logger.debug("🌐 Cached themes unavailable or stale, fetching from API")
            // Otherwise, fetch from API
            let fetchedThemes = try await fetchThemesFromAPI()
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("✅ Fetched \(fetchedThemes.count) themes in \(duration, format: .fixed(precision: 3))s")
            logger.exitWith(result: "\(fetchedThemes.count) API themes")
            return fetchedThemes
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.error("❌ Failed to fetch themes after \(duration, format: .fixed(precision: 3))s: \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
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
        let rootThemes = allThemes.filter { $0.parentId == nil }
        
        Logger.themeService.info("🎯 getRootThemes: \(rootThemes.count) root themes out of \(allThemes.count) total")
        
        // If we have suspiciously few root themes, log more details
        if rootThemes.count < 30 {
            Logger.themeService.warning("⚠️ Low root theme count detected: \(rootThemes.count)")
            Logger.themeService.info("📝 All root themes:")
            for (index, theme) in rootThemes.enumerated() {
                Logger.themeService.info("  \(index + 1). \(theme.name) (ID: \(theme.id))")
            }
        }
        
        return rootThemes
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
        let pageSize = AppConstants.API.maxPageSize // Use large page size to minimize API calls
        
        Logger.network.info("Starting theme fetch with pagination")
        
        while true {
            Logger.network.debug("Fetching themes page \(currentPage)")
            
            let themesResponse = try await LegoAPI.legoThemesList(
                page: currentPage,
                pageSize: pageSize,
                ordering: "id", // Ensure consistent ordering by ID
                apiConfiguration: apiClientConfig
            )
            
            let pageThemes = themesResponse.results
            allApiThemes.append(contentsOf: pageThemes)
            
            Logger.network.debug("Page \(currentPage): got \(pageThemes.count) themes (total so far: \(allApiThemes.count))")
            Logger.network.debug("API Response - Count: \(themesResponse.count), Next: \(themesResponse.next != nil ? "exists" : "null"), Previous: \(themesResponse.previous != nil ? "exists" : "null")")
            
            // If we got fewer themes than the page size, we've reached the end
            // OR if next is null, we've reached the end
            if pageThemes.count < pageSize || themesResponse.next == nil {
                Logger.network.info("Completed theme fetch: \(allApiThemes.count) themes across \(currentPage) pages")
                break
            }
            
            currentPage += 1
            
            // Safety check to prevent infinite loops
            if currentPage > 100 {
                Logger.network.error("⚠️ Theme fetch exceeded safety limit of 100 pages, stopping")
                break
            }
        }
        
        let apiThemes = allApiThemes
        
        // Add detailed logging for theme analysis
        Logger.themeService.info("📊 API Theme Analysis:")
        Logger.themeService.info("  Total themes from API: \(apiThemes.count)")
        
        let rootThemesFromAPI = apiThemes.filter { $0.parentId == nil }
        let childThemesFromAPI = apiThemes.filter { $0.parentId != nil }
        
        Logger.themeService.info("  Root themes (parentId == nil): \(rootThemesFromAPI.count)")
        Logger.themeService.info("  Child themes (parentId != nil): \(childThemesFromAPI.count)")
        
        // Log first 10 root themes for debugging
        Logger.themeService.info("🎯 First 10 root themes from API:")
        for (index, theme) in rootThemesFromAPI.prefix(10).enumerated() {
            Logger.themeService.info("  \(index + 1). \(theme.name) (ID: \(theme.id))")
        }
        
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
        
        // Log conversion results
        let localRootThemes = localThemes.filter { $0.isRootTheme }
        Logger.themeService.info("📱 Local Theme Analysis after conversion:")
        Logger.themeService.info("  Total local themes: \(localThemes.count)")
        Logger.themeService.info("  Local root themes: \(localRootThemes.count)")
        
        // Now establish parent-child relationships
        Logger.themeService.info("Establishing theme relationships...")
        try establishThemeRelationships()
        
        // Establish set-theme relationships
        Logger.themeService.info("Establishing set-theme relationships...")
        try establishSetThemeRelationships()
        
        // Final save after establishing relationships
        try modelContext.save()
        
        // Update sync timestamp
        lastThemeSyncDate = Date()
        saveLastThemeSyncDate()
        
        Logger.themeService.info("All relationships established successfully")
        Logger.themeService.info("✅ Theme sync completed at \(Date())")
        
        return localThemes
    }
    
    /// Check if theme data is fresh (less than 24 hours old)
    private func isThemeDataFresh() -> Bool {
        guard let lastSync = lastThemeSyncDate else { return false }
        let ageHours = Date().timeIntervalSince(lastSync) / AppConstants.TimeIntervals.secondsPerHour
        return ageHours < AppConstants.TimeIntervals.cacheSyncValidHours
    }
    
    /// Get the age of cached theme data in hours
    func getCacheAgeHours() -> Double? {
        guard let lastSync = lastThemeSyncDate else { return nil }
        return Date().timeIntervalSince(lastSync) / 3_600.0
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
