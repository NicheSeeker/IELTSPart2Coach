//
//  AudioSessionManager.swift
//  IELTSPart2Coach
//
//  Global Audio Session Coordinator
//  Ensures single point of control for AVAudioSession configuration
//  Prevents I/O thread conflicts and RemoteIO crashes on iPhone 15/16
//

import AVFoundation

/// Thread-safe audio session manager
/// CRITICAL: All audio session modifications must go through this manager
/// to prevent "Unable to join I/O thread to workgroup" crashes
@MainActor
class AudioSessionManager {
    static let shared = AudioSessionManager()

    // MARK: - State

    private var isSessionActive = false
    private let session = AVAudioSession.sharedInstance()

    private init() {}

    // MARK: - Session Management

    /// Configure and activate audio session for recording and playback
    /// MUST be called before any audio operations (recording or playing)
    /// This is the ONLY place where setCategory() and setActive() should be called
    func configureSession() throws {
        // Prevent redundant activation (causes I/O conflicts)
        guard !isSessionActive else {
            print("⚠️ Audio session already active, skipping reconfiguration")
            return
        }

        #if DEBUG
        print("🎧 Configuring audio session...")
        print("🎧 Available inputs: \(session.availableInputs?.count ?? 0)")
        if let inputs = session.availableInputs {
            for input in inputs {
                print("   - \(input.portName) (\(input.portType.rawValue))")
            }
        }
        #endif

        // Configure session for both recording and playback
        // - .playAndRecord: Supports recording + playback simultaneously
        // - .defaultToSpeaker: Route playback to speaker (not receiver/听筒)
        // - .allowBluetooth: Support Bluetooth devices
        // - .mixWithOthers: Allow background music (respects user's audio context)
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
        )

        // Activate session (CRITICAL: Do this ONCE and ONLY HERE)
        try session.setActive(true, options: [])
        isSessionActive = true

        #if DEBUG
        print("✅ Audio session activated successfully")
        print("🎧 Category: \(session.category.rawValue)")
        print("🎧 Mode: \(session.mode.rawValue)")
        print("🎧 Current route: \(session.currentRoute)")
        if let input = session.currentRoute.inputs.first {
            print("🎧 Input: \(input.portName) - Channels: \(input.channels?.count ?? 0)")
        }
        if let output = session.currentRoute.outputs.first {
            print("🎧 Output: \(output.portName)")
        }
        #endif
    }

    /// Deactivate audio session when no longer needed
    /// NOTE: Usually not needed as iOS manages this automatically
    /// Only call this during app termination or extended idle periods
    func deactivateSession() throws {
        guard isSessionActive else { return }

        try session.setActive(false, options: .notifyOthersOnDeactivation)
        isSessionActive = false

        #if DEBUG
        print("🎧 Audio session deactivated")
        #endif
    }

    /// Force re-activation if session was interrupted (e.g., by phone call)
    /// iOS will send AVAudioSession.interruptionNotification in such cases
    func reactivateIfNeeded() throws {
        if !isSessionActive {
            #if DEBUG
            print("🎧 Re-activating audio session after interruption...")
            #endif
            try configureSession()
        }
    }

    // MARK: - Session Info

    /// Check if session is currently active
    var isActive: Bool {
        isSessionActive
    }

    /// Get current output route (for debugging)
    var currentOutputRoute: String {
        session.currentRoute.outputs.first?.portName ?? "Unknown"
    }
}
