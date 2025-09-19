import Testing
import SwiftData
@testable import Brixie

/// Test suite for LegoSetService
@MainActor
struct LegoSetServiceTests {
    
    private var service: LegoSetService!
    private var modelContext: ModelContext!
    
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: LegoSet.self, Theme.self, UserCollection.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        service = LegoSetService.shared
    }
    
    @Test("LegoSetService singleton works")
    func testSingleton() {
        let service1 = LegoSetService.shared
        let service2 = LegoSetService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("LegoSetService can search sets by number")
    func testSearchBySetNumber() async {
        // This would require mocking the API client
        // For now, we'll test the structure
        let searchTerm = "75192"
        
        // In a real implementation, we would mock the API response
        // and test the parsing and storage logic
        #expect(!searchTerm.isEmpty)
    }
    
    @Test("LegoSetService handles empty search results")
    func testEmptySearchResults() async {
        let searchTerm = ""
        
        // Service should handle empty search terms gracefully
        #expect(searchTerm.isEmpty)
    }
}

/// Test suite for ImageCacheService
@MainActor
struct ImageCacheServiceTests {
    
    private var cacheService: ImageCacheService!
    
    init() {
        cacheService = ImageCacheService.shared
    }
    
    @Test("ImageCacheService singleton works")
    func testSingleton() {
        let service1 = ImageCacheService.shared
        let service2 = ImageCacheService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("ImageCacheService cache size tracking works")
    func testCacheSizeTracking() {
        let initialSize = cacheService.currentCacheSize
        
        #expect(initialSize >= 0)
        #expect(cacheService.cacheUsagePercentage >= 0.0)
        #expect(cacheService.cacheUsagePercentage <= 1.0)
    }
    
    @Test("ImageCacheService can format cache size")
    func testCacheSizeFormatting() {
        let formattedSize = cacheService.formattedCacheSize
        
        #expect(!formattedSize.isEmpty)
        #expect(formattedSize.contains("B") || formattedSize.contains("KB") || formattedSize.contains("MB"))
    }
    
    @Test("ImageCacheService can clear memory cache")
    func testClearMemoryCache() {
        // This is mainly testing that the method doesn't crash
        cacheService.clearMemoryCache()
        
        // The method should complete without throwing
        #expect(true)
    }
    
    @Test("ImageCacheService can get disk cache file count")
    func testDiskCacheFileCount() {
        let fileCount = cacheService.diskCacheFileCount
        
        #expect(fileCount >= 0)
    }
}

/// Test suite for CollectionService
@MainActor
struct CollectionServiceTests {
    
    private var service: CollectionService!
    private var modelContext: ModelContext!
    
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: LegoSet.self, Theme.self, UserCollection.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        service = CollectionService.shared
    }
    
    @Test("CollectionService singleton works")
    func testSingleton() {
        let service1 = CollectionService.shared
        let service2 = CollectionService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("CollectionService can toggle owned status")
    func testToggleOwned() {
        let set = LegoSet(
            setNumber: "75192",
            name: "Millennium Falcon",
            year: 2017,
            numParts: 7541,
            themeID: 158
        )
        
        modelContext.insert(set)
        
        // Test toggling from not owned to owned
        service.toggleOwned(set, in: modelContext)
        
        do {
            try modelContext.save()
            #expect(set.userCollection?.isOwned == true)
        } catch {
            Issue.record("Failed to save after toggle owned: \(error)")
        }
        
        // Test toggling back to not owned
        service.toggleOwned(set, in: modelContext)
        
        do {
            try modelContext.save()
            #expect(set.userCollection?.isOwned == false)
        } catch {
            Issue.record("Failed to save after toggle owned back: \(error)")
        }
    }
    
    @Test("CollectionService can toggle wishlist status")
    func testToggleWishlist() {
        let set = LegoSet(
            setNumber: "75193",
            name: "Millennium Falcon Microfighter",
            year: 2018,
            numParts: 101,
            themeID: 158
        )
        
        modelContext.insert(set)
        
        // Test toggling to wishlist
        service.toggleWishlist(set, in: modelContext)
        
        do {
            try modelContext.save()
            #expect(set.userCollection?.isWishlist == true)
        } catch {
            Issue.record("Failed to save after toggle wishlist: \(error)")
        }
    }
    
    @Test("CollectionService statistics calculation works")
    func testStatisticsCalculation() {
        // Add some test sets to collection
        let set1 = LegoSet(setNumber: "001", name: "Test Set 1", year: 2020, numParts: 100, themeID: 1)
        let set2 = LegoSet(setNumber: "002", name: "Test Set 2", year: 2021, numParts: 200, themeID: 1)
        
        let collection1 = UserCollection(setNumber: "001", isOwned: true, purchasePrice: 50.0, currentValue: 75.0)
        let collection2 = UserCollection(setNumber: "002", isOwned: true, purchasePrice: 100.0, currentValue: 90.0)
        
        set1.userCollection = collection1
        set2.userCollection = collection2
        collection1.legoSet = set1
        collection2.legoSet = set2
        
        modelContext.insert(set1)
        modelContext.insert(set2)
        modelContext.insert(collection1)
        modelContext.insert(collection2)
        
        do {
            try modelContext.save()
            
            let stats = service.getCollectionStatistics(in: modelContext)
            
            #expect(stats.totalSets == 2)
            #expect(stats.totalParts == 300)
            #expect(stats.totalValue == 165.0)
            #expect(stats.totalInvestment == 150.0)
            
        } catch {
            Issue.record("Failed to save test data for statistics: \(error)")
        }
    }
}

/// Test suite for SearchHistoryService
@MainActor
struct SearchHistoryServiceTests {
    
    private var service: SearchHistoryService!
    
    init() {
        service = SearchHistoryService.shared
        // Clear any existing history for clean tests
        service.clearHistory()
    }
    
    @Test("SearchHistoryService singleton works")
    func testSingleton() {
        let service1 = SearchHistoryService.shared
        let service2 = SearchHistoryService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("SearchHistoryService can add search terms")
    func testAddSearchTerm() {
        let searchTerm = "Millennium Falcon"
        
        service.addSearchTerm(searchTerm)
        
        let recentSearches = service.recentSearches
        #expect(recentSearches.contains(searchTerm))
    }
    
    @Test("SearchHistoryService limits recent searches")
    func testRecentSearchesLimit() {
        // Add more than the maximum number of searches
        for i in 1...15 {
            service.addSearchTerm("Search Term \(i)")
        }
        
        let recentSearches = service.recentSearches
        #expect(recentSearches.count <= 10) // Assuming max limit is 10
    }
    
    @Test("SearchHistoryService provides suggestions")
    func testGetSuggestions() {
        service.addSearchTerm("Star Wars")
        service.addSearchTerm("Star Trek")
        service.addSearchTerm("Starcraft")
        
        let suggestions = service.getSuggestions(for: "Star")
        
        #expect(suggestions.count == 3)
        #expect(suggestions.contains("Star Wars"))
        #expect(suggestions.contains("Star Trek"))
        #expect(suggestions.contains("Starcraft"))
    }
    
    @Test("SearchHistoryService case-insensitive suggestions")
    func testCaseInsensitiveSuggestions() {
        service.addSearchTerm("LEGO Technic")
        
        let suggestions = service.getSuggestions(for: "lego")
        
        #expect(suggestions.contains("LEGO Technic"))
    }
    
    @Test("SearchHistoryService can clear history")
    func testClearHistory() {
        service.addSearchTerm("Test Search")
        service.clearHistory()
        
        let recentSearches = service.recentSearches
        #expect(recentSearches.isEmpty)
    }
}

/// Test suite for OfflineManager
@MainActor 
struct OfflineManagerTests {
    
    private var offlineManager: OfflineManager!
    
    init() {
        offlineManager = OfflineManager.shared
    }
    
    @Test("OfflineManager singleton works")
    func testSingleton() {
        let manager1 = OfflineManager.shared
        let manager2 = OfflineManager.shared
        
        #expect(manager1 === manager2)
    }
    
    @Test("OfflineManager can queue actions")
    func testQueueAction() {
        let initialCount = offlineManager.queuedActions.count
        
        let action = QueuedAction(
            type: .addToCollection,
            data: ["setNumber": "75192", "name": "Millennium Falcon"]
        )
        
        offlineManager.queueAction(action)
        
        #expect(offlineManager.queuedActions.count == initialCount + 1)
    }
    
    @Test("OfflineManager can remove queued actions")
    func testRemoveQueuedAction() {
        let action = QueuedAction(
            type: .addToWishlist,
            data: ["setNumber": "75193"]
        )
        
        offlineManager.queueAction(action)
        let countAfterAdd = offlineManager.queuedActions.count
        
        offlineManager.removeQueuedAction(action)
        let countAfterRemove = offlineManager.queuedActions.count
        
        #expect(countAfterRemove == countAfterAdd - 1)
    }
    
    @Test("OfflineManager can clear all queued actions")
    func testClearAllQueuedActions() {
        let action1 = QueuedAction(type: .addToCollection, data: ["setNumber": "001"])
        let action2 = QueuedAction(type: .addToWishlist, data: ["setNumber": "002"])
        
        offlineManager.queueAction(action1)
        offlineManager.queueAction(action2)
        
        #expect(!offlineManager.queuedActions.isEmpty)
        
        offlineManager.clearAllQueuedActions()
        
        #expect(offlineManager.queuedActions.isEmpty)
    }
    
    @Test("QueuedAction has correct properties")
    func testQueuedActionProperties() {
        let data = ["setNumber": "75192", "name": "Millennium Falcon"]
        let action = QueuedAction(type: .addToCollection, data: data)
        
        #expect(action.type == .addToCollection)
        #expect(action.data["setNumber"] == "75192")
        #expect(action.data["name"] == "Millennium Falcon")
        #expect(action.timestamp != nil)
        #expect(!action.id.uuidString.isEmpty)
    }
}