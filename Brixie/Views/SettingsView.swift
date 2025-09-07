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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(DIContainer.self) private var diContainer
    @State private var showingClearCacheAlert = false
    @State private var cacheSize = "Calculating..."
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        themeSection
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
                    Text(NSLocalizedString("Settings", comment: "Settings navigation title"))
                        .font(.brixieTitle)
                        .foregroundStyle(Color.brixieText)
                }
            }
        }
        .alert(NSLocalizedString("Clear Cache", comment: "Clear cache alert title"), isPresented: $showingClearCacheAlert) {
            Button(NSLocalizedString("Clear", comment: "Clear button"), role: .destructive) {
                clearImageCache()
            }
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("This will clear all cached images and set data. You can always re-download them later.", comment: "Clear cache alert message"))
        }
        .onAppear {
            updateCacheSize()
        }
    }
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Appearance", comment: "Appearance section title"))
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.brixieAccent.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: themeManager.selectedTheme.iconName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.brixieAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Theme", comment: "Theme label"))
                                .font(.brixieSubhead)
                                .foregroundStyle(Color.brixieText)
                            
                            Text(themeManager.selectedTheme.displayName)
                                .font(.brixieCaption)
                                .foregroundStyle(Color.brixieTextSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.brixieSecondary.opacity(0.3))
                    
                    VStack(spacing: 12) {
                        ForEach(AppTheme.allCases) { theme in
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    themeManager.selectedTheme = theme
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: theme.iconName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(themeManager.selectedTheme == theme ? Color.brixieAccent : Color.brixieTextSecondary)
                                        .frame(width: 20)
                                    
                                    Text(theme.displayName)
                                        .font(.brixieBody)
                                        .foregroundStyle(themeManager.selectedTheme == theme ? Color.brixieAccent : Color.brixieText)
                                    
                                    Spacer()
                                    
                                    if themeManager.selectedTheme == theme {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.brixieAccent)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
            }
            
            Text(NSLocalizedString("Choose how Brixie looks. System follows your device's appearance settings.", comment: "Theme section description"))
                .font(.brixieCaption)
                .foregroundStyle(Color.brixieTextSecondary)
                .padding(.leading, 4)
        }
    }
    
    
    private var cacheSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Storage Management", comment: "Storage section title"))
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.brixieWarning.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "photo.stack")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.brixieWarning)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Image Cache", comment: "Image cache label"))
                                .font(.brixieSubhead)
                                .foregroundStyle(Color.brixieText)
                            
                            Text(cacheSize)
                                .font(.brixieCaption)
                                .foregroundStyle(Color.brixieTextSecondary)
                        }
                        
                        Spacer()
                        
                        Button(NSLocalizedString("Clear Cache", comment: "Clear cache button")) {
                            showingClearCacheAlert = true
                        }
                        .buttonStyle(BrixieButtonStyle(variant: .ghost))
                    }
                    
                    Divider()
                        .background(Color.brixieSecondary.opacity(0.3))
                    
                    Button {
                        clearAllData()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                            
                            Text(NSLocalizedString("Clear All Data", comment: "Clear all data label"))
                                .font(.brixieBody)
                                .foregroundStyle(.red)
                            
                            Spacer()
                        }
                    }
                }
                .padding(20)
            }
            
            Text(NSLocalizedString("Clear cached images and stored set data to free up storage space on your device.", comment: "Storage section description"))
                .font(.brixieCaption)
                .foregroundStyle(Color.brixieTextSecondary)
                .padding(.leading, 4)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("About Brixie", comment: "About section title"))
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText)
            
            BrixieCard {
                VStack(spacing: 16) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.brixieAccent.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.brixieAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Brixie", comment: "App name label"))
                                .font(.brixieSubhead)
                                .foregroundStyle(Color.brixieText)
                            
                            Text(NSLocalizedString("Version 1.0.0", comment: "App version label"))
                                .font(.brixieCaption)
                                .foregroundStyle(Color.brixieTextSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        Link(destination: URL(string: "https://brixie.net")!) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.brixieAccent)
                                
                                Text(NSLocalizedString("Visit Website", comment: "Visit website"))
                                    .font(.brixieBody)
                                    .foregroundStyle(Color.brixieAccent)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.brixieAccent.opacity(0.6))
                            }
                        }
                        
                        Divider()
                            .background(Color.brixieSecondary.opacity(0.3))
                        
                        Link(destination: URL(string: "https://rebrickable.com")!) {
                            HStack {
                                Image(systemName: "building.2")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.brixieAccent)
                                
                                Text(NSLocalizedString("Powered by Rebrickable", comment: "Rebrickable link"))
                                    .font(.brixieBody)
                                    .foregroundStyle(Color.brixieAccent)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.brixieAccent.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            Text(NSLocalizedString("Brixie uses the Rebrickable API to provide comprehensive LEGO set information and enhance your building experience.", comment: "About app description"))
                .font(.brixieCaption)
                .foregroundStyle(Color.brixieTextSecondary)
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
