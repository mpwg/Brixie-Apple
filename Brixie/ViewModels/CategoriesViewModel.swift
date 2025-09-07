//
//  CategoriesViewModel.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@Observable
@MainActor
final class CategoriesViewModel: ViewModelErrorHandling {
    private let legoThemeRepository: LegoThemeRepository
    
    var themes: [LegoTheme] = []
    var filteredThemes: [LegoTheme] = []
    var searchText = "" {
        didSet {
            updateFilteredThemes()
        }
    }
    var isLoading = false
    var error: BrixieError?
    
    init(legoThemeRepository: LegoThemeRepository) {
        self.legoThemeRepository = legoThemeRepository
    }
    
    func loadThemes() async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            themes = try await legoThemeRepository.fetchThemes(page: 1, pageSize: 100)
            updateFilteredThemes()
        } catch {
            handleError(error)
            themes = await legoThemeRepository.getCachedThemes()
            updateFilteredThemes()
        }
    }
    
    func searchThemes(_ query: String) async {
        searchText = query
        
        guard !query.isEmpty else {
            updateFilteredThemes()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let searchResults = try await legoThemeRepository.searchThemes(
                query: query,
                page: 1,
                pageSize: 50
            )
            filteredThemes = searchResults
        } catch {
            updateFilteredThemes()
        }
    }
    
    private func updateFilteredThemes() {
        if searchText.isEmpty {
            filteredThemes = themes
        } else {
            filteredThemes = themes.filter { theme in
                theme.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    
    var cachedThemesAvailable: Bool {
        !themes.isEmpty
    }
}
