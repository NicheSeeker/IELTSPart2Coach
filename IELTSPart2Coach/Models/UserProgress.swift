//
//  UserProgress.swift
//  IELTSPart2Coach
//
//  Phase 7.1: Aggregated user progress model (Codable)
//  Stores total sessions count and average band scores across all practice
//  Updates in real-time after each session with AI feedback
//

import Foundation
struct UserProgress: Codable {
    // MARK: - Core Properties

    /// Unique identifier (singleton pattern: only one UserProgress instance)
    var id: UUID

    /// Total number of practice sessions with AI feedback
    var totalSessions: Int

    /// Average Fluency & Coherence score (0.0-9.0)
    var averageFluency: Double

    /// Average Lexical Resource score (0.0-9.0)
    var averageLexical: Double

    /// Average Grammar Range & Accuracy score (0.0-9.0)
    var averageGrammar: Double

    /// Average Pronunciation score (0.0-9.0)
    var averagePronunciation: Double

    /// When progress was last updated
    var lastUpdated: Date

    // MARK: - Computed Properties

    /// Overall average band score (average of 4 categories)
    var overallAverage: Double {
        guard totalSessions > 0 else { return 0.0 }
        return (averageFluency + averageLexical + averageGrammar + averagePronunciation) / 4.0
    }

    /// Identify weakest band category
    var weakestCategory: String {
        let scores = [
            ("Fluency", averageFluency),
            ("Lexical", averageLexical),
            ("Grammar", averageGrammar),
            ("Pronunciation", averagePronunciation)
        ]

        return scores.min { $0.1 < $1.1 }?.0 ?? "None"
    }

    /// Identify strongest band category
    var strongestCategory: String {
        let scores = [
            ("Fluency", averageFluency),
            ("Lexical", averageLexical),
            ("Grammar", averageGrammar),
            ("Pronunciation", averagePronunciation)
        ]

        return scores.max { $0.1 < $1.1 }?.0 ?? "None"
    }

    /// Check if user has enough data for meaningful analysis (minimum 5 sessions)
    var hasEnoughData: Bool {
        totalSessions >= 5
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        totalSessions: Int = 0,
        averageFluency: Double = 0.0,
        averageLexical: Double = 0.0,
        averageGrammar: Double = 0.0,
        averagePronunciation: Double = 0.0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.totalSessions = totalSessions
        self.averageFluency = averageFluency
        self.averageLexical = averageLexical
        self.averageGrammar = averageGrammar
        self.averagePronunciation = averagePronunciation
        self.lastUpdated = lastUpdated
    }

    // MARK: - Helper Methods

    /// Update progress with new feedback result (incremental update)
    mutating func updateWithFeedback(_ feedback: FeedbackResult) {
        let n = Double(totalSessions)
        let newN = n + 1

        // Incremental average formula: new_avg = (old_avg * n + new_value) / (n + 1)
        averageFluency = (averageFluency * n + feedback.bands.fluency.score) / newN
        averageLexical = (averageLexical * n + feedback.bands.lexical.score) / newN
        averageGrammar = (averageGrammar * n + feedback.bands.grammar.score) / newN
        averagePronunciation = (averagePronunciation * n + feedback.bands.pronunciation.score) / newN

        totalSessions += 1
        lastUpdated = Date()

        #if DEBUG
        print("✅ UserProgress updated: Session #\(totalSessions)")
        print("   Overall Average: \(String(format: "%.1f", overallAverage))")
        print("   Weakest: \(weakestCategory), Strongest: \(strongestCategory)")

        // Phase 7.5: Print trend analysis if enough data
        if totalSessions >= 10 {
            print("   \(trendSummary.replacingOccurrences(of: "\n", with: "\n   "))")
        }
        #endif
    }

    /// Recalculate all averages from scratch (for data corrections or migrations)
    mutating func recalculate(from sessions: [PracticeSession]) {
        // Filter sessions with feedback
        let sessionsWithFeedback = sessions.compactMap(\.feedback)

        guard !sessionsWithFeedback.isEmpty else {
            reset()
            return
        }

        totalSessions = sessionsWithFeedback.count

        averageFluency = sessionsWithFeedback.map { $0.bands.fluency.score }.reduce(0, +) / Double(totalSessions)
        averageLexical = sessionsWithFeedback.map { $0.bands.lexical.score }.reduce(0, +) / Double(totalSessions)
        averageGrammar = sessionsWithFeedback.map { $0.bands.grammar.score }.reduce(0, +) / Double(totalSessions)
        averagePronunciation = sessionsWithFeedback.map { $0.bands.pronunciation.score }.reduce(0, +) / Double(totalSessions)

        lastUpdated = Date()

        #if DEBUG
        print("✅ UserProgress recalculated from \(totalSessions) sessions")
        print("   Overall Average: \(String(format: "%.1f", overallAverage))")
        #endif
    }

    /// Reset all progress data (for "Clear All History" action)
    mutating func reset() {
        totalSessions = 0
        averageFluency = 0.0
        averageLexical = 0.0
        averageGrammar = 0.0
        averagePronunciation = 0.0
        lastUpdated = Date()

        #if DEBUG
        print("🔄 UserProgress reset to zero")
        #endif
    }
}

// MARK: - Display Helpers

extension UserProgress {
    /// Formatted overall average (1 decimal place)
    var overallAverageString: String {
        guard totalSessions > 0 else { return "N/A" }
        return String(format: "%.1f", overallAverage)
    }

    /// Formatted individual band scores (1 decimal place)
    var fluencyString: String {
        guard totalSessions > 0 else { return "N/A" }
        return String(format: "%.1f", averageFluency)
    }

    var lexicalString: String {
        guard totalSessions > 0 else { return "N/A" }
        return String(format: "%.1f", averageLexical)
    }

    var grammarString: String {
        guard totalSessions > 0 else { return "N/A" }
        return String(format: "%.1f", averageGrammar)
    }

    var pronunciationString: String {
        guard totalSessions > 0 else { return "N/A" }
        return String(format: "%.1f", averagePronunciation)
    }

    /// Relative date string for last update
    var lastUpdatedString: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(lastUpdated) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: lastUpdated))"
        } else if calendar.isDateInYesterday(lastUpdated) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: lastUpdated, to: now).day ?? 0
            if days < 7 {
                return "\(days) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter.string(from: lastUpdated)
            }
        }
    }

    /// Progress summary for display
    var summaryText: String {
        guard totalSessions > 0 else {
            return "No practice sessions yet"
        }

        return """
        \(totalSessions) session\(totalSessions == 1 ? "" : "s") completed
        Overall: \(overallAverageString)
        Strongest: \(strongestCategory) | Weakest: \(weakestCategory)
        """
    }
}

// MARK: - Trend Analysis (Phase 7.5)

extension UserProgress {
    /// Fluency & Coherence trend (requires >= 10 sessions)
    /// Dynamically computed from all practice sessions
    var fluencyTrend: TrendDirection {
        guard let sessions = try? DataManager.shared.fetchAllSessions() else {
            return .insufficient
        }
        return TrendCalculator.calculateTrend(sessions: sessions, category: .fluency)
    }

    /// Lexical Resource trend (requires >= 10 sessions)
    /// Dynamically computed from all practice sessions
    var lexicalTrend: TrendDirection {
        guard let sessions = try? DataManager.shared.fetchAllSessions() else {
            return .insufficient
        }
        return TrendCalculator.calculateTrend(sessions: sessions, category: .lexical)
    }

    /// Grammar Range & Accuracy trend (requires >= 10 sessions)
    /// Dynamically computed from all practice sessions
    var grammarTrend: TrendDirection {
        guard let sessions = try? DataManager.shared.fetchAllSessions() else {
            return .insufficient
        }
        return TrendCalculator.calculateTrend(sessions: sessions, category: .grammar)
    }

    /// Pronunciation trend (requires >= 10 sessions)
    /// Dynamically computed from all practice sessions
    var pronunciationTrend: TrendDirection {
        guard let sessions = try? DataManager.shared.fetchAllSessions() else {
            return .insufficient
        }
        return TrendCalculator.calculateTrend(sessions: sessions, category: .pronunciation)
    }

    /// Overall trend across all 4 bands (requires >= 10 sessions)
    /// Dynamically computed from all practice sessions
    var overallTrend: TrendDirection {
        guard let sessions = try? DataManager.shared.fetchAllSessions() else {
            return .insufficient
        }
        return TrendCalculator.calculateOverallTrend(sessions: sessions)
    }

    /// Formatted trend summary for DEBUG output
    /// Shows all 5 trends with symbols and descriptions
    var trendSummary: String {
        """
        Overall: \(overallTrend.symbol) \(overallTrend.description)
        Fluency: \(fluencyTrend.symbol) \(fluencyTrend.description)
        Lexical: \(lexicalTrend.symbol) \(lexicalTrend.description)
        Grammar: \(grammarTrend.symbol) \(grammarTrend.description)
        Pronunciation: \(pronunciationTrend.symbol) \(pronunciationTrend.description)
        """
    }

    /// Detailed trend analysis for DEBUG (includes explanations)
    var trendDetailedSummary: String {
        """
        📊 Trend Analysis (Latest 5 vs Previous 5 sessions):

        Overall: \(overallTrend.symbol) \(overallTrend.description)
        → \(overallTrend.detailedDescription)

        Fluency: \(fluencyTrend.symbol) \(fluencyTrend.description)
        Lexical: \(lexicalTrend.symbol) \(lexicalTrend.description)
        Grammar: \(grammarTrend.symbol) \(grammarTrend.description)
        Pronunciation: \(pronunciationTrend.symbol) \(pronunciationTrend.description)
        """
    }
}
