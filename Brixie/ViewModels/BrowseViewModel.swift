//
//  BrowseViewModel.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData

/// ViewModel for BrowseView following MVVM pattern
@Observable
@MainActor
final class BrowseViewModel {
    // MARK: - Published State
    var isLoading: Bool = false
    var error: BrixieError?
    var lastRefreshDate: Date?
    
    // MARK: - Dependencies
    private let legoSetService: LegoSetService
    
    // MARK: - Initialization
    init(legoSetService: LegoSetService = LegoSetService.shared) {
        self.legoSetService = legoSetService
    }
    
    // MARK: - Public Methods
    
    /// Configure the ViewModel with SwiftData context
    func configure(with modelContext: ModelContext) {
        legoSetService.configure(with: modelContext)
    }
    
    /// Load LEGO sets from API or cache
    func loadSets() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            _ = try await legoSetService.fetchSets()
            lastRefreshDate = Date()
        } catch {
            self.error = BrixieError.from(error)
        }
    }
    
    /// Refresh sets data
    func refresh() async {
        await loadSets()
    }
}