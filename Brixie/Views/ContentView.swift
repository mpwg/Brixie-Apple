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
        TabView(selection: $selectedTab) {
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "square.grid.2x2")
                }
                .tag(NavigationTab.browse)
                .transition(.opacity.combined(with: .slide))
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(NavigationTab.search)
                .transition(.opacity.combined(with: .slide))
            
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "heart")
                }
                .tag(NavigationTab.collection)
                .transition(.opacity.combined(with: .slide))
            
            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "star")
                }
                .tag(NavigationTab.wishlist)
                .transition(.opacity.combined(with: .slide))
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
    
    // MARK: - Sidebar Navigation (macOS, iPad)
    
    private var sidebarNavigationView: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            destinationView(for: selectedTab)
        }
    }
    
    // MARK: - API Key Prompt
    
    private var apiKeyPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
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
    
    /// Returns the appropriate view for the selected tab
    @ViewBuilder
    private func destinationView(for tab: NavigationTab) -> some View {
        switch tab {
        case .browse:
            BrowseView()
        case .search:
            SearchView()
        case .collection:
            CollectionView()
        case .wishlist:
            WishlistView()
        }
    }
    
    /// Configure services with model context
    private func configureServices() {
        legoSetService.configure(with: modelContext)
        // offlineManager.startMonitoring() - temporarily disabled
        
        // Show API key prompt if not configured
        if !apiConfig.isConfigured {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.systemImage)
                }
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
