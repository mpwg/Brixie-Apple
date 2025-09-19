import SwiftUI
import SwiftData

struct SetDetailView: View {
    let set: LegoSet
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SetDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncCachedImage(url: URL(string: set.primaryImageURL ?? ""))
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
                
                // Collection Management Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.toggleOwned(set, in: modelContext)
                    }) {
                        HStack {
                            Image(systemName: set.userCollection?.isOwned == true ? "heart.fill" : "heart")
                            Text(set.userCollection?.isOwned == true ? "Remove from Collection" : "Add to Collection")
                        }
                        .foregroundStyle(set.userCollection?.isOwned == true ? .red : .blue)
                    }
                    .accessibilityIdentifier("ownedToggle")
                    
                    Button(action: {
                        viewModel.toggleWishlist(set, in: modelContext)
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
                            
                            if collection.condition != nil {
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
                            Button("View Missing Parts") {
                                viewModel.showMissingParts()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingMissingParts) {
            if let collection = set.userCollection {
                MissingPartsView(userCollection: collection)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
            Button("OK") { viewModel.error = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

#Preview {
    SetDetailView(set: LegoSet.example)
}
