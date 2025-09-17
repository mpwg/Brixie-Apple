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
            // Summary header (refactored for compiler performance)
            HStack {
                Text("LEGO-Sets Übersicht")
                    .font(.largeTitle)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding(.top)

            HStack(spacing: 12) {
                Label("Gesamtanzahl der LEGO-Teile", systemImage: "number")
                    .accessibilityLabel("Gesamtanzahl der LEGO-Teile")
                Text("\(viewModel.sets.reduce(0) { $0 + $1.numParts })")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(
                        "\(viewModel.sets.reduce(0) { $0 + $1.numParts }) Teile insgesamt")
                let missingCount = viewModel.sets.filter { $0.numParts == 0 }.count
                if missingCount > 0 {
                    BadgeView(count: missingCount, color: .orange)
                        .accessibilityLabel("\(missingCount) Sets ohne Teileangabe")
                }
            }
            .padding(.horizontal)

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
                            .accessibilityLabel("Bild von \(set.name)")
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 160)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Kein Bild verfügbar")
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
                    .accessibilityLabel("Kein Bild verfügbar")
            }

            Text(set.name)
                .font(.headline)
                .lineLimit(2)
                .accessibilityLabel("Set Name: \(set.name)")
            Text("Set-Nummer: \(set.setNum)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Set-Nummer: \(set.setNum)")
            HStack {
                Text("Jahr: \(set.year)")
                Spacer()
                Text("Teile: \(set.numParts)")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)

            HStack {
                Button(action: { /* TODO: Add to collection */  }) {
                    Text("Dieses LEGO hinzufügen")
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Dieses LEGO zu meiner Sammlung hinzufügen")
                .accessibilityHint("Fügt das Set zu deiner Sammlung hinzu")

                Button(action: { /* TODO: Add to wishlist */  }) {
                    Text("Zur Wunschliste hinzufügen")
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Dieses LEGO zur Wunschliste hinzufügen")
                .accessibilityHint("Fügt das Set zu deiner Wunschliste hinzu")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 2)
        )
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    SetsOverviewView()
}
