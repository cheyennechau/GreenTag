import SwiftUI

struct BiodegradationTimelineView: View {
    let data: BiodegradationData

    @State private var showAssumptions = false
    @State private var animatedPosition: CGFloat = 0

    private let zones = ["Weeks", "Months", "Years", "Decades", "Centuries"]
    private let zonePositions: [CGFloat] = [0.06, 0.18, 0.38, 0.62, 0.88]

    var body: some View {
        VStack(alignment: .leading, spacing: GTSpacing.xl) {
            // Header
            headerRow

            // Range label
            rangeLabel

            // Time-to-nature meter track
            meterTrack

            // Synthetic warning
            if data.hasSynthetics, let warning = data.syntheticWarning {
                syntheticWarningView(warning)
            }

            // Assumptions dropdown
            if showAssumptions {
                assumptionsCard
            }

            // In perspective
            perspectiveSection
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Time to Nature")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.gtForeground)

                Text("How long until this item returns to the earth")
                    .font(.caption)
                    .foregroundColor(.gtSecondaryText)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showAssumptions.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .medium))

                    Text("Assumptions")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    showAssumptions
                        ? Color.gtPrimary.opacity(0.1)
                        : Color(UIColor.tertiarySystemFill)
                )
                .foregroundColor(
                    showAssumptions
                        ? .gtPrimary
                        : .gtSecondaryText
                )
                .clipShape(Capsule())
            }
            .accessibilityLabel("View assumptions about biodegradation estimates")
        }
    }

    // MARK: - Range Label

    private var rangeLabel: some View {
        VStack(spacing: 2) {
            Text("\(data.rangeLow) \u{2013} \(data.rangeHigh)")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(.gtForeground)
                .monospacedDigit()

            Text("estimated range")
                .font(.caption2)
                .foregroundColor(.gtSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Meter Track

    private var meterTrack: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                let width = geometry.size.width

                ZStack(alignment: .leading) {
                    // Gradient track
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 152/360, saturation: 0.45, brightness: 0.52),
                                    Color(hue: 152/360, saturation: 0.35, brightness: 0.60),
                                    Color(hue: 48/360, saturation: 0.90, brightness: 0.65),
                                    Color(hue: 28/360, saturation: 0.85, brightness: 0.65),
                                    Color(hue: 0/360, saturation: 0.65, brightness: 0.62),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 10)

                    // Inactive overlay
                    let activeEnd = min(width * (animatedPosition + 0.04), width)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gtCard.opacity(0.70))
                        .frame(width: max(0, width - activeEnd), height: 10)
                        .offset(x: activeEnd)

                    // Position marker
                    Circle()
                        .fill(Color.gtCard)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.gtForeground, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        .offset(x: width * animatedPosition - 11)
                }
            }
            .frame(height: 22)

            // Zone labels
            GeometryReader { geometry in
                let width = geometry.size.width
                ZStack {
                    ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                        Text(zone)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.gtTertiaryText)
                            .position(
                                x: width * zonePositions[index],
                                y: 8
                            )
                    }
                }
            }
            .frame(height: 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedPosition = data.positionPercent / 100.0
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Biodegradation timeline. Estimated range: \(data.rangeLow) to \(data.rangeHigh)")
    }

    // MARK: - Synthetic Warning

    private func syntheticWarningView(_ warning: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.gtMixed.opacity(0.15))
                    .frame(width: 28, height: 28)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hue: 42/360, saturation: 0.80, brightness: 0.38))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Synthetic fibers detected")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gtWarningText)

                Text(warning)
                    .font(.caption)
                    .foregroundColor(.gtWarningBody)
                    .lineSpacing(2)
            }
        }
        .padding(GTSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                .fill(Color.gtWarningBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                .strokeBorder(Color.gtWarningBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Assumptions Card

    private var assumptionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VARIES BY ENVIRONMENT")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.gtSecondaryText)
                .tracking(0.8)

            ForEach(SampleData.assumptions) { env in
                VStack(alignment: .leading, spacing: 2) {
                    Text(env.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gtForeground)

                    Text(env.note)
                        .font(.caption)
                        .foregroundColor(.gtSecondaryText)
                        .lineSpacing(1)
                }
            }

            Divider()

            Text("Estimates based on landfill conditions. Actual time varies significantly by disposal method.")
                .font(.caption2)
                .foregroundColor(.gtTertiaryText)
                .lineSpacing(1)
        }
        .padding(GTSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Perspective Section

    private var perspectiveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("IN PERSPECTIVE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.gtSecondaryText)
                .tracking(0.8)

            FlowLayout(spacing: 8) {
                ForEach(data.comparisons) { comp in
                    HStack(spacing: 6) {
                        Text(comp.label)
                            .fontWeight(.medium)
                            .foregroundColor(
                                comp.isSynthetic
                                    ? Color(hue: 0, saturation: 0.55, brightness: 0.42)
                                    : .gtForeground
                            )

                        Text(comp.time)
                            .foregroundColor(
                                comp.isSynthetic
                                    ? Color(hue: 0, saturation: 0.40, brightness: 0.50)
                                    : .gtSecondaryText
                            )
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        comp.isSynthetic
                            ? Color.gtAvoid.opacity(0.06)
                            : Color(UIColor.tertiarySystemFill)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                comp.isSynthetic
                                    ? Color.gtAvoid.opacity(0.12)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }
}

// MARK: - Flow Layout (wrapping chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

#Preview {
    BiodegradationTimelineView(data: SampleData.result.biodegradation)
        .padding()
}
