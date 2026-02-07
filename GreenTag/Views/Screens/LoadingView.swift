import SwiftUI

struct LoadingView: View {
    @Binding var screenState: ScreenState

    @State private var shimmerOffset: CGFloat = -1
    @State private var dotScale: [CGFloat] = [0.6, 0.6, 0.6]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Item preview skeleton card
                    skeletonCard {
                        HStack(spacing: GTSpacing.lg) {
                            shimmerRect(width: 72, height: 72, radius: GTSpacing.cardRadius)

                            VStack(alignment: .leading, spacing: 10) {
                                shimmerRect(width: 60, height: 10, radius: 5)
                                shimmerRect(width: 160, height: 14, radius: 7)
                                shimmerRect(width: 140, height: 10, radius: 5)
                            }

                            Spacer()
                        }
                    }
                    .padding(.top, GTSpacing.lg)

                    // Score ring skeleton
                    VStack(spacing: GTSpacing.lg) {
                        shimmerRect(width: 200, height: 200, radius: 100)
                        shimmerRect(width: 80, height: 24, radius: 12)
                        shimmerRect(width: 180, height: 14, radius: 7)
                    }
                    .padding(.vertical, GTSpacing.xxxl + 8)

                    // Analyzing indicator
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(Color.gtPrimary)
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(dotScale[i])
                            }
                        }

                        Text("Analyzing scan\u{2026}")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gtSecondaryText)
                    }
                    .padding(.vertical, GTSpacing.xxl)

                    // Breakdown skeleton card
                    skeletonCard {
                        VStack(spacing: GTSpacing.xxl) {
                            ForEach(0..<4, id: \.self) { _ in
                                VStack(spacing: 10) {
                                    HStack {
                                        shimmerRect(width: 32, height: 32, radius: GTSpacing.iconContainerRadius)
                                        shimmerRect(width: 110, height: 12, radius: 6)
                                        Spacer()
                                        shimmerRect(width: 28, height: 12, radius: 6)
                                    }
                                    shimmerRect(height: 6, radius: 3)
                                    HStack {
                                        shimmerRect(width: 200, height: 10, radius: 5)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, GTSpacing.xl)
                .padding(.bottom, GTSpacing.xxxl)
            }
        }
        .navigationTitle("Scan Results")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gtBackground)
        .onAppear {
            startDotAnimation()
            // Auto-transition to results after simulated analysis
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    screenState = .results
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Analyzing scan, please wait")
    }

    // MARK: - Shimmer Shapes

    @ViewBuilder
    private func shimmerRect(
        width: CGFloat? = nil,
        height: CGFloat,
        radius: CGFloat
    ) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color(UIColor.tertiarySystemFill))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * 200)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1
                }
            }
    }

    @ViewBuilder
    private func skeletonCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    // MARK: - Dot Animation

    private func startDotAnimation() {
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)
            ) {
                dotScale[i] = 1.0
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoadingView(screenState: .constant(.loading))
    }
}
