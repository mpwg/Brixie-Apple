//
//  APIKeySettingsSheet.swift
//  Brixie
//
//  Created by Copilot on 06.09.25.
//

import SwiftUI

struct APIKeySettingsSheet: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.colorScheme)
    private var colorScheme
    
    private let apiConfigurationService: APIConfigurationService
    @State private var apiKeyInput: String = ""
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    
    init(apiConfigurationService: APIConfigurationService) {
        self.apiConfigurationService = apiConfigurationService
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        statusSection
                        configurationSection
                        helpSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("API Key Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKeyInput.isEmpty || !apiConfigurationService.isValidAPIKeyFormat(apiKeyInput))
                }
            }
        }
        .onAppear {
            apiKeyInput = apiConfigurationService.userApiKey
        }
        .alert("Invalid API Key", isPresented: $showingValidationError) {
            Button("OK") { }
        } message: {
            Text(validationErrorMessage)
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Status")
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText)
            
            BrixieCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                apiConfigurationService.hasValidAPIKey ?
                                Color.green.opacity(0.1) : Color.orange.opacity(0.1)
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(
                            systemName: apiConfigurationService.hasValidAPIKey ?
                                "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(apiConfigurationService.hasValidAPIKey ? Color.green : Color.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(apiConfigurationService.hasValidAPIKey ? "API Key Configured" : "No API Key")
                            .font(.brixieSubhead)
                            .foregroundStyle(Color.brixieText)
                        
                        Text(apiConfigurationService.configurationStatus)
                            .font(.brixieCaption)
                            .foregroundStyle(Color.brixieTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
        }
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configure API Key")
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rebrickable API Key")
                            .font(.brixieSubhead)
                            .foregroundStyle(Color.brixieText)
                        
                        TextField("Enter your API key here", text: $apiKeyInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    if !apiKeyInput.isEmpty && !apiConfigurationService.isValidAPIKeyFormat(apiKeyInput) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Invalid API key format. Must be 32+ characters.")
                                .font(.brixieCaption)
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                    }
                    
                    if apiConfigurationService.hasUserOverride {
                        Button("Reset to Embedded Key") {
                            apiConfigurationService.clearUserOverride()
                            apiKeyInput = ""
                        }
                        .buttonStyle(BrixieButtonStyle(variant: .ghost))
                    }
                }
                .padding(20)
            }
        }
    }
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help")
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to get your API key:")
                            .font(.brixieSubhead)
                            .foregroundStyle(Color.brixieText)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Visit rebrickable.com/api/")
                            Text("2. Create a free account")
                            Text("3. Generate your API key")
                            Text("4. Copy and paste it above")
                        }
                        .font(.brixieBody)
                        .foregroundStyle(Color.brixieTextSecondary)
                    }
                    
                    Link(destination: URL(string: "https://rebrickable.com/api/")!) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.brixieAccent)
                            
                            Text("Open Rebrickable API")
                                .font(.brixieBody)
                                .foregroundStyle(Color.brixieAccent)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.brixieAccent.opacity(0.6))
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            validationErrorMessage = "API key cannot be empty."
            showingValidationError = true
            return
        }
        
        guard apiConfigurationService.isValidAPIKeyFormat(trimmedKey) else {
            validationErrorMessage = "Invalid API key format. Please check your key and try again."
            showingValidationError = true
            return
        }
        
        apiConfigurationService.userApiKey = trimmedKey
        dismiss()
    }
}

#Preview {
    APIKeySettingsSheet(apiConfigurationService: APIConfigurationService())
}
