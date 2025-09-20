//
//  PaginatedQuery.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import SwiftUI
import SwiftData
import OSLog

/// A SwiftUI view that provides paginated data loading for SwiftData queries
/// Designed to improve performance by loading data in chunks rather than all at once
struct PaginatedQuery<Item: PersistentModel, Content: View>: View {
    
    // MARK: - Properties
    
    /// The maximum number of items to load per page
    private let pageSize: Int
    
    /// Current page number (0-based)
    @State private var currentPage: Int = 0
    
    /// All loaded items across all pages
    @State private var loadedItems: [Item] = []
    
    /// Whether we're currently loading more items
    @State private var isLoadingMore: Bool = false
    
    /// Whether we've reached the end of available data
    @State private var hasReachedEnd: Bool = false
    
    /// The SwiftData query configuration
    private let sort: [SortDescriptor<Item>]
    private let predicate: Predicate<Item>?
    
    /// Content builder that receives the loaded items
    private let content: ([Item]) -> Content
    
    /// Model context for queries
    @Environment(\.modelContext) private var modelContext
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.brixie", category: "PaginatedQuery")
    
    // MARK: - Initialization
    
    /// Initialize with sort descriptors and content builder
    /// - Parameters:
    ///   - sort: Sort descriptors for the query
    ///   - predicate: Optional predicate to filter results
    ///   - pageSize: Number of items to load per page (default: 20)
    ///   - content: Content builder that receives loaded items
    init(
        sort: [SortDescriptor<Item>],
        predicate: Predicate<Item>? = nil,
        pageSize: Int = 20,
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        self.sort = sort
        self.predicate = predicate
        self.pageSize = pageSize
        self.content = content
    }
    
    /// Convenience initializer with single sort descriptor
    /// - Parameters:
    ///   - sort: Single sort descriptor
    ///   - predicate: Optional predicate to filter results
    ///   - pageSize: Number of items to load per page (default: 20)
    ///   - content: Content builder that receives loaded items
    init(
        sort: SortDescriptor<Item>,
        predicate: Predicate<Item>? = nil,
        pageSize: Int = 20,
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        self.init(sort: [sort], predicate: predicate, pageSize: pageSize, content: content)
    }
    
    // MARK: - Body
    
    var body: some View {
        content(loadedItems)
            .onAppear {
                if loadedItems.isEmpty {
                    loadInitialPage()
                }
            }
            .refreshable {
                await refresh()
            }
    }
    
    // MARK: - Public Methods
    
    /// Load more items (call this from scroll view when near end)
    func loadMore() {
        guard !isLoadingMore && !hasReachedEnd else { return }
        
        Task {
            await loadNextPage()
        }
    }
    
    /// Refresh all data (resets pagination)
    func refresh() async {
        logger.debug("Refreshing paginated query")
        currentPage = 0
        loadedItems.removeAll()
        hasReachedEnd = false
        await loadNextPage()
    }
    
    // MARK: - Private Methods
    
    /// Load the first page of data
    private func loadInitialPage() {
        Task {
            await loadNextPage()
        }
    }
    
    /// Load the next page of data
    @MainActor
    private func loadNextPage() async {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        
        do {
            let offset = currentPage * pageSize
            logger.debug("Loading page \(currentPage) with offset \(offset), limit \(pageSize)")
            
            // Create fetch descriptor with pagination
            var descriptor = FetchDescriptor<Item>(
                predicate: predicate,
                sortBy: sort
            )
            descriptor.fetchLimit = pageSize
            descriptor.fetchOffset = offset
            
            let newItems = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(newItems.count) items for page \(currentPage)")
            
            if newItems.isEmpty || newItems.count < pageSize {
                hasReachedEnd = true
                logger.debug("Reached end of data")
            }
            
            // Append new items to existing ones
            loadedItems.append(contentsOf: newItems)
            currentPage += 1
            
        } catch {
            logger.error("Failed to load page \(currentPage): \(error.localizedDescription)")
        }
        
        isLoadingMore = false
    }
}

// MARK: - View Modifiers

extension PaginatedQuery {
    /// Add infinite scroll behavior - automatically loads more when approaching end
    /// Note: For now, this is a placeholder - infinite scroll would need to be implemented
    /// by calling loadMore() manually when items appear
    func infiniteScroll(threshold: Int = 5) -> some View {
        self
    }
}

// MARK: - Convenience Extensions

extension PaginatedQuery where Item == LegoSet {
    /// Convenience initializer for LEGO sets sorted by name
    static func legoSetsByName(
        pageSize: Int = 20,
        @ViewBuilder content: @escaping ([LegoSet]) -> Content
    ) -> PaginatedQuery<LegoSet, Content> {
        PaginatedQuery(
            sort: SortDescriptor(\LegoSet.name),
            pageSize: pageSize,
            content: content
        )
    }
    
    /// Convenience initializer for LEGO sets sorted by year (newest first)
    static func legoSetsByYear(
        pageSize: Int = 20,
        @ViewBuilder content: @escaping ([LegoSet]) -> Content
    ) -> PaginatedQuery<LegoSet, Content> {
        PaginatedQuery(
            sort: SortDescriptor(\LegoSet.year, order: .reverse),
            pageSize: pageSize,
            content: content
        )
    }
    
    /// Convenience initializer for LEGO sets with theme filter
    static func legoSets(
        forTheme themeId: Int,
        pageSize: Int = 20,
        @ViewBuilder content: @escaping ([LegoSet]) -> Content
    ) -> PaginatedQuery<LegoSet, Content> {
        PaginatedQuery(
            sort: SortDescriptor(\LegoSet.name),
            predicate: #Predicate { $0.themeId == themeId },
            pageSize: pageSize,
            content: content
        )
    }
}

extension PaginatedQuery where Item == Theme {
    /// Convenience initializer for themes sorted by name
    static func themesByName(
        pageSize: Int = 20,
        @ViewBuilder content: @escaping ([Theme]) -> Content
    ) -> PaginatedQuery<Theme, Content> {
        PaginatedQuery(
            sort: SortDescriptor(\Theme.name),
            pageSize: pageSize,
            content: content
        )
    }
}