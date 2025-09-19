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
                viewModel.configure(with: modelContext)
            }
            .task {
                if allThemes.isEmpty || allSets.isEmpty {
                    await viewModel.loadInitialData()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
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
    
    /// Main content area showing subthemes or sets
    private var mainContentView: some View {
        VStack {
            if let selectedSubtheme = viewModel.selectedSubtheme {
                // Show sets for selected subtheme
                SubthemeSetsView(subtheme: selectedSubtheme, sets: setsForSubtheme(selectedSubtheme))
            } else if let selectedTheme = viewModel.selectedTheme {
                let _ = Logger.database.debug("Selected theme \(selectedTheme.name): hasSubthemes=\(selectedTheme.hasSubthemes), subthemes.count=\(selectedTheme.subthemes.count), sets.count=\(selectedTheme.sets.count)")
                // Show subthemes or sets for selected theme
                if selectedTheme.hasSubthemes {
                    ThemeSubthemesView(theme: selectedTheme) { subtheme in
                        viewModel.selectSubtheme(subtheme)
                    }
                } else {
                    let setsForTheme = setsForTheme(selectedTheme)
                    let _ = Logger.database.debug("Sets for theme \(selectedTheme.name): \(setsForTheme.count) sets found")
                    ThemeSetsView(theme: selectedTheme, sets: setsForTheme)
                }
            } else {
                // No theme selected - show welcome message
                ContentUnavailableView("Select a Theme", 
                                     systemImage: "square.grid.3x3",
                                     description: Text("Choose a theme from the sidebar to browse LEGO sets"))
            }
        }
        .onAppear {
            Logger.viewCycle.info("MainContentView appeared - selectedTheme: \(viewModel.selectedTheme?.name ?? "nil", privacy: .private)")
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
            
            if filteredRootThemes.isEmpty {
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
                    List(selectedTheme.subthemes.sorted(by: { $0.name < $1.name })) { subtheme in
                        NavigationButton(action: { viewModel.selectSubtheme(subtheme) }) {
                            SubthemeRowView(subtheme: subtheme)
                        }
                    }
                } else {
                    ThemeSetsView(theme: selectedTheme, sets: setsForTheme(selectedTheme))
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
                SubthemeSetsView(subtheme: selectedSubtheme, sets: setsForSubtheme(selectedSubtheme))
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
    
    // MARK: - Data Helpers
    
    /// Filtered root themes based on search
    private var filteredRootThemes: [Theme] {
        let rootThemes = allThemes.filter { $0.isRootTheme }
        
        // Log theme statistics using the service
        Task {
            do {
                let stats = try ThemeService.shared.getThemeStatistics()
                Logger.database.info("Theme Stats - Total: \(stats.totalThemes), Root: \(stats.rootThemes), Fresh: \(stats.isDataFresh)")
                if let lastSync = stats.lastSyncDate {
                    Logger.database.debug("Last theme sync: \(lastSync.formatted())")
                }
            } catch {
                Logger.error.error("Failed to get theme statistics: \(error)")
            }
        }
        
        if !rootThemes.isEmpty {
            let themeNames = rootThemes.prefix(5).map { "\($0.name) (ID: \($0.id), subthemes: \($0.subthemes.count), sets: \($0.sets.count))" }.joined(separator: ", ")
            Logger.database.debug("First 5 root themes: \(themeNames)")
        }
        
        if searchText.isEmpty {
            return rootThemes.sorted { $0.name < $1.name }
        } else {
            let filtered = rootThemes
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
            Logger.search.debug("Search '\(searchText, privacy: .private)' returned \(filtered.count) themes")
            return filtered
        }
    }
    
    /// Get sets for a specific theme
    private func setsForTheme(_ theme: Theme) -> [LegoSet] {
        Logger.database.debug("setsForTheme(\(theme.name)) - Theme ID: \(theme.id)")
        Logger.database.debug("Total sets available: \(allSets.count)")
        
        // Log first few sets for debugging
        for (index, set) in allSets.prefix(5).enumerated() {
            Logger.database.debug("Set \(index): \(set.name) - themeId: \(set.themeId), theme?.id: \(set.theme?.id ?? -1)")
        }
        
        // Try relationship-based filter first, fallback to themeId
        let filteredSets = allSets.filter { 
            $0.theme?.id == theme.id || $0.themeId == theme.id
        }
        
        Logger.database.debug("setsForTheme(\(theme.name)): filtered \(filteredSets.count) sets from \(allSets.count) total sets")
        
        return filteredSets
    }
    
    /// Get sets for a specific subtheme
    private func setsForSubtheme(_ subtheme: Theme) -> [LegoSet] {
        // Use both relationship and themeId for filtering
        return allSets.filter { 
            $0.theme?.id == subtheme.id || $0.themeId == subtheme.id
        }
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
                    do {
                        try ThemeService.shared.clearCachedThemes()
                        await viewModel.refresh()
                    } catch {
                        Logger.error.error("Failed to clear themes: \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
            .foregroundStyle(.red)
            .help("Clear cached themes")
        }
    }
}

// MARK: - Component Views

/// Theme row for sidebar
private struct ThemeRowView: View {
    let theme: Theme
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                if theme.hasSubthemes {
                    Text("\(theme.subthemes.count) categories")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                } else {
                    Text("\(theme.totalSetCount) sets")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            
            Spacer()
            
            if theme.hasSubthemes {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? .blue : .clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(theme.name), \(theme.hasSubthemes ? "\(theme.subthemes.count) categories" : "\(theme.totalSetCount) sets")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Subtheme row view
private struct SubthemeRowView: View {
    let subtheme: Theme
    
    var body: some View {
        HStack {
            Text(subtheme.name)
                .font(.body)
            
            Spacer()
            
            Text("\(subtheme.totalSetCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subtheme.name), \(subtheme.totalSetCount) sets")
    }
}

/// Theme subthemes view
private struct ThemeSubthemesView: View {
    let theme: Theme
    let onSubthemeSelected: (Theme) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(theme.name)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding(.horizontal)
            
            if theme.subthemes.isEmpty {
                ContentUnavailableView("No Subcategories", 
                                     systemImage: "folder",
                                     description: Text("This theme has no subcategories"))
            } else {
                // Grid of subthemes
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 280), spacing: 16)
                ], spacing: 16) {
                    ForEach(theme.subthemes.sorted(by: { $0.name < $1.name })) { subtheme in
                        SubthemeCardView(subtheme: subtheme) {
                            onSubthemeSelected(subtheme)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

/// Subtheme card view
private struct SubthemeCardView: View {
    let subtheme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(subtheme.name)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("\(subtheme.totalSetCount) sets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subtheme.name), \(subtheme.totalSetCount) sets")
        .accessibilityAddTraits(.isButton)
    }
}

/// Theme sets view
private struct ThemeSetsView: View {
    let theme: Theme
    let sets: [LegoSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("\(sets.count) sets")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            if sets.isEmpty {
                ContentUnavailableView("No Sets", 
                                     systemImage: "cube",
                                     description: Text("No LEGO sets found in this theme"))
            } else {
                List(sets) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        SetRowView(set: set)
                    }
                }
            }
        }
    }
}

/// Subtheme sets view
private struct SubthemeSetsView: View {
    let subtheme: Theme
    let sets: [LegoSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtheme.name)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    if let parent = subtheme.parentTheme {
                        Text(parent.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(sets.count) sets")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            if sets.isEmpty {
                ContentUnavailableView("No Sets", 
                                     systemImage: "cube",
                                     description: Text("No LEGO sets found in this category"))
            } else {
                List(sets) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        SetRowView(set: set)
                    }
                }
            }
        }
    }
}

/// Set row view for lists
private struct SetRowView: View {
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
                    .lineLimit(1)
                
                Text("#\(set.setNumber) • \(set.year)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.name), set number \(set.setNumber), year \(set.year)")
    }
}

#Preview {
    BrowseView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
