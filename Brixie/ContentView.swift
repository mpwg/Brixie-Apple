//
//  ContentView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SetsListView()
                .tabItem {
                    Label(NSLocalizedString("Sets", comment: "Tab label for sets"), systemImage: "building.2")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label(NSLocalizedString("Search", comment: "Tab label for search"), systemImage: "magnifyingglass")
                }
                .tag(1)
            
            FavoritesView()
                .tabItem {
                    Label(NSLocalizedString("Favorites", comment: "Tab label for favorites"), systemImage: "heart")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: "Tab label for settings"), systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LegoSet.self, inMemory: true)
}
