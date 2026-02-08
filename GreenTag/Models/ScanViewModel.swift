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
    @Published var result: ScanResult? = nil

    @Published var lastImage: UIImage?
    @Published var errorMessage: String?
    @Published var tagInput = TagInput()

    @Published var ocrText: String = ""
    @Published var parsedText: String = ""
    @Published var parseConfidence: String = ""

    @Published var scoreOverall: Int?
    @Published var scoreVerdict: String = ""
    @Published var biodegText: String = ""
    @Published var syntheticWarningText: String?

    func analyze(image: UIImage) {
        // reset
        result = nil
        errorMessage = nil
        lastImage = image

        ocrText = ""
        parsedText = ""
        parseConfidence = ""
        scoreOverall = nil
        scoreVerdict = ""
        biodegText = ""
        syntheticWarningText = nil

        withAnimation(.easeInOut(duration: 0.3)) {
            screenState = .loading
        }

        Task {
            do {
                let out = try await GreenTagPipeline.analyze(image: image)

                // store debug/state
                ocrText = out.ocrText
                parsedText = out.parsedText
                parseConfidence = out.parseConfidence

                scoreOverall = out.overall
                scoreVerdict = out.verdict
                biodegText = out.biodegText
                syntheticWarningText = out.syntheticWarningText

                // build a ScanResult (MVP mapping)
                result = buildScanResult(from: out)

                // go to results only when result exists
                withAnimation(.easeInOut(duration: 0.3)) {
                    screenState = .results
                }

            } catch {
                errorMessage = "❌ OCR failed: \(error.localizedDescription)"
                withAnimation(.easeInOut(duration: 0.3)) {
                    screenState = .scan
                }
            }
        }
    }

    // MARK: - MVP Result Builder (compiles with your models)

    private func buildScanResult(from out: GreenTagPipeline.Output) -> ScanResult {
        // Parse "96% cotton" lines into MaterialComposition
        let materials: [MaterialComposition] = out.parsedText
            .split(separator: "\n")
            .compactMap { line in
                // Expected: "96% cotton"
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }

                let pctString = parts[0].replacingOccurrences(of: "%", with: "")
                let pct = Int(pctString) ?? 0
                let mat = parts[1]

                return MaterialComposition(material: mat.capitalized, percentage: pct)
            }

        // Confidence mapping from pipeline string to enum
        let confidence: ConfidenceLevel = {
            switch out.parseConfidence.lowercased() {
            case "high": return .high
            case "medium": return .medium
            default: return .low
            }
        }()

        // Biodeg range: ResultsView wants low/high strings
        // out.biodegText is currently like "Most: X • Residue..." sometimes,
        // for MVP, extract the first "A – B"
        let (low, high) = extractRange(from: out.biodegText)

        let biodeg = BiodegradationData(
            rangeLow: low,
            rangeHigh: high,
            positionPercent: min(max(Double(out.overall) / 100.0, 0.0), 1.0),
            hasSynthetics: out.syntheticWarningText != nil,
            syntheticWarning: out.syntheticWarningText,
            comparisons: [
                BiodegradationComparison(label: "Apple core", time: "2 months", isSynthetic: false),
                BiodegradationComparison(label: "Cotton tee", time: "6 months", isSynthetic: false),
                BiodegradationComparison(label: "Nylon jacket", time: "30–40 yr", isSynthetic: true),
                BiodegradationComparison(label: "Plastic bottle", time: "450 yr", isSynthetic: true),
            ]
        )

        // Minimal breakdown so the UI renders
        let breakdown: [BreakdownCategory] = [
            BreakdownCategory(
                label: "Material Safety",
                value: out.overall,
                explanation: out.syntheticWarningText == nil
                    ? "Mostly natural fibers detected."
                    : "Synthetic blend increases microplastics risk.",
                color: bucket(out.overall),
                sfSymbol: "shield.checkered"
            ),
            BreakdownCategory(
                label: "Environmental Impact",
                value: max(min(out.overall - 10, 100), 0),
                explanation: "Estimated from fiber mix + biodegradation range.",
                color: bucket(max(min(out.overall - 10, 100), 0)),
                sfSymbol: "leaf.arrow.triangle.circlepath"
            ),
            BreakdownCategory(
                label: "Social Responsibility",
                value: 70,
                explanation: tagInput.countryOfOrigin.isEmpty
                    ? "Origin not detected/entered."
                    : "Origin: \(tagInput.countryOfOrigin)",
                color: bucket(70),
                sfSymbol: "person.2"
            ),
            BreakdownCategory(
                label: "Durability & Lifespan",
                value: 65,
                explanation: "Baseline estimate (MVP).",
                color: bucket(65),
                sfSymbol: "clock.arrow.circlepath"
            )
        ]

        let certs: [Certification] = tagInput.certifications
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { Certification(name: $0.uppercased(), verified: false) }

        var why: [String] = []
        if !materials.isEmpty {
            why.append("Detected composition: " + materials.map { "\($0.percentage)% \($0.material)" }.joined(separator: ", "))
        } else {
            why.append("No clear composition detected from the tag.")
        }
        why.append("Estimated biodegradation: \(low) – \(high).")
        if let warn = out.syntheticWarningText {
            why.append(warn)
        }
        if !certs.isEmpty {
            why.append("Certifications entered: " + certs.map { $0.name }.joined(separator: ", "))
        }

        let brand = tagInput.brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        return ScanResult(
            brand: brand.isEmpty ? "UNKNOWN" : brand.uppercased(),
            item: "Clothing Item",
            materials: materials,
            score: out.overall,
            confidence: confidence,
            breakdown: breakdown,
            biodegradation: biodeg,
            whyThisScore: why,
            certifications: certs
        )
    }

    private func bucket(_ score: Int) -> String {
        switch score {
        case 75...100: return "good"
        case 50..<75: return "mixed"
        default: return "avoid"
        }
    }

    private func extractRange(from text: String) -> (String, String) {
        let separators = ["–", "-"]

        // Find a line containing a dash-like separator
        for sep in separators {
            if let range = text.range(of: sep) {
                let left = text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let right = text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

                // If "Most:" exists, remove it
                let cleanLeft = left.replacingOccurrences(of: "Most:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // If there's extra after the right side (like "• Residue..."), cut it
                let cleanRight = right.components(separatedBy: "•").first?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? right

                if !cleanLeft.isEmpty && !cleanRight.isEmpty {
                    return (cleanLeft, cleanRight)
                }
            }
        }
        return ("—", "—")
    }
}
