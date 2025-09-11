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
                    // Error banner for search failures  
                    if let vm = viewModel, let error = vm.error, !vm.searchText.isEmpty {
                        errorBannerView(for: error)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    
                    if viewModel != nil {
                        searchContentView
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
                if let vm = viewModel {
                    BrixieSearchSuggestions(recentSearches: vm.recentSearches) { selection in
                        vm.searchText = selection
                        Task { await vm.performImmediateSearch() }
                    }
                }
            }
            .onSubmit(of: .search) {
                Task {
                    await viewModel?.performImmediateSearch()
                }
            }
            .onChange(of: viewModel?.searchText ?? "") { _, newValue in
                if newValue.isEmpty {
                    viewModel?.clearResults()
                } else {
                    viewModel?.performDebouncedSearch()
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
                                            await vm.performImmediateSearch()
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
                            SetRowView(set: set) { set in
                                Task {
                                    await vm.toggleFavorite(for: set)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private func errorBannerView(for error: BrixieError) -> some View {
        switch error {
        case .networkError:
            BrixieBannerView.networkError(onRetry: {
                Task {
                    await viewModel?.retrySearch()
                }
            }, onDismiss: {
                viewModel?.error = nil
            })
            
        case .apiKeyMissing, .unauthorized:
            BrixieBannerView.apiKeyError(onRetry: {
                // Navigate to settings - for now just clear error
                viewModel?.error = nil
            }, onDismiss: {
                viewModel?.error = nil
            })
            
        default:
            BrixieBannerView.generalError(error, onRetry: {
                Task {
                    await viewModel?.retrySearch()
                }
            }, onDismiss: {
                viewModel?.error = nil
            })
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
