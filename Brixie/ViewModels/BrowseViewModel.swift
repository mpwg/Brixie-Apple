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
    
    // MARK: - Dependencies
    private let legoSetService: LegoSetService
    private let themeService: ThemeService
    
    // MARK: - Initialization
    init(legoSetService: LegoSetService = LegoSetService.shared, themeService: ThemeService = ThemeService.shared) {
        self.legoSetService = legoSetService
        self.themeService = themeService
    }
    
    // MARK: - Public Methods
    
    /// Configure the ViewModel with SwiftData context
    func configure(with modelContext: ModelContext) {
        legoSetService.configure(with: modelContext)
        themeService.configure(with: modelContext)
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
}