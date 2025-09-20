import SwiftUI
import SwiftData

struct ThemeDebugView: View {
    @Query(sort: \Theme.name) private var allThemes: [Theme]
    @State private var debugOutput: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Statistics
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Themes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(allThemes.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Root Themes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(rootThemes.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Actions
                HStack {
                    Button("Debug Themes") {
                        debugThemes()
                    }
                    .disabled(isLoading)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        refreshThemes()
                    }
                    .disabled(isLoading)
                }
                
                // Debug output
                ScrollView {
                    Text(debugOutput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.systemBackground))
                .border(Color(.separator))
                
                Spacer()
            }
            .padding()
            .navigationTitle("Theme Debug")
            .overlay(
                Group {
                    if isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).opacity(0.8))
                    }
                }
            )
        }
    }
    
    private var rootThemes: [Theme] {
        allThemes.filter { $0.isRootTheme }
    }
    
    private func debugThemes() {
        isLoading = true
        debugOutput = "Starting theme debug...\n"
        
        Task {
            await MainActor.run {
                debugOutput += "📊 Current state:\n"
                debugOutput += "  Total themes in SwiftData: \(allThemes.count)\n"
                debugOutput += "  Root themes in SwiftData: \(rootThemes.count)\n"
                debugOutput += "\n🎯 Root themes:\n"
                
                for (index, theme) in rootThemes.enumerated() {
                    debugOutput += "  \(index + 1). \(theme.name) (ID: \(theme.id))\n"
                }
                
                debugOutput += "\n👶 Sample child themes:\n"
                let childThemes = allThemes.filter { !$0.isRootTheme }
                for (index, theme) in childThemes.prefix(10).enumerated() {
                    debugOutput += "  \(index + 1). \(theme.name) (ID: \(theme.id), Parent: \(theme.parentId ?? 0))\n"
                }
                
                debugOutput += "\nChild themes total: \(childThemes.count)\n"
            }
            
            do {
                debugOutput += "\n🔄 Fetching fresh themes from API...\n"
                let themeService = ThemeService.shared
                
                // Force refresh to see what API returns
                let fetchedThemes = try await themeService.forceRefreshThemes()
                
                await MainActor.run {
                    debugOutput += "✅ Fresh fetch complete!\n"
                    debugOutput += "📥 API returned: \(fetchedThemes.count) themes\n"
                    
                    let freshRootThemes = fetchedThemes.filter { $0.isRootTheme }
                    debugOutput += "🎯 Fresh root themes: \(freshRootThemes.count)\n"
                    
                    debugOutput += "\n🔍 Fresh root themes list:\n"
                    for (index, theme) in freshRootThemes.enumerated() {
                        debugOutput += "  \(index + 1). \(theme.name) (ID: \(theme.id))\n"
                    }
                }
                
            } catch {
                await MainActor.run {
                    debugOutput += "❌ Error: \(error.localizedDescription)\n"
                }
            }
            
            await MainActor.run {
                debugOutput += "\n=== Debug Complete ===\n"
                isLoading = false
            }
        }
    }
    
    private func refreshThemes() {
        isLoading = true
        
        Task {
            do {
                let themeService = ThemeService.shared
                let themes = try await themeService.fetchThemes()
                
                await MainActor.run {
                    debugOutput = "✅ Refreshed: \(themes.count) themes total, \(themes.filter { $0.isRootTheme }.count) root themes\n"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    debugOutput = "❌ Refresh failed: \(error.localizedDescription)\n"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ThemeDebugView()
        .modelContainer(for: [Theme.self, LegoSet.self, UserCollection.self])
}