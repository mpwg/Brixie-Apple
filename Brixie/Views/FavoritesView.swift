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
            Group {
                if favoriteSet.isEmpty {
                    emptyFavoritesView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var emptyFavoritesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Sets you favorite will appear here")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var favoritesList: some View {
        List {
            ForEach(favoriteSet) { set in
                NavigationLink(destination: SetDetailView(set: set)) {
                    SetRowView(set: set)
                }
            }
        }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: LegoSet.self, inMemory: true)
}