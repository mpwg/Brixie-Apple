//
//  MissingPart.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftData

/// Represents a missing part from a LEGO set
@Model
final class MissingPart {
    /// Unique identifier
    @Attribute(.unique) var id: UUID
    
    /// Part number from LEGO/Rebrickable
    var partNumber: String
    
    /// Part name/description
    var partName: String?
    
    /// Color of the part
    var colorName: String?
    
    /// Color ID from Rebrickable
    var colorId: Int?
    
    /// Quantity missing
    var quantity: Int
    
    /// Date when part was marked as missing
    var dateMissing: Date
    
    /// Whether the part has been ordered/acquired
    var isOrdered: Bool
    
    /// Date when part was ordered (if applicable)
    var dateOrdered: Date?
    
    /// Price paid for replacement part
    var replacementPrice: Decimal?
    
    /// Currency for replacement price
    var priceCurrency: String?
    
    /// Where the part was ordered from
    var orderSource: String?
    
    /// User notes about this missing part
    var notes: String?
    
    // MARK: - Relationships
    
    /// The collection entry this missing part belongs to
    @Relationship(deleteRule: .cascade, inverse: \UserCollection.missingParts)
    var userCollection: UserCollection?
    
    // MARK: - Initialization
    
    init(
        partNumber: String,
        partName: String? = nil,
        colorName: String? = nil,
        colorId: Int? = nil,
        quantity: Int = 1,
        dateMissing: Date = Date(),
        isOrdered: Bool = false,
        dateOrdered: Date? = nil,
        replacementPrice: Decimal? = nil,
        priceCurrency: String? = nil,
        orderSource: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.partNumber = partNumber
        self.partName = partName
        self.colorName = colorName
        self.colorId = colorId
        self.quantity = quantity
        self.dateMissing = dateMissing
        self.isOrdered = isOrdered
        self.dateOrdered = dateOrdered
        self.replacementPrice = replacementPrice
        self.priceCurrency = priceCurrency
        self.orderSource = orderSource
        self.notes = notes
    }
}

// MARK: - Convenience Properties

extension MissingPart {
    /// Formatted part description
    var partDescription: String {
        var desc = partNumber
        
        if let name = partName {
            desc += " - \(name)"
        }
        
        if let color = colorName {
            desc += " (\(color))"
        }
        
        return desc
    }
    
    /// Formatted replacement price
    var formattedReplacementPrice: String? {
        guard let replacementPrice = replacementPrice else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let currency = priceCurrency {
            formatter.currencyCode = currency
        }
        
        return formatter.string(from: replacementPrice as NSDecimalNumber)
    }
    
    /// Status description
    var statusDescription: String {
        if isOrdered {
            return "Ordered"
        } else {
            return "Missing"
        }
    }
    
    /// Time since missing
    var timeSinceMissing: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateMissing, relativeTo: Date())
    }
}

// MARK: - Part Management

extension MissingPart {
    /// Mark part as ordered
    func markAsOrdered(from source: String? = nil, price: Decimal? = nil, currency: String? = nil) {
        isOrdered = true
        dateOrdered = Date()
        orderSource = source
        replacementPrice = price
        priceCurrency = currency
    }
    
    /// Mark part as still missing
    func markAsMissing() {
        isOrdered = false
        dateOrdered = nil
        orderSource = nil
    }
}