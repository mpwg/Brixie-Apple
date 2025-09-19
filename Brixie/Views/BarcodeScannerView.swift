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

#if canImport(VisionKit) && !targetEnvironment(macCatalyst)
struct DataScannerView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = [
            .barcode(symbologies: [
                .ean13, .ean8, .upce,
                .code128, .code39, .code93,
                .itf14,
                .dataMatrix, .pdf417, .qr
            ])
        ]
        
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: DataScannerView
        
        init(_ parent: DataScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let barcodeValue = barcode.payloadStringValue {
                    parent.onBarcodeScanned(barcodeValue)
                }
            default:
                break
            }
        }
    }
}
#endif

struct ManualBarcodeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var barcodeText = ""
    let onBarcodeEntered: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Enter barcode", text: $barcodeText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Manual Barcode Entry")
                } footer: {
                    Text("Enter the barcode numbers manually if the scanner cannot read it.")
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let trimmed = barcodeText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onBarcodeEntered(trimmed)
                        }
                    }
                    .disabled(barcodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

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
    BarcodeScannerView { barcode in
        print("Scanned: \(barcode)")
    }
}