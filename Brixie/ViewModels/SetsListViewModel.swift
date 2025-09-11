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
    
    private let pageSize = 20
    private var currentTask: Task<Void, Never>?
    
    init(legoSetRepository: LegoSetRepository) {
        self.legoSetRepository = legoSetRepository
    }
    
    func loadSets() async {
        // Cancel any existing loading task
        currentTask?.cancel()
        
        sets = []
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        currentTask = Task {
            do {
                // Collect the first page worth of data
                let initialSets = try await legoSetRepository
                    .allSets(pageSize: pageSize)
                    .collect(limit: pageSize)
                
                guard !Task.isCancelled else { return }
                
                sets = initialSets
            } catch let brixieError as BrixieError {
                guard !Task.isCancelled else { return }
                error = brixieError
                sets = await legoSetRepository.getCachedSets()
            } catch {
                guard !Task.isCancelled else { return }
                self.error = BrixieError.networkError(underlying: error)
                sets = await legoSetRepository.getCachedSets()
            }
        }
        
        await currentTask?.value
    }
    
    /// Loads additional sets with protection against duplicate requests.
    /// Features:
    /// - Cancels any existing loadMore task before starting new one
    /// - Guards against overlapping requests using isLoadingMore flag  
    /// - Checks Task.isCancelled after network calls to prevent race conditions
    /// - Maintains proper loading state throughout the operation
    func loadMoreSets() async {
        guard !isLoadingMore && !sets.isEmpty else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                // Calculate the next page based on current set count
                let nextPageIndex = (sets.count / pageSize) + 1
                
                // Create a sequence starting from the next page
                let paginatedSequence = PaginatedAsyncSequence<LegoSet>(
                    pageSize: pageSize,
                    startPage: nextPageIndex
                ) { [weak self] page, pageSize in
                    guard let self = self else { throw BrixieError.dataNotFound }
                    return try await self.legoSetRepository.fetchSets(page: page, pageSize: pageSize)
                }
                
                // Get the next page
                let newSets = try await paginatedSequence.collect(limit: pageSize)
                
                guard !Task.isCancelled, !newSets.isEmpty else { return }
                
                sets.append(contentsOf: newSets)
            } catch {
                // Don't update error state for pagination failures
                // This maintains existing behavior
                guard !Task.isCancelled else { return }
            }
        }
        
        await currentTask?.value
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
