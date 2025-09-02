//
//  SearchView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("rebrickableAPIKey") private var apiKey = ""
    @State private var searchText = ""
    @State private var searchResults: [LegoSet] = []
    @State private var isSearching = false
    @State private var legoSetService: LegoSetService?
    @State private var recentSearches: [String] = []
    @State private var showingNoResults = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if legoSetService == nil {
                    noServiceView
                } else {
                    searchContentView
                }
            }
            .navigationTitle("Search Sets")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search LEGO sets...")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                    showingNoResults = false
                }
            }
        }
        .onAppear {
            setupServiceIfNeeded()
        }
    }
    
    private var noServiceView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Search Not Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Configure your API key in Settings to enable search")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var searchContentView: some View {
        Group {
            if searchText.isEmpty {
                recentSearchesView
            } else if isSearching {
                loadingView
            } else if searchResults.isEmpty && showingNoResults {
                noResultsView
            } else {
                searchResultsView
            }
        }
    }
    
    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Searches")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(recentSearches, id: \.self) { search in
                                Button(search) {
                                    searchText = search
                                    performSearch()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Search LEGO Sets")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Search by set name, number, or theme")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No sets found for '\(searchText)'")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var searchResultsView: some View {
        List {
            ForEach(searchResults) { set in
                NavigationLink(destination: SetDetailView(set: set)) {
                    SetRowView(set: set)
                }
            }
        }
    }
    
    private func setupServiceIfNeeded() {
        if !apiKey.isEmpty && legoSetService == nil {
            legoSetService = LegoSetService(modelContext: modelContext, apiKey: apiKey)
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let service = legoSetService else { return }
        
        // Add to recent searches
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !recentSearches.contains(trimmedSearch) {
            recentSearches.insert(trimmedSearch, at: 0)
            if recentSearches.count > 5 {
                recentSearches = Array(recentSearches.prefix(5))
            }
        }
        
        isSearching = true
        showingNoResults = false
        
        Task {
            do {
                let results = try await service.searchSets(query: trimmedSearch)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                    showingNoResults = results.isEmpty
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    showingNoResults = true
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: LegoSet.self, inMemory: true)
}