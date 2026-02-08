//
//  ScanStore.swift
//  GreenTag
//
//  Created by Bia Shok on 2/7/26.
//

import Foundation
import UIKit
import SwiftUI
internal import Combine

@MainActor
final class ScanStore: ObservableObject {
    
    @Published private(set) var records: [ScanRecord] = []
    // call this once at app start or via a debug button
        func seedFakeDataIfEmpty() {
            guard records.isEmpty else { return }
            records = [
                ScanRecord(id: UUID(), brand: "Everlane", date: Date(), score: 72, grade: nil),
                ScanRecord(id: UUID(), brand: "H&M", date: Date().addingTimeInterval(-60*60*24*2), score: 48, grade: nil),
                ScanRecord(id: UUID(), brand: "Patagonia", date: Date().addingTimeInterval(-60*60*24*7), score: nil, grade: "A+")
            ]
        }
    
    private let storeFileURL: URL
    private let imagesDirectory: URL

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "scans.json") {
        let fm = FileManager.default

        let appSupport = try! fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(
            Bundle.main.bundleIdentifier ?? "GreenTag",
            isDirectory: true
        )

        if !fm.fileExists(atPath: appSupport.path) {
            try? fm.createDirectory(
                at: appSupport,
                withIntermediateDirectories: true
            )
        }

        self.imagesDirectory = appSupport.appendingPathComponent(
            "images",
            isDirectory: true
        )

        if !fm.fileExists(atPath: imagesDirectory.path) {
            try? fm.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true
            )
        }

        self.storeFileURL = appSupport.appendingPathComponent(filename)
    }

    // MARK: - Load

    func load() async {
        guard FileManager.default.fileExists(atPath: storeFileURL.path) else {
            records = []
            return
        }

        do {
            let data = try Data(contentsOf: storeFileURL)
            let loaded = try decoder.decode([ScanRecord].self, from: data)
            records = loaded.sorted { $0.date > $1.date }
        } catch {
            print("ScanStore load error:", error)
            records = []
        }
    }
    func save() {
        do {
            let data = try encoder.encode(records)
            try data.write(to: storeFileURL, options: .atomic)
        } catch {
            print("ScanStore save error:", error)
        }
    }
    

    func add(record: ScanRecord, image: UIImage? = nil) {
        var r = record
        // if image provided, save it and set filename
        if let img = image {
            if let fname = saveImage(img, id: r.id) {
                r.imageFilename = fname
            }
        }

        records.insert(r, at: 0) // newest first
        save()
    }

    func update(_ record: ScanRecord) {
        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[idx] = record
        save()
    }

    func delete(at offsets: IndexSet) {
        for idx in offsets.sorted().reversed() {
            let r = records[idx]
            if let fname = r.imageFilename {
                try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(fname))
            }
            // if analysis json file exists, remove it similarly
            if let af = r.analysisJSONFilename {
                try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(af))
            }
            records.remove(at: idx)
        }
        save()
    }

    func delete(record: ScanRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            delete(at: IndexSet(integer: idx))
        }
    }

    // MARK: - Images

    private func saveImage(_ image: UIImage, id: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let filename = "\(id.uuidString).jpg"
        let url = imagesDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("saveImage error:", error)
            return nil
        }
    }

    func loadImage(for record: ScanRecord) -> UIImage? {
        guard let fname = record.imageFilename else { return nil }
        let url = imagesDirectory.appendingPathComponent(fname)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    // optional: save arbitrary analysis JSON (string or encodable)
    func saveAnalysis<T: Encodable>(_ object: T, for record: ScanRecord, filenamePrefix: String = "analysis") -> String? {
        let fname = "\(filenamePrefix)-\(record.id.uuidString).json"
        let url = imagesDirectory.appendingPathComponent(fname)
        do {
            let data = try encoder.encode(object)
            try data.write(to: url, options: .atomic)
            return fname
        } catch {
            print("saveAnalysis error:", error)
            return nil
        }
    }

    func loadAnalysisData(for record: ScanRecord) -> Data? {
        guard let fname = record.analysisJSONFilename else { return nil }
        let url = imagesDirectory.appendingPathComponent(fname)
        return try? Data(contentsOf: url)
    }
    // MARK: - Analysis load helper (optional)
    func loadAnalysis(for record: ScanRecord) -> ScanResult? {
        // If the record doesn't reference an analysis JSON, bail out
        guard let analysisFilename = record.analysisJSONFilename, !analysisFilename.isEmpty else {
            return nil
        }

        // locate file relative to the store file's directory (Application Support / bundle id / ...)
        let appSupportDir = storeFileURL.deletingLastPathComponent()
        let analysisURL = appSupportDir.appendingPathComponent(analysisFilename)

        guard FileManager.default.fileExists(atPath: analysisURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: analysisURL)
            let result = try decoder.decode(ScanResult.self, from: data)
            return result
        } catch {
            print("[ScanStore] loadAnalysis error:", error)
            return nil
        }
    }

}
extension ScanStore {
    // call at app start; existing load() is async so this wrapper calls it safely
    func loadIfNeeded() async {
        // try to load persisted file — if nothing exists, seedFakeDataIfEmpty already created samples
        await load()
        if records.isEmpty {
            // keep seeded fake data if load found nothing
            seedFakeDataIfEmpty()
        }
    }
}
