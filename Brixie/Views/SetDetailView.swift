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
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.colorScheme)
    private var colorScheme
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
                FavoriteButton(isFavorite: isFavorite, action: { toggleFavorite() }, prominent: false)
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
            CachedImageCard(urlString: set.imageURL, maxHeight: 300) {
                EmptyView()
            }
            .onTapGesture {
                if set.imageURL != nil {
                    showingFullScreenImage = true
                }
            }
            
            if set.imageURL != nil {
                Text(NSLocalizedString("Tap to view full size", comment: "Hint for image tap"))
                    .font(.brixieCaption)
                    .foregroundStyle(Color.brixieTextSecondary(for: colorScheme))
            }
        }
    }
    
    private var setInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Set Information", comment: "Set information heading"))
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText(for: colorScheme))

            BrixieCard {
                VStack(spacing: 12) {
                    InfoRow(label: NSLocalizedString("Set Number", comment: "Set number label"), value: set.setNum)
                    InfoRow(label: NSLocalizedString("Name", comment: "Name label"), value: set.name)
                    InfoRow(label: NSLocalizedString("Year", comment: "Year label"), value: String(set.year))
                    InfoRow(label: NSLocalizedString("Pieces", comment: "Pieces label"), value: String(set.numParts))
                    if let themeName = set.themeName {
                        InfoRow(label: NSLocalizedString("Theme", comment: "Theme label"), value: themeName)
                    }
                }
                .padding()
            }
        }
    }
    
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Statistics", comment: "Statistics heading"))
                .font(.brixieHeadline)
                .foregroundStyle(Color.brixieText(for: colorScheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: NSLocalizedString("Pieces", comment: "Pieces stat title"),
                    value: String(set.numParts),
                    icon: "cube.box",
                    color: Color.brixieAccent
                )

                StatCard(
                    title: NSLocalizedString("Year", comment: "Year stat title"),
                    value: String(set.year),
                    icon: "calendar",
                    color: Color.brixieSuccess
                )

                if let lastViewed = set.lastViewed {
                    StatCard(
                        title: NSLocalizedString("Last Viewed", comment: "Last viewed stat title"),
                        value: RelativeDateTimeFormatter().localizedString(for: lastViewed, relativeTo: Date()),
                        icon: "eye",
                        color: Color.brixieWarning
                    )
                }

                StatCard(
                    title: NSLocalizedString("Favorite", comment: "Favorite stat title"),
                    value: isFavorite ? NSLocalizedString("Yes", comment: "Yes") : NSLocalizedString("No", comment: "No"),
                    icon: isFavorite ? "heart.fill" : "heart",
                    color: isFavorite ? Color.brixieSuccess : Color.brixieTextSecondary(for: colorScheme)
                )
            }
        }
    }
    
    private var actionsView: some View {
        VStack(spacing: 12) {
            Button {
                toggleFavorite()
            } label: {
                Label(
                    isFavorite ?
                        NSLocalizedString("Remove from Favorites", comment: "Remove favorite action") :
                        NSLocalizedString("Add to Favorites", comment: "Add favorite action"),
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }
            .buttonStyle(BrixieButtonStyle(variant: .primary))

            if let imageURL = set.imageURL {
                ShareLink(item: URL(string: imageURL)!) {
                    Label(
                        NSLocalizedString("Share Image", comment: "Share image action"),
                        systemImage: "square.and.arrow.up"
                    )
                }
                .buttonStyle(BrixieButtonStyle(variant: .secondary))
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(label)
                .font(.brixieBody)
                .foregroundStyle(Color.brixieTextSecondary(for: colorScheme))
            Spacer()
            Text(value)
                .font(.brixieSubhead)
                .foregroundStyle(Color.brixieText(for: colorScheme))
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BrixieCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(color)

                Text(value)
                    .font(.brixieHeadline)
                    .foregroundStyle(Color.brixieText(for: colorScheme))

                Text(title)
                    .font(.brixieCaption)
                    .foregroundStyle(Color.brixieTextSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
}

struct FullScreenImageView: View {
    let imageURL: String?
    @Environment(\.dismiss)
    private var dismiss
    
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
        year: 2_021,
        themeId: 1,
        numParts: 9_090
    )
    
    NavigationStack {
        SetDetailView(set: sampleSet)
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
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
