import SwiftUI
import SwiftData
import OSLog

struct SetListView: View {
    @State private var isGrid: Bool = true
    @State private var error: String?
    @State private var prefetchService = ImagePrefetchService.shared
    
    private let logger = Logger(subsystem: "com.brixie", category: "SetListView")
    
    var body: some View {
        VStack {
            HStack {
                Text("LEGO Sets")
                    .font(.title2)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGrid.toggle()
                    }
                }) {
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
            
            // Use PaginatedQuery for better performance
            PaginatedQuery.legoSetsByYear(pageSize: 20) { sets in
                if isGrid {
                    gridView(sets: sets)
                } else {
                    listView(sets: sets)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func gridView(sets: [LegoSet]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    SetCardView(set: set)
                        .id(set.id) // Explicit view identity
                        .onAppear {
                            handleSetAppear(set: set, index: index, allSets: sets)
                        }
                }
            }
            .padding()
        }
        .accessibilityIdentifier("gridView")
    }
    
    private func listView(sets: [LegoSet]) -> some View {
        List {
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                SetCardView(set: set)
                    .id(set.id) // Explicit view identity
                    .listRowBackground(Color.clear) // Reduce overdraw
                    .listRowInsets(EdgeInsets()) // Custom insets
                    .onAppear {
                        handleSetAppear(set: set, index: index, allSets: sets)
                    }
            }
        }
        .listStyle(.plain) // Use plain style for performance
        .accessibilityIdentifier("listView")
    }
    
    /// Handle when a set appears - trigger prefetching for upcoming images
    private func handleSetAppear(set: LegoSet, index: Int, allSets: [LegoSet]) {
        // Trigger image prefetching when we're near the end of loaded items
        let prefetchThreshold = 5
        let upcomingRange = (index + 1)..<min(index + prefetchThreshold + 1, allSets.count)
        let upcomingSets = Array(allSets[upcomingRange])
        
        if !upcomingSets.isEmpty {
            prefetchService.prefetchImages(for: upcomingSets, imageType: .thumbnail)
        }
    }
}

#Preview {
    SetListView()
}
