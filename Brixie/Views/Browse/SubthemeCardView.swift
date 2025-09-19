//
//  SubthemeCardView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Subtheme card view
struct SubthemeCardView: View {
    let subtheme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(subtheme.name)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("\(subtheme.totalSetCount) sets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subtheme.name), \(subtheme.totalSetCount) sets")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    // Mock subtheme for preview
    let subtheme = Theme(id: 2, name: "Clone Wars", parentId: 1)
    
    SubthemeCardView(subtheme: subtheme) {
        print("Selected subtheme: \(subtheme.name)")
    }
    .padding()
}