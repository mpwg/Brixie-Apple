//
//  SearchView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: SearchViewModel?
    @State private var showingAPIKeyAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let vm = viewModel {
                        if !vm.hasAPIKey {
                            noServiceView
                        } else {
                            searchContentView
                        }
                    } else {
                        ProgressView("Loading...")
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Text("Search Sets")
                        .font(.brixieTitle)
                        .foregroundStyle(Color.brixieText)
                }
            }
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), prompt: "Search LEGO sets...") {
                if let vm = viewModel, !vm.recentSearches.isEmpty {
                    Section("Recent Searches") {
                        ForEach(vm.recentSearches, id: \.self) { search in
                            Button {
                                vm.searchText = search
                                Task {
                                    await vm.performSearch()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.brixieAccent)
                                    Text(search)
                                        .foregroundStyle(Color.brixieText)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .onSubmit(of: .search) {
                Task {
                    await viewModel?.performSearch()
                }
            }
            .onChange(of: viewModel?.searchText ?? "") { _, newValue in
                if newValue.isEmpty {
                    viewModel?.clearResults()
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = diContainer.makeSearchViewModel()
            }
        }
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: Binding(
                get: { diContainer.apiKeyManager.apiKey },
                set: { diContainer.apiKeyManager.apiKey = $0 }
            ))
            Button("Save") {
                // Key is automatically saved via binding
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
            if let vm = viewModel {
                if vm.searchText.isEmpty {
                    recentSearchesView
                } else if vm.isSearching {
                    modernLoadingView
                } else if vm.searchResults.isEmpty && vm.showingNoResults {
                    modernNoResultsView
                } else {
                    modernSearchResultsView
                }
            }
        }
    }
    
    private var recentSearchesView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let vm = viewModel, !vm.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                            HStack {
                            Text(NSLocalizedString("Recent Searches", comment: "Recent searches heading"))
                                .font(.brixieHeadline)
                                .foregroundStyle(Color.brixieText)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(vm.recentSearches, id: \.self) { search in
                                    Button {
                                        vm.searchText = search
                                        Task {
                                            await vm.performSearch()
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.brixieAccent)
                                            Text(search)
                                                .font(.brixieCaption)
                                                .foregroundStyle(Color.brixieAccent)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color.brixieAccent.opacity(0.15))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.brixieAccent.opacity(0.3), lineWidth: 1)
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
            subtitle: String(format: NSLocalizedString("No sets found for '%@'. Try a different search term.", comment: "No results message"), viewModel?.searchText ?? ""),
            icon: "magnifyingglass"
        ) {
            Button("Clear Search") {
                viewModel?.clearSearch()
            }
            .buttonStyle(BrixieButtonStyle(variant: .secondary))
        }
    }
    
    private var modernSearchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let vm = viewModel {
                    HStack {
                        Text("\(vm.searchResults.count) results")
                            .font(.brixieSubhead)
                            .foregroundStyle(Color.brixieTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    ForEach(vm.searchResults) { set in
                        NavigationLink(destination: SetDetailView(set: set)) {
                            SetRowView(set: set, onFavoriteToggle: { set in
                                Task {
                                    await vm.toggleFavorite(for: set)
                                }
                            })
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: LegoSet.self, inMemory: true)
}
