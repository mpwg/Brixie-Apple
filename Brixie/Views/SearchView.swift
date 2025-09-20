//
//  SearchView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var showingFilters = false
    
    @Query(sort: \LegoSet.name) private var allSets: [LegoSet]
    @Query(sort: \Theme.name) private var themes: [Theme]
    
    @Environment(\.isSearching) private var isSearching

    var body: some View {
        NavigationStack {
            if isSearching && viewModel.query.isEmpty {
                // Show suggestions when search is active but no query
                SearchSuggestionsView(
                    suggestions: viewModel.getSuggestions(for: "")
                )                    { suggestion in
                        viewModel.query = suggestion
                        viewModel.submitSearch()
                        viewModel.filterSets(from: allSets)
                    }
            } else if viewModel.filteredResults.isEmpty && !viewModel.query.isEmpty {
                // Show no results state
                EmptyStateView.searchNoResults(query: viewModel.query)
            } else {
                // Show results
                List {
                    ForEach(viewModel.filteredResults.isEmpty ? allSets : viewModel.filteredResults) { set in
                        NavigationLink(destination: SetDetailView(set: set)) {
                            SetSearchRowView(set: set)
                        }
                        .id(set.id) // Explicit view identity
                    }
                }
                .listStyle(.plain) // Use plain style for performance
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $viewModel.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search sets, themes, or numbers"
        ) {
            // Search suggestions in search scope
            if !viewModel.query.isEmpty {
                ForEach(viewModel.getSuggestions(for: viewModel.query), id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            }
        }
        .onSubmit(of: .search) {
            viewModel.submitSearch()
            viewModel.filterSets(from: allSets)
        }
        .onChange(of: viewModel.query) {
            viewModel.filterSets(from: allSets)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        viewModel.showBarcodeScanner()
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .accessibilityLabel("Scan barcode")
                    
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filters")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(
                selectedThemes: $viewModel.selectedThemes,
                themes: themes,
                minYear: $viewModel.minYear,
                maxYear: $viewModel.maxYear,
                minParts: $viewModel.minParts,
                maxParts: $viewModel.maxParts,
                useYearFilter: $viewModel.useYearFilter,
                usePartsFilter: $viewModel.usePartsFilter
            )
        }
        .sheet(isPresented: $viewModel.showingBarcodeScanner) {
            BarcodeScannerView { barcode in
                viewModel.handleBarcodeResult(barcode, with: allSets)
            }
        }
    }
}

// MARK: - Supporting Views

struct SetSearchRowView: View {
    let set: LegoSet
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncCachedImage(thumbnailURL: URL(string: set.primaryImageURL ?? ""))
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Text("#\(set.setNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let theme = set.theme {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(theme.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text("\(set.formattedPartCount) parts")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    if set.year > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("\(set.year)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            if let price = set.formattedPrice {
                Text(price)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.name), set number \(set.setNumber)")
        .accessibilityHint("Opens set details")
    }
}

struct SearchSuggestionsView: View {
    let suggestions: [String]
    let onSuggestionSelected: (String) -> Void
    private let searchHistory = SearchHistoryService.shared
    
    var body: some View {
        List {
            if !searchHistory.recentSearches.isEmpty {
                Section("Recent Searches") {
                    ForEach(Array(searchHistory.recentSearches.prefix(5)), id: \.self) { search in
                        Button {
                            onSuggestionSelected(search)
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                Text(search)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            Section("Popular Themes") {
                ForEach(Array(searchHistory.suggestions.prefix(8)), id: \.self) { suggestion in
                    Button {
                        onSuggestionSelected(suggestion)
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text(suggestion)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
