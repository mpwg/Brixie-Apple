//
//  ContentView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Main content view with platform-specific navigation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private let legoSetService = LegoSetService.shared
    private let apiConfig = APIConfiguration.shared
    
    @State private var selectedTab: NavigationTab = .browse
    @State private var showingSettings = false
    @State private var showingAPIKeyPrompt = false
    
    var body: some View {
        Group {
            if apiConfig.isConfigured {
                mainContent
            } else {
                apiKeyPromptView
            }
        }
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
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(NavigationTab.search)
            
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "heart")
                }
                .tag(NavigationTab.collection)
            
            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "star")
                }
                .tag(NavigationTab.wishlist)
        }
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
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Helper Methods
    
    /// Determines whether to use tab or sidebar navigation
    private var useTabNavigation: Bool {
        #if os(iOS)
        // Use tab navigation on iPhone or iPad in compact width
        return UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact
        #else
        // Always use sidebar on macOS and visionOS
        return false
        #endif
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
        List(NavigationTab.allCases, id: \.self, selection: $selectedTab) { tab in
            NavigationLink(value: tab) {
                Label(tab.title, systemImage: tab.systemImage)
            }
        }
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

// MARK: - Placeholder Views

struct BrowseView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Browse LEGO Sets")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Coming soon in Phase 2")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Browse")
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Search Sets")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Coming soon in Phase 3")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Search")
        }
    }
}

struct CollectionView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "heart")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Meine LEGO-Sammlung")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Coming soon in Phase 4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Collection")
        }
    }
}

struct WishlistView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "star")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("LEGO-Wunschliste")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Coming soon in Phase 4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Wishlist")
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiConfig = APIConfiguration()
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var validationResult: Bool?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Rebrickable API Key", text: $apiKey)
                        .textContentType(.password)
                        .onAppear {
                            apiKey = apiConfig.currentAPIKey ?? ""
                        }
                    
                    if isValidating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Validating...")
                                .foregroundColor(.secondary)
                        }
                    } else if let isValid = validationResult {
                        Label(
                            isValid ? "Valid API Key" : "Invalid API Key",
                            systemImage: isValid ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(isValid ? .green : .red)
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Get your API key from rebrickable.com/api/")
                }
                
                Section {
                    Button("Save & Validate") {
                        saveAndValidateAPIKey()
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                    
                    Button("Clear Key") {
                        apiConfig.clearAPIKey()
                        apiKey = ""
                        validationResult = nil
                    }
                    .foregroundColor(.red)
                    .disabled(apiKey.isEmpty)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveAndValidateAPIKey() {
        isValidating = true
        apiConfig.updateAPIKey(apiKey)
        
        Task {
            let isValid = await apiConfig.validateAPIKey()
            await MainActor.run {
                isValidating = false
                validationResult = isValid
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ContentView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}

#Preview("Settings") {
    SettingsView()
}
#endif