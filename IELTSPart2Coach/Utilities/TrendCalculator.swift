//
//  TrendCalculator.swift
//  IELTSPart2Coach
//
//  Phase 7.5: Trend analysis pure functions
//  Calculates score improvement/decline/stability for each band category
//  Architecture: Stateless utility with pure functions for testability
//

import Foundation

// MARK: - Trend Direction

/// Represents the direction of score change over time
enum TrendDirection {
    case improving      // Score increased by >= 0.3 (latest 5 vs previous 5)
    case declining      // Score decreased by >= 0.3 (latest 5 vs previous 5)
    case stable         // Change within ±0.3 range
    case insufficient   // < 10 sessions available
}

// MARK: - Trend Calculator

/// Stateless utility for calculating IELTS score trends
/// All methods are pure functions for easy testing
struct TrendCalculator {
    // MARK: - Public API

    /// Calculate trend for specific band category
    /// - Parameters:
    ///   - sessions: All practice sessions (will be filtered for feedback)
    ///   - category: Which band to analyze (fluency/lexical/grammar/pronunciation)
    /// - Returns: Trend direction based on ±0.3 threshold
    static func calculateTrend(
        sessions: [PracticeSession],
        category: BandCategory
    ) -> TrendDirection {
        // Extract sessions with feedback and their scores
        let sessionsWithScores = sessions.compactMap { session -> (Date, Double)? in
            guard let feedback = session.feedback else { return nil }
            let score = getScore(from: feedback.bands, category: category)
            return (session.date, score)
        }

        // Require minimum 10 sessions for meaningful trend analysis
        guard sessionsWithScores.count >= 10 else {
            return .insufficient
        }

        // Sort by date (oldest first) to ensure chronological order
        let sorted = sessionsWithScores.sorted { $0.0 < $1.0 }

        // Split into two halves: previous 5 vs latest 5
        // Example: 12 sessions → compare sessions [2-6] vs [7-11]
        let count = sorted.count
        let previousFive = Array(sorted[(count - 10)..<(count - 5)])
        let latestFive = Array(sorted[(count - 5)..<count])

        // Calculate averages for both periods
        let previousAvg = previousFive.map { $0.1 }.reduce(0, +) / 5.0
        let latestAvg = latestFive.map { $0.1 }.reduce(0, +) / 5.0

        // Determine trend based on ±0.3 threshold (half IELTS band)
        let diff = latestAvg - previousAvg

        if diff >= 0.3 {
            return .improving
        } else if diff <= -0.3 {
            return .declining
        } else {
            return .stable
        }
    }

    /// Calculate overall trend (average of 4 bands)
    /// - Parameter sessions: All practice sessions
    /// - Returns: Trend direction for overall performance
    static func calculateOverallTrend(sessions: [PracticeSession]) -> TrendDirection {
        // Extract sessions with feedback and calculate overall scores
        let sessionsWithScores = sessions.compactMap { session -> (Date, Double)? in
            guard let feedback = session.feedback else { return nil }

            // Overall = average of 4 band categories
            let overallScore = (
                feedback.bands.fluency.score +
                feedback.bands.lexical.score +
                feedback.bands.grammar.score +
                feedback.bands.pronunciation.score
            ) / 4.0

            return (session.date, overallScore)
        }

        // Require minimum 10 sessions
        guard sessionsWithScores.count >= 10 else {
            return .insufficient
        }

        // Sort by date (oldest first)
        let sorted = sessionsWithScores.sorted { $0.0 < $1.0 }

        // Split into two halves: previous 5 vs latest 5
        let count = sorted.count
        let previousFive = Array(sorted[(count - 10)..<(count - 5)])
        let latestFive = Array(sorted[(count - 5)..<count])

        // Calculate averages
        let previousAvg = previousFive.map { $0.1 }.reduce(0, +) / 5.0
        let latestAvg = latestFive.map { $0.1 }.reduce(0, +) / 5.0

        // Determine trend based on ±0.3 threshold
        let diff = latestAvg - previousAvg

        if diff >= 0.3 {
            return .improving
        } else if diff <= -0.3 {
            return .declining
        } else {
            return .stable
        }
    }

    // MARK: - Helper Methods

    /// Extract score for specific category from band scores
    private static func getScore(from bands: BandScores, category: BandCategory) -> Double {
        switch category {
        case .fluency:
            return bands.fluency.score
        case .lexical:
            return bands.lexical.score
        case .grammar:
            return bands.grammar.score
        case .pronunciation:
            return bands.pronunciation.score
        }
    }
}

// MARK: - Display Helpers

extension TrendDirection {
    /// Symbol for visual representation (↗/↘/→/—)
    var symbol: String {
        switch self {
        case .improving:
            return "↗"
        case .declining:
            return "↘"
        case .stable:
            return "→"
        case .insufficient:
            return "—"
        }
    }

    /// Human-readable description
    var description: String {
        switch self {
        case .improving:
            return "Improving"
        case .declining:
            return "Declining"
        case .stable:
            return "Stable"
        case .insufficient:
            return "Insufficient data"
        }
    }

    /// Detailed explanation (for DEBUG logs)
    var detailedDescription: String {
        switch self {
        case .improving:
            return "Score increased by ≥0.3 (latest 5 sessions vs previous 5)"
        case .declining:
            return "Score decreased by ≥0.3 (latest 5 sessions vs previous 5)"
        case .stable:
            return "Score change within ±0.3 range (stable performance)"
        case .insufficient:
            return "Need at least 10 sessions with feedback for trend analysis"
        }
    }
}
