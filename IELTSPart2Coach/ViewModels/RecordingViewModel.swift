//
//  RecordingViewModel.swift
//  IELTSPart2Coach
//
//  State machine for recording flow
//  Manages: idle → recording → finished → analyzing states
//

import AVFoundation
import Foundation
import Speech
import SwiftUI

@MainActor
@Observable
class RecordingViewModel {
    // MARK: - State

    enum RecordingState {
        case idle           // Initial state, show Start button
        case preparing      // Preparation countdown (60s)
        case recording      // Recording in progress (0-120s)
        case finished       // Recording complete, can playback
        case analyzing      // AI analyzing the recording
    }

    enum AnalysisStage {
        case encoding       // Encoding audio to base64
        case uploading      // Uploading to API
        case analyzing      // AI processing
        case preparing      // Preparing feedback display
    }

    var state: RecordingState = .idle
    var analysisStage: AnalysisStage? = nil  // Current analysis stage (nil when not analyzing)
    var elapsedTime: TimeInterval = 0
    var showStopButton = false                  // For recording state (after 60s)
    var currentTopic: Topic?
    var isGeneratingTopic = false               // Phase 8.2: AI topic generation in progress

    // Phase 8.2: Topic history tracking (avoid duplicates)
    private var recentTopicTitles: [String] = []  // Last 5 generated topics
    private let maxRecentTopics = 5
    private let recentTopicsKey = "recentTopicTitles"
    var showFallbackToast = false  // Show toast when using backup topic

    // MARK: - Preparation State (Phase 4.5)

    var preparationTimeLeft: TimeInterval = 60  // Countdown timer (60 → 0)
    var showSkipButton = false                  // Show Skip button after threshold (10s)
    var showTransitionOverlay = false           // Phase 4.6: Show transition overlay (1.2s)

    // MARK: - Analysis State (Phase 3)

    var feedbackResult: FeedbackResult?
    var analysisError: Error?
    var showFeedbackSheet = false

    // MARK: - Transcript State (Phase 8.1)

    var currentTranscript: String? = nil  // Current session transcript (for FeedbackView)

    // MARK: - Recording Error State (Bug Fix)

    var recordingError: Error?  // Recording startup failure

    // MARK: - Topic Generation Error State (Phase 8.2)

    var topicGenerationError: Error?  // AI topic generation failure

    // MARK: - Notification State (Phase 7.4)

    var showNotificationPrePrompt = false  // Show permission pre-prompt Alert
    var shouldTriggerNotificationFlowOnDismiss = false  // Flag for onDismiss logic

    // MARK: - Services

    private let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer()
    private let haptics = HapticManager.shared
    private let soundEffects = SoundEffects.shared
    private let notificationManager = NotificationManager.shared
    private let speechRecognition = SpeechRecognitionService.shared  // Phase 8.1: Speech-to-Text
    @ObservationIgnored private nonisolated(unsafe) var timer: Timer?

    // MARK: - Constants

    #if DEBUG
    private let stopButtonThreshold: TimeInterval = 10  // Dev: 10s for fast testing
    private let skipButtonThreshold: TimeInterval = 3   // Dev: 3s for fast testing
    #else
    private let stopButtonThreshold: TimeInterval = 60  // Production: 60s (IELTS standard)
    private let skipButtonThreshold: TimeInterval = 10  // Production: 10s
    #endif

    private let maxRecordingTime: TimeInterval = 120    // Auto-stop at 120s
    private let maxPreparationTime: TimeInterval = 60   // Fixed 60s (IELTS standard)

    // MARK: - Session Persistence

    private let hasActiveSessionKey = "hasActiveRecordingSession"
    var hadInterruptedSession: Bool = false

    // MARK: - Data Persistence (Phase 7.1)

    private var currentSessionID: UUID?  // Track current session for feedback update

    // MARK: - Notification Data Cache (Phase 7.4 Fix)

    /// Cache session/topic data before reset() to prevent scheduling failure
    private var pendingNotificationData: (sessionID: UUID, topic: Topic)?

    // MARK: - Computed Properties

    /// Phase 9: User progress data for home screen display
    var userProgress: UserProgress? {
        try? DataManager.shared.fetchUserProgress()
    }

    /// Phase 9: Next-focus suggestion based on weakest category
    var nextFocusText: String? {
        guard let progress = userProgress, progress.totalSessions >= 1 else { return nil }
        let category = progress.weakestCategory
        guard category != "None" else { return nil }

        switch category {
        case "Fluency":
            return "Next time, try linking your ideas with phrases like \"that reminds me of\" or \"speaking of which.\""
        case "Lexical":
            return "Next time, try replacing one common word with a more specific one — like \"fascinating\" instead of \"good.\""
        case "Grammar":
            return "Next time, try mixing in one complex sentence — a \"because\" or \"although\" clause."
        case "Pronunciation":
            return "Next time, try slowing down slightly on key words to make your pronunciation clearer."
        default:
            return "Keep practicing — consistency is the fastest path to improvement."
        }
    }

    /// Progress from 0.0 to 1.0
    var progress: Double {
        switch state {
        case .recording:
            // Recording progress: as time increases, progress increases
            return min(1.0, elapsedTime / maxRecordingTime)
        default:
            return 0.0
        }
    }

    /// Preparation progress (1.0 → 0.0, inverse for countdown)
    var preparationProgress: Double {
        guard state == .preparing else { return 0.0 }
        return preparationTimeLeft / maxPreparationTime
    }

    /// Preparation time string (MM:SS)
    var preparationTimeString: String {
        let minutes = Int(preparationTimeLeft) / 60
        let seconds = Int(preparationTimeLeft) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formatted time string (MM:SS)
    var timeString: String {
        let time: TimeInterval
        switch state {
        case .recording, .finished, .analyzing:
            time = elapsedTime
        case .idle, .preparing:
            time = 0
        }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Audio levels for waveform visualization (real-time during recording)
    var audioLevels: [Float] {
        audioRecorder.audioLevels
    }

    /// Saved waveform for playback visualization (60 samples)
    var savedWaveform: [Float] {
        audioRecorder.savedWaveform
    }

    /// Current recording URL
    var audioURL: URL? {
        audioRecorder.currentAudioURL
    }

    /// Playback state
    var isPlaying: Bool {
        audioPlayer.isPlaying
    }

    /// Playback completion state (for dynamic button text)
    var hasFinishedPlayback: Bool {
        audioPlayer.hasFinished
    }

    /// Playback progress (0.0 - 1.0)
    var playbackProgress: Double {
        audioPlayer.progress
    }

    /// Playback time string
    var playbackTimeString: String {
        audioPlayer.timeString
    }

    /// Current analysis stage text for UI display
    var analysisStageText: String {
        guard let stage = analysisStage else { return "Listening to you…" }

        switch stage {
        case .encoding:
            return "Encoding audio…"
        case .uploading:
            return "Uploading…"
        case .analyzing:
            return "Analyzing…"
        case .preparing:
            return "Preparing feedback…"
        }
    }

    // MARK: - Initialization

    init() {
        // ✅ FIX: Minimal init to prevent iPhone 16 startup freeze
        // Only load topic, skip all other operations

        // Phase 8.2: Load recent topic history from persistent storage
        loadRecentTopicHistory()

        loadRandomTopic()

        // ✅ FIX: Don't check for interrupted session on init
        // This was causing first-launch freezes on iPhone 16
        hadInterruptedSession = false

        #if DEBUG
        print("✅ RecordingViewModel.init() completed (optimized)")
        #endif
    }

    // MARK: - Session Persistence Helpers

    /// Check if there was an interrupted recording session
    private func checkForInterruptedSession() -> Bool {
        // ✅ FIX: This method is no longer called on init
        // Kept for potential future use, but simplified
        let hasActiveSession = UserDefaults.standard.bool(forKey: hasActiveSessionKey)
        if hasActiveSession {
            // Clear the flag since we're handling it
            clearActiveSessionFlag()
            return true
        }
        return false
    }

    /// Mark that a recording session is active
    private func setActiveSessionFlag() {
        UserDefaults.standard.set(true, forKey: hasActiveSessionKey)
    }

    /// Clear the active session flag
    private func clearActiveSessionFlag() {
        UserDefaults.standard.set(false, forKey: hasActiveSessionKey)
    }

    /// Acknowledge the interrupted session (user has seen the message)
    func acknowledgeInterruptedSession() {
        hadInterruptedSession = false
    }

    /// ✅ RESTORED: Async interrupted session detection (safe for startup)
    /// Called from QuestionCardView.task with 500ms delay
    func checkForInterruptedSessionAsync() async {
        // Run UserDefaults check off main thread to avoid blocking
        let hasActiveSession = await Task.detached { [weak self] in
            guard let self = self else { return false }
            return UserDefaults.standard.bool(forKey: self.hasActiveSessionKey)
        }.value

        // If session was interrupted, update UI state on main thread
        if hasActiveSession {
            hadInterruptedSession = true
            clearActiveSessionFlag()

            #if DEBUG
            print("✅ Detected interrupted session, showing recovery prompt")
            #endif
        }
    }

    // MARK: - Topic Management

    func loadRandomTopic() {
        currentTopic = TopicLoader.shared.randomTopic()
    }

    func loadNextTopic() {
        // Phase 3: Cleanup before loading new topic
        cleanupIfNeeded()

        loadRandomTopic()
        reset()
    }

    // MARK: - Topic History Management (Phase 8.2)

    /// Load recent topic history from UserDefaults
    /// Phase 8.2: Pre-fill topics.json on first launch to avoid generating similar topics
    private func loadRecentTopicHistory() {
        if let titles = UserDefaults.standard.array(forKey: recentTopicsKey) as? [String] {
            recentTopicTitles = titles
            #if DEBUG
            print("📚 Loaded \(titles.count) recent topics from history")
            #endif
        } else {
            // First launch: pre-fill with all topics from topics.json
            // This ensures Gemini avoids generating similar topics from the start
            let allTopics = TopicLoader.shared.loadTopics()
            recentTopicTitles = allTopics.map { $0.title }
            saveRecentTopicHistory()

            #if DEBUG
            print("🎯 First launch: pre-filled \(recentTopicTitles.count) topics from topics.json")
            print("📚 Pre-filled topics:")
            for (index, title) in recentTopicTitles.enumerated() {
                print("   \(index + 1). \(title)")
            }
            #endif
        }
    }

    /// Save recent topic history to UserDefaults
    private func saveRecentTopicHistory() {
        UserDefaults.standard.set(recentTopicTitles, forKey: recentTopicsKey)
        #if DEBUG
        print("💾 Saved \(recentTopicTitles.count) recent topics to history")
        #endif
    }

    /// Add topic to recent history (max 5, FIFO)
    private func addToRecentHistory(title: String) {
        // Remove if already exists (avoid duplicates)
        recentTopicTitles.removeAll { $0 == title }

        // Add to front
        recentTopicTitles.insert(title, at: 0)

        // Keep only last 5
        if recentTopicTitles.count > maxRecentTopics {
            recentTopicTitles = Array(recentTopicTitles.prefix(maxRecentTopics))
        }

        // Persist to UserDefaults
        saveRecentTopicHistory()

        #if DEBUG
        print("📝 Topic added to history: \(title)")
        print("📚 Current history: \(recentTopicTitles)")
        #endif
    }

    /// Check if topic title is in recent history
    private func isRecentTopic(_ title: String) -> Bool {
        return recentTopicTitles.contains(title)
    }

    /// Generate AI-powered personalized topic (Phase 8.2)
    /// Uses UserProgress data if available, else generates generic IELTS topic
    /// Retry logic: max 3 attempts to avoid duplicate topics
    func generateAITopic() async {
        // Phase 8.2 Bug Fix: Cleanup before generating new topic (same as loadNextTopic)
        cleanupIfNeeded()

        // Set loading state
        isGeneratingTopic = true
        topicGenerationError = nil
        showFallbackToast = false

        #if DEBUG
        print("✨ Starting AI topic generation...")
        #endif

        // Retry logic: max 3 attempts
        let maxRetries = 3
        var attempt = 0
        var generatedTopic: Topic?

        while attempt < maxRetries && generatedTopic == nil {
            attempt += 1

            do {
                // Get user progress from DataManager
                let userProgress = try? DataManager.shared.fetchUserProgress()

                #if DEBUG
                print("✨ Attempt \(attempt)/\(maxRetries)")
                if let progress = userProgress, progress.hasEnoughData {
                    print("✨ Using personalized prompt (Weakest: \(progress.weakestCategory), Avg: \(String(format: "%.1f", progress.overallAverage)))")
                } else {
                    print("✨ Using generic prompt (insufficient data)")
                }
                #endif

                // Call Gemini API to generate topic (with recent history)
                let topic = try await GeminiService.shared.generatePersonalizedTopic(
                    userProgress: userProgress,
                    excludeRecent: recentTopicTitles
                )

                // Check if topic is duplicate of current topic
                if let currentTitle = currentTopic?.title, topic.title == currentTitle {
                    #if DEBUG
                    print("⚠️ Generated topic is same as current, retrying...")
                    #endif
                    continue
                }

                // Check if topic is in recent history
                if isRecentTopic(topic.title) {
                    #if DEBUG
                    print("⚠️ Generated topic is in recent history, retrying...")
                    #endif
                    continue
                }

                // Success: unique topic generated
                generatedTopic = topic

            } catch {
                #if DEBUG
                print("❌ AI topic generation failed (attempt \(attempt)): \(error.localizedDescription)")
                #endif

                // If last attempt, save error
                if attempt == maxRetries {
                    topicGenerationError = error
                }
            }
        }

        // Update state
        isGeneratingTopic = false

        if let topic = generatedTopic {
            // Success: update topic and add to history
            currentTopic = topic
            addToRecentHistory(title: topic.title)

            #if DEBUG
            print("✅ AI topic generation complete: \(topic.title)")
            #endif

        } else {
            // Fallback: Load random topic from JSON
            loadRandomTopic()
            showFallbackToast = true  // Show toast notification

            #if DEBUG
            print("🔄 Fallback to random topic (all attempts failed)")
            #endif

            // Auto-hide toast after 3 seconds
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showFallbackToast = false
            }
        }

        // Phase 8.2 Bug Fix: Reset state to .idle after topic update (same as loadNextTopic)
        reset()
    }

    /// Generate AI topic in background (on app startup)
    /// Similar to generateAITopic() but without cleanup/reset (non-disruptive)
    /// Smoothly replaces topics.json topic with AI-generated one
    func generateAITopicInBackground() async {
        #if DEBUG
        print("🌟 Starting background AI topic generation...")
        #endif

        // Retry logic: max 3 attempts
        let maxRetries = 3
        var attempt = 0
        var generatedTopic: Topic?

        while attempt < maxRetries && generatedTopic == nil {
            attempt += 1

            do {
                // Get user progress from DataManager
                let userProgress = try? DataManager.shared.fetchUserProgress()

                #if DEBUG
                print("🌟 Background attempt \(attempt)/\(maxRetries)")
                #endif

                // Call Gemini API to generate topic (with recent history)
                let topic = try await GeminiService.shared.generatePersonalizedTopic(
                    userProgress: userProgress,
                    excludeRecent: recentTopicTitles
                )

                // Check if topic is in recent history
                if isRecentTopic(topic.title) {
                    #if DEBUG
                    print("⚠️ Background generated topic is in recent history, retrying...")
                    #endif
                    continue
                }

                // Success: unique topic generated
                generatedTopic = topic

            } catch {
                #if DEBUG
                print("❌ Background AI topic generation failed (attempt \(attempt)): \(error.localizedDescription)")
                #endif
            }
        }

        if let topic = generatedTopic {
            // Success: smoothly replace current topic with AI-generated one
            addToRecentHistory(title: topic.title)

            // 0.3s crossfade animation
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTopic = topic
            }

            #if DEBUG
            print("✅ Background AI topic replaced successfully: \(topic.title)")
            #endif

        } else {
            // Failure: silently keep topics.json topic (no toast on startup)
            #if DEBUG
            print("⚠️ Background AI generation failed, keeping topics.json")
            #endif
        }
    }

    // MARK: - Preparation Control (Phase 4.5)

    /// Start 60s preparation countdown
    func startPreparation() {
        state = .preparing
        preparationTimeLeft = maxPreparationTime
        showSkipButton = false

        // Haptic feedback
        haptics.light()

        // Start countdown timer
        startPreparationTimer()
    }

    /// Skip preparation and start recording immediately (with transition overlay)
    func skipPreparation() async {
        stopTimer()
        // Reuse transition overlay logic from onPreparationComplete()
        await onPreparationComplete()
    }

    /// Auto-transition to recording when countdown reaches 0
    private func onPreparationComplete() async {
        stopTimer()

        // ✅ CRITICAL FIX: Start recording FIRST to capture user's immediate speech
        // Transition overlay shown during recording (non-blocking)
        await startRecording()

        // Phase 4.6: Show transition overlay DURING recording (1.2s)
        // This prevents losing first words when user starts speaking immediately
        showTransitionOverlay = true
        haptics.light()  // Feedback: "Recording has started"

        // Keep overlay visible for 1.2s during active recording
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        // Hide transition overlay (recording continues)
        showTransitionOverlay = false
    }

    // MARK: - Recording Control

    /// Start recording (called after preparation or skip)
    private func startRecording() async {
        // Check microphone permission first
        let hasPermission = audioRecorder.checkPermission()
        if !hasPermission {
            let granted = await audioRecorder.requestPermission()
            guard granted else {
                print("⚠️ Microphone permission denied")
                return
            }
        }

        // CRITICAL: Configure audio session BEFORE recording starts
        // This is the ONLY place where session is activated
        // Prevents "Unable to join I/O thread" crashes on iPhone 15/16
        do {
            try AudioSessionManager.shared.configureSession()
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
            recordingError = error
            state = .idle
            return
        }

        // Wait 300ms for session to stabilize before starting recorder
        // Prevents I/O conflicts during session activation
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Start recording hardware (but don't show "recording" UI yet)
        do {
            try audioRecorder.startRecording()

            // Mark session as active for crash recovery
            setActiveSessionFlag()

            #if DEBUG
            print("🎤 Recording hardware started, waiting for stabilization...")
            #endif

            // ✅ Bug Fix (2025-11-23): Play sound effects AFTER recorder starts
            // This gives user an audible cue to wait before speaking
            haptics.recordingStart()
            soundEffects.playRecordStart()

            // ✅ CRITICAL: Wait 300ms for hardware to fully stabilize
            // This prevents losing first words spoken immediately after prep countdown
            // User hears the "ding" sound and naturally waits ~300ms before speaking
            try? await Task.sleep(nanoseconds: 300_000_000)

            // NOW show "recording" state (user can start speaking)
            state = .recording
            elapsedTime = 0
            showStopButton = false

            // Start recording timer
            startRecordingTimer()

            #if DEBUG
            print("✅ Recording UI activated, ready to capture speech")
            #endif

        } catch {
            print("❌ Failed to start recording: \(error.localizedDescription)")

            // Bug Fix: Recover from recording failure
            recordingError = error
            state = .idle  // Return to initial state
            preparationTimeLeft = maxPreparationTime  // Reset countdown
            showSkipButton = false
            // Note: showTransitionOverlay managed by onPreparationComplete() only
            stopTimer()

            // Clear any partial recording
            audioRecorder.deleteRecording()
        }
    }

    /// Stop recording manually
    func stopRecording() {
        // ✅ Bug Fix (2025-11-23): Use delegate callback instead of Task.sleep
        // Set callback BEFORE calling stop() to ensure we catch the event
        audioRecorder.onRecordingFinished = { [weak self] url in
            Task { @MainActor [weak self] in
                await self?.handleRecordingFinished(url: url)
            }
        }

        audioRecorder.stopRecording()
        stopTimer()
        state = .finished

        // Clear active session flag (recording completed)
        clearActiveSessionFlag()

        #if DEBUG
        print("🎤 Waiting for recording file to be fully written...")
        #endif
    }

    /// Handle recording completion after file is fully written to disk
    /// ✅ Bug Fix (2025-11-23): Called by AudioRecorder delegate, not Task.sleep
    private func handleRecordingFinished(url: URL) async {
        #if DEBUG
        print("✅ Recording file ready for processing")
        #endif

        // Load audio for playback
        do {
            try audioPlayer.load(url: url)
            #if DEBUG
            print("✅ Audio loaded for playback")
            #endif
        } catch {
            print("❌ Failed to load audio for playback: \(error)")
        }

        // Play sound effects
        haptics.recordingStop()
        soundEffects.playRecordStop()

        // Phase 7.1: Auto-save recording to persistence layer
        // File is now complete, safe for transcription
        await saveCurrentSession()
    }

    /// Save current recording session to persistence storage (Phase 7.1)
    private func saveCurrentSession() async {
        guard let audioURL = audioRecorder.currentAudioURL,
              let topic = currentTopic else {
            #if DEBUG
            print("⚠️ Cannot save session: missing audio or topic")
            #endif
            return
        }

        do {
            // Generate session ID
            let sessionID = UUID()

            // Move audio file from temp to Documents/Recordings
            let savedAudioURL = try DataManager.shared.saveAudioFile(
                from: audioURL,
                sessionID: sessionID
            )

            // Extract filename only (path-independent storage)
            let audioFileName = savedAudioURL.lastPathComponent

            // Create PracticeSession (without feedback initially)
            try DataManager.shared.savePracticeSession(
                sessionID: sessionID,
                topicID: topic.id,
                topicTitle: topic.title,
                audioFileName: audioFileName,
                duration: elapsedTime,
                feedback: nil
            )

            // Track session ID for later feedback update
            currentSessionID = sessionID

            // Update AudioRecorder's URL reference to new location
            audioRecorder.updateAudioURL(savedAudioURL)

            #if DEBUG
            print("✅ Session saved: \(sessionID)")
            #endif

            // Phase 8.1: Trigger transcript generation (async, non-blocking)
            Task {
                await transcribeCurrentSession(sessionID: sessionID, audioURL: savedAudioURL)
            }
        } catch {
            // Silent failure (user experience not affected)
            #if DEBUG
            print("❌ Failed to save session: \(error.localizedDescription)")
            #endif
        }
    }

    /// Update existing session with AI feedback (Phase 7.1)
    private func updateSessionFeedback(sessionID: UUID, feedback: FeedbackResult) async {
        do {
            try DataManager.shared.updateSessionFeedback(
                sessionID: sessionID,
                feedback: feedback
            )

            #if DEBUG
            print("✅ Session feedback updated: \(sessionID)")
            #endif
        } catch {
            // Silent failure (user experience not affected)
            #if DEBUG
            print("❌ Failed to update session feedback: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Speech Transcription (Phase 8.1)

    /// Transcribe current session audio (async, non-blocking)
    /// - Parameters:
    ///   - sessionID: Session to update
    ///   - audioURL: Audio file to transcribe
    private func transcribeCurrentSession(sessionID: UUID, audioURL: URL) async {
        // ✅ Phase 8.1 Fix: Check if transcription is enabled in Settings
        guard UserDefaults.standard.isTranscriptEnabled else {
            #if DEBUG
            print("⏭️ Transcription disabled in Settings, skipping")
            #endif
            return
        }

        #if DEBUG
        print("🎙 Starting transcription for session: \(sessionID)")
        #endif

        // Check speech recognition permission
        let authStatus = speechRecognition.authorizationStatus

        // If not authorized, try to request permission or fail silently
        if authStatus != .authorized {
            if authStatus == .notDetermined {
                // Request permission silently (no user interruption)
                let granted = await speechRecognition.requestPermission()
                guard granted else {
                    #if DEBUG
                    print("⚠️ Speech recognition permission denied")
                    #endif
                    return
                }
                // Permission granted, continue to transcription
            } else {
                // Permission denied or restricted - silent failure
                #if DEBUG
                print("⚠️ Speech recognition not authorized (status: \(authStatus))")
                #endif
                return
            }
        }

        // Perform transcription
        let transcript = await speechRecognition.transcribe(audioURL: audioURL)

        // Update session if transcript is not empty
        guard !transcript.isEmpty else {
            #if DEBUG
            print("⚠️ Transcription returned empty result")
            #endif
            return
        }

        await updateSessionTranscript(sessionID: sessionID, transcript: transcript)
    }

    /// Update session with transcript (Phase 8.1)
    private func updateSessionTranscript(sessionID: UUID, transcript: String) async {
        do {
            try DataManager.shared.updateSessionTranscript(
                sessionID: sessionID,
                transcript: transcript
            )

            // Update current transcript for FeedbackView display
            currentTranscript = transcript

            #if DEBUG
            print("✅ Session transcript updated: \(sessionID)")
            print("📝 Transcript length: \(transcript.count) chars")
            #endif
        } catch {
            // Silent failure
            #if DEBUG
            print("❌ Failed to update session transcript: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - AI Analysis (Phase 3)

    /// Analyze recorded speech with Gemini AI
    func analyzeRecording() async {
        // Stop playback before analysis
        audioPlayer.stop()

        guard let audioURL = audioRecorder.currentAudioURL else {
            analysisError = SimpleError("No recording found")
            return
        }

        // Validate recording quality
        guard canAnalyze(audioURL: audioURL) else {
            analysisError = SimpleError("Recording too short or silent. Please try again.")
            return
        }

        state = .analyzing
        analysisError = nil

        // Stage 1: Encoding (show immediately)
        analysisStage = .encoding

        do {
            // ✅ Performance Note: Base64 encoding now runs on background thread (non-blocking)
            // Stage progression simulates realistic timing for user feedback
            Task {
                // Encoding stage: 0.5s (base64 encoding is now async, completes quickly)
                try? await Task.sleep(nanoseconds: 500_000_000)
                if state == .analyzing { analysisStage = .uploading }

                // Uploading stage: 2s (network upload time)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if state == .analyzing { analysisStage = .analyzing }
            }

            let result = try await GeminiService.shared.analyzeSpeech(
                audioURL: audioURL,
                duration: elapsedTime
            )

            // Stage 4: Preparing feedback
            analysisStage = .preparing
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s

            feedbackResult = result
            showFeedbackSheet = true
            analysisStage = nil  // Clear stage when done
            state = .finished  // Stay in finished to allow playback

            // Phase 7.1: Update session with feedback data
            if let sessionID = currentSessionID {
                await updateSessionFeedback(sessionID: sessionID, feedback: result)
            }

            // Phase 9: Update streak counter
            StreakManager.shared.recordPractice()

            // Phase 9: Update daily reminder with latest progress
            Task { await NotificationManager.shared.updateDailyReminderContent() }

            // Request App Store review at milestone sessions
            AppReviewManager.shared.requestReviewIfAppropriate()

            // Phase 7.4 Fix: DO NOT trigger pre-prompt here (causes Alert/Sheet conflict)
            // Pre-prompt now triggers AFTER FeedbackView dismissal (see playAgain/recordAgain/onNewTopic)
        } catch {
            print("❌ Analysis failed: \(error.localizedDescription)")
            analysisError = error
            analysisStage = nil
            state = .finished  // Graceful degradation
        }
    }

    /// Minimal validation: only check if recording system worked
    /// All audio quality decisions delegated to Gemini AI (product philosophy: trust AI, not algorithms)
    private func canAnalyze(audioURL: URL) -> Bool {
        let waveform = audioRecorder.savedWaveform
        guard !waveform.isEmpty else {
            #if DEBUG
            print("⚠️ Recording failed: empty waveform (AVAudioRecorder did not capture audio)")
            #endif
            return false
        }
        return true
    }

    /// Toggle playback (play/pause)
    func togglePlayback() {
        audioPlayer.togglePlayback()

        // Haptic feedback
        if audioPlayer.isPlaying {
            haptics.light()
        }
    }

    /// Seek to specific progress in playback (0.0 - 1.0)
    func seekPlayback(to progress: Double) {
        audioPlayer.seek(toProgress: progress)

        // Haptic feedback for scrubbing
        haptics.light()
    }

    /// Replay from beginning
    func replayRecording() {
        audioPlayer.stop()
        audioPlayer.play()

        // Haptic feedback
        haptics.medium()
    }

    // MARK: - Feedback Actions

    /// Play Again: Toggle playback in FeedbackView (Report stays open)
    func playAgain() {
        // Phase 8.1 Fix: Keep Report open, use togglePlayback like History mode
        togglePlayback()
    }

    /// Practice Again: Keep current session in History, reset to re-record same topic (Phase 8.1 Fix)
    func recordAgain() async {
        shouldTriggerNotificationFlowOnDismiss = true  // Phase 7.4: Mark for notification flow
        showFeedbackSheet = false  // Dismiss feedback

        // ✅ Phase 7.2 Bug Fix: Keep saved session in History (file already in Documents/)
        // Use clearState() instead of deleteRecording() to preserve the saved audio file
        audioRecorder.clearState()  // Clear recorder internal state without deleting file
        reset()  // Reset to .idle to allow new recording
    }

    /// Delete recording and reset to idle (Phase 7.1)
    func deleteRecording() async {
        audioPlayer.stop()

        // Remove saved session if it exists
        if currentSessionID != nil {
            await deleteCurrentSession()
        } else {
            // No saved session, just delete temp file
            deleteCurrentAudioFile()
        }

        audioRecorder.deleteRecording()
        reset()
    }

    /// Delete current audio file from disk (temp files only)
    func deleteCurrentAudioFile() {
        guard let audioURL = audioRecorder.currentAudioURL else { return }

        do {
            try FileManager.default.removeItem(at: audioURL)
            print("🗑️ Deleted audio file: \(audioURL.lastPathComponent)")
        } catch {
            print("⚠️ Failed to delete audio: \(error)")
        }
    }

    /// Delete current session from persistence store
    private func deleteCurrentSession() async {
        guard let sessionID = currentSessionID else { return }

        do {
            // Fetch session first
            let sessions = try DataManager.shared.fetchAllSessions()
            if let session = sessions.first(where: { $0.id == sessionID }) {
                try DataManager.shared.deleteSession(session)

                #if DEBUG
                print("✅ Session deleted: \(sessionID)")
                #endif
            }

            currentSessionID = nil
        } catch {
            // Silent failure
            #if DEBUG
            print("❌ Failed to delete session: \(error.localizedDescription)")
            #endif
        }
    }

    /// Cleanup analysis state (Phase 7.1: preserve saved audio files)
    /// Centralized cleanup for sheet dismissal and navigation
    func cleanupIfNeeded() {
        // Phase 7.1: Don't delete audio file (already saved to Documents)
        // Only delete temp files that weren't saved
        if currentSessionID == nil {
            deleteCurrentAudioFile()  // Delete unsaved temp file
        }

        feedbackResult = nil
        analysisError = nil
        showFeedbackSheet = false
    }

    /// Reset to idle state
    private func reset() {
        state = .idle
        elapsedTime = 0
        showStopButton = false
        stopTimer()
        audioPlayer.stop()

        // Clear active session flag when resetting
        clearActiveSessionFlag()

        // Clear analysis state
        feedbackResult = nil
        analysisError = nil

        // Phase 7.1: Clear current session ID
        currentSessionID = nil

        // Phase 8.1 Fix: Clear transcript for new recording
        currentTranscript = nil
    }

    // MARK: - Timer Management

    /// Timer for preparation countdown (60 → 0)
    private func startPreparationTimer() {
        // ✅ FIX: Guard against duplicate timers to prevent state corruption
        guard timer == nil else {
            #if DEBUG
            print("⚠️ Timer already running, skipping duplicate creation")
            #endif
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                // Decrement countdown
                self.preparationTimeLeft -= 1

                // Calculate elapsed time for Skip button threshold
                let elapsed = self.maxPreparationTime - self.preparationTimeLeft

                // Show Skip button after threshold
                if elapsed >= self.skipButtonThreshold && !self.showSkipButton {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showSkipButton = true
                    }
                }

                // Auto-start recording when countdown reaches 0
                if self.preparationTimeLeft <= 0 {
                    await self.onPreparationComplete()
                }
            }
        }
    }

    /// Timer for recording (0 → 120)
    private func startRecordingTimer() {
        // ✅ FIX: Guard against duplicate timers to prevent state corruption
        guard timer == nil else {
            #if DEBUG
            print("⚠️ Recording timer already running, skipping duplicate creation")
            #endif
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.elapsedTime += 1

                // Show Stop button after threshold (10s in dev, 60s in production)
                if self.elapsedTime >= self.stopButtonThreshold && !self.showStopButton {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showStopButton = true
                    }
                }

                // Auto-stop at 120 seconds
                if self.elapsedTime >= self.maxRecordingTime {
                    self.stopRecording()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Notification Management (Phase 7.4)

    /// Handle notification permission flow after FeedbackView dismissal (Phase 7.4 Fix)
    func handleNotificationPermissionFlow() async {
        // CRITICAL: Refresh system permission status before checking
        // Prevents stale cache if user enabled notifications in Settings
        await notificationManager.updateSystemPermissionStatus()

        #if DEBUG
        print("🔔 handleNotificationPermissionFlow() called")
        print("🔔 shouldShowPrePrompt: \(notificationManager.shouldShowPrePrompt())")
        print("🔔 Current showNotificationPrePrompt: \(showNotificationPrePrompt)")
        #endif

        // Check if we should show pre-prompt
        if notificationManager.shouldShowPrePrompt() {
            // Show pre-prompt Alert (will be displayed by QuestionCardView)
            showNotificationPrePrompt = true

            #if DEBUG
            print("✅ Set showNotificationPrePrompt = true")
            #endif
        } else {
            // Already have permission, directly schedule notification
            await scheduleNotificationIfEnabled()

            #if DEBUG
            print("ℹ️ Skipping pre-prompt, scheduling directly")
            #endif
        }
    }

    /// User accepted pre-prompt → Request system permission
    func acceptNotificationPrePrompt() async {
        await notificationManager.handlePrePromptAccepted()

        // After permission granted, schedule notification
        await scheduleNotificationIfEnabled()
    }

    /// User denied pre-prompt → Mark for retry next time
    func denyNotificationPrePrompt() {
        notificationManager.handlePrePromptDenied()
    }

    /// Save session/topic data for notification scheduling before reset()
    /// Called by QuestionCardView before loadNextTopic()
    func savePendingNotificationData() {
        guard let sessionID = currentSessionID,
              let topic = currentTopic else {
            #if DEBUG
            print("⚠️ Cannot save notification data: missing session or topic")
            #endif
            return
        }

        pendingNotificationData = (sessionID, topic)

        #if DEBUG
        print("💾 Saved notification data: session=\(sessionID), topic=\(topic.title)")
        #endif
    }

    /// Schedule notification if enabled and have necessary data
    private func scheduleNotificationIfEnabled() async {
        // Phase 7.4 Fix: Use pending data if available (after reset cleared current session)
        let sessionID: UUID
        let topic: Topic

        if let pending = pendingNotificationData {
            // Use cached data (survives reset())
            sessionID = pending.sessionID
            topic = pending.topic
            pendingNotificationData = nil  // Clear after use

            #if DEBUG
            print("📮 Using cached notification data")
            #endif
        } else if let currentID = currentSessionID,
                  let currentTopic = currentTopic {
            // Use current session data (normal flow)
            sessionID = currentID
            topic = currentTopic

            #if DEBUG
            print("📮 Using current session data")
            #endif
        } else {
            #if DEBUG
            print("⚠️ Cannot schedule notification: missing session or topic")
            #endif
            return
        }

        await notificationManager.scheduleReminder(
            sessionID: sessionID,
            topicTitle: topic.title,
            topicID: topic.id
        )
    }

    // MARK: - Cleanup

    deinit {
        timer?.invalidate()
        timer = nil
        // AudioPlayer's deinit handles its own cleanup
    }
}

// MARK: - Helper Types

/// Simple error wrapper for user-facing messages
struct SimpleError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
