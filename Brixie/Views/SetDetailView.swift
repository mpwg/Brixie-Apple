//
//  SetDetailView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct SetDetailView: View {
    let set: LegoSet
    @Environment(\.modelContext) private var modelContext
    @State private var isFavorite: Bool
    @State private var showingFullScreenImage = false
    
    init(set: LegoSet) {
        self.set = set
        self._isFavorite = State(initialValue: set.isFavorite)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero Image
                heroImageView
                
                // Set Information
                setInfoView
                
                // Statistics
                statisticsView
                
                // Actions
                actionsView
            }
            .padding()
        }
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .primary)
                }
            }
        }
        .onAppear {
            markAsViewed()
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageView(imageURL: set.imageURL)
        }
    }
    
    private var heroImageView: some View {
        VStack {
            AsyncCachedImage(urlString: set.imageURL)
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.1))
                )
                .onTapGesture {
                    if set.imageURL != nil {
                        showingFullScreenImage = true
                    }
                }
            
            if set.imageURL != nil {
                Text(NSLocalizedString("Tap to view full size", comment: "Hint for image tap"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var setInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Set Information", comment: "Set information heading"))
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(label: "Set Number", value: set.setNum)
                InfoRow(label: "Name", value: set.name)
                InfoRow(label: "Year", value: String(set.year))
                InfoRow(label: "Pieces", value: String(set.numParts))
                if let themeName = set.themeName {
                    InfoRow(label: "Theme", value: themeName)
                }
            }
            .padding()
            .background(.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Statistics", comment: "Statistics heading"))
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Pieces",
                    value: String(set.numParts),
                    icon: "cube.box",
                    color: .blue
                )
                
                StatCard(
                    title: "Year",
                    value: String(set.year),
                    icon: "calendar",
                    color: .green
                )

                if let lastViewed = set.lastViewed {
                    StatCard(
                        title: "Last Viewed",
                        value: RelativeDateTimeFormatter().localizedString(for: lastViewed, relativeTo: Date()),
                        icon: "eye",
                        color: .purple
                    )
                }
                
                StatCard(
                    title: "Favorite",
                    value: isFavorite ? "Yes" : "No",
                    icon: isFavorite ? "heart.fill" : "heart",
                    color: .red
                )
            }
        }
    }
    
    private var actionsView: some View {
        VStack(spacing: 12) {
            Button {
                toggleFavorite()
            } label: {
                                Label(isFavorite ? NSLocalizedString("Remove from Favorites", comment: "Remove favorite action") : NSLocalizedString("Add to Favorites", comment: "Add favorite action"),
                                            systemImage: isFavorite ? "heart.slash" : "heart")
            }
            .buttonStyle(.borderedProminent)
            .tint(isFavorite ? .red : .blue)
            
            if let imageURL = set.imageURL {
                ShareLink(item: URL(string: imageURL)!) {
                                        Label(NSLocalizedString("Share Image", comment: "Share image action"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func toggleFavorite() {
        set.isFavorite.toggle()
        isFavorite = set.isFavorite
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update favorite status: \(error)")
        }
    }
    
    private func markAsViewed() {
        set.lastViewed = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update view date: \(error)")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FullScreenImageView: View {
    let imageURL: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                AsyncCachedImage(urlString: imageURL)
                    .aspectRatio(contentMode: .fit)
                    .clipped()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    let sampleSet = LegoSet(
        setNum: "10294-1",
        name: "Titanic",
        year: 2021,
        themeId: 1,
        numParts: 9090
    )
    
    NavigationStack {
        SetDetailView(set: sampleSet)
    }
    .modelContainer(for: LegoSet.self, inMemory: true)
}

#Preview {
    // Preview for InfoRow
    VStack {
        InfoRow(label: "Set Number", value: "10294-1")
        Divider()
        InfoRow(label: "Year", value: "2021")
    }
    .padding()
}

#Preview {
    // Preview for StatCard
    HStack(spacing: 12) {
        StatCard(title: "Pieces", value: "9090", icon: "cube.box", color: .blue)
        StatCard(title: "Year", value: "2021", icon: "calendar", color: .green)
    }
    .padding()
}

#Preview("No Image") {
    FullScreenImageView(imageURL: nil)
}

#Preview("With Image") {
    FullScreenImageView(imageURL: "https://example.com/image.jpg")
}