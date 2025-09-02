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
    @AppStorage("rebrickableAPIKey") private var apiKey = ""
    @State private var showingAPIKeyAlert = false
    @State private var showingClearCacheAlert = false
    @State private var cacheSize = "Calculating..."
    
    var body: some View {
        NavigationStack {
            List {
                apiSection
                cacheSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Enter API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Rebrickable API Key", text: $apiKey)
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
        Section(content: {
            HStack {
                VStack(alignment: .leading) {
                    Text("API Key")
                        .fontWeight(.medium)
                    if apiKey.isEmpty {
                        Text("Not configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Configured")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                Spacer()
                
                Button("Configure") {
                    showingAPIKeyAlert = true
                }
                .buttonStyle(.bordered)
            }
            
            Link(destination: URL(string: "https://rebrickable.com/api/")!) {
                Label("Get API Key", systemImage: "link")
            }
        }, header: {
            Text("API Configuration")
        }, footer: {
            Text("A free Rebrickable API key is required to fetch LEGO set data.")
        })
    }
    
    private var cacheSection: some View {
        Section(content: {
            HStack {
                VStack(alignment: .leading) {
                    Text("Image Cache")
                        .fontWeight(.medium)
                    Text(cacheSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Clear Cache") {
                    showingClearCacheAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
            }
            
            Button("Clear All Data") {
                clearAllData()
            }
            .foregroundStyle(.red)
        }, header: {
            Text("Storage")
        }, footer: {
            Text("Clear cached images and stored set data to free up storage space.")
        })
    }
    
    private var aboutSection: some View {
        Section(content: {
            HStack {
                Text("App Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            
            Link(destination: URL(string: "https://brixie.net")!) {
                Label("Visit Website", systemImage: "globe")
            }
            
            Link(destination: URL(string: "https://rebrickable.com")!) {
                Label("Rebrickable", systemImage: "building.2")
            }
        }, header: {
            Text("About")
        }, footer: {
            Text("Brixie uses the Rebrickable API to provide LEGO set information.")
        })
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