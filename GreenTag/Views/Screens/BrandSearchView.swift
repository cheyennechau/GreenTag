//
//  BrandSearchView.swift
//  GreenTag
//
//  Created by Bia Shok on 2/7/26.
//

import SwiftUI

// MARK: - Sustainability Level

enum SustainabilityLevel: String {
    case low, medium, high

    var label: String {
        switch self {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    var color: Color {
        switch self {
        case .low:    return Color(red: 0.90, green: 0.22, blue: 0.21)  // Red
        case .medium: return Color(red: 0.95, green: 0.76, blue: 0.06)  // Amber
        case .high:   return Color.leafGreen                              // Green
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

    var score: Int {
        switch self {
        case .low:    return 32
        case .medium: return 61
        case .high:   return 87
        }
    }
}

// MARK: - Brand Data Model

struct BrandInfo: Identifiable {
    let id = UUID()
    let name: String
    let category: String       // e.g. "Fast Fashion", "Outdoor / Active", "Luxury"
    let level: SustainabilityLevel
    let overview: String
    let materialSourcing: [BrandDetail]
    let laborPractices: [BrandDetail]
    let environmentalImpact: [BrandDetail]
    let certifications: [String]
    let alternatives: [AlternativeBrand]
}

struct BrandDetail: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let sentiment: Sentiment

    enum Sentiment {
        case positive, neutral, negative

        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .neutral:  return "minus.circle.fill"
            case .negative: return "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .positive: return Color.leafGreen
            case .neutral:  return Color(red: 0.95, green: 0.76, blue: 0.06)
            case .negative: return Color(red: 0.90, green: 0.22, blue: 0.21)
            }
        }
    }
}

struct AlternativeBrand: Identifiable {
    let id = UUID()
    let name: String
    let tagline: String
    let level: SustainabilityLevel
}

// MARK: - Sample Brands

struct SampleBrands {
    static let all: [BrandInfo] = [
        patagonia, zara, hm, everlane, shein, nike, reformation, uniqlo
    ]

    static let patagonia = BrandInfo(
        name: "Patagonia",
        category: "Outdoor / Active",
        level: .high,
        overview: "Patagonia is widely recognized as an industry leader in sustainable fashion. The company donates 1% of sales to environmental causes and has pioneered fair trade certified sewing since 2014.",
        materialSourcing: [
            BrandDetail(title: "Recycled Materials", description: "87% of fabrics use recycled or regenerated materials including recycled polyester and nylon.", sentiment: .positive),
            BrandDetail(title: "Organic Cotton", description: "100% of cotton used has been organic since 1996, eliminating synthetic pesticides.", sentiment: .positive),
            BrandDetail(title: "Traceable Down", description: "All down is traceable and certified to ensure no live-plucking or force-feeding.", sentiment: .positive),
        ],
        laborPractices: [
            BrandDetail(title: "Fair Trade Certified", description: "76% of products are Fair Trade Certified sewn, ensuring fair wages for workers.", sentiment: .positive),
            BrandDetail(title: "Supply Chain Transparency", description: "Publishes full supplier list and factory audit results annually.", sentiment: .positive),
        ],
        environmentalImpact: [
            BrandDetail(title: "Carbon Neutral", description: "Achieved carbon neutrality across entire supply chain in 2025.", sentiment: .positive),
            BrandDetail(title: "Worn Wear Program", description: "Repair and resale program extends garment lifespan, reducing waste significantly.", sentiment: .positive),
            BrandDetail(title: "Water Usage", description: "Still working on reducing water intensity in dyeing processes.", sentiment: .neutral),
        ],
        certifications: ["B Corp", "Fair Trade", "bluesign", "1% for the Planet"],
        alternatives: [
            AlternativeBrand(name: "Cotopaxi", tagline: "Gear for good — repurposed materials", level: .high),
            AlternativeBrand(name: "prAna", tagline: "Fair Trade certified active wear", level: .high),
            AlternativeBrand(name: "Tentree", tagline: "Plants 10 trees for every item sold", level: .high),
        ]
    )

    static let zara = BrandInfo(
        name: "Zara",
        category: "Fast Fashion",
        level: .low,
        overview: "Zara, owned by Inditex, is one of the world's largest fast fashion retailers. While the company has made sustainability pledges, the fast fashion model inherently encourages overconsumption and generates significant waste.",
        materialSourcing: [
            BrandDetail(title: "Join Life Collection", description: "Only ~15% of total production uses their more sustainable Join Life line.", sentiment: .neutral),
            BrandDetail(title: "Conventional Cotton", description: "Majority of cotton is conventionally grown using high pesticide inputs.", sentiment: .negative),
            BrandDetail(title: "Synthetic Fabrics", description: "Heavy use of polyester and other synthetics that shed microplastics.", sentiment: .negative),
        ],
        laborPractices: [
            BrandDetail(title: "Supplier Audits", description: "Conducts supplier audits but has faced reports of labor violations in supply chain.", sentiment: .neutral),
            BrandDetail(title: "Living Wage Gap", description: "Does not guarantee living wages across its supplier factories.", sentiment: .negative),
        ],
        environmentalImpact: [
            BrandDetail(title: "Overproduction", description: "Produces billions of garments annually, contributing to massive textile waste.", sentiment: .negative),
            BrandDetail(title: "2040 Pledge", description: "Committed to net-zero emissions by 2040 but limited interim milestones.", sentiment: .neutral),
            BrandDetail(title: "Garment Collection", description: "Offers in-store clothing collection bins for recycling, though impact is limited.", sentiment: .neutral),
        ],
        certifications: [],
        alternatives: [
            AlternativeBrand(name: "Everlane", tagline: "Radical transparency in pricing and sourcing", level: .medium),
            AlternativeBrand(name: "Reformation", tagline: "Sustainable fabrics and carbon-neutral operations", level: .high),
            AlternativeBrand(name: "ARKET", tagline: "Quality basics with durability focus", level: .medium),
        ]
    )

    static let hm = BrandInfo(
        name: "H&M",
        category: "Fast Fashion",
        level: .medium,
        overview: "H&M has invested heavily in sustainability marketing with its Conscious Collection and garment recycling programs. However, the fast fashion business model remains at odds with true sustainability goals.",
        materialSourcing: [
            BrandDetail(title: "Conscious Collection", description: "~30% of materials are from recycled or sustainably sourced origins.", sentiment: .neutral),
            BrandDetail(title: "Organic Cotton Commitment", description: "One of the world's largest users of organic cotton, though still a minority of total.", sentiment: .positive),
            BrandDetail(title: "Synthetic Dependency", description: "Still relies heavily on virgin polyester for the majority of products.", sentiment: .negative),
        ],
        laborPractices: [
            BrandDetail(title: "Fair Living Wage Strategy", description: "Has a wage strategy but implementation across all suppliers remains incomplete.", sentiment: .neutral),
            BrandDetail(title: "Transparency", description: "Publishes detailed supplier list and sustainability reports.", sentiment: .positive),
        ],
        environmentalImpact: [
            BrandDetail(title: "Garment Collection", description: "Largest fashion garment collector globally, though only a fraction is truly recycled.", sentiment: .neutral),
            BrandDetail(title: "Climate Targets", description: "Aims for climate positive by 2040 with science-based targets.", sentiment: .positive),
            BrandDetail(title: "Volume Problem", description: "Sheer production volume undermines sustainability efforts.", sentiment: .negative),
        ],
        certifications: ["GOTS (partial)", "Better Cotton Initiative"],
        alternatives: [
            AlternativeBrand(name: "Everlane", tagline: "Radical transparency in pricing and sourcing", level: .medium),
            AlternativeBrand(name: "Pact", tagline: "Organic cotton basics at accessible prices", level: .high),
            AlternativeBrand(name: "People Tree", tagline: "Pioneer in fair trade fashion", level: .high),
        ]
    )

    static let everlane = BrandInfo(
        name: "Everlane",
        category: "Modern Essentials",
        level: .medium,
        overview: "Everlane pioneered radical transparency by sharing factory details and cost breakdowns. Quality and ethical production are prioritized, though the brand still has room to improve on environmental metrics.",
        materialSourcing: [
            BrandDetail(title: "Ethical Factories", description: "Partners with audited factories and shares detailed factory profiles publicly.", sentiment: .positive),
            BrandDetail(title: "Recycled Materials", description: "Uses recycled polyester in several product lines including outerwear.", sentiment: .positive),
            BrandDetail(title: "Limited Organic Cotton", description: "Not all cotton products use organic cotton yet.", sentiment: .neutral),
        ],
        laborPractices: [
            BrandDetail(title: "Factory Transparency", description: "Publishes detailed profiles of every factory they work with.", sentiment: .positive),
            BrandDetail(title: "Worker Wellbeing", description: "Invests in worker programs but no third-party fair trade certification.", sentiment: .neutral),
        ],
        environmentalImpact: [
            BrandDetail(title: "No New Plastic Pledge", description: "Committed to eliminating all virgin plastic from supply chain.", sentiment: .positive),
            BrandDetail(title: "Carbon Offsets", description: "Uses carbon offsets but hasn't achieved full neutrality yet.", sentiment: .neutral),
        ],
        certifications: ["OEKO-TEX (select)", "bluesign (select)"],
        alternatives: [
            AlternativeBrand(name: "Patagonia", tagline: "Gold standard in outdoor sustainability", level: .high),
            AlternativeBrand(name: "Kotn", tagline: "Egyptian cotton with community investment", level: .high),
            AlternativeBrand(name: "Frank And Oak", tagline: "Circular fashion with take-back programs", level: .medium),
        ]
    )

    static let shein = BrandInfo(
        name: "Shein",
        category: "Ultra Fast Fashion",
        level: .low,
        overview: "Shein is an ultra-fast fashion retailer that produces thousands of new styles daily. The extreme speed and low price point raise serious concerns about environmental impact and labor conditions throughout its supply chain.",
        materialSourcing: [
            BrandDetail(title: "Low-Quality Synthetics", description: "Primarily uses cheap polyester and other synthetic materials with limited durability.", sentiment: .negative),
            BrandDetail(title: "No Material Traceability", description: "Minimal transparency about where raw materials are sourced.", sentiment: .negative),
            BrandDetail(title: "evoluSHEIN Collection", description: "Small collection using recycled polyester, but represents a tiny fraction of output.", sentiment: .neutral),
        ],
        laborPractices: [
            BrandDetail(title: "Supply Chain Opacity", description: "Limited visibility into working conditions across thousands of suppliers.", sentiment: .negative),
            BrandDetail(title: "Investigation Reports", description: "Multiple investigations have revealed concerning labor practices.", sentiment: .negative),
        ],
        environmentalImpact: [
            BrandDetail(title: "Massive Overproduction", description: "Adds thousands of new items daily, generating enormous textile waste.", sentiment: .negative),
            BrandDetail(title: "Microplastic Pollution", description: "Synthetic garments shed microplastics with every wash cycle.", sentiment: .negative),
            BrandDetail(title: "Carbon Footprint", description: "Global shipping of individually packaged items creates significant emissions.", sentiment: .negative),
        ],
        certifications: [],
        alternatives: [
            AlternativeBrand(name: "ThredUp", tagline: "Secondhand clothing marketplace", level: .high),
            AlternativeBrand(name: "Pact", tagline: "Affordable organic cotton basics", level: .high),
            AlternativeBrand(name: "H&M Conscious", tagline: "More sustainable fast fashion option", level: .medium),
        ]
    )

    static let nike = BrandInfo(
        name: "Nike",
        category: "Athletic / Sportswear",
        level: .medium,
        overview: "Nike has made significant investments in sustainable innovation, including Nike Grind recycling and Flyknit technology that reduces waste. However, the company's massive scale and reliance on synthetic materials present ongoing challenges.",
        materialSourcing: [
            BrandDetail(title: "Nike Grind", description: "Recycles manufacturing waste and old shoes into materials for new products and surfaces.", sentiment: .positive),
            BrandDetail(title: "Flyknit Technology", description: "Reduces waste by 60% compared to traditional cut-and-sew manufacturing.", sentiment: .positive),
            BrandDetail(title: "Synthetic Dependency", description: "Still heavily reliant on petroleum-based synthetics for performance wear.", sentiment: .neutral),
        ],
        laborPractices: [
            BrandDetail(title: "Supplier Audits", description: "Comprehensive audit program covering hundreds of factories globally.", sentiment: .positive),
            BrandDetail(title: "Historical Concerns", description: "Has significantly improved from past labor controversies but monitoring continues.", sentiment: .neutral),
        ],
        environmentalImpact: [
            BrandDetail(title: "Move to Zero", description: "Committed to zero carbon and zero waste across operations.", sentiment: .positive),
            BrandDetail(title: "Water Reduction", description: "Reduced freshwater usage in textile dyeing by 30% since 2020.", sentiment: .positive),
            BrandDetail(title: "Scale Challenge", description: "Enormous production volume makes meaningful impact reduction difficult.", sentiment: .neutral),
        ],
        certifications: ["bluesign (select)", "Better Cotton Initiative"],
        alternatives: [
            AlternativeBrand(name: "Allbirds", tagline: "Carbon-neutral footwear from natural materials", level: .high),
            AlternativeBrand(name: "Veja", tagline: "Transparent sneakers with fair trade rubber", level: .high),
            AlternativeBrand(name: "On Running", tagline: "Performance with recycled materials", level: .medium),
        ]
    )

    static let reformation = BrandInfo(
        name: "Reformation",
        category: "Contemporary / Trendy",
        level: .high,
        overview: "Reformation combines trendy designs with genuine sustainability practices. The brand tracks and publishes the environmental footprint of every product and invests heavily in deadstock and sustainable fabrics.",
        materialSourcing: [
            BrandDetail(title: "Deadstock & Surplus Fabrics", description: "Uses deadstock, surplus, and regenerated fabrics to minimize waste.", sentiment: .positive),
            BrandDetail(title: "RefScale", description: "Tracks CO2, water, and waste for every garment and publishes results.", sentiment: .positive),
            BrandDetail(title: "TENCEL & Linen", description: "Prioritizes low-impact fibers like TENCEL Lyocell and organic linen.", sentiment: .positive),
        ],
        laborPractices: [
            BrandDetail(title: "LA Manufacturing", description: "Majority of production in owned LA factory with fair wages.", sentiment: .positive),
            BrandDetail(title: "Supplier Code", description: "Strict supplier code of conduct with regular audits.", sentiment: .positive),
        ],
        environmentalImpact: [
            BrandDetail(title: "Carbon Neutral", description: "Has been carbon neutral since 2015 through reduction and offsets.", sentiment: .positive),
            BrandDetail(title: "Water Savings", description: "Saves millions of gallons of water annually compared to conventional production.", sentiment: .positive),
        ],
        certifications: ["Climate Neutral", "OEKO-TEX"],
        alternatives: [
            AlternativeBrand(name: "Christy Dawn", tagline: "Farm-to-closet regenerative fashion", level: .high),
            AlternativeBrand(name: "Amour Vert", tagline: "Zero-waste sustainable basics", level: .high),
            AlternativeBrand(name: "Girlfriend Collective", tagline: "Activewear from recycled bottles", level: .high),
        ]
    )

    static let uniqlo = BrandInfo(
        name: "Uniqlo",
        category: "Casual / Basics",
        level: .medium,
        overview: "Uniqlo focuses on functional basics with longer product lifecycles than typical fast fashion. The brand has made progress on sustainability but still faces challenges around supply chain transparency and environmental impact at scale.",
        materialSourcing: [
            BrandDetail(title: "RE.UNIQLO", description: "Recycling program turns old garments into new products like down jackets.", sentiment: .positive),
            BrandDetail(title: "DRY-EX Technology", description: "Uses recycled PET bottles for their moisture-wicking fabric line.", sentiment: .positive),
            BrandDetail(title: "Conventional Cotton", description: "Still sources significant amounts of conventional cotton.", sentiment: .neutral),
        ],
        laborPractices: [
            BrandDetail(title: "Factory List", description: "Publishes list of core partner factories for transparency.", sentiment: .positive),
            BrandDetail(title: "Xinjiang Cotton", description: "Has faced scrutiny over cotton sourcing from sensitive regions.", sentiment: .negative),
        ],
        environmentalImpact: [
            BrandDetail(title: "Longevity Focus", description: "LifeWear philosophy emphasizes durability over trend-chasing.", sentiment: .positive),
            BrandDetail(title: "Packaging Reduction", description: "Eliminated single-use plastic bags in many markets.", sentiment: .positive),
            BrandDetail(title: "Global Scale", description: "Massive production volume presents ongoing sustainability challenges.", sentiment: .neutral),
        ],
        certifications: ["Better Cotton Initiative"],
        alternatives: [
            AlternativeBrand(name: "Kotn", tagline: "Egyptian cotton essentials with impact", level: .high),
            AlternativeBrand(name: "Pact", tagline: "Organic cotton everyday basics", level: .high),
            AlternativeBrand(name: "MUJI", tagline: "Minimal basics with natural materials", level: .medium),
        ]
    )
}

// MARK: - Brand Search View

struct BrandSearchView: View {
    @State private var searchText = ""
    @State private var selectedBrand: BrandInfo?
    @Environment(\.dismiss) private var dismiss

    private var filteredBrands: [BrandInfo] {
        if searchText.isEmpty {
            return SampleBrands.all.sorted { $0.name < $1.name }
        }
        return SampleBrands.all
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    // Group brands by first letter for section headers
    private var groupedBrands: [(letter: String, brands: [BrandInfo])] {
        let dict = Dictionary(grouping: filteredBrands) { brand in
            String(brand.name.prefix(1)).uppercased()
        }
        return dict.sorted { $0.key < $1.key }
            .map { (letter: $0.key, brands: $0.value) }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if filteredBrands.isEmpty {
                    emptyState
                } else {
                    brandList
                }
            }
        }
        .navigationTitle("Search Brands")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedBrand) { brand in
            BrandReportView(brand: brand)
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
                                    selectedBrand = brand
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

    private func brandRow(_ brand: BrandInfo) -> some View {
        HStack(spacing: 14) {
            // Brand initial badge
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(brand.level.bgColor)
                    .frame(width: 44, height: 44)
                Text(String(brand.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(brand.level.color)
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

            // Sustainability pill
            HStack(spacing: 4) {
                Circle()
                    .fill(brand.level.color)
                    .frame(width: 8, height: 8)
                Text(brand.level.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(brand.level.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(brand.level.bgColor)
            .clipShape(Capsule())

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
            Text("No brands found")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text("Try a different search term, or this brand\nwill be available after our API integration.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Make BrandInfo work with navigationDestination

extension BrandInfo: Hashable {
    static func == (lhs: BrandInfo, rhs: BrandInfo) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Brand Report View

struct BrandReportView: View {
    let brand: BrandInfo
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Score Card
                scoreCard
                    .padding(.top, 8)

                // Overview
                overviewSection

                // Material Sourcing
                detailSection(
                    title: "Material Sourcing",
                    icon: "tshirt.fill",
                    details: brand.materialSourcing
                )

                // Labor Practices
                detailSection(
                    title: "Labor Practices",
                    icon: "person.2.fill",
                    details: brand.laborPractices
                )

                // Environmental Impact
                detailSection(
                    title: "Environmental Impact",
                    icon: "globe.americas.fill",
                    details: brand.environmentalImpact
                )

                // Certifications
                if !brand.certifications.isEmpty {
                    certificationsSection
                }

                // Alternative Brands
                alternativesSection

                // Disclaimer
                disclaimerFooter
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(brand.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 16) {
            // Score ring
            ZStack {
                // Track
                Circle()
                    .stroke(Color.gray.opacity(0.12), lineWidth: 10)
                    .frame(width: 100, height: 100)

                // Fill
                Circle()
                    .trim(from: 0, to: appeared ? CGFloat(brand.level.score) / 100.0 : 0)
                    .stroke(
                        brand.level.color,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0).delay(0.2), value: appeared)

                VStack(spacing: 2) {
                    Text("\(brand.level.score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(brand.level.color)
                    Text("/ 100")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Level badge
            HStack(spacing: 8) {
                Image(systemName: brand.level.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text("\(brand.level.label) Sustainability")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(brand.level.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(brand.level.bgColor)
            .clipShape(Capsule())

            // Category
            Text(brand.category)
                .font(.caption)
                .foregroundStyle(.secondary)
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

            Text(brand.overview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Detail Section

    private func detailSection(title: String, icon: String, details: [BrandDetail]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(title, icon: icon)

            ForEach(details) { detail in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: detail.sentiment.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(detail.sentiment.color)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(detail.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                }

                if detail.id != details.last?.id {
                    Divider()
                        .padding(.leading, 28)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Certifications

    private var certificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Certifications", icon: "checkmark.seal.fill")

            FlowLayoutSimple(spacing: 8) {
                ForEach(brand.certifications, id: \.self) { cert in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.leafGreen)
                        Text(cert)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.forestGreen)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.paleGreen)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Alternatives

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Sustainable Alternatives", icon: "arrow.triangle.swap")

            ForEach(brand.alternatives) { alt in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(alt.level.bgColor)
                            .frame(width: 42, height: 42)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(alt.level.color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(alt.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(alt.tagline)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(alt.level.color)
                            .frame(width: 6, height: 6)
                        Text(alt.level.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(alt.level.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(alt.level.bgColor)
                    .clipShape(Capsule())
                }

                if alt.id != brand.alternatives.last?.id {
                    Divider()
                        .padding(.leading, 54)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Disclaimer

    private var disclaimerFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Text("Scores are based on available data and will update with API integration.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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

// MARK: - Simple Flow Layout (for certification chips)

struct FlowLayoutSimple: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: - Previews

#Preview("Brand Search") {
    NavigationStack {
        BrandSearchView()
    }
}

#Preview("Brand Report - High") {
    NavigationStack {
        BrandReportView(brand: SampleBrands.patagonia)
    }
}

#Preview("Brand Report - Low") {
    NavigationStack {
        BrandReportView(brand: SampleBrands.zara)
    }
}
