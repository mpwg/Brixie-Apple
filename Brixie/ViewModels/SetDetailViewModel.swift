//
//  SetDetailViewModel.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData

/// ViewModel for SetDetailView following MVVM pattern
@Observable
@MainActor
final class SetDetailViewModel {
    // MARK: - Published State
    var showingMissingParts: Bool = false
    var error: BrixieError?
    
    // MARK: - Dependencies
    private let collectionService: CollectionService
    
    // MARK: - Initialization
    init(collectionService: CollectionService = CollectionService.shared) {
        self.collectionService = collectionService
    }
    
    // MARK: - Public Methods
    
    /// Toggle owned status of a set
    func toggleOwned(_ set: LegoSet, in modelContext: ModelContext) {
        // CollectionService.toggleOwned is non-throwing; call directly and clear any existing error.
        collectionService.toggleOwned(set, in: modelContext)
        error = nil
    }
    
    /// Toggle wishlist status of a set
    func toggleWishlist(_ set: LegoSet, in modelContext: ModelContext) {
        // CollectionService.toggleWishlist is non-throwing; call directly and clear any existing error.
        collectionService.toggleWishlist(set, in: modelContext)
        error = nil
    }
    
    /// Show missing parts view
    func showMissingParts() {
        showingMissingParts = true
    }
    
    /// Hide missing parts view
    func hideMissingParts() {
        showingMissingParts = false
    }
    
    /// Generate share text for a LEGO set
    func generateShareText(for set: LegoSet) -> String {
        return "Check out LEGO set \(set.name) (#\(set.setNumber)), released in \(set.year) with \(set.numParts) parts!"
    }
}