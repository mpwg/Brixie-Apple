//
//  BarcodeScannerView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
#if canImport(VisionKit) && !targetEnvironment(macCatalyst)
import VisionKit
import Vision
#endif
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingManualEntry = false
    @State private var manualBarcode = ""
    let onBarcodeScanned: (String) -> Void
    
    var body: some View {
        NavigationView {
            Group {
#if canImport(VisionKit) && !targetEnvironment(macCatalyst)
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    switch cameraPermissionStatus {
                    case .authorized:
                        DataScannerView { scannedCode in
                            onBarcodeScanned(scannedCode)
                            dismiss()
                        }
                    case .denied, .restricted:
                        PermissionDeniedView()
                    case .notDetermined:
                        PermissionRequestView()
                    @unknown default:
                        PermissionRequestView()
                    }
                } else {
                    UnsupportedDeviceView()
                }
#else
                MacCatalystUnsupportedView()
#endif
            }
            .navigationTitle("Barcode Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manual Entry") {
                        showingManualEntry = true
                    }
                }
            }
        }
        .onAppear {
            checkCameraPermission()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBarcodeEntryView { barcode in
                onBarcodeScanned(barcode)
                dismiss()
            }
        }
    }
    
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if cameraPermissionStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionStatus = granted ? .authorized : .denied
                }
            }
        }
    }
}

#Preview {
    BarcodeScannerView { _ in
        // Preview - barcode handling should be done by ViewModel
    }
}
