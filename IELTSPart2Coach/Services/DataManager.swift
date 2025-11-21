//
//  DataManager.swift
//  IELTSPart2Coach
//
//  Phase 7.1.2: JSON-based persistence layer (SwiftData disabled)
//  Stores sessions, topic history, and user progress in lightweight files
//  Designed to avoid first-launch freezes caused by SwiftData schema building
//

import Foundation

@MainActor
class DataManager {
    // MARK: - Singleton

    static let shared = DataManager()

    private init() {
        loadCachedData()
    }

    // MARK: - In-Memory State

    private var sessions: [PracticeSession] = []
    private var topicHistories: [UUID: TopicHistory] = [:]
    private var progress: UserProgress = UserProgress()

    // MARK: - File Paths

    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var recordingsDirectory: URL {
        documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
    }

    private var persistenceDirectory: URL {
        documentsDirectory.appendingPathComponent("Persistence", isDirectory: true)
    }

    private var sessionsURL: URL {
        persistenceDirectory.appendingPathComponent("sessions.json")
    }

    private var topicHistoryURL: URL {
        persistenceDirectory.appendingPathComponent("topicHistory.json")
    }

    private var progressURL: URL {
        persistenceDirectory.appendingPathComponent("userProgress.json")
    }

    // MARK: - Bootstrap

    private func loadCachedData() {
        do {
            try ensureDirectoriesExist()
        } catch {
            #if DEBUG
            print("⚠️ Failed to prepare persistence directories: \(error)")
            #endif
        }

        sessions = load([PracticeSession].self, from: sessionsURL) ?? []
        let histories = load([TopicHistory].self, from: topicHistoryURL) ?? []
        topicHistories = Dictionary(uniqueKeysWithValues: histories.map { ($0.topicID, $0) })
        progress = load(UserProgress.self, from: progressURL) ?? UserProgress()

        #if DEBUG
        print("💾 Persistence loaded: \(sessions.count) sessions, \(topicHistories.count) topics")
        #endif
    }

    private func ensureDirectoriesExist() throws {
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: persistenceDirectory.path) {
            try fileManager.createDirectory(at: persistenceDirectory, withIntermediateDirectories: true)
        }
    }

    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ Failed to load \(url.lastPathComponent): \(error)")
            #endif
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic])
    }

    private func persistSessions() throws {
        try ensureDirectoriesExist()
        try save(sessions, to: sessionsURL)
    }

    private func persistTopicHistories() throws {
        try ensureDirectoriesExist()
        try save(Array(topicHistories.values), to: topicHistoryURL)
    }

    private func persistProgress() throws {
        try ensureDirectoriesExist()
        try save(progress, to: progressURL)
    }

    // MARK: - Audio File Management

    func saveAudioFile(from tempURL: URL, sessionID: UUID) throws -> URL {
        try ensureDirectoriesExist()

        let fileName = "session_\(sessionID.uuidString).wav"
        let destinationURL = recordingsDirectory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        do {
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            #if DEBUG
            print("✅ Audio saved: \(fileName)")
            #endif
            return destinationURL
        } catch {
            throw DataError.audioFileSaveFailed
        }
    }

    func deleteAudioFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }

        do {
            try fileManager.removeItem(at: url)
            #if DEBUG
            print("🗑 Audio deleted: \(url.lastPathComponent)")
            #endif
        } catch {
            throw DataError.audioFileDeleteFailed
        }
    }

    // MARK: - PracticeSession Operations

    func savePracticeSession(
        sessionID: UUID,
        topicID: UUID,
        topicTitle: String,
        audioFileName: String,
        duration: TimeInterval,
        feedback: FeedbackResult? = nil
    ) throws {
        var session = PracticeSession(
            id: sessionID,
            date: Date(),
            topicID: topicID,
            topicTitle: topicTitle,
            audioFileName: audioFileName,
            duration: duration,
            feedback: feedback
        )

        sessions.append(session)
        try persistSessions()

        try updateTopicHistory(for: topicID, with: session)

        if let feedback {
            try updateUserProgress(with: feedback)
        }

        #if DEBUG
        print("✅ PracticeSession saved: \(sessionID)")
        #endif
    }

    func updateSessionFeedback(sessionID: UUID, feedback: FeedbackResult) throws {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw DataError.sessionNotFound
        }

        sessions[index].updateFeedback(feedback)
        try persistSessions()
        try updateUserProgress(with: feedback)
    }

    func updateSessionTranscript(sessionID: UUID, transcript: String) throws {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw DataError.sessionNotFound
        }

        sessions[index].transcript = transcript
        try persistSessions()

        #if DEBUG
        print("✅ Session transcript persisted: \(sessionID)")
        #endif
    }

    func fetchAllSessions() throws -> [PracticeSession] {
        sessions.sorted { $0.date > $1.date }
    }

    func fetchSessions(for topicID: UUID) throws -> [PracticeSession] {
        sessions
            .filter { $0.topicID == topicID }
            .sorted { $0.date > $1.date }
    }

    func fetchSessions(for topicHistory: TopicHistory) throws -> [PracticeSession] {
        sessions.filter { topicHistory.sessionIDs.contains($0.id) }
            .sorted { $0.date > $1.date }
    }

    func fetchSession(id: UUID) throws -> PracticeSession? {
        sessions.first { $0.id == id }
    }

    func deleteSession(_ session: PracticeSession) throws {
        try deleteAudioFile(at: session.audioFileURL)

        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            throw DataError.sessionNotFound
        }

        sessions.remove(at: index)
        try persistSessions()

        // Update topic history
        if var history = topicHistories[session.topicID] {
            history.sessionIDs.removeAll { $0 == session.id }
            history.attemptCount = max(0, history.attemptCount - 1)

            if history.sessionIDs.isEmpty {
                topicHistories.removeValue(forKey: session.topicID)
            } else {
                if let latest = sessions.filter({ history.sessionIDs.contains($0.id) }).max(by: { $0.date < $1.date }) {
                    history.lastAttemptDate = latest.date
                }
                topicHistories[session.topicID] = history
            }

            try persistTopicHistories()
        }

        // Recalculate progress after deletion
        try recalculateUserProgress()

        #if DEBUG
        print("🗑 Session deleted: \(session.id)")
        #endif
    }

    // MARK: - TopicHistory Operations

    private func updateTopicHistory(for topicID: UUID, with session: PracticeSession) throws {
        var history = topicHistories[topicID] ?? TopicHistory(
            topicID: topicID,
            firstAttemptDate: session.date,
            attemptCount: 0,
            lastAttemptDate: session.date,
            sessionIDs: []
        )

        history.recordAttempt(sessionID: session.id, date: session.date)
        topicHistories[topicID] = history
        try persistTopicHistories()
    }

    func fetchAllTopicHistory() throws -> [TopicHistory] {
        Array(topicHistories.values).sorted { $0.lastAttemptDate > $1.lastAttemptDate }
    }

    func fetchTopicHistory(for topicID: UUID) throws -> TopicHistory? {
        topicHistories[topicID]
    }

    // MARK: - UserProgress Operations

    func fetchUserProgress() throws -> UserProgress? {
        progress.totalSessions > 0 ? progress : nil
    }

    private func updateUserProgress(with feedback: FeedbackResult) throws {
        progress.updateWithFeedback(feedback)
        try persistProgress()

        // Phase 7.5: Print trend analysis after update
        #if DEBUG
        if progress.totalSessions >= 10 {
            print("📊 Trend Analysis:")
            print(progress.trendSummary)
        } else {
            print("📊 Trend: Insufficient data (\(progress.totalSessions)/10 sessions)")
        }
        #endif
    }

    private func recalculateUserProgress() throws {
        progress.recalculate(from: sessions)
        try persistProgress()
    }

    // MARK: - Bulk Operations

    func clearAllData() throws {
        // Delete audio files
        if fileManager.fileExists(atPath: recordingsDirectory.path) {
            let files = try fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        }

        sessions.removeAll()
        topicHistories.removeAll()
        progress.reset()

        try persistSessions()
        try persistTopicHistories()
        try persistProgress()

        #if DEBUG
        print("🗑 All data cleared")
        #endif
    }

    // MARK: - Storage Metrics

    func calculateStorageUsage() throws -> (audioSize: Int64, databaseSize: Int64) {
        var audioSize: Int64 = 0
        var databaseSize: Int64 = 0

        if fileManager.fileExists(atPath: recordingsDirectory.path) {
            let files = try fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                audioSize += attributes[.size] as? Int64 ?? 0
            }
        }

        for url in [sessionsURL, topicHistoryURL, progressURL] {
            if fileManager.fileExists(atPath: url.path) {
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                databaseSize += attributes[.size] as? Int64 ?? 0
            }
        }

        return (audioSize, databaseSize)
    }
}

// MARK: - Error Types

enum DataError: LocalizedError {
    case sessionNotFound
    case audioFileSaveFailed
    case audioFileDeleteFailed

    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Practice session not found"
        case .audioFileSaveFailed:
            return "Failed to save audio file"
        case .audioFileDeleteFailed:
            return "Failed to delete audio file"
        }
    }
}
