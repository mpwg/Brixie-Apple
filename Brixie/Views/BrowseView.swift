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
    @State private var viewModel = BrowseViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading LEGO sets...", isError: false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sets.isEmpty {
                    EmptyStateView.emptyBrowse {
                        Task { await viewModel.refresh() }
                    }
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
                    .refreshable { 
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Browse")
            .toolbar { toolbar }
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .task {
                if sets.isEmpty {
                    await viewModel.loadSets()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
                Button("OK") { viewModel.error = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await viewModel.refresh() }
            } label: { Image(systemName: "arrow.clockwise") }
            .accessibilityLabel("Refresh sets")
        }
    }
}

#Preview {
    BrowseView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
