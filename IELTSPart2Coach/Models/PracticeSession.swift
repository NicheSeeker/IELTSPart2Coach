//
//  PracticeSession.swift
//  IELTSPart2Coach
//
//  Phase 7.1: Practice session persistence model (Codable)
//  Stores metadata for each practice recording (audio URL, duration, AI feedback)
//

import Foundation
struct PracticeSession: Identifiable, Codable {
    // MARK: - Core Properties

    /// Unique identifier (also used in audio filename: session_<id>.m4a)
    var id: UUID

    /// When the recording was made
    var date: Date

    /// Reference to the topic practiced
    var topicID: UUID

    /// Topic title (cached for display, avoid TopicLoader lookups)
    var topicTitle: String

    /// Audio filename (relative path: session_<UUID>.wav)
    /// Stored as filename only to survive app reinstalls (container path changes)
    var audioFileName: String

    /// Recording duration in seconds
    var duration: TimeInterval

    /// Optional AI feedback result (nil if not analyzed yet)
    var feedback: FeedbackResult?

    /// Optional speech-to-text transcript (Phase 8.1, nil if disabled or failed)
    var transcript: String?

    // MARK: - Computed Properties

    /// Dynamically construct full audio file URL (survives app reinstalls)
    var audioFileURL: URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let recordingsURL = documentsURL.appendingPathComponent("Recordings", isDirectory: true)
        return recordingsURL.appendingPathComponent(audioFileName)
    }

    /// Check if session has AI feedback
    var hasFeedback: Bool {
        feedback != nil
    }

    /// Check if session has speech transcript (Phase 8.1)
    var hasTranscript: Bool {
        transcript != nil && !transcript!.isEmpty
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        topicID: UUID,
        topicTitle: String,
        audioFileName: String,
        duration: TimeInterval,
        feedback: FeedbackResult? = nil,
        transcript: String? = nil
    ) {
        self.id = id
        self.date = date
        self.topicID = topicID
        self.topicTitle = topicTitle
        self.audioFileName = audioFileName
        self.duration = duration
        self.feedback = feedback
        self.transcript = transcript
    }

    // MARK: - Helper Methods

    /// Update feedback after AI analysis
    mutating func updateFeedback(_ feedbackResult: FeedbackResult) {
        feedback = feedbackResult

        #if DEBUG
        print("✅ PracticeSession \(id): Feedback updated")
        #endif
    }
}

// MARK: - Display Helpers

extension PracticeSession {
    /// Formatted duration (MM:SS)
    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Absolute date string (for grouping in History)
    var absoluteDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
