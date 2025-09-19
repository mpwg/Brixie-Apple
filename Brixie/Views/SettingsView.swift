//
//  SettingsView.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiConfig = APIConfiguration()
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var validationResult: Bool?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Rebrickable API Key", text: $apiKey)
                        .textContentType(.password)
                        .onAppear { apiKey = apiConfig.currentAPIKey ?? "" }
                        .accessibilityLabel("Rebrickable API Key")

                    if isValidating {
                        HStack { ProgressView().scaleEffect(AppConstants.Scale.small); Text("Validating...").foregroundColor(.secondary) }
                    } else if let isValid = validationResult {
                        Label(
                            isValid ? "Valid API Key" : "Invalid API Key",
                            systemImage: isValid ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(isValid ? .green : .red)
                        .accessibilityLabel(isValid ? "API key is valid" : "API key is invalid")
                    }
                } header: { Text("API Configuration") } footer: { Text("Get your API key from rebrickable.com/api/") }

                Section {
                    Button("Save & Validate") { saveAndValidateAPIKey() }
                        .disabled(apiKey.isEmpty || isValidating)
                    Button("Clear Key", role: .destructive) {
                        apiConfig.clearAPIKey(); apiKey = ""; validationResult = nil
                    }.disabled(apiKey.isEmpty)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func saveAndValidateAPIKey() {
        isValidating = true
        apiConfig.updateAPIKey(apiKey)
        Task {
            let isValid = await apiConfig.validateAPIKey()
            await MainActor.run { isValidating = false; validationResult = isValid }
        }
    }
}

#Preview { SettingsView() }
