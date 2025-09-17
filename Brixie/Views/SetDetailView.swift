import SwiftData
import SwiftUI

struct SetDetailView: View {
    @Environment(\.diContainer) private var di: DIContainer
    @State private var viewModel: SetDetailViewModel

    init(setNum: String, di: DIContainer? = nil) {
        let container = di ?? MainActor.assumeIsolated { DIContainer.shared }
        let repository = container.makeLegoSetRepository()
        self._viewModel = State(
            initialValue: SetDetailViewModel(repository: repository, setNum: setNum))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let legoSet = viewModel.legoSet {
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
            } else {
                Text("No details available")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(viewModel.legoSet?.setNum ?? "Set Details")
        .task {
            await viewModel.loadDetails()
        }
        // Unified error handling overlay
        .errorHandling(
            error: viewModel.error,
            onDismiss: { viewModel.error = nil },
            onRetry: { Task { await viewModel.retry() } },
            style: .banner
        )
    }
}

// Preview
#Preview {
    SetDetailView(setNum: "123-1")
}
