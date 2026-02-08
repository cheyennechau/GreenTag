import SwiftUI

struct ItemPreviewView: View {
    let image: UIImage?
    let brand: String
    let item: String
    let materials: [MaterialComposition]

    var body: some View {
        HStack(spacing: GTSpacing.lg) {
            // Photo placeholder
            ZStack {
                RoundedRectangle(cornerRadius: GTSpacing.cardRadius)
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(width: 72, height: 72)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: GTSpacing.cardRadius))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.gtTertiaryText)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(brand)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gtSecondaryText)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(item)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.gtForeground)
                    .lineLimit(1)

                Text(materialsString)
                    .font(.caption)
                    .foregroundColor(.gtSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var materialsString: String {
        materials.map { "\($0.percentage)% \($0.material)" }.joined(separator: ", ")
    }
}

#Preview {
    ItemPreviewView(
        image: nil,
        brand: "EVERLANE",
        item: "The Organic Cotton Crew",
        materials: SampleData.result.materials
    )
    .padding()
}
