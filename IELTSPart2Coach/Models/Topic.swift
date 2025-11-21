//
//  Topic.swift
//  IELTSPart2Coach
//
//  IELTS Part 2 speaking topic model
//

import Foundation

/// Represents an IELTS Part 2 speaking topic
struct Topic: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let prompts: [String]?  // Phase 8.2: Optional bullet points for structured topics
}

// MARK: - Topic Loader

class TopicLoader {
    static let shared = TopicLoader()

    private var cachedTopics: [Topic]?

    private init() {}

    /// Load all topics from the bundled JSON file
    /// ⏱️ DIAGNOSTIC: Synchronous file I/O - measuring exact time
    func loadTopics() -> [Topic] {
        // ⏱️ DIAGNOSTIC: Measure total loading time
        let t0 = CFAbsoluteTimeGetCurrent()
        print("📚 [0ms] TopicLoader.loadTopics() START")

        // Return cached topics if available
        if let cached = cachedTopics {
            let elapsed = (CFAbsoluteTimeGetCurrent() - t0) * 1000
            print("📚 [\(Int(elapsed))ms] Returning cached topics: \(cached.count)")
            return cached
        }

        // Locate JSON file
        let t1 = CFAbsoluteTimeGetCurrent()
        print("📚 [\(Int((t1 - t0) * 1000))ms] Loading topics.json from bundle...")
        guard let url = Bundle.main.url(forResource: "topics", withExtension: "json") else {
            print("⚠️ topics.json not found in bundle")
            return []
        }

        do {
            // ⏱️ CRITICAL: Measure file I/O time
            let t2 = CFAbsoluteTimeGetCurrent()
            print("📚 [\(Int((t2 - t0) * 1000))ms] Reading JSON file (synchronous I/O)...")
            let data = try Data(contentsOf: url)
            let t3 = CFAbsoluteTimeGetCurrent()
            let ioTime = (t3 - t2) * 1000
            print("📚 [\(Int((t3 - t0) * 1000))ms] File read complete (I/O took \(Int(ioTime))ms, size: \(data.count) bytes)")

            // ⏱️ CRITICAL: Measure JSON decode time
            let t4 = CFAbsoluteTimeGetCurrent()
            print("📚 [\(Int((t4 - t0) * 1000))ms] Decoding JSON...")
            let topics = try JSONDecoder().decode([Topic].self, from: data)
            let t5 = CFAbsoluteTimeGetCurrent()
            let decodeTime = (t5 - t4) * 1000
            print("📚 [\(Int((t5 - t0) * 1000))ms] JSON decoded (took \(Int(decodeTime))ms)")

            cachedTopics = topics

            let totalTime = (CFAbsoluteTimeGetCurrent() - t0) * 1000
            print("✅ [\(Int(totalTime))ms] Topics loaded: \(topics.count)")
            return topics
        } catch {
            print("❌ Error loading topics: \(error)")
            return []
        }
    }

    /// Get a random topic
    func randomTopic() -> Topic? {
        loadTopics().randomElement()
    }

    /// Get topic by ID
    func topic(by id: UUID) -> Topic? {
        loadTopics().first { $0.id == id }
    }
}
