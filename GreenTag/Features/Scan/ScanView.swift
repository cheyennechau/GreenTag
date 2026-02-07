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

                    // MVP: OCR first page and print to console
                    guard let first = images.first else { return }

                    Task {
                        do {
                            let result = try await TextRecognizer.recognizeText(from: first)
                            print("===== OCR FULL TEXT =====")
                            print(result.fullText)
                            print("===== OCR LINES =====")
                            result.lines.forEach { print($0) }
                        } catch {
                            errorMessage = "OCR failed: \(error.localizedDescription)"
                            print("OCR error:", error)
                        }
                    }
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
