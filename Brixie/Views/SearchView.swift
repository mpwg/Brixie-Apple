//
//  SearchView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var query = ""
    @Query(sort: \LegoSet.name) private var results: [LegoSet]

    var body: some View {
        NavigationStack {
            List(filteredResults) { set in
                HStack(spacing: 12) {
                    AsyncCachedImage(url: URL(string: set.primaryImageURL ?? ""))
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(set.name)
                        Text("#\(set.setNumber)").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search sets")
            .onChange(of: query) { _, _ in }
        }
    }

    private var filteredResults: [LegoSet] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return results }
        return results.filter { set in
            set.name.localizedStandardContains(trimmed) || set.setNumber.localizedStandardContains(trimmed)
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
