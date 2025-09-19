//
//  CollectionView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    private let collectionService = CollectionService.shared
    
    // Query LegoSets that have a related UserCollection with isOwned == true
    @Query private var ownedSets: [LegoSet]
    
    @State private var selectedSortOption: SortOption = .dateAdded
    @State private var showingStats = false
    @State private var showingExportSheet = false
    @State private var searchText = ""

    init() {
        _ownedSets = Query(filter: #Predicate<LegoSet> { set in
            set.userCollection?.isOwned == true
        }, sort: \LegoSet.name)
    }

    var body: some View {
        NavigationStack {
            VStack {
                if ownedSets.isEmpty {
                    ContentUnavailableView(
                        "No sets in your collection",
                        systemImage: "heart",
                        description: Text("Mark sets as owned to see them here.")
                    )
                } else {
                    collectionContent
                }
            }
            .navigationTitle("My Collection")
            .searchable(text: $searchText, prompt: "Search collection...")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Sort By") {
                            Picker("Sort", selection: $selectedSortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Label(option.title, systemImage: option.icon)
                                        .tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Section("Actions") {
                            Button(action: { showingStats = true }) {
                                Label("Statistics", systemImage: "chart.bar")
                            }
                            
                            Button(action: { showingExportSheet = true }) {
                                Label("Export Collection", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingStats) {
                CollectionStatisticsView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingExportSheet) {
                CollectionExportView(sets: filteredSets)
            }
        }
    }
    
    private var collectionContent: some View {
        List {
            // Quick stats section
            Section {
                CollectionSummaryCardView()
            }
            
            // Collection groups
            ForEach(groupedSets.keys.sorted(), id: \.self) { groupName in
                Section(header: Text(groupName)) {
                    ForEach(groupedSets[groupName] ?? []) { set in
                        NavigationLink(destination: SetDetailView(set: set)) {
                            CollectionSetRowView(set: set)
                        }
                    }
                }
            }
        }
    }
    
    private var filteredSets: [LegoSet] {
        let filtered = searchText.isEmpty ? ownedSets : ownedSets.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.setNumber.contains(searchText)
        }
        
        return filtered.sorted { lhs, rhs in
            switch selectedSortOption {
            case .name:
                return lhs.name < rhs.name
            case .year:
                return lhs.year > rhs.year
            case .parts:
                return lhs.numParts > rhs.numParts
            case .dateAdded:
                return (lhs.userCollection?.dateAdded ?? Date()) > (rhs.userCollection?.dateAdded ?? Date())
            case .value:
                return (lhs.retailPrice ?? 0) > (rhs.retailPrice ?? 0)
            }
        }
    }
    
    private var groupedSets: [String: [LegoSet]] {
        return Dictionary(grouping: filteredSets) { set in
            set.theme?.name ?? "Unknown Theme"
        }
    }
}

// MARK: - Supporting Views

private struct CollectionSummaryCardView: View {
    @Environment(\.modelContext) private var modelContext
    private let collectionService = CollectionService.shared
    
    var body: some View {
        let stats = collectionService.getCollectionStats(from: modelContext)
        
        HStack(spacing: 20) {
            VStack {
                Text("\(stats.ownedSetsCount)")
                    .font(.title2)
                    .bold()
                Text("Sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack {
                Text("\(stats.totalParts)")
                    .font(.title2)
                    .bold()
                Text("Parts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack {
                Text(formatPrice(stats.totalRetailValue))
                    .font(.title2)
                    .bold()
                Text("Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if stats.missingPartsCount > 0 {
                VStack {
                    Text("\(stats.missingPartsCount)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.orange)
                    Text("Missing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$0"
    }
}

private struct CollectionSetRowView: View {
    let set: LegoSet
    
    var body: some View {
        HStack {
            AsyncCachedImage(url: URL(string: set.primaryImageURL ?? ""))
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(set.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("#\(set.setNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text("\(set.year)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\(set.numParts) parts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let collection = set.userCollection {
                    if collection.isSealedBox {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    
                    if collection.hasMissingParts {
                        Label("\(collection.missingPartsCount)", systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .labelStyle(.iconOnly)
                    }
                    
                    if let condition = collection.condition {
                        Text("\(condition)★")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let price = set.formattedPrice {
                    Text(price)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Sort Options

private enum SortOption: CaseIterable {
    case name
    case year
    case parts
    case dateAdded
    case value
    
    var title: String {
        switch self {
        case .name: return "Name"
        case .year: return "Year"
        case .parts: return "Parts"
        case .dateAdded: return "Date Added"
        case .value: return "Value"
        }
    }
    
    var icon: String {
        switch self {
        case .name: return "textformat"
        case .year: return "calendar"
        case .parts: return "cube.box"
        case .dateAdded: return "clock"
        case .value: return "dollarsign.circle"
        }
    }
}

#Preview {
    CollectionView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
