//
//  SoundEffects.swift
//  IELTSPart2Coach
//
//  Breath-like sound effects for recording start/stop
//  Uses AVAudioPlayer (NOT AVAudioEngine) to avoid I/O conflicts
//  CRITICAL: Does NOT configure or modify AVAudioSession
//

import AVFoundation

@MainActor
class SoundEffects {
    static let shared = SoundEffects()

    // MARK: - Properties

    @ObservationIgnored private nonisolated(unsafe) var startPlayer: AVAudioPlayer?
    @ObservationIgnored private nonisolated(unsafe) var stopPlayer: AVAudioPlayer?

    private let volume: Float = 0.08  // Very low volume (calm, subtle)
    private var isReady = false  // Phase 7.4 Fix: Lazy initialization flag

    // MARK: - Initialization

    private init() {
        // CRITICAL: Do NOT configure audio session here!
        // AudioSessionManager manages the session
        //
        // Phase 7.4 Fix: Audio files now generated on first use (async)
        // This prevents blocking main thread during app launch (Watchdog timeout)
    }

    // MARK: - Setup

    /// Prepare audio files for playback (async, called on first use)
    /// Phase 7.4 Fix: Moved to background to avoid blocking main thread
    private func prepareAudioFilesAsync() async {
        guard !isReady else { return }

        do {
            // Generate breath-in sound (0.5s, 200Hz)
            let startURL = try generateTone(frequency: 200, duration: 0.5, envelope: .breathIn)
            startPlayer = try AVAudioPlayer(contentsOf: startURL)
            startPlayer?.prepareToPlay()
            startPlayer?.volume = volume

            // Generate breath-out sound (0.8s, 180Hz)
            let stopURL = try generateTone(frequency: 180, duration: 0.8, envelope: .breathOut)
            stopPlayer = try AVAudioPlayer(contentsOf: stopURL)
            stopPlayer?.prepareToPlay()
            stopPlayer?.volume = volume

            isReady = true

            #if DEBUG
            print("🎵 Sound effects prepared (async)")
            #endif
        } catch {
            print("⚠️ Failed to prepare sound effects: \(error)")
        }
    }

    // MARK: - Public API

    /// Play soft breath-in sound (0.5s fade-in)
    /// Triggered when recording actually starts
    /// Phase 7.4 Fix: Auto-prepares async on first call
    func playRecordStart() {
        Task {
            if !isReady {
                await prepareAudioFilesAsync()
            }

            await MainActor.run {
                startPlayer?.currentTime = 0
                startPlayer?.play()

                #if DEBUG
                print("🎵 Playing start sound")
                #endif
            }
        }
    }

    /// Play gentle breath-out sound (0.8s fade-out)
    /// Triggered when entering .finished state
    /// Phase 7.4 Fix: Auto-prepares async on first call
    func playRecordStop() {
        Task {
            if !isReady {
                await prepareAudioFilesAsync()
            }

            await MainActor.run {
                stopPlayer?.currentTime = 0
                stopPlayer?.play()

                #if DEBUG
                print("🎵 Playing stop sound")
                #endif
            }
        }
    }

    // MARK: - Audio Generation

    /// Envelope type for fade in/out
    private enum Envelope {
        case breathIn   // Quick fade-in (0.5s)
        case breathOut  // Longer fade-out (0.8s)
    }

    /// Generate a simple sine wave tone with envelope and save to file
    /// Returns the URL of the generated WAV file
    private func generateTone(frequency: Float, duration: TimeInterval, envelope: Envelope) throws -> URL {
        // Audio format: 44.1kHz, mono, 16-bit PCM
        let sampleRate: Double = 44100.0
        let frameCount = Int(sampleRate * duration)
        let channelCount: AVAudioChannelCount = 1

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        ) else {
            throw SoundEffectError.formatCreationFailed
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            throw SoundEffectError.bufferCreationFailed
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        // Generate sine wave with envelope
        guard let channelData = buffer.int16ChannelData else {
            throw SoundEffectError.channelDataUnavailable
        }

        let data = channelData[0]
        let amplitude: Int16 = 3000  // Very low amplitude (calm, subtle)
        let angularFrequency = 2.0 * Float.pi * frequency / Float(sampleRate)

        for frame in 0..<frameCount {
            let sampleValue = sin(angularFrequency * Float(frame))

            // Apply envelope (fade in or fade out)
            let envelopeMultiplier: Float
            let progress = Float(frame) / Float(frameCount)

            switch envelope {
            case .breathIn:
                // Fade in quickly (0.0 → 1.0 → 0.8)
                if progress < 0.3 {
                    // Fast fade-in
                    envelopeMultiplier = progress / 0.3
                } else {
                    // Gentle fade-out
                    envelopeMultiplier = 1.0 - (progress - 0.3) * 0.3
                }

            case .breathOut:
                // Longer fade-out (1.0 → 0.0)
                if progress < 0.2 {
                    // Quick peak
                    envelopeMultiplier = 1.0
                } else {
                    // Long fade-out
                    envelopeMultiplier = 1.0 - ((progress - 0.2) / 0.8)
                }
            }

            data[frame] = Int16(sampleValue * Float(amplitude) * envelopeMultiplier)
        }

        // Write to temporary file
        let fileName = envelope == .breathIn ? "start_tone.wav" : "stop_tone.wav"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let audioFile = try AVAudioFile(
            forWriting: fileURL,
            settings: format.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: false
        )

        try audioFile.write(from: buffer)

        #if DEBUG
        print("🎵 Generated tone: \(fileName)")
        #endif

        return fileURL
    }

    // MARK: - Errors

    enum SoundEffectError: Error {
        case formatCreationFailed
        case bufferCreationFailed
        case channelDataUnavailable
    }
}
