//
//  WishlistView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

struct WishlistView: View {
    @Query private var wishedSets: [LegoSet]

    init() {
        _wishedSets = Query(filter: #Predicate<LegoSet> { set in
            set.userCollection?.isWishlist == true
        }, sort: \LegoSet.name)
    }

    var body: some View {
        NavigationStack {
            Group {
                if wishedSets.isEmpty {
                    ContentUnavailableView(
                        "Your wishlist is empty",
                        systemImage: "star",
                        description: Text("Add sets to your wishlist to track them here.")
                    )
                } else {
                    List(wishedSets) { set in
                        HStack {
                            AsyncCachedImage(url: URL(string: set.primaryImageURL ?? ""))
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading) {
                                Text(set.name)
                                Text("#\(set.setNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let formatted = set.formattedPrice { Text(formatted).font(.subheadline).foregroundColor(.secondary) }
                        }
                    }
                }
            }
            .navigationTitle("Wishlist")
        }
    }
}

#Preview { WishlistView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
