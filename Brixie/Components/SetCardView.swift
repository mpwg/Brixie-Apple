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
            AsyncCachedImage(url: URL(string: set.imageURL ?? ""), imageType: .medium)
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
            HStack(spacing: AppConstants.Layout.cardContentSpacing) {
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
                HStack(spacing: AppConstants.Layout.buttonRowSpacing) {
                    Button(action: {
                        withAnimation(AppConstants.CommonAnimations.normalEaseInOut) {
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
                            .scaleEffect(set.userCollection?.isOwned == true ? AppConstants.Scale.selected : AppConstants.Scale.base)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(set.userCollection?.isOwned == true ? "Remove from collection" : "Add to collection")
                    .animation(AppConstants.CommonAnimations.normalEaseInOut, value: set.userCollection?.isOwned == true)
                    
                    Button(action: {
                        withAnimation(AppConstants.CommonAnimations.normalEaseInOut) {
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
                            .scaleEffect(set.userCollection?.isWishlist == true ? AppConstants.Scale.selected : AppConstants.Scale.base)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(set.userCollection?.isWishlist == true ? "Remove from wishlist" : "Add to wishlist")
                    .animation(AppConstants.CommonAnimations.normalEaseInOut, value: set.userCollection?.isWishlist == true)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card).fill(Color(.systemBackground)))
        .scaleEffect(isPressed ? AppConstants.Scale.pressed : AppConstants.Scale.base)
        .shadow(
            color: .black.opacity(isHovering ? AppConstants.VisualEffects.hoverShadowOpacity : AppConstants.VisualEffects.standardShadowOpacity), 
            radius: isHovering ? AppConstants.VisualEffects.hoverShadowRadius : AppConstants.VisualEffects.standardShadowRadius,
            y: isHovering ? AppConstants.VisualEffects.hoverShadowY : AppConstants.VisualEffects.standardShadowY
        )
        .onHover { hovering in
            withAnimation(AppConstants.CommonAnimations.quickEaseInOut) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            withAnimation(AppConstants.CommonAnimations.quickEaseInOut) {
                isPressed = true
            }
            
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(AppConstants.Delays.quick) / 1_000_000_000) {
                withAnimation(AppConstants.CommonAnimations.quickEaseInOut) {
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
