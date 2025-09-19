//
//  MacCatalystUnsupportedView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

struct MacCatalystUnsupportedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "laptopcomputer")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("Scanner Not Available on Mac")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Barcode scanning is not supported on Mac. You can enter barcodes manually using the Manual Entry button.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    MacCatalystUnsupportedView()
}
