//
//  HomeView.swift
//  GreenTag
//
//  Created by Bia Shok on 2/7/26.
//

import SwiftUI

// MARK: - Theme Colors

extension Color {
    static let leafGreen      = Color(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255)   // #4CAF50
    static let forestGreen    = Color(red: 0x2E/255, green: 0x7D/255, blue: 0x32/255)   // #2E7D32
    static let darkGreen      = Color(red: 0x38/255, green: 0x8E/255, blue: 0x3C/255)   // #388E3C
    static let paleGreen      = Color(red: 0xE8/255, green: 0xF5/255, blue: 0xE9/255)   // #E8F5E9
    static let mintCream      = Color(red: 0xF1/255, green: 0xF8/255, blue: 0xE9/255)   // #F1F8E9
}

// MARK: - Home View

struct HomeView: View {
    @State private var leafRotation: Double = 0
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Soft gradient background
                LinearGradient(
                    colors: [Color.mintCream, Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // MARK: - Top Bar
                        topBar
                            .padding(.top, 8)

                        // MARK: - Hero
                        hero
                            .padding(.top, 28)
                            .padding(.bottom, 32)

                        // MARK: - Features Card
                        featuresCard
                            .padding(.bottom, 28)

                        // MARK: - Action Buttons
                        actionButtons
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { appeared = true }
                withAnimation(
                    .easeInOut(duration: 3).repeatForever(autoreverses: true)
                ) { leafRotation = 10 }
            }
        }
    }

    // ──────────────────────────────────────
    // MARK: – Top Bar
    // ──────────────────────────────────────

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, Bia")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.forestGreen)
                Text("Make fashion greener")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Profile menu
            Menu {
                NavigationLink(destination: ProfileView()) {
                    Label("My Profile", systemImage: "person.crop.circle")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.leafGreen.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Circle()
                        .stroke(Color.leafGreen.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 46, height: 46)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.leafGreen)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -6)
    }

    // ──────────────────────────────────────
    // MARK: – Hero
    // ──────────────────────────────────────

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.leafGreen.opacity(0.10))
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(Color.leafGreen.opacity(0.15), lineWidth: 2)
                    .frame(width: 110, height: 110)
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(Color.leafGreen)
                    .rotationEffect(.degrees(leafRotation))
            }

            VStack(spacing: 6) {
                Text("GreenTag")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.forestGreen)
                Text("Sustainable Fashion Transparency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    // ──────────────────────────────────────
    // MARK: – Features Card
    // ──────────────────────────────────────

    private var featuresCard: some View {
        VStack(spacing: 0) {
            FeatureRow(icon: "camera.viewfinder",
                       text: "Scan clothing tags or brands",
                       isFirst: true)
            FeatureRow(icon: "chart.bar.fill",
                       text: "See environmental impact scores")
            FeatureRow(icon: "person.2.fill",
                       text: "Check labor transparency")
            FeatureRow(icon: "leaf.arrow.circlepath",
                       text: "Discover ethical alternatives",
                       isLast: true)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    // ──────────────────────────────────────
    // MARK: – Action Buttons
    // ──────────────────────────────────────

    private var actionButtons: some View {
        VStack(spacing: 14) {

            // Primary — Scan a Tag
            NavigationLink(destination: ScanView()) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.body.weight(.semibold))
                    Text("Scan a Tag")
                        .font(.body.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.leafGreen, Color.darkGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.leafGreen.opacity(0.35), radius: 8, x: 0, y: 4)
            }

            // Secondary row — Past Results & Search Brands
            HStack(spacing: 12) {

                NavigationLink(destination: ScanHistoryView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.subheadline.weight(.semibold))
                        Text("Past Results")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color.forestGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.paleGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.leafGreen.opacity(0.2), lineWidth: 1)
                    )
                }

                NavigationLink(destination: BrandSearchView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.subheadline.weight(.semibold))
                        Text("Search Brands")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color.forestGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String
    var isFirst: Bool = false
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.leafGreen.opacity(0.10))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.leafGreen)
                }
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !isLast {
                Divider()
                    .padding(.leading, 64)
            }
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.leafGreen.opacity(0.10))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.leafGreen)
                }

                VStack(spacing: 6) {
                    Text("Bia Shok")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.forestGreen)
                    Text("Eco-conscious shopper")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Quick stats
                HStack(spacing: 24) {
                    statBubble(value: "12", label: "Scans")
                    statBubble(value: "A-", label: "Avg Score")
                    statBubble(value: "3", label: "Saved")
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statBubble(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.forestGreen)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 72, height: 72)
        .background(Color.paleGreen)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var notificationsOn = true
    @State private var darkMode = false

    var body: some View {
        List {
            Section("Preferences") {
                Toggle(isOn: $notificationsOn) {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tint(Color.leafGreen)

                Toggle(isOn: $darkMode) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
                .tint(Color.leafGreen)
            }

            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Scan History View

struct ScanHistoryView: View {
    private let sampleScans: [(brand: String, date: String, score: String)] = [
        ("Patagonia",     "Feb 6, 2026",  "A+"),
        ("H&M Conscious", "Feb 4, 2026",  "B"),
        ("Zara",          "Jan 30, 2026", "C+"),
        ("Everlane",      "Jan 28, 2026", "A"),
    ]

    var body: some View {
        List {
            ForEach(sampleScans, id: \.brand) { scan in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.leafGreen.opacity(0.10))
                            .frame(width: 42, height: 42)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.leafGreen)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(scan.brand)
                            .font(.subheadline.weight(.semibold))
                        Text(scan.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(scan.score)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.forestGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.paleGreen)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Past Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView()
}
