//
//  SearchViewModel.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@Observable
@MainActor
final class SearchViewModel: ViewModelErrorHandling {
    private let legoSetRepository: LegoSetRepository
    private let legoThemeRepository: LegoThemeRepository
    private let recentSearchesStorage: RecentSearchesStorage
    
    var searchText = ""
    var searchResults: [LegoSet] = []
    var isSearching = false
    var error: BrixieError?
    var selectedFilter: SearchFilter = .all
    var recentSearches: [String] = []
    var showingNoResults = false
    
    init(legoSetRepository: LegoSetRepository, legoThemeRepository: LegoThemeRepository, recentSearchesStorage: RecentSearchesStorage = .shared) {
        self.legoSetRepository = legoSetRepository
        self.legoThemeRepository = legoThemeRepository
        self.recentSearchesStorage = recentSearchesStorage
        
        // Load recent searches from storage
        self.recentSearches = recentSearchesStorage.loadRecentSearches()
    }
    
    func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearResults()
            return
        }
        
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add to recent searches and persist
        recentSearchesStorage.addSearch(trimmedSearch)
        recentSearches = recentSearchesStorage.loadRecentSearches()
        
        isSearching = true
        showingNoResults = false
        error = nil
        
        defer { isSearching = false }
        
        do {
            let results = try await legoSetRepository.searchSets(
                query: trimmedSearch,
                page: 1,
                pageSize: 50
            )
            searchResults = results
            showingNoResults = results.isEmpty
        } catch {
            handleError(error)
            searchResults = []
            showingNoResults = true
        }
    }
    
    func search(_ query: String) async {
        searchText = query
        await performSearch()
    }
    
    func clearResults() {
        searchResults = []
        showingNoResults = false
        error = nil
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        error = nil
    }
    
    // Method for manually testing persistence
    func addManualSearch(_ search: String) {
        recentSearchesStorage.addSearch(search)
        recentSearches = recentSearchesStorage.loadRecentSearches()
    }
    
    // Method to clear recent searches for testing
    func clearRecentSearches() {
        recentSearchesStorage.clearRecentSearches()
        recentSearches = []
    }
    
    func toggleFavorite(for set: LegoSet) async {
        do {
            try await toggleFavoriteOnRepository(set: set, repository: legoSetRepository)
            if let index = searchResults.firstIndex(where: { $0.id == set.id }) {
                searchResults[index].isFavorite.toggle()
            }
        } catch {
            handleError(error)
        }
    }
    
    
    var hasResults: Bool {
        !searchResults.isEmpty
    }
    
    var showEmptyState: Bool {
        !isSearching && searchText.isEmpty
    }
    
    var showNoResults: Bool {
        !isSearching && !searchText.isEmpty && searchResults.isEmpty
    }
}

enum SearchFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case sets = "sets"
    case themes = "themes"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all:
            return NSLocalizedString("All", comment: "Search filter: All")
        case .sets:
            return NSLocalizedString("Sets", comment: "Search filter: Sets")
        case .themes:
            return NSLocalizedString("Themes", comment: "Search filter: Themes")
        }
    }
}
