//
//  SpeechRecognitionService.swift
//  IELTSPart2Coach
//
//  Phase 8.1: Speech-to-Text transcription service
//  Apple Speech framework wrapper for audio file transcription
//  Design: Silent failure, no user interruption
//

import Foundation
import Speech
import AVFAudio

@MainActor
class SpeechRecognitionService {
    static let shared = SpeechRecognitionService()

    private let recognizer: SFSpeechRecognizer?

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
        let session = AVAudioSession.sharedInstance()
        guard let input = session.currentRoute.inputs.first else {
            // No input detected, default to on-device (safer fallback)
            return true
        }

        // Bluetooth devices (phone call quality) → Server-based
        // Reason: On-device models require high-quality audio (≥16kHz)
        //         BluetoothHFP degrades to ~8kHz, causing recognition failure
        if input.portType == .bluetoothHFP || input.portType == .bluetoothA2DP {
            #if DEBUG
            print("🎧 Bluetooth device detected (\(input.portName))")
            print("🎧 Using server-based recognition (accuracy priority)")
            #endif
            return false
        }

        // Built-in mic, wired headphones → On-device
        // Reason: High-quality audio, best recognition + punctuation support
        #if DEBUG
        print("🎤 High-quality input detected (\(input.portName))")
        print("🎤 Using on-device recognition (optimal quality)")
        #endif
        return true
    }

    // MARK: - Transcription

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
        request.shouldReportPartialResults = false  // Only final result

        // ✅ Intelligent recognition mode selection based on audio input device
        // - Built-in mic/wired headphones → On-device (high quality, best punctuation)
        // - Bluetooth devices → Server-based (handles low-quality audio, accuracy priority)
        let useOnDevice = shouldUseOnDeviceRecognition()
        request.requiresOnDeviceRecognition = useOnDevice

        // ✅ Add punctuation for readability (iOS 16+)
        // Server-based may not support this for low-quality audio, but we attempt it
        request.addsPunctuation = true

        #if DEBUG
        let inputDevice = AVAudioSession.sharedInstance().currentRoute.inputs.first?.portName ?? "Unknown"
        print("🎤 Transcription starting:")
        print("   Input device: \(inputDevice)")
        print("   Recognition mode: \(useOnDevice ? "On-device" : "Server-based")")
        print("   Punctuation enabled: true")
        #endif

        // ⚠️ NOTE: taskHint intentionally NOT set
        // .dictation mode causes over-correction (changes "professor" → "supervisor", etc.)
        // IELTS requires accurate transcription of user's actual speech, not AI-corrected version
        // Default behavior preserves word accuracy while addsPunctuation handles formatting

        do {
            // Perform transcription with timeout and cancellation support
            let result = try await withThrowingTaskGroup(of: SFSpeechRecognitionResult.self) { group in
                var recognitionTask: SFSpeechRecognitionTask?

                // Main transcription task
                group.addTask {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SFSpeechRecognitionResult, Error>) in
                        var didResume = false  // Prevent double-resume

                        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                            guard !didResume else { return }

                            if let error = error {
                                didResume = true
                                continuation.resume(throwing: error)
                                return
                            }

                            // Accept final result OR last available result after timeout
                            if let result = result, result.isFinal {
                                didResume = true
                                continuation.resume(returning: result)
                            }
                        }
                    }
                }

                // Timeout task (60 seconds - enough for 2min recording)
                group.addTask {
                    try await Task.sleep(nanoseconds: 60_000_000_000)  // 60s
                    throw SpeechRecognitionError.transcriptionFailed
                }

                // Return first completed task (either result or timeout)
                let result = try await group.next()!

                // Cancel remaining tasks
                group.cancelAll()
                recognitionTask?.cancel()

                return result
            }

            let transcript = result.bestTranscription.formattedString

            #if DEBUG
            let hasPunctuation = transcript.contains(".") || transcript.contains(",") || transcript.contains("!")
            print("✅ Transcript generated:")
            print("   Length: \(transcript.count) chars")
            print("   Recognition mode: \(useOnDevice ? "On-device" : "Server-based")")
            print("   Punctuation detected: \(hasPunctuation ? "Yes" : "No")")
            print("   Preview: \(transcript.prefix(100))...")
            #endif

            return transcript

        } catch {
            #if DEBUG
            print("❌ Transcription failed: \(error.localizedDescription)")
            #endif
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
        }
    }
}
