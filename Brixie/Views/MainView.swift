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
            ThemeSelectionView()
        } content: {
            VStack(alignment: .leading) {
                Text("Select a theme from the sidebar to view its sets")
                    .padding()
            }
        } detail: {
            VStack(alignment: .leading) {
                Text("Select a theme to see details")
            }
            .padding()
        }
    }

    // Themes loading handled by ThemeSelectionViewModel
}

// MARK: - Preview

#Preview {
    MainView()
}
