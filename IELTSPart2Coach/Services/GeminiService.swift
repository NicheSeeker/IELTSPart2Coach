//
//  GeminiService.swift
//  IELTSPart2Coach
//
//  OpenRouter API client for Gemini 2.5 Flash multimodal analysis
//  Phase 3: Audio analysis with structured feedback
//

import Foundation

@MainActor
class GeminiService {
    static let shared = GeminiService()

    // ✅ Phase 5: Secure API Key Management
    // Priority 1: Keychain (encrypted at rest)
    // Priority 2: Environment variable (Xcode simulator only)
    // Priority 3: First-launch migration (one-time automatic setup)
    private func getAPIKey() throws -> String {
        // Priority 1: Try Keychain first
        do {
            let key = try KeychainManager.shared.getAPIKey()
            #if DEBUG
            print("✅ API key loaded from Keychain")
            #endif
            return key
        } catch KeychainError.keyNotFound {
            // First launch: Try environment variable (simulator only)
            #if DEBUG
            print("🔐 API key not found in Keychain")
            #endif

            // Priority 2: Check environment variable (simulator)
            if let envKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !envKey.isEmpty {
                #if DEBUG
                print("✅ Using API key from environment variable")
                #endif
                try KeychainManager.shared.saveAPIKey(envKey)
                return envKey
            }

            // No API key available - user must configure via Settings
            #if DEBUG
            print("❌ No API key found. Please configure in Settings → AI Service")
            #endif
            throw GeminiError.missingAPIKey
        } catch {
            // Failed to retrieve from Keychain
            throw GeminiError.missingAPIKey
        }
    }

    // Backend Configuration (2025-11-23): Intelligent backend selection
    // Priority: Manual Tunnel URL > Local .local > Localhost (simulator) > Production
    private var baseURL: String {
        #if DEBUG
        // DEBUG Mode: Allow manual configuration via Settings
        if let manualURL = UserDefaults.standard.string(forKey: "manualBackendURL"),
           !manualURL.isEmpty {
            // Priority 1: User-configured Cloudflare Tunnel URL
            // ✅ Bug Fix (2025-11-23): Sanitize URL to prevent crash
            let sanitized = manualURL.trimmingCharacters(in: .whitespacesAndNewlines)

            // Validate URL format
            if URL(string: sanitized) != nil {
                return sanitized
            } else {
                // Invalid URL: clear it and fallback
                #if DEBUG
                print("⚠️ Invalid manual backend URL '\(manualURL)', clearing and using fallback")
                #endif
                UserDefaults.standard.removeObject(forKey: "manualBackendURL")
                // Fall through to Priority 2
            }
        }

        // Priority 2: Local development backend
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8787"  // Simulator: Mac localhost
        #else
        return "http://CharliedeMacBook-Pro.local:8787"  // Real device: Mac .local hostname
        #endif
        #else
        // RELEASE Mode: Force production environment only
        return "https://ielts-api.charliewang0322.workers.dev"
        #endif
    }

    private let model = "google/gemini-2.5-flash"
    private let timeout: TimeInterval = 45.0  // ✅ Optimization 1: Increased from 30s

    private init() {}

    // MARK: - Public Methods

    /// Get current backend URL (for Settings display)
    func getCurrentBackendURL() -> String {
        return baseURL
    }

    // MARK: - Device ID Management (Backend Migration)

    /// Get device ID for backend rate limiting
    /// Generates new UUID if not exists (lazy initialization)
    private func getDeviceID() -> String {
        if let deviceID = try? KeychainManager.shared.getDeviceID() {
            return deviceID
        }
        // Generate new UUID on first API call
        let newID = UUID().uuidString
        try? KeychainManager.shared.saveDeviceID(newID)
        #if DEBUG
        print("🆔 Generated new device ID: \(newID)")
        #endif
        return newID
    }

    // MARK: - API Key Management

    /// Update API key (for Settings UI)
    func updateAPIKey(_ newKey: String) throws {
        guard !newKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        try KeychainManager.shared.saveAPIKey(newKey)

        #if DEBUG
        print("✅ API key updated successfully")
        #endif
    }

    /// Check if API key is configured
    func hasAPIKey() -> Bool {
        return KeychainManager.shared.hasAPIKey()
    }

    // MARK: - Public API

    /// Generate personalized IELTS Part 2 topic based on user progress
    /// Phase 8.2: Minimal implementation - no caching, one request = one topic
    /// - Parameter userProgress: Optional user progress data (if nil, generates generic topic)
    /// - Parameter excludeRecent: Recent topic titles to avoid generating duplicates
    /// - Returns: Generated Topic with title and prompts
    func generatePersonalizedTopic(userProgress: UserProgress?, excludeRecent: [String] = []) async throws -> Topic {
        // Build prompt based on available data
        let prompt = buildTopicPrompt(userProgress: userProgress, excludeRecent: excludeRecent)

        // Create request body (text-only, no audio)
        let requestBody = try buildTopicRequestBody(prompt: prompt)

        // Create request (Backend Migration: use Worker endpoint instead of OpenRouter)
        // ✅ Bug Fix (2025-11-23): Safe URL creation with validation
        guard let url = URL(string: "\(baseURL)/generate-topic") else {
            #if DEBUG
            print("❌ Invalid backend URL: \(baseURL)")
            #endif
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getDeviceID(), forHTTPHeaderField: "X-Device-ID")
        request.httpBody = requestBody

        // Send request
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(for: request)

            // Check HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                // Success - parse topic from response
                return try parseTopicResponse(data: data)

            case 429:
                // Backend Migration: Distinguish daily limit (10/day) from OpenRouter rate limit
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String,
                   error == "dailyLimitReached" {
                    throw GeminiError.dailyLimitReached
                }
                throw GeminiError.rateLimited

            case 400...499, 500...599:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("⚠️ API Error [\(httpResponse.statusCode)]: \(message)")
                throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: message)

            default:
                throw GeminiError.invalidResponse
            }

        } catch let error as GeminiError {
            throw error
        } catch {
            // Network error or timeout
            if (error as NSError).code == NSURLErrorTimedOut {
                throw GeminiError.timeout
            }
            throw GeminiError.networkError(error)
        }
    }

    /// Analyze recorded speech and return structured feedback
    /// ✅ Performance Optimization: Async base64 encoding on background thread
    /// ✅ Memory Optimization: Streaming encoding to avoid dual memory allocation
    func analyzeSpeech(audioURL: URL, duration: TimeInterval) async throws -> FeedbackResult {
        // 1. Base64 encode audio (async, on background thread to avoid UI blocking)
        // 🚀 Optimization: Move 150-200ms I/O operation off main thread
        // 💾 Memory fix: audioData released immediately after encoding
        let base64Audio = try await Task.detached(priority: .userInitiated) {
            // This closure runs on a background thread
            let audioData = try Data(contentsOf: audioURL)
            let sizeKB = audioData.count / 1024

            #if DEBUG
            print("📦 Audio size: \(sizeKB)KB (encoded on background thread)")
            #endif

            // Encode to base64 and return immediately
            // audioData will be automatically deallocated after this line
            let encoded = audioData.base64EncodedString()

            #if DEBUG
            print("✅ Base64 encoded (\(encoded.count) chars), original Data released")
            #endif

            return encoded
        }.value

        // 2. Build request body with duration context
        let requestBody = try buildRequestBody(base64Audio: base64Audio, duration: duration)

        // 3. Create request (Backend Migration: use Worker endpoint instead of OpenRouter)
        // ✅ Bug Fix (2025-11-23): Safe URL creation with validation
        guard let url = URL(string: "\(baseURL)/analyze-speech") else {
            #if DEBUG
            print("❌ Invalid backend URL: \(baseURL)")
            #endif
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getDeviceID(), forHTTPHeaderField: "X-Device-ID")
        request.httpBody = requestBody

        // 4. Send request (ephemeral config to avoid disk caching audio)
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(for: request)

            // 5. Check HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                // Success - parse response and return as-is (trust AI completely)
                let result = try parseResponse(data: data, duration: duration)
                return result

            case 429:
                // Backend Migration: Distinguish daily limit (10/day) from OpenRouter rate limit
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String,
                   error == "dailyLimitReached" {
                    throw GeminiError.dailyLimitReached
                }
                throw GeminiError.rateLimited

            case 400...499, 500...599:
                // API error
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("⚠️ API Error [\(httpResponse.statusCode)]: \(message)")
                throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: message)

            default:
                throw GeminiError.invalidResponse
            }

        } catch let error as GeminiError {
            throw error
        } catch {
            // Network error or timeout
            if (error as NSError).code == NSURLErrorTimedOut {
                throw GeminiError.timeout
            }
            throw GeminiError.networkError(error)
        }
    }

    // MARK: - Private Helpers

    // ✅ Performance Optimization Note:
    // Base64 encoding is now inlined in analyzeSpeech() with async background execution
    // This eliminates 150-200ms UI blocking during file I/O and encoding

    /// Build IELTS examiner prompt with duration context
    private func buildPrompt(duration: TimeInterval) -> String {
        """
        You are a supportive IELTS Speaking coach listening to a Part 2 practice response.

        The speaker recorded for about \(Int(duration)) seconds.

        In IELTS Part 2, candidates typically speak for 1–2 minutes (60–120 seconds) to allow
        full assessment across fluency, vocabulary, grammar, and pronunciation.

        As you listen, consider:

        • How complete is the response? Does it address the topic meaningfully?
        • How developed are the ideas? Are there specific details or examples?
        • How natural is the flow? Does it feel like authentic communication?
        • How appropriate is the language? Consider vocabulary range and grammatical accuracy.
        • How clear is the pronunciation?

        ✅ Scores must remain proportionate to how fully the response demonstrates each skill.
        Short or limited responses cannot receive high bands, even if pronunciation is clear.

        You are a coach, not an examiner — balance honesty with encouragement.
        Short responses naturally show fewer skills, so acknowledge clarity while noting the limits.

        When giving feedback:
        • Acknowledge what was clear or well expressed
        • Be honest if the response is too brief for full evaluation
        • Avoid over-praising incomplete answers
        • Use natural coaching language — not templates
        • For brief answers, you may say: "You expressed your ideas clearly, but only in a few words."

        ⚠️ CRITICAL: If you cannot hear ANY clear human speech in the audio:
           - Set ALL scores to 0.0
           - Set "summary" to "No clear speech detected in the recording."
           - Set "action_tip" to "Please record again with clear voice."
           - Set "quote" to ""

        Examples of non-speech audio that should receive 0.0 scores:
        • Background noise only (air conditioning, traffic, wind)
        • Ambient sounds without human voice
        • Music or instrumental audio
        • Keyboard typing, door closing, or other non-voice sounds
        • Recordings where you can only hear faint breathing or silence

        Return ONLY the following JSON structure:

        {
          "summary": "...",
          "action_tip": "...",
          "bands": {
            "fluency": { "score": 0.0-9.0, "comment": "..." },
            "lexical_resource": { "score": 0.0-9.0, "comment": "..." },
            "grammar": { "score": 0.0-9.0, "comment": "..." },
            "pronunciation": { "score": 0.0-9.0, "comment": "..." }
          },
          "quote": "..."
        }

        Do not add extra fields.

        ----------------------------------------------------
        CRITICAL: Quote guidelines
        ----------------------------------------------------

        1. Authenticity (absolute rule)
           - ONLY quote a phrase you clearly heard in the audio.
           - If uncertain → "quote": ""
           - If the audio content does not match the suggested quote → "quote": ""

        2. Must be natural spoken language
           - Do NOT quote the topic prompt.
           - Do NOT quote formulaic or template-like openings.

        3. Forbidden patterns (absolute blocklist)
           If the spoken phrase resembles these templates → return ""
           - "I would like to describe"
           - "Today I'm going to talk about"
           - "There was a time when"
           - "Let me tell you"
           - "The thing I want to describe"
           - "One thing I'd like to talk about"
           - "I'm going to describe"
           - "I want to share"

        4. Must contain meaningful content
           Valid examples:
           - "the cafe near my school"
           - "my laptop suddenly shut down"
           - "the view was amazing"

           Invalid:
           - Generic or empty phrases
           - Phrases with only articles / prepositions

        5. Short recordings
           - If duration < 12 seconds → always return "quote": ""
           - Short audio is unreliable for quoting

        IMPORTANT:
        If you cannot confidently identify a genuine, meaningful phrase,
        respond with:  "quote": ""

        When in doubt, omit the quote. It is optional enrichment, not required.
        """
    }

    /// Build request body (OpenRouter + audio multimodal)
    private func buildRequestBody(base64Audio: String, duration: TimeInterval) throws -> Data {
        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],  // Force JSON response
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": buildPrompt(duration: duration)],
                        [
                            "type": "input_audio",  // ✅ Correct OpenRouter format
                            "input_audio": [
                                "data": base64Audio,
                                "format": "wav"  // Linear PCM format (compatible with simulator)
                            ]
                        ]
                    ]
                ]
            ]
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }

    /// Build request headers
    /// ✅ Phase 5: Retrieves API key from Keychain (BYOK mode)
    /// ⚠️ Backend Migration (2025-11-22): Deprecated in backend proxy mode
    /// Headers now set individually with X-Device-ID instead of Authorization
    /// Preserved for potential BYOK rollback capability
    @available(*, deprecated, message: "Use individual header setting with X-Device-ID in backend mode")
    private func makeHeaders() throws -> [String: String] {
        let key = try getAPIKey()
        return [
            "Authorization": "Bearer \(key)",
            "Content-Type": "application/json",
            "X-Title": "IELTSPart2Coach",
            "Referer": "https://com.Charlie.IELTSPart2Coach"
        ]
    }

    /// Parse API response
    /// ✅ Optimization 2: Compatible with both string and array content formats
    private func parseResponse(data: Data, duration: TimeInterval) throws -> FeedbackResult {
        do {
            // OpenRouter returns: {"choices": [{"message": {"content": "..." or [...]}}]}
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any] else {
                print("❌ Invalid response structure")
                logRawResponse(data)
                throw GeminiError.invalidResponse
            }

            // Extract content (handle both string and array formats)
            var contentString: String?

            // Try string format first
            if let content = message["content"] as? String {
                contentString = content
            }
            // ✅ Optimization 2: Handle array format
            else if let contents = message["content"] as? [[String: Any]],
                    let textContent = contents.first(where: { $0["type"] as? String == "text" }),
                    let text = textContent["text"] as? String {
                contentString = text
            }

            guard let finalContent = contentString else {
                print("❌ Could not extract content from message")
                logRawResponse(data)
                throw GeminiError.invalidResponse
            }

            // Parse content JSON
            guard let contentData = finalContent.data(using: .utf8) else {
                throw GeminiError.invalidResponse
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(FeedbackResult.self, from: contentData)

            // Validate score ranges
            let allScores = [
                result.bands.fluency.score,
                result.bands.lexical.score,
                result.bands.grammar.score,
                result.bands.pronunciation.score
            ]

            guard allScores.allSatisfy({ $0 >= 0.0 && $0 <= 9.0 }) else {
                print("⚠️ Invalid score range detected")
                throw GeminiError.invalidResponse
            }

            // Sanitize quote before returning (with duration check)
            let sanitizedQuote = sanitizeQuote(result.quote, duration: duration)

            // Return AI response as-is (trust AI completely - product philosophy)
            return FeedbackResult(
                summary: result.summary,
                actionTip: result.actionTip,
                bands: result.bands,
                quote: sanitizedQuote
            )

        } catch let decodingError as DecodingError {
            print("❌ Decoding error: \(decodingError)")
            // 🔍 Print complete response for debugging
            print("🔍 Raw API Response:")
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
            throw GeminiError.invalidResponse
        } catch {
            throw error
        }
    }

    /// Log raw response for debugging (never log audio or API keys)
    private func logRawResponse(_ data: Data) {
        if let jsonString = String(data: data, encoding: .utf8) {
            // Truncate long responses
            let preview = jsonString.prefix(500)
            print("Raw response preview: \(preview)")
        }
    }

    // MARK: - Quote Sanitization

    /// Clean and validate quote from AI response
    /// Returns empty string if quote is invalid, non-English, or from short recordings
    /// - Parameters:
    ///   - quote: Raw quote string from AI response
    ///   - duration: Recording duration in seconds
    /// - Returns: Sanitized quote or empty string if invalid
    private func sanitizeQuote(_ quote: String, duration: TimeInterval) -> String {
        // CRITICAL Rule 4: Short recordings prohibited (<12 seconds)
        guard duration >= 12.0 else {
            return ""
        }

        // Remove all non-English characters, keep only [A-Za-z0-9 ,.'?!-]
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ,.'?!-")
        let filtered = quote.unicodeScalars.filter { allowedCharacterSet.contains($0) }
        let cleaned = String(String.UnicodeScalarView(filtered))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate length: must be between 5-80 characters
        guard cleaned.count >= 5, cleaned.count <= 80 else {
            return ""  // Return empty if too short or too long
        }

        // CRITICAL Rule 3: Filter template language (11 forbidden patterns)
        let forbiddenTemplates = [
            "I would like to describe",
            "Today I'm going to talk about",
            "There was a time when",
            "Let me tell you",
            "The thing I want to describe",
            "I want to talk about",           // variation
            "Let me describe",                 // variation
            "I'm going to tell you about",     // variation
            "One thing I'd like to talk about",
            "I'm going to describe",
            "I want to share"
        ]

        let lowercased = cleaned.lowercased()
        for template in forbiddenTemplates {
            if lowercased.hasPrefix(template.lowercased()) {
                return ""  // Return empty if starts with template phrase
            }
        }

        return cleaned
    }

    // MARK: - Topic Generation Helpers (Phase 8.2)

    /// Build structured prompt for topic generation (Phase 8.2)
    /// Generates generic IELTS topics with structured prompts array
    /// - Parameter excludeRecent: Recent topic titles to avoid duplicates
    private func buildTopicPrompt(userProgress: UserProgress?, excludeRecent: [String]) -> String {
        var prompt = "You are an IELTS Speaking Part 2 topic generator.\n\n"

        // Phase 8.2: Add exclusion list if topics exist
        if !excludeRecent.isEmpty {
            prompt += "IMPORTANT: Avoid generating any topic that is similar to these previously practiced ones:\n"
            for title in excludeRecent {
                prompt += "- \(title)\n"
            }
            prompt += "\nGenerate a NEW, DISTINCT, and DIVERSE topic that is meaningfully different from all the above.\n\n"
        } else {
            // First generation or no history
            prompt += "Generate a DIVERSE and less common IELTS Part 2 topic.\n\n"
        }

        prompt += """
        Prefer less common but still authentic IELTS themes.
        Ensure variety across different topic categories (not just typical textbook topics).

        Generate ONE topic in strict JSON format:

        {
          "title": "Describe a habit you developed recently",
          "prompts": [
            "What the habit is",
            "How you started it",
            "Why it benefits you"
          ]
        }

        RULES:
        - "title": one sentence, imperative form, no ending punctuation
        - "prompts": exactly 3-4 items, 5-10 words each
        - Only return valid JSON, no explanations
        """

        // Add extra emphasis for topics with history
        if !excludeRecent.isEmpty {
            prompt += "\n- The topic must be meaningfully different from all excluded ones"
        }

        prompt += "\n\nOutput ONLY the JSON."

        return prompt
    }

    /// Build request body for topic generation (text-only, no audio)
    private func buildTopicRequestBody(prompt: String) throws -> Data {
        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],  // Force JSON response
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }

    /// Parse topic generation response
    private func parseTopicResponse(data: Data) throws -> Topic {
        do {
            // OpenRouter returns: {"choices": [{"message": {"content": "..." or [...]}}]}
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any] else {
                print("❌ Invalid topic response structure")
                logRawResponse(data)
                throw GeminiError.invalidResponse
            }

            // Extract content (handle both string and array formats)
            var contentString: String?

            if let content = message["content"] as? String {
                contentString = content
            } else if let contents = message["content"] as? [[String: Any]],
                      let textContent = contents.first(where: { $0["type"] as? String == "text" }),
                      let text = textContent["text"] as? String {
                contentString = text
            }

            guard let finalContent = contentString else {
                print("❌ Could not extract content from topic response")
                logRawResponse(data)
                throw GeminiError.invalidResponse
            }

            // Phase 8.2 Bug Fix: Clean Markdown code fence from Gemini response
            // Gemini may return: ```json\n{"title": "..."}\n```
            // We need to extract the pure JSON content
            var cleanedContent = finalContent.trimmingCharacters(in: .whitespacesAndNewlines)

            // Remove ```json prefix and ``` suffix
            if cleanedContent.hasPrefix("```json") {
                cleanedContent = cleanedContent
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if cleanedContent.hasPrefix("```") {
                // Also handle plain ``` without json specifier
                cleanedContent = cleanedContent
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Parse content JSON to extract title and prompts
            guard let contentData = cleanedContent.data(using: .utf8),
                  let topicJson = try JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                  let title = topicJson["title"] as? String,
                  !title.isEmpty else {
                print("❌ Invalid topic format or empty title")
                print("🔍 Cleaned content: \(cleanedContent.prefix(200))")
                logRawResponse(data)
                throw GeminiError.invalidResponse
            }

            // Extract prompts array (Phase 8.2: Structured topic format)
            let prompts = topicJson["prompts"] as? [String]

            // Create Topic with generated title and prompts
            let topic = Topic(id: UUID(), title: title, prompts: prompts)

            #if DEBUG
            print("✨ AI Topic Generated: \(title)")
            #endif

            return topic

        } catch {
            print("❌ Topic parsing error: \(error)")
            logRawResponse(data)
            throw GeminiError.invalidResponse
        }
    }
}

// MARK: - Error Types

enum GeminiError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case timeout
    case rateLimited
    case apiError(statusCode: Int, message: String)
    case missingAPIKey  // ✅ Reserved for Phase 5 (Keychain migration)
    case dailyLimitReached  // Backend Migration (2025-11-22): 10 requests/day per device

    // ✅ Optimization 4: All error messages in English
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed. Please check your internet."
        case .invalidResponse:
            return "Invalid response format."
        case .timeout:
            return "Analysis timed out. Please try again."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .apiError(let statusCode, _):
            return "Analysis failed (code: \(statusCode))."
        case .missingAPIKey:
            return "Missing API Key. Please configure it in Settings."
        case .dailyLimitReached:
            return "That's all for today. Come back tomorrow to continue practicing."
        }
    }
}
