import Testing
import SwiftData
@testable import Brixie

/// Test suite for LegoSet model
@MainActor
struct LegoSetTests {
    
    // MARK: - Test Setup
    
    private func createModelContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: LegoSet.self, configurations: config)
        return ModelContext(container)
    }
    
    // MARK: - Model Creation Tests
    
    @Test("LegoSet can be created with required properties")
    func testLegoSetCreation() {
        let set = LegoSet(
            setNumber: "75192",
            name: "Millennium Falcon",
            year: 2017,
            numParts: 7541,
            themeID: 158,
            imageURL: "https://example.com/image.jpg"
        )
        
        #expect(set.setNumber == "75192")
        #expect(set.name == "Millennium Falcon")
        #expect(set.year == 2017)
        #expect(set.numParts == 7541)
        #expect(set.themeID == 158)
        #expect(set.imageURL == "https://example.com/image.jpg")
    }
    
    @Test("LegoSet unique constraint works")
    func testLegoSetUniqueConstraint() {
        let context = createModelContext()
        
        let set1 = LegoSet(
            setNumber: "75192",
            name: "Millennium Falcon",
            year: 2017,
            numParts: 7541,
            themeID: 158
        )
        
        let set2 = LegoSet(
            setNumber: "75192", // Same set number
            name: "Another Name",
            year: 2018,
            numParts: 1000,
            themeID: 200
        )
        
        context.insert(set1)
        
        do {
            try context.save()
        } catch {
            Issue.record("Failed to save first set: \(error)")
        }
        
        context.insert(set2)
        
        // This should fail due to unique constraint
        #expect(throws: Error.self) {
            try context.save()
        }
    }
    
    @Test("LegoSet computed properties work correctly")
    func testLegoSetComputedProperties() {
        let set = LegoSet(
            setNumber: "75192",
            name: "Millennium Falcon",
            year: 2017,
            numParts: 7541,
            themeID: 158,
            imageURL: "https://example.com/image.jpg"
        )
        
        #expect(set.primaryImageURL == "https://example.com/image.jpg")
        #expect(set.displayYear == "2017")
        #expect(set.partsDescription == "7541 parts")
    }
    
    @Test("LegoSet example data is valid")
    func testLegoSetExample() {
        let example = LegoSet.example
        
        #expect(!example.setNumber.isEmpty)
        #expect(!example.name.isEmpty)
        #expect(example.year > 1900)
        #expect(example.numParts > 0)
    }
    
    // MARK: - Relationship Tests
    
    @Test("LegoSet can be associated with UserCollection")
    func testLegoSetUserCollectionRelationship() {
        let context = createModelContext()
        
        let set = LegoSet(
            setNumber: "75192",
            name: "Millennium Falcon",
            year: 2017,
            numParts: 7541,
            themeID: 158
        )
        
        let collection = UserCollection(
            setNumber: "75192",
            isOwned: true,
            isWishlist: false
        )
        
        set.userCollection = collection
        collection.legoSet = set
        
        context.insert(set)
        context.insert(collection)
        
        do {
            try context.save()
            
            #expect(set.userCollection?.isOwned == true)
            #expect(collection.legoSet?.name == "Millennium Falcon")
        } catch {
            Issue.record("Failed to save set with collection: \(error)")
        }
    }
}