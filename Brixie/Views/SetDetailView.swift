import SwiftUI
import SwiftData

struct SetDetailView: View {
    let set: LegoSet
    
    @Environment(\.modelContext) private var modelContext
    private let collectionService = CollectionService.shared
    
    @State private var showingMissingParts = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncCachedImage(url: URL(string: set.primaryImageURL ?? "")) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                }
                .frame(height: 200)
                .accessibilityLabel("Image of LEGO set \(set.name)")
                
                Text(set.name)
                    .font(.title)
                    .accessibilityIdentifier("setDetailName")
                Text("Set #\(set.setNumber)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("setDetailNumber")
                Text("Year: \(set.year)")
                    .font(.subheadline)
                    .accessibilityIdentifier("setDetailYear")
                Text("Parts: \(set.numParts)")
                    .font(.subheadline)
                    .accessibilityIdentifier("setDetailParts")
                
                if let gallery = set.imageGallery, !gallery.isEmpty {
                    Text("Gallery")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(gallery, id: \.self) { url in
                                AsyncCachedImage(url: url) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                }
                                .frame(width: 120, height: 120)
                                .accessibilityLabel("Gallery image for \(set.name)")
                            }
                        }
                    }
                    .accessibilityIdentifier("setGallery")
                }
                
                // Collection Management Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        collectionService.toggleOwned(set, in: modelContext)
                    }) {
                        HStack {
                            Image(systemName: set.userCollection?.isOwned == true ? "heart.fill" : "heart")
                            Text(set.userCollection?.isOwned == true ? "Remove from Collection" : "Add to Collection")
                        }
                        .foregroundStyle(set.userCollection?.isOwned == true ? .red : .blue)
                    }
                    .accessibilityIdentifier("ownedToggle")
                    
                    Button(action: {
                        collectionService.toggleWishlist(set, in: modelContext)
                    }) {
                        HStack {
                            Image(systemName: set.userCollection?.isWishlist == true ? "star.fill" : "star")
                            Text(set.userCollection?.isWishlist == true ? "Remove from Wishlist" : "Add to Wishlist")
                        }
                        .foregroundStyle(set.userCollection?.isWishlist == true ? .yellow : .blue)
                    }
                    .accessibilityIdentifier("wishlistToggle")
                }
                .buttonStyle(.bordered)
                
                // Collection Status Information
                if let collection = set.userCollection, collection.isActiveCollectionItem {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collection Status")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        if collection.isOwned {
                            Label("Owned", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            if let dateAcquired = collection.dateAcquired {
                                Text("Acquired: \(dateAcquired.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let price = collection.formattedPurchasePrice {
                                Text("Purchase Price: \(price)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let condition = collection.condition {
                                Text("Condition: \(collection.conditionStars)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if collection.hasMissingParts {
                                Label("\(collection.missingPartsCount) missing parts", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                        }
                        
                        if collection.isWishlist {
                            Label("On Wishlist", systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                        
                        // Missing parts management for owned sets
                        if collection.isOwned {
                            Button(action: {
                                showingMissingParts = true
                            }) {
                                Label("Manage Missing Parts", systemImage: "wrench.and.screwdriver")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("manageMissingParts")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Pure SwiftUI sharing using ShareLink (iOS 16+/macOS 13+)
                ShareLink(item: shareText, preview: SharePreview(set.name)) {
                    Label("Share Set", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("shareButton")
            }
            .padding()
        }
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $showingMissingParts) {
            if let collection = set.userCollection {
                MissingPartsView(userCollection: collection)
            }
        }
    }
    
    private var shareText: String {
        "Check out LEGO set \(set.name) (#\(set.setNumber)), released in \(set.year) with \(set.numParts) parts!"
    }
}
#Preview {
    SetDetailView(set: LegoSet.example)
}
