//
//  SettingsView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var showingAPIKeyAlert = false
    @State private var showingClearCacheAlert = false
    @State private var cacheSize = "Calculating..."
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        apiSection
                        cacheSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Settings")
                        .font(.brixieTitle)
                        .foregroundStyle(.brixieText)
                }
            }
        }
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: $apiKeyManager.apiKey)
            Button("Save") { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your Rebrickable API key. Get one for free at rebrickable.com")
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Clear", role: .destructive) {
                clearImageCache()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all cached images and set data. You can always re-download them later.")
        }
        .onAppear {
            updateCacheSize()
        }
    }
    
    private var apiSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Configuration")
                .font(.brixieHeadline)
                .foregroundStyle(.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.brixieAccent.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: apiKeyManager.hasValidAPIKey ? "checkmark.shield.fill" : "key.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(apiKeyManager.hasValidAPIKey ? .brixieSuccess : .brixieAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rebrickable API Key")
                                .font(.brixieSubhead)
                                .foregroundStyle(.brixieText)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(apiKeyManager.hasValidAPIKey ? .brixieSuccess : .brixieSecondary)
                                    .frame(width: 8, height: 8)
                                Text(apiKeyManager.hasValidAPIKey ? "Connected" : "Not configured")
                                    .font(.brixieCaption)
                                    .foregroundStyle(apiKeyManager.hasValidAPIKey ? .brixieSuccess : .brixieTextSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Configure") {
                            showingAPIKeyAlert = true
                        }
                        .buttonStyle(BrixieButtonStyle(variant: .secondary))
                    }
                    
                    Divider()
                        .background(.brixieSecondary.opacity(0.3))
                    
                    Link(destination: URL(string: "https://rebrickable.com/api/")!) {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: 14))
                                .foregroundStyle(.brixieAccent)
                            
                            Text(NSLocalizedString("Get Free API Key", comment: "Get API Key link"))
                                .font(.brixieBody)
                                .foregroundStyle(.brixieAccent)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.brixieAccent.opacity(0.6))
                        }
                    }
                }
                .padding(20)
            }
            
            Text("A free Rebrickable API key is required to fetch LEGO set data and unlock all features.")
                .font(.brixieCaption)
                .foregroundStyle(.brixieTextSecondary)
                .padding(.leading, 4)
        }
    }
    
    private var cacheSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Management")
                .font(.brixieHeadline)
                .foregroundStyle(.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.brixieWarning.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "photo.stack")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.brixieWarning)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Image Cache")
                                .font(.brixieSubhead)
                                .foregroundStyle(.brixieText)
                            
                            Text(cacheSize)
                                .font(.brixieCaption)
                                .foregroundStyle(.brixieTextSecondary)
                        }
                        
                        Spacer()
                        
                        Button("Clear Cache") {
                            showingClearCacheAlert = true
                        }
                        .buttonStyle(BrixieButtonStyle(variant: .ghost))
                    }
                    
                    Divider()
                        .background(.brixieSecondary.opacity(0.3))
                    
                    Button {
                        clearAllData()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                            
                            Text("Clear All Data")
                                .font(.brixieBody)
                                .foregroundStyle(.red)
                            
                            Spacer()
                        }
                    }
                }
                .padding(20)
            }
            
            Text("Clear cached images and stored set data to free up storage space on your device.")
                .font(.brixieCaption)
                .foregroundStyle(.brixieTextSecondary)
                .padding(.leading, 4)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Brixie")
                .font(.brixieHeadline)
                .foregroundStyle(.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(.brixieAccent.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.brixieAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brixie")
                                .font(.brixieSubhead)
                                .foregroundStyle(.brixieText)
                            
                            Text("Version 1.0.0")
                                .font(.brixieCaption)
                                .foregroundStyle(.brixieTextSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        Link(destination: URL(string: "https://brixie.net")!) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.brixieAccent)
                                
                                Text(NSLocalizedString("Visit Website", comment: "Visit website"))
                                    .font(.brixieBody)
                                    .foregroundStyle(.brixieAccent)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.brixieAccent.opacity(0.6))
                            }
                        }
                        
                        Divider()
                            .background(.brixieSecondary.opacity(0.3))
                        
                        Link(destination: URL(string: "https://rebrickable.com")!) {
                            HStack {
                                Image(systemName: "building.2")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.brixieAccent)
                                
                                Text(NSLocalizedString("Powered by Rebrickable", comment: "Rebrickable link"))
                                    .font(.brixieBody)
                                    .foregroundStyle(.brixieAccent)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.brixieAccent.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            Text("Brixie uses the Rebrickable API to provide comprehensive LEGO set information and enhance your building experience.")
                .font(.brixieCaption)
                .foregroundStyle(.brixieTextSecondary)
                .padding(.leading, 4)
        }
    }
    
    private func updateCacheSize() {
        Task {
            let size = ImageCacheService.shared.getCacheSize()
            await MainActor.run {
                cacheSize = size
            }
        }
    }
    
    private func clearImageCache() {
        ImageCacheService.shared.clearCache()
        updateCacheSize()
    }
    
    private func clearAllData() {
        // Clear SwiftData
        do {
            let descriptor = FetchDescriptor<LegoSet>()
            let allSets = try modelContext.fetch(descriptor)
            for set in allSets {
                modelContext.delete(set)
            }
            try modelContext.save()
        } catch {
            print("Failed to clear SwiftData: \(error)")
        }
        
        // Clear image cache
        clearImageCache()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: LegoSet.self, inMemory: true)
}