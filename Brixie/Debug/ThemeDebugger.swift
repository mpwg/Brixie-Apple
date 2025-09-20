import Foundation

// Quick debug tool to test theme fetching
@MainActor
class ThemeDebugger {
    static func debugThemeFetching() {
        print("=== THEME DEBUG SESSION ===")
        
        let themeService = ThemeService.shared
        
        // Force clear themes and refetch
        Task {
            do {
                print("🧹 Clearing cached themes...")
                try themeService.clearCachedThemes()
                
                print("📥 Fetching themes from API...")
                let themes = try await themeService.fetchThemes()
                
                print("📊 Total themes fetched: \(themes.count)")
                
                let rootThemes = themes.filter { $0.isRootTheme }
                print("🎯 Root themes: \(rootThemes.count)")
                
                print("🔍 Root themes list:")
                for (index, theme) in rootThemes.enumerated() {
                    print("  \(index + 1). \(theme.name) (ID: \(theme.id))")
                }
                
                // Check for themes with parents
                let childThemes = themes.filter { !$0.isRootTheme }
                print("👶 Child themes: \(childThemes.count)")
                
                if childThemes.count > 0 {
                    print("🔍 First 5 child themes:")
                    for (index, theme) in childThemes.prefix(5).enumerated() {
                        print("  \(index + 1). \(theme.name) (ID: \(theme.id), Parent: \(theme.parentId ?? 0))")
                    }
                }
                
                // Get theme statistics
                let stats = try themeService.getThemeStatistics()
                print("📈 Statistics: Total: \(stats.totalThemes), Root: \(stats.rootThemes), Fresh: \(stats.isDataFresh)")
                
            } catch {
                print("❌ Error during theme debug: \(error)")
            }
        }
    }
}