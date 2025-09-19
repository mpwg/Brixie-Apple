//
//  LegoSet.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftData

/// A LEGO set model for SwiftData persistence
@Model
final class LegoSet {
    /// Unique set number (e.g., "75192")
    @Attribute(.unique) var setNumber: String
    
    /// Set name (e.g., "Millennium Falcon")
    var name: String
    
    /// Year of release
    var year: Int
    
    /// Theme ID reference
    var themeId: Int
    
    /// Number of parts in the set
    var numParts: Int
    
    /// URL for the set image
    var setImageURL: String?
    
    /// Last modified date from API
    var lastModified: Date
    
    /// Set image URL (alternate naming for compatibility)
    var imageURL: String?
    
    /// Retail price if available
    var retailPrice: Decimal?
    
    /// Currency code for retail price
    var priceCurrency: String?
    
    /// Build instructions URL if available
    var instructionsURL: String?
    
    // MARK: - Relationships
    
    /// Associated theme
    @Relationship(deleteRule: .nullify, inverse: \Theme.sets)
    var theme: Theme?
    
    /// User collection entry if exists
    @Relationship(deleteRule: .cascade, inverse: \UserCollection.legoSet)
    var userCollection: UserCollection?
    
    // MARK: - Initialization
    
    init(
        setNumber: String,
        name: String,
        year: Int,
        themeId: Int,
        numParts: Int,
        setImageURL: String? = nil,
        lastModified: Date = Date(),
        imageURL: String? = nil,
        retailPrice: Decimal? = nil,
        priceCurrency: String? = nil,
        instructionsURL: String? = nil
    ) {
        self.setNumber = setNumber
        self.name = name
        self.year = year
        self.themeId = themeId
        self.numParts = numParts
        self.setImageURL = setImageURL
        self.lastModified = lastModified
        self.imageURL = imageURL ?? setImageURL
        self.retailPrice = retailPrice
        self.priceCurrency = priceCurrency
        self.instructionsURL = instructionsURL
    }
}

// MARK: - Convenience Properties

extension LegoSet {
    /// Primary image URL, preferring setImageURL over imageURL
    var primaryImageURL: String? {
        return setImageURL ?? imageURL
    }
    
    /// Formatted price string including currency
    var formattedPrice: String? {
        guard let retailPrice = retailPrice else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let currency = priceCurrency {
            formatter.currencyCode = currency
        }
        
        return formatter.string(from: retailPrice as NSDecimalNumber)
    }
    
    /// Formatted part count with localization
    var formattedPartCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: numParts)) ?? "\(numParts)"
    }
    
    /// Display name combining set number and name
    var displayName: String {
        return "\(setNumber) - \(name)"
    }
}

// MARK: - Preview Support

extension LegoSet {
    /// Example LEGO set for previews and testing
    static var example: LegoSet {
        let set = LegoSet(
            setNumber: "75192",
            name: "Millennium Falcon",
            year: 2017,
            themeId: 171,
            numParts: 7541,
            setImageURL: "https://cdn.rebrickable.com/media/sets/75192-1/53219.jpg",
            lastModified: Date()
        )
        set.retailPrice = 799.99
        set.priceCurrency = "USD"
        return set
    }
}

// MARK: - Hashable & Equatable
