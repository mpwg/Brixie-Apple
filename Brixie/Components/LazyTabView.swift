//
//  LazyTabView.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import SwiftUI

/// A performance-optimized TabView that only creates views when they are first accessed
/// This improves app launch time and memory usage by deferring heavy view initialization
struct LazyTabView<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let tabs: [(value: SelectionValue, label: AnyView, content: () -> AnyView)]
    
    @State private var loadedTabs: Set<SelectionValue> = []
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs, id: \.value) { tab in
                Group {
                    if loadedTabs.contains(tab.value) {
                        tab.content()
                    } else {
                        // Show minimal placeholder while tab loads
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.regularMaterial)
                            .onAppear {
                                // Load the tab content
                                loadedTabs.insert(tab.value)
                            }
                    }
                }
                .tabItem {
                    tab.label
                }
                .tag(tab.value)
                .id(tab.value) // Preserve view identity
            }
        }
        .onAppear {
            // Always load the initial tab immediately
            if !loadedTabs.contains(selection) {
                loadedTabs.insert(selection)
            }
        }
        .onChange(of: selection) { _, newValue in
            // Load tab content when switching
            if !loadedTabs.contains(newValue) {
                loadedTabs.insert(newValue)
            }
        }
    }
}

// MARK: - Convenience Extensions

extension LazyTabView {
    init(
        selection: Binding<SelectionValue>,
        @LazyTabBuilder<SelectionValue> content: () -> [(value: SelectionValue, label: AnyView, content: () -> AnyView)]
    ) {
        self.init(selection: selection, tabs: content())
    }
}

// MARK: - Result Builder for Lazy Tabs

@resultBuilder
struct LazyTabBuilder<SelectionValue: Hashable> {
    static func buildBlock(_ components: LazyTab<SelectionValue>...) -> [(value: SelectionValue, label: AnyView, content: () -> AnyView)] {
        return components.map { tab in
            (value: tab.value, label: tab.label, content: tab.content)
        }
    }
}

struct LazyTab<SelectionValue: Hashable> {
    let value: SelectionValue
    let label: AnyView
    let content: () -> AnyView
    
    init<Label: View, Content: View>(
        _ value: SelectionValue,
        @ViewBuilder label: () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.value = value
        self.label = AnyView(label())
        self.content = { AnyView(content()) }
    }
}

// MARK: - NavigationTab Specific Implementation

// Note: This extension is moved to ContentView.swift to access private selectedTab property

#Preview {
    LazyTabView(selection: .constant(NavigationTab.browse), tabs: [
        (.browse, AnyView(Label("Browse", systemImage: "magnifyingglass")), { AnyView(Text("Browse View")) }),
        (.search, AnyView(Label("Search", systemImage: "search")), { AnyView(Text("Search View")) }),
    ])
}