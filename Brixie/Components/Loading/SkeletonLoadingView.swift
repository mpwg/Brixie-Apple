//
//  SkeletonLoadingView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Skeleton loading view that shows placeholder content while data loads
struct SkeletonLoadingView: View {
    let itemCount: Int
    let itemHeight: CGFloat
    @State private var isAnimating = false
    
    init(itemCount: Int = 8, itemHeight: CGFloat = 60) {
        self.itemCount = itemCount
        self.itemHeight = itemHeight
    }
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { _ in
                skeletonRow
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var skeletonRow: some View {
        HStack(spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: itemHeight, height: itemHeight)
                .opacity(isAnimating ? 0.5 : 0.8)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(height: 16)
                    .opacity(isAnimating ? 0.5 : 0.8)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(maxWidth: .infinity, maxHeight: 12)
                    .opacity(isAnimating ? 0.3 : 0.6)
            }
            
            Spacer()
        }
        .frame(height: itemHeight)
        .accessibilityHidden(true)
    }
}

/// Theme-specific skeleton loading view
struct ThemeSkeletonView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                themeSkeletonRow
            }
        }
        .accessibilityLabel("Loading themes")
    }
    
    private var themeSkeletonRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(maxWidth: 100, maxHeight: 12)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }
}

#Preview("Skeleton Loading") {
    SkeletonLoadingView()
        .padding()
}

#Preview("Theme Skeleton") {
    ThemeSkeletonView()
        .padding()
}