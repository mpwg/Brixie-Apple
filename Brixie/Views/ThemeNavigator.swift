import SwiftUI
import SwiftData

struct ThemeNavigator: View {
    @Query(sort: \Theme.name) var themes: [Theme]
    @State private var searchText: String = ""
    @State private var selectedTheme: Theme?
    
    var body: some View {
        VStack {
            HStack {
                Text("Themes")
                    .font(.title2)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                TextField("Search themes", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityIdentifier("themeSearchField")
            }
            .padding(.horizontal)
            
            List(filteredThemes, selection: $selectedTheme) { theme in
                ThemeRow(theme: theme)
                    .id(theme.id) // Explicit view identity
            }
            .listStyle(.plain) // Use plain style for performance
            .accessibilityIdentifier("themeList")
        }
        .accessibilityElement(children: .contain)
    }
    
    private var filteredThemes: [Theme] {
        if searchText.isEmpty {
            return themes
        } else {
            return themes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct ThemeRow: View {
    let theme: Theme
    var body: some View {
        HStack {
            Text(theme.name)
                .font(.body)
            if !theme.subthemes.isEmpty {
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(theme.name)
    }
}

#Preview {
    ThemeNavigator()
}
