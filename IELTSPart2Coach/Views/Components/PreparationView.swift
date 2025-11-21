//
//  PreparationView.swift
//  IELTSPart2Coach
//
//  Preparation stage UI: 60-second countdown with optional skip
//  Clean, minimal design following Liquid Glass aesthetic
//

import SwiftUI

struct PreparationView: View {
    let timeLeft: TimeInterval
    let progress: Double
    let showSkipButton: Bool
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Circular countdown ring
            countdownRing

            Spacer()

            // Skip button (fades in after 10s)
            if showSkipButton {
                skipButton
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Countdown Ring

    private var countdownRing: some View {
        ZStack {
            // Progress ring (inverse: fills as time decreases)
            CircularProgressRing(
                progress: progress,
                lineWidth: 12,
                diameter: 220
            )

            // Time display
            VStack(spacing: 12) {
                Text("Prepare")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(formattedTime)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button {
            onSkip()
        } label: {
            Text("Skip Preparation")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background {
                    Capsule()
                        .fill(.black.opacity(0.3))
                        .background {
                            Capsule()
                                .fill(.ultraThinMaterial)
                        }
                }
        }
    }

    // MARK: - Helper

    private var formattedTime: String {
        let minutes = Int(timeLeft) / 60
        let seconds = Int(timeLeft) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.fogWhite
            .ignoresSafeArea()

        PreparationView(
            timeLeft: 45,
            progress: 0.25,
            showSkipButton: true,
            onSkip: {
                print("Skip tapped")
            }
        )
    }
}
