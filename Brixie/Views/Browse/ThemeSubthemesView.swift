//
//  ThemeSubthemesView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Theme subthemes view
struct ThemeSubthemesView: View {
    let theme: Theme
    let onSubthemeSelected: (Theme) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.standardSpacing) {
            // Header
            HStack {
                Text(theme.name)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding(.horizontal)
            
            if theme.subthemes.isEmpty {
                ContentUnavailableView("No Subcategories", 
                                     systemImage: "folder",
                                     description: Text("This theme has no subcategories"))
            } else {
                // Grid of subthemes
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: AppConstants.UI.gridItemMinWidth), spacing: AppConstants.UI.standardSpacing)
                ], spacing: 16) {
                    ForEach(theme.subthemes.sorted(by: { $0.name < $1.name })) { subtheme in
                        SubthemeCardView(subtheme: subtheme) {
                            onSubthemeSelected(subtheme)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

#Preview {
    // Mock theme with subthemes for preview
    let theme = Theme(id: 1, name: "Star Wars", parentId: nil)
    
    ThemeSubthemesView(theme: theme) { subtheme in
        // Preview action - no-op for preview
        print("Selected subtheme: \(subtheme.name)")
    }
}