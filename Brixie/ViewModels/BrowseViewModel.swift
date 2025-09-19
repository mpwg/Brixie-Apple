//
//  BrowseViewModel.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData
import OSLog

/// ViewModel for BrowseView following MVVM pattern
@Observable
@MainActor
final class BrowseViewModel {
    // MARK: - Published State
    var isLoading: Bool = false
    var error: BrixieError?
    var lastRefreshDate: Date?
    
    // MARK: - Navigation State
    var selectedTheme: Theme?
    var selectedSubtheme: Theme?
    
    // MARK: - Data References
    private var allThemes: [Theme] = []
    private var allSets: [LegoSet] = []
    
    // MARK: - Dependencies
    private let legoSetService: LegoSetService
    private let themeService: ThemeService
    
    // MARK: - Initialization
    init(legoSetService: LegoSetService = LegoSetService.shared, themeService: ThemeService = ThemeService.shared) {
        self.legoSetService = legoSetService
        self.themeService = themeService
    }
    
    // MARK: - Public Methods
    
    /// Configure the ViewModel with SwiftData context and data
    func configure(with modelContext: ModelContext, themes: [Theme] = [], sets: [LegoSet] = []) {
        legoSetService.configure(with: modelContext)
        themeService.configure(with: modelContext)
        self.allThemes = themes
        self.allSets = sets
    }
    
    /// Load themes and LEGO sets from API or cache
    func loadInitialData() async {
        guard !isLoading else { return }
        
        Logger.viewCycle.entering()
        isLoading = true
        error = nil
        defer { 
            isLoading = false 
            Logger.viewCycle.exitWith()
        }
        
        do {
            // Load themes first, then sets - sequential to avoid concurrency issues
            Logger.themeService.info("Loading themes...")
            let themes = try await themeService.fetchThemes()
            Logger.themeService.info("Loaded \(themes.count) themes")
            
            Logger.legoSetService.info("Loading sets...")
            let sets = try await legoSetService.fetchSets()
            Logger.legoSetService.info("Loaded \(sets.count) sets")
            
            lastRefreshDate = Date()
        } catch {
            Logger.error.error("Error during loadInitialData: \(error.localizedDescription, privacy: .public)")
            self.error = BrixieError.from(error)
        }
    }
    
    /// Load LEGO sets from API or cache
    func loadSets() async {
        await loadInitialData()
    }
    
    /// Refresh data
    func refresh() async {
        await loadInitialData()
    }
    
    /// Force refresh all data from API (ignores cache)
    func forceRefresh() async {
        guard !isLoading else { return }
        
        Logger.viewCycle.entering()
        isLoading = true
        error = nil
        defer { 
            isLoading = false 
            Logger.viewCycle.exitWith()
        }
        
        do {
            // Force refresh themes from API
            Logger.themeService.info("Force refreshing themes from API...")
            let themes = try await themeService.forceRefreshThemes()
            Logger.themeService.info("Force refreshed \(themes.count) themes from API")
            
            // Refresh sets as well
            Logger.legoSetService.info("Refreshing sets...")
            let sets = try await legoSetService.fetchSets()
            Logger.legoSetService.info("Refreshed \(sets.count) sets")
            
            lastRefreshDate = Date()
        } catch {
            Logger.error.error("Error during forceRefresh: \(error.localizedDescription, privacy: .public)")
            self.error = BrixieError.from(error)
        }
    }
    
    // MARK: - Theme Navigation
    
    /// Select a root theme and show its subthemes or sets
    func selectTheme(_ theme: Theme) {
        Logger.navigation.userAction("selectTheme", context: ["themeId": theme.id, "themeName": theme.name])
        selectedTheme = theme
        selectedSubtheme = nil
    }
    
    /// Select a subtheme and show its sets
    func selectSubtheme(_ subtheme: Theme) {
        Logger.navigation.userAction("selectSubtheme", context: ["subthemeId": subtheme.id, "subthemeName": subtheme.name])
        selectedSubtheme = subtheme
    }
    
    /// Clear theme selection and return to theme list
    func clearSelection() {
        Logger.navigation.userAction("clearThemeSelection")
        selectedTheme = nil
        selectedSubtheme = nil
    }
    
    // MARK: - Data Processing
    
    /// Get filtered root themes based on search text
    func filteredRootThemes(searchText: String) -> [Theme] {
        let rootThemes = allThemes.filter { $0.isRootTheme }
        
        if !rootThemes.isEmpty {
            let themeNames = rootThemes.prefix(5).map { "\($0.name) (ID: \($0.id), subthemes: \($0.subthemes.count), sets: \($0.sets.count))" }.joined(separator: ", ")
            Logger.database.debug("First 5 root themes: \(themeNames)")
        }
        
        if searchText.isEmpty {
            let sorted = rootThemes.sorted { $0.name < $1.name }
            Logger.search.debug("No search filter - returning \(sorted.count) root themes")
            return sorted
        } else {
            let filtered = rootThemes
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
            Logger.search.debug("Search '\(searchText, privacy: .private)' returned \(filtered.count) themes")
            return filtered
        }
    }
    
    /// Get sets for a specific theme
    func setsForTheme(_ theme: Theme) -> [LegoSet] {
        Logger.database.debug("setsForTheme(\(theme.name)) - Theme ID: \(theme.id)")
        Logger.database.debug("Total sets available: \(allSets.count)")
        
        // Log first few sets for debugging
        for (index, set) in allSets.prefix(5).enumerated() {
            Logger.database.debug("Set \(index): \(set.name) - themeId: \(set.themeId), theme?.id: \(set.theme?.id ?? -1)")
        }
        
        // Try relationship-based filter first, fallback to themeId
        let filteredSets = allSets.filter { 
            $0.theme?.id == theme.id || $0.themeId == theme.id
        }
        
        Logger.database.debug("setsForTheme(\(theme.name)): filtered \(filteredSets.count) sets from \(allSets.count) total sets")
        
        return filteredSets
    }
    
    /// Get sets for a specific subtheme
    func setsForSubtheme(_ subtheme: Theme) -> [LegoSet] {
        Logger.database.debug("setsForSubtheme(\(subtheme.name)) - Subtheme ID: \(subtheme.id)")
        
        // Use both relationship and themeId for filtering
        let filteredSets = allSets.filter { 
            $0.theme?.id == subtheme.id || $0.themeId == subtheme.id
        }
        
        Logger.database.debug("setsForSubtheme(\(subtheme.name)): filtered \(filteredSets.count) sets")
        
        return filteredSets
    }
    
    /// Log theme selection details
    func logThemeDetails(_ theme: Theme) {
        Logger.database.debug("Selected theme \(theme.name): hasSubthemes=\(theme.hasSubthemes), subthemes.count=\(theme.subthemes.count), sets.count=\(theme.sets.count)")
    }
    
    /// Log theme statistics for debugging
    func logThemeStatistics() {
        Task {
            do {
                let stats = try themeService.getThemeStatistics()
                Logger.database.info("Theme Stats - Total: \(stats.totalThemes), Root: \(stats.rootThemes), Fresh: \(stats.isDataFresh)")
                if let lastSync = stats.lastSyncDate {
                    Logger.database.debug("Last theme sync: \(lastSync.formatted())")
                }
            } catch {
                Logger.error.error("Failed to get theme statistics: \(error)")
            }
        }
    }
    
    /// Log main content view appearance
    func logMainContentViewAppearance() {
        Logger.viewCycle.info("MainContentView appeared - selectedTheme: \(selectedTheme?.name ?? "nil", privacy: .private)")
    }
    
    /// Clear cached themes data
    func clearCachedThemes() async {
        do {
            try await themeService.clearAllThemes()
        } catch {
            Logger.error.error("Failed to clear themes: \(error.localizedDescription, privacy: .public)")
        }
    }
}