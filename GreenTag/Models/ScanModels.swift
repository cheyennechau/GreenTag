import Foundation

// MARK: - Material Composition

struct MaterialComposition: Identifiable {
    let id = UUID()
    let material: String
    let percentage: Int
}

// MARK: - Breakdown Category

struct BreakdownCategory: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
    let explanation: String
    let color: String      // "good", "mixed", "avoid"
    let sfSymbol: String
}

// MARK: - Biodegradation

struct BiodegradationComparison: Identifiable {
    let id = UUID()
    let label: String
    let time: String
    let isSynthetic: Bool
}

struct BiodegradationData {
    let rangeLow: String
    let rangeHigh: String
    let positionPercent: Double
    let hasSynthetics: Bool
    let syntheticWarning: String?
    let comparisons: [BiodegradationComparison]
}

struct AssumptionEnvironment: Identifiable {
    let id = UUID()
    let name: String
    let note: String
}

// MARK: - Certification

struct Certification: Identifiable {
    let id = UUID()
    let name: String
    let verified: Bool
}

// MARK: - Compare Item

struct CompareItem: Identifiable {
    let id = UUID()
    let brand: String
    let item: String
    let score: Int
    let materials: String
    let breakdown: [BreakdownSimple]
    let biodegRange: String
}

struct BreakdownSimple: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

// MARK: - Complete Scan Result

struct ScanResult {
    let brand: String
    let item: String
    let materials: [MaterialComposition]
    let score: Int
    let confidence: ConfidenceLevel
    let breakdown: [BreakdownCategory]
    let biodegradation: BiodegradationData
    let whyThisScore: [String]
    let certifications: [Certification]
}

// MARK: - Screen State

enum ScreenState: Equatable {
    case scan
    case loading
    case error
    case results
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
