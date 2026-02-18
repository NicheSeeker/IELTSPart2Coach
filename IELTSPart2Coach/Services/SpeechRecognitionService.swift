//
//  SpeechRecognitionService.swift
//  IELTSPart2Coach
//
//  Phase 8.1: Speech-to-Text transcription service
//  Phase 8.2: Audio segmentation for long recordings (>50s)
//  Apple Speech framework wrapper for audio file transcription
//  Design: Silent failure, no user interruption
//

import Foundation
import Speech
import AVFAudio
import AVFoundation

@MainActor
class SpeechRecognitionService {
    static let shared = SpeechRecognitionService()

    private let recognizer: SFSpeechRecognizer?

    // Audio segmentation constants
    #if DEBUG
    private let maxSegmentDuration: TimeInterval = 20.0  // Debug: 20s segments for faster testing (60s → 3 segments)
    #else
    private let maxSegmentDuration: TimeInterval = 50.0  // Production: 50s per segment (leave 10s buffer)
    #endif
    private let recognitionTimeout: TimeInterval = 120.0  // 120s timeout per segment (supports 2-min recordings)

    // MARK: - Initialization

    private init() {
        // Use US English locale for IELTS (international standard)
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        #if DEBUG
        if recognizer == nil {
            print("⚠️ Speech recognizer unavailable for en-US locale")
        }
        #endif
    }

    // MARK: - Permission Management

    /// Check current authorization status
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    /// Check if speech recognition is available
    var isAvailable: Bool {
        guard let recognizer = recognizer else { return false }
        return recognizer.isAvailable
    }

    /// Request speech recognition permission
    /// - Returns: true if granted, false otherwise
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    let granted = status == .authorized

                    #if DEBUG
                    print("🎤 Speech recognition permission: \(granted ? "granted" : "denied")")
                    #endif

                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Audio Source Detection

    /// Determine optimal recognition mode based on audio input device
    /// - Returns: true for on-device recognition, false for server-based
    private func shouldUseOnDeviceRecognition() -> Bool {
        // ⚠️ TEMPORARY FIX: Force server-based recognition for better transcript quality
        // User reported on-device recognition only captured ~30-40 words from 59s recording
        // Server-based typically provides higher accuracy, especially for longer audio
        // TODO: Re-evaluate after testing server-based quality

        #if DEBUG
        let session = AVAudioSession.sharedInstance()
        let input = session.currentRoute.inputs.first
        print("🎤 Input device: \(input?.portName ?? "Unknown")")
        print("📡 FORCING server-based recognition (quality improvement)")
        #endif

        return false  // Always use server-based for better accuracy
    }

    // MARK: - Audio Duration Detection

    /// Get audio file duration
    /// - Parameter url: Audio file URL
    /// - Returns: Duration in seconds, or 0 if failed
    private func getAudioDuration(url: URL) async -> TimeInterval {
        do {
            let asset = AVAsset(url: url)
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)

            #if DEBUG
            print("🎵 Audio duration: \(String(format: "%.1f", seconds))s")
            #endif

            return seconds
        } catch {
            #if DEBUG
            print("⚠️ Failed to get audio duration: \(error.localizedDescription)")
            #endif
            return 0
        }
    }

    // MARK: - Audio Segmentation

    /// Export a segment of audio file to temporary location
    /// - Parameters:
    ///   - sourceURL: Original audio file
    ///   - startTime: Segment start time
    ///   - endTime: Segment end time
    /// - Returns: URL of exported segment, or nil if failed
    private func exportAudioSegment(
        sourceURL: URL,
        startTime: CMTime,
        endTime: CMTime
    ) async throws -> URL {
        let asset = AVAsset(url: sourceURL)

        // Create export session
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            throw SpeechRecognitionError.audioExportFailed
        }

        // Generate unique temporary file name
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "segment_\(UUID().uuidString).wav"
        let outputURL = tempDir.appendingPathComponent(fileName)

        // Configure export
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .wav
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)

        // Perform export
        await exportSession.export()

        guard exportSession.status == .completed else {
            if let error = exportSession.error {
                throw error
            }
            throw SpeechRecognitionError.audioExportFailed
        }

        #if DEBUG
        let startSeconds = CMTimeGetSeconds(startTime)
        let endSeconds = CMTimeGetSeconds(endTime)
        print("✂️  Segment exported: \(String(format: "%.1f", startSeconds))s - \(String(format: "%.1f", endSeconds))s")
        #endif

        return outputURL
    }

    // MARK: - Single Segment Recognition

    /// Recognize a single audio segment (≤50s)
    /// - Parameter audioURL: Audio file URL
    /// - Returns: Transcribed text or empty string if failed
    private func recognizeSingleSegment(audioURL: URL) async -> String {
        // Guard: Check recognizer availability
        guard let recognizer = recognizer, recognizer.isAvailable else {
            #if DEBUG
            print("⚠️ Speech recognizer not available")
            #endif
            return ""
        }

        // Guard: Check file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            #if DEBUG
            print("⚠️ Audio file not found: \(audioURL.lastPathComponent)")
            #endif
            return ""
        }

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        // ✅ CRITICAL FIX: Enable partial results to receive ALL recognition callbacks
        // Without this, long audio only returns the last recognized segment
        request.shouldReportPartialResults = true

        // ✅ Intelligent recognition mode selection based on audio input device
        // - Built-in mic/wired headphones → On-device (high quality, best punctuation)
        // - Bluetooth devices → Server-based (handles low-quality audio, accuracy priority)
        let useOnDevice = shouldUseOnDeviceRecognition()
        request.requiresOnDeviceRecognition = useOnDevice

        // ✅ Add punctuation for readability (iOS 16+)
        request.addsPunctuation = true

        // ⚠️ NOTE: taskHint intentionally NOT set
        // .dictation mode causes over-correction (changes "professor" → "supervisor", etc.)
        // IELTS requires accurate transcription of user's actual speech, not AI-corrected version
        // Default behavior preserves word accuracy while addsPunctuation handles formatting

        // Thread-safe accumulator using actor
        actor TranscriptAccumulator {
            private var transcript = ""
            private var hasResumed = false

            func update(_ text: String) {
                if text.count > transcript.count {
                    transcript = text
                }
            }

            func getTranscript() -> String {
                return transcript
            }

            func markResumed() -> Bool {
                if hasResumed {
                    return false  // Already resumed
                }
                hasResumed = true
                return true  // First time resuming
            }
        }

        let accumulator = TranscriptAccumulator()

        do {
            let transcript = try await withThrowingTaskGroup(of: String.self) { group in
                var recognitionTask: SFSpeechRecognitionTask?

                // Main transcription task
                group.addTask { @MainActor in
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                            Task { @MainActor in
                                // Handle completion or errors
                                if let error = error {
                                    let nsError = error as NSError
                                    // Error code 203 or 216 means recognition completed successfully
                                    if nsError.code == 203 || nsError.code == 216 {
                                        let canResume = await accumulator.markResumed()
                                        if canResume {
                                            let finalTranscript = await accumulator.getTranscript()
                                            #if DEBUG
                                            print("   📝 Recognition completed via error code \(nsError.code)")
                                            #endif
                                            continuation.resume(returning: finalTranscript)
                                        }
                                    } else {
                                        let canResume = await accumulator.markResumed()
                                        if canResume {
                                            #if DEBUG
                                            print("   ⚠️ Recognition error: \(error.localizedDescription) (code \(nsError.code))")
                                            #endif
                                            continuation.resume(throwing: error)
                                        }
                                    }
                                    return
                                }

                                // Update with latest result
                                if let result = result {
                                    let currentTranscript = result.bestTranscription.formattedString
                                    await accumulator.update(currentTranscript)

                                    // ✅ CRITICAL FIX: Return immediately when isFinal is true
                                    // Don't wait for error code - it may never come
                                    if result.isFinal {
                                        #if DEBUG
                                        print("   📝 isFinal: \(currentTranscript.count) chars")
                                        #endif

                                        let canResume = await accumulator.markResumed()
                                        if canResume {
                                            recognitionTask?.cancel()
                                            #if DEBUG
                                            print("   ✅ Returning on isFinal")
                                            #endif
                                            continuation.resume(returning: currentTranscript)
                                        }
                                    }
                                }
                            }
                        }

                        // Safety timeout (backup mechanism only)
                        // Primary return is now via isFinal callback above
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 150_000_000_000)  // 150s safety timeout for real device processing

                            let canResume = await accumulator.markResumed()
                            if canResume {
                                let finalTranscript = await accumulator.getTranscript()
                                if !finalTranscript.isEmpty {
                                    #if DEBUG
                                    print("   ⏱️ Safety timeout triggered (backup only)")
                                    #endif
                                    recognitionTask?.cancel()
                                    continuation.resume(returning: finalTranscript)
                                } else {
                                    #if DEBUG
                                    print("   ⚠️ Safety timeout: no transcript accumulated")
                                    #endif
                                }
                            }
                        }
                    }
                }

                // Main timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(self.recognitionTimeout * 1_000_000_000))
                    throw SpeechRecognitionError.transcriptionFailed
                }

                // Return first completed task
                let result = try await group.next()!

                // Cancel remaining tasks
                group.cancelAll()
                recognitionTask?.cancel()

                return result
            }

            #if DEBUG
            print("   ✅ Segment complete: \(transcript.count) chars")
            #endif

            return transcript

        } catch {
            #if DEBUG
            print("   ❌ Segment recognition failed: \(error.localizedDescription)")
            #endif
            return ""
        }
    }

    // MARK: - Main Transcription (with Segmentation)

    /// Transcribe audio file to text
    /// - Parameter audioURL: URL to audio file (WAV/M4A)
    /// - Returns: Transcribed text or empty string if failed
    func transcribe(audioURL: URL) async -> String {
        // Guard: Check authorization
        guard authorizationStatus == .authorized else {
            #if DEBUG
            print("⚠️ Speech recognition not authorized")
            #endif
            return ""
        }

        // Guard: Check recognizer availability
        guard recognizer != nil else {
            #if DEBUG
            print("⚠️ Speech recognizer not available")
            #endif
            return ""
        }

        // Guard: Check file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            #if DEBUG
            print("⚠️ Audio file not found: \(audioURL.lastPathComponent)")
            #endif
            return ""
        }

        // Get audio duration
        let duration = await getAudioDuration(url: audioURL)
        guard duration > 0 else {
            #if DEBUG
            print("⚠️ Invalid audio duration")
            #endif
            return ""
        }

        #if DEBUG
        let inputDevice = AVAudioSession.sharedInstance().currentRoute.inputs.first?.portName ?? "Unknown"
        let useOnDevice = shouldUseOnDeviceRecognition()
        print("🎤 Transcription starting:")
        print("   Input device: \(inputDevice)")
        print("   Recognition mode: \(useOnDevice ? "On-device" : "Server-based")")
        print("   Punctuation enabled: true")
        #endif

        // Short audio: Direct recognition
        if duration <= maxSegmentDuration {
            #if DEBUG
            print("📝 Short audio, processing directly...")
            #endif

            let transcript = await recognizeSingleSegment(audioURL: audioURL)

            #if DEBUG
            if !transcript.isEmpty {
                let hasPunctuation = transcript.contains(".") || transcript.contains(",") || transcript.contains("!")
                print("✅ Transcript generated:")
                print("   Length: \(transcript.count) chars")
                print("   Punctuation detected: \(hasPunctuation ? "Yes" : "No")")
                print("   Preview: \(transcript.prefix(100))...")
                print("📝 FULL TRANSCRIPT (for debugging):")
                print("   \"\(transcript)\"")
            }
            #endif

            return transcript
        }

        // Long audio: Segmentation required
        let segmentCount = Int(ceil(duration / maxSegmentDuration))
        #if DEBUG
        print("🔪 Long audio detected, splitting into \(segmentCount) segments...")
        #endif

        var fullTranscript = ""
        var segmentURLs: [URL] = []

        do {
            // Process each segment sequentially
            var currentTime: TimeInterval = 0
            var segmentIndex = 1

            while currentTime < duration {
                let segmentStart = CMTime(seconds: currentTime, preferredTimescale: 600)
                let segmentEnd = CMTime(
                    seconds: min(currentTime + maxSegmentDuration, duration),
                    preferredTimescale: 600
                )

                #if DEBUG
                print("📝 Processing segment \(segmentIndex)/\(segmentCount) (\(String(format: "%.1f", currentTime))s - \(String(format: "%.1f", min(currentTime + maxSegmentDuration, duration)))s)")
                #endif

                // Export segment
                let segmentURL = try await exportAudioSegment(
                    sourceURL: audioURL,
                    startTime: segmentStart,
                    endTime: segmentEnd
                )
                segmentURLs.append(segmentURL)

                // Recognize segment
                let transcript = await recognizeSingleSegment(audioURL: segmentURL)

                // Append to full transcript (with space separator)
                if !transcript.isEmpty {
                    if !fullTranscript.isEmpty {
                        fullTranscript += " "
                    }
                    fullTranscript += transcript
                }

                currentTime += maxSegmentDuration
                segmentIndex += 1
            }

            // Clean up temporary segment files
            for segmentURL in segmentURLs {
                try? FileManager.default.removeItem(at: segmentURL)
            }

            #if DEBUG
            if !fullTranscript.isEmpty {
                let hasPunctuation = fullTranscript.contains(".") || fullTranscript.contains(",") || fullTranscript.contains("!")
                print("✅ Full transcript generated:")
                print("   Length: \(fullTranscript.count) chars")
                print("   Segments processed: \(segmentCount)")
                print("   Punctuation detected: \(hasPunctuation ? "Yes" : "No")")
                print("   Preview: \(fullTranscript.prefix(100))...")
            } else {
                print("⚠️ All segments returned empty results")
            }
            #endif

            return fullTranscript

        } catch {
            #if DEBUG
            print("❌ Segmentation/transcription failed: \(error.localizedDescription)")
            #endif

            // Clean up any temporary files
            for segmentURL in segmentURLs {
                try? FileManager.default.removeItem(at: segmentURL)
            }

            return ""
        }
    }
}

// MARK: - Error Types (Internal Use)

enum SpeechRecognitionError: LocalizedError {
    case notAuthorized
    case recognizerUnavailable
    case audioFileNotFound
    case transcriptionFailed
    case audioExportFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition permission not granted"
        case .recognizerUnavailable:
            return "Speech recognizer not available"
        case .audioFileNotFound:
            return "Audio file not found"
        case .transcriptionFailed:
            return "Transcription failed"
        case .audioExportFailed:
            return "Audio segment export failed"
        }
    }
}
