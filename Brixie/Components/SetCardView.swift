import SwiftUI
import SwiftData

struct SetCardView: View {
    let set: LegoSet
    
    @Environment(\.modelContext) private var modelContext
    private let collectionService = CollectionService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncCachedImage(url: set.imageURL) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
            }
            .frame(height: 120)
            .accessibilityLabel("Image of LEGO set \(set.name)")
            
            Text(set.name)
                .font(.headline)
                .accessibilityIdentifier("setName")
            Text("Set #\(set.setNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("setNumber")
            Text("Year: \(set.year)")
                .font(.caption)
                .accessibilityIdentifier("setYear")
            Text("Parts: \(set.numParts)")
                .font(.caption)
                .accessibilityIdentifier("setParts")
                
            // Collection Status Indicators
            HStack(spacing: 4) {
                if set.userCollection?.isOwned == true {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .accessibilityLabel("Owned")
                }
                
                if set.userCollection?.isWishlist == true {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                        .accessibilityLabel("On wishlist")
                }
                
                if set.userCollection?.hasMissingParts == true {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)
                        .accessibilityLabel("Missing parts")
                }
                
                Spacer()
                
                // Quick action buttons
                HStack(spacing: 2) {
                    Button(action: {
                        collectionService.toggleOwned(set, in: modelContext)
                    }) {
                        Image(systemName: set.userCollection?.isOwned == true ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundStyle(set.userCollection?.isOwned == true ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(set.userCollection?.isOwned == true ? "Remove from collection" : "Add to collection")
                    
                    Button(action: {
                        collectionService.toggleWishlist(set, in: modelContext)
                    }) {
                        Image(systemName: set.userCollection?.isWishlist == true ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(set.userCollection?.isWishlist == true ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(set.userCollection?.isWishlist == true ? "Remove from wishlist" : "Add to wishlist")
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LEGO set \(set.name), number \(set.setNumber), year \(set.year), \(set.numParts) parts")
    }
}

#Preview {
    SetCardView(set: LegoSet.example)
}
