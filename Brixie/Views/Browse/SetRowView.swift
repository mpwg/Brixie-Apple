//
//  SetRowView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import Foundation

/// Set row view for lists
struct SetRowView: View {
    let set: LegoSet
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncCachedImage(thumbnailURL: URL(string: set.primaryImageURL ?? ""))
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("#\(set.setNumber) • \(set.year)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.name), set number \(set.setNumber), year \(set.year)")
    }
}

#Preview {
    // Mock set for preview  
    let mockSet = LegoSet(
        setNumber: "75301",
        name: "Luke Skywalker's X-wing Fighter",
        year: 2021,
        themeId: 158,
        numParts: 474
    )
    
    SetRowView(set: mockSet)
        .padding()
}