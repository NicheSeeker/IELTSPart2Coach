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
    func loadTopics() -> [Topic] {
        // Return cached topics if available
        if let cached = cachedTopics {
            return cached
        }

        // Locate JSON file
        guard let url = Bundle.main.url(forResource: "topics", withExtension: "json") else {
            #if DEBUG
            print("⚠️ topics.json not found in bundle")
            #endif
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let topics = try JSONDecoder().decode([Topic].self, from: data)
            cachedTopics = topics

            #if DEBUG
            print("✅ Topics loaded: \(topics.count)")
            #endif
            return topics
        } catch {
            #if DEBUG
            print("❌ Error loading topics: \(error)")
            #endif
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
