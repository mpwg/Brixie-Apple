//
//  SetsListView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct SetsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LegoSet.year, order: .reverse) private var cachedSets: [LegoSet]
    
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var legoSetService: LegoSetService?
    @State private var sets: [LegoSet] = []
    @State private var showingAPIKeyAlert = false
    @State private var currentPage = 1
    @State private var isLoadingMore = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground
                    .ignoresSafeArea()
                
                Group {
                    if !apiKeyManager.hasValidAPIKey {
                        apiKeyPromptView
                    } else if sets.isEmpty && !cachedSets.isEmpty {
                        cachedSetsView
                    } else if sets.isEmpty {
                        emptyStateView
                    } else {
                        setsListView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("LEGO Sets")
                        .font(.brixieTitle)
                        .foregroundStyle(.brixieText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAPIKeyAlert = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.brixieAccent)
                            .padding(8)
                            .background(Circle().fill(.brixieCard))
                    }
                }
            }
        }
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: $apiKeyManager.apiKey)
            Button("Save") {
                setupService()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your Rebrickable API key to fetch LEGO sets")
        }
        .onAppear {
            if legoSetService == nil && apiKeyManager.hasValidAPIKey {
                setupService()
            }
        }
    }
    
    private var apiKeyPromptView: some View {
        BrixieHeroSection(
            title: "Welcome to Brixie",
            subtitle: "Your gateway to the amazing world of LEGO sets. Get started with your free Rebrickable API key.",
            icon: "building.2.crop.circle.fill"
        ) {
            VStack(spacing: 16) {
                Button("Get Started") {
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
    
    private var cachedSetsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offline Collection")
                            .font(.brixieHeadline)
                            .foregroundStyle(.brixieText)
                        Text("Showing cached sets")
                            .font(.brixieCaption)
                            .foregroundStyle(.brixieTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 16))
                        .foregroundStyle(.brixieWarning)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                ForEach(cachedSets) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        ModernSetRowView(set: set)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .refreshable {
            await loadSets()
        }
    }
    
    private var emptyStateView: some View {
        BrixieHeroSection(
            title: "Building Something Amazing",
            subtitle: "We're loading the latest LEGO sets for you. This might take a moment.",
            icon: "cube.box.fill"
        ) {
            BrixieLoadingView()
        }
    }
    
    private var setsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sets) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        ModernSetRowView(set: set)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if set == sets.last {
                            Task {
                                await loadMoreSets()
                            }
                        }
                    }
                }
                
                if isLoadingMore {
                    BrixieLoadingView()
                        .padding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .refreshable {
            currentPage = 1
            await loadSets()
        }
    }
    
    private func setupService() {
        legoSetService = LegoSetService(modelContext: modelContext, apiKey: apiKeyManager.apiKey)
        Task {
            await loadSets()
        }
    }
    
    private func loadSets() async {
        guard let service = legoSetService else { return }
        
        do {
            sets = try await service.fetchSets(page: currentPage)
        } catch {
            // Fallback to cached sets
            sets = service.getCachedSets()
        }
    }
    
    private func loadMoreSets() async {
        guard let service = legoSetService, !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let newSets = try await service.fetchSets(page: currentPage)
            sets.append(contentsOf: newSets)
        } catch {
            currentPage -= 1 // Reset page on error
        }
        
        isLoadingMore = false
    }
}

struct ModernSetRowView: View {
    let set: LegoSet
    @State private var imageLoaded = false
    
    var body: some View {
        BrixieCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.brixieSecondary.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    AsyncCachedImage(urlString: set.imageURL)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .opacity(imageLoaded ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: imageLoaded)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                imageLoaded = true
                            }
                        }
                    
                    if !imageLoaded {
                        Image(systemName: "building.2")
                            .font(.system(size: 24))
                            .foregroundStyle(.brixieAccent.opacity(0.6))
                    }
                }
                .brixieGlow(color: .brixieAccent.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(set.name)
                            .font(.brixieHeadline)
                            .foregroundStyle(.brixieText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(String(format: NSLocalizedString("Set #%@", comment: "Set number display"), set.setNum))
                            .font(.brixieCaption)
                            .foregroundStyle(.brixieTextSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundStyle(.brixieAccent)
                            Text("\(set.year)")
                                .font(.brixieCaption)
                                .foregroundStyle(.brixieAccent)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.brixieAccent.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.brixieAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        HStack(spacing: 4) {
                            Image(systemName: "cube.box")
                                .font(.system(size: 10))
                                .foregroundStyle(.brixieSuccess)
                            AnimatedCounter(value: set.numParts)
                                .font(.brixieCaption)
                                .foregroundStyle(.brixieSuccess)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.brixieSuccess.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.brixieSuccess.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        Spacer()
                    }
                }
                
                VStack {
                    if set.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.red)
                            .brixieGlow(color: .red)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.brixieAccent.opacity(0.6))
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    ZStack {
        Color.brixieBackground
            .ignoresSafeArea()
        
        SetsListView()
            .modelContainer(for: LegoSet.self, inMemory: true)
    }
}

#Preview {
    // Small preview for the row component used in lists
    let sample = LegoSet(
        setNum: "10294-1",
        name: "Titanic",
        year: 2021,
        themeId: 1,
        numParts: 9090
    )

    ZStack {
        Color.brixieBackground
            .ignoresSafeArea()
        
        ModernSetRowView(set: sample)
            .padding(20)
    }
}