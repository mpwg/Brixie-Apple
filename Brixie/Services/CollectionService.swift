//
//  CollectionService.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftData

/// Service for managing user's LEGO collection
final class CollectionService {
    static let shared = CollectionService()
    
    private init() {}
    
    // MARK: - Collection Management
    
    /// Add or update a set in the user's collection
    func addToCollection(_ set: LegoSet, in context: ModelContext, isOwned: Bool = true, isWishlist: Bool = false) {
        // Get all UserCollections and filter manually since SwiftData predicates have limitations
        let descriptor = FetchDescriptor<UserCollection>()
        let collections = (try? context.fetch(descriptor)) ?? []
        let existingCollection = collections.first { $0.legoSet?.setNumber == set.setNumber }
        
        if let existing = existingCollection {
            // Update existing entry
            if isOwned {
                existing.markAsOwned()
            } else if isWishlist {
                existing.addToWishlist()
            }
        } else {
            // Create new collection entry
            let newCollection = UserCollection(
                isOwned: isOwned,
                isWishlist: isWishlist
            )
            newCollection.legoSet = set
            context.insert(newCollection)
            
            // Update the set's relationship
            set.userCollection = newCollection
        }
        
        try? context.save()
    }
    
    /// Remove a set from collection
    func removeFromCollection(_ set: LegoSet, in context: ModelContext) {
        guard let collection = set.userCollection else { return }
        
        collection.removeFromCollections()
        
        // If no longer in any collection, delete the UserCollection entry
        if !collection.isActiveCollectionItem {
            context.delete(collection)
            set.userCollection = nil
        }
        
        try? context.save()
    }
    
    /// Toggle wishlist status for a set
    func toggleWishlist(_ set: LegoSet, in context: ModelContext) {
        if let collection = set.userCollection {
            if collection.isWishlist {
                collection.isWishlist = false
                
                // Remove if no longer active
                if !collection.isActiveCollectionItem {
                    context.delete(collection)
                    set.userCollection = nil
                }
            } else {
                collection.addToWishlist()
            }
        } else {
            // Create new wishlist entry
            addToCollection(set, in: context, isOwned: false, isWishlist: true)
        }
        
        try? context.save()
    }
    
    /// Toggle owned status for a set
    func toggleOwned(_ set: LegoSet, in context: ModelContext) {
        if let collection = set.userCollection {
            if collection.isOwned {
                collection.isOwned = false
                collection.dateAcquired = nil
                
                // Remove if no longer active
                if !collection.isActiveCollectionItem {
                    context.delete(collection)
                    set.userCollection = nil
                }
            } else {
                collection.markAsOwned()
            }
        } else {
            // Create new owned entry
            addToCollection(set, in: context, isOwned: true, isWishlist: false)
        }
        
        try? context.save()
    }
    
    // MARK: - Statistics
    
    /// Get collection statistics
    func getCollectionStats(from context: ModelContext) -> CollectionStats {
        let descriptor = FetchDescriptor<UserCollection>(
            predicate: #Predicate<UserCollection> { collection in
                collection.isActiveCollectionItem
            }
        )
        
        guard let collections = try? context.fetch(descriptor) else {
            return CollectionStats()
        }
        
        var stats = CollectionStats()
        
        for collection in collections {
            if collection.isOwned {
                stats.ownedSetsCount += 1
                
                if let set = collection.legoSet {
                    stats.totalParts += set.numParts
                    
                    if let price = collection.purchasePrice {
                        stats.totalInvestment += price
                    }
                    
                    if let retailPrice = set.retailPrice {
                        stats.totalRetailValue += retailPrice
                    }
                }
                
                stats.missingPartsCount += collection.missingPartsCount
                
                if let replacementCost = collection.totalReplacementCost {
                    stats.totalReplacementCost += replacementCost
                }
            }
            
            if collection.isWishlist {
                stats.wishlistCount += 1
                
                if let set = collection.legoSet, let price = set.retailPrice {
                    stats.wishlistValue += price
                }
            }
        }
        
        return stats
    }
    
    /// Get sets grouped by theme for owned collection
    func getOwnedSetsByTheme(from context: ModelContext) -> [String: [LegoSet]] {
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: #Predicate<LegoSet> { set in
                set.userCollection?.isOwned == true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        guard let sets = try? context.fetch(descriptor) else { return [:] }
        
        return Dictionary(grouping: sets) { set in
            set.theme?.name ?? "Unknown Theme"
        }
    }
    
    /// Get recent acquisitions
    func getRecentAcquisitions(from context: ModelContext, limit: Int = 10) -> [UserCollection] {
        var descriptor = FetchDescriptor<UserCollection>(
            predicate: #Predicate<UserCollection> { collection in
                collection.isOwned && collection.dateAcquired != nil
            },
            sortBy: [SortDescriptor(\.dateAcquired, order: .reverse)]
        )
        
        descriptor.fetchLimit = limit
        
        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - Collection Statistics

struct CollectionStats {
    var ownedSetsCount: Int = 0
    var wishlistCount: Int = 0
    var totalParts: Int = 0
    var totalInvestment: Decimal = 0
    var totalRetailValue: Decimal = 0
    var totalReplacementCost: Decimal = 0
    var missingPartsCount: Int = 0
    var wishlistValue: Decimal = 0
    
    var averageSetValue: Decimal {
        guard ownedSetsCount > 0 else { return 0 }
        return totalRetailValue / Decimal(ownedSetsCount)
    }
    
    var totalValueGain: Decimal {
        return totalRetailValue - totalInvestment
    }
    
    var investmentROI: Double {
        guard totalInvestment > 0 else { return 0 }
        let roi = (totalRetailValue - totalInvestment) / totalInvestment * 100
        return Double(truncating: roi as NSDecimalNumber)
    }
}