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

/// Test suite for Theme model
@MainActor
struct ThemeTests {
    
    private func createModelContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Theme.self, configurations: config)
        return ModelContext(container)
    }
    
    @Test("Theme can be created with required properties")
    func testThemeCreation() {
        let theme = Theme(
            id: 158,
            parentID: 157,
            name: "Star Wars",
            sortOrder: 1
        )
        
        #expect(theme.id == 158)
        #expect(theme.parentID == 157)
        #expect(theme.name == "Star Wars")
        #expect(theme.sortOrder == 1)
    }
    
    @Test("Theme hierarchy relationships work")
    func testThemeHierarchy() {
        let context = createModelContext()
        
        let parentTheme = Theme(id: 1, parentID: nil, name: "Licensed", sortOrder: 1)
        let childTheme = Theme(id: 158, parentID: 1, name: "Star Wars", sortOrder: 1)
        
        context.insert(parentTheme)
        context.insert(childTheme)
        
        do {
            try context.save()
            
            #expect(childTheme.parentID == parentTheme.id)
            #expect(parentTheme.parentID == nil)
        } catch {
            Issue.record("Failed to save theme hierarchy: \(error)")
        }
    }
    
    @Test("Theme example data is valid")
    func testThemeExample() {
        let example = Theme.example
        
        #expect(example.id > 0)
        #expect(!example.name.isEmpty)
        #expect(example.sortOrder >= 0)
    }
}

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

/// Test suite for MissingPart model
@MainActor
struct MissingPartTests {
    
    private func createModelContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: MissingPart.self, configurations: config)
        return ModelContext(container)
    }
    
    @Test("MissingPart can be created with required properties")
    func testMissingPartCreation() {
        let part = MissingPart(
            setNumber: "75192",
            partNumber: "3001",
            partName: "Brick 2x4",
            colorName: "Bright Red",
            quantity: 5,
            isFound: false,
            notes: "Lost during build"
        )
        
        #expect(part.setNumber == "75192")
        #expect(part.partNumber == "3001")
        #expect(part.partName == "Brick 2x4")
        #expect(part.colorName == "Bright Red")
        #expect(part.quantity == 5)
        #expect(part.isFound == false)
        #expect(part.notes == "Lost during build")
    }
    
    @Test("MissingPart defaults work correctly")
    func testMissingPartDefaults() {
        let part = MissingPart(setNumber: "12345", partNumber: "3001")
        
        #expect(part.quantity == 1)
        #expect(part.isFound == false)
        #expect(part.dateAdded != nil)
    }
}