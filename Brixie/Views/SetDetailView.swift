import SwiftData
import SwiftUI

struct SetDetailView: View {
    @Environment(\.diContainer) private var di: DIContainer
    @State private var legoSet: LegoSet?
    @State private var isLoading: Bool = false
    @State private var error: BrixieError?

    let setNum: String

    init(setNum: String) {
        self.setNum = setNum
    }

    var body: some View {
        Group {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let legoSet = legoSet {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(legoSet.name)
                            .font(.largeTitle)

                        Text(legoSet.setNum)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Year: \(legoSet.year)")
                            Spacer()
                            Text("Pieces: \(legoSet.numParts)")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        if let themeName = legoSet.themeName {
                            Text("Theme: \(themeName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Placeholder for image / more details
                        if let url = legoSet.imageURL, let imageUrl = URL(string: url) {
                            AsyncImage(url: imageUrl) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 320)
                                case .failure:
                                    Color.gray.frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
            } else if let error = error {
                VStack(alignment: .leading) {
                    Text("Failed to load set details")
                        .font(.headline)
                    Text(error.errorDescription ?? "Unknown error")
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await loadDetails() }
                    }
                }
                .padding()
            } else {
                Text("No details available")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(setNum)
        .task {
            await loadDetails()
        }
        .onChange(of: setNum) { _, _ in
            Task { await loadDetails() }
        }
    }

    @MainActor
    private func loadDetails() async {
        isLoading = true
        error = nil
        do {
            let repo = di.makeLegoSetRepository()
            let fetched = try await repo.getSetDetails(setNum: setNum)
            legoSet = fetched
        } catch {
            if let b = error as? BrixieError {
                self.error = b
            } else {
                self.error = .networkError(underlying: error)
            }
        }
        isLoading = false
    }
}

// Preview
#Preview {
    SetDetailView(setNum: "123-1")
}
