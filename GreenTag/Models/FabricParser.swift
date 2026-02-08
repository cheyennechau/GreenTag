//
//  FabricParser.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import Foundation

enum ParseConfidence: String {
    case high, medium, low
}

struct MaterialPart: Hashable {
    let material: String
    let percent: Int
}

struct FabricParseResult {
    let parts: [MaterialPart]
    let confidence: ParseConfidence
    let matchedLine: String?
}

enum FabricParser {

    // Canonical fiber name -> aliases you might see in OCR (add as you go)
    private static let fiberAliases: [String: [String]] = [
        "cotton": ["cotton", "coton", "cotone", "algodon", "algodón", "algodao", "algodão", "baumwolle", "pamuk", "хлопок"],
        "polyester": ["polyester", "poliester", "poliéster", "poliestere", "polyamid", "polyamide"],
        "viscose": ["viscose", "rayon", "modal", "lyocell", "tencel"],
        "wool": ["wool", "lana", "laine", "wolle"],
        "linen": ["linen", "lin", "lino"],
        "silk": ["silk", "soie", "seta", "seide"],
        "elastane": ["elastane", "elastan", "elastano", "spandex", "lycra"],
        "nylon": ["nylon", "polyamide", "poliamida", "poliamide"]
    ]

    // Precompute alias -> canonical
    private static let aliasToCanonical: [String: String] = {
        var map: [String: String] = [:]
        for (canonical, aliases) in fiberAliases {
            for a in aliases { map[a] = canonical }
        }
        return map
    }()
    
    static func parse(_ ocrText: String) -> FabricParseResult {
        let normalized = normalizeDocument(ocrText)

        // Extract pairs anywhere in the whole text
        let parts = extractPartsFromDocument(normalized)

        guard !parts.isEmpty else {
            return FabricParseResult(parts: [], confidence: .low, matchedLine: nil)
        }

        let deduped = Array(Set(parts)).sorted { $0.percent > $1.percent }

        let conf: ParseConfidence
        if deduped.count == 1, deduped[0].percent == 100 { conf = .high }
        else { conf = .medium }

        return FabricParseResult(parts: deduped, confidence: conf, matchedLine: nil)
    }

//    static func parse(_ ocrText: String) -> FabricParseResult {
//        let rawLines = ocrText
//            .components(separatedBy: .newlines)
//            .map { normalizeLine($0) }
//            .filter { !$0.isEmpty }
//
//        // 1) candidate lines: must have a % and at least one known fiber alias
//        let candidates = rawLines.filter { line in
//            (line.contains("%") || line.range(of: #"\b\d{1,3}\b"#, options: .regularExpression) != nil)
//            && containsAnyFiberAlias(line)
//        }
//
//        // If nothing looks like composition, low confidence
//        guard !candidates.isEmpty else {
//            return FabricParseResult(parts: [], confidence: .low, matchedLine: nil)
//        }
//
//        // 2) Score each candidate and extract parts; pick best
//        var best: (score: Int, parts: [MaterialPart], line: String)? = nil
//
//        for line in candidates {
//            let parts = extractParts(from: line)
//            let score = scoreLine(line, parts: parts)
//            if let b = best {
//                if score > b.score { best = (score, parts, line) }
//            } else {
//                best = (score, parts, line)
//            }
//        }
//
//        guard let bestPick = best, !bestPick.parts.isEmpty else {
//            return FabricParseResult(parts: [], confidence: .low, matchedLine: candidates.first)
//        }
//
//        // 3) confidence
//        let conf: ParseConfidence
//        if bestPick.parts.count == 1, bestPick.parts[0].percent == 100 {
//            conf = .high
//        } else if !bestPick.parts.isEmpty {
//            conf = .medium
//        } else {
//            conf = .low
//        }
//
//        return FabricParseResult(parts: bestPick.parts, confidence: conf, matchedLine: bestPick.line)
//    }

    // MARK: - Helpers

    private static func normalizeLine(_ s: String) -> String {
        var t = s.lowercased()

        // Replace common OCR bullets / punctuation with spaces
        t = t.replacingOccurrences(of: "•", with: " ")
        t = t.replacingOccurrences(of: "»", with: " ")
        t = t.replacingOccurrences(of: "«", with: " ")
        t = t.replacingOccurrences(of: "=", with: " ")
        t = t.replacingOccurrences(of: "/", with: " ")

        // Collapse whitespace
        t = t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsAnyFiberAlias(_ line: String) -> Bool {
        // quick check: does the line contain any alias token
        for alias in aliasToCanonical.keys {
            if line.contains(alias) { return true }
        }
        return false
    }

    private static func normalizeDocument(_ s: String) -> String {
        var t = s.lowercased()
        t = t.replacingOccurrences(of: "•", with: " ")
        t = t.replacingOccurrences(of: "»", with: " ")
        t = t.replacingOccurrences(of: "«", with: " ")
        t = t.replacingOccurrences(of: "=", with: " ")
        t = t.replacingOccurrences(of: "/", with: " ")
        // turn newlines into spaces so pairs can form across lines
        t = t.replacingOccurrences(of: "\n", with: " ")
        // collapse whitespace
        t = t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }


//    private static func extractParts(from line: String) -> [MaterialPart] {
//        // Matches patterns like:
//        // 100% cotton
//        // 60 % polyester
//        // 40% algodao
//        let pattern = #"(?:^|\s)(\d{1,3})\s*%?\s*([a-záàâãäåçéèêëíìîïñóòôõöúùûüýÿ]+)"#
//        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
//
//        let ns = line as NSString
//        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: ns.length))
//
//        var parts: [MaterialPart] = []
//        for m in matches {
//            guard m.numberOfRanges >= 3 else { continue }
//            let pctStr = ns.substring(with: m.range(at: 1))
//            let word = ns.substring(with: m.range(at: 2))
//
//            guard let pct = Int(pctStr), (0...100).contains(pct) else { continue }
//
//            // Map alias -> canonical (if unknown, skip)
//            if let canonical = aliasToCanonical[word] {
//                parts.append(MaterialPart(material: canonical, percent: pct))
//            }
//        }
//
//        // Dedup if OCR repeats the same thing
//        parts = Array(Set(parts)).sorted { $0.percent > $1.percent }
//        return parts
//    }
//
//    private static func scoreLine(_ line: String, parts: [MaterialPart]) -> Int {
//        var score = 0
//
//        // Reward percent presence
//        if line.contains("%") { score += 2 }
//
//        // Reward having extracted parts
//        score += parts.count * 3
//
//        // Reward clean “100% single fiber”
//        if parts.count == 1, parts.first?.percent == 100 { score += 10 }
//
//        // Penalize very long noisy lines (addresses etc.)
//        if line.count > 40 { score -= 2 }
//        if line.range(of: #"\b\d{3,}\b"#, options: .regularExpression) != nil { score -= 1 } // postal codes etc.
//
//        return score
//    }
    
    private static func extractPartsFromDocument(_ text: String) -> [MaterialPart] {
        // We'll match either:
        //  (A) 100% ... cotton
        //  (B) cotton ... 100%
        //
        // Guardrail: only accept if the gap between percent and fiber is <= maxGap characters.
        let maxGap = 30

        var parts: [MaterialPart] = []

        // Precompute all alias occurrences (so we can look up canonical)
        let aliases = Array(aliasToCanonical.keys)

        // 1) Find all percent occurrences
        let percentRegex = try! NSRegularExpression(pattern: #"\b(\d{1,3})\s*%"#, options: [])
        let ns = text as NSString
        let percentMatches = percentRegex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))

        // 2) For each percent, look around it for any fiber alias within maxGap chars
        for pm in percentMatches {
            let pctStr = ns.substring(with: pm.range(at: 1))
            guard let pct = Int(pctStr), (0...100).contains(pct) else { continue }

            let start = max(0, pm.range.location - maxGap)
            let end = min(ns.length, pm.range.location + pm.range.length + maxGap)
            let windowRange = NSRange(location: start, length: end - start)
            let window = ns.substring(with: windowRange)

            // Find any alias in the window
            if let alias = aliases.first(where: { window.contains($0) }),
               let canonical = aliasToCanonical[alias] {
                parts.append(MaterialPart(material: canonical, percent: pct))
            }
        }

        return parts
    }
}
