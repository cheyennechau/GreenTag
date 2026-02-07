import SwiftUI

struct ResultsView: View {
    let result: ScanResult
    @Binding var screenState: ScreenState

    @State private var showCompare = false
    @State private var whyExpanded = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Item preview card
                    cardSection {
                        ItemPreviewView(
                            brand: result.brand,
                            item: result.item,
                            materials: result.materials
                        )
                    }
                    .padding(.top, GTSpacing.lg)

                    // Score ring + confidence
                    VStack(spacing: 12) {
                        ScoreRingView(score: result.score)
                        ConfidenceIndicatorView(level: result.confidence)
                    }
                    .padding(.vertical, GTSpacing.xxxl + 8)

                    // Breakdown card
                    cardSection {
                        VStack(alignment: .leading, spacing: GTSpacing.xxl) {
                            Text("Breakdown")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.gtForeground)

                            ForEach(Array(result.breakdown.enumerated()), id: \.element.id) { index, category in
                                BreakdownBarView(
                                    category: category,
                                    delay: Double(index) * 0.1
                                )
                            }
                        }
                    }

                    // Biodegradation card
                    cardSection {
                        BiodegradationTimelineView(data: result.biodegradation)
                    }
                    .padding(.top, GTSpacing.sm)

                    // Why this score? accordion card
                    cardSection {
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    whyExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Why this score?")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gtForeground)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gtSecondaryText)
                                        .rotationEffect(.degrees(whyExpanded ? 180 : 0))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Why this score? \(whyExpanded ? "Collapse" : "Expand")")

                            if whyExpanded {
                                VStack(alignment: .leading, spacing: GTSpacing.lg) {
                                    Divider()
                                        .padding(.top, GTSpacing.md)

                                    // Bullet reasons
                                    ForEach(result.whyThisScore, id: \.self) { reason in
                                        HStack(alignment: .top, spacing: 12) {
                                            Circle()
                                                .fill(Color.gtTertiaryText)
                                                .frame(width: 5, height: 5)
                                                .padding(.top, 7)

                                            Text(reason)
                                                .font(.subheadline)
                                                .foregroundColor(.gtForeground)
                                                .lineSpacing(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }

                                    // Certifications
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("DETECTED CERTIFICATIONS")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gtSecondaryText)
                                            .tracking(0.8)

                                        FlowLayout(spacing: 8) {
                                            ForEach(result.certifications) { cert in
                                                CertificationChipView(certification: cert)
                                            }
                                        }
                                    }
                                    .padding(.top, GTSpacing.sm)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.top, GTSpacing.sm)
                }
                .padding(.horizontal, GTSpacing.xl)
                .padding(.bottom, 120) // Clear sticky bar
            }

            // Sticky bottom actions
            StickyActionsView(
                onCompare: { showCompare = true },
                onBack: { screenState = .scan }
            )
        }
        .navigationTitle("Scan Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    screenState = .scan
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gtPrimary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    screenState = .error
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.gtPrimary)
                }
            }
        }
        .sheet(isPresented: $showCompare) {
            CompareSheetView(
                itemA: compareItemA,
                itemB: SampleData.compareItemB
            )
        }
        .background(Color.gtBackground)
    }

    // MARK: - Card helper

    @ViewBuilder
    private func cardSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            content()
        }
        .padding(GTSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                .fill(Color.gtCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                .strokeBorder(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private var compareItemA: CompareItem {
        CompareItem(
            brand: result.brand,
            item: result.item,
            score: result.score,
            materials: result.materials.map { "\($0.percentage)% \($0.material)" }.joined(separator: ", "),
            breakdown: result.breakdown.map { BreakdownSimple(label: $0.label, value: $0.value) },
            biodegRange: "\(result.biodegradation.rangeLow) \u{2013} \(result.biodegradation.rangeHigh)"
        )
    }
}

#Preview {
    NavigationStack {
        ResultsView(result: SampleData.result, screenState: .constant(.results))
    }
}
