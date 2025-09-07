//
//  SetsListViewModel.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@Observable
@MainActor
final class SetsListViewModel: ViewModelErrorHandling {
    private let legoSetRepository: LegoSetRepository
    
    var sets: [LegoSet] = []
    var isLoading = false
    var isLoadingMore = false
    var error: BrixieError?
    var currentPage = 1
    
    private let pageSize = 20
    
    init(legoSetRepository: LegoSetRepository) {
        self.legoSetRepository = legoSetRepository
    }
    
    func loadSets() async {
        currentPage = 1
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            sets = try await legoSetRepository.fetchSets(page: currentPage, pageSize: pageSize)
        } catch {
            handleError(error)
            sets = await legoSetRepository.getCachedSets()
        }
    }
    
    func loadMoreSets() async {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        let nextPage = currentPage + 1
        
        do {
            let newSets = try await legoSetRepository.fetchSets(page: nextPage, pageSize: pageSize)
            sets.append(contentsOf: newSets)
            currentPage = nextPage
        } catch {
            // Don't update error state for pagination failures
        }
    }
    
    func toggleFavorite(for set: LegoSet) async {
        do {
            try await toggleFavoriteOnRepository(set: set, repository: legoSetRepository)

            if let index = sets.firstIndex(where: { $0.id == set.id }) {
                sets[index].isFavorite.toggle()
            }
        } catch {
            handleError(error)
        }
    }
    
    func retryLoad() async {
        await loadSets()
    }
    
    var cachedSetsAvailable: Bool {
        !sets.isEmpty
    }
    
    /// Backfill theme names for existing sets
    func backfillThemeNames() async {
        do {
            try await legoSetRepository.backfillThemeNames()
            // Refresh the current sets list to show updated theme names
            sets = await legoSetRepository.getCachedSets()
        } catch let brixieError as BrixieError {
            error = brixieError
        } catch {
            self.error = BrixieError.networkError(underlying: error)
        }
    }
}
