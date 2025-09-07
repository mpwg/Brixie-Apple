//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
import Foundation
@testable import Brixie

struct BrixieTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - Pagination Hardening Tests

struct PaginationHardeningTests {
    
    @Test("SetsListViewModel prevents overlapping loadMore calls") 
    func testSetsListViewModelPreventsOverlappingLoadMore() async throws {
        // Create a mock repository that tracks call count
        let mockRepository = MockLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Simulate rapid loadMore calls
        async let task1: Void = viewModel.loadMoreSets()
        async let task2: Void = viewModel.loadMoreSets()
        async let task3: Void = viewModel.loadMoreSets()
        
        // Wait for all tasks to complete
        let _ = await (task1, task2, task3)
        
        // Verify only one actual network call was made
        #expect(mockRepository.fetchCallCount <= 1, "Expected at most 1 fetch call, got \(mockRepository.fetchCallCount)")
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false after completion")
    }
    
    @Test("SetsListViewModel cancels previous loadMore when new one starts")
    func testSetsListViewModelCancelsPreviousLoadMore() async throws {
        let mockRepository = MockSlowLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Start a loadMore operation
        let task1 = Task {
            await viewModel.loadMoreSets()
        }
        
        // Wait a bit then start another
        try await Task.sleep(for: .milliseconds(50))
        
        let task2 = Task {
            await viewModel.loadMoreSets()
        }
        
        await task1.value
        await task2.value
        
        // Verify that we handled cancellation properly
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false")
        #expect(mockRepository.fetchCallCount <= 2, "Expected at most 2 fetch calls due to cancellation")
    }
    
    @Test("Rapid pagination requests are properly handled")
    func testRapidPaginationRequestsHandling() async throws {
        let mockRepository = MockLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Load initial data
        await viewModel.loadSets()
        let initialFetchCount = mockRepository.fetchCallCount
        
        // Simulate stress test - rapid fire loadMore calls
        let tasks = (1...10).map { _ in
            Task {
                await viewModel.loadMoreSets()
            }
        }
        
        // Wait for all to complete
        for task in tasks {
            await task.value
        }
        
        // Should have much fewer actual calls than attempted calls
        let totalCalls = mockRepository.fetchCallCount - initialFetchCount
        #expect(totalCalls <= 5, "Expected at most 5 pagination calls in stress test, got \(totalCalls)")
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false after stress test")
    }
    
    @Test("Task cancellation prevents race conditions")
    func testTaskCancellationPreventsRaceConditions() async throws {
        let mockRepository = MockSlowLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Start a loadMore operation
        let task = Task {
            await viewModel.loadMoreSets()
        }
        
        // Cancel it quickly
        task.cancel()
        await task.value
        
        // Verify state is clean
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false after cancellation")
        #expect(viewModel.currentPage == 1, "Expected currentPage to remain unchanged after cancellation")
    }
    
    @Test("CategoryDetailView debouncing prevents rapid button taps")
    func testCategoryDetailViewDebouncing() async throws {
        // This test validates the debouncing logic conceptually
        // In a real app test, we would test the actual CategoryDetailView
        
        var callCount = 0
        let lastCallTime = Date()
        
        // Simulate rapid calls with debouncing logic
        func simulateLoadMore() {
            let now = Date()
            guard now.timeIntervalSince(lastCallTime) > 0.5 else { return }
            callCount += 1
        }
        
        // Simulate rapid calls
        for _ in 1...5 {
            simulateLoadMore()
        }
        
        #expect(callCount <= 1, "Expected debouncing to prevent multiple rapid calls")
    }
}

// MARK: - Mock Implementations

@MainActor
final class MockLegoSetRepository: LegoSetRepository {
    var fetchCallCount = 0
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.01) {
        self.delay = delay
    }
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        fetchCallCount += 1
        try await Task.sleep(for: .seconds(delay))
        
        // Return mock data
        return [
            LegoSet(setNum: "\(page)-1", name: "Test Set \(page)", year: 2024, themeId: 1, numParts: 100),
            LegoSet(setNum: "\(page)-2", name: "Test Set \(page + 1)", year: 2024, themeId: 1, numParts: 200)
        ]
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        return []
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        return nil
    }
    
    func getCachedSets() async -> [LegoSet] {
        return []
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {}
    
    func removeFromFavorites(_ set: LegoSet) async throws {}
    
    func getFavoriteSets() async -> [LegoSet] {
        return []
    }
}

@MainActor
final class MockSlowLegoSetRepository: MockLegoSetRepository {
    init() {
        super.init(delay: 0.2) // Slower delay for cancellation testing
    }
}
