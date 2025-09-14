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
    
    // Debounce configuration
    private var searchTask: Task<Void, Never>?
    private let debounceDelay: TimeInterval
    
    var searchText = ""
    var searchResults: [LegoSet] = []
    var isSearching = false
    var error: BrixieError?
    var selectedFilter: SearchFilter = .all
    var recentSearches: [String] = []
    var showingNoResults = false
    var lastSyncTimestamp: SyncTimestamp?
    

    init(
        legoSetRepository: LegoSetRepository,
        legoThemeRepository: LegoThemeRepository,
        recentSearchesStorage: RecentSearchesStorage = .shared, 
      debounceDelay: TimeInterval = 0.4
    ) {
        self.legoSetRepository = legoSetRepository
        self.legoThemeRepository = legoThemeRepository
        self.recentSearchesStorage = recentSearchesStorage
        self.debounceDelay = debounceDelay
        
        // Load recent searches from storage
        self.recentSearches = recentSearchesStorage.loadRecentSearches()
    }
    
    deinit {
        searchTask?.cancel()
    }
    
    // MARK: - Search Methods
    
    /// Performs an immediate search without debouncing (for manual submit)
    func performImmediateSearch() async {
        // Cancel any pending debounced search
        searchTask?.cancel()
        searchTask = nil
        
        await performSearch()
    }
    
    /// Performs a debounced search - cancels previous searches and waits for delay
    func performDebouncedSearch() {
        // Cancel previous search task
        searchTask?.cancel()
        
        // Don't start new search if text is empty
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            clearResults()
            return
        }
        
        // Create new search task with debounce delay
        searchTask = Task { [weak self] in
            guard let self = self else { return }
            // Wait for debounce delay
            try? await Task.sleep(nanoseconds: UInt64(self.debounceDelay * 1_000_000_000))
            
            // Check if task was cancelled during delay
            guard !Task.isCancelled else { return }
            
            // Perform the actual search
            await self.performSearch()
        }
    }
    
    /// Core search implementation - performs the actual API call
    private func performSearch() async {
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
        
        defer { 
            isSearching = false
            updateLastSyncTimestamp()
        }
        
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
        await performImmediateSearch()
    }
    
    func clearResults() {
        searchResults = []
        showingNoResults = false
        error = nil
        
        // Cancel any pending search
        searchTask?.cancel()
        searchTask = nil
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        error = nil
        
        // Cancel any pending search
        searchTask?.cancel()
        searchTask = nil
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
    
    func retrySearch() async {
        await performSearch()
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
    
    private func updateLastSyncTimestamp() {
        Task {
            lastSyncTimestamp = await legoSetRepository.getLastSyncTimestamp(for: .search)
        }
    }
}

enum SearchFilter: String, CaseIterable, Identifiable {
    case all
    case sets
    case themes
    
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
