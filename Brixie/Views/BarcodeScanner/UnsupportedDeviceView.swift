//
//  UnsupportedDeviceView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

struct UnsupportedDeviceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            Text("Scanner Not Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The barcode scanner is not available on this device. You can still enter barcodes manually.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    UnsupportedDeviceView()
}