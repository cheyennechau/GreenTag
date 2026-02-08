import Foundation
import SwiftUI
// MARK: - Material Composition

struct MaterialComposition: Codable, Identifiable {
    public let id = UUID()
    public let material: String
    public let percentage: Int
    private enum CodingKeys: String, CodingKey {
           case material, percentage
       }
}

// MARK: - Breakdown Category

struct BreakdownCategory: Codable,Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Int
    public let explanation: String
    public let color: String
    public let sfSymbol: String

    private enum CodingKeys: String, CodingKey {
        case label, value, explanation, color, sfSymbol
    }
}


// MARK: - Biodegradation

struct BiodegradationComparison: Identifiable, Codable {
    public let id = UUID()
    public let label: String
    public let time: String
    public let isSynthetic: Bool

    // exclude id from Codable synthesis
    private enum CodingKeys: String, CodingKey {
        case label, time, isSynthetic
    }
}

struct BiodegradationData: Codable {
    public let rangeLow: String
    public let rangeHigh: String
    public let positionPercent: Double
    public let hasSynthetics: Bool
    public let syntheticWarning: String?
    public let comparisons: [BiodegradationComparison]
}

struct AssumptionEnvironment: Identifiable {
    public let id = UUID()
    public let name: String
    public let note: String

    private enum CodingKeys: String, CodingKey {
        case name, note
    }
}

// MARK: - Certification

struct Certification: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let verified: Bool

    private enum CodingKeys: String, CodingKey {
        case name, verified
    }
}

// MARK: - Compare Item

struct CompareItem: Identifiable {
    public let id = UUID()
    public let brand: String
    public let item: String
    public let score: Int
    public let materials: String
    public let breakdown: [BreakdownSimple]
    public let biodegRange: String

    private enum CodingKeys: String, CodingKey {
        case brand, item, score, materials, breakdown, biodegRange
    }
}

struct BreakdownSimple: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Int

    private enum CodingKeys: String, CodingKey {
        case label, value
    }
}

// MARK: - Complete Scan Result

struct ScanResult: Codable {
    public let brand: String
    public let item: String
    public let materials: [MaterialComposition]
    public let score: Int
    public let confidence: ConfidenceLevel
    public let breakdown: [BreakdownCategory]
    public let biodegradation: BiodegradationData
    public let whyThisScore: [String]
    public let certifications: [Certification]
}

// MARK: - Screen State

enum ScreenState: Equatable {
    case scan
    case loading
    case error
    case results
}
enum ConfidenceLevel: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var activeBars: Int {
           switch self {
           case .high: return 3
           case .medium: return 2
           case .low: return 1
           }
       }

       var color: Color {
           switch self {
           case .high: return .gtGood
           case .medium: return .gtMixed
           case .low: return .gtAvoid
           }
       }

       var label: String {
           "\(rawValue) confidence"
       }
}
// MARK: - Sample Data

enum SampleData {

    static let result = ScanResult(
        brand: "EVERLANE",
        item: "The Organic Cotton Crew",
        materials: [
            MaterialComposition(material: "Cotton", percentage: 60),
            MaterialComposition(material: "Polyester", percentage: 35),
            MaterialComposition(material: "Elastane", percentage: 5),
        ],
        score: 72,
        confidence: .high,
        breakdown: [
            BreakdownCategory(
                label: "Material Safety",
                value: 82,
                explanation: "Majority organic cotton with low chemical treatment risk",
                color: "good",
                sfSymbol: "shield.checkered"
            ),
            BreakdownCategory(
                label: "Environmental Impact",
                value: 65,
                explanation: "Polyester blend raises water usage and microplastic concerns",
                color: "mixed",
                sfSymbol: "leaf.arrow.triangle.circlepath"
            ),
            BreakdownCategory(
                label: "Social Responsibility",
                value: 78,
                explanation: "Fair Trade certified factory with published labor audits",
                color: "good",
                sfSymbol: "person.2"
            ),
            BreakdownCategory(
                label: "Durability & Lifespan",
                value: 63,
                explanation: "Medium-weight knit; expect 2\u{2013}3 years with regular washing",
                color: "mixed",
                sfSymbol: "clock.arrow.circlepath"
            ),
        ],
        biodegradation: BiodegradationData(
            rangeLow: "5 years",
            rangeHigh: "40 years",
            positionPercent: 38,
            hasSynthetics: true,
            syntheticWarning: "35% polyester will persist in the environment for decades, shedding microplastics with each wash cycle.",
            comparisons: [
                BiodegradationComparison(label: "Apple core", time: "2 months", isSynthetic: false),
                BiodegradationComparison(label: "Cotton tee", time: "6 months", isSynthetic: false),
                BiodegradationComparison(label: "Nylon jacket", time: "30\u{2013}40 yr", isSynthetic: true),
                BiodegradationComparison(label: "Plastic bottle", time: "450 yr", isSynthetic: true),
            ]
        ),
        whyThisScore: [
            "60% organic cotton is above average for fast fashion, but the polyester blend lowers the overall score.",
            "GOTS-certified cotton ensures reduced pesticide and chemical use during growing.",
            "Polyester component contributes to microplastic shedding during washing cycles.",
            "Factory holds Fair Trade certification with transparent wage reporting.",
            "No OEKO-TEX 100 label detected \u{2014} harmful substance testing is unverified.",
        ],
        certifications: [
            Certification(name: "GOTS", verified: true),
            Certification(name: "Fair Trade", verified: true),
            Certification(name: "OEKO-TEX", verified: false),
            Certification(name: "Bluesign", verified: false),
        ]
    )

    static let compareItemB = CompareItem(
        brand: "H&M",
        item: "Basic Cotton T-Shirt",
        score: 48,
        materials: "100% conventional cotton",
        breakdown: [
            BreakdownSimple(label: "Material Safety", value: 55),
            BreakdownSimple(label: "Environmental Impact", value: 42),
            BreakdownSimple(label: "Social Responsibility", value: 50),
            BreakdownSimple(label: "Durability & Lifespan", value: 45),
        ],
        biodegRange: "1\u{2013}6 months"
    )

    static let assumptions: [AssumptionEnvironment] = [
        AssumptionEnvironment(name: "Landfill", note: "Slow, anaerobic. Can take 2\u{2013}5\u{00D7} longer than composting."),
        AssumptionEnvironment(name: "Compost", note: "Fastest for natural fibers. Requires industrial facility."),
        AssumptionEnvironment(name: "Marine", note: "Extremely slow for synthetics. Microplastic risk."),
    ]
}
