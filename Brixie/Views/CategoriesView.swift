//
//  CategoriesView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var themeService: LegoThemeService?
    @State private var themes: [LegoTheme] = []
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .name
    @State private var showingAPIKeyAlert = false
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case setCount = "Set Count"
        
        var localizedString: String {
            NSLocalizedString(self.rawValue, comment: "Sort order")
        }
    }
    
    var filteredAndSortedThemes: [LegoTheme] {
        var filtered = themes
        
        if !searchText.isEmpty {
            filtered = filtered.filter { theme in
                theme.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch sortOrder {
        case .name:
            filtered = filtered.sorted { $0.name < $1.name }
        case .setCount:
            filtered = filtered.sorted { $0.setCount > $1.setCount }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if !apiKeyManager.hasValidAPIKey {
                    apiKeyPromptView
                } else if let service = themeService {
                    if service.isLoading && themes.isEmpty {
                        ProgressView(NSLocalizedString("Loading categories...", comment: "Loading message"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredAndSortedThemes, id: \.id) { theme in
                                NavigationLink(destination: CategoryDetailView(theme: theme)) {
                                    CategoryRowView(theme: theme)
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: NSLocalizedString("Search categories", comment: "Search prompt"))
                        .refreshable {
                            await loadThemes()
                        }
                    }
                    
                    if let errorMessage = service.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                } else {
                    ProgressView(NSLocalizedString("Initializing...", comment: "Initialization message"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(NSLocalizedString("Categories", comment: "Navigation title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Settings") {
                            showingAPIKeyAlert = true
                        }
                        
                        Menu {
                            Picker(NSLocalizedString("Sort by", comment: "Sort picker label"), selection: $sortOrder) {
                                ForEach(SortOrder.allCases, id: \.self) { order in
                                    Text(order.localizedString).tag(order)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
            }
        }
        .task {
            if apiKeyManager.hasValidAPIKey {
                await initializeService()
            }
        }
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: $apiKeyManager.apiKey)
            Button("Save") {
                Task {
                    await initializeService()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your Rebrickable API key to fetch LEGO categories")
        }
    }
    
    private var apiKeyPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("API Key Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To view LEGO categories, you need a Rebrickable API key. Get one for free at rebrickable.com")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Enter API Key") {
                showingAPIKeyAlert = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    @MainActor
    private func initializeService() async {
        guard themeService == nil else { return }
        
        themeService = LegoThemeService(modelContext: modelContext, apiKey: apiKeyManager.apiKey)
        
        let cachedThemes = themeService?.getCachedThemes() ?? []
        if !cachedThemes.isEmpty {
            themes = cachedThemes
        }
        
        await loadThemes()
    }
    
    @MainActor
    private func loadThemes() async {
        guard let service = themeService else { return }
        
        do {
            let fetchedThemes = try await service.fetchThemes()
            themes = fetchedThemes
        } catch {
            themes = service.getCachedThemes()
        }
    }
}

struct CategoryRowView: View {
    let theme: LegoTheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(String(format: NSLocalizedString("%d sets", comment: "Set count"), theme.setCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CategoriesView()
        .modelContainer(for: [LegoTheme.self, LegoSet.self], inMemory: true)
}