//
//  OfflineIndicatorBadge.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import SwiftUI

struct OfflineIndicatorBadge: View {
    @Environment(NetworkMonitorService.self) private var networkMonitor
    @Environment(\.colorScheme) private var colorScheme
    
    let lastSyncTimestamp: SyncTimestamp?
    let variant: BadgeVariant
    
    init(lastSyncTimestamp: SyncTimestamp? = nil, variant: BadgeVariant = .compact) {
        self.lastSyncTimestamp = lastSyncTimestamp
        self.variant = variant
    }
    
    var body: some View {
        Group {
            if !networkMonitor.isConnected {
                offlineBadge
            } else if let timestamp = lastSyncTimestamp {
                lastSyncBadge(timestamp)
            }
        }
    }
    
    private var offlineBadge: some View {
        HStack(spacing: variant.spacing) {
            Image(systemName: networkMonitor.connectionType.iconName)
                .font(.system(size: variant.iconSize, weight: .medium))
                .foregroundStyle(Color.brixieWarning)
            
            if variant.showText {
                Text("Offline")
                    .font(variant.textFont)
                    .foregroundStyle(Color.brixieWarning)
            }
        }
        .padding(.horizontal, variant.horizontalPadding)
        .padding(.vertical, variant.verticalPadding)
        .background(
            Capsule()
                .fill(Color.brixieWarning.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.brixieWarning.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func lastSyncBadge(_ timestamp: SyncTimestamp) -> some View {
        HStack(spacing: variant.spacing) {
            Image(systemName: timestamp.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: variant.iconSize, weight: .medium))
                .foregroundStyle(timestamp.isSuccessful ? Color.brixieSuccess : Color.brixieWarning)
            
            if variant.showText {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last sync")
                        .font(variant.textFont)
                        .foregroundStyle(Color.brixieTextSecondary)
                    
                    Text(formatSyncTime(timestamp.lastSync))
                        .font(variant.textFont)
                        .foregroundStyle(Color.brixieText)
                }
            }
        }
        .padding(.horizontal, variant.horizontalPadding)
        .padding(.vertical, variant.verticalPadding)
        .background(
            Capsule()
                .fill(Color.brixieSecondary.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.brixieSecondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatSyncTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

enum BadgeVariant {
    case compact
    case expanded
    case iconOnly
    
    var spacing: CGFloat {
        switch self {
        case .compact: return 4
        case .expanded: return 8
        case .iconOnly: return 0
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .compact: return 12
        case .expanded: return 14
        case .iconOnly: return 16
        }
    }
    
    var textFont: Font {
        switch self {
        case .compact: return .brixieCaption
        case .expanded: return .brixieBody
        case .iconOnly: return .brixieCaption
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 8
        case .expanded: return 12
        case .iconOnly: return 6
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .compact: return 4
        case .expanded: return 6
        case .iconOnly: return 4
        }
    }
    
    var showText: Bool {
        switch self {
        case .compact, .expanded: return true
        case .iconOnly: return false
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        OfflineIndicatorBadge(variant: .compact)
        OfflineIndicatorBadge(variant: .expanded)
        OfflineIndicatorBadge(variant: .iconOnly)
        OfflineIndicatorBadge(
            lastSyncTimestamp: SyncTimestamp(
                id: "preview",
                lastSync: Date().addingTimeInterval(-3600),
                syncType: .sets
            ),
            variant: .expanded
        )
    }
    .padding()
    .environment(NetworkMonitorService.shared)
}