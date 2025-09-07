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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel != nil {
                        searchContentView
                    } else {
                        ProgressView(NSLocalizedString("Loading...", comment: "Loading indicator text"))
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Text(NSLocalizedString("Search Sets", comment: "Navigation title for search"))
                        .font(.brixieTitle)
                        .foregroundStyle(Color.brixieText)
                }
            }
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), prompt: NSLocalizedString("Search LEGO sets...", comment: "Search prompt text")) {
                if let vm = viewModel, !vm.recentSearches.isEmpty {
                    Section(NSLocalizedString("Recent Searches", comment: "Recent searches section header")) {
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
            Button(NSLocalizedString("Clear Search", comment: "Clear search button")) {
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
                        Text(String(format: NSLocalizedString("%d results", comment: "Number of search results"), vm.searchResults.count))
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
