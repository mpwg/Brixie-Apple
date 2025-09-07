//
//  FavoriteButton.swift
//  Brixie
//
//  Created by Claude on 07.09.25.
//
import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    var prominent: Bool = false

    var body: some View {
        Group {
            if prominent {
                Button(action: action) {
                    Label(isFavorite ? NSLocalizedString("Remove from Favorites", comment: "") : NSLocalizedString("Add to Favorites", comment: ""), systemImage: isFavorite ? "heart.slash" : "heart")
                }
                .buttonStyle(.borderedProminent)
                .tint(isFavorite ? .red : .blue)
                .brixieAccessibility(
                    label: isFavorite ? NSLocalizedString("Remove from Favorites", comment: "Favorite button accessibility") : NSLocalizedString("Add to Favorites", comment: "Favorite button accessibility"),
                    hint: NSLocalizedString("Double tap to toggle favorite status", comment: "Favorite button hint"),
                    traits: .isButton
                )
            } else {
                Button(action: action) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .gray)
                }
                .buttonStyle(.plain)
                .brixieAccessibility(
                    label: isFavorite ? NSLocalizedString("Remove from favorites", comment: "Favorite button accessibility") : NSLocalizedString("Add to favorites", comment: "Favorite button accessibility"),
                    hint: NSLocalizedString("Double tap to toggle favorite status", comment: "Favorite button hint"),
                    traits: .isButton
                )
            }
        }
    }
}

struct FavoriteButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            FavoriteButton(isFavorite: true, action: {}, prominent: false)
            FavoriteButton(isFavorite: false, action: {}, prominent: false)
            FavoriteButton(isFavorite: true, action: {}, prominent: true)
            FavoriteButton(isFavorite: false, action: {}, prominent: true)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
