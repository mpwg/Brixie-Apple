//
//  CollectionExportView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct CollectionExportView: View {
    let sets: [LegoSet]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var includeImages = false
    @State private var includePricing = true
    @State private var includeCondition = true
    @State private var includeNotes = true
    @State private var isExporting = false
    @State private var exportedDocument: ExportDocument?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Label(format.title, systemImage: format.icon)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Export Options") {
                    Toggle("Include pricing information", isOn: $includePricing)
                    Toggle("Include condition ratings", isOn: $includeCondition)
                    Toggle("Include personal notes", isOn: $includeNotes)
                    
                    if selectedFormat == .csv {
                        Toggle("Include image URLs", isOn: $includeImages)
                    }
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your export will include:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("\(sets.count) sets", systemImage: "cube.box")
                            Label("Set details (name, number, year, parts)", systemImage: "info.circle")
                            
                            if includePricing {
                                Label("Pricing information", systemImage: "dollarsign.circle")
                            }
                            if includeCondition {
                                Label("Condition ratings", systemImage: "star")
                            }
                            if includeNotes {
                                Label("Personal notes", systemImage: "note.text")
                            }
                            if includeImages && selectedFormat == .csv {
                                Label("Image URLs", systemImage: "photo")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Export Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportCollection()
                    }
                    .disabled(isExporting)
                }
            }
            .fileExporter(
                isPresented: Binding(
                    get: { exportedDocument != nil },
                    set: { if !$0 { exportedDocument = nil } }
                ),
                document: exportedDocument,
                contentType: selectedFormat.contentType,
                defaultFilename: "brixie-collection.\(selectedFormat.fileExtension)"
            ) { result in
                switch result {
                case .success:
                    dismiss()
                case .failure(_):
                    // Error handling should be done by ViewModel, not view
                    // Remove logging from view - this should be handled by a proper ViewModel
                    break
                }
            }
        }
    }
    
    private func exportCollection() {
        isExporting = true
        
        Task {
            let content: String
            
            switch selectedFormat {
            case .csv:
                content = generateCSV()
            case .json:
                content = generateJSON()
            case .text:
                content = generateText()
            }
            
            await MainActor.run {
                exportedDocument = ExportDocument(content: content)
                isExporting = false
            }
        }
    }
    
    private func generateCSV() -> String {
        var headers = ["Set Number", "Name", "Year", "Parts", "Theme"]
        
        if includePricing {
            headers.append(contentsOf: ["Retail Price", "Purchase Price", "Purchase Date"])
        }
        if includeCondition {
            headers.append("Condition")
        }
        if includeNotes {
            headers.append("Notes")
        }
        if includeImages {
            headers.append("Image URL")
        }
        
        var rows = [headers.joined(separator: ",")]
        
        for set in sets {
            var row = [
                escapeCsv(set.setNumber),
                escapeCsv(set.name),
                "\(set.year)",
                "\(set.numParts)",
                escapeCsv(set.theme?.name ?? "")
            ]
            
            if includePricing {
                row.append(set.formattedPrice ?? "")
                row.append(set.userCollection?.formattedPurchasePrice ?? "")
                row.append(set.userCollection?.dateAcquired?.formatted(.dateTime.day().month().year()) ?? "")
            }
            
            if includeCondition {
                row.append(set.userCollection?.conditionStars ?? "")
            }
            
            if includeNotes {
                row.append(escapeCsv(set.userCollection?.notes ?? ""))
            }
            
            if includeImages {
                row.append(set.primaryImageURL ?? "")
            }
            
            rows.append(row.joined(separator: ","))
        }
        
        return rows.joined(separator: "\n")
    }
    
    private func generateJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let exportSets = sets.map { set in
            ExportSet(
                setNumber: set.setNumber,
                name: set.name,
                year: set.year,
                numParts: set.numParts,
                theme: set.theme?.name,
                retailPrice: includePricing ? set.retailPrice : nil,
                purchasePrice: includePricing ? set.userCollection?.purchasePrice : nil,
                purchaseDate: includePricing ? set.userCollection?.dateAcquired : nil,
                condition: includeCondition ? set.userCollection?.condition : nil,
                notes: includeNotes ? set.userCollection?.notes : nil,
                imageURL: includeImages ? set.primaryImageURL : nil
            )
        }
        
        let exportData = CollectionExportData(
            exportDate: Date(),
            totalSets: sets.count,
            sets: exportSets
        )
        
        guard let data = try? encoder.encode(exportData),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "Export failed"
        }
        
        return jsonString
    }
    
    private func generateText() -> String {
        var lines = [
            "LEGO Collection Export",
            "Generated: \(Date().formatted())",
            "Total Sets: \(sets.count)",
            "",
            String(repeating: "=", count: 50),
            ""
        ]
        
        for set in sets {
            lines.append("Set #\(set.setNumber): \(set.name)")
            lines.append("Year: \(set.year) | Parts: \(set.numParts)")
            
            if let theme = set.theme?.name {
                lines.append("Theme: \(theme)")
            }
            
            if includePricing, let price = set.formattedPrice {
                lines.append("Retail Price: \(price)")
            }
            
            if includePricing, let purchasePrice = set.userCollection?.formattedPurchasePrice {
                lines.append("Purchase Price: \(purchasePrice)")
            }
            
            if includeCondition, set.userCollection?.condition != nil {
                lines.append("Condition: \(set.userCollection?.conditionStars ?? "")")
            }
            
            if includeNotes, let notes = set.userCollection?.notes, !notes.isEmpty {
                lines.append("Notes: \(notes)")
            }
            
            lines.append("")
            lines.append(String(repeating: "-", count: 30))
            lines.append("")
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func escapeCsv(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
}

// MARK: - Export Models

private struct ExportSet: Codable {
    let setNumber: String
    let name: String
    let year: Int
    let numParts: Int
    let theme: String?
    let retailPrice: Decimal?
    let purchasePrice: Decimal?
    let purchaseDate: Date?
    let condition: Int?
    let notes: String?
    let imageURL: String?
}

private struct CollectionExportData: Codable {
    let exportDate: Date
    let totalSets: Int
    let sets: [ExportSet]
}

private enum ExportFormat: CaseIterable {
    case csv
    case json
    case text
    
    var title: String {
        switch self {
        case .csv: return "CSV (Spreadsheet)"
        case .json: return "JSON (Structured Data)"
        case .text: return "Plain Text"
        }
    }
    
    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .text: return "doc.text"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .text: return "txt"
        }
    }
    
    var contentType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        case .text: return .plainText
        }
    }
}

private struct ExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = []
    let content: String
    
    init(content: String) {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        content = ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: content.data(using: .utf8) ?? Data())
    }
}

#Preview {
    CollectionExportView(sets: [])
}
