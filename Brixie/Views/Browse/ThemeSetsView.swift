//
//  ThemeSetsView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Theme sets view with endless scrolling support
struct ThemeSetsView: View {
    let theme: Theme
    let sets: [LegoSet]
    let isLoading: Bool
    
    // ViewModels needed for endless scrolling
    let browseViewModel: BrowseViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with pagination info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    
                    // Show loaded count vs total count
                    if theme.totalSetCount > 0 {
                        Text("\(theme.loadedSetCount) of \(theme.totalSetCount) sets")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(sets.count) sets")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                
                if isLoading || browseViewModel.isLoadingMoreSets(for: theme) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .accessibilityLabel("Loading sets")
                }
            }
            .padding(.horizontal)
            
            if isLoading && sets.isEmpty {
                ScrollView {
                    SkeletonLoadingView(itemCount: 8, itemHeight: 80)
                        .padding(.horizontal)
                }
                .accessibilityLabel("Loading LEGO sets for \(theme.name)")
            } else if sets.isEmpty {
                ContentUnavailableView("No Sets", 
                                     systemImage: "cube",
                                     description: Text("No LEGO sets found in this theme. Pull to refresh to try loading from the server."))
            } else {
                List {
                    ForEach(sets) { set in
                        NavigationLink(destination: SetDetailView(set: set)) {
                            SetRowView(set: set)
                        }
                        .onAppear {
                            // Endless scrolling: Load more when approaching the end
                            if shouldLoadMoreSets(for: set) {
                                Task {
                                    await browseViewModel.loadMoreSetsForTheme(theme)
                                }
                            }
                        }
                    }
                    
                    // Loading indicator at bottom when loading more
                    if browseViewModel.isLoadingMoreSets(for: theme) {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more sets...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Loading more sets")
                    }
                    
                    // End of data indicator
                    if !browseViewModel.canLoadMoreSets(for: theme) && theme.totalSetCount > 0 {
                        HStack {
                            Spacer()
                            Text("All \(theme.totalSetCount) sets loaded")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    /// Determine if we should load more sets when this item appears
    private func shouldLoadMoreSets(for set: LegoSet) -> Bool {
        guard browseViewModel.canLoadMoreSets(for: theme) else { return false }
        guard !browseViewModel.isLoadingMoreSets(for: theme) else { return false }
        
        // Load more when we're within the last 5 items
        if let setIndex = sets.firstIndex(where: { $0.id == set.id }) {
            let threshold = max(0, sets.count - 5)
            return setIndex >= threshold
        }
        
        return false
    }
}

#Preview {
    // Mock theme and sets for preview
    let theme = Theme(id: 1, name: "Star Wars", parentId: nil)
    let mockSets: [LegoSet] = []
    let mockBrowseViewModel = BrowseViewModel()
    
    return NavigationView {
        ThemeSetsView(theme: theme, sets: mockSets, isLoading: false, browseViewModel: mockBrowseViewModel)
    }
}