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
    @State private var themeService: LegoThemeService?
    @State private var themes: [LegoTheme] = []
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .name
    
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
        NavigationView {
            VStack {
                if let service = themeService {
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
        .task {
            await initializeService()
        }
    }
    
    @MainActor
    private func initializeService() async {
        guard themeService == nil else { return }
        
        let apiKey = UserDefaults.standard.string(forKey: "RebrickableAPIKey") ?? ""
        themeService = LegoThemeService(modelContext: modelContext, apiKey: apiKey)
        
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