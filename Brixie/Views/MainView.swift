//
//  MainView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 15.09.25.
//

import Foundation
import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.diContainer) private var di: DIContainer

    // Sidebar is now provided by ThemeSelectionView which owns its own view model.

    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Meine LEGO-Sammlung").font(.title2)) {
                    NavigationLink(destination: SetsOverviewView()) {
                        Label("LEGO-Sets", systemImage: "cube.box.fill")
                    }
                    NavigationLink(destination: SealedBoxView()) {
                        Label("Versiegelte Box", systemImage: "lock.fill")
                    }
                    NavigationLink(destination: MissingPartsView()) {
                        Label("Fehlende Teile", systemImage: "key.fill")
                    }
                    HStack {
                        Label("Gesamtanzahl der LEGO-Teile", systemImage: "number")
                        Spacer()
                        Text("2.766")  // Example count, replace with dynamic value
                            .foregroundStyle(.secondary)
                    }
                }
                Section(header: Text("Themen")) {
                    NavigationLink(destination: ThemesView()) {
                        Label("Alle", systemImage: "square.grid.2x2")
                    }
                    NavigationLink(destination: BotanicalsView()) {
                        Label("Botanicals", systemImage: "leaf.fill")
                    }
                    NavigationLink(destination: IconsView()) {
                        Label("Icons", systemImage: "star.fill")
                    }
                    // Add more theme links as needed
                }
                Section(header: Text("LEGO-Wunschliste")) {
                    NavigationLink(destination: WishlistView()) {
                        Label("LEGO-Wunschliste", systemImage: "heart.fill")
                    }
                }
                Section(header: Text("Fehlende Teile")) {
                    NavigationLink(destination: MissingPartsView()) {
                        Label("Fehlende Teile", systemImage: "key.fill")
                    }
                }
            }
            .listStyle(.sidebar)
        } content: {
            SetsOverviewView()  // Default main content area
        } detail: {
            SetDetailView(setNum: "19710-1")  // Example detail, replace with selection binding
        }
    }

    // Themes loading handled by ThemeSelectionViewModel
}

// MARK: - Preview

#Preview {
    MainView()
}
