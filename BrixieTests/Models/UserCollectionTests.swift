import Testing
import SwiftData
@testable import Brixie

/// Test suite for UserCollection model
@MainActor
struct UserCollectionTests {
    private func createModelContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserCollection.self, configurations: config)
        return ModelContext(container)
    }
    
    @Test("UserCollection can be created with required properties")
    func testUserCollectionCreation() {
        let collection = UserCollection(
            setNumber: "75192",
            isOwned: true,
            isWishlist: false,
            hasMissingParts: true,
            purchasePrice: 79.99,
            currentValue: 150.00,
            notes: "Birthday gift"
        )
        
        #expect(collection.setNumber == "75192")
        #expect(collection.isOwned == true)
        #expect(collection.isWishlist == false)
        #expect(collection.hasMissingParts == true)
        #expect(collection.purchasePrice == 79.99)
        #expect(collection.currentValue == 150.00)
        #expect(collection.notes == "Birthday gift")
    }
    
    @Test("UserCollection defaults work correctly")
    func testUserCollectionDefaults() {
        let collection = UserCollection(setNumber: "12345")
        
        #expect(collection.isOwned == false)
        #expect(collection.isWishlist == false)
        #expect(collection.hasMissingParts == false)
        #expect(collection.purchasePrice == nil)
        #expect(collection.currentValue == nil)
        #expect(collection.notes == nil)
        #expect(collection.dateAdded != nil)
    }
    
    @Test("UserCollection computed properties work")
    func testUserCollectionComputedProperties() {
        let collection = UserCollection(
            setNumber: "75192",
            purchasePrice: 79.99,
            currentValue: 150.00
        )
        
        #expect(collection.valueChange == 70.01)
        #expect(collection.hasValueGain == true)
    }
}
