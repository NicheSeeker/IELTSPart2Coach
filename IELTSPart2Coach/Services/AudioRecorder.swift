//
//  AudioRecorder.swift
//  IELTSPart2Coach
//
//  Audio recording service with real-time volume monitoring
//  Format: WAV (Linear PCM) at 44.1kHz - compatible with simulator and real devices
//  CRITICAL: Does NOT configure AVAudioSession (managed by AudioSessionManager)
//

import AVFoundation
import Foundation

@MainActor
@Observable
class AudioRecorder: NSObject {
    // MARK: - Published State

    var isRecording = false
    var currentAudioURL: URL?
    var audioLevels: [Float] = [] // For real-time waveform visualization (last 30 samples)
    var savedWaveform: [Float] = [] // Downsampled waveform for playback (60 samples)

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var fullWaveform: [Float] = [] // Complete waveform recorded during session
    private let maxLevels = 30 // Number of samples to keep for real-time display
    private let savedWaveformSamples = 60 // Target sample count for playback visualization

    // MARK: - Completion Callback

    /// Callback invoked when recording finishes and file is fully written to disk
    /// ✅ Bug Fix (2025-11-23): Use this instead of Task.sleep to ensure file is complete
    var onRecordingFinished: ((URL) -> Void)?

    // MARK: - Initialization

    override init() {
        super.init()
        // CRITICAL: Do NOT configure audio session here!
        // All session management is handled by AudioSessionManager
    }

    // MARK: - Permission Handling

    /// Request microphone permission (iOS 17+ API)
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Check current permission status (iOS 17+ API)
    func checkPermission() -> Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    // MARK: - Recording Control

    /// Start recording audio
    /// CRITICAL: AudioSessionManager.shared.configureSession() must be called BEFORE this
    /// Otherwise recording will fail or route to wrong output
    func startRecording() throws {
        #if DEBUG
        print("🎤 Starting recording...")
        #endif

        // Ensure audio session is configured (defensive check)
        if !AudioSessionManager.shared.isActive {
            print("⚠️ Audio session not active, attempting to configure...")
            try AudioSessionManager.shared.configureSession()
        }

        // Generate unique file URL
        let fileName = "recording_\(Date().timeIntervalSince1970).wav"
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Audio settings: WAV (Linear PCM) format - compatible with simulator and real devices
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        #if DEBUG
        print("🎤 Audio settings: PCM 16-bit, 44.1kHz, Mono")
        #endif

        // Create recorder
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true

        // Start recording
        #if DEBUG
        print("🎤 Attempting to start AVAudioRecorder...")
        #endif

        guard let recorder = audioRecorder else {
            throw RecordingError.failedToStart
        }

        let started = recorder.record()

        #if DEBUG
        print("🎤 AVAudioRecorder.record() returned: \(started)")
        if !started {
            print("❌ Recorder failed to start - checking recorder state:")
            print("   - URL: \(recorder.url)")
            print("   - isRecording: \(recorder.isRecording)")
        }
        #endif

        guard started else {
            throw RecordingError.failedToStart
        }

        currentAudioURL = audioURL
        isRecording = true
        audioLevels.removeAll()
        fullWaveform.removeAll()
        savedWaveform.removeAll()

        #if DEBUG
        print("✅ Recording started successfully")
        print("🎤 File: \(audioURL.lastPathComponent)")
        print("🎤 Output route: \(AudioSessionManager.shared.currentOutputRoute)")
        #endif

        // Start level monitoring
        startLevelMonitoring()
    }

    /// Stop recording audio
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopLevelMonitoring()

        // Downsample full waveform to 60 samples for playback visualization
        downsampleWaveform()

        #if DEBUG
        print("🎤 Recording stopped")
        if let url = currentAudioURL {
            print("🎤 Saved to: \(url.lastPathComponent)")
        }
        #endif
    }

    /// Delete current recording
    func deleteRecording() {
        if let url = currentAudioURL {
            try? FileManager.default.removeItem(at: url)
            currentAudioURL = nil
        }
        audioLevels.removeAll()
        fullWaveform.removeAll()
        savedWaveform.removeAll()
    }

    /// Update current audio URL after file has been moved to Documents (Phase 7.1 Bug Fix)
    /// - Parameter newURL: New file location (Documents/Recordings/session_<UUID>.m4a)
    func updateAudioURL(_ newURL: URL) {
        currentAudioURL = newURL

        #if DEBUG
        print("🔄 AudioRecorder URL updated: \(newURL.lastPathComponent)")
        #endif
    }

    /// Clear recorder state without deleting files (Phase 7.2 Bug Fix)
    /// Use this when file has already been saved to Documents and should be preserved
    func clearState() {
        currentAudioURL = nil
        audioLevels.removeAll()
        fullWaveform.removeAll()
        savedWaveform.removeAll()

        #if DEBUG
        print("🧹 AudioRecorder state cleared (file preserved)")
        #endif
    }

    // MARK: - Level Monitoring

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAudioLevel()
            }
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)

        // Normalize level from [-160, 0] to [0, 1]
        let normalizedLevel = max(0, min(1, (level + 160) / 160))

        // Add to real-time levels array (for current display)
        audioLevels.append(normalizedLevel)

        // Keep only recent samples for real-time display
        if audioLevels.count > maxLevels {
            audioLevels.removeFirst()
        }

        // Also store in full waveform (unlimited) for later playback
        fullWaveform.append(normalizedLevel)
    }

    // MARK: - Waveform Processing

    /// Downsample the full waveform to a fixed number of samples for playback
    /// ✅ Memory fix: Clear fullWaveform after downsampling to prevent memory leak
    private func downsampleWaveform() {
        guard !fullWaveform.isEmpty else {
            savedWaveform = []
            return
        }

        let totalSamples = fullWaveform.count

        // If we have fewer samples than target, just use what we have
        if totalSamples <= savedWaveformSamples {
            savedWaveform = fullWaveform
            // ✅ Memory fix: Clear fullWaveform immediately
            fullWaveform.removeAll(keepingCapacity: false)
            return
        }

        // Calculate how many original samples per output sample
        let samplesPerPoint = Double(totalSamples) / Double(savedWaveformSamples)

        var downsampled: [Float] = []

        for i in 0..<savedWaveformSamples {
            let startIndex = Int(Double(i) * samplesPerPoint)
            let endIndex = Int(Double(i + 1) * samplesPerPoint)

            // Calculate average amplitude for this segment
            let segment = fullWaveform[startIndex..<min(endIndex, totalSamples)]
            let average = segment.reduce(0, +) / Float(segment.count)
            downsampled.append(average)
        }

        savedWaveform = downsampled

        // ✅ Memory fix: Clear fullWaveform after downsampling (releases ~10KB per recording)
        fullWaveform.removeAll(keepingCapacity: false)

        #if DEBUG
        print("💾 fullWaveform cleared after downsampling (saved \(totalSamples * 4) bytes)")
        #endif
    }

    // MARK: - Errors

    enum RecordingError: LocalizedError {
        case failedToStart
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .failedToStart:
                return "Failed to start recording"
            case .permissionDenied:
                return "Microphone permission denied"
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                print("⚠️ Recording finished with error")
                deleteRecording()
            } else {
                // ✅ Bug Fix (2025-11-23): Recording file is now fully written to disk
                // Invoke callback to notify ViewModel it's safe to process the file
                if let url = currentAudioURL {
                    #if DEBUG
                    print("✅ Recording file fully written: \(url.lastPathComponent)")
                    #endif

                    onRecordingFinished?(url)
                } else {
                    print("⚠️ Recording finished but no URL available")
                }
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Recording error: \(error)")
            }
        }
    }
}
