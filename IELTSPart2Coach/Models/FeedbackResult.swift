//
//  FeedbackResult.swift
//  IELTSPart2Coach
//
//  AI feedback response model from Gemini
//  Phase 3: Data structure for parsed API response
//

import Foundation

struct FeedbackResult: Codable, Identifiable {
    let id = UUID()
    let summary: String
    let actionTip: String
    let bands: BandScores
    let quote: String

    enum CodingKeys: String, CodingKey {
        case summary
        case actionTip = "action_tip"
        case bands
        case quote
    }
}

struct BandScores: Codable {
    let fluency: BandScore
    let lexical: BandScore
    let grammar: BandScore
    let pronunciation: BandScore

    enum CodingKeys: String, CodingKey {
        case fluency
        case lexical = "lexical_resource"  // Gemini uses "lexical_resource" instead of "lexical"
        case grammar
        case pronunciation
    }
}

struct BandScore: Codable {
    let score: Double  // 0.0-9.0
    let comment: String

    var displayScore: String {
        String(format: "%.1f", score)
    }
}

// MARK: - BandScores Extensions

extension BandScores {
    /// Calculate average score rounded to nearest 0.5 (IELTS standard)
    /// IELTS only uses whole numbers (6.0, 7.0) and half scores (6.5, 7.5)
    var averageScore: Double {
        let raw = (fluency.score + lexical.score + grammar.score + pronunciation.score) / 4.0
        return (raw * 2).rounded() / 2  // Round to nearest 0.5
    }

    /// Display average score in IELTS format
    /// - Returns: "6" for 6.0, "6.5" for 6.5 (no trailing .0 for whole numbers)
    var averageDisplayScore: String {
        if averageScore.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", averageScore)  // Display as "6" not "6.0"
        } else {
            return String(format: "%.1f", averageScore)  // Display as "6.5"
        }
    }
}
