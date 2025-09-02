//
//  ContentView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
       
    }

   

   
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
