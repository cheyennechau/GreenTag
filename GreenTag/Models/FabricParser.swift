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

        // 1) Get raw parts (positional if possible, otherwise document extraction)
        let rawParts: [MaterialPart]
        if let positional = tryPositionalPairing(normalized), !positional.isEmpty {
            rawParts = positional
        } else {
            rawParts = extractPartsFromDocument(normalized)
        }

        guard !rawParts.isEmpty else {
            return FabricParseResult(parts: [], confidence: .low, matchedLine: nil)
        }

        // 2) Dedupe exact duplicates
        let deduped = Array(Set(rawParts))

        // 3) Filter bogus extras by choosing subset closest to 100
        let filtered = bestSubsetNear100(deduped)

        // 4) Combine same fiber (sum percents)
        let merged = combineSameFiber(filtered)

        // 5) Confidence from how “complete” total looks
        let total = merged.map(\.percent).reduce(0, +)
        let confidence: ParseConfidence =
            (merged.count == 1 && total == 100) ? .high :
            (abs(total - 100) <= 3) ? .medium : .low

        return FabricParseResult(parts: merged, confidence: confidence, matchedLine: nil)
    }

    // Helpers
    
    private static func combineSameFiber(_ parts: [MaterialPart]) -> [MaterialPart] {
        let grouped = Dictionary(grouping: parts, by: { $0.material })
        let merged = grouped.map { (material, items) in
            MaterialPart(material: material, percent: items.map(\.percent).reduce(0, +))
        }
        return merged.sorted { $0.percent > $1.percent }
    }

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
    
    private static func tryPositionalPairing(_ text: String) -> [MaterialPart]? {
        let ns = text as NSString

        // 1) extract percentages in order
        let percentRegex = try! NSRegularExpression(pattern: #"\b(\d{1,3})\s*%"#, options: [])
        let percentMatches = percentRegex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
        let percents = percentMatches.compactMap {
            Int(ns.substring(with: $0.range(at: 1)))
        }

        // 2) extract fibers in order
        let fibers = aliasToCanonical
            .keys
            .compactMap { alias in
                text.contains(alias) ? alias : nil
            }

        // 3) strict positional condition
        guard
            percents.count > 1,
            percents.count == fibers.count,
            percentMatches.last!.range.location < text.range(of: fibers.first!)!.lowerBound.utf16Offset(in: text)
        else {
            return nil
        }

        // 4) zip by index
        return zip(percents, fibers).compactMap { pct, alias in
            guard let canonical = aliasToCanonical[alias] else { return nil }
            return MaterialPart(material: canonical, percent: pct)
        }
    }
    
    private static func extractPartsFromDocument(_ text: String) -> [MaterialPart] {
        let maxForward = 40   // how far AFTER the % to search
        let maxBackward = 20  // how far BEFORE the % to search (fallback)

        var parts: [MaterialPart] = []

        let percentRegex = try! NSRegularExpression(pattern: #"\b(\d{1,3})\s*%"#, options: [])
        let ns = text as NSString
        let percentMatches = percentRegex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))

        // Sort aliases longest-first so "polyester" beats "ester" etc.
        let aliases = aliasToCanonical.keys.sorted { $0.count > $1.count }

        for pm in percentMatches {
            let pctStr = ns.substring(with: pm.range(at: 1))
            guard let pct = Int(pctStr), (0...100).contains(pct) else { continue }

            let pctLoc = pm.range.location

            // 1) Look forward first (most common on tags)
            let fStart = pctLoc
            let fEnd = min(ns.length, pctLoc + pm.range.length + maxForward)
            let fRange = NSRange(location: fStart, length: fEnd - fStart)
            let forward = ns.substring(with: fRange)

            if let (alias, _) = firstAliasOccurrence(in: forward, aliases: aliases),
               let canonical = aliasToCanonical[alias] {
                parts.append(MaterialPart(material: canonical, percent: pct))
                continue
            }

            // 2) Fallback: look backward
            let bStart = max(0, pctLoc - maxBackward)
            let bRange = NSRange(location: bStart, length: pctLoc - bStart)
            let backward = ns.substring(with: bRange)

            if let (alias, _) = lastAliasOccurrence(in: backward, aliases: aliases),
               let canonical = aliasToCanonical[alias] {
                parts.append(MaterialPart(material: canonical, percent: pct))
                continue
            }
        }

        return parts
    }

    private static func firstAliasOccurrence(in s: String, aliases: [String]) -> (String, Int)? {
        var best: (alias: String, idx: Int)? = nil
        for a in aliases {
            if let r = s.range(of: a) {
                let idx = r.lowerBound.utf16Offset(in: s)
                if best == nil || idx < best!.idx {
                    best = (a, idx)
                }
            }
        }
        return best
    }

    private static func lastAliasOccurrence(in s: String, aliases: [String]) -> (String, Int)? {
        var best: (alias: String, idx: Int)? = nil
        for a in aliases {
            if let r = s.range(of: a, options: .backwards) {
                let idx = r.lowerBound.utf16Offset(in: s)
                if best == nil || idx > best!.idx {
                    best = (a, idx)
                }
            }
        }
        return best
    }
    
    private static func bestSubsetNear100(_ parts: [MaterialPart]) -> [MaterialPart] {
        guard parts.count > 1 else { return parts }

        let target = 100
        var best: [MaterialPart] = parts
        var bestDiff = abs(parts.map(\.percent).reduce(0, +) - target)

        // try all non-empty subsets
        let n = parts.count
        for mask in 1..<(1 << n) {
            var subset: [MaterialPart] = []
            subset.reserveCapacity(n)
            var sum = 0

            for i in 0..<n where (mask & (1 << i)) != 0 {
                subset.append(parts[i])
                sum += parts[i].percent
            }

            let diff = abs(sum - target)

            // prefer closer to 100; tie-breaker: fewer items (simpler)
            if diff < bestDiff || (diff == bestDiff && subset.count < best.count) {
                bestDiff = diff
                best = subset
            }

            // perfect match, stop early
            if bestDiff == 0 { break }
        }

        return best.sorted { $0.percent > $1.percent }
    }
}

import Foundation

extension FabricParser {
    /// Parse manual text like "60% cotton, 40% polyester" into MaterialPart[]
    /// Uses the same material key normalization your scoring tables expect.
    static func parseManualParts(_ text: String) -> [MaterialPart] {
        let cleaned = text
            .lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ";", with: " ")
            .replacingOccurrences(of: "%", with: "% ")

        let tokens = cleaned.split(whereSeparator: { $0.isWhitespace }).map(String.init)

        var parts: [MaterialPart] = []
        var i = 0
        while i < tokens.count {
            let t = tokens[i].replacingOccurrences(of: "%", with: "")
            if let pct = Int(t), pct > 0, pct <= 100 {
                let rawMaterial = (i + 1 < tokens.count) ? tokens[i + 1] : ""
                let key = normalizeMaterialKey(rawMaterial)
                if !key.isEmpty {
                    parts.append(MaterialPart(material: key, percent: pct))
                    i += 2
                    continue
                }
            }
            i += 1
        }

        // Fallback: user typed only "cotton" or "polyester"
        if parts.isEmpty {
            let words = tokens.filter { $0.allSatisfy(\.isLetter) }
            if let first = words.first {
                let key = normalizeMaterialKey(first)
                if !key.isEmpty {
                    parts = [MaterialPart(material: key, percent: 100)]
                }
            }
        }

        return mergeDuplicateMaterials(parts)
    }

    /// Map user-friendly names to scoring keys. Expand as you see real inputs.
    private static func normalizeMaterialKey(_ raw: String) -> String {
        let s = raw
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch s {
        case "organic", "organiccotton", "organic-cotton", "organic_cotton":
            return "organic_cotton"
        case "cotton":
            return "cotton"
        case "poly", "polyester":
            return "polyester"
        case "recycledpolyester", "recycled-polyester", "recycled_polyester":
            return "recycled_polyester"
        case "nylon", "polyamide":
            return "nylon"
        case "recyclednylon", "recycled-nylon", "recycled_nylon":
            return "recycled_nylon"
        case "spandex", "elastane":
            return "elastane"
        case "linen":
            return "linen"
        case "hemp":
            return "hemp"
        case "wool":
            return "wool"
        case "cashmere":
            return "cashmere"
        case "silk":
            return "silk"
        case "viscose", "rayon":
            return "viscose"
        case "bamboo", "bamboo_viscose", "bamboo-viscose":
            return "bamboo_viscose"
        case "acrylic":
            return "acrylic"
        case "polypropylene":
            return "polypropylene"
        case "polyurethane":
            return "polyurethane"
        case "acetate":
            return "acetate"
        case "leather":
            return "leather"
        case "fauxleather", "faux-leather", "faux_leather":
            return "faux_leather"
        default:
            // If user typed "cotton/polyester" etc, strip punctuation and try again
            let stripped = s.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            if stripped != s { return normalizeMaterialKey(stripped) }
            return ""
        }
    }

    private static func mergeDuplicateMaterials(_ parts: [MaterialPart]) -> [MaterialPart] {
        var dict: [String: Int] = [:]
        for p in parts {
            dict[p.material, default: 0] += p.percent
        }
        return dict.map { MaterialPart(material: $0.key, percent: $0.value) }
            .sorted { $0.percent > $1.percent }
    }
}
