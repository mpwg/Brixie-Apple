import Testing
import SwiftData
@testable import Brixie

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
            year: 2_017,
            numParts: 7_541,
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
            year: 2_018,
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
        let set1 = LegoSet(setNumber: "001", name: "Test Set 1", year: 2_020, numParts: 100, themeID: 1)
        let set2 = LegoSet(setNumber: "002", name: "Test Set 2", year: 2_021, numParts: 200, themeID: 1)
        
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
