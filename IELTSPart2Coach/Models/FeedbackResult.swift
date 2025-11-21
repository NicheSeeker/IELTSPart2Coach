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
