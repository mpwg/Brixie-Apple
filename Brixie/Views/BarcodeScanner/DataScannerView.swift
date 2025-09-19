//
//  DataScannerView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
#if canImport(VisionKit) && !targetEnvironment(macCatalyst)
import VisionKit
import Vision
#endif

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