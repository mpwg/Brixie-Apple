//
//  BrixieApp.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftData
import SwiftUI

@main
struct BrixieApp: App {
    // Single DI container for the app lifetime
    private let di = MainActor.assumeIsolated { DIContainer.shared }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.diContainer, di)
        }
        // Use the DI's ModelContainer for all SwiftData operations
        .modelContainer(di.modelContainer)
    }
}
