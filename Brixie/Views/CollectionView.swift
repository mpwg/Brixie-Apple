//
//  CollectionView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    // Query LegoSets that have a related UserCollection with isOwned == true
    @Query private var ownedSets: [LegoSet]

    init() {
        _ownedSets = Query(filter: #Predicate<LegoSet> { set in
            set.userCollection?.isOwned == true
        }, sort: \LegoSet.name)
    }

    var body: some View {
        NavigationStack {
            Group {
                if ownedSets.isEmpty {
                    ContentUnavailableView(
                        "No sets in your collection",
                        systemImage: "heart",
                        description: Text("Mark sets as owned to see them here.")
                    )
                } else {
                    List(ownedSets) { set in
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
                            if let isSealed = set.userCollection?.isSealedBox, isSealed {
                                Label("Sealed", systemImage: "shippingbox.fill").labelStyle(.iconOnly)
                                    .foregroundStyle(.blue)
                                    .accessibilityLabel("Sealed box")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Collection")
        }
    }
}

#Preview {
    CollectionView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
