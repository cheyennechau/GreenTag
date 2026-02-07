import SwiftUI

struct BreakdownBarView: View {
    let category: BreakdownCategory
    var delay: Double = 0

    @State private var animatedWidth: CGFloat = 0

    private var barColor: Color {
        switch category.color {
        case "good": return .gtGood
        case "mixed": return .gtMixed
        case "avoid": return .gtAvoid
        default: return .gtSecondaryText
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: icon + label + value
            HStack {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: GTSpacing.iconContainerRadius)
                        .fill(barColor.opacity(0.08))
                        .frame(width: GTSpacing.iconContainerSize, height: GTSpacing.iconContainerSize)

                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gtSecondaryText)
                }

                Text(category.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gtForeground)

                Spacer()

                Text("\(category.value)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundColor(barColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(
                            width: geometry.size.width * animatedWidth,
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            // Explanation
            Text(category.explanation)
                .font(.caption)
                .foregroundColor(.gtSecondaryText)
                .lineSpacing(2)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(delay + 0.4)) {
                animatedWidth = CGFloat(category.value) / 100.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.label): \(category.value) out of 100. \(category.explanation)")
    }
}

#Preview {
    BreakdownBarView(
        category: SampleData.result.breakdown[0]
    )
    .padding()
}
