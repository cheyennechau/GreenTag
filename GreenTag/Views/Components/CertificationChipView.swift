import SwiftUI

struct CertificationChipView: View {
    let certification: Certification

    var body: some View {
        HStack(spacing: 5) {
            if certification.verified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 12))
            }

            Text(certification.name)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            certification.verified
                ? Color.gtPrimary.opacity(0.08)
                : Color(UIColor.tertiarySystemFill)
        )
        .foregroundColor(
            certification.verified
                ? .gtPrimary
                : .gtSecondaryText
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    certification.verified
                        ? Color.gtPrimary.opacity(0.15)
                        : Color(UIColor.separator),
                    lineWidth: 1
                )
        )
        .accessibilityLabel("\(certification.name), \(certification.verified ? "verified" : "not verified")")
    }
}

#Preview {
    HStack {
        CertificationChipView(certification: Certification(name: "GOTS", verified: true))
        CertificationChipView(certification: Certification(name: "OEKO-TEX", verified: false))
    }
    .padding()
}
