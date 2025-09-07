//
//  CategoryDetailView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let theme: LegoTheme
    
    @Environment(\.modelContext)
    private var modelContext
    @Environment(DIContainer.self)
    private var diContainer
    @State private var themeService: LegoThemeService?
    @State private var sets: [LegoSet] = []
    @State private var searchText = ""
    @State private var sortOrder: SetSortOrder = .year
    @State private var showingFilters = false
    @State private var yearRange: ClosedRange<Int> = 1_950...2_024
    @State private var minParts: Int = 0
    @State private var maxParts: Int = 10_000
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var isLoadingMore = false
    @State private var loadMoreTask: Task<Void, Never>?
    @State private var lastLoadMoreTime: Date = .distantPast
    
    private var apiConfigurationService: APIConfigurationService {
        diContainer.apiConfigurationService
    }
    
    enum SetSortOrder: String, CaseIterable {
        case year = "-year"
        case yearAsc = "year"
        case name = "name"
        case nameDesc = "-name"
        case numParts = "-num_parts"
        case numPartsAsc = "num_parts"
        
        var displayName: String {
            switch self {
            case .year: return NSLocalizedString("Year (newest first)", comment: "Sort option")
            case .yearAsc: return NSLocalizedString("Year (oldest first)", comment: "Sort option")
            case .name: return NSLocalizedString("Name (A-Z)", comment: "Sort option")
            case .nameDesc: return NSLocalizedString("Name (Z-A)", comment: "Sort option")
            case .numParts: return NSLocalizedString("Parts (most first)", comment: "Sort option")
            case .numPartsAsc: return NSLocalizedString("Parts (least first)", comment: "Sort option")
            }
        }
    }
    
    var filteredSets: [LegoSet] {
        var filtered = sets
        
        if !searchText.isEmpty {
            filtered = filtered.filter { set in
                set.name.localizedCaseInsensitiveContains(searchText) ||
                set.setNum.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filtered = filtered.filter { set in
            yearRange.contains(set.year) &&
            set.numParts >= minParts &&
            set.numParts <= maxParts
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let service = themeService {
                    if service.isLoading && sets.isEmpty {
                        ProgressView(NSLocalizedString("Loading sets...", comment: "Loading message"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredSets, id: \.setNum) { set in
                                NavigationLink(destination: SetDetailView(set: set)) {
                                    SetRowView(set: set)
                                }
                            }
                            
                            if hasMorePages && !service.isLoading && !isLoadingMore {
                                Button(action: loadMoreSets) {
                                    HStack {
                                        Spacer()
                                        Text(NSLocalizedString("Load More", comment: "Load more button"))
                                        Spacer()
                                    }
                                    .padding()
                                }
                                .disabled(isLoadingMore)
                            }
                            
                            if service.isLoading && !sets.isEmpty || isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .searchable(
                            text: $searchText,
                            prompt: NSLocalizedString("Search sets", comment: "Search prompt")
                        )
                        .refreshable {
                            await loadSets(reset: true)
                        }
                    }
                    
                    if let error = service.error {
                        Text(
                            error.errorDescription ?? NSLocalizedString(
                                "Unknown error occurred",
                                comment: "Generic error message"
                            )
                        )
                            .foregroundColor(.red)
                            .padding()
                    }
                } else {
                    ProgressView(NSLocalizedString("Initializing...", comment: "Initialization message"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(theme.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        
                        Menu {
                            Picker(NSLocalizedString("Sort by", comment: "Sort picker label"), selection: $sortOrder) {
                                ForEach(SetSortOrder.allCases, id: \.self) { order in
                                    Text(order.displayName).tag(order)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheetView(
                    yearRange: $yearRange,
                    minParts: $minParts,
                    maxParts: $maxParts
                )
            }
            .onChange(of: sortOrder) { _, _ in
                Task {
                    await loadSets(reset: true)
                }
            }
        }
        .task {
            if apiConfigurationService.hasValidAPIKey {
                await initializeService()
            }
        }
    }
    
    @MainActor
    private func initializeService() async {
        guard themeService == nil else { return }
        
        themeService = LegoThemeService(modelContext: modelContext, apiKey: apiConfigurationService.currentAPIKey ?? "")
        
        await loadSets(reset: true)
    }
    
    @MainActor
    private func loadSets(reset: Bool = false) async {
        guard let service = themeService else { return }
        
        if reset {
            // Cancel any existing loadMore task when resetting
            loadMoreTask?.cancel()
            currentPage = 1
            sets = []
            hasMorePages = true
            isLoadingMore = false
        }
        
        do {
            let fetchedSets = try await service.getSetsForTheme(
                themeId: theme.id,
                page: currentPage,
                pageSize: 20,
                ordering: sortOrder.rawValue
            )
            
            if reset {
                sets = fetchedSets
            } else {
                sets.append(contentsOf: fetchedSets)
            }
            
            hasMorePages = fetchedSets.count == 20
        } catch {
            // Handle error silently, keeping existing sets
        }
    }
    
    /// Loads more sets with multiple protection mechanisms against duplicate requests:
    /// - 500ms debouncing to prevent rapid button taps
    /// - Task cancellation for concurrent request management  
    /// - Guard logic to prevent overlapping operations
    /// - Proper page rollback on cancellation
    private func loadMoreSets() {
        // Debounce: prevent requests more frequent than 500ms
        let now = Date()
        guard now.timeIntervalSince(lastLoadMoreTime) > 0.5 else { return }
        lastLoadMoreTime = now
        
        // Cancel any existing load more task
        loadMoreTask?.cancel()
        
        // Guard against multiple simultaneous requests
        guard !isLoadingMore, let service = themeService, !service.isLoading else { return }
        
        loadMoreTask = Task { @MainActor in
            isLoadingMore = true
            defer { 
                isLoadingMore = false
                loadMoreTask = nil
            }
            
            currentPage += 1
            
            // Check if cancelled before starting network request
            guard !Task.isCancelled else { 
                currentPage -= 1 // Reset page if cancelled
                return 
            }
            
            await loadSets()
        }
    }
}

struct FilterSheetView: View {
    @Binding var yearRange: ClosedRange<Int>
    @Binding var minParts: Int
    @Binding var maxParts: Int
    
    @Environment(\.dismiss)
    private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text(NSLocalizedString("Year Range", comment: "Filter section"))
                ) {
                    VStack {
                        HStack {
                            Text(String(yearRange.lowerBound))
                            Spacer()
                            Text(String(yearRange.upperBound))
                        }
                        .font(.caption)
                        
                        RangeSlider(range: $yearRange, bounds: 1_950...2_024)
                    }
                }
                
                Section(
                    header: Text(NSLocalizedString("Part Count", comment: "Filter section"))
                ) {
                    HStack {
                        Text(NSLocalizedString("Min:", comment: "Minimum label"))
                        TextField(
                            NSLocalizedString("Minimum", comment: "Minimum placeholder"),
                            value: $minParts,
                            format: .number
                        )
                            .keyboardType(.numberPad)
                            .brixieAccessibility(
                                label: NSLocalizedString("Minimum parts", comment: "Minimum parts text field accessibility"),
                                hint: NSLocalizedString("Enter the minimum number of parts for filtering", comment: "Minimum parts hint")
                            )
                    }
                    
                    HStack {
                        Text(NSLocalizedString("Max:", comment: "Maximum label"))
                        TextField(
                            NSLocalizedString("Maximum", comment: "Maximum placeholder"),
                            value: $maxParts,
                            format: .number
                        )
                            .keyboardType(.numberPad)
                            .brixieAccessibility(
                                label: NSLocalizedString("Maximum parts", comment: "Maximum parts text field accessibility"),
                                hint: NSLocalizedString("Enter the maximum number of parts for filtering", comment: "Maximum parts hint")
                            )
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Filters", comment: "Filter sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Reset", comment: "Reset button")) {
                        yearRange = 1_950...2_024
                        minParts = 0
                        maxParts = 10_000
                    }
                    .brixieAccessibility(
                        label: NSLocalizedString("Reset filters", comment: "Reset button accessibility"),
                        hint: NSLocalizedString("Resets all filter values to defaults", comment: "Reset button hint"),
                        traits: .isButton
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                    .brixieAccessibility(
                        label: NSLocalizedString("Done", comment: "Done button accessibility"),
                        hint: NSLocalizedString("Apply filters and close", comment: "Done button hint"),
                        traits: .isButton
                    )
                }
            }
        }
    }
}

// Simple range slider implementation
struct RangeSlider: View {
    @Binding var range: ClosedRange<Int>
    let bounds: ClosedRange<Int>
    
    @State private var isDraggingLower = false
    @State private var isDraggingUpper = false
    
    var body: some View {
        GeometryReader { geometry in
            let totalRange = bounds.upperBound - bounds.lowerBound
            let lowerPercent = Double(range.lowerBound - bounds.lowerBound) / Double(totalRange)
            let upperPercent = Double(range.upperBound - bounds.lowerBound) / Double(totalRange)
            let sliderHeight: CGFloat = 4
            let handleDiameter: CGFloat = 24
            
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: sliderHeight)
                
                // Selected range
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(upperPercent - lowerPercent))
                    .offset(x: geometry.size.width * CGFloat(lowerPercent))
                    .frame(height: sliderHeight)
                
                // Lower handle
                Circle()
                    .fill(isDraggingLower ? Color.blue : Color.white)
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    .frame(width: handleDiameter, height: handleDiameter)
                    .offset(x: geometry.size.width * CGFloat(lowerPercent) - handleDiameter / 2)
                    .brixieAccessibility(
                        label: String(format: NSLocalizedString("Minimum year %d", comment: "Range slider minimum"), range.lowerBound),
                        hint: NSLocalizedString("Drag to adjust minimum year", comment: "Range slider minimum hint"),
                        traits: .adjustable
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingLower = true
                                let x = min(max(0, value.location.x), geometry.size.width)
                                let percent = x / geometry.size.width
                                let newLower = Int(round(percent * Double(totalRange))) + bounds.lowerBound
                                range = max(bounds.lowerBound, min(newLower, range.upperBound - 1))...range.upperBound
                            }
                            .onEnded { _ in
                                isDraggingLower = false
                            }
                    )
                
                // Upper handle
                Circle()
                    .fill(isDraggingUpper ? Color.blue : Color.white)
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    .frame(width: handleDiameter, height: handleDiameter)
                    .offset(x: geometry.size.width * CGFloat(upperPercent) - handleDiameter / 2)
                    .brixieAccessibility(
                        label: String(format: NSLocalizedString("Maximum year %d", comment: "Range slider maximum"), range.upperBound),
                        hint: NSLocalizedString("Drag to adjust maximum year", comment: "Range slider maximum hint"),
                        traits: .adjustable
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingUpper = true
                                let x = min(max(0, value.location.x), geometry.size.width)
                                let percent = x / geometry.size.width
                                let newUpper = Int(round(percent * Double(totalRange))) + bounds.lowerBound
                                range = range.lowerBound...min(bounds.upperBound, max(newUpper, range.lowerBound + 1))
                            }
                            .onEnded { _ in
                                isDraggingUpper = false
                            }
                    )
            }
        }
        .frame(height: 32)
        .brixieAccessibility(
            label: String(format: NSLocalizedString("Year range slider, from %d to %d", comment: "Range slider accessibility"), range.lowerBound, range.upperBound),
            hint: NSLocalizedString("Use the handles to adjust the year range for filtering", comment: "Range slider hint"),
            traits: .adjustable
        )
    }
}

#Preview {
    CategoryDetailView(theme: LegoTheme(id: 1, name: "City", setCount: 150))
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
