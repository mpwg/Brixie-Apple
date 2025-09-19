//
//  ThemeRowView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Theme row for sidebar
struct ThemeRowView: View {
    let theme: Theme
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppConstants.Layout.buttonRowSpacing) {
                Text(theme.name)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                if theme.hasSubthemes {
                    Text("\(theme.subthemes.count) categories")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(AppConstants.Opacity.secondaryText) : .secondary)
                } else {
                    Text("\(theme.totalSetCount) sets")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(AppConstants.Opacity.secondaryText) : .secondary)
                }
                
                // Debug info (temporary)
                #if DEBUG
                Text("ID: \(theme.id)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                #endif
            }
            
            Spacer()
            
            if theme.hasSubthemes {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(AppConstants.Opacity.secondaryText) : .secondary)
            }
        }
        .padding(.vertical, AppConstants.Layout.cardContentSpacing)
        .padding(.horizontal, AppConstants.UI.smallSpacing)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.button)
                .fill(isSelected ? .blue : .clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(theme.name), \(theme.hasSubthemes ? "\(theme.subthemes.count) categories" : "\(theme.totalSetCount) sets")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    // Mock theme for preview
    let theme = Theme(id: AppConstants.SampleData.sampleThemeId, name: AppConstants.SampleData.sampleThemeName, parentId: nil)
    
    VStack {
        ThemeRowView(theme: theme, isSelected: false)
        ThemeRowView(theme: theme, isSelected: true)
    }
    .padding()
}