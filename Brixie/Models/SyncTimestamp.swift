//
//  SyncTimestamp.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import SwiftData

@Model
final class SyncTimestamp {
    var id: String
    var lastSync: Date
    var syncType: SyncType
    var isSuccessful: Bool
    var itemCount: Int
    
    init(id: String, lastSync: Date, syncType: SyncType, isSuccessful: Bool = true, itemCount: Int = 0) {
        self.id = id
        self.lastSync = lastSync
        self.syncType = syncType
        self.isSuccessful = isSuccessful
        self.itemCount = itemCount
    }
}

enum SyncType: String, CaseIterable, Codable, Sendable {
    case sets = "sets"
    case themes = "themes"
    case search = "search"
    case setDetails = "setDetails"
    
    var displayName: String {
        switch self {
        case .sets:
            return NSLocalizedString("Sets", comment: "Sets sync type")
        case .themes:
            return NSLocalizedString("Themes", comment: "Themes sync type")
        case .search:
            return NSLocalizedString("Search", comment: "Search sync type")
        case .setDetails:
            return NSLocalizedString("Set Details", comment: "Set details sync type")
        }
    }
}