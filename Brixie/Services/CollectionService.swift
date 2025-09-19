//
//  CollectionService.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftData
import OSLog

/// Service for managing user's LEGO collection
final class CollectionService {
    static let shared = CollectionService()
    private let logger = Logger.collection
    
    private init() {
        logger.debug("🎯 CollectionService initialized")
    }
    
    // MARK: - Collection Management
    
    /// Add or update a set in the user's collection
    func addToCollection(_ set: LegoSet, in context: ModelContext, isOwned: Bool = true, isWishlist: Bool = false) {
        logger.entering(parameters: [
            "setNumber": set.setNumber,
            "setName": set.name,
            "isOwned": isOwned,
            "isWishlist": isWishlist
        ])
        
        do {
            // Get all UserCollections and filter manually since SwiftData predicates have limitations
            let descriptor = FetchDescriptor<UserCollection>()
            let collections = try context.fetch(descriptor)
            let existingCollection = collections.first { $0.legoSet?.setNumber == set.setNumber }
            
            if let existing = existingCollection {
                logger.debug("📝 Found existing collection entry for set \(set.setNumber)")
                // Update existing entry
                if isOwned {
                    existing.markAsOwned()
                    logger.info("✅ Marked set \(set.setNumber) as owned")
                    logger.userAction("marked_set_as_owned", context: ["setNumber": set.setNumber, "setName": set.name])
                } else if isWishlist {
                    existing.addToWishlist()
                    logger.info("💝 Added set \(set.setNumber) to wishlist")
                    logger.userAction("added_set_to_wishlist", context: ["setNumber": set.setNumber, "setName": set.name])
                }
            } else {
                logger.debug("➕ Creating new collection entry for set \(set.setNumber)")
                // Create new collection entry
                let newCollection = UserCollection(
                    isOwned: isOwned,
                    isWishlist: isWishlist
                )
                newCollection.legoSet = set
                context.insert(newCollection)
                
                // Update the set's relationship
                set.userCollection = newCollection
                
                let actionType = isOwned ? "added_set_to_owned" : "added_set_to_wishlist"
                logger.info("✨ Created new collection entry for set \(set.setNumber) (owned: \(isOwned), wishlist: \(isWishlist))")
                logger.userAction(actionType, context: ["setNumber": set.setNumber, "setName": set.name])
            }
            
            try context.save()
            logger.debug("💾 Successfully saved collection changes for set \(set.setNumber)")
            logger.exitWith(result: "success")
        } catch {
            logger.error("❌ Failed to add set \(set.setNumber) to collection: \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
        }
    }
    
    /// Remove a set from collection
    func removeFromCollection(_ set: LegoSet, in context: ModelContext) {
        logger.entering(parameters: [
            "setNumber": set.setNumber,
            "setName": set.name
        ])
        
        guard let collection = set.userCollection else {
            logger.debug("⚠️ No collection entry found for set \(set.setNumber) - nothing to remove")
            logger.exitWith(result: "no collection found")
            return
        }
        
        do {
            logger.debug("🗑️ Removing set \(set.setNumber) from collections")
            collection.removeFromCollections()
            
            // If no longer in any collection, delete the UserCollection entry
            if !collection.isActiveCollectionItem {
                logger.debug("🧹 Deleting UserCollection entry for set \(set.setNumber) as it's no longer active")
                context.delete(collection)
                set.userCollection = nil
            }
            
            try context.save()
            logger.info("✅ Successfully removed set \(set.setNumber) from collection")
            logger.userAction("removed_set_from_collection", context: ["setNumber": set.setNumber, "setName": set.name])
            logger.exitWith(result: "success")
        } catch {
            logger.error("❌ Failed to remove set \(set.setNumber) from collection: \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
        }
    }
    
    /// Toggle wishlist status for a set
    func toggleWishlist(_ set: LegoSet, in context: ModelContext) {
        logger.entering(parameters: [
            "setNumber": set.setNumber,
            "setName": set.name,
            "currentWishlistStatus": set.userCollection?.isWishlist ?? false
        ])
        
        do {
            if let collection = set.userCollection {
                if collection.isWishlist {
                    logger.debug("➖ Removing set \(set.setNumber) from wishlist")
                    collection.isWishlist = false
                    
                    // Remove if no longer active
                    if !collection.isActiveCollectionItem {
                        logger.debug("🧹 Deleting UserCollection entry for set \(set.setNumber) as it's no longer active")
                        context.delete(collection)
                        set.userCollection = nil
                    }
                    logger.userAction("removed_from_wishlist", context: ["setNumber": set.setNumber, "setName": set.name])
                } else {
                    logger.debug("➕ Adding set \(set.setNumber) to wishlist")
                    collection.addToWishlist()
                    logger.userAction("added_to_wishlist", context: ["setNumber": set.setNumber, "setName": set.name])
                }
            } else {
                logger.debug("✨ Creating new wishlist entry for set \(set.setNumber)")
                // Create new wishlist entry
                addToCollection(set, in: context, isOwned: false, isWishlist: true)
                return // addToCollection handles its own logging
            }
            
            try context.save()
            let newStatus = set.userCollection?.isWishlist ?? false
            logger.info("🔄 Successfully toggled wishlist status for set \(set.setNumber) to \(newStatus)")
            logger.exitWith(result: "wishlist status: \(newStatus)")
        } catch {
            logger.error("❌ Failed to toggle wishlist for set \(set.setNumber): \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
        }
    }
    
    /// Toggle owned status for a set
    func toggleOwned(_ set: LegoSet, in context: ModelContext) {
        logger.entering(parameters: [
            "setNumber": set.setNumber,
            "setName": set.name,
            "currentOwnedStatus": set.userCollection?.isOwned ?? false
        ])
        
        do {
            if let collection = set.userCollection {
                if collection.isOwned {
                    logger.debug("➖ Removing set \(set.setNumber) from owned collection")
                    collection.isOwned = false
                    collection.dateAcquired = nil
                    
                    // Remove if no longer active
                    if !collection.isActiveCollectionItem {
                        logger.debug("🧹 Deleting UserCollection entry for set \(set.setNumber) as it's no longer active")
                        context.delete(collection)
                        set.userCollection = nil
                    }
                    logger.userAction("removed_from_owned", context: ["setNumber": set.setNumber, "setName": set.name])
                } else {
                    logger.debug("➕ Marking set \(set.setNumber) as owned")
                    collection.markAsOwned()
                    logger.userAction("marked_as_owned", context: ["setNumber": set.setNumber, "setName": set.name])
                }
            } else {
                logger.debug("✨ Creating new owned entry for set \(set.setNumber)")
                // Create new owned entry
                addToCollection(set, in: context, isOwned: true, isWishlist: false)
                return // addToCollection handles its own logging
            }
            
            try context.save()
            let newStatus = set.userCollection?.isOwned ?? false
            logger.info("🔄 Successfully toggled owned status for set \(set.setNumber) to \(newStatus)")
            logger.exitWith(result: "owned status: \(newStatus)")
        } catch {
            logger.error("❌ Failed to toggle owned status for set \(set.setNumber): \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics
    
    /// Get collection statistics
    func getCollectionStats(from context: ModelContext) -> CollectionStats {
        logger.entering()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let descriptor = FetchDescriptor<UserCollection>(
            predicate: #Predicate<UserCollection> { collection in
                collection.isActiveCollectionItem
            }
        )
        
        do {
            let collections = try context.fetch(descriptor)
            logger.debug("📊 Fetched \(collections.count) active collection items for statistics")
            
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
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("📈 Calculated collection statistics: \(stats.ownedSetsCount) owned, \(stats.wishlistCount) wishlist items, \(stats.totalParts) total parts")
            logger.debug("⏱️ Statistics calculation took \(duration, format: .fixed(precision: 3))s")
            logger.exitWith(result: "CollectionStats with \(stats.ownedSetsCount) owned sets")
            
            return stats
        } catch {
            logger.error("❌ Failed to fetch collection statistics: \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
            return CollectionStats()
        }
    }
    
    /// Get sets grouped by theme for owned collection
    func getOwnedSetsByTheme(from context: ModelContext) -> [String: [LegoSet]] {
        logger.entering()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: #Predicate<LegoSet> { set in
                set.userCollection?.isOwned == true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            let sets = try context.fetch(descriptor)
            logger.debug("📚 Fetched \(sets.count) owned sets for theme grouping")
            
            let groupedSets = Dictionary(grouping: sets) { set in
                set.theme?.name ?? "Unknown Theme"
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("🏷️ Grouped owned sets into \(groupedSets.keys.count) themes")
            logger.debug("⏱️ Theme grouping took \(duration, format: .fixed(precision: 3))s")
            
            // Log theme distribution for insights
            let themeCounts = groupedSets.mapValues { $0.count }.sorted { $0.value > $1.value }
            logger.debug("📊 Theme distribution: \(themeCounts.prefix(5).map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
            
            logger.exitWith(result: "\(groupedSets.keys.count) themes with \(sets.count) total sets")
            return groupedSets
        } catch {
            logger.error("❌ Failed to fetch owned sets by theme: \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
            return [:]
        }
    }
    
    /// Get recent acquisitions
    func getRecentAcquisitions(from context: ModelContext, limit: Int = AppConstants.Collection.recentAcquisitionsLimit) -> [UserCollection] {
        logger.entering(parameters: ["limit": limit])
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var descriptor = FetchDescriptor<UserCollection>(
            predicate: #Predicate<UserCollection> { collection in
                collection.isOwned && collection.dateAcquired != nil
            },
            sortBy: [SortDescriptor(\.dateAcquired, order: .reverse)]
        )
        
        descriptor.fetchLimit = limit
        
        do {
            let acquisitions = try context.fetch(descriptor)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            logger.info("📅 Retrieved \(acquisitions.count) recent acquisitions (limit: \(limit))")
            logger.debug("⏱️ Recent acquisitions fetch took \(duration, format: .fixed(precision: 3))s")
            
            // Log some insights about recent acquisitions
            if !acquisitions.isEmpty {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                if let mostRecent = acquisitions.first?.dateAcquired {
                    logger.debug("🔍 Most recent acquisition: \(dateFormatter.string(from: mostRecent))")
                }
                
                let totalValue = acquisitions.compactMap { $0.legoSet?.retailPrice }.reduce(0, +)
                logger.debug("💰 Total value of recent acquisitions: \(totalValue)")
            }
            
            logger.exitWith(result: "\(acquisitions.count) recent acquisitions")
            return acquisitions
        } catch {
            logger.error("❌ Failed to fetch recent acquisitions: \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
            return []
        }
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
