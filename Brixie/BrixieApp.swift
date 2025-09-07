//
//  BrixieApp.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData
import Observation

@main
struct BrixieApp: App {
    private let diContainer: DIContainer
    
    init() {
        do {
            let modelContainer = try ModelContainerFactory.createProductionContainer()
            self.diContainer = DIContainer(modelContainer: modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(diContainer)
                .environment(diContainer.themeManager)
                .environment(diContainer.networkMonitorService)
                .preferredColorScheme(diContainer.themeManager.colorScheme)
        }
        .modelContainer(diContainer.modelContainer)
    }
}
