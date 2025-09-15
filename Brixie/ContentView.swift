//
//  ContentView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.colorScheme)
    private var colorScheme


    
    var body: some View {
        MainView()

    }
}
