//
//  PermissionDeniedView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

struct PermissionDeniedView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 64))
                .foregroundStyle(.red)
            
            Text("Camera Access Denied")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please enable camera access in Settings to use the barcode scanner.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: "app-settings:") {
            openURL(settingsURL)
        }
    }
}

#Preview {
    PermissionDeniedView()
}