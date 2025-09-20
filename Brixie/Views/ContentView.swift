//
//  ContentView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData
import Foundation

/// Main content view with platform-specific navigation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private let legoSetService = LegoSetService.shared
    private let themeService = ThemeService.shared
    private let apiConfig = APIConfiguration.shared
    // private let offlineManager = OfflineManager.shared
    
    @State private var selectedTab: NavigationTab = .browse
    @State private var showingSettings = false
    @State private var showingAPIKeyPrompt = false
    
    var body: some View {
        ZStack {
            Group {
                if apiConfig.isConfigured {
                    mainContent
                } else {
                    apiKeyPromptView
                }
            }
            
            // Offline indicator at the top
            VStack {
                // OfflineIndicator() - temporarily disabled
                //     .frame(maxWidth: .infinity, alignment: .center)
                //     .padding(.top)
                Spacer()
            }
        }
        // .environment(\.offlineManager, offlineManager) - temporarily disabled
        .onAppear {
            configureServices()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("API Key Required", isPresented: $showingAPIKeyPrompt) {
            Button("Settings") {
                showingSettings = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please configure your Rebrickable API key in Settings to use Brixie.")
        }
        #if DEBUG
        .performanceMonitored() // Add performance dashboard in debug builds
        #endif
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if useTabNavigation {
            tabNavigationView
        } else {
            sidebarNavigationView
        }
    }
    
    // MARK: - Tab Navigation (iOS, iPhone in portrait)
    
    private var tabNavigationView: some View {
        // Use optimized lazy-loading TabView for better performance
        LazyTabView(selection: $selectedTab) {
            LazyTab(NavigationTab.browse) {
                Label(NavigationTab.browse.title, systemImage: NavigationTab.browse.systemImage)
            } content: {
                BrowseView()
            }
            
            LazyTab(NavigationTab.search) {
                Label(NavigationTab.search.title, systemImage: NavigationTab.search.systemImage)
            } content: {
                SearchView()
            }
            
            LazyTab(NavigationTab.collection) {
                Label(NavigationTab.collection.title, systemImage: NavigationTab.collection.systemImage)
            } content: {
                CollectionView()
            }
            
            LazyTab(NavigationTab.wishlist) {
                Label(NavigationTab.wishlist.title, systemImage: NavigationTab.wishlist.systemImage)
            } content: {
                WishlistView()
            }
        }
    }
    
    // MARK: - Sidebar Navigation (macOS, iPad)
    
    private var sidebarNavigationView: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: AppConstants.UI.navigationMinWidth, ideal: AppConstants.UI.navigationIdealWidth)
        } detail: {
            destinationView(for: selectedTab)
        }
    }
    
    // MARK: - API Key Prompt
    
    private var apiKeyPromptView: some View {
        VStack(spacing: AppConstants.UI.largeSpacing) {
            Image(systemName: "key.fill")
                .font(.system(size: AppConstants.Accessibility.largeIconSize))
                .foregroundColor(.secondary)
            
            VStack(spacing: AppConstants.UI.smallSpacing + 4) {
                Text("Welcome to Brixie")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("To get started, please configure your Rebrickable API key in Settings.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Button("Open Settings") {
                showingSettings = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
    
    // MARK: - Helper Methods
    
    /// Determines whether to use tab or sidebar navigation
    private var useTabNavigation: Bool {
        // Use SwiftUI's horizontal size class for responsive navigation
        // Tab navigation for compact width (iPhone, iPad split view)
        // Sidebar navigation for regular width (iPad full screen, macOS)
        return horizontalSizeClass == .compact
    }
    
    /// Returns the appropriate view for the selected tab with lazy loading
    @ViewBuilder
    private func destinationView(for tab: NavigationTab) -> some View {
        // Use lazy loading to improve navigation performance
        Group {
            switch tab {
            case .browse:
                BrowseView()
                    .id("browse-view") // Stable identity
            case .search:
                SearchView()
                    .id("search-view") // Stable identity
            case .collection:
                CollectionView()
                    .id("collection-view") // Stable identity
            case .wishlist:
                WishlistView()
                    .id("wishlist-view") // Stable identity
            }
        }
        .transition(.opacity) // Simple fade transition for better performance
        .animation(.easeInOut(duration: 0.2), value: tab) // Shorter, simpler animation
    }
    
    /// Configure services with model context
    private func configureServices() {
        // Use Task to avoid blocking the main thread during service configuration
        Task { @MainActor in
            legoSetService.configure(with: modelContext)
            themeService.configure(with: modelContext)
            // offlineManager.startMonitoring() - temporarily disabled
            
            // Show API key prompt if not configured
            if !apiConfig.isConfigured {
                // Use shorter delay for better responsiveness
                try? await Task.sleep(for: .milliseconds(100))
                showingAPIKeyPrompt = true
            }
        }
    }
}

// MARK: - Navigation Tab Enum

enum NavigationTab: String, CaseIterable {
    case browse = "browse"
    case search = "search"
    case collection = "collection"
    case wishlist = "wishlist"
    
    var title: String {
        switch self {
        case .browse:
            return NSLocalizedString("Browse", comment: "Browse tab title")
        case .search:
            return NSLocalizedString("Search", comment: "Search tab title")
        case .collection:
            return NSLocalizedString("Meine LEGO-Sammlung", comment: "Collection tab title")
        case .wishlist:
            return NSLocalizedString("LEGO-Wunschliste", comment: "Wishlist tab title")
        }
    }
    
    var systemImage: String {
        switch self {
        case .browse:
            return "square.grid.2x2"
        case .search:
            return "magnifyingglass"
        case .collection:
            return "heart"
        case .wishlist:
            return "star"
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selectedTab: NavigationTab
    @State private var showingSettings = false
    
    var body: some View {
        List {
            ForEach(NavigationTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack {
                        Label(tab.title, systemImage: tab.systemImage)
                        Spacer()
                        if selectedTab == tab {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                .tag(tab)
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Brixie")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ContentView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
#endif
