//
//  SetsListView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct SetsListView: View {
    @Environment(\.diContainer)
    private var diContainer
    @Query(sort: \LegoSet.year, order: .reverse)
    private var cachedSets: [LegoSet]
    
    @State private var viewModel: SetsListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.sets.isEmpty && !cachedSets.isEmpty {
                        cachedSetsView
                    } else if vm.sets.isEmpty && !vm.isLoading {
                        emptyStateView
                    } else if vm.isLoading && vm.sets.isEmpty {
                        loadingView
                    } else {
                        setsListView
                    }
                } else {
                    loadingView
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Text(NSLocalizedString("LEGO Sets", comment: "Navigation title"))
                        .font(.brixieTitle)
                        .foregroundStyle(Color.brixieText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if let vm = viewModel {
                        OfflineIndicatorBadge(
                            lastSyncTimestamp: vm.lastSyncTimestamp,
                            variant: .compact
                        )
                    }
                }
            }
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
                    SetRowView(set: set) { set in
                        Task {
                            await viewModel?.toggleFavorite(for: set)
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel?.loadSets()
        }
    }

    private var loadingView: some View {
        BrixieHeroSection(
            title: NSLocalizedString("Loading Sets", comment: "Loading title"),
            subtitle: NSLocalizedString("Discovering amazing LEGO sets for you...", comment: "Loading subtitle"),
            icon: "building.2"
        ) {
            BrixieLoadingView()
        }
    }

    private var emptyStateView: some View {
        BrixieHeroSection(
            title: NSLocalizedString("No Sets Found", comment: "Empty state title"),
            subtitle: NSLocalizedString("Pull to refresh or check your internet connection", comment: "Empty state subtitle"),
            icon: "building.2"
        ) {
            Button(NSLocalizedString("Refresh", comment: "Refresh button")) {
                Task {
                    await viewModel?.loadSets()
                }
            }
            .buttonStyle(BrixieButtonStyle(variant: .primary))
        }
    }

    private var setsListView: some View {
        List {
            if let vm = viewModel {
                ForEach(vm.sets) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        SetRowView(set: set) { set in
                            Task {
                                await vm.toggleFavorite(for: set)
                            }
                        }
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
    
    @ViewBuilder
    private func errorBannerView(for error: BrixieError) -> some View {
        switch error {
        case .networkError:
            BrixieBannerView.networkError(onRetry: {
                Task {
                    await viewModel?.retryLoad()
                }
            }, onDismiss: {
                viewModel?.error = nil
            })
            
        case .apiKeyMissing, .unauthorized:
            BrixieBannerView.apiKeyError(onRetry: {
                // Navigate to settings - for now just clear error
                viewModel?.error = nil
            }, onDismiss: {
                viewModel?.error = nil
            })
            
        default:
            BrixieBannerView.generalError(
                error,
                onRetry: {
                    Task {
                        await viewModel?.retryLoad()
                    }
                },
                onDismiss: {
                    viewModel?.error = nil
                }
            )
        }
    }
}

struct SetRowView: View {
    let set: LegoSet
    let onFavoriteToggle: ((LegoSet) -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    init(set: LegoSet, onFavoriteToggle: ((LegoSet) -> Void)? = nil) {
        self.set = set
        self.onFavoriteToggle = onFavoriteToggle
    }

    var body: some View {
        HStack {
            CachedImageCard(urlString: set.imageURL, maxHeight: 60)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brixieSecondary(for: colorScheme))
                )
                .accessibilityLabel(Text("LEGO set image for \(set.name)"))

            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.brixieHeadline)
                    .lineLimit(2)
                    .foregroundStyle(Color.brixieText(for: colorScheme))

                Text(String(format: NSLocalizedString("Set #%@", comment: "Set number display"), set.setNum))
                    .font(.brixieBody)
                    .foregroundStyle(Color.brixieTextSecondary(for: colorScheme))

                HStack {
                    Text("\(set.year)")
                        .font(.brixieCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.brixieAccent.opacity(0.2))
                        .foregroundStyle(Color.brixieAccent)
                        .clipShape(Capsule())

                    if let themeName = set.themeName {
                        Text(themeName)
                            .font(.brixieCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.brixieSuccess.opacity(0.2))
                            .foregroundStyle(Color.brixieSuccess)
                            .clipShape(Capsule())
                    }

                    Text(String(format: NSLocalizedString("%d pieces", comment: "Number of pieces"), set.numParts))
                        .font(.brixieCaption)
                        .foregroundStyle(Color.brixieTextSecondary(for: colorScheme))
                }
            }

            Spacer()

            FavoriteButton(isFavorite: set.isFavorite) { onFavoriteToggle?(set) }
                .accessibilityLabel(Text(set.isFavorite ? "Remove from favorites" : "Add to favorites"))
                .accessibilityHint(Text("Double tap to toggle favorite status"))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(set.name), set number \(set.setNum), from \(set.year), \(set.numParts) pieces\(set.themeName != nil ? ", \(set.themeName!)" : ""), \(set.isFavorite ? "favorited" : "not favorited")"))
        .accessibilityHint(Text("Double tap to view details"))
    }
}

struct SetRowSkeleton: View {
    var body: some View {
        HStack {
            // Image skeleton
            SkeletonImage(width: 60, height: 60, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 4) {
                // Title skeleton - two lines
                SkeletonTextLine(width: 200, height: 18)
                SkeletonTextLine(width: 150, height: 18)

                // Set number skeleton
                SkeletonTextLine(width: 100, height: 14)

                HStack {
                    // Year badge skeleton
                    SkeletonTextLine(width: 40, height: 20)
                        .clipShape(Capsule())

                    // Pieces text skeleton
                    SkeletonTextLine(width: 80, height: 12)
                }
            }

            Spacer()

            // Heart button skeleton
            SkeletonTextLine(width: 24, height: 24)
                .clipShape(Circle())
        }
        .padding(.vertical, 4)
    }
}

struct SkeletonListView: View {
    let itemCount: Int

    init(itemCount: Int = 8) {
        self.itemCount = itemCount
    }

    var body: some View {
        List {
            ForEach(0..<itemCount, id: \.self) { _ in
                SetRowSkeleton()
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

#Preview {
    SetsListView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}

#Preview("SetRowSkeleton") {
    VStack {
        SetRowSkeleton()
            .padding()
        Divider()
        SetRowSkeleton()
            .padding()
    }
}

#Preview("SkeletonListView") {
    SkeletonListView(itemCount: 5)
}

#Preview {
    // Small preview for the row component used in lists
    let sample = LegoSet(
        setNum: "10294-1",
        name: "Titanic",
        year: 2_021,
        themeId: 1,
        numParts: 9_090,
        themeName: "Creator Expert"
    )

    SetRowView(set: sample)
        .padding()
}
