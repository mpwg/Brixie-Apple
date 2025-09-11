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
            } else {
                Button(action: action) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .gray)
                }
                .buttonStyle(.plain)
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
