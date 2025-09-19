//
//  ManualBarcodeEntryView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

struct ManualBarcodeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var barcodeText = ""
    let onBarcodeEntered: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Enter barcode", text: $barcodeText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Manual Barcode Entry")
                } footer: {
                    Text("Enter the barcode numbers manually if the scanner cannot read it.")
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let trimmed = barcodeText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onBarcodeEntered(trimmed)
                        }
                    }
                    .disabled(barcodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ManualBarcodeEntryView { barcode in
        print("Entered barcode: \(barcode)")
    }
}