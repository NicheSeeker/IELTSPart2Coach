//
//  StreakManager.swift
//  IELTSPart2Coach
//
//  Phase 9: Streak tracking for user retention
//  Lightweight UserDefaults-backed singleton
//

import Foundation

@MainActor
@Observable
class StreakManager {
    static let shared = StreakManager()

    private let lastPracticeDateKey = "streak_lastPracticeDate"
    private let currentStreakKey = "streak_currentStreak"

    var currentStreak: Int = 0 {
        didSet { UserDefaults.standard.set(currentStreak, forKey: currentStreakKey) }
    }

    private var lastPracticeDate: Date? {
        get { UserDefaults.standard.object(forKey: lastPracticeDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastPracticeDateKey) }
    }

    private init() {
        currentStreak = UserDefaults.standard.integer(forKey: currentStreakKey)
        validateStreak()
    }

    /// Call after AI feedback is successfully received
    func recordPractice() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastPracticeDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay == today { return } // Same day, don't double count

            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            currentStreak = (daysBetween == 1) ? currentStreak + 1 : 1
        } else {
            currentStreak = 1
        }

        lastPracticeDate = Date()

        #if DEBUG
        print("🔥 Streak updated: \(currentStreak) day(s)")
        #endif
    }

    /// Validate streak hasn't lapsed (call on init)
    private func validateStreak() {
        guard let lastDate = lastPracticeDate else { return }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day],
            from: calendar.startOfDay(for: lastDate),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        if daysSince > 1 {
            currentStreak = 0
        }
    }

    /// Reset streak (for Clear All History)
    func reset() {
        currentStreak = 0
        UserDefaults.standard.removeObject(forKey: lastPracticeDateKey)
    }
}
