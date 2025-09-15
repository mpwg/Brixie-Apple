//
//  ThemeRowView.swift
//  Brixie
//
//  Created by Claude on 15.09.25.
//

import SwiftUI

struct ThemeRowView: View {
    let displayItem: ThemeDisplayItem
    let onToggleExpanded: (Int) -> Void
    let di: DIContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Theme content is padded for indentation instead of using a Spacer with fixed frame.
                // Using padding(.leading:) is more efficient in lists than Spacer().frame(width:).

                // Expansion indicator
                if displayItem.hasChildren {
                    Button(action: {
                        onToggleExpanded(displayItem.theme.id)
                    }) {
                        Image(systemName: displayItem.isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Alignment spacer for items without children
                    Spacer()
                        .frame(width: 20)
                }

                // Theme content
                if displayItem.hasChildren {
                    // Parent theme: just shows label for expansion
                    HStack {
                        Text(displayItem.theme.name)
                        Text("ID: \(displayItem.theme.id)")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                } else {
                    // Leaf theme: navigates to SetListView
                    NavigationLink {
                        SetListView(theme: displayItem.theme, di: di)
                    } label: {
                        HStack {
                            Text(displayItem.theme.name)
                            Text("ID: \(displayItem.theme.id)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.leading, displayItem.indentationWidth)
        }
    }
}

#Preview {
    NavigationStack {
        VStack {
            ThemeRowView(
                displayItem: ThemeDisplayItem(
                    theme: LegoTheme(id: 1, name: "Sample Theme", parentId: nil),
                    level: 0,
                    isExpanded: false,
                    hasChildren: true
                ),
                onToggleExpanded: { _ in },
                di: DIContainer()
            )

            ThemeRowView(
                displayItem: ThemeDisplayItem(
                    theme: LegoTheme(id: 2, name: "Nested Theme", parentId: 1),
                    level: 1,
                    isExpanded: false,
                    hasChildren: false
                ),
                onToggleExpanded: { _ in },
                di: DIContainer()
            )
        }
        .padding()
    }
}
