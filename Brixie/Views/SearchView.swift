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
    @State private var showingSuggestions = false
    @State private var selectedThemes: Set<Int> = []
    @State private var showingFilters = false
    @State private var showingBarcodeScanner = false
    @State private var minYear = 1958
    @State private var maxYear = Calendar.current.component(.year, from: Date())
    @State private var minParts = 1
    @State private var maxParts = 10000
    @State private var useYearFilter = false
    @State private var usePartsFilter = false
    
    @Query(sort: \LegoSet.name) private var allSets: [LegoSet]
    @Query(sort: \Theme.name) private var themes: [Theme]
    
    @Environment(\.isSearching) private var isSearching
    private let searchHistory = SearchHistoryService.shared

    var body: some View {
        NavigationStack {
            if isSearching && query.isEmpty {
                // Show suggestions when search is active but no query
                SearchSuggestionsView(
                    suggestions: searchHistory.getSuggestions(for: ""),
                    onSuggestionSelected: { suggestion in
                        query = suggestion
                        submitSearch()
                    }
                )
            } else if filteredResults.isEmpty && !query.isEmpty {
                // Show no results state
                ContentUnavailableView.search(text: query)
            } else {
                // Show results
                List {
                    ForEach(filteredResults) { set in
                        NavigationLink(destination: SetDetailView(set: set)) {
                            SetSearchRowView(set: set)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search sets, themes, or numbers"
        ) {
            // Search suggestions in search scope
            if !query.isEmpty {
                ForEach(searchHistory.getSuggestions(for: query), id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            }
        }
        .onSubmit(of: .search) {
            submitSearch()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showingBarcodeScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .accessibilityLabel("Scan barcode")
                    
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: selectedThemes.isEmpty && !useYearFilter && !usePartsFilter ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel("Filters")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(
                selectedThemes: $selectedThemes,
                themes: themes,
                minYear: $minYear,
                maxYear: $maxYear,
                minParts: $minParts,
                maxParts: $maxParts,
                useYearFilter: $useYearFilter,
                usePartsFilter: $usePartsFilter
            )
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView { barcode in
                query = barcode
                showingBarcodeScanner = false
                submitSearch()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func submitSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            searchHistory.addToHistory(trimmed)
        }
    }

    private var filteredResults: [LegoSet] {
        var results = allSets
        
        // Filter by search query
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            results = results.filter { set in
                set.name.localizedStandardContains(trimmed) ||
                set.setNumber.localizedStandardContains(trimmed) ||
                set.theme?.name.localizedStandardContains(trimmed) == true
            }
        }
        
        // Filter by selected themes
        if !selectedThemes.isEmpty {
            results = results.filter { set in
                guard let themeId = set.theme?.id else { return false }
                return selectedThemes.contains(themeId)
            }
        }
        
        // Filter by year range
        if useYearFilter {
            results = results.filter { set in
                set.year >= minYear && set.year <= maxYear
            }
        }
        
        // Filter by parts count
        if usePartsFilter {
            results = results.filter { set in
                set.numParts >= minParts && set.numParts <= maxParts
            }
        }
        
        return results
    }
}

// MARK: - Supporting Views

struct SetSearchRowView: View {
    let set: LegoSet
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncCachedImage(url: URL(string: set.primaryImageURL ?? ""))
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
