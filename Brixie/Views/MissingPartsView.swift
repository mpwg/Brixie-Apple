//
//  MissingPartsView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData

struct MissingPartsView: View {
    let userCollection: UserCollection
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddPart = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if userCollection.missingParts.isEmpty {
                    ContentUnavailableView(
                        "No missing parts tracked",
                        systemImage: "checkmark.circle",
                        description: Text("This set appears to be complete!")
                    )
                } else {
                    partsContent
                }
            }
            .navigationTitle("Missing Parts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search parts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Part") {
                        showingAddPart = true
                    }
                }
            }
            .sheet(isPresented: $showingAddPart) {
                AddMissingPartView(userCollection: userCollection)
            }
        }
    }
    
    private var partsContent: some View {
        List {
            // Summary section
            Section {
                MissingPartsSummaryView(userCollection: userCollection)
            }
            
            // Missing parts list
            Section("Missing Parts") {
                ForEach(filteredParts, id: \.id) { part in
                    MissingPartRowView(part: part)
                        .swipeActions(edge: .leading) {
                            if !part.isOrdered {
                                Button("Mark Ordered") {
                                    part.markAsOrdered()
                                    try? modelContext.save()
                                }
                                .tint(.green)
                            } else {
                                Button("Mark Missing") {
                                    part.markAsMissing()
                                    try? modelContext.save()
                                }
                                .tint(.orange)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete") {
                                deletePart(part)
                            }
                            .tint(.red)
                        }
                }
            }
        }
    }
    
    private var filteredParts: [MissingPart] {
        if searchText.isEmpty {
            return userCollection.missingParts.sorted { $0.dateMissing > $1.dateMissing }
        } else {
            return userCollection.missingParts.filter {
                $0.partNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.partName?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.colorName?.localizedCaseInsensitiveContains(searchText) == true
            }.sorted { $0.dateMissing > $1.dateMissing }
        }
    }
    
    private func deletePart(_ part: MissingPart) {
        userCollection.removeMissingPart(part)
        modelContext.delete(part)
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

private struct MissingPartsSummaryView: View {
    let userCollection: UserCollection
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack {
                    Text("\(userCollection.missingPartsCount)")
                        .font(.title2)
                        .bold()
                    Text("Missing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(userCollection.orderedPartsCount)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.green)
                    Text("Ordered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(Int(userCollection.completionPercentage))%")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.blue)
                    Text("Complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let totalCost = userCollection.totalReplacementCost {
                Text("Total replacement cost: \(totalCost, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct MissingPartRowView: View {
    let part: MissingPart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(part.partDescription)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if part.quantity > 1 {
                        Text("Quantity: \(part.quantity)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    StatusBadge(isOrdered: part.isOrdered)
                    
                    if let price = part.formattedReplacementPrice {
                        Text(price)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            HStack {
                Text("Missing \(part.timeSinceMissing)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let orderDate = part.dateOrdered {
                    Text("• Ordered \(orderDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if let source = part.orderSource {
                    Text("• \(source)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if let notes = part.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct StatusBadge: View {
    let isOrdered: Bool
    
    var body: some View {
        Label(isOrdered ? "Ordered" : "Missing", systemImage: isOrdered ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(isOrdered ? .green : .orange)
            .labelStyle(.iconOnly)
    }
}

// MARK: - Add Missing Part View

private struct AddMissingPartView: View {
    let userCollection: UserCollection
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var partNumber = ""
    @State private var partName = ""
    @State private var colorName = ""
    @State private var quantity = 1
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Part Information") {
                    TextField("Part Number", text: $partNumber)
                        .textContentType(.none)
                    
                    TextField("Part Name (optional)", text: $partName)
                        .textContentType(.none)
                    
                    TextField("Color (optional)", text: $colorName)
                        .textContentType(.none)
                }
                
                Section("Details") {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Add Missing Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addPart()
                    }
                    .disabled(partNumber.isEmpty)
                }
            }
        }
    }
    
    private func addPart() {
        let part = MissingPart(
            partNumber: partNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            partName: partName.isEmpty ? nil : partName.trimmingCharacters(in: .whitespacesAndNewlines),
            colorName: colorName.isEmpty ? nil : colorName.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        userCollection.addMissingPart(part)
        modelContext.insert(part)
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: LegoSet.self, Theme.self, UserCollection.self, MissingPart.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    let collection = UserCollection(isOwned: true)
    container.mainContext.insert(collection)
    
    return MissingPartsView(userCollection: collection)
        .modelContainer(container)
}