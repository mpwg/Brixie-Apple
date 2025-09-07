//
//  ContentView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.colorScheme)
    private var colorScheme
    @Environment(ThemeManager.self)
    private var themeManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.brixieBackground(for: colorScheme)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                CategoriesView()
                    .tabItem {
                        Label(
                            NSLocalizedString("Categories", comment: "Tab label for categories"),
                            systemImage: "folder"
                        )
                    }
                    .tag(0)
                    .brixieAccessibility(label: NSLocalizedString("Categories", comment: "Tab label for categories"), 
                                        hint: NSLocalizedString("Browse LEGO themes and categories", comment: "Categories tab hint"),
                                        traits: .isButton)
                
                SetsListView()
                    .tabItem {
                        Label(
                            NSLocalizedString("Sets", comment: "Tab label for sets"),
                            systemImage: "building.2"
                        )
                    }
                    .tag(1)
                    .brixieAccessibility(label: NSLocalizedString("Sets", comment: "Tab label for sets"),
                                        hint: NSLocalizedString("Browse all LEGO sets", comment: "Sets tab hint"),
                                        traits: .isButton)
                
                SearchView()
                    .tabItem {
                        Label(
                            NSLocalizedString("Search", comment: "Tab label for search"),
                            systemImage: "magnifyingglass"
                        )
                    }
                    .tag(2)
                    .brixieAccessibility(label: NSLocalizedString("Search", comment: "Tab label for search"),
                                        hint: NSLocalizedString("Search for specific LEGO sets", comment: "Search tab hint"),
                                        traits: .isButton)
                
                FavoritesView()
                    .tabItem {
                        Label(NSLocalizedString("Favorites", comment: "Tab label for favorites"), systemImage: "heart")
                    }
                    .tag(3)
                    .brixieAccessibility(label: NSLocalizedString("Favorites", comment: "Tab label for favorites"),
                                        hint: NSLocalizedString("View your favorite LEGO sets", comment: "Favorites tab hint"),
                                        traits: .isButton)
                
                SettingsView()
                    .tabItem {
                        Label(NSLocalizedString("Settings", comment: "Tab label for settings"), systemImage: "gear")
                    }
                    .tag(4)
                    .brixieAccessibility(label: NSLocalizedString("Settings", comment: "Tab label for settings"),
                                        hint: NSLocalizedString("Configure app settings", comment: "Settings tab hint"),
                                        traits: .isButton)
            }
            .tint(Color.brixieAccent)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
