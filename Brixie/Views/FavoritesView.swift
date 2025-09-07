//
//  FavoritesView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(filter: #Predicate<LegoSet> { $0.isFavorite == true }, sort: \LegoSet.name) 
    private var favoriteSet: [LegoSet]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brixieBackground
                    .ignoresSafeArea()
                
                Group {
                    if favoriteSet.isEmpty {
                        emptyFavoritesView
                    } else {
                        favoritesList
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(NSLocalizedString("Favorites", comment: "Navigation title for favorites"))
                        .font(.brixieTitle)
                        .foregroundStyle(Color.brixieText)
                }
            }
        }
    }
    
    private var emptyFavoritesView: some View {
        BrixieHeroSection(
            title: NSLocalizedString("No Favorites Yet", comment: "Empty favorites title"),
            subtitle: NSLocalizedString("Sets you favorite will appear here for quick access. Start exploring to find your perfect builds!", comment: "Empty favorites subtitle"),
            icon: "heart.fill"
        ) {
            EmptyView()
        }
    }
    
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(favoriteSet) { set in
                    NavigationLink(destination: SetDetailView(set: set)) {
                        SetRowView(set: set)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ZStack {
        Color.brixieBackground
            .ignoresSafeArea()
        
        FavoritesView()
            .modelContainer(for: LegoSet.self, inMemory: true)
    }
}