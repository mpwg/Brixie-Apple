//
//  SubthemeRowView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Subtheme row view
struct SubthemeRowView: View {
    let subtheme: Theme
    
    var body: some View {
        HStack {
            Text(subtheme.name)
                .font(.body)
            
            Spacer()
            
            Text("\(subtheme.totalSetCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subtheme.name), \(subtheme.totalSetCount) sets")
    }
}

#Preview {
    // Mock subtheme for preview
    let subtheme = Theme(id: 2, name: "Clone Wars", parentId: 1)
    
    SubthemeRowView(subtheme: subtheme)
        .padding()
}
