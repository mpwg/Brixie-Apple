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
    
    init(itemCount: Int = AppConstants.Layout.defaultSkeletonItemCount, itemHeight: CGFloat = AppConstants.Layout.standardListItemHeight) {
        self.itemCount = itemCount
        self.itemHeight = itemHeight
    }
    
    var body: some View {
        LazyVStack(spacing: AppConstants.Layout.listRowSpacing) {
            ForEach(0..<itemCount, id: \.self) { _ in
                skeletonRow
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: AppConstants.Timing.skeletonAnimationDuration).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var skeletonRow: some View {
        HStack(spacing: AppConstants.Layout.listRowSpacing) {
            // Image placeholder
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.thumbnail)
                .fill(.quaternary)
                .frame(width: itemHeight, height: itemHeight)
                .opacity(isAnimating ? AppConstants.Opacity.shimmerPrimary : AppConstants.Opacity.shimmerSecondary)
            
            VStack(alignment: .leading, spacing: AppConstants.Layout.skeletonRowSpacing) {
                // Title placeholder
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.skeleton)
                    .fill(.quaternary)
                    .frame(height: AppConstants.ImageSize.skeletonPlaceholderHeight)
                    .opacity(isAnimating ? AppConstants.Opacity.shimmerPrimary : AppConstants.Opacity.shimmerSecondary)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.skeleton)
                    .fill(.quaternary)
                    .frame(maxWidth: .infinity, maxHeight: AppConstants.ImageSize.skeletonSecondaryHeight)
                    .opacity(isAnimating ? AppConstants.Opacity.skeletonMin : AppConstants.Opacity.skeletonMax)
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
        VStack(spacing: AppConstants.Layout.listRowSpacing) {
            ForEach(0..<AppConstants.Layout.themePreviewItemCount, id: \.self) { _ in
                themeSkeletonRow
            }
        }
        .accessibilityLabel("Loading themes")
    }
    
    private var themeSkeletonRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppConstants.Layout.skeletonRowSpacing) {
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.skeleton)
                    .fill(.quaternary)
                    .frame(height: AppConstants.ImageSize.skeletonPlaceholderHeight)
                
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.skeleton)
                    .fill(.quaternary)
                    .frame(maxWidth: AppConstants.ImageSize.skeletonMaxWidth, maxHeight: AppConstants.ImageSize.skeletonSecondaryHeight)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, AppConstants.UI.smallSpacing)
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
