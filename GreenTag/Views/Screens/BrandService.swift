//
//  BrandService.swift
//  GreenTag
//
//  Created by Bia Shok on 2/8/26.
//

import Foundation
internal import Combine

// MARK: - API Response Models (match server.js JSON schema)

struct BrandAssessment: Codable, Equatable {
    let brand: String
    let summary: String
    let pillars: Pillars
    let overall: OverallRating

    struct Pillars: Codable, Equatable {
        let materials: Pillar
        let labor: Pillar
        let materials_common: Pillar
    }

    struct Pillar: Codable, Equatable {
        let rating: String        // "low" | "medium" | "high"
        let explanation: String
        let evidence: [Evidence]
    }

    struct Evidence: Codable, Equatable {
        let source: String
        let text: String
    }

    struct OverallRating: Codable, Equatable {
        let rating: String        // "low" | "medium" | "high"
        let score: Int?
    }
}

// MARK: - Brand Service

@MainActor
class BrandService: ObservableObject {
    // IMPORTANT: Change this to your machine's local IP when running on a real device.
    // For simulator, localhost works. For a physical iPhone, use your Mac's IP like:
    // static let baseURL = "http://192.168.1.XXX:3000"
    static let baseURL = "http://localhost:3000"

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastAssessment: BrandAssessment?

    // Assess a brand by calling POST /api/brands/assess
    func assessBrand(_ brandName: String) async {
        let trimmed = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a brand name."
            return
        }

        isLoading = true
        errorMessage = nil
        lastAssessment = nil

        defer { isLoading = false }

        guard let url = URL(string: "\(Self.baseURL)/api/brands/assess") else {
            errorMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: String] = ["brand": trimmed]
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            errorMessage = "Failed to encode request."
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let serverError = String(data: data, encoding: .utf8) ?? "Unknown error"
                errorMessage = "Server error (\(httpResponse.statusCode)): \(serverError)"
                return
            }

            let assessment = try JSONDecoder().decode(BrandAssessment.self, from: data)
            lastAssessment = assessment

        } catch let urlError as URLError {
            switch urlError.code {
            case .cannotConnectToHost, .notConnectedToInternet, .timedOut:
                errorMessage = "Cannot connect to server. Make sure server.js is running on port 3000."
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } catch {
            errorMessage = "Failed to parse response: \(error.localizedDescription)"
        }
    }

    // Quick test to check if the API key is working
    func testConnection() async -> (ok: Bool, message: String) {
        guard let url = URL(string: "\(Self.baseURL)/api/brands/test") else {
            return (false, "Invalid URL")
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                return (false, "Server returned \(httpResponse.statusCode)")
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ok = json["ok"] as? Bool {
                let msg = ok
                    ? "Gemini API key is working!"
                    : "API key issue: \(json["error"] as? String ?? "unknown")"
                return (ok, msg)
            }

            return (false, "Unexpected response format")

        } catch {
            return (false, "Cannot reach server: \(error.localizedDescription)")
        }
    }
}
