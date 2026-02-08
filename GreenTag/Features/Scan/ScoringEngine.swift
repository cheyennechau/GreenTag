//
//  ScoringEngine.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import Foundation

enum ScoringEngine {
    enum GreenTagVerdict: String {
        case good = "Good"
        case mixed = "Mixed"
        case avoid = "Avoid"
    }

    struct BiodegradationRange {
        let minMonths: Int
        let maxMonths: Int
    }

    struct ScoreOutput {
        let overall: Int
        let verdict: GreenTagVerdict

        let biodegMajority: BiodegradationRange
        let biodegResidual: BiodegradationRange?

        let syntheticWarning: Bool

        // Back-compat so ScanCoordinator doesn't break
        var biodegradation: BiodegradationRange { biodegMajority }
    }

    // Fiber base scores (0–100) for materials scoring
    // keys must match FabricParser outputs
    private static let fiberScore: [String: Int] = [
        "organic_cotton": 82,
        "cotton": 78,
        "linen": 88,
        "hemp": 90,
        "wool": 75,
        "cashmere": 72,
        "silk": 72,
        "viscose": 65,
        "bamboo_viscose": 60,
        "polyester": 30,
        "recycled_polyester": 38,
        "nylon": 25,
        "recycled_nylon": 32,
        "acrylic": 15,
        "elastane": 10,
        "polypropylene": 20,
        "polyurethane": 12,
        "acetate": 55,
        "leather": 40,
        "faux_leather": 10
    ]

    // Biodegradation min/max ranges in months
    private static let biodegMonths: [String: (min: Int, max: Int)] = [
        "organic_cotton": (2, 6),
        "cotton": (2, 6),
        "linen": (1, 6),
        "hemp": (1, 6),
        "viscose": (2, 8),
        "bamboo_viscose": (2, 10),
        "silk": (6, 24),
        "wool": (12, 60),
        "cashmere": (12, 60),
        "acetate": (6, 36),

        // synthetics = “very long” (hackathon-safe)
        "polyester": (240, 2400),
        "recycled_polyester": (240, 2400),
        "nylon": (240, 2400),
        "recycled_nylon": (240, 2400),
        "acrylic": (240, 2400),
        "elastane": (240, 2400),
        "polypropylene": (240, 2400),
        "polyurethane": (240, 2400),
        "faux_leather": (240, 2400),

        // leather varies wildly; keep broad
        "leather": (60, 600)
    ]

    // Synthetic set for warning + biodeg weighting
    private static let syntheticFibers: Set<String> = [
        "polyester", "recycled_polyester",
        "nylon", "recycled_nylon",
        "acrylic", "elastane",
        "polypropylene", "polyurethane",
        "faux_leather"
    ]

    // Weights for the weighted average score; hardcoded for now
    private static let wMaterials = 0.45
    private static let wDurability = 0.15
    private static let wMicroplastics = 0.25
    private static let wBiodeg = 0.15
    private static let wCerts = 0.00

    static func score(parts: [MaterialPart]) -> ScoreOutput {
        // Normalize % total if OCR slightly off
        let total = max(1, parts.map(\.percent).reduce(0, +))

        let syntheticPct = parts
            .filter { syntheticFibers.contains($0.material) }
            .map(\.percent)
            .reduce(0, +)

        // Synthetic warning flag
        let syntheticWarning = syntheticPct >= 30

        // materials score = blend-weighted fiberScore
        let materials = blendWeighted(parts: parts, total: total, table: fiberScore, defaultValue: 45)

        // 2) durability score = simple penalties/bonuses (for material choice)
        var durability = 74
        if parts.count >= 3 { durability -= 8 }

        if let elast = parts.first(where: { $0.material == "elastane" }) {
            if elast.percent >= 6 { durability -= 6 }
            else if elast.percent >= 2 { durability += 1 }
        }

        if syntheticPct == 0 {
            durability += 4
        }

        durability = clamp(durability)

        // microplastics score = simple function of synthetic %
        var microplastics = Int(round(100.0 - Double(syntheticPct) * 1.2))
        microplastics = clamp(microplastics)

        // certifications score = neutral baseline until you detect certs
        let certs = 50

        // biodegradation majority/residual + biodeg score
        let (majority, residual) = biodegradationMajorityAndResidual(parts: parts, total: total)

        var biodeg = biodegScore(majority)
        if residual != nil {
            biodeg -= 12
        }
        biodeg = clamp(biodeg)

        // weighted average overall
        let overallDouble =
            wMaterials * Double(materials) +
            wDurability * Double(durability) +
            wMicroplastics * Double(microplastics) +
            wBiodeg * Double(biodeg) +
            wCerts * Double(certs)

        let overall = clamp(Int(round(overallDouble)))

        // verdict mapping
        let verdict: GreenTagVerdict = (overall >= 80) ? .good : (overall >= 50) ? .mixed : .avoid

        return ScoreOutput(
            overall: overall,
            verdict: verdict,
            biodegMajority: majority,
            biodegResidual: residual,
            syntheticWarning: syntheticWarning
        )
    }

    // MARK: - Helpers

    private static func blendWeighted(parts: [MaterialPart], total: Int, table: [String: Int], defaultValue: Int) -> Int {
        var acc = 0.0
        for p in parts {
            let value = table[p.material] ?? defaultValue
            acc += (Double(p.percent) / Double(total)) * Double(value)
        }
        return clamp(Int(round(acc)))
    }

    private static func biodegradationMajorityAndResidual(parts: [MaterialPart], total: Int)
    -> (majority: BiodegradationRange, residual: BiodegradationRange?) {

        let syntheticPct = parts
            .filter { syntheticFibers.contains($0.material) }
            .map(\.percent)
            .reduce(0, +)

        let bioParts = parts.filter { !syntheticFibers.contains($0.material) }
        let bioPct = bioParts.map(\.percent).reduce(0, +)

        // Majority: if mostly biodegradable, estimate decomposition time for that portion
        if bioPct > 0 {
            let bioTotal = max(1, bioPct)
            var minAcc = 0.0
            var maxAcc = 0.0

            for p in bioParts {
                let r = biodegMonths[p.material] ?? (min: 120, max: 1200)
                let w = Double(p.percent) / Double(bioTotal)
                minAcc += w * Double(r.min)
                maxAcc += w * Double(r.max)
            }

            let majority = BiodegradationRange(
                minMonths: max(1, Int(round(minAcc))),
                maxMonths: max(1, Int(round(maxAcc)))
            )

            // Residual: if any synthetic content exists, it doesn’t “fully biodegrade”
            let residual: BiodegradationRange? = (syntheticPct > 0)
                ? BiodegradationRange(minMonths: 240, maxMonths: 2400) // or compute from synthetic blend
                : nil

            return (majority, residual)
        }

        // If no biodegradable content, everything is “residual”
        return (
            BiodegradationRange(minMonths: 240, maxMonths: 2400),
            BiodegradationRange(minMonths: 240, maxMonths: 2400)
        )
    }

    private static func clamp(_ x: Int) -> Int {
        min(100, max(0, x))
    }
    
    private static func biodegScore(_ majority: BiodegradationRange) -> Int {
        switch majority.maxMonths {
        case ...6: return 95      // fast biodegradation
        case 7...12: return 88
        case 13...24: return 78
        case 25...60: return 62
        case 61...120: return 45
        default: return 30
        }
    }
}
