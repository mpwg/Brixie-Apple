//
//  Theme.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftData

/// A LEGO theme model for SwiftData persistence
@Model
final class Theme {
    /// Unique theme ID from Rebrickable API
    @Attribute(.unique) var id: Int
    
    /// Theme name (e.g., "Star Wars", "Creator Expert")
    var name: String
    
    /// Parent theme ID for hierarchical themes (nil for root themes)
    var parentId: Int?
    
    /// Last modified date from API
    var lastModified: Date
    
    /// Display order for sorting themes
    var sortOrder: Int?
    
    // MARK: - Relationships
    
    /// LEGO sets belonging to this theme
    @Relationship(deleteRule: .nullify)
    var sets: [LegoSet] = []
    
    /// Child themes (subthemes)
    @Relationship(deleteRule: .cascade)
    var subthemes: [Theme] = []
    
    /// Parent theme reference
    @Relationship(deleteRule: .nullify, inverse: \Theme.subthemes)
    var parentTheme: Theme?
    
    // MARK: - Initialization
    
    init(
        id: Int,
        name: String,
        parentId: Int? = nil,
        lastModified: Date = Date(),
        sortOrder: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.lastModified = lastModified
        self.sortOrder = sortOrder
    }
}

// MARK: - Convenience Properties

extension Theme {
    /// Whether this is a root theme (no parent)
    var isRootTheme: Bool {
        return parentId == nil
    }
    
    /// Whether this theme has subthemes
    var hasSubthemes: Bool {
        return !subthemes.isEmpty
    }
    
    /// Total number of sets in this theme and all subthemes
    var totalSetCount: Int {
        let directSets = sets.count
        let subthemeSets = subthemes.reduce(0) { $0 + $1.totalSetCount }
        return directSets + subthemeSets
    }
    
    /// Hierarchical display name showing parent context
    var hierarchicalName: String {
        guard let parentTheme = parentTheme else {
            return name
        }
        return "\(parentTheme.name) → \(name)"
    }
    
    /// All ancestor themes up to the root
    var ancestorThemes: [Theme] {
        var ancestors: [Theme] = []
        var current = parentTheme
        
        while let theme = current {
            ancestors.append(theme)
            current = theme.parentTheme
        }
        
        return ancestors.reversed()
    }
    
    /// Full hierarchy path as string
    var hierarchyPath: String {
        let ancestors = ancestorThemes.map(\.name)
        return (ancestors + [name]).joined(separator: " → ")
    }
}

// MARK: - Sorting and Filtering

extension Theme {
    /// Sort themes by name alphabetically
    static func sortedByName(_ themes: [Theme]) -> [Theme] {
        return themes.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    /// Sort themes by set count (descending)
    static func sortedBySetCount(_ themes: [Theme]) -> [Theme] {
        return themes.sorted { $0.totalSetCount > $1.totalSetCount }
    }
    
    /// Filter themes that have sets (directly or in subthemes)
    static func withSets(_ themes: [Theme]) -> [Theme] {
        return themes.filter { $0.totalSetCount > 0 }
    }
}
