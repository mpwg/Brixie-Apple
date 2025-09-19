//
//  WishlistViewModel.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData

/// ViewModel for WishlistView following MVVM pattern
@Observable
@MainActor
final class WishlistViewModel {
    // MARK: - Published State
    var searchText: String = ""
    var selectedSortOption: WishlistSortOption = .dateAdded
    var showingShareSheet: Bool = false
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
    
    /// Show share sheet
    func showShareSheet() {
        showingShareSheet = true
    }
    
    /// Hide share sheet
    func hideShareSheet() {
        showingShareSheet = false
    }
    
    /// Filter wishlisted sets by search text
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
    
    /// Apply sorting to sets
    func sortSets(_ sets: [LegoSet]) -> [LegoSet] {
        switch selectedSortOption {
        case .dateAdded:
            return sets.sorted { ($0.userCollection?.dateAdded ?? Date.distantPast) > ($1.userCollection?.dateAdded ?? Date.distantPast) }
        case .name:
            return sets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .year:
            return sets.sorted { $0.year > $1.year }
        case .parts:
            return sets.sorted { $0.numParts > $1.numParts }
        case .theme:
            return sets.sorted { ($0.theme?.name ?? "") < ($1.theme?.name ?? "") }
        }
    }
}

/// Sort options for wishlist
enum WishlistSortOption: String, CaseIterable {
    case dateAdded = "dateAdded"
    case name = "name"
    case year = "year"
    case parts = "parts"
    case theme = "theme"
    
    var title: String {
        switch self {
        case .dateAdded: return "Date Added"
        case .name: return "Name"
        case .year: return "Year"
        case .parts: return "Parts"
        case .theme: return "Theme"
        }
    }
    
    var icon: String {
        switch self {
        case .dateAdded: return "clock"
        case .name: return "textformat"
        case .year: return "calendar"
        case .parts: return "cube.box"
        case .theme: return "folder"
        }
    }
}
