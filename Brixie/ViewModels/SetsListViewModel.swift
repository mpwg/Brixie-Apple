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
    
    func loadMoreSets() async {
        guard !isLoadingMore && !sets.isEmpty else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
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
            
            guard !newSets.isEmpty else { return }
            
            sets.append(contentsOf: newSets)
        } catch {
            // Don't update error state for pagination failures
            // This maintains existing behavior
        }
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
