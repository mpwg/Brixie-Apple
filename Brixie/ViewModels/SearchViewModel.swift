//
//  SearchViewModel.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData
import OSLog

/// ViewModel for SearchView following MVVM pattern
@Observable
@MainActor
final class SearchViewModel {
    // MARK: - Published State
    var query: String = "" {
        didSet {
            // Trigger debounced search when query changes
            debouncedSearch()
        }
    }
    var selectedThemes: Set<Int> = []
    var minYear: Int = 1_958
    var maxYear: Int = Calendar.current.component(.year, from: Date())
    var minParts: Int = 1
    var maxParts: Int = 10_000
    var useYearFilter: Bool = false
    var usePartsFilter: Bool = false
    var showingSuggestions: Bool = false
    var filteredResults: [LegoSet] = []
    var showingBarcodeScanner: Bool = false
    var isSearching: Bool = false
    
    // MARK: - Dependencies
    private let searchHistoryService: SearchHistoryService
    private let logger = Logger(subsystem: "com.brixie", category: "SearchViewModel")
    
    // MARK: - Debouncing Properties
    private var searchTask: Task<Void, Never>?
    private let searchDebounceInterval: TimeInterval = 0.3 // 300ms debounce
    
    // MARK: - Initialization
    init(searchHistoryService: SearchHistoryService = SearchHistoryService.shared) {
        self.searchHistoryService = searchHistoryService
    }
    
    // MARK: - Public Methods
    
    /// Get search suggestions for current query
    func getSuggestions(for text: String = "") -> [String] {
        let searchText = text.isEmpty ? query : text
        return searchHistoryService.getSuggestions(for: searchText)
    }
    
    /// Submit search query and add to history
    func submitSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            searchHistoryService.addToHistory(trimmed)
            // Perform immediate search when submitted
            performSearch(query: trimmed)
        }
    }
    
    /// Filter sets based on current criteria (synchronous version for immediate filtering)
    func filterSets(from allSets: [LegoSet]) {
        logger.debug("Filtering \(allSets.count) sets with query: '\(self.query)'")
        
        var results = allSets
        
        // Filter by search query
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            results = results.filter { set in
                set.name.localizedStandardContains(trimmed) ||
                set.setNumber.localizedStandardContains(trimmed) ||
                set.theme?.name.localizedStandardContains(trimmed) == true
            }
        }
        
        // Filter by selected themes
        if !selectedThemes.isEmpty {
            results = results.filter { set in
                guard let themeId = set.theme?.id else { return false }
                return selectedThemes.contains(themeId)
            }
        }
        
        // Filter by year range
        if useYearFilter {
            results = results.filter { set in
                set.year >= minYear && set.year <= maxYear
            }
        }
        
        // Filter by parts count
        if usePartsFilter {
            results = results.filter { set in
                set.numParts >= minParts && set.numParts <= maxParts
            }
        }
        
        filteredResults = results
        logger.debug("Filtered results: \(results.count) sets")
    }
    
    /// Clear all filters
    func clearFilters() {
        selectedThemes.removeAll()
        useYearFilter = false
        usePartsFilter = false
        minYear = 1_958
        maxYear = Calendar.current.component(.year, from: Date())
        minParts = 1
        maxParts = 10_000
    }
    
    /// Check if any filters are active
    var hasActiveFilters: Bool {
        return !selectedThemes.isEmpty || useYearFilter || usePartsFilter
    }
    
    // MARK: - Debounced Search
    
    /// Trigger a debounced search operation
    private func debouncedSearch() {
        // Cancel any existing search task
        searchTask?.cancel()
        
        let currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If query is empty, clear results immediately
        if currentQuery.isEmpty {
            filteredResults.removeAll()
            isSearching = false
            return
        }
        
        // Start debounced search task
        searchTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Wait for debounce interval
                try await Task.sleep(for: .milliseconds(Int(searchDebounceInterval * 1000)))
                
                // Check if task was cancelled during sleep
                guard !Task.isCancelled else { return }
                
                // Perform the actual search
                self.performSearch(query: currentQuery)
                
            } catch {
                // Task was cancelled or failed
                if !Task.isCancelled {
                    self.logger.error("Search task failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Perform the actual search operation
    private func performSearch(query searchQuery: String) {
        logger.debug("Performing search for: '\(searchQuery)'")
        isSearching = true
        
        // This would typically involve an API call or database query
        // For now, we'll simulate search by filtering available data
        // In a real implementation, this would call LegoSetService to search
        
        // Simulate network delay for demonstration
        Task { @MainActor in
            // In real implementation, replace this with actual search logic
            // For now, just clear the searching state
            isSearching = false
        }
    }
    
    /// Cancel any ongoing search operations
    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
    }
    
    // MARK: - Barcode Scanner
    
    /// Show barcode scanner
    func showBarcodeScanner() {
        showingBarcodeScanner = true
    }
    
    /// Handle barcode scan result
    func handleBarcodeResult(_ barcode: String, with allSets: [LegoSet]) {
        Logger.search.info("Scanned barcode: \(barcode)")
        query = barcode
        showingBarcodeScanner = false
        submitSearch()
        filterSets(from: allSets)
    }
}
