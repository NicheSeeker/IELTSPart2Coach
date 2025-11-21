//
//  HistoryViewModel.swift
//  IELTSPart2Coach
//
//  Phase 7.2: History View state management
//  Independent AudioPlayer instance for playback isolation
//

import Foundation
import Observation

@MainActor
@Observable
class HistoryViewModel {
    // MARK: - Published State

    var sessions: [PracticeSession] = []
    var isLoading = false
    var selectedSession: PracticeSession?
    var showPlaybackSheet = false
    var deleteError: Error?

    // MARK: - Private Properties

    private let audioPlayer = AudioPlayer()
    private let dataManager = DataManager.shared

    // MARK: - Computed Properties

    /// Group sessions by date ("Today", "Yesterday", "Dec 1, 2024")
    var groupedSessions: [(dateString: String, sessions: [PracticeSession])] {
        let calendar = Calendar.current
        let now = Date()

        // Group by start of day
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }

        // Convert to sorted array with date strings
        return grouped.map { date, sessions in
            let dateString = formatDateGroup(date, relativeTo: now)
            let sortedSessions = sessions.sorted { $0.date > $1.date }
            return (dateString, sortedSessions)
        }
        .sorted { first, second in
            // Sort groups by date (newest first)
            // ✅ FIX: Use each group's first session date, not outer scope's sessions array
            guard let firstDate = first.sessions.first?.date,
                  let secondDate = second.sessions.first?.date else {
                return false
            }
            return firstDate > secondDate
        }
    }

    // MARK: - Audio Player State (Passthrough)

    var isPlaying: Bool {
        audioPlayer.isPlaying
    }

    var playbackProgress: Double {
        audioPlayer.progress
    }

    var playbackTimeString: String {
        audioPlayer.timeString
    }

    var hasFinishedPlayback: Bool {
        audioPlayer.hasFinished
    }

    // MARK: - Lifecycle

    init() {
        // HistoryViewModel uses its own AudioPlayer instance
        // Independent from RecordingViewModel to avoid state conflicts
    }

    // MARK: - Data Loading

    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sessions = try dataManager.fetchAllSessions()

            #if DEBUG
            print("📚 Loaded \(sessions.count) sessions from history")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load sessions: \(error)")
            #endif
            sessions = []
        }
    }

    // MARK: - Playback Control

    /// Play selected session (opens Sheet)
    /// ✅ FIX: Load audio but don't auto-play - user manually controls playback
    func playSession(_ session: PracticeSession) async {
        selectedSession = session

        // Wait 100ms for UI transition
        try? await Task.sleep(nanoseconds: 100_000_000)

        do {
            try audioPlayer.load(url: session.audioFileURL)
            // ✅ REMOVED: audioPlayer.play() - user will click "Play" button to start
            showPlaybackSheet = true

            #if DEBUG
            print("🎵 Loaded session (ready to play): \(session.id)")
            #endif
        } catch {
            // Phase 7.2 Bug Fix: Show error and auto-delete corrupted session
            deleteError = HistoryError.audioFileNotFound(session.topicTitle)
            selectedSession = nil

            #if DEBUG
            print("❌ Failed to load session: \(error)")
            print("🗑 Auto-deleting session with missing audio file")
            #endif

            // Automatically remove corrupted session
            await deleteSession(session)
        }
    }

    /// Toggle playback (called from Sheet)
    func togglePlayback() {
        audioPlayer.togglePlayback()
    }

    /// Seek to specific playback position (called from circular ring drag)
    func seekPlayback(toProgress progress: Double) {
        audioPlayer.seek(toProgress: progress)

        #if DEBUG
        print("🔄 Seeked to \(Int(progress * 100))%")
        #endif
    }

    /// Stop playback (called when Sheet dismisses)
    func stopPlayback() {
        audioPlayer.stop()
        selectedSession = nil
    }

    // MARK: - Session Management

    /// Delete a session (audio file + database record)
    func deleteSession(_ session: PracticeSession) async {
        do {
            try dataManager.deleteSession(session)

            // Remove from local array
            sessions.removeAll { $0.id == session.id }

            #if DEBUG
            print("🗑 Deleted session: \(session.id)")
            #endif
        } catch {
            deleteError = error

            #if DEBUG
            print("❌ Failed to delete session: \(error)")
            #endif
        }
    }

    // MARK: - Date Formatting

    /// Format date group string (Today, Yesterday, or absolute date)
    private func formatDateGroup(_ date: Date, relativeTo now: Date) -> String {
        let calendar = Calendar.current

        // Today
        if calendar.isDateInToday(date) {
            return "Today"
        }

        // Yesterday
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        // Within last 7 days: "3 days ago"
        let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if daysDiff > 0 && daysDiff <= 7 {
            return "\(daysDiff) day\(daysDiff == 1 ? "" : "s") ago"
        }

        // Older: Absolute date "Dec 1, 2024"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Error Types (Phase 7.2 Bug Fix)

enum HistoryError: LocalizedError {
    case audioFileNotFound(String)  // Topic title

    var errorDescription: String? {
        switch self {
        case .audioFileNotFound(let title):
            return "Audio file not found for '\(title)'. This session will be removed from history."
        }
    }
}
