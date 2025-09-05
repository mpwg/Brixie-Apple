//
//  CategoriesView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var themeService: LegoThemeService?
    @State private var themes: [LegoTheme] = []
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .name
    @State private var showingAPIKeyAlert = false
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case setCount = "Set Count"
        
        var localizedString: String {
            NSLocalizedString(self.rawValue, comment: "Sort order")
        }
    }
    
    var filteredAndSortedThemes: [LegoTheme] {
        var filtered = themes
        
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
                Color.brixieBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !apiKeyManager.hasValidAPIKey {
                        apiKeyPromptView
                    } else if let service = themeService {
                        if service.isLoading && themes.isEmpty {
                            loadingView
                        } else {
                            modernCategoriesView
                        }
                        
                        if let errorMessage = service.errorMessage {
                            errorView(errorMessage)
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
                    HStack(spacing: 12) {
                        Button {
                            showingAPIKeyAlert = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.brixieAccent)
                                .padding(6)
                                .background(Circle().fill(Color.brixieCard))
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
                    }
                }
            }
            .searchable(text: $searchText, prompt: NSLocalizedString("Search categories", comment: "Search prompt"))

        }
        .task {
            if apiKeyManager.hasValidAPIKey {
                await initializeService()
            }
        }
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: $apiKeyManager.apiKey)
            Button("Save") {
                Task {
                    await initializeService()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your Rebrickable API key to fetch LEGO categories")
        }
    }
    
    private var apiKeyPromptView: some View {
        BrixieHeroSection(
            title: "Explore Categories",
            subtitle: "Browse LEGO themes and categories. Connect with your Rebrickable API key to get started.",
            icon: "square.grid.3x3.fill"
        ) {
            VStack(spacing: 16) {
                Button("Connect API Key") {
                    showingAPIKeyAlert = true
                }
                .buttonStyle(BrixieButtonStyle(variant: .primary))
                
                Button("Learn More") {
                    // Open rebrickable.com
                }
                .buttonStyle(BrixieButtonStyle(variant: .ghost))
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
    
    private func errorView(_ message: String) -> some View {
        BrixieCard {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.brixieWarning)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection Issue")
                        .font(.brixieSubhead)
                        .foregroundStyle(Color.brixieText)
                    
                    Text(message)
                        .font(.brixieBody)
                        .foregroundStyle(Color.brixieTextSecondary)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
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
            await loadThemes()
        }
    }
    
    @MainActor
    private func initializeService() async {
        guard themeService == nil else { return }
        
        themeService = LegoThemeService(modelContext: modelContext, apiKey: apiKeyManager.apiKey)
        
        let cachedThemes = themeService?.getCachedThemes() ?? []
        if !cachedThemes.isEmpty {
            themes = cachedThemes
        }
        
        await loadThemes()
    }
    
    @MainActor
    private func loadThemes() async {
        guard let service = themeService else { return }
        
        do {
            let fetchedThemes = try await service.fetchThemes()
            themes = fetchedThemes
        } catch {
            themes = service.getCachedThemes()
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
                .brixieGlow(color: .brixieAccent.opacity(0.4))
                
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
                            AnimatedCounter(value: theme.setCount)
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
        case let x where x.contains("vehicle") || x.contains("car") || x.contains("truck"):
            return "car"
        case let x where x.contains("train"):
            return "tram"
        case let x where x.contains("boat") || x.contains("ship"):
            return "ferry"
        case let x where x.contains("animal") || x.contains("pet"):
            return "pawprint"
        default:
            return "square.grid.3x3"
        }
    }
}

#Preview {
    ZStack {
        Color.brixieBackground
            .ignoresSafeArea()
        
        CategoriesView()
            .modelContainer(for: [LegoTheme.self, LegoSet.self], inMemory: true)
    }
}

