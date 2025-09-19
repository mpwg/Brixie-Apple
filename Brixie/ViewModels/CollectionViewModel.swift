//
//  CollectionViewModel.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData

/// ViewModel for collection-related views following MVVM pattern
@Observable
@MainActor
final class CollectionViewModel {
    // MARK: - Published State
    var selectedSortOption: CollectionSortOption = .dateAdded
    var showingStats: Bool = false
    var showingExportSheet: Bool = false
    var searchText: String = ""
    var error: BrixieError?
    
    // MARK: - Dependencies
    private let collectionService: CollectionService
    
    // MARK: - Initialization
    init(collectionService: CollectionService = CollectionService.shared) {
        self.collectionService = collectionService
    }
    
    // MARK: - Public Methods
    
    /// Get collection statistics
    func getCollectionStats(from modelContext: ModelContext) -> CollectionStats {
        return collectionService.getCollectionStats(from: modelContext)
    }
    
    /// Show statistics view
    func showStatistics() {
        showingStats = true
    }
    
    /// Hide statistics view
    func hideStatistics() {
        showingStats = false
    }
    
    /// Show export sheet
    func showExport() {
        showingExportSheet = true
    }
    
    /// Hide export sheet
    func hideExport() {
        showingExportSheet = false
    }
    
    /// Filter sets by search text
    func filterSets(_ sets: [LegoSet]) -> [LegoSet] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return sets
        }
        
        return sets.filter { set in
            set.name.localizedStandardContains(trimmed) ||
            set.setNumber.localizedStandardContains(trimmed) ||
            set.theme?.name.localizedStandardContains(trimmed) == true
        }
    }
}

/// Sort options for collection views
enum CollectionSortOption: String, CaseIterable {
    case name = "name"
    case year = "year"
    case parts = "parts"
    case dateAdded = "dateAdded"
    case value = "value"
    
    var title: String {
        switch self {
        case .name: return "Name"
        case .year: return "Year"
        case .parts: return "Parts"
        case .dateAdded: return "Date Added"
        case .value: return "Value"
        }
    }
    
    var icon: String {
        switch self {
        case .name: return "textformat"
        case .year: return "calendar"
        case .parts: return "cube.box"
        case .dateAdded: return "clock"
        case .value: return "dollarsign.circle"
        }
    }
}