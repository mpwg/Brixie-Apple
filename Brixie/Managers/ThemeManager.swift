//
//  ThemeManager.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import SwiftUI
import Foundation

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light:
            return Strings.light.localized
        case .dark:
            return Strings.dark.localized
        case .system:
            return Strings.system.localized
        }
    }
    
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}

@Observable
@MainActor
class ThemeManager {
    static let shared = ThemeManager()
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    var selectedTheme: AppTheme {
        didSet {
            userDefaults.set(selectedTheme.rawValue, forKey: themeKey)
            updateColorScheme()
        }
    }
    
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    private init() {
        if let themeString = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeString) {
            selectedTheme = theme
        } else {
            selectedTheme = .system
        }
    }
    
    private func updateColorScheme() {
        // Trigger UI update - handled by @Observable
    }
}