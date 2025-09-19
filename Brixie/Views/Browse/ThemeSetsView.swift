//
//  ThemeSetsView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Theme sets view
struct ThemeSetsView: View {
    let theme: Theme
    let sets: [LegoSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("\(sets.count) sets")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            if sets.isEmpty {
                ContentUnavailableView("No Sets", 
                                     systemImage: "cube",
                                     description: Text("No LEGO sets found in this theme"))
            } else {
                List(sets) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        SetRowView(set: set)
                    }
                }
            }
        }
    }
}

#Preview {
    // Mock theme and sets for preview
    let theme = Theme(id: 1, name: "Star Wars", parentId: nil)
    let mockSets: [LegoSet] = []
    
    ThemeSetsView(theme: theme, sets: mockSets)
}