//
//  PermissionRequestView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

struct PermissionRequestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To scan LEGO set barcodes, Brixie needs access to your camera.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    PermissionRequestView()
}