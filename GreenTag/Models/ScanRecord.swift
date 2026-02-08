//
//  ScanRecord.swift
//  GreenTag
//
//  Created by Bia Shok on 2/7/26.
//
import Foundation
import UIKit

struct ScanRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var brand: String
    var dateISO: String
    var score: Int?
    var grade: String?
    var notes: String?
    var imageFilename: String?
    var analysisJSONFilename: String?

    init(
        id: UUID = .init(),
        brand: String,
        date: Date = .init(),
        score: Int? = nil,
        grade: String? = nil,
        notes: String? = nil,
        imageFilename: String? = nil,
        analysisJSONFilename: String? = nil
    ) {
        self.id = id
        self.brand = brand
        self.dateISO = ISO8601DateFormatter().string(from: date)
        self.score = score
        self.grade = grade
        self.notes = notes
        self.imageFilename = imageFilename
        self.analysisJSONFilename = analysisJSONFilename
    }

    var date: Date {
        ISO8601DateFormatter().date(from: dateISO) ?? Date()
    }

    // Hashable conformance (synthesized would also work; explicit ensures id-based equality)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ScanRecord, rhs: ScanRecord) -> Bool {
        lhs.id == rhs.id
    }
}
