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
    
    // MARK: - Theme-specific Data
    private var themeSetsCache: [Int: [LegoSet]] = [:]
    var isLoadingThemeSets: Bool = false
    
    // MARK: - Pagination State
    /// Track the pagination state for each theme
    private var themePaginationState: [Int: PaginationState] = [:]
    
    /// Pagination state for a theme
    private struct PaginationState {
        let totalCount: Int
        var loadedCount: Int
        var nextURL: String?
        var isLoadingMore: Bool = false
        
        var hasMore: Bool { 
            loadedCount < totalCount && nextURL != nil 
        }
        
        var hasLoadedAll: Bool {
            loadedCount >= totalCount
        }
    }
    
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
        
        // Check cache first
        if let cachedSets = themeSetsCache[theme.id] {
            Logger.database.debug("setsForTheme(\(theme.name)): returning \(cachedSets.count) cached sets")
            
            // Update theme's loaded count if we have pagination state
            if let paginationState = themePaginationState[theme.id] {
                theme.loadedSetCount = paginationState.loadedCount
                Logger.database.debug("setsForTheme(\(theme.name)): updated loadedSetCount to \(theme.loadedSetCount)")
            }
            
            return cachedSets
        }
        
        // Try to find sets in allSets (for backward compatibility)
        Logger.database.debug("Total sets available: \(self.allSets.count)")
        
        // Log first few sets for debugging
        for (index, set) in self.allSets.prefix(5).enumerated() {
            Logger.database.debug("Set \(index): \(set.name) - themeId: \(set.themeId), theme?.id: \(set.theme?.id ?? -1)")
        }
        
        // Try relationship-based filter first, fallback to themeId
        let filteredSets = self.allSets.filter { 
            $0.theme?.id == theme.id || $0.themeId == theme.id
        }
        
        Logger.database.debug("setsForTheme(\(theme.name)): filtered \(filteredSets.count) sets from \(self.allSets.count) total sets")
        
        // Cache the result even if empty (to avoid repeated filtering)
        themeSetsCache[theme.id] = filteredSets
        
        // Initialize pagination state if we have sets but no pagination info
        if !filteredSets.isEmpty && themePaginationState[theme.id] == nil {
            // Use theme's totalSetCount if available, otherwise assume we have all sets
            let totalCount = theme.totalSetCount > 0 ? theme.totalSetCount : filteredSets.count
            themePaginationState[theme.id] = PaginationState(
                totalCount: totalCount,
                loadedCount: filteredSets.count,
                nextURL: totalCount > filteredSets.count ? "unknown" : nil
            )
            theme.loadedSetCount = filteredSets.count
        }
        
        // If no sets found, trigger async load
        if filteredSets.isEmpty {
            Logger.database.debug("setsForTheme(\(theme.name)): No sets found, triggering async load")
            Task {
                await loadSetsForTheme(theme)
            }
        }
        
        return filteredSets
    }
    
    /// Load sets for a specific theme from API
    func loadSetsForTheme(_ theme: Theme, limit: Int = 20) async {
        guard !isLoadingThemeSets else {
            Logger.database.debug("loadSetsForTheme(\(theme.name)): Already loading, skipping")
            return
        }
        
        isLoadingThemeSets = true
        Logger.database.debug("loadSetsForTheme(\(theme.name)): Starting API fetch")
        
        do {
            let result = try await legoSetService.fetchSetsWithPagination(forThemeId: theme.id, limit: limit)
            Logger.database.info("loadSetsForTheme(\(theme.name)): Fetched \(result.sets.count) sets from API, total: \(result.totalCount)")
            
            // Update theme model with total count
            theme.totalSetCount = result.totalCount
            theme.loadedSetCount = result.sets.count
            
            // Initialize pagination state
            themePaginationState[theme.id] = PaginationState(
                totalCount: result.totalCount,
                loadedCount: result.sets.count,
                nextURL: result.sets.count < result.totalCount ? "next" : nil
            )
            
            // Update cache
            themeSetsCache[theme.id] = result.sets
            
            // Add to allSets if not already present
            for set in result.sets {
                if !allSets.contains(where: { $0.setNumber == set.setNumber }) {
                    allSets.append(set)
                }
            }
            
            Logger.database.debug("loadSetsForTheme(\(theme.name)): Updated cache and pagination state with \(result.sets.count)/\(result.totalCount) sets")
            
        } catch {
            Logger.database.error("loadSetsForTheme(\(theme.name)): Failed to fetch sets - \(error)")
            self.error = BrixieError.from(error)
        }
        
        isLoadingThemeSets = false
    }
    
    // MARK: - Pagination Methods
    
    /// Check if more sets can be loaded for a theme
    func canLoadMoreSets(for theme: Theme) -> Bool {
        guard let paginationState = themePaginationState[theme.id] else {
            // No pagination state means we haven't loaded anything yet
            return theme.totalSetCount == 0 || theme.totalSetCount > (themeSetsCache[theme.id]?.count ?? 0)
        }
        return paginationState.hasMore
    }
    
    /// Check if we're currently loading more sets for a theme
    func isLoadingMoreSets(for theme: Theme) -> Bool {
        return themePaginationState[theme.id]?.isLoadingMore == true
    }
    
    /// Load more sets for endless scrolling
    func loadMoreSetsForTheme(_ theme: Theme) async {
        guard canLoadMoreSets(for: theme) else {
            Logger.database.debug("loadMoreSetsForTheme(\(theme.name)): Cannot load more sets")
            return
        }
        
        guard let paginationState = themePaginationState[theme.id], !paginationState.isLoadingMore else {
            Logger.database.debug("loadMoreSetsForTheme(\(theme.name)): Already loading more")
            return
        }
        
        // Update state to show we're loading more
        themePaginationState[theme.id]?.isLoadingMore = true
        
        Logger.database.debug("loadMoreSetsForTheme(\(theme.name)): Loading more sets, current count: \(paginationState.loadedCount)/\(paginationState.totalCount)")
        
        do {
            // Calculate offset for pagination
            let offset = paginationState.loadedCount
            let result = try await legoSetService.fetchSetsWithPagination(forThemeId: theme.id, limit: 20, offset: offset)
            
            Logger.database.info("loadMoreSetsForTheme(\(theme.name)): Fetched \(result.sets.count) additional sets")
            
            // Append to existing cache
            var existingSets = themeSetsCache[theme.id] ?? []
            let newSets = result.sets.filter { newSet in
                !existingSets.contains { $0.setNumber == newSet.setNumber }
            }
            existingSets.append(contentsOf: newSets)
            themeSetsCache[theme.id] = existingSets
            
            // Update pagination state
            let newLoadedCount = existingSets.count
            let hasMore = newLoadedCount < result.totalCount && !result.sets.isEmpty
            
            themePaginationState[theme.id] = PaginationState(
                totalCount: result.totalCount,
                loadedCount: newLoadedCount,
                nextURL: hasMore ? "next" : nil,
                isLoadingMore: false
            )
            
            // Update theme model
            theme.totalSetCount = result.totalCount
            theme.loadedSetCount = newLoadedCount
            
            // Add to allSets if not already present
            for set in newSets {
                if !allSets.contains(where: { $0.setNumber == set.setNumber }) {
                    allSets.append(set)
                }
            }
            
            Logger.database.debug("loadMoreSetsForTheme(\(theme.name)): Now have \(newLoadedCount)/\(result.totalCount) sets")
            
        } catch {
            Logger.database.error("loadMoreSetsForTheme(\(theme.name)): Failed to load more sets - \(error)")
            themePaginationState[theme.id]?.isLoadingMore = false
            self.error = BrixieError.from(error)
        }
    }
    
    /// Get sets for a specific subtheme
    func setsForSubtheme(_ subtheme: Theme) -> [LegoSet] {
        Logger.database.debug("setsForSubtheme(\(subtheme.name)) - Subtheme ID: \(subtheme.id)")
        
        // Use both relationship and themeId for filtering
        let filteredSets = self.allSets.filter { 
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
        Logger.viewCycle.info("MainContentView appeared - selectedTheme: \(self.selectedTheme?.name ?? "nil")")
    }
    
    /// Clear cached themes data
    func clearCachedThemes() async {
        do {
            try themeService.clearCachedThemes()
        } catch {
            Logger.error.error("Failed to clear themes: \(error.localizedDescription)")
        }
    }
}