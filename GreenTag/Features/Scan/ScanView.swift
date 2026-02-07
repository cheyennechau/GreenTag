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
    @State private var showingPhotoPicker = false

    @State private var scannedImages: [UIImage] = []
    @State private var errorMessage: String?
    @State private var isAnalyzing = false

    var body: some View {
        VStack(spacing: 16) {

            HStack(spacing: 12) {
                Button("Scan tag") { showingScanner = true }
                    .disabled(!VNDocumentCameraViewController.isSupported)

                Button("Choose photo") { showingPhotoPicker = true }
            }

            if isAnalyzing {
                ProgressView("Analyzing…")
            }

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

        // Camera scanner sheet
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(
                onComplete: { images in
                    scannedImages = images
                    guard let first = images.first else { return }
                    Task { await analyze(image: first) }
                },
                onCancel: { },
                onError: { err in errorMessage = err.localizedDescription }
            )
        }

        // Photo picker sheet
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker { image in
                scannedImages = [image]
                Task { await analyze(image: image) }
            }
        }

        .onAppear {
            if !VNDocumentCameraViewController.isSupported {
                errorMessage = "Document scanning isn’t supported on this device."
            }
        }
    }

    @MainActor
    private func analyze(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            let result = try await TextRecognizer.recognizeText(from: image)
            print("===== OCR FULL TEXT =====")
            print(result.fullText)
            print("===== OCR LINES =====")
            result.lines.forEach { print($0) }
        } catch {
            errorMessage = "OCR failed: \(error.localizedDescription)"
            print("OCR error:", error)
        }
    }
}
