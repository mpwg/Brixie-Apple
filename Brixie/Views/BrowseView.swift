//
//  BrowseView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LegoSet.year, order: .reverse, animation: .default) private var sets: [LegoSet]
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            Group {
                if sets.isEmpty {
                    emptyState
                } else {
                    List(sets) { set in
                        HStack(spacing: 12) {
                            AsyncCachedImage(url: URL(string: set.primaryImageURL ?? ""))
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(set.name)
                                    .font(.headline)
                                Text("#\(set.setNumber) • \(set.year)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .refreshable { await refresh() }
                }
            }
            .navigationTitle("Browse")
            .toolbar { toolbar }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No sets yet",
            systemImage: "square.grid.2x2",
            description: Text("You can refresh to fetch sample data once API is wired in Phase 2.")
        )
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await refresh() }
            } label: { Image(systemName: "arrow.clockwise") }
            .accessibilityLabel("Refresh sets")
        }
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        // Phase 1: no network fetch. Optionally seed with sample data.
        isRefreshing = false
    }
}

#Preview {
    BrowseView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
