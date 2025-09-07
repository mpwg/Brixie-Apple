//
//  SetsListView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct SetsListView: View {
    @Environment(\.diContainer) private var diContainer
    @Query(sort: \LegoSet.year, order: .reverse) private var cachedSets: [LegoSet]
    
    @State private var viewModel: SetsListViewModel?
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.sets.isEmpty && !cachedSets.isEmpty {
                        cachedSetsView
                    } else if vm.sets.isEmpty && !vm.isLoading {
                        emptyStateView
                    } else {
                        setsListView
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("LEGO Sets")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = diContainer.makeSetsListViewModel()
                Task {
                    await viewModel?.loadSets()
                }
            }
        }
    }
    
    
    private var cachedSetsView: some View {
        List {
            ForEach(cachedSets) { set in
                NavigationLink(destination: SetDetailView(set: set)) {
                    SetRowView(set: set, onFavoriteToggle: { set in
                        Task {
                            await viewModel?.toggleFavorite(for: set)
                        }
                    })
                }
            }
        }
        .refreshable {
            await viewModel?.loadSets()
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
            if let vm = viewModel {
                ForEach(vm.sets) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        SetRowView(set: set, onFavoriteToggle: { set in
                            Task {
                                await vm.toggleFavorite(for: set)
                            }
                        })
                    }
                    .onAppear {
                        if set == vm.sets.last {
                            Task {
                                await vm.loadMoreSets()
                            }
                        }
                    }
                }
                
                if vm.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .refreshable {
            await viewModel?.loadSets()
        }
    }
}

struct SetRowView: View {
    let set: LegoSet
    let onFavoriteToggle: ((LegoSet) -> Void)?
    
    init(set: LegoSet, onFavoriteToggle: ((LegoSet) -> Void)? = nil) {
        self.set = set
        self.onFavoriteToggle = onFavoriteToggle
    }
    
    var body: some View {
        HStack {
            CachedImageCard(urlString: set.imageURL, maxHeight: 60)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                Text(String(format: NSLocalizedString("Set #%@", comment: "Set number display"), set.setNum))
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
                    
                    Text(String(format: NSLocalizedString("%d pieces", comment: "Number of pieces"), set.numParts))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            FavoriteButton(isFavorite: set.isFavorite, action: { onFavoriteToggle?(set) })
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SetsListView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
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
}
