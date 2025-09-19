import SwiftUI
import SwiftData

struct SetCardView: View {
    let set: LegoSet
    
    @Environment(\.modelContext) private var modelContext
    private let collectionService = CollectionService.shared
    
    @State private var isPressed = false
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.smallSpacing) {
            AsyncCachedImage(url: URL(string: set.imageURL ?? ""))
                .frame(height: AppConstants.UI.cardImageHeight)
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            collectionService.toggleOwned(set, in: modelContext)
                        }
                        // Add haptic feedback when available
                        #if canImport(UIKit)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        #endif
                    }) {
                        Image(systemName: set.userCollection?.isOwned == true ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundStyle(set.userCollection?.isOwned == true ? .red : .secondary)
                            .scaleEffect(set.userCollection?.isOwned == true ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(set.userCollection?.isOwned == true ? "Remove from collection" : "Add to collection")
                    .animation(.easeInOut(duration: 0.3), value: set.userCollection?.isOwned == true)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            collectionService.toggleWishlist(set, in: modelContext)
                        }
                        #if canImport(UIKit)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        #endif
                    }) {
                        Image(systemName: set.userCollection?.isWishlist == true ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(set.userCollection?.isWishlist == true ? .yellow : .secondary)
                            .scaleEffect(set.userCollection?.isWishlist == true ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(set.userCollection?.isWishlist == true ? "Remove from wishlist" : "Add to wishlist")
                    .animation(.easeInOut(duration: 0.3), value: set.userCollection?.isWishlist == true)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(
            color: .black.opacity(isHovering ? 0.15 : 0.1), 
            radius: isHovering ? 6 : 2,
            y: isHovering ? 3 : 1
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LEGO set \(set.name), number \(set.setNumber), year \(set.year), \(set.numParts) parts")
    }
}

#Preview {
    SetCardView(set: LegoSet.example)
}
