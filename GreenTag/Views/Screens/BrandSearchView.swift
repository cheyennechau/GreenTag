//
//  BrandSearchView.swift
//  GreenTag
//
//  Created by Bia Shok on 2/7/26.
//

import SwiftUI

// MARK: - Sustainability Level (used for UI rendering)

enum SustainabilityLevel: String, CaseIterable {
    case low, medium, high

    /// Initialize from the API rating string
    init(from rating: String) {
        switch rating.lowercased() {
        case "high":   self = .high
        case "medium": self = .medium
        default:       self = .low
        }
    }

    var label: String {
        switch self {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    var color: Color {
        switch self {
        case .low:    return Color(red: 0.90, green: 0.22, blue: 0.21)
        case .medium: return Color(red: 0.95, green: 0.76, blue: 0.06)
        case .high:   return Color.leafGreen
        }
    }

    var bgColor: Color {
        switch self {
        case .low:    return Color(red: 0.90, green: 0.22, blue: 0.21).opacity(0.08)
        case .medium: return Color(red: 0.95, green: 0.76, blue: 0.06).opacity(0.10)
        case .high:   return Color.leafGreen.opacity(0.08)
        }
    }

    var icon: String {
        switch self {
        case .low:    return "exclamationmark.triangle.fill"
        case .medium: return "arrow.triangle.2.circlepath"
        case .high:   return "leaf.fill"
        }
    }
}

// MARK: - Quick Brand Entry (for the browsable list)

struct QuickBrand: Identifiable {
    let id = UUID()
    let name: String
    let category: String
}

private let quickBrands: [QuickBrand] = [
    QuickBrand(name: "Everlane",    category: "Modern Essentials"),
    QuickBrand(name: "H&M",         category: "Fast Fashion"),
    QuickBrand(name: "Nike",        category: "Athletic / Sportswear"),
    QuickBrand(name: "Patagonia",   category: "Outdoor / Active"),
    QuickBrand(name: "Reformation", category: "Contemporary / Trendy"),
    QuickBrand(name: "Shein",       category: "Ultra Fast Fashion"),
    QuickBrand(name: "Uniqlo",      category: "Casual / Basics"),
    QuickBrand(name: "Zara",        category: "Fast Fashion"),
]

// MARK: - Brand Search View

struct BrandSearchView: View {
    @StateObject private var service = BrandService()
    @State private var searchText = ""
    @State private var navigateToReport = false

    private var filteredBrands: [QuickBrand] {
        if searchText.isEmpty { return quickBrands }
        return quickBrands.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedBrands: [(letter: String, brands: [QuickBrand])] {
        let dict = Dictionary(grouping: filteredBrands) {
            String($0.name.prefix(1)).uppercased()
        }
        return dict.sorted { $0.key < $1.key }
            .map { (letter: $0.key, brands: $0.value) }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if filteredBrands.isEmpty && !searchText.isEmpty {
                    // No matches in quick list — offer to search via API
                    freeSearchState
                } else if filteredBrands.isEmpty {
                    emptyState
                } else {
                    brandList
                }
            }

            // Loading overlay
            if service.isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Search Brands")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigateToReport) {
            if let assessment = service.lastAssessment {
                BrandReportView(assessment: assessment)
            }
        }
        .alert("Error", isPresented: .init(
            get: { service.errorMessage != nil },
            set: { if !$0 { service.errorMessage = nil } }
        )) {
            Button("OK") { service.errorMessage = nil }
        } message: {
            Text(service.errorMessage ?? "")
        }
        .onChange(of: service.lastAssessment) { _, newVal in
            if newVal != nil {
                navigateToReport = true
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.leafGreen)

            TextField("Search for a brand...", text: $searchText)
                .font(.subheadline)
                .autocorrectionDisabled()
                .onSubmit {
                    // When user presses return, search any brand
                    let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        Task { await service.assessBrand(trimmed) }
                    }
                }

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    searchText.isEmpty ? Color.gray.opacity(0.15) : Color.leafGreen.opacity(0.35),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Brand List

    private var brandList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedBrands, id: \.letter) { group in
                    Section {
                        ForEach(group.brands) { brand in
                            brandRow(brand)
                                .onTapGesture {
                                    Task { await service.assessBrand(brand.name) }
                                }
                        }
                    } header: {
                        if searchText.isEmpty {
                            sectionHeader(group.letter)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    private func sectionHeader(_ letter: String) -> some View {
        HStack {
            Text(letter)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.forestGreen)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(Color(.systemGroupedBackground))
    }

    private func brandRow(_ brand: QuickBrand) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.leafGreen.opacity(0.08))
                    .frame(width: 44, height: 44)
                Text(String(brand.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.forestGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(brand.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(brand.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .padding(.vertical, 4)
    }

    // MARK: - Free Search State (brand not in quick list)

    private var freeSearchState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.leafGreen.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.leafGreen.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("Not in our quick list")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("Press Search to analyze \"\(searchText)\" using AI.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                Task { await service.assessBrand(searchText) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Analyze \(searchText)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.leafGreen, Color.darkGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.leafGreen.opacity(0.3), radius: 6, x: 0, y: 3)
            }

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.leafGreen.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.leafGreen.opacity(0.4))
            }
            Text("Search for any brand")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text("Type a brand name and press return\nto get a sustainability report.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.leafGreen.opacity(0.10))
                        .frame(width: 90, height: 90)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.leafGreen))
                        .scaleEffect(1.3)
                }

                Text("Analyzing brand...")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Checking sustainability data with AI")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Brand Report View (API-driven)

struct BrandReportView: View {
    let assessment: BrandAssessment
    @State private var appeared = false

    private var level: SustainabilityLevel {
        SustainabilityLevel(from: assessment.overall.rating)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {

                // Score Card
                scoreCard
                    .padding(.top, 8)

                // Overview
                overviewSection

                // Material Sourcing
                pillarSection(
                    title: "Material Sourcing",
                    icon: "tshirt.fill",
                    pillar: assessment.pillars.materials
                )

                // Labor & Ethics
                pillarSection(
                    title: "Labor & Ethics",
                    icon: "person.2.fill",
                    pillar: assessment.pillars.labor
                )

                // Common Materials
                pillarSection(
                    title: "Common Materials Used",
                    icon: "cube.fill",
                    pillar: assessment.pillars.materials_common
                )

                // Evidence sources
                evidenceSection

                // Disclaimer
                disclaimerFooter
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(assessment.brand)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 16) {
            // Level icon
            ZStack {
                Circle()
                    .fill(level.bgColor)
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(level.color.opacity(0.3), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Image(systemName: level.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(level.color)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

            // Level badge
            HStack(spacing: 8) {
                Image(systemName: level.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text("\(level.label) Sustainability")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(level.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(level.bgColor)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Overview", icon: "doc.text.fill")

            Text(assessment.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Pillar Section

    private func pillarSection(title: String, icon: String, pillar: BrandAssessment.Pillar) -> some View {
        let pillarLevel = SustainabilityLevel(from: pillar.rating)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle(title, icon: icon)
                Spacer()
                // Rating pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(pillarLevel.color)
                        .frame(width: 8, height: 8)
                    Text(pillarLevel.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(pillarLevel.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(pillarLevel.bgColor)
                .clipShape(Capsule())
            }

            Text(pillar.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            // Evidence snippets
            if !pillar.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(pillar.evidence.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .padding(.top, 3)
                            Text(item.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Evidence

    private var evidenceSection: some View {
        let allEvidence = [
            assessment.pillars.materials.evidence,
            assessment.pillars.labor.evidence,
            assessment.pillars.materials_common.evidence
        ].flatMap { $0 }

        let uniqueSources = Array(Set(allEvidence.map(\.source))).sorted()

        return Group {
            if !uniqueSources.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Sources Analyzed", icon: "doc.text.magnifyingglass")

                    ForEach(uniqueSources, id: \.self) { source in
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.leafGreen)
                            Text(source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Text("Analysis powered by Gemini AI based on available public data. Ratings may change as more sources become available.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.leafGreen)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.forestGreen)
        }
    }
}

// MARK: - Previews

#Preview("Brand Search") {
    NavigationStack {
        BrandSearchView()
    }
}
