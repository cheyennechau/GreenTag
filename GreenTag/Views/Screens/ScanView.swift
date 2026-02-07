import SwiftUI

struct ScanView: View {
    @Binding var screenState: ScreenState

    @State private var scanLineOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Dark camera background
            Color(hue: 0, saturation: 0, brightness: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.top, 8)

                Spacer()

                // Viewfinder
                viewfinder
                    .padding(.horizontal, GTSpacing.xxxl + 8)

                // Instruction
                Text("Align the clothing tag within the frame.\nHold steady for best results.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, GTSpacing.xxxl)

                Spacer()

                // Bottom controls
                bottomControls
                    .padding(.bottom, GTSpacing.xxxl)
            }
        }
        .statusBarHidden()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                scanLineOffset = 1
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                // Close
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close scanner")

            Spacer()

            Button {
                // Flash toggle
            } label: {
                Image(systemName: "bolt")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Toggle flash")
        }
        .padding(.horizontal, GTSpacing.xl)
    }

    // MARK: - Viewfinder

    private var viewfinder: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = w * (4.0 / 3.0)
            let bracketLen: CGFloat = 32
            let bracketWeight: CGFloat = 3

            ZStack {
                // Corner brackets
                Group {
                    // Top left
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .position(x: bracketLen / 2, y: bracketLen / 2)

                    // Top right
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .rotationEffect(.degrees(90))
                        .position(x: w - bracketLen / 2, y: bracketLen / 2)

                    // Bottom left
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .rotationEffect(.degrees(-90))
                        .position(x: bracketLen / 2, y: h - bracketLen / 2)

                    // Bottom right
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .rotationEffect(.degrees(180))
                        .position(x: w - bracketLen / 2, y: h - bracketLen / 2)
                }

                // Scan line
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.gtPrimary.opacity(0.8))
                    .frame(width: w - 32, height: 2)
                    .shadow(color: Color.gtPrimary.opacity(0.5), radius: 8)
                    .offset(y: -h / 2 + 16 + (h - 32) * scanLineOffset)

                // Center tag hint
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.3))

                    Text("Position tag here")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
    }

    // MARK: - Corner Bracket

    private func cornerBracket(width: CGFloat, height: CGFloat, lineWidth: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: -width / 2, y: -height / 2 + height / 3))
            path.addLine(to: CGPoint(x: -width / 2, y: -height / 2))
            path.addLine(to: CGPoint(x: -width / 2 + width / 3, y: -height / 2))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: GTSpacing.xl) {
            // Capture button
            Button {
                screenState = .loading
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)

                    Circle()
                        .strokeBorder(Color.black.opacity(0.1), lineWidth: 2.5)
                        .frame(width: 66, height: 66)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black.opacity(0.85))
                }
            }
            .accessibilityLabel("Capture tag photo")

            // Secondary actions
            HStack(spacing: GTSpacing.xxl) {
                Button("Choose photo") {}
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.5))

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 12)

                Button("Enter manually") {}
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

#Preview {
    ScanView(screenState: .constant(.scan))
}
