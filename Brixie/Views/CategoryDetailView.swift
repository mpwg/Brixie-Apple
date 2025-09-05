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
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var themeService: LegoThemeService?
    @State private var sets: [LegoSet] = []
    @State private var searchText = ""
    @State private var sortOrder: SetSortOrder = .year
    @State private var showingFilters = false
    @State private var yearRange: ClosedRange<Int> = 1950...2024
    @State private var minParts: Int = 0
    @State private var maxParts: Int = 10000
    @State private var currentPage = 1
    @State private var hasMorePages = true
    
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
        NavigationView {
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
                            
                            if hasMorePages && !service.isLoading {
                                Button(action: loadMoreSets) {
                                    HStack {
                                        Spacer()
                                        Text(NSLocalizedString("Load More", comment: "Load more button"))
                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                            
                            if service.isLoading && !sets.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .searchable(text: $searchText, prompt: NSLocalizedString("Search sets", comment: "Search prompt"))
                        .refreshable {
                            await loadSets(reset: true)
                        }
                    }
                    
                    if let errorMessage = service.errorMessage {
                        Text(errorMessage)
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
                        Button(action: { showingFilters = true }) {
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
            .onChange(of: yearRange) { _, _ in
                // Filtering is done locally, no need to reload
            }
            .onChange(of: minParts) { _, _ in
                // Filtering is done locally, no need to reload
            }
            .onChange(of: maxParts) { _, _ in
                // Filtering is done locally, no need to reload
            }
        }
        .task {
            await initializeService()
        }
    }
    
    @MainActor
    private func initializeService() async {
        guard themeService == nil else { return }
        
        themeService = LegoThemeService(modelContext: modelContext, apiKey: apiKeyManager.apiKey)
        
        await loadSets(reset: true)
    }
    
    @MainActor
    private func loadSets(reset: Bool = false) async {
        guard let service = themeService else { return }
        
        if reset {
            currentPage = 1
            sets = []
            hasMorePages = true
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
    
    private func loadMoreSets() {
        Task {
            currentPage += 1
            await loadSets()
        }
    }
}


struct FilterSheetView: View {
    @Binding var yearRange: ClosedRange<Int>
    @Binding var minParts: Int
    @Binding var maxParts: Int
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Year Range", comment: "Filter section"))) {
                    VStack {
                        HStack {
                            Text(String(yearRange.lowerBound))
                            Spacer()
                            Text(String(yearRange.upperBound))
                        }
                        .font(.caption)
                        
                        RangeSlider(range: $yearRange, bounds: 1950...2024)
                    }
                }
                
                Section(header: Text(NSLocalizedString("Part Count", comment: "Filter section"))) {
                    HStack {
                        Text(NSLocalizedString("Min:", comment: "Minimum label"))
                        TextField(NSLocalizedString("Minimum", comment: "Minimum placeholder"), value: $minParts, format: .number)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("Max:", comment: "Maximum label"))
                        TextField(NSLocalizedString("Maximum", comment: "Maximum placeholder"), value: $maxParts, format: .number)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Filters", comment: "Filter sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Reset", comment: "Reset button")) {
                        yearRange = 1950...2024
                        minParts = 0
                        maxParts = 10000
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Simple range slider implementation
struct RangeSlider: View {
    @Binding var range: ClosedRange<Int>
    let bounds: ClosedRange<Int>
    
    var body: some View {
        GeometryReader { geometry in
            let totalRange = bounds.upperBound - bounds.lowerBound
            let lowerPercent = Double(range.lowerBound - bounds.lowerBound) / Double(totalRange)
            let upperPercent = Double(range.upperBound - bounds.lowerBound) / Double(totalRange)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * (upperPercent - lowerPercent))
                    .offset(x: geometry.size.width * lowerPercent)
                    .frame(height: 4)
            }
        }
        .frame(height: 20)
    }
}

#Preview {
    CategoryDetailView(theme: LegoTheme(id: 1, name: "City", setCount: 150))
        .modelContainer(for: [LegoTheme.self, LegoSet.self], inMemory: true)
}