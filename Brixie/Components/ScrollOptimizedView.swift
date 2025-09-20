//
//  ScrollOptimizedView.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import SwiftUI

/// A view modifier that optimizes animations during scrolling for better performance
struct ScrollOptimizedView: ViewModifier {
    @State private var isScrolling = false
    @State private var scrollTimer: Timer?
    
    /// Duration to wait after scroll stops before re-enabling animations
    private let animationRestoreDelay: TimeInterval = 0.1
    
    func body(content: Content) -> some View {
        content
            .animation(isScrolling ? nil : .default, value: UUID())
            .onScrollPhaseChange { oldPhase, newPhase in
                handleScrollPhaseChange(oldPhase: oldPhase, newPhase: newPhase)
            }
    }
    
    private func handleScrollPhaseChange(oldPhase: ScrollPhase, newPhase: ScrollPhase) {
        switch newPhase {
        case .idle:
            // Delay animation restoration to avoid flickering
            scrollTimer?.invalidate()
            scrollTimer = Timer.scheduledTimer(withTimeInterval: animationRestoreDelay, repeats: false) { _ in
                Task { @MainActor in
                    isScrolling = false
                }
            }
        case .tracking, .decelerating, .animating, .interacting:
            scrollTimer?.invalidate()
            isScrolling = true
        @unknown default:
            break
        }
    }
}

/// A view modifier for list/grid items that optimizes their appearance during scrolling
struct ScrollOptimizedItem: ViewModifier {
    @State private var isScrolling = false
    @State private var wasVisible = false
    
    let onAppear: (() -> Void)?
    let onDisappear: (() -> Void)?
    
    init(onAppear: (() -> Void)? = nil, onDisappear: (() -> Void)? = nil) {
        self.onAppear = onAppear
        self.onDisappear = onDisappear
    }
    
    func body(content: Content) -> some View {
        content
            .drawingGroup(opaque: true) // Rasterize complex views during scroll
            .clipped() // Prevent overdraw
            .onAppear {
                if !wasVisible {
                    wasVisible = true
                    onAppear?()
                }
            }
            .onDisappear {
                onDisappear?()
            }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Optimizes the view for scrolling performance by disabling animations during scroll
    func scrollOptimized() -> some View {
        self.modifier(ScrollOptimizedView())
    }
    
    /// Optimizes list/grid items for better scroll performance
    func scrollOptimizedItem(
        onAppear: (() -> Void)? = nil,
        onDisappear: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ScrollOptimizedItem(onAppear: onAppear, onDisappear: onDisappear))
    }
}

// MARK: - Optimized List Components

/// A performance-optimized List that handles scroll states automatically
struct OptimizedList<Data: RandomAccessCollection, ID: Hashable, RowContent: View>: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let rowContent: (Data.Element) -> RowContent
    
    @State private var isScrolling = false
    
    var body: some View {
        List {
            ForEach(data, id: id) { item in
                rowContent(item)
                    .scrollOptimizedItem()
            }
        }
        .listStyle(.plain) // Use plain style for better performance
        .scrollOptimized()
    }
}

/// A performance-optimized LazyVGrid that handles scroll states automatically  
struct OptimizedLazyVGrid<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let columns: [GridItem]
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(data, id: id) { item in
                    content(item)
                        .scrollOptimizedItem()
                }
            }
            .padding()
        }
        .scrollOptimized()
        .scrollIndicators(.hidden) // Hide scroll indicators for cleaner look
    }
}

// MARK: - Preview Support

#Preview {
    OptimizedList(
        data: Array(1...100),
        id: \.self
    ) { number in
        HStack {
            Image(systemName: "photo")
                .foregroundColor(.blue)
            Text("Item \(number)")
            Spacer()
        }
        .padding()
    }
}