//
//  CategoriesView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.diContainer)
    private var diContainer
    @Environment(\.colorScheme)
    private var colorScheme
    @State private var viewModel: CategoriesViewModel?
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .name
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case setCount = "Set Count"
        
        var localizedString: String {
            switch self {
            case .name:
                return NSLocalizedString("Name", comment: "Sort order")
            case .setCount:
                return NSLocalizedString("Set Count", comment: "Sort order")
            }
        }
    }
    
    var filteredAndSortedThemes: [LegoTheme] {
        guard let vm = viewModel else { return [] }
        
        var filtered = vm.themes
        
        if !searchText.isEmpty {
            filtered = filtered.filter { theme in
                theme.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch sortOrder {
        case .name:
            filtered = filtered.sorted { $0.name < $1.name }
        case .setCount:
            filtered = filtered.sorted { $0.setCount > $1.setCount }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let vm = viewModel {
                        if vm.isLoading && vm.themes.isEmpty {
                            loadingView
                        } else {
                            modernCategoriesView
                        }
                        
                        if let error = vm.error {
                            BrixieErrorBanner(
                                error: error,
                                onDismiss: { vm.error = nil },
                                onRetry: { 
                                    Task { await vm.loadThemes() }
                                }
                            )
                        }
                    } else {
                        initializingView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Text(NSLocalizedString("Categories", comment: "Navigation title"))
                        .font(.brixieTitle)
                        .foregroundStyle(Color.brixieText)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if let vm = viewModel {
                            OfflineIndicatorBadge(
                                lastSyncTimestamp: vm.lastSyncTimestamp,
                                variant: .iconOnly
                            )
                        }
                        
                        Menu {
                                Picker(NSLocalizedString("Sort by", comment: "Sort picker label"), selection: $sortOrder) {
                                    ForEach(SortOrder.allCases, id: \.self) { order in
                                        Label(order.localizedString, systemImage: sortOrder == order ? "checkmark" : "")
                                            .tag(order)
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.brixieAccent)
                                    .padding(6)
                                    .background(Circle().fill(Color.brixieCard))
                            }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.brixieAccent)
                            .padding(6)
                            .background(Circle().fill(Color.brixieCard))
                    }
                }
            }
            .searchable(text: $searchText, prompt: NSLocalizedString("Search categories", comment: "Search prompt"))
        }
        .task {
            if viewModel == nil {
                viewModel = diContainer.makeCategoriesViewModel()
                await viewModel?.loadThemes()
            }
        }
    }
    
    private var loadingView: some View {
        BrixieHeroSection(
            title: "Loading Categories",
            subtitle: "Discovering all the amazing LEGO themes for you...",
            icon: "square.grid.3x3"
        ) {
            BrixieLoadingView()
        }
    }
    
    private var initializingView: some View {
        BrixieHeroSection(
            title: "Getting Ready",
            subtitle: "Preparing your LEGO categories experience...",
            icon: "gear"
        ) {
            BrixieLoadingView()
        }
    }
    
    private var modernCategoriesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredAndSortedThemes, id: \.id) { theme in
                    NavigationLink(destination: CategoryDetailView(theme: theme)) {
                        ModernCategoryRowView(theme: theme)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .refreshable {
        }
    }
}

struct ModernCategoryRowView: View {
    let theme: LegoTheme
    @State private var isHovered = false
    
    var body: some View {
        BrixieCard(gradient: isHovered) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.brixieAccent.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: categoryIcon(for: theme.name))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.brixieAccent)
                }
                .brixieGlow(color: Color.brixieAccent.opacity(0.4))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(theme.name)
                        .font(.brixieHeadline)
                        .foregroundStyle(Color.brixieText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.brixieSuccess)
                            Text("\(theme.setCount)")
                                .font(.brixieCaption)
                                .foregroundStyle(Color.brixieSuccess)
                            Text("sets")
                                .font(.brixieCaption)
                                .foregroundStyle(Color.brixieTextSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.brixieSuccess.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.brixieSuccess.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        Spacer()
                    }
                }
                
                VStack {
                    Spacer()
                    
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.brixieAccent.opacity(0.6))
                        .scaleEffect(isHovered ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isHovered)
                }
            }
            .padding(16)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private func categoryIcon(for name: String) -> String {
        let lowercased = name.lowercased()
        
        if let icon = getSpecialCategoryIcon(lowercased) {
            return icon
        }
        
        if let icon = getVehicleCategoryIcon(lowercased) {
            return icon
        }
        
        return "square.grid.3x3"
    }
    
    private func getSpecialCategoryIcon(_ lowercased: String) -> String? {
        switch lowercased {
        case let x where x.contains("city"):
            return "building.2.crop.circle"
        case let x where x.contains("space"):
            return "globe"
        case let x where x.contains("castle"):
            return "crown"
        case let x where x.contains("technic"):
            return "gear"
        case let x where x.contains("creator"):
            return "paintbrush"
        case let x where x.contains("friends"):
            return "heart.circle"
        case let x where x.contains("star wars"):
            return "sparkles"
        case let x where x.contains("ninjago"):
            return "figure.martial.arts"
        case let x where x.contains("animal") || x.contains("pet"):
            return "pawprint"
        default:
            return nil
        }
    }
    
    private func getVehicleCategoryIcon(_ lowercased: String) -> String? {
        switch lowercased {
        case let x where x.contains("vehicle") || x.contains("car") || x.contains("truck"):
            return "car"
        case let x where x.contains("train"):
            return "tram"
        case let x where x.contains("boat") || x.contains("ship"):
            return "ferry"
        default:
            return nil
        }
    }
}

#Preview {
    ZStack {
        Color.brixieBackground
            .ignoresSafeArea()
        
        CategoriesView()
            .modelContainer(ModelContainerFactory.createPreviewContainer())
    }
}
