import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary green accent
    static let gtPrimary = Color(hue: 152/360, saturation: 0.45, brightness: 0.36)
    static let gtPrimaryLight = Color(hue: 152/360, saturation: 0.30, brightness: 0.95)

    // Semantic backgrounds
    static let gtBackground = Color(UIColor.systemGroupedBackground)
    static let gtCard = Color(UIColor.secondarySystemGroupedBackground)
    static let gtSecondary = Color(UIColor.tertiarySystemGroupedBackground)

    // Semantic text
    static let gtForeground = Color(UIColor.label)
    static let gtSecondaryText = Color(UIColor.secondaryLabel)
    static let gtTertiaryText = Color(UIColor.tertiaryLabel)

    // Score colors
    static let gtGood = Color(hue: 152/360, saturation: 0.45, brightness: 0.36)
    static let gtMixed = Color(hue: 42/360, saturation: 1.0, brightness: 0.50)
    static let gtAvoid = Color(hue: 0/360, saturation: 0.72, brightness: 0.51)

    // Warning tones
    static let gtWarningBg = Color(hue: 42/360, saturation: 1.0, brightness: 0.96)
    static let gtWarningBorder = Color(hue: 42/360, saturation: 0.60, brightness: 0.88)
    static let gtWarningText = Color(hue: 42/360, saturation: 0.80, brightness: 0.25)
    static let gtWarningBody = Color(hue: 42/360, saturation: 0.50, brightness: 0.35)

    // Separator
    static let gtSeparator = Color(UIColor.separator)
}

// MARK: - Verdict

enum Verdict: String {
    case good = "Good"
    case mixed = "Mixed"
    case avoid = "Avoid"

    var color: Color {
        switch self {
        case .good: return .gtGood
        case .mixed: return .gtMixed
        case .avoid: return .gtAvoid
        }
    }

    var description: String {
        switch self {
        case .good: return "Above average sustainability"
        case .mixed: return "Room for improvement"
        case .avoid: return "Significant concerns found"
        }
    }

    static func from(score: Int) -> Verdict {
        if score >= 65 { return .good }
        if score >= 35 { return .mixed }
        return .avoid
    }
}

// MARK: - Confidence

//enum ConfidenceLevel: String, Codable {
//    case high = "High"
//    case medium = "Medium"
//    case low = "Low"
//
//    var color: Color {
//        switch self {
//        case .high: return .gtGood
//        case .medium: return .gtMixed
//        case .low: return .gtAvoid
//        }
//    }
//
//    var activeBars: Int {
//        switch self {
//        case .high: return 3
//        case .medium: return 2
//        case .low: return 1
//        }
//    }
//
//    var label: String {
//        "\(rawValue) confidence"
//    }
//}

// MARK: - Spacing Constants

enum GTSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let chipRadius: CGFloat = 100
    static let iconContainerSize: CGFloat = 32
    static let iconContainerRadius: CGFloat = 10
}
