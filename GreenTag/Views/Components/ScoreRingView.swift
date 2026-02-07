import SwiftUI

struct ScoreRingView: View {
    let score: Int
    var size: CGFloat = 200
    var strokeWidth: CGFloat = 8

    @State private var animatedProgress: CGFloat = 0
    @State private var displayedScore: Int = 0

    private var verdict: Verdict { Verdict.from(score: score) }
    private var color: Color { verdict.color }

    var body: some View {
        VStack(spacing: GTSpacing.lg) {
            // Ring
            ZStack {
                // Background track
                Circle()
                    .stroke(Color(UIColor.systemFill), lineWidth: strokeWidth)

                // Score arc
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))

                // Center label
                VStack(spacing: 2) {
                    Text("\(displayedScore)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(color)
                        .contentTransition(.numericText())

                    Text("out of 100")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gtSecondaryText)
                }
            }
            .frame(width: size, height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Sustainability score: \(score) out of 100, rated \(verdict.rawValue)")

            // Verdict pill + description
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 7, height: 7)

                    Text(verdict.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(color.opacity(0.08))
                .clipShape(Capsule())
                .foregroundColor(verdict == .mixed ? Color(hue: 42/360, saturation: 0.80, brightness: 0.35) : color)

                Text(verdict.description)
                    .font(.subheadline)
                    .foregroundColor(.gtSecondaryText)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) {
                animatedProgress = CGFloat(score) / 100.0
            }
            // Animate the number
            animateScore()
        }
    }

    private func animateScore() {
        let duration: Double = 1.4
        let steps = 60
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            let t = Double(step) / Double(steps)
            // ease-out exponential
            let eased = 1 - pow(2, -10 * t)
            let value = Int(eased * Double(score))

            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                displayedScore = min(value, score)
            }
        }
    }
}

#Preview {
    ScoreRingView(score: 72)
        .padding()
}
