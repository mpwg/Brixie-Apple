//
//  SetsListViewModel.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@Observable
@MainActor
final class SetsListViewModel {
    private let legoSetRepository: LegoSetRepository
    
    var sets: [LegoSet] = []
    var isLoading = false
    var isLoadingMore = false
    var error: BrixieError?
    var currentPage = 1
    
    private let pageSize = 20
    private var loadMoreTask: Task<Void, Never>?
    
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
        } catch let brixieError as BrixieError {
            error = brixieError
            sets = await legoSetRepository.getCachedSets()
        } catch {
            self.error = BrixieError.networkError(underlying: error)
            sets = await legoSetRepository.getCachedSets()
        }
    }
    
    /// Loads additional sets with protection against duplicate requests.
    /// Features:
    /// - Cancels any existing loadMore task before starting new one
    /// - Guards against overlapping requests using isLoadingMore flag  
    /// - Checks Task.isCancelled after network calls to prevent race conditions
    /// - Maintains proper loading state throughout the operation
    func loadMoreSets() async {
        // Cancel any existing load more task
        loadMoreTask?.cancel()
        
        guard !isLoadingMore else { return }
        
        loadMoreTask = Task { @MainActor in
            isLoadingMore = true
            defer { 
                isLoadingMore = false
                loadMoreTask = nil
            }
            
            let nextPage = currentPage + 1
            
            do {
                let newSets = try await legoSetRepository.fetchSets(page: nextPage, pageSize: pageSize)
                // Check if task was cancelled during network request
                guard !Task.isCancelled else { return }
                
                sets.append(contentsOf: newSets)
                currentPage = nextPage
            } catch {
                // Don't update error state for pagination failures
                // but check if we were cancelled
                guard !Task.isCancelled else { return }
            }
        }
        
        await loadMoreTask?.value
    }
    
    func toggleFavorite(for set: LegoSet) async {
        do {
            if set.isFavorite {
                try await legoSetRepository.removeFromFavorites(set)
            } else {
                try await legoSetRepository.markAsFavorite(set)
            }
            
            if let index = sets.firstIndex(where: { $0.id == set.id }) {
                sets[index].isFavorite.toggle()
            }
        } catch let brixieError as BrixieError {
            error = brixieError
        } catch {
            self.error = BrixieError.networkError(underlying: error)
        }
    }
    
    
    var cachedSetsAvailable: Bool {
        !sets.isEmpty
    }
}
