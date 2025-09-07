//
//  PaginatedAsyncSequence.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

/// A generic AsyncSequence that provides automatic pagination for any paginated API
/// Handles page management, error recovery, and provides a clean streaming interface
struct PaginatedAsyncSequence<Element>: AsyncSequence {
    typealias AsyncIterator = PaginatedAsyncIterator<Element>
    
    private let fetchPage: @Sendable (Int, Int) async throws -> [Element]
    private let pageSize: Int
    private let startPage: Int
    
    /// Creates a new paginated async sequence
    /// - Parameters:
    ///   - fetchPage: Async function that fetches a page of data given page number and page size
    ///   - pageSize: Number of items per page (default: 20)
    ///   - startPage: Starting page number (default: 1)
    init(
        pageSize: Int = 20,
        startPage: Int = 1,
        fetchPage: @escaping @Sendable (Int, Int) async throws -> [Element]
    ) {
        self.fetchPage = fetchPage
        self.pageSize = pageSize
        self.startPage = startPage
    }
    
    func makeAsyncIterator() -> PaginatedAsyncIterator<Element> {
        PaginatedAsyncIterator(
            fetchPage: fetchPage,
            pageSize: pageSize,
            startPage: startPage
        )
    }
}

/// Iterator for PaginatedAsyncSequence that manages the actual pagination logic
struct PaginatedAsyncIterator<Element>: AsyncIteratorProtocol {
    private let fetchPage: @Sendable (Int, Int) async throws -> [Element]
    private let pageSize: Int
    private var currentPage: Int
    private var currentPageItems: [Element] = []
    private var currentIndex = 0
    private var hasMorePages = true
    private var isFinished = false
    
    init(
        fetchPage: @escaping @Sendable (Int, Int) async throws -> [Element],
        pageSize: Int,
        startPage: Int
    ) {
        self.fetchPage = fetchPage
        self.pageSize = pageSize
        self.currentPage = startPage
    }
    
    mutating func next() async throws -> Element? {
        // If we've finished iteration, return nil
        guard !isFinished else { return nil }
        
        // If we need to fetch more data
        if currentIndex >= currentPageItems.count {
            // If we have no more pages, we're done
            guard hasMorePages else {
                isFinished = true
                return nil
            }
            
            // Fetch the next page
            let pageItems = try await fetchPage(currentPage, pageSize)
            
            // Update pagination state
            currentPageItems = pageItems
            currentIndex = 0
            hasMorePages = pageItems.count == pageSize
            currentPage += 1
            
            // If this page is empty, we're done
            guard !pageItems.isEmpty else {
                isFinished = true
                return nil
            }
        }
        
        // Return the next item from current page
        let item = currentPageItems[currentIndex]
        currentIndex += 1
        return item
    }
}

// MARK: - Convenience Extensions

extension PaginatedAsyncSequence {
    /// Collect all items into an array (use with caution for large datasets)
    func collect() async throws -> [Element] {
        var result: [Element] = []
        for try await item in self {
            result.append(item)
        }
        return result
    }
    
    /// Collect up to a specified number of items
    func collect(limit: Int) async throws -> [Element] {
        var result: [Element] = []
        var count = 0
        
        for try await item in self {
            result.append(item)
            count += 1
            if count >= limit {
                break
            }
        }
        
        return result
    }
    
    /// Collect items in batches (pages)
    func collectByPages() -> AsyncThrowingStream<[Element], Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var iterator = makeAsyncIterator()
                    var currentBatch: [Element] = []
                    var batchSize = 0
                    
                    while let item = try await iterator.next() {
                        currentBatch.append(item)
                        batchSize += 1
                        
                        // When we've collected a full page, yield it
                        if batchSize == pageSize {
                            continuation.yield(currentBatch)
                            currentBatch = []
                            batchSize = 0
                        }
                    }
                    
                    // Yield any remaining items
                    if !currentBatch.isEmpty {
                        continuation.yield(currentBatch)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}