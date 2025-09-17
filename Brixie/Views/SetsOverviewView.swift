import SwiftUI

// Ensure BadgeView.swift, Item.swift, DIContainer.swift, and SetListViewModel.swift are in the Brixie target.

// NOTE: If you see 'Cannot find type in scope' errors, ensure Item.swift, DIContainer.swift, and SetListViewModel.swift are included in your Xcode target's build phases.

struct SetsOverviewView: View {
    @Environment(\.diContainer) private var di: DIContainer
    @State private var viewModel: SetListViewModel

    init(di: DIContainer? = nil) {
        let container = di ?? MainActor.assumeIsolated { DIContainer.shared }
        let repository = container.makeLegoSetRepository()
        _viewModel = State(initialValue: SetListViewModel(repository: repository, themeId: 0))  // themeId: 0 for all sets
    }

    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Alle"
    @State private var selectedSort: String = "Keine"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary header
            HStack {
                Text("LEGO-Sets Übersicht")
                    .font(.largeTitle)
                Spacer()
                Label("Gesamtanzahl der LEGO-Teile", systemImage: "number")
                Text("\(viewModel.sets.reduce(0) { $0 + $1.numParts })")
                    .foregroundStyle(.secondary)
                // Example badge for missing parts
                let missingCount = viewModel.sets.filter { $0.numParts == 0 }.count
                if missingCount > 0 {
                    BadgeView(count: missingCount, color: .orange)
                }
            }
            .padding([.top, .horizontal])

            // Search and filter controls
            HStack(spacing: 16) {
                TextField("Gib die Set-Nummer, das Thema, ...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200, maxWidth: 320)
                Picker("Filter", selection: $selectedFilter) {
                    Text("Alle").tag("Alle")
                    Text("Meine Sets").tag("Meine Sets")
                    Text("Fehlend").tag("Fehlend")
                }
                .pickerStyle(.segmented)
                // Example badge for "Fehlend" filter
                if selectedFilter == "Fehlend" {
                    let missingCount = viewModel.sets.filter { $0.numParts == 0 }.count
                    BadgeView(count: missingCount, color: .orange)
                }
                Picker("Sortieren nach", selection: $selectedSort) {
                    Text("Keine").tag("Keine")
                    Text("Jahr").tag("Jahr")
                    Text("Set-Nummer").tag("Set-Nummer")
                    Text("Name").tag("Name")
                    Text("Teile").tag("Teile")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Main content
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
