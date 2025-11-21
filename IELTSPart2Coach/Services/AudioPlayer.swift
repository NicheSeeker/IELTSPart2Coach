//
//  AudioPlayer.swift
//  IELTSPart2Coach
//
//  Audio playback service with progress tracking and scrubbing support
//  Uses AVAudioPlayer (does NOT modify AVAudioSession)
//  Playback automatically routes to speaker via AudioSessionManager's .defaultToSpeaker option
//

import AVFoundation
import Foundation

@MainActor
@Observable
class AudioPlayer: NSObject {
    // MARK: - Published State

    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var staticWaveform: [Float] = [] // Extracted waveform for visualization
    var hasFinished = false  // Phase 7.2 Fix: Track if playback completed naturally

    // MARK: - Private Properties

    @ObservationIgnored private nonisolated(unsafe) var audioPlayer: AVAudioPlayer?
    @ObservationIgnored private nonisolated(unsafe) var progressTimer: Timer?

    // MARK: - Computed Properties

    /// Playback progress from 0.0 to 1.0
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, currentTime / duration)
    }

    /// Formatted time string (MM:SS)
    var timeString: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Load & Prepare

    /// Load audio file and prepare for playback
    /// CRITICAL: Do NOT call this immediately after stopRecording()
    /// Wait at least 300-500ms to avoid I/O conflicts
    func load(url: URL) throws {
        // Stop any existing playback
        stop()

        #if DEBUG
        print("🔊 Loading audio file: \(url.lastPathComponent)")
        #endif

        // Create audio player
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()

        // Get duration
        duration = audioPlayer?.duration ?? 0
        currentTime = 0

        #if DEBUG
        print("🔊 Audio loaded successfully")
        print("🔊 Duration: \(String(format: "%.2f", duration))s")
        print("🔊 Output route: \(AudioSessionManager.shared.currentOutputRoute)")
        #endif

        // Extract waveform data
        extractWaveform(from: url)
    }

    // MARK: - Playback Control

    /// Start or resume playback
    func play() {
        // ✅ Bug Fix: Ensure audio session is configured before playback
        // Fixes: History playback has no sound after cold app launch
        if !AudioSessionManager.shared.isActive {
            #if DEBUG
            print("⚠️ Audio session not active, attempting to configure...")
            #endif

            do {
                try AudioSessionManager.shared.configureSession()
            } catch {
                #if DEBUG
                print("❌ Failed to configure audio session: \(error)")
                #endif
                return  // Cannot play without active session
            }
        }

        guard let player = audioPlayer else {
            print("⚠️ No audio loaded, cannot play")
            return
        }

        player.play()
        isPlaying = true
        hasFinished = false  // Phase 7.2 Fix: Reset finished state when playing

        #if DEBUG
        print("▶️ Playback started")
        #endif

        // Start progress tracking
        startProgressTimer()
    }

    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()

        #if DEBUG
        print("⏸ Playback paused")
        #endif
    }

    /// Stop playback and reset to beginning
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        isPlaying = false
        hasFinished = false  // Phase 7.2 Fix: Reset finished state
        stopProgressTimer()

        #if DEBUG
        print("⏹ Playback stopped")
        #endif
    }

    /// Toggle play/pause
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }

        let seekTime = max(0, min(time, duration))
        player.currentTime = seekTime
        currentTime = seekTime

        #if DEBUG
        print("⏩ Seeked to: \(String(format: "%.2f", seekTime))s")
        #endif
    }

    /// Seek by progress (0.0 - 1.0)
    func seek(toProgress progress: Double) {
        let time = progress * duration
        seek(to: time)
    }

    // MARK: - Progress Tracking

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Waveform Extraction

    /// Extract waveform samples from audio file for visualization
    private func extractWaveform(from url: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("⚠️ Failed to create audio buffer")
                return
            }

            try audioFile.read(into: buffer)

            guard let channelData = buffer.floatChannelData?[0] else {
                print("⚠️ Failed to get channel data")
                return
            }

            // Sample count for visualization (60 samples for smooth display)
            let sampleCount = 60
            let samplesPerPoint = Int(frameCount) / sampleCount

            var waveformSamples: [Float] = []

            for i in 0..<sampleCount {
                let startIndex = i * samplesPerPoint
                let endIndex = min(startIndex + samplesPerPoint, Int(frameCount))

                // Calculate average amplitude for this segment
                var sum: Float = 0
                for j in startIndex..<endIndex {
                    sum += abs(channelData[j])
                }

                let average = sum / Float(samplesPerPoint)
                waveformSamples.append(average)
            }

            // Normalize waveform to 0.0 - 1.0 range
            if let maxValue = waveformSamples.max(), maxValue > 0 {
                staticWaveform = waveformSamples.map { $0 / maxValue }
            } else {
                staticWaveform = waveformSamples
            }

            #if DEBUG
            print("🔊 Waveform extracted: \(staticWaveform.count) samples")
            #endif

        } catch {
            print("❌ Failed to extract waveform: \(error)")
            // Fallback: create placeholder waveform
            staticWaveform = Array(repeating: 0.5, count: 60)
        }
    }

    // MARK: - Cleanup

    deinit {
        progressTimer?.invalidate()
        progressTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            hasFinished = true  // Phase 7.2 Fix: Mark as finished
            stopProgressTimer()

            // Reset to beginning
            currentTime = 0
            self.audioPlayer?.currentTime = 0

            #if DEBUG
            print("🔊 Playback finished")
            #endif
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Audio playback error: \(error)")
            }
            isPlaying = false
            stopProgressTimer()
        }
    }
}
