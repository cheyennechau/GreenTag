//
//  SaveResultView.swift
//  GreenTag
//
//  Created by Bia Shok on 2/7/26.
//

import SwiftUI

// SavedResultView: show full ResultsView when we can decode a ScanResult, otherwise
// show a simple fallback view built from the ScanRecord fields.
struct SavedResultView: View {
    let record: ScanRecord
    @EnvironmentObject var scanStore: ScanStore

    @State private var decodedResult: ScanResult?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let result = decodedResult {
                // We have a full ScanResult: show your existing ResultsView
                ResultsView(result: result, screenState: .constant(.results))
            } else if isLoading {
                ProgressView("Loading…")
                    .task { await loadIfAvailable() }
            } else {
                // Fallback UI if we can't decode a ScanResult JSON
                fallbackView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var fallbackView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image = scanStore.loadImage(for: record) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text(record.brand)
                    .font(.title2.weight(.semibold))

                if let grade = record.grade {
                    Text(grade)
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.green)
                } else if let score = record.score {
                    Text("\(score) / 100")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.green)
                }

                if let notes = record.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Saved Scan")
    }

    @MainActor
    private func loadIfAvailable() async {
        // Try to decode the full ScanResult via ScanStore (Option A)
        if let r = scanStore.loadAnalysis(for: record) {
            decodedResult = r
        } else {
            decodedResult = nil
        }
        isLoading = false
    }
}
