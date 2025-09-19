//
//  UserCollection.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftData

/// User collection tracking for LEGO sets
@Model
final class UserCollection {
    /// Unique identifier for this collection entry
    @Attribute(.unique) var id: UUID
    
    /// Whether the user owns this set ("Meine LEGO-Sammlung")
    var isOwned: Bool
    
    /// Whether this set is on the user's wishlist ("LEGO-Wunschliste")
    var isWishlist: Bool
    
    /// Whether the set has missing parts ("Fehlende Teile")
    var hasMissingParts: Bool
    
    /// Whether the set is in a sealed box ("Versiegelte Box")
    var isSealedBox: Bool
    
    /// Date when this entry was added to the collection
    var dateAdded: Date
    
    /// Date when the set was acquired (if owned)
    var dateAcquired: Date?
    
    /// Purchase price if known
    var purchasePrice: Decimal?
    
    /// Purchase currency
    var priceCurrency: String?
    
    /// Purchase location/store
    var purchaseLocation: String?
    
    /// User notes about this set
    var notes: String?
    
    /// Condition rating (1-5 scale, 5 being mint)
    var condition: Int?
    
    /// Whether this set is built or unbuilt
    var isBuilt: Bool
    
    /// Current location of the set
    var storageLocation: String?
    
    // MARK: - Relationships
    
    /// The associated LEGO set
    @Relationship(deleteRule: .nullify)
    var legoSet: LegoSet?
    
    // MARK: - Initialization
    
    init(
        isOwned: Bool = false,
        isWishlist: Bool = false,
        hasMissingParts: Bool = false,
        isSealedBox: Bool = false,
        dateAdded: Date = Date(),
        dateAcquired: Date? = nil,
        purchasePrice: Decimal? = nil,
        priceCurrency: String? = nil,
        purchaseLocation: String? = nil,
        notes: String? = nil,
        condition: Int? = nil,
        isBuilt: Bool = false,
        storageLocation: String? = nil
    ) {
        self.id = UUID()
        self.isOwned = isOwned
        self.isWishlist = isWishlist
        self.hasMissingParts = hasMissingParts
        self.isSealedBox = isSealedBox
        self.dateAdded = dateAdded
        self.dateAcquired = dateAcquired
        self.purchasePrice = purchasePrice
        self.priceCurrency = priceCurrency
        self.purchaseLocation = purchaseLocation
        self.notes = notes
        self.condition = condition
        self.isBuilt = isBuilt
        self.storageLocation = storageLocation
    }
}

// MARK: - Convenience Properties

extension UserCollection {
    /// Collection status as a localized string
    var statusDescription: String {
        var statuses: [String] = []
        
        if isOwned {
            statuses.append("Owned") // Will be localized
        }
        if isWishlist {
            statuses.append("Wishlist") // Will be localized
        }
        if hasMissingParts {
            statuses.append("Missing Parts") // Will be localized
        }
        if isSealedBox {
            statuses.append("Sealed Box") // Will be localized
        }
        
        return statuses.isEmpty ? "No Status" : statuses.joined(separator: ", ")
    }
    
    /// Formatted purchase price including currency
    var formattedPurchasePrice: String? {
        guard let purchasePrice = purchasePrice else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let currency = priceCurrency {
            formatter.currencyCode = currency
        }
        
        return formatter.string(from: purchasePrice as NSDecimalNumber)
    }
    
    /// Condition as a star rating string
    var conditionStars: String {
        guard let condition = condition, condition > 0, condition <= 5 else {
            return "Not Rated"
        }
        
        return String(repeating: "★", count: condition) + String(repeating: "☆", count: 5 - condition)
    }
    
    /// Whether this entry represents an active collection item
    var isActiveCollectionItem: Bool {
        return isOwned || isWishlist
    }
    
    /// Time since added to collection
    var timeSinceAdded: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: dateAdded, relativeTo: Date())
    }
    
    /// Estimated value increase (if purchase price and retail price are available)
    var valueChange: Decimal? {
        guard let purchasePrice = purchasePrice,
              let retailPrice = legoSet?.retailPrice else {
            return nil
        }
        return retailPrice - purchasePrice
    }
    
    /// Percentage value increase
    var valueChangePercentage: Double? {
        guard let purchasePrice = purchasePrice,
              let valueChange = valueChange,
              purchasePrice > 0 else {
            return nil
        }
        return Double(truncating: (valueChange / purchasePrice * 100) as NSDecimalNumber)
    }
    
    /// Collection completion status (percentage based on missing parts)
    var completionPercentage: Double {
        return hasMissingParts ? 90.0 : 100.0
    }
    
    /// Count of missing parts
    var missingPartsCount: Int {
        return hasMissingParts ? 1 : 0
    }
    
    /// Count of ordered parts
    var orderedPartsCount: Int {
        return 0
    }
    
    /// Total replacement cost for missing parts
    var totalReplacementCost: Decimal? {
        return nil
    }
}

// MARK: - Collection Management

extension UserCollection {
    /// Add to owned collection
    func markAsOwned(dateAcquired: Date = Date()) {
        isOwned = true
        self.dateAcquired = dateAcquired
        
        // Remove from wishlist when owned
        isWishlist = false
    }
    
    /// Add to wishlist
    func addToWishlist() {
        isWishlist = true
        
        // Can't be owned and on wishlist simultaneously
        if isOwned {
            isWishlist = false
        }
    }
    
    /// Remove from all collections
    func removeFromCollections() {
        isOwned = false
        isWishlist = false
        dateAcquired = nil
    }
    
    /// Update condition rating
    func updateCondition(_ rating: Int) {
        condition = max(1, min(5, rating)) // Clamp between 1-5
    }
}
