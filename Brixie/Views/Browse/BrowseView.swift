//
//  BrowseView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData
import OSLog

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Queries for data
    @Query(sort: \Theme.name, animation: .default) private var allThemes: [Theme]
    @Query(sort: \LegoSet.year, order: .reverse, animation: .default) private var allSets: [LegoSet]
    
    @State private var viewModel = BrowseViewModel()
    @State private var searchText = ""
    @State private var cachedFilteredThemes: [Theme] = []
    @State private var lastSearchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading LEGO themes...", isError: false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isCompactLayout {
                    // Compact layout for iPhone
                    compactLayout
                } else {
                    // Regular layout for iPad/Mac
                    regularLayout
                }
            }
            .navigationTitle("Browse")
            .toolbar { toolbar }
            .onAppear {
                viewModel.configure(with: modelContext, themes: allThemes, sets: allSets)
                print("🔍 BrowseView onAppear: allThemes.count = \(allThemes.count)")
            }
            .task {
                if allThemes.isEmpty || allSets.isEmpty {
                    await viewModel.loadInitialData()
                }
            }
            .onChange(of: allThemes.count) { oldValue, newValue in
                print("🔍 BrowseView: allThemes count changed from \(oldValue) to \(newValue)")
                // Clear cache to force recomputation
                cachedFilteredThemes = []
                lastSearchText = ""
            }
            .onChange(of: searchText) { _, newValue in
                // Update cache when search changes
                let allSorted = allThemes.sorted { $0.name < $1.name }
                let themes = Array(allSorted.prefix(20))
                let filtered = newValue.isEmpty ? themes : themes.filter { $0.name.localizedCaseInsensitiveContains(newValue) }
                
                cachedFilteredThemes = filtered
                lastSearchText = newValue
                print("🔍 Search changed: \(filtered.count) themes for '\(newValue)'")
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { _ in
                Button("OK") { viewModel.error = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Layout Variants
    
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
    
    /// Compact layout for iPhone - navigational flow
    private var compactLayout: some View {
        VStack {
            if viewModel.selectedSubtheme != nil {
                // Show sets for selected subtheme
                selectedSubthemeSetsView
            } else if viewModel.selectedTheme != nil {
                // Show subthemes for selected theme
                selectedThemeSubthemesView
            } else {
                // Show root themes
                rootThemesView
            }
        }
    }
    
    /// Regular layout for iPad/Mac - sidebar + detail
    private var regularLayout: some View {
        HStack(spacing: 0) {
            // Sidebar with root themes
            themeSidebarView
                .frame(maxWidth: 300)
                .background(.regularMaterial, in: Rectangle())
            
            Divider()
            
            // Main content area
            VStack {
                // Debug info (temporary)
                if viewModel.selectedTheme != nil || viewModel.selectedSubtheme != nil {
                    HStack {
                        Text("Selected: \(viewModel.selectedTheme?.name ?? "none") → \(viewModel.selectedSubtheme?.name ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") {
                            viewModel.clearSelection()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                mainContentView
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - View Components
    
    /// Sidebar showing root themes
    private var themeSidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Themes")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                
                // Debug info (temporary)
                #if DEBUG
                Text("\(filteredRootThemes.count)/\(allThemes.count)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                #endif
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search themes", text: $searchText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            
            // Root themes list
            if viewModel.isLoading && filteredRootThemes.isEmpty {
                ScrollView {
                    ThemeSkeletonView()
                        .padding()
                }
            } else if filteredRootThemes.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "square.grid.3x3")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No themes found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredRootThemes) { theme in
                    Button(action: {
                        HapticFeedback.selection()
                        viewModel.selectTheme(theme)
                    }) {
                        ThemeRowView(theme: theme, isSelected: viewModel.selectedTheme?.id == theme.id)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.sidebar)
            }
        }
    }
    
    /// Main content area showing subthemes or sets
    private var mainContentView: some View {
        VStack {
            if let selectedSubtheme = viewModel.selectedSubtheme {
                // Show sets for selected subtheme
                SubthemeSetsView(subtheme: selectedSubtheme, sets: viewModel.setsForSubtheme(selectedSubtheme))
            } else if let selectedTheme = viewModel.selectedTheme {
                // Show subthemes or sets for selected theme
                if selectedTheme.hasSubthemes {
                    ThemeSubthemesView(theme: selectedTheme) { subtheme in
                        viewModel.selectSubtheme(subtheme)
                    }
                    .onAppear {
                        viewModel.logThemeDetails(selectedTheme)
                    }
                } else {
                    let setsForTheme = viewModel.setsForTheme(selectedTheme)
                    ThemeSetsView(
                        theme: selectedTheme, 
                        sets: setsForTheme,
                        isLoading: viewModel.isLoadingThemeSets,
                        browseViewModel: viewModel
                    )
                    .onAppear {
                        viewModel.logThemeDetails(selectedTheme)
                    }
                    .refreshable {
                        await viewModel.loadSetsForTheme(selectedTheme)
                    }
                }
            } else if viewModel.isLoading {
                // Show skeleton loading when no theme selected but data is loading
                VStack(alignment: .leading, spacing: 16) {
                    // Header placeholder
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .frame(height: 32)
                            .frame(maxWidth: 250)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                            .frame(height: 20)
                            .frame(maxWidth: 150)
                    }
                    .padding(.horizontal)
                    
                    // Content skeleton
                    SkeletonLoadingView(itemCount: 6)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                // No theme selected - show welcome message
                ContentUnavailableView("Select a Theme", 
                                     systemImage: "square.grid.3x3",
                                     description: Text("Choose a theme from the sidebar to browse LEGO sets"))
            }
        }
        .onAppear {
            viewModel.logMainContentViewAppearance()
        }
    }
    
    // MARK: - Compact Layout Views
    
    /// Root themes view for compact layout
    private var rootThemesView: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search themes", text: $searchText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            
            if viewModel.isLoading && filteredRootThemes.isEmpty {
                ScrollView {
                    ThemeSkeletonView()
                        .padding()
                }
            } else if filteredRootThemes.isEmpty {
                EmptyStateView.emptyBrowse {
                    Task { await viewModel.refresh() }
                }
            } else {
                List(filteredRootThemes) { theme in
                    NavigationButton(action: { viewModel.selectTheme(theme) }) {
                        ThemeRowView(theme: theme, isSelected: false)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Themes")
    }
    
    /// Selected theme's subthemes view for compact layout  
    private var selectedThemeSubthemesView: some View {
        VStack {
            if let selectedTheme = viewModel.selectedTheme {
                if selectedTheme.hasSubthemes {
                    if selectedTheme.subthemes.isEmpty && viewModel.isLoading {
                        ScrollView {
                            ThemeSkeletonView()
                                .padding()
                        }
                    } else {
                        List(selectedTheme.subthemes.sorted { $0.name < $1.name }) { subtheme in
                            NavigationButton(action: { viewModel.selectSubtheme(subtheme) }) {
                                SubthemeRowView(subtheme: subtheme)
                            }
                        }
                    }
                } else {
                    ThemeSetsView(
                        theme: selectedTheme, 
                        sets: viewModel.setsForTheme(selectedTheme),
                        isLoading: viewModel.isLoadingThemeSets,
                        browseViewModel: viewModel
                    )
                    .refreshable {
                        await viewModel.loadSetsForTheme(selectedTheme)
                    }
                }
            }
        }
        .navigationTitle(viewModel.selectedTheme?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", action: viewModel.clearSelection)
            }
        }
    }
    
    /// Selected subtheme's sets view for compact layout
    private var selectedSubthemeSetsView: some View {
        VStack {
            if let selectedSubtheme = viewModel.selectedSubtheme {
                SubthemeSetsView(subtheme: selectedSubtheme, sets: viewModel.setsForSubtheme(selectedSubtheme))
            }
        }
        .navigationTitle(viewModel.selectedSubtheme?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    viewModel.selectedSubtheme = nil
                }
            }
        }
    }
    
    // MARK: - Data Helpers
    
    /// Filtered root themes based on search (cached to prevent recomputation during scrolling)
    private var filteredRootThemes: [Theme] {
        // Use cached themes if available and search hasn't changed
        if !cachedFilteredThemes.isEmpty && searchText == lastSearchText {
            return cachedFilteredThemes
        }
        
        // TEMPORARY FIX: Return first 20 themes directly while we debug the theme hierarchy
        let allSorted = allThemes.sorted { $0.name < $1.name }
        let themes = Array(allSorted.prefix(20))
        
        let filtered = searchText.isEmpty ? themes : themes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        // IMPORTANT: Don't update state from within a computed property - this causes the infinite loop!
        // Instead, we'll use onChange modifiers to update the cache
        return filtered
    }

    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Force refresh button (fetches from API)
            Button {
                Task { await viewModel.forceRefresh() }
            } label: { 
                Image(systemName: "arrow.counterclockwise") 
            }
            .accessibilityLabel("Force Refresh from API")
            .help("Force refresh all themes from API")
            
            // Regular refresh button (may use cache)
            Button {
                Task { await viewModel.refresh() }
            } label: { 
                Image(systemName: "arrow.clockwise") 
            }
            .accessibilityLabel("Refresh")
            .help("Refresh themes (may use cache)")
            
            // Debug button to clear themes (temporary)
            Button("Clear Cache") {
                Task {
                    await viewModel.clearCachedThemes()
                    // Clear view-level cache as well
                    cachedFilteredThemes.removeAll()
                    lastSearchText = ""
                    await viewModel.refresh()
                }
            }
            .foregroundStyle(.red)
            .help("Clear cached themes")
        }
    }
}

// MARK: - Helper Views

/// Navigation button for compact layout
private struct NavigationButton<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            HStack {
                content()
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BrowseView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
