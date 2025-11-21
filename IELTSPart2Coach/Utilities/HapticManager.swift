//
//  HapticManager.swift
//  IELTSPart2Coach
//
//  Haptic feedback system for tactile interactions
//  Supports the "calm, intimate, and fluid" interaction philosophy
//

import UIKit

/// Centralized haptic feedback manager
@MainActor
class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private var isPrepared = false

    private init() {}

    // MARK: - Preparation

    /// Auto-prepares haptic engine on first use (lazy initialization)
    /// Phase 7.4 Fix: No longer called during app launch to avoid blocking
    private func prepareIfNeeded() {
        guard !isPrepared else { return }

        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selection.prepare()
        notification.prepare()

        isPrepared = true
    }

    // MARK: - Impact Feedback

    /// Light impact - for subtle interactions (button hover, selection)
    func light() {
        prepareIfNeeded()
        impactLight.impactOccurred()
    }

    /// Medium impact - for primary actions (Start recording, Stop recording)
    func medium() {
        prepareIfNeeded()
        impactMedium.impactOccurred()
    }

    /// Heavy impact - for significant moments (recording complete, error states)
    func heavy() {
        prepareIfNeeded()
        impactHeavy.impactOccurred()
    }

    // MARK: - Selection Feedback

    /// Selection change - for UI state transitions
    func selectionDidChange() {
        prepareIfNeeded()
        selection.selectionChanged()
    }

    // MARK: - Notification Feedback

    /// Success notification - for positive confirmations
    func success() {
        prepareIfNeeded()
        notification.notificationOccurred(.success)
    }

    /// Warning notification - for caution states
    func warning() {
        prepareIfNeeded()
        notification.notificationOccurred(.warning)
    }

    /// Error notification - for error states
    func error() {
        prepareIfNeeded()
        notification.notificationOccurred(.error)
    }

    // MARK: - Custom Sequences

    /// Breathing pulse - a subtle double-tap for calm moments
    func breathingPulse() {
        light()
        Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
            light()
        }
    }

    /// Recording start sequence - medium impact with light echo
    func recordingStart() {
        medium()
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            light()
        }
    }

    /// Recording stop sequence - medium impact with breathing pulse
    func recordingStop() {
        medium()
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            breathingPulse()
        }
    }
}
