//
//  SearchFiltersView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

struct SearchFiltersView: View {
    @Binding var selectedThemes: Set<Int>
    let themes: [Theme]
    @Binding var minYear: Int
    @Binding var maxYear: Int
    @Binding var minParts: Int
    @Binding var maxParts: Int
    @Binding var useYearFilter: Bool
    @Binding var usePartsFilter: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Themes") {
                    if themes.isEmpty {
                        Text("No themes available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rootThemes, id: \.id) { theme in
                            ThemeFilterRow(
                                theme: theme,
                                selectedThemes: $selectedThemes,
                                allThemes: themes
                            )
                        }
                    }
                }
                
                Section("Year Range") {
                    Toggle("Filter by year", isOn: $useYearFilter)
                    
                    if useYearFilter {
                        VStack(spacing: 8) {
                            HStack {
                                Text("From")
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: Binding(
                                    get: { Double(minYear) },
                                    set: { minYear = Int($0) }
                                ), in: 1_958...Double(maxYear), step: 1)
                                Text("\(minYear)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: AppConstants.Layout.smallFieldWidth)
                            }
                            
                            HStack {
                                Text("To")
                                    .frame(width: AppConstants.Layout.mediumFieldWidth, alignment: .leading)
                                Slider(value: Binding(
                                    get: { Double(maxYear) },
                                    set: { maxYear = Int($0) }
                                ), in: Double(minYear)...Double(Calendar.current.component(.year, from: Date())), step: 1)
                                Text("\(maxYear)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: AppConstants.Layout.smallFieldWidth)
                            }
                        }
                    }
                }
                
                Section("Parts Count") {
                    Toggle("Filter by parts", isOn: $usePartsFilter)
                    
                    if usePartsFilter {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Min")
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: Binding(
                                    get: { Double(minParts) },
                                    set: { minParts = Int($0) }
                                ), in: 1...Double(maxParts), step: 1)
                                Text("\(minParts)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60)
                            }
                            
                            HStack {
                                Text("Max")
                                    .frame(width: AppConstants.Layout.mediumFieldWidth, alignment: .leading)
                                Slider(value: Binding(
                                    get: { Double(maxParts) },
                                    set: { maxParts = Int($0) }
                                ), in: Double(minParts)...AppConstants.Search.maxPartCount, step: AppConstants.Search.partCountStep)
                                Text("\(maxParts)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Clear All Filters") {
                        selectedThemes.removeAll()
                        useYearFilter = false
                        usePartsFilter = false
                        minYear = 1_958
                        maxYear = Calendar.current.component(.year, from: Date())
                        minParts = 1
                        maxParts = 10_000
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var rootThemes: [Theme] {
        themes.filter { $0.parentId == nil }.sorted { $0.name < $1.name }
    }
}

struct ThemeFilterRow: View {
    let theme: Theme
    @Binding var selectedThemes: Set<Int>
    let allThemes: [Theme]
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !subthemes.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: AppConstants.CommonAnimations.standardDuration)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Spacer()
                        .frame(width: 16)
                }
                
                Button {
                    toggleThemeSelection()
                } label: {
                    HStack {
                        Image(systemName: isThemeSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isThemeSelected ? .blue : .secondary)
                        
                        Text(theme.name)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded && !subthemes.isEmpty {
                VStack(spacing: 2) {
                    ForEach(subthemes, id: \.id) { subtheme in
                        HStack {
                            Spacer()
                                .frame(width: 32)
                            
                            Button {
                                if selectedThemes.contains(subtheme.id) {
                                    selectedThemes.remove(subtheme.id)
                                } else {
                                    selectedThemes.insert(subtheme.id)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedThemes.contains(subtheme.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedThemes.contains(subtheme.id) ? .blue : .secondary)
                                    
                                    Text(subtheme.name)
                                        .foregroundStyle(.primary)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    private var subthemes: [Theme] {
        allThemes.filter { $0.parentId == theme.id }.sorted { $0.name < $1.name }
    }
    
    private var isThemeSelected: Bool {
        selectedThemes.contains(theme.id) || subthemes.allSatisfy { selectedThemes.contains($0.id) }
    }
    
    private func toggleThemeSelection() {
        if isThemeSelected {
            // Deselect theme and all subthemes
            selectedThemes.remove(theme.id)
            subthemes.forEach { selectedThemes.remove($0.id) }
        } else {
            // Select theme and all subthemes
            selectedThemes.insert(theme.id)
            subthemes.forEach { selectedThemes.insert($0.id) }
        }
    }
}

#Preview {
    @Previewable @State var selectedThemes: Set<Int> = []
    @Previewable @State var minYear = 1_958
    @Previewable @State var maxYear = 2_024
    @Previewable @State var minParts = 1
    @Previewable @State var maxParts = 10_000
    @Previewable @State var useYearFilter = false
    @Previewable @State var usePartsFilter = false
    
    return SearchFiltersView(
        selectedThemes: $selectedThemes,
        themes: [
            Theme(id: 1, name: "Star Wars"),
            Theme(id: 2, name: "Creator", parentId: nil),
            Theme(id: 3, name: "Creator Expert", parentId: 2),
            Theme(id: 4, name: "Technic")
        ],
        minYear: $minYear,
        maxYear: $maxYear,
        minParts: $minParts,
        maxParts: $maxParts,
        useYearFilter: $useYearFilter,
        usePartsFilter: $usePartsFilter
    )
}
