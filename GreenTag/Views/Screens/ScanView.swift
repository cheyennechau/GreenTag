//
//  ScanView.swift
//  GreenTag
//
//  Created by Bia Shok on 2/7/26.
//

import SwiftUI

// MARK: - Tag Input (passed between manual entry → results)

struct TagInput {
    var brandName: String = ""
    var materials: String = ""
    var countryOfOrigin: String = ""
    var careInstructions: String = ""
    var certifications: String = ""

    // Whether the input came from the camera or manual entry
    var source: InputSource = .manual

    enum InputSource {
        case camera, manual, photoLibrary
    }
}

// MARK: - Scan View

struct ScanView: View {
    @EnvironmentObject private var scanStore: ScanStore
    @StateObject private var vm: ScanViewModel

    init() {
        _vm = StateObject(wrappedValue: ScanViewModel())
    }

    @Environment(\.dismiss) var dismiss
    @State private var scanLineOffset: CGFloat = 0
    @State private var showManualEntry = false
    @State private var tagInput = TagInput()

    enum ActiveSheet: Identifiable {
        case scanner, photos
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?

    var body: some View {
            ZStack {
                switch vm.screenState {
                case .scan:
                    scannerView
                        .transition(.opacity)

                case .loading:
                    LoadingView(screenState: $vm.screenState)
                        .transition(.opacity)

                case .results:
                    if let result = vm.result {
                        ResultsView(result: result, screenState: $vm.screenState)
                    } else {
                        LoadingView(screenState: $vm.screenState)
                    }
                    
                case .error:
                    VStack(spacing: 16) {
                        Text("Something went wrong")
                            .foregroundStyle(.white)

                        if let msg = vm.errorMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button("Try again") {
                            withAnimation {
                                vm.screenState = .scan
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: vm.screenState)
            .navigationBarHidden(vm.screenState == .scan)
            .sheet(isPresented: $showManualEntry, onDismiss: handleManualEntryDismiss) {
                ManualEntrySheet(tagInput: $tagInput)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .scanner:
                    DocumentScannerView { images in
                        guard let first = images.first else { return }
                        activeSheet = nil
                        vm.analyze(image: first)
                    }

                case .photos:
                    PhotoPicker { image in
                        activeSheet = nil
                        vm.analyze(image: image)
                    }
                }
            }
            .onAppear {
                vm.scanStore = scanStore
            }
    }

    // MARK: - Scanner View (camera state)

    private var scannerView: some View {
        ZStack {
            Color(hue: 0, saturation: 0, brightness: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 8)

                Spacer()

                viewfinder
                    .padding(.horizontal, GTSpacing.xxxl + 8)

                Text("Align the clothing tag within the frame.\nHold steady for best results.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, GTSpacing.xxxl)

                Spacer()

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

    // MARK: - Manual Entry Dismiss Handler

    private func handleManualEntryDismiss() {
        guard !tagInput.brandName.trimmingCharacters(in: .whitespaces).isEmpty,
              tagInput.source == .manual else { return }

        vm.tagInput = tagInput // capture manual input
        vm.analyzeManual()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
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
                Group {
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .position(x: bracketLen / 2, y: bracketLen / 2)
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .rotationEffect(.degrees(90))
                        .position(x: w - bracketLen / 2, y: bracketLen / 2)
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .rotationEffect(.degrees(-90))
                        .position(x: bracketLen / 2, y: h - bracketLen / 2)
                    cornerBracket(width: bracketLen, height: bracketLen, lineWidth: bracketWeight)
                        .rotationEffect(.degrees(180))
                        .position(x: w - bracketLen / 2, y: h - bracketLen / 2)
                }

                if w > 32 {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gtPrimary.opacity(0.8))
                        .frame(width: w - 32, height: 2)
                        .shadow(color: Color.gtPrimary.opacity(0.5), radius: 8)
                        .offset(
                            y: -h / 2 + 16 + (h - 32) * scanLineOffset
                        )
                }

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

            Button {
                vm.tagInput = tagInput
                activeSheet = .scanner
            } label: {
                ZStack {
                    Circle().fill(Color.white).frame(width: 72, height: 72)
                    Circle().strokeBorder(Color.black.opacity(0.1), lineWidth: 2.5).frame(width: 66, height: 66)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black.opacity(0.85))
                }
            }

            HStack(spacing: GTSpacing.xxl) {
                Button("Choose photo") {
                    vm.tagInput = tagInput
                    activeSheet = .photos
                }
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(.white.opacity(0.5))

                Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 12)

                Button("Enter manually") {
                    vm.tagInput = tagInput
                    showManualEntry = true
                }
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    private func close() {
        dismiss()
    }
}

// MARK: - Manual Entry Sheet

struct ManualEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var tagInput: TagInput

    // Local form state
    @State private var brandName = ""
    @State private var materials = ""
    @State private var countryOfOrigin = ""
    @State private var careInstructions = ""
    @State private var certifications = ""
    @FocusState private var focusedField: EntryField?

    private enum EntryField: Hashable {
        case brand, materials, origin, care, certifications
    }

    @State private var showOrigin = false
    @State private var showCare = false
    @State private var showCertifications = false

    // Track whether the user submitted or just cancelled
    @State private var didSubmit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    headerSection
                        .padding(.bottom, 24)

                    VStack(spacing: 16) {
                        ManualEntryField(
                            icon: "tag.fill",
                            label: "Brand Name",
                            placeholder: "e.g. Patagonia, Zara, Everlane",
                            text: $brandName,
                            isRequired: true
                        )
                        .focused($focusedField, equals: .brand)

                        ManualEntryField(
                            icon: "tshirt.fill",
                            label: "Materials / Fabric",
                            placeholder: "e.g. 100% organic cotton",
                            text: $materials
                        )
                        .focused($focusedField, equals: .materials)

                        optionalSection(
                            title: "Country of Origin",
                            icon: "globe.americas.fill",
                            isExpanded: $showOrigin
                        ) {
                            ManualEntryField(
                                icon: "globe.americas.fill",
                                label: "Country of Origin",
                                placeholder: "e.g. Bangladesh, Portugal, USA",
                                text: $countryOfOrigin
                            )
                            .focused($focusedField, equals: .origin)
                        }

                        optionalSection(
                            title: "Care Instructions",
                            icon: "drop.fill",
                            isExpanded: $showCare
                        ) {
                            ManualEntryField(
                                icon: "drop.fill",
                                label: "Care Instructions",
                                placeholder: "e.g. Machine wash cold, tumble dry low",
                                text: $careInstructions
                            )
                            .focused($focusedField, equals: .care)
                        }

                        optionalSection(
                            title: "Certifications",
                            icon: "checkmark.seal.fill",
                            isExpanded: $showCertifications
                        ) {
                            ManualEntryField(
                                icon: "checkmark.seal.fill",
                                label: "Certifications",
                                placeholder: "e.g. GOTS, Fair Trade, OEKO-TEX",
                                text: $certifications
                            )
                            .focused($focusedField, equals: .certifications)
                        }
                    }
                    .padding(.horizontal, 20)

                    submitButton
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Reset source so dismiss handler doesn't trigger loading
                        tagInput = TagInput()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Enter Tag Details")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.forestGreen)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.leafGreen.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.leafGreen)
            }

            Text("Fill in what you know")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Text("Only brand name is needed — add more for a detailed report.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 20)
    }

    // MARK: - Optional Section

    private func optionalSection<Content: View>(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            if !isExpanded.wrappedValue {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.wrappedValue = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.leafGreen)
                        Text("Add \(title)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.leafGreen)
                        Spacer()
                        Image(systemName: icon)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.leafGreen.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.leafGreen.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.leafGreen.opacity(0.12), lineWidth: 1)
                    )
                }
            } else {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Submit Button

    private var canSubmit: Bool {
        !brandName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var submitButton: some View {
        Button {
            // Write form data into the binding so ScanView can use it
            tagInput = TagInput(
                brandName: brandName.trimmingCharacters(in: .whitespaces),
                materials: materials.trimmingCharacters(in: .whitespaces),
                countryOfOrigin: countryOfOrigin.trimmingCharacters(in: .whitespaces),
                careInstructions: careInstructions.trimmingCharacters(in: .whitespaces),
                certifications: certifications.trimmingCharacters(in: .whitespaces),
                source: .manual
            )
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.body.weight(.semibold))
                Text("Analyze Tag")
                    .font(.body.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if canSubmit {
                        LinearGradient(
                            colors: [Color.leafGreen, Color.darkGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: canSubmit ? Color.leafGreen.opacity(0.35) : .clear,
                radius: 8, x: 0, y: 4
            )
        }
        .disabled(!canSubmit)
        .animation(.easeInOut(duration: 0.2), value: canSubmit)
    }
}

// MARK: - Reusable Text Field

struct ManualEntryField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.forestGreen)
                    .textCase(.uppercase)
                    .tracking(0.5)
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .foregroundStyle(Color.leafGreen)
                }
            }

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.leafGreen.opacity(0.08))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.leafGreen)
                }

                TextField(placeholder, text: $text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .autocorrectionDisabled()

                if !text.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { text = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        text.isEmpty ? Color.gray.opacity(0.15) : Color.leafGreen.opacity(0.35),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        }
    }
}

// MARK: - Previews

#Preview("Scanner") {
    ScanView()
        .environmentObject(ScanStore())
}

#Preview("Manual Entry") {
    ManualEntrySheet(tagInput: .constant(TagInput()))
}
