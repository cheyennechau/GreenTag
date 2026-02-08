//
//  LocalFiles.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/8/26.
//

import Foundation
import UIKit

enum LocalFiles {
    // MARK: - Directories

    private static func documents() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    private static func ensureDir(_ name: String) throws -> URL {
        let dir = try documents().appendingPathComponent(name, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Images

    static func saveJPEG(_ image: UIImage, id: UUID, compression: CGFloat = 0.85) throws -> String {
        let dir = try ensureDir("ScanImages")
        let filename = "\(id.uuidString).jpg"
        let url = dir.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: compression) else {
            throw NSError(domain: "LocalFiles", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JPEG"])
        }

        try data.write(to: url, options: [.atomic])
        return "ScanImages/\(filename)" // store relative path
    }

    static func loadImage(relativePath: String) -> UIImage? {
        do {
            let url = try documents().appendingPathComponent(relativePath)
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    // MARK: - Analysis JSON

    static func saveAnalysisJSON(_ obj: Any, id: UUID) throws -> String {
        let dir = try ensureDir("ScanAnalysis")
        let filename = "\(id.uuidString).json"
        let url = dir.appendingPathComponent(filename)

        let data = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: [.atomic])
        return "ScanAnalysis/\(filename)"
    }

    static func loadAnalysisJSON(relativePath: String) -> Any? {
        do {
            let url = try documents().appendingPathComponent(relativePath)
            let data = try Data(contentsOf: url)
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            return nil
        }
    }

    // MARK: - Delete helpers (optional)

    static func delete(relativePath: String) {
        do {
            let url = try documents().appendingPathComponent(relativePath)
            try FileManager.default.removeItem(at: url)
        } catch { }
    }
}
