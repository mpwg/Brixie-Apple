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
    
    /// Fetch all themes from API or local cache
    func fetchThemes() async throws -> [Theme] {
        guard modelContext != nil else {
            throw ThemeServiceError.notConfigured
        }
        
        guard apiConfig.isConfigured else {
            throw ThemeServiceError.apiNotConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Try to get cached themes first
        let cachedThemes = try fetchCachedThemes()
        
        // If we have fresh data, return it
        if isThemeDataFresh() && !cachedThemes.isEmpty {
            return cachedThemes
        }
        
        // Otherwise fetch from API
        do {
            let apiThemes = try await fetchThemesFromAPI()
            lastThemeSyncDate = Date()
            saveLastThemeSyncDate()
            return apiThemes
        } catch {
            currentError = error
            // Return cached data if API fails
            if !cachedThemes.isEmpty {
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
        
        // Fetch themes from API
        let themesResponse = try await LegoAPI.legoThemesList(
            page: nil,
            pageSize: nil,
            ordering: nil,
            apiConfiguration: apiClientConfig
        )
        let apiThemes = themesResponse.results
        
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
        
        // Save changes
        try modelContext.save()
        
        return localThemes
    }
    
    /// Check if theme data is fresh (less than 24 hours old)
    private func isThemeDataFresh() -> Bool {
        guard let lastSync = lastThemeSyncDate else { return false }
        return Date().timeIntervalSince(lastSync) < 24 * 60 * 60 // 24 hours
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