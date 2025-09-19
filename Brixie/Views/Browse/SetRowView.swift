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
        HStack(spacing: AppConstants.Layout.listRowSpacing) {
            AsyncCachedImage(thumbnailURL: URL(string: set.primaryImageURL ?? ""))
                .frame(width: AppConstants.ImageSize.thumbnailWidth, height: AppConstants.ImageSize.thumbnailHeight)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.thumbnail))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: AppConstants.Layout.cardContentSpacing) {
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
        setNumber: AppConstants.SampleData.sampleSetNumber,
        name: "Luke Skywalker's X-wing Fighter",
        year: AppConstants.SampleData.sampleYear,
        themeId: AppConstants.SampleData.sampleSetThemeId,
        numParts: AppConstants.SampleData.samplePieceCount
    )
    
    SetRowView(set: mockSet)
        .padding()
}
