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
                
                SetsListView()
                    .tabItem {
                        Label(
                            NSLocalizedString("Sets", comment: "Tab label for sets"),
                            systemImage: "building.2"
                        )
                    }
                    .tag(1)
                
                SearchView()
                    .tabItem {
                        Label(
                            NSLocalizedString("Search", comment: "Tab label for search"),
                            systemImage: "magnifyingglass"
                        )
                    }
                    .tag(2)
                
                FavoritesView()
                    .tabItem {
                        Label(Strings.favorites.localized, systemImage: "heart")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label(Strings.settings.localized, systemImage: "gear")
                    }
                    .tag(4)
            }
            .tint(Color.brixieAccent)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
