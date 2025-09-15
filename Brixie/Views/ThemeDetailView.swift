import SwiftData
import SwiftUI

struct ThemeDetailView: View {
    @Environment(\.diContainer) private var di: DIContainer
    @StateObject private var viewModel: ThemeDetailViewModel
    private let theme: LegoTheme

    // Accept a DIContainer for easier injection and previews. The caller can
    // pass `di` from the environment when building the view, or omit it and
    // the default will use the environment-provided container.
    init(theme: LegoTheme, di: DIContainer? = nil) {
        self.theme = theme
        let container: DIContainer
        if let di = di {
            container = di
        } else {
            // Fallback to the shared instance on the MainActor for compatibility.
            container = MainActor.assumeIsolated { DIContainer.shared }
        }
        _viewModel = StateObject(
            wrappedValue: ThemeDetailViewModel(di: container, themeId: theme.id))
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(theme.name)
                .font(.largeTitle)
                .padding(.horizontal)

            List {
                ForEach(viewModel.sets, id: \.setNum) { set in
                    NavigationLink {
                        SetDetailView(setNum: set.setNum)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(set.name)
                                .font(.headline)
                            Text(set.setNum)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .task {
                        await viewModel.loadMoreIfNeeded(currentItem: set)
                    }
                }

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }

                if let error = viewModel.error {
                    VStack(alignment: .leading) {
                        Text("Failed to load sets")
                            .font(.headline)
                        Text(error.errorDescription ?? "Unknown error")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.plain)
            .task {
                // On initial appearance we want to load the initial page for
                // the provided theme id in the view model. The view model may
                // already have sets (if reusing the view), so prefer loadInitial.
                await viewModel.loadInitial()
            }
            .onChange(of: theme.id) { _, newId in
                Task { await viewModel.updateForTheme(newId) }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    let t = LegoTheme(id: 1, name: "Preview", parentId: nil, setCount: 10)
    ThemeDetailView(theme: t)
}
