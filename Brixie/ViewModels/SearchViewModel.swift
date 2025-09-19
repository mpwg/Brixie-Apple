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
    var query: String = ""
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
    
    // MARK: - Dependencies
    private let searchHistoryService: SearchHistoryService
    
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
        }
    }
    
    /// Filter sets based on current criteria
    func filterSets(from allSets: [LegoSet]) {
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
