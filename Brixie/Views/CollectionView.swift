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
    @State private var viewModel = CollectionViewModel()
    
    // Query LegoSets that have a related UserCollection with isOwned == true
    @Query private var ownedSets: [LegoSet]

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
                            Button(action: { viewModel.showStatistics() }) {
                                Label("Statistics", systemImage: "chart.bar")
                            }
                            
                            Button(action: { viewModel.showExport() }) {
                                Label("Export Collection", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingStats) {
                CollectionStatisticsView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showingExportSheet) {
                CollectionExportView(sets: viewModel.filterSets(ownedSets))
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
        return viewModel.filterSets(ownedSets)
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
    @State private var viewModel = CollectionViewModel()
    
    var body: some View {
        let stats = viewModel.getCollectionStats(from: modelContext)
        
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

#Preview {
    CollectionView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}
