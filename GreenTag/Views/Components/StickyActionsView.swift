import SwiftUI

struct StickyActionsView: View {
    var onSave: (() -> Void)?
    var onCompare: (() -> Void)?
    var onImprove: (() -> Void)?
    var onShare: (() -> Void)?
    var onBack: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)

            HStack(spacing: 10) {
                // Save
                actionButton(
                    label: "Save",
                    icon: "bookmark",
                    style: .secondary
                ) { onSave?() }

                // Compare
                actionButton(
                    label: "Compare",
                    icon: "arrow.left.arrow.right",
                    style: .secondary
                ) { onCompare?() }

                // Improve (primary)
                actionButton(
                    label: "Improve",
                    icon: "lightbulb",
                    style: .primary
                ) { onImprove?() }

                // Share (icon only)
                Button {
                    onShare?()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 50, height: 50)
                        .background(Color(UIColor.tertiarySystemFill))
                        .foregroundColor(.gtForeground)
                        .clipShape(RoundedRectangle(cornerRadius: GTSpacing.cardRadius))
                }
                .accessibilityLabel("Share this result")
            }
            .padding(.horizontal, GTSpacing.xl)
            .padding(.top, 12)
            .padding(.bottom, 34) // safe area
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    // MARK: - Button Variants

    private enum ActionButtonStyle { case primary, secondary }

    @ViewBuilder
    private func actionButton(
        label: String,
        icon: String,
        style: ActionButtonStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .frame(height: 50)
            .padding(.horizontal, style == .primary ? 0 : 14)
            .background(
                style == .primary
                    ? AnyShapeStyle(Color.gtPrimary)
                    : AnyShapeStyle(Color(UIColor.tertiarySystemFill))
            )
            .foregroundColor(
                style == .primary
                    ? .white
                    : .gtForeground
            )
            .clipShape(RoundedRectangle(cornerRadius: GTSpacing.cardRadius))
        }
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack {
        Spacer()
        StickyActionsView()
    }
}
