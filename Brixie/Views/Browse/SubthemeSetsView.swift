//
//  SubthemeSetsView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Subtheme sets view
struct SubthemeSetsView: View {
    let subtheme: Theme
    let sets: [LegoSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtheme.name)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    if let parent = subtheme.parentTheme {
                        Text(parent.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
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
                                     description: Text("No LEGO sets found in this category"))
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
    // Mock subtheme and sets for preview
    let subtheme = Theme(id: 2, name: "Clone Wars", parentId: 1)
    let mockSets: [LegoSet] = []
    
    SubthemeSetsView(subtheme: subtheme, sets: mockSets)
}
