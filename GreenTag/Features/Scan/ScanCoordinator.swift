//
//  ScanCoordinator.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import SwiftUI

struct ScanCoordinator: View {

    enum ActiveSheet: Identifiable {
        case scanner
        case photos
        var id: Int { hashValue }
    }
    

    @State private var activeSheet: ActiveSheet?
    @State private var lastImage: UIImage?
    @State private var ocrText: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    // add state for parser output
    @State private var parsedText: String = ""
    @State private var parseConfidence: String = ""
    
    @State private var scoreOverall: Int?
    @State private var scoreVerdict: String = ""
    @State private var biodegText: String = ""
    @State private var syntheticWarningText: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                if let scoreOverall = scoreOverall {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Score")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("\(scoreOverall) — \(scoreVerdict)")
                            .foregroundStyle(.white.opacity(0.9))

                        Text("Biodegradation: \(biodegText)")
                            .foregroundStyle(.white.opacity(0.85))

                        if let syntheticWarningText {
                            Text(syntheticWarningText)
                                .foregroundStyle(.yellow)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Text("GreenTag")
                    .font(.title2).bold()
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Button("Scan tag") { activeSheet = .scanner }
                    Button("Choose photo") { activeSheet = .photos }
                }
                .buttonStyle(.borderedProminent)

                if isAnalyzing {
                    ProgressView("Analyzing…")
                        .foregroundStyle(.white)
                }

                if let lastImage {
                    Image(uiImage: lastImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }

                // show parsed result
                if !parsedText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Parsed composition (\(parseConfidence))")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(parsedText)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if !ocrText.isEmpty {
                    ScrollView {
                        Text(ocrText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.white)
                            .padding()
                    }
                    .frame(maxHeight: 260)
                }
            }
            .padding()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .scanner:
                DocumentScannerView { images in
                    guard let first = images.first else { return }
                    lastImage = first
                    activeSheet = nil
                    Task { await analyze(image: first) }
                }

            case .photos:
                PhotoPicker { image in
                    lastImage = image
                    activeSheet = nil
                    Task { await analyze(image: image) }
                }
            }
        }
    }

    @MainActor
    private func analyze(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        ocrText = ""
        parsedText = ""
        parseConfidence = ""
        scoreOverall = nil
        scoreVerdict = ""
        biodegText = ""
        syntheticWarningText = nil
        defer { isAnalyzing = false }

        do {
            let result = try await TextRecognizer.recognizeText(from: image)
            ocrText = result.fullText
            print("✅ OCR OUTPUT:\n\(result.fullText)")

            let parsed = FabricParser.parse(result.fullText)
            let score = ScoringEngine.score(parts: parsed.parts)

            scoreOverall = score.overall
            scoreVerdict = score.verdict.rawValue

            let majority = "\(formatMonths(score.biodegMajority.minMonths)) – \(formatMonths(score.biodegMajority.maxMonths))"

            if let res = score.biodegResidual {
                biodegText = "Most: \(majority) • Residue: \(formatMonths(res.minMonths))–\(formatMonths(res.maxMonths))"
            } else {
                biodegText = majority
            }

            syntheticWarningText = score.syntheticWarning
                ? "⚠️ High synthetic content (microplastics risk)"
                : nil

            print("✅ SCORE:", score.overall, score.verdict.rawValue, score.syntheticWarning,
                  score.biodegMajority.minMonths, score.biodegMajority.maxMonths,
                  score.biodegResidual?.minMonths ?? -1, score.biodegResidual?.maxMonths ?? -1)

            parseConfidence = parsed.confidence.rawValue

            if parsed.parts.isEmpty {
                parsedText = "No composition detected"
            } else {
                parsedText = parsed.parts
                    .sorted { $0.percent > $1.percent }
                    .map { "\($0.percent)% \($0.material)" }
                    .joined(separator: "\n")
            }

            print("✅ PARSED:", parsed.parts, parsed.confidence)
        } catch {
            errorMessage = "❌ OCR failed: \(error.localizedDescription)"
            print("❌ OCR error:", error)
        }
    }
    
    private func formatMonths(_ months: Int) -> String {
        if months < 12 { return "\(months) mo" }
        let years = Double(months) / 12.0
        if years < 10 {
            return String(format: "%.1f yr", years)
        } else {
            return "\(Int(round(years))) yr"
        }
    }
}
