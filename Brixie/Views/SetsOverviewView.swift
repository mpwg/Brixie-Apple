import SwiftUI

// NOTE: If you see 'Cannot find type in scope' errors, ensure Item.swift, DIContainer.swift, and SetListViewModel.swift are included in your Xcode target's build phases.

struct SetsOverviewView: View {
    @Environment(\.diContainer) private var di: DIContainer
    @State private var viewModel: SetListViewModel

    init(di: DIContainer? = nil) {
        let container = di ?? MainActor.assumeIsolated { DIContainer.shared }
        let repository = container.makeLegoSetRepository()
        _viewModel = State(initialValue: SetListViewModel(repository: repository, themeId: 0))  // themeId: 0 for all sets
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("LEGO-Sets Übersicht")
                .font(.largeTitle)
                .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView("Lade Sets…")
                    .padding()
            } else if viewModel.sets.isEmpty {
                Text("Keine Sets gefunden.")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 280), spacing: 24)], spacing: 24
                    ) {
                        ForEach(viewModel.sets, id: \.setNum) { set in
                            SetCardView(set: set)
                                .onAppear {
                                    Task { await viewModel.loadMoreIfNeeded(currentItem: set) }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.loadInitial()
        }
    }
}

struct SetCardView: View {
    let set: LegoSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlString = set.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 160)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 160)
                            .cornerRadius(12)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 160)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .foregroundStyle(.secondary)
            }

            Text(set.name)
                .font(.headline)
                .lineLimit(2)
            Text("Set-Nummer: \(set.setNum)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text("Jahr: \(set.year)")
                Spacer()
                Text("Teile: \(set.numParts)")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack {
                Button(action: { /* TODO: Add to collection */  }) {
                    Text("Dieses LEGO hinzufügen")
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { /* TODO: Add to wishlist */  }) {
                    Text("Zur Wunschliste hinzufügen")
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        // For platform-specific backgrounds, use Color(.systemBackground) on iOS, Color(.windowBackgroundColor) on macOS, etc.
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(radius: 2))
    }
}

#Preview {
    SetsOverviewView()
}
