//
//  ScanViewModel.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/8/26.
//

import SwiftUI
internal import Combine
import UIKit

@MainActor
final class ScanViewModel: ObservableObject {

    @Published var screenState: ScreenState = .scan

    @Published var lastImage: UIImage?
    @Published var errorMessage: String?

    // Debug / visibility (optional to show in UI)
    @Published var ocrText: String = ""
    @Published var parsedText: String = ""
    @Published var parseConfidence: String = ""

    // Final values you’ll pass into ResultsView later
    @Published var scoreOverall: Int?
    @Published var scoreVerdict: String = ""
    @Published var biodegText: String = ""
    @Published var syntheticWarningText: String?

    func analyze(image: UIImage) {
        lastImage = image
        errorMessage = nil

        // switch UI first
        withAnimation(.easeInOut(duration: 0.3)) {
            screenState = .loading
        }

        Task {
            do {
                let out = try await GreenTagPipeline.analyze(image: image)

                // store
                ocrText = out.ocrText
                parsedText = out.parsedText
                parseConfidence = out.parseConfidence

                scoreOverall = out.overall
                scoreVerdict = out.verdict
                biodegText = out.biodegText
                syntheticWarningText = out.syntheticWarningText

                // when LoadingView auto-advances, it can go to .results
                // OR you can force it here after a tiny delay if you prefer:
                // try? await Task.sleep(nanoseconds: 500_000_000)
                // screenState = .results

            } catch {
                errorMessage = "❌ OCR failed: \(error.localizedDescription)"
                // If you want: jump back to scan on failure
                withAnimation(.easeInOut(duration: 0.3)) {
                    screenState = .scan
                }
            }
        }
    }
}
