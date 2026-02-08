import Foundation
import SwiftUI
import UIKit
internal import Combine

@MainActor
final class ScanStore: ObservableObject {

    @Published private(set) var records: [ScanRecord] = []

    private let fileName = "scan_records.json"

    init() {
        load()
    }

    // MARK: - Public API

    func addRecord(
        brand: String,
        score: Int?,
        grade: String?,
        notes: String? = nil,
        image: UIImage? = nil,
        analysisJSON: Any? = nil
    ) {
        let id = UUID()

        var imagePath: String?
        var analysisPath: String?

        do {
            if let image {
                imagePath = try LocalFiles.saveJPEG(image, id: id)
            }
            if let analysisJSON {
                analysisPath = try LocalFiles.saveAnalysisJSON(analysisJSON, id: id)
            }
        } catch {
            // Non-fatal for MVP: still save record without files
            print("⚠️ File save error:", error)
        }

        let record = ScanRecord(
            id: id,
            brand: brand,
            date: Date(),
            score: score,
            grade: grade,
            notes: notes,
            imageFilename: imagePath,
            analysisJSONFilename: analysisPath
        )

        records.insert(record, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        for i in offsets {
            let rec = records[i]
            if let p = rec.imageFilename { LocalFiles.delete(relativePath: p) }
            if let p = rec.analysisJSONFilename { LocalFiles.delete(relativePath: p) }
        }
        records.remove(atOffsets: offsets)
        persist()
    }
    
    func delete(record: ScanRecord) {
        guard let idx = records.firstIndex(of: record) else { return }

        // delete files
        let rec = records[idx]
        if let p = rec.imageFilename { LocalFiles.delete(relativePath: p) }
        if let p = rec.analysisJSONFilename { LocalFiles.delete(relativePath: p) }

        // delete record + persist
        records.remove(at: idx)
        persist()
    }

    func clearAll() {
        for rec in records {
            if let p = rec.imageFilename { LocalFiles.delete(relativePath: p) }
            if let p = rec.analysisJSONFilename { LocalFiles.delete(relativePath: p) }
        }
        records = []
        persist()
    }

    // MARK: - Persistence

    private func recordsURL() throws -> URL {
        let docs = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return docs.appendingPathComponent(fileName)
    }

    private func load() {
        do {
            let url = try recordsURL()
            guard FileManager.default.fileExists(atPath: url.path) else {
                records = []
                return
            }
            let data = try Data(contentsOf: url)
            records = try JSONDecoder().decode([ScanRecord].self, from: data)
        } catch {
            print("⚠️ Failed to load scan records:", error)
            records = []
        }
    }

    private func persist() {
        do {
            let url = try recordsURL()
            let data = try JSONEncoder().encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("⚠️ Failed to save scan records:", error)
        }
    }
}

extension ScanStore {
    func loadImage(for record: ScanRecord) -> UIImage? {
        guard let path = record.imageFilename else { return nil }
        return LocalFiles.loadImage(relativePath: path)
    }

    func loadRawAnalysisObject(for record: ScanRecord) -> Any? {
        guard let path = record.analysisJSONFilename else { return nil }
        return LocalFiles.loadAnalysisJSON(relativePath: path)
    }
    
    func rebuildScanResult(for record: ScanRecord) -> ScanResult? {
            // Try to read persisted JSON payload
            guard let obj = loadRawAnalysisObject(for: record),
                  let dict = obj as? [String: Any] else { return nil }

            let overall = dict["overall"] as? Int ?? record.score ?? 0
            let verdict = (dict["verdict"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let grade = (verdict?.isEmpty == false) ? verdict! : (record.grade ?? "")

            // Try to reconstruct materials if present
            var materials: [MaterialComposition] = []
            if let mats = dict["materials"] as? [[String: Any]] {
                materials = mats.compactMap { m in
                    guard let material = m["material"] as? String,
                          let pct = m["percentage"] as? Int else { return nil }
                    return MaterialComposition(material: material, percentage: pct)
                }
            }

            // Confidence (best-effort)
            let confString = (dict["parseConfidence"] as? String)?.lowercased() ?? "low"
            let confidence: ConfidenceLevel = (confString == "high") ? .high : (confString == "medium" ? .medium : .low)

            // Biodeg text (best-effort -> range parsing)
            let biodegText = dict["biodegText"] as? String ?? "—"
            let (low, high) = extractRange(from: biodegText)

            let biodeg = BiodegradationData(
                rangeLow: low,
                rangeHigh: high,
                positionPercent: min(max(Double(overall) / 100.0, 0.0), 1.0),
                hasSynthetics: (dict["syntheticWarningText"] is String),
                syntheticWarning: dict["syntheticWarningText"] as? String,
                comparisons: [
                    BiodegradationComparison(label: "Apple core", time: "2 months", isSynthetic: false),
                    BiodegradationComparison(label: "Cotton tee", time: "6 months", isSynthetic: false),
                    BiodegradationComparison(label: "Nylon jacket", time: "30–40 yr", isSynthetic: true),
                    BiodegradationComparison(label: "Plastic bottle", time: "450 yr", isSynthetic: true),
                ]
            )

            let why: [String] = (dict["why"] as? [String]) ?? {
                var reasons: [String] = []
                if !grade.isEmpty { reasons.append("Verdict: \(grade)") }
                if let ocr = dict["ocrText"] as? String, !ocr.isEmpty { reasons.append("OCR captured.") }
                return reasons.isEmpty ? ["Saved scan (details unavailable)."] : reasons
            }()

            let certNames: [String] = (dict["certifications"] as? [String]) ?? []
            let certs = certNames.map { Certification(name: $0, verified: false) }

            return ScanResult(
                brand: record.brand,
                item: "Clothing Item",
                materials: materials,
                score: overall,
                confidence: confidence,
                breakdown: [], // you can rebuild later; MVP leave empty
                biodegradation: biodeg,
                whyThisScore: why,
                certifications: certs
            )
        }

        // Local helper for range extraction (duplicate of VM version for now)
        private func extractRange(from text: String) -> (String, String) {
            let separators = ["–", "-"]
            for sep in separators {
                if let range = text.range(of: sep) {
                    let left = text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                    let right = text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanLeft = left.replacingOccurrences(of: "Most:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanRight = right.components(separatedBy: "•").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? right
                    if !cleanLeft.isEmpty && !cleanRight.isEmpty { return (cleanLeft, cleanRight) }
                }
            }
            return ("—", "—")
        }
}
