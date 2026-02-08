//
//  GreenTagPipeline.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/8/26.
//

import UIKit

struct GreenTagPipeline {

    struct Output {
        let ocrText: String
        let parsedText: String
        let parseConfidence: String

        let overall: Int
        let verdict: String
        let biodegText: String
        let syntheticWarningText: String?
    }

    static func analyze(image: UIImage) async throws -> Output {
        // 1) OCR
        let ocr = try await TextRecognizer.recognizeText(from: image)
        let fullText = ocr.fullText

        // 2) Parse
        let parsed = FabricParser.parse(fullText)
        let parts = parsed.parts

        let parsedText: String
        if parts.isEmpty {
            parsedText = "No composition detected"
        } else {
            parsedText = parts
                .sorted { $0.percent > $1.percent }
                .map { "\($0.percent)% \($0.material)" }
                .joined(separator: "\n")
        }

        // 3) Score
        let score = ScoringEngine.score(parts: parts)

        let majority = "\(formatMonths(score.biodegMajority.minMonths)) – \(formatMonths(score.biodegMajority.maxMonths))"
        let biodegText: String
        if let res = score.biodegResidual {
            biodegText = "Most: \(majority) • Residue: \(formatMonths(res.minMonths))–\(formatMonths(res.maxMonths))"
        } else {
            biodegText = majority
        }

        let warning = score.syntheticWarning ? "⚠️ High synthetic content (microplastics risk)" : nil

        return Output(
            ocrText: fullText,
            parsedText: parsedText,
            parseConfidence: parsed.confidence.rawValue,
            overall: score.overall,
            verdict: score.verdict.rawValue,
            biodegText: biodegText,
            syntheticWarningText: warning
        )
    }

    private static func formatMonths(_ months: Int) -> String {
        if months < 12 { return "\(months) mo" }
        let years = Double(months) / 12.0
        if years < 10 {
            return String(format: "%.1f yr", years)
        } else {
            return "\(Int(round(years))) yr"
        }
    }
}
