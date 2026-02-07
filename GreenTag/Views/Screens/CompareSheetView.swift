import SwiftUI

struct CompareSheetView: View {
    let itemA: CompareItem
    let itemB: CompareItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GTSpacing.xxl) {
                    // Score comparison header
                    scoreComparison
                        .padding(.top, GTSpacing.sm)

                    // Category breakdown
                    categoryBreakdown

                    // Time to nature
                    biodegComparison

                    // Summary
                    summarySection
                }
                .padding(.horizontal, GTSpacing.xl)
                .padding(.bottom, GTSpacing.xxxl)
            }
            .background(Color.gtBackground)
            .navigationTitle("Compare Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray, Color(UIColor.tertiarySystemFill))
                    }
                    .accessibilityLabel("Close comparison")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Score Comparison

    private var scoreComparison: some View {
        HStack(alignment: .top, spacing: GTSpacing.lg) {
            // Item A
            itemColumn(
                brand: itemA.brand,
                name: itemA.item,
                materials: itemA.materials,
                score: itemA.score
            )

            // VS
            Text("vs")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gtTertiaryText)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.top, 48)

            // Item B
            itemColumn(
                brand: itemB.brand,
                name: itemB.item,
                materials: itemB.materials,
                score: itemB.score
            )
        }
    }

    @ViewBuilder
    private func itemColumn(brand: String, name: String, materials: String, score: Int) -> some View {
        VStack(spacing: 12) {
            ScoreRingView(score: score, size: 100, strokeWidth: 5)

            VStack(spacing: 3) {
                Text(brand)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gtSecondaryText)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(name)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.gtForeground)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(materials)
                    .font(.caption2)
                    .foregroundColor(.gtSecondaryText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: GTSpacing.md) {
            Text("CATEGORY BREAKDOWN")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.gtSecondaryText)
                .tracking(0.8)

            VStack(spacing: 0) {
                ForEach(Array(itemA.breakdown.enumerated()), id: \.element.id) { index, cat in
                    if index > 0 { Divider() }

                    statRow(
                        label: cat.label,
                        valueA: cat.value,
                        valueB: itemB.breakdown.indices.contains(index) ? itemB.breakdown[index].value : 0
                    )
                }
            }
            .padding(GTSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                    .fill(Color.gtCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                    .strokeBorder(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
            )
        }
    }

    @ViewBuilder
    private func statRow(label: String, valueA: Int, valueB: Int) -> some View {
        let colorA = scoreColor(valueA)
        let colorB = scoreColor(valueB)
        let better = valueA > valueB ? "A" : (valueB > valueA ? "B" : "tie")

        HStack(spacing: 8) {
            // Value A + bar (reversed)
            HStack(spacing: 6) {
                GeometryReader { geo in
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(colorA)
                            .frame(width: geo.size.width * CGFloat(valueA) / 100.0, height: 5)
                    }
                }
                .frame(height: 5)

                Text("\(valueA)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundColor(better == "A" ? colorA : .gtSecondaryText)
                    .frame(width: 28, alignment: .trailing)
            }

            // Label
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.gtSecondaryText)
                .frame(width: 80)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Value B + bar
            HStack(spacing: 6) {
                Text("\(valueB)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundColor(better == "B" ? colorB : .gtSecondaryText)
                    .frame(width: 28, alignment: .leading)

                GeometryReader { geo in
                    HStack {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(colorB)
                            .frame(width: geo.size.width * CGFloat(valueB) / 100.0, height: 5)
                        Spacer()
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(itemA.brand) \(valueA), \(itemB.brand) \(valueB)")
    }

    // MARK: - Biodeg Comparison

    private var biodegComparison: some View {
        VStack(alignment: .leading, spacing: GTSpacing.md) {
            Text("TIME TO NATURE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.gtSecondaryText)
                .tracking(0.8)

            HStack(spacing: 12) {
                biodegCard(range: itemA.biodegRange, brand: itemA.brand)
                biodegCard(range: itemB.biodegRange, brand: itemB.brand)
            }
        }
    }

    @ViewBuilder
    private func biodegCard(range: String, brand: String) -> some View {
        VStack(spacing: 4) {
            Text(range)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.gtForeground)

            Text(brand)
                .font(.caption2)
                .foregroundColor(.gtSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GTSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                .fill(Color.gtCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                .strokeBorder(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: 6) {
            let diff = abs(itemA.score - itemB.score)
            if itemA.score > itemB.score {
                Text("\(itemA.item) scores \(diff) points higher")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gtForeground)
            } else if itemB.score > itemA.score {
                Text("\(itemB.item) scores \(diff) points higher")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gtForeground)
            } else {
                Text("Both items score equally")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gtForeground)
            }

            Text("based on material safety, environmental impact, and durability")
                .font(.caption)
                .foregroundColor(.gtSecondaryText)
        }
        .multilineTextAlignment(.center)
        .padding(.top, GTSpacing.sm)
    }

    // MARK: - Helpers

    private func scoreColor(_ value: Int) -> Color {
        if value >= 65 { return .gtGood }
        if value >= 35 { return .gtMixed }
        return .gtAvoid
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CompareSheetView(
                itemA: CompareItem(
                    brand: "EVERLANE",
                    item: "The Organic Cotton Crew",
                    score: 72,
                    materials: "60% Cotton, 35% Polyester, 5% Elastane",
                    breakdown: [
                        BreakdownSimple(label: "Material Safety", value: 82),
                        BreakdownSimple(label: "Environmental Impact", value: 65),
                        BreakdownSimple(label: "Social Responsibility", value: 78),
                        BreakdownSimple(label: "Durability & Lifespan", value: 63),
                    ],
                    biodegRange: "5 yr \u{2013} 40 yr"
                ),
                itemB: SampleData.compareItemB
            )
        }
}
