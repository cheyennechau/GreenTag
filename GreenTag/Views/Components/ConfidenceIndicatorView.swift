import SwiftUI

struct ConfidenceIndicatorView: View {
    let level: ConfidenceLevel

    var body: some View {
        // extract commonly-used values to help the compiler
                let activeBars = level.activeBars
                let barColor = level.color
                let labelText = level.label
        HStack(spacing: 6) {
            // Signal bars
            HStack(alignment: .bottom, spacing: 2.5) {
                ForEach(1...3, id: \.self) { bar in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            bar <= level.activeBars
                                ? level.color
                                : level.color.opacity(0.2)
                        )
                        .frame(width: 3, height: CGFloat(4 + bar * 3))
                }
            }
            .frame(height: 13)

            Text(level.label)
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(0.3)
        }
        .foregroundColor(level.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(level.color.opacity(0.08))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Detection accuracy: \(level.label)")
    }
}

#Preview {
    VStack(spacing: 12) {
        ConfidenceIndicatorView(level: .high)
        ConfidenceIndicatorView(level: .medium)
        ConfidenceIndicatorView(level: .low)
    }
    .padding()
}
