//
//  SearchViewModel.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@Observable
@MainActor
final class SearchViewModel {
    private let legoSetRepository: LegoSetRepository
    private let legoThemeRepository: LegoThemeRepository
    private let apiKeyManager: APIKeyManager
    
    var searchText = ""
    var searchResults: [LegoSet] = []
    var isSearching = false
    var error: BrixieError?
    var selectedFilter: SearchFilter = .all
    
    init(legoSetRepository: LegoSetRepository, legoThemeRepository: LegoThemeRepository, apiKeyManager: APIKeyManager) {
        self.legoSetRepository = legoSetRepository
        self.legoThemeRepository = legoThemeRepository
        self.apiKeyManager = apiKeyManager
    }
    
    func search(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchText = query
        isSearching = true
        error = nil
        
        defer { isSearching = false }
        
        do {
            switch selectedFilter {
            case .all, .sets:
                let results = try await legoSetRepository.searchSets(
                    query: query,
                    page: 1,
                    pageSize: 50
                )
                searchResults = results
            case .themes:
                let themes = try await legoThemeRepository.searchThemes(
                    query: query,
                    page: 1,
                    pageSize: 50
                )
                searchResults = []
            }
        } catch let brixieError as BrixieError {
            error = brixieError
            searchResults = []
        } catch {
            self.error = BrixieError.networkError(underlying: error)
            searchResults = []
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        error = nil
    }
    
    func toggleFavorite(for set: LegoSet) async {
        do {
            if set.isFavorite {
                try await legoSetRepository.removeFromFavorites(set)
            } else {
                try await legoSetRepository.markAsFavorite(set)
            }
            
            if let index = searchResults.firstIndex(where: { $0.id == set.id }) {
                searchResults[index].isFavorite.toggle()
            }
        } catch let brixieError as BrixieError {
            error = brixieError
        } catch {
            self.error = BrixieError.networkError(underlying: error)
        }
    }
    
    var hasAPIKey: Bool {
        apiKeyManager.hasValidAPIKey
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