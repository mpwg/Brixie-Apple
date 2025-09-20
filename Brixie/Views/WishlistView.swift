//
//  WishlistView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

struct WishlistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WishlistViewModel()
    
    @Query private var wishedSets: [LegoSet]

    init() {
        _wishedSets = Query(filter: #Predicate<LegoSet> { set in
            set.userCollection?.isWishlist == true
        }, sort: \LegoSet.name)
    }

    var body: some View {
        NavigationStack {
            VStack {
                if wishedSets.isEmpty {
                    EmptyStateView.emptyWishlist()
                } else {
                    wishlistContent
                }
            }
            .navigationTitle("Wishlist")
            .searchable(text: $viewModel.searchText, prompt: "Search wishlist...")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Sort By") {
                            Picker("Sort", selection: $viewModel.selectedSortOption) {
                                ForEach(WishlistSortOption.allCases, id: \.self) { option in
                                    Label(option.title, systemImage: option.icon)
                                        .tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Section("Actions") {
                            ShareLink(
                                item: wishlistShareText,
                                preview: SharePreview("My LEGO Wishlist")
                            ) {
                                Label("Share Wishlist", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var wishlistContent: some View {
        List {
            // Wishlist summary
            Section {
                WishlistSummaryCardView()
            }
            
            // Priority groups
            ForEach(groupedWishlistSets.keys.sorted(), id: \.self) { groupName in
                Section(header: Text(groupName)) {
                    ForEach(groupedWishlistSets[groupName] ?? []) { set in
                        NavigationLink(destination: SetDetailView(set: set)) {
                            WishlistSetRowView(set: set)
                        }
                        .id(set.id) // Explicit view identity
                        .swipeActions(edge: .leading) {
                            Button("Own It") {
                                // Move from wishlist to collection
                                let collectionService = CollectionService.shared
                                collectionService.addToCollection(set, in: modelContext, isOwned: true, isWishlist: false)
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Remove") {
                                let collectionService = CollectionService.shared
                                collectionService.toggleWishlist(set, in: modelContext)
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.plain) // Use plain style for performance
    }
    
    private var filteredSets: [LegoSet] {
        return viewModel.sortSets(viewModel.filterSets(wishedSets))
    }
    
    private var groupedWishlistSets: [String: [LegoSet]] {
        return Dictionary(grouping: filteredSets) { set in
            set.theme?.name ?? "Unknown Theme"
        }
    }
    
    private var wishlistShareText: String {
        let setList = wishedSets.prefix(10).map { "#\($0.setNumber) \($0.name)" }.joined(separator: "\n")
        let totalValue = wishedSets.compactMap { $0.retailPrice }.reduce(0, +)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let formattedTotal = formatter.string(from: totalValue as NSDecimalNumber) ?? "$0"
        
        return """
        My LEGO Wishlist (\(wishedSets.count) sets, ~\(formattedTotal)):
        
        \(setList)
        \(wishedSets.count > 10 ? "\n...and \(wishedSets.count - 10) more!" : "")
        
        Created with Brixie
        """
    }
}

// MARK: - Supporting Views

private struct WishlistSummaryCardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WishlistViewModel()
    
    var body: some View {
        let stats = viewModel.getCollectionStats(from: modelContext)
        
        HStack(spacing: AppConstants.UI.largePadding) {
            VStack {
                Text("\(stats.wishlistCount)")
                    .font(.title2)
                    .bold()
                Text("Sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack {
                Text(formatPrice(stats.wishlistValue))
                    .font(.title2)
                    .bold()
                Text("Total Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack {
                Text(formatPrice(stats.averageSetValue))
                    .font(.title2)
                    .bold()
                Text("Avg. Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$0"
    }
}

private struct WishlistSetRowView: View {
    let set: LegoSet
    
    var body: some View {
        HStack {
            AsyncCachedImage(thumbnailURL: URL(string: set.primaryImageURL ?? ""))
                .frame(width: AppConstants.Layout.iconButtonSize, height: AppConstants.Layout.iconButtonSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(set.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("#\(set.setNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text("\(set.year)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(AppConstants.Opacity.light))
                        .cornerRadius(4)
                    
                    Text("\(set.numParts) parts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let price = set.formattedPrice {
                    Text(price)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.primary)
                }
                
                if let collection = set.userCollection {
                    Text("Added \(collection.timeSinceAdded)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview { 
    WishlistView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
