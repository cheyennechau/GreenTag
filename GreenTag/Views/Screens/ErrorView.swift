import SwiftUI

struct ErrorView: View {
    @Binding var screenState: ScreenState

    private let tips: [(icon: String, text: String)] = [
        ("hand.raised", "Hold steady and close to the tag"),
        ("sun.max", "Use natural or bright lighting"),
        ("rectangle.compress.vertical", "Flatten the label with your finger"),
        ("cloud.sun", "Avoid shadows across the text"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: GTSpacing.xxxl) {
                // Error icon
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.gtAvoid.opacity(0.08))
                        .frame(width: 72, height: 72)

                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.gtAvoid)
                }

                // Copy
                VStack(spacing: 8) {
                    Text("Couldn\u{2019}t Read Tag")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gtForeground)

                    Text("We weren\u{2019}t able to recognize the text on this label. Try scanning again with these tips.")
                        .font(.subheadline)
                        .foregroundColor(.gtSecondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 280)
                }

                // Tips card
                VStack(alignment: .leading, spacing: GTSpacing.lg) {
                    Text("TIPS FOR A BETTER SCAN")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gtSecondaryText)
                        .tracking(0.8)

                    ForEach(tips, id: \.text) { tip in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: GTSpacing.iconContainerRadius)
                                    .fill(Color.gtPrimary.opacity(0.08))
                                    .frame(width: GTSpacing.iconContainerSize, height: GTSpacing.iconContainerSize)

                                Image(systemName: tip.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gtPrimary)
                            }

                            Text(tip.text)
                                .font(.subheadline)
                                .foregroundColor(.gtForeground)
                        }
                    }
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
                .frame(maxWidth: 320)

                // Retry button
                Button {
                    screenState = .loading
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Try Again")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: 320)
                    .frame(height: 50)
                    .background(Color.gtPrimary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: GTSpacing.cardRadius))
                }
            }
            .padding(.horizontal, GTSpacing.xxl)

            Spacer()
        }
        .navigationTitle("Scan Results")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gtBackground)
    }
}

#Preview {
    NavigationStack {
        ErrorView(screenState: .constant(.error))
    }
}
