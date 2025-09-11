import SwiftUI

struct BrixieSearchSuggestions: View {
    let recentSearches: [String]
    let onSelect: (String) -> Void

    var body: some View {
        if !recentSearches.isEmpty {
            Section(LocalizedStringKey("Recent Searches")) {
                ForEach(recentSearches, id: \.self) { search in
                    Button {
                        onSelect(search)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.brixieAccent)
                            Text(search)
                                .foregroundStyle(Color.brixieText)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct BrixieSearchSuggestions_Previews: PreviewProvider {
    static var previews: some View {
        BrixieSearchSuggestions(recentSearches: ["Star Wars", "City"]) { _ in }
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
