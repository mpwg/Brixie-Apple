import SwiftUI
import SwiftData

struct SetListView: View {
    @Query(sort: \LegoSet.setNumber) var sets: [LegoSet]
    @State private var isGrid: Bool = true
    @State private var currentPage: Int = 1
    @State private var isRefreshing: Bool = false
    @State private var error: String?
    
    private let pageSize = 20
    
    var body: some View {
        VStack {
            HStack {
                Text("LEGO Sets")
                    .font(.title2)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: { isGrid.toggle() }) {
                    Image(systemName: isGrid ? "square.grid.2x2" : "list.bullet")
                        .accessibilityLabel(isGrid ? "Switch to list view" : "Switch to grid view")
                }
                .accessibilityIdentifier("toggleViewButton")
            }
            .padding(.horizontal)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("errorText")
            }
            
            if isGrid {
                gridView
            } else {
                listView
            }
            
            if isRefreshing {
                ProgressView("Refreshing...")
                    .accessibilityIdentifier("refreshProgress")
            }
            
            Button("Load More") {
                currentPage += 1
            }
            .disabled(sets.count < currentPage * pageSize)
            .accessibilityIdentifier("loadMoreButton")
        }
        .refreshable {
            isRefreshing = true
            // Simulate refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isRefreshing = false
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))]) {
            ForEach(paginatedSets) { set in
                SetCardView(set: set)
            }
        }
        .padding()
        .accessibilityIdentifier("gridView")
    }
    
    private var listView: some View {
        List(paginatedSets) { set in
            SetCardView(set: set)
        }
        .accessibilityIdentifier("listView")
    }
    
    private var paginatedSets: [LegoSet] {
        Array(sets.prefix(currentPage * pageSize))
    }
}

#Preview {
    SetListView()
}
