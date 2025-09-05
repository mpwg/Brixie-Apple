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
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var searchText = ""
    @State private var searchResults: [LegoSet] = []
    @State private var isSearching = false
    @State private var legoSetService: LegoSetService?
    @State private var recentSearches: [String] = []
    @State private var showingNoResults = false
    @State private var showingAPIKeyAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !apiKeyManager.hasValidAPIKey {
                        noServiceView
                    } else {
                        searchContentView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Search Sets")
                        .font(.brixieTitle)
                        .foregroundStyle(.brixieText)
                }
            }
            .searchable(text: $searchText, prompt: "Search LEGO sets...") {
                if !recentSearches.isEmpty {
                    Section("Recent Searches") {
                        ForEach(recentSearches, id: \.self) { search in
                            Button {
                                searchText = search
                                performSearch()
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.brixieAccent)
                                    Text(search)
                                        .foregroundStyle(.brixieText)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
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
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: $apiKeyManager.apiKey)
            Button("Save") {
                setupServiceIfNeeded()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your Rebrickable API key to search LEGO sets")
        }
    }
    
    private var noServiceView: some View {
        BrixieHeroSection(
            title: "Search LEGO Sets",
            subtitle: "Find your favorite LEGO sets by name, number, or theme. Connect your API key to get started.",
            icon: "magnifyingglass.circle.fill"
        ) {
            VStack(spacing: 16) {
                Button("Connect API Key") {
                    showingAPIKeyAlert = true
                }
                .buttonStyle(BrixieButtonStyle(variant: .primary))
                
                Button("Browse Categories") {
                    // Navigate to categories
                }
                .buttonStyle(BrixieButtonStyle(variant: .ghost))
            }
        }
    }
    
    private var searchContentView: some View {
        Group {
            if searchText.isEmpty {
                recentSearchesView
            } else if isSearching {
                modernLoadingView
            } else if searchResults.isEmpty && showingNoResults {
                modernNoResultsView
            } else {
                modernSearchResultsView
            }
        }
    }
    
    private var recentSearchesView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(NSLocalizedString("Recent Searches", comment: "Recent searches heading"))
                                .font(.brixieHeadline)
                                .foregroundStyle(.brixieText)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(recentSearches, id: \.self) { search in
                                    Button {
                                        searchText = search
                                        performSearch()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.brixieAccent)
                                            Text(search)
                                                .font(.brixieCaption)
                                                .foregroundStyle(.brixieAccent)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(.brixieAccent.opacity(0.15))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(.brixieAccent.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                BrixieHeroSection(
                    title: "Discover LEGO Sets",
                    subtitle: "Search through thousands of LEGO sets by name, number, or theme to find your next build.",
                    icon: "magnifyingglass"
                ) {
                    EmptyView()
                }
            }
            .padding(.top, 20)
        }
    }
    
    private var modernLoadingView: some View {
        BrixieHeroSection(
            title: "Searching...",
            subtitle: "Finding the perfect LEGO sets for you",
            icon: "magnifyingglass"
        ) {
            BrixieLoadingView()
        }
    }
    
    private var modernNoResultsView: some View {
        BrixieHeroSection(
            title: "No Results Found",
            subtitle: String(format: NSLocalizedString("No sets found for '%@'. Try a different search term.", comment: "No results message"), searchText),
            icon: "magnifyingglass"
        ) {
            Button("Clear Search") {
                searchText = ""
                searchResults = []
                showingNoResults = false
            }
            .buttonStyle(BrixieButtonStyle(variant: .secondary))
        }
    }
    
    private var modernSearchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HStack {
                    Text("\(searchResults.count) results")
                        .font(.brixieSubhead)
                        .foregroundStyle(.brixieTextSecondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                ForEach(searchResults) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        ModernSetRowView(set: set)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func setupServiceIfNeeded() {
        if apiKeyManager.hasValidAPIKey && legoSetService == nil {
            legoSetService = LegoSetService(modelContext: modelContext, apiKey: apiKeyManager.apiKey)
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
