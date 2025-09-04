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
    
    @AppStorage("rebrickableAPIKey") private var apiKey = ""
    @State private var legoSetService: LegoSetService?
    @State private var sets: [LegoSet] = []
    @State private var showingAPIKeyAlert = false
    @State private var currentPage = 1
    @State private var isLoadingMore = false
    
    var body: some View {
        NavigationStack {
            Group {
                if legoSetService == nil {
                    apiKeyPromptView
                } else if sets.isEmpty && !cachedSets.isEmpty {
                    cachedSetsView
                } else if sets.isEmpty {
                    emptyStateView
                } else {
                    setsListView
                }
            }
            .navigationTitle("LEGO Sets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingAPIKeyAlert = true
                    }
                }
            }
        }
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: $apiKey)
            Button("Save") {
                setupService()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your Rebrickable API key to fetch LEGO sets")
        }
        .onAppear {
            if legoSetService == nil && !apiKey.isEmpty {
                setupService()
            }
        }
    }
    
    private var apiKeyPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("API Key Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To fetch LEGO sets, you need a Rebrickable API key. Get one for free at rebrickable.com")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Enter API Key") {
                showingAPIKeyAlert = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var cachedSetsView: some View {
        List {
            ForEach(cachedSets) { set in
                NavigationLink(destination: SetDetailView(set: set)) {
                    SetRowView(set: set)
                }
            }
        }
        .refreshable {
            await loadSets()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("No Sets Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Pull to refresh or check your internet connection")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var setsListView: some View {
        List {
            ForEach(sets) { set in
                NavigationLink(destination: SetDetailView(set: set)) {
                    SetRowView(set: set)
                }
                .onAppear {
                    if set == sets.last {
                        Task {
                            await loadMoreSets()
                        }
                    }
                }
            }
            
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            }
        }
        .refreshable {
            currentPage = 1
            await loadSets()
        }
    }
    
    private func setupService() {
        legoSetService = LegoSetService(modelContext: modelContext, apiKey: apiKey)
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

struct SetRowView: View {
    let set: LegoSet
    
    var body: some View {
        HStack {
            AsyncCachedImage(urlString: set.imageURL)
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("Set #\(set.setNum)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("\(set.year)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    
                    Text("\(set.numParts) pieces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if set.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SetsListView()
        .modelContainer(for: LegoSet.self, inMemory: true)
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

    SetRowView(set: sample)
        .padding()
        .previewLayout(.sizeThatFits)
}