//
//  TopicHistory.swift
//  IELTSPart2Coach
//
//  Phase 7.1: Persistence model for tracking topic practice records
//  Stores how many times each topic has been practiced, when first/last attempted
//  Maintains relationship to all practice sessions for that topic
//

import Foundation
struct TopicHistory: Identifiable, Codable {
    // MARK: - Core Properties

    /// Topic identifier (matches Topic.id from topics.json)
    var topicID: UUID

    /// When this topic was first practiced
    var firstAttemptDate: Date

    /// Total number of practice sessions for this topic
    var attemptCount: Int

    /// When this topic was most recently practiced
    var lastAttemptDate: Date

    // MARK: - Session Tracking

    /// Use simple UUID array instead of heavy relationships
    /// Session objects can be fetched separately when needed
    var sessionIDs: [UUID]

    var id: UUID { topicID }

    // MARK: - Computed Properties

    /// Check if topic was practiced today
    var isPracticedToday: Bool {
        Calendar.current.isDateInToday(lastAttemptDate)
    }

    /// Check if topic should be repeated (3+ days since last attempt)
    var shouldRepeat: Bool {
        let daysSinceLastAttempt = Calendar.current.dateComponents(
            [.day],
            from: lastAttemptDate,
            to: Date()
        ).day ?? 0

        return daysSinceLastAttempt >= 3
    }

    /// ⚡ PERFORMANCE FIX: Removed computed properties that required relationship
    /// Use DataManager to fetch sessions when needed:
    /// - DataManager.shared.getSession(id: sessionID)
    /// - DataManager.shared.getSessionsForTopic(topicID: topicID)

    // MARK: - Initialization

    init(
        topicID: UUID,
        firstAttemptDate: Date = Date(),
        attemptCount: Int = 1,
        lastAttemptDate: Date = Date(),
        sessionIDs: [UUID] = []
    ) {
        self.topicID = topicID
        self.firstAttemptDate = firstAttemptDate
        self.attemptCount = attemptCount
        self.lastAttemptDate = lastAttemptDate
        self.sessionIDs = sessionIDs
    }

    // MARK: - Helper Methods

    /// Record a new practice session for this topic
    /// ⚡ PERFORMANCE FIX: Only store session ID, not the full object
    mutating func recordAttempt(sessionID: UUID, date: Date = Date()) {
        sessionIDs.append(sessionID)
        attemptCount += 1
        lastAttemptDate = date

        #if DEBUG
        print("✅ TopicHistory \(topicID): Attempt #\(attemptCount) recorded (session: \(sessionID))")
        #endif
    }

    /// Update last attempt date (for manual corrections)
    mutating func updateLastAttempt(to date: Date) {
        lastAttemptDate = date

        #if DEBUG
        print("✅ TopicHistory \(topicID): Last attempt updated to \(date)")
        #endif
    }
}

// MARK: - Display Helpers

extension TopicHistory {
    /// Formatted string for attempt count ("1 time", "5 times")
    var attemptCountString: String {
        attemptCount == 1 ? "1 time" : "\(attemptCount) times"
    }

    /// Relative date string for last attempt ("Today", "3 days ago")
    var lastAttemptRelativeString: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(lastAttemptDate) {
            return "Today"
        } else if calendar.isDateInYesterday(lastAttemptDate) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: lastAttemptDate, to: now).day ?? 0
            if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
            } else {
                let months = calendar.dateComponents([.month], from: lastAttemptDate, to: now).month ?? 0
                return months == 1 ? "1 month ago" : "\(months) months ago"
            }
        }
    }

    /// Absolute date string for first attempt (for History grouping)
    var firstAttemptDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: firstAttemptDate)
    }

    /// Practice streak indicator (days since first attempt)
    var practiceStreak: Int {
        Calendar.current.dateComponents(
            [.day],
            from: firstAttemptDate,
            to: Date()
        ).day ?? 0
    }
}
