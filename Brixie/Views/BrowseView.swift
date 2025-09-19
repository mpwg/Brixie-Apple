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
    @State private var service = LegoSetService.shared

    var body: some View {
        NavigationStack {
            Group {
                if isRefreshing {
                    LoadingView(message: "Loading LEGO sets...", isError: false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sets.isEmpty {
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
            .onAppear {
                service.configure(with: modelContext)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No LEGO Sets Found",
            systemImage: "square.grid.2x2",
            description: Text("Configure your Rebrickable API key in Settings to browse LEGO sets from the catalog.")
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
        defer { isRefreshing = false }
        
        // Try to fetch sets from the service
        do {
            let service = LegoSetService.shared
            service.configure(with: modelContext)
            let _ = try await service.fetchSets()
        } catch {
            print("Failed to fetch sets: \(error)")
        }
    }
}

#Preview {
    BrowseView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
