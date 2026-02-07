//
//  TextRecognizer.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import UIKit
import Vision

enum TextRecognizer {
    // Recognize text from a UIImage and return full text + per-line strings
    static func recognizeText(from image: UIImage) async throws -> (fullText: String, lines: [String]) {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "TextRecognizer", code: 1)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, err in
                if let err {
                    continuation.resume(throwing: err)
                    return
                }

                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []

                let lines = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .flatMap { $0.components(separatedBy: .newlines) }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                continuation.resume(
                    returning: (lines.joined(separator: "\n"), lines)
                )
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.015
            request.recognitionLanguages = ["en-US", "ko-KR", "vi-VN"]

            let orientation = cgOrientation(from: image.imageOrientation)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            
            Task.detached(priority: .userInitiated) {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // Vision needs CGImagePropertyOrientation
    private static func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
