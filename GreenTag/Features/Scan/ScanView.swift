//
//  ScanView.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import SwiftUI
import VisionKit

struct ScanScreen: View {
    @State private var showingScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Button("Scan tag") {
                showingScanner = true
            }
            .disabled(!VNDocumentCameraViewController.isSupported)

            if let first = scannedImages.first {
                Image(uiImage: first)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .padding()
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(
                onComplete: { images in
                    scannedImages = images
                    // next: pass images into OCR to extract text
                },
                onCancel: { },
                onError: { err in
                    errorMessage = err.localizedDescription
                }
            )
        }
        .onAppear {
            if !VNDocumentCameraViewController.isSupported {
                errorMessage = "Document scanning isn’t supported on this device."
            }
        }
    }
}
