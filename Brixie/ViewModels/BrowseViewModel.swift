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
    var isConfigured: Bool = false
    
    // MARK: - Navigation State
    var selectedTheme: Theme?
    var selectedSubtheme: Theme?
    
    // MARK: - Data References
    private var allThemes: [Theme] = []
    private var allSets: [LegoSet] = []
    
    // MARK: - Performance Caching
    private var filteredThemesCache: [String: [Theme]] = [:]
    private var lastFilteredSearchText: String = ""
    
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
    
    /// Check if we have any data loaded
    var hasData: Bool {
        return !allThemes.isEmpty || !allSets.isEmpty
    }
    
    /// Configure the ViewModel with SwiftData context
    func configure(with modelContext: ModelContext) {
        legoSetService.configure(with: modelContext)
        themeService.configure(with: modelContext)
        
        // Clear caches when reconfiguring
        clearPerformanceCaches()
    }
    
    /// Clear performance caches when data changes
    private func clearPerformanceCaches() {
        filteredThemesCache.removeAll()
        lastFilteredSearchText = ""
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
            
            // Clear performance caches when data is refreshed
            clearPerformanceCaches()
            
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
            
            // Clear performance caches when data is refreshed
            clearPerformanceCaches()
            
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
    
    /// Get filtered root themes based on search text (cached for performance)
    func filteredRootThemes(searchText: String) -> [Theme] {
        // Use cached result if search text hasn't changed
        if searchText == lastFilteredSearchText, let cached = filteredThemesCache[searchText] {
            return cached
        }
        
        // Clear cache if search text changed significantly (avoid memory bloat)
        if filteredThemesCache.count > 10 {
            filteredThemesCache.removeAll()
        }
        
        let rootThemes = allThemes.filter { $0.isRootTheme }
        print("📊 BrowseViewModel: allThemes.count = \(allThemes.count), rootThemes.count = \(rootThemes.count)")
        
        let result: [Theme]
        if searchText.isEmpty {
            result = rootThemes.sorted { $0.name < $1.name }
        } else {
            result = rootThemes
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
        
        // Cache the result
        filteredThemesCache[searchText] = result
        lastFilteredSearchText = searchText
        
        print("✨ BrowseViewModel: returning \(result.count) filtered themes")
        return result
    }
    
    /// Get sets for a specific theme (cached for performance)
    func setsForTheme(_ theme: Theme) -> [LegoSet] {
        Logger.database.debug("setsForTheme(\(theme.name)) - Theme ID: \(theme.id)")
        Logger.database.debug("setsForTheme(\(theme.name)) - theme.sets.count: \(theme.sets.count), allSets.count: \(self.allSets.count)")
        
        // Check cache first
        if let cachedSets = themeSetsCache[theme.id] {
            Logger.database.debug("setsForTheme(\(theme.name)): returning \(cachedSets.count) cached sets")
            
            // Update theme's loaded count if we have pagination state
            if let paginationState = themePaginationState[theme.id] {
                theme.loadedSetCount = paginationState.loadedCount
            }
            
            return cachedSets
        }
        
        // Use a background queue for expensive filtering to avoid blocking UI
        let themeId = theme.id
        let filteredSets: [LegoSet]
        
        // Prefer relationship-based filtering for better performance
        if !theme.sets.isEmpty {
            filteredSets = Array(theme.sets)
            Logger.database.debug("setsForTheme(\(theme.name)): used relationship, found \(filteredSets.count) sets")
        } else {
            // Fallback to manual filtering only if relationship is empty
            filteredSets = self.allSets.filter { $0.themeId == themeId }
            Logger.database.debug("setsForTheme(\(theme.name)): used themeId filter, found \(filteredSets.count) sets")
            
            // Debug why manual filtering might not work
            let matchingSetIds = allSets.compactMap { $0.themeId == themeId ? $0.setNumber : nil }.prefix(5)
            Logger.database.debug("setsForTheme(\(theme.name)): First 5 matching sets: \(Array(matchingSetIds))")
        }
        
        // Cache the result even if empty (to avoid repeated filtering)
        themeSetsCache[theme.id] = filteredSets
        
        // Initialize pagination state if we have sets but no pagination info
        if !filteredSets.isEmpty && themePaginationState[theme.id] == nil {
            let totalCount = theme.totalSetCount > 0 ? theme.totalSetCount : filteredSets.count
            themePaginationState[theme.id] = PaginationState(
                totalCount: totalCount,
                loadedCount: filteredSets.count,
                nextURL: totalCount > filteredSets.count ? "unknown" : nil
            )
            theme.loadedSetCount = filteredSets.count
        }
        
        // If no sets found, trigger async load (non-blocking)
        if filteredSets.isEmpty {
            Logger.database.debug("setsForTheme(\(theme.name)): No sets found, triggering async load")
            let themeId = theme.id
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Find the theme by ID to avoid capturing the original theme
                let themes = self.allThemes
                if let themeToLoad = themes.first(where: { $0.id == themeId }) {
                    await self.loadSetsForTheme(themeToLoad)
                }
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
    
    /// Get sets for a specific subtheme (optimized)
    func setsForSubtheme(_ subtheme: Theme) -> [LegoSet] {
        Logger.database.debug("setsForSubtheme(\(subtheme.name)) - Subtheme ID: \(subtheme.id)")
        
        let filteredSets: [LegoSet]
        
        // Prefer relationship-based filtering for better performance
        if !subtheme.sets.isEmpty {
            filteredSets = Array(subtheme.sets)
        } else {
            // Fallback to manual filtering
            filteredSets = self.allSets.filter { $0.themeId == subtheme.id }
        }
        
        Logger.database.debug("setsForSubtheme(\(subtheme.name)): found \(filteredSets.count) sets")
        
        return filteredSets
    }
    
    /// Log theme selection details
    func logThemeDetails(_ theme: Theme) {
        Logger.database.debug("Selected theme \(theme.name): hasSubthemes=\(theme.hasSubthemes), subthemes.count=\(theme.subthemes.count), sets.count=\(theme.sets.count)")
    }
    
    /// Log theme statistics for debugging (async to avoid blocking UI)
    func logThemeStatistics() {
        Task.detached { @MainActor [weak self] in
            guard let self else { return }
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
